import std;
import os;

extern fn is_stdin_pipe() -> bool;

struct CliOptions {
    chat: bool,
    server: bool,
    config_path: u8[..256],
    prompt: u8[..4096],
    has_prompt: bool,
    show_help: bool,
}

fn print_help() {
    write_stdout("APLAI Goose (gz-aplai) - Apple Silicon Local AI Runner\n\n");
    write_stdout("Usage:\n");
    write_stdout("  gz-aplai [prompt]            Run single prompt in UNIX pipeline/CLI mode\n");
    write_stdout("  gz-aplai --chat              Start interactive REPL chat session\n");
    write_stdout("  gz-aplai --server            Start OpenAI-compatible HTTP server\n");
    write_stdout("  gz-aplai --config <path>     Specify custom configuration file path\n");
    write_stdout("  gz-aplai --help, -h          Show this help message\n\n");
    write_stdout("Piping:\n");
    write_stdout("  echo \"Explain quantum computing\" | gz-aplai\n\n");
}

fn parse_cli_args(args_list: const u8[:][>..]&) -> CliOptions {
    var opts = CliOptions {
        chat: false,
        server: false,
        config_path: "",
        prompt: "",
        has_prompt: false,
        show_help: false,
    };

    var prompt_builder: u8[>..] = [];
    var i = 1;
    while i < args_list.len {
        let arg = args_list[i];
        if arg == "--chat" || arg == "-chat" {
            opts.chat = true;
        } else if arg == "--server" || arg == "-server" {
            opts.server = true;
        } else if arg == "--help" || arg == "-h" || arg == "-help" {
            opts.show_help = true;
        } else if arg == "--config" || arg == "-config" {
            if i + 1 < args_list.len {
                i++;
                opts.config_path = args_list[i];
            }
        } else if starts_with(arg, "--config=") {
            opts.config_path = arg[9..];
        } else if starts_with(arg, "-") {
            write_stderr(str("Unknown flag: ", arg, "\n"));
            opts.show_help = true;
        } else {
            if prompt_builder.len > 0 {
                prompt_builder.append(" ");
            }
            prompt_builder.append(arg);
            opts.has_prompt = true;
        }
        i++;
    }

    if prompt_builder.len > 0 {
        opts.prompt = prompt_builder;
    }
    return opts;
}

fn get_input_prompt(opts: CliOptions&, out: u8[>..]&) -> bool {
    // 1. If explicit argument prompt passed
    if opts.has_prompt && opts.prompt.len > 0 {
        out.append(opts.prompt);
        return true;
    }

    // 2. Check if stdin is piped
    if is_stdin_pipe() {
        var stdin_buf: u8[>..] = [];
        read_stdin(stdin_buf);
        let trimmed = trim(stdin_buf);
        if trimmed.len > 0 {
            out.append(trimmed);
            return true;
        }
    }

    return false;
}
