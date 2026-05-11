#include <cstdint>
#include <cstring>
#include <iostream>
#include <vector>

enum TokenKind {
    EndOfFile = 0,
    Invalid = 1,
    Identifier = 2,
    IntegerLiteral = 3,
    LongLiteral = 4,
    DoubleLiteral = 5,
    StringLiteral = 6,
    KeywordIf = 10,
    KeywordElse = 11,
    KeywordWhile = 12,
    KeywordSwitch = 13,
    KeywordFor = 14,
    KeywordCase = 15,
    KeywordDefault = 16,
    KeywordPrint = 17,
    KeywordPrintln = 18,
    KeywordInteger = 19,
    KeywordFileInteger = 20,
    KeywordString = 21,
    KeywordFileString = 22,
    KeywordLong = 23,
    KeywordFileLong = 24,
    KeywordDouble = 25,
    KeywordFileDouble = 26,
    KeywordBoolean = 27,
    KeywordFileBoolean = 28,
    KeywordArray = 29,
    KeywordMap = 30,
    KeywordThread = 31,
    KeywordFrom = 32,
    KeywordTrue = 33,
    KeywordFalse = 34,
    KeywordPrivate = 35,
    ArrowClassStart = 36,
    ArrowClassEnd = 37,
    ArrowMethodStart = 38,
    ArrowMethodEnd = 39,
    FatArrow = 40,
    Plus = 41,
    PlusPlus = 42,
    Minus = 43,
    MinusMinus = 44,
    Star = 45,
    Slash = 46,
    Percent = 47,
    Assign = 48,
    EqualEqual = 49,
    Bang = 50,
    BangEqual = 51,
    Less = 52,
    LessEqual = 53,
    Greater = 54,
    GreaterEqual = 55,
    AndAnd = 56,
    OrOr = 57,
    Question = 58,
    Comma = 59,
    Colon = 60,
    Semicolon = 61,
    Dot = 62,
    DoubleColon = 63,
    LeftParen = 64,
    RightParen = 65,
    LeftBrace = 66,
    RightBrace = 67,
    LeftBracket = 68,
    RightBracket = 69
};

struct AsmToken {
    std::int32_t kind;
    std::uint32_t pad;
    const char* lexeme;
};

struct AsmParser {
    AsmToken* tokens;
    std::uint64_t count;
    std::uint64_t current;
    std::uint64_t errors;
    std::uint64_t imports;
    std::uint64_t classes;
    std::uint64_t methods;
    std::uint64_t statements;
    std::uint64_t expressions;
    const char* last_type;
    std::uint64_t last_flags;
};

static_assert(sizeof(AsmToken) == 16);
static_assert(sizeof(AsmParser) == 88);

extern "C" {
void parser_init(AsmParser* parser, AsmToken* tokens, std::uint64_t count);
std::uint64_t parser_error_count(AsmParser* parser);
int parser_has_error(AsmParser* parser);
void parser_add_error(AsmParser* parser);
int parser_token_kind_at(AsmParser* parser, std::uint64_t index);
const char* parser_token_lexeme_at(AsmParser* parser, std::uint64_t index);
int parser_peek_kind(AsmParser* parser);
int parser_previous_kind(AsmParser* parser);
int parser_is_at_end(AsmParser* parser);
int parser_check(AsmParser* parser, int kind);
int parser_advance(AsmParser* parser);
int parser_match(AsmParser* parser, int kind);
int parser_consume(AsmParser* parser, int kind);
int parser_is_type_kind(int kind);
int parser_is_file_type_kind(int kind);
int parser_is_statement_boundary(int kind);
int parser_looks_like_method_decl(AsmParser* parser);
int parser_looks_like_lambda(AsmParser* parser);
int parser_is_method_return_start(AsmParser* parser);
int parser_looks_like_switch_block(AsmParser* parser);
std::uint64_t parser_parse_type(AsmParser* parser);
int parser_parse_expression(AsmParser* parser);
void parser_parse_statement(AsmParser* parser);
void parser_parse_method_decl(AsmParser* parser);
void parser_parse_class_decl(AsmParser* parser);
void parser_parse_import_decl(AsmParser* parser);
void parser_parse_program(AsmParser* parser);
}

static AsmToken t(int kind, const char* lexeme) {
    return AsmToken{kind, 0, lexeme};
}

