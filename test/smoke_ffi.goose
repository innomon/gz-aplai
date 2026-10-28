// FFI Smoke Test for gz-aplai
import std;

extern fn apple_ai_is_available() -> bool;
extern fn apple_ai_init_session(instructions: const u8[:]) -> i64;
extern fn apple_ai_close_session(session_handle: i64);
extern fn apple_ai_generate(session_handle: i64, prompt: const u8[:], out: u8[>..]&) -> bool;

fn main() {
    print("Testing Apple AI Bridge FFI...");
    let available = apple_ai_is_available();
    print("Apple AI is available: ", available);

    let session = apple_ai_init_session("You are a helpful assistant.");
    print("Session handle: ", session);
    assert(session != 0);

    apple_ai_close_session(session);
    print("Session closed successfully.");
    print("PASS: FFI smoke test succeeded.");
}
