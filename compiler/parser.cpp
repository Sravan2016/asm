#include "parser.h"

#include <iostream>
#include <utility>

namespace {

const Token& eof_token() {
    static const Token token{TokenKind::EndOfFile, "", SourceLocation{}, SourceLocation{}};
    return token;
}

} // namespace

Parser::Parser(const std::vector<Token>& tokens) : tokens_(tokens) {}

Program Parser::parseProgram() {
    Program program;

    while (!isAtEnd() &&
           (check(TokenKind::KeywordFrom) ||
            (check(TokenKind::Identifier) && peek().lexeme == "from"))) {
        program.imports.push_back(parseImportDecl());
    }

    while (!isAtEnd()) {
        program.classes.push_back(parseClassDecl());
    }

    return program;
}

const std::vector<ParseError>& Parser::errors() const {
    return errors_;
}

bool Parser::hasError() const {
    return !errors_.empty();
}

const Token& Parser::peek() const {
    if (current_ >= tokens_.size()) return eof_token();
    return tokens_[current_];
}

const Token& Parser::previous() const {
    if (current_ == 0 || tokens_.empty()) return eof_token();
    return tokens_[current_ - 1];
}

const Token& Parser::advance() {
    if (!isAtEnd()) ++current_;
    return previous();
}

bool Parser::isAtEnd() const {
    return peek().kind == TokenKind::EndOfFile;
}

bool Parser::check(TokenKind kind) const {
    return peek().kind == kind;
}

bool Parser::match(TokenKind kind) {
    if (!check(kind)) return false;
    advance();
    return true;
}

bool Parser::matchAny(std::initializer_list<TokenKind> kinds) {
    for (TokenKind kind : kinds) {
        if (check(kind)) {
            advance();
            return true;
        }
    }
    return false;
}

const Token& Parser::consume(TokenKind kind, const char* message) {
    if (check(kind)) return advance();
    addErrorAtCurrent(message);
    return eof_token();
}

void Parser::synchronize() {
    while (!isAtEnd()) {
        if (previous().kind == TokenKind::Semicolon) return;
        if (isStatementBoundary(peek().kind) || check(TokenKind::ArrowMethodEnd) ||
            check(TokenKind::ArrowClassEnd) || check(TokenKind::RightBrace) ||
            check(TokenKind::RightBracket) || check(TokenKind::Greater)) {
            return;
        }
        advance();
    }
}

void Parser::addErrorAtCurrent(const std::string& message) {
    errors_.push_back(ParseError{message, peek().start});
}

bool Parser::isTypeToken(const Token& token) const {
    switch (token.kind) {
        case TokenKind::KeywordInteger:
        case TokenKind::KeywordFileInteger:
        case TokenKind::KeywordString:
        case TokenKind::KeywordFileString:
        case TokenKind::KeywordLong:
        case TokenKind::KeywordFileLong:
        case TokenKind::KeywordDouble:
        case TokenKind::KeywordFileDouble:
        case TokenKind::KeywordBoolean:
        case TokenKind::KeywordFileBoolean:
        case TokenKind::KeywordArray:
        case TokenKind::KeywordMap:
        case TokenKind::KeywordThread:
            return true;
        default:
            return false;
    }
}

namespace {
bool is_generic_type_decl_start(const std::vector<Token>& tokens, std::size_t current) {
    if (current + 1 >= tokens.size()) return false;
    return tokens[current].kind == TokenKind::Identifier &&
           tokens[current + 1].kind == TokenKind::Identifier;
}
}

bool Parser::isStatementBoundary(TokenKind kind) const {
    switch (kind) {
        case TokenKind::KeywordIf:
        case TokenKind::KeywordWhile:
        case TokenKind::KeywordFor:
        case TokenKind::KeywordSwitch:
        case TokenKind::KeywordPrint:
        case TokenKind::KeywordPrintln:
        case TokenKind::LeftParen:
        case TokenKind::Identifier:
        case TokenKind::KeywordInteger:
        case TokenKind::KeywordFileInteger:
        case TokenKind::KeywordString:
        case TokenKind::KeywordFileString:
        case TokenKind::KeywordLong:
        case TokenKind::KeywordFileLong:
        case TokenKind::KeywordDouble:
        case TokenKind::KeywordFileDouble:
        case TokenKind::KeywordBoolean:
        case TokenKind::KeywordFileBoolean:
        case TokenKind::KeywordArray:
        case TokenKind::KeywordMap:
        case TokenKind::KeywordThread:
            return true;
        default:
            return false;
    }
}

