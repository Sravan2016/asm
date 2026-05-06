#include "IRGenerator.h"

#include <functional>
#include <sstream>
#include <unordered_set>

namespace {

std::string file_create_runtime(const IRType& type) {
    switch (type.kind) {
        case IRTypeKind::Integer: return type.is_file_backed ? "fileint_create_auto" : "";
        case IRTypeKind::Long: return type.is_file_backed ? "filelong_create_auto" : "";
        case IRTypeKind::Double: return type.is_file_backed ? "filedouble_create_auto" : "";
        case IRTypeKind::Boolean: return type.is_file_backed ? "filebool_create_auto" : "";
        default: return "";
    }
}

std::string file_get_runtime(const IRType& type) {
    switch (type.kind) {
        case IRTypeKind::Integer: return type.is_file_backed ? "fileint_get" : "";
        case IRTypeKind::Long: return type.is_file_backed ? "filelong_get" : "";
        case IRTypeKind::Double: return type.is_file_backed ? "filedouble_get" : "";
        case IRTypeKind::Boolean: return type.is_file_backed ? "filebool_get" : "";
        default: return "";
    }
}

std::string file_set_runtime(const IRType& type) {
    switch (type.kind) {
        case IRTypeKind::Integer: return type.is_file_backed ? "fileint_set" : "";
        case IRTypeKind::Long: return type.is_file_backed ? "filelong_set" : "";
        case IRTypeKind::Double: return type.is_file_backed ? "filedouble_set" : "";
        case IRTypeKind::Boolean: return type.is_file_backed ? "filebool_set" : "";
        default: return "";
    }
}

std::string decode_string_literal_value(const std::string& literal) {
    std::string val = literal;
    if (val.size() >= 2 && val.front() == '"' && val.back() == '"') {
        val = val.substr(1, val.size() - 2);
    }
    std::string decoded;
    decoded.reserve(val.size());
    for (std::size_t i = 0; i < val.size(); ++i) {
        if (val[i] == '\\' && i + 1 < val.size()) {
            ++i;
            switch (val[i]) {
                case 'n': decoded.push_back('\n'); break;
                case 't': decoded.push_back('\t'); break;
                case '\\': decoded.push_back('\\'); break;
                case '"': decoded.push_back('"'); break;
                default:
                    decoded.push_back('\\');
                    decoded.push_back(val[i]);
                    break;
            }
        } else {
            decoded.push_back(val[i]);
        }
    }
    return decoded;
}

bool is_builtin_map_type(const SemanticType& type) {
    return type.kind == SemanticTypeKind::Class && type.name == "Map";
}

bool is_builtin_file_type(const SemanticType& type) {
    return type.kind == SemanticTypeKind::Class && type.name == "File";
}

std::string find_declaring_class_for_method(
    const std::unordered_map<std::string, SemanticClassSymbol>& classes,
    const std::string& class_name,
    const std::string& method_name,
    std::unordered_set<std::string>& visited) {
    if (visited.count(class_name)) return {};
    visited.insert(class_name);

    auto it = classes.find(class_name);
    if (it == classes.end()) return {};
    if (it->second.methods.find(method_name) != it->second.methods.end()) {
        return class_name;
    }
    for (const auto& parent_name : it->second.parents) {
        std::string owner = find_declaring_class_for_method(classes, parent_name, method_name, visited);
        if (!owner.empty()) return owner;
    }
    return {};
}

std::string find_unique_method_owner(
    const std::unordered_map<std::string, SemanticClassSymbol>& classes,
    const std::string& method_name) {
    std::string owner;
    for (const auto& entry : classes) {
        if (entry.second.methods.find(method_name) == entry.second.methods.end()) {
            continue;
        }
        if (!owner.empty()) {
            return {};
        }
        owner = entry.first;
    }
    return owner;
}

std::string resolve_method_owner(
    const std::unordered_map<std::string, std::vector<std::string>>& class_parent_map,
    const std::unordered_map<std::string, std::unordered_set<std::string>>& class_method_map,
    const std::unordered_map<std::string, SemanticClassSymbol>& classes,
    const std::string& current_class_name,
    const std::vector<std::string>& current_parents,
    const std::string& method_name) {
    std::function<std::string(const std::string&, std::unordered_set<std::string>&)> find_in_ast =
        [&](const std::string& class_name, std::unordered_set<std::string>& visited) -> std::string {
            if (visited.count(class_name)) return {};
            visited.insert(class_name);

            auto methods_it = class_method_map.find(class_name);
            if (methods_it != class_method_map.end() && methods_it->second.count(method_name)) {
                return class_name;
            }

            auto parents_it = class_parent_map.find(class_name);
            if (parents_it == class_parent_map.end()) {
                return {};
            }
            for (const auto& parent_name : parents_it->second) {
                std::string owner = find_in_ast(parent_name, visited);
                if (!owner.empty()) return owner;
            }
            return {};
        };

    {
        std::unordered_set<std::string> visited;
        std::string owner = find_in_ast(current_class_name, visited);
        if (!owner.empty()) return owner;
    }

    for (const auto& parent_name : current_parents) {
        std::unordered_set<std::string> visited;
        std::string owner = find_in_ast(parent_name, visited);
        if (!owner.empty()) return owner;
    }

    std::string unique_ast_owner;
    for (const auto& entry : class_method_map) {
        if (!entry.second.count(method_name)) continue;
        if (!unique_ast_owner.empty()) {
            unique_ast_owner.clear();
            break;
        }
        unique_ast_owner = entry.first;
    }
    if (!unique_ast_owner.empty()) return unique_ast_owner;

    {
        std::unordered_set<std::string> visited;
        std::string owner = find_declaring_class_for_method(classes, current_class_name, method_name, visited);
        if (!owner.empty()) return owner;
    }

    for (const auto& parent_name : current_parents) {
        std::unordered_set<std::string> visited;
        std::string owner = find_declaring_class_for_method(classes, parent_name, method_name, visited);
        if (!owner.empty()) return owner;
    }

    return find_unique_method_owner(classes, method_name);
}

std::string normalize_map_method(const std::string& method) {
    if (method == "containsKey") return "contains_key";
    if (method == "isEmpty") return "is_empty";
    return method;
}

std::string map_runtime_name(const std::string& method) {
    const std::string normalized = normalize_map_method(method);
    if (normalized == "create") return "map_create";
    if (normalized == "put") return "map_put";
    if (normalized == "get") return "map_get";
    if (normalized == "contains_key") return "map_contains_key";
    if (normalized == "remove") return "map_remove";
    if (normalized == "size") return "map_size";
    if (normalized == "is_empty") return "map_is_empty";
    if (normalized == "clear") return "map_clear";
    if (normalized == "free") return "map_free";
    if (normalized == "toString") return "map_to_string";
    return {};
}

std::string file_runtime_name(const std::string& method) {
    if (method == "read_all") return "file_read_all";
    if (method == "print_lines_count") return "file_print_lines_count";
    if (method == "line_reader_open") return "file_line_reader_open";
    if (method == "line_reader_next") return "file_line_reader_next";
    if (method == "line_reader_close") return "file_line_reader_close";
    if (method == "line_reader_line_count") return "file_line_reader_line_count";
    if (method == "count_lines") return "file_count_lines";
    if (method == "get_line_at") return "file_get_line_at";
    return {};
}

bool is_string_semantic_type(const SemanticType& type) {
    return type.kind == SemanticTypeKind::String;
}

std::string array_join_runtime_name(const IRType& array_type) {
    if (array_type.kind != IRTypeKind::Array || !array_type.element_type) {
        return "array_join";
    }
    switch (array_type.element_type->kind) {
        case IRTypeKind::String: return "array_join";
        case IRTypeKind::Integer: return "array_join_int";
        case IRTypeKind::Long: return "array_join_long";
        case IRTypeKind::Double: return "array_join_double";
        case IRTypeKind::Boolean: return "array_join_bool";
        default: return "array_join";
    }
}

} // namespace

IRModule IRGenerator::generate(const Program& program,
                               const SemanticAnalyser& analyser,
                               const std::unordered_set<std::string>* emit_only_classes) {
    module_ = IRModule{};
    analyser_ = &analyser;
    temp_counter_ = 0;
    label_counter_ = 0;
    lambda_counter_ = 0;
    symbol_table_.clear();
    string_constants_.clear();
    owned_values_.clear();
    value_aliases_.clear();
    scope_stack_.clear();
    class_parent_map_.clear();
    class_method_map_.clear();

    for (const auto& cls : program.classes) {
        if (!cls) continue;
        auto& parents = class_parent_map_[cls->name.lexeme];
        for (const auto& parent : cls->parents) {
            parents.push_back(parent.lexeme);
        }
        auto& methods = class_method_map_[cls->name.lexeme];
        for (const auto& member : cls->members) {
            if (member.kind == ClassMember::Kind::Method && member.method) {
                methods.insert(member.method->name.lexeme);
            }
        }
    }

    for (const auto& cls : program.classes) {
        if (!cls) continue;
        if (emit_only_classes && !emit_only_classes->count(cls->name.lexeme)) continue;
        visitClass(*cls);
    }

    return module_;
}

