import std;
import os;
import config from "../src";

fn main() {
    print("Testing config module...");

    // Test default config
    let def = default_config();
    assert(def.server.host == "127.0.0.1");
    assert(def.server.port == 8080);
    assert(def.logger.console_enabled == true);
    assert(def.logger.max_backups == 5);
    assert(def.engine.instructions == "You are a helpful on-device AI assistant.");
    print("PASS: default_config defaults verified.");

    // Test parse_config with custom YAML content
    let yaml_sample = "server:\n  host: 0.0.0.0\n  port: 9090\n\nlogger:\n  level: DEBUG\n  console_enabled: false\n  max_size_mb: 25\n  max_backups: 10\n\nengine:\n  instructions: Custom instructions for local model\n";
    let parsed = parse_config(yaml_sample);
    assert(parsed.server.host == "0.0.0.0");
    assert(parsed.server.port == 9090);
    assert(parsed.logger.level == "DEBUG");
    assert(parsed.logger.console_enabled == false);
    assert(parsed.logger.max_size_mb == 25);
    assert(parsed.logger.max_backups == 10);
    assert(parsed.engine.instructions == "Custom instructions for local model");
    print("PASS: parse_config parsed YAML correctly.");

    // Test load_config with nonexistent custom file falls back to defaults
    let fallback = load_config("nonexistent_path_xyz.yaml");
    assert(fallback.server.port == 8080);
    print("PASS: load_config fallback verified.");

    print("ALL CONFIG TESTS PASSED.");
}
