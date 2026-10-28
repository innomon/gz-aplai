import std;
import os;
import config from "../src";
import logger from "../src";
import engine from "../src";
import server from "../src";

fn main() {
    print("Testing server JSON parsing with multimodal vision...");

    // Test 1: Standard text payload
    let payload = "{\"model\":\"apple-intelligence\",\"messages\":[{\"role\":\"user\",\"content\":\"Explain gravity in 5 words\"}],\"stream\":false}";
    var prompt: u8[>..] = [];
    let ok = extract_json_string(payload, "\"content\"", prompt);
    assert(ok == true);
    assert(prompt == "Explain gravity in 5 words");
    print("PASS: extract_json_string extracted prompt.");

    // Test 2: OpenAI Multimodal Vision payload
    let vision_payload = "{\"model\":\"apple-intelligence\",\"messages\":[{\"role\":\"user\",\"content\":[{\"type\":\"text\",\"text\":\"What does the sign say?\"},{\"type\":\"image_url\",\"image_url\":{\"url\":\"/path/to/sample.png\"}}]}],\"stream\":false}";
    var vision_prompt: u8[>..] = [];
    assert(extract_json_string(vision_payload, "\"text\"", vision_prompt));
    assert(vision_prompt == "What does the sign say?");

    var vision_url: u8[>..] = [];
    assert(extract_image_url(vision_payload, vision_url));
    assert(vision_url == "/path/to/sample.png");
    print("PASS: OpenAI vision content text and image_url extracted successfully.");

    print("ALL SERVER VISION TESTS PASSED.");
}