bool Parser::isSwitchCaseStart() const {
    if (!(check(TokenKind::IntegerLiteral) || check(TokenKind::Identifier) ||
          check(TokenKind::StringLiteral) || check(TokenKind::KeywordTrue) ||
          check(TokenKind::KeywordFalse))) {
        return false;
    }

    if (current_ + 1 >= tokens_.size()) return false;
    return tokens_[current_ + 1].kind == TokenKind::LeftBracket;
}

bool Parser::looksLikeSwitchBlock() const {
    std::size_t idx = current_;
    int square_depth = 0;
    int paren_depth = 0;

    while (idx < tokens_.size()) {
        const TokenKind kind = tokens_[idx].kind;

        if (kind == TokenKind::Greater && square_depth == 0 && paren_depth == 0) {
            return false;
        }

        if (kind == TokenKind::LeftBracket) ++square_depth;
        else if (kind == TokenKind::RightBracket && square_depth > 0) --square_depth;
        else if (kind == TokenKind::LeftParen) ++paren_depth;
        else if (kind == TokenKind::RightParen && paren_depth > 0) --paren_depth;

        if (square_depth == 0 && paren_depth == 0) {
            const bool label_kind =
                kind == TokenKind::IntegerLiteral ||
                kind == TokenKind::Identifier ||
                kind == TokenKind::StringLiteral ||
                kind == TokenKind::KeywordTrue ||
                kind == TokenKind::KeywordFalse;

            if (label_kind && idx + 1 < tokens_.size() &&
                tokens_[idx + 1].kind == TokenKind::LeftBracket) {
                return true;
            }
        }

        ++idx;
    }

    return false;
}

bool Parser::isMethodReturnStart() const {
    if (!check(TokenKind::LeftBracket)) return false;

    std::size_t idx = current_ + 1;
    int bracket_depth = 1;
    while (idx < tokens_.size()) {
        if (tokens_[idx].kind == TokenKind::LeftBracket) {
            ++bracket_depth;
        } else if (tokens_[idx].kind == TokenKind::RightBracket) {
            --bracket_depth;
            if (bracket_depth == 0) {
                bool has_arrow = idx + 1 < tokens_.size() &&
                       tokens_[idx + 1].kind == TokenKind::ArrowMethodEnd;
                return has_arrow;
            }
        } else if (tokens_[idx].kind == TokenKind::EndOfFile) {
            return false;
        }
        ++idx;
    }

    return false;
}

bool Parser::looksLikeLambda() const {
    if (!check(TokenKind::LeftParen)) return false;

    std::size_t idx = current_ + 1;
    int paren_depth = 1;
    while (idx < tokens_.size()) {
        const TokenKind kind = tokens_[idx].kind;
        if (kind == TokenKind::LeftParen) ++paren_depth;
        else if (kind == TokenKind::RightParen) {
            --paren_depth;
            if (paren_depth == 0) {
                return idx + 1 < tokens_.size() &&
                       tokens_[idx + 1].kind == TokenKind::FatArrow;
            }
        }
        ++idx;
    }
    return false;
}

std::unique_ptr<LambdaExpr> Parser::parseLambdaExpr() {
    consume(TokenKind::LeftParen, "expected '(' to start lambda");

    auto lambda = std::make_unique<LambdaExpr>(previous().start, previous().end);

    if (!check(TokenKind::RightParen)) {
        do {
            if (isTypeToken(peek())) {
                lambda->parameters.push_back(parseParameter());
            } else {
                Token name = consume(TokenKind::Identifier, "expected lambda parameter name");
                ParameterDecl param;
                param.name = name;
                param.type = TypeRef{"Unknown", false, false};
                lambda->parameters.push_back(std::move(param));
            }
        } while (match(TokenKind::Comma));
    }
    consume(TokenKind::RightParen, "expected ')' after lambda parameters");
    consume(TokenKind::FatArrow, "expected '=>' after lambda parameters");

    TokenKind body_start = TokenKind::Less;
    TokenKind body_end = TokenKind::Greater;
    if (match(TokenKind::Less)) {
        body_start = TokenKind::Less;
        body_end = TokenKind::Greater;
    } else if (match(TokenKind::LeftBrace)) {
        body_start = TokenKind::LeftBrace;
        body_end = TokenKind::RightBrace;
    } else {
        addErrorAtCurrent("expected '<' or '{' to start lambda body");
        return lambda;
    }

    while (!check(body_end) && !isAtEnd()) {
        lambda->body.push_back(parseStatement());
    }
    if (body_end == TokenKind::Greater) {
        consume(TokenKind::Greater, "expected '>' to end lambda body");
    } else {
        consume(TokenKind::RightBrace, "expected '}' to end lambda body");
    }

    return lambda;
}

