# Technology Stack - gz-aplai

## 1. Core Language & Runtime
- **Primary Language:** **Goose** (systems programming language featuring bump-pointer data stacks, zero-cost memory management, and inline data layouts)
- **Goose Toolchain Executable:** `/Volumes/mac1tb/B204-zone/owly-sewa/goose-lang/build/goose`
- **Backend C Toolchain:** Apple Clang / `cc` (for final linking and dynamic library binding with pthreads)

## 2. Hardware Acceleration & Native Inference
- **Native ML Framework:** Apple macOS `FoundationModels` framework (`LanguageModelSession`) targeting Apple Silicon (M1/M2/M3/M4) Neural Engine and GPU.
- **Vision & Multimodal Processing:** Apple macOS `Vision`, `ImageIO`, and `CoreGraphics` frameworks for high-precision on-device OCR and scene classification.
- **Inference Bridge:** Swift dynamic bridge (`apple_ai_bridge.swift` compiled to `libapple_ai_bridge.dylib`) exposing C ABI function exports.
- **FFI Binding:** Goose `extern fn` bindings interfacing through a clean C header (`apple_ai_bridge.h`).

## 3. Server, CLI & Networking
- **CLI Engine:** Goose CLI parser supporting command line flags (`--chat`, `--server`, `--image`, `--config`, `--help`) and UNIX stdin streaming.
- **Networking & Server:** Native POSIX socket HTTP server in Goose serving OpenAI-compatible `/v1/chat/completions` (including Vision `image_url` payloads) with JSON payload responses and Server-Sent Events (SSE) streaming.
- **Configuration & Logging:** YAML/key-value configuration reader (`config.yaml`), combined with Goose console printing and rotating file logging.

## 4. Build System & Environment
- **Build Harness:** `Makefile` driving `swiftc` compilation and `goose` compilation/linking.
- **Platform Support:** macOS Sequoia (15.0+) and Tahoe (16.0+) on Apple Silicon (arm64).
