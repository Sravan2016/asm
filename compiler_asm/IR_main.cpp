#include <cstddef>
#include <cstdint>
#include <cstring>
#include <iostream>
#include <string>

struct AsmIRType {
    int kind;
    int is_file_backed;
    AsmIRType* element_type;
};

struct AsmSemanticType {
    int kind;
    int is_file_backed;
    AsmSemanticType* element_type;
};

struct AsmIRInstruction {
    int opcode;
    AsmIRType type;
    char result[32];
    const char* operands[4];
    std::size_t operand_count;
    char label_name[32];
    char string_value[32];
    std::int64_t int_value;
    char double_text[32];
};

struct AsmIRBasicBlock {
    char name[32];
    AsmIRInstruction* instructions;
    std::size_t instruction_count;
    std::size_t instruction_capacity;
};

struct AsmIRParameter {
    char name[32];
    AsmIRType type;
};

struct AsmIRFunction {
    char name[32];
    AsmIRType return_type;
    AsmIRParameter* parameters;
    std::size_t parameter_count;
    AsmIRBasicBlock* blocks;
    std::size_t block_count;
    std::size_t block_capacity;
    std::size_t current_block_index;
};

struct AsmIRGlobal {
    char name[32];
    AsmIRType type;
};

struct AsmIRStringConstant {
    char name[32];
    char value[64];
};

struct AsmIRModule {
    AsmIRFunction* functions;
    std::size_t function_count;
    std::size_t function_capacity;
    AsmIRGlobal* globals;
    std::size_t global_count;
    std::size_t global_capacity;
    AsmIRStringConstant* string_constants;
    std::size_t string_count;
    std::size_t string_capacity;
    const char** external_symbols;
    std::size_t external_count;
    std::size_t external_capacity;
};

static_assert(sizeof(AsmIRType) == 16);
static_assert(sizeof(AsmSemanticType) == 16);
static_assert(sizeof(AsmIRInstruction) == 200);
static_assert(sizeof(AsmIRBasicBlock) == 56);
static_assert(sizeof(AsmIRParameter) == 48);
static_assert(sizeof(AsmIRFunction) == 96);
static_assert(sizeof(AsmIRGlobal) == 48);
static_assert(sizeof(AsmIRStringConstant) == 96);
static_assert(sizeof(AsmIRModule) == 96);

extern "C" std::size_t ir_strlen(const char*);
extern "C" int ir_streq(const char*, const char*);
extern "C" int ir_copy_cstr(char*, const char*, std::size_t);
extern "C" int ir_append_cstr(char*, const char*, std::size_t);
extern "C" void ir_append_int(char*, std::int64_t, std::size_t);
extern "C" void ir_type_init(AsmIRType*, int, int, AsmIRType*);
extern "C" void ir_type_to_string(AsmIRType*, char*, std::size_t);
extern "C" int ir_type_size_bytes(AsmIRType*);
extern "C" int ir_type_is_integer_family(AsmIRType*);
extern "C" int ir_type_is_numeric(AsmIRType*);
extern "C" void ir_semantic_to_ir_type(AsmIRType*, AsmSemanticType*, AsmIRType*);
extern "C" void ir_instruction_to_string(AsmIRInstruction*, char*, std::size_t);
extern "C" int ir_block_is_terminated(AsmIRBasicBlock*);
extern "C" int ir_block_add_instruction(AsmIRBasicBlock*, AsmIRInstruction*);
extern "C" AsmIRBasicBlock* ir_function_entry_block(AsmIRFunction*);
extern "C" AsmIRBasicBlock* ir_function_add_block(AsmIRFunction*, const char*);
extern "C" AsmIRBasicBlock* ir_function_find_block(AsmIRFunction*, const char*);
extern "C" AsmIRBasicBlock* ir_function_current_block(AsmIRFunction*);
extern "C" void ir_function_set_current_block(AsmIRFunction*, std::size_t);
extern "C" AsmIRFunction* ir_module_add_function(AsmIRModule*, const char*, AsmIRParameter*, AsmIRType*);
extern "C" AsmIRFunction* ir_module_find_function(AsmIRModule*, const char*);
extern "C" int ir_module_add_global(AsmIRModule*, const char*, AsmIRType*);
extern "C" int ir_module_add_external_symbol(AsmIRModule*, const char*);
extern "C" int ir_module_add_string_constant(AsmIRModule*, const char*, const char*);
extern "C" void ir_module_dump_to_string(AsmIRModule*, char*, std::size_t);

