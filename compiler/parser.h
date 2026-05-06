#pragma once

#include "lexer.h"

#include <initializer_list>
#include <utility>
#include <memory>
#include <string>
#include <vector>

struct ParseError {
    std::string message;
    SourceLocation location;
};

struct TypeRef {
    std::string name;
    bool isArray = false;
    bool isFileBacked = false;
};

enum class ExprKind {
    Identifier,
    IntegerLiteral,
    LongLiteral,
    DoubleLiteral,
    StringLiteral,
    BooleanLiteral,
    Unary,
    Binary,
    Assignment,
    Call,
    Member,
    Index,
    Postfix,
    Grouping,
    ArrayLiteral,
    Lambda
};

struct Expr {
    explicit Expr(ExprKind kindValue, SourceLocation startValue = {}, SourceLocation endValue = {})
        : kind(kindValue), start(startValue), end(endValue) {}
    virtual ~Expr() = default;

    ExprKind kind;
    SourceLocation start;
    SourceLocation end;
};

struct IdentifierExpr final : Expr {
    explicit IdentifierExpr(std::string nameValue, SourceLocation startValue = {}, SourceLocation endValue = {})
        : Expr(ExprKind::Identifier, startValue, endValue), name(std::move(nameValue)) {}
    std::string name;
};

struct LiteralExpr final : Expr {
    LiteralExpr(ExprKind kindValue, std::string valueValue, SourceLocation startValue = {}, SourceLocation endValue = {})
        : Expr(kindValue, startValue, endValue), value(std::move(valueValue)) {}
    std::string value;
};

struct UnaryExpr final : Expr {
    UnaryExpr(Token opValue, std::unique_ptr<Expr> operandValue)
        : Expr(ExprKind::Unary, opValue.start, operandValue ? operandValue->end : opValue.end),
          op(std::move(opValue)),
          operand(std::move(operandValue)) {}
    Token op;
    std::unique_ptr<Expr> operand;
};

struct BinaryExpr final : Expr {
    BinaryExpr(std::unique_ptr<Expr> leftValue, Token opValue, std::unique_ptr<Expr> rightValue)
        : Expr(ExprKind::Binary,
               leftValue ? leftValue->start : opValue.start,
               rightValue ? rightValue->end : opValue.end),
          left(std::move(leftValue)),
          op(std::move(opValue)),
          right(std::move(rightValue)) {}
    std::unique_ptr<Expr> left;
    Token op;
    std::unique_ptr<Expr> right;
};

struct AssignmentExpr final : Expr {
    AssignmentExpr(std::unique_ptr<Expr> targetValue, Token opValue, std::unique_ptr<Expr> valueValue)
        : Expr(ExprKind::Assignment,
               targetValue ? targetValue->start : opValue.start,
               valueValue ? valueValue->end : opValue.end),
          target(std::move(targetValue)),
          op(std::move(opValue)),
          value(std::move(valueValue)) {}
    std::unique_ptr<Expr> target;
    Token op;
    std::unique_ptr<Expr> value;
};

struct CallExpr final : Expr {
    CallExpr(std::unique_ptr<Expr> calleeValue, SourceLocation startValue = {}, SourceLocation endValue = {})
        : Expr(ExprKind::Call, startValue, endValue), callee(std::move(calleeValue)) {}
    std::unique_ptr<Expr> callee;
    std::vector<std::unique_ptr<Expr>> arguments;
};

struct MemberExpr final : Expr {
    MemberExpr(std::unique_ptr<Expr> objectValue, Token memberValue)
        : Expr(ExprKind::Member,
               objectValue ? objectValue->start : memberValue.start,
               memberValue.end),
          object(std::move(objectValue)),
          member(std::move(memberValue)) {}
    std::unique_ptr<Expr> object;
    Token member;
};

struct IndexExpr final : Expr {
    IndexExpr(std::unique_ptr<Expr> objectValue, std::unique_ptr<Expr> indexValue, SourceLocation endValue = {})
        : Expr(ExprKind::Index,
               objectValue ? objectValue->start : SourceLocation{},
               endValue),
          object(std::move(objectValue)),
          index(std::move(indexValue)) {}
    std::unique_ptr<Expr> object;
    std::unique_ptr<Expr> index;
};

