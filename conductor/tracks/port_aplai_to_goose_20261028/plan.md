# Implementation Plan - Port APLAI to Goose Language with Native Apple Silicon Bridge

## Phase 1: Build Harness, Swift Bridge & Goose FFI Smoke Test [checkpoint: 888144c]

- [x] Task: Create Swift Dynamic Bridge and C Header [39e6b79]
    - [x] Create `apple_ai_bridge.swift` with C exports (`AppleAIGenerate`, `FreeAppleAIString`, `AppleAIIsAvailable`)
    - [x] Create `apple_ai_bridge.h` declaring C ABI signatures for Goose FFI
    - [x] Create `Makefile` driving `swiftc` to build `libapple_ai_bridge.dylib`
- [x] Task: Goose FFI smoke test [d9d4d8c]
    - [x] Create minimal Goose smoke test (`smoke_ffi.goose`) invoking bridge C functions
    - [x] Compile smoke test using `/Volumes/mac1tb/B204-zone/owly-sewa/goose-lang/build/goose` and verify execution
- [x] Task: Conductor - User Manual Verification 'Phase 1: Build Harness, Swift Bridge & Goose FFI' [888144c]

## Phase 2: Core Engine, Configuration & Structured Logging [checkpoint: 631d20c]

- [x] Task: Configuration module (`config.goose` / `config.yaml`) [d039916]
    - [x] Implement config parser checking explicit path, `./config.yaml`, and executable directory
    - [x] Define default fallback configuration
- [x] Task: Structured logger (`logger.goose`) [44bf96e]
    - [x] Implement console message formatting and file logging
- [x] Task: Core Inference Engine wrapper (`engine.goose`) [dff9021]
    - [x] Implement Goose wrapper around `AppleAIGenerate` with proper memory management and error handling
- [x] Task: Conductor - User Manual Verification 'Phase 2: Core Engine, Configuration & Structured Logging' [631d20c]

## Phase 3: CLI Engine, UNIX Pipeline & Interactive REPL

- [x] Task: CLI argument parser and UNIX pipeline execution [b504b4c]
    - [x] Implement argument parsing for flags (`--chat`, `--server`, `--config`, positional prompt)
    - [x] Implement stdin reader for streaming piping input into engine
- [ ] Task: Interactive REPL chat mode (`--chat`)
    - [ ] Implement interactive chat loop with ANSI terminal styling
    - [ ] Implement exit commands (`/exit`, `/quit`, `exit`, `quit`)
- [ ] Task: Conductor - User Manual Verification 'Phase 3: CLI Engine, UNIX Pipeline & Interactive REPL'

## Phase 4: OpenAI-Compatible HTTP Server & Concurrency Control

- [ ] Task: OpenAI-compatible completions HTTP server
    - [ ] Implement HTTP server listening on configured host/port
    - [ ] Handle `/v1/chat/completions` supporting JSON response format and Server-Sent Events (SSE)
- [ ] Task: Hardware execution concurrency control
    - [ ] Implement execution mutex / serialization around inference calls to prevent NPU/GPU contention
- [ ] Task: Conductor - User Manual Verification 'Phase 4: OpenAI-Compatible HTTP Server & Concurrency Control'
