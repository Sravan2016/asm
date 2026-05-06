#include <iostream>
#include <string>

struct AsmString {
    char* ptr;
    unsigned long long len;
};

struct AsmArray {
    void* data;
    unsigned long long len;
    unsigned long long cap;
    unsigned long long elem_size;
};

extern "C" {
void runtime_init();
void string_from_cstr(AsmString* dst, const char* src);
void string_copy(AsmString* dst, const AsmString* src);
void string_free(AsmString* s);
unsigned char string_char_at(const AsmString* s, unsigned long long idx);
long long filestring_replace_char_at(AsmString* s, unsigned long long idx, unsigned char c);
long long string_equals_icase(const AsmString* a, const AsmString* b);
long long string_equals(const AsmString* a, const AsmString* b);
long long string_contains_char(const AsmString* s, unsigned char c);
long long string_contains_sub(const AsmString* hay, const AsmString* needle);
void print_cstr(const char* s);
void print_string(const AsmString* s);
void print_uint(unsigned long long v);

void array_init(AsmArray* arr, unsigned long long cap, unsigned long long elem_size);
AsmArray* array_create(unsigned long long cap, unsigned long long elem_size);
long long array_add(AsmArray* arr, const void* elem_ptr);
long long array_find(AsmArray* arr, long long (*cb)(const void* elem_ptr));
unsigned long long array_size(const AsmArray* arr);
void* array_get(AsmArray* arr, unsigned long long idx);
long long array_remove(AsmArray* arr, unsigned long long idx);
AsmArray* array_filter(AsmArray* src, long long (*cb)(const void* elem_ptr));
void array_map(AsmArray* src, AsmArray* dst, long long (*cb)(const void* elem_ptr, void* out_elem_ptr));
void array_join(AsmArray* src, const AsmString* delim, AsmString* out);
void array_sort(AsmArray* arr, long long (*cmp)(const void* a, const void* b));
void array_free(AsmArray* arr);
}

static long long cb_find_alpha(const void* elem_ptr) {
    const auto* s = static_cast<const AsmString*>(elem_ptr);
    AsmString alpha{};
    string_from_cstr(&alpha, "alpha");
    long long ok = string_equals_icase(s, &alpha);
    string_free(&alpha);
    return ok;
}

static long long cb_filter_has_a(const void* elem_ptr) {
    const auto* s = static_cast<const AsmString*>(elem_ptr);
    extern AsmString g_filter_key;
    if (g_filter_key.len == 1 && g_filter_key.ptr) {
        return string_contains_char(s, string_char_at(&g_filter_key, 0));
    }
    return string_contains_sub(s, &g_filter_key);
}

static long long cb_map_upper(const void* elem_ptr, void* out_elem_ptr) {
    const auto* s = static_cast<const AsmString*>(elem_ptr);
    auto* out = static_cast<AsmString*>(out_elem_ptr);
    string_copy(out, s);
    if (out->ptr) {
        for (unsigned long long i = 0; i < out->len; ++i) {
            unsigned char ch = string_char_at(out, i);
            if (ch >= 'a' && ch <= 'z') {
                filestring_replace_char_at(out, i, static_cast<unsigned char>(ch - 'a' + 'A'));
            }
        }
    }
    return 1;
}

static long long cb_sort_lex(const void* a_ptr, const void* b_ptr) {
    const auto* a = static_cast<const AsmString*>(a_ptr);
    const auto* b = static_cast<const AsmString*>(b_ptr);
    if (string_equals(a, b)) {
        return 0;
    }
    unsigned long long min_len = a->len < b->len ? a->len : b->len;
    for (unsigned long long i = 0; i < min_len; ++i) {
        const unsigned char ca = string_char_at(a, i);
        const unsigned char cb = string_char_at(b, i);
        if (ca < cb) {
            return -1;
        }
        if (ca > cb) {
            return 1;
        }
    }
    return a->len < b->len ? -1 : 1;
}

struct ArrayScenarioContext {
    AsmArray arr{};
    AsmString s1{};
    AsmString s2{};
    AsmString s3{};
};

AsmString g_filter_key{};

static void scenario_create_array(ArrayScenarioContext& ctx) {
    print_cstr("Scenario: create array\n");
    array_init(&ctx.arr, 3, sizeof(AsmString));
}

static void scenario_add_to_array(ArrayScenarioContext& ctx) {
    print_cstr("Scenario: add to array\n");
    string_from_cstr(&ctx.s1, "alpha");
    string_from_cstr(&ctx.s2, "bravo");
    string_from_cstr(&ctx.s3, "charlie");
    array_add(&ctx.arr, &ctx.s1);
    array_add(&ctx.arr, &ctx.s2);
    array_add(&ctx.arr, &ctx.s3);
    print_cstr("size = ");
    print_uint(array_size(&ctx.arr));
    print_cstr("\n");
}

