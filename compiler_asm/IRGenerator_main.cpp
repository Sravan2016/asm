#include <cstddef>
#include <cstdint>
#include <cstring>
#include <iostream>
#include <string>

struct AsmTypeRef {
    int kind;
    int is_file_backed;
    int is_array;
    int element_kind;
};

struct AsmInstruction {
    int opcode;
    int type;
    char result[32];
    char op0[32];
    char op1[32];
    char op2[32];
    std::int64_t int_value;
};

struct AsmStringConstant {
    char name[32];
    char value[64];
    int raw;
    std::uint32_t pad0;
};

struct AsmSymbol {
    char name[32];
    char value[32];
    int type;
    std::uint32_t pad0;
};

struct AsmIRGeneratorState {
    AsmInstruction* instructions;
    std::size_t instruction_count;
    std::size_t instruction_capacity;
    int temp_counter;
    int label_counter;
    int lambda_counter;
    int scope_depth;
    int owned_count;
    std::uint32_t pad0;
    AsmStringConstant* strings;
    std::size_t string_count;
    std::size_t string_capacity;
    AsmSymbol* symbols;
    std::size_t symbol_count;
    std::size_t symbol_capacity;
    char current_class[32];
    char current_function[32];
    char file_line_slot[32];
};

struct AsmExpr {
    int kind;
    AsmTypeRef type;
    char text[32];
    AsmExpr* left;
    AsmExpr* right;
    AsmExpr* extra;
    std::int64_t int_value;
};

struct AsmStmt {
    int kind;
    std::uint32_t pad0;
    char name[32];
    AsmTypeRef type;
    AsmExpr* expr;
    AsmStmt* body;
    std::size_t body_count;
};

struct AsmMethod {
    char name[32];
    AsmStmt* body;
    std::size_t body_count;
};

struct AsmClass {
    char name[32];
    AsmMethod* methods;
    std::size_t method_count;
    AsmStmt* fields;
    std::size_t field_count;
};

struct AsmProgram {
    AsmClass* classes;
    std::size_t class_count;
};

static_assert(sizeof(AsmTypeRef) == 16);
static_assert(sizeof(AsmInstruction) == 144);
static_assert(sizeof(AsmStringConstant) == 104);
static_assert(sizeof(AsmSymbol) == 72);
static_assert(sizeof(AsmIRGeneratorState) == 192);
static_assert(sizeof(AsmExpr) == 88);
static_assert(sizeof(AsmStmt) == 80);
static_assert(sizeof(AsmMethod) == 48);
static_assert(sizeof(AsmClass) == 64);
static_assert(sizeof(AsmProgram) == 16);

