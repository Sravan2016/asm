#include <cstddef>
#include <cstdint>
#include <cstring>
#include <iostream>
#include <string>

struct AsmCollectionToken {
    int kind;
    int location;
    char name[32];
    char argument_type[128];
    char return_type[128];
};

struct AsmCollectionError {
    char message[128];
    int location;
};

struct AsmCollectionMethodInfo {
    int kind;
    int has_lambda;
    char name[32];
    char argument_type[128];
    char return_type[128];
};

struct AsmCollectionLexerState {
    AsmCollectionToken* tokens;
    std::size_t token_count;
    std::size_t token_capacity;
    AsmCollectionError* errors;
    std::size_t error_count;
    std::size_t error_capacity;
    const char* element_type;
};

struct AsmExpr {
    int kind;
    std::uint32_t pad0;
    const char* object_name;
    const char* method_name;
    AsmExpr** children;
    std::size_t child_count;
    int location;
    std::uint32_t pad1;
};

struct AsmStmt {
    int kind;
    std::uint32_t pad0;
    AsmExpr* expr;
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

static_assert(sizeof(AsmCollectionToken) == 296);
static_assert(sizeof(AsmCollectionError) == 132);
static_assert(sizeof(AsmCollectionMethodInfo) == 296);
static_assert(sizeof(AsmCollectionLexerState) == 56);
static_assert(sizeof(AsmExpr) == 48);
static_assert(sizeof(AsmStmt) == 32);
static_assert(sizeof(AsmMethod) == 16);
static_assert(sizeof(AsmClass) == 32);
static_assert(sizeof(AsmProgram) == 16);

extern "C" void collectionlexer_init(AsmCollectionLexerState*, AsmCollectionToken*, std::size_t, AsmCollectionError*, std::size_t, const char*);
extern "C" void collectionlexer_analyze(AsmCollectionLexerState*, AsmProgram*);
extern "C" void collectionlexer_analyze_class(AsmCollectionLexerState*, AsmClass*);
extern "C" void collectionlexer_analyze_method(AsmCollectionLexerState*, AsmMethod*);
extern "C" void collectionlexer_analyze_statement(AsmCollectionLexerState*, AsmStmt*);
extern "C" void collectionlexer_analyze_expression(AsmCollectionLexerState*, AsmExpr*);
extern "C" void collectionlexer_identify_method(AsmCollectionMethodInfo*, const char*, const char*);
extern "C" int collectionlexer_is_collection_method(const char*);
extern "C" int collectionlexer_method_kind(const char*);
extern "C" const char* collectionlexer_method_name(int);
extern "C" int collectionlexer_emit_token(AsmCollectionLexerState*, int, const char*, const char*, const char*, int);
extern "C" int collectionlexer_add_error(AsmCollectionLexerState*, const char*, int);
extern "C" std::size_t collectionlexer_tokens_count(AsmCollectionLexerState*);
extern "C" std::size_t collectionlexer_errors_count(AsmCollectionLexerState*);
extern "C" int collectionlexer_has_errors(AsmCollectionLexerState*);
extern "C" std::size_t collectionlexer_strlen(const char*);
extern "C" int collectionlexer_streq(const char*, const char*);
extern "C" int collectionlexer_copy_cstr(char*, const char*, std::size_t);
extern "C" int collectionlexer_append_cstr(char*, const char*, std::size_t);

namespace {

constexpr int TokenCollectionMethod = 0;

constexpr int MethodContains = 0;
constexpr int MethodAdd = 1;
constexpr int MethodFind = 2;
constexpr int MethodSize = 3;
constexpr int MethodGet = 4;
constexpr int MethodRemove = 5;
constexpr int MethodFilter = 6;
constexpr int MethodJoin = 7;
constexpr int MethodSort = 8;
constexpr int MethodUnknown = 9;

constexpr int StmtExpression = 0;
constexpr int StmtVariableDecl = 1;
constexpr int StmtPrint = 2;
constexpr int StmtGuardBlock = 3;
constexpr int StmtForEach = 4;
constexpr int StmtSwitch = 5;

constexpr int ExprCall = 0;
constexpr int ExprMember = 1;
constexpr int ExprBinary = 3;
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

template <std::size_t TokenCount, std::size_t ErrorCount>
AsmCollectionLexerState fresh_state(AsmCollectionToken (&tokens)[TokenCount],
                                    AsmCollectionError (&errors)[ErrorCount],
                                    const char* element_type = "Integer") {
    std::memset(tokens, 0, sizeof(tokens));
    std::memset(errors, 0, sizeof(errors));
    AsmCollectionLexerState state{};
    collectionlexer_init(&state, tokens, TokenCount, errors, ErrorCount, element_type);
    return state;
}

void expect_method(const char* method, const char* element, int kind, const char* arg, const char* ret, int has_lambda) {
    AsmCollectionMethodInfo info{};
    collectionlexer_identify_method(&info, method, element);
    expect_int(std::string("method kind ") + method, info.kind, kind);
    expect_text(std::string("method name ") + method, info.name, method);
    expect_text(std::string("method arg ") + method, info.argument_type, arg);
    expect_text(std::string("method return ") + method, info.return_type, ret);
    expect_int(std::string("method lambda ") + method, info.has_lambda, has_lambda);
}

void positive_scenarios() {
    expect_int("strlen basic", collectionlexer_strlen("contains"), 8);
    expect_true("streq exact", collectionlexer_streq("add", "add") != 0);
    expect_true("contains recognized", collectionlexer_is_collection_method("contains") != 0);
    expect_true("sort recognized", collectionlexer_is_collection_method("sort") != 0);
    expect_int("method kind get", collectionlexer_method_kind("get"), MethodGet);
    expect_text("method name filter", collectionlexer_method_name(MethodFilter), "filter");

    char text[32]{};
    collectionlexer_copy_cstr(text, "Hello", sizeof(text));
    collectionlexer_append_cstr(text, "World", sizeof(text));
    expect_text("copy append", text, "HelloWorld");

    expect_method("contains", "Integer", MethodContains, "Integer", "Boolean", 0);
    expect_method("add", "Integer", MethodAdd, "Integer", "Void", 0);
    expect_method("find", "Integer", MethodFind, "Integer", "Integer", 0);
    expect_method("size", "Integer", MethodSize, "None", "Integer", 0);
    expect_method("get", "User", MethodGet, "Integer", "User", 0);
    expect_method("remove", "User", MethodRemove, "Integer", "Void", 0);
    expect_method("filter", "User", MethodFilter, "Lambda<Boolean(User)>", "User[]", 1);
    expect_method("join", "String", MethodJoin, "String", "String", 0);
    expect_method("sort", "User", MethodSort, "Lambda<Boolean(User,User)>", "User[]", 1);

    AsmCollectionToken tokens[32]{};
    AsmCollectionError errors[8]{};
    AsmCollectionLexerState state = fresh_state(tokens, errors, "User");

    expect_true("emit token", collectionlexer_emit_token(&state, TokenCollectionMethod, "size", "None", "Integer", 11) != 0);
    expect_int("emit token count", state.token_count, 1);
    expect_text("emit token name", tokens[0].name, "size");
    expect_text("emit token return", tokens[0].return_type, "Integer");

    AsmExpr call_expr{ExprCall, 0, "users", "filter", nullptr, 0, 22, 0};
    collectionlexer_analyze_expression(&state, &call_expr);
    expect_int("call expression token count", state.token_count, 2);
    expect_text("call expression name", tokens[1].name, "filter");
    expect_text("call expression arg", tokens[1].argument_type, "Lambda<Boolean(User)>");
    expect_text("call expression ret", tokens[1].return_type, "User[]");

    AsmExpr nested_call{ExprCall, 0, "users", "sort", nullptr, 0, 33, 0};
    AsmExpr* children[]{&nested_call};
    AsmExpr member_expr{ExprMember, 0, nullptr, nullptr, children, 1, 0, 0};
    collectionlexer_analyze_expression(&state, &member_expr);
    expect_int("nested expression token count", state.token_count, 3);
    expect_text("nested expression name", tokens[2].name, "sort");

    AsmStmt expr_stmt{StmtExpression, 0, &call_expr, nullptr, 0};
    AsmStmt guarded_body[]{expr_stmt};
    AsmStmt guard_stmt{StmtGuardBlock, 0, &nested_call, guarded_body, 1};
    collectionlexer_analyze_statement(&state, &guard_stmt);
    expect_true("statement emitted tokens", state.token_count >= 5);

    AsmStmt method_body[]{expr_stmt, guard_stmt};
    AsmMethod method{method_body, 2};
    collectionlexer_analyze_method(&state, &method);
    expect_true("method emitted tokens", state.token_count >= 8);

    AsmClass klass{&method, 1, nullptr, 0};
    collectionlexer_analyze_class(&state, &klass);
    expect_true("class emitted tokens", state.token_count >= 11);

    AsmProgram program{&klass, 1};
    collectionlexer_analyze(&state, &program);
    expect_true("analyze resets token count", state.token_count > 0 && state.token_count < 10);
    expect_text("program first token", tokens[0].name, "filter");
}

void negative_scenarios() {
    expect_false("unknown method rejected", collectionlexer_is_collection_method("clear") != 0);
    expect_false("case-sensitive method rejected", collectionlexer_is_collection_method("Add") != 0);
    expect_int("unknown method kind", collectionlexer_method_kind("clear"), MethodUnknown);
    expect_text("unknown method name", collectionlexer_method_name(44), "unknown");
    expect_false("streq null", collectionlexer_streq(nullptr, "add") != 0);

    AsmCollectionMethodInfo info{};
    collectionlexer_identify_method(&info, "clear", "Integer");
    expect_int("identify unknown kind", info.kind, MethodUnknown);
    expect_text("identify unknown name", info.name, "clear");
    expect_text("identify unknown arg empty", info.argument_type, "");
    expect_text("identify unknown ret empty", info.return_type, "");

    char small[6]{};
    collectionlexer_copy_cstr(small, "abcdef", sizeof(small));
    expect_text("copy truncates", small, "abcde");

    AsmCollectionToken tokens[1]{};
    AsmCollectionError errors[1]{};
    AsmCollectionLexerState state = fresh_state(tokens, errors, "Integer");
    expect_true("emit capacity first", collectionlexer_emit_token(&state, TokenCollectionMethod, "get", "Integer", "Integer", 1) != 0);
    expect_false("emit capacity full", collectionlexer_emit_token(&state, TokenCollectionMethod, "get", "Integer", "Integer", 1) != 0);

    AsmExpr bad_call{ExprCall, 0, "items", "clear", nullptr, 0, 2, 0};
    collectionlexer_analyze_expression(&state, &bad_call);
    expect_int("unsupported call ignored", state.token_count, 1);

    expect_true("add error", collectionlexer_add_error(&state, "bad collection", 99) != 0);
    expect_true("has errors", collectionlexer_has_errors(&state) != 0);
    expect_int("error count", collectionlexer_errors_count(&state), 1);
    expect_text("error message", errors[0].message, "bad collection");
    expect_false("error capacity full", collectionlexer_add_error(&state, "again", 100) != 0);

    collectionlexer_analyze(nullptr, nullptr);
    collectionlexer_analyze_class(nullptr, nullptr);
    collectionlexer_analyze_method(nullptr, nullptr);
    collectionlexer_analyze_statement(nullptr, nullptr);
    collectionlexer_analyze_expression(nullptr, nullptr);
    collectionlexer_identify_method(nullptr, nullptr, nullptr);
    collectionlexer_emit_token(nullptr, 0, nullptr, nullptr, nullptr, 0);
    collectionlexer_add_error(nullptr, nullptr, 0);
    expect_true("null calls survive", true);
}

} // namespace

int main() {
    std::cout.setf(std::ios::unitbuf);
    positive_scenarios();
    negative_scenarios();

    if (failures == 0) {
        std::cout << "CollectionLexer asm scenarios passed\n";
        return 0;
    }

    std::cout << "CollectionLexer asm scenarios failed: " << failures << '\n';
    return 1;
}