namespace {

constexpr int TypeVoid = 0;
constexpr int TypeInteger = 1;
constexpr int TypeLong = 2;
constexpr int TypeDouble = 3;
constexpr int TypeBoolean = 4;
constexpr int TypePointer = 5;
constexpr int TypeArray = 6;
constexpr int TypeString = 7;

constexpr int SemVoid = 0;
constexpr int SemInteger = 1;
constexpr int SemLong = 2;
constexpr int SemDouble = 3;
constexpr int SemBoolean = 4;
constexpr int SemString = 5;
constexpr int SemClass = 6;
constexpr int SemArray = 7;
constexpr int SemUnknown = 8;

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
constexpr int OpNeg = 10;
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
constexpr int OpZExt = 28;
constexpr int OpSExt = 29;
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
    if (actual != nullptr && std::string(actual) == expected) {
        std::cout << "PASS " << name << '\n';
        return;
    }
    std::cout << "FAIL " << name << " expected [" << expected << "] got [" << (actual ? actual : "<null>") << "]\n";
    ++failures;
}

void expect_contains(const std::string& name, const char* actual, const char* needle) {
    expect_true(name, actual != nullptr && std::string(actual).find(needle) != std::string::npos);
}

AsmIRType type(int kind, bool file_backed = false, AsmIRType* element = nullptr) {
    AsmIRType result{};
    ir_type_init(&result, kind, file_backed ? 1 : 0, element);
    return result;
}

AsmIRInstruction inst(int opcode, AsmIRType t, const char* result = "") {
    AsmIRInstruction i{};
    i.opcode = opcode;
    i.type = t;
    ir_copy_cstr(i.result, result, sizeof(i.result));
    return i;
}

void instruction_expect(int opcode, AsmIRType t, const char* result, const char** operands,
                        std::size_t operand_count, const char* expected) {
    AsmIRInstruction i = inst(opcode, t, result);
    for (std::size_t idx = 0; idx < operand_count && idx < 4; ++idx) {
        i.operands[idx] = operands[idx];
    }
    i.operand_count = operand_count;
    char out[256]{};
    ir_instruction_to_string(&i, out, sizeof(out));
    expect_text(std::string("instruction ") + expected, out, expected);
}