void IRGenerator::visitClass(const ClassDecl& cls) {
    current_class_name_ = cls.name.lexeme;
    class_field_stmts_.clear();

    std::vector<std::string> parents;
    for (const auto& parent : cls.parents) {
        parents.push_back(parent.lexeme);
    }

    for (const auto& member : cls.members) {
        if (member.kind == ClassMember::Kind::Statement && member.statement &&
            member.statement->kind == StmtKind::VariableDecl) {
            class_field_stmts_.push_back(member.statement.get());
        }
    }

    for (const auto& member : cls.members) {
        if (member.kind == ClassMember::Kind::Method && member.method) {
            visitMethod(*member.method, cls, parents);
        }
    }
}

void IRGenerator::visitMethod(const MethodDecl& method, const ClassDecl& cls, const std::vector<std::string>& parents) {
    current_class_name_ = cls.name.lexeme;
    current_parents_ = parents;
    symbol_table_.clear();
    temp_counter_ = 0;
    owned_values_.clear();
    value_aliases_.clear();
    scope_stack_.clear();

    std::string func_name = cls.name.lexeme + "_" + method.name.lexeme;

    IRType return_type = IRType::makeVoid();
    if (method.returnValue) {
        SemanticType st = analyser_->expressionType(method.returnValue.get());
        return_type = semantic_to_ir_type(st);
    }

    std::vector<IRParameter> params;
    for (const auto& param : method.parameters) {
        auto it = analyser_->classes().find(cls.name.lexeme);
        if (it != analyser_->classes().end()) {
            const auto& class_sym = it->second;
            auto method_it = class_sym.methods.find(method.name.lexeme);
            if (method_it != class_sym.methods.end()) {
                std::size_t idx = 0;
                for (std::size_t i = 0; i < method.parameters.size() && i < method_it->second.parameter_types.size(); ++i) {
                    if (method.parameters[i].name.lexeme == param.name.lexeme) {
                        idx = i;
                        break;
                    }
                }
                IRType param_type = (idx < method_it->second.parameter_types.size())
                    ? semantic_to_ir_type(method_it->second.parameter_types[idx])
                    : IRType::makePointer();
                params.push_back({param.name.lexeme, param_type});
            }
        }
        if (params.empty() || params.back().name != param.name.lexeme) {
            params.push_back({param.name.lexeme, IRType::makePointer()});
        }
    }

    module_.add_function(func_name, return_type, params);
    current_function_ = module_.find_function(func_name);
    IRFunction* func = current_function_;

    // Add 'this' parameter implicitly
    IRParameter this_param{"this", IRType::makePointer()};
    func->parameters.insert(func->parameters.begin(), this_param);

    func->entry_block();
    func->set_current_block(0);
    push_scope();

    // Alloca for parameters
    for (const auto& param : func->parameters) {
        std::string addr = new_temporary();
        emit(IRInstruction::make_alloca(addr, param.type));
        symbol_table_[param.name] = addr;

        // Store parameter value to alloca
        emit(IRInstruction::make_store(param.name, addr));
    }

    // Materialize class fields as method-scope storage so bare field references
    // resolve consistently in methods even without an object layout.
    for (const Stmt* field_stmt : class_field_stmts_) {
        if (field_stmt && field_stmt->kind == StmtKind::VariableDecl) {
            visitVariableDecl(static_cast<const VariableDeclStmt&>(*field_stmt));
        }
    }

    // Alloca for local variables and visit body
    for (const auto& stmt : method.body) {
        if (stmt) visitStatement(*stmt);
    }

    func = module_.find_function(func_name);

    // Handle return list
    if (method.returnValue) {
        std::string ret_val = visitExpression(*method.returnValue);
        std::unordered_set<std::string> preserved;
        std::string preserved_owner = preserved_owner_for_return(*method.returnValue, ret_val);
        if (!preserved_owner.empty()) {
            preserved.insert(preserved_owner);
        }
        emit_all_scope_cleanups(preserved);
        IRInstruction ret;
        ret.opcode = IROpcode::Ret;
        ret.type = return_type;
        ret.operands = {ret_val};
        emit(ret);
    } else if ((func && !func->blocks.empty() && !func->blocks.front().is_terminated()) &&
               (func->current_block() == nullptr || !func->current_block()->is_terminated())) {
        emit_all_scope_cleanups();
        IRInstruction ret;
        ret.opcode = IROpcode::Ret;
        ret.type = return_type;
        emit(ret);
    }
    scope_stack_.clear();
    owned_values_.clear();
    value_aliases_.clear();
}

void IRGenerator::visitStatement(const Stmt& stmt) {
    switch (stmt.kind) {
        case StmtKind::Expression:
            visitExpressionStmt(static_cast<const ExprStmt&>(stmt));
            break;
        case StmtKind::VariableDecl:
            visitVariableDecl(static_cast<const VariableDeclStmt&>(stmt));
            break;
        case StmtKind::Print:
            visitPrintStmt(static_cast<const PrintStmt&>(stmt));
            break;
        case StmtKind::GuardBlock:
            if (static_cast<const GuardBlockStmt&>(stmt).isLoop) {
                visitWhileBlock(static_cast<const GuardBlockStmt&>(stmt));
            } else {
                visitGuardBlock(static_cast<const GuardBlockStmt&>(stmt));
            }
            break;
        case StmtKind::ForEach:
            visitForEach(static_cast<const ForEachStmt&>(stmt));
            break;
        case StmtKind::Switch:
            visitSwitch(static_cast<const SwitchStmt&>(stmt));
            break;
        case StmtKind::Return:
            visitReturn(static_cast<const ReturnStmt&>(stmt));
            break;
    }
}

void IRGenerator::visitVariableDecl(const VariableDeclStmt& stmt) {
    IRType type = semantic_to_ir_type(analyser_->expressionType(stmt.initializer.get()));
    if (stmt.type.name == "Integer") type = IRType::makeInteger(stmt.type.isFileBacked);
    else if (stmt.type.name == "Long") type = IRType::makeLong(stmt.type.isFileBacked);
    else if (stmt.type.name == "Double") type = IRType::makeDouble(stmt.type.isFileBacked);
    else if (stmt.type.name == "Boolean") type = IRType::makeBoolean(stmt.type.isFileBacked);
    else if (stmt.type.name == "String") type = IRType::makeString(stmt.type.isFileBacked);
    else if (stmt.type.isArray) type = IRType::makeArray(IRType::makePointer(), stmt.type.isFileBacked);
    else type = IRType::makePointer(stmt.type.isFileBacked);

    std::string addr = new_temporary();
    emit(IRInstruction::make_alloca(addr, type));
    symbol_table_[stmt.name.lexeme] = addr;

    if (stmt.initializer) {
        if (type.kind == IRTypeKind::String && type.is_file_backed) {
            if (const auto* literal = dynamic_cast<const LiteralExpr*>(stmt.initializer.get());
                literal && literal->kind == ExprKind::StringLiteral) {
                const std::string decoded = decode_string_literal_value(literal->value);
                const std::string str_name = "str_" + std::to_string(string_constants_.size());
                string_constants_[str_name] = decoded;
                module_.add_string_constant(str_name, decoded);

                std::string data_ptr = new_temporary();
                IRInstruction ptr_inst;
                ptr_inst.opcode = IROpcode::ConstPtr;
                ptr_inst.type = IRType::makePointer();
                ptr_inst.result = data_ptr;
                ptr_inst.string_value = str_name + "_data";
                emit(ptr_inst);

                module_.add_external_symbol("filestring_create_auto_from_cstr");
                IRInstruction call;
                call.opcode = IROpcode::CallRuntime;
                call.type = IRType::makeVoid();
                call.operands = {"filestring_create_auto_from_cstr", addr, data_ptr};
                emit(call);

                OwnedValueInfo cleanup = cleanup_info_for_ir_type(type, true);
                if (!cleanup.runtime_func.empty()) {
                    register_owned_value(addr, cleanup.runtime_func, cleanup.operand_kind);
                }
                return;
            }
        }

        std::string val = visitExpression(*stmt.initializer);
        const std::string create_runtime = file_create_runtime(type);
        if (!create_runtime.empty()) {
            module_.add_external_symbol(create_runtime);
            IRInstruction call;
            call.opcode = IROpcode::CallRuntime;
            call.type = IRType::makeVoid();
            call.operands = {create_runtime, addr, val};
            emit(call);
            OwnedValueInfo cleanup = cleanup_info_for_ir_type(type, true);
            if (!cleanup.runtime_func.empty()) {
                register_owned_value(addr, cleanup.runtime_func, cleanup.operand_kind);
            }
        } else {
            emit(IRInstruction::make_store(val, addr));
            assign_owned_value(addr, val, type);
        }
    }
}