extern "C" void irgen_init(AsmIRGeneratorState*, AsmInstruction*, std::size_t, AsmStringConstant*, std::size_t, AsmSymbol*, std::size_t);
extern "C" void irgen_generate(AsmIRGeneratorState*, AsmProgram*);
extern "C" void irgen_visit_class(AsmIRGeneratorState*, AsmClass*);
extern "C" void irgen_visit_method(AsmIRGeneratorState*, AsmMethod*);
extern "C" void irgen_visit_synthetic_aleka_accessor(AsmIRGeneratorState*);
extern "C" void irgen_visit_synthetic_aleka_factory(AsmIRGeneratorState*);
extern "C" void irgen_visit_synthetic_aleka_to_string(AsmIRGeneratorState*);
extern "C" void irgen_visit_synthetic_aleka_to_object(AsmIRGeneratorState*);
extern "C" void irgen_visit_statement_sequence(AsmIRGeneratorState*, AsmStmt*, std::size_t);
extern "C" void irgen_visit_statement(AsmIRGeneratorState*, AsmStmt*);
extern "C" void irgen_visit_variable_decl(AsmIRGeneratorState*, AsmStmt*);
extern "C" void irgen_visit_expression_stmt(AsmIRGeneratorState*, AsmStmt*);
extern "C" void irgen_visit_print_stmt(AsmIRGeneratorState*, AsmStmt*);
extern "C" void irgen_visit_guard_block(AsmIRGeneratorState*, AsmStmt*);
extern "C" void irgen_visit_while_block(AsmIRGeneratorState*, AsmStmt*);
extern "C" void irgen_visit_for_each(AsmIRGeneratorState*, AsmStmt*);
extern "C" void irgen_visit_switch(AsmIRGeneratorState*, AsmStmt*);
extern "C" void irgen_visit_return(AsmIRGeneratorState*, AsmStmt*);
extern "C" const char* irgen_visit_expression(AsmIRGeneratorState*, AsmExpr*, char*, std::size_t);
extern "C" const char* irgen_visit_identifier(AsmIRGeneratorState*, AsmExpr*);
extern "C" const char* irgen_visit_literal(AsmIRGeneratorState*, AsmExpr*, char*, std::size_t);
extern "C" const char* irgen_visit_binary(AsmIRGeneratorState*, AsmExpr*, char*, std::size_t);
extern "C" const char* irgen_visit_unary(AsmIRGeneratorState*, AsmExpr*, char*, std::size_t);
extern "C" const char* irgen_visit_postfix(AsmIRGeneratorState*, AsmExpr*, char*, std::size_t);
extern "C" const char* irgen_visit_assignment(AsmIRGeneratorState*, AsmExpr*, char*, std::size_t);
extern "C" const char* irgen_visit_conditional(AsmIRGeneratorState*, AsmExpr*, char*, std::size_t);
extern "C" const char* irgen_visit_call(AsmIRGeneratorState*, AsmExpr*, char*, std::size_t);
extern "C" const char* irgen_visit_member(AsmIRGeneratorState*, AsmExpr*);
extern "C" const char* irgen_visit_index(AsmIRGeneratorState*, AsmExpr*, char*, std::size_t);
extern "C" const char* irgen_visit_grouping(AsmIRGeneratorState*, AsmExpr*, char*, std::size_t);
extern "C" const char* irgen_visit_array_literal(AsmIRGeneratorState*, AsmExpr*, char*, std::size_t);
extern "C" const char* irgen_visit_lambda(AsmIRGeneratorState*, char*, std::size_t);
extern "C" const char* irgen_load_symbol_value(AsmIRGeneratorState*, const char*);
extern "C" const char* irgen_emit_string_constant(AsmIRGeneratorState*, const char*, char*, std::size_t);
extern "C" const char* irgen_ensure_file_line_slot(AsmIRGeneratorState*);
extern "C" void irgen_ir_type_for_typeref(AsmTypeRef*, AsmTypeRef*);
extern "C" void irgen_get_expr_type(AsmTypeRef*, AsmExpr*);
extern "C" void irgen_new_temporary(AsmIRGeneratorState*, char*, std::size_t);
extern "C" void irgen_new_label(AsmIRGeneratorState*, char*, std::size_t);
extern "C" void irgen_new_lambda_name(AsmIRGeneratorState*, char*, std::size_t);
extern "C" int irgen_emit(AsmIRGeneratorState*, int, const char*, const char*, const char*);
extern "C" void irgen_add_successor(AsmIRGeneratorState*, const char*);
extern "C" void irgen_push_scope(AsmIRGeneratorState*);
extern "C" void irgen_pop_scope(AsmIRGeneratorState*);
extern "C" int irgen_scope_depth(AsmIRGeneratorState*);
extern "C" void irgen_emit_all_scope_cleanups(AsmIRGeneratorState*);
extern "C" void irgen_emit_cleanup(AsmIRGeneratorState*, const char*);
extern "C" void irgen_register_owned_value(AsmIRGeneratorState*, const char*, const char*, int);
extern "C" void irgen_release_owned_value(AsmIRGeneratorState*, const char*);
extern "C" void irgen_transfer_ownership(AsmIRGeneratorState*, const char*, const char*, int);
extern "C" void irgen_assign_owned_value(AsmIRGeneratorState*, const char*, const char*, AsmTypeRef*);
extern "C" void irgen_free_owned_storage_before_store(AsmIRGeneratorState*, const char*);
extern "C" const char* irgen_cleanup_info_for_ir_type(AsmTypeRef*, int);
extern "C" const char* irgen_preserved_owner_for_return(AsmExpr*, const char*);
extern "C" const char* irgen_type_suffix(AsmTypeRef*);
extern "C" std::size_t irgen_instruction_count(AsmIRGeneratorState*);
extern "C" std::size_t irgen_string_count(AsmIRGeneratorState*);
extern "C" void irgen_decode_string_literal(const char*, char*, std::size_t);
extern "C" const char* irgen_file_create_runtime(AsmTypeRef*);
extern "C" const char* irgen_file_get_runtime(AsmTypeRef*);
extern "C" const char* irgen_file_set_runtime(AsmTypeRef*);
extern "C" const char* irgen_normalize_map_method(const char*);
extern "C" const char* irgen_map_runtime_name(const char*);
extern "C" const char* irgen_file_runtime_name(const char*);
extern "C" std::uint64_t irgen_aleka_json_type_tag(AsmTypeRef*);
extern "C" std::uint64_t irgen_aleka_json_field_descriptor(std::uint64_t, AsmTypeRef*);
extern "C" void irgen_accessor_suffix_for_field_name(const char*, char*, std::size_t);
extern "C" const char* irgen_array_join_runtime_name(AsmTypeRef*);

