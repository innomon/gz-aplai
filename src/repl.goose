import std;
import os;
import engine from "../src";
import logger from "../src";

fn is_exit_command(input: const u8[:]) -> bool {
    let t = trim(input);
    return t == "/exit" || t == "/quit" || t == "exit" || t == "quit";
}

fn is_help_command(input: const u8[:]) -> bool {
    let t = trim(input);
    return t == "/" || t == "/help" || t == "help" || t == "/?";
}

fn print_repl_help() {
    write_stdout("\x1b[1;33m--- APLAI Interactive REPL Help ---\x1b[0m\n");
    write_stdout("Commands:\n");
    write_stdout("  /, /help, help       Display this help message\n");
    write_stdout("  /clear               Clear the terminal screen\n");
    write_stdout("  /exit, /quit, exit   Exit the interactive chat session\n\n");
    write_stdout("Enter any natural language prompt to generate on-device completions.\n\n");
}

fn run_repl(eng: Engine&, log: Logger&) {
    write_stdout("\x1b[1;35m--- APLAI Local Interactive REPL (Apple Silicon) ---\x1b[0m\n");
    write_stdout("Type your prompt and press Enter. Commands: /, /help, /exit, /quit\n\n");

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

        if is_help_command(trimmed) {
            print_repl_help();
            continue;
        }

        if trimmed == "/clear" || trimmed == "clear" {
            write_stdout("\x1b[2J\x1b[H");
            flush_stdout();
            continue;
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