static void expect(bool condition, const char* label, int& failures) {
    if (condition) {
        std::cout << "[PASS] " << label << '\n';
        return;
    }
    std::cout << "[FAIL] " << label << '\n';
    ++failures;
}

static AsmParser parser_for(std::vector<AsmToken>& tokens) {
    AsmParser parser{};
    parser_init(&parser, tokens.data(), tokens.size());
    return parser;
}

int main() {
    int failures = 0;

    std::vector<AsmToken> cursor_tokens{
        t(KeywordInteger, "Integer"), t(Identifier, "count"), t(Semicolon, ";"), t(EndOfFile, "")
    };
    AsmParser cursor = parser_for(cursor_tokens);
    expect(parser_peek_kind(&cursor) == KeywordInteger, "positive: peek returns current token kind", failures);
    expect(parser_check(&cursor, KeywordInteger) == 1, "positive: check matches current token", failures);
    expect(parser_match(&cursor, KeywordInteger) == 1, "positive: match advances on expected token", failures);
    expect(parser_previous_kind(&cursor) == KeywordInteger, "positive: previous returns last consumed token", failures);
    expect(parser_match(&cursor, KeywordString) == 0, "negative: match rejects wrong token", failures);
    expect(cursor.current == 1, "negative: failed match does not advance", failures);
    expect(parser_consume(&cursor, KeywordString) == 0 && parser_has_error(&cursor) == 1,
           "negative: consume records parse error", failures);

    expect(parser_is_type_kind(KeywordInteger) == 1, "positive: primitive type recognized", failures);
    expect(parser_is_type_kind(KeywordMap) == 1, "positive: collection type recognized", failures);
    expect(parser_is_type_kind(Identifier) == 0, "negative: identifier is not built-in type token", failures);
    expect(parser_is_file_type_kind(KeywordFileString) == 1, "positive: file-backed type recognized", failures);
    expect(parser_is_file_type_kind(KeywordString) == 0, "negative: normal type is not file-backed", failures);
    expect(parser_is_statement_boundary(KeywordIf) == 1, "positive: if starts a statement", failures);
    expect(parser_is_statement_boundary(Star) == 0, "negative: operator is not a statement boundary", failures);

    std::vector<AsmToken> type_tokens{
        t(KeywordFileInteger, "Integer"), t(LeftBracket, "["), t(RightBracket, "]"), t(EndOfFile, "")
    };
    AsmParser type_parser = parser_for(type_tokens);
    std::uint64_t flags = parser_parse_type(&type_parser);
    expect((flags & 1) != 0, "positive: parse_type marks valid type", failures);
    expect((flags & 2) != 0, "positive: parse_type marks array type", failures);
    expect((flags & 4) != 0, "positive: parse_type marks file-backed type", failures);
    expect(type_parser.current == 3, "positive: parse_type consumes array suffix", failures);

    std::vector<AsmToken> bad_type_tokens{t(Star, "*"), t(EndOfFile, "")};
    AsmParser bad_type = parser_for(bad_type_tokens);
    expect(parser_parse_type(&bad_type) == 0 && parser_error_count(&bad_type) == 1,
           "negative: parse_type rejects invalid type token", failures);

    std::vector<AsmToken> method_tokens{
        t(KeywordPrivate, "private"), t(Identifier, "compute"), t(LeftBrace, "{"), t(RightBrace, "}"),
        t(ArrowMethodStart, "-->"), t(KeywordPrint, "print"), t(LeftParen, "("), t(Identifier, "x"),
        t(RightParen, ")"), t(Semicolon, ";"), t(LeftBracket, "["), t(Identifier, "x"),
        t(RightBracket, "]"), t(ArrowMethodEnd, "<--"), t(EndOfFile, "")
    };
    AsmParser method_parser = parser_for(method_tokens);
    expect(parser_looks_like_method_decl(&method_parser) == 1, "positive: private method declaration lookahead", failures);
    parser_parse_method_decl(&method_parser);
    expect(method_parser.methods == 1, "positive: parse_method_decl counts method", failures);
    expect(method_parser.statements == 1, "positive: parse_method_decl parses method body statement", failures);
    expect(method_parser.errors == 0, "positive: valid method has no errors", failures);

    std::vector<AsmToken> lambda_tokens{
        t(LeftParen, "("), t(Identifier, "x"), t(RightParen, ")"), t(FatArrow, "=>"),
        t(LeftBrace, "{"), t(RightBrace, "}"), t(EndOfFile, "")
    };
    AsmParser lambda_parser = parser_for(lambda_tokens);
    expect(parser_looks_like_lambda(&lambda_parser) == 1, "positive: lambda lookahead sees fat arrow", failures);

    std::vector<AsmToken> not_lambda_tokens{
        t(LeftParen, "("), t(Identifier, "x"), t(RightParen, ")"), t(Less, "<"), t(EndOfFile, "")
    };
    AsmParser not_lambda = parser_for(not_lambda_tokens);
    expect(parser_looks_like_lambda(&not_lambda) == 0, "negative: parenthesized condition is not lambda", failures);

    std::vector<AsmToken> switch_tokens{
        t(IntegerLiteral, "1"), t(LeftBracket, "["), t(KeywordPrintln, "println"),
        t(LeftParen, "("), t(StringLiteral, "one"), t(RightParen, ")"), t(Semicolon, ";"),
        t(RightBracket, "]"), t(Greater, ">"), t(EndOfFile, "")
    };
    AsmParser switch_parser = parser_for(switch_tokens);
    expect(parser_looks_like_switch_block(&switch_parser) == 1, "positive: switch block lookahead finds case label", failures);

    std::vector<AsmToken> expression_tokens{
        t(Identifier, "a"), t(Plus, "+"), t(IntegerLiteral, "1"), t(Star, "*"),
        t(IntegerLiteral, "2"), t(Semicolon, ";"), t(EndOfFile, "")
    };
    AsmParser expr_parser = parser_for(expression_tokens);
    expect(parser_parse_expression(&expr_parser) == 1, "positive: parse_expression consumes expression tokens", failures);
    expect(expr_parser.expressions == 1 && expr_parser.current == 5,
           "positive: parse_expression stops before semicolon", failures);

    std::vector<AsmToken> bad_expression_tokens{t(Semicolon, ";"), t(EndOfFile, "")};
    AsmParser bad_expr = parser_for(bad_expression_tokens);
    expect(parser_parse_expression(&bad_expr) == 0 && bad_expr.errors == 1,
           "negative: parse_expression rejects empty expression", failures);

    std::vector<AsmToken> program_tokens{
        t(KeywordFrom, "from"), t(Colon, ":"), t(Identifier, "com"), t(Dot, "."),
        t(Identifier, "base"), t(Semicolon, ";"),
        t(Identifier, "User"), t(ArrowClassStart, "->"),
        t(Identifier, "init"), t(LeftBrace, "{"), t(RightBrace, "}"), t(ArrowMethodStart, "-->"),
        t(KeywordString, "String"), t(Identifier, "name"), t(Assign, "="), t(StringLiteral, "Sravan"), t(Semicolon, ";"),
        t(KeywordPrintln, "println"), t(LeftParen, "("), t(Identifier, "name"), t(RightParen, ")"), t(Semicolon, ";"),
        t(LeftBracket, "["), t(Identifier, "name"), t(RightBracket, "]"), t(ArrowMethodEnd, "<--"),
        t(ArrowClassEnd, "<-"), t(EndOfFile, "")
    };
    AsmParser program = parser_for(program_tokens);
    parser_parse_program(&program);
    expect(program.imports == 1, "positive: parse_program counts import declaration", failures);
    expect(program.classes == 1, "positive: parse_program counts class declaration", failures);
    expect(program.methods == 1, "positive: parse_program counts method declaration", failures);
    expect(program.statements == 2, "positive: parse_program counts variable and print statements", failures);
    expect(program.errors == 0, "positive: parse_program accepts valid class", failures);

    std::vector<AsmToken> bad_program_tokens{
        t(Identifier, "Broken"), t(Identifier, "field"), t(Semicolon, ";"), t(EndOfFile, "")
    };
    AsmParser bad_program = parser_for(bad_program_tokens);
    parser_parse_program(&bad_program);
    expect(bad_program.classes == 1, "negative: parser still records attempted class", failures);
    expect(bad_program.errors > 0, "negative: missing class arrow/end records errors", failures);

    if (failures == 0) {
        std::cout << "Parser asm scenarios passed\n";
        return 0;
    }

    std::cout << "Parser asm scenarios failed: " << failures << '\n';
    return 1;
}
