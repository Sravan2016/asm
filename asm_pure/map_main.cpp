#include <cstdint>

struct AsmString {
    char* ptr;
    unsigned long long len;
};

extern "C" {
void runtime_init();
void string_from_cstr(AsmString* dst, const char* src);
void string_free(AsmString* s);
long long string_equals(const AsmString* a, const AsmString* b);
unsigned char string_char_at(const AsmString* s, unsigned long long idx);
void print_cstr(const char* s);
void print_string(const AsmString* s);
void print_uint(unsigned long long v);

void* map_create(unsigned long long bucket_count,
                 unsigned long long (*hash_fn)(const void*),
                 long long (*equals_fn)(const void*, const void*));
unsigned long long map_put(void* map, const void* key, const void* value);
void* map_get(void* map, const void* key);
long long map_contains_key(void* map, const void* key);
unsigned long long map_remove(void* map, const void* key);
unsigned long long map_size(void* map);
unsigned long long map_is_empty(void* map);
void map_clear(void* map);
void map_free(void* map);
}

static unsigned long long hash_string(const void* key) {
    if (!key) {
        return 0;
    }
    const auto* s = static_cast<const AsmString*>(key);
    unsigned long long hash = 1469598103934665603ull;
    for (unsigned long long i = 0; i < s->len; ++i) {
        hash ^= string_char_at(s, i);
        hash *= 1099511628211ull;
    }
    return hash;
}

static long long equals_string(const void* a, const void* b) {
    if (a == b) {
        return 1;
    }
    if (!a || !b) {
        return 0;
    }
    return string_equals(static_cast<const AsmString*>(a),
                         static_cast<const AsmString*>(b));
}

static unsigned long long hash_int64(const void* key) {
    if (!key) {
        return 0;
    }
    unsigned long long v = *static_cast<const unsigned long long*>(key);
    v ^= v >> 33;
    v *= 0xff51afd7ed558ccdull;
    v ^= v >> 33;
    v *= 0xc4ceb9fe1a85ec53ull;
    v ^= v >> 33;
    return v;
}

static long long equals_int64(const void* a, const void* b) {
    if (a == b) {
        return 1;
    }
    if (!a || !b) {
        return 0;
    }
    return *static_cast<const unsigned long long*>(a) ==
           *static_cast<const unsigned long long*>(b);
}

static void print_bool(const char* label, long long value) {
    print_cstr(label);
    print_cstr(value ? "true\n" : "false\n");
}

static void scenario_positive() {
    print_cstr("Scenario: positive\n");

    AsmString key1{};
    AsmString key2{};
    AsmString key3{};
    AsmString value1{};
    AsmString value2{};
    AsmString value3{};

    string_from_cstr(&key1, "alpha");
    string_from_cstr(&key2, "bravo");
    string_from_cstr(&key3, "charlie");
    string_from_cstr(&value1, "one");
    string_from_cstr(&value2, "two");
    string_from_cstr(&value3, "three");

    void* map = map_create(16, hash_string, equals_string);
    map_put(map, &key1, &value1);
    map_put(map, &key2, &value2);
    map_put(map, &key3, &value3);

    print_cstr("size = ");
    print_uint(map_size(map));
    print_cstr("\n");

    const auto* v2 = static_cast<const AsmString*>(map_get(map, &key2));
    print_cstr("get bravo = ");
    if (v2) {
        print_string(v2);
    } else {
        print_cstr("(null)");
    }
    print_cstr("\n");

    AsmString value2b{};
    string_from_cstr(&value2b, "two-updated");
    const auto* old = reinterpret_cast<const AsmString*>(
        map_put(map, &key2, &value2b));
    print_cstr("put bravo old = ");
    if (old) {
        print_string(old);
    } else {
        print_cstr("(null)");
    }
    print_cstr("\n");

    const auto* removed = reinterpret_cast<const AsmString*>(
        map_remove(map, &key1));
    print_cstr("remove alpha = ");
    if (removed) {
        print_string(removed);
    } else {
        print_cstr("(null)");
    }
    print_cstr("\n");

    print_cstr("size after remove = ");
    print_uint(map_size(map));
    print_cstr("\n");

    map_clear(map);
    print_cstr("size after clear = ");
    print_uint(map_size(map));
    print_cstr("\n");
    print_bool("is_empty = ", map_is_empty(map));

    map_free(map);
    string_free(&key1);
    string_free(&key2);
    string_free(&key3);
    string_free(&value1);
    string_free(&value2);
    string_free(&value2b);
    string_free(&value3);
}

static void scenario_negative() {
    print_cstr("Scenario: negative\n");

    AsmString key1{};
    AsmString missing{};
    AsmString value1{};
    string_from_cstr(&key1, "alpha");
    string_from_cstr(&missing, "missing");
    string_from_cstr(&value1, "one");

    void* map = map_create(8, hash_string, equals_string);
    map_put(map, &key1, &value1);

    print_cstr("get missing = ");
    const auto* value = static_cast<const AsmString*>(map_get(map, &missing));
    if (value) {
        print_string(value);
    } else {
        print_cstr("(null)");
    }
    print_cstr("\n");

    print_bool("contains missing = ", map_contains_key(map, &missing));

    const auto* removed = reinterpret_cast<const AsmString*>(
        map_remove(map, &missing));
    print_cstr("remove missing = ");
    if (removed) {
        print_string(removed);
    } else {
        print_cstr("(null)");
    }
    print_cstr("\n");

    map_free(map);
    string_free(&key1);
    string_free(&missing);
    string_free(&value1);
}

static void scenario_int_key_string_value() {
    print_cstr("Scenario: int key, string value\n");

    unsigned long long k1 = 10;
    unsigned long long k2 = 20;
    unsigned long long k3 = 30;
    unsigned long long missing = 40;

    AsmString v1{};
    AsmString v2{};
    AsmString v3{};
    string_from_cstr(&v1, "ten");
    string_from_cstr(&v2, "twenty");
    string_from_cstr(&v3, "thirty");

    void* map = map_create(16, hash_int64, equals_int64);
    map_put(map, &k1, &v1);
    map_put(map, &k2, &v2);
    map_put(map, &k3, &v3);

    print_cstr("get 20 = ");
    const auto* got = static_cast<const AsmString*>(map_get(map, &k2));
    if (got) {
        print_string(got);
    } else {
        print_cstr("(null)");
    }
    print_cstr("\n");

    print_bool("contains 40 = ", map_contains_key(map, &missing));

    const auto* removed = reinterpret_cast<const AsmString*>(
        map_remove(map, &k1));
    print_cstr("remove 10 = ");
    if (removed) {
        print_string(removed);
    } else {
        print_cstr("(null)");
    }
    print_cstr("\n");

    map_free(map);
    string_free(&v1);
    string_free(&v2);
    string_free(&v3);
}

int main() {
    runtime_init();
    print_cstr("Map.bada scenarios:\n");
    scenario_positive();
    scenario_negative();
    scenario_int_key_string_value();
    return 0;
}
