#include <cstdint>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>

extern "C" {
void* aleka_create(unsigned long long field_count);
void aleka_set(void* object, unsigned long long index, std::uint64_t value);
std::uint64_t aleka_get(void* object, unsigned long long index);
void aleka_free(void* object);
void aleka_json_apply(void* object, const void* json, const char* key, unsigned long long descriptor);
void aleka_json_extract(const void* json, const char* key, void* out);

void string_from_cstr(void* dst, const char* src);
long long string_length(const void* s);
unsigned char string_char_at(const void* s, unsigned long long idx);
void string_free(void* s);
}

struct AsmString {
    void* handle = nullptr;
    unsigned long long len = 0;
};

namespace {

constexpr unsigned long long kInteger = 1;
constexpr unsigned long long kLong = 2;
constexpr unsigned long long kBoolean = 4;
constexpr unsigned long long kString = 5;

unsigned long long descriptor(unsigned long long field, unsigned long long type) {
    return (field << 8) | type;
}

AsmString make_string(const char* text) {
    AsmString value;
    string_from_cstr(&value, text);
    return value;
}

std::string to_std_string(const AsmString& value) {
    std::string out;
    const auto length = static_cast<unsigned long long>(string_length(&value));
    out.reserve(static_cast<std::size_t>(length));
    for (unsigned long long i = 0; i < length; ++i) {
        out.push_back(static_cast<char>(string_char_at(&value, i)));
    }
    return out;
}

bool expect_true(const char* name, bool condition) {
    std::cout << (condition ? "[PASS] " : "[FAIL] ") << name << '\n';
    return condition;
}

std::string aleka_path_for_object(const void* object) {
    static constexpr char hex[] = "0123456789ABCDEF";
    auto value = reinterpret_cast<std::uintptr_t>(object);
    std::string path = "aleka_";
    for (int i = 15; i >= 0; --i) {
        path.push_back(hex[(value >> (i * 4)) & 0x0f]);
    }
    path += ".bin";
    return path;
}

bool file_exists(const std::string& path) {
    std::ifstream input(path, std::ios::binary);
    return static_cast<bool>(input);
}

bool positive_storage_roundtrip() {
    void* object = aleka_create(3);
    const std::string path = aleka_path_for_object(object);
    bool ok = expect_true("create returns object", object != nullptr);
    ok &= expect_true("create writes aleka file", file_exists(path));
    aleka_set(object, 0, 42);
    aleka_set(object, 1, 9182592263ULL);
    aleka_set(object, 2, 1);
    ok &= expect_true("integer slot roundtrip", aleka_get(object, 0) == 42);
    ok &= expect_true("long slot roundtrip", aleka_get(object, 1) == 9182592263ULL);
    ok &= expect_true("boolean slot roundtrip", aleka_get(object, 2) == 1);
    aleka_free(object);
    ok &= expect_true("free deletes aleka file", !file_exists(path));
    return ok;
}

bool positive_json_apply() {
    void* object = aleka_create(4);
    AsmString json = make_string("{\"id\":7,\"phone\":9182592263,\"active\":true,\"name\":\"Sravan\"}");

    aleka_json_apply(object, &json, "id", descriptor(0, kInteger));
    aleka_json_apply(object, &json, "phone", descriptor(1, kLong));
    aleka_json_apply(object, &json, "active", descriptor(2, kBoolean));
    aleka_json_apply(object, &json, "name", descriptor(3, kString));

    auto* name = reinterpret_cast<AsmString*>(aleka_get(object, 3));
    bool ok = expect_true("json integer apply", aleka_get(object, 0) == 7);
    ok &= expect_true("json long apply", aleka_get(object, 1) == 9182592263ULL);
    ok &= expect_true("json boolean apply", aleka_get(object, 2) == 1);
    ok &= expect_true("json string apply", name && to_std_string(*name) == "Sravan");

    if (name) {
        string_free(name);
    }
    string_free(&json);
    aleka_free(object);
    return ok;
}

bool positive_nested_extract() {
    AsmString json = make_string("{\"user\":{\"id\":1,\"child\":{\"id\":2}},\"tail\":9}");
    AsmString out;
    aleka_json_extract(&json, "user", &out);
    const std::string extracted = to_std_string(out);
    bool ok = expect_true("nested json extract", extracted == "{\"id\":1,\"child\":{\"id\":2}}");
    string_free(&out);
    string_free(&json);
    return ok;
}

bool negative_scenarios() {
    void* object = aleka_create(1);
    AsmString json = make_string("{\"id\":5}");
    AsmString out;

    aleka_set(nullptr, 0, 10);
    aleka_set(object, 4, 99);
    aleka_json_apply(nullptr, &json, "id", descriptor(0, kInteger));
    aleka_json_apply(object, &json, "missing", descriptor(0, kInteger));
    aleka_json_extract(&json, "missing", &out);

    bool ok = expect_true("out-of-range get returns zero", aleka_get(object, 4) == 0);
    ok &= expect_true("missing json key leaves slot unchanged", aleka_get(object, 0) == 0);
    ok &= expect_true("missing extract leaves empty string", string_length(&out) == 0);

    string_free(&out);
    string_free(&json);
    aleka_free(object);
    aleka_free(nullptr);
    return ok;
}

}  // namespace

int main() {
    bool ok = true;
    ok &= positive_storage_roundtrip();
    ok &= positive_json_apply();
    ok &= positive_nested_extract();
    ok &= negative_scenarios();
    std::cout << (ok ? "Aleka scenarios passed\n" : "Aleka scenarios failed\n");
    return ok ? 0 : 1;
}