struct PostfixExpr final : Expr {
    PostfixExpr(std::unique_ptr<Expr> operandValue, Token opValue)
        : Expr(ExprKind::Postfix,
               operandValue ? operandValue->start : opValue.start,
               opValue.end),
          operand(std::move(operandValue)),
          op(std::move(opValue)) {}
    std::unique_ptr<Expr> operand;
    Token op;
};

struct GroupingExpr final : Expr {
    explicit GroupingExpr(std::unique_ptr<Expr> innerValue)
        : Expr(ExprKind::Grouping,
               innerValue ? innerValue->start : SourceLocation{},
               innerValue ? innerValue->end : SourceLocation{}),
          inner(std::move(innerValue)) {}
    std::unique_ptr<Expr> inner;
};

struct ArrayLiteralExpr final : Expr {
    ArrayLiteralExpr(SourceLocation startValue = {}, SourceLocation endValue = {})
        : Expr(ExprKind::ArrayLiteral, startValue, endValue) {}
    std::vector<std::unique_ptr<Expr>> elements;
};

enum class StmtKind {
    Expression,
    VariableDecl,
    Print,
    GuardBlock,
    ForEach,
    Switch,
    Return
};

struct Stmt {
    explicit Stmt(StmtKind kindValue, SourceLocation startValue = {}, SourceLocation endValue = {})
        : kind(kindValue), start(startValue), end(endValue) {}
    virtual ~Stmt() = default;

    StmtKind kind;
    SourceLocation start;
    SourceLocation end;
};

struct ExprStmt final : Stmt {
    explicit ExprStmt(std::unique_ptr<Expr> expressionValue)
        : Stmt(StmtKind::Expression,
               expressionValue ? expressionValue->start : SourceLocation{},
               expressionValue ? expressionValue->end : SourceLocation{}),
          expression(std::move(expressionValue)) {}
    std::unique_ptr<Expr> expression;
};

struct VariableDeclStmt final : Stmt {
    VariableDeclStmt(TypeRef typeValue, Token nameValue)
        : Stmt(StmtKind::VariableDecl, nameValue.start, nameValue.end),
          type(std::move(typeValue)),
          name(std::move(nameValue)) {}
    TypeRef type;
    Token name;
    std::unique_ptr<Expr> initializer;
};

struct PrintStmt final : Stmt {
    PrintStmt(Token keywordValue, std::unique_ptr<Expr> expressionValue)
        : Stmt(StmtKind::Print,
               keywordValue.start,
               expressionValue ? expressionValue->end : keywordValue.end),
          keyword(std::move(keywordValue)),
          expression(std::move(expressionValue)) {}
    Token keyword;
    std::unique_ptr<Expr> expression;
};

struct GuardBlockStmt final : Stmt {
    explicit GuardBlockStmt(std::unique_ptr<Expr> conditionValue, bool loopValue = false)
        : Stmt(StmtKind::GuardBlock,
               conditionValue ? conditionValue->start : SourceLocation{},
               conditionValue ? conditionValue->end : SourceLocation{}),
          condition(std::move(conditionValue)),
          isLoop(loopValue) {}
    std::unique_ptr<Expr> condition;
    bool isLoop = false;
    std::vector<std::unique_ptr<Stmt>> body;
    std::vector<std::unique_ptr<Stmt>> elseBody;
};

struct ForEachStmt final : Stmt {
    ForEachStmt(TypeRef typeValue, Token nameValue, std::unique_ptr<Expr> iterableValue)
        : Stmt(StmtKind::ForEach,
               nameValue.start,
               iterableValue ? iterableValue->end : nameValue.end),
          type(std::move(typeValue)),
          name(std::move(nameValue)),
          iterable(std::move(iterableValue)) {}
    TypeRef type;
    Token name;
    std::unique_ptr<Expr> iterable;
    std::vector<std::unique_ptr<Stmt>> body;
};

struct SwitchCase {
    std::unique_ptr<Expr> label;
    bool isDefault = false;
    std::vector<std::unique_ptr<Stmt>> body;
    SourceLocation start;
    SourceLocation end;
};

struct SwitchStmt final : Stmt {
    explicit SwitchStmt(std::unique_ptr<Expr> subjectValue)
        : Stmt(StmtKind::Switch,
               subjectValue ? subjectValue->start : SourceLocation{},
               subjectValue ? subjectValue->end : SourceLocation{}),
          subject(std::move(subjectValue)) {}
    std::unique_ptr<Expr> subject;
    std::vector<SwitchCase> cases;
};