void positive_scenarios() {
    char out[1024]{};
    AsmIRType i32 = type(TypeInteger);
    AsmIRType file_i32 = type(TypeInteger, true);
    AsmIRType i64 = type(TypeLong);
    AsmIRType f64 = type(TypeDouble);
    AsmIRType boolean = type(TypeBoolean);
    AsmIRType ptr = type(TypePointer);
    AsmIRType str = type(TypeString);
    AsmIRType file_str = type(TypeString, true);
    AsmIRType arr_i32 = type(TypeArray, false, &i32);
    AsmIRType arr_plain = type(TypeArray);

    expect_int("strlen", ir_strlen("Integer"), 7);
    expect_true("streq exact", ir_streq("entry", "entry") != 0);
    ir_copy_cstr(out, "abc", sizeof(out));
    ir_append_cstr(out, "def", sizeof(out));
    ir_append_int(out, -12, sizeof(out));
    expect_text("copy append int", out, "abcdef-12");

    ir_type_to_string(&i32, out, sizeof(out));
    expect_text("type i32", out, "i32");
    ir_type_to_string(&file_i32, out, sizeof(out));
    expect_text("type file i32", out, "file<i32>");
    ir_type_to_string(&i64, out, sizeof(out));
    expect_text("type i64", out, "i64");
    ir_type_to_string(&f64, out, sizeof(out));
    expect_text("type f64", out, "f64");
    ir_type_to_string(&boolean, out, sizeof(out));
    expect_text("type bool", out, "bool");
    ir_type_to_string(&ptr, out, sizeof(out));
    expect_text("type ptr", out, "ptr");
    ir_type_to_string(&str, out, sizeof(out));
    expect_text("type string", out, "string");
    ir_type_to_string(&file_str, out, sizeof(out));
    expect_text("type file string", out, "file<string>");
    ir_type_to_string(&arr_i32, out, sizeof(out));
    expect_text("type array", out, "array<i32>");
    ir_type_to_string(&arr_plain, out, sizeof(out));
    expect_text("type array plain", out, "array");

    AsmIRType void_type = type(TypeVoid);
    expect_int("size void", ir_type_size_bytes(&void_type), 0);
    expect_int("size i32", ir_type_size_bytes(&i32), 8);
    expect_int("size file i32", ir_type_size_bytes(&file_i32), 16);
    expect_int("size string", ir_type_size_bytes(&str), 16);
    expect_true("integer family bool", ir_type_is_integer_family(&boolean) != 0);
    expect_true("numeric double", ir_type_is_numeric(&f64) != 0);

    AsmSemanticType sem_i64{SemLong, 1, nullptr};
    AsmIRType sem_result{};
    ir_semantic_to_ir_type(&sem_result, &sem_i64, nullptr);
    expect_int("semantic long kind", sem_result.kind, TypeLong);
    expect_int("semantic file flag", sem_result.is_file_backed, 1);

    AsmSemanticType sem_array{SemArray, 0, nullptr};
    ir_semantic_to_ir_type(&sem_result, &sem_array, &i32);
    expect_int("semantic array kind", sem_result.kind, TypeArray);
    expect_true("semantic array element", sem_result.element_type == &i32);

    AsmIRInstruction ci = inst(OpConstInt, i32, "%1");
    ci.int_value = 31;
    ir_instruction_to_string(&ci, out, sizeof(out));
    expect_text("const int string", out, "    %1 = const i32 31");

    AsmIRInstruction cd = inst(OpConstDouble, f64, "%d");
    ir_copy_cstr(cd.double_text, "3.14", sizeof(cd.double_text));
    ir_instruction_to_string(&cd, out, sizeof(out));
    expect_text("const double string", out, "    %d = const f64 3.14");

    AsmIRInstruction cb = inst(OpConstBool, boolean, "%b");
    cb.int_value = 1;
    ir_instruction_to_string(&cb, out, sizeof(out));
    expect_text("const bool string", out, "    %b = const bool true");

    AsmIRInstruction cp = inst(OpConstPtr, ptr, "%p");
    ir_copy_cstr(cp.string_value, "str_0", sizeof(cp.string_value));
    ir_instruction_to_string(&cp, out, sizeof(out));
    expect_text("const ptr string", out, "    %p = const ptr str_0");

    const char* ab[]{"a", "b"};
    instruction_expect(OpAdd, i32, "%add", ab, 2, "    %add = add a, b");
    instruction_expect(OpSub, i32, "%sub", ab, 2, "    %sub = sub a, b");
    instruction_expect(OpMul, i32, "%mul", ab, 2, "    %mul = mul a, b");
    instruction_expect(OpDiv, i32, "%div", ab, 2, "    %div = div a, b");
    instruction_expect(OpMod, i32, "%mod", ab, 2, "    %mod = mod a, b");
    instruction_expect(OpEQ, boolean, "%eq", ab, 2, "    %eq = eq a, b");
    instruction_expect(OpNE, boolean, "%ne", ab, 2, "    %ne = ne a, b");
    instruction_expect(OpLT, boolean, "%lt", ab, 2, "    %lt = lt a, b");
    instruction_expect(OpLE, boolean, "%le", ab, 2, "    %le = le a, b");
    instruction_expect(OpGT, boolean, "%gt", ab, 2, "    %gt = gt a, b");
    instruction_expect(OpGE, boolean, "%ge", ab, 2, "    %ge = ge a, b");
    instruction_expect(OpAnd, boolean, "%and", ab, 2, "    %and = and a, b");
    instruction_expect(OpOr, boolean, "%or", ab, 2, "    %or = or a, b");
    const char* one[]{"x"};
    instruction_expect(OpNeg, i32, "%neg", one, 1, "    %neg = neg x");
    instruction_expect(OpNot, boolean, "%not", one, 1, "    %not = not x");
    instruction_expect(OpLoad, i32, "%load", one, 1, "    %load = load x");
    instruction_expect(OpAlloca, i32, "%slot", nullptr, 0, "    %slot = alloca i32");
    instruction_expect(OpArrayGet, i32, "%get", ab, 2, "    %get = array_get a, b");
    instruction_expect(OpArrayLen, i32, "%len", one, 1, "    %len = array_len x");
    instruction_expect(OpZExt, i64, "%wide", one, 1, "    %wide = zext x to i64");
    instruction_expect(OpSExt, i64, "%sw", one, 1, "    %sw = sext x to i64");

    AsmIRInstruction label = inst(OpLabel, type(TypeVoid));
    ir_copy_cstr(label.label_name, "done", sizeof(label.label_name));
    ir_instruction_to_string(&label, out, sizeof(out));
    expect_text("label string", out, "done:");

    const char* branch_ops[]{"cond", "then", "else"};
    instruction_expect(OpBranch, boolean, "", branch_ops, 3, "    br cond, then, else");
    const char* call_ops[]{"fn", "x", "y"};
    instruction_expect(OpCall, i32, "%call", call_ops, 3, "%call = call fn, x, y");
    instruction_expect(OpCallRuntime, i32, "", call_ops, 1, "    call_runtime fn");
    const char* three[]{"arr", "idx", "value"};
    instruction_expect(OpArraySet, type(TypeVoid), "", three, 3, "    array_set arr, idx, value");
    instruction_expect(OpArrayPush, type(TypeVoid), "", ab, 2, "    array_push a, b");
    instruction_expect(OpArrayNew, arr_i32, "%arr", one, 1, "    %arr = array_new array<i32>, x");

    AsmIRInstruction inst_store = inst(OpStore, type(TypeVoid));
    inst_store.operands[0] = "src";
    inst_store.operands[1] = "dst";
    inst_store.operand_count = 2;
    ir_instruction_to_string(&inst_store, out, sizeof(out));
    expect_text("store string", out, "    store src, dst");

    AsmIRInstruction block_storage[4]{};
    AsmIRBasicBlock block{};
    ir_copy_cstr(block.name, "entry", sizeof(block.name));
    block.instructions = block_storage;
    block.instruction_capacity = 4;
    expect_false("empty block terminated", ir_block_is_terminated(&block) != 0);
    expect_true("block add instruction", ir_block_add_instruction(&block, &ci) != 0);
    expect_false("const block terminated", ir_block_is_terminated(&block) != 0);
    AsmIRInstruction ret = inst(OpRet, type(TypeVoid));
    expect_true("block add ret", ir_block_add_instruction(&block, &ret) != 0);
    expect_true("ret block terminated", ir_block_is_terminated(&block) != 0);

    AsmIRBasicBlock function_blocks[3]{};
    AsmIRFunction fn{};
    ir_copy_cstr(fn.name, "main", sizeof(fn.name));
    fn.blocks = function_blocks;
    fn.block_capacity = 3;
    AsmIRBasicBlock* entry = ir_function_entry_block(&fn);
    expect_true("entry block created", entry != nullptr);
    expect_text("entry block name", entry->name, "entry");
    AsmIRBasicBlock* extra = ir_function_add_block(&fn, "after");
    expect_true("add block", extra != nullptr);
    expect_true("find block", ir_function_find_block(&fn, "after") == extra);
    ir_function_set_current_block(&fn, 1);
    expect_true("current block", ir_function_current_block(&fn) == extra);

    AsmIRFunction functions[2]{};
    AsmIRGlobal globals[2]{};
    AsmIRStringConstant strings[2]{};
    const char* externs[2]{};
    AsmIRModule module{functions, 0, 2, globals, 0, 2, strings, 0, 2, externs, 0, 2};
    expect_true("module add function", ir_module_add_function(&module, "main", nullptr, &i32) != nullptr);
    expect_true("module find function", ir_module_find_function(&module, "main") != nullptr);
    expect_true("module add global", ir_module_add_global(&module, "g", &i64) != 0);
    expect_true("module duplicate global ok", ir_module_add_global(&module, "g", &i64) != 0);
    expect_int("module global dedupe", module.global_count, 1);
    expect_true("module add external", ir_module_add_external_symbol(&module, "print") != 0);
    expect_true("module duplicate external ok", ir_module_add_external_symbol(&module, "print") != 0);
    expect_int("module external dedupe", module.external_count, 1);
    expect_true("module add string", ir_module_add_string_constant(&module, "str_0", "Hi") != 0);
    expect_text("module string name", strings[0].name, "str_0");
    expect_text("module string value", strings[0].value, "Hi");
    ir_module_dump_to_string(&module, out, sizeof(out));
    expect_contains("dump global", out, "global g: i64");
    expect_contains("dump function", out, "func main() -> i32");
}

