#include <iostream>

struct FileDouble {
    void* handle;
    unsigned long long len;
};

extern "C" {
double double_add(double a, double b);
double double_sub(double a, double b);
double double_mul(double a, double b);
double double_div(double a, double b);
int double_eq(double a, double b);
int double_lt(double a, double b);
int double_gt(double a, double b);
double fromStringToDouble(const char* s);
double fromIntegerToDouble(int v);
double fromLongToDouble(long long v);
long long filedouble_create_auto(FileDouble* dst, double value);
double filedouble_get(FileDouble* dst);
long long filedouble_set(FileDouble* dst, double value);
void filedouble_free(FileDouble* dst);
}

static void scenario_positive() {
    std::cout << "Double positive scenarios\n";
    std::cout << "add(1.5,2.25) = " << double_add(1.5, 2.25) << "\n";
    std::cout << "sub(5.5,2.0) = " << double_sub(5.5, 2.0) << "\n";
    std::cout << "mul(3.0,4.0) = " << double_mul(3.0, 4.0) << "\n";
    std::cout << "div(7.5,2.5) = " << double_div(7.5, 2.5) << "\n";
    std::cout << "eq(3.0,3.0) = " << double_eq(3.0, 3.0) << "\n";
    std::cout << "lt(2.0,5.0) = " << double_lt(2.0, 5.0) << "\n";
    std::cout << "gt(5.0,2.0) = " << double_gt(5.0, 2.0) << "\n";
    std::cout << "fromStringToDouble(\"3.14\") = " << fromStringToDouble("3.14") << "\n";
    std::cout << "fromIntegerToDouble(42) = " << fromIntegerToDouble(42) << "\n";
    std::cout << "fromLongToDouble(123456) = " << fromLongToDouble(123456) << "\n";
}

static void scenario_negative() {
    std::cout << "Double negative scenarios\n";
    std::cout << "sub(2.0,5.5) = " << double_sub(2.0, 5.5) << "\n";
    std::cout << "div(7.0,-2.0) = " << double_div(7.0, -2.0) << "\n";
    std::cout << "eq(3.0,3.1) = " << double_eq(3.0, 3.1) << "\n";
    std::cout << "lt(9.0,3.0) = " << double_lt(9.0, 3.0) << "\n";
    std::cout << "gt(3.0,9.0) = " << double_gt(3.0, 9.0) << "\n";
    std::cout << "fromStringToDouble(\"-2.5\") = " << fromStringToDouble("-2.5") << "\n";
    std::cout << "fromIntegerToDouble(-7) = " << fromIntegerToDouble(-7) << "\n";
    std::cout << "fromLongToDouble(-9000) = " << fromLongToDouble(-9000) << "\n";
}

static void scenario_file_backed_double() {
    std::cout << "Double file-backed scenario\n";
    FileDouble a{};
    FileDouble b{};
    if (!filedouble_create_auto(&a, 3.5)) {
        std::cout << "create a = false\n";
        return;
    }
    if (!filedouble_create_auto(&b, -2.25)) {
        std::cout << "create b = false\n";
        filedouble_free(&a);
        return;
    }
    std::cout << "a = " << filedouble_get(&a) << "\n";
    std::cout << "b = " << filedouble_get(&b) << "\n";
    filedouble_set(&a, double_add(filedouble_get(&a), 0.75));
    std::cout << "a after add = " << filedouble_get(&a) << "\n";
    filedouble_free(&a);
    filedouble_free(&b);
}

int main() {
    scenario_positive();
    scenario_negative();
    scenario_file_backed_double();
    return 0;
}
