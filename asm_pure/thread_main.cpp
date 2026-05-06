#include <iostream>

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
void string_free(AsmString* s);
void print_cstr(const char* s);
void print_string(const AsmString* s);
void print_uint(unsigned long long v);

void thread_init();
long long thread_run(const char* name, void (*cb)(const char* name, void* cache, void* user_data), void* user_data);
long long thread_join(long long handle);
void thread_cache_set_string(const char* name, const AsmString* value);
long long thread_cache_get_string(const char* name, AsmString* out);
void thread_cache_set_int(const char* name, int value);
long long thread_cache_get_int(const char* name, int* out);
}

struct ThreadCache {
    AsmString str;
    int value;
    int pad;
    long long long_value;
    double double_value;
    AsmArray* array_value;
};

static void worker_cb(const char* name, void* cache_ptr, void* user_data) {
    (void)cache_ptr;
    (void)user_data;
    AsmString msg{};
    string_from_cstr(&msg, "hello-from-thread");
    thread_cache_set_string(name, &msg);
    thread_cache_set_int(name, 42);
    string_free(&msg);
}

static const char* number_to_words_1_100(int n) {
    static const char* ones[] = {
        "", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine",
        "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen",
        "seventeen", "eighteen", "nineteen"
    };
    static const char* tens[] = {
        "", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"
    };
    static char buf[32];
    if (n <= 0 || n > 100) {
        return "";
    }
    if (n < 20) {
        return ones[n];
    }
    if (n == 100) {
        return "one hundred";
    }
    int t = n / 10;
    int o = n % 10;
    if (o == 0) {
        return tens[t];
    }
    int pos = 0;
    const char* tstr = tens[t];
    const char* ostr = ones[o];
    while (*tstr) {
        buf[pos++] = *tstr++;
    }
    buf[pos++] = ' ';
    while (*ostr) {
        buf[pos++] = *ostr++;
    }
    buf[pos] = 0;
    return buf;
}

static void worker_print_numbers(const char* name, void* cache_ptr, void* user_data) {
    (void)cache_ptr;
    (void)user_data;
    print_cstr("Thread ");
    print_cstr(name);
    print_cstr(": numbers 1..100\n");
    for (int i = 1; i <= 100; ++i) {
        print_uint(static_cast<unsigned long long>(i));
        print_cstr("\n");
    }
}

static void worker_print_words(const char* name, void* cache_ptr, void* user_data) {
    (void)cache_ptr;
    (void)user_data;
    print_cstr("Thread ");
    print_cstr(name);
    print_cstr(": words 1..100\n");
    for (int i = 1; i <= 100; ++i) {
        print_cstr(number_to_words_1_100(i));
        print_cstr("\n");
    }
}

int main() {
    runtime_init();
    thread_init();

    print_cstr("Thread scenarios:\n");

    print_cstr("Scenario: positive\n");
    long long h = thread_run("worker1", worker_cb, nullptr);
    print_cstr("thread_run = ");
    print_cstr(h ? "true\n" : "false\n");
    if (h) {
        thread_join(h);
        AsmString out{};
        print_cstr("cache string = ");
        if (thread_cache_get_string("worker1", &out)) {
            print_string(&out);
            print_cstr("\n");
            string_free(&out);
        } else {
            print_cstr("missing\n");
        }
        int v = 0;
        print_cstr("cache int = ");
        if (thread_cache_get_int("worker1", &v)) {
            print_uint(static_cast<unsigned long long>(v));
            print_cstr("\n");
        } else {
            print_cstr("missing\n");
        }
    }

    print_cstr("Scenario: negative\n");
    long long bad = thread_run(nullptr, worker_cb, nullptr);
    print_cstr("thread_run(null name) = ");
    print_cstr(bad ? "true\n" : "false\n");
    AsmString miss{};
    print_cstr("cache string missing = ");
    print_cstr(thread_cache_get_string("missing", &miss) ? "true\n" : "false\n");

    print_cstr("Scenario: two threads printing\n");
    long long h1 = thread_run("numbers", worker_print_numbers, nullptr);
    long long h2 = thread_run("words", worker_print_words, nullptr);
    if (h1) {
        thread_join(h1);
    }
    if (h2) {
        thread_join(h2);
    }
    return 0;
}
