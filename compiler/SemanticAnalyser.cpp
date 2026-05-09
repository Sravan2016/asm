#include "SemanticAnalyser.h"

#include <cctype>
#include <sstream>
#include <utility>

namespace {

template <typename MapType>
bool contains_key(const MapType& map, const std::string& key) {
    return map.find(key) != map.end();
}

bool is_builtin_class_name(const std::string& name) {
    return name == "Map" || name == "File";
}

bool is_builtin_map_type(const SemanticType& type) {
    return type.kind == SemanticTypeKind::Class && type.name == "Map";
}

bool is_builtin_file_type(const SemanticType& type) {
    return type.kind == SemanticTypeKind::Class && type.name == "File";
}

bool has_parent(const ClassDecl& class_decl, const std::string& parent_name) {
    for (const Token& parent : class_decl.parents) {
        if (parent.lexeme == parent_name) return true;
    }
    return false;
}

std::string accessor_suffix_for_field(const std::string& field_name) {
    if (field_name.empty()) return field_name;
    std::string suffix = field_name;
    suffix[0] = static_cast<char>(std::toupper(static_cast<unsigned char>(suffix[0])));
    return suffix;
}

} // namespace

SemanticType SemanticType::makeError() { return {SemanticTypeKind::Error, "error", nullptr, false}; }
SemanticType SemanticType::makeUnknown() { return {SemanticTypeKind::Unknown, "unknown", nullptr, false}; }
SemanticType SemanticType::makeVoid() { return {SemanticTypeKind::Void, "Void", nullptr, false}; }
SemanticType SemanticType::makeInteger(bool is_file_backed) { return {SemanticTypeKind::Integer, "Integer", nullptr, is_file_backed}; }
SemanticType SemanticType::makeString(bool is_file_backed) { return {SemanticTypeKind::String, "String", nullptr, is_file_backed}; }
SemanticType SemanticType::makeLong(bool is_file_backed) { return {SemanticTypeKind::Long, "Long", nullptr, is_file_backed}; }
SemanticType SemanticType::makeDouble(bool is_file_backed) { return {SemanticTypeKind::Double, "Double", nullptr, is_file_backed}; }
SemanticType SemanticType::makeBoolean(bool is_file_backed) { return {SemanticTypeKind::Boolean, "Boolean", nullptr, is_file_backed}; }
SemanticType SemanticType::makeClass(std::string class_name, bool is_file_backed) { return {SemanticTypeKind::Class, std::move(class_name), nullptr, is_file_backed}; }
SemanticType SemanticType::makeArray(SemanticType element, bool is_file_backed) {
    SemanticType array_type;
    array_type.kind = SemanticTypeKind::Array;
    array_type.name = "Array";
    array_type.element_type = std::make_shared<SemanticType>(std::move(element));
    array_type.is_file_backed = is_file_backed;
    return array_type;
}

bool SemanticAnalyser::analyse(const Program& program) {
    program_ = &program;
    classes_.clear();
    scopes_.clear();
    expression_types_.clear();
    errors_.clear();
    current_class_ = nullptr;
    current_method_ = nullptr;

    if (!collectDeclarations(program)) {
        return false;
    }

    for (const auto& class_decl : program.classes) {
        if (class_decl) {
            analyseClass(*class_decl);
        }
    }

    return errors_.empty();
}

const std::vector<SemanticError>& SemanticAnalyser::errors() const {
    return errors_;
}

bool SemanticAnalyser::hasErrors() const {
    return !errors_.empty();
}

SemanticType SemanticAnalyser::expressionType(const Expr* expr) const {
    if (!expr) return SemanticType::makeError();
    const auto it = expression_types_.find(expr);
    if (it == expression_types_.end()) return SemanticType::makeUnknown();
    return it->second;
}

const std::unordered_map<std::string, SemanticClassSymbol>& SemanticAnalyser::classes() const {
    return classes_;
}

bool SemanticAnalyser::collectDeclarations(const Program& program) {
    for (const auto& class_decl_ptr : program.classes) {
        if (!class_decl_ptr) continue;
        const ClassDecl& class_decl = *class_decl_ptr;
        if (contains_key(classes_, class_decl.name.lexeme)) {
            addError(class_decl.name.start, "duplicate class declaration '" + class_decl.name.lexeme + "'");
            continue;
        }

        SemanticClassSymbol class_symbol;
        class_symbol.name = class_decl.name.lexeme;
        class_symbol.declaration = &class_decl;

        for (const Token& parent : class_decl.parents) {
            class_symbol.parents.push_back(parent.lexeme);
        }

        for (const ClassMember& member : class_decl.members) {
            if (member.kind == ClassMember::Kind::Statement && member.statement &&
                member.statement->kind == StmtKind::VariableDecl) {
                const auto& decl_stmt = static_cast<const VariableDeclStmt&>(*member.statement);
                if (contains_key(class_symbol.fields, decl_stmt.name.lexeme)) {
                    addError(decl_stmt.name.start, "duplicate field declaration '" + decl_stmt.name.lexeme + "'");
                } else {
                    SemanticVariableSymbol field_symbol;
                    field_symbol.name = decl_stmt.name.lexeme;
                    field_symbol.type = resolveType(decl_stmt.type, decl_stmt.name.start);
                    field_symbol.location = decl_stmt.name.start;
                    field_symbol.implicit = false;
                    class_symbol.fields.emplace(field_symbol.name, std::move(field_symbol));
                }
                continue;
            }
            if (member.kind != ClassMember::Kind::Method || !member.method) continue;
            const MethodDecl& method_decl = *member.method;
            if (contains_key(class_symbol.methods, method_decl.name.lexeme)) {
                addError(method_decl.name.start, "duplicate method declaration '" + method_decl.name.lexeme + "'");
                continue;
            }

            SemanticMethodSymbol method_symbol;
            method_symbol.name = method_decl.name.lexeme;
            method_symbol.declaration = &method_decl;
            method_symbol.is_private = method_decl.isPrivate;
            method_symbol.return_type = SemanticType::makeUnknown();
            for (const ParameterDecl& parameter : method_decl.parameters) {
                method_symbol.parameter_types.push_back(resolveType(parameter.type, parameter.name.start));
            }
            class_symbol.methods.emplace(method_symbol.name, std::move(method_symbol));
        }

        if (has_parent(class_decl, "Aleka")) {
            for (const ClassMember& member : class_decl.members) {
                if (member.kind != ClassMember::Kind::Statement || !member.statement ||
                    member.statement->kind != StmtKind::VariableDecl) {
                    continue;
                }
                const auto& field_decl = static_cast<const VariableDeclStmt&>(*member.statement);
                const SemanticType field_type = resolveType(field_decl.type, field_decl.name.start);
                const std::string suffix = accessor_suffix_for_field(field_decl.name.lexeme);

                const std::string getter_name = "get" + suffix;
                if (!contains_key(class_symbol.methods, getter_name)) {
                    SemanticMethodSymbol getter_symbol;
                    getter_symbol.name = getter_name;
                    getter_symbol.return_type = field_type;
                    class_symbol.methods.emplace(getter_name, std::move(getter_symbol));
                }

                const std::string setter_name = "set" + suffix;
                if (!contains_key(class_symbol.methods, setter_name)) {
                    SemanticMethodSymbol setter_symbol;
                    setter_symbol.name = setter_name;
                    setter_symbol.return_type = SemanticType::makeVoid();
                    setter_symbol.parameter_types.push_back(field_type);
                    class_symbol.methods.emplace(setter_name, std::move(setter_symbol));
                }
            }

            if (!contains_key(class_symbol.methods, "of")) {
                SemanticMethodSymbol of_symbol;
                of_symbol.name = "of";
                of_symbol.return_type = SemanticType::makeClass(class_decl.name.lexeme);
                for (const ClassMember& member : class_decl.members) {
                    if (member.kind != ClassMember::Kind::Statement || !member.statement ||
                        member.statement->kind != StmtKind::VariableDecl) {
                        continue;
                    }
                    const auto& field_decl = static_cast<const VariableDeclStmt&>(*member.statement);
                    of_symbol.parameter_types.push_back(resolveType(field_decl.type, field_decl.name.start));
                }
                class_symbol.methods.emplace("of", std::move(of_symbol));
            }

            if (!contains_key(class_symbol.methods, "toString")) {
                SemanticMethodSymbol to_string_symbol;
                to_string_symbol.name = "toString";
                to_string_symbol.return_type = SemanticType::makeString();
                class_symbol.methods.emplace("toString", std::move(to_string_symbol));
            }

            if (!contains_key(class_symbol.methods, "toObject")) {
                SemanticMethodSymbol to_object_symbol;
                to_object_symbol.name = "toObject";
                to_object_symbol.return_type = SemanticType::makeClass(class_decl.name.lexeme);
                to_object_symbol.parameter_types.push_back(SemanticType::makeString());
                class_symbol.methods.emplace("toObject", std::move(to_object_symbol));
            }
        }

        classes_.emplace(class_symbol.name, std::move(class_symbol));
    }

    return errors_.empty();
}

