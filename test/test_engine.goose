import std;
import os;
import engine from "../src";

fn main() {
    print("Testing engine module...");

    let eng = init_engine("You are a concise testing AI.");
    assert(eng.available == true);
    assert(eng.session_handle != 0);
    print("Engine initialized successfully. Session handle: ", eng.session_handle);

    var response: u8[>..] = [];
    print("Sending prompt 'Say test ok' to local model...");
    let ok = engine_generate(eng, "Say test ok in one word", response);
    print("Generate returned ok: ", ok);
    print("Model response: [", response, "]");
    assert(response.len > 0);

    close_engine(eng);
    print("Engine closed.");
    print("ALL ENGINE TESTS PASSED.");
}
