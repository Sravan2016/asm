typedef struct AsmString {
    char* ptr;
    unsigned long long len;
} AsmString;

typedef struct FileString {
    void* handle;
    unsigned long long len;
} FileString;

#ifdef __cplusplus
extern "C" {
#endif
void runtime_init();
void string_from_cstr(AsmString* dst, const char* src);
void string_copy(AsmString* dst, const AsmString* src);
void string_free(AsmString* s);
long long string_length(const AsmString* s);
unsigned char string_char_at(const AsmString* s, unsigned long long idx);
void string_concat(AsmString* dst, const AsmString* a, const AsmString* b);
long long string_equals(const AsmString* a, const AsmString* b);
long long string_equals_icase(const AsmString* a, const AsmString* b);
long long string_contains_char(const AsmString* s, unsigned char c);
long long string_contains_sub(const AsmString* hay, const AsmString* needle);
void print_cstr(const char* s);
void print_string(const AsmString* s);
void print_uint(unsigned long long v);
void fromInteger(AsmString* dst, int v);
void fromLong(AsmString* dst, long long v);
void fromDouble(AsmString* dst, double v);
long long string_regex_digits_matches(AsmString* dst, const AsmString* input);
long long string_regex_digits_nonmatches(AsmString* dst, const AsmString* input);
long long string_between_symbol(AsmString* dst, const AsmString* input, const AsmString* symbol);
long long string_between_two_symbols(AsmString* dst, const AsmString* input, const AsmString* startSym, const AsmString* endSym);
long long string_split(AsmString* dst, const AsmString* input, const AsmString* delim);
long long string_before_token(AsmString* dst, const AsmString* input, const AsmString* token);
long long string_after_token(AsmString* dst, const AsmString* input, const AsmString* token);
long long string_trim(AsmString* dst, const AsmString* input);
long long string_trimall(AsmString* dst, const AsmString* input);
long long filestring_create_auto_from_cstr(FileString* dst, const char* src);
long long filestring_create_from_cstr(FileString* dst, const char* path, const char* src);
long long filestring_open(FileString* dst, const char* path);
unsigned long long filestring_length(const FileString* s);
unsigned char filestring_char_at(FileString* s, unsigned long long idx);
long long filestring_write_at(FileString* s, unsigned long long idx, const char* src, unsigned long long len);
long long filestring_replace_char_at(FileString* s, unsigned long long idx, unsigned char c);
long long filestring_replace_char(FileString* s, const char* target, const char* replacement);
void filestring_close(FileString* s);
void filestring_free(FileString* s);
#ifdef __cplusplus
}
#endif

static void scenario_create_string() {
    print_cstr("Scenario: create string\n");
    AsmString s = {0};
    string_from_cstr(&s, "alpha");
    print_cstr("value = ");
    print_string(&s);
    print_cstr("\n");
    string_free(&s);
}

static void scenario_sizeof_string() {
    print_cstr("Scenario: size of string\n");
    AsmString s = {0};
    string_from_cstr(&s, "alpha");
    print_cstr("length = ");
    print_uint((unsigned long long)string_length(&s));
    print_cstr("\n");
    string_free(&s);
}

static void scenario_concat_string() {
    print_cstr("Scenario: concat string\n");
    AsmString a = {0};
    AsmString b = {0};
    AsmString out = {0};
    string_from_cstr(&a, "alpha");
    string_from_cstr(&b, "bravo");
    string_concat(&out, &a, &b);
    print_cstr("concat = ");
    print_string(&out);
    print_cstr("\n");
    string_free(&a);
    string_free(&b);
    string_free(&out);
}

static void scenario_equals() {
    print_cstr("Scenario: equals\n");
    AsmString a = {0};
    AsmString b = {0};
    string_from_cstr(&a, "alpha");
    string_from_cstr(&b, "alpha");
    print_cstr("equals = ");
    print_cstr(string_equals(&a, &b) ? "true\n" : "false\n");
    string_free(&a);
    string_free(&b);
}

static void scenario_equals_icase() {
    print_cstr("Scenario: equals_icase\n");
    AsmString a = {0};
    AsmString b = {0};
    string_from_cstr(&a, "alpha");
    string_from_cstr(&b, "ALPHA");
    print_cstr("equals_icase = ");
    print_cstr(string_equals_icase(&a, &b) ? "true\n" : "false\n");
    string_free(&a);
    string_free(&b);
}

