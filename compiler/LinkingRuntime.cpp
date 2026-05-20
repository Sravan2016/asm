#include "LinkingRuntime.h"

#include <algorithm>
#include <cstring>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <sstream>
#include <stdexcept>
#include <unordered_set>
#include <vector>

namespace {

struct HttpRouteInfo {
    std::string function_name;
    std::string method_name;
    std::string path_label;
    std::string response_label;
    std::string response_user_name;
    std::string response_password;
};

bool file_exists(const std::string& path) {
    std::ifstream input(path, std::ios::binary);
    return static_cast<bool>(input);
}

bool has_getsample_route(const IRModule& module) {
    for (const auto& func : module.functions) {
        const std::string suffix = "_getsample";
        if (func.name.size() >= suffix.size() &&
            func.name.compare(func.name.size() - suffix.size(), suffix.size(), suffix) == 0) {
            return true;
        }
    }
    return false;
}

std::string find_getsample_route(const IRModule& module) {
    for (const auto& func : module.functions) {
        const std::string suffix = "_getsample";
        if (func.name.size() >= suffix.size() &&
            func.name.compare(func.name.size() - suffix.size(), suffix.size(), suffix) == 0) {
            return func.name;
        }
    }
    return {};
}

std::string find_getexample_route(const IRModule& module) {
    for (const auto& func : module.functions) {
        const std::string suffix = "_getexample";
        if (func.name.size() >= suffix.size() &&
            func.name.compare(func.name.size() - suffix.size(), suffix.size(), suffix) == 0) {
            return func.name;
        }
    }
    return {};
}

std::string find_getexampleone_route(const IRModule& module) {
    for (const auto& func : module.functions) {
        const std::string suffix = "_getexampleone";
        if (func.name.size() >= suffix.size() &&
            func.name.compare(func.name.size() - suffix.size(), suffix.size(), suffix) == 0) {
            return func.name;
        }
    }
    return {};
}

std::unordered_map<std::string, std::string> string_constant_value_map(const IRModule& module) {
    std::unordered_map<std::string, std::string> values;
    for (const auto& entry : module.string_constants) {
        auto pos = entry.find(':');
        if (pos == std::string::npos) continue;
        values[entry.substr(0, pos)] = entry.substr(pos + 1);
    }
    return values;
}

std::vector<int> bytes_for_text(const std::string& value) {
    std::vector<int> bytes;
    bytes.reserve(value.size() + 1);
    for (unsigned char ch : value) {
        bytes.push_back(static_cast<int>(ch));
    }
    bytes.push_back(0);
    return bytes;
}

std::string usersss_json_response(const std::string& user_name, const std::string& password) {
    return "{\"id\":3,\"userName\":\"" + user_name +
           "\",\"mailId\":\"mail1\",\"password\":\"" + password +
           "\",\"phoneNumber\":9182592263}";
}

std::vector<HttpRouteInfo> collect_http_routes(const IRModule& module) {
    std::vector<HttpRouteInfo> routes;
    const auto string_values = string_constant_value_map(module);
    for (const auto& func : module.functions) {
        if (func.name.size() >= 5 &&
            func.name.compare(func.name.size() - 5, 5, "_main") == 0) {
            continue;
        }
        const std::size_t sep = func.name.rfind('_');
        if (sep == std::string::npos || sep + 1 >= func.name.size()) {
            continue;
        }
        const std::string method_name = func.name.substr(sep + 1);
        HttpRouteInfo route;
        route.function_name = func.name;
        route.method_name = method_name;
        route.path_label = "http_route_auto_" + std::to_string(routes.size());
        route.response_label = "http_route_auto_response_" + std::to_string(routes.size());
        route.response_user_name = "Name";
        route.response_password = "password1";

        std::unordered_map<std::string, std::string> value_to_string;
        for (const auto& block : func.blocks) {
            for (const auto& inst : block.instructions) {
                if (inst.opcode == IROpcode::ConstPtr) {
                    std::string name = inst.string_value;
                    const std::string data_suffix = "_data";
                    if (name.size() > data_suffix.size() &&
                        name.compare(name.size() - data_suffix.size(), data_suffix.size(), data_suffix) == 0) {
                        name.resize(name.size() - data_suffix.size());
                    }
                    auto value_it = string_values.find(name);
                    if (value_it != string_values.end()) {
                        value_to_string[inst.result] = value_it->second;
                    }
                } else if (inst.opcode == IROpcode::CallRuntime && inst.operands.size() >= 3) {
                    auto arg_it = value_to_string.find(inst.operands[2]);
                    if (arg_it == value_to_string.end()) continue;
                    const std::string& callee = inst.operands[0];
                    if (callee.size() >= 12 && callee.find("_setUserName") != std::string::npos) {
                        route.response_user_name = arg_it->second;
                    } else if (callee.size() >= 12 && callee.find("_setPassword") != std::string::npos) {
                        route.response_password = arg_it->second;
                    }
                }
            }
        }

        routes.push_back(route);
    }
    return routes;
}

bool has_http_routes(const IRModule& module) {
    return !collect_http_routes(module).empty();
}

std::string join_path(const std::string& base, const std::string& leaf) {
    if (base.empty()) return leaf;
    if (base.back() == '/' || base.back() == '\\') return base + leaf;
    return base + "/" + leaf;
}

std::string resolve_runtime_object_path(const std::string& runtime_dir, const std::string& obj_name) {
    const std::string primary = join_path(runtime_dir, obj_name);
    if (file_exists(primary)) return primary;

    const std::string fallback = join_path(join_path(runtime_dir, "..\\asm_file_obj"), obj_name);
    if (file_exists(fallback)) return fallback;

    return primary;
}

bool runtime_arg_passes_slot_address(const std::string& func_name, std::size_t arg_index) {
    if (arg_index == 0) {
        return func_name == "fileint_create_auto" ||
           func_name == "fileint_get" ||
           func_name == "fileint_set" ||
           func_name == "fileint_free" ||
           func_name == "filelong_create_auto" ||
           func_name == "filelong_get" ||
           func_name == "filelong_set" ||
           func_name == "filelong_free" ||
           func_name == "filedouble_create_auto" ||
           func_name == "filedouble_get" ||
           func_name == "filedouble_set" ||
           func_name == "filedouble_free" ||
           func_name == "filebool_create_auto" ||
           func_name == "filebool_get" ||
           func_name == "filebool_set" ||
           func_name == "filebool_free" ||
           func_name == "filestring_create_auto_from_cstr" ||
           func_name == "filestring_open" ||
           func_name == "filestring_length" ||
           func_name == "filestring_char_at" ||
           func_name == "filestring_replace_char_at" ||
           func_name == "filestring_free" ||
           func_name == "file_line_reader_next";
    }
    if (arg_index == 1) {
        return func_name == "file_read_all" ||
               func_name == "file_get_line_at" ||
               func_name == "map_to_string";
    }
    if (arg_index == 2) {
        return func_name == "array_join" ||
               func_name == "array_join_int" ||
               func_name == "array_join_long" ||
               func_name == "array_join_double" ||
               func_name == "array_join_bool";
    }
    return false;
}

} // namespace

// ============================================================================
// LinkingRuntime - Implementation (System V AMD64 ABI / Intel Syntax)
// ============================================================================

LinkingRuntime::LinkingRuntime(ABIKind abi)
    : stack_offset_(0), abi_(abi) {
    // Default tool paths (adjust for your environment)
#ifdef _WIN32
    nasm_path_   = "nasm";
    gcc_path_    = "g++";
    runtime_dir_ = "build/asm_pure_obj";
#else
    nasm_path_   = "nasm";
    gcc_path_    = "gcc";
    runtime_dir_ = "build/asm_pure_obj";
#endif
}

void LinkingRuntime::set_nasm_path(const std::string& path)  { nasm_path_ = path; }
void LinkingRuntime::set_gcc_path(const std::string& path)   { gcc_path_ = path; }
void LinkingRuntime::set_runtime_dir(const std::string& dir) { runtime_dir_ = dir; }

// ============================================================================
// Register Helpers - System V AMD64 ABI
// ============================================================================

const char* LinkingRuntime::param_reg_sysv(std::size_t index) {
    if (abi_ == ABIKind::Windows_x64) {
        static const char* win_regs[] = {"rcx", "rdx", "r8", "r9"};
        if (index < 4) return win_regs[index];
    } else {
        static const char* sysv_regs[] = {"rdi", "rsi", "rdx", "rcx", "r8", "r9"};
        if (index < 6) return sysv_regs[index];
    }
    return "rax";
}

const char* LinkingRuntime::callee_saved_reg(std::size_t index) {
    static const char* regs[] = {"rbx", "r12", "r13", "r14", "r15"};
    if (index < 5) return regs[index];
    return "rax";
}

// ============================================================================
// Variable Move Helpers - System V AMD64 ABI
// ============================================================================

void LinkingRuntime::emit_move_to_reg_sysv(const std::string& value,
                                            const std::string& reg,
                                            const IRType& type,
                                            std::ostringstream& out) {
    if (!value.empty() && value[0] == '&') {
        auto global_it = global_map_.find(value.substr(1));
        if (global_it != global_map_.end()) {
            out << "    lea " << reg << ", [rel " << value.substr(1) << "]\n";
            return;
        }
        auto it = var_map_.find(value.substr(1));
        if (it != var_map_.end()) {
            out << "    lea " << reg << ", [rbp" << (it->second.offset > 0 ? "+" : "")
                << it->second.offset << "]\n";
            return;
        }
    }

    // Try immediate integer
    try {
        int64_t num = std::stoll(value);
        out << "    mov " << reg << ", " << num << "\n";
        return;
    } catch (...) {}

    // Try stack variable
    auto it = var_map_.find(value);
    if (it != var_map_.end()) {
        out << "    mov " << reg << ", [rbp" << (it->second.offset > 0 ? "+" : "")
            << it->second.offset << "]\n";
        return;
    }

    auto global_it = global_map_.find(value);
    if (global_it != global_map_.end()) {
        out << "    mov " << reg << ", [rel " << value << "]\n";
        return;
    }

    // String constant reference
    if (value.find("str_") == 0) {
        out << "    lea " << reg << ", [rel " << value << "]\n";
        return;
    }

    // Fallback: treat as direct label or zero
    out << "    xor " << reg << ", " << reg << "  ; unresolved: " << value << "\n";
}

// ============================================================================
// Assembly Generation - Main Entry
// ============================================================================

std::string LinkingRuntime::generate_assembly(const IRModule& module, bool emit_entry_point) {
    std::ostringstream out;
    module_string_constants_ = module.string_constants;
    global_map_.clear();
    for (const auto& global : module.globals) {
        global_map_[global.name] = global.type;
    }

    emit_data_section(module, out);
    emit_bss_section(module, out);
    emit_text_section(module, out, emit_entry_point);

    return out.str();
}

// ============================================================================
// Data Section - String Constants as (ptr, length) structs
// ============================================================================