struct ReturnStmt final : Stmt {
    explicit ReturnStmt(std::unique_ptr<Expr> expressionValue, SourceLocation startValue = {}, SourceLocation endValue = {})
        : Stmt(StmtKind::Return, startValue, endValue),
          expression(std::move(expressionValue)) {}
    std::unique_ptr<Expr> expression;
};

struct ParameterDecl {
    TypeRef type;
    Token name;
};

struct LambdaExpr final : Expr {
    LambdaExpr(SourceLocation startValue = {}, SourceLocation endValue = {})
        : Expr(ExprKind::Lambda, startValue, endValue) {}
    std::vector<ParameterDecl> parameters;
    std::vector<std::unique_ptr<Stmt>> body;
};

struct MethodDecl {
    Token name;
    std::vector<ParameterDecl> parameters;
    std::vector<std::unique_ptr<Stmt>> body;
    std::unique_ptr<Expr> returnValue;
    SourceLocation end;
};

struct ClassMember {
    enum class Kind {
        Statement,
        Method
    };

    Kind kind = Kind::Statement;
    std::unique_ptr<Stmt> statement;
    std::unique_ptr<MethodDecl> method;
};

struct ClassDecl {
    Token name;
    std::vector<Token> parents;
    std::vector<ClassMember> members;
    SourceLocation end;
};

struct ImportDecl {
    Token fromToken;
    std::vector<Token> path;
};

struct Program {
    std::vector<ImportDecl> imports;
    std::vector<std::unique_ptr<ClassDecl>> classes;
};

class Parser {
public:
    explicit Parser(const std::vector<Token>& tokens);

    Program parseProgram();
    const std::vector<ParseError>& errors() const;
    bool hasError() const;

private:
    const Token& peek() const;
    const Token& previous() const;
    const Token& advance();
    bool isAtEnd() const;
    bool check(TokenKind kind) const;
    bool match(TokenKind kind);
    bool matchAny(std::initializer_list<TokenKind> kinds);
    const Token& consume(TokenKind kind, const char* message);

    void synchronize();
    void addErrorAtCurrent(const std::string& message);

    bool isTypeToken(const Token& token) const;
    bool isStatementBoundary(TokenKind kind) const;
    bool isSwitchCaseStart() const;
    bool looksLikeSwitchBlock() const;
    bool isMethodReturnStart() const;
    bool looksLikeLambda() const;
    bool looksLikeParenStatement() const;

    ImportDecl parseImportDecl();
    std::unique_ptr<ClassDecl> parseClassDecl();
    ClassMember parseClassMember();
    std::unique_ptr<MethodDecl> parseMethodDecl();
    ParameterDecl parseParameter();
    TypeRef parseType();

    std::unique_ptr<Stmt> parseStatement();
    std::unique_ptr<Stmt> parseVariableDecl();
    std::unique_ptr<Stmt> parsePrintStmt();
    std::unique_ptr<Stmt> parseReturnStmt();
    std::unique_ptr<Stmt> parseIfStmt();
    std::unique_ptr<Stmt> parseWhileStmt();
    std::unique_ptr<Stmt> parseForStmt();
    std::unique_ptr<Stmt> parseSwitchStmt();
    std::unique_ptr<Stmt> parseParenLedStatement();
    std::vector<std::unique_ptr<Stmt>> parseBraceBody();
    std::vector<std::unique_ptr<Stmt>> parseAngleBody();
    SwitchCase parseSwitchCase();

    std::unique_ptr<Expr> parseExpression();
    std::unique_ptr<Expr> parseAssignment();
    std::unique_ptr<Expr> parseLogicalOr();
    std::unique_ptr<Expr> parseLogicalAnd();
    std::unique_ptr<Expr> parseEquality();
    std::unique_ptr<Expr> parseComparison();
    std::unique_ptr<Expr> parseTerm();
    std::unique_ptr<Expr> parseFactor();
    std::unique_ptr<Expr> parseUnary();
    std::unique_ptr<Expr> parsePostfix();
    std::unique_ptr<Expr> parsePrimary();
    std::vector<std::unique_ptr<Expr>> parseArgumentList(TokenKind closingKind);
    std::unique_ptr<ArrayLiteralExpr> parseArrayLiteral();
    std::unique_ptr<LambdaExpr> parseLambdaExpr();

private:
    const std::vector<Token>& tokens_;
    std::size_t current_ = 0;
    std::vector<ParseError> errors_;
};
