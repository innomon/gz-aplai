import std;
import os;
import config from "../src";
import logger from "../src";
import engine from "../src";

extern fn net_listen(port: i32) -> i32;
extern fn net_accept(server_fd: i32) -> i32;
extern fn net_read(client_fd: i32, out: u8[>..]&) -> i64;
extern fn net_write(client_fd: i32, data: const u8[:]) -> i64;
extern fn net_close(client_fd: i32);

fn extract_json_string(body: const u8[:], key: const u8[:], out: u8[>..]&) -> bool {
    let key_idx = find(body, key);
    if key_idx < 0 {
        return false;
    }
    let after_key = body[key_idx + key.len..];
    let quote_start = find(after_key, "\"");
    if quote_start < 0 {
        return false;
    }
    let val_start = quote_start + 1;
    var i = val_start;
    var escaped = false;
    while i < after_key.len {
        let c = after_key[i];
        if escaped {
            escaped = false;
        } else if c == '\\' {
            escaped = true;
        } else if c == '"' {
            // Found closing unescaped quote
            let raw_val = after_key[val_start..i];
            out.append(raw_val);
            return true;
        }
        i++;
    }
    return false;
}

fn handle_client_request(client_fd: i32, req: const u8[:], eng: Engine&, log: Logger&) {
    if starts_with(req, "GET /health") || starts_with(req, "GET / HTTP") {
        let resp = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: 15\r\n\r\n{\"status\":\"ok\"}";
        net_write(client_fd, resp);
        return;
    }

    if !starts_with(req, "POST /v1/chat/completions") {
        let not_found = "HTTP/1.1 404 Not Found\r\nContent-Type: application/json\r\nContent-Length: 43\r\n\r\n{\"error\":{\"message\":\"Endpoint not found\"}}";
        net_write(client_fd, not_found);
        return;
    }

    // Find body after double newline
    var body_idx = find(req, "\r\n\r\n");
    var header_len = 4;
    if body_idx < 0 {
        body_idx = find(req, "\n\n");
        header_len = 2;
    }

    let body = if body_idx >= 0 { req[body_idx + header_len..] } else { req[req.len..] };

    // Extract prompt from "content"
    var prompt: u8[>..] = [];
    if !extract_json_string(body, "\"content\"", prompt) {
        // Fallback: check prompt key
        extract_json_string(body, "\"prompt\"", prompt);
    }

    if prompt.len == 0 {
        let bad_req = "HTTP/1.1 400 Bad Request\r\nContent-Type: application/json\r\nContent-Length: 51\r\n\r\n{\"error\":{\"message\":\"Missing messages or prompt\"}}";
        net_write(client_fd, bad_req);
        return;
    }

    let is_stream = (find(body, "\"stream\": true") >= 0 || find(body, "\"stream\":true") >= 0);

    if is_stream {
        log_info(log, str("Streaming SSE completion for prompt: ", prompt));
        let sse_headers = "HTTP/1.1 200 OK\r\nContent-Type: text/event-stream\r\nCache-Control: no-cache\r\nConnection: keep-alive\r\n\r\n";
        net_write(client_fd, sse_headers);
        var sse_acc: u8[>..] = [];
        engine_generate_sse(eng, client_fd, prompt, sse_acc);
    } else {
        log_info(log, str("Generating synchronous completion for prompt: ", prompt));
        var gen_resp: u8[>..] = [];
        let ok = engine_generate(eng, prompt, gen_resp);

        var json_body: u8[>..] = [];
        json_body.append("{\"id\":\"chatcmpl-aplai\",\"object\":\"chat.completion\",\"created\":");
        format_flt(json_body, time(), 0);
        json_body.append(",\"model\":\"apple-intelligence\",\"choices\":[{\"index\":0,\"message\":{\"role\":\"assistant\",\"content\":\"");

        // Escape JSON response
        for i in gen_resp.len {
            let c = gen_resp[i];
            if c == '"' { json_body.append("\\\""); }
            else if c == '\\' { json_body.append("\\\\"); }
            else if c == '\n' { json_body.append("\\n"); }
            else if c == '\r' { json_body.append("\\r"); }
            else if c == '\t' { json_body.append("\\t"); }
            else { json_body.push(c); }
        }
        json_body.append("\"},\"finish_reason\":\"stop\"}]}");

        var http_resp: u8[>..] = [];
        http_resp.append("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: ");
        format(http_resp, json_body.len);
        http_resp.append("\r\n\r\n");
        http_resp.append(json_body);

        net_write(client_fd, http_resp);
    }
}

fn run_server(cfg: Config&, eng: Engine&, log: Logger&) {
    let port = cfg.server.port;
    let server_fd = net_listen(port);
    if server_fd < 0 {
        log_error(log, str("Failed to bind and listen on port ", port));
        return;
    }

    log_info(log, str("APLAI OpenAI-compatible HTTP server listening on http://", cfg.server.host, ":", port));
    write_stdout(str("APLAI OpenAI server running at http://", cfg.server.host, ":", port, "\n"));
    flush_stdout();

    loop {
        let client_fd = net_accept(server_fd);
        if client_fd < 0 {
            continue;
        }

        var req_buf: u8[>..] = [];
        let n = net_read(client_fd, req_buf);
        if n > 0 {
            handle_client_request(client_fd, req_buf, eng, log);
        }
        net_close(client_fd);
    }
}