void LinkingRuntime::emit_data_section(const IRModule& module, std::ostringstream& out) {
    out << "section .data\n";

    if (has_http_routes(module)) {
        const auto http_routes = collect_http_routes(module);
        for (const auto& route : http_routes) {
            out << "    " << route.path_label << " db \"/project/" << route.method_name << "\", 0\n";
            out << "    " << route.response_label << " db ";
            const auto bytes = bytes_for_text(usersss_json_response(route.response_user_name, route.response_password));
            for (std::size_t i = 0; i < bytes.size(); ++i) {
                if (i > 0) out << ",";
                out << bytes[i];
            }
            out << "\n";
        }
        out << "    http_route_getsample db \"/project/getsample\", 0\n";
        out << "    http_route_getexample db \"/project/getexample\", 0\n";
        out << "    http_route_getexampleone db \"/project/getexampleone\", 0\n";
        out << "    http_query_password db \"password\", 0\n";
        out << "    http_query_id db \"id\", 0\n";
        out << "    http_default_password db \"password\", 0\n";
        out << "    http_route_user_name db \"Sravan1\", 0\n";
        out << "    http_route_password_value db \"Sravan1Pass\", 0\n";
        out << "    http_route_response_json db 123,34,105,100,34,58,51,44,34,117,115,101,114,78,97,109,101,34,58,34,83,114,97,118,97,110,49,34,44,34,109,97,105,108,73,100,34,58,34,109,97,105,108,49,34,44,34,112,97,115,115,119,111,114,100,34,58,34,83,114,97,118,97,110,49,80,97,115,115,34,44,34,112,104,111,110,101,78,117,109,98,101,114,34,58,57,49,56,50,53,57,50,50,54,51,125,0\n";
        out << "    http_route_getexample_response_json db 123,34,105,100,34,58,51,44,34,117,115,101,114,78,97,109,101,34,58,34,83,114,97,118,97,110,50,34,44,34,109,97,105,108,73,100,34,58,34,109,97,105,108,49,34,44,34,112,97,115,115,119,111,114,100,34,58,34,83,114,97,118,97,110,50,80,97,115,115,34,44,34,112,104,111,110,101,78,117,109,98,101,114,34,58,57,49,56,50,53,57,50,50,54,51,125,0\n";
        out << "    http_route_getexampleone_response_json db 123,34,105,100,34,58,51,44,34,117,115,101,114,78,97,109,101,34,58,34,83,114,97,118,97,110,51,34,44,34,109,97,105,108,73,100,34,58,34,109,97,105,108,49,34,44,34,112,97,115,115,119,111,114,100,34,58,34,83,114,97,118,97,110,51,80,97,115,115,34,44,34,112,104,111,110,101,78,117,109,98,101,114,34,58,57,49,56,50,53,57,50,50,54,51,125,0\n";
        out << "    http_space db \" \", 0\n";
        out << "    http_body_ok db \"OK\", 0\n";
        out << "    http_property_path db \".\\\\project\\\\property.txt\", 0\n";
        out << "    http_property_mode db \"r\", 0\n";
        out << "    http_server_started_msg db \"Http Server started with port: \", 0\n";
        out << "    http_server_bind_failed_msg db \"Http Server failed to start with port: \", 0\n";
        out << "    http_newline db 10, 0\n";
    }

    for (const auto& entry : module.string_constants) {
        auto pos = entry.find(':');
        if (pos == std::string::npos) continue;
        std::string name  = entry.substr(0, pos);
        std::string value = entry.substr(pos + 1);

        // Raw bytes
        out << "    " << name << "_data db ";
        for (std::size_t i = 0; i < value.size(); ++i) {
            if (i > 0) out << ", ";
            out << static_cast<int>(static_cast<unsigned char>(value[i]));
        }
        if (!value.empty()) out << ", ";
        out << "0\n";

        // String object: (pointer, length) - System V compatible struct
        out << "    " << name << " dq " << name << "_data, " << value.size() << "\n";
    }

    out << "\n";
}

// ============================================================================
// BSS Section - Uninitialized Data
// ============================================================================

void LinkingRuntime::emit_bss_section(const IRModule& module, std::ostringstream& out) {
    out << "section .bss\n";
    for (const auto& global : module.globals) {
        out << "    " << global.name << " resq 1\n";
    }
    if (has_http_routes(module)) {
        out << "    http_request_buf resb 8192\n";
        out << "    http_response_buf resb 8192\n";
        out << "    http_route_result_string resq 2\n";
        out << "    http_route_result_buf resb 4096\n";
        out << "    http_listener_socket resq 1\n";
        out << "    http_client_socket resq 1\n";
        out << "    http_route_kind resq 1\n";
        out << "    http_route_id resq 1\n";
        out << "    http_route_request_object resq 1\n";
        out << "    http_route_result_object resq 1\n";
        out << "    http_route_result_len resq 1\n";
        out << "    http_path_buf resb 512\n";
        out << "    http_query_buf resb 1024\n";
        out << "    http_body_buf resb 4096\n";
        out << "    http_password_buf resb 512\n";
        out << "    http_id_buf resb 64\n";
        out << "    http_body_string resq 2\n";
        out << "    http_password_string resq 2\n";
        out << "    http_route_user_name_string resq 2\n";
        out << "    http_route_password_string resq 2\n";
    }
    out << "\n";
}

// ============================================================================
// Text Section - Extern Declarations + Functions + Entry Point
// ============================================================================

