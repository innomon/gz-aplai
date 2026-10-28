import std;
import os;
import engine from "../src";
import logger from "../src";

fn is_exit_command(input: const u8[:]) -> bool {
    let t = trim(input);
    return t == "/exit" || t == "/quit" || t == "exit" || t == "quit";
}

fn run_repl(eng: Engine&, log: Logger&) {
    write_stdout("\033[1;35m--- APLAI Local Interactive REPL (Apple Silicon) ---\033[0m\n");
    write_stdout("Type your prompt and press Enter. Commands: /exit, /quit\n\n");

    loop {
        write_stdout("\033[1;36muser>\033[0m ");
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
        write_stdout("\033[1;32massistant>\033[0m ");
        flush_stdout();

        var response: u8[>..] = [];
        let gen_ok = engine_generate_chat(eng, trimmed, response);
        write_stdout("\n\n");

        if !gen_ok {
            log_error(log, "Failed to generate response in REPL");
        }
    }
}