ImportDecl Parser::parseImportDecl() {
    ImportDecl importDecl;
    importDecl.fromToken = advance();
    if (check(TokenKind::DoubleColon)) {
        advance();
    } else {
        consume(TokenKind::Colon, "expected ':' or '::' after 'from'");
    }
    importDecl.path.push_back(consume(TokenKind::Identifier, "expected identifier after 'from:'"));
    while (match(TokenKind::Dot)) {
        importDecl.path.push_back(consume(TokenKind::Identifier, "expected identifier after '.'"));
    }
    match(TokenKind::Semicolon);
    return importDecl;
}

std::unique_ptr<ClassDecl> Parser::parseClassDecl() {
    Token name = consume(TokenKind::Identifier, "expected class name");

    auto classDecl = std::make_unique<ClassDecl>();
    classDecl->name = std::move(name);

    while (match(TokenKind::DoubleColon)) {
        Token parent = advance();
        if (parent.kind != TokenKind::Identifier && !isTypeToken(parent)) {
            addErrorAtCurrent("expected trait name after '::'");
        }
        classDecl->parents.push_back(std::move(parent));
    }

    consume(TokenKind::ArrowClassStart, "expected '->' after class name");

    while (!isAtEnd() && !check(TokenKind::ArrowClassEnd)) {
        classDecl->members.push_back(parseClassMember());
    }

    const Token& endTok = consume(TokenKind::ArrowClassEnd, "expected '<-' to end class");
    classDecl->end = endTok.end;
    return classDecl;
}

ClassMember Parser::parseClassMember() {
    ClassMember member;
    if (check(TokenKind::Identifier) && current_ + 1 < tokens_.size() &&
        tokens_[current_ + 1].kind == TokenKind::LeftBrace) {
        member.kind = ClassMember::Kind::Method;
        member.method = parseMethodDecl();
        return member;
    }

    member.kind = ClassMember::Kind::Statement;
    member.statement = parseStatement();
    return member;
}

std::unique_ptr<MethodDecl> Parser::parseMethodDecl() {
    auto method = std::make_unique<MethodDecl>();
    method->name = consume(TokenKind::Identifier, "expected method name");

    consume(TokenKind::LeftBrace, "expected '{' after method name");
    if (!check(TokenKind::RightBrace)) {
        do {
            method->parameters.push_back(parseParameter());
        } while (match(TokenKind::Comma));
    }
    consume(TokenKind::RightBrace, "expected '}' after parameter list");
    consume(TokenKind::ArrowMethodStart, "expected '=>' after method declaration");

    for (;;) {
        if (isAtEnd() || check(TokenKind::ArrowMethodEnd)) break;

        if (check(TokenKind::LeftBracket)) {
            bool next_is_rbracket = current_ + 1 < tokens_.size() && tokens_[current_ + 1].kind == TokenKind::RightBracket;
            bool after_is_arrow = current_ + 2 < tokens_.size() && tokens_[current_ + 2].kind == TokenKind::ArrowMethodEnd;
            if (next_is_rbracket && after_is_arrow) break;
        }

        if (isMethodReturnStart()) break;

        method->body.push_back(parseStatement());
    }

    if (isMethodReturnStart()) {
        consume(TokenKind::LeftBracket, "expected '[' to start return expression");
        if (!check(TokenKind::RightBracket)) {
            method->returnValue = parseExpression();
        }
        consume(TokenKind::RightBracket, "expected ']' after return expression");
    }

    const Token& endTok = consume(TokenKind::ArrowMethodEnd, "expected '<--' to end method");
    method->end = endTok.end;
    return method;
}

