#include <cstdint>
#include <cstring>
#include <iostream>

enum SemanticKind {
    Error = 0,
    Unknown = 1,
    Void = 2,
    Integer = 3,
    String = 4,
    Long = 5,
    Double = 6,
    Boolean = 7,
    Array = 8,
    Class = 9
};

struct AsmSemanticAnalyser {
    std::uint64_t errors;
    std::uint64_t classes;
    std::uint64_t fields;
    std::uint64_t methods;
    std::uint64_t scopes;
    std::uint64_t variables;
    std::uint64_t expression_types;
    std::uint64_t implicit_methods;
    const char* class_names[32];
    const char* variable_names[32];
    std::uint64_t variable_kinds[32];
};

static_assert(sizeof(AsmSemanticAnalyser) == 832);

extern "C" {
void semantic_init(AsmSemanticAnalyser* analyser);
std::uint64_t semantic_error_count(AsmSemanticAnalyser* analyser);
int semantic_has_errors(AsmSemanticAnalyser* analyser);
void semantic_add_error(AsmSemanticAnalyser* analyser);
const char* semantic_type_name(int kind, int file_backed);
int semantic_is_numeric(int kind);
int semantic_is_boolean(int kind);
int semantic_is_string(int kind);
int semantic_are_types_equal(int left, int right);
int semantic_is_assignable(int target, int value);
int semantic_collect_class(AsmSemanticAnalyser* analyser, const char* name, const char* parent);
int semantic_lookup_class(AsmSemanticAnalyser* analyser, const char* name);
int semantic_collect_field(AsmSemanticAnalyser* analyser, const char* name, int kind);
int semantic_collect_method(AsmSemanticAnalyser* analyser, const char* name, int return_kind);
void semantic_push_scope(AsmSemanticAnalyser* analyser);
void semantic_pop_scope(AsmSemanticAnalyser* analyser);
int semantic_declare_variable(AsmSemanticAnalyser* analyser, const char* name, int kind);
int semantic_lookup_variable(AsmSemanticAnalyser* analyser, const char* name);
int semantic_resolve_type(AsmSemanticAnalyser* analyser, const char* name, int is_array, int is_file_backed);
int semantic_analyse_variable_decl(AsmSemanticAnalyser* analyser, int declared_kind, int init_kind);
int semantic_analyse_guard_condition(AsmSemanticAnalyser* analyser, int condition_kind);
int semantic_analyse_foreach(AsmSemanticAnalyser* analyser, int iterable_kind, int loop_kind, int element_kind);
int semantic_analyse_binary(AsmSemanticAnalyser* analyser, int op, int left_kind, int right_kind);
int semantic_analyse_unary(AsmSemanticAnalyser* analyser, int op, int operand_kind);
int semantic_analyse_array_literal(AsmSemanticAnalyser* analyser, const int* kinds, std::uint64_t count);
int semantic_builtin_member_type(int object_kind, const char* member);
void semantic_remember_expr_type(AsmSemanticAnalyser* analyser, const void* expr, int kind);
int semantic_analyse_program(AsmSemanticAnalyser* analyser);
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
    AsmSemanticAnalyser analyser{};
    semantic_init(&analyser);

    expect(analyser.errors == 0 && analyser.classes == 0 && analyser.variables == 0,
           "positive: init clears analyser state", failures);
    expect(semantic_has_errors(&analyser) == 0, "positive: fresh analyser has no errors", failures);

    expect(std::strcmp(semantic_type_name(Integer, 0), "Integer") == 0,
           "positive: describe Integer type", failures);
    expect(std::strcmp(semantic_type_name(String, 1), "FileString") == 0,
           "positive: describe file-backed String type", failures);
    expect(std::strcmp(semantic_type_name(99, 0), "unknown") == 0,
           "negative: unknown type kind describes as unknown", failures);

    expect(semantic_is_numeric(Integer) == 1 && semantic_is_numeric(Long) == 1 && semantic_is_numeric(Double) == 1,
           "positive: numeric type detection", failures);
    expect(semantic_is_numeric(Boolean) == 0, "negative: Boolean is not numeric", failures);
    expect(semantic_is_boolean(Boolean) == 1, "positive: Boolean type detection", failures);
    expect(semantic_is_string(String) == 1, "positive: String type detection", failures);

    expect(semantic_are_types_equal(Integer, Integer) == 1,
           "positive: identical type kinds are equal", failures);
    expect(semantic_are_types_equal(Integer, String) == 0,
           "negative: different type kinds are not equal", failures);
    expect(semantic_is_assignable(Double, Integer) == 1,
           "positive: Integer can widen to Double", failures);
    expect(semantic_is_assignable(Long, Integer) == 1,
           "positive: Integer can widen to Long", failures);
    expect(semantic_is_assignable(Integer, String) == 0,
           "negative: String cannot assign to Integer", failures);
    expect(semantic_is_assignable(Unknown, String) == 1,
           "positive: Unknown assignment is tolerated after earlier errors", failures);

    expect(semantic_collect_class(&analyser, "User", nullptr) == 1,
           "positive: collect class declaration", failures);
    expect(semantic_lookup_class(&analyser, "User") == 1,
           "positive: lookup collected class", failures);
    expect(semantic_collect_class(&analyser, "User", nullptr) == 0,
           "negative: duplicate class declaration records error", failures);
    expect(semantic_collect_class(&analyser, "Profile", "Aleka") == 1,
           "positive: collect Aleka-backed class", failures);
    expect(analyser.implicit_methods == 4,
           "positive: Aleka class receives implicit of/toString/toObject accessors", failures);

    expect(semantic_collect_field(&analyser, "name", String) == 1,
           "positive: collect field declaration", failures);
    expect(semantic_collect_method(&analyser, "show", Void) == 1,
           "positive: collect method declaration", failures);

    expect(semantic_resolve_type(&analyser, "Integer", 0, 0) == Integer,
           "positive: resolve primitive type", failures);
    expect(semantic_resolve_type(&analyser, "String", 1, 0) == Array,
           "positive: resolve array type wrapper", failures);
    expect(semantic_resolve_type(&analyser, "User", 0, 0) == Class,
           "positive: resolve known class type", failures);
    std::uint64_t errors_before_unknown = analyser.errors;
    expect(semantic_resolve_type(&analyser, "MissingType", 0, 0) == Error &&
               analyser.errors == errors_before_unknown + 1,
           "negative: resolve unknown type records error", failures);

    semantic_push_scope(&analyser);
    expect(analyser.scopes == 1, "positive: push scope increments scope depth", failures);
    expect(semantic_declare_variable(&analyser, "count", Integer) == 1,
           "positive: declare variable in scope", failures);
    expect(semantic_lookup_variable(&analyser, "count") == Integer,
           "positive: lookup declared variable type", failures);
    expect(semantic_declare_variable(&analyser, "count", String) == 0,
           "negative: duplicate variable declaration records error", failures);
    expect(semantic_lookup_variable(&analyser, "missing") == Error,
           "negative: unknown variable lookup returns error type", failures);
    semantic_pop_scope(&analyser);
    expect(analyser.scopes == 0, "positive: pop scope decrements scope depth", failures);

    expect(semantic_analyse_variable_decl(&analyser, Double, Integer) == 1,
           "positive: variable declaration accepts widening initializer", failures);
    std::uint64_t errors_before_assign = analyser.errors;
    expect(semantic_analyse_variable_decl(&analyser, Boolean, String) == 0 &&
               analyser.errors == errors_before_assign + 1,
           "negative: variable declaration rejects incompatible initializer", failures);

    expect(semantic_analyse_guard_condition(&analyser, Boolean) == 1,
           "positive: guard condition accepts Boolean", failures);
    std::uint64_t errors_before_guard = analyser.errors;
    expect(semantic_analyse_guard_condition(&analyser, Integer) == 0 &&
               analyser.errors == errors_before_guard + 1,
           "negative: guard condition rejects non-Boolean", failures);

    expect(semantic_analyse_foreach(&analyser, Array, Integer, Integer) == 1,
           "positive: foreach accepts matching array element type", failures);
    std::uint64_t errors_before_foreach = analyser.errors;
    expect(semantic_analyse_foreach(&analyser, String, Integer, Integer) == 0 &&
               analyser.errors == errors_before_foreach + 1,
           "negative: foreach rejects non-array source", failures);

    expect(semantic_analyse_binary(&analyser, '+', Integer, Long) == Long,
           "positive: binary plus widens numeric result", failures);
    expect(semantic_analyse_binary(&analyser, '+', String, Integer) == String,
           "positive: binary plus supports string concatenation", failures);
    expect(semantic_analyse_binary(&analyser, '<', Integer, Double) == Boolean,
           "positive: comparison returns Boolean", failures);
    expect(semantic_analyse_binary(&analyser, '&', Boolean, Boolean) == Boolean,
           "positive: logical operator returns Boolean", failures);
    std::uint64_t errors_before_binary = analyser.errors;
    expect(semantic_analyse_binary(&analyser, '*', String, Boolean) == Error &&
               analyser.errors == errors_before_binary + 1,
           "negative: invalid binary operation records error", failures);

    expect(semantic_analyse_unary(&analyser, '!', Boolean) == Boolean,
           "positive: unary bang accepts Boolean", failures);
    expect(semantic_analyse_unary(&analyser, '-', Double) == Double,
           "positive: unary minus accepts numeric type", failures);
    std::uint64_t errors_before_unary = analyser.errors;
    expect(semantic_analyse_unary(&analyser, '!', Integer) == Error &&
               analyser.errors == errors_before_unary + 1,
           "negative: unary bang rejects Integer", failures);

    int homogeneous[] = {Integer, Integer, Integer};
    int mixed[] = {Integer, String};
    expect(semantic_analyse_array_literal(&analyser, homogeneous, 3) == Integer,
           "positive: array literal infers homogeneous element type", failures);
    std::uint64_t errors_before_array = analyser.errors;
    expect(semantic_analyse_array_literal(&analyser, mixed, 2) == Error &&
               analyser.errors == errors_before_array + 1,
           "negative: array literal rejects mixed element types", failures);
    expect(semantic_analyse_array_literal(&analyser, homogeneous, 0) == Unknown,
           "positive: empty array literal has unknown element type", failures);

    expect(semantic_builtin_member_type(Array, "size") == Integer,
           "positive: Array.size returns Integer", failures);
    expect(semantic_builtin_member_type(Array, "contains") == Boolean,
           "positive: Array.contains returns Boolean", failures);
    expect(semantic_builtin_member_type(Array, "join") == String,
           "positive: Array.join returns String", failures);
    expect(semantic_builtin_member_type(Class, "containsKey") == Boolean,
           "positive: Map-style containsKey returns Boolean", failures);
    expect(semantic_builtin_member_type(Class, "clear") == Void,
           "positive: Map-style clear returns Void", failures);
    expect(semantic_builtin_member_type(String, "length") == Integer,
           "positive: String.length returns Integer", failures);
    expect(semantic_builtin_member_type(String, "missing") == Unknown,
           "negative: unknown builtin member returns Unknown", failures);

    semantic_remember_expr_type(&analyser, &analyser, Integer);
    expect(analyser.expression_types == 1, "positive: remember expression type records entry", failures);
    expect(semantic_analyse_program(&analyser) == 0,
           "negative: analyse_program reports failure when semantic errors exist", failures);

    AsmSemanticAnalyser clean{};
    semantic_init(&clean);
    semantic_collect_class(&clean, "Clean", nullptr);
    expect(semantic_analyse_program(&clean) == 1,
           "positive: analyse_program reports success without semantic errors", failures);

    if (failures == 0) {
        std::cout << "SemanticAnalyser asm scenarios passed\n";
        return 0;
    }

    std::cout << "SemanticAnalyser asm scenarios failed: " << failures << '\n';
    return 1;
}
