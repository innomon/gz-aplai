import std;
import os;
import config from "../src";
import logger from "../src";

fn main() {
    print("Testing logger module...");

    var cfg = default_config();
    cfg.logger.console_enabled = true;
    cfg.logger.file_enabled = true;
    cfg.logger.dir = "test_logs";
    cfg.logger.filename = "test_run.log";

    // Clean any previous test log file
    let full_path = "test_logs/test_run.log";
    if file_exists(full_path) {
        delete_file(full_path);
    }

    let log = init_logger(cfg);
    assert(log.console_enabled == true);
    assert(log.file_enabled == true);
    assert(log.file_path == full_path);

    log_info(log, "Initial testing message");
    log_warn(log, "Warning message for test");
    log_error(log, "Error message with \"quotes\" and newline");

    // Verify file was written and contains structured JSONL
    assert(file_exists(full_path));
    var content: u8[>..] = [];
    assert(read_file(full_path, content));
    assert(content.len > 0);
    assert(find(content, "\"level\":\"INFO\"") >= 0);
    assert(find(content, "\"level\":\"WARN\"") >= 0);
    assert(find(content, "\"level\":\"ERROR\"") >= 0);
    assert(find(content, "Initial testing message") >= 0);

    // Clean up test file and dir
    delete_file(full_path);
    delete_dir("test_logs");

    print("ALL LOGGER TESTS PASSED.");
}