ParameterDecl Parser::parseParameter() {
    ParameterDecl parameter;
    parameter.type = parseType();
    parameter.name = consume(TokenKind::Identifier, "expected parameter name");
    return parameter;
}

TypeRef Parser::parseType() {
    Token typeToken = advance();
    if (!isTypeToken(typeToken) && typeToken.kind != TokenKind::Identifier) {
        addErrorAtCurrent("expected type name");
    }

    TypeRef type{typeToken.lexeme, false, false};
    if (typeToken.kind == TokenKind::KeywordFileInteger) {
        type.name = "Integer";
        type.isFileBacked = true;
    } else if (typeToken.kind == TokenKind::KeywordFileString) {
        type.name = "String";
        type.isFileBacked = true;
    } else if (typeToken.kind == TokenKind::KeywordFileLong) {
        type.name = "Long";
        type.isFileBacked = true;
    } else if (typeToken.kind == TokenKind::KeywordFileDouble) {
        type.name = "Double";
        type.isFileBacked = true;
    } else if (typeToken.kind == TokenKind::KeywordFileBoolean) {
        type.name = "Boolean";
        type.isFileBacked = true;
    }
    if (match(TokenKind::LeftBracket)) {
        consume(TokenKind::RightBracket, "expected ']' after '[' in array type");
        type.isArray = true;
    }
    return type;
}

std::unique_ptr<Stmt> Parser::parseStatement() {
    if (check(TokenKind::KeywordIf)) {
        return parseIfStmt();
    }
    if (check(TokenKind::KeywordWhile)) {
        return parseWhileStmt();
    }
    if (check(TokenKind::KeywordFor)) {
        return parseForStmt();
    }
    if (check(TokenKind::KeywordSwitch)) {
        return parseSwitchStmt();
    }
    if (check(TokenKind::KeywordPrint) || check(TokenKind::KeywordPrintln)) {
        return parsePrintStmt();
    }
    if (check(TokenKind::Identifier) && peek().lexeme == "return") {
        return parseReturnStmt();
    }
    if (isTypeToken(peek()) || is_generic_type_decl_start(tokens_, current_)) {
        return parseVariableDecl();
    }
    if (check(TokenKind::LeftParen)) {
        if (looksLikeLambda()) {
            auto expr = parseLambdaExpr();
            match(TokenKind::Semicolon);
            return std::make_unique<ExprStmt>(std::move(expr));
        }
        return parseParenLedStatement();
    }
    auto expr = parseExpression();
    match(TokenKind::Semicolon);
    return std::make_unique<ExprStmt>(std::move(expr));
}

std::unique_ptr<Stmt> Parser::parseIfStmt() {
    advance();
    consume(TokenKind::LeftParen, "expected '(' after if");
    auto condition = parseExpression();
    consume(TokenKind::RightParen, "expected ')' after if condition");
    consume(TokenKind::LeftBrace, "expected '{' to start if block");

    auto stmt = std::make_unique<GuardBlockStmt>(std::move(condition), false);
    stmt->body = parseBraceBody();
    if (!stmt->body.empty()) stmt->end = stmt->body.back()->end;

    if (match(TokenKind::KeywordElse)) {
        if (check(TokenKind::KeywordIf)) {
            auto else_if = parseIfStmt();
            if (else_if) {
                stmt->end = else_if->end;
                stmt->elseBody.push_back(std::move(else_if));
            }
        } else {
            consume(TokenKind::LeftBrace, "expected '{' to start else block");
            stmt->elseBody = parseBraceBody();
            if (!stmt->elseBody.empty()) stmt->end = stmt->elseBody.back()->end;
        }
    }

    return stmt;
}

std::unique_ptr<Stmt> Parser::parseWhileStmt() {
    advance();
    consume(TokenKind::LeftParen, "expected '(' after while");
    auto condition = parseExpression();
    consume(TokenKind::RightParen, "expected ')' after while condition");
    consume(TokenKind::LeftBrace, "expected '{' to start while block");

    auto stmt = std::make_unique<GuardBlockStmt>(std::move(condition), true);
    stmt->body = parseBraceBody();
    if (!stmt->body.empty()) stmt->end = stmt->body.back()->end;
    return stmt;
}