void IRGenerator::visitExpressionStmt(const ExprStmt& stmt) {
    if (stmt.expression) {
        visitExpression(*stmt.expression);
    }
}

void IRGenerator::visitPrintStmt(const PrintStmt& stmt) {
    if (!stmt.expression) return;

    IRType type = get_expr_type(*stmt.expression);
    std::string val = visitExpression(*stmt.expression);

    std::string runtime_func = (type.kind == IRTypeKind::String || type.kind == IRTypeKind::Pointer)
        ? "print_string" : "print_uint";

    module_.add_external_symbol(runtime_func);

    IRInstruction call;
    call.opcode = IROpcode::CallRuntime;
    call.type = IRType::makeVoid();
    call.operands = {runtime_func, val};
    emit(call);

    if (stmt.keyword.kind == TokenKind::KeywordPrintln) {
        std::string nl_name = "str_" + std::to_string(string_constants_.size());
        std::string nl_value = "\n";
        string_constants_[nl_name] = nl_value;
        module_.add_string_constant(nl_name, nl_value);

        std::string nl_val = new_temporary();
        IRInstruction nl_inst;
        nl_inst.opcode = IROpcode::ConstPtr;
        nl_inst.type = IRType::makeString();
        nl_inst.result = nl_val;
        nl_inst.string_value = nl_name;
        emit(nl_inst);

        IRInstruction nl_call;
        nl_call.opcode = IROpcode::CallRuntime;
        nl_call.type = IRType::makeVoid();
        nl_call.operands = {"print_string", nl_val};
        emit(nl_call);
    }
}

void IRGenerator::visitGuardBlock(const GuardBlockStmt& stmt) {
    std::string then_label = new_label();
    std::string else_label = stmt.elseBody.empty() ? std::string{} : new_label();
    std::string end_label = new_label();

    std::string cond = visitExpression(*stmt.condition);
    IRInstruction branch;
    branch.opcode = IROpcode::Branch;
    branch.type = IRType::makeVoid();
    branch.operands = {cond, then_label, stmt.elseBody.empty() ? end_label : else_label};
    emit(branch);

    IRBasicBlock& then_block = current_function_->add_block(then_label);
    current_function_->set_current_block(current_function_->blocks.size() - 1);
    push_scope();

    for (const auto& body_stmt : stmt.body) {
        if (body_stmt) visitStatement(*body_stmt);
    }
    pop_scope();

    if (current_function_->current_block() && !current_function_->current_block()->is_terminated()) {
        IRInstruction jmp;
        jmp.opcode = IROpcode::Jmp;
        jmp.type = IRType::makeVoid();
        jmp.label_name = end_label;
        emit(jmp);
    }

    if (!stmt.elseBody.empty()) {
        current_function_->add_block(else_label);
        current_function_->set_current_block(current_function_->blocks.size() - 1);
        push_scope();
        for (const auto& body_stmt : stmt.elseBody) {
            if (body_stmt) visitStatement(*body_stmt);
        }
        pop_scope();

        if (current_function_->current_block() && !current_function_->current_block()->is_terminated()) {
            IRInstruction else_jmp;
            else_jmp.opcode = IROpcode::Jmp;
            else_jmp.type = IRType::makeVoid();
            else_jmp.label_name = end_label;
            emit(else_jmp);
        }
    }

    current_function_->add_block(end_label);
    current_function_->set_current_block(current_function_->blocks.size() - 1);
}

void IRGenerator::visitWhileBlock(const GuardBlockStmt& stmt) {
    std::string loop_label = new_label();
    std::string body_label = new_label();
    std::string end_label = new_label();

    IRInstruction start_jmp;
    start_jmp.opcode = IROpcode::Jmp;
    start_jmp.type = IRType::makeVoid();
    start_jmp.label_name = loop_label;
    emit(start_jmp);

    current_function_->add_block(loop_label);
    current_function_->set_current_block(current_function_->blocks.size() - 1);

    std::string cond = visitExpression(*stmt.condition);
    IRInstruction branch;
    branch.opcode = IROpcode::Branch;
    branch.type = IRType::makeVoid();
    branch.operands = {cond, body_label, end_label};
    emit(branch);

    current_function_->add_block(body_label);
    current_function_->set_current_block(current_function_->blocks.size() - 1);
    push_scope();

    for (const auto& body_stmt : stmt.body) {
        if (body_stmt) visitStatement(*body_stmt);
    }
    pop_scope();

    if (current_function_->current_block() && !current_function_->current_block()->is_terminated()) {
        IRInstruction back_jmp;
        back_jmp.opcode = IROpcode::Jmp;
        back_jmp.type = IRType::makeVoid();
        back_jmp.label_name = loop_label;
        emit(back_jmp);
    }

    current_function_->add_block(end_label);
    current_function_->set_current_block(current_function_->blocks.size() - 1);
}

void IRGenerator::visitForEach(const ForEachStmt& stmt) {
    std::string loop_label = new_label();
    std::string body_label = new_label();
    std::string end_label = new_label();

    const auto* iterable_ident = stmt.iterable ? dynamic_cast<const IdentifierExpr*>(stmt.iterable.get()) : nullptr;
    std::string arr_addr = iterable_ident ? symbol_table_[iterable_ident->name] : std::string{};
    std::string arr = !arr_addr.empty() ? arr_addr : visitExpression(*stmt.iterable);

    // Index variable
    std::string idx_addr = new_temporary();
    emit(IRInstruction::make_alloca(idx_addr, IRType::makeInteger()));
    std::string zero_val = new_temporary();
    emit(IRInstruction::make_const_int(zero_val, 0));
    emit(IRInstruction::make_store(zero_val, idx_addr));

    IRInstruction branch1;
    branch1.opcode = IROpcode::Jmp;
    branch1.type = IRType::makeVoid();
    branch1.label_name = loop_label;
    emit(branch1);

    // Loop block
    IRBasicBlock& loop_block = current_function_->add_block(loop_label);
    current_function_->set_current_block(current_function_->blocks.size() - 1);

    // Check idx < size
    std::string idx_val = new_temporary();
    emit(IRInstruction::make_load(idx_val, idx_addr, IRType::makeInteger()));

    std::string size_val = new_temporary();
    IRInstruction arr_len;
    arr_len.opcode = IROpcode::ArrayLen;
    arr_len.type = IRType::makeInteger();
    arr_len.result = size_val;
    arr_len.operands = {arr};
    emit(arr_len);

    std::string cond = new_temporary();
    IRInstruction lt;
    lt.opcode = IROpcode::LT;
    lt.type = IRType::makeBoolean();
    lt.result = cond;
    lt.operands = {idx_val, size_val};
    emit(lt);

    IRInstruction branch2;
    branch2.opcode = IROpcode::Branch;
    branch2.type = IRType::makeVoid();
    branch2.operands = {cond, body_label, end_label};
    emit(branch2);

    // Body block
    IRBasicBlock& body_block = current_function_->add_block(body_label);
    current_function_->set_current_block(current_function_->blocks.size() - 1);

    IRType loop_type;
    if (stmt.type.name == "Integer") loop_type = IRType::makeInteger(stmt.type.isFileBacked);
    else if (stmt.type.name == "Long") loop_type = IRType::makeLong(stmt.type.isFileBacked);
    else if (stmt.type.name == "Double") loop_type = IRType::makeDouble(stmt.type.isFileBacked);
    else if (stmt.type.name == "String") loop_type = IRType::makeString(stmt.type.isFileBacked);
    else if (stmt.type.name == "Boolean") loop_type = IRType::makeBoolean(stmt.type.isFileBacked);
    else loop_type = IRType::makePointer(stmt.type.isFileBacked);

    // Get element
    std::string elem = new_temporary();
    IRInstruction arr_get;
    arr_get.opcode = IROpcode::ArrayGet;
    arr_get.type = loop_type;
    arr_get.result = elem;
    arr_get.operands = {arr, idx_val};
    emit(arr_get);

    // Store the fetched element to the loop variable

    std::string var_addr = new_temporary();
    emit(IRInstruction::make_alloca(var_addr, loop_type));
    emit(IRInstruction::make_store(elem, var_addr));
    const auto saved_it = symbol_table_.find(stmt.name.lexeme);
    const bool had_saved_symbol = saved_it != symbol_table_.end();
    const std::string saved_symbol = had_saved_symbol ? saved_it->second : std::string{};
    symbol_table_[stmt.name.lexeme] = var_addr;
    push_scope();
    assign_owned_value(var_addr, elem, loop_type);

    for (const auto& body_stmt : stmt.body) {
        if (body_stmt) visitStatement(*body_stmt);
    }
    pop_scope();

    if (had_saved_symbol) {
        symbol_table_[stmt.name.lexeme] = saved_symbol;
    } else {
        symbol_table_.erase(stmt.name.lexeme);
    }

    // Increment index
    std::string idx_val2 = new_temporary();
    emit(IRInstruction::make_load(idx_val2, idx_addr, IRType::makeInteger()));

    std::string one = new_temporary();
    emit(IRInstruction::make_const_int(one, 1));

    std::string idx_inc = new_temporary();
    IRInstruction add;
    add.opcode = IROpcode::Add;
    add.type = IRType::makeInteger();
    add.result = idx_inc;
    add.operands = {idx_val2, one};
    emit(add);

    emit(IRInstruction::make_store(idx_inc, idx_addr));

    // Jump back to loop
    IRInstruction jmp;
    jmp.opcode = IROpcode::Jmp;
    jmp.type = IRType::makeVoid();
    jmp.label_name = loop_label;
    emit(jmp);

    // End block
    IRBasicBlock& end_block = current_function_->add_block(end_label);
    current_function_->set_current_block(current_function_->blocks.size() - 1);
}

