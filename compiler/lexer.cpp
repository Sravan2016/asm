#include "lexer.h"

#include <cctype>
#include <utility>

namespace {

bool is_digit(char c) {
    return c >= '0' && c <= '9';
}

} // namespace

Lexer::Lexer(std::string source, std::string file_path) : source_(std::move(source)), file_path_(std::move(file_path)) {}

Token Lexer::nextToken() {
    skipWhitespaceAndComments();

    const SourceLocation start{file_path_, line_, column_};
    const std::size_t startPos = pos_;

    if (isAtEnd()) {
        return makeToken(TokenKind::EndOfFile, startPos, start);
    }

    const char c = advance();

    if (isIdentifierStart(c)) {
        return scanIdentifierOrKeyword();
    }

    if (is_digit(c)) {
        return scanNumber();
    }

    switch (c) {
        case '"':
            return scanString();
        case '+':
            if (match('+')) return makeToken(TokenKind::PlusPlus, startPos, start);
            return makeToken(TokenKind::Plus, startPos, start);
        case '-':
            if (match('-')) {
                if (match('>')) return makeToken(TokenKind::ArrowMethodStart, startPos, start);
                return makeToken(TokenKind::MinusMinus, startPos, start);
            }
            if (match('>')) return makeToken(TokenKind::ArrowClassStart, startPos, start);
            return makeToken(TokenKind::Minus, startPos, start);
        case '*':
            return makeToken(TokenKind::Star, startPos, start);
        case '/':
            return makeToken(TokenKind::Slash, startPos, start);
        case '%':
            return makeToken(TokenKind::Percent, startPos, start);
        case '=':
            if (match('>')) return makeToken(TokenKind::FatArrow, startPos, start);
            if (match('=')) return makeToken(TokenKind::EqualEqual, startPos, start);
            return makeToken(TokenKind::Assign, startPos, start);
        case '!':
            if (match('=')) return makeToken(TokenKind::BangEqual, startPos, start);
            return makeToken(TokenKind::Bang, startPos, start);
        case '<':
            if (match('-')) {
                if (match('-')) return makeToken(TokenKind::ArrowMethodEnd, startPos, start);
                return makeToken(TokenKind::ArrowClassEnd, startPos, start);
            }
            if (match('=')) return makeToken(TokenKind::LessEqual, startPos, start);
            return makeToken(TokenKind::Less, startPos, start);
        case '>':
            if (match('=')) return makeToken(TokenKind::GreaterEqual, startPos, start);
            return makeToken(TokenKind::Greater, startPos, start);
        case '&':
            if (match('&')) return makeToken(TokenKind::AndAnd, startPos, start);
            return makeInvalidToken(startPos, start, "unexpected character '&'");
        case '|':
            if (match('|')) return makeToken(TokenKind::OrOr, startPos, start);
            return makeInvalidToken(startPos, start, "unexpected character '|'");
        case '(':
            return makeToken(TokenKind::LeftParen, startPos, start);
        case ')':
            return makeToken(TokenKind::RightParen, startPos, start);
        case '{':
            return makeToken(TokenKind::LeftBrace, startPos, start);
        case '}':
            return makeToken(TokenKind::RightBrace, startPos, start);
        case '[':
            return makeToken(TokenKind::LeftBracket, startPos, start);
        case ']':
            return makeToken(TokenKind::RightBracket, startPos, start);
        case ',':
            return makeToken(TokenKind::Comma, startPos, start);
        case ':':
            if (match(':')) return makeToken(TokenKind::DoubleColon, startPos, start);
            return makeToken(TokenKind::Colon, startPos, start);
        case ';':
            return makeToken(TokenKind::Semicolon, startPos, start);
        case '.':
            return makeToken(TokenKind::Dot, startPos, start);
        default:
            return makeInvalidToken(startPos, start, std::string("unexpected character '") + c + "'");
    }
}

std::vector<Token> Lexer::tokenizeAll() {
    std::vector<Token> tokens;
    for (;;) {
        Token token = nextToken();
        tokens.push_back(token);
        if (token.kind == TokenKind::EndOfFile) {
            break;
        }
    }
    return tokens;
}

bool Lexer::hasError() const {
    return !errors_.empty();
}

const std::vector<LexError>& Lexer::errors() const {
    return errors_;
}

bool Lexer::isAtEnd() const {
    return pos_ >= source_.size();
}

char Lexer::peek() const {
    return isAtEnd() ? '\0' : source_[pos_];
}

char Lexer::peekNext() const {
    return (pos_ + 1 >= source_.size()) ? '\0' : source_[pos_ + 1];
}

char Lexer::advance() {
    if (isAtEnd()) return '\0';
    const char c = source_[pos_++];
    if (c == '\n') {
        ++line_;
        column_ = 1;
    } else {
        ++column_;
    }
    return c;
}

bool Lexer::match(char expected) {
    if (isAtEnd() || source_[pos_] != expected) return false;
    advance();
    return true;
}

