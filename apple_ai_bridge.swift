import Foundation
import FoundationModels

public class AppleAISession {
    let session: LanguageModelSession
    
    init(instructions: String?) {
        let model = SystemLanguageModel.default
        self.session = LanguageModelSession(model: model, instructions: instructions)
    }
}

public typealias AppleAITokenCallback = @convention(c) (UnsafePointer<CChar>?, Int32, UnsafeMutableRawPointer?) -> Void

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