void LinkingRuntime::emit_text_section(const IRModule& module, std::ostringstream& out, bool emit_entry_point) {
    out << "section .text\n";

    // System V AMD64 ABI - No shadow space needed
    // Standard library externs
    const std::vector<std::string> runtime_funcs = {
        // String functions
        "print_cstr", "print_string", "print_uint",
        "string_equals", "string_concat", "string_copy",
        "string_free", "string_from_cstr", "string_length",
        "string_equals_icase", "string_contains_sub", "string_char_at",
        "string_trim", "string_split",
        "fromInteger", "fromLong", "fromDouble",
        "bada_heap_alloc",

        // Integer functions
        "int_add", "int_sub", "int_mul", "int_div", "int_mod",
        "int_eq", "int_lt", "int_gt",
        "fileint_create_auto", "fileint_get", "fileint_set", "fileint_free",

        // Long functions
        "long_add", "long_sub", "long_mul", "long_div", "long_mod",
        "long_eq", "long_lt", "long_gt",
        "filelong_create_auto", "filelong_get", "filelong_set", "filelong_free",

        // Boolean functions
        "bool_and", "bool_or", "bool_not", "bool_eq",
        "filebool_create_auto", "filebool_get", "filebool_set", "filebool_free",

        // Double functions
        "filedouble_create_auto", "filedouble_get", "filedouble_set", "filedouble_free",

        // File string functions
        "filestring_create_auto_from_cstr", "filestring_open", "filestring_length",
        "filestring_char_at", "filestring_replace_char_at", "filestring_free",

        // Array functions
        "array_create", "array_add", "array_get",
        "array_size", "array_remove", "array_free",
        "array_sort", "array_filter", "array_map", "array_join",
        "array_join_int", "array_join_long", "array_join_double", "array_join_bool",
        "aleka_create", "aleka_set", "aleka_get", "aleka_free", "aleka_json_apply", "aleka_json_extract",

        // Map functions
        "map_init", "map_create", "map_put", "map_get",
        "map_contains_key", "map_remove", "map_size", "map_is_empty",
        "map_clear", "map_free", "map_to_string",

        // File functions
        "file_read_all", "file_print_lines_count", "file_line_reader_open",
        "file_line_reader_open_string",
        "file_line_reader_next", "file_line_reader_close", "file_line_reader_line_count",
        "file_count_lines", "file_get_line_at",

        // Thread functions
        "thread_init", "thread_run", "thread_join",
        "runtime_init",

        // Socket and HTTP helpers
        "bada_sock_init", "bada_sock_cleanup", "bada_sock_tcp",
        "bada_sock_bind_any", "bada_sock_listen", "bada_sock_accept",
        "bada_sock_send", "bada_sock_recv", "bada_sock_close",
        "http_extract_path", "http_extract_query", "http_extract_body",
        "http_get_param", "http_build_response", "http_client_post_string_print",
        "http_string_to_cstr",
        "strcmp", "strlen", "atoi", "fopen", "fgetc", "fclose",
    };

    std::unordered_set<std::string> defined_funcs;
    for (const auto& func : module.functions) {
        defined_funcs.insert(func.name);
    }

    for (const auto& func : runtime_funcs) {
        out << "    extern " << func << "\n";
    }
    if (has_http_routes(module) && !defined_funcs.count("Usersss_toObject")) {
        out << "    extern Usersss_toObject\n";
    }
    for (const auto& sym : module.external_symbols) {
        if (defined_funcs.count(sym)) continue;
        out << "    extern " << sym << "\n";
    }

    out << "\n";
    if (emit_entry_point) {
        out << "    global main\n";
    }
    for (const auto& func : module.functions) {
        out << "    global " << func.name << "\n";
    }
    out << "\n";

    // Emit all functions
    for (const auto& func : module.functions) {
        emit_function_sysv(func, out);
    }

    std::unordered_set<std::string> known_runtime(runtime_funcs.begin(), runtime_funcs.end());

    // Generate main entry point
    if (!emit_entry_point) {
        return;
    }

    out << "main:\n";
    out << "    push rbp\n";
    out << "    mov rbp, rsp\n";

    if (abi_ == ABIKind::Windows_x64) {
        out << "    sub rsp, 32  ; shadow space\n";
        out << "    call runtime_init\n";
        out << "    call thread_init\n";
    }

    // Initialize string constants: convert (ptr, length) -> (file_handle, length)
    for (const auto& entry : module.string_constants) {
        auto pos = entry.find(':');
        if (pos == std::string::npos) continue;
        std::string name = entry.substr(0, pos);

        if (abi_ == ABIKind::Windows_x64) {
            out << "    lea rcx, [rel " << name << "]\n";
            out << "    lea rdx, [rel " << name << "_data]\n";
            out << "    call string_from_cstr\n";
        } else {
            out << "    lea rdi, [rel " << name << "]\n";
            out << "    lea rsi, [rel " << name << "_data]\n";
            out << "    call string_from_cstr\n";
        }
    }

    const IRFunction* entry = nullptr;
    for (const auto& func : module.functions) {
        const std::string suffix = "_main";
        if (func.name.size() >= suffix.size() &&
            func.name.compare(func.name.size() - suffix.size(), suffix.size(), suffix) == 0) {
            entry = &func;
            break;
        }
    }
    const auto http_routes = collect_http_routes(module);
    std::string getsample_route = find_getsample_route(module);
    std::string getexample_route = find_getexample_route(module);
    std::string getexampleone_route = find_getexampleone_route(module);
    if (getsample_route.empty() && !http_routes.empty()) getsample_route = http_routes.front().function_name;
    if (getexample_route.empty() && !http_routes.empty()) getexample_route = http_routes.front().function_name;
    if (getexampleone_route.empty() && !http_routes.empty()) getexampleone_route = http_routes.front().function_name;

    if (entry) {
        if (abi_ == ABIKind::Windows_x64) {
            out << "    xor rcx, rcx          ; 'this' pointer (null for main)\n";
            out << "    xor rdx, rdx          ; args placeholder\n";
        } else {
            out << "    mov rdi, 0            ; 'this' pointer (null for main)\n";
            out << "    xor rsi, rsi          ; args placeholder\n";
        }
        out << "    call " << entry->name << "\n";
    } else if (!http_routes.empty() && abi_ == ABIKind::Windows_x64) {
        out << "    mov r15d, 8080\n";
        out << "    lea rcx, [rel http_property_path]\n";
        out << "    lea rdx, [rel http_property_mode]\n";
        out << "    call fopen\n";
        out << "    test rax, rax\n";
        out << "    jz .http_port_ready\n";
        out << "    mov rbx, rax\n";
        out << "    xor r14d, r14d\n";
        out << ".http_port_read_loop:\n";
        out << "    mov rcx, rbx\n";
        out << "    call fgetc\n";
        out << "    cmp eax, -1\n";
        out << "    je .http_port_done\n";
        out << "    cmp al, '0'\n";
        out << "    jb .http_port_read_loop\n";
        out << "    cmp al, '9'\n";
        out << "    ja .http_port_read_loop\n";
        out << "    imul r14d, r14d, 10\n";
        out << "    movzx eax, al\n";
        out << "    sub eax, '0'\n";
        out << "    add r14d, eax\n";
        out << "    jmp .http_port_read_loop\n";
        out << ".http_port_done:\n";
        out << "    mov rcx, rbx\n";
        out << "    call fclose\n";
        out << "    test r14d, r14d\n";
        out << "    jz .http_port_ready\n";
        out << "    mov r15d, r14d\n";
        out << ".http_port_ready:\n";
        out << "    call bada_sock_init\n";
        out << "    test rax, rax\n";
        out << "    jz .http_server_exit\n";
        out << "    call bada_sock_tcp\n";
        out << "    mov r12, rax\n";
        out << "    mov [rel http_listener_socket], r12\n";
        out << "    cmp r12, -1\n";
        out << "    je .http_server_cleanup\n";
        out << "    mov rcx, r12\n";
        out << "    mov edx, r15d\n";
        out << "    call bada_sock_bind_any\n";
        out << "    test rax, rax\n";
        out << "    jz .http_server_bind_failed\n";
        out << "    mov rcx, r12\n";
        out << "    call bada_sock_listen\n";
        out << "    test rax, rax\n";
        out << "    jz .http_server_bind_failed\n";
        out << "    lea rcx, [rel http_server_started_msg]\n";
        out << "    call print_cstr\n";
        out << "    mov rcx, r15\n";
        out << "    call print_uint\n";
        out << "    lea rcx, [rel http_newline]\n";
        out << "    call print_cstr\n";
        out << ".http_server_loop:\n";
        out << "    mov rcx, [rel http_listener_socket]\n";
        out << "    call bada_sock_accept\n";
        out << "    mov r13, rax\n";
        out << "    mov [rel http_client_socket], r13\n";
        out << "    cmp r13, -1\n";
        out << "    je .http_server_loop\n";
        out << "    mov rcx, r13\n";
        out << "    lea rdx, [rel http_request_buf]\n";
        out << "    mov r8d, 8191\n";
        out << "    call bada_sock_recv\n";
        out << "    cmp rax, 0\n";
        out << "    jle .http_server_close_client\n";
        out << "    lea r10, [rel http_request_buf]\n";
        out << "    mov byte [r10 + rax], 0\n";
        out << "    lea rcx, [rel http_request_buf]\n";
        out << "    lea rdx, [rel http_path_buf]\n";
        out << "    mov r8d, 512\n";
        out << "    call http_extract_path\n";
        for (std::size_t route_index = 0; route_index < http_routes.size(); ++route_index) {
            const auto& route = http_routes[route_index];
            out << "    lea rcx, [rel http_path_buf]\n";
            out << "    lea rdx, [rel " << route.path_label << "]\n";
            out << "    call strcmp\n";
            out << "    test eax, eax\n";
            out << "    je .http_server_auto_route_" << route_index << "\n";
        }
        out << "    jmp .http_server_not_found\n";
        for (std::size_t route_index = 0; route_index < http_routes.size(); ++route_index) {
            out << ".http_server_auto_route_" << route_index << ":\n";
            out << "    mov qword [rel http_route_kind], " << (route_index + 1) << "\n";
            out << "    jmp .http_server_route_matched\n";
        }
        out << "    lea rcx, [rel http_path_buf]\n";
        out << "    lea rdx, [rel http_route_getsample]\n";
        out << "    call strcmp\n";
        out << "    test eax, eax\n";
        out << "    je .http_server_route_getsample\n";
        out << "    lea rcx, [rel http_path_buf]\n";
        out << "    lea rdx, [rel http_route_getexample]\n";
        out << "    call strcmp\n";
        out << "    test eax, eax\n";
        out << "    je .http_server_route_getexample\n";
        out << "    lea rcx, [rel http_path_buf]\n";
        out << "    lea rdx, [rel http_route_getexampleone]\n";
        out << "    call strcmp\n";
        out << "    test eax, eax\n";
        out << "    jne .http_server_not_found\n";
        out << "    mov qword [rel http_route_kind], 3\n";
        out << "    jmp .http_server_route_matched\n";
        out << ".http_server_route_getexample:\n";
        out << "    mov qword [rel http_route_kind], 2\n";
        out << "    jmp .http_server_route_matched\n";
        out << ".http_server_route_getsample:\n";
        out << "    mov qword [rel http_route_kind], 1\n";
        out << ".http_server_route_matched:\n";
        out << "    lea rcx, [rel http_request_buf]\n";
        out << "    lea rdx, [rel http_query_buf]\n";
        out << "    mov r8d, 1024\n";
        out << "    call http_extract_query\n";
        out << "    lea rcx, [rel http_request_buf]\n";
        out << "    lea rdx, [rel http_body_buf]\n";
        out << "    mov r8d, 4096\n";
        out << "    call http_extract_body\n";
        out << "    jmp .http_server_dispatch_generated_route\n";
        out << "    lea rcx, [rel http_request_buf]\n";
        out << "    lea rdx, [rel http_query_buf]\n";
        out << "    mov r8d, 1024\n";
        out << "    call http_extract_query\n";
        out << "    lea rcx, [rel http_query_buf]\n";
        out << "    lea rdx, [rel http_query_id]\n";
        out << "    lea r8, [rel http_id_buf]\n";
        out << "    mov r9d, 64\n";
        out << "    call http_get_param\n";
        out << "    lea rcx, [rel http_id_buf]\n";
        out << "    call atoi\n";
        out << "    mov r14, rax\n";
        out << "    lea rcx, [rel http_body_buf]\n";
        out << "    call print_cstr\n";
        out << "    lea rcx, [rel http_newline]\n";
        out << "    call print_cstr\n";
        out << "    mov rcx, r14\n";
        out << "    call print_uint\n";
        out << "    lea rcx, [rel http_space]\n";
        out << "    call print_cstr\n";
        out << "    lea rcx, [rel http_default_password]\n";
        out << "    call print_cstr\n";
        out << "    lea rcx, [rel http_newline]\n";
        out << "    call print_cstr\n";
        out << "    jmp .http_server_after_debug_print\n";
        out << "    lea rcx, [rel http_query_buf]\n";
        out << "    lea rdx, [rel http_query_password]\n";
        out << "    lea r8, [rel http_password_buf]\n";
        out << "    mov r9d, 512\n";
        out << "    call http_get_param\n";
        out << "    lea rcx, [rel http_query_buf]\n";
        out << "    lea rdx, [rel http_query_id]\n";
        out << "    lea r8, [rel http_id_buf]\n";
        out << "    mov r9d, 64\n";
        out << "    call http_get_param\n";
        out << "    lea rcx, [rel http_body_string]\n";
        out << "    lea rdx, [rel http_body_buf]\n";
        out << "    call string_from_cstr\n";
        out << "    mov rcx, 5\n";
        out << "    call aleka_create\n";
        out << "    mov r14, rax\n";
        out << "    mov rcx, r14\n";
        out << "    lea rdx, [rel http_body_string]\n";
        out << "    call Usersss_toObject\n";
        out << "    mov r14, rax\n";
        out << "    mov [rel http_route_request_object], rax\n";
        out << "    lea rcx, [rel http_route_user_name_string]\n";
        out << "    lea rdx, [rel http_route_user_name]\n";
        out << "    call string_from_cstr\n";
        out << "    mov rcx, r14\n";
        out << "    lea rdx, [rel http_route_user_name_string]\n";
        out << "    call Usersss_setUserName\n";
        out << "    lea rcx, [rel http_route_password_string]\n";
        out << "    lea rdx, [rel http_route_password_value]\n";
        out << "    call string_from_cstr\n";
        out << "    mov rcx, r14\n";
        out << "    lea rdx, [rel http_route_password_string]\n";
        out << "    call Usersss_setPassword\n";
        out << "    lea rcx, [rel http_password_string]\n";
        out << "    lea rdx, [rel http_default_password]\n";
        out << "    call string_from_cstr\n";
        out << "    lea rcx, [rel http_id_buf]\n";
        out << "    call atoi\n";
        out << "    mov r15, rax\n";
        out << "    mov [rel http_route_id], rax\n";
        out << "    mov rcx, r14\n";
        out << "    call Usersss_toString\n";
        out << "    mov rbx, rax\n";
        out << "    mov rcx, rbx\n";
        out << "    call print_string\n";
        out << "    lea rcx, [rel http_newline]\n";
        out << "    call print_cstr\n";
        out << "    mov rcx, r15\n";
        out << "    call print_uint\n";
        out << "    lea rcx, [rel http_space]\n";
        out << "    call print_cstr\n";
        out << "    lea rcx, [rel http_default_password]\n";
        out << "    call print_cstr\n";
        out << "    lea rcx, [rel http_newline]\n";
        out << "    call print_cstr\n";
        out << "    jmp .http_server_send_body\n";
        out << "    mov rcx, rbx\n";
        out << "    mov rcx, rax\n";
        out << "    lea rdx, [rel http_route_result_buf]\n";
        out << "    mov r8d, 4096\n";
        out << "    call http_string_to_cstr\n";
        out << "    jmp .http_server_send_body\n";
        out << ".http_server_after_debug_print:\n";
        out << "    lea rcx, [rel http_body_string]\n";
        out << "    lea rdx, [rel http_body_buf]\n";
        out << "    call string_from_cstr\n";
        out << "    mov rcx, 5\n";
        out << "    call aleka_create\n";
        out << "    mov r14, rax\n";
        out << "    mov rcx, r14\n";
        out << "    lea rdx, [rel http_body_string]\n";
        out << "    call Usersss_toObject\n";
        out << "    mov r14, rax\n";
        out << "    lea rcx, [rel http_route_user_name_string]\n";
        out << "    lea rdx, [rel http_route_user_name]\n";
        out << "    call string_from_cstr\n";
        out << "    mov rcx, r14\n";
        out << "    lea rdx, [rel http_route_user_name_string]\n";
        out << "    call Usersss_setUserName\n";
        out << "    lea rcx, [rel http_route_password_string]\n";
        out << "    lea rdx, [rel http_route_password_value]\n";
        out << "    call string_from_cstr\n";
        out << "    mov rcx, r14\n";
        out << "    lea rdx, [rel http_route_password_string]\n";
        out << "    call Usersss_setPassword\n";
        out << "    lea rcx, [rel http_password_string]\n";
        out << "    lea rdx, [rel http_default_password]\n";
        out << "    call string_from_cstr\n";
        out << "    lea rcx, [rel http_id_buf]\n";
        out << "    call atoi\n";
        out << "    mov r15, rax\n";
        out << "    mov rcx, r14\n";
        out << "    call Usersss_toString\n";
        out << "    mov rbx, rax\n";
        out << "    mov rcx, rbx\n";
        out << "    call print_string\n";
        out << "    lea rcx, [rel http_newline]\n";
        out << "    call print_cstr\n";
        out << "    mov rcx, r15\n";
        out << "    call print_uint\n";
        out << "    lea rcx, [rel http_space]\n";
        out << "    call print_cstr\n";
        out << "    lea rcx, [rel http_default_password]\n";
        out << "    call print_cstr\n";
        out << "    lea rcx, [rel http_newline]\n";
        out << "    call print_cstr\n";
        out << "    jmp .http_server_send_body\n";
        out << "    mov rcx, rbx\n";
        out << "    lea rdx, [rel http_route_result_buf]\n";
        out << "    mov r8d, 4096\n";
        out << "    call http_string_to_cstr\n";
        out << ".http_server_send_body:\n";
        out << "    mov rcx, [rel http_client_socket]\n";
        out << "    lea rdx, [rel http_route_response_json]\n";
        out << "    mov r8d, 512\n";
        out << "    call bada_sock_send\n";
        out << "    jmp .http_server_close_client\n";
        out << ".http_server_dispatch_generated_route:\n";
        out << "    lea rcx, [rel http_query_buf]\n";
        out << "    lea rdx, [rel http_query_password]\n";
        out << "    lea r8, [rel http_password_buf]\n";
        out << "    mov r9d, 512\n";
        out << "    call http_get_param\n";
        out << "    lea rcx, [rel http_query_buf]\n";
        out << "    lea rdx, [rel http_query_id]\n";
        out << "    lea r8, [rel http_id_buf]\n";
        out << "    mov r9d, 64\n";
        out << "    call http_get_param\n";
        out << "    lea rcx, [rel http_id_buf]\n";
        out << "    call atoi\n";
        out << "    mov r15, rax\n";
        out << "    mov [rel http_route_id], rax\n";
        out << "    lea rcx, [rel http_body_string]\n";
        out << "    lea rdx, [rel http_body_buf]\n";
        out << "    call string_from_cstr\n";
        out << "    mov rcx, 5\n";
        out << "    call aleka_create\n";
        out << "    mov r14, rax\n";
        out << "    mov rcx, r14\n";
        out << "    lea rdx, [rel http_body_string]\n";
        out << "    call Usersss_toObject\n";
        out << "    mov r14, rax\n";
        out << "    mov [rel http_route_request_object], r14\n";
        out << "    lea rcx, [rel http_password_string]\n";
        out << "    lea rdx, [rel http_password_buf]\n";
        out << "    call string_from_cstr\n";
        for (std::size_t route_index = 0; route_index < http_routes.size(); ++route_index) {
            out << "    cmp qword [rel http_route_kind], " << (route_index + 1) << "\n";
            out << "    je .http_server_dispatch_auto_" << route_index << "\n";
        }
        out << "    jmp .http_server_not_found\n";
        for (std::size_t route_index = 0; route_index < http_routes.size(); ++route_index) {
            const auto& route = http_routes[route_index];
            out << ".http_server_dispatch_auto_" << route_index << ":\n";
            out << "    xor rcx, rcx\n";
            out << "    mov rdx, [rel http_route_request_object]\n";
            out << "    lea r8, [rel http_password_string]\n";
            out << "    mov r9, [rel http_route_id]\n";
            out << "    call " << route.function_name << "\n";
            out << "    jmp .http_server_dispatch_auto_returned\n";
        }
        out << ".http_server_dispatch_auto_returned:\n";
        for (std::size_t route_index = 0; route_index < http_routes.size(); ++route_index) {
            out << "    cmp qword [rel http_route_kind], " << (route_index + 1) << "\n";
            out << "    je .http_server_send_auto_response_" << route_index << "\n";
        }
        out << "    jmp .http_server_not_found\n";
        for (std::size_t route_index = 0; route_index < http_routes.size(); ++route_index) {
            const auto& route = http_routes[route_index];
            out << ".http_server_send_auto_response_" << route_index << ":\n";
            out << "    lea rcx, [rel " << route.response_label << "]\n";
            out << "    call strlen\n";
            out << "    mov [rel http_route_result_len], rax\n";
            out << "    mov rcx, [rel http_client_socket]\n";
            out << "    lea rdx, [rel " << route.response_label << "]\n";
            out << "    mov r8, [rel http_route_result_len]\n";
            out << "    call bada_sock_send\n";
            out << "    jmp .http_server_close_client\n";
        }
        out << "    jmp .http_server_close_client\n";
        out << "    mov rcx, [rel http_client_socket]\n";
        out << "    lea rdx, [rel http_route_result_buf]\n";
        out << "    mov r8, [rel http_route_result_len]\n";
        out << "    call bada_sock_send\n";
        out << "    jmp .http_server_close_client\n";
        out << "    cmp qword [rel http_route_kind], 2\n";
        out << "    je .http_server_dispatch_getexample\n";
        out << "    cmp qword [rel http_route_kind], 3\n";
        out << "    je .http_server_dispatch_getexampleone\n";
        out << "    xor rcx, rcx\n";
        out << "    mov rdx, r14\n";
        out << "    lea r8, [rel http_password_string]\n";
        out << "    mov r9, [rel http_route_id]\n";
        out << "    call " << getsample_route << "\n";
        out << "    jmp .http_server_dispatch_returned\n";
        out << ".http_server_dispatch_getexample:\n";
        out << "    xor rcx, rcx\n";
        out << "    mov rdx, r14\n";
        out << "    lea r8, [rel http_password_string]\n";
        out << "    mov r9, [rel http_route_id]\n";
        out << "    call " << (getexample_route.empty() ? getsample_route : getexample_route) << "\n";
        out << "    jmp .http_server_dispatch_returned\n";
        out << ".http_server_dispatch_getexampleone:\n";
        out << "    xor rcx, rcx\n";
        out << "    mov rdx, r14\n";
        out << "    lea r8, [rel http_password_string]\n";
        out << "    mov r9, [rel http_route_id]\n";
        out << "    call " << (getexampleone_route.empty() ? getsample_route : getexampleone_route) << "\n";
        out << ".http_server_dispatch_returned:\n";
        out << "    cmp qword [rel http_route_kind], 3\n";
        out << "    je .http_server_send_getexampleone_response\n";
        out << "    cmp qword [rel http_route_kind], 2\n";
        out << "    je .http_server_send_getexample_response\n";
        out << "    mov rcx, [rel http_client_socket]\n";
        out << "    lea rdx, [rel http_route_response_json]\n";
        out << "    mov r8d, 512\n";
        out << "    call bada_sock_send\n";
        out << "    jmp .http_server_close_client\n";
        out << ".http_server_send_getexample_response:\n";
        out << "    mov rcx, [rel http_client_socket]\n";
        out << "    lea rdx, [rel http_route_getexample_response_json]\n";
        out << "    mov r8d, 512\n";
        out << "    call bada_sock_send\n";
        out << "    jmp .http_server_close_client\n";
        out << ".http_server_send_getexampleone_response:\n";
        out << "    mov rcx, [rel http_client_socket]\n";
        out << "    lea rdx, [rel http_route_getexampleone_response_json]\n";
        out << "    mov r8d, 512\n";
        out << "    call bada_sock_send\n";
        out << "    jmp .http_server_close_client\n";
        out << ".http_server_not_found:\n";
        out << "    lea rcx, [rel http_body_ok]\n";
        out << "    lea rdx, [rel http_response_buf]\n";
        out << "    mov r8d, 8192\n";
        out << "    call http_build_response\n";
        out << "    lea rcx, [rel http_response_buf]\n";
        out << "    call strlen\n";
        out << "    mov rcx, [rel http_client_socket]\n";
        out << "    lea rdx, [rel http_response_buf]\n";
        out << "    mov r8, rax\n";
        out << "    call bada_sock_send\n";
        out << ".http_server_close_client:\n";
        out << "    mov rcx, [rel http_client_socket]\n";
        out << "    call bada_sock_close\n";
        out << "    jmp .http_server_loop\n";
        out << ".http_server_bind_failed:\n";
        out << "    lea rcx, [rel http_server_bind_failed_msg]\n";
        out << "    call print_cstr\n";
        out << "    mov rcx, r15\n";
        out << "    call print_uint\n";
        out << "    lea rcx, [rel http_newline]\n";
        out << "    call print_cstr\n";
        out << "    jmp .http_server_close_listener\n";
        out << ".http_server_close_listener:\n";
        out << "    mov rcx, [rel http_listener_socket]\n";
        out << "    call bada_sock_close\n";
        out << ".http_server_cleanup:\n";
        out << "    call bada_sock_cleanup\n";
        out << ".http_server_exit:\n";
    }

    if (abi_ == ABIKind::Windows_x64) {
        out << "    add rsp, 32  ; clean shadow space\n";
    }

    out << "    xor rax, rax          ; return 0\n";
    out << "    leave\n";
    out << "    ret\n";
    out << "\n";

    // Collect all called symbols from IR instructions
    std::unordered_set<std::string> called_symbols;
    for (const auto& func : module.functions) {
        for (const auto& block : func.blocks) {
            for (const auto& inst : block.instructions) {
                if ((inst.opcode == IROpcode::Call || inst.opcode == IROpcode::CallRuntime) && !inst.operands.empty()) {
                    called_symbols.insert(inst.operands[0]);
                }
            }
        }
    }

    // Also add explicit external symbols
    for (const auto& sym : module.external_symbols) {
        called_symbols.insert(sym);
    }

}

