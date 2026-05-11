#include <cstdint>
#include <cstring>
#include <iostream>

struct AsmStringList {
    std::uint64_t count;
    const char* items[16];
};

extern "C" {
std::uint64_t compiler_strlen(const char* text);
int compiler_streq(const char* left, const char* right);
void compiler_copy(char* out, const char* text, std::uint64_t cap);
void compiler_append(char* out, const char* text, std::uint64_t cap);
int compiler_ends_with_bada(const char* path);
void compiler_parent_directory(const char* path, char* out, std::uint64_t cap);
void compiler_replace_extension(const char* path, const char* ext, char* out, std::uint64_t cap);
void compiler_normalize_path(const char* path, char* out, std::uint64_t cap);
int compiler_path_eq_normalized(const char* left, const char* right);
void compiler_import_to_path(const char* base, const char** parts, std::uint64_t count, char* out, std::uint64_t cap);
void compiler_class_name_to_path(const char* base, const char* name, char* out, std::uint64_t cap);
int compiler_is_builtin_class_name(const char* name);
int compiler_looks_like_class_name(const char* name);
int compiler_collect_class_ref_from_type(const char* name);
int compiler_append_unique(AsmStringList* list, const char* value);
std::uint64_t compiler_count_link_manifest_entries(const char* content);
int compiler_run_model(int argc, const char** argv, int flags);
}

static void expect(bool condition, const char* label, int& failures) {
    if (condition) {
        std::cout << "[PASS] " << label << '\n';
        return;
    }
    std::cout << "[FAIL] " << label << '\n';
    ++failures;
}

