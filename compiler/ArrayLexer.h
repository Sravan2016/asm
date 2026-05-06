#pragma once

#include "lexer.h"
#include "parser.h"

#include <string>
#include <vector>

enum class ArrayTokenKind {
    ArrayDeclaration,
    ArrayLiteral,
    ArrayIndex,
    ArrayElement,
    ArrayAssignment,
    ArrayUnknown
};

struct ArrayToken {
    ArrayTokenKind kind = ArrayTokenKind::ArrayUnknown;
    std::string array_name;
    std::string element_type;
    int element_count = 0;
    std::vector<std::string> element_values;
    SourceLocation location;
};

struct ArrayError {
    std::string message;
    SourceLocation location;
};

enum class ArrayLiteralKind {
    BraceLiteral,
    BacktickLiteral,
    Unknown
};

struct ArrayLiteralInfo {
    ArrayLiteralKind kind = ArrayLiteralKind::Unknown;
    std::string element_type;
    int element_count = 0;
    std::vector<std::string> element_values;
};

class ArrayLexer {
public:
    ArrayLexer() = default;

    void analyze(const Program& program);
    const std::vector<ArrayToken>& tokens() const;
    const std::vector<ArrayError>& errors() const;
    bool hasErrors() const;

private:
    void analyzeClass(const ClassDecl& class_decl);
    void analyzeMethod(const MethodDecl& method_decl);
    void analyzeStatement(const Stmt& stmt);
    void analyzeExpression(const Expr& expr);
    void analyzeTypeRef(const TypeRef& type_ref);
    void analyzeArrayAssignment(const Token& name, const TypeRef& type_ref, const Expr* initializer);
    void analyzeArrayLiteral(const ArrayLiteralExpr& expr, const std::string& context_type);
    void analyzeIndexAccess(const IndexExpr& expr);
    std::string extractTypeName(const TypeRef& type_ref);
    std::string extractElementType(const TypeRef& type_ref);
    bool isArrayType(const TypeRef& type_ref);
    void addError(const SourceLocation& location, const std::string& message);

    std::vector<ArrayToken> tokens_;
    std::vector<ArrayError> errors_;
};
