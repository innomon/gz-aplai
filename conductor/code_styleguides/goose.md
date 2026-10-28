# Goose Language Style Guide

## 1. Principles & Memory Management
- **Zero-Heap Idioms:** Prefer contiguous flat arrays (`u8[>..]`, fixed-size arrays) and references (`&`) rather than complex pointer graphs.
- **Slice Usage:** Pass slices (`const u8[:]` or `u8[:]`) to functions for string/buffer read-only views without copying data.
- **Builders:** Use `u8[>..]&` builders for accumulating output or passing to C string functions.
- **Guard Clauses:** Prefer `guard condition else { return ...; }` or early returns to keep main logic unindented.

## 2. Naming Conventions
- **Functions:** Use `snake_case` for function names (`fn process_prompt(...)`).
- **Types & Structs:** Use `PascalCase` for struct and enum names (`struct Config`, `struct ChatMessage`).
- **Variables & Fields:** Use `snake_case` for local variables and struct fields (`var max_tokens: i32`).
- **Constants:** Use `SCREAMING_SNAKE_CASE` or `PascalCase` for constants (`let DEFAULT_PORT = 8080`).

## 3. C Interoperability (FFI)
- Use explicit `extern fn` signatures matching C types (e.g., `extern fn apple_ai_generate(prompt: const u8[:], out: u8[>..]&) -> bool;`).
- Always pair external allocations with appropriate cleanup functions or leverage builder appending (`gs_bld_append`).

## 4. Error Handling
- Use multi-value return tuples (e.g., `fn parse_header(...) -> (Header, bool)`) or sentinel error codes with early returns.
- Provide descriptive terminal messages on errors rather than panics.
