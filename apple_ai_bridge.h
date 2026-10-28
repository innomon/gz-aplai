#ifndef APPLE_AI_BRIDGE_H
#define APPLE_AI_BRIDGE_H

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <fcntl.h>
#include <errno.h>
#include <pthread.h>

#ifdef __cplusplus
extern "C" {
#endif

// Global execution mutex to serialize Apple Silicon inference calls
static pthread_mutex_t g_inference_mutex = PTHREAD_MUTEX_INITIALIZER;

// Declarations of Swift exported functions
extern int32_t _swift_apple_ai_is_available(void);
extern void* _swift_apple_ai_session_create(const char *instructions);
extern void _swift_apple_ai_session_destroy(void *sessionPtr);
extern char* _swift_apple_ai_respond(void *sessionPtr, const char *prompt);
typedef void (*AppleAITokenCallback)(const char *token, int32_t len, void *userData);
extern char* _swift_apple_ai_respond_stream(void *sessionPtr, const char *prompt, AppleAITokenCallback callback, void *userData);
extern void _swift_apple_ai_free_string(char *str);
extern char* _swift_apple_ai_process_image(const char *imageSource);

// C helper for null-terminating a Goose sl_u8 slice into a temporary heap buffer
static inline char* sl_to_cstr(sl_u8 s) {
    char *buf = (char*)malloc(s.len + 1);
    if (!buf) return NULL;
    if (s.len > 0 && s.data) {
        memcpy(buf, s.data, s.len);
    }
    buf[s.len] = '\0';
    return buf;
}

// 1. Availability check
static inline uint8_t apple_ai_is_available(void) {
    return _swift_apple_ai_is_available() != 0 ? 1 : 0;
}

static inline uint8_t is_stdin_pipe(void) {
    return !isatty(STDIN_FILENO) ? 1 : 0;
}

// 2. Session lifecycle
static inline int64_t apple_ai_init_session(sl_u8 instructions) {
    char *inst_cstr = NULL;
    if (instructions.len > 0) {
        inst_cstr = sl_to_cstr(instructions);
    }
    void *session = _swift_apple_ai_session_create(inst_cstr);
    if (inst_cstr) free(inst_cstr);
    return (int64_t)session;
}

static inline void apple_ai_close_session(int64_t handle) {
    if (handle != 0) {
        _swift_apple_ai_session_destroy((void*)handle);
    }
}

// 2b. Vision Image Processing (OCR & Scene understanding)
static inline uint8_t apple_ai_process_image(sl_u8 image_source, gs_rref out_desc) {
    char *src_cstr = sl_to_cstr(image_source);
    if (!src_cstr) return 0;

    char *result = _swift_apple_ai_process_image(src_cstr);
    free(src_cstr);

    if (!result) return 0;

    uint8_t success = 1;
    if (strncmp(result, "ERROR:", 6) == 0) {
        success = 0;
    }

    gs_bld_append(out_desc, result, (int64_t)strlen(result));
    _swift_apple_ai_free_string(result);
    return success;
}

// 3. Batch prompt generation (UNIX pipeline & single prompt)
static inline uint8_t apple_ai_generate(int64_t session_handle, sl_u8 prompt, gs_rref out) {
    char *prompt_cstr = sl_to_cstr(prompt);
    if (!prompt_cstr) return 0;

    pthread_mutex_lock(&g_inference_mutex);
    char *result = _swift_apple_ai_respond((void*)session_handle, prompt_cstr);
    pthread_mutex_unlock(&g_inference_mutex);
    free(prompt_cstr);

    if (!result) return 0;

    uint8_t success = 1;
    if (strncmp(result, "ERROR: ", 7) == 0) {
        success = 0;
    }

    gs_bld_append(out, result, (int64_t)strlen(result));
    _swift_apple_ai_free_string(result);
    return success;
}

// 4. Interactive REPL token streaming
struct ChatStreamContext {
    gs_rref out;
};

static void on_chat_token(const char *token, int32_t len, void *userData) {
    if (!token || len <= 0) return;
    struct ChatStreamContext *ctx = (struct ChatStreamContext*)userData;
    // Print directly to stdout for immediate interactive feedback
    write(STDOUT_FILENO, token, len);
    fsync(STDOUT_FILENO);
    // Also accumulate in Goose builder
    gs_bld_append(ctx->out, token, (int64_t)len);
}

static inline uint8_t apple_ai_generate_chat(int64_t session_handle, sl_u8 prompt, gs_rref out) {
    char *prompt_cstr = sl_to_cstr(prompt);
    if (!prompt_cstr) return 0;

    struct ChatStreamContext ctx;
    ctx.out = out;

    pthread_mutex_lock(&g_inference_mutex);
    char *err = _swift_apple_ai_respond_stream((void*)session_handle, prompt_cstr, on_chat_token, &ctx);
    pthread_mutex_unlock(&g_inference_mutex);
    free(prompt_cstr);

    if (err) {
        fprintf(stderr, "\n%s\n", err);
        _swift_apple_ai_free_string(err);
        return 0;
    }
    return 1;
}

// 5. OpenAI SSE Streaming for HTTP server
struct SseStreamContext {
    int client_fd;
    gs_rref out;
    int index;
};

// JSON string escaping helper
static void sse_escape_json_write(int fd, const char *text, int len) {
    for (int i = 0; i < len; i++) {
        char c = text[i];
        switch (c) {
            case '"':  write(fd, "\\\"", 2); break;
            case '\\': write(fd, "\\\\", 2); break;
            case '\b': write(fd, "\\b", 2); break;
            case '\f': write(fd, "\\f", 2); break;
            case '\n': write(fd, "\\n", 2); break;
            case '\r': write(fd, "\\r", 2); break;
            case '\t': write(fd, "\\t", 2); break;
            default:
                if ((unsigned char)c < 0x20) {
                    char hex[8];
                    int hlen = snprintf(hex, sizeof(hex), "\\u%04x", (unsigned char)c);
                    write(fd, hex, hlen);
                } else {
                    write(fd, &c, 1);
                }
                break;
        }
    }
}

static void on_sse_token(const char *token, int32_t len, void *userData) {
    if (!token || len <= 0) return;
    struct SseStreamContext *ctx = (struct SseStreamContext*)userData;

    // Send SSE event data chunk
    const char *prefix = "data: {\"id\":\"chatcmpl-aplai\",\"object\":\"chat.completion.chunk\",\"model\":\"apple-intelligence\",\"choices\":[{\"index\":0,\"delta\":{\"content\":\"";
    write(ctx->client_fd, prefix, strlen(prefix));
    sse_escape_json_write(ctx->client_fd, token, len);
    const char *suffix = "\"},\"finish_reason\":null}]}\n\n";
    write(ctx->client_fd, suffix, strlen(suffix));

    gs_bld_append(ctx->out, token, (int64_t)len);
}

static inline uint8_t apple_ai_generate_sse(int64_t session_handle, int32_t client_fd, sl_u8 prompt, gs_rref out) {
    char *prompt_cstr = sl_to_cstr(prompt);
    if (!prompt_cstr) return 0;

    struct SseStreamContext ctx;
    ctx.client_fd = client_fd;
    ctx.out = out;
    ctx.index = 0;

    pthread_mutex_lock(&g_inference_mutex);
    char *err = _swift_apple_ai_respond_stream((void*)session_handle, prompt_cstr, on_sse_token, &ctx);
    pthread_mutex_unlock(&g_inference_mutex);
    free(prompt_cstr);

    if (err) {
        _swift_apple_ai_free_string(err);
        return 0;
    }

    // Send final [DONE] event
    const char *done_chunk = "data: {\"choices\":[{\"delta\":{},\"finish_reason\":\"stop\"}]}\n\ndata: [DONE]\n\n";
    write(client_fd, done_chunk, strlen(done_chunk));
    return 1;
}

// 6. POSIX Network helpers for HTTP server
static inline int32_t net_listen(int32_t port) {
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    if (fd < 0) return -1;

    int opt = 1;
    setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = htonl(INADDR_ANY);
    addr.sin_port = htons((uint16_t)port);

    if (bind(fd, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
        close(fd);
        return -1;
    }

    if (listen(fd, 64) < 0) {
        close(fd);
        return -1;
    }
    return fd;
}

static inline int32_t net_accept(int32_t server_fd) {
    struct sockaddr_in client_addr;
    socklen_t addr_len = sizeof(client_addr);
    return accept(server_fd, (struct sockaddr*)&client_addr, &addr_len);
}

static inline int64_t net_read(int32_t fd, gs_rref out) {
    char buf[4096];
    ssize_t n = read(fd, buf, sizeof(buf));
    if (n > 0) {
        gs_bld_append(out, buf, (int64_t)n);
    }
    return (int64_t)n;
}

static inline int64_t net_write(int32_t fd, sl_u8 data) {
    if (data.len <= 0 || !data.data) return 0;
    return (int64_t)write(fd, data.data, (size_t)data.len);
}

static inline void net_close(int32_t fd) {
    if (fd >= 0) close(fd);
}

#ifdef __cplusplus
}
#endif

#endif // APPLE_AI_BRIDGE_H
