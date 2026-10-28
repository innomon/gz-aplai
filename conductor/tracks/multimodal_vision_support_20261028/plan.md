# Implementation Plan - Add Multimodal Capabilities (macOS Vision & Image Understanding) to APLAI in Goose

## Phase 1: Swift Vision Dynamic Bridge & C ABI [checkpoint: 727153f]

- [x] Task: Implement Swift Vision image processor in `apple_ai_bridge.swift` [d58406e]
    - [x] Add image loader supporting file paths and base64 data URLs via `ImageIO` / `CoreGraphics`
    - [x] Run `VNRecognizeTextRequest` (.accurate) for OCR text extraction
    - [x] Run `VNClassifyImageRequest` for scene and object classification
    - [x] Export `_swift_apple_ai_process_image` C symbol
- [x] Task: C ABI Bridge & Compilation in `apple_ai_bridge.h` and `Makefile` [d58406e]
    - [x] Add C wrapper `apple_ai_process_image(image_source, out_desc)`
    - [x] Link `Vision` framework in `Makefile` and verify dylib compilation
- [x] Task: Conductor - User Manual Verification 'Phase 1: Swift Vision Dynamic Bridge & C ABI' (Protocol in workflow.md) [727153f]

## Phase 2: Goose Multimodal Engine Integration & CLI Support

- [x] Task: Goose multimodal inference integration in `src/engine.goose` [8bb6525]
    - [x] Declare `extern fn apple_ai_process_image(image_source: const u8[:], out: u8[>..]&) -> bool`
    - [x] Implement `engine_generate_multimodal(eng, image_source, prompt, out)` combining visual context and user query
- [x] Task: CLI `--image` argument parsing and execution [8bb6525]
    - [x] Add `--image <path>` / `-i <path>` flag to `src/cli.goose`
    - [x] Wire up multimodal generation in `src/main.goose` for single prompts and piped stdin
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Goose Multimodal Engine Integration & CLI Support' (Protocol in workflow.md)

## Phase 3: OpenAI Vision API & Automated Test Suite

- [ ] Task: OpenAI `image_url` payload support in `src/server.goose`
    - [ ] Parse array-style `content: [{"type": "text", ...}, {"type": "image_url", ...}]` in HTTP request
    - [ ] Route multimodal prompts through `engine_generate_multimodal` for synchronous and SSE responses
- [ ] Task: Multimodal automated test suite in `test/test_vision.goose` and `test/test_all.goose`
    - [ ] Generate minimal synthetic test image
    - [ ] Verify OCR extraction and visual question answering
- [ ] Task: Conductor - User Manual Verification 'Phase 3: OpenAI Vision API & Automated Test Suite' (Protocol in workflow.md)
