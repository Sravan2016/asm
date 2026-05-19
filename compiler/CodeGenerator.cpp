#include "CodeGenerator.h"

#include <algorithm>
#include <cstring>

std::string CodeGenerator::generate(const IRModule& module, bool emit_entry_point) {
    output_.str("");
    output_.clear();

    emit_data_section(module);
    emit_text_section(module, emit_entry_point);

    return output_.str();
}

void CodeGenerator::emit_data_section(const IRModule& module) {
    output_ << "section .data" << std::endl;

    // Emit string constants as objects (ptr + length struct)
    for (const auto& entry : module.string_constants) {
        auto pos = entry.find(':');
        if (pos == std::string::npos) continue;
        std::string name = entry.substr(0, pos);
        std::string value = entry.substr(pos + 1);
        output_ << "    " << name << "_data db '" << value << "', 0" << std::endl;
        output_ << "    " << name << " dq " << name << "_data, " << value.size() << std::endl;
    }

    output_ << std::endl;
    output_ << "section .bss" << std::endl;
    output_ << std::endl;
}

void CodeGenerator::emit_text_section(const IRModule& module, bool emit_entry_point) {
    output_ << "section .text" << std::endl;

    // External symbols
    std::vector<std::string> runtime_funcs = {
        "print_cstr", "print_string", "print_uint",
        "string_equals", "string_concat", "string_copy", "string_free",
        "string_from_cstr",
        "int_add", "int_sub", "int_mul", "int_div", "int_mod",
        "int_eq", "int_lt", "int_gt",
        "array_create", "array_add", "array_find", "array_remove",
        "array_size", "array_get", "array_free",
        "array_filter", "array_sort", "array_map", "array_join",
        "map_init", "map_create", "map_put", "map_get",
        "map_contains_key", "map_remove", "map_size", "map_clear", "map_free",
        "http_build_get_request", "http_build_get_request_params", "http_build_post_request",
        "http_client_get", "http_client_post_string_print", "http_build_response", "http_extract_path",
        "http_extract_query", "http_extract_body", "http_get_param",
        "malloc", "free", "realloc",
        "fileint_get", "fileint_set",
        "print"
    };

    for (const auto& func : runtime_funcs) {
        output_ << "    extern " << func << std::endl;
    }
    for (const auto& sym : module.external_symbols) {
        output_ << "    extern " << sym << std::endl;
    }
    output_ << std::endl;

    if (emit_entry_point) {
        output_ << "    global main" << std::endl;
        output_ << std::endl;
    }

    // Emit each function
    for (const auto& func : module.functions) {
        emit_function(func);
    }

    if (emit_entry_point) {
        // Main entry point
        output_ << "main:" << std::endl;
        output_ << "    push rbp" << std::endl;
        output_ << "    mov rbp, rsp" << std::endl;

        const IRFunction* entry = nullptr;
        for (const auto& func : module.functions) {
            const std::string suffix = "_main";
            if (func.name.size() >= suffix.size() &&
                func.name.compare(func.name.size() - suffix.size(), suffix.size(), suffix) == 0) {
                entry = &func;
                break;
            }
        }

        if (entry) {
            output_ << "    mov rdi, 0" << std::endl;  // this pointer
            output_ << "    call " << entry->name << std::endl;
        }

        output_ << "    mov rax, 0" << std::endl;
        output_ << "    leave" << std::endl;
        output_ << "    ret" << std::endl;
        output_ << std::endl;
    }
}