void SemanticAnalyser::analyseClass(const ClassDecl& class_decl) {
    auto class_it = classes_.find(class_decl.name.lexeme);
    if (class_it == classes_.end()) return;

    current_class_ = &class_it->second;
    current_method_ = nullptr;
    scopes_.clear();

    for (const ClassMember& member : class_decl.members) {
        if (member.kind == ClassMember::Kind::Statement && member.statement &&
            member.statement->kind == StmtKind::VariableDecl) {
            const auto& decl_stmt = static_cast<const VariableDeclStmt&>(*member.statement);
            auto field_it = current_class_->fields.find(decl_stmt.name.lexeme);
            if (field_it != current_class_->fields.end() && decl_stmt.initializer) {
                const SemanticType init_type = analyseExpr(*decl_stmt.initializer);
                if (!isAssignable(field_it->second.type, init_type)) {
                    addError(decl_stmt.name.start,
                             "cannot assign " + describeType(init_type) + " to " + describeType(field_it->second.type));
                }
            }
        }
    }

    for (const ClassMember& member : class_decl.members) {
        if (member.kind != ClassMember::Kind::Method || !member.method) continue;
        auto method_it = current_class_->methods.find(member.method->name.lexeme);
        if (method_it != current_class_->methods.end()) {
            analyseMethod(*member.method, method_it->second);
        }
    }

    scopes_.clear();
    current_class_ = nullptr;
}

void SemanticAnalyser::analyseMethod(const MethodDecl& method_decl, SemanticMethodSymbol& method_symbol) {
    current_method_ = &method_symbol;
    scopes_.clear();
    pushScope();

    for (std::size_t i = 0; i < method_decl.parameters.size(); ++i) {
        const ParameterDecl& parameter = method_decl.parameters[i];
        const SemanticType parameter_type = i < method_symbol.parameter_types.size()
                                                ? method_symbol.parameter_types[i]
                                                : resolveType(parameter.type, parameter.name.start);
        declareVariable(parameter.name, parameter_type, false);
    }

    for (const auto& stmt : method_decl.body) {
        if (stmt) analyseStatement(*stmt);
    }

    if (method_decl.returnValue) {
        method_symbol.return_type = analyseExpr(*method_decl.returnValue);
    } else {
        method_symbol.return_type = SemanticType::makeVoid();
    }

    popScope();
    current_method_ = nullptr;
}

