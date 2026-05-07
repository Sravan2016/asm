#include "IR.h"

#include <sstream>

std::string IRType::to_string() const {
    switch (kind) {
        case IRTypeKind::Void: return "void";
        case IRTypeKind::Integer: return is_file_backed ? "file<i32>" : "i32";
        case IRTypeKind::Long: return is_file_backed ? "file<i64>" : "i64";
        case IRTypeKind::Double: return is_file_backed ? "file<f64>" : "f64";
        case IRTypeKind::Boolean: return is_file_backed ? "file<bool>" : "bool";
        case IRTypeKind::Pointer: return "ptr";
        case IRTypeKind::String: return is_file_backed ? "file<string>" : "string";
        case IRTypeKind::Array:
            if (element_type) return "array<" + element_type->to_string() + ">";
            return "array";
    }
    return "unknown";
}

int IRType::size_bytes() const {
    switch (kind) {
        case IRTypeKind::Void: return 0;
        case IRTypeKind::Boolean: return is_file_backed ? 16 : 8;
        case IRTypeKind::Integer: return is_file_backed ? 16 : 8;
        case IRTypeKind::Long: return is_file_backed ? 16 : 8;
        case IRTypeKind::Double: return is_file_backed ? 16 : 8;
        case IRTypeKind::Pointer: return 8;
        case IRTypeKind::String: return 16;
        case IRTypeKind::Array: return 8;
    }
    return 8;
}

IRType semantic_to_ir_type(const SemanticType& type) {
    switch (type.kind) {
        case SemanticTypeKind::Void: return IRType::makeVoid();
        case SemanticTypeKind::Integer: return IRType::makeInteger(type.is_file_backed);
        case SemanticTypeKind::Long: return IRType::makeLong(type.is_file_backed);
        case SemanticTypeKind::Double: return IRType::makeDouble(type.is_file_backed);
        case SemanticTypeKind::Boolean: return IRType::makeBoolean(type.is_file_backed);
        case SemanticTypeKind::String: return IRType::makeString(type.is_file_backed);
        case SemanticTypeKind::Class: return IRType::makePointer(type.is_file_backed);
        case SemanticTypeKind::Array:
            if (type.element_type) {
                return IRType::makeArray(semantic_to_ir_type(*type.element_type), type.is_file_backed);
            }
            return IRType::makeArray(IRType::makePointer(), type.is_file_backed);
        case SemanticTypeKind::Unknown:
        case SemanticTypeKind::Error:
            return IRType::makePointer();
    }
    return IRType::makePointer();
}

std::string IRInstruction::to_string() const {
    std::ostringstream os;

    switch (opcode) {
        case IROpcode::ConstInt:
            os << "    " << result << " = const i32 " << int_value;
            break;
        case IROpcode::ConstLong:
            os << "    " << result << " = const i64 " << int_value;
            break;
        case IROpcode::ConstDouble: {
            std::ostringstream ds;
            ds << double_value;
            os << "    " << result << " = const f64 " << ds.str();
            break;
        }
        case IROpcode::ConstBool:
            os << "    " << result << " = const bool " << (int_value ? "true" : "false");
            break;
        case IROpcode::ConstPtr:
            os << "    " << result << " = const ptr " << (string_value.empty() ? "null" : string_value);
            break;
        case IROpcode::Add:
            os << "    " << result << " = add " << operands[0] << ", " << operands[1];
            break;
        case IROpcode::Sub:
            os << "    " << result << " = sub " << operands[0] << ", " << operands[1];
            break;
        case IROpcode::Mul:
            os << "    " << result << " = mul " << operands[0] << ", " << operands[1];
            break;
        case IROpcode::Div:
            os << "    " << result << " = div " << operands[0] << ", " << operands[1];
            break;
        case IROpcode::Mod:
            os << "    " << result << " = mod " << operands[0] << ", " << operands[1];
            break;
        case IROpcode::Neg:
            os << "    " << result << " = neg " << operands[0];
            break;
        case IROpcode::EQ:
            os << "    " << result << " = eq " << operands[0] << ", " << operands[1];
            break;
        case IROpcode::NE:
            os << "    " << result << " = ne " << operands[0] << ", " << operands[1];
            break;
        case IROpcode::LT:
            os << "    " << result << " = lt " << operands[0] << ", " << operands[1];
            break;
        case IROpcode::LE:
            os << "    " << result << " = le " << operands[0] << ", " << operands[1];
            break;
        case IROpcode::GT:
            os << "    " << result << " = gt " << operands[0] << ", " << operands[1];
            break;
        case IROpcode::GE:
            os << "    " << result << " = ge " << operands[0] << ", " << operands[1];
            break;
        case IROpcode::And:
            os << "    " << result << " = and " << operands[0] << ", " << operands[1];
            break;
        case IROpcode::Or:
            os << "    " << result << " = or " << operands[0] << ", " << operands[1];
            break;
        case IROpcode::Not:
            os << "    " << result << " = not " << operands[0];
            break;
        case IROpcode::Load:
            os << "    " << result << " = load " << operands[0];
            break;
        case IROpcode::Store:
            os << "    store " << operands[0] << ", " << operands[1];
            break;
        case IROpcode::Alloca:
            os << "    " << result << " = alloca " << type.to_string();
            break;
        case IROpcode::Label:
            os << label_name << ":";
            break;
        case IROpcode::Jmp:
            os << "    jmp " << label_name;
            break;
        case IROpcode::Branch:
            os << "    br " << operands[0] << ", " << (operands.size() > 1 ? operands[1] : "?") << ", " << (operands.size() > 2 ? operands[2] : "?");
            break;
        case IROpcode::Ret:
            if (operands.empty()) {
                os << "    ret";
            } else {
                os << "    ret " << operands[0];
            }
            break;
        case IROpcode::Call:
            if (!result.empty()) {
                os << "    " << result << " = call " << (operands.empty() ? "?" : operands[0]);
                for (std::size_t i = 1; i < operands.size(); ++i) {
                    os << ", " << operands[i];
                }
            } else {
                os << "    call " << (operands.empty() ? "?" : operands[0]);
                for (std::size_t i = 1; i < operands.size(); ++i) {
                    os << ", " << operands[i];
                }
            }
            break;
        case IROpcode::CallRuntime:
            if (!result.empty()) {
                os << "    " << result << " = call_runtime " << (operands.empty() ? "?" : operands[0]);
            } else {
                os << "    call_runtime " << (operands.empty() ? "?" : operands[0]);
            }
            break;
        case IROpcode::ArrayNew:
            os << "    " << result << " = array_new " << type.to_string() << ", " << operands[0];
            break;
        case IROpcode::ArrayGet:
            os << "    " << result << " = array_get " << operands[0] << ", " << operands[1];
            break;
        case IROpcode::ArraySet:
            os << "    array_set " << operands[0] << ", " << operands[1] << ", " << operands[2];
            break;
        case IROpcode::ArrayLen:
            os << "    " << result << " = array_len " << operands[0];
            break;
        case IROpcode::ArrayPush:
            os << "    array_push " << operands[0] << ", " << operands[1];
            break;
        case IROpcode::ZExt:
            os << "    " << result << " = zext " << operands[0] << " to " << type.to_string();
            break;
        case IROpcode::SExt:
            os << "    " << result << " = sext " << operands[0] << " to " << type.to_string();
            break;
        default:
            os << "    <unknown>";
            break;
    }

    return os.str();
}