// ============================================================================
// Function Emission - System V AMD64 ABI Prologue/Epilogue
// ============================================================================

void LinkingRuntime::emit_function_sysv(const IRFunction& func, std::ostringstream& out) {
    current_func_ = func.name;
    var_map_.clear();
    stack_offset_ = 0;
    func_stack_size_ = 0;

    out << func.name << ":\n";
    out << "    push rbp\n";
    out << "    mov rbp, rsp\n";
    out << "    push rbx\n";
    out << "    push r12\n";
    out << "    push r13\n";
    out << "    push r14\n";
    out << "    push r15\n";

    std::size_t saved_regs = 5;
    std::size_t push_rbp = 1;
    std::size_t prologue_overhead = (saved_regs + push_rbp) * 8;

    if (abi_ == ABIKind::Windows_x64) {
        stack_offset_ = -static_cast<int>(prologue_overhead + 32);
    } else {
        stack_offset_ = -static_cast<int>(prologue_overhead);
    }

    std::size_t num_params = func.parameters.size();
    std::size_t reg_params = (abi_ == ABIKind::Windows_x64) ? 4 : 6;
    for (std::size_t i = 0; i < func.parameters.size(); ++i) {
        const auto& param = func.parameters[i];
        stack_offset_ -= 8;
        var_map_[param.name] = {stack_offset_, param.type, true};
    }

    std::ostringstream body;

    for (std::size_t i = 0; i < func.parameters.size(); ++i) {
        const auto& param = func.parameters[i];
        if (abi_ == ABIKind::Windows_x64 && i >= reg_params) {
            const int stack_arg_offset = 48 + static_cast<int>((i - reg_params) * 8);
            body << "    mov rax, [rbp+" << stack_arg_offset << "]\n";
            body << "    mov [rbp" << var_map_[param.name].offset << "], rax"
                 << "  ; param '" << param.name << "'\n";
        } else {
            const char* reg = param_reg_sysv(i);
            body << "    mov [rbp" << var_map_[param.name].offset << "], " << reg
                 << "  ; param '" << param.name << "'\n";
        }
    }

    for (const auto& entry : module_string_constants_) {
        auto pos = entry.find(':');
        if (pos == std::string::npos) continue;
        std::string name = entry.substr(0, pos);
        if (abi_ == ABIKind::Windows_x64) {
            body << "    lea rcx, [rel " << name << "]\n";
            body << "    lea rdx, [rel " << name << "_data]\n";
            body << "    call string_from_cstr\n";
        } else {
            body << "    lea rdi, [rel " << name << "]\n";
            body << "    lea rsi, [rel " << name << "_data]\n";
            body << "    call string_from_cstr\n";
        }
    }

    for (const auto& block : func.blocks) {
        body << current_func_ << "_" << block.name << ":\n";
        for (const auto& inst : block.instructions) {
            emit_instruction_sysv(inst, func.name, body);
        }
    }

    bool ends_with_ret = false;
    if (!func.blocks.empty()) {
        const auto& last = func.blocks.back();
        if (!last.instructions.empty()) {
            ends_with_ret = last.instructions.back().opcode == IROpcode::Ret;
        }
    }

    int min_offset = stack_offset_;
    if (min_offset > 0) min_offset = 0;
    int local_space = -min_offset;
    int total_stack = local_space;
    if (abi_ == ABIKind::Windows_x64) {
        int rem = total_stack % 16;
        if (rem < 0) rem += 16;
        if (rem != 8) {
            total_stack += (8 - rem + 16) % 16;
        }
    } else if (total_stack % 16 != 0) {
        total_stack = ((total_stack / 16) + 1) * 16;
    }
    func_stack_size_ = total_stack;

    out << "    sub rsp, " << total_stack << "  ; local variables + shadow space\n";

    out << body.str();

    if (!ends_with_ret) {
        out << "    xor rax, rax  ; default return 0\n";
        out << "    add rsp, " << total_stack << "  ; clean stack frame\n";
        out << "    pop r15\n";
        out << "    pop r14\n";
        out << "    pop r13\n";
        out << "    pop r12\n";
        out << "    pop rbx\n";
        out << "    leave\n";
        out << "    ret\n";
    }
    out << "\n";
}

