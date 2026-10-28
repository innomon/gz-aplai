import std;
import os;

struct ServerConfig {
    host: u8[..64],
    port: i32,
}

struct LoggerConfig {
    level: u8[..32],
    console_enabled: bool,
    file_enabled: bool,
    dir: u8[..128],
    filename: u8[..128],
    max_size_mb: i32,
    max_backups: i32,
}

struct EngineConfig {
    instructions: u8[..512],
}

struct Config {
    server: ServerConfig,
    logger: LoggerConfig,
    engine: EngineConfig,
}

fn default_config() -> Config {
    return Config {
        server: ServerConfig {
            host: "127.0.0.1",
            port: 8080,
        },
        logger: LoggerConfig {
            level: "INFO",
            console_enabled: true,
            file_enabled: true,
            dir: "logs",
            filename: "aplai.log",
            max_size_mb: 10,
            max_backups: 5,
        },
        engine: EngineConfig {
            instructions: "You are a helpful on-device AI assistant.",
        },
    };
}

fn parse_config(content: const u8[:]) -> Config {
    var cfg = default_config();
    var current_section: u8[>..] = [];

    each_split(content, '\n') {
        let raw_line = it;
        let line = trim(raw_line);
        if line.len > 0 && !starts_with(line, "#") {
            let colon_idx = find(line, ":");
            if colon_idx >= 0 {
                let key = trim(line[..colon_idx]);
                let val = trim(line[colon_idx + 1..]);

                if val.len == 0 {
                    // Section header like "server:", "logger:", "engine:"
                    current_section.resize(0);
                    current_section.append(key);
                } else {
                    // Strip quotes if present
                    var clean_val = val;
                    if (starts_with(clean_val, "\"") && ends_with(clean_val, "\"")) ||
                       (starts_with(clean_val, "'") && ends_with(clean_val, "'")) {
                        if clean_val.len >= 2 {
                            clean_val = clean_val[1..clean_val.len - 1];
                        }
                    }

                    if current_section == "server" {
                        if key == "host" {
                            cfg.server.host = clean_val;
                        } else if key == "port" {
                            let p, ok = parse_int(clean_val);
                            if ok { cfg.server.port = p as i32; }
                        }
                    } else if current_section == "logger" {
                        if key == "level" {
                            cfg.logger.level = clean_val;
                        } else if key == "console_enabled" {
                            cfg.logger.console_enabled = (clean_val == "true" || clean_val == "1");
                        } else if key == "file_enabled" {
                            cfg.logger.file_enabled = (clean_val == "true" || clean_val == "1");
                        } else if key == "dir" {
                            cfg.logger.dir = clean_val;
                        } else if key == "filename" {
                            cfg.logger.filename = clean_val;
                        } else if key == "max_size_mb" {
                            let s, ok = parse_int(clean_val);
                            if ok { cfg.logger.max_size_mb = s as i32; }
                        } else if key == "max_backups" {
                            let b, ok = parse_int(clean_val);
                            if ok { cfg.logger.max_backups = b as i32; }
                        }
                    } else if current_section == "engine" {
                        if key == "instructions" {
                            cfg.engine.instructions = clean_val;
                        }
                    } else {
                        // Top level fallback
                        if key == "host" {
                            cfg.server.host = clean_val;
                        } else if key == "port" {
                            let p, ok = parse_int(clean_val);
                            if ok { cfg.server.port = p as i32; }
                        } else if key == "instructions" {
                            cfg.engine.instructions = clean_val;
                        }
                    }
                }
            }
        }
    };
    return cfg;
}

fn load_config(custom_path: const u8[:]) -> Config {
    var content: u8[>..] = [];

    // 1. Explicit path
    if custom_path.len > 0 {
        if file_exists(custom_path) && read_file(custom_path, content) {
            return parse_config(content);
        } else {
            write_stderr(str("Warning: explicit config file not found: ", custom_path, ", using defaults\n"));
            return default_config();
        }
    }

    // 2. Current working directory ./config.yaml
    if file_exists("./config.yaml") && read_file("./config.yaml", content) {
        return parse_config(content);
    }

    // 3. Executable / resource directory
    var exe_cfg: u8[>..] = [];
    exe_cfg.append(resource_dir());
    exe_cfg.append("config.yaml");
    if file_exists(exe_cfg) && read_file(exe_cfg, content) {
        return parse_config(content);
    }

    // Default fallback
    return default_config();
}
