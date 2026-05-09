#include <windows.h>

#include <cstdint>
#include <cstring>

extern "C" {

void* bada_mem_alloc(unsigned long long size);
long long bada_mem_free(void* ptr);
}

namespace {

constexpr char kHexDigits[] = "0123456789ABCDEF";

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

}