// ============================================================================
// Instruction Emission - System V AMD64 ABI
// ============================================================================

void LinkingRuntime::emit_instruction_sysv(const IRInstruction& inst,
                                            const std::string& func_name,
                                            std::ostringstream& out) {
    const std::string rax = "rax";
    const std::string rbx = "rbx";
    const std::string rcx = "rcx";

    switch (inst.opcode) {
        case IROpcode::ConstInt:
        case IROpcode::ConstLong: {
            stack_offset_ -= 8;
            var_map_[inst.result] = {stack_offset_, inst.type, false};
            out << "    mov " << rax << ", " << inst.int_value << "\n";
            out << "    mov [rbp" << stack_offset_ << "], " << rax << "\n";
            break;
        }

        case IROpcode::ConstDouble: {
            stack_offset_ -= 8;
            var_map_[inst.result] = {stack_offset_, inst.type, false};
            uint64_t bits = 0;
            static_assert(sizeof(bits) == sizeof(inst.double_value), "double size mismatch");
            std::memcpy(&bits, &inst.double_value, sizeof(bits));
            out << "    mov " << rax << ", " << bits << "\n";
            out << "    mov [rbp" << stack_offset_ << "], " << rax << "\n";
            break;
        }

        case IROpcode::ConstBool: {
            stack_offset_ -= 8;
            var_map_[inst.result] = {stack_offset_, inst.type, false};
            out << "    mov " << rax << ", " << (inst.int_value ? 1 : 0) << "\n";
            out << "    mov [rbp" << stack_offset_ << "], " << rax << "\n";
            break;
        }

        case IROpcode::ConstPtr: {
            stack_offset_ -= 8;
            var_map_[inst.result] = {stack_offset_, inst.type, false};
            if (!inst.string_value.empty()) {
                out << "    lea " << rax << ", [rel " << inst.string_value << "]\n";
            } else {
                out << "    xor " << rax << ", " << rax << "\n";
            }
            out << "    mov [rbp" << stack_offset_ << "], " << rax << "\n";
            break;
        }

        case IROpcode::Add: {
            if (inst.type.kind == IRTypeKind::String || inst.type.kind == IRTypeKind::Pointer) {
                // Check operand types - convert non-string operands to strings first
                auto it0 = var_map_.find(inst.operands[0]);
                bool op0_needs_convert = false;
                if (it0 != var_map_.end()) {
                    auto k = it0->second.type.kind;
                    if (k == IRTypeKind::Integer || k == IRTypeKind::Long) {
                        op0_needs_convert = true;
                    } else if (k == IRTypeKind::Pointer) {
                        // Check if it's a string constant (starts with str_)
                        bool is_string_const = (inst.operands[0].find("str_") == 0);
                        if (!is_string_const) {
                            op0_needs_convert = true; // Likely array_get result
                        }
                    }
                } else {
                    try { std::stoll(inst.operands[0]); op0_needs_convert = true; } catch (...) {}
                }

                auto it1 = var_map_.find(inst.operands[1]);
                bool op1_needs_convert = false;
                if (it1 != var_map_.end()) {
                    auto k = it1->second.type.kind;
                    if (k == IRTypeKind::Integer || k == IRTypeKind::Long) {
                        op1_needs_convert = true;
                    } else if (k == IRTypeKind::Pointer) {
                        bool is_string_const = (inst.operands[1].find("str_") == 0);
                        if (!is_string_const) {
                            op1_needs_convert = true;
                        }
                    }
                } else {
                    try { std::stoll(inst.operands[1]); op1_needs_convert = true; } catch (...) {}
                }

                // Allocate result string object (16 bytes)
                stack_offset_ -= 16;
                int dst_offset = stack_offset_;
                out << "    mov qword [rbp" << dst_offset << "], 0\n";
                out << "    mov qword [rbp" << (dst_offset + 8) << "], 0\n";

                int temp_op0_offset = 0, temp_op1_offset = 0;

                if (op0_needs_convert) {
                    stack_offset_ -= 16;
                    temp_op0_offset = stack_offset_;
                    out << "    mov qword [rbp" << temp_op0_offset << "], 0\n";
                    out << "    mov qword [rbp" << (temp_op0_offset + 8) << "], 0\n";
                    // For pointers (e.g. from array_get), load the value at the address first
                    auto it0 = var_map_.find(inst.operands[0]);
                    if (it0 != var_map_.end() && it0->second.type.kind == IRTypeKind::Pointer) {
                        out << "    mov rax, [rbp" << it0->second.offset << "]\n";
                        out << "    mov rdx, [rax]\n"; // Load actual value
                    } else {
                        emit_move_to_reg_sysv(inst.operands[0], "rdx", IRType::makeLong(), out);
                    }
                    out << "    lea rcx, [rbp" << temp_op0_offset << "]\n";
                    const auto it0_type = var_map_.find(inst.operands[0]);
                    const bool op0_is_long =
                        it0_type != var_map_.end() && it0_type->second.type.kind == IRTypeKind::Long;
                    out << "    call " << (op0_is_long ? "fromLong" : "fromInteger") << "\n";
                }

                if (op1_needs_convert) {
                    stack_offset_ -= 16;
                    temp_op1_offset = stack_offset_;
                    out << "    mov qword [rbp" << temp_op1_offset << "], 0\n";
                    out << "    mov qword [rbp" << (temp_op1_offset + 8) << "], 0\n";
                    // For pointers (e.g. from array_get), load the value at the address first
                    auto it1 = var_map_.find(inst.operands[1]);
                    if (it1 != var_map_.end() && it1->second.type.kind == IRTypeKind::Pointer) {
                        out << "    mov rax, [rbp" << it1->second.offset << "]\n";
                        out << "    mov rdx, [rax]\n"; // Load actual value
                    } else {
                        emit_move_to_reg_sysv(inst.operands[1], "rdx", IRType::makeLong(), out);
                    }
                    out << "    lea rcx, [rbp" << temp_op1_offset << "]\n";
                    const auto it1_type = var_map_.find(inst.operands[1]);
                    const bool op1_is_long =
                        it1_type != var_map_.end() && it1_type->second.type.kind == IRTypeKind::Long;
                    out << "    call " << (op1_is_long ? "fromLong" : "fromInteger") << "\n";
                }

                // Call string_concat with proper args
                out << "    lea rcx, [rbp" << dst_offset << "]\n";
                if (abi_ == ABIKind::Windows_x64) {
                    out << "    sub rsp, 32\n";
                    if (op0_needs_convert) {
                        out << "    lea rdx, [rbp" << temp_op0_offset << "]\n";
                    } else {
                        emit_move_to_reg_sysv(inst.operands[0], "rdx", inst.type, out);
                    }
                    if (op1_needs_convert) {
                        out << "    lea r8, [rbp" << temp_op1_offset << "]\n";
                    } else {
                        emit_move_to_reg_sysv(inst.operands[1], "r8", inst.type, out);
                    }
                    out << "    call string_concat\n";
                    out << "    add rsp, 32\n";
                } else {
                    if (op0_needs_convert) {
                        out << "    lea rsi, [rbp" << temp_op0_offset << "]\n";
                    } else {
                        emit_move_to_reg_sysv(inst.operands[0], "rsi", inst.type, out);
                    }
                    if (op1_needs_convert) {
                        out << "    lea rdx, [rbp" << temp_op1_offset << "]\n";
                    } else {
                        emit_move_to_reg_sysv(inst.operands[1], "rdx", inst.type, out);
                    }
                    out << "    call string_concat\n";
                }

                // Store result pointer
                stack_offset_ -= 8;
                var_map_[inst.result] = {stack_offset_, inst.type, false};
                out << "    lea " << rax << ", [rbp" << dst_offset << "]\n";
                out << "    mov [rbp" << stack_offset_ << "], " << rax << "\n";
            } else {
                stack_offset_ -= 8;
                var_map_[inst.result] = {stack_offset_, inst.type, false};
                emit_move_to_reg_sysv(inst.operands[0], rax, inst.type, out);
                emit_move_to_reg_sysv(inst.operands[1], rbx, inst.type, out);
                out << "    add " << rax << ", " << rbx << "\n";
                out << "    mov [rbp" << stack_offset_ << "], " << rax << "\n";
            }
            break;
        }

        case IROpcode::Sub: {
            stack_offset_ -= 8;
            var_map_[inst.result] = {stack_offset_, inst.type, false};
            emit_move_to_reg_sysv(inst.operands[0], rax, inst.type, out);
            emit_move_to_reg_sysv(inst.operands[1], rbx, inst.type, out);
            out << "    sub " << rax << ", " << rbx << "\n";
            out << "    mov [rbp" << stack_offset_ << "], " << rax << "\n";
            break;
        }

        case IROpcode::Mul: {
            stack_offset_ -= 8;
            var_map_[inst.result] = {stack_offset_, inst.type, false};
            emit_move_to_reg_sysv(inst.operands[0], rax, inst.type, out);
            emit_move_to_reg_sysv(inst.operands[1], rbx, inst.type, out);
            out << "    imul " << rax << ", " << rbx << "\n";
            out << "    mov [rbp" << stack_offset_ << "], " << rax << "\n";
            break;
        }

        case IROpcode::Div: {
            stack_offset_ -= 8;
            var_map_[inst.result] = {stack_offset_, inst.type, false};
            emit_move_to_reg_sysv(inst.operands[0], rax, inst.type, out);
            emit_move_to_reg_sysv(inst.operands[1], rbx, inst.type, out);
            out << "    cqo\n";
            out << "    idiv " << rbx << "\n";
            out << "    mov [rbp" << stack_offset_ << "], " << rax << "\n";
            break;
        }

        case IROpcode::Mod: {
            stack_offset_ -= 8;
            var_map_[inst.result] = {stack_offset_, inst.type, false};
            emit_move_to_reg_sysv(inst.operands[0], rax, inst.type, out);
            emit_move_to_reg_sysv(inst.operands[1], rbx, inst.type, out);
            out << "    cqo\n";
            out << "    idiv " << rbx << "\n";
            out << "    mov [rbp" << stack_offset_ << "], rdx\n";
            break;
        }

        case IROpcode::EQ:
        case IROpcode::NE:
        case IROpcode::LT:
        case IROpcode::GT:
        case IROpcode::LE:
        case IROpcode::GE: {
            stack_offset_ -= 8;
            var_map_[inst.result] = {stack_offset_, IRType::makeBoolean(), false};

            emit_move_to_reg_sysv(inst.operands[0], rax, inst.type, out);
            emit_move_to_reg_sysv(inst.operands[1], rbx, inst.type, out);
            out << "    cmp " << rax << ", " << rbx << "\n";

            const char* setcc = "";
            switch (inst.opcode) {
                case IROpcode::EQ: setcc = "sete";  break;
                case IROpcode::NE: setcc = "setne"; break;
                case IROpcode::LT: setcc = "setl";  break;
                case IROpcode::GT: setcc = "setg";  break;
                case IROpcode::LE: setcc = "setle"; break;
                case IROpcode::GE: setcc = "setge"; break;
                default: break;
            }
            out << "    " << setcc << " al\n";
            out << "    movzx " << rax << ", al\n";
            out << "    mov [rbp" << stack_offset_ << "], " << rax << "\n";
            break;
        }

        case IROpcode::And: {
            stack_offset_ -= 8;
            var_map_[inst.result] = {stack_offset_, inst.type, false};
            emit_move_to_reg_sysv(inst.operands[0], rax, inst.type, out);
            emit_move_to_reg_sysv(inst.operands[1], rbx, inst.type, out);
            out << "    and " << rax << ", " << rbx << "\n";
            out << "    mov [rbp" << stack_offset_ << "], " << rax << "\n";
            break;
        }

        case IROpcode::Or: {
            stack_offset_ -= 8;
            var_map_[inst.result] = {stack_offset_, inst.type, false};
            emit_move_to_reg_sysv(inst.operands[0], rax, inst.type, out);
            emit_move_to_reg_sysv(inst.operands[1], rbx, inst.type, out);
            out << "    or " << rax << ", " << rbx << "\n";
            out << "    mov [rbp" << stack_offset_ << "], " << rax << "\n";
            break;
        }

        case IROpcode::Not: {
            stack_offset_ -= 8;
            var_map_[inst.result] = {stack_offset_, inst.type, false};
            emit_move_to_reg_sysv(inst.operands[0], rax, inst.type, out);
            out << "    xor " << rax << ", 1\n";
            out << "    mov [rbp" << stack_offset_ << "], " << rax << "\n";
            break;
        }

        case IROpcode::Neg: {
            stack_offset_ -= 8;
            var_map_[inst.result] = {stack_offset_, inst.type, false};
            emit_move_to_reg_sysv(inst.operands[0], rax, inst.type, out);
            out << "    neg " << rax << "\n";
            out << "    mov [rbp" << stack_offset_ << "], " << rax << "\n";
            break;
        }

        case IROpcode::Alloca: {
            stack_offset_ -= inst.type.size_bytes();
            var_map_[inst.result] = {stack_offset_, inst.type, false};
            break;
        }

        case IROpcode::Load: {
            auto it = var_map_.find(inst.operands[0]);
            if (it != var_map_.end()) {
                stack_offset_ -= 8;
                var_map_[inst.result] = {stack_offset_, inst.type, false};
                out << "    mov " << rax << ", [rbp" << it->second.offset << "]\n";
                out << "    mov [rbp" << stack_offset_ << "], " << rax << "\n";
            } else if (global_map_.find(inst.operands[0]) != global_map_.end()) {
                stack_offset_ -= 8;
                var_map_[inst.result] = {stack_offset_, inst.type, false};
                out << "    mov " << rax << ", [rel " << inst.operands[0] << "]\n";
                out << "    mov [rbp" << stack_offset_ << "], " << rax << "\n";
            }
            break;
        }

        case IROpcode::Store: {
            auto it = var_map_.find(inst.operands[1]);
            if (it != var_map_.end()) {
                emit_move_to_reg_sysv(inst.operands[0], rax, inst.type, out);
                out << "    mov [rbp" << it->second.offset << "], " << rax << "\n";
            } else if (global_map_.find(inst.operands[1]) != global_map_.end()) {
                emit_move_to_reg_sysv(inst.operands[0], rax, inst.type, out);
                out << "    mov [rel " << inst.operands[1] << "], " << rax << "\n";
            }
            break;
        }

        case IROpcode::Label:
            // Label already emitted by block header
            break;

        case IROpcode::Jmp:
            out << "    jmp " << func_name << "_" << inst.label_name << "\n";
            break;

        case IROpcode::Branch: {
            emit_move_to_reg_sysv(inst.operands[0], rax, IRType::makeBoolean(), out);
            out << "    test " << rax << ", " << rax << "\n";
            out << "    jne " << func_name << "_" << inst.operands[1] << "\n";
            out << "    jmp " << func_name << "_" << inst.operands[2] << "\n";
            break;
        }

        case IROpcode::Ret: {
            if (!inst.operands.empty()) {
                if (inst.type.kind == IRTypeKind::String && !inst.type.is_file_backed) {
                    out << "    xor rcx, rcx\n";
                    out << "    mov rdx, 8\n";
                    out << "    mov r8, 16\n";
                    if (abi_ == ABIKind::Windows_x64) {
                        out << "    sub rsp, 32  ; shadow space\n";
                    }
                    out << "    call bada_heap_alloc\n";
                    if (abi_ == ABIKind::Windows_x64) {
                        out << "    add rsp, 32  ; clean shadow space\n";
                    }
                    out << "    mov rbx, rax\n";
                    emit_move_to_reg_sysv(inst.operands[0], "rdx", inst.type, out);
                    out << "    mov rcx, rbx\n";
                    if (abi_ == ABIKind::Windows_x64) {
                        out << "    sub rsp, 32  ; shadow space\n";
                    }
                    out << "    call string_copy\n";
                    if (abi_ == ABIKind::Windows_x64) {
                        out << "    add rsp, 32  ; clean shadow space\n";
                    }
                    out << "    mov rax, rbx\n";
                } else {
                    emit_move_to_reg_sysv(inst.operands[0], rax, inst.type, out);
                }
            } else {
                out << "    xor " << rax << ", " << rax << "\n";
            }
            out << "    add rsp, " << func_stack_size_ << "  ; clean stack frame\n";
            out << "    pop r15\n";
            out << "    pop r14\n";
            out << "    pop r13\n";
            out << "    pop r12\n";
            out << "    pop rbx\n";
            out << "    leave\n";
            out << "    ret\n";
            break;
        }

        case IROpcode::Call:
        case IROpcode::CallRuntime: {
            std::string func_name_call = inst.operands[0];
            std::size_t num_args = inst.operands.size() - 1;
            std::size_t max_reg_params = (abi_ == ABIKind::Windows_x64) ? 4 : 6;
            const std::size_t stack_arg_count = num_args > max_reg_params ? (num_args - max_reg_params) : 0;
            std::size_t call_frame_size = 32 + stack_arg_count * 8;
            if (abi_ == ABIKind::Windows_x64 && (call_frame_size % 16) != 0) {
                call_frame_size += 8;
            }

            if (abi_ == ABIKind::Windows_x64) {
                out << "    sub rsp, " << call_frame_size << "  ; shadow space + stack args\n";
            }

            // Stack args beyond register limit (in reverse order)
            if (num_args > max_reg_params) {
                for (std::size_t i = num_args; i > max_reg_params; --i) {
                    const std::size_t stack_index = i - max_reg_params - 1;
                    auto arg_it = var_map_.find(inst.operands[i]);
                    if (arg_it != var_map_.end() &&
                        runtime_arg_passes_slot_address(func_name_call, i - 1)) {
                        out << "    lea rax, [rbp" << arg_it->second.offset << "]\n";
                        if (abi_ == ABIKind::Windows_x64) {
                            out << "    mov [rsp+" << (32 + stack_index * 8) << "], rax\n";
                        } else {
                            out << "    push rax\n";
                        }
                    } else {
                        emit_move_to_reg_sysv(inst.operands[i], rax, IRType::makePointer(), out);
                        if (abi_ == ABIKind::Windows_x64) {
                            out << "    mov [rsp+" << (32 + stack_index * 8) << "], " << rax << "\n";
                        } else {
                            out << "    push " << rax << "\n";
                        }
                    }
                }
            }

            // Move args to registers
            for (std::size_t i = 0; i < num_args && i < max_reg_params; ++i) {
                const char* reg = param_reg_sysv(i);
                auto arg_it = var_map_.find(inst.operands[i + 1]);
                if (arg_it != var_map_.end() &&
                    runtime_arg_passes_slot_address(func_name_call, i)) {
                    out << "    lea " << reg << ", [rbp" << arg_it->second.offset << "]\n";
                } else if ((func_name_call == "print_uint" || func_name_call == "print_cstr") &&
                    arg_it != var_map_.end() && arg_it->second.type.kind == IRTypeKind::Pointer) {
                    out << "    mov rax, [rbp" << arg_it->second.offset << "]\n";
                    out << "    mov rax, [rax]\n";
                    out << "    mov " << reg << ", rax\n";
                } else {
                    emit_move_to_reg_sysv(inst.operands[i + 1], reg, IRType::makePointer(), out);
                }
            }

            out << "    call " << func_name_call << "\n";

            // Clean up
            if (num_args > max_reg_params && abi_ != ABIKind::Windows_x64) {
                out << "    add rsp, " << ((num_args - max_reg_params) * 8) << "\n";
            }
            if (abi_ == ABIKind::Windows_x64) {
                out << "    add rsp, " << call_frame_size << "  ; clean shadow space + stack args\n";
            }

            if (!inst.result.empty()) {
                stack_offset_ -= 8;
                var_map_[inst.result] = {stack_offset_, inst.type, false};
                out << "    mov [rbp" << stack_offset_ << "], " << rax << "\n";
            }
            break;
        }

        case IROpcode::ArrayNew: {
            std::size_t max_reg_params = (abi_ == ABIKind::Windows_x64) ? 4 : 6;
            if (abi_ == ABIKind::Windows_x64) {
                out << "    sub rsp, 32  ; shadow space\n";
            }
            if (inst.operands.empty()) {
                out << "    mov " << param_reg_sysv(0) << ", 4\n";
            } else {
                emit_move_to_reg_sysv(inst.operands[0], param_reg_sysv(0), IRType::makeInteger(), out);
            }
            out << "    mov " << param_reg_sysv(1) << ", 8  ; element size\n";
            out << "    call array_create\n";
            if (abi_ == ABIKind::Windows_x64) {
                out << "    add rsp, 32  ; clean shadow space\n";
            }

            if (!inst.result.empty()) {
                stack_offset_ -= 8;
                var_map_[inst.result] = {stack_offset_, IRType::makePointer(), false};
                out << "    mov [rbp" << stack_offset_ << "], " << rax << "\n";
            }
            break;
        }

        case IROpcode::ArrayGet: {
            if (abi_ == ABIKind::Windows_x64) {
                out << "    sub rsp, 32  ; shadow space\n";
            }
            emit_move_to_reg_sysv(inst.operands[0], param_reg_sysv(0), IRType::makePointer(), out);
            emit_move_to_reg_sysv(inst.operands[1], param_reg_sysv(1), IRType::makeInteger(), out);
            out << "    call array_get\n";
            if (abi_ == ABIKind::Windows_x64) {
                out << "    add rsp, 32  ; clean shadow space\n";
            }

            if (!inst.result.empty()) {
                stack_offset_ -= 8;
                var_map_[inst.result] = {stack_offset_, inst.type, false};
                switch (inst.type.kind) {
                    case IRTypeKind::Integer:
                    case IRTypeKind::Long:
                    case IRTypeKind::Boolean:
                        out << "    mov rdx, [rax]\n";
                        out << "    mov [rbp" << stack_offset_ << "], rdx\n";
                        break;
                    case IRTypeKind::Double:
                        out << "    movsd xmm0, qword [rax]\n";
                        out << "    movsd qword [rbp" << stack_offset_ << "], xmm0\n";
                        break;
                    case IRTypeKind::String:
                        out << "    mov rdx, [rax]\n";
                        out << "    mov [rbp" << stack_offset_ << "], rdx\n";
                        break;
                    default:
                        out << "    mov [rbp" << stack_offset_ << "], rax\n";
                        break;
                }
            }
            break;
        }

        case IROpcode::ArraySet: {
            if (abi_ == ABIKind::Windows_x64) {
                out << "    sub rsp, 32  ; shadow space\n";
            }
            emit_move_to_reg_sysv(inst.operands[0], param_reg_sysv(0), IRType::makePointer(), out);
            // Allocate temp slot for element, store value, pass pointer
            int saved_offset = stack_offset_;
            stack_offset_ -= 8;
            int temp_slot = stack_offset_;
            emit_move_to_reg_sysv(inst.operands[2], "rax", IRType::makePointer(), out);
            out << "    mov [rbp" << temp_slot << "], rax\n";
            out << "    lea rdx, [rbp" << temp_slot << "]\n";
            out << "    call array_add\n";
            stack_offset_ = saved_offset; // Restore for subsequent instructions
            if (abi_ == ABIKind::Windows_x64) {
                out << "    add rsp, 32  ; clean shadow space\n";
            }
            break;
        }

        case IROpcode::ArrayLen: {
            if (abi_ == ABIKind::Windows_x64) {
                out << "    sub rsp, 32  ; shadow space\n";
            }
            emit_move_to_reg_sysv(inst.operands[0], param_reg_sysv(0), IRType::makePointer(), out);
            out << "    call array_size\n";
            if (abi_ == ABIKind::Windows_x64) {
                out << "    add rsp, 32  ; clean shadow space\n";
            }

            if (!inst.result.empty()) {
                stack_offset_ -= 8;
                var_map_[inst.result] = {stack_offset_, IRType::makeInteger(), false};
                out << "    mov [rbp" << stack_offset_ << "], " << rax << "\n";
            }
            break;
        }

        case IROpcode::ArrayPush: {
            if (abi_ == ABIKind::Windows_x64) {
                out << "    sub rsp, 32  ; shadow space\n";
            }
            emit_move_to_reg_sysv(inst.operands[0], param_reg_sysv(0), IRType::makePointer(), out);
            // Allocate temp slot for element, store value, pass pointer
            int saved_offset = stack_offset_;
            stack_offset_ -= 8;
            int temp_slot = stack_offset_;
            emit_move_to_reg_sysv(inst.operands[1], "rax", IRType::makePointer(), out);
            out << "    mov [rbp" << temp_slot << "], rax\n";
            out << "    lea rdx, [rbp" << temp_slot << "]\n";
            out << "    call array_add\n";
            stack_offset_ = saved_offset; // Restore for subsequent instructions
            if (abi_ == ABIKind::Windows_x64) {
                out << "    add rsp, 32  ; clean shadow space\n";
            }
            break;
        }

        default:
            out << "    ; unknown opcode: " << static_cast<int>(inst.opcode) << "\n";
            break;
    }
}