namespace {
constexpr int TypeInteger = 1;
constexpr int TypeLong = 2;
constexpr int TypeDouble = 3;
constexpr int TypeBoolean = 4;
constexpr int TypePointer = 5;
constexpr int TypeArray = 6;
constexpr int TypeString = 7;
constexpr int ExprIdentifier = 0;
constexpr int ExprLiteral = 1;
constexpr int ExprBinary = 2;
constexpr int ExprCall = 6;
constexpr int ExprIndex = 8;
constexpr int ExprArrayLiteral = 10;
constexpr int StmtVariable = 0;
constexpr int StmtPrint = 2;
constexpr int StmtReturn = 7;
constexpr int OpAlloca = 27;
constexpr int OpRet = 23;
constexpr int OpCallRuntime = 40;

int failures = 0;

void expect_true(const std::string& name, bool value) {
    if (value) std::cout << "PASS " << name << '\n';
    else { std::cout << "FAIL " << name << '\n'; ++failures; }
}
void expect_false(const std::string& name, bool value) { expect_true(name, !value); }
void expect_int(const std::string& name, std::uint64_t actual, std::uint64_t expected) {
    if (actual == expected) std::cout << "PASS " << name << '\n';
    else { std::cout << "FAIL " << name << " expected " << expected << " got " << actual << '\n'; ++failures; }
}
void expect_text(const std::string& name, const char* actual, const char* expected) {
    if (actual && std::string(actual) == expected) std::cout << "PASS " << name << '\n';
    else { std::cout << "FAIL " << name << " expected [" << expected << "] got [" << (actual ? actual : "<null>") << "]\n"; ++failures; }
}

template <std::size_t I, std::size_t S, std::size_t Y>
AsmIRGeneratorState fresh(AsmInstruction (&insts)[I], AsmStringConstant (&strings)[S], AsmSymbol (&symbols)[Y]) {
    std::memset(insts, 0, sizeof(insts));
    std::memset(strings, 0, sizeof(strings));
    std::memset(symbols, 0, sizeof(symbols));
    AsmIRGeneratorState state{};
    irgen_init(&state, insts, I, strings, S, symbols, Y);
    return state;
}

AsmTypeRef type(int kind, bool file = false, bool array = false, int elem = 0) {
    return {kind, file ? 1 : 0, array ? 1 : 0, elem};
}

void positive_scenarios() {
    AsmInstruction insts[128]{};
    AsmStringConstant strings[16]{};
    AsmSymbol symbols[16]{};
    AsmIRGeneratorState state = fresh(insts, strings, symbols);
    char out[64]{};

    AsmTypeRef file_i32 = type(TypeInteger, true);
    AsmTypeRef file_long = type(TypeLong, true);
    AsmTypeRef file_double = type(TypeDouble, true);
    AsmTypeRef file_bool = type(TypeBoolean, true);
    AsmTypeRef str = type(TypeString);
    AsmTypeRef arr_int = type(TypeArray, false, false, TypeInteger);

    expect_text("file create int", irgen_file_create_runtime(&file_i32), "fileint_create_auto");
    expect_text("file get long", irgen_file_get_runtime(&file_long), "filelong_get");
    expect_text("file set double", irgen_file_set_runtime(&file_double), "filedouble_set");
    expect_text("file create bool", irgen_file_create_runtime(&file_bool), "filebool_create_auto");
    expect_text("map containsKey", irgen_map_runtime_name("containsKey"), "map_contains_key");
    expect_text("map isEmpty", irgen_map_runtime_name("isEmpty"), "map_is_empty");
    expect_text("file read", irgen_file_runtime_name("read_all"), "file_read_all");
    expect_text("file line", irgen_file_runtime_name("get_line_at"), "file_get_line_at");
    expect_int("aleka string tag", irgen_aleka_json_type_tag(&str), 5);
    expect_int("aleka descriptor", irgen_aleka_json_field_descriptor(3, &file_i32), (3u << 8) | 1u);
    irgen_accessor_suffix_for_field_name("userName", out, sizeof(out));
    expect_text("accessor suffix", out, "UserName");
    expect_text("array join int", irgen_array_join_runtime_name(&arr_int), "array_join_int");
    expect_text("type suffix string", irgen_type_suffix(&str), "_string");

    irgen_decode_string_literal("\"Hi\\nThere\"", out, sizeof(out));
    expect_true("decode newline", std::string(out) == std::string("Hi\nThere"));
    irgen_new_temporary(&state, out, sizeof(out));
    expect_text("temp 0", out, "%t0");
    irgen_new_temporary(&state, out, sizeof(out));
    expect_text("temp 1", out, "%t1");
    irgen_new_label(&state, out, sizeof(out));
    expect_text("label 0", out, "L0");
    irgen_new_lambda_name(&state, out, sizeof(out));
    expect_text("lambda 0", out, "lambda_0");

    expect_true("emit instruction", irgen_emit(&state, OpAlloca, "slot", "", "") != 0);
    expect_int("instruction count", irgen_instruction_count(&state), 1);
    expect_text("emit result", insts[0].result, "slot");

    irgen_push_scope(&state);
    irgen_push_scope(&state);
    expect_int("scope depth", irgen_scope_depth(&state), 2);
    irgen_pop_scope(&state);
    expect_int("scope pop", irgen_scope_depth(&state), 1);
    irgen_register_owned_value(&state, "s", "string_free", 0);
    expect_int("owned inc", state.owned_count, 1);
    irgen_release_owned_value(&state, "s");
    expect_int("owned release", state.owned_count, 0);
    expect_text("cleanup string", irgen_cleanup_info_for_ir_type(&str, 0), "string_free");

    expect_text("string constant", irgen_emit_string_constant(&state, "Hello", out, sizeof(out)), "str_0");
    expect_int("string count", irgen_string_count(&state), 1);
    expect_text("file slot", irgen_ensure_file_line_slot(&state), "__file_line_slot");

    AsmExpr lit{ExprLiteral, type(TypeInteger), "42", nullptr, nullptr, nullptr, 0};
    expect_text("visit literal", irgen_visit_literal(&state, &lit, out, sizeof(out)), "%t2");
    expect_int("literal emitted", irgen_instruction_count(&state), 2);
    AsmExpr id{ExprIdentifier, type(TypeInteger), "value", nullptr, nullptr, nullptr, 0};
    expect_text("visit identifier", irgen_visit_identifier(&state, &id), "value");
    AsmExpr bin{ExprBinary, type(TypeInteger), "+", &id, &lit, nullptr, 0};
    expect_text("visit binary", irgen_visit_binary(&state, &bin, out, sizeof(out)), "%t3");
    AsmExpr arr{ExprArrayLiteral, type(TypeArray), "arr", nullptr, nullptr, nullptr, 0};
    irgen_visit_array_literal(&state, &arr, out, sizeof(out));
    AsmExpr idx{ExprIndex, type(TypeInteger), "arr", &arr, &lit, nullptr, 0};
    irgen_visit_index(&state, &idx, out, sizeof(out));
    AsmExpr call{ExprCall, type(TypePointer), "fn", nullptr, nullptr, nullptr, 0};
    irgen_visit_call(&state, &call, out, sizeof(out));
    expect_true("expression visits emitted", irgen_instruction_count(&state) >= 6);

    AsmStmt var{};
    var.kind = StmtVariable;
    std::strcpy(var.name, "local");
    var.type = type(TypeInteger);
    irgen_visit_variable_decl(&state, &var);
    expect_int("var alloca opcode", insts[state.instruction_count - 1].opcode, OpAlloca);
    AsmStmt print{};
    print.kind = StmtPrint;
    irgen_visit_print_stmt(&state, &print);
    expect_int("print call opcode", insts[state.instruction_count - 1].opcode, OpCallRuntime);
    AsmStmt ret{};
    ret.kind = StmtReturn;
    irgen_visit_return(&state, &ret);
    expect_int("return opcode", insts[state.instruction_count - 1].opcode, OpRet);

    AsmStmt body[]{var, print, ret};
    AsmMethod method{};
    std::strcpy(method.name, "main");
    method.body = body;
    method.body_count = 3;
    AsmClass cls{};
    std::strcpy(cls.name, "App");
    cls.methods = &method;
    cls.method_count = 1;
    AsmProgram program{&cls, 1};
    irgen_generate(&state, &program);
    expect_text("current class", state.current_class, "App");
    expect_text("current function", state.current_function, "main");
    expect_true("generate emitted", state.instruction_count >= 3);
    irgen_visit_synthetic_aleka_accessor(&state);
    irgen_visit_synthetic_aleka_factory(&state);
    irgen_visit_synthetic_aleka_to_string(&state);
    irgen_visit_synthetic_aleka_to_object(&state);
    expect_true("synthetic emitted", state.instruction_count >= 7);
}

void negative_scenarios() {
    AsmInstruction insts[1]{};
    AsmStringConstant strings[1]{};
    AsmSymbol symbols[1]{};
    AsmIRGeneratorState state = fresh(insts, strings, symbols);
    char out[8]{};
    AsmTypeRef scalar = type(TypeInteger);
    AsmTypeRef array_typeref = type(TypeInteger, false, true);

    expect_text("non-file create empty", irgen_file_create_runtime(&scalar), "");
    expect_text("unknown map empty", irgen_map_runtime_name("missing"), "");
    expect_text("unknown file empty", irgen_file_runtime_name("missing"), "");
    expect_int("array aleka tag zero", irgen_aleka_json_type_tag(&array_typeref), 0);
    expect_int("bad descriptor zero", irgen_aleka_json_field_descriptor(2, &array_typeref), 0);
    irgen_decode_string_literal("\"abcdef\"", out, sizeof(out));
    expect_text("decode truncates", out, "abcdef");
    expect_true("emit one", irgen_emit(&state, OpAlloca, "a", "", "") != 0);
    expect_false("emit capacity full", irgen_emit(&state, OpAlloca, "b", "", "") != 0);
    expect_text("string first", irgen_emit_string_constant(&state, "A", out, sizeof(out)), "str_0");
    expect_true("string capacity null", irgen_emit_string_constant(&state, "B", out, sizeof(out)) == nullptr);
    irgen_pop_scope(&state);
    expect_int("scope stays zero", irgen_scope_depth(&state), 0);
    irgen_release_owned_value(&state, "missing");
    expect_int("owned stays zero", state.owned_count, 0);
    expect_text("visit expression null", irgen_visit_expression(&state, nullptr, out, sizeof(out)), "");

    irgen_init(nullptr, nullptr, 0, nullptr, 0, nullptr, 0);
    irgen_generate(nullptr, nullptr);
    irgen_visit_class(nullptr, nullptr);
    irgen_visit_method(nullptr, nullptr);
    irgen_visit_statement(nullptr, nullptr);
    irgen_visit_expression(nullptr, nullptr, nullptr, 0);
    irgen_emit(nullptr, 0, nullptr, nullptr, nullptr);
    irgen_push_scope(nullptr);
    irgen_pop_scope(nullptr);
    irgen_register_owned_value(nullptr, nullptr, nullptr, 0);
    irgen_release_owned_value(nullptr, nullptr);
    expect_true("null calls survive", true);
}
}

int main() {
    std::cout.setf(std::ios::unitbuf);
    positive_scenarios();
    negative_scenarios();
    if (failures == 0) {
        std::cout << "IRGenerator asm scenarios passed\n";
        return 0;
    }
    std::cout << "IRGenerator asm scenarios failed: " << failures << '\n';
    return 1;
}