void IRGenerator::visitSwitch(const SwitchStmt& stmt) {
    std::string end_label = new_label();
    std::string subject = visitExpression(*stmt.subject);

    std::string prev_check_label;

    for (std::size_t i = 0; i < stmt.cases.size(); ++i) {
        const auto& switch_case = stmt.cases[i];
        std::string case_label = new_label();
        std::string next_label = (i + 1 < stmt.cases.size()) ? new_label() : end_label;

        std::string case_label_str;
        if (const auto* lit = dynamic_cast<const LiteralExpr*>(switch_case.label.get())) {
            case_label_str = lit->value;
            std::string case_val = new_temporary();
            if (lit->kind == ExprKind::IntegerLiteral) {
                emit(IRInstruction::make_const_int(case_val, std::stoll(case_label_str)));
            }
            std::string cond = new_temporary();
            IRInstruction eq;
            eq.opcode = IROpcode::EQ;
            eq.type = IRType::makeBoolean();
            eq.result = cond;
            eq.operands = {subject, case_val};
            emit(eq);

            IRInstruction branch;
            branch.opcode = IROpcode::Branch;
            branch.type = IRType::makeVoid();
            branch.operands = {cond, case_label, next_label};
            emit(branch);
        }

        // Case block
        IRBasicBlock& case_block = current_function_->add_block(case_label);
        current_function_->set_current_block(current_function_->blocks.size() - 1);
        push_scope();

        for (const auto& body_stmt : switch_case.body) {
            if (body_stmt) visitStatement(*body_stmt);
        }
        pop_scope();

        if (current_function_->current_block() && !current_function_->current_block()->is_terminated()) {
            IRInstruction jmp;
            jmp.opcode = IROpcode::Jmp;
            jmp.type = IRType::makeVoid();
            jmp.label_name = end_label;
            emit(jmp);
        }

        // Next check block (if not last)
        if (i + 1 < stmt.cases.size()) {
            IRBasicBlock& next_block = current_function_->add_block(next_label);
            current_function_->set_current_block(current_function_->blocks.size() - 1);
        }
    }

    // End block
    IRBasicBlock& end_block = current_function_->add_block(end_label);
    current_function_->set_current_block(current_function_->blocks.size() - 1);
}

void IRGenerator::visitReturn(const ReturnStmt& stmt) {
    if (stmt.expression) {
        std::string val = visitExpression(*stmt.expression);
        std::unordered_set<std::string> preserved;
        std::string preserved_owner = preserved_owner_for_return(*stmt.expression, val);
        if (!preserved_owner.empty()) {
            preserved.insert(preserved_owner);
        }
        emit_all_scope_cleanups(preserved);
        IRInstruction ret;
        ret.opcode = IROpcode::Ret;
        ret.type = get_expr_type(*stmt.expression);
        ret.operands = {val};
        emit(ret);
    } else {
        emit_all_scope_cleanups();
        IRInstruction ret;
        ret.opcode = IROpcode::Ret;
        ret.type = IRType::makeVoid();
        emit(ret);
    }
}

std::string IRGenerator::visitExpression(const Expr& expr) {
    switch (expr.kind) {
        case ExprKind::Identifier:
            return visitIdentifier(static_cast<const IdentifierExpr&>(expr));
        case ExprKind::IntegerLiteral:
        case ExprKind::LongLiteral:
        case ExprKind::DoubleLiteral:
        case ExprKind::StringLiteral:
        case ExprKind::BooleanLiteral:
            return visitLiteral(static_cast<const LiteralExpr&>(expr));
        case ExprKind::Binary:
            return visitBinary(static_cast<const BinaryExpr&>(expr));
        case ExprKind::Unary:
            return visitUnary(static_cast<const UnaryExpr&>(expr));
        case ExprKind::Postfix:
            return visitPostfix(static_cast<const PostfixExpr&>(expr));
        case ExprKind::Assignment:
            return visitAssignment(static_cast<const AssignmentExpr&>(expr));
        case ExprKind::Call:
            return visitCall(static_cast<const CallExpr&>(expr));
        case ExprKind::Member:
            return visitMember(static_cast<const MemberExpr&>(expr));
        case ExprKind::Index:
            return visitIndex(static_cast<const IndexExpr&>(expr));
        case ExprKind::Grouping:
            return visitGrouping(static_cast<const GroupingExpr&>(expr));
        case ExprKind::ArrayLiteral:
            return visitArrayLiteral(static_cast<const ArrayLiteralExpr&>(expr));
        case ExprKind::Lambda:
            return visitLambda(static_cast<const LambdaExpr&>(expr));
    }
    return new_temporary();
}

std::string IRGenerator::visitIdentifier(const IdentifierExpr& expr) {
    auto it = symbol_table_.find(expr.name);
    if (it != symbol_table_.end()) {
        IRType load_type = semantic_to_ir_type(analyser_->expressionType(&expr));
        if (load_type.kind == IRTypeKind::String && load_type.is_file_backed) {
            return it->second;
        }
        const std::string file_get = file_get_runtime(load_type);
        if (!file_get.empty()) {
            module_.add_external_symbol(file_get);
            std::string val = new_temporary();
            IRInstruction call;
            call.opcode = IROpcode::CallRuntime;
            call.type = IRType{load_type.kind, load_type.element_type, false};
            call.result = val;
            call.operands = {file_get, it->second};
            emit(call);
            return val;
        }
        std::string val = new_temporary();
        emit(IRInstruction::make_load(val, it->second, load_type));
        value_aliases_[val] = it->second;
        return val;
    }
    return expr.name;
}

namespace {
bool is_address_value(const std::string& value) {
    return !value.empty() && value[0] == '&';
}

std::string strip_address_marker(const std::string& value) {
    return is_address_value(value) ? value.substr(1) : value;
}
} // namespace

std::string IRGenerator::visitLiteral(const LiteralExpr& expr) {
    std::string dest = new_temporary();

    switch (expr.kind) {
        case ExprKind::IntegerLiteral:
            emit(IRInstruction::make_const_int(dest, std::stoll(expr.value)));
            break;
        case ExprKind::LongLiteral: {
            std::string val = expr.value;
            if (!val.empty() && val.back() == 'l') val.pop_back();
            emit(IRInstruction::make_const_long(dest, std::stoll(val)));
            break;
        }
        case ExprKind::DoubleLiteral: {
            std::string val = expr.value;
            if (!val.empty() && val.back() == 'd') val.pop_back();
            emit(IRInstruction::make_const_double(dest, std::stod(val)));
            break;
        }
        case ExprKind::StringLiteral: {
            std::string decoded = decode_string_literal_value(expr.value);
            std::string str_name = "str_" + std::to_string(string_constants_.size());
            string_constants_[str_name] = decoded;
            module_.add_string_constant(str_name, decoded);
            IRInstruction inst;
            inst.opcode = IROpcode::ConstPtr;
            inst.type = IRType::makeString();
            inst.result = dest;
            inst.string_value = str_name;
            emit(inst);
            break;
        }
        case ExprKind::BooleanLiteral:
            emit(IRInstruction::make_const_bool(dest, expr.value == "true"));
            break;
        default:
            emit(IRInstruction::make_const_int(dest, 0));
            break;
    }

    return dest;
}

