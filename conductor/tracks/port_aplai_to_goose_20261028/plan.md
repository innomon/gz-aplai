# Implementation Plan - Port APLAI to Goose Language with Native Apple Silicon Bridge

## Phase 1: Build Harness, Swift Bridge & Goose FFI Smoke Test

- [ ] Task: Create Swift Dynamic Bridge and C Header
    - [ ] Create `apple_ai_bridge.swift` with C exports (`AppleAIGenerate`, `FreeAppleAIString`, `AppleAIIsAvailable`)
    - [ ] Create `apple_ai_bridge.h` declaring C ABI signatures for Goose FFI
    - [ ] Create `Makefile` driving `swiftc` to build `libapple_ai_bridge.dylib`
- [ ] Task: Goose FFI smoke test
    - [ ] Create minimal Goose smoke test (`smoke_ffi.goose`) invoking bridge C functions
    - [ ] Compile smoke test using `/Volumes/mac1tb/B204-zone/owly-sewa/goose-lang/build/goose` and verify execution
- [ ] Task: Conductor - User Manual Verification 'Phase 1: Build Harness, Swift Bridge & Goose FFI'

## Phase 2: Core Engine, Configuration & Structured Logging

- [ ] Task: Configuration module (`config.goose` / `config.yaml`)
    - [ ] Implement config parser checking explicit path, `./config.yaml`, and executable directory
    - [ ] Define default fallback configuration
- [ ] Task: Structured logger (`logger.goose`)
    - [ ] Implement console message formatting and file logging
- [ ] Task: Core Inference Engine wrapper (`engine.goose`)
    - [ ] Implement Goose wrapper around `AppleAIGenerate` with proper memory management and error handling
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Core Engine, Configuration & Structured Logging'

## Phase 3: CLI Engine, UNIX Pipeline & Interactive REPL

- [ ] Task: CLI argument parser and UNIX pipeline execution
    - [ ] Implement argument parsing for flags (`--chat`, `--server`, `--config`, positional prompt)
    - [ ] Implement stdin reader for streaming piping input into engine
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
