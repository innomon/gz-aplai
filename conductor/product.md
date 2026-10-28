# Initial Concept
APLAI Goose: Port the Apple Silicon Local AI Runner (../aplai) to the Goose systems programming language, executable via /Volumes/mac1tb/B204-zone/owly-sewa/goose-lang/build/goose.

---

# Product Guide - gz-aplai (Goose APLAI)

## 1. Product Vision & Overview
`gz-aplai` is a high-performance, 100% on-device local LLM (Large Language Model) runner and API server optimized specifically for Apple Silicon macOS (Sequoia 15+ / Tahoe 16+), ported to and implemented in the **Goose** systems programming language. It leverages Goose's zero-cost memory model and C foreign-function interface (FFI) to link against native Apple `LanguageModelSession` (FoundationModels) via an in-process Swift dynamic library (`libapple_ai_bridge.dylib`).

It provides:
1. A fast, UNIX-pipeline-friendly CLI for single prompt execution and script integration.
2. A colorized interactive REPL chat interface with real-time streaming token generation.
3. An OpenAI-compatible HTTP server (`/v1/chat/completions`) supporting both synchronous JSON responses and real-time Server-Sent Events (SSE) streaming.
4. An automated build harness driven by the Goose compiler toolchain (`/Volumes/mac1tb/B204-zone/owly-sewa/goose-lang/build/goose`).
5. Native multimodal visual intelligence via macOS Vision framework (OCR and scene classification) for CLI (`--image`) and OpenAI Vision API.

## 2. Target Audience
- **Systems & Terminal Power Users:** Developers needing a lightning-fast, zero-overhead, scriptable local LLM runner for Apple Silicon.
- **App & Agent Developers:** Engineers seeking an OpenAI-compatible local completions endpoint with zero external Python/Go runtimes, leveraging Goose native binary execution.

## 3. Key Functional Features
- **Native Swift/C Dynamic Bridge:** Direct C-ABI bridge calls to Swift `LanguageModelSession` with thread synchronization, memory safety, and streaming callbacks.
- **UNIX CLI & Interactive REPL:** Single-shot prompt evaluation via stdin or arguments, and full `--chat` interactive console.
- **OpenAI-Compatible HTTP Server:** Local REST API server on default port 8080 with streaming SSE support and concurrency serialization.
- **Configuration & Structured Logging:** Dual console/file logging, structured output, and `config.yaml` support.
- **Pure Goose Architecture:** Maximum utilization of Goose data stacks, inline structures, and native performance.
- **Multimodal Vision & OCR Engine:** Native Apple Vision framework integration (`VNRecognizeTextRequest`, `VNClassifyImageRequest`) supporting local image files and OpenAI base64 data URLs.