std::string IRGenerator::visitBinary(const BinaryExpr& expr) {
    std::string left = visitExpression(*expr.left);
    std::string right = visitExpression(*expr.right);
    std::string dest = new_temporary();

    IROpcode opcode;
    switch (expr.op.kind) {
        case TokenKind::Plus: opcode = IROpcode::Add; break;
        case TokenKind::Minus: opcode = IROpcode::Sub; break;
        case TokenKind::Star: opcode = IROpcode::Mul; break;
        case TokenKind::Slash: opcode = IROpcode::Div; break;
        case TokenKind::Percent: opcode = IROpcode::Mod; break;
        case TokenKind::EqualEqual: opcode = IROpcode::EQ; break;
        case TokenKind::BangEqual: opcode = IROpcode::NE; break;
        case TokenKind::Less: opcode = IROpcode::LT; break;
        case TokenKind::LessEqual: opcode = IROpcode::LE; break;
        case TokenKind::Greater: opcode = IROpcode::GT; break;
        case TokenKind::GreaterEqual: opcode = IROpcode::GE; break;
        case TokenKind::AndAnd: opcode = IROpcode::And; break;
        case TokenKind::OrOr: opcode = IROpcode::Or; break;
        default: opcode = IROpcode::Add; break;
    }

    IRType result_type = get_expr_type(expr);
    IRInstruction inst;
    inst.opcode = opcode;
    inst.type = result_type;
    inst.result = dest;
    inst.operands = {left, right};
    emit(inst);
    if ((opcode == IROpcode::Add) && result_type.kind == IRTypeKind::String) {
        register_owned_value(dest, "string_free", CleanupOperandKind::DirectValue);
    }

    return dest;
}

std::string IRGenerator::visitUnary(const UnaryExpr& expr) {
    std::string operand = visitExpression(*expr.operand);
    std::string dest = new_temporary();

    if (expr.op.kind == TokenKind::Bang) {
        std::string one = new_temporary();
        emit(IRInstruction::make_const_bool(one, true));
        IRInstruction ne;
        ne.opcode = IROpcode::NE;
        ne.type = IRType::makeBoolean();
        ne.result = dest;
        ne.operands = {operand, one};
        emit(ne);
    } else if (expr.op.kind == TokenKind::Minus) {
        IRInstruction neg;
        neg.opcode = IROpcode::Neg;
        neg.type = get_expr_type(expr);
        neg.result = dest;
        neg.operands = {operand};
        emit(neg);
    } else {
        dest = operand;
    }

    return dest;
}

std::string IRGenerator::visitPostfix(const PostfixExpr& expr) {
    const auto* ident = dynamic_cast<const IdentifierExpr*>(expr.operand.get());
    if (!ident) {
        return visitExpression(*expr.operand);
    }

    auto it = symbol_table_.find(ident->name);
    if (it == symbol_table_.end()) {
        return new_temporary();
    }

    IRType type = get_expr_type(expr);
    const std::string file_get = file_get_runtime(type);
    const std::string file_set = file_set_runtime(type);
    if (!file_get.empty() && !file_set.empty()) {
        module_.add_external_symbol(file_get);
        module_.add_external_symbol(file_set);

        std::string current = new_temporary();
        IRInstruction get_call;
        get_call.opcode = IROpcode::CallRuntime;
        get_call.type = IRType{type.kind, type.element_type, false};
        get_call.result = current;
        get_call.operands = {file_get, it->second};
        emit(get_call);

        std::string one = new_temporary();
        emit(IRInstruction::make_const_int(one, 1));

        std::string updated = new_temporary();
        IRInstruction op;
        op.opcode = (expr.op.kind == TokenKind::PlusPlus) ? IROpcode::Add : IROpcode::Sub;
        op.type = IRType{type.kind, type.element_type, false};
        op.result = updated;
        op.operands = {current, one};
        emit(op);

        IRInstruction set_call;
        set_call.opcode = IROpcode::CallRuntime;
        set_call.type = IRType::makeVoid();
        set_call.operands = {file_set, it->second, updated};
        emit(set_call);
        return current;
    }

    std::string current = new_temporary();
    emit(IRInstruction::make_load(current, it->second, type));

    std::string one = new_temporary();
    emit(IRInstruction::make_const_int(one, 1));

    std::string updated = new_temporary();
    IRInstruction op;
    op.opcode = (expr.op.kind == TokenKind::PlusPlus) ? IROpcode::Add : IROpcode::Sub;
    op.type = type;
    op.result = updated;
    op.operands = {current, one};
    emit(op);

    emit(IRInstruction::make_store(updated, it->second));
    return current;
}

std::string IRGenerator::visitAssignment(const AssignmentExpr& expr) {
    std::string val = visitExpression(*expr.value);

    if (const auto* ident = dynamic_cast<const IdentifierExpr*>(expr.target.get())) {
        auto it = symbol_table_.find(ident->name);
        if (it != symbol_table_.end()) {
            IRType target_type = semantic_to_ir_type(analyser_->expressionType(expr.target.get()));
            const std::string file_set = file_set_runtime(target_type);
            if (!file_set.empty()) {
                module_.add_external_symbol(file_set);
                IRInstruction set_call;
                set_call.opcode = IROpcode::CallRuntime;
                set_call.type = IRType::makeVoid();
                set_call.operands = {file_set, it->second, val};
                emit(set_call);
                return val;
            }
            free_owned_storage_before_store(it->second);
            emit(IRInstruction::make_store(val, it->second));
            assign_owned_value(it->second, val, get_expr_type(expr));
        }
        return val;
    }

    return val;
}

