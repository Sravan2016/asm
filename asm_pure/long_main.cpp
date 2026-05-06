#include <iostream>

struct FileLong {
    void* handle;
    unsigned long long len;
};

extern "C" {
long long long_add(long long a, long long b);
long long long_sub(long long a, long long b);
long long long_mul(long long a, long long b);
long long long_div(long long a, long long b);
long long long_mod(long long a, long long b);
int long_eq(long long a, long long b);
int long_lt(long long a, long long b);
int long_gt(long long a, long long b);
long long fromStringToLong(const char* s);
long long fromIntegerToLong(int v);
long long fromDoubleToLong(double v);
long long filelong_create_auto(FileLong* dst, long long value);
long long filelong_get(FileLong* dst);
long long filelong_set(FileLong* dst, long long value);
void filelong_free(FileLong* dst);
}

static void scenario_positive() {
    std::cout << "Long positive scenarios\n";
    std::cout << "add(10000000000,5) = " << long_add(10000000000LL, 5) << "\n";
    std::cout << "sub(50000000000,3) = " << long_sub(50000000000LL, 3) << "\n";
    std::cout << "mul(300000,4000) = " << long_mul(300000LL, 4000LL) << "\n";
    std::cout << "div(9000000000,3) = " << long_div(9000000000LL, 3) << "\n";
    std::cout << "mod(9000000007,5) = " << long_mod(9000000007LL, 5) << "\n";
    std::cout << "eq(7,7) = " << long_eq(7, 7) << "\n";
    std::cout << "lt(3,9) = " << long_lt(3, 9) << "\n";
    std::cout << "gt(9,3) = " << long_gt(9, 3) << "\n";
    std::cout << "fromStringToLong(\"123456\") = " << fromStringToLong("123456") << "\n";
    std::cout << "fromIntegerToLong(42) = " << fromIntegerToLong(42) << "\n";
    std::cout << "fromDoubleToLong(123.9) = " << fromDoubleToLong(123.9) << "\n";
}

static void scenario_negative() {
    std::cout << "Long negative scenarios\n";
    std::cout << "sub(5,9) = " << long_sub(5, 9) << "\n";
    std::cout << "div(7,-2) = " << long_div(7, -2) << "\n";
    std::cout << "mod(-7,3) = " << long_mod(-7, 3) << "\n";
    std::cout << "eq(5,6) = " << long_eq(5, 6) << "\n";
    std::cout << "lt(9,3) = " << long_lt(9, 3) << "\n";
    std::cout << "gt(3,9) = " << long_gt(3, 9) << "\n";
    std::cout << "fromStringToLong(\"-98765\") = " << fromStringToLong("-98765") << "\n";
    std::cout << "fromIntegerToLong(-42) = " << fromIntegerToLong(-42) << "\n";
    std::cout << "fromDoubleToLong(-123.7) = " << fromDoubleToLong(-123.7) << "\n";
}

static void scenario_file_backed_long() {
    std::cout << "Long file-backed scenario\n";
    FileLong a{};
    FileLong b{};
    if (!filelong_create_auto(&a, 10000000000LL)) {
        std::cout << "create a = false\n";
        return;
    }
    if (!filelong_create_auto(&b, -4567890123LL)) {
        std::cout << "create b = false\n";
        filelong_free(&a);
        return;
    }
    std::cout << "a = " << filelong_get(&a) << "\n";
    std::cout << "b = " << filelong_get(&b) << "\n";
    filelong_set(&a, long_add(filelong_get(&a), 7));
    std::cout << "a after add = " << filelong_get(&a) << "\n";
    filelong_free(&a);
    filelong_free(&b);
}

int main() {
    scenario_positive();
    scenario_negative();
    scenario_file_backed_long();
    return 0;
}
