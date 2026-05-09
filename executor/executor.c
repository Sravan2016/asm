#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define CMD_MAX 32768

static void append_text(char* dst, size_t cap, const char* text) {
    size_t used = strlen(dst);
    if (used >= cap) return;
    snprintf(dst + used, cap - used, "%s", text);
}

static void append_quoted(char* dst, size_t cap, const char* text) {
    size_t used = strlen(dst);
    if (used >= cap) return;
    snprintf(dst + used, cap - used, "\"%s\" ", text);
}

static void replace_extension(const char* path, const char* ext, char* out, size_t cap) {
    size_t len = strlen(path);
    size_t dot = len;
    size_t slash = len;
    size_t i;
    for (i = 0; i < len; ++i) {
        if (path[i] == '/' || path[i] == '\\') slash = i;
        if (path[i] == '.') dot = i;
    }
    if (dot == len || dot < slash) {
        snprintf(out, cap, "%s%s", path, ext);
    } else {
        snprintf(out, cap, "%.*s%s", (int)dot, path, ext);
    }
}

static void join_path(const char* dir, const char* name, char* out, size_t cap) {
    size_t len = strlen(dir);
    if (len == 0) {
        snprintf(out, cap, "%s", name);
        return;
    }
    if (dir[len - 1] == '\\' || dir[len - 1] == '/') {
        snprintf(out, cap, "%s%s", dir, name);
    } else {
        snprintf(out, cap, "%s\\%s", dir, name);
    }
}

static int is_absolute_path(const char* path) {
    if (!path || !path[0]) return 0;
    if ((path[0] && path[1] == ':') || path[0] == '\\' || path[0] == '/') return 1;
    return 0;
}

static int file_exists(const char* path) {
    FILE* input = fopen(path, "rb");
    if (!input) return 0;
    fclose(input);
    return 1;
}

static void canonicalize_path(const char* path, char* out, size_t cap) {
#ifdef _WIN32
    char* full = _fullpath(out, path, cap);
    if (full) return;
#endif
    snprintf(out, cap, "%s", path);
}

static void parent_directory(const char* path, char* out, size_t cap) {
    size_t len = strlen(path);
    size_t cut = len;
    size_t i;
    for (i = 0; i < len; ++i) {
        if (path[i] == '\\' || path[i] == '/') {
            cut = i;
        }
    }
    if (cut == len) {
        snprintf(out, cap, ".");
        return;
    }
    snprintf(out, cap, "%.*s", (int)cut, path);
}

static int append_manifest_objects(char* cmd, size_t cap, const char* manifest_path) {
    FILE* input = fopen(manifest_path, "rb");
    int ch;
    char token[1024];
    char resolved[1024];
    char canonical[1024];
    char manifest_dir[1024];
    char seen[128][1024];
    int seen_count = 0;
    size_t idx = 0;
    int in_quote = 0;
    int i;

    if (!input) return 0;
    parent_directory(manifest_path, manifest_dir, sizeof(manifest_dir));

    while ((ch = fgetc(input)) != EOF) {
        if (in_quote) {
            if (ch == '"') {
                token[idx] = '\0';
                if (idx > 0) {
                    if (is_absolute_path(token) || file_exists(token)) snprintf(resolved, sizeof(resolved), "%s", token);
                    else join_path(manifest_dir, token, resolved, sizeof(resolved));
                    canonicalize_path(resolved, canonical, sizeof(canonical));
                    for (i = 0; i < seen_count; ++i) {
                        if (strcmp(seen[i], canonical) == 0) break;
                    }
                    if (i == seen_count && seen_count < 128) {
                        snprintf(seen[seen_count++], sizeof(seen[0]), "%s", canonical);
                        append_quoted(cmd, cap, resolved);
                    }
                }
                idx = 0;
                in_quote = 0;
            } else if (idx + 1 < sizeof(token)) {
                token[idx++] = (char)ch;
            }
            continue;
        }

        if (ch == '"') {
            in_quote = 1;
            idx = 0;
            continue;
        }

        if (isspace((unsigned char)ch)) {
            if (idx > 0) {
                token[idx] = '\0';
                if (is_absolute_path(token) || file_exists(token)) snprintf(resolved, sizeof(resolved), "%s", token);
                else join_path(manifest_dir, token, resolved, sizeof(resolved));
                canonicalize_path(resolved, canonical, sizeof(canonical));
                for (i = 0; i < seen_count; ++i) {
                    if (strcmp(seen[i], canonical) == 0) break;
                }
                if (i == seen_count && seen_count < 128) {
                    snprintf(seen[seen_count++], sizeof(seen[0]), "%s", canonical);
                    append_quoted(cmd, cap, resolved);
                }
                idx = 0;
            }
            continue;
        }

        if (idx + 1 < sizeof(token)) {
            token[idx++] = (char)ch;
        }
    }

    if (idx > 0) {
        token[idx] = '\0';
        if (is_absolute_path(token) || file_exists(token)) snprintf(resolved, sizeof(resolved), "%s", token);
        else join_path(manifest_dir, token, resolved, sizeof(resolved));
        canonicalize_path(resolved, canonical, sizeof(canonical));
        for (i = 0; i < seen_count; ++i) {
            if (strcmp(seen[i], canonical) == 0) break;
        }
        if (i == seen_count && seen_count < 128) {
            snprintf(seen[seen_count++], sizeof(seen[0]), "%s", canonical);
            append_quoted(cmd, cap, resolved);
        }
    }

    fclose(input);
    return 1;
}

