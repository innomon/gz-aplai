import std;
import os;
import config from "../src";
import logger from "../src";
import engine from "../src";
import server from "../src";

fn main() {
    print("Testing server JSON parsing...");

    let payload = "{\"model\":\"apple-intelligence\",\"messages\":[{\"role\":\"user\",\"content\":\"Explain gravity in 5 words\"}],\"stream\":false}";
    var prompt: u8[>..] = [];
    let ok = extract_json_string(payload, "\"content\"", prompt);
    assert(ok == true);
    assert(prompt == "Explain gravity in 5 words");
    print("PASS: extract_json_string extracted prompt: ", prompt);

    let stream_payload = "{\"model\":\"apple-intelligence\",\"messages\":[{\"role\":\"user\",\"content\":\"Hello\"}],\"stream\":true}";
    var stream_prompt: u8[>..] = [];
    assert(extract_json_string(stream_payload, "\"content\"", stream_prompt));
    assert(stream_prompt == "Hello");
    print("PASS: extract_json_string stream prompt extracted.");

    print("ALL SERVER TESTS PASSED.");
}
