#include <cstddef>
#include <cstdint>
#include <cstring>
#include <iostream>
#include <string>

struct AsmToken {
    int kind;
    char lexeme[64];
    int start_line;
    int start_column;
    int end_line;
    int end_column;
};

struct AsmLexError {
    char message[96];
    int line;
    int column;
};

struct AsmLexer {
    const char* source;
    std::size_t length;
    std::size_t position;
    int line;
    int column;
    AsmLexError* errors;
    std::size_t error_count;
    std::size_t error_capacity;
    AsmToken* tokens;
    std::size_t token_count;
    std::size_t token_capacity;
};

static_assert(sizeof(AsmToken) == 84);
static_assert(sizeof(AsmLexError) == 104);
static_assert(sizeof(AsmLexer) == 80);

extern "C" void lexer_init(AsmLexer*, const char*, std::size_t, AsmToken*, std::size_t, AsmLexError*, std::size_t);
extern "C" void lexer_next_token(AsmLexer*, AsmToken*);
extern "C" void lexer_tokenize_all(AsmLexer*);
extern "C" int lexer_has_error(AsmLexer*);
extern "C" std::size_t lexer_error_count(AsmLexer*);
extern "C" std::size_t lexer_token_count(AsmLexer*);
extern "C" int lexer_is_at_end(AsmLexer*);
extern "C" int lexer_peek(AsmLexer*);
extern "C" int lexer_peek_next(AsmLexer*);
extern "C" int lexer_advance(AsmLexer*);
extern "C" int lexer_match(AsmLexer*, int);
extern "C" void lexer_skip_whitespace_and_comments(AsmLexer*);
extern "C" void lexer_make_token(AsmLexer*, int, std::size_t, std::size_t, AsmToken*, int, int);
extern "C" void lexer_make_invalid_token(AsmLexer*, std::size_t, std::size_t, const char*, AsmToken*, int, int);
extern "C" int lexer_add_error(AsmLexer*, const char*);
extern "C" void lexer_scan_identifier_or_keyword(AsmLexer*, AsmToken*);
extern "C" void lexer_scan_number(AsmLexer*, AsmToken*);
extern "C" void lexer_scan_string(AsmLexer*, AsmToken*);
extern "C" int lexer_is_identifier_start(int);
extern "C" int lexer_is_identifier_part(int);
extern "C" int lexer_keyword_kind(const char*, std::size_t);
extern "C" const char* lexer_token_kind_name(int);