std::unique_ptr<Stmt> Parser::parseForStmt() {
    advance();
    consume(TokenKind::LeftParen, "expected '(' after for");
    TypeRef type = parseType();
    Token name = consume(TokenKind::Identifier, "expected loop variable name");
    consume(TokenKind::Colon, "expected ':' after loop variable");
    auto iterable = parseExpression();
    consume(TokenKind::RightParen, "expected ')' after for header");
    consume(TokenKind::LeftBrace, "expected '{' to start for block");

    auto stmt = std::make_unique<ForEachStmt>(std::move(type), std::move(name), std::move(iterable));
    stmt->body = parseBraceBody();
    if (!stmt->body.empty()) stmt->end = stmt->body.back()->end;
    return stmt;
}

std::unique_ptr<Stmt> Parser::parseSwitchStmt() {
    advance();
    consume(TokenKind::LeftParen, "expected '(' after switch");
    auto subject = parseExpression();
    consume(TokenKind::RightParen, "expected ')' after switch subject");
    consume(TokenKind::LeftBrace, "expected '{' to start switch block");

    auto stmt = std::make_unique<SwitchStmt>(std::move(subject));
    while (!isAtEnd() && !check(TokenKind::RightBrace)) {
        stmt->cases.push_back(parseSwitchCase());
    }
    consume(TokenKind::RightBrace, "expected '}' to end switch block");
    if (!stmt->cases.empty()) stmt->end = stmt->cases.back().end;
    return stmt;
}

std::unique_ptr<Stmt> Parser::parseVariableDecl() {
    TypeRef type = parseType();
    Token name = consume(TokenKind::Identifier, "expected variable name");

    auto stmt = std::make_unique<VariableDeclStmt>(std::move(type), std::move(name));
    if (match(TokenKind::Assign)) {
        stmt->initializer = parseExpression();
        stmt->end = stmt->initializer ? stmt->initializer->end : stmt->end;
    }
    match(TokenKind::Semicolon);
    return stmt;
}

std::unique_ptr<Stmt> Parser::parsePrintStmt() {
    Token keyword = advance();
    consume(TokenKind::LeftParen, "expected '(' after print keyword");
    auto expr = parseExpression();
    consume(TokenKind::RightParen, "expected ')' after print expression");
    match(TokenKind::Semicolon);
    return std::make_unique<PrintStmt>(std::move(keyword), std::move(expr));
}

std::unique_ptr<Stmt> Parser::parseReturnStmt() {
    Token keyword = advance();
    SourceLocation start = keyword.start;

    std::unique_ptr<Expr> expr;
    if (!check(TokenKind::Semicolon) && !isAtEnd()) {
        expr = parseExpression();
    }
    match(TokenKind::Semicolon);

    SourceLocation end = expr ? expr->end : keyword.end;
    return std::make_unique<ReturnStmt>(std::move(expr), start, end);
}

std::unique_ptr<Stmt> Parser::parseParenLedStatement() {
    consume(TokenKind::LeftParen, "expected '('");

    if (isTypeToken(peek()) || is_generic_type_decl_start(tokens_, current_)) {
        TypeRef type = parseType();
        Token name = consume(TokenKind::Identifier, "expected loop variable name");
        consume(TokenKind::Colon, "expected ':' after loop variable");
        auto iterable = parseExpression();
        consume(TokenKind::RightParen, "expected ')' after foreach header");
        consume(TokenKind::Less, "expected '<' to start foreach body");
        auto stmt = std::make_unique<ForEachStmt>(std::move(type), std::move(name), std::move(iterable));
        stmt->body = parseAngleBody();
        if (!stmt->body.empty()) stmt->end = stmt->body.back()->end;
        return stmt;
    }

    auto header = parseExpression();
    consume(TokenKind::RightParen, "expected ')' after condition");

    if (!match(TokenKind::Less)) {
        addErrorAtCurrent("expected '<' to start block");
        return std::make_unique<ExprStmt>(std::move(header));
    }

    if (looksLikeSwitchBlock()) {
        auto stmt = std::make_unique<SwitchStmt>(std::move(header));
        while (!isAtEnd() && !check(TokenKind::Greater)) {
            stmt->cases.push_back(parseSwitchCase());
        }
        consume(TokenKind::Greater, "expected '>' to end switch block");
        if (!stmt->cases.empty()) stmt->end = stmt->cases.back().end;
        return stmt;
    }

    auto stmt = std::make_unique<GuardBlockStmt>(std::move(header));
    stmt->body = parseAngleBody();
    if (!stmt->body.empty()) stmt->end = stmt->body.back()->end;
    return stmt;
}

