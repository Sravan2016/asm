#include "CollectionLexer.h"

namespace {

bool is_collection_method(const std::string& name) {
    return name == "contains" || name == "add" || name == "find" ||
           name == "size" || name == "get" || name == "remove" ||
           name == "filter" || name == "join" || name == "sort";
}

const char* collection_method_name(CollectionMethodKind kind) {
    switch (kind) {
        case CollectionMethodKind::Contains: return "contains";
        case CollectionMethodKind::Add: return "add";
        case CollectionMethodKind::Find: return "find";
        case CollectionMethodKind::Size: return "size";
        case CollectionMethodKind::Get: return "get";
        case CollectionMethodKind::Remove: return "remove";
        case CollectionMethodKind::Filter: return "filter";
        case CollectionMethodKind::Join: return "join";
        case CollectionMethodKind::Sort: return "sort";
        default: return "unknown";
    }
}

} // namespace

CollectionMethodInfo CollectionLexer::identifyCollectionMethod(const std::string& method_name, const std::string& element_type) {
    CollectionMethodInfo info;
    info.name = method_name;

    if (method_name == "contains") {
        info.kind = CollectionMethodKind::Contains;
        info.argument_type = element_type;
        info.return_type = "Boolean";
    } else if (method_name == "add") {
        info.kind = CollectionMethodKind::Add;
        info.argument_type = element_type;
        info.return_type = "Void";
    } else if (method_name == "find") {
        info.kind = CollectionMethodKind::Find;
        info.argument_type = element_type;
        info.return_type = "Integer";
    } else if (method_name == "size") {
        info.kind = CollectionMethodKind::Size;
        info.argument_type = "None";
        info.return_type = "Integer";
    } else if (method_name == "get") {
        info.kind = CollectionMethodKind::Get;
        info.argument_type = "Integer";
        info.return_type = element_type;
    } else if (method_name == "remove") {
        info.kind = CollectionMethodKind::Remove;
        info.argument_type = "Integer";
        info.return_type = "Void";
    } else if (method_name == "filter") {
        info.kind = CollectionMethodKind::Filter;
        info.argument_type = "Lambda<Boolean(" + element_type + ")>";
        info.return_type = element_type + "[]";
        info.has_lambda = true;
    } else if (method_name == "join") {
        info.kind = CollectionMethodKind::Join;
        info.argument_type = "String";
        info.return_type = "String";
    } else if (method_name == "sort") {
        info.kind = CollectionMethodKind::Sort;
        info.argument_type = "Lambda<Boolean(" + element_type + "," + element_type + ")>";
        info.return_type = element_type + "[]";
        info.has_lambda = true;
    } else {
        info.kind = CollectionMethodKind::Unknown;
    }

    return info;
}

void CollectionLexer::analyze(const Program& program) {
    tokens_.clear();
    errors_.clear();

    for (const auto& class_decl : program.classes) {
        if (class_decl) {
            analyzeClass(*class_decl);
        }
    }
}

const std::vector<CollectionToken>& CollectionLexer::tokens() const {
    return tokens_;
}

const std::vector<CollectionError>& CollectionLexer::errors() const {
    return errors_;
}

bool CollectionLexer::hasErrors() const {
    return !errors_.empty();
}

void CollectionLexer::analyzeClass(const ClassDecl& class_decl) {
    for (const ClassMember& member : class_decl.members) {
        if (member.kind == ClassMember::Kind::Method && member.method) {
            analyzeMethod(*member.method);
        } else if (member.kind == ClassMember::Kind::Statement && member.statement) {
            analyzeStatement(*member.statement);
        }
    }
}

void CollectionLexer::analyzeMethod(const MethodDecl& method_decl) {
    for (const auto& stmt : method_decl.body) {
        if (stmt) {
            analyzeStatement(*stmt);
        }
    }
}

