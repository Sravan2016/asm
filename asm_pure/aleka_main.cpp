#include <cstdint>
#include <cstdlib>
#include <cstring>

extern "C" {

void* aleka_create(unsigned long long field_count) {
    const std::size_t slots = static_cast<std::size_t>(field_count) + 1;
    auto* storage = static_cast<std::uint64_t*>(std::calloc(slots, sizeof(std::uint64_t)));
    if (!storage) {
        return nullptr;
    }
    storage[0] = field_count;
    return storage;
}

void aleka_set(void* object, unsigned long long index, std::uint64_t value) {
    if (!object) {
        return;
    }
    auto* storage = static_cast<std::uint64_t*>(object);
    const std::uint64_t field_count = storage[0];
    if (index >= field_count) {
        return;
    }
    storage[index + 1] = value;
}

std::uint64_t aleka_get(void* object, unsigned long long index) {
    if (!object) {
        return 0;
    }
    auto* storage = static_cast<std::uint64_t*>(object);
    const std::uint64_t field_count = storage[0];
    if (index >= field_count) {
        return 0;
    }
    return storage[index + 1];
}

void aleka_free(void* object) {
    std::free(object);
}

}
