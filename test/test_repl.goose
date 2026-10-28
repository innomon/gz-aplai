import std;
import os;
import config from "../src";
import logger from "../src";
import engine from "../src";
import repl from "../src";

fn main() {
    print("Testing REPL module...");

    assert(is_exit_command("/exit") == true);
    assert(is_exit_command("/quit") == true);
    assert(is_exit_command("exit") == true);
    assert(is_exit_command("quit") == true);
    assert(is_exit_command("  /exit  ") == true);
    assert(is_exit_command("hello world") == false);
    assert(is_exit_command("/explain") == false);
    print("PASS: is_exit_command exit commands verified.");

    assert(is_help_command("/") == true);
    assert(is_help_command("/help") == true);
    assert(is_help_command("help") == true);
    assert(is_help_command("/?") == true);
    assert(is_help_command("hello") == false);
    print("PASS: is_help_command help commands verified.");

    print("ALL REPL TESTS PASSED.");
}