static void scenario_remove_from_array(ArrayScenarioContext& ctx) {
    print_cstr("Scenario: remove from array\n");
    print_cstr("remove[1] = ");
    print_cstr(array_remove(&ctx.arr, 1) ? "true\n" : "false\n");
    print_cstr("size = ");
    print_uint(array_size(&ctx.arr));
    print_cstr("\n");
}

static void scenario_size_of_array(const ArrayScenarioContext& ctx) {
    print_cstr("Scenario: size of array\n");
    print_cstr("size = ");
    print_uint(array_size(&ctx.arr));
    print_cstr("\n");
}

static void scenario_find_in_array(const ArrayScenarioContext& ctx) {
    print_cstr("Scenario: find in array\n");
    print_cstr("find alpha = ");
    print_cstr(array_find(const_cast<AsmArray*>(&ctx.arr), cb_find_alpha) ? "true\n" : "false\n");
}

static void scenario_filter_map_join_with(const ArrayScenarioContext& ctx, const char* filter_label, const char* filter_value) {
    print_cstr("Scenario: filter/map/join\n");

    print_cstr("total values = ");
    for (unsigned long long i = 0; i < array_size(&ctx.arr); ++i) {
        auto* item = static_cast<AsmString*>(array_get(const_cast<AsmArray*>(&ctx.arr), i));
        print_string(item);
        if (i + 1 < array_size(&ctx.arr)) {
            print_cstr(", ");
        }
    }
    print_cstr("\n");

    string_from_cstr(&g_filter_key, filter_value);
    print_cstr("filter = ");
    print_cstr(filter_label);
    print_cstr("\n");

    AsmArray* filtered = array_filter(const_cast<AsmArray*>(&ctx.arr), cb_filter_has_a);
    print_cstr("filtered size = ");
    print_uint(array_size(filtered));
    print_cstr("\n");
    print_cstr("filtered values = ");
    for (unsigned long long i = 0; i < array_size(filtered); ++i) {
        auto* item = static_cast<AsmString*>(array_get(filtered, i));
        print_string(item);
        if (i + 1 < array_size(filtered)) {
            print_cstr(", ");
        }
    }
    print_cstr("\n");

    AsmArray mapped{};
    array_init(&mapped, array_size(filtered), sizeof(AsmString));
    array_map(filtered, &mapped, cb_map_upper);
    print_cstr("mapped size = ");
    print_uint(array_size(&mapped));
    print_cstr("\n");
    print_cstr("mapped values = ");
    for (unsigned long long i = 0; i < array_size(&mapped); ++i) {
        auto* item = static_cast<AsmString*>(array_get(&mapped, i));
        print_string(item);
        if (i + 1 < array_size(&mapped)) {
            print_cstr(", ");
        }
    }
    print_cstr("\n");

    AsmString delim{};
    string_from_cstr(&delim, ",");
    AsmString joined{};
    array_join(&mapped, &delim, &joined);

    print_cstr("joined = ");
    print_string(&joined);
    print_cstr("\n");

    for (unsigned long long i = 0; i < array_size(&mapped); ++i) {
        auto* item = static_cast<AsmString*>(array_get(&mapped, i));
        string_free(item);
    }
    array_free(filtered);
    array_free(&mapped);
    string_free(&delim);
    string_free(&joined);
    string_free(&g_filter_key);
}

static void print_array_values(AsmArray* arr) {
    unsigned long long count = array_size(arr);
    for (unsigned long long i = 0; i < count; ++i) {
        auto* item = static_cast<AsmString*>(array_get(arr, i));
        print_string(item);
        if (i + 1 < count) {
            print_cstr(", ");
        }
    }
    print_cstr("\n");
}

static void scenario_sort_array() {
    print_cstr("Scenario: sort array\n");
    AsmArray* arr = array_create(4, sizeof(AsmString));

    AsmString s1{};
    AsmString s2{};
    AsmString s3{};
    AsmString s4{};
    string_from_cstr(&s1, "delta");
    string_from_cstr(&s2, "alpha");
    string_from_cstr(&s3, "charlie");
    string_from_cstr(&s4, "bravo");
    array_add(arr, &s1);
    array_add(arr, &s2);
    array_add(arr, &s3);
    array_add(arr, &s4);

    print_cstr("before sort = ");
    print_array_values(arr);
    array_sort(arr, cb_sort_lex);
    print_cstr("after sort = ");
    print_array_values(arr);

    array_free(arr);
    string_free(&s1);
    string_free(&s2);
    string_free(&s3);
    string_free(&s4);
}

int main() {
    runtime_init();
    print_cstr("Array scenarios:\n");
    ArrayScenarioContext ctx{};
    scenario_create_array(ctx);
    scenario_add_to_array(ctx);
    scenario_size_of_array(ctx);
    scenario_find_in_array(ctx);
    scenario_remove_from_array(ctx);
    scenario_filter_map_join_with(ctx, "alpha", "alpha");
    scenario_filter_map_join_with(ctx, "al", "al");
    scenario_sort_array();
    array_free(&ctx.arr);
    string_free(&ctx.s1);
    string_free(&ctx.s2);
    string_free(&ctx.s3);
    return 0;
}
