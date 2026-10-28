# APLAI Goose (`gz-aplai`) - Apple Silicon Local AI Runner

`gz-aplai` is a high-performance, 100% on-device local LLM and multimodal inference engine optimized for Apple Silicon (macOS Sequoia 15+ and Tahoe 16+), ported to and written in the **Goose** systems programming language.

It leverages Goose's bump-pointer memory stacks, zero-cost abstractions, and C Foreign Function Interface (FFI) to link directly against Apple's native `LanguageModelSession` (FoundationModels) and `Vision` framework via an in-process Swift dynamic library (`libapple_ai_bridge.dylib`).

---

## Key Features

- **Native Apple Silicon Inference:** Direct execution on Apple Neural Engine (ANE) and GPU via macOS `LanguageModelSession` with zero external Python or Go runtimes.
- **Multimodal Visual Understanding:** Ingests images (PNG, JPEG, HEIC, or base64 data URIs) using macOS `Vision` (`VNRecognizeTextRequest` accurate OCR and `VNClassifyImageRequest`), automatically injecting visual context for reasoning and question answering.
- **UNIX Pipeline Friendly CLI:** Evaluates prompts passed as arguments or piped through standard input (`stdin`) for composable shell workflows.
- **Colorized Interactive REPL (`--chat`):** Terminal chat experience with ANSI color highlighting, real-time token delta streaming, and slash commands (`/help`, `/clear`, `/exit`, `/quit`).
- **OpenAI-Compatible HTTP Server (`--server`):** Local REST server on port 8080 providing `/v1/chat/completions` with both synchronous JSON and real-time Server-Sent Events (SSE) streaming, including support for OpenAI Vision `image_url` payloads.
- **Hardware-Safe Concurrency Serialization:** Mutex-backed request queueing prevents concurrent execution collisions on the Neural Engine.
- **Structured Dual Logging & YAML Config:** Configurable via `config.yaml` with simultaneous console output and size-rotated file logging.

---

## Architecture Overview

```
                      +---------------------------------------+
                      |               gz-aplai                |
                      |        (Goose Native Binary)          |
                      +-------------------+-------------------+
                                          |
                        Goose FFI Binding | (extern fn C ABI)
                                          v
                      +---------------------------------------+
                      |        libapple_ai_bridge.dylib       |
                      |     (In-Process Swift C-Bridge)       |
                      +---------+-------------------+---------+
                                |                   |
                                v                   v
             +-----------------------+ +-----------------------+
             |   FoundationModels    | |        Vision         |
             | (LanguageModelSession)| |   (OCR & Classifier)  |
             +-----------------------+ +-----------------------+
                                |                   |
             +-------------------------------------------------+
             |        Apple Silicon Neural Engine & GPU        |
             +-------------------------------------------------+
```

---

## Prerequisites

- **Operating System:** macOS Sequoia (15.0+) or macOS Tahoe (16.0+)
- **Architecture:** Apple Silicon (`arm64` - M1, M2, M3, M4 series)
- **Compilers:**
  - Xcode Command Line Tools (`swiftc`, `cc` / Apple Clang)
  - Goose programming language compiler toolchain (`goose`)

---

## Building and Testing

Use the provided `Makefile` to compile the Swift dynamic library, transpile Goose source code, and link the final native binary:

```bash
# Build the Swift dynamic library and gz-aplai executable
make build

# Run the automated 6-part test suite (Config, Logger, Engine, CLI, Server, Multimodal)
make test

# Clean all build artifacts
make clean
```

---

## Usage Modes

### 1. UNIX Pipeline & Single Prompts

Evaluate a prompt directly from command line arguments:
```bash
./gz-aplai "Explain Apple Silicon Neural Engine in one sentence."
```

Or pipe input through standard input (`stdin`):
```bash
echo "List three key features of the Goose programming language." | ./gz-aplai
```

### 2. Multimodal Image Understanding (`--image`)

Pass a local image file (or base64 data URL) alongside a prompt:
```bash
./gz-aplai --image document.png "Summarize the text in this image."
```

Combine piping with image ingestion:
```bash
cat instructions.txt | ./gz-aplai --image invoice.jpg
```

### 3. Interactive REPL Chat (`--chat`)

Launch the colorized interactive console with real-time streaming tokens:
```bash
./gz-aplai --chat
```

Available REPL commands:
- `/` or `/help` - Display interactive help and command list.
- `/clear` - Clear the terminal screen.
- `/exit` or `/quit` - Exit the interactive chat session.

### 4. OpenAI-Compatible HTTP Server (`--server`)

Start the local completions server:
```bash
./gz-aplai --server
```
The server binds to `http://127.0.0.1:8080` by default.

#### Synchronous JSON Completion:
```bash
curl -X POST http://127.0.0.1:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      {"role": "user", "content": "What is 2+2?"}
    ]
  }'
```

#### Real-Time SSE Streaming Completion:
```bash
curl -X POST http://127.0.0.1:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "stream": true,
    "messages": [
      {"role": "user", "content": "Write a short poem about compiler optimization."}
    ]
  }'
```

#### Multimodal OpenAI Vision Request:
```bash
curl -X POST http://127.0.0.1:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      {
        "role": "user",
        "content": [
          {"type": "text", "text": "What does this image show?"},
          {"type": "image_url", "image_url": {"url": "document.png"}}
        ]
      }
    ]
  }'
```

---

## Configuration (`config.yaml`)

`gz-aplai` searches for `config.yaml` in:
1. Custom path supplied via `./gz-aplai --config <path>`
2. Current working directory (`./config.yaml`)
3. Executable binary directory

### Example `config.yaml`:
```yaml
server:
  host: "127.0.0.1"
  port: 8080

logger:
  level: "INFO"
  console_enabled: true
  file_enabled: true
  dir: "logs"
  filename: "aplai.log"
  max_size_mb: 10
  max_backups: 5

engine:
  instructions: "You are a helpful on-device AI assistant."
```

---

## Project Structure

```
gz-aplai/
├── Makefile                 # Unified build & test automation harness
├── apple_ai_bridge.swift    # Swift dynamic bridge (FoundationModels & Vision)
├── apple_ai_bridge.h        # Clean C ABI interface header
├── src/
│   ├── main.goose           # CLI entry point and dispatch
│   ├── cli.goose            # CLI argument parsing
│   ├── repl.goose           # ANSI colorized interactive REPL
│   ├── server.goose         # OpenAI-compatible POSIX HTTP completions server
│   ├── engine.goose         # Model session & multimodal inference coordinator
│   ├── config.goose         # YAML configuration reader
│   └── logger.goose         # Structured console & rotating file logging
├── test/
│   ├── test_all.goose       # Complete automated test runner
│   ├── test_cli.goose       # CLI & stdin pipeline tests
│   ├── test_repl.goose      # REPL parser & command tests
│   ├── test_server.goose    # HTTP endpoint & SSE streaming tests
│   ├── test_engine.goose    # Engine session tests
│   ├── test_config.goose    # YAML configuration tests
│   └── test_logger.goose    # Structured logging tests
├── LICENSE                  # Apache License 2.0
└── README.md                # Project documentation
```

---

## License

Licensed under the Apache License, Version 2.0 (the "License"). You may obtain a copy of the License in the [LICENSE](LICENSE) file or at:

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)
