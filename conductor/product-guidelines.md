# Product Guidelines - gz-aplai

This document outlines the user experience (UX), error handling, API design, and architectural standards for developing `gz-aplai` in the Goose systems programming language.

## 1. User Experience & CLI Design

### 1.1 Terminal Output Formatting
- **Interactive REPL Mode (`--chat`):** Output must be clean and responsive. Use subtle ANSI escape sequences for speaker delineation (e.g., prompt indicator, user turn vs assistant turn) and real-time token streaming.
- **Pipelined / Non-Interactive Mode:** When stdin is piped or prompts are passed as command-line arguments, stdout must emit pure plain text with no ANSI escapes or progress artifacts, ensuring seamless composition with UNIX pipelines (`grep`, `awk`, shell scripts).
- **Graceful Session Exit:** In REPL mode, commands `/exit`, `/quit`, `exit`, and `quit` must cleanly exit the loop without panics or leaks.

### 1.2 Error Handling & Verbosity
- User-facing runtime errors should output to stderr with clear, actionable diagnostics.
- Avoid low-level crashes; handle missing Swift dylibs, invalid model sessions, or bad parameters gracefully with descriptive messages.
- Diagnostic information should be recorded cleanly in structured format (console + JSON log).

## 2. API Design & Interoperability

### 2.1 OpenAI Specification Compliance
- The HTTP server must serve `/v1/chat/completions` with request and response payloads conforming to the OpenAI Chat Completion format.
- Both synchronous JSON (`stream: false`) and SSE streaming (`stream: true`) must adhere strictly to chunk formats (`data: {...}\n\n` followed by `data: [DONE]\n\n`).

### 2.2 API Error Responses
- API errors must emit OpenAI-compatible JSON error bodies with standard HTTP status codes (`400`, `404`, `500`).

## 3. Goose Architecture & Coding Standards

### 3.1 Zero-Heap Idiomatic Goose Design
- Leverage Goose's contiguous data stacks and inline data structures (`u8[>..]`, fixed-size structs, slice views `u8[:]`) rather than dynamic pointer graphs.
- Exploit Goose compile-time lifetime verification to prevent dangling pointers and memory safety issues.

### 3.2 FFI & Native Bridge Boundaries
- Keep foreign-function calls between Goose and the Swift dylib (`libapple_ai_bridge.dylib`) strictly typed and minimal across C ABI boundaries.
- Swift memory allocated dynamically must have explicit deallocation paired on the bridge side, preventing memory leaks during long-running server sessions.

### 3.3 Hardware Safety & Concurrency
- Implement queueing and serial execution locks around inference sessions to avoid overwhelming Apple Silicon GPU/NPU cores during concurrent HTTP requests.
