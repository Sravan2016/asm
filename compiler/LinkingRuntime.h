#pragma once

#include "IR.h"

#include <cstdint>
#include <functional>
#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

// ============================================================================
// System V AMD64 ABI Register Definitions (Intel / Linux / macOS)
// ============================================================================
//
// Parameter registers (in order): RDI, RSI, RDX, RCX, R8, R9
// Return registers:               RAX (integer), XMM0 (floating-point)
// Callee-saved:                   RBX, RBP, R12, R13, R14, R15
// Caller-saved:                   RAX, RCX, RDX, RSI, RDI, R8-R11
// Shadow space:                   NONE (unlike Windows x64)
// Red zone:                       128 bytes below RSP (leaf functions)
// Stack alignment:                16 bytes before CALL instruction
//
// ============================================================================

enum class ABIKind {
    SystemV_AMD64,    // Linux, macOS, BSD (Intel syntax)
    Windows_x64       // Windows MSVC
};

// ============================================================================
// LinkingRuntime - Manages the full pipeline: IR -> Assembly -> Object -> Executable
// ============================================================================

class LinkingRuntime {
public:
    explicit LinkingRuntime(ABIKind abi = ABIKind::SystemV_AMD64);

    // --- Assembly Generation (IR -> Intel-syntax .s) ---
    std::string generate_assembly(const IRModule& module, bool emit_entry_point = true);

    // --- Object File Linking ---
    // Assemble .s -> .obj using NASM
    bool assemble_to_object(const std::string& source_s_path, const std::string& output_obj_path);

    // Link .obj + runtime .obj -> .exe
    bool link_executable(const std::string& input_obj_path,
                         const std::string& output_exe_path,
                         const std::string& runtime_dir = "",
                         const std::vector<std::string>& extra_objects = {},
                         const std::vector<std::string>& extra_libraries = {});

    // Full pipeline: IR -> .s -> .obj -> .exe
    bool build_executable(const IRModule& module,
                          const std::string& output_exe_path,
                          const std::string& runtime_dir = "");

    // --- Runtime Initialization ---
    // Returns the assembly preamble for runtime initialization
    std::string generate_runtime_init();

    // --- Runtime Function Calls ---
    // Generate assembly for calling a runtime function with given args
    std::string generate_runtime_call(const std::string& func_name,
                                       const std::vector<std::string>& args,
                                       const std::string& result_reg = "rax");

    // --- Object Layout Constants ---
    static constexpr std::size_t STRING_HEADER_SIZE = 16;
    static constexpr std::size_t ARRAY_HEADER_SIZE  = 32;
    static constexpr std::size_t MAP_HEADER_SIZE    = 40;
    static constexpr std::size_t PRIMITIVE_HEADER   = 16;

    // --- Configuration ---
    void set_nasm_path(const std::string& path);
    void set_gcc_path(const std::string& path);
    void set_runtime_dir(const std::string& dir);

    ABIKind get_abi() const { return abi_; }

private:
    // --- Assembly Emission (System V AMD64 ABI) ---
    void emit_data_section(const IRModule& module, std::ostringstream& out);
    void emit_bss_section(const IRModule& module, std::ostringstream& out);
    void emit_text_section(const IRModule& module, std::ostringstream& out, bool emit_entry_point);
    void emit_function_sysv(const IRFunction& func, std::ostringstream& out);
    void emit_instruction_sysv(const IRInstruction& inst,
                               const std::string& func_name,
                               std::ostringstream& out);

    // --- Register Helpers (System V) ---
    const char* param_reg_sysv(std::size_t index);     // rdi, rsi, rdx, rcx, r8, r9
    const char* callee_saved_reg(std::size_t index);   // rbx, r12, r13, r14, r15
    void emit_move_to_reg_sysv(const std::string& value,
                               const std::string& reg,
                               const IRType& type,
                               std::ostringstream& out);

    // --- Variable Tracking ---
    struct VarInfo {
        int offset;            // Stack offset from RBP (negative = below)
        IRType type;
        bool is_param;
    };

    std::unordered_map<std::string, VarInfo> var_map_;
    int stack_offset_;
    int func_stack_size_;
    std::string current_func_;
    std::vector<std::string> module_string_constants_;

    // --- Build Pipeline ---
    std::string nasm_path_;
    std::string gcc_path_;
    std::string runtime_dir_;
    ABIKind abi_;
};

// ============================================================================
// Runtime Function Registry - Maps bada runtime functions to signatures
// ============================================================================

struct RuntimeFuncSignature {
    std::string name;
    std::vector<std::string> param_types;  // "ptr", "i64", "i32", "f64", "bool"
    std::string return_type;               // "void", "ptr", "i64", "i32", "f64", "bool"
    std::string module;                    // Which .obj file provides this
};

class RuntimeRegistry {
public:
    static const RuntimeRegistry& instance();

    const RuntimeFuncSignature* lookup(const std::string& name) const;
    std::vector<std::string> get_required_objects() const;
    std::vector<std::string> get_required_libraries() const;

private:
    RuntimeRegistry();
    std::unordered_map<std::string, RuntimeFuncSignature> functions_;
};
