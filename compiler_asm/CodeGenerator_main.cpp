#include <cstddef>
#include <cstdint>
#include <cstring>
#include <iostream>
#include <string>

struct AsmVar {
    const char* name;
    std::int64_t offset;
    int type;
    std::uint32_t pad0;
};

struct AsmCodegenState {
    char* buffer;
    std::size_t length;
    std::size_t capacity;
    AsmVar* vars;
    std::size_t var_count;
    std::size_t var_capacity;
    int local_offset;
    std::uint32_t pad0;
    const char* current_function;
};

struct AsmStringConstant {
    const char* name;
    const char* value;
};

struct AsmInstruction {
    int opcode;
    int type;
    const char* result;
    const char** operands;
    std::size_t operand_count;
    const char* label_name;
    const char* string_value;
    std::int64_t int_value;
    std::uint64_t double_bits;
};

struct AsmBlock {
    const char* name;
    AsmInstruction* instructions;
    std::size_t instruction_count;
};

struct AsmParam {
    const char* name;
    int type;
    std::uint32_t pad0;
};

struct AsmFunction {
    const char* name;
    AsmParam* params;
    std::size_t param_count;
    AsmBlock* blocks;
    std::size_t block_count;
};

struct AsmModule {
    AsmStringConstant* string_constants;
    std::size_t string_count;
    const char** external_symbols;
    std::size_t external_count;
    AsmFunction* functions;
    std::size_t function_count;
};

static_assert(sizeof(AsmVar) == 24);
static_assert(sizeof(AsmCodegenState) == 64);
static_assert(sizeof(AsmInstruction) == 64);
static_assert(sizeof(AsmBlock) == 24);
static_assert(sizeof(AsmParam) == 16);
static_assert(sizeof(AsmFunction) == 40);
static_assert(sizeof(AsmModule) == 48);

extern "C" void codegen_init(AsmCodegenState*, char*, std::size_t, AsmVar*, std::size_t);
extern "C" void codegen_generate(AsmCodegenState*, AsmModule*, int);
extern "C" void codegen_emit_data_section(AsmCodegenState*, AsmModule*);
extern "C" void codegen_emit_text_section(AsmCodegenState*, AsmModule*, int);
extern "C" void codegen_emit_function(AsmCodegenState*, AsmFunction*);
extern "C" void codegen_emit_block(AsmCodegenState*, AsmBlock*);
extern "C" void codegen_emit_instruction(AsmCodegenState*, AsmInstruction*);
extern "C" const char* codegen_reg_for_type(int);
extern "C" const char* codegen_reg_for_param(std::size_t);
extern "C" std::int64_t codegen_var_location(AsmCodegenState*, const char*);
extern "C" std::int64_t codegen_assign_location(AsmCodegenState*, const char*, int);
extern "C" void codegen_emit_move_to_reg(AsmCodegenState*, const char*, const char*, int);
extern "C" void codegen_emit_address_to_reg(AsmCodegenState*, const char*, const char*);
extern "C" void codegen_emit_move_from_reg(AsmCodegenState*, const char*, const char*, int);
extern "C" int codegen_mangle_symbol(const char*, char*);
extern "C" const char* codegen_output(AsmCodegenState*);
extern "C" std::size_t codegen_output_length(AsmCodegenState*);
extern "C" std::size_t codegen_strlen(const char*);
extern "C" int codegen_starts_with(const char*, const char*);

