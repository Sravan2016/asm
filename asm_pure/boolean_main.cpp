#include <iostream>

struct FileBool {
    void* handle;
    unsigned long long len;
};

extern "C" {
int bool_not(int a);
int bool_and(int a, int b);
int bool_or(int a, int b);
int bool_xor(int a, int b);
int bool_eq(int a, int b);
int fromStringToBoolean(const char* s);
int fromIntegerToBoolean(int v);
int fromLongToBoolean(long long v);
int fromDoubleToBoolean(double v);
long long filebool_create_auto(FileBool* dst, int value);
int filebool_get(FileBool* dst);
long long filebool_set(FileBool* dst, int value);
void filebool_free(FileBool* dst);
}

static void scenario_positive() {
    std::cout << "Boolean positive scenarios\n";
    std::cout << "not(0) = " << bool_not(0) << "\n";
    std::cout << "and(1,1) = " << bool_and(1, 1) << "\n";
    std::cout << "or(0,1) = " << bool_or(0, 1) << "\n";
    std::cout << "xor(1,0) = " << bool_xor(1, 0) << "\n";
    std::cout << "eq(1,1) = " << bool_eq(1, 1) << "\n";
    std::cout << "fromStringToBoolean(\"yes\") = " << fromStringToBoolean("yes") << "\n";
    std::cout << "fromIntegerToBoolean(1) = " << fromIntegerToBoolean(1) << "\n";
    std::cout << "fromLongToBoolean(10) = " << fromLongToBoolean(10) << "\n";
    std::cout << "fromDoubleToBoolean(0.1) = " << fromDoubleToBoolean(0.1) << "\n";
}

static void scenario_negative() {
    std::cout << "Boolean negative scenarios\n";
    std::cout << "not(1) = " << bool_not(1) << "\n";
    std::cout << "and(1,0) = " << bool_and(1, 0) << "\n";
    std::cout << "or(0,0) = " << bool_or(0, 0) << "\n";
    std::cout << "xor(1,1) = " << bool_xor(1, 1) << "\n";
    std::cout << "eq(1,0) = " << bool_eq(1, 0) << "\n";
    std::cout << "fromStringToBoolean(\"no\") = " << fromStringToBoolean("no") << "\n";
    std::cout << "fromIntegerToBoolean(0) = " << fromIntegerToBoolean(0) << "\n";
    std::cout << "fromLongToBoolean(-1) = " << fromLongToBoolean(-1) << "\n";
    std::cout << "fromDoubleToBoolean(0.0) = " << fromDoubleToBoolean(0.0) << "\n";
}

static void scenario_file_backed_boolean() {
    std::cout << "Boolean file-backed scenario\n";
    FileBool a{};
    FileBool b{};
    if (!filebool_create_auto(&a, 1)) {
        std::cout << "create a = false\n";
        return;
    }
    if (!filebool_create_auto(&b, 0)) {
        std::cout << "create b = false\n";
        filebool_free(&a);
        return;
    }
    std::cout << "a = " << filebool_get(&a) << "\n";
    std::cout << "b = " << filebool_get(&b) << "\n";
    filebool_set(&a, bool_not(filebool_get(&a)));
    std::cout << "a after not = " << filebool_get(&a) << "\n";
    filebool_free(&a);
    filebool_free(&b);
}

int main() {
    scenario_positive();
    scenario_negative();
    scenario_file_backed_boolean();
    return 0;
}