void SemanticAnalyser::analyseStatement(const Stmt& stmt) {
    switch (stmt.kind) {
        case StmtKind::Expression: {
            const auto& expr_stmt = static_cast<const ExprStmt&>(stmt);
            if (expr_stmt.expression) analyseExpr(*expr_stmt.expression);
            break;
        }
        case StmtKind::VariableDecl: {
            const auto& decl_stmt = static_cast<const VariableDeclStmt&>(stmt);
            const SemanticType declared_type = resolveType(decl_stmt.type, decl_stmt.name.start);
            declareVariable(decl_stmt.name, declared_type, false);
            if (decl_stmt.initializer) {
                const SemanticType init_type = analyseExpr(*decl_stmt.initializer);
                if (!isAssignable(declared_type, init_type)) {
                    addError(decl_stmt.name.start,
                             "cannot assign " + describeType(init_type) + " to " + describeType(declared_type));
                }
            }
            break;
        }
        case StmtKind::Print: {
            const auto& print_stmt = static_cast<const PrintStmt&>(stmt);
            if (print_stmt.expression) analyseExpr(*print_stmt.expression);
            break;
        }
        case StmtKind::GuardBlock: {
            const auto& guard_stmt = static_cast<const GuardBlockStmt&>(stmt);
            if (guard_stmt.condition) {
                const SemanticType cond_type = analyseExpr(*guard_stmt.condition);
                if (!isBoolean(cond_type) && cond_type.kind != SemanticTypeKind::Error &&
                    cond_type.kind != SemanticTypeKind::Unknown) {
                    addError(guard_stmt.condition->start,
                             "guard condition must be Boolean, got " + describeType(cond_type));
                }
            }
            pushScope();
            for (const auto& body_stmt : guard_stmt.body) {
                if (body_stmt) analyseStatement(*body_stmt);
            }
            popScope();
            if (!guard_stmt.elseBody.empty()) {
                pushScope();
                for (const auto& body_stmt : guard_stmt.elseBody) {
                    if (body_stmt) analyseStatement(*body_stmt);
                }
                popScope();
            }
            break;
        }
        case StmtKind::ForEach: {
            const auto& foreach_stmt = static_cast<const ForEachStmt&>(stmt);
            const SemanticType iterable_type = foreach_stmt.iterable ? analyseExpr(*foreach_stmt.iterable)
                                                                     : SemanticType::makeError();
            SemanticType element_type = SemanticType::makeUnknown();
            if (iterable_type.kind == SemanticTypeKind::Array && iterable_type.element_type) {
                element_type = *iterable_type.element_type;
            } else if (iterable_type.kind != SemanticTypeKind::Error && iterable_type.kind != SemanticTypeKind::Unknown) {
                addError(foreach_stmt.name.start,
                         "foreach source must be an array, got " + describeType(iterable_type));
            }

            const SemanticType loop_type = resolveType(foreach_stmt.type, foreach_stmt.name.start);
            if (element_type.kind != SemanticTypeKind::Unknown && !isAssignable(loop_type, element_type)) {
                addError(foreach_stmt.name.start,
                         "foreach variable type " + describeType(loop_type) +
                             " does not match iterable element type " + describeType(element_type));
            }

            pushScope();
            declareVariable(foreach_stmt.name, loop_type, false);
            for (const auto& body_stmt : foreach_stmt.body) {
                if (body_stmt) analyseStatement(*body_stmt);
            }
            popScope();
            break;
        }
        case StmtKind::Switch: {
            const auto& switch_stmt = static_cast<const SwitchStmt&>(stmt);
            const SemanticType subject_type = switch_stmt.subject ? analyseExpr(*switch_stmt.subject)
                                                                  : SemanticType::makeError();
            std::unordered_map<std::string, bool> seen_labels;
            for (const SwitchCase& switch_case : switch_stmt.cases) {
                if (!switch_case.isDefault && switch_case.label) {
                    const SemanticType label_type = analyseExpr(*switch_case.label);
                    if (!isAssignable(subject_type, label_type) && !isAssignable(label_type, subject_type) &&
                        subject_type.kind != SemanticTypeKind::Unknown && label_type.kind != SemanticTypeKind::Unknown &&
                        subject_type.kind != SemanticTypeKind::Error && label_type.kind != SemanticTypeKind::Error) {
                        addError(switch_case.start,
                                 "switch case type " + describeType(label_type) +
                                     " does not match subject type " + describeType(subject_type));
                    }

                    if (switch_case.label->kind == ExprKind::IntegerLiteral ||
                        switch_case.label->kind == ExprKind::StringLiteral ||
                        switch_case.label->kind == ExprKind::BooleanLiteral ||
                        switch_case.label->kind == ExprKind::Identifier) {
                        const auto* label_expr = dynamic_cast<const LiteralExpr*>(switch_case.label.get());
                        const auto* ident_expr = dynamic_cast<const IdentifierExpr*>(switch_case.label.get());
                        const std::string label_key =
                            label_expr ? label_expr->value : (ident_expr ? ident_expr->name : std::string{});
                        if (!label_key.empty()) {
                            if (contains_key(seen_labels, label_key)) {
                                addError(switch_case.start, "duplicate switch case label '" + label_key + "'");
                            } else {
                                seen_labels.emplace(label_key, true);
                            }
                        }
                    }
                }

                pushScope();
                for (const auto& body_stmt : switch_case.body) {
                    if (body_stmt) analyseStatement(*body_stmt);
                }
                popScope();
            }
            break;
        }
        case StmtKind::Return: {
            const auto& return_stmt = static_cast<const ReturnStmt&>(stmt);
            if (return_stmt.expression) {
                analyseExpr(*return_stmt.expression);
            }
            break;
        }
    }
}

SemanticType SemanticAnalyser::analyseExpr(const Expr& expr) {
    switch (expr.kind) {
        case ExprKind::Identifier: {
            const auto& ident = static_cast<const IdentifierExpr&>(expr);
            if (SemanticVariableSymbol* symbol = lookupVariable(ident.name)) {
                rememberExprType(expr, symbol->type);
                return symbol->type;
            }
            if (lookupCurrentClassMethod(ident.name)) {
                const SemanticType type = SemanticType::makeUnknown();
                rememberExprType(expr, type);
                return type;
            }
            if (lookupClass(ident.name)) {
                const SemanticType type = SemanticType::makeClass(ident.name);
                rememberExprType(expr, type);
                return type;
            }
            if (is_builtin_class_name(ident.name)) {
                const SemanticType type = SemanticType::makeClass(ident.name);
                rememberExprType(expr, type);
                return type;
            }
            addError(expr.start, "undeclared identifier '" + ident.name + "'");
            rememberExprType(expr, SemanticType::makeError());
            return SemanticType::makeError();
        }
        case ExprKind::IntegerLiteral: {
            const SemanticType type = SemanticType::makeInteger();
            rememberExprType(expr, type);
            return type;
        }
        case ExprKind::LongLiteral: {
            const SemanticType type = SemanticType::makeLong();
            rememberExprType(expr, type);
            return type;
        }
        case ExprKind::DoubleLiteral: {
            const SemanticType type = SemanticType::makeDouble();
            rememberExprType(expr, type);
            return type;
        }
        case ExprKind::StringLiteral: {
            const SemanticType type = SemanticType::makeString();
            rememberExprType(expr, type);
            return type;
        }
        case ExprKind::BooleanLiteral: {
            const SemanticType type = SemanticType::makeBoolean();
            rememberExprType(expr, type);
            return type;
        }
        case ExprKind::Unary:
            return analyseUnaryExpr(static_cast<const UnaryExpr&>(expr));
        case ExprKind::Binary:
            return analyseBinaryExpr(static_cast<const BinaryExpr&>(expr));
        case ExprKind::Assignment:
            return analyseAssignmentExpr(static_cast<const AssignmentExpr&>(expr));
        case ExprKind::Conditional:
            return analyseConditionalExpr(static_cast<const ConditionalExpr&>(expr));
        case ExprKind::Call:
            return analyseCallExpr(static_cast<const CallExpr&>(expr));
        case ExprKind::Member:
            return analyseMemberExpr(static_cast<const MemberExpr&>(expr));
        case ExprKind::Index: {
            const auto& index_expr = static_cast<const IndexExpr&>(expr);
            const SemanticType object_type = index_expr.object ? analyseExpr(*index_expr.object) : SemanticType::makeError();
            const SemanticType index_type = index_expr.index ? analyseExpr(*index_expr.index) : SemanticType::makeError();
            if (!isNumeric(index_type) && index_type.kind != SemanticTypeKind::Error &&
                index_type.kind != SemanticTypeKind::Unknown) {
                addError(expr.start, "array index must be numeric, got " + describeType(index_type));
            }
            if (object_type.kind == SemanticTypeKind::Array && object_type.element_type) {
                rememberExprType(expr, *object_type.element_type);
                return *object_type.element_type;
            }
            if (object_type.kind != SemanticTypeKind::Error && object_type.kind != SemanticTypeKind::Unknown) {
                addError(expr.start, "indexed expression must be an array, got " + describeType(object_type));
            }
            rememberExprType(expr, SemanticType::makeError());
            return SemanticType::makeError();
        }
        case ExprKind::Postfix:
            return analysePostfixExpr(static_cast<const PostfixExpr&>(expr));
        case ExprKind::Grouping: {
            const auto& group = static_cast<const GroupingExpr&>(expr);
            const SemanticType type = group.inner ? analyseExpr(*group.inner) : SemanticType::makeError();
            rememberExprType(expr, type);
            return type;
        }
        case ExprKind::ArrayLiteral:
            return analyseArrayLiteralExpr(static_cast<const ArrayLiteralExpr&>(expr));
        case ExprKind::Lambda: {
            const auto& lambda_expr = static_cast<const LambdaExpr&>(expr);
            pushScope();
            for (const ParameterDecl& param : lambda_expr.parameters) {
                SemanticType param_type = resolveType(param.type, param.name.start);
                declareVariable(param.name, param_type, false);
            }
            for (const auto& body_stmt : lambda_expr.body) {
                if (body_stmt) analyseStatement(*body_stmt);
            }
            popScope();
            const SemanticType type = SemanticType::makeUnknown();
            rememberExprType(expr, type);
            return type;
        }
    }

    rememberExprType(expr, SemanticType::makeError());
    return SemanticType::makeError();
}

