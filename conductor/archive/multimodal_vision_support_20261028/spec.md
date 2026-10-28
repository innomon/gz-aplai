# Specification: Add Multimodal Capabilities (macOS Vision & Image Understanding) to APLAI in Goose

## 1. Overview
This track introduces multimodal capabilities to `gz-aplai`. By integrating Apple's native **Vision Framework** (`VNRecognizeTextRequest`, `VNClassifyImageRequest`) via our Swift dynamic bridge (`apple_ai_bridge.swift`), `gz-aplai` will be able to ingest image inputs (local file paths and OpenAI base64 data URLs), extract high-fidelity text/OCR, classify visual scene elements, and inject these structured multimodal contexts into the Apple Silicon `LanguageModelSession` for visual reasoning and question answering.

---

## 2. Functional Requirements

### 2.1 Swift Vision Bridge (`apple_ai_bridge.swift`, `apple_ai_bridge.h`)
- Extend Swift bridge to import `Vision` and `CoreGraphics` / `ImageIO`.
- Add C-ABI export `_swift_apple_ai_process_image(image_path_or_base64: UnsafePointer<CChar>) -> UnsafeMutablePointer<CChar>?`:
  - Loads image from filesystem path or decodes from `data:image/...;base64,...`.
  - Runs Vision text recognition (`VNRecognizeTextRequest` with `.accurate` recognition level) to extract all text, signs, labels, or documents.
  - Runs Vision image classification (`VNClassifyImageRequest`) to detect visual scene objects, settings, and subjects.
  - Formats the extracted multimodal context into a structured descriptor block:
    ```
    [VISUAL CONTEXT]
    Scene Description: <top classification tags>
    Extracted Text (OCR):
    <recognized text lines>
    [/VISUAL CONTEXT]
    ```
- Provide C wrapper `apple_ai_process_image(sl_u8 image_source, gs_rref out_desc) -> bool` in `apple_ai_bridge.h`.

### 2.2 CLI & Pipeline Multimodal Ingestion (`src/cli.goose`, `src/main.goose`)
- Add `--image <path>` (and `-i <path>`) CLI flag.
- When `--image` is provided:
  - Process image with Vision bridge.
  - Prepend structured visual context to the prompt before evaluation.
- Support piping prompts alongside `--image` (e.g. `cat question.txt | gz-aplai --image invoice.png`).

### 2.3 OpenAI Multimodal API (`/v1/chat/completions`)
- Support OpenAI Vision format in request message content array:
  ```json
  {
    "messages": [
      {
        "role": "user",
        "content": [
          {"type": "text", "text": "What does this invoice say?"},
          {"type": "image_url", "image_url": {"url": "data:image/png;base64,..."}}
        ]
      }
    ]
  }
  ```
- Also support `url` pointing to local file path (e.g. `file:///...` or `/path/to/image.png`).
- Parse `image_url`, extract vision features, compose unified context, and return standard chat completion or SSE streaming chunks.

---

## 3. Acceptance Criteria
- [ ] Swift bridge compiles with Vision framework without warnings or errors.
- [ ] Image processor handles PNG, JPEG, HEIC, and base64 data URIs.
- [ ] CLI command `gz-aplai --image <image> "prompt"` correctly describes image content and reads text.
- [ ] `/v1/chat/completions` accepts OpenAI `image_url` payloads and answers visual questions.
- [ ] Automated tests cover image decoding, OCR extraction, and combined multimodal completions.