namespace {
constexpr int EndOfFile = 0;
constexpr int Invalid = 1;
constexpr int Identifier = 2;
constexpr int IntegerLiteral = 3;
constexpr int LongLiteral = 4;
constexpr int DoubleLiteral = 5;
constexpr int StringLiteral = 6;
constexpr int KeywordClass = 7;
constexpr int KeywordIf = 10;
constexpr int KeywordPrintln = 18;
constexpr int KeywordInteger = 19;
constexpr int KeywordMap = 30;
constexpr int KeywordTrue = 33;
constexpr int ArrowClassStart = 36;
constexpr int ArrowClassEnd = 37;
constexpr int ArrowMethodStart = 38;
constexpr int ArrowMethodEnd = 39;
constexpr int FatArrow = 40;
constexpr int Plus = 41;
constexpr int PlusPlus = 42;
constexpr int Minus = 43;
constexpr int MinusMinus = 44;
constexpr int EqualEqual = 49;
constexpr int AndAnd = 56;
constexpr int OrOr = 57;
constexpr int Question = 58;
constexpr int DoubleColon = 63;
constexpr int LeftParen = 64;

int failures = 0;

void expect_true(const std::string& name, bool value) {
    if (value) std::cout << "PASS " << name << '\n';
    else { std::cout << "FAIL " << name << '\n'; ++failures; }
}
void expect_false(const std::string& name, bool value) { expect_true(name, !value); }
void expect_int(const std::string& name, std::int64_t actual, std::int64_t expected) {
    if (actual == expected) std::cout << "PASS " << name << '\n';
    else { std::cout << "FAIL " << name << " expected " << expected << " got " << actual << '\n'; ++failures; }
}
void expect_text(const std::string& name, const char* actual, const char* expected) {
    if (actual && std::string(actual) == expected) std::cout << "PASS " << name << '\n';
    else { std::cout << "FAIL " << name << " expected [" << expected << "] got [" << (actual ? actual : "<null>") << "]\n"; ++failures; }
}

template <std::size_t T, std::size_t E>
AsmLexer fresh(const char* source, AsmToken (&tokens)[T], AsmLexError (&errors)[E]) {
    std::memset(tokens, 0, sizeof(tokens));
    std::memset(errors, 0, sizeof(errors));
    AsmLexer lexer{};
    lexer_init(&lexer, source, std::strlen(source), tokens, T, errors, E);
    return lexer;
}

void positive_scenarios() {
    AsmToken tokens[128]{};
    AsmLexError errors[16]{};
    AsmLexer lexer = fresh("class App { Integer a = 10; println(\"Hi\\n\"); }", tokens, errors);

    expect_int("peek", lexer_peek(&lexer), 'c');
    expect_int("peek next", lexer_peek_next(&lexer), 'l');
    expect_int("advance char", lexer_advance(&lexer), 'c');
    expect_int("column advance", lexer.column, 2);
    expect_true("match l", lexer_match(&lexer, 'l') != 0);
    expect_false("match x", lexer_match(&lexer, 'x') != 0);

    lexer = fresh("class App { Integer a = 10; println(\"Hi\\n\"); }", tokens, errors);
    lexer_tokenize_all(&lexer);
    expect_false("tokenize no errors", lexer_has_error(&lexer) != 0);
    expect_true("token count", lexer_token_count(&lexer) > 10);
    expect_int("keyword class", tokens[0].kind, KeywordClass);
    expect_text("keyword class lexeme", tokens[0].lexeme, "class");
    expect_int("identifier App", tokens[1].kind, Identifier);
    expect_text("identifier lexeme", tokens[1].lexeme, "App");
    expect_int("keyword Integer", tokens[3].kind, KeywordInteger);
    expect_int("integer literal", tokens[6].kind, IntegerLiteral);
    expect_text("integer lexeme", tokens[6].lexeme, "10");
    expect_int("keyword println", tokens[8].kind, KeywordPrintln);
    expect_int("string literal", tokens[10].kind, StringLiteral);
    expect_int("eof token", tokens[lexer.token_count - 1].kind, EndOfFile);

    lexer = fresh("  // skip\n  /* block */ Map true", tokens, errors);
    lexer_skip_whitespace_and_comments(&lexer);
    AsmToken one{};
    lexer_next_token(&lexer, &one);
    expect_int("skip comments Map", one.kind, KeywordMap);
    lexer_next_token(&lexer, &one);
    expect_int("keyword true", one.kind, KeywordTrue);

    lexer = fresh("123 456l 78D", tokens, errors);
    lexer_next_token(&lexer, &one);
    expect_int("scan int", one.kind, IntegerLiteral);
    lexer_next_token(&lexer, &one);
    expect_int("scan long", one.kind, LongLiteral);
    lexer_next_token(&lexer, &one);
    expect_int("scan double", one.kind, DoubleLiteral);

    lexer = fresh("++ + -- - -> --> <- <-- => == && || ? :: (", tokens, errors);
    lexer_tokenize_all(&lexer);
    int expected[]{PlusPlus, Plus, MinusMinus, Minus, ArrowClassStart, ArrowMethodStart, ArrowClassEnd, ArrowMethodEnd, FatArrow, EqualEqual, AndAnd, OrOr, Question, DoubleColon, LeftParen};
    for (std::size_t i = 0; i < sizeof(expected) / sizeof(expected[0]); ++i) {
        expect_int("operator token " + std::to_string(i), tokens[i].kind, expected[i]);
    }

    expect_true("identifier start underscore", lexer_is_identifier_start('_') != 0);
    expect_true("identifier part digit", lexer_is_identifier_part('7') != 0);
    expect_int("keyword kind if", lexer_keyword_kind("if", 2), KeywordIf);
    expect_int("keyword kind identifier", lexer_keyword_kind("iffy", 4), Identifier);
    expect_text("token kind name", lexer_token_kind_name(KeywordClass), "KeywordClass");

    lexer = fresh("manual", tokens, errors);
    AsmToken manual{};
    lexer.position = 6;
    lexer_make_token(&lexer, Identifier, 0, 6, &manual, 1, 1);
    expect_text("make token lexeme", manual.lexeme, "manual");
}

void negative_scenarios() {
    AsmToken tokens[16]{};
    AsmLexError errors[4]{};
    AsmLexer lexer = fresh("& | \"bad\\q\" \"open /* comment", tokens, errors);
    lexer_tokenize_all(&lexer);
    expect_true("lexer has errors", lexer_has_error(&lexer) != 0);
    expect_true("error count", lexer_error_count(&lexer) >= 3);
    expect_int("first invalid", tokens[0].kind, Invalid);
    expect_text("amp error", errors[0].message, "unexpected character '&'");

    lexer = fresh("/* unterminated", tokens, errors);
    lexer_tokenize_all(&lexer);
    expect_true("unterminated comment error", lexer_has_error(&lexer) != 0);
    expect_text("comment error text", errors[0].message, "unterminated block comment");

    lexer = fresh("\"unterminated\nnext", tokens, errors);
    lexer_next_token(&lexer, &tokens[0]);
    expect_int("unterminated string invalid", tokens[0].kind, Invalid);

    expect_false("identifier start digit", lexer_is_identifier_start('9') != 0);
    expect_false("identifier part dash", lexer_is_identifier_part('-') != 0);
    expect_text("unknown token name", lexer_token_kind_name(999), "Unknown");

    lexer = fresh("@", tokens, errors);
    lexer_next_token(&lexer, &tokens[0]);
    expect_int("unexpected invalid", tokens[0].kind, Invalid);
    expect_true("unexpected error", lexer_has_error(&lexer) != 0);

    lexer_init(nullptr, nullptr, 0, nullptr, 0, nullptr, 0);
    lexer_next_token(nullptr, nullptr);
    lexer_tokenize_all(nullptr);
    lexer_skip_whitespace_and_comments(nullptr);
    lexer_add_error(nullptr, nullptr);
    expect_true("null calls survive", true);
}
}

int main() {
    std::cout.setf(std::ios::unitbuf);
    positive_scenarios();
    negative_scenarios();
    if (failures == 0) {
        std::cout << "Lexer asm scenarios passed\n";
        return 0;
    }
    std::cout << "Lexer asm scenarios failed: " << failures << '\n';
    return 1;
}