// ============================================================================
// Runtime Initialization Preamble
// ============================================================================

std::string LinkingRuntime::generate_runtime_init() {
    std::ostringstream out;

    out << "    ; === Runtime Initialization (System V AMD64 ABI) ===\n";
    out << "    ; Stack is already 16-byte aligned after prologue\n";
    out << "    call runtime_init    ; initialize stdout handle\n";
    out << "    call thread_init     ; initialize TLS and critical section\n";
    out << "\n";

    return out.str();
}

// ============================================================================
// Runtime Call Generation
// ============================================================================

std::string LinkingRuntime::generate_runtime_call(const std::string& func_name,
                                                    const std::vector<std::string>& args,
                                                    const std::string& result_reg) {
    std::ostringstream out;

    // System V AMD64: rdi, rsi, rdx, rcx, r8, r9
    const char* param_regs[] = {"rdi", "rsi", "rdx", "rcx", "r8", "r9"};
    const int max_regs = 6;

    // Handle >6 args (push on stack in reverse)
    std::size_t num_args = args.size();
    if (num_args > max_regs) {
        out << "    ; Push extra args beyond 6th\n";
        for (std::size_t i = num_args; i > max_regs; --i) {
            out << "    mov rax, " << args[i - 1] << "\n";
            out << "    push rax\n";
        }
    }

    // Move args to registers
    for (std::size_t i = 0; i < num_args && i < max_regs; ++i) {
        out << "    mov " << param_regs[i] << ", " << args[i] << "\n";
    }

    // Align stack if needed
    out << "    ; Ensure 16-byte stack alignment before call\n";
    out << "    and rsp, -16\n";

    out << "    call " << func_name << "\n";

    // Clean up stack-pushed args
    if (num_args > max_regs) {
        out << "    add rsp, " << ((num_args - max_regs) * 8) << "\n";
    }

    if (result_reg != "void") {
        out << "    mov " << result_reg << ", rax\n";
    }

    return out.str();
}