std::string IRGenerator::visitCall(const CallExpr& expr) {
    if (const auto* ident = dynamic_cast<const IdentifierExpr*>(expr.callee.get())) {
        std::string func_name = ident->name;

        std::vector<std::string> args;
        std::string owner_class =
            resolve_method_owner(class_parent_map_, class_method_map_,
                                 analyser_->classes(), current_class_name_, current_parents_, func_name);
        std::vector<SemanticType> parameter_types;
        const std::string& lookup_class = owner_class.empty() ? current_class_name_ : owner_class;
        auto class_it = analyser_->classes().find(lookup_class);
        if (class_it != analyser_->classes().end()) {
            auto method_it = class_it->second.methods.find(func_name);
            if (method_it != class_it->second.methods.end()) {
                parameter_types = method_it->second.parameter_types;
            }
        }
        if (!owner_class.empty()) {
            args.push_back(load_symbol_value("this", IRType::makePointer()));
        }
        for (std::size_t i = 0; i < expr.arguments.size(); ++i) {
            const auto& arg = expr.arguments[i];
            if (i < parameter_types.size() &&
                is_string_semantic_type(parameter_types[i])) {
                if (const auto* literal = dynamic_cast<const LiteralExpr*>(arg.get());
                    literal && literal->kind == ExprKind::StringLiteral) {
                    const std::string data_ptr =
                        emit_string_constant(decode_string_literal_value(literal->value), true);
                    const std::string temp_string = new_temporary();
                    emit(IRInstruction::make_alloca(temp_string, IRType::makeString()));
                    module_.add_external_symbol("string_from_cstr");
                    IRInstruction call;
                    call.opcode = IROpcode::CallRuntime;
                    call.type = IRType::makeVoid();
                    call.operands = {"string_from_cstr", "&" + temp_string, data_ptr};
                    emit(call);
                    register_owned_value(temp_string, "string_free", CleanupOperandKind::PassAddress);
                    args.push_back("&" + temp_string);
                    continue;
                }
            }
            args.push_back(visitExpression(*arg));
        }

        std::string result_temp = new_temporary();
        IRType ret_type = get_expr_type(expr);

        // Try current class first
        std::string mangled = (owner_class.empty() ? current_class_name_ : owner_class) + "_" + func_name;
        module_.add_external_symbol(mangled);

        IRInstruction call;
        call.opcode = IROpcode::CallRuntime;
        call.type = ret_type;
        call.result = result_temp;
        call.operands = {mangled};
        for (const auto& a : args) {
            call.operands.push_back(a);
        }
        emit(call);

        return result_temp;
    }

    if (const auto* member = dynamic_cast<const MemberExpr*>(expr.callee.get())) {
        IRType object_type = get_expr_type(*member->object);
        SemanticType object_sem_type = analyser_->expressionType(member->object.get());
        std::string object_value = visitExpression(*member->object);
        IRType ret_type = get_expr_type(expr);

        std::vector<std::string> args;
        args.push_back(object_value);
        for (const auto& arg : expr.arguments) {
            args.push_back(visitExpression(*arg));
        }

        std::string runtime_name;
        if (const auto* object_ident = dynamic_cast<const IdentifierExpr*>(member->object.get())) {
            if (object_ident->name == "Map") {
                const std::string& method = member->member.lexeme;
                if (method == "of") {
                    std::string bucket_count = new_temporary();
                    std::size_t pair_count = expr.arguments.size() / 2;
                    emit(IRInstruction::make_const_int(bucket_count, static_cast<int64_t>(pair_count == 0 ? 8 : pair_count)));

                    bool use_string_key_runtime = true;
                    for (std::size_t i = 0; i < expr.arguments.size(); i += 2) {
                        if (i >= expr.arguments.size()) break;
                        if (!is_string_semantic_type(analyser_->expressionType(expr.arguments[i].get()))) {
                            use_string_key_runtime = false;
                            break;
                        }
                    }

                    std::string hash_fn = new_temporary();
                    IRInstruction hash_fn_inst;
                    hash_fn_inst.opcode = IROpcode::ConstPtr;
                    hash_fn_inst.type = IRType::makePointer();
                    hash_fn_inst.result = hash_fn;
                    if (use_string_key_runtime) {
                        hash_fn_inst.string_value = "map_string_hash";
                        module_.add_external_symbol("map_string_hash");
                    }
                    emit(hash_fn_inst);

                    std::string equals_fn = new_temporary();
                    IRInstruction equals_fn_inst;
                    equals_fn_inst.opcode = IROpcode::ConstPtr;
                    equals_fn_inst.type = IRType::makePointer();
                    equals_fn_inst.result = equals_fn;
                    if (use_string_key_runtime) {
                        equals_fn_inst.string_value = "map_string_equals";
                        module_.add_external_symbol("map_string_equals");
                    }
                    emit(equals_fn_inst);

                    std::string result_temp = new_temporary();
                    module_.add_external_symbol("map_create");
                    IRInstruction create_call;
                    create_call.opcode = IROpcode::CallRuntime;
                    create_call.type = IRType::makePointer();
                    create_call.result = result_temp;
                    create_call.operands = {"map_create", bucket_count, hash_fn, equals_fn};
                    emit(create_call);
                    register_owned_value(result_temp, "map_free", CleanupOperandKind::DirectValue);

                    for (std::size_t i = 0; i + 1 < expr.arguments.size(); i += 2) {
                        module_.add_external_symbol("map_put");
                        IRInstruction put_call;
                        put_call.opcode = IROpcode::CallRuntime;
                        put_call.type = IRType::makePointer();
                        put_call.operands = {"map_put", result_temp, args[i + 1], args[i + 2]};
                        emit(put_call);
                    }
                    return result_temp;
                }

                if (method == "create") {
                    std::string bucket_count = expr.arguments.empty() ? new_temporary() : args[1];
                    if (expr.arguments.empty()) {
                        emit(IRInstruction::make_const_int(bucket_count, 16));
                    }
                    std::string hash_fn = expr.arguments.size() > 1 ? args[2] : new_temporary();
                    std::string equals_fn = expr.arguments.size() > 2 ? args[3] : new_temporary();
                    if (expr.arguments.size() <= 1) {
                        IRInstruction inst;
                        inst.opcode = IROpcode::ConstPtr;
                        inst.type = IRType::makePointer();
                        inst.result = hash_fn;
                        inst.string_value = "map_string_hash";
                        module_.add_external_symbol("map_string_hash");
                        emit(inst);
                    }
                    if (expr.arguments.size() <= 2) {
                        IRInstruction inst;
                        inst.opcode = IROpcode::ConstPtr;
                        inst.type = IRType::makePointer();
                        inst.result = equals_fn;
                        inst.string_value = "map_string_equals";
                        module_.add_external_symbol("map_string_equals");
                        emit(inst);
                    }

                    std::string result_temp = new_temporary();
                    module_.add_external_symbol("map_create");
                    IRInstruction create_call;
                    create_call.opcode = IROpcode::CallRuntime;
                    create_call.type = IRType::makePointer();
                    create_call.result = result_temp;
                    create_call.operands = {"map_create", bucket_count, hash_fn, equals_fn};
                    emit(create_call);
                    register_owned_value(result_temp, "map_free", CleanupOperandKind::DirectValue);
                    return result_temp;
                }
            }

            if (object_ident->name == "File") {
                const std::string& method = member->member.lexeme;
                if (method == "of" && !expr.arguments.empty()) {
                    std::string result_temp = new_temporary();
                    IRInstruction file_ref;
                    file_ref.opcode = IROpcode::ConstPtr;
                    file_ref.type = IRType::makePointer();
                    file_ref.result = result_temp;
                    emit(file_ref);

                    const Expr* path_expr = expr.arguments[0].get();
                    std::string path_value = args[1];
                    std::string open_runtime = "file_line_reader_open";
                    if (const auto* literal = dynamic_cast<const LiteralExpr*>(path_expr);
                        literal && literal->kind == ExprKind::StringLiteral) {
                        path_value = emit_string_constant(decode_string_literal_value(literal->value), true);
                    } else {
                        IRType path_type = semantic_to_ir_type(analyser_->expressionType(path_expr));
                        if (path_type.kind == IRTypeKind::String && !path_type.is_file_backed) {
                            open_runtime = "file_line_reader_open_string";
                        }
                    }

                    module_.add_external_symbol(open_runtime);
                    IRInstruction open_call;
                    open_call.opcode = IROpcode::CallRuntime;
                    open_call.type = IRType::makeBoolean();
                    open_call.operands = {open_runtime, path_value};
                    emit(open_call);
                    return result_temp;
                }

                const std::string static_runtime = file_runtime_name(method);
                if (!static_runtime.empty()) {
                    module_.add_external_symbol(static_runtime);
                    std::string result_temp = new_temporary();
                    IRInstruction call;
                    call.opcode = IROpcode::CallRuntime;
                    call.type = ret_type;
                    call.result = result_temp;
                    call.operands = {static_runtime};
                    for (std::size_t i = 0; i < expr.arguments.size(); ++i) {
                        const Expr* arg_expr = expr.arguments[i].get();
                        std::string arg_value = args[i + 1];
                        if (i == 0 && static_runtime != "file_line_reader_next" &&
                            static_runtime != "file_line_reader_close" &&
                            static_runtime != "file_line_reader_line_count") {
                            if (const auto* literal = dynamic_cast<const LiteralExpr*>(arg_expr);
                                literal && literal->kind == ExprKind::StringLiteral) {
                                arg_value = emit_string_constant(decode_string_literal_value(literal->value), true);
                            }
                        }
                        call.operands.push_back(arg_value);
                    }
                    emit(call);
                    return result_temp;
                }
            }
        }

        if (object_type.kind == IRTypeKind::Array) {
            const std::string& method = member->member.lexeme;

            if (method == "add" && expr.arguments.size() == 1) {
                IRInstruction push;
                push.opcode = IROpcode::ArrayPush;
                push.type = IRType::makeVoid();
                push.operands = {object_value, args[1]};
                emit(push);
                return new_temporary();
            }

            if (method == "size") {
                std::string result_temp = new_temporary();
                IRInstruction len;
                len.opcode = IROpcode::ArrayLen;
                len.type = IRType::makeInteger();
                len.result = result_temp;
                len.operands = {object_value};
                emit(len);
                return result_temp;
            }

            if (method == "get" && expr.arguments.size() == 1) {
                std::string result_temp = new_temporary();
                IRInstruction get;
                get.opcode = IROpcode::ArrayGet;
                get.type = ret_type;
                get.result = result_temp;
                get.operands = {object_value, args[1]};
                emit(get);
                return result_temp;
            }

            if (method == "remove" && expr.arguments.size() == 1) {
                module_.add_external_symbol("array_remove");
                IRInstruction call;
                call.opcode = IROpcode::CallRuntime;
                call.type = IRType::makeVoid();
                call.operands = {"array_remove", object_value, args[1]};
                emit(call);
                return new_temporary();
            }

            if (method == "filter" || method == "sort") {
                return object_value;
            }

            if (method == "join") {
                std::string out_slot = new_temporary();
                emit(IRInstruction::make_alloca(out_slot, IRType::makeString()));
                const std::string join_runtime = array_join_runtime_name(object_type);
                module_.add_external_symbol(join_runtime);
                IRInstruction call;
                call.opcode = IROpcode::CallRuntime;
                call.type = IRType::makeVoid();
                call.operands = {join_runtime, object_value, args[1], out_slot};
                emit(call);
                register_owned_value(out_slot, "string_free", CleanupOperandKind::PassAddress);
                return "&" + out_slot;
            }

            if (method == "contains") {
                std::string result_temp = new_temporary();
                emit(IRInstruction::make_const_bool(result_temp, false));
                return result_temp;
            }

            if (method == "find") {
                std::string result_temp = new_temporary();
                emit(IRInstruction::make_const_int(result_temp, 0));
                return result_temp;
            }
        }

        if (is_builtin_map_type(object_sem_type)) {
            runtime_name = map_runtime_name(member->member.lexeme);
            if (member->member.lexeme == "toString") {
                std::string out_slot = new_temporary();
                emit(IRInstruction::make_alloca(out_slot, IRType::makeString()));
                module_.add_external_symbol("map_to_string");
                IRInstruction call;
                call.opcode = IROpcode::CallRuntime;
                call.type = IRType::makeVoid();
                call.operands = {"map_to_string", object_value, out_slot};
                emit(call);
                register_owned_value(out_slot, "string_free", CleanupOperandKind::PassAddress);
                return "&" + out_slot;
            }
        }

        if (is_builtin_file_type(object_sem_type)) {
            const std::string& method = member->member.lexeme;
            if (method == "nextLine") {
                const std::string line_slot = ensure_file_line_slot();
                module_.add_external_symbol("file_line_reader_next");
                std::string result_temp = new_temporary();
                IRInstruction call;
                call.opcode = IROpcode::CallRuntime;
                call.type = IRType::makeBoolean();
                call.result = result_temp;
                call.operands = {"file_line_reader_next", line_slot};
                emit(call);
                return result_temp;
            }
            if (method == "getLine") {
                return "&" + ensure_file_line_slot();
            }
            if (method == "close") {
                module_.add_external_symbol("file_line_reader_close");
                IRInstruction call;
                call.opcode = IROpcode::CallRuntime;
                call.type = IRType::makeVoid();
                call.operands = {"file_line_reader_close"};
                emit(call);
                return new_temporary();
            }
        }

        if (object_type.kind == IRTypeKind::String) {
            if (object_type.is_file_backed) {
                if (member->member.lexeme == "length") runtime_name = "filestring_length";
                else if (member->member.lexeme == "atIndex") runtime_name = "filestring_char_at";
                else if (member->member.lexeme == "replaceAt") runtime_name = "filestring_replace_char_at";
            } else {
                if (member->member.lexeme == "length") runtime_name = "string_length";
                else if (member->member.lexeme == "atIndex") runtime_name = "string_char_at";
                else if (member->member.lexeme == "equals") runtime_name = "string_equals";
                else if (member->member.lexeme == "equalsIcase") runtime_name = "string_equals_icase";
                else if (member->member.lexeme == "containString") runtime_name = "string_contains_sub";
            }
        }

        if (!runtime_name.empty()) {
            module_.add_external_symbol(runtime_name);
            std::string result_temp = new_temporary();

            IRInstruction call;
            call.opcode = IROpcode::CallRuntime;
            call.type = ret_type;
            call.result = result_temp;
            call.operands = {runtime_name};
            for (const auto& a : args) {
                call.operands.push_back(a);
            }
            emit(call);
            return result_temp;
        }

        if (const auto* object_ident = dynamic_cast<const IdentifierExpr*>(member->object.get())) {
            auto target_class = analyser_->classes().find(object_ident->name);
            if (target_class != analyser_->classes().end() &&
                target_class->second.methods.find(member->member.lexeme) != target_class->second.methods.end()) {
                std::vector<std::string> args;
                std::string null_this = new_temporary();
                IRInstruction zero_this;
                zero_this.opcode = IROpcode::ConstPtr;
                zero_this.type = IRType::makePointer();
                zero_this.result = null_this;
                emit(zero_this);
                args.push_back(null_this);
                for (const auto& arg : expr.arguments) {
                    args.push_back(visitExpression(*arg));
                }

                std::string result_temp = new_temporary();
                IRType ret_type = get_expr_type(expr);
                std::string mangled = object_ident->name + "_" + member->member.lexeme;
                module_.add_external_symbol(mangled);

                IRInstruction call;
                call.opcode = IROpcode::CallRuntime;
                call.type = ret_type;
                call.result = result_temp;
                call.operands = {mangled};
                for (const auto& a : args) {
                    call.operands.push_back(a);
                }
                emit(call);
                return result_temp;
            }
        }
    }

    return new_temporary();
}