void Lexer::skipWhitespaceAndComments() {
    for (;;) {
        const char c = peek();
        switch (c) {
            case ' ':
            case '\t':
            case '\r':
            case '\n':
                advance();
                break;
            case '/':
                if (peekNext() == '/') {
                    advance();
                    advance();
                    while (!isAtEnd() && peek() != '\n') {
                        advance();
                    }
                } else if (peekNext() == '*') {
                    const SourceLocation start{file_path_, line_, column_};
                    advance();
                    advance();
                    bool closed = false;
                    while (!isAtEnd()) {
                        if (peek() == '*' && peekNext() == '/') {
                            advance();
                            advance();
                            closed = true;
                            break;
                        }
                        advance();
                    }
                    if (!closed) {
                        addError("unterminated block comment", start);
                    }
                } else {
                    return;
                }
                break;
            default:
                return;
        }
    }
}

Token Lexer::makeToken(TokenKind kind, std::size_t startPos, SourceLocation start) const {
    return Token{kind, source_.substr(startPos, pos_ - startPos), start, SourceLocation{file_path_, line_, column_}};
}

Token Lexer::makeInvalidToken(std::size_t startPos, SourceLocation start, const std::string& message) {
    addError(message, start);
    return Token{TokenKind::Invalid, source_.substr(startPos, pos_ - startPos), start, SourceLocation{file_path_, line_, column_}};
}

void Lexer::addError(const std::string& message, SourceLocation location) {
    errors_.push_back(LexError{message, location});
}

Token Lexer::scanIdentifierOrKeyword() {
    const SourceLocation start{file_path_, line_, column_ - 1};
    const std::size_t startPos = pos_ - 1;
    while (isIdentifierPart(peek())) {
        advance();
    }

    const std::string text = source_.substr(startPos, pos_ - startPos);
    return Token{keywordKind(text), text, start, SourceLocation{file_path_, line_, column_}};
}

Token Lexer::scanNumber() {
    const SourceLocation start{file_path_, line_, column_ - 1};
    const std::size_t startPos = pos_ - 1;
    while (is_digit(peek())) {
        advance();
    }

    if (peek() == 'l' || peek() == 'L') {
        advance();
        return Token{TokenKind::LongLiteral, source_.substr(startPos, pos_ - startPos), start, SourceLocation{file_path_, line_, column_}};
    }
    if (peek() == 'd' || peek() == 'D') {
        advance();
        return Token{TokenKind::DoubleLiteral, source_.substr(startPos, pos_ - startPos), start, SourceLocation{file_path_, line_, column_}};
    }

    return Token{TokenKind::IntegerLiteral, source_.substr(startPos, pos_ - startPos), start, SourceLocation{file_path_, line_, column_}};
}

Token Lexer::scanString() {
    const SourceLocation start{file_path_, line_, column_ - 1};
    const std::size_t startPos = pos_ - 1;
    bool escaped = false;

    while (!isAtEnd()) {
        const char c = advance();
        if (escaped) {
            switch (c) {
                case 'n':
                case 't':
                case '\\':
                case '"':
                    escaped = false;
                    break;
                default:
                    return makeInvalidToken(startPos, start, std::string("invalid escape sequence '\\") + c + "'");
            }
            continue;
        }

        if (c == '\\') {
            escaped = true;
            continue;
        }

        if (c == '"') {
            return Token{TokenKind::StringLiteral, source_.substr(startPos, pos_ - startPos), start, SourceLocation{file_path_, line_, column_}};
        }

        if (c == '\n') {
            return makeInvalidToken(startPos, start, "unterminated string literal");
        }
    }

    return makeInvalidToken(startPos, start, "unterminated string literal");
}

bool Lexer::isIdentifierStart(char c) {
    return std::isalpha(static_cast<unsigned char>(c)) != 0 || c == '_';
}

bool Lexer::isIdentifierPart(char c) {
    return std::isalnum(static_cast<unsigned char>(c)) != 0 || c == '_';
}

TokenKind Lexer::keywordKind(const std::string& text) {
    if (text == "class") return TokenKind::KeywordClass;
    if (text == "inheritence") return TokenKind::KeywordInheritance;
    if (text == "methodcall") return TokenKind::KeywordMethodCall;
    if (text == "if") return TokenKind::KeywordIf;
    if (text == "else") return TokenKind::KeywordElse;
    if (text == "while") return TokenKind::KeywordWhile;
    if (text == "switch") return TokenKind::KeywordSwitch;
    if (text == "for") return TokenKind::KeywordFor;
    if (text == "case") return TokenKind::KeywordCase;
    if (text == "default") return TokenKind::KeywordDefault;
    if (text == "print") return TokenKind::KeywordPrint;
    if (text == "println") return TokenKind::KeywordPrintln;
    if (text == "Integer") return TokenKind::KeywordInteger;
    if (text == "FileInteger") return TokenKind::KeywordFileInteger;
    if (text == "String") return TokenKind::KeywordString;
    if (text == "FileString") return TokenKind::KeywordFileString;
    if (text == "Long") return TokenKind::KeywordLong;
    if (text == "FileLong") return TokenKind::KeywordFileLong;
    if (text == "Double") return TokenKind::KeywordDouble;
    if (text == "FileDouble") return TokenKind::KeywordFileDouble;
    if (text == "Boolean") return TokenKind::KeywordBoolean;
    if (text == "FileBoolean") return TokenKind::KeywordFileBoolean;
    if (text == "Array") return TokenKind::KeywordArray;
    if (text == "Thread") return TokenKind::KeywordThread;
    if (text == "from") return TokenKind::KeywordFrom;
    if (text == "true") return TokenKind::KeywordTrue;
    if (text == "false") return TokenKind::KeywordFalse;
    return TokenKind::Identifier;
}