void CollectionLexer::analyzeStatement(const Stmt& stmt) {
    switch (stmt.kind) {
        case StmtKind::Expression: {
            const auto& expr_stmt = static_cast<const ExprStmt&>(stmt);
            if (expr_stmt.expression) {
                analyzeExpression(*expr_stmt.expression);
            }
            break;
        }
        case StmtKind::VariableDecl: {
            const auto& decl_stmt = static_cast<const VariableDeclStmt&>(stmt);
            if (decl_stmt.initializer) {
                analyzeExpression(*decl_stmt.initializer);
            }
            break;
        }
        case StmtKind::Print: {
            const auto& print_stmt = static_cast<const PrintStmt&>(stmt);
            if (print_stmt.expression) {
                analyzeExpression(*print_stmt.expression);
            }
            break;
        }
        case StmtKind::GuardBlock: {
            const auto& guard_stmt = static_cast<const GuardBlockStmt&>(stmt);
            if (guard_stmt.condition) {
                analyzeExpression(*guard_stmt.condition);
            }
            for (const auto& body_stmt : guard_stmt.body) {
                if (body_stmt) {
                    analyzeStatement(*body_stmt);
                }
            }
            for (const auto& body_stmt : guard_stmt.elseBody) {
                if (body_stmt) {
                    analyzeStatement(*body_stmt);
                }
            }
            break;
        }
        case StmtKind::ForEach: {
            const auto& foreach_stmt = static_cast<const ForEachStmt&>(stmt);
            if (foreach_stmt.iterable) {
                analyzeExpression(*foreach_stmt.iterable);
            }
            for (const auto& body_stmt : foreach_stmt.body) {
                if (body_stmt) {
                    analyzeStatement(*body_stmt);
                }
            }
            break;
        }
        case StmtKind::Switch: {
            const auto& switch_stmt = static_cast<const SwitchStmt&>(stmt);
            if (switch_stmt.subject) {
                analyzeExpression(*switch_stmt.subject);
            }
            for (const SwitchCase& switch_case : switch_stmt.cases) {
                if (switch_case.label) {
                    analyzeExpression(*switch_case.label);
                }
                for (const auto& body_stmt : switch_case.body) {
                    if (body_stmt) {
                        analyzeStatement(*body_stmt);
                    }
                }
            }
            break;
        }
    }
}

void CollectionLexer::analyzeExpression(const Expr& expr) {
    switch (expr.kind) {
        case ExprKind::Call: {
            const auto& call_expr = static_cast<const CallExpr&>(expr);
            if (const auto* member = dynamic_cast<const MemberExpr*>(call_expr.callee.get())) {
                if (const auto* object_ident = dynamic_cast<const IdentifierExpr*>(member->object.get())) {
                    std::string method_name = member->member.lexeme;

                    if (is_collection_method(method_name)) {
                        CollectionMethodInfo info = identifyCollectionMethod(method_name, current_array_element_type_);

                        CollectionToken token;
                        token.kind = CollectionTokenKind::CollectionMethod;
                        token.name = method_name;
                        token.argument_type = info.argument_type;
                        token.return_type = info.return_type;
                        token.location = member->member.start;
                        tokens_.push_back(token);
                    }
                }
            }

            for (const auto& arg : call_expr.arguments) {
                if (arg) {
                    analyzeExpression(*arg);
                }
            }
            break;
        }
        case ExprKind::Member: {
            const auto& member_expr = static_cast<const MemberExpr&>(expr);
            if (member_expr.object) {
                analyzeExpression(*member_expr.object);
            }
            break;
        }
        case ExprKind::Assignment: {
            const auto& assign_expr = static_cast<const AssignmentExpr&>(expr);
            if (assign_expr.target) {
                analyzeExpression(*assign_expr.target);
            }
            if (assign_expr.value) {
                analyzeExpression(*assign_expr.value);
            }
            break;
        }
        case ExprKind::Binary: {
            const auto& binary_expr = static_cast<const BinaryExpr&>(expr);
            if (binary_expr.left) {
                analyzeExpression(*binary_expr.left);
            }
            if (binary_expr.right) {
                analyzeExpression(*binary_expr.right);
            }
            break;
        }
        case ExprKind::Unary: {
            const auto& unary_expr = static_cast<const UnaryExpr&>(expr);
            if (unary_expr.operand) {
                analyzeExpression(*unary_expr.operand);
            }
            break;
        }
        case ExprKind::Postfix: {
            const auto& postfix_expr = static_cast<const PostfixExpr&>(expr);
            if (postfix_expr.operand) {
                analyzeExpression(*postfix_expr.operand);
            }
            break;
        }
        case ExprKind::Grouping: {
            const auto& group_expr = static_cast<const GroupingExpr&>(expr);
            if (group_expr.inner) {
                analyzeExpression(*group_expr.inner);
            }
            break;
        }
        case ExprKind::Index: {
            const auto& index_expr = static_cast<const IndexExpr&>(expr);
            if (index_expr.object) {
                analyzeExpression(*index_expr.object);
            }
            if (index_expr.index) {
                analyzeExpression(*index_expr.index);
            }
            break;
        }
        case ExprKind::ArrayLiteral: {
            const auto& array_expr = static_cast<const ArrayLiteralExpr&>(expr);
            for (const auto& element : array_expr.elements) {
                if (element) {
                    analyzeExpression(*element);
                }
            }
            break;
        }
        default:
            break;
    }
}

void CollectionLexer::addError(const SourceLocation& location, const std::string& message) {
    errors_.push_back(CollectionError{message, location});
}
