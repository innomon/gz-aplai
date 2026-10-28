import std;
import os;
import cli from "../src";

fn main() {
    print("Testing CLI parser...");

    // Test 1: Flag parsing
    var args1 = args();
    args1.resize(0);
    args1.push("gz-aplai");
    args1.push("--chat");
    args1.push("--config");
    args1.push("custom.yaml");
    let opts1 = parse_cli_args(args1);
    assert(opts1.chat == true);
    assert(opts1.server == false);
    assert(opts1.config_path == "custom.yaml");
    assert(opts1.has_prompt == false);
    print("PASS: --chat and --config parsing verified.");

    // Test 2: Server flag
    var args2 = args();
    args2.resize(0);
    args2.push("gz-aplai");
    args2.push("--server");
    let opts2 = parse_cli_args(args2);
    assert(opts2.server == true);
    assert(opts2.chat == false);
    print("PASS: --server flag verified.");

    // Test 3: Positional prompt
    var args3 = args();
    args3.resize(0);
    args3.push("gz-aplai");
    args3.push("what");
    args3.push("is");
    args3.push("the");
    args3.push("capital");
    args3.push("of");
    args3.push("france?");
    let opts3 = parse_cli_args(args3);
    assert(opts3.has_prompt == true);
    assert(opts3.prompt == "what is the capital of france?");
    print("PASS: Positional prompt joining verified.");

    // Test 4: Help flag
    var args4: const u8[:][>..] = [];
    args4.push("gz-aplai");
    args4.push("-h");
    let opts4 = parse_cli_args(args4);
    assert(opts4.show_help == true);
    print("PASS: Help flag verified.");

    // Test 5: Image flag
    var args5: const u8[:][>..] = [];
    args5.push("gz-aplai");
    args5.push("--image");
    args5.push("sample.png");
    args5.push("describe");
    args5.push("this");
    let opts5 = parse_cli_args(args5);
    assert(opts5.has_image == true);
    assert(opts5.image_path == "sample.png");
    assert(opts5.prompt == "describe this");
    print("PASS: --image flag verified.");

    print("ALL CLI TESTS PASSED.");
}