static void scenario_contains() {
    print_cstr("Scenario: contains_sub\n");
    AsmString a = {0};
    AsmString sub = {0};
    string_from_cstr(&a, "alpha");
    string_from_cstr(&sub, "ha");
    print_cstr("contains_sub = ");
    print_cstr(string_contains_sub(&a, &sub) ? "true\n" : "false\n");
    string_free(&a);
    string_free(&sub);
}

static void scenario_contains_char() {
    print_cstr("Scenario: contains_char\n");
    AsmString a = {0};
    string_from_cstr(&a, "alpha");
    print_cstr("contains_char = ");
    print_cstr(string_contains_char(&a, 'l') ? "true\n" : "false\n");
    string_free(&a);
}

static void scenario_from_number() {
    print_cstr("Scenario: from integer/long/double\n");
    AsmString s1 = {0};
    AsmString s2 = {0};
    AsmString s3 = {0};
    fromInteger(&s1, 123);
    fromLong(&s2, -4567);
    fromDouble(&s3, 3.14159);
    print_cstr("fromInteger = ");
    print_string(&s1);
    print_cstr("\n");
    print_cstr("fromLong = ");
    print_string(&s2);
    print_cstr("\n");
    print_cstr("fromDouble = ");
    print_string(&s3);
    print_cstr("\n");
    string_free(&s1);
    string_free(&s2);
    string_free(&s3);
}

static void scenario_file_backed_replace_char() {
    print_cstr("Scenario: file-backed replace char\n");
    FileString s = {0};
    if (!filestring_create_auto_from_cstr(&s, "String")) {
        print_cstr("create = false\n");
        return;
    }
    if (!filestring_replace_char(&s, "g", "gs")) {
        print_cstr("replace = false\n");
        filestring_free(&s);
        return;
    }

    print_cstr("value = ");
    for (unsigned long long i = 0; i < filestring_length(&s); ++i) {
        unsigned char ch = filestring_char_at(&s, i);
        char out[2] = {(char)ch, 0};
        print_cstr(out);
    }
    print_cstr("\n");
    filestring_free(&s);
}

static void scenario_regex_digits() {
    print_cstr("Scenario: regex digits\n");
    AsmString inputStr = {0};
    AsmString regexStr = {0};
    AsmString matches = {0};
    AsmString nonmatches = {0};

    string_from_cstr(&inputStr, "abc00123xyz456_01");
    string_from_cstr(&regexStr, "[0-9]+");

    print_cstr("input = ");
    print_string(&inputStr);
    print_cstr("\n");
    print_cstr("regex = ");
    print_string(&regexStr);
    print_cstr("\n");

    if (!string_regex_digits_matches(&matches, &inputStr)) {
        print_cstr("matches = false\n");
        string_free(&inputStr);
        string_free(&regexStr);
        return;
    }
    if (!string_regex_digits_nonmatches(&nonmatches, &inputStr)) {
        print_cstr("nonmatches = false\n");
        string_free(&matches);
        string_free(&inputStr);
        string_free(&regexStr);
        return;
    }

    print_cstr("matches = ");
    print_string(&matches);
    print_cstr("\n");
    print_cstr("nonmatches = ");
    print_string(&nonmatches);
    print_cstr("\n");

    string_free(&matches);
    string_free(&nonmatches);
    string_free(&inputStr);
    string_free(&regexStr);
}

static void scenario_between_symbol() {
    print_cstr("Scenario: between symbol\n");
    AsmString input = {0};
    AsmString symbol = {0};
    AsmString out = {0};

    string_from_cstr(&input, "String s = \"abcde\"");
    string_from_cstr(&symbol, "\"");

    if (!string_between_symbol(&out, &input, &symbol)) {
        print_cstr("between = false\n");
        string_free(&input);
        string_free(&symbol);
        return;
    }

    print_cstr("between = ");
    print_string(&out);
    print_cstr("\n");

    string_free(&out);
    string_free(&input);
    string_free(&symbol);

    AsmString input2 = {0};
    AsmString sym2 = {0};
    AsmString out2 = {0};
    string_from_cstr(&input2, "pre>>middle>>post");
    string_from_cstr(&sym2, ">>");
    if (!string_between_symbol(&out2, &input2, &sym2)) {
        print_cstr("between2 = false\n");
        string_free(&input2);
        string_free(&sym2);
        return;
    }
    print_cstr("between2 = ");
    print_string(&out2);
    print_cstr("\n");
    string_free(&out2);
    string_free(&input2);
    string_free(&sym2);
}

