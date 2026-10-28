import std;
import os;
import engine from "../src";
import logger from "../src";

fn is_exit_command(input: const u8[:]) -> bool {
    let t = trim(input);
    return t == "/exit" || t == "/quit" || t == "exit" || t == "quit";
}

fn run_repl(eng: Engine&, log: Logger&) {
    write_stdout("\x1b[1;35m--- APLAI Local Interactive REPL (Apple Silicon) ---\x1b[0m\n");
    write_stdout("Type your prompt and press Enter. Commands: /exit, /quit\n\n");

    loop {
        write_stdout("\x1b[1;36muser>\x1b[0m ");
        flush_stdout();

        var line: u8[>..] = [];
        let ok = read_line(line);
        if !ok {
            // EOF (Ctrl-D)
            write_stdout("\nGoodbye!\n");
            break;
        }

        let trimmed = trim(line);
        if trimmed.len == 0 {
            continue;
        }

        if is_exit_command(trimmed) {
            write_stdout("Goodbye!\n");
            break;
        }

        log_debug(log, str("REPL prompt: ", trimmed));
        write_stdout("\x1b[1;32massistant>\x1b[0m ");
        flush_stdout();

        var response: u8[>..] = [];
        let gen_ok = engine_generate_chat(eng, trimmed, response);
        write_stdout("\n\n");

        if !gen_ok {
            log_error(log, "Failed to generate response in REPL");
        }
    }
}
