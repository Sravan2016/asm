#pragma once

#include "parser.h"

#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

enum class SemanticTypeKind {
    Error,
    Unknown,
    Void,
    Integer,
    String,
    Long,
    Double,
    Boolean,
    Array,
    Class
};

struct SemanticType {
    SemanticTypeKind kind = SemanticTypeKind::Unknown;
    std::string name;
    std::shared_ptr<SemanticType> element_type;
    bool is_file_backed = false;

    static SemanticType makeError();
    static SemanticType makeUnknown();
    static SemanticType makeVoid();
    static SemanticType makeInteger(bool is_file_backed = false);
    static SemanticType makeString(bool is_file_backed = false);
    static SemanticType makeLong(bool is_file_backed = false);
    static SemanticType makeDouble(bool is_file_backed = false);
    static SemanticType makeBoolean(bool is_file_backed = false);
    static SemanticType makeClass(std::string class_name, bool is_file_backed = false);
    static SemanticType makeArray(SemanticType element, bool is_file_backed = false);
};

struct SemanticError {
    std::string message;
    SourceLocation location;
};

struct SemanticVariableSymbol {
    std::string name;
    SemanticType type;
    SourceLocation location;
    bool implicit = false;
};

struct SemanticMethodSymbol {
    std::string name;
    std::vector<SemanticType> parameter_types;
    SemanticType return_type;
    const MethodDecl* declaration = nullptr;
};

struct SemanticClassSymbol {
    std::string name;
    std::vector<std::string> parents;
    const ClassDecl* declaration = nullptr;
    std::unordered_map<std::string, SemanticVariableSymbol> fields;
    std::unordered_map<std::string, SemanticMethodSymbol> methods;
};

class SemanticAnalyser {
public:
    SemanticAnalyser() = default;

    bool analyse(const Program& program);

    const std::vector<SemanticError>& errors() const;
    bool hasErrors() const;
    SemanticType expressionType(const Expr* expr) const;
    const std::unordered_map<std::string, SemanticClassSymbol>& classes() const;

private:
    struct ScopeFrame {
        std::unordered_map<std::string, SemanticVariableSymbol> variables;
    };

    bool collectDeclarations(const Program& program);
    void analyseClass(const ClassDecl& class_decl);
    void analyseMethod(const MethodDecl& method_decl, SemanticMethodSymbol& method_symbol);
    void analyseStatement(const Stmt& stmt);
    SemanticType analyseExpr(const Expr& expr);
    SemanticType analyseCallExpr(const CallExpr& expr);
    SemanticType analyseMemberExpr(const MemberExpr& expr);
    SemanticType analyseAssignmentExpr(const AssignmentExpr& expr);
    SemanticType analyseBinaryExpr(const BinaryExpr& expr);
    SemanticType analyseUnaryExpr(const UnaryExpr& expr);
    SemanticType analysePostfixExpr(const PostfixExpr& expr);
    SemanticType analyseArrayLiteralExpr(const ArrayLiteralExpr& expr);

    SemanticType resolveType(const TypeRef& type_ref, const SourceLocation& location);
    SemanticVariableSymbol* lookupVariable(const std::string& name);
    const SemanticMethodSymbol* lookupCurrentClassMethod(const std::string& name) const;
    const SemanticMethodSymbol* lookupMethodInClass(const SemanticClassSymbol* class_symbol, const std::string& name) const;
    const SemanticClassSymbol* lookupClass(const std::string& name) const;
    SemanticVariableSymbol* declareVariable(const Token& name, const SemanticType& type, bool implicit);
    SemanticVariableSymbol* declareVariable(const std::string& name, const SourceLocation& location, const SemanticType& type, bool implicit);

    void pushScope();
    void popScope();

    void addError(const SourceLocation& location, const std::string& message);
    void rememberExprType(const Expr& expr, const SemanticType& type);

    bool isNumeric(const SemanticType& type) const;
    bool isBoolean(const SemanticType& type) const;
    bool isString(const SemanticType& type) const;
    bool isAssignableTarget(const Expr& expr) const;
    bool areTypesEqual(const SemanticType& left, const SemanticType& right) const;
    bool isAssignable(const SemanticType& target, const SemanticType& value) const;
    std::string describeType(const SemanticType& type) const;

private:
    const Program* program_ = nullptr;
    std::unordered_map<std::string, SemanticClassSymbol> classes_;
    std::vector<ScopeFrame> scopes_;
    std::unordered_map<const Expr*, SemanticType> expression_types_;
    std::vector<SemanticError> errors_;
    SemanticClassSymbol* current_class_ = nullptr;
    SemanticMethodSymbol* current_method_ = nullptr;
};