static void scenario_between_two_symbols() {
    print_cstr("Scenario: between two symbols\n");
    AsmString input = {0};
    AsmString start = {0};
    AsmString end = {0};
    AsmString out = {0};

    string_from_cstr(&input, "pre->middles<-post");
    string_from_cstr(&start, "->");
    string_from_cstr(&end, "<-");

    if (!string_between_two_symbols(&out, &input, &start, &end)) {
        print_cstr("between2 = false\n");
        string_free(&input);
        string_free(&start);
        string_free(&end);
        return;
    }

    print_cstr("between2 = ");
    print_string(&out);
    print_cstr("\n");

    string_free(&out);
    string_free(&input);
    string_free(&start);
    string_free(&end);
}

static void scenario_split() {
    print_cstr("Scenario: split\n");
    AsmString input = {0};
    AsmString delim = {0};
    AsmString out = {0};

    string_from_cstr(&input, "pre->middle<-post");
    string_from_cstr(&delim, "->");

    if (!string_split(&out, &input, &delim)) {
        print_cstr("split = false\n");
        string_free(&input);
        string_free(&delim);
        return;
    }

    print_cstr("split = ");
    print_string(&out);
    print_cstr("\n");

    string_free(&out);
    string_free(&input);
    string_free(&delim);
}

static void scenario_before_after_arrow() {
    print_cstr("Scenario: before/after =>\n");
    AsmString input = {0};
    AsmString token = {0};
    AsmString before = {0};
    AsmString after = {0};

    string_from_cstr(&input, "main{String[] args} => body");
    string_from_cstr(&token, "=>");
    print_cstr("string = ");
    print_string(&input);
    if (!string_before_token(&before, &input, &token)) {
        print_cstr("before = false\n");
        string_free(&input);
        string_free(&token);
        return;
    }
    if (!string_after_token(&after, &input, &token)) {
        print_cstr("after = false\n");
        string_free(&before);
        string_free(&input);
        string_free(&token);
        return;
    }

    print_cstr(" \n before = ");
    print_string(&before);
    print_cstr("\n");
    print_cstr("after = ");
    print_string(&after);
    print_cstr("\n");

    string_free(&before);
    string_free(&after);
    string_free(&input);
    string_free(&token);
}

static void scenario_trim() {
    print_cstr("Scenario: trim\n");
    AsmString input = {0};
    AsmString out = {0};
    string_from_cstr(&input, "   \t abc \r\n");
    print_string(&input);
    if (!string_trim(&out, &input)) {
        print_cstr("trim = false\n");
        string_free(&input);
        return;
    }
    print_cstr("trim = ");
    print_string(&out);
    print_cstr("\n");
    string_free(&out);
    string_free(&input);
}

static void scenario_trimall() {
    print_cstr("Scenario: trimall\n");
    AsmString input = {0};
    AsmString out = {0};
    string_from_cstr(&input, "Strings s =");
    if (!string_trimall(&out, &input)) {
        print_cstr("trimall = false\n");
        string_free(&input);
        return;
    }
    print_cstr("trimall = ");
    print_string(&out);
    print_cstr("\n");
    string_free(&out);
    string_free(&input);
}

int main() {
    runtime_init();
    scenario_create_string();
    scenario_sizeof_string();
    scenario_concat_string();
    scenario_equals();
    scenario_equals_icase();
    scenario_contains();
    scenario_contains_char();
    scenario_from_number();
    scenario_file_backed_replace_char();
    scenario_regex_digits();
    scenario_between_symbol();
    scenario_between_two_symbols();
    scenario_split();
    scenario_before_after_arrow();
    scenario_trim();
    scenario_trimall();
    return 0;
}