void CodeGenerator::emit_function(const IRFunction& func) {
    current_function_name_ = func.name;
    output_ << func.name << ":" << std::endl;

    // Prologue
    output_ << "    push rbp" << std::endl;
    output_ << "    mov rbp, rsp" << std::endl;

    // Setup local variables
    var_locations_.clear();
    var_types_.clear();
    local_var_offset_ = 8;  // Start after saved rbp

    // Save callee-saved registers
    output_ << "    push rbx" << std::endl;
    output_ << "    push r12" << std::endl;
    output_ << "    push r13" << std::endl;
    output_ << "    push r14" << std::endl;
    output_ << "    push r15" << std::endl;
    local_var_offset_ += 40;  // 5 registers * 8 bytes

    // Assign stack locations to parameters
    for (std::size_t i = 0; i < func.parameters.size(); ++i) {
        const auto& param = func.parameters[i];
        assign_location(param.name, param.type);

        if (i < 4) {
            std::string reg = reg_for_param(i);
            output_ << "    mov [rbp-" << var_locations_[param.name] << "], " << reg << std::endl;
        } else {
            const int stack_arg_offset = 48 + static_cast<int>((i - 4) * 8);
            output_ << "    mov rax, [rbp+" << stack_arg_offset << "]" << std::endl;
            output_ << "    mov [rbp-" << var_locations_[param.name] << "], rax" << std::endl;
        }
    }

    // Emit blocks
    for (const auto& block : func.blocks) {
        emit_block(block);
    }

    // Epilogue (only if function doesn't already end with ret)
    bool ends_with_ret = false;
    if (!func.blocks.empty()) {
        const auto& last_block = func.blocks.back();
        if (!last_block.instructions.empty()) {
            ends_with_ret = last_block.instructions.back().opcode == IROpcode::Ret;
        }
    }

    if (ends_with_ret) {
        return;
    }

    output_ << "    mov rax, 0" << std::endl;
    output_ << "    pop r15" << std::endl;
    output_ << "    pop r14" << std::endl;
    output_ << "    pop r13" << std::endl;
    output_ << "    pop r12" << std::endl;
    output_ << "    pop rbx" << std::endl;
    output_ << "    leave" << std::endl;
    output_ << "    ret" << std::endl;
    output_ << std::endl;
}

void CodeGenerator::emit_block(const IRBasicBlock& block) {
    output_ << current_function_name_ << "_" << block.name << ":" << std::endl;

    for (const auto& inst : block.instructions) {
        emit_instruction(inst);
    }
}

