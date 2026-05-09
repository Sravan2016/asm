#include <windows.h>

#include <cstddef>
#include <cctype>
#include <cstdint>
#include <cstring>
#include <cstdlib>

extern "C" {

void* bada_mem_alloc(unsigned long long size);
long long bada_mem_free(void* ptr);
void string_from_cstr(void* dst, const char* src);
long long string_length(const void* s);
unsigned char string_char_at(const void* s, unsigned long long idx);
}

namespace {

constexpr char kHexDigits[] = "0123456789ABCDEF";

struct AsmString {
    char* ptr;
    unsigned long long len;
};

enum class AlekaJsonType : std::uint64_t {
    Integer = 1,
    Long = 2,
    Double = 3,
    Boolean = 4,
    String = 5,
};

struct AlekaStorage {
    HANDLE handle;
    std::uint64_t field_count;
    char path[32];
};

void make_path(const void* object, char* out) {
    std::memcpy(out, "aleka_", 6);
    auto value = static_cast<std::uint64_t>(reinterpret_cast<std::uintptr_t>(object));
    for (int i = 0; i < 16; ++i) {
        const auto shift = static_cast<unsigned>((15 - i) * 4);
        out[6 + i] = kHexDigits[(value >> shift) & 0x0f];
    }
    std::memcpy(out + 22, ".bin", 5);
}

bool seek_to_slot(AlekaStorage* storage, std::uint64_t index) {
    LARGE_INTEGER offset;
    offset.QuadPart = static_cast<LONGLONG>(index * sizeof(std::uint64_t));
    return SetFilePointerEx(storage->handle, offset, nullptr, FILE_BEGIN) != 0;
}

std::size_t skip_ws(const char* text, std::size_t index, std::size_t length) {
    while (index < length && std::isspace(static_cast<unsigned char>(text[index])) != 0) {
        ++index;
    }
    return index;
}

std::size_t trim_right_index(const char* text, std::size_t start, std::size_t end) {
    while (end > start && std::isspace(static_cast<unsigned char>(text[end - 1])) != 0) {
        --end;
    }
    return end;
}

bool extract_json_value_span(const char* text,
                             const char* key,
                             const char** out_start,
                             std::size_t* out_length,
                             bool* quoted_value) {
    if (!text || !key || !out_start || !out_length || !quoted_value) {
        return false;
    }

    const std::size_t length = std::strlen(text);
    const std::size_t key_length = std::strlen(key);

    for (std::size_t i = 0; i < length; ++i) {
        if (text[i] != '"') continue;
        if (i + 1 + key_length >= length) continue;
        if (std::memcmp(text + i + 1, key, key_length) != 0) continue;
        if (text[i + 1 + key_length] != '"') continue;

        std::size_t cursor = i + key_length + 2;
        cursor = skip_ws(text, cursor, length);
        if (cursor >= length || text[cursor] != ':') continue;

        ++cursor;
        cursor = skip_ws(text, cursor, length);
        if (cursor >= length) return false;

        *quoted_value = text[cursor] == '"';
        if (*quoted_value) {
            ++cursor;
            const char* start = text + cursor;
            while (cursor < length) {
                if (text[cursor] == '\\' && cursor + 1 < length) {
                    cursor += 2;
                    continue;
                }
                if (text[cursor] == '"') {
                    *out_start = start;
                    *out_length = static_cast<std::size_t>((text + cursor) - start);
                    return true;
                }
                ++cursor;
            }
            return false;
        }

        const std::size_t start_index = cursor;
        while (cursor < length && text[cursor] != ',' && text[cursor] != '}') {
            ++cursor;
        }
        const std::size_t end_index = trim_right_index(text, start_index, cursor);
        *out_start = text + start_index;
        *out_length = end_index - start_index;
        return *out_length > 0;
    }
    return false;
}

std::uint64_t make_string_slot_value(const char* value_start, std::size_t value_length, bool quoted_value) {
    auto* stored = static_cast<AsmString*>(bada_mem_alloc(sizeof(AsmString)));
    if (!stored) {
        return 0;
    }

    auto* bytes = static_cast<char*>(bada_mem_alloc(value_length + 1));
    if (!bytes) {
        bada_mem_free(stored);
        return 0;
    }

    std::size_t out_index = 0;
    for (std::size_t i = 0; i < value_length; ++i) {
        char current = value_start[i];
        if (quoted_value && current == '\\' && i + 1 < value_length) {
            ++i;
            switch (value_start[i]) {
                case '"': current = '"'; break;
                case '\\': current = '\\'; break;
                case 'n': current = '\n'; break;
                case 't': current = '\t'; break;
                case 'r': current = '\r'; break;
                default: current = value_start[i]; break;
            }
        }
        bytes[out_index++] = current;
    }
    bytes[out_index] = '\0';

    string_from_cstr(stored, bytes);
    bada_mem_free(bytes);
    return static_cast<std::uint64_t>(reinterpret_cast<std::uintptr_t>(stored));
}

std::uint64_t parse_json_slot_value(const char* value_start,
                                    std::size_t value_length,
                                    AlekaJsonType type,
                                    bool quoted_value) {
    if (!value_start) return 0;

    if (type == AlekaJsonType::String) {
        return make_string_slot_value(value_start, value_length, quoted_value);
    }

    auto* buffer = static_cast<char*>(bada_mem_alloc(value_length + 1));
    if (!buffer) {
        return 0;
    }
    std::memcpy(buffer, value_start, value_length);
    buffer[value_length] = '\0';

    std::uint64_t result = 0;
    switch (type) {
        case AlekaJsonType::Integer:
            result = static_cast<std::uint64_t>(static_cast<std::int32_t>(std::strtol(buffer, nullptr, 10)));
            break;
        case AlekaJsonType::Long:
            result = static_cast<std::uint64_t>(std::strtoll(buffer, nullptr, 10));
            break;
        case AlekaJsonType::Double: {
            const double parsed = std::strtod(buffer, nullptr);
            std::uint64_t bits = 0;
            static_assert(sizeof(bits) == sizeof(parsed), "unexpected double size");
            std::memcpy(&bits, &parsed, sizeof(bits));
            result = bits;
            break;
        }
        case AlekaJsonType::Boolean: {
            for (std::size_t i = 0; i < value_length; ++i) {
                buffer[i] = static_cast<char>(std::tolower(static_cast<unsigned char>(buffer[i])));
            }
            result = (std::strcmp(buffer, "true") == 0 || std::strcmp(buffer, "yes") == 0 ||
                      std::strcmp(buffer, "1") == 0)
                ? 1u
                : 0u;
            break;
        }
        case AlekaJsonType::String:
            break;
    }
    bada_mem_free(buffer);
    return result;
}

}  // namespace