SemanticType SemanticAnalyser::analyseCallExpr(const CallExpr& expr) {
    const SemanticMethodSymbol* method_symbol = nullptr;
    const SemanticClassSymbol* owner_class = nullptr;

    if (const auto* ident = dynamic_cast<const IdentifierExpr*>(expr.callee.get())) {
        if (ident->name == "print" || ident->name == "println") {
            for (const auto& arg : expr.arguments) {
                if (arg) analyseExpr(*arg);
            }
            const SemanticType result = SemanticType::makeVoid();
            rememberExprType(expr, result);
            return result;
        }
        method_symbol = findMethodInClassHierarchy(current_class_, ident->name, &owner_class);
        if (!method_symbol) {
            if (current_class_) {
                for (const std::string& parent_name : current_class_->parents) {
                    auto parent_it = classes_.find(parent_name);
                    if (parent_it != classes_.end() && parent_it->second.methods.empty()) {
                        for (const auto& arg : expr.arguments) {
                            if (arg) analyseExpr(*arg);
                        }
                        const SemanticType result = SemanticType::makeUnknown();
                        rememberExprType(expr, result);
                        return result;
                    }
                }
            }
            addError(expr.start, "unknown callable '" + ident->name + "'");
            rememberExprType(expr, SemanticType::makeError());
            return SemanticType::makeError();
        }
        if (!canAccessMethod(owner_class, *method_symbol)) {
            addError(expr.start, "method '" + ident->name + "' is private");
            rememberExprType(expr, SemanticType::makeError());
            return SemanticType::makeError();
        }
    } else if (const auto* member = dynamic_cast<const MemberExpr*>(expr.callee.get())) {
        if (const auto* object_ident = dynamic_cast<const IdentifierExpr*>(member->object.get())) {
            if (const SemanticClassSymbol* class_symbol = lookupClass(object_ident->name)) {
                method_symbol = findMethodInClassHierarchy(class_symbol, member->member.lexeme, &owner_class);
            }
            if (!method_symbol && object_ident->name == "Map") {
                for (const auto& arg : expr.arguments) {
                    if (arg) analyseExpr(*arg);
                }
                SemanticType result = SemanticType::makeUnknown();
                if (member->member.lexeme == "of" || member->member.lexeme == "create") {
                    result = SemanticType::makeClass("Map");
                }
                rememberExprType(expr, result);
                return result;
            }
            if (!method_symbol && object_ident->name == "File") {
                for (const auto& arg : expr.arguments) {
                    if (arg) analyseExpr(*arg);
                }
                SemanticType result = SemanticType::makeUnknown();
                if (member->member.lexeme == "of") result = SemanticType::makeClass("File");
                else if (member->member.lexeme == "line_reader_line_count" ||
                         member->member.lexeme == "count_lines") result = SemanticType::makeInteger();
                else if (member->member.lexeme == "line_reader_close") result = SemanticType::makeVoid();
                else if (member->member.lexeme == "read_all" ||
                         member->member.lexeme == "print_lines_count" ||
                         member->member.lexeme == "line_reader_open" ||
                         member->member.lexeme == "line_reader_next" ||
                         member->member.lexeme == "get_line_at") {
                    result = SemanticType::makeBoolean();
                }
                rememberExprType(expr, result);
                return result;
            }
        }

        if (!method_symbol && member->object) {
            const SemanticType object_type = analyseExpr(*member->object);
            if (object_type.kind == SemanticTypeKind::Class) {
                if (const SemanticClassSymbol* class_symbol = lookupClass(object_type.name)) {
                    method_symbol = findMethodInClassHierarchy(class_symbol, member->member.lexeme, &owner_class);
                }
                if (!method_symbol && is_builtin_map_type(object_type)) {
                    for (const auto& arg : expr.arguments) {
                        if (arg) analyseExpr(*arg);
                    }
                    const std::string& method = member->member.lexeme;
                    SemanticType result_type = SemanticType::makeUnknown();
                    if (method == "containsKey" || method == "isEmpty") result_type = SemanticType::makeBoolean();
                    else if (method == "size") result_type = SemanticType::makeInteger();
                    else if (method == "toString") result_type = SemanticType::makeString();
                    else if (method == "clear" || method == "free") result_type = SemanticType::makeVoid();
                    rememberExprType(expr, result_type);
                    return result_type;
                }
                if (!method_symbol && is_builtin_file_type(object_type)) {
                    for (const auto& arg : expr.arguments) {
                        if (arg) analyseExpr(*arg);
                    }
                    const std::string& method = member->member.lexeme;
                    SemanticType result_type = SemanticType::makeUnknown();
                    if (method == "nextLine") result_type = SemanticType::makeBoolean();
                    else if (method == "getLine") result_type = SemanticType::makeString();
                    else if (method == "close") result_type = SemanticType::makeVoid();
                    rememberExprType(expr, result_type);
                    return result_type;
                }
            } else if (object_type.kind == SemanticTypeKind::Unknown) {
                for (const auto& arg : expr.arguments) {
                    if (arg) analyseExpr(*arg);
                }
                const SemanticType result = SemanticType::makeUnknown();
                rememberExprType(expr, result);
                return result;
            } else if (object_type.kind == SemanticTypeKind::String) {
                const std::string& method = member->member.lexeme;
                for (const auto& arg : expr.arguments) {
                    if (arg) analyseExpr(*arg);
                }
                SemanticType result_type = SemanticType::makeUnknown();
                if (method == "equals" || method == "equalsIcase" || method == "containString") {
                    result_type = SemanticType::makeBoolean();
                } else if (method == "atIndex") {
                    result_type = SemanticType::makeInteger();
                } else if (method == "length") {
                    result_type = SemanticType::makeInteger();
                } else if (method == "concat") {
                    result_type = SemanticType::makeString(object_type.is_file_backed);
                } else if (method == "split") {
                    result_type = SemanticType::makeArray(SemanticType::makeString());
                } else if (object_type.is_file_backed && method == "replaceAt") {
                    result_type = SemanticType::makeBoolean();
                }
                rememberExprType(expr, result_type);
                return result_type;
            } else if (object_type.kind == SemanticTypeKind::Array) {
                const std::string& method = member->member.lexeme;
                if (method == "contains" || method == "add" || method == "find" ||
                    method == "size" || method == "get" || method == "remove" ||
                    method == "filter" || method == "join" || method == "sort") {
                    for (const auto& arg : expr.arguments) {
                        if (arg) analyseExpr(*arg);
                    }
                    const SemanticType element_type = object_type.element_type ? *object_type.element_type : SemanticType::makeUnknown();
                    SemanticType result_type;
                    if (method == "contains") result_type = SemanticType::makeBoolean();
                    else if (method == "add") result_type = SemanticType::makeVoid();
                    else if (method == "find") result_type = SemanticType::makeInteger();
                    else if (method == "size") result_type = SemanticType::makeInteger();
                    else if (method == "get") result_type = element_type;
                    else if (method == "remove") result_type = SemanticType::makeVoid();
                    else if (method == "filter") result_type = object_type;
                    else if (method == "join") result_type = SemanticType::makeString();
                    else if (method == "sort") result_type = object_type;
                    else result_type = SemanticType::makeUnknown();
                    rememberExprType(expr, result_type);
                    return result_type;
                }
            } else if (is_builtin_map_type(object_type)) {
                for (const auto& arg : expr.arguments) {
                    if (arg) analyseExpr(*arg);
                }
                const std::string& method = member->member.lexeme;
                SemanticType result_type = SemanticType::makeUnknown();
                if (method == "containsKey" || method == "isEmpty") result_type = SemanticType::makeBoolean();
                else if (method == "size") result_type = SemanticType::makeInteger();
                else if (method == "toString") result_type = SemanticType::makeString();
                else if (method == "clear" || method == "free") result_type = SemanticType::makeVoid();
                rememberExprType(expr, result_type);
                return result_type;
            } else if (is_builtin_file_type(object_type)) {
                for (const auto& arg : expr.arguments) {
                    if (arg) analyseExpr(*arg);
                }
                const std::string& method = member->member.lexeme;
                SemanticType result_type = SemanticType::makeUnknown();
                if (method == "nextLine") result_type = SemanticType::makeBoolean();
                else if (method == "getLine") result_type = SemanticType::makeString();
                else if (method == "close") result_type = SemanticType::makeVoid();
                rememberExprType(expr, result_type);
                return result_type;
            }
        }

        if (method_symbol && !canAccessMethod(owner_class, *method_symbol)) {
            addError(expr.start, "method '" + member->member.lexeme + "' is private");
            rememberExprType(expr, SemanticType::makeError());
            return SemanticType::makeError();
        }

        if (!method_symbol) {
            const std::string& method = member->member.lexeme;
            if (method == "put" || method == "get" || method == "containsKey" ||
                method == "remove" || method == "size" || method == "isEmpty" ||
                method == "toString" || method == "clear" || method == "free") {
                for (const auto& arg : expr.arguments) {
                    if (arg) analyseExpr(*arg);
                }
                SemanticType result_type = SemanticType::makeUnknown();
                if (method == "containsKey" || method == "isEmpty") result_type = SemanticType::makeBoolean();
                else if (method == "size") result_type = SemanticType::makeInteger();
                else if (method == "toString") result_type = SemanticType::makeString();
                else if (method == "clear" || method == "free") result_type = SemanticType::makeVoid();
                rememberExprType(expr, result_type);
                return result_type;
            }
            if (method == "nextLine" || method == "getLine" || method == "close") {
                for (const auto& arg : expr.arguments) {
                    if (arg) analyseExpr(*arg);
                }
                SemanticType result_type = SemanticType::makeUnknown();
                if (method == "nextLine") result_type = SemanticType::makeBoolean();
                else if (method == "getLine") result_type = SemanticType::makeString();
                else if (method == "close") result_type = SemanticType::makeVoid();
                rememberExprType(expr, result_type);
                return result_type;
            }
            addError(expr.start, "member '" + member->member.lexeme + "' is not callable");
            rememberExprType(expr, SemanticType::makeError());
            return SemanticType::makeError();
        }
    } else {
        addError(expr.start, "expression is not callable");
        rememberExprType(expr, SemanticType::makeError());
        return SemanticType::makeError();
    }

    if (method_symbol->parameter_types.size() != expr.arguments.size()) {
        std::ostringstream builder;
        builder << "method '" << method_symbol->name << "' expects "
                << method_symbol->parameter_types.size() << " arguments but got "
                << expr.arguments.size();
        addError(expr.start, builder.str());
    }

    for (std::size_t i = 0; i < expr.arguments.size(); ++i) {
        const SemanticType arg_type = expr.arguments[i] ? analyseExpr(*expr.arguments[i]) : SemanticType::makeError();
        if (i < method_symbol->parameter_types.size() &&
            !isAssignable(method_symbol->parameter_types[i], arg_type)) {
            addError(expr.arguments[i]->start,
                     "argument " + std::to_string(i + 1) + " of method '" + method_symbol->name +
                         "' expects " + describeType(method_symbol->parameter_types[i]) +
                         " but got " + describeType(arg_type));
        }
    }

    rememberExprType(expr, method_symbol->return_type);
    return method_symbol->return_type;
}