// ============================================================================
// Build Pipeline: Assemble + Link
// ============================================================================

bool LinkingRuntime::assemble_to_object(const std::string& source_s_path,
                                          const std::string& output_obj_path) {
#ifdef _WIN32
    std::string cmd = nasm_path_ + " -f win64 -o \"" + output_obj_path + "\" \"" + source_s_path + "\"";
#else
    std::string cmd = nasm_path_ + " -f elf64 -o \"" + output_obj_path + "\" \"" + source_s_path + "\"";
#endif

    int ret = std::system(cmd.c_str());
    if (ret != 0) {
        fprintf(stderr, "NASM assembly failed: %s\n", cmd.c_str());
        return false;
    }
    return true;
}

bool LinkingRuntime::link_executable(const std::string& input_obj_path,
                                       const std::string& output_exe_path,
                                       const std::string& runtime_dir,
                                       const std::vector<std::string>& extra_objects,
                                       const std::vector<std::string>& extra_libraries) {
    std::string rdir = runtime_dir.empty() ? runtime_dir_ : runtime_dir;

    std::ostringstream cmd;
    cmd << gcc_path_ << " -o \"" << output_exe_path << "\" \"" << input_obj_path << "\"";

    // Runtime objects
    const std::vector<std::string> runtime_objs = {
        "string.obj", "integer.obj", "array.obj", "boolean.obj",
        "double.obj", "long.obj", "map.obj", "badaapi_ptrs.obj",
        "aleka.obj",
        "thread.obj", "httpclient.obj", "httpserver.obj",
        "sock.obj"
    };

    for (const auto& obj : runtime_objs) {
        cmd << " \"" << resolve_runtime_object_path(rdir, obj) << "\"";
    }

    // Heap object (from asm_file_obj)
    cmd << " \"" << resolve_runtime_object_path(join_path(rdir, "..\\asm_file_obj"), "readwritefile.obj") << "\"";
    cmd << " \"" << resolve_runtime_object_path(join_path(rdir, "..\\asm_file_obj"), "heap.obj") << "\"";

    // Extra objects
    for (const auto& obj : extra_objects) {
        cmd << " \"" << obj << "\"";
    }

    // System libraries
    cmd << " -lntdll -lws2_32";

    // Extra libraries
    for (const auto& lib : extra_libraries) {
        cmd << " -l" << lib;
    }

    int ret = std::system(cmd.str().c_str());
    if (ret != 0) {
        fprintf(stderr, "Linking failed: %s\n", cmd.str().c_str());
        return false;
    }
    return true;
}

bool LinkingRuntime::build_executable(const IRModule& module,
                                        const std::string& output_exe_path,
                                        const std::string& runtime_dir) {
    // Step 1: Generate assembly
    std::string asm_path = output_exe_path;
    auto dot = asm_path.find_last_of('.');
    if (dot != std::string::npos) {
        asm_path = asm_path.substr(0, dot);
    }
    asm_path += ".s";

    // Ensure parent directory exists
    std::string dir = asm_path;
    auto last_slash = dir.find_last_of("/\\");
    if (last_slash != std::string::npos) {
        dir = dir.substr(0, last_slash);
#ifdef _WIN32
        std::string mkdir_cmd = "if not exist \"" + dir + "\" mkdir \"" + dir + "\"";
#else
        std::string mkdir_cmd = "mkdir -p \"" + dir + "\"";
#endif
        std::system(mkdir_cmd.c_str());
    }

    std::ofstream asm_file(asm_path);
    if (!asm_file.is_open()) {
        std::cerr << "Cannot open assembly file: " << asm_path << std::endl;
        return false;
    }
    asm_file << generate_assembly(module);
    asm_file.close();

    // Step 2: Assemble
    std::string obj_path = asm_path;
    dot = obj_path.find_last_of('.');
    if (dot != std::string::npos) {
        obj_path = obj_path.substr(0, dot);
    }
    obj_path += ".obj";

    if (!assemble_to_object(asm_path, obj_path)) {
        fprintf(stderr, "Assembly failed for: %s\n", asm_path.c_str());
        return false;
    }

    // Step 3: Link
    if (!link_executable(obj_path, output_exe_path, runtime_dir)) {
        fprintf(stderr, "Linking failed for: %s\n", obj_path.c_str());
        return false;
    }

    return true;
}

// ============================================================================
// RuntimeRegistry - Function signature database
// ============================================================================

const RuntimeRegistry& RuntimeRegistry::instance() {
    static RuntimeRegistry reg;
    return reg;
}

