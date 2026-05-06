#pragma once

#include "IR.h"

#include <string>
#include <unordered_map>
#include <vector>
#include <sstream>

class CodeGenerator {
public:
    std::string generate(const IRModule& module);

private:
    void emit_data_section(const IRModule& module);
    void emit_text_section(const IRModule& module);
    void emit_function(const IRFunction& func);
    void emit_block(const IRBasicBlock& block);
    void emit_instruction(const IRInstruction& inst);

    std::string reg_for_type(const IRType& type);
    std::string reg_for_param(std::size_t index);
    std::string var_location(const std::string& name);
    void assign_location(const std::string& name, const IRType& type);
    void emit_move_to_reg(const std::string& value, const std::string& reg, const IRType& type);
    void emit_address_to_reg(const std::string& value, const std::string& reg);
    void emit_move_from_reg(const std::string& reg, const std::string& dest, const IRType& type);

    std::string mangle_symbol(const std::string& name);

    std::ostringstream output_;
    std::unordered_map<std::string, std::string> var_locations_;
    std::unordered_map<std::string, IRType> var_types_;
    int local_var_offset_;
    std::vector<std::string> saved_regs_;
    std::string current_function_name_;
};