SemanticType SemanticAnalyser::analyseConditionalExpr(const ConditionalExpr& expr) {
    const SemanticType cond_type = expr.condition ? analyseExpr(*expr.condition) : SemanticType::makeError();
    if (!isBoolean(cond_type) && cond_type.kind != SemanticTypeKind::Error &&
        cond_type.kind != SemanticTypeKind::Unknown) {
        addError(expr.condition ? expr.condition->start : expr.start,
                 "conditional condition must be Boolean, got " + describeType(cond_type));
    }

    const SemanticType then_type = expr.thenBranch ? analyseExpr(*expr.thenBranch) : SemanticType::makeError();
    const SemanticType else_type = expr.elseBranch ? analyseExpr(*expr.elseBranch) : SemanticType::makeError();

    SemanticType result = SemanticType::makeError();
    if (areTypesEqual(then_type, else_type)) {
        result = then_type;
    } else if (isAssignable(then_type, else_type)) {
        result = then_type;
    } else if (isAssignable(else_type, then_type)) {
        result = else_type;
    } else if (then_type.kind == SemanticTypeKind::Error || else_type.kind == SemanticTypeKind::Error) {
        result = SemanticType::makeError();
    } else if (then_type.kind == SemanticTypeKind::Unknown) {
        result = else_type;
    } else if (else_type.kind == SemanticTypeKind::Unknown) {
        result = then_type;
    } else {
        addError(expr.start, "conditional branches must have compatible types, got " +
                                 describeType(then_type) + " and " + describeType(else_type));
        result = SemanticType::makeError();
    }

    rememberExprType(expr, result);
    return result;
}

