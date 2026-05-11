#include <cstdint>
#include <cstring>
#include <iostream>

enum CollectionMethodKind {
    Contains = 0,
    Add = 1,
    Find = 2,
    Size = 3,
    Get = 4,
    Remove = 5,
    Filter = 6,
    Join = 7,
    Sort = 8,
    Unknown = 9
};

struct AsmCollectionAnalyser {
    std::uint64_t tokens;
    std::uint64_t errors;
    std::uint64_t classes;
    std::uint64_t methods;
    std::uint64_t statements;
    std::uint64_t expressions;
    const char* current_element;
    std::uint64_t last_kind;
    const char* last_argument_type;
    const char* last_return_type;
    std::uint64_t last_has_lambda;
};

static_assert(sizeof(AsmCollectionAnalyser) == 88);

extern "C" {
void collection_analyser_init(AsmCollectionAnalyser* analyser);
std::uint64_t collection_analyser_token_count(AsmCollectionAnalyser* analyser);
std::uint64_t collection_analyser_error_count(AsmCollectionAnalyser* analyser);
int collection_analyser_has_errors(AsmCollectionAnalyser* analyser);
void collection_analyser_add_error(AsmCollectionAnalyser* analyser);
void collection_analyser_set_element_type(AsmCollectionAnalyser* analyser, const char* element_type);
int collection_analyser_identify_method(const char* method_name, const char* element_type);
int collection_analyser_fill_method_info(AsmCollectionAnalyser* analyser, const char* element_type, const char* method_name);
int collection_analyser_record_method_call(AsmCollectionAnalyser* analyser, const char* method_name, int has_lambda);
void collection_analyser_analyze_expression(AsmCollectionAnalyser* analyser);
void collection_analyser_analyze_statement(AsmCollectionAnalyser* analyser, std::uint64_t nested_expressions);
void collection_analyser_analyze_method(AsmCollectionAnalyser* analyser, std::uint64_t statement_count);
void collection_analyser_analyze_class(AsmCollectionAnalyser* analyser);
int collection_analyser_analyze_program(AsmCollectionAnalyser* analyser, std::uint64_t classes,
                                        std::uint64_t methods, std::uint64_t statements);
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
    AsmCollectionAnalyser analyser{};
    collection_analyser_init(&analyser);

    expect(analyser.tokens == 0 && analyser.errors == 0, "positive: init clears token and error state", failures);
    expect(std::strcmp(analyser.current_element, "Unknown") == 0, "positive: init sets unknown element type", failures);
    expect(collection_analyser_has_errors(&analyser) == 0, "positive: fresh analyser has no errors", failures);

    collection_analyser_set_element_type(&analyser, "Integer");
    expect(std::strcmp(analyser.current_element, "Integer") == 0,
           "positive: current array element type can be set", failures);
    collection_analyser_set_element_type(&analyser, nullptr);
    expect(std::strcmp(analyser.current_element, "Unknown") == 0,
           "negative: null element type falls back to Unknown", failures);
    collection_analyser_set_element_type(&analyser, "Integer");

    expect(collection_analyser_identify_method("contains", "Integer") == Contains,
           "positive: identify contains method", failures);
    expect(collection_analyser_identify_method("add", "Integer") == Add,
           "positive: identify add method", failures);
    expect(collection_analyser_identify_method("find", "Integer") == Find,
           "positive: identify find method", failures);
    expect(collection_analyser_identify_method("size", "Integer") == Size,
           "positive: identify size method", failures);
    expect(collection_analyser_identify_method("get", "Integer") == Get,
           "positive: identify get method", failures);
    expect(collection_analyser_identify_method("remove", "Integer") == Remove,
           "positive: identify remove method", failures);
    expect(collection_analyser_identify_method("filter", "Integer") == Filter,
           "positive: identify filter method", failures);
    expect(collection_analyser_identify_method("join", "Integer") == Join,
           "positive: identify join method", failures);
    expect(collection_analyser_identify_method("sort", "Integer") == Sort,
           "positive: identify sort method", failures);
    expect(collection_analyser_identify_method("missing", "Integer") == Unknown,
           "negative: unknown collection method is rejected", failures);

    collection_analyser_fill_method_info(&analyser, "String", "contains");
    expect(analyser.last_kind == Contains &&
               std::strcmp(analyser.last_argument_type, "String") == 0 &&
               std::strcmp(analyser.last_return_type, "Boolean") == 0,
           "positive: contains method info uses element type and returns Boolean", failures);

    collection_analyser_fill_method_info(&analyser, "String", "size");
    expect(analyser.last_kind == Size &&
               std::strcmp(analyser.last_argument_type, "None") == 0 &&
               std::strcmp(analyser.last_return_type, "Integer") == 0,
           "positive: size method info has no argument and returns Integer", failures);

    collection_analyser_fill_method_info(&analyser, "String", "get");
    expect(analyser.last_kind == Get &&
               std::strcmp(analyser.last_argument_type, "Integer") == 0 &&
               std::strcmp(analyser.last_return_type, "String") == 0,
           "positive: get method info indexes by Integer and returns element type", failures);

    collection_analyser_fill_method_info(&analyser, "String", "filter");
    expect(analyser.last_kind == Filter &&
               analyser.last_has_lambda == 1 &&
               std::strcmp(analyser.last_argument_type, "Lambda<Boolean(T)>") == 0 &&
               std::strcmp(analyser.last_return_type, "[]") == 0,
           "positive: filter method info requires lambda and returns array", failures);

    collection_analyser_fill_method_info(&analyser, "String", "sort");
    expect(analyser.last_kind == Sort &&
               analyser.last_has_lambda == 1 &&
               std::strcmp(analyser.last_argument_type, "Lambda<Boolean(T,T)>") == 0,
           "positive: sort method info requires binary lambda", failures);

    collection_analyser_fill_method_info(&analyser, "String", "notReal");
    expect(analyser.last_kind == Unknown &&
               std::strcmp(analyser.last_argument_type, "Unknown") == 0 &&
               std::strcmp(analyser.last_return_type, "Unknown") == 0,
           "negative: unknown method info stays Unknown", failures);

    expect(collection_analyser_record_method_call(&analyser, "contains", 0) == 1,
           "positive: record normal collection method call", failures);
    expect(collection_analyser_token_count(&analyser) == 1, "positive: token count increments for method call", failures);
    expect(collection_analyser_record_method_call(&analyser, "filter", 1) == 1,
           "positive: record lambda collection method call", failures);
    expect(collection_analyser_token_count(&analyser) == 2, "positive: token count increments for lambda method", failures);

    std::uint64_t errors_before_lambda = analyser.errors;
    expect(collection_analyser_record_method_call(&analyser, "sort", 0) == 0 &&
               analyser.errors == errors_before_lambda + 1,
           "negative: lambda method without lambda records error", failures);

    std::uint64_t errors_before_unknown = analyser.errors;
    expect(collection_analyser_record_method_call(&analyser, "missing", 0) == 0 &&
               analyser.errors == errors_before_unknown + 1,
           "negative: unknown method call records error", failures);
    expect(collection_analyser_has_errors(&analyser) == 1, "positive: analyser reports accumulated errors", failures);

    collection_analyser_analyze_expression(&analyser);
    expect(analyser.expressions >= 4, "positive: analyze_expression increments expression traversal count", failures);
    collection_analyser_analyze_statement(&analyser, 2);
    expect(analyser.statements == 1 && analyser.expressions >= 6,
           "positive: analyze_statement records statement and nested expressions", failures);
    collection_analyser_analyze_method(&analyser, 3);
    expect(analyser.methods == 1 && analyser.statements == 4,
           "positive: analyze_method records method and body statements", failures);
    collection_analyser_analyze_class(&analyser);
    expect(analyser.classes == 1, "positive: analyze_class records visited class", failures);

    AsmCollectionAnalyser program{};
    collection_analyser_init(&program);
    expect(collection_analyser_analyze_program(&program, 2, 3, 5) == 1 &&
               program.classes == 2 && program.methods == 3 && program.statements == 5,
           "positive: analyze_program records aggregate traversal counts", failures);
    expect(collection_analyser_analyze_program(nullptr, 1, 1, 1) == 0,
           "negative: analyze_program rejects null analyser", failures);

    collection_analyser_add_error(&program);
    expect(collection_analyser_error_count(&program) == 1,
           "positive: add_error increments error count", failures);

    if (failures == 0) {
        std::cout << "CollectionAnalyser asm scenarios passed\n";
        return 0;
    }

    std::cout << "CollectionAnalyser asm scenarios failed: " << failures << '\n';
    return 1;
}