namespace {

constexpr int TypeInteger = 1;
constexpr int TypeLong = 2;
constexpr int TypeDouble = 3;
constexpr int TypeBoolean = 4;
constexpr int TypePointer = 5;
constexpr int TypeString = 7;

constexpr int OpConstInt = 0;
constexpr int OpConstLong = 1;
constexpr int OpConstDouble = 2;
constexpr int OpConstBool = 3;
constexpr int OpConstPtr = 4;
constexpr int OpAdd = 5;
constexpr int OpSub = 6;
constexpr int OpMul = 7;
constexpr int OpDiv = 8;
constexpr int OpMod = 9;
constexpr int OpEQ = 11;
constexpr int OpNE = 12;
constexpr int OpLT = 13;
constexpr int OpLE = 14;
constexpr int OpGT = 15;
constexpr int OpGE = 16;
constexpr int OpAnd = 17;
constexpr int OpOr = 18;
constexpr int OpNot = 19;
constexpr int OpLabel = 20;
constexpr int OpJmp = 21;
constexpr int OpBranch = 22;
constexpr int OpRet = 23;
constexpr int OpCall = 24;
constexpr int OpLoad = 25;
constexpr int OpStore = 26;
constexpr int OpAlloca = 27;
constexpr int OpArrayNew = 35;
constexpr int OpArrayGet = 36;
constexpr int OpArraySet = 37;
constexpr int OpArrayLen = 38;
constexpr int OpArrayPush = 39;
constexpr int OpCallRuntime = 40;

int failures = 0;

void expect_true(const std::string& name, bool value) {
    if (value) {
        std::cout << "PASS " << name << '\n';
        return;
    }
    std::cout << "FAIL " << name << '\n';
    ++failures;
}

void expect_false(const std::string& name, bool value) {
    expect_true(name, !value);
}

void expect_int(const std::string& name, std::int64_t actual, std::int64_t expected) {
    if (actual == expected) {
        std::cout << "PASS " << name << '\n';
        return;
    }
    std::cout << "FAIL " << name << " expected " << expected << " got " << actual << '\n';
    ++failures;
}

void expect_text(const std::string& name, const char* actual, const char* expected) {
    expect_true(name, actual != nullptr && std::string(actual) == expected);
}

void expect_contains(const std::string& name, const char* haystack, const char* needle) {
    expect_true(name, haystack != nullptr && std::string(haystack).find(needle) != std::string::npos);
}

template <std::size_t BufferSize, std::size_t VarCount>
AsmCodegenState fresh_state(char (&buffer)[BufferSize], AsmVar (&vars)[VarCount]) {
    std::memset(buffer, 0, BufferSize);
    std::memset(vars, 0, sizeof(vars));
    AsmCodegenState state{};
    codegen_init(&state, buffer, BufferSize, vars, VarCount);
    return state;
}

void positive_scenarios() {
    char buffer[32768]{};
    AsmVar vars[128]{};
    AsmCodegenState state = fresh_state(buffer, vars);

    expect_int("strlen", codegen_strlen("sample"), 6);
    expect_true("starts with str_", codegen_starts_with("str_1", "str_") != 0);
    expect_text("boolean register", codegen_reg_for_type(TypeBoolean), "al");
    expect_text("default register", codegen_reg_for_type(TypeLong), "rax");
    expect_text("param rcx", codegen_reg_for_param(0), "rcx");
    expect_text("param r9", codegen_reg_for_param(3), "r9");
    expect_text("param fallback", codegen_reg_for_param(8), "rax");

    expect_int("assign location a", codegen_assign_location(&state, "a", TypeInteger), 8);
    expect_int("assign location b", codegen_assign_location(&state, "b", TypeInteger), 16);
    expect_int("var location b", codegen_var_location(&state, "b"), 16);

    codegen_emit_move_to_reg(&state, "42", "rax", TypeInteger);
    codegen_emit_move_to_reg(&state, "a", "rbx", TypeInteger);
    codegen_emit_move_to_reg(&state, "str_hello", "rcx", TypePointer);
    codegen_emit_address_to_reg(&state, "&b", "rdx");
    codegen_emit_move_from_reg(&state, "rax", "a", TypeInteger);
    expect_contains("move immediate", buffer, "mov rax, 42");
    expect_contains("move variable", buffer, "mov rbx, [rbp-8]");
    expect_contains("address variable", buffer, "lea rdx, [rbp-16]");

    char mangled[64]{};
    expect_true("mangle ok", codegen_mangle_symbol("pkg.User.main", mangled) != 0);
    expect_text("mangle symbol", mangled, "pkg_User_main");

    AsmStringConstant strings[]{{"str_0", "Hello"}};
    const char* externs[]{"custom_runtime"};

    const char* add_ops[]{"lhs", "rhs"};
    const char* branch_ops[]{"cond", "then", "else"};
    const char* call_ops[]{"runtime_func", "a1", "a2", "a3", "a4", "a5"};
    const char* ret_ops[]{"sum"};

    AsmInstruction instructions[]{
        {OpAlloca, TypeInteger, "lhs", nullptr, 0, nullptr, nullptr, 0, 0},
        {OpAlloca, TypeInteger, "rhs", nullptr, 0, nullptr, nullptr, 0, 0},
        {OpConstInt, TypeInteger, "cond", nullptr, 0, nullptr, nullptr, 1, 0},
        {OpAdd, TypeInteger, "sum", add_ops, 2, nullptr, nullptr, 0, 0},
        {OpEQ, TypeInteger, "is_eq", add_ops, 2, nullptr, nullptr, 0, 0},
        {OpBranch, TypeBoolean, nullptr, branch_ops, 3, nullptr, nullptr, 0, 0},
        {OpLabel, TypeInteger, nullptr, nullptr, 0, "then", nullptr, 0, 0},
        {OpCall, TypeInteger, "call_result", call_ops, 6, nullptr, nullptr, 0, 0},
        {OpArrayNew, TypePointer, "arr", nullptr, 0, nullptr, nullptr, 0, 0},
        {OpRet, TypeInteger, nullptr, ret_ops, 1, nullptr, nullptr, 0, 0},
    };
    AsmBlock blocks[]{{"entry", instructions, sizeof(instructions) / sizeof(instructions[0])}};
    AsmParam params[]{{"this", TypePointer, 0}, {"p", TypeInteger, 0}};
    AsmFunction functions[]{{"Demo_main", params, 2, blocks, 1}};
    AsmModule module{strings, 1, externs, 1, functions, 1};

    state = fresh_state(buffer, vars);
    codegen_generate(&state, &module, 1);
    const char* output = codegen_output(&state);
    expect_contains("data section", output, "section .data");
    expect_contains("string constant data", output, "str_0_data db 'Hello'");
    expect_contains("text section", output, "section .text");
    expect_contains("runtime extern", output, "extern print_cstr");
    expect_contains("custom extern", output, "extern custom_runtime");
    expect_contains("global main", output, "global main");
    expect_contains("function label", output, "Demo_main:");
    expect_contains("block label", output, "Demo_main_entry:");
    expect_contains("add instruction", output, "add rax, rbx");
    expect_contains("compare instruction", output, "sete al");
    expect_contains("branch true label", output, "jne Demo_main_then");
    expect_contains("call frame padded", output, "sub rsp, 48");
    expect_contains("fifth stack argument", output, "mov [rsp+32], rax");
    expect_contains("array create", output, "call array_create");
    expect_contains("entry call", output, "call Demo_main");
    expect_true("output length", codegen_output_length(&state) > 100);

    state = fresh_state(buffer, vars);
    codegen_emit_data_section(&state, &module);
    expect_contains("emit data direct", buffer, "section .bss");

    state = fresh_state(buffer, vars);
    codegen_emit_text_section(&state, &module, 0);
    expect_contains("emit text direct", buffer, "section .text");
    expect_false("no main when disabled", std::string(buffer).find("global main") != std::string::npos);

    state = fresh_state(buffer, vars);
    codegen_emit_function(&state, &functions[0]);
    expect_contains("emit function direct", buffer, "Demo_main_entry:");

    state = fresh_state(buffer, vars);
    state.current_function = "Demo_main";
    codegen_emit_block(&state, &blocks[0]);
    expect_contains("emit block direct", buffer, "Demo_main_entry:");
}

void negative_scenarios() {
    char buffer[512]{};
    AsmVar vars[2]{};
    AsmCodegenState state = fresh_state(buffer, vars);

    expect_false("starts with null", codegen_starts_with(nullptr, "str_") != 0);
    expect_int("missing var location", codegen_var_location(&state, "missing"), 0);
    expect_true("mangle null rejected", codegen_mangle_symbol(nullptr, buffer) == 0);

    expect_int("assign one", codegen_assign_location(&state, "one", TypeInteger), 8);
    expect_int("assign two", codegen_assign_location(&state, "two", TypeInteger), 16);
    expect_int("assign capacity full", codegen_assign_location(&state, "three", TypeInteger), 0);

    AsmInstruction unknown{99, TypeInteger, nullptr, nullptr, 0, nullptr, nullptr, 0, 0};
    codegen_emit_instruction(&state, &unknown);
    expect_contains("unknown instruction comment", buffer, "; unknown instruction");

    state = fresh_state(buffer, vars);
    codegen_emit_move_to_reg(&state, "missing", "rax", TypeInteger);
    codegen_emit_address_to_reg(&state, "missing", "rcx");
    expect_contains("unknown move zero", buffer, "xor rax, rax");
    expect_contains("unknown address zero", buffer, "xor rcx, rcx");

    codegen_generate(nullptr, nullptr, 1);
    codegen_emit_data_section(nullptr, nullptr);
    codegen_emit_text_section(nullptr, nullptr, 1);
    codegen_emit_function(nullptr, nullptr);
    codegen_emit_block(nullptr, nullptr);
    codegen_emit_instruction(nullptr, nullptr);
    codegen_emit_move_to_reg(nullptr, nullptr, nullptr, 0);
    codegen_emit_address_to_reg(nullptr, nullptr, nullptr);
    codegen_emit_move_from_reg(nullptr, nullptr, nullptr, 0);
    expect_true("null calls survive", true);
}

} // namespace

int main() {
    std::cout.setf(std::ios::unitbuf);
    positive_scenarios();
    negative_scenarios();

    if (failures == 0) {
        std::cout << "CodeGenerator asm scenarios passed\n";
        return 0;
    }

    std::cout << "CodeGenerator asm scenarios failed: " << failures << '\n';
    return 1;
}