SemanticType SemanticAnalyser::analyseMemberExpr(const MemberExpr& expr) {
    if (const auto* object_ident = dynamic_cast<const IdentifierExpr*>(expr.object.get())) {
        if (lookupClass(object_ident->name)) {
            const SemanticType type = SemanticType::makeUnknown();
            rememberExprType(expr, type);
            return type;
        }
        if (is_builtin_class_name(object_ident->name)) {
            const SemanticType type = SemanticType::makeUnknown();
            rememberExprType(expr, type);
            return type;
        }
    }

    const SemanticType object_type = expr.object ? analyseExpr(*expr.object) : SemanticType::makeError();
    if (object_type.kind == SemanticTypeKind::Class) {
        if (const SemanticClassSymbol* class_symbol = lookupClass(object_type.name)) {
            if (contains_key(class_symbol->fields, expr.member.lexeme)) {
                const SemanticType type = class_symbol->fields.at(expr.member.lexeme).type;
                rememberExprType(expr, type);
                return type;
            }
            if (contains_key(class_symbol->methods, expr.member.lexeme)) {
                const SemanticType type = SemanticType::makeUnknown();
                rememberExprType(expr, type);
                return type;
            }
        }
    }

    if (object_type.kind == SemanticTypeKind::Array) {
        const std::string& method = expr.member.lexeme;
        const SemanticType element_type = object_type.element_type ? *object_type.element_type : SemanticType::makeUnknown();

        if (method == "contains" || method == "add" || method == "find" ||
            method == "size" || method == "get" || method == "remove" ||
            method == "filter" || method == "join" || method == "sort") {
            SemanticType result_type;
            if (method == "contains") result_type = SemanticType::makeBoolean();
            else if (method == "add") result_type = SemanticType::makeVoid();
            else if (method == "find") result_type = SemanticType::makeInteger();
            else if (method == "size") result_type = SemanticType::makeInteger();
            else if (method == "get") result_type = element_type;
            else if (method == "remove") result_type = SemanticType::makeVoid();
            else if (method == "filter") result_type = object_type;
            else if (method == "join") result_type = SemanticType::makeString();
            else if (method == "sort") result_type = object_type;
            else result_type = SemanticType::makeUnknown();

            rememberExprType(expr, result_type);
            return result_type;
        }
    }

    if (is_builtin_map_type(object_type)) {
        const std::string& method = expr.member.lexeme;
        SemanticType result_type = SemanticType::makeUnknown();
        if (method == "of" || method == "create") result_type = SemanticType::makeClass("Map");
        else if (method == "containsKey" || method == "isEmpty") result_type = SemanticType::makeBoolean();
        else if (method == "size") result_type = SemanticType::makeInteger();
        else if (method == "toString") result_type = SemanticType::makeString();
        else if (method == "clear" || method == "free") result_type = SemanticType::makeVoid();
        rememberExprType(expr, result_type);
        return result_type;
    }

    if (is_builtin_file_type(object_type)) {
        const std::string& method = expr.member.lexeme;
        SemanticType result_type = SemanticType::makeUnknown();
        if (method == "of") result_type = SemanticType::makeClass("File");
        else if (method == "nextLine") result_type = SemanticType::makeBoolean();
        else if (method == "getLine") result_type = SemanticType::makeString();
        else if (method == "close" || method == "line_reader_close") result_type = SemanticType::makeVoid();
        else if (method == "line_reader_line_count" || method == "count_lines") result_type = SemanticType::makeInteger();
        else if (method == "read_all" || method == "print_lines_count" ||
                 method == "line_reader_open" || method == "line_reader_next" ||
                 method == "get_line_at") result_type = SemanticType::makeBoolean();
        rememberExprType(expr, result_type);
        return result_type;
    }

    if (object_type.kind == SemanticTypeKind::String) {
        const std::string& method = expr.member.lexeme;
        if (method == "length") {
            const SemanticType result_type = SemanticType::makeInteger();
            rememberExprType(expr, result_type);
            return result_type;
        }
        if (method == "equals" || method == "equalsIcase" || method == "containString" ||
            method == "atIndex" || method == "concat" || method == "split" ||
            (object_type.is_file_backed && method == "replaceAt")) {
            const SemanticType type = SemanticType::makeUnknown();
            rememberExprType(expr, type);
            return type;
        }
    }

    addError(expr.member.start,
             "type " + describeType(object_type) + " has no member '" + expr.member.lexeme + "'");
    rememberExprType(expr, SemanticType::makeError());
    return SemanticType::makeError();
}

SemanticType SemanticAnalyser::analyseAssignmentExpr(const AssignmentExpr& expr) {
    const SemanticType value_type = expr.value ? analyseExpr(*expr.value) : SemanticType::makeError();

    if (const auto* ident = dynamic_cast<const IdentifierExpr*>(expr.target.get())) {
        if (SemanticVariableSymbol* symbol = lookupVariable(ident->name)) {
            if (!isAssignable(symbol->type, value_type)) {
                addError(expr.start,
                         "cannot assign " + describeType(value_type) + " to " + describeType(symbol->type));
            }
            rememberExprType(expr, symbol->type);
            return symbol->type;
        }

        SemanticVariableSymbol* implicit = declareVariable(ident->name, ident->start, value_type, true);
        const SemanticType result = implicit ? implicit->type : value_type;
        rememberExprType(expr, result);
        return result;
    }

    if (!isAssignableTarget(*expr.target)) {
        addError(expr.target ? expr.target->start : expr.start, "left-hand side is not assignable");
        rememberExprType(expr, SemanticType::makeError());
        return SemanticType::makeError();
    }

    const SemanticType target_type = expr.target ? analyseExpr(*expr.target) : SemanticType::makeError();
    if (!isAssignable(target_type, value_type)) {
        addError(expr.start,
                 "cannot assign " + describeType(value_type) + " to " + describeType(target_type));
    }
    rememberExprType(expr, target_type);
    return target_type;
}