int main(int argc, char** argv) {
    const char* pure_dir = ".\\build\\asm_pure_obj";
    const char* heap_dir = ".\\build\\asm_file_obj";
    const char* gcc_path = "C:\\Strawberry\\c\\bin\\gcc.exe";
    const char* main_obj = "sample.obj";
    const char* manifest_arg = NULL;
    char manifest_path[1024];
    char command[CMD_MAX];
    char path_buf[1024];
    int i;

    const char* pure_objs[] = {
        "string.obj", "integer.obj", "array.obj", "boolean.obj",
        "double.obj", "httpclient.obj", "httpserver.obj",
        "long.obj", "map.obj", "sock.obj", "thread.obj", "badaapi_ptrs.obj",
        "aleka.obj"
    };

    command[0] = '\0';

    for (i = 1; i < argc; ++i) {
        if (strcmp(argv[i], "-d") == 0 && i + 1 < argc) {
            heap_dir = argv[++i];
            continue;
        }
        if (strcmp(argv[i], "--link") == 0 && i + 1 < argc) {
            manifest_arg = argv[++i];
            continue;
        }
        main_obj = argv[i];
    }

    if (manifest_arg) {
        snprintf(manifest_path, sizeof(manifest_path), "%s", manifest_arg);
    } else {
        replace_extension(main_obj, ".link", manifest_path, sizeof(manifest_path));
    }

    append_quoted(command, sizeof(command), gcc_path);
    append_quoted(command, sizeof(command), main_obj);
    append_manifest_objects(command, sizeof(command), manifest_path);

    for (i = 0; i < (int)(sizeof(pure_objs) / sizeof(pure_objs[0])); ++i) {
        join_path(pure_dir, pure_objs[i], path_buf, sizeof(path_buf));
        if (!file_exists(path_buf)) {
            join_path(heap_dir, pure_objs[i], path_buf, sizeof(path_buf));
        }
        append_quoted(command, sizeof(command), path_buf);
    }

    join_path(heap_dir, "heap.obj", path_buf, sizeof(path_buf));
    append_quoted(command, sizeof(command), path_buf);
    join_path(heap_dir, "readwritefile.obj", path_buf, sizeof(path_buf));
    append_quoted(command, sizeof(command), path_buf);
    append_text(command, sizeof(command), "-o \".\\bada_run.exe\" ");
    append_text(command, sizeof(command),
                "-lntdll -lws2_32 -lkernel32 -lkernel32 -luser32 -lgdi32 "
                "-lwinspool -lshell32 -lole32 -loleaut32 -luuid -lcomdlg32 -ladvapi32");

    {
        char shell_command[CMD_MAX + 32];
        snprintf(shell_command, sizeof(shell_command), "cmd /c \"%s\"", command);
        if (system(shell_command) != 0) {
            fprintf(stderr, "executor_asm: link failed\n");
            return 1;
        }
    }

    if (system(".\\bada_run.exe") != 0) {
        fprintf(stderr, "executor_asm: run failed\n");
        return 1;
    }

    return 0;
}
