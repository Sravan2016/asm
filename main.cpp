#include <iostream>
#include <string>

#include "interpretor/interpreter.h"
#include "bada_runtime/executor.h"

int main(int argc, char** argv) {
    std::string path = "sample.bada";
    if (argc > 1 && argv[1]) {
        path = argv[1];
    }

    interpreter interp;
    if (!interp.parse_file(path)) {
        if (argc <= 1) {
            std::string fallback = "..\\sample.bada";
            if (!interp.parse_file(fallback)) {
                return 1;
            }
            path = fallback;
        } else {
            return 1;
        }
    }

    std::cout << "line->method:\n";
    for (const auto& kv : interp.line_to_method()) {
        std::cout << kv.first << " -> " << kv.second << "\n";
    }

    std::cout << "method->class:\n";
    for (const auto& kv : interp.method_to_class()) {
        std::cout << kv.first << " -> " << kv.second << "\n";
    }

    bada_executor exec(interp.line_to_method());
    if (!exec.load_file(path)) {
        return 1;
    }
    if (!exec.run_main()) {
        return 1;
    }

    return 0;
}
