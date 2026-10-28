import Foundation
import FoundationModels
import Vision
import CoreGraphics
import ImageIO

public class AppleAISession {
    let session: LanguageModelSession
    
    init(instructions: String?) {
        let model = SystemLanguageModel.default
        self.session = LanguageModelSession(model: model, instructions: instructions)
    }
}

public typealias AppleAITokenCallback = @convention(c) (UnsafePointer<CChar>?, Int32, UnsafeMutableRawPointer?) -> Void

private func loadImage(from source: String) -> CGImage? {
    let cleanSource = source.trimmingCharacters(in: .whitespacesAndNewlines)
    if cleanSource.hasPrefix("data:image/") {
        guard let commaIdx = cleanSource.firstIndex(of: ",") else { return nil }
        let base64Part = String(cleanSource[cleanSource.index(after: commaIdx)...])
        guard let data = Data(base64Encoded: base64Part, options: .ignoreUnknownCharacters),
              let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            return nil
        }
        return cgImage
    } else {
        var filePath = cleanSource
        if filePath.hasPrefix("file://") {
            filePath = String(filePath.dropFirst(7))
        }
        let url = URL(fileURLWithPath: filePath)
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            return nil
        }
        return cgImage
    }
}

@_cdecl("_swift_apple_ai_process_image")
public func _swift_apple_ai_process_image(imageSource: UnsafePointer<CChar>) -> UnsafeMutablePointer<CChar>? {
    let sourceStr = String(cString: imageSource)
    guard let cgImage = loadImage(from: sourceStr) else {
        return strdup("ERROR: Failed to load image from source path or data URI")
    }

    let textRequest = VNRecognizeTextRequest()
    textRequest.recognitionLevel = .accurate
    textRequest.usesLanguageCorrection = true

    let classifyRequest = VNClassifyImageRequest()

    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    do {
        try handler.perform([textRequest, classifyRequest])
    } catch {
        return strdup("ERROR: Vision request failed: \(error.localizedDescription)")
    }

    var recognizedLines: [String] = []
    if let textResults = textRequest.results {
        for observation in textResults {
            if let topCandidate = observation.topCandidates(1).first {
                recognizedLines.append(topCandidate.string)
            }
        }
    }

    var classifications: [String] = []
    if let classResults = classifyRequest.results {
        for observation in classResults.prefix(6) {
            if observation.confidence > 0.15 {
                let pct = Int(observation.confidence * 100)
                classifications.append("\(observation.identifier) (\(pct)%)")
            }
        }
    }

    var desc = "[VISUAL CONTEXT]\n"
    if !classifications.isEmpty {
        desc += "Scene/Objects: " + classifications.joined(separator: ", ") + "\n"
    }
    if !recognizedLines.isEmpty {
        desc += "Extracted Text (OCR):\n"
        for line in recognizedLines {
            desc += "- " + line + "\n"
        }
    } else {
        desc += "Extracted Text (OCR): (No text detected)\n"
    }
    desc += "[/VISUAL CONTEXT]"

    return strdup(desc)
}

@_cdecl("_swift_apple_ai_is_available")
public func _swift_apple_ai_is_available() -> Int32 {
    let model = SystemLanguageModel.default
    switch model.availability {
    case .available:
        return 1
    default:
        return 0
    }
}

@_cdecl("_swift_apple_ai_session_create")
public func _swift_apple_ai_session_create(instructions: UnsafePointer<CChar>?) -> UnsafeMutableRawPointer? {
    let instStr = instructions != nil ? String(cString: instructions!) : nil
    let session = AppleAISession(instructions: instStr)
    return Unmanaged.passRetained(session).toOpaque()
}

@_cdecl("_swift_apple_ai_session_destroy")
public func _swift_apple_ai_session_destroy(sessionPtr: UnsafeMutableRawPointer) {
    let _: AppleAISession = Unmanaged.fromOpaque(sessionPtr).takeRetainedValue()
}

@_cdecl("_swift_apple_ai_respond")
public func _swift_apple_ai_respond(
    sessionPtr: UnsafeMutableRawPointer?,
    prompt: UnsafePointer<CChar>
) -> UnsafeMutablePointer<CChar>? {
    let session: AppleAISession
    if let sessionPtr = sessionPtr {
        session = Unmanaged<AppleAISession>.fromOpaque(sessionPtr).takeUnretainedValue()
    } else {
        session = AppleAISession(instructions: nil)
    }
    
    let promptStr = String(cString: prompt)
    let semaphore = DispatchSemaphore(value: 0)
    var resultStr = ""
    
    Task {
        do {
            let response = try await session.session.respond(to: promptStr)
            resultStr = response.content
        } catch {
            resultStr = "ERROR: \(error.localizedDescription)"
        }
        semaphore.signal()
    }
    
    semaphore.wait()
    return strdup(resultStr)
}

@_cdecl("_swift_apple_ai_respond_stream")
public func _swift_apple_ai_respond_stream(
    sessionPtr: UnsafeMutableRawPointer?,
    prompt: UnsafePointer<CChar>,
    callback: AppleAITokenCallback,
    userData: UnsafeMutableRawPointer?
) -> UnsafeMutablePointer<CChar>? {
    let session: AppleAISession
    if let sessionPtr = sessionPtr {
        session = Unmanaged<AppleAISession>.fromOpaque(sessionPtr).takeUnretainedValue()
    } else {
        session = AppleAISession(instructions: nil)
    }
    
    let promptStr = String(cString: prompt)
    let semaphore = DispatchSemaphore(value: 0)
    var errorStr: String? = nil
    
    Task {
        do {
            var lastLength = 0
            let stream = session.session.streamResponse(to: promptStr)
            for try await partialResponse in stream {
                let fullContent = partialResponse.content
                let currentLength = fullContent.count
                if currentLength > lastLength {
                    let startIndex = fullContent.index(fullContent.startIndex, offsetBy: lastLength)
                    let newContent = String(fullContent[startIndex...])
                    lastLength = currentLength
                    newContent.withCString { cStr in
                        callback(cStr, Int32(newContent.utf8.count), userData)
                    }
                }
            }
        } catch {
            errorStr = "ERROR: \(error.localizedDescription)"
        }
        semaphore.signal()
    }
    
    semaphore.wait()
    if let errorStr = errorStr {
        return strdup(errorStr)
    }
    return nil
}

@_cdecl("_swift_apple_ai_free_string")
public func _swift_apple_ai_free_string(str: UnsafeMutablePointer<CChar>?) {
    if let str = str {
        free(str)
    }
}
