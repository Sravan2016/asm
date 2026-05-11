#include <cstdint>
#include <cstring>
#include <iostream>
#include <string>
#include <vector>

struct AsmString {
    char name[32];
    char value[64];
};

struct AsmGlobal {
    char name[32];
};

struct AsmFunction {
    char name[32];
};

struct AsmModule {
    AsmString* strings;
    std::uint64_t string_count;
    AsmGlobal* globals;
    std::uint64_t global_count;
    AsmFunction* functions;
    std::uint64_t function_count;
};

struct AsmLinkingRuntime {
    std::int32_t abi;
    std::uint32_t pad;
    char nasm[128];
    char gcc[128];
    char runtime_dir[128];
    char* buffer;
    std::uint64_t len;
    std::uint64_t cap;
};

static_assert(sizeof(AsmString) == 96);
static_assert(sizeof(AsmGlobal) == 32);
static_assert(sizeof(AsmFunction) == 32);
static_assert(sizeof(AsmLinkingRuntime) == 416);

extern "C" {
void linking_init(AsmLinkingRuntime* runtime, int abi);
void linking_set_nasm_path(AsmLinkingRuntime* runtime, const char* path);
void linking_set_gcc_path(AsmLinkingRuntime* runtime, const char* path);
void linking_set_runtime_dir(AsmLinkingRuntime* runtime, const char* path);
int linking_get_abi(AsmLinkingRuntime* runtime);
const char* linking_param_reg_sysv(int abi, std::uint64_t index);
const char* linking_callee_saved_reg(std::uint64_t index);
char* linking_join_path(const char* base, const char* leaf, char* out, std::uint64_t cap);
void linking_set_output(AsmLinkingRuntime* runtime, char* out, std::uint64_t cap);
void linking_clear_output(AsmLinkingRuntime* runtime);
void linking_generate_runtime_init(AsmLinkingRuntime* runtime);
void linking_generate_runtime_call(AsmLinkingRuntime* runtime, const char* name, const char** args,
                                   std::uint64_t arg_count, const char* result_reg);
void linking_emit_data_section(AsmLinkingRuntime* runtime, AsmModule* module);
void linking_emit_bss_section(AsmLinkingRuntime* runtime, AsmModule* module);
void linking_emit_text_section(AsmLinkingRuntime* runtime, AsmModule* module, std::uint64_t emit_entry);
void linking_generate_assembly(AsmLinkingRuntime* runtime, AsmModule* module, std::uint64_t emit_entry);
int linking_assemble_to_object(AsmLinkingRuntime* runtime, const char* source, const char* object);
int linking_link_executable(AsmLinkingRuntime* runtime, const char* object, const char* executable);
int linking_build_executable(AsmLinkingRuntime* runtime, AsmModule* module, const char* executable);
const char* linking_registry_lookup(const char* name);
void linking_registry_required_objects(char* out, std::uint64_t cap);
void linking_registry_required_libraries(char* out, std::uint64_t cap);
int linking_runtime_arg_passes_slot_address(const char* name, std::uint64_t arg_index);
char* linking_resolve_runtime_object_path(const char* dir, const char* obj, char* out, std::uint64_t cap);
}

static bool contains(const char* haystack, const char* needle) {
    return std::strstr(haystack, needle) != nullptr;
}

static void copy(char* out, const char* text, std::size_t cap) {
    std::strncpy(out, text, cap - 1);
    out[cap - 1] = '\0';
}

static void expect(bool condition, const char* label, int& failures) {
    if (condition) {
        std::cout << "[PASS] " << label << '\n';
        return;
    }

    std::cout << "[FAIL] " << label << '\n';
    ++failures;
}