std::vector<std::unique_ptr<Stmt>> Parser::parseBraceBody() {
    std::vector<std::unique_ptr<Stmt>> body;
    while (!isAtEnd() && !check(TokenKind::RightBrace)) {
        body.push_back(parseStatement());
    }
    consume(TokenKind::RightBrace, "expected '}' to close block");
    return body;
}

std::vector<std::unique_ptr<Stmt>> Parser::parseAngleBody() {
    std::vector<std::unique_ptr<Stmt>> body;
    while (!isAtEnd() && !check(TokenKind::Greater)) {
        body.push_back(parseStatement());
    }
    consume(TokenKind::Greater, "expected '>' to close block");
    return body;
}

SwitchCase Parser::parseSwitchCase() {
    SwitchCase switchCase;
    if (match(TokenKind::KeywordDefault)) {
        switchCase.isDefault = true;
        switchCase.start = previous().start;
    } else if (match(TokenKind::KeywordCase)) {
        if (match(TokenKind::IntegerLiteral)) {
            switchCase.label = std::make_unique<LiteralExpr>(
                ExprKind::IntegerLiteral, previous().lexeme, previous().start, previous().end);
        } else if (match(TokenKind::StringLiteral)) {
            switchCase.label = std::make_unique<LiteralExpr>(
                ExprKind::StringLiteral, previous().lexeme, previous().start, previous().end);
        } else if (matchAny({TokenKind::KeywordTrue, TokenKind::KeywordFalse})) {
            switchCase.label = std::make_unique<LiteralExpr>(
                ExprKind::BooleanLiteral, previous().lexeme, previous().start, previous().end);
        } else if (match(TokenKind::Identifier)) {
            switchCase.label = std::make_unique<IdentifierExpr>(
                previous().lexeme, previous().start, previous().end);
        } else {
            addErrorAtCurrent("expected switch case label");
        }
        switchCase.start = switchCase.label ? switchCase.label->start : previous().start;
        match(TokenKind::Colon);
    } else if (match(TokenKind::IntegerLiteral)) {
        switchCase.label = std::make_unique<LiteralExpr>(
            ExprKind::IntegerLiteral, previous().lexeme, previous().start, previous().end);
    } else if (match(TokenKind::StringLiteral)) {
        switchCase.label = std::make_unique<LiteralExpr>(
            ExprKind::StringLiteral, previous().lexeme, previous().start, previous().end);
    } else if (matchAny({TokenKind::KeywordTrue, TokenKind::KeywordFalse})) {
        switchCase.label = std::make_unique<LiteralExpr>(
            ExprKind::BooleanLiteral, previous().lexeme, previous().start, previous().end);
    } else if (match(TokenKind::Identifier)) {
        switchCase.label = std::make_unique<IdentifierExpr>(
            previous().lexeme, previous().start, previous().end);
    } else {
        addErrorAtCurrent("expected switch case label");
        Token bad = advance();
        switchCase.label = std::make_unique<IdentifierExpr>(bad.lexeme, bad.start, bad.end);
    }

    if (!switchCase.isDefault && !switchCase.label) {
        switchCase.start = peek().start;
    } else if (!switchCase.isDefault) {
        switchCase.start = switchCase.label->start;
    }

    if (match(TokenKind::LeftBrace)) {
        switchCase.body = parseBraceBody();
        if (!switchCase.body.empty()) {
            switchCase.end = switchCase.body.back()->end;
        }
    } else {
        consume(TokenKind::LeftBracket, "expected '{' or '[' to start switch case body");
        while (!isAtEnd() && !check(TokenKind::RightBracket)) {
            switchCase.body.push_back(parseStatement());
        }
        const Token& endTok = consume(TokenKind::RightBracket, "expected ']' after switch case body");
        switchCase.end = endTok.end;
    }
    return switchCase;
}