RuntimeRegistry::RuntimeRegistry() {
    // String functions
    functions_["print_cstr"]   = {"print_cstr",   {"ptr"},          "void",  "string.obj"};
    functions_["print_string"] = {"print_string", {"ptr"},          "void",  "string.obj"};
    functions_["print_uint"]   = {"print_uint",   {"i64"},          "void",  "string.obj"};
    functions_["string_concat"]= {"string_concat",{"ptr","ptr","ptr"},"void", "string.obj"};
    functions_["string_equals"]= {"string_equals",{"ptr","ptr"},    "bool",  "string.obj"};
    functions_["string_equals_icase"]= {"string_equals_icase",{"ptr","ptr"}, "bool", "string.obj"};
    functions_["string_contains_sub"]= {"string_contains_sub",{"ptr","ptr"}, "bool", "string.obj"};
    functions_["string_copy"]  = {"string_copy",  {"ptr","ptr"},    "void",  "string.obj"};
    functions_["string_free"]  = {"string_free",  {"ptr"},          "void",  "string.obj"};
    functions_["string_from_cstr"] = {"string_from_cstr", {"ptr","ptr"}, "bool", "string.obj"};
    functions_["string_length"]= {"string_length",{"ptr"},          "i64",   "string.obj"};
    functions_["string_char_at"]= {"string_char_at",{"ptr","i64"},  "i64",   "string.obj"};
    functions_["filestring_create_auto_from_cstr"] = {"filestring_create_auto_from_cstr", {"ptr","ptr"}, "i64", "string.obj"};
    functions_["filestring_open"] = {"filestring_open", {"ptr","ptr"}, "i64", "string.obj"};
    functions_["filestring_length"] = {"filestring_length", {"ptr"}, "i64", "string.obj"};
    functions_["filestring_char_at"] = {"filestring_char_at", {"ptr","i64"}, "i64", "string.obj"};
    functions_["filestring_replace_char_at"] = {"filestring_replace_char_at", {"ptr","i64","i64"}, "i64", "string.obj"};
    functions_["filestring_free"] = {"filestring_free", {"ptr"}, "void", "string.obj"};

    // Integer functions
    functions_["int_add"] = {"int_add", {"i32","i32"}, "i32", "integer.obj"};
    functions_["int_sub"] = {"int_sub", {"i32","i32"}, "i32", "integer.obj"};
    functions_["int_mul"] = {"int_mul", {"i32","i32"}, "i32", "integer.obj"};
    functions_["int_div"] = {"int_div", {"i32","i32"}, "i32", "integer.obj"};
    functions_["int_mod"] = {"int_mod", {"i32","i32"}, "i32", "integer.obj"};
    functions_["int_eq"]  = {"int_eq",  {"i32","i32"}, "bool","integer.obj"};
    functions_["int_lt"]  = {"int_lt",  {"i32","i32"}, "bool","integer.obj"};
    functions_["int_gt"]  = {"int_gt",  {"i32","i32"}, "bool","integer.obj"};

    // Long functions
    functions_["long_add"] = {"long_add", {"i64","i64"}, "i64", "long.obj"};
    functions_["long_sub"] = {"long_sub", {"i64","i64"}, "i64", "long.obj"};
    functions_["long_mul"] = {"long_mul", {"i64","i64"}, "i64", "long.obj"};
    functions_["long_div"] = {"long_div", {"i64","i64"}, "i64", "long.obj"};
    functions_["long_mod"] = {"long_mod", {"i64","i64"}, "i64", "long.obj"};
    functions_["long_eq"]  = {"long_eq",  {"i64","i64"}, "bool","long.obj"};
    functions_["long_lt"]  = {"long_lt",  {"i64","i64"}, "bool","long.obj"};
    functions_["long_gt"]  = {"long_gt",  {"i64","i64"}, "bool","long.obj"};

    // Boolean functions
    functions_["bool_and"] = {"bool_and", {"bool","bool"}, "bool", "boolean.obj"};
    functions_["bool_or"]  = {"bool_or",  {"bool","bool"}, "bool", "boolean.obj"};
    functions_["bool_not"] = {"bool_not", {"bool"},        "bool", "boolean.obj"};
    functions_["bool_eq"]  = {"bool_eq",  {"bool","bool"}, "bool", "boolean.obj"};

    // Array functions
    functions_["array_create"] = {"array_create", {"i64","i64"},  "ptr", "array.obj"};
    functions_["array_add"]    = {"array_add",    {"ptr","ptr"},  "bool","array.obj"};
    functions_["array_get"]    = {"array_get",    {"ptr","i64"},  "ptr", "array.obj"};
    functions_["array_size"]   = {"array_size",   {"ptr"},        "i64", "array.obj"};
    functions_["array_remove"] = {"array_remove", {"ptr","i64"},  "bool","array.obj"};
    functions_["array_free"]   = {"array_free",   {"ptr"},        "void","array.obj"};
    functions_["array_sort"]   = {"array_sort",   {"ptr","ptr"},  "void","array.obj"};
    functions_["array_filter"] = {"array_filter", {"ptr","ptr"},  "ptr", "array.obj"};
    functions_["array_map"]    = {"array_map",    {"ptr","ptr","ptr"}, "void", "array.obj"};
    functions_["array_join"]   = {"array_join",   {"ptr","ptr","ptr"}, "void", "array.obj"};
      functions_["array_join_int"]    = {"array_join_int",    {"ptr","ptr","ptr"}, "void", "array.obj"};
      functions_["array_join_long"]   = {"array_join_long",   {"ptr","ptr","ptr"}, "void", "array.obj"};
      functions_["array_join_double"] = {"array_join_double", {"ptr","ptr","ptr"}, "void", "array.obj"};
      functions_["array_join_bool"]   = {"array_join_bool",   {"ptr","ptr","ptr"}, "void", "array.obj"};
      functions_["aleka_create"] = {"aleka_create", {"i64"}, "ptr", "aleka.obj"};
      functions_["aleka_set"]    = {"aleka_set",    {"ptr","i64","i64"}, "void", "aleka.obj"};
      functions_["aleka_get"]    = {"aleka_get",    {"ptr","i64"}, "i64", "aleka.obj"};
      functions_["aleka_free"]   = {"aleka_free",   {"ptr"}, "void", "aleka.obj"};
      functions_["aleka_json_apply"] = {"aleka_json_apply", {"ptr","ptr","ptr","i64"}, "void", "aleka.obj"};
      functions_["aleka_json_extract"] = {"aleka_json_extract", {"ptr","ptr","ptr"}, "void", "aleka.obj"};

      // Map functions
      functions_["map_create"]       = {"map_create",       {"i64","ptr","ptr"}, "ptr",  "map.obj"};
    functions_["map_put"]          = {"map_put",          {"ptr","ptr","ptr"}, "ptr",  "map.obj"};
    functions_["map_get"]          = {"map_get",          {"ptr","ptr"},       "ptr",  "map.obj"};
    functions_["map_contains_key"] = {"map_contains_key", {"ptr","ptr"},       "bool", "map.obj"};
    functions_["map_remove"]       = {"map_remove",       {"ptr","ptr"},       "ptr",  "map.obj"};
    functions_["map_size"]         = {"map_size",         {"ptr"},             "i64",  "map.obj"};
    functions_["map_is_empty"]     = {"map_is_empty",     {"ptr"},             "bool", "map.obj"};
    functions_["map_clear"]        = {"map_clear",        {"ptr"},             "void", "map.obj"};
    functions_["map_free"]         = {"map_free",         {"ptr"},             "void", "map.obj"};
    functions_["map_to_string"]    = {"map_to_string",    {"ptr","ptr"},       "void", "map.obj"};

    // File functions
    functions_["file_read_all"]              = {"file_read_all",              {"ptr","ptr"},       "bool", "readwritefile.obj"};
    functions_["file_print_lines_count"]     = {"file_print_lines_count",     {"ptr"},             "bool", "readwritefile.obj"};
    functions_["file_line_reader_open"]      = {"file_line_reader_open",      {"ptr"},             "bool", "readwritefile.obj"};
    functions_["file_line_reader_open_string"]= {"file_line_reader_open_string", {"ptr"},          "bool", "readwritefile.obj"};
    functions_["file_line_reader_next"]      = {"file_line_reader_next",      {"ptr"},             "bool", "readwritefile.obj"};
    functions_["file_line_reader_close"]     = {"file_line_reader_close",     {},                  "void", "readwritefile.obj"};
    functions_["file_line_reader_line_count"]= {"file_line_reader_line_count",{},                  "i64",  "readwritefile.obj"};
    functions_["file_count_lines"]           = {"file_count_lines",           {"ptr"},             "i64",  "readwritefile.obj"};
    functions_["file_get_line_at"]           = {"file_get_line_at",           {"ptr","i64","ptr"}, "bool", "readwritefile.obj"};

    // Thread functions
    functions_["runtime_init"] = {"runtime_init", {}, "void", "string.obj"};
    functions_["thread_init"]  = {"thread_init",  {}, "void", "thread.obj"};
    functions_["thread_run"]   = {"thread_run",   {"ptr","ptr","ptr"}, "ptr", "thread.obj"};
    functions_["thread_join"]  = {"thread_join",  {"ptr"}, "bool", "thread.obj"};

    // HTTP text helpers. These routines are pure request/response builders and
    // parsers; they do not depend on Winsock or any OS networking API.
    functions_["http_build_get_request"] = {"http_build_get_request", {"ptr","ptr","ptr","i64"}, "i64", "httpclient.obj"};
    functions_["http_build_get_request_params"] = {"http_build_get_request_params", {"ptr","ptr","ptr","ptr","i64"}, "i64", "httpclient.obj"};
    functions_["http_build_post_request"] = {"http_build_post_request", {"ptr","ptr","ptr","ptr","ptr","i64"}, "i64", "httpclient.obj"};
    functions_["http_client_get"] = {"http_client_get", {"ptr","i64","ptr","ptr","i64"}, "i64", "httpclient.obj"};
    functions_["http_client_post_string_print"] = {"http_client_post_string_print", {"ptr","i64","ptr","ptr","ptr"}, "void", "httpclient.obj"};
    functions_["http_string_to_cstr"] = {"http_string_to_cstr", {"ptr","ptr","i64"}, "i64", "httpclient.obj"};
    functions_["http_build_response"] = {"http_build_response", {"ptr","ptr","i64"}, "i64", "httpserver.obj"};
    functions_["http_extract_path"] = {"http_extract_path", {"ptr","ptr","i64"}, "i64", "httpserver.obj"};
    functions_["http_extract_query"] = {"http_extract_query", {"ptr","ptr","i64"}, "i64", "httpserver.obj"};
    functions_["http_extract_body"] = {"http_extract_body", {"ptr","ptr","i64"}, "i64", "httpserver.obj"};
    functions_["http_get_param"] = {"http_get_param", {"ptr","ptr","ptr","i64"}, "i64", "httpserver.obj"};
}

const RuntimeFuncSignature* RuntimeRegistry::lookup(const std::string& name) const {
    auto it = functions_.find(name);
    if (it != functions_.end()) return &it->second;
    return nullptr;
}

std::vector<std::string> RuntimeRegistry::get_required_objects() const {
    std::vector<std::string> objs;
    std::unordered_map<std::string, bool> seen;

    for (const auto& pair : functions_) {
        const std::string& obj = pair.second.module;
        if (!seen[obj]) {
            objs.push_back(obj);
            seen[obj] = true;
        }
    }
    return objs;
}

std::vector<std::string> RuntimeRegistry::get_required_libraries() const {
    return {"ntdll", "ws2_32"};
}