bool IRBasicBlock::is_terminated() const {
    if (instructions.empty()) return false;
    const auto& last = instructions.back();
    return last.opcode == IROpcode::Ret || last.opcode == IROpcode::Jmp || last.opcode == IROpcode::Branch;
}

void IRBasicBlock::add_instruction(const IRInstruction& inst) {
    instructions.push_back(inst);
}

IRBasicBlock& IRFunction::entry_block() {
    if (blocks.empty()) {
        blocks.push_back({"entry", {}, {}, {}});
        current_block_index_ = 0;
    }
    return blocks.front();
}

IRBasicBlock& IRFunction::add_block(const std::string& name) {
    blocks.push_back({name, {}, {}, {}});
    return blocks.back();
}

IRBasicBlock* IRFunction::find_block(const std::string& name) {
    for (auto& block : blocks) {
        if (block.name == name) return &block;
    }
    return nullptr;
}

IRBasicBlock* IRFunction::current_block() {
    if (current_block_index_ >= blocks.size()) return nullptr;
    return &blocks[current_block_index_];
}

void IRFunction::set_current_block(std::size_t index) {
    current_block_index_ = index;
}

IRFunction& IRModule::add_function(const std::string& name, IRType return_type, const std::vector<IRParameter>& params) {
    IRFunction func;
    func.name = name;
    func.return_type = return_type;
    func.parameters = params;
    functions.push_back(std::move(func));
    return functions.back();
}

IRFunction* IRModule::find_function(const std::string& name) {
    for (auto& func : functions) {
        if (func.name == name) return &func;
    }
    return nullptr;
}

void IRModule::add_global(const std::string& name, IRType type) {
    for (const auto& global : globals) {
        if (global.name == name) return;
    }
    globals.push_back({name, type});
}

void IRModule::add_external_symbol(const std::string& name) {
    for (const auto& sym : external_symbols) {
        if (sym == name) return;
    }
    external_symbols.push_back(name);
}

void IRModule::add_string_constant(const std::string& name, const std::string& value) {
    string_constants.push_back(name + ":" + value);
}

void IRModule::dump() const {
    for (const auto& global : globals) {
        printf("global %s: %s\n", global.name.c_str(), global.type.to_string().c_str());
    }
    if (!globals.empty()) {
        printf("\n");
    }
    for (const auto& func : functions) {
        std::string ret = func.return_type.to_string();
        std::string params;
        for (std::size_t i = 0; i < func.parameters.size(); ++i) {
            if (i > 0) params += ", ";
            params += func.parameters[i].name + ": " + func.parameters[i].type.to_string();
        }
        printf("func %s(%s) -> %s {\n", func.name.c_str(), params.c_str(), ret.c_str());
        for (const auto& block : func.blocks) {
            printf("  %s:\n", block.name.c_str());
            for (const auto& inst : block.instructions) {
                printf("    %s\n", inst.to_string().c_str());
            }
        }
        printf("}\n\n");
    }
}
