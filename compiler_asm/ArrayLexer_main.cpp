#include <cstddef>
#include <cstdint>
#include <iostream>
#include <string>

struct AsmArrayToken {
    int kind;
    std::uint32_t pad0;
    const char* array_name;
    const char* element_type;
    std::size_t element_type_len;
    int element_count;
    int location;
};

struct AsmArrayError {
    const char* message;
    int location;
    std::uint32_t pad0;
};

struct AsmArrayLexerState {
    AsmArrayToken* tokens;
    std::size_t token_count;
    std::size_t token_capacity;
    AsmArrayError* errors;
    std::size_t error_count;
    std::size_t error_capacity;
};

struct AsmTypeRef {
    const char* name;
    int is_array;
    std::uint32_t pad0;
};

struct AsmExpr {
    int kind;
    std::uint32_t pad0;
    const char* object_name;
    const char* method_name;
    AsmExpr** children;
    std::size_t child_count;
    int element_count;
    int location;
};

struct AsmStmt {
    int kind;
    std::uint32_t pad0;
    AsmExpr* expr;
    const char* name;
    AsmTypeRef* type;
    int initializer_kind;
    std::uint32_t pad1;
    int element_count;
    std::uint32_t pad2;
    AsmStmt* body;
    std::size_t body_count;
};

struct AsmMethod {
    AsmStmt* statements;
    std::size_t statement_count;
};

struct AsmClass {
    AsmMethod* methods;
    std::size_t method_count;
    AsmStmt* statements;
    std::size_t statement_count;
};

struct AsmProgram {
    AsmClass* classes;
    std::size_t class_count;
};

static_assert(sizeof(AsmArrayToken) == 40);
static_assert(sizeof(AsmArrayError) == 16);
static_assert(sizeof(AsmArrayLexerState) == 48);
static_assert(sizeof(AsmTypeRef) == 16);
static_assert(sizeof(AsmExpr) == 48);
static_assert(sizeof(AsmStmt) == 64);
static_assert(sizeof(AsmMethod) == 16);
static_assert(sizeof(AsmClass) == 32);
static_assert(sizeof(AsmProgram) == 16);

extern "C" void arraylexer_init(AsmArrayLexerState*, AsmArrayToken*, std::size_t, AsmArrayError*, std::size_t);
extern "C" void arraylexer_analyze(AsmArrayLexerState*, AsmProgram*);
extern "C" std::size_t arraylexer_tokens_count(AsmArrayLexerState*);
extern "C" std::size_t arraylexer_errors_count(AsmArrayLexerState*);
extern "C" int arraylexer_has_errors(AsmArrayLexerState*);
extern "C" const char* arraylexer_extract_type_name(AsmTypeRef*);
extern "C" const char* arraylexer_extract_element_type_name(AsmTypeRef*);
extern "C" std::size_t arraylexer_extract_element_type_length(AsmTypeRef*);
extern "C" int arraylexer_is_array_type(AsmTypeRef*);
extern "C" void arraylexer_analyze_class(AsmArrayLexerState*, AsmClass*);
extern "C" void arraylexer_analyze_method(AsmArrayLexerState*, AsmMethod*);
extern "C" void arraylexer_analyze_statement(AsmArrayLexerState*, AsmStmt*);
extern "C" void arraylexer_analyze_expression(AsmArrayLexerState*, AsmExpr*);
extern "C" int arraylexer_analyze_type_ref(AsmTypeRef*);
extern "C" void arraylexer_analyze_array_assignment(AsmArrayLexerState*, const char*, AsmTypeRef*, int, int);
extern "C" void arraylexer_analyze_array_literal(AsmArrayLexerState*, int);
extern "C" void arraylexer_analyze_index_access(AsmArrayLexerState*, const char*, int);
extern "C" int arraylexer_add_error(AsmArrayLexerState*, const char*, int);
extern "C" int arraylexer_emit_token(AsmArrayLexerState*, int, const char*, const char*, std::size_t, int, int);
extern "C" int arraylexer_is_array_type_name(const char*);
extern "C" std::size_t arraylexer_element_type_length(const char*);
extern "C" int arraylexer_is_supported_array_method(const char*);
extern "C" const char* arraylexer_operation_label(const char*);
extern "C" std::size_t arraylexer_strlen(const char*);
extern "C" int arraylexer_streq(const char*, const char*);

