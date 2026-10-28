import std;
import os;

extern fn apple_ai_is_available() -> bool;
extern fn apple_ai_init_session(instructions: const u8[:]) -> i64;
extern fn apple_ai_close_session(session_handle: i64);
extern fn apple_ai_generate(session_handle: i64, prompt: const u8[:], out: u8[>..]&) -> bool;
extern fn apple_ai_generate_chat(session_handle: i64, prompt: const u8[:], out: u8[>..]&) -> bool;
extern fn apple_ai_generate_sse(session_handle: i64, client_fd: i32, prompt: const u8[:], out: u8[>..]&) -> bool;
extern fn apple_ai_process_image(image_source: const u8[:], out_desc: u8[>..]&) -> bool;

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

fn engine_generate_multimodal(e: Engine&, image_source: const u8[:], user_prompt: const u8[:], out: u8[>..]&) -> bool {
    if !e.available || e.session_handle == 0 {
        out.append("ERROR: Apple AI is not available on this system.");
        return false;
    }

    var visual_context: u8[>..] = [];
    let ok = apple_ai_process_image(image_source, visual_context);
    if !ok {
        out.append("ERROR: Failed to process image: ");
        out.append(visual_context);
        return false;
    }

    var unified_prompt: u8[>..] = [];
    unified_prompt.append(visual_context);
    unified_prompt.append("\n\nBased on the visual context above, answer this user question:\n");
    unified_prompt.append(user_prompt);

    return engine_generate(e, unified_prompt, out);
}

fn engine_generate_multimodal_sse(e: Engine&, client_fd: i32, image_source: const u8[:], user_prompt: const u8[:], out: u8[>..]&) -> bool {
    if !e.available || e.session_handle == 0 {
        out.append("ERROR: Apple AI is not available on this system.");
        return false;
    }

    var visual_context: u8[>..] = [];
    let ok = apple_ai_process_image(image_source, visual_context);
    if !ok {
        out.append("ERROR: Failed to process image: ");
        out.append(visual_context);
        return false;
    }

    var unified_prompt: u8[>..] = [];
    unified_prompt.append(visual_context);
    unified_prompt.append("\n\nBased on the visual context above, answer this user question:\n");
    unified_prompt.append(user_prompt);

    return engine_generate_sse(e, client_fd, unified_prompt, out);
}
