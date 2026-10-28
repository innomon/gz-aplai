import std;
import os;
import config from ".";
import logger from ".";
import engine from ".";
import cli from ".";
import repl from ".";
import server from ".";

fn main() {
    let raw_args = args();
    let opts = parse_cli_args(raw_args);

    if opts.show_help {
        print_help();
        return;
    }

    let cfg = load_config(opts.config_path);
    let log = init_logger(cfg);

    let eng = init_engine(cfg.engine.instructions);
    if !eng.available {
        write_stderr("ERROR: Apple Silicon FoundationModels is not available on this machine.\n");
        return;
    }

    if opts.chat {
        // Interactive REPL chat mode
        run_repl(eng, log);
        close_engine(eng);
        return;
    }

    if opts.server {
        // OpenAI-compatible HTTP server mode
        run_server(cfg, eng, log);
        close_engine(eng);
        return;
    }

    var input_prompt: u8[>..] = [];
    if get_input_prompt(opts, input_prompt) {
        // Single prompt or piped stdin: UNIX pipeline mode (pure stdout)
        log_debug(log, str("Executing prompt: ", input_prompt));
        var response: u8[>..] = [];
        let ok = engine_generate(eng, input_prompt, response);
        if ok {
            write_stdout(response);
            write_stdout("\n");
        } else {
            write_stderr(str("Error generating response: ", response, "\n"));
        }
        close_engine(eng);
        return;
    }

    if !opts.server {
        // No flags or input passed: show help
        print_help();
    }
    close_engine(eng);
}