SemanticType SemanticAnalyser::analyseBinaryExpr(const BinaryExpr& expr) {
    const SemanticType left_type = expr.left ? analyseExpr(*expr.left) : SemanticType::makeError();
    const SemanticType right_type = expr.right ? analyseExpr(*expr.right) : SemanticType::makeError();
    SemanticType result = SemanticType::makeError();

    switch (expr.op.kind) {
        case TokenKind::Plus:
            if (isString(left_type) || isString(right_type)) {
                result = SemanticType::makeString();
            } else if (isNumeric(left_type) && isNumeric(right_type)) {
                result = (left_type.kind == SemanticTypeKind::Double || right_type.kind == SemanticTypeKind::Double)
                             ? SemanticType::makeDouble()
                             : ((left_type.kind == SemanticTypeKind::Long || right_type.kind == SemanticTypeKind::Long)
                                    ? SemanticType::makeLong()
                                    : SemanticType::makeInteger());
            }
            break;
        case TokenKind::Minus:
        case TokenKind::Star:
        case TokenKind::Slash:
        case TokenKind::Percent:
            if (isNumeric(left_type) && isNumeric(right_type)) {
                result = (left_type.kind == SemanticTypeKind::Double || right_type.kind == SemanticTypeKind::Double)
                             ? SemanticType::makeDouble()
                             : ((left_type.kind == SemanticTypeKind::Long || right_type.kind == SemanticTypeKind::Long)
                                    ? SemanticType::makeLong()
                                    : SemanticType::makeInteger());
            }
            break;
        case TokenKind::EqualEqual:
        case TokenKind::BangEqual:
            if (isAssignable(left_type, right_type) || isAssignable(right_type, left_type)) {
                result = SemanticType::makeBoolean();
            }
            break;
        case TokenKind::Less:
        case TokenKind::LessEqual:
        case TokenKind::Greater:
        case TokenKind::GreaterEqual:
            if (isNumeric(left_type) && isNumeric(right_type)) {
                result = SemanticType::makeBoolean();
            }
            break;
        case TokenKind::AndAnd:
        case TokenKind::OrOr:
            if (isBoolean(left_type) && isBoolean(right_type)) {
                result = SemanticType::makeBoolean();
            }
            break;
        default:
            break;
    }

    if (result.kind == SemanticTypeKind::Error &&
        left_type.kind != SemanticTypeKind::Error && right_type.kind != SemanticTypeKind::Error &&
        left_type.kind != SemanticTypeKind::Unknown && right_type.kind != SemanticTypeKind::Unknown) {
        addError(expr.op.start,
                 "operator '" + expr.op.lexeme + "' is not defined for " +
                     describeType(left_type) + " and " + describeType(right_type));
    }

    rememberExprType(expr, result);
    return result;
}

SemanticType SemanticAnalyser::analyseUnaryExpr(const UnaryExpr& expr) {
    const SemanticType operand_type = expr.operand ? analyseExpr(*expr.operand) : SemanticType::makeError();
    SemanticType result = SemanticType::makeError();

    switch (expr.op.kind) {
        case TokenKind::Bang:
            if (isBoolean(operand_type)) result = SemanticType::makeBoolean();
            break;
        case TokenKind::Minus:
            if (isNumeric(operand_type)) result = operand_type;
            break;
        case TokenKind::PlusPlus:
        case TokenKind::MinusMinus:
            if (!expr.operand || !isAssignableTarget(*expr.operand)) {
                addError(expr.op.start, "increment or decrement target is not assignable");
            } else if (isNumeric(operand_type)) {
                result = operand_type;
            }
            break;
        default:
            break;
    }

    if (result.kind == SemanticTypeKind::Error && operand_type.kind != SemanticTypeKind::Error &&
        operand_type.kind != SemanticTypeKind::Unknown && expr.op.kind != TokenKind::PlusPlus &&
        expr.op.kind != TokenKind::MinusMinus) {
        addError(expr.op.start,
                 "operator '" + expr.op.lexeme + "' is not defined for " + describeType(operand_type));
    }

    rememberExprType(expr, result);
    return result;
}

SemanticType SemanticAnalyser::analysePostfixExpr(const PostfixExpr& expr) {
    const SemanticType operand_type = expr.operand ? analyseExpr(*expr.operand) : SemanticType::makeError();
    if (!expr.operand || !isAssignableTarget(*expr.operand)) {
        addError(expr.op.start, "postfix target is not assignable");
        rememberExprType(expr, SemanticType::makeError());
        return SemanticType::makeError();
    }
    if (!isNumeric(operand_type) && operand_type.kind != SemanticTypeKind::Error &&
        operand_type.kind != SemanticTypeKind::Unknown) {
        addError(expr.op.start, "postfix operator requires numeric operand");
        rememberExprType(expr, SemanticType::makeError());
        return SemanticType::makeError();
    }
    rememberExprType(expr, operand_type);
    return operand_type;
}

SemanticType SemanticAnalyser::analyseArrayLiteralExpr(const ArrayLiteralExpr& expr) {
    SemanticType element_type = SemanticType::makeUnknown();
    for (const auto& element : expr.elements) {
        if (!element) continue;
        const SemanticType current_type = analyseExpr(*element);
        if (element_type.kind == SemanticTypeKind::Unknown) {
            element_type = current_type;
            continue;
        }
        if (!isAssignable(element_type, current_type) && !isAssignable(current_type, element_type)) {
            addError(element->start,
                     "array literal element type " + describeType(current_type) +
                         " does not match " + describeType(element_type));
        }
    }

    const SemanticType result = SemanticType::makeArray(
        element_type.kind == SemanticTypeKind::Unknown ? SemanticType::makeUnknown() : element_type);
    rememberExprType(expr, result);
    return result;
}

SemanticType SemanticAnalyser::resolveType(const TypeRef& type_ref, const SourceLocation& location) {
    SemanticType base_type = SemanticType::makeUnknown();
    if (type_ref.name == "Integer") base_type = SemanticType::makeInteger(type_ref.isFileBacked);
    else if (type_ref.name == "String") base_type = SemanticType::makeString(type_ref.isFileBacked);
    else if (type_ref.name == "Long") base_type = SemanticType::makeLong(type_ref.isFileBacked);
    else if (type_ref.name == "Double") base_type = SemanticType::makeDouble(type_ref.isFileBacked);
    else if (type_ref.name == "Boolean") base_type = SemanticType::makeBoolean(type_ref.isFileBacked);
    else if (lookupClass(type_ref.name) || is_builtin_class_name(type_ref.name)) {
        base_type = SemanticType::makeClass(type_ref.name, type_ref.isFileBacked);
    }
    else if (type_ref.name == "Unknown") {
        base_type = SemanticType::makeUnknown();
    } else {
        addError(location, "unknown type '" + type_ref.name + "'");
        base_type = SemanticType::makeError();
    }

    if (type_ref.isArray) return SemanticType::makeArray(base_type, type_ref.isFileBacked);
    return base_type;
}

SemanticVariableSymbol* SemanticAnalyser::lookupVariable(const std::string& name) {
    for (auto it = scopes_.rbegin(); it != scopes_.rend(); ++it) {
        auto found = it->variables.find(name);
        if (found != it->variables.end()) return &found->second;
    }
    if (current_class_) {
        auto found = current_class_->fields.find(name);
        if (found != current_class_->fields.end()) return &found->second;
    }
    return nullptr;
}

