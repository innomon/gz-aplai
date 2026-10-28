import std;
import os;

extern fn apple_ai_is_available() -> bool;
extern fn apple_ai_init_session(instructions: const u8[:]) -> i64;
extern fn apple_ai_close_session(session_handle: i64);
extern fn apple_ai_generate(session_handle: i64, prompt: const u8[:], out: u8[>..]&) -> bool;
extern fn apple_ai_generate_chat(session_handle: i64, prompt: const u8[:], out: u8[>..]&) -> bool;
extern fn apple_ai_generate_sse(session_handle: i64, client_fd: i32, prompt: const u8[:], out: u8[>..]&) -> bool;

struct Engine {
    session_handle: i64,
    available: bool,
}

fn init_engine(instructions: const u8[:]) -> Engine {
    let avail = apple_ai_is_available();
    var handle: i64 = 0;
    if avail {
        handle = apple_ai_init_session(instructions);
    }
    return Engine {
        session_handle: handle,
        available: avail,
    };
}

fn close_engine(e: Engine&) {
    if e.session_handle != 0 {
        apple_ai_close_session(e.session_handle);
    }
}

fn engine_generate(e: Engine&, prompt: const u8[:], out: u8[>..]&) -> bool {
    if !e.available || e.session_handle == 0 {
        out.append("ERROR: Apple AI is not available on this system.");
        return false;
    }
    return apple_ai_generate(e.session_handle, prompt, out);
}

fn engine_generate_chat(e: Engine&, prompt: const u8[:], out: u8[>..]&) -> bool {
    if !e.available || e.session_handle == 0 {
        out.append("ERROR: Apple AI is not available on this system.");
        return false;
    }
    return apple_ai_generate_chat(e.session_handle, prompt, out);
}

fn engine_generate_sse(e: Engine&, client_fd: i32, prompt: const u8[:], out: u8[>..]&) -> bool {
    if !e.available || e.session_handle == 0 {
        out.append("ERROR: Apple AI is not available on this system.");
        return false;
    }
    return apple_ai_generate_sse(e.session_handle, client_fd, prompt, out);
}