std::unique_ptr<Expr> Parser::parseExpression() {
    return parseAssignment();
}

std::unique_ptr<Expr> Parser::parseAssignment() {
    // Keep ternary parsing separate from statement-level if/else parsing.
    auto expr = parseConditional();
    if (match(TokenKind::Assign)) {
        Token op = previous();
        auto value = parseAssignment();
        return std::make_unique<AssignmentExpr>(std::move(expr), std::move(op), std::move(value));
    }
    return expr;
}

std::unique_ptr<Expr> Parser::parseConditional() {
    // Ternary conditional expression: cond ? thenExpr : elseExpr
    auto expr = parseLogicalOr();
    if (match(TokenKind::Question)) {
        Token question = previous();
        auto then_branch = parseExpression();
        consume(TokenKind::Colon, "expected ':' in conditional expression");
        auto else_branch = parseConditional();
        return std::make_unique<ConditionalExpr>(
            std::move(expr), std::move(question), std::move(then_branch), std::move(else_branch));
    }
    return expr;
}

std::unique_ptr<Expr> Parser::parseLogicalOr() {
    auto expr = parseLogicalAnd();
    while (match(TokenKind::OrOr)) {
        Token op = previous();
        auto right = parseLogicalAnd();
        expr = std::make_unique<BinaryExpr>(std::move(expr), std::move(op), std::move(right));
    }
    return expr;
}

std::unique_ptr<Expr> Parser::parseLogicalAnd() {
    auto expr = parseEquality();
    while (match(TokenKind::AndAnd)) {
        Token op = previous();
        auto right = parseEquality();
        expr = std::make_unique<BinaryExpr>(std::move(expr), std::move(op), std::move(right));
    }
    return expr;
}

std::unique_ptr<Expr> Parser::parseEquality() {
    auto expr = parseComparison();
    while (matchAny({TokenKind::EqualEqual, TokenKind::BangEqual})) {
        Token op = previous();
        auto right = parseComparison();
        expr = std::make_unique<BinaryExpr>(std::move(expr), std::move(op), std::move(right));
    }
    return expr;
}

std::unique_ptr<Expr> Parser::parseComparison() {
    auto expr = parseTerm();
    while (matchAny({TokenKind::Less, TokenKind::LessEqual, TokenKind::Greater, TokenKind::GreaterEqual})) {
        Token op = previous();
        auto right = parseTerm();
        expr = std::make_unique<BinaryExpr>(std::move(expr), std::move(op), std::move(right));
    }
    return expr;
}

std::unique_ptr<Expr> Parser::parseTerm() {
    auto expr = parseFactor();
    while (matchAny({TokenKind::Plus, TokenKind::Minus})) {
        Token op = previous();
        auto right = parseFactor();
        expr = std::make_unique<BinaryExpr>(std::move(expr), std::move(op), std::move(right));
    }
    return expr;
}

std::unique_ptr<Expr> Parser::parseFactor() {
    auto expr = parseUnary();
    while (matchAny({TokenKind::Star, TokenKind::Slash, TokenKind::Percent})) {
        Token op = previous();
        auto right = parseUnary();
        expr = std::make_unique<BinaryExpr>(std::move(expr), std::move(op), std::move(right));
    }
    return expr;
}

std::unique_ptr<Expr> Parser::parseUnary() {
    if (matchAny({TokenKind::Bang, TokenKind::Minus, TokenKind::PlusPlus, TokenKind::MinusMinus})) {
        Token op = previous();
        auto operand = parseUnary();
        return std::make_unique<UnaryExpr>(std::move(op), std::move(operand));
    }
    return parsePostfix();
}