std::string IRGenerator::visitMember(const MemberExpr& expr) {
    std::string obj = visitExpression(*expr.object);
    std::string dest = new_temporary();
    IRType object_type = get_expr_type(*expr.object);

    // Check if it's followed by a call (handled in visitCall)
    // For now, just mark member access

    if (expr.member.lexeme == "length" && object_type.kind == IRTypeKind::String) {
        const std::string runtime_name = object_type.is_file_backed ? "filestring_length" : "string_length";
        module_.add_external_symbol(runtime_name);
        IRInstruction call;
        call.opcode = IROpcode::CallRuntime;
        call.type = IRType::makeInteger();
        call.result = dest;
        call.operands = {runtime_name, obj};
        emit(call);
        return dest;
    }

    if (expr.member.lexeme == "contains" || expr.member.lexeme == "add" ||
        expr.member.lexeme == "find" || expr.member.lexeme == "size" ||
        expr.member.lexeme == "get" || expr.member.lexeme == "remove" ||
        expr.member.lexeme == "filter" || expr.member.lexeme == "join" ||
        expr.member.lexeme == "sort" || expr.member.lexeme == "equals" ||
        expr.member.lexeme == "equalsIcase" || expr.member.lexeme == "containString" ||
        expr.member.lexeme == "atIndex" || expr.member.lexeme == "replaceAt" ||
        expr.member.lexeme == "length") {
        // This will be handled by the parent call
        dest = obj;
    } else {
        dest = obj;
    }

    return dest;
}

std::string IRGenerator::visitIndex(const IndexExpr& expr) {
    std::string obj = visitExpression(*expr.object);
    std::string idx = visitExpression(*expr.index);
    std::string dest = new_temporary();

    IRInstruction arr_get;
    arr_get.opcode = IROpcode::ArrayGet;
    arr_get.type = get_expr_type(expr);
    arr_get.result = dest;
    arr_get.operands = {obj, idx};
    emit(arr_get);

    return dest;
}

std::string IRGenerator::visitGrouping(const GroupingExpr& expr) {
    return visitExpression(*expr.inner);
}

std::string IRGenerator::visitArrayLiteral(const ArrayLiteralExpr& expr) {
    std::string dest = new_temporary();
    std::size_t count = expr.elements.size();
    std::size_t initial_capacity = count == 0 ? 4 : count + 4;

    // Create array with spare capacity so later add(...) calls can append.
    std::string capacity_val = new_temporary();
    emit(IRInstruction::make_const_int(capacity_val, static_cast<int64_t>(initial_capacity)));

    IRInstruction arr_new;
    arr_new.opcode = IROpcode::ArrayNew;
    arr_new.type = IRType::makeArray(IRType::makePointer());
    arr_new.result = dest;
    arr_new.operands = {capacity_val};
    emit(arr_new);

    module_.add_external_symbol("array_create");
    register_owned_value(dest, "array_free", CleanupOperandKind::DirectValue);

    // Initialize elements
    for (std::size_t i = 0; i < count; ++i) {
        std::string idx = new_temporary();
        emit(IRInstruction::make_const_int(idx, static_cast<int64_t>(i)));

        std::string val = visitExpression(*expr.elements[i]);

        IRInstruction arr_set;
        arr_set.opcode = IROpcode::ArraySet;
        arr_set.type = IRType::makeVoid();
        arr_set.operands = {dest, idx, val};
        emit(arr_set);
    }

    return dest;
}

std::string IRGenerator::visitLambda(const LambdaExpr& expr) {
    std::string lambda_name = "__lambda_" + std::to_string(lambda_counter_++);

    // Create lambda function
    std::vector<IRParameter> params;
    for (const auto& param : expr.parameters) {
        IRType param_type;
        if (param.type.name == "Integer") param_type = IRType::makeInteger();
        else if (param.type.name == "Long") param_type = IRType::makeLong();
        else if (param.type.name == "Double") param_type = IRType::makeDouble();
        else if (param.type.name == "Boolean") param_type = IRType::makeBoolean();
        else if (param.type.name == "String") param_type = IRType::makeString();
        else param_type = IRType::makePointer();
        params.push_back({param.name.lexeme, param_type});
    }

    std::string saved_function_name;
    std::string saved_block_name;
    if (current_function_) {
        saved_function_name = current_function_->name;
        if (current_function_->current_block()) {
            saved_block_name = current_function_->current_block()->name;
        }
    }

    module_.add_function(lambda_name, IRType::makeBoolean(), params);
    IRFunction* func = module_.find_function(lambda_name);

    // Add this parameter
    IRParameter this_param{"this", IRType::makePointer()};
    func->parameters.insert(func->parameters.begin(), this_param);

    func->entry_block();
    current_function_ = func;
    func->set_current_block(0);

    // Save current symbol table and create new one
    auto saved_symbols = symbol_table_;
    auto saved_owned_values = owned_values_;
    auto saved_aliases = value_aliases_;
    auto saved_scopes = scope_stack_;
    symbol_table_.clear();
    owned_values_.clear();
    value_aliases_.clear();
    scope_stack_.clear();
    push_scope();

    // Alloca for lambda parameters
    for (const auto& param : func->parameters) {
        std::string addr = new_temporary();
        emit(IRInstruction::make_alloca(addr, param.type));
        symbol_table_[param.name] = addr;
        emit(IRInstruction::make_store(param.name, addr));
    }

    // Visit lambda body
    for (const auto& stmt : expr.body) {
        if (stmt) visitStatement(*stmt);
    }

    // Restore symbol table
    symbol_table_ = saved_symbols;
    owned_values_ = saved_owned_values;
    value_aliases_ = saved_aliases;
    scope_stack_ = saved_scopes;
    current_function_ = saved_function_name.empty() ? nullptr : module_.find_function(saved_function_name);
    if (current_function_ && !saved_block_name.empty()) {
        for (std::size_t i = 0; i < current_function_->blocks.size(); ++i) {
            if (current_function_->blocks[i].name == saved_block_name) {
                current_function_->set_current_block(i);
                break;
            }
        }
    }

    // Return pointer to lambda
    std::string dest = new_temporary();
    IRInstruction inst;
    inst.opcode = IROpcode::ConstPtr;
    inst.type = IRType::makePointer();
    inst.result = dest;
    inst.string_value = lambda_name;
    emit(inst);

    return dest;
}

