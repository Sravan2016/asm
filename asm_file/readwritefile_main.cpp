#include <iostream>

struct AsmString {
    char* ptr;
    unsigned long long len;
};

extern "C" {
void runtime_init();
void print_cstr(const char* s);
void print_string(const AsmString* s);
void string_free(AsmString* s);long long string_contains_sub(const AsmString* hay, const AsmString* needle);
void string_from_cstr(AsmString* dst, const char* src);
long long file_read_all(const char* path, AsmString* out);
long long file_print_lines_count(const char* path);
long long file_line_reader_open(const char* path);
long long file_line_reader_next(AsmString* out);
void file_line_reader_close();
long long file_line_reader_line_count();
long long file_count_lines(const char* path);
long long file_get_line_at(const char* path, long long index, AsmString* out);
}

static AsmString getLineFromFile(const char* path, long long index) {
    AsmString out{};
    if (!file_get_line_at(path, index, &out)) {
        out.ptr = nullptr;
        out.len = 0;
    }
    return out;
}

int main() {
    runtime_init();
    print_cstr("Line-by-line scenario:\n");
    const char* path = "../sample.bada";
    long long lines = file_count_lines(path);
    if (lines == 0) {
        print_cstr("Failed to read file\n");
        return 0;
    }
    AsmString a{};
    string_from_cstr(&a, "main");
    for (long long i = 0; i < lines; i++) {
        AsmString s = getLineFromFile(path, i);
        print_cstr(string_contains_sub(&s, &a) ? "true\n" : "false\n");
        if (!s.ptr) {
            break;
        }
        print_string(&s);
        print_cstr("\n");
        string_free(&s);
    }
    string_free(&a);
    return 0;
}
