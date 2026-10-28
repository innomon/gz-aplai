import std;
import os;
import config from "../src";

struct Logger {
    level: u8[..32],
    console_enabled: bool,
    file_enabled: bool,
    file_path: u8[..256],
}

fn init_logger(cfg: Config&) -> Logger {
    var l = Logger {
        level: cfg.logger.level,
        console_enabled: cfg.logger.console_enabled,
        file_enabled: cfg.logger.file_enabled,
        file_path: "",
    };

    if l.file_enabled {
        if cfg.logger.dir.len > 0 && !file_exists(cfg.logger.dir) && !is_dir(cfg.logger.dir) {
            make_dir(cfg.logger.dir);
        }
        var p: u8[>..] = [];
        if cfg.logger.dir.len > 0 {
            p.append(cfg.logger.dir);
            p.append("/");
        }
        p.append(cfg.logger.filename);
        l.file_path = p;
    }
    return l;
}

fn log_write(l: Logger&, level: const u8[:], msg: const u8[:]) {
    let now = time();

    // 1. Console Output
    if l.console_enabled {
        var console_line: u8[>..] = [];
        console_line.append("[");
        format_flt(console_line, now, 2);
        console_line.append("] [");
        console_line.append(level);
        console_line.append("] ");
        console_line.append(msg);
        console_line.append("\n");
        write_stderr(console_line);
    }

    // 2. Structured JSONL File Output
    if l.file_enabled && l.file_path.len > 0 {
        var json_line: u8[>..] = [];
        json_line.append("{\"timestamp\":");
        format_flt(json_line, now, 4);
        json_line.append(",\"level\":\"");
        json_line.append(level);
        json_line.append("\",\"message\":\"");

        // Simple JSON escape
        for i in msg.len {
            let c = msg[i];
            if c == '"' {
                json_line.append("\\\"");
            } else if c == '\\' {
                json_line.append("\\\\");
            } else if c == '\n' {
                json_line.append("\\n");
            } else if c == '\r' {
                json_line.append("\\r");
            } else if c == '\t' {
                json_line.append("\\t");
            } else {
                json_line.push(c);
            }
        }
        json_line.append("\"}\n");
        append_file(l.file_path, json_line);
    }
}

fn log_info(l: Logger&, msg: const u8[:]) {
    log_write(l, "INFO", msg);
}

fn log_warn(l: Logger&, msg: const u8[:]) {
    log_write(l, "WARN", msg);
}

fn log_error(l: Logger&, msg: const u8[:]) {
    log_write(l, "ERROR", msg);
}

fn log_debug(l: Logger&, msg: const u8[:]) {
    if l.level == "DEBUG" {
        log_write(l, "DEBUG", msg);
    }
}