const SemanticMethodSymbol* SemanticAnalyser::lookupCurrentClassMethod(const std::string& name) const {
    return lookupMethodInClass(current_class_, name);
}

const SemanticMethodSymbol* SemanticAnalyser::lookupMethodInClass(const SemanticClassSymbol* class_symbol, const std::string& name) const {
    const SemanticClassSymbol* owner_class = nullptr;
    const SemanticMethodSymbol* method = findMethodInClassHierarchy(class_symbol, name, &owner_class);
    if (!method || !canAccessMethod(owner_class, *method)) {
        return nullptr;
    }
    return method;
}

const SemanticMethodSymbol* SemanticAnalyser::findMethodInClassHierarchy(const SemanticClassSymbol* class_symbol,
                                                                         const std::string& name,
                                                                         const SemanticClassSymbol** owner_class) const {
    if (!class_symbol) return nullptr;
    auto it = class_symbol->methods.find(name);
    if (it != class_symbol->methods.end()) {
        if (owner_class) *owner_class = class_symbol;
        return &it->second;
    }

    for (const std::string& parent_name : class_symbol->parents) {
        auto parent_it = classes_.find(parent_name);
        if (parent_it != classes_.end()) {
            if (const SemanticMethodSymbol* method = findMethodInClassHierarchy(&parent_it->second, name, owner_class)) {
                return method;
            }
        }
    }

    return nullptr;
}

bool SemanticAnalyser::canAccessMethod(const SemanticClassSymbol* owner_class, const SemanticMethodSymbol& method) const {
    return !method.is_private || owner_class == current_class_;
}

const SemanticClassSymbol* SemanticAnalyser::lookupClass(const std::string& name) const {
    const auto it = classes_.find(name);
    return it == classes_.end() ? nullptr : &it->second;
}

SemanticVariableSymbol* SemanticAnalyser::declareVariable(const Token& name, const SemanticType& type, bool implicit) {
    return declareVariable(name.lexeme, name.start, type, implicit);
}

SemanticVariableSymbol* SemanticAnalyser::declareVariable(const std::string& name,
                                                          const SourceLocation& location,
                                                          const SemanticType& type,
                                                          bool implicit) {
    if (!scopes_.empty()) {
        auto& current_scope = scopes_.back().variables;
        if (contains_key(current_scope, name)) {
            addError(location, "duplicate variable declaration '" + name + "'");
            return &current_scope[name];
        }
        if (current_class_ && contains_key(current_class_->fields, name)) {
            addError(location, "variable declaration '" + name + "' conflicts with field declaration");
            return &current_class_->fields[name];
        }
        SemanticVariableSymbol symbol{name, type, location, implicit};
        auto [it, inserted] = current_scope.emplace(name, std::move(symbol));
        return &it->second;
    }

    if (!current_class_) return nullptr;
    if (contains_key(current_class_->fields, name)) {
        addError(location, "duplicate field declaration '" + name + "'");
        return &current_class_->fields[name];
    }
    SemanticVariableSymbol symbol{name, type, location, implicit};
    auto [it, inserted] = current_class_->fields.emplace(name, std::move(symbol));
    return &it->second;
}

void SemanticAnalyser::pushScope() {
    scopes_.push_back(ScopeFrame{});
}

void SemanticAnalyser::popScope() {
    if (!scopes_.empty()) scopes_.pop_back();
}

void SemanticAnalyser::addError(const SourceLocation& location, const std::string& message) {
    errors_.push_back(SemanticError{message, location});
}

void SemanticAnalyser::rememberExprType(const Expr& expr, const SemanticType& type) {
    expression_types_[&expr] = type;
}

bool SemanticAnalyser::isNumeric(const SemanticType& type) const {
    return type.kind == SemanticTypeKind::Integer ||
           type.kind == SemanticTypeKind::Long ||
           type.kind == SemanticTypeKind::Double;
}

bool SemanticAnalyser::isBoolean(const SemanticType& type) const {
    return type.kind == SemanticTypeKind::Boolean;
}

bool SemanticAnalyser::isString(const SemanticType& type) const {
    return type.kind == SemanticTypeKind::String;
}

bool SemanticAnalyser::isAssignableTarget(const Expr& expr) const {
    return expr.kind == ExprKind::Identifier ||
           expr.kind == ExprKind::Index ||
           expr.kind == ExprKind::Member;
}

bool SemanticAnalyser::areTypesEqual(const SemanticType& left, const SemanticType& right) const {
    if (left.kind != right.kind) return false;
    if (left.is_file_backed != right.is_file_backed) return false;
    if (left.kind == SemanticTypeKind::Class) return left.name == right.name;
    if (left.kind == SemanticTypeKind::Array) {
        if (!left.element_type || !right.element_type) return false;
        return areTypesEqual(*left.element_type, *right.element_type);
    }
    return true;
}

bool SemanticAnalyser::isAssignable(const SemanticType& target, const SemanticType& value) const {
    if (target.kind == SemanticTypeKind::Error || value.kind == SemanticTypeKind::Error) return true;
    if (target.kind == SemanticTypeKind::Unknown || value.kind == SemanticTypeKind::Unknown) return true;
    if (areTypesEqual(target, value)) return true;
    if (target.kind == value.kind && target.is_file_backed && !value.is_file_backed) {
        if (target.kind != SemanticTypeKind::Array && target.kind != SemanticTypeKind::Class) {
            return true;
        }
    }

    if (target.kind == SemanticTypeKind::Double &&
        (value.kind == SemanticTypeKind::Integer || value.kind == SemanticTypeKind::Long)) {
        return true;
    }
    if (target.kind == SemanticTypeKind::Long && value.kind == SemanticTypeKind::Integer) {
        return true;
    }
    return false;
}

std::string SemanticAnalyser::describeType(const SemanticType& type) const {
    switch (type.kind) {
        case SemanticTypeKind::Error: return "error";
        case SemanticTypeKind::Unknown: return "unknown";
        case SemanticTypeKind::Void: return "Void";
        case SemanticTypeKind::Integer: return type.is_file_backed ? "FileInteger" : "Integer";
        case SemanticTypeKind::String: return type.is_file_backed ? "FileString" : "String";
        case SemanticTypeKind::Long: return type.is_file_backed ? "FileLong" : "Long";
        case SemanticTypeKind::Double: return type.is_file_backed ? "FileDouble" : "Double";
        case SemanticTypeKind::Boolean: return type.is_file_backed ? "FileBoolean" : "Boolean";
        case SemanticTypeKind::Class: return type.is_file_backed ? ("File" + type.name) : type.name;
        case SemanticTypeKind::Array:
            return type.element_type ? describeType(*type.element_type) + "[]" : "Array";
    }
    return "unknown";
}
