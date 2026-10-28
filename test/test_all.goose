import std;
import os;
import config from "../src";
import logger from "../src";
import engine from "../src";

fn main() {
    print("=== Running Complete gz-aplai Test Suite ===");

    // 1. Config tests
    print("\n[1/3] Running Config Tests...");
    let def = default_config();
    assert(def.server.port == 8080);
    let parsed = parse_config("server:\n  port: 9999\n");
    assert(parsed.server.port == 9999);
    print("Config tests passed.");

    // 2. Logger tests
    print("\n[2/3] Running Logger Tests...");
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
    print("\n[3/3] Running Engine Tests...");
    let eng = init_engine("You are a helpful test assistant.");
    assert(eng.available == true);
    assert(eng.session_handle != 0);
    var resp: u8[>..] = [];
    assert(engine_generate(eng, "Reply with 'ok'", resp));
    assert(resp.len > 0);
    print("Model inference result: [", resp, "]");
    close_engine(eng);
    print("Engine tests passed.");

    print("\n=== ALL TESTS PASSED SUCCESSFULLY ===");
}
