#include <iostream>

struct FileInt {
    void* handle;
    unsigned long long len;
};

extern "C" {
int int_add(int a, int b);
int int_sub(int a, int b);
int int_mul(int a, int b);
int int_div(int a, int b);
int int_mod(int a, int b);
int int_eq(int a, int b);
int int_lt(int a, int b);
int int_gt(int a, int b);
int fromStringToInteger(const char* s);
int fromLongToInteger(long long v);
int fromDoubleToInteger(double v);
long long fileint_create_auto(FileInt* dst, int value);
int fileint_get(FileInt* dst);
long long fileint_set(FileInt* dst, int value);
void fileint_free(FileInt* dst);
}

static void scenario_positive() {
    std::cout << "Integer positive scenarios\n";
    std::cout << "add(7,5) = " << int_add(7, 5) << "\n";
    std::cout << "sub(20,3) = " << int_sub(20, 3) << "\n";
    std::cout << "mul(6,4) = " << int_mul(6, 4) << "\n";
    std::cout << "div(21,3) = " << int_div(21, 3) << "\n";
    std::cout << "mod(22,5) = " << int_mod(22, 5) << "\n";
    std::cout << "eq(5,5) = " << int_eq(5, 5) << "\n";
    std::cout << "lt(3,9) = " << int_lt(3, 9) << "\n";
    std::cout << "gt(9,3) = " << int_gt(9, 3) << "\n";
    std::cout << "fromStringToInteger(\"123\") = " << fromStringToInteger("123") << "\n";
    std::cout << "fromLongToInteger(42) = " << fromLongToInteger(42) << "\n";
    std::cout << "fromDoubleToInteger(3.9) = " << fromDoubleToInteger(3.9) << "\n";
}

static void scenario_negative() {
    std::cout << "Integer negative scenarios\n";
    std::cout << "sub(5,9) = " << int_sub(5, 9) << "\n";
    std::cout << "div(7,-2) = " << int_div(7, -2) << "\n";
    std::cout << "mod(-7,3) = " << int_mod(-7, 3) << "\n";
    std::cout << "eq(5,6) = " << int_eq(5, 6) << "\n";
    std::cout << "lt(9,3) = " << int_lt(9, 3) << "\n";
    std::cout << "gt(3,9) = " << int_gt(3, 9) << "\n";
    std::cout << "fromStringToInteger(\"-7\") = " << fromStringToInteger("-7") << "\n";
    std::cout << "fromLongToInteger(-100) = " << fromLongToInteger(-100) << "\n";
    std::cout << "fromDoubleToInteger(-2.7) = " << fromDoubleToInteger(-2.7) << "\n";
}

static void scenario_file_backed_integer() {
    std::cout << "Integer file-backed scenario\n";
    FileInt a{};
    FileInt b{};
    if (!fileint_create_auto(&a, 123)) {
        std::cout << "create a = false\n";
        return;
    }
    if (!fileint_create_auto(&b, -456)) {
        std::cout << "create b = false\n";
        fileint_free(&a);
        return;
    }
    std::cout << "a = " << fileint_get(&a) << "\n";
    std::cout << "b = " << fileint_get(&b) << "\n";
    fileint_set(&a, int_add(fileint_get(&a), 7));
    std::cout << "a after add = " << fileint_get(&a) << "\n";
    fileint_free(&a);
    fileint_free(&b);
}

int main() {
    scenario_positive();
    scenario_negative();
    scenario_file_backed_integer();
    return 0;
}