int main() {
    int failures = 0;
    char output[8192]{};
    AsmLinkingRuntime runtime{};
    linking_init(&runtime, 0);
    linking_set_output(&runtime, output, sizeof(output));

    expect(linking_get_abi(&runtime) == 0, "positive: init stores System V ABI", failures);
    expect(std::strcmp(runtime.nasm, "nasm") == 0, "positive: init stores default nasm path", failures);
    expect(std::strcmp(runtime.gcc, "g++") == 0, "positive: init stores default gcc path", failures);

    linking_set_nasm_path(&runtime, "custom-nasm");
    linking_set_gcc_path(&runtime, "custom-g++");
    linking_set_runtime_dir(&runtime, "runtime/objects");
    expect(std::strcmp(runtime.nasm, "custom-nasm") == 0, "positive: set_nasm_path updates state", failures);
    expect(std::strcmp(runtime.gcc, "custom-g++") == 0, "positive: set_gcc_path updates state", failures);
    expect(std::strcmp(runtime.runtime_dir, "runtime/objects") == 0, "positive: set_runtime_dir updates state", failures);

    expect(std::strcmp(linking_param_reg_sysv(0, 0), "rdi") == 0, "positive: sysv first arg register", failures);
    expect(std::strcmp(linking_param_reg_sysv(0, 5), "r9") == 0, "positive: sysv sixth arg register", failures);
    expect(std::strcmp(linking_param_reg_sysv(1, 0), "rcx") == 0, "positive: windows first arg register", failures);
    expect(std::strcmp(linking_param_reg_sysv(0, 9), "rax") == 0, "negative: unsupported arg register falls back", failures);
    expect(std::strcmp(linking_callee_saved_reg(0), "rbx") == 0, "positive: callee saved register lookup", failures);
    expect(std::strcmp(linking_callee_saved_reg(99), "rax") == 0, "negative: callee saved fallback", failures);

    char path[256]{};
    linking_join_path("runtime", "string.obj", path, sizeof(path));
    expect(std::strcmp(path, "runtime/string.obj") == 0, "positive: join_path inserts slash", failures);
    linking_join_path("runtime/", "array.obj", path, sizeof(path));
    expect(std::strcmp(path, "runtime/array.obj") == 0, "positive: join_path keeps existing slash", failures);
    linking_join_path("", "map.obj", path, sizeof(path));
    expect(std::strcmp(path, "map.obj") == 0, "negative: empty base returns leaf", failures);
    linking_resolve_runtime_object_path("runtime", "integer.obj", path, sizeof(path));
    expect(std::strcmp(path, "runtime/integer.obj") == 0, "positive: resolve runtime object path", failures);

    expect(linking_runtime_arg_passes_slot_address("file_open", 0) == 1, "positive: file_open path arg is slot-addressed", failures);
    expect(linking_runtime_arg_passes_slot_address("file_read_all", 1) == 1, "positive: file_read_all output arg is slot-addressed", failures);
    expect(linking_runtime_arg_passes_slot_address("array_join", 2) == 1, "positive: array_join destination arg is slot-addressed", failures);
    expect(linking_runtime_arg_passes_slot_address("print_cstr", 0) == 0, "negative: normal runtime arg is direct", failures);

    linking_clear_output(&runtime);
    linking_generate_runtime_init(&runtime);
    expect(contains(output, "call runtime_init") && contains(output, "call thread_init"),
           "positive: runtime init emits required calls", failures);

    const char* args[] = {"a0", "a1", "a2", "a3", "a4", "a5", "a6"};
    linking_clear_output(&runtime);
    linking_generate_runtime_call(&runtime, "runtime_fn", args, 7, "r10");
    expect(contains(output, "mov rdi, a0") && contains(output, "mov r9, a5"),
           "positive: runtime call maps first six args", failures);
    expect(contains(output, "push rax") && contains(output, "add rsp, 8"),
           "positive: runtime call pushes and cleans extra args", failures);
    expect(contains(output, "call runtime_fn") && contains(output, "mov r10, rax"),
           "positive: runtime call emits call and result move", failures);

    linking_clear_output(&runtime);
    linking_generate_runtime_call(&runtime, "runtime_void", args, 1, "void");
    expect(!contains(output, "mov void, rax"), "negative: void runtime call skips result move", failures);

    AsmString strings[1]{};
    copy(strings[0].name, "msg", sizeof(strings[0].name));
    copy(strings[0].value, "hello", sizeof(strings[0].value));
    AsmGlobal globals[1]{};
    copy(globals[0].name, "counter", sizeof(globals[0].name));
    AsmFunction functions[2]{};
    copy(functions[0].name, "start", sizeof(functions[0].name));
    copy(functions[1].name, "helper", sizeof(functions[1].name));
    AsmModule module{strings, 1, globals, 1, functions, 2};

    linking_clear_output(&runtime);
    linking_generate_assembly(&runtime, &module, 1);
    expect(contains(output, "section .data") && contains(output, "msg_data db \"hello\", 0"),
           "positive: data section emits string storage", failures);
    expect(contains(output, "section .bss") && contains(output, "counter resq 1"),
           "positive: bss section emits globals", failures);
    expect(contains(output, "section .text") && contains(output, "global main") && contains(output, "call start"),
           "positive: text section emits entry and functions", failures);

    linking_clear_output(&runtime);
    linking_emit_text_section(&runtime, &module, 0);
    expect(!contains(output, "global main"), "negative: text section can omit entry point", failures);

    expect(linking_assemble_to_object(&runtime, "sample.s", "sample.obj") == 1,
           "positive: assemble command accepts source and object", failures);
    expect(contains(output, "custom-nasm -f win64 -o sample.obj sample.s"),
           "positive: assemble command mirrors nasm invocation", failures);
    expect(linking_assemble_to_object(&runtime, "", "sample.obj") == 0,
           "negative: assemble command rejects empty source", failures);

    expect(linking_link_executable(&runtime, "sample.obj", "sample.exe") == 1,
           "positive: link command accepts object and exe", failures);
    expect(contains(output, "custom-g++ sample.obj -o sample.exe") && contains(output, "-lntdll -lws2_32"),
           "positive: link command includes Windows runtime libraries", failures);
    expect(linking_link_executable(&runtime, "sample.obj", "") == 0,
           "negative: link command rejects empty executable", failures);

    expect(linking_build_executable(&runtime, &module, "sample.exe") == 1,
           "positive: build executable records generated build flow", failures);
    expect(contains(output, "build_executable generated assembly"), "positive: build executable writes trace", failures);
    expect(linking_build_executable(&runtime, &module, "") == 0,
           "negative: build executable rejects empty target", failures);

    expect(std::strcmp(linking_registry_lookup("print_cstr"), "string.obj") == 0,
           "positive: registry maps print_cstr to string runtime", failures);
    expect(std::strcmp(linking_registry_lookup("int_add"), "integer.obj") == 0,
           "positive: registry maps int_add to integer runtime", failures);
    expect(linking_registry_lookup("not_a_runtime") == nullptr,
           "negative: registry returns null for unknown function", failures);

    char registry[512]{};
    linking_registry_required_objects(registry, sizeof(registry));
    expect(contains(registry, "string.obj") && contains(registry, "heap.obj"),
           "positive: required objects list runtime object files", failures);
    linking_registry_required_libraries(registry, sizeof(registry));
    expect(contains(registry, "ntdll") && contains(registry, "ws2_32"),
           "positive: required libraries list linker libraries", failures);

    if (failures == 0) {
        std::cout << "LinkingRuntime asm scenarios passed\n";
        return 0;
    }

    std::cout << "LinkingRuntime asm scenarios failed: " << failures << '\n';
    return 1;
}
