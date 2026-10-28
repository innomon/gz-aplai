# Specification: Port APLAI to Goose Language with Native Apple Silicon Bridge

## 1. Overview
This track ports the APLAI (Apple Silicon Local AI Runner) MVP to the **Goose** systems programming language, executable via `/Volumes/mac1tb/B204-zone/owly-sewa/goose-lang/build/goose`. The engine interfaces with native macOS Sequoia/Tahoe (15.0+) `LanguageModelSession` (FoundationModels) using an in-process Swift dynamic library (`libapple_ai_bridge.dylib`) and Goose C FFI (`extern fn`).

---

## 2. Functional Requirements

### 2.1 Swift Bridge & C ABI (`apple_ai_bridge.swift`, `apple_ai_bridge.h`)
- Compile Swift bridge to dynamic library `libapple_ai_bridge.dylib` exposing C functions (`@_cdecl`).
- Synchronize async Swift calls using `DispatchSemaphore`.
- Memory safety: export deallocator (`FreeAppleAIString`) or append directly to Goose buffers.
- Provide a clean C header (`apple_ai_bridge.h`) declaring function signatures and types.

### 2.2 Core Goose Engine & Logging (`src/engine.goose`, `src/logger.goose`, `src/config.goose`)
- Define Goose `extern fn` bindings to call the Swift dynamic library.
- Memory management ensuring zero leaks across prompt inference cycles.
- Structured dual logging: formatted output to stderr/console and structured logging to log file.
- Configuration loading from `config.yaml` with search order: explicit CLI path -> `./config.yaml` -> binary directory.

### 2.3 CLI Engine & REPL (`src/cli.goose`, `src/main.goose`)
- Argument parsing supporting:
  - Positional trailing prompt argument.
  - `--chat`: Interactive REPL console with ANSI color accents and escape commands (`/exit`, `/quit`).
  - Stdin piping: Reading plain text from stdin for UNIX pipeline workflows (`echo "hello" | gz-aplai`).
  - `--server`: Launch the HTTP completions server.
  - `--config <path>`: Explicit configuration file path.

### 2.4 OpenAI-Compatible HTTP Server (`src/server.goose`)
- Expose `/v1/chat/completions` supporting JSON response payloads and Server-Sent Events (SSE) streaming.
- Hardware execution mutex to serialize concurrent LLM requests and prevent Apple Silicon GPU/NPU overload.
- Standard OpenAI error payloads on failure.

### 2.5 Build Harness (`Makefile`)
- Orchestrate `swiftc` compilation into `libapple_ai_bridge.dylib`.
- Invoke `/Volumes/mac1tb/B204-zone/owly-sewa/goose-lang/build/goose` to compile Goose sources into the executable `gz-aplai`.
- Proper rpath settings (`-Wl,-rpath,@loader_path`) so the binary finds the Swift dylib in its directory.

---

## 3. Acceptance Criteria
- [ ] Swift bridge compiles cleanly to `libapple_ai_bridge.dylib`.
- [ ] Goose binary builds cleanly using `/Volumes/mac1tb/B204-zone/owly-sewa/goose-lang/build/goose`.
- [ ] Positional prompt and stdin piping execute local inference and return plain text.
- [ ] Interactive REPL (`--chat`) operates with colored turns and clean exit commands.
- [ ] HTTP server (`--server`) serves `/v1/chat/completions` with JSON and SSE streaming.
- [ ] Hardware concurrency mutex prevents simultaneous inference collisions.
- [ ] Automated tests / smoke verification scripts pass.