const char* token_kind_name(TokenKind kind) {
    switch (kind) {
        case TokenKind::EndOfFile: return "EndOfFile";
        case TokenKind::Invalid: return "Invalid";
        case TokenKind::Identifier: return "Identifier";
        case TokenKind::IntegerLiteral: return "IntegerLiteral";
        case TokenKind::LongLiteral: return "LongLiteral";
        case TokenKind::DoubleLiteral: return "DoubleLiteral";
        case TokenKind::StringLiteral: return "StringLiteral";
        case TokenKind::KeywordClass: return "KeywordClass";
        case TokenKind::KeywordInheritance: return "KeywordInheritance";
        case TokenKind::KeywordMethodCall: return "KeywordMethodCall";
        case TokenKind::KeywordIf: return "KeywordIf";
        case TokenKind::KeywordElse: return "KeywordElse";
        case TokenKind::KeywordWhile: return "KeywordWhile";
        case TokenKind::KeywordSwitch: return "KeywordSwitch";
        case TokenKind::KeywordFor: return "KeywordFor";
        case TokenKind::KeywordCase: return "KeywordCase";
        case TokenKind::KeywordDefault: return "KeywordDefault";
        case TokenKind::KeywordPrint: return "KeywordPrint";
        case TokenKind::KeywordPrintln: return "KeywordPrintln";
        case TokenKind::KeywordInteger: return "KeywordInteger";
        case TokenKind::KeywordFileInteger: return "KeywordFileInteger";
        case TokenKind::KeywordString: return "KeywordString";
        case TokenKind::KeywordFileString: return "KeywordFileString";
        case TokenKind::KeywordLong: return "KeywordLong";
        case TokenKind::KeywordFileLong: return "KeywordFileLong";
        case TokenKind::KeywordDouble: return "KeywordDouble";
        case TokenKind::KeywordFileDouble: return "KeywordFileDouble";
        case TokenKind::KeywordBoolean: return "KeywordBoolean";
        case TokenKind::KeywordFileBoolean: return "KeywordFileBoolean";
        case TokenKind::KeywordArray: return "KeywordArray";
        case TokenKind::KeywordMap: return "KeywordMap";
        case TokenKind::KeywordThread: return "KeywordThread";
        case TokenKind::KeywordFrom: return "KeywordFrom";
        case TokenKind::KeywordTrue: return "KeywordTrue";
        case TokenKind::KeywordFalse: return "KeywordFalse";
        case TokenKind::ArrowClassStart: return "ArrowClassStart";
        case TokenKind::ArrowClassEnd: return "ArrowClassEnd";
        case TokenKind::ArrowMethodStart: return "ArrowMethodStart";
        case TokenKind::ArrowMethodEnd: return "ArrowMethodEnd";
        case TokenKind::FatArrow: return "FatArrow";
        case TokenKind::Plus: return "Plus";
        case TokenKind::PlusPlus: return "PlusPlus";
        case TokenKind::Minus: return "Minus";
        case TokenKind::MinusMinus: return "MinusMinus";
        case TokenKind::Star: return "Star";
        case TokenKind::Slash: return "Slash";
        case TokenKind::Percent: return "Percent";
        case TokenKind::Assign: return "Assign";
        case TokenKind::EqualEqual: return "EqualEqual";
        case TokenKind::Bang: return "Bang";
        case TokenKind::BangEqual: return "BangEqual";
        case TokenKind::Less: return "Less";
        case TokenKind::LessEqual: return "LessEqual";
        case TokenKind::Greater: return "Greater";
        case TokenKind::GreaterEqual: return "GreaterEqual";
        case TokenKind::AndAnd: return "AndAnd";
        case TokenKind::OrOr: return "OrOr";
        case TokenKind::Comma: return "Comma";
        case TokenKind::Colon: return "Colon";
        case TokenKind::Semicolon: return "Semicolon";
        case TokenKind::Dot: return "Dot";
        case TokenKind::DoubleColon: return "DoubleColon";
        case TokenKind::LeftParen: return "LeftParen";
        case TokenKind::RightParen: return "RightParen";
        case TokenKind::LeftBrace: return "LeftBrace";
        case TokenKind::RightBrace: return "RightBrace";
        case TokenKind::LeftBracket: return "LeftBracket";
        case TokenKind::RightBracket: return "RightBracket";
        case TokenKind::LeftAngle: return "LeftAngle";
        case TokenKind::RightAngle: return "RightAngle";
    }
    return "Unknown";
}
