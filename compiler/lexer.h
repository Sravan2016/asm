#pragma once

#include <string>
#include <vector>

enum class TokenKind {
    EndOfFile,
    Invalid,

    Identifier,
    IntegerLiteral,
    LongLiteral,
    DoubleLiteral,
    StringLiteral,

    KeywordClass,
    KeywordInheritance,
    KeywordMethodCall,
    KeywordIf,
    KeywordElse,
    KeywordWhile,
    KeywordSwitch,
    KeywordFor,
    KeywordCase,
    KeywordDefault,
    KeywordPrint,
    KeywordPrintln,
    KeywordInteger,
    KeywordFileInteger,
    KeywordString,
    KeywordFileString,
    KeywordLong,
    KeywordFileLong,
    KeywordDouble,
    KeywordFileDouble,
    KeywordBoolean,
    KeywordFileBoolean,
    KeywordArray,
    KeywordMap,
    KeywordThread,
    KeywordFrom,
    KeywordTrue,
    KeywordFalse,

    ArrowClassStart,   // ->
    ArrowClassEnd,     // <-
    ArrowMethodStart,  // -->
    ArrowMethodEnd,    // <--
    FatArrow,          // =>

    Plus,
    PlusPlus,
    Minus,
    MinusMinus,
    Star,
    Slash,
    Percent,
    Assign,
    EqualEqual,
    Bang,
    BangEqual,
    Less,
    LessEqual,
    Greater,
    GreaterEqual,
    AndAnd,
    OrOr,
    Question,
    Comma,
    Colon,
    Semicolon,
    Dot,
    DoubleColon,
    LeftParen,
    RightParen,
    LeftBrace,
    RightBrace,
    LeftBracket,
    RightBracket,
    LeftAngle,
    RightAngle
};

struct SourceLocation {
    std::string file_path;
    int line = 1;
    int column = 1;
};

struct Token {
    TokenKind kind = TokenKind::Invalid;
    std::string lexeme;
    SourceLocation start;
    SourceLocation end;
};

struct LexError {
    std::string message;
    SourceLocation location;
};

class Lexer {
public:
    explicit Lexer(std::string source, std::string file_path = "");

    Token nextToken();
    std::vector<Token> tokenizeAll();

    bool hasError() const;
    const std::vector<LexError>& errors() const;

private:
    bool isAtEnd() const;
    char peek() const;
    char peekNext() const;
    char advance();
    bool match(char expected);

    void skipWhitespaceAndComments();
    Token makeToken(TokenKind kind, std::size_t startPos, SourceLocation start) const;
    Token makeInvalidToken(std::size_t startPos, SourceLocation start, const std::string& message);
    void addError(const std::string& message, SourceLocation location);

    Token scanIdentifierOrKeyword();
    Token scanNumber();
    Token scanString();

    static bool isIdentifierStart(char c);
    static bool isIdentifierPart(char c);
    static TokenKind keywordKind(const std::string& text);

private:
    std::string source_;
    std::string file_path_;
    std::size_t pos_ = 0;
    int line_ = 1;
    int column_ = 1;
    std::vector<LexError> errors_;
};

const char* token_kind_name(TokenKind kind);