void CodeGenerator::emit_instruction(const IRInstruction& inst) {
    std::string reg = "rax";
    std::string reg2 = "rbx";
    std::string reg3 = "rcx";

    switch (inst.opcode) {
        case IROpcode::ConstInt:
            output_ << "    mov " << reg << ", " << inst.int_value << std::endl;
            var_locations_[inst.result] = std::to_string(local_var_offset_);
            var_types_[inst.result] = IRType::makeInteger();
            output_ << "    mov [rbp-" << var_locations_[inst.result] << "], " << reg << std::endl;
            local_var_offset_ += 8;
            break;

        case IROpcode::ConstLong:
            output_ << "    mov " << reg << ", " << inst.int_value << std::endl;
            var_locations_[inst.result] = std::to_string(local_var_offset_);
            var_types_[inst.result] = IRType::makeLong();
            output_ << "    mov [rbp-" << var_locations_[inst.result] << "], " << reg << std::endl;
            local_var_offset_ += 8;
            break;

        case IROpcode::ConstDouble:
        {
            uint64_t bits = 0;
            static_assert(sizeof(bits) == sizeof(inst.double_value), "double size mismatch");
            std::memcpy(&bits, &inst.double_value, sizeof(bits));
            output_ << "    mov rax, " << bits << std::endl;
            var_locations_[inst.result] = std::to_string(local_var_offset_);
            var_types_[inst.result] = IRType::makeDouble();
            output_ << "    mov [rbp-" << var_locations_[inst.result] << "], rax" << std::endl;
            local_var_offset_ += 8;
            break;
        }

        case IROpcode::ConstBool:
            output_ << "    mov " << reg << ", " << (inst.int_value ? 1 : 0) << std::endl;
            var_locations_[inst.result] = std::to_string(local_var_offset_);
            var_types_[inst.result] = IRType::makeBoolean();
            output_ << "    mov [rbp-" << var_locations_[inst.result] << "], " << reg << std::endl;
            local_var_offset_ += 8;
            break;

        case IROpcode::ConstPtr:
            if (!inst.string_value.empty()) {
                output_ << "    lea " << reg << ", [rel " << inst.string_value << "]" << std::endl;
            } else {
                output_ << "    xor " << reg << ", " << reg << std::endl;
            }
            var_locations_[inst.result] = std::to_string(local_var_offset_);
            var_types_[inst.result] = IRType::makePointer();
            output_ << "    mov [rbp-" << var_locations_[inst.result] << "], " << reg << std::endl;
            local_var_offset_ += 8;
            break;

        case IROpcode::Add:
            if (inst.type.kind == IRTypeKind::String || inst.type.kind == IRTypeKind::Pointer) {
                output_ << "    sub rsp, 32" << std::endl;
                emit_move_to_reg(inst.operands[0], "rcx", inst.type);
                emit_move_to_reg(inst.operands[1], "rdx", inst.type);
                output_ << "    call string_concat" << std::endl;
                output_ << "    add rsp, 32" << std::endl;
                var_locations_[inst.result] = std::to_string(local_var_offset_);
                var_types_[inst.result] = inst.type;
                output_ << "    mov [rbp-" << var_locations_[inst.result] << "], rax" << std::endl;
                local_var_offset_ += 8;
            } else {
                emit_move_to_reg(inst.operands[0], reg, inst.type);
                emit_move_to_reg(inst.operands[1], reg2, inst.type);
                output_ << "    add " << reg << ", " << reg2 << std::endl;
                var_locations_[inst.result] = std::to_string(local_var_offset_);
                var_types_[inst.result] = inst.type;
                output_ << "    mov [rbp-" << var_locations_[inst.result] << "], " << reg << std::endl;
                local_var_offset_ += 8;
            }
            break;

        case IROpcode::Sub:
            emit_move_to_reg(inst.operands[0], reg, inst.type);
            emit_move_to_reg(inst.operands[1], reg2, inst.type);
            output_ << "    sub " << reg << ", " << reg2 << std::endl;
            var_locations_[inst.result] = std::to_string(local_var_offset_);
            var_types_[inst.result] = inst.type;
            output_ << "    mov [rbp-" << var_locations_[inst.result] << "], " << reg << std::endl;
            local_var_offset_ += 8;
            break;

        case IROpcode::Mul:
            emit_move_to_reg(inst.operands[0], reg, inst.type);
            emit_move_to_reg(inst.operands[1], reg2, inst.type);
            output_ << "    imul " << reg << ", " << reg2 << std::endl;
            var_locations_[inst.result] = std::to_string(local_var_offset_);
            var_types_[inst.result] = inst.type;
            output_ << "    mov [rbp-" << var_locations_[inst.result] << "], " << reg << std::endl;
            local_var_offset_ += 8;
            break;

        case IROpcode::Div:
            emit_move_to_reg(inst.operands[0], "rax", inst.type);
            emit_move_to_reg(inst.operands[1], reg2, inst.type);
            output_ << "    cqo" << std::endl;
            output_ << "    idiv " << reg2 << std::endl;
            var_locations_[inst.result] = std::to_string(local_var_offset_);
            var_types_[inst.result] = inst.type;
            output_ << "    mov [rbp-" << var_locations_[inst.result] << "], rax" << std::endl;
            local_var_offset_ += 8;
            break;

        case IROpcode::Mod:
            emit_move_to_reg(inst.operands[0], "rax", inst.type);
            emit_move_to_reg(inst.operands[1], reg2, inst.type);
            output_ << "    cqo" << std::endl;
            output_ << "    idiv " << reg2 << std::endl;
            var_locations_[inst.result] = std::to_string(local_var_offset_);
            var_types_[inst.result] = inst.type;
            output_ << "    mov [rbp-" << var_locations_[inst.result] << "], rdx" << std::endl;
            local_var_offset_ += 8;
            break;

        case IROpcode::EQ:
            emit_move_to_reg(inst.operands[0], reg, inst.type);
            emit_move_to_reg(inst.operands[1], reg2, inst.type);
            output_ << "    cmp " << reg << ", " << reg2 << std::endl;
            output_ << "    sete al" << std::endl;
            output_ << "    movzx " << reg << ", al" << std::endl;
            var_locations_[inst.result] = std::to_string(local_var_offset_);
            var_types_[inst.result] = IRType::makeBoolean();
            output_ << "    mov [rbp-" << var_locations_[inst.result] << "], " << reg << std::endl;
            local_var_offset_ += 8;
            break;

        case IROpcode::NE:
            emit_move_to_reg(inst.operands[0], reg, inst.type);
            emit_move_to_reg(inst.operands[1], reg2, inst.type);
            output_ << "    cmp " << reg << ", " << reg2 << std::endl;
            output_ << "    setne al" << std::endl;
            output_ << "    movzx " << reg << ", al" << std::endl;
            var_locations_[inst.result] = std::to_string(local_var_offset_);
            var_types_[inst.result] = IRType::makeBoolean();
            output_ << "    mov [rbp-" << var_locations_[inst.result] << "], " << reg << std::endl;
            local_var_offset_ += 8;
            break;

        case IROpcode::LT:
            emit_move_to_reg(inst.operands[0], reg, inst.type);
            emit_move_to_reg(inst.operands[1], reg2, inst.type);
            output_ << "    cmp " << reg << ", " << reg2 << std::endl;
            output_ << "    setl al" << std::endl;
            output_ << "    movzx " << reg << ", al" << std::endl;
            var_locations_[inst.result] = std::to_string(local_var_offset_);
            var_types_[inst.result] = IRType::makeBoolean();
            output_ << "    mov [rbp-" << var_locations_[inst.result] << "], " << reg << std::endl;
            local_var_offset_ += 8;
            break;

        case IROpcode::GT:
            emit_move_to_reg(inst.operands[0], reg, inst.type);
            emit_move_to_reg(inst.operands[1], reg2, inst.type);
            output_ << "    cmp " << reg << ", " << reg2 << std::endl;
            output_ << "    setg al" << std::endl;
            output_ << "    movzx " << reg << ", al" << std::endl;
            var_locations_[inst.result] = std::to_string(local_var_offset_);
            var_types_[inst.result] = IRType::makeBoolean();
            output_ << "    mov [rbp-" << var_locations_[inst.result] << "], " << reg << std::endl;
            local_var_offset_ += 8;
            break;

        case IROpcode::LE:
            emit_move_to_reg(inst.operands[0], reg, inst.type);
            emit_move_to_reg(inst.operands[1], reg2, inst.type);
            output_ << "    cmp " << reg << ", " << reg2 << std::endl;
            output_ << "    setle al" << std::endl;
            output_ << "    movzx " << reg << ", al" << std::endl;
            var_locations_[inst.result] = std::to_string(local_var_offset_);
            var_types_[inst.result] = IRType::makeBoolean();
            output_ << "    mov [rbp-" << var_locations_[inst.result] << "], " << reg << std::endl;
            local_var_offset_ += 8;
            break;

        case IROpcode::GE:
            emit_move_to_reg(inst.operands[0], reg, inst.type);
            emit_move_to_reg(inst.operands[1], reg2, inst.type);
            output_ << "    cmp " << reg << ", " << reg2 << std::endl;
            output_ << "    setge al" << std::endl;
            output_ << "    movzx " << reg << ", al" << std::endl;
            var_locations_[inst.result] = std::to_string(local_var_offset_);
            var_types_[inst.result] = IRType::makeBoolean();
            output_ << "    mov [rbp-" << var_locations_[inst.result] << "], " << reg << std::endl;
            local_var_offset_ += 8;
            break;

        case IROpcode::And:
            emit_move_to_reg(inst.operands[0], reg, inst.type);
            emit_move_to_reg(inst.operands[1], reg2, inst.type);
            output_ << "    and " << reg << ", " << reg2 << std::endl;
            var_locations_[inst.result] = std::to_string(local_var_offset_);
            var_types_[inst.result] = inst.type;
            output_ << "    mov [rbp-" << var_locations_[inst.result] << "], " << reg << std::endl;
            local_var_offset_ += 8;
            break;

        case IROpcode::Or:
            emit_move_to_reg(inst.operands[0], reg, inst.type);
            emit_move_to_reg(inst.operands[1], reg2, inst.type);
            output_ << "    or " << reg << ", " << reg2 << std::endl;
            var_locations_[inst.result] = std::to_string(local_var_offset_);
            var_types_[inst.result] = inst.type;
            output_ << "    mov [rbp-" << var_locations_[inst.result] << "], " << reg << std::endl;
            local_var_offset_ += 8;
            break;

        case IROpcode::Not:
            emit_move_to_reg(inst.operands[0], reg, inst.type);
            output_ << "    xor " << reg << ", 1" << std::endl;
            var_locations_[inst.result] = std::to_string(local_var_offset_);
            var_types_[inst.result] = inst.type;
            output_ << "    mov [rbp-" << var_locations_[inst.result] << "], " << reg << std::endl;
            local_var_offset_ += 8;
            break;

        case IROpcode::Load: {
            std::string addr = var_locations_[inst.operands[0]];
            if (addr.empty()) {
                // It's a parameter or direct reference
                addr = var_locations_[inst.operands[0]];
            }
            var_locations_[inst.result] = std::to_string(local_var_offset_);
            var_types_[inst.result] = inst.type;
            output_ << "    mov " << reg << ", [rbp-" << addr << "]" << std::endl;
            output_ << "    mov [rbp-" << var_locations_[inst.result] << "], " << reg << std::endl;
            local_var_offset_ += 8;
            break;
        }

        case IROpcode::Store: {
            emit_move_to_reg(inst.operands[0], reg, inst.type);
            std::string addr = var_locations_[inst.operands[1]];
            output_ << "    mov [rbp-" << addr << "], " << reg << std::endl;
            break;
        }

        case IROpcode::Alloca:
            var_locations_[inst.result] = std::to_string(local_var_offset_);
            var_types_[inst.result] = inst.type;
            local_var_offset_ += 8;
            break;

        case IROpcode::Label:
            output_ << current_function_name_ << "_" << inst.label_name << ":" << std::endl;
            break;

        case IROpcode::Jmp:
            output_ << "    jmp " << current_function_name_ << "_" << inst.label_name << std::endl;
            break;

        case IROpcode::Branch: {
            emit_move_to_reg(inst.operands[0], reg, IRType::makeBoolean());
            output_ << "    test " << reg << ", " << reg << std::endl;
            output_ << "    jne " << current_function_name_ << "_" << inst.operands[1] << std::endl;
            output_ << "    jmp " << current_function_name_ << "_" << inst.operands[2] << std::endl;
            break;
        }

        case IROpcode::Ret:
            if (!inst.operands.empty()) {
                emit_move_to_reg(inst.operands[0], "rax", inst.type);
            } else {
                output_ << "    xor rax, rax" << std::endl;
            }
            // Restore callee-saved registers
            output_ << "    pop r15" << std::endl;
            output_ << "    pop r14" << std::endl;
            output_ << "    pop r13" << std::endl;
            output_ << "    pop r12" << std::endl;
            output_ << "    pop rbx" << std::endl;
            output_ << "    leave" << std::endl;
            output_ << "    ret" << std::endl;
            break;

        case IROpcode::Call:
        case IROpcode::CallRuntime: {
            std::string func_name = inst.operands[0];

            const std::size_t num_args = inst.operands.size() > 0 ? inst.operands.size() - 1 : 0;
            const std::size_t stack_arg_count = num_args > 4 ? num_args - 4 : 0;
            std::size_t call_frame_size = 32 + stack_arg_count * 8;
            if ((call_frame_size % 16) != 0) {
                call_frame_size += 8;
            }

            // Allocate shadow space and any stack arguments (Windows x64 ABI)
            output_ << "    sub rsp, " << call_frame_size << std::endl;

            for (std::size_t i = num_args; i > 4; --i) {
                const std::size_t stack_index = i - 5;
                if (!inst.operands[i].empty() && inst.operands[i][0] == '&') {
                    emit_address_to_reg(inst.operands[i], "rax");
                } else {
                    emit_move_to_reg(inst.operands[i], "rax", IRType::makePointer());
                }
                output_ << "    mov [rsp+" << (32 + stack_index * 8) << "], rax" << std::endl;
            }

            // Move arguments to registers
            for (std::size_t i = 1; i < inst.operands.size() && i <= 4; ++i) {
                std::string target_reg = reg_for_param(i - 1);
                if (!inst.operands[i].empty() && inst.operands[i][0] == '&') {
                    emit_address_to_reg(inst.operands[i], target_reg);
                } else {
                    emit_move_to_reg(inst.operands[i], target_reg, IRType::makePointer());
                }
            }

            output_ << "    call " << func_name << std::endl;

            // Deallocate shadow space
            output_ << "    add rsp, " << call_frame_size << std::endl;

            if (!inst.result.empty()) {
                var_locations_[inst.result] = std::to_string(local_var_offset_);
                var_types_[inst.result] = inst.type;
                output_ << "    mov [rbp-" << var_locations_[inst.result] << "], rax" << std::endl;
                local_var_offset_ += 8;
            }
            break;
        }

        case IROpcode::ArrayNew:
            output_ << "    sub rsp, 32" << std::endl;
            if (inst.operands.empty()) {
                output_ << "    mov rcx, 4" << std::endl;
            } else {
                emit_move_to_reg(inst.operands[0], "rcx", IRType::makeInteger());
            }
            output_ << "    mov rdx, 8" << std::endl;  // element size
            output_ << "    call array_create" << std::endl;
            output_ << "    add rsp, 32" << std::endl;
            if (!inst.result.empty()) {
                var_locations_[inst.result] = std::to_string(local_var_offset_);
                var_types_[inst.result] = IRType::makePointer();
                output_ << "    mov [rbp-" << var_locations_[inst.result] << "], rax" << std::endl;
                local_var_offset_ += 8;
            }
            break;

        case IROpcode::ArrayGet:
            output_ << "    sub rsp, 32" << std::endl;
            emit_move_to_reg(inst.operands[0], "rcx", IRType::makePointer());
            emit_move_to_reg(inst.operands[1], "rdx", IRType::makeInteger());
            output_ << "    call array_get" << std::endl;
            output_ << "    add rsp, 32" << std::endl;
            if (!inst.result.empty()) {
                var_locations_[inst.result] = std::to_string(local_var_offset_);
                var_types_[inst.result] = IRType::makePointer();
                output_ << "    mov [rbp-" << var_locations_[inst.result] << "], rax" << std::endl;
                local_var_offset_ += 8;
            }
            break;

        case IROpcode::ArraySet:
            output_ << "    sub rsp, 32" << std::endl;
            emit_move_to_reg(inst.operands[0], "rcx", IRType::makePointer());
            emit_address_to_reg(inst.operands[2], "rdx");
            output_ << "    call array_add" << std::endl;
            output_ << "    add rsp, 32" << std::endl;
            break;

        case IROpcode::ArrayLen:
            output_ << "    sub rsp, 32" << std::endl;
            emit_move_to_reg(inst.operands[0], "rcx", IRType::makePointer());
            output_ << "    call array_size" << std::endl;
            output_ << "    add rsp, 32" << std::endl;
            if (!inst.result.empty()) {
                var_locations_[inst.result] = std::to_string(local_var_offset_);
                var_types_[inst.result] = IRType::makeInteger();
                output_ << "    mov [rbp-" << var_locations_[inst.result] << "], rax" << std::endl;
                local_var_offset_ += 8;
            }
            break;

        case IROpcode::ArrayPush:
            output_ << "    sub rsp, 32" << std::endl;
            emit_move_to_reg(inst.operands[0], "rcx", IRType::makePointer());
            emit_address_to_reg(inst.operands[1], "rdx");
            output_ << "    call array_add" << std::endl;
            output_ << "    add rsp, 32" << std::endl;
            break;

        default:
            output_ << "    ; unknown instruction" << std::endl;
            break;
    }
}

