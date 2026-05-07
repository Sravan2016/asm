#pragma once

#include "SemanticAnalyser.h"
#include "parser.h"

#include <cstdint>
#include <memory>
#include <string>
#include <vector>
#include <unordered_map>

enum class IRTypeKind {
    Void,
    Integer,    // i32
    Long,       // i64
    Double,     // f64
    Boolean,    // bool/i8
    Pointer,    // ptr/i64
    Array,      // array<T>
    String      // string (ptr)
};

struct IRType {
    IRTypeKind kind;
    std::shared_ptr<IRType> element_type;
    bool is_file_backed = false;

    static IRType makeVoid() { return {IRTypeKind::Void, nullptr, false}; }
    static IRType makeInteger(bool is_file_backed = false) { return {IRTypeKind::Integer, nullptr, is_file_backed}; }
    static IRType makeLong(bool is_file_backed = false) { return {IRTypeKind::Long, nullptr, is_file_backed}; }
    static IRType makeDouble(bool is_file_backed = false) { return {IRTypeKind::Double, nullptr, is_file_backed}; }
    static IRType makeBoolean(bool is_file_backed = false) { return {IRTypeKind::Boolean, nullptr, is_file_backed}; }
    static IRType makePointer(bool is_file_backed = false) { return {IRTypeKind::Pointer, nullptr, is_file_backed}; }
    static IRType makeString(bool is_file_backed = false) { return {IRTypeKind::String, nullptr, is_file_backed}; }
    static IRType makeArray(IRType element, bool is_file_backed = false) { return {IRTypeKind::Array, std::make_shared<IRType>(element), is_file_backed}; }

    bool isIntegerFamily() const {
        return kind == IRTypeKind::Integer || kind == IRTypeKind::Long || kind == IRTypeKind::Boolean;
    }

    bool isNumeric() const {
        return kind == IRTypeKind::Integer || kind == IRTypeKind::Long || kind == IRTypeKind::Double;
    }

    std::string to_string() const;
    int size_bytes() const;
};

IRType semantic_to_ir_type(const SemanticType& type);

enum class IROpcode {
    // Constants
    ConstInt,
    ConstLong,
    ConstDouble,
    ConstBool,
    ConstPtr,

    // Arithmetic
    Add,
    Sub,
    Mul,
    Div,
    Mod,
    Neg,

    // Comparison
    EQ,
    NE,
    LT,
    LE,
    GT,
    GE,

    // Logical
    And,
    Or,
    Not,

    // Control Flow
    Label,
    Jmp,
    Branch,
    Ret,
    Call,

    // Memory
    Load,
    Store,
    Alloca,

    // Type Conversion
    ZExt,
    SExt,
    FPToUI,
    UIToFP,
    SIToFP,
    FPToSI,
    Trunc,

    // Array Operations
    ArrayNew,
    ArrayGet,
    ArraySet,
    ArrayLen,
    ArrayPush,

    // Method Call (runtime)
    CallRuntime
};

struct IRInstruction {
    IROpcode opcode;
    IRType type;
    std::string result;
    std::vector<std::string> operands;
    std::string label_name;
    std::string string_value;
    double double_value;
    int64_t int_value;

    static IRInstruction make_const_int(const std::string& dest, int64_t value) {
        IRInstruction inst;
        inst.opcode = IROpcode::ConstInt;
        inst.type = IRType::makeInteger();
        inst.result = dest;
        inst.int_value = value;
        return inst;
    }

    static IRInstruction make_const_long(const std::string& dest, int64_t value) {
        IRInstruction inst;
        inst.opcode = IROpcode::ConstLong;
        inst.type = IRType::makeLong();
        inst.result = dest;
        inst.int_value = value;
        return inst;
    }

    static IRInstruction make_const_double(const std::string& dest, double value) {
        IRInstruction inst;
        inst.opcode = IROpcode::ConstDouble;
        inst.type = IRType::makeDouble();
        inst.result = dest;
        inst.double_value = value;
        return inst;
    }

    static IRInstruction make_const_bool(const std::string& dest, bool value) {
        IRInstruction inst;
        inst.opcode = IROpcode::ConstBool;
        inst.type = IRType::makeBoolean();
        inst.result = dest;
        inst.int_value = value ? 1 : 0;
        return inst;
    }

    static IRInstruction make_label(const std::string& name) {
        IRInstruction inst;
        inst.opcode = IROpcode::Label;
        inst.type = IRType::makeVoid();
        inst.label_name = name;
        return inst;
    }

    static IRInstruction make_load(const std::string& dest, const std::string& src, IRType type) {
        IRInstruction inst;
        inst.opcode = IROpcode::Load;
        inst.type = type;
        inst.result = dest;
        inst.operands = {src};
        return inst;
    }

    static IRInstruction make_store(const std::string& src, const std::string& dest) {
        IRInstruction inst;
        inst.opcode = IROpcode::Store;
        inst.type = IRType::makeVoid();
        inst.operands = {src, dest};
        return inst;
    }

    static IRInstruction make_alloca(const std::string& dest, IRType type) {
        IRInstruction inst;
        inst.opcode = IROpcode::Alloca;
        inst.type = type;
        inst.result = dest;
        return inst;
    }

    std::string to_string() const;
};

struct IRBasicBlock {
    std::string name;
    std::vector<IRInstruction> instructions;
    std::vector<std::string> predecessors;
    std::vector<std::string> successors;

    bool is_terminated() const;
    void add_instruction(const IRInstruction& inst);
};

struct IRParameter {
    std::string name;
    IRType type;
};

struct IRFunction {
    std::string name;
    IRType return_type;
    std::vector<IRParameter> parameters;
    std::vector<IRBasicBlock> blocks;
    std::unordered_map<std::string, IRType> local_variables;
    std::vector<std::string> string_constants;

    IRBasicBlock& entry_block();
    IRBasicBlock& add_block(const std::string& name);
    IRBasicBlock* find_block(const std::string& name);
    IRBasicBlock* current_block();
    void set_current_block(std::size_t index);

private:
    std::size_t current_block_index_ = 0;
};

struct IRGlobal {
    std::string name;
    IRType type;
};

struct IRModule {
    std::vector<IRFunction> functions;
    std::vector<IRGlobal> globals;
    std::vector<std::string> string_constants;
    std::vector<std::string> external_symbols;

    IRFunction& add_function(const std::string& name, IRType return_type, const std::vector<IRParameter>& params);
    IRFunction* find_function(const std::string& name);
    void add_global(const std::string& name, IRType type);
    void add_external_symbol(const std::string& name);
    void add_string_constant(const std::string& name, const std::string& value);

    void dump() const;
};