namespace {

constexpr int ArrayDeclaration = 0;
constexpr int ArrayLiteral = 1;
constexpr int ArrayIndex = 2;
constexpr int ArrayElement = 3;

constexpr int StmtExpression = 0;
constexpr int StmtVariableDecl = 1;
constexpr int StmtPrint = 2;
constexpr int StmtGuardBlock = 3;

constexpr int ExprCall = 0;
constexpr int ExprIndex = 7;
constexpr int ExprArrayLiteral = 8;

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

void expect_size(const std::string& name, std::size_t actual, std::size_t expected) {
    if (actual == expected) {
        std::cout << "PASS " << name << '\n';
        return;
    }
    std::cout << "FAIL " << name << " expected " << expected << " got " << actual << '\n';
    ++failures;
}

void expect_int(const std::string& name, int actual, int expected) {
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

AsmArrayLexerState fresh_state(AsmArrayToken (&tokens)[32], AsmArrayError (&errors)[8]) {
    AsmArrayLexerState state{};
    arraylexer_init(&state, tokens, 32, errors, 8);
    return state;
}

void positive_scenarios() {
    AsmArrayToken tokens[32]{};
    AsmArrayError errors[8]{};
    AsmArrayLexerState state = fresh_state(tokens, errors);
    AsmTypeRef integer_array{"Integer[]", 1, 0};

    expect_size("strlen basic", arraylexer_strlen("Integer[]"), 9);
    expect_true("streq exact", arraylexer_streq("add", "add") != 0);
    expect_true("array type suffix", arraylexer_is_array_type_name("Integer[]") != 0);
    expect_size("element type suffix length", arraylexer_element_type_length("Integer[]"), 7);
    expect_true("supported method", arraylexer_is_supported_array_method("contains") != 0);
    expect_text("operation label", arraylexer_operation_label("add"), "Operation:add");

    expect_text("extract type name", arraylexer_extract_type_name(&integer_array), "Integer[]");
    expect_text("extract element type name", arraylexer_extract_element_type_name(&integer_array), "Integer[]");
    expect_size("extract element length", arraylexer_extract_element_type_length(&integer_array), 7);
    expect_true("is array type", arraylexer_is_array_type(&integer_array) != 0);
    expect_true("analyze type ref", arraylexer_analyze_type_ref(&integer_array) != 0);

    arraylexer_analyze_array_assignment(&state, "nums", &integer_array, 1, 4);
    expect_size("assignment token count", arraylexer_tokens_count(&state), 1);
    expect_int("assignment literal kind", tokens[0].kind, ArrayLiteral);
    expect_text("assignment name", tokens[0].array_name, "nums");
    expect_size("assignment element len", tokens[0].element_type_len, 7);
    expect_int("assignment element count", tokens[0].element_count, 4);

    arraylexer_analyze_array_literal(&state, 3);
    expect_size("array literal token count", state.token_count, 2);
    expect_int("array literal kind", tokens[1].kind, ArrayLiteral);
    expect_text("array literal name", tokens[1].array_name, "<literal>");

    arraylexer_analyze_index_access(&state, "nums", 17);
    expect_size("index token count", state.token_count, 3);
    expect_int("index kind", tokens[2].kind, ArrayIndex);
    expect_text("index type", tokens[2].element_type, "Indexed");

    AsmExpr call_expr{ExprCall, 0, "nums", "sort", nullptr, 0, 0, 22};
    arraylexer_analyze_expression(&state, &call_expr);
    expect_size("call expression token count", state.token_count, 4);
    expect_int("call expression kind", tokens[3].kind, ArrayElement);
    expect_text("call expression operation", tokens[3].element_type, "Operation:sort");

    AsmStmt var_stmt{StmtVariableDecl, 0, nullptr, "items", &integer_array, 1, 0, 2, 0, nullptr, 0};
    AsmStmt print_stmt{StmtPrint, 0, &call_expr, nullptr, nullptr, 0, 0, 0, 0, nullptr, 0};
    AsmStmt method_body[]{var_stmt, print_stmt};
    AsmMethod method{method_body, 2};
    AsmClass klass{&method, 1, nullptr, 0};
    AsmProgram program{&klass, 1};

    arraylexer_analyze(&state, &program);
    expect_size("analyze resets and walks program", state.token_count, 2);
    expect_int("program first token declaration literal", tokens[0].kind, ArrayLiteral);
    expect_int("program second token call", tokens[1].kind, ArrayElement);

    arraylexer_analyze_class(&state, &klass);
    expect_true("analyze class callable", state.token_count >= 2);
    arraylexer_analyze_method(&state, &method);
    expect_true("analyze method callable", state.token_count >= 2);
    arraylexer_analyze_statement(&state, &print_stmt);
    expect_true("analyze statement callable", state.token_count >= 2);

    expect_true("emit token direct", arraylexer_emit_token(&state, ArrayDeclaration, "direct", "Long[]", 4, 0, 9) != 0);
    expect_int("direct token kind", tokens[state.token_count - 1].kind, ArrayDeclaration);
}

void negative_scenarios() {
    AsmArrayToken tokens[2]{};
    AsmArrayError errors[2]{};
    AsmArrayLexerState state{};
    arraylexer_init(&state, tokens, 2, errors, 2);
    AsmTypeRef scalar{"Integer", 0, 0};

    expect_size("strlen null", arraylexer_strlen(nullptr), 0);
    expect_false("streq mismatch", arraylexer_streq("add", "addAll") != 0);
    expect_false("streq null", arraylexer_streq(nullptr, "add") != 0);
    expect_false("array type null", arraylexer_is_array_type_name(nullptr) != 0);
    expect_false("array type missing close", arraylexer_is_array_type_name("Integer[") != 0);
    expect_false("array type scalar", arraylexer_is_array_type_name("Integer") != 0);
    expect_false("unsupported method", arraylexer_is_supported_array_method("clear") != 0);
    expect_false("case-sensitive method", arraylexer_is_supported_array_method("Add") != 0);
    expect_true("operation label null for unknown", arraylexer_operation_label("clear") == nullptr);
    expect_false("scalar type ref", arraylexer_is_array_type(&scalar) != 0);

    arraylexer_analyze_array_assignment(&state, "value", &scalar, 0, 0);
    expect_size("scalar assignment ignored", state.token_count, 0);

    AsmExpr unknown_call{ExprCall, 0, "items", "clear", nullptr, 0, 0, 0};
    arraylexer_analyze_expression(&state, &unknown_call);
    expect_size("unsupported call ignored", state.token_count, 0);

    expect_true("add error", arraylexer_add_error(&state, "bad array", 44) != 0);
    expect_true("has errors", arraylexer_has_errors(&state) != 0);
    expect_size("errors count", arraylexer_errors_count(&state), 1);
    expect_text("error text", errors[0].message, "bad array");

    expect_true("emit token one", arraylexer_emit_token(&state, ArrayDeclaration, "a", "Integer[]", 7, 0, 0) != 0);
    expect_true("emit token two", arraylexer_emit_token(&state, ArrayDeclaration, "b", "Integer[]", 7, 0, 0) != 0);
    expect_false("emit token capacity full", arraylexer_emit_token(&state, ArrayDeclaration, "c", "Integer[]", 7, 0, 0) != 0);

    arraylexer_analyze(nullptr, nullptr);
    arraylexer_analyze_class(nullptr, nullptr);
    arraylexer_analyze_method(nullptr, nullptr);
    arraylexer_analyze_statement(nullptr, nullptr);
    arraylexer_analyze_expression(nullptr, nullptr);
    arraylexer_analyze_array_assignment(nullptr, nullptr, nullptr, 0, 0);
    arraylexer_analyze_array_literal(nullptr, 0);
    arraylexer_analyze_index_access(nullptr, nullptr, 0);
    expect_true("null calls survive", true);
}

} // namespace

int main() {
    positive_scenarios();
    negative_scenarios();

    if (failures == 0) {
        std::cout << "ArrayLexer asm scenarios passed\n";
        return 0;
    }

    std::cout << "ArrayLexer asm scenarios failed: " << failures << '\n';
    return 1;
}