extern "C" {

void* aleka_create(unsigned long long field_count) {
    auto* storage = static_cast<AlekaStorage*>(bada_mem_alloc(sizeof(AlekaStorage)));
    if (!storage) {
        return nullptr;
    }

    storage->handle = INVALID_HANDLE_VALUE;
    storage->field_count = field_count;
    make_path(storage, storage->path);

    storage->handle = CreateFileA(
        storage->path,
        GENERIC_READ | GENERIC_WRITE,
        FILE_SHARE_READ,
        nullptr,
        CREATE_ALWAYS,
        FILE_ATTRIBUTE_NORMAL,
        nullptr
    );
    if (storage->handle == INVALID_HANDLE_VALUE) {
        bada_mem_free(storage);
        return nullptr;
    }

    return storage;
}

void aleka_set(void* object, unsigned long long index, std::uint64_t value) {
    if (!object) {
        return;
    }

    auto* storage = static_cast<AlekaStorage*>(object);
    if (index >= storage->field_count) {
        return;
    }
    if (!seek_to_slot(storage, index)) {
        return;
    }

    DWORD written = 0;
    WriteFile(storage->handle, &value, sizeof(value), &written, nullptr);
}

std::uint64_t aleka_get(void* object, unsigned long long index) {
    if (!object) {
        return 0;
    }

    auto* storage = static_cast<AlekaStorage*>(object);
    if (index >= storage->field_count) {
        return 0;
    }
    if (!seek_to_slot(storage, index)) {
        return 0;
    }

    std::uint64_t value = 0;
    DWORD read = 0;
    if (!ReadFile(storage->handle, &value, sizeof(value), &read, nullptr) || read != sizeof(value)) {
        return 0;
    }
    return value;
}

void aleka_free(void* object) {
    if (!object) {
        return;
    }

    auto* storage = static_cast<AlekaStorage*>(object);
    if (storage->handle != INVALID_HANDLE_VALUE) {
        CloseHandle(storage->handle);
        storage->handle = INVALID_HANDLE_VALUE;
    }
    DeleteFileA(storage->path);
    bada_mem_free(storage);
}

void aleka_json_apply(void* object,
                      const AsmString* json,
                      const char* key,
                      unsigned long long descriptor) {
    if (!object || !json || !key || descriptor == 0) {
        return;
    }

    const auto json_length = static_cast<std::size_t>(string_length(json));
    auto* json_buffer = static_cast<char*>(bada_mem_alloc(json_length + 1));
    if (!json_buffer) {
        return;
    }
    for (std::size_t i = 0; i < json_length; ++i) {
        json_buffer[i] = static_cast<char>(string_char_at(json, i));
    }
    json_buffer[json_length] = '\0';

    const char* value_start = nullptr;
    std::size_t value_length = 0;
    bool quoted_value = false;
    if (!extract_json_value_span(json_buffer, key, &value_start, &value_length, &quoted_value)) {
        bada_mem_free(json_buffer);
        return;
    }

    const std::uint64_t index = descriptor >> 8;
    const AlekaJsonType type = static_cast<AlekaJsonType>(descriptor & 0xffu);
    const std::ptrdiff_t offset = value_start - json_buffer;
    const std::uint64_t value = parse_json_slot_value(json_buffer + offset, value_length, type, quoted_value);
    bada_mem_free(json_buffer);
    aleka_set(object, index, value);
}

}