static int run_self_test() {
    int failures = 0;
    char out[512]{};

    expect(compiler_strlen("sample") == 6, "positive: strlen counts text", failures);
    expect(compiler_streq("asm", "asm") == 1, "positive: streq matches equal text", failures);
    expect(compiler_streq("asm", "bada") == 0, "negative: streq rejects different text", failures);

    compiler_copy(out, "hello", sizeof(out));
    compiler_append(out, " world", sizeof(out));
    expect(std::strcmp(out, "hello world") == 0, "positive: copy and append build output text", failures);

    expect(compiler_ends_with_bada("project/sample.bada") == 1,
           "positive: .bada source file is accepted", failures);
    expect(compiler_ends_with_bada("project/sample.txt") == 0,
           "negative: non-.bada source file is rejected", failures);
    expect(compiler_ends_with_bada("bada") == 0,
           "negative: short path cannot match .bada suffix", failures);

    compiler_parent_directory("project/com/base/User.bada", out, sizeof(out));
    expect(std::strcmp(out, "project/com/base") == 0,
           "positive: parent_directory handles slash paths", failures);
    compiler_parent_directory("User.bada", out, sizeof(out));
    expect(std::strcmp(out, "") == 0,
           "negative: parent_directory returns empty for file-only path", failures);

    compiler_replace_extension("project/User.bada", ".obj", out, sizeof(out));
    expect(std::strcmp(out, "project/User.obj") == 0,
           "positive: replace_extension swaps existing extension", failures);
    compiler_replace_extension("project/User", ".s", out, sizeof(out));
    expect(std::strcmp(out, "project/User.s") == 0,
           "positive: replace_extension appends missing extension", failures);
    compiler_replace_extension("project.dir/User", ".obj", out, sizeof(out));
    expect(std::strcmp(out, "project.dir/User.obj") == 0,
           "negative: dot before slash is ignored as extension", failures);

    compiler_normalize_path("project/com/base/User.obj", out, sizeof(out));
    expect(std::strcmp(out, "project\\com\\base\\User.obj") == 0,
           "positive: normalize_path converts slashes to backslashes", failures);
    expect(compiler_path_eq_normalized("project/com/User.obj", "project\\com\\User.obj") == 1,
           "positive: normalized path equality treats separators the same", failures);
    expect(compiler_path_eq_normalized("project/com/User.obj", "project/com/Order.obj") == 0,
           "negative: normalized path equality rejects different paths", failures);

    const char* import_parts[] = {"com", "base", "User"};
    compiler_import_to_path("project", import_parts, 3, out, sizeof(out));
    expect(std::strcmp(out, "project/com/base/User.bada") == 0,
           "positive: import_to_path joins import parts", failures);
    compiler_import_to_path("project/", import_parts, 2, out, sizeof(out));
    expect(std::strcmp(out, "project/com/base.bada") == 0,
           "positive: import_to_path preserves existing trailing slash", failures);

    compiler_class_name_to_path("project/com/base", "User", out, sizeof(out));
    expect(std::strcmp(out, "project/com/base/User.bada") == 0,
           "positive: class_name_to_path builds same-folder class path", failures);

    expect(compiler_is_builtin_class_name("Map") == 1, "positive: Map is built-in class", failures);
    expect(compiler_is_builtin_class_name("Aleka") == 1, "positive: Aleka is built-in class", failures);
    expect(compiler_is_builtin_class_name("User") == 0, "negative: User is not built-in class", failures);
    expect(compiler_looks_like_class_name("User") == 1, "positive: uppercase identifier looks like class", failures);
    expect(compiler_looks_like_class_name("user") == 0, "negative: lowercase identifier is not class-like", failures);
    expect(compiler_collect_class_ref_from_type("User") == 1,
           "positive: custom class type is collected as dependency", failures);
    expect(compiler_collect_class_ref_from_type("String") == 0,
           "negative: primitive type is not collected as dependency", failures);
    expect(compiler_collect_class_ref_from_type("Map") == 0,
           "negative: built-in class is not collected as dependency", failures);

    AsmStringList list{};
    expect(compiler_append_unique(&list, "project/com/User.obj") == 1,
           "positive: append_unique adds first dependency", failures);
    expect(compiler_append_unique(&list, "project\\com\\User.obj") == 0,
           "negative: append_unique skips normalized duplicate", failures);
    expect(compiler_append_unique(&list, "project/com/Order.obj") == 1 && list.count == 2,
           "positive: append_unique adds distinct dependency", failures);

    expect(compiler_count_link_manifest_entries("\"a.obj\" \"b.obj\" c.obj") == 3,
           "positive: manifest parser counts quoted and bare objects", failures);
    expect(compiler_count_link_manifest_entries("   \n\t") == 0,
           "negative: empty manifest content has no dependencies", failures);

    const char* ok_args[] = {"compiler", "project/sample.bada"};
    const char* txt_args[] = {"compiler", "project/sample.txt"};
    const char* dump_args[] = {"compiler", "project/sample.bada", "--dump-tokens"};
    const char* link_args[] = {"compiler", "project/sample.bada", "--link"};
    const int all_ok = 1 | 2 | 4 | 8 | 16;

    expect(compiler_run_model(2, ok_args, all_ok) == 0,
           "positive: compiler_run succeeds for valid bada file", failures);
    expect(compiler_run_model(2, txt_args, all_ok) == 2,
           "negative: compiler_run rejects unsupported extension", failures);
    expect(compiler_run_model(3, dump_args, all_ok & ~1) == 1,
           "negative: dump-tokens returns open-file failure when source is missing", failures);
    expect(compiler_run_model(2, ok_args, all_ok & ~2) == 4,
           "negative: compiler_run returns import collection failure", failures);
    expect(compiler_run_model(2, ok_args, all_ok & ~4) == 5,
           "negative: compiler_run returns module compile failure", failures);
    expect(compiler_run_model(2, ok_args, all_ok & ~8) == 6,
           "negative: compiler_run returns manifest failure", failures);
    expect(compiler_run_model(3, link_args, all_ok & ~16) == 6,
           "negative: compiler_run returns link failure", failures);
    expect(compiler_run_model(3, link_args, all_ok) == 0,
           "positive: compiler_run succeeds with --link when link step passes", failures);

    if (failures == 0) {
        std::cout << "Compiler asm scenarios passed\n";
        return 0;
    }

    std::cout << "Compiler asm scenarios failed: " << failures << '\n';
    return 1;
}

int main(int argc, char** argv) {
    if (argc == 2 && std::strcmp(argv[1], "--self-test") == 0) {
        return run_self_test();
    }

    const int all_ok = 1 | 2 | 4 | 8 | 16;
    return compiler_run_model(argc, const_cast<const char**>(argv), all_ok);
}