void negative_scenarios() {
    char out[64]{};
    expect_int("strlen null", ir_strlen(nullptr), 0);
    expect_false("streq null", ir_streq(nullptr, "x") != 0);
    ir_copy_cstr(out, "abcdef", 4);
    expect_text("copy truncates", out, "abc");

    AsmIRType unknown = type(44);
    ir_type_to_string(&unknown, out, sizeof(out));
    expect_text("unknown type", out, "unknown");
    expect_int("null type size defaults", ir_type_size_bytes(nullptr), 8);
    AsmIRType ptr_type = type(TypePointer);
    expect_false("pointer not numeric", ir_type_is_numeric(&ptr_type) != 0);

    AsmIRInstruction bad = inst(99, type(TypeVoid));
    ir_instruction_to_string(&bad, out, sizeof(out));
    expect_text("unknown instruction", out, "    <unknown>");

    AsmIRInstruction block_storage[1]{};
    AsmIRBasicBlock block{};
    block.instructions = block_storage;
    block.instruction_capacity = 1;
    AsmIRInstruction ci = inst(OpConstInt, type(TypeInteger), "%1");
    expect_true("block add first", ir_block_add_instruction(&block, &ci) != 0);
    expect_false("block capacity full", ir_block_add_instruction(&block, &ci) != 0);

    AsmIRBasicBlock function_blocks[1]{};
    AsmIRFunction fn{};
    fn.blocks = function_blocks;
    fn.block_capacity = 1;
    expect_true("add only block", ir_function_add_block(&fn, "one") != nullptr);
    expect_true("add block capacity null", ir_function_add_block(&fn, "two") == nullptr);
    ir_function_set_current_block(&fn, 9);
    expect_true("current out of range null", ir_function_current_block(&fn) == nullptr);
    expect_true("find missing null", ir_function_find_block(&fn, "missing") == nullptr);

    AsmIRFunction functions[1]{};
    AsmIRGlobal globals[1]{};
    AsmIRStringConstant strings[1]{};
    const char* externs[1]{};
    AsmIRModule module{functions, 0, 1, globals, 0, 1, strings, 0, 1, externs, 0, 1};
    AsmIRType i32 = type(TypeInteger);
    expect_true("module function one", ir_module_add_function(&module, "one", nullptr, &i32) != nullptr);
    expect_true("module function capacity null", ir_module_add_function(&module, "two", nullptr, &i32) == nullptr);
    expect_true("module global one", ir_module_add_global(&module, "g1", &i32) != 0);
    expect_false("module global capacity full", ir_module_add_global(&module, "g2", &i32) != 0);
    expect_true("module external one", ir_module_add_external_symbol(&module, "e1") != 0);
    expect_false("module external capacity full", ir_module_add_external_symbol(&module, "e2") != 0);
    expect_true("module string one", ir_module_add_string_constant(&module, "s1", "v1") != 0);
    expect_false("module string capacity full", ir_module_add_string_constant(&module, "s2", "v2") != 0);

    ir_type_to_string(nullptr, nullptr, 0);
    ir_instruction_to_string(nullptr, nullptr, 0);
    ir_block_add_instruction(nullptr, nullptr);
    ir_function_entry_block(nullptr);
    ir_module_dump_to_string(nullptr, nullptr, 0);
    expect_true("null calls survive", true);
}

} // namespace

int main() {
    std::cout.setf(std::ios::unitbuf);
    positive_scenarios();
    negative_scenarios();

    if (failures == 0) {
        std::cout << "IR asm scenarios passed\n";
        return 0;
    }

    std::cout << "IR asm scenarios failed: " << failures << '\n';
    return 1;
}