std::string IRGenerator::new_temporary() {
    return "%t" + std::to_string(temp_counter_++);
}

std::string IRGenerator::new_label() {
    return "L" + std::to_string(label_counter_++);
}

void IRGenerator::emit(const IRInstruction& inst) {
    if (current_function_ && current_function_->current_block()) {
        current_function_->current_block()->add_instruction(inst);
    }
}

void IRGenerator::push_scope() {
    scope_stack_.push_back(ScopeFrame{});
}

void IRGenerator::pop_scope() {
    if (scope_stack_.empty()) return;
    ScopeFrame scope = scope_stack_.back();
    scope_stack_.pop_back();
    if (!current_function_ || !current_function_->current_block() || current_function_->current_block()->is_terminated()) {
        for (auto it = scope.owned_value_order.rbegin(); it != scope.owned_value_order.rend(); ++it) {
            owned_values_.erase(*it);
        }
        return;
    }
    for (auto it = scope.owned_value_order.rbegin(); it != scope.owned_value_order.rend(); ++it) {
        auto owned_it = owned_values_.find(*it);
        if (owned_it == owned_values_.end()) continue;
        emit_cleanup(owned_it->first, owned_it->second);
        owned_values_.erase(owned_it);
    }
}

void IRGenerator::emit_all_scope_cleanups(const std::unordered_set<std::string>& preserved) {
    if (!current_function_ || !current_function_->current_block() || current_function_->current_block()->is_terminated()) {
        return;
    }
    for (auto scope_it = scope_stack_.rbegin(); scope_it != scope_stack_.rend(); ++scope_it) {
        for (auto value_it = scope_it->owned_value_order.rbegin(); value_it != scope_it->owned_value_order.rend(); ++value_it) {
            auto owned_it = owned_values_.find(*value_it);
            if (owned_it == owned_values_.end()) continue;
            if (preserved.find(owned_it->first) != preserved.end()) continue;
            emit_cleanup(owned_it->first, owned_it->second);
            owned_values_.erase(owned_it);
        }
    }
}

void IRGenerator::emit_cleanup(const std::string& value_name, const OwnedValueInfo& info) {
    if (info.runtime_func.empty()) return;
    module_.add_external_symbol(info.runtime_func);
    std::string operand = value_name;
    if (info.operand_kind == CleanupOperandKind::LoadFromAddress) {
        std::string loaded = new_temporary();
        emit(IRInstruction::make_load(loaded, value_name, IRType::makePointer()));
        operand = loaded;
    } else if (info.operand_kind == CleanupOperandKind::PassAddress) {
        operand = "&" + value_name;
    }
    IRInstruction call;
    call.opcode = IROpcode::CallRuntime;
    call.type = IRType::makeVoid();
    call.operands = {info.runtime_func, operand};
    emit(call);
}

void IRGenerator::register_owned_value(const std::string& value_name,
                                       const std::string& runtime_func,
                                       CleanupOperandKind operand_kind) {
    if (value_name.empty() || runtime_func.empty() || scope_stack_.empty()) return;
    if (owned_values_.find(value_name) != owned_values_.end()) return;
    owned_values_[value_name] = OwnedValueInfo{runtime_func, operand_kind};
    scope_stack_.back().owned_value_order.push_back(value_name);
}

void IRGenerator::release_owned_value(const std::string& value_name) {
    owned_values_.erase(value_name);
}

void IRGenerator::transfer_ownership(const std::string& from_value,
                                     const std::string& to_value,
                                     CleanupOperandKind operand_kind) {
    auto it = owned_values_.find(from_value);
    if (it == owned_values_.end()) return;
    const std::string runtime_func = it->second.runtime_func;
    owned_values_.erase(it);
    register_owned_value(to_value, runtime_func, operand_kind);
}

void IRGenerator::assign_owned_value(const std::string& target_addr,
                                     const std::string& value_name,
                                     const IRType& type) {
    if (target_addr.empty()) return;
    release_owned_value(target_addr);
    OwnedValueInfo cleanup = cleanup_info_for_ir_type(type, true);
    if (cleanup.runtime_func.empty()) return;
    const std::string owner_value = strip_address_marker(value_name);
    auto existing_owner = owned_values_.find(owner_value);
    if (existing_owner != owned_values_.end()) {
        transfer_ownership(owner_value, target_addr, existing_owner->second.operand_kind);
        return;
    }
    register_owned_value(target_addr, cleanup.runtime_func, cleanup.operand_kind);
}

void IRGenerator::free_owned_storage_before_store(const std::string& target_addr) {
    auto it = owned_values_.find(target_addr);
    if (it == owned_values_.end()) return;
    emit_cleanup(it->first, it->second);
    owned_values_.erase(it);
}

IRGenerator::OwnedValueInfo IRGenerator::cleanup_info_for_ir_type(const IRType& type, bool for_storage) const {
    switch (type.kind) {
        case IRTypeKind::String:
            if (type.is_file_backed) {
                return {"filestring_free", CleanupOperandKind::PassAddress};
            }
            return {"string_free", for_storage ? CleanupOperandKind::LoadFromAddress
                                               : CleanupOperandKind::DirectValue};
        case IRTypeKind::Integer:
            if (type.is_file_backed) return {"fileint_free", CleanupOperandKind::PassAddress};
            return {};
        case IRTypeKind::Long:
            if (type.is_file_backed) return {"filelong_free", CleanupOperandKind::PassAddress};
            return {};
        case IRTypeKind::Double:
            if (type.is_file_backed) return {"filedouble_free", CleanupOperandKind::PassAddress};
            return {};
        case IRTypeKind::Boolean:
            if (type.is_file_backed) return {"filebool_free", CleanupOperandKind::PassAddress};
            return {};
        case IRTypeKind::Array:
            return {"array_free", for_storage ? CleanupOperandKind::LoadFromAddress
                                              : CleanupOperandKind::DirectValue};
        default:
            return {};
    }
}

std::string IRGenerator::preserved_owner_for_return(const Expr& expr, const std::string& value_name) const {
    auto owned_it = owned_values_.find(value_name);
    if (owned_it != owned_values_.end()) {
        return value_name;
    }
    auto alias_it = value_aliases_.find(value_name);
    if (alias_it != value_aliases_.end()) {
        auto source_it = owned_values_.find(alias_it->second);
        if (source_it != owned_values_.end()) {
            return source_it->first;
        }
    }
    if (expr.kind == ExprKind::Grouping) {
        return preserved_owner_for_return(*static_cast<const GroupingExpr&>(expr).inner, value_name);
    }
    return "";
}

void IRGenerator::add_successor(const std::string& name) {
    if (current_function_ && current_function_->current_block()) {
        current_function_->current_block()->successors.push_back(name);
    }
}

std::string IRGenerator::load_symbol_value(const std::string& name, const IRType& type) {
    auto it = symbol_table_.find(name);
    if (it == symbol_table_.end()) return name;
    std::string val = new_temporary();
    emit(IRInstruction::make_load(val, it->second, type));
    return val;
}

std::string IRGenerator::emit_string_constant(const std::string& value, bool raw_cstr_data) {
    const std::string str_name = "str_" + std::to_string(string_constants_.size());
    string_constants_[str_name] = value;
    module_.add_string_constant(str_name, value);

    std::string temp = new_temporary();
    IRInstruction inst;
    inst.opcode = IROpcode::ConstPtr;
    inst.type = raw_cstr_data ? IRType::makePointer() : IRType::makeString();
    inst.result = temp;
    inst.string_value = raw_cstr_data ? (str_name + "_data") : str_name;
    emit(inst);
    return temp;
}

std::string IRGenerator::ensure_file_line_slot() {
    auto it = symbol_table_.find("__file_line_current");
    if (it != symbol_table_.end()) return it->second;
    std::string addr = new_temporary();
    emit(IRInstruction::make_alloca(addr, IRType::makeString()));
    symbol_table_["__file_line_current"] = addr;
    return addr;
}

IRType IRGenerator::get_expr_type(const Expr& expr) {
    SemanticType st = analyser_->expressionType(&expr);
    return semantic_to_ir_type(st);
}

std::string IRGenerator::type_suffix(const IRType& type) {
    switch (type.kind) {
        case IRTypeKind::Integer: return "_int";
        case IRTypeKind::Long: return "_long";
        case IRTypeKind::Double: return "_double";
        case IRTypeKind::Boolean: return "_bool";
        case IRTypeKind::String: return "_string";
        case IRTypeKind::Array: return "_array";
        default: return "_ptr";
    }
}
