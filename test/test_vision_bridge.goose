import std;
import os;

extern fn apple_ai_process_image(image_source: const u8[:], out_desc: u8[>..]&) -> bool;

fn main() {
    print("Testing Vision Image Processor FFI...");

    var desc: u8[>..] = [];
    let ok = apple_ai_process_image("test_sample.png", desc);
    print("Vision process returned: ", ok);
    print("Extracted descriptor:\n", desc);

    assert(ok == true);
    assert(find(desc, "[VISUAL CONTEXT]") >= 0);
    assert(find(desc, "APLAI OCR TEST") >= 0);

    print("PASS: Vision OCR accurately recognized text from image.");
    print("ALL VISION BRIDGE TESTS PASSED.");
}
