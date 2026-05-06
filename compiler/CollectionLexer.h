#pragma once

#include "lexer.h"
#include "parser.h"

#include <string>
#include <vector>
#include <unordered_map>

enum class CollectionTokenKind {
    CollectionMethod,
    CollectionArgument,
    CollectionReturnType,
    CollectionLambdaParam,
    CollectionUnknown
};

struct CollectionToken {
    CollectionTokenKind kind = CollectionTokenKind::CollectionUnknown;
    std::string name;
    std::string argument_type;
    std::string return_type;
    SourceLocation location;
};

struct CollectionError {
    std::string message;
    SourceLocation location;
};

enum class CollectionMethodKind {
    Contains,
    Add,
    Find,
    Size,
    Get,
    Remove,
    Filter,
    Join,
    Sort,
    Unknown
};

struct CollectionMethodInfo {
    CollectionMethodKind kind = CollectionMethodKind::Unknown;
    std::string name;
    std::string argument_type;
    std::string return_type;
    bool has_lambda = false;
};

class CollectionLexer {
public:
    CollectionLexer() = default;

    void analyze(const Program& program);
    const std::vector<CollectionToken>& tokens() const;
    const std::vector<CollectionError>& errors() const;
    bool hasErrors() const;

private:
    void analyzeClass(const ClassDecl& class_decl);
    void analyzeMethod(const MethodDecl& method_decl);
    void analyzeStatement(const Stmt& stmt);
    void analyzeExpression(const Expr& expr);
    CollectionMethodInfo identifyCollectionMethod(const std::string& method_name, const std::string& element_type);
    void addError(const SourceLocation& location, const std::string& message);

    std::vector<CollectionToken> tokens_;
    std::vector<CollectionError> errors_;
    std::string current_array_element_type_;
};
