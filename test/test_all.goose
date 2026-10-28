import std;
import os;
import config from "../src";
import logger from "../src";
import engine from "../src";
import cli from "../src";
import repl from "../src";
import server from "../src";

fn main() {
    print("=== Running Complete gz-aplai Test Suite ===");

    // 1. Config tests
    print("\n[1/6] Running Config Tests...");
    let def = default_config();
    assert(def.server.port == 8080);
    let parsed = parse_config("server:\n  port: 9999\n");
    assert(parsed.server.port == 9999);
    print("Config tests passed.");

    // 2. Logger tests
    print("\n[2/6] Running Logger Tests...");
    var lcfg = default_config();
    lcfg.logger.console_enabled = false;
    lcfg.logger.file_enabled = true;
    lcfg.logger.dir = "test_logs";
    lcfg.logger.filename = "suite.log";
    let log = init_logger(lcfg);
    log_info(log, "Suite log test message");
    assert(file_exists("test_logs/suite.log"));
    delete_file("test_logs/suite.log");
    delete_dir("test_logs");
    print("Logger tests passed.");

    // 3. Engine tests
    print("\n[3/6] Running Engine Tests...");
    let eng = init_engine("You are a helpful test assistant.");
    assert(eng.available == true);
    assert(eng.session_handle != 0);
    var resp: u8[>..] = [];
    assert(engine_generate(eng, "Reply with 'ok'", resp));
    assert(resp.len > 0);
    print("Model inference result: [", resp, "]");
    print("Engine tests passed.");

    // 4. CLI & REPL tests
    print("\n[4/6] Running CLI & REPL Tests...");
    var mock_args: const u8[:][>..] = [];
    mock_args.push("gz-aplai");
    mock_args.push("--chat");
    let opts = parse_cli_args(mock_args);
    assert(opts.chat == true);
    assert(is_exit_command("/exit") == true);
    assert(is_exit_command("quit") == true);
    assert(is_exit_command("hello") == false);
    assert(is_help_command("/") == true);
    assert(is_help_command("/help") == true);
    print("CLI and REPL tests passed.");

    // 5. Server tests
    print("\n[5/6] Running Server Tests...");
    let payload = "{\"messages\":[{\"role\":\"user\",\"content\":\"Explain gravity\"}],\"stream\":true}";
    var extracted_prompt: u8[>..] = [];
    assert(extract_json_string(payload, "\"content\"", extracted_prompt));
    assert(extracted_prompt == "Explain gravity");
    print("Server tests passed.");

    // 6. Multimodal Vision tests
    print("\n[6/6] Running Multimodal Vision Tests...");
    let vision_json = "{\"messages\":[{\"role\":\"user\",\"content\":[{\"type\":\"text\",\"text\":\"Read invoice\"},{\"type\":\"image_url\",\"image_url\":{\"url\":\"test_sample.png\"}}]}]}";
    var v_prompt: u8[>..] = [];
    var v_url: u8[>..] = [];
    assert(extract_json_string(vision_json, "\"text\"", v_prompt));
    assert(v_prompt == "Read invoice");
    assert(extract_image_url(vision_json, v_url));
    assert(v_url == "test_sample.png");

    var v_resp: u8[>..] = [];
    assert(engine_generate_multimodal(eng, "test_sample.png", "What text is shown in the image?", v_resp));
    assert(find(v_resp, "APLAI") >= 0);
    print("Vision multimodal generation result: [", v_resp, "]");
    print("Multimodal Vision tests passed.");

    close_engine(eng);
    print("\n=== ALL 6 TEST SUITES PASSED SUCCESSFULLY ===");
}