std::unique_ptr<Expr> Parser::parsePostfix() {
    auto expr = parsePrimary();

    for (;;) {
        if (match(TokenKind::Dot)) {
            Token member = consume(TokenKind::Identifier, "expected member name after '.'");
            expr = std::make_unique<MemberExpr>(std::move(expr), std::move(member));
            continue;
        }
        if (match(TokenKind::LeftBrace)) {
            auto args = parseArgumentList(TokenKind::RightBrace);
            auto call = std::make_unique<CallExpr>(std::move(expr));
            call->arguments = std::move(args);
            call->end = previous().end;
            if (call->callee) call->start = call->callee->start;
            expr = std::move(call);
            continue;
        }
        if (match(TokenKind::LeftParen)) {
            auto args = parseArgumentList(TokenKind::RightParen);
            auto call = std::make_unique<CallExpr>(std::move(expr));
            call->arguments = std::move(args);
            call->end = previous().end;
            if (call->callee) call->start = call->callee->start;
            expr = std::move(call);
            continue;
        }
        if (match(TokenKind::LeftBracket)) {
            if (check(TokenKind::RightBracket) && current_ + 1 < tokens_.size() &&
                tokens_[current_ + 1].kind == TokenKind::ArrowMethodEnd) {
                current_--;
                break;
            }
            auto index = parseExpression();
            const Token& endTok = consume(TokenKind::RightBracket, "expected ']' after index expression");
            expr = std::make_unique<IndexExpr>(std::move(expr), std::move(index), endTok.end);
            continue;
        }
        if (matchAny({TokenKind::PlusPlus, TokenKind::MinusMinus})) {
            Token op = previous();
            expr = std::make_unique<PostfixExpr>(std::move(expr), std::move(op));
            continue;
        }
        break;
    }

    return expr;
}

std::unique_ptr<Expr> Parser::parsePrimary() {
    if (match(TokenKind::Identifier)) {
        return std::make_unique<IdentifierExpr>(previous().lexeme, previous().start, previous().end);
    }
    if (matchAny({TokenKind::KeywordPrint, TokenKind::KeywordPrintln})) {
        return std::make_unique<IdentifierExpr>(previous().lexeme, previous().start, previous().end);
    }
    if (match(TokenKind::IntegerLiteral)) {
        return std::make_unique<LiteralExpr>(ExprKind::IntegerLiteral, previous().lexeme, previous().start, previous().end);
    }
    if (match(TokenKind::LongLiteral)) {
        return std::make_unique<LiteralExpr>(ExprKind::LongLiteral, previous().lexeme, previous().start, previous().end);
    }
    if (match(TokenKind::DoubleLiteral)) {
        return std::make_unique<LiteralExpr>(ExprKind::DoubleLiteral, previous().lexeme, previous().start, previous().end);
    }
    if (match(TokenKind::StringLiteral)) {
        return std::make_unique<LiteralExpr>(ExprKind::StringLiteral, previous().lexeme, previous().start, previous().end);
    }
    if (matchAny({TokenKind::KeywordTrue, TokenKind::KeywordFalse})) {
        return std::make_unique<LiteralExpr>(ExprKind::BooleanLiteral, previous().lexeme, previous().start, previous().end);
    }
    if (check(TokenKind::LeftParen)) {
        if (looksLikeLambda()) {
            return parseLambdaExpr();
        }
        consume(TokenKind::LeftParen, "expected '('");
        auto expr = parseExpression();
        consume(TokenKind::RightParen, "expected ')' after expression");
        return std::make_unique<GroupingExpr>(std::move(expr));
    }
    if (check(TokenKind::LeftBrace)) {
        return parseArrayLiteral();
    }

    addErrorAtCurrent("expected expression");
    Token bad = advance();
    return std::make_unique<IdentifierExpr>(bad.lexeme, bad.start, bad.end);
}

std::vector<std::unique_ptr<Expr>> Parser::parseArgumentList(TokenKind closingKind) {
    std::vector<std::unique_ptr<Expr>> arguments;
    if (!check(closingKind)) {
        do {
            arguments.push_back(parseExpression());
        } while (match(TokenKind::Comma));
    }
    consume(closingKind, "expected closing delimiter after arguments");
    return arguments;
}

std::unique_ptr<ArrayLiteralExpr> Parser::parseArrayLiteral() {
    const Token& startTok = consume(TokenKind::LeftBrace, "expected '{' to start array literal");
    auto array = std::make_unique<ArrayLiteralExpr>(startTok.start, startTok.end);
    if (!check(TokenKind::RightBrace)) {
        do {
            array->elements.push_back(parseExpression());
        } while (match(TokenKind::Comma));
    }
    const Token& endTok = consume(TokenKind::RightBrace, "expected '}' after array literal");
    array->end = endTok.end;
    return array;
}