std::string CodeGenerator::reg_for_type(const IRType& type) {
    switch (type.kind) {
        case IRTypeKind::Boolean: return "al";
        default: return "rax";
    }
}

std::string CodeGenerator::reg_for_param(std::size_t index) {
    const char* regs[] = {"rcx", "rdx", "r8", "r9"};
    if (index < 4) return regs[index];
    return "rax";
}

std::string CodeGenerator::var_location(const std::string& name) {
    auto it = var_locations_.find(name);
    if (it != var_locations_.end()) return it->second;
    return "0";
}

void CodeGenerator::assign_location(const std::string& name, const IRType& type) {
    var_locations_[name] = std::to_string(local_var_offset_);
    var_types_[name] = type;
    local_var_offset_ += 8;
}

void CodeGenerator::emit_move_to_reg(const std::string& value, const std::string& reg, const IRType& type) {
    // Check if it's a constant number
    try {
        int64_t num = std::stoll(value);
        output_ << "    mov " << reg << ", " << num << std::endl;
        return;
    } catch (...) {}

    // Check if it's a known variable with a stack location
    auto it = var_locations_.find(value);
    if (it != var_locations_.end()) {
        output_ << "    mov " << reg << ", [rbp-" << it->second << "]" << std::endl;
        return;
    }

    // Check if it's a string constant reference
    if (value.find("str_") == 0) {
        output_ << "    lea " << reg << ", [rel " << value << "]" << std::endl;
        return;
    }

    // Unresolved temporary (e.g. %0 from incomplete IR) - zero out the register
    output_ << "    xor " << reg << ", " << reg << std::endl;
}

void CodeGenerator::emit_address_to_reg(const std::string& value, const std::string& reg) {
    const std::string base_value = (!value.empty() && value[0] == '&') ? value.substr(1) : value;

    auto it = var_locations_.find(base_value);
    if (it != var_locations_.end()) {
        output_ << "    lea " << reg << ", [rbp-" << it->second << "]" << std::endl;
        return;
    }

    if (base_value.find("str_") == 0) {
        output_ << "    lea " << reg << ", [rel " << base_value << "]" << std::endl;
        return;
    }

    output_ << "    xor " << reg << ", " << reg << std::endl;
}

void CodeGenerator::emit_move_from_reg(const std::string& reg, const std::string& dest, const IRType& type) {
    auto it = var_locations_.find(dest);
    if (it != var_locations_.end()) {
        output_ << "    mov [rbp-" << it->second << "], " << reg << std::endl;
    }
}

std::string CodeGenerator::mangle_symbol(const std::string& name) {
    std::string result = name;
    std::replace(result.begin(), result.end(), '.', '_');
    return result;
}
