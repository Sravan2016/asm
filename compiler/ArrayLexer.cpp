#include "ArrayLexer.h"

namespace {

bool is_array_type_name(const std::string& type_name) {
    return type_name.size() >= 2 && type_name[type_name.size() - 2] == '[' && type_name.back() == ']';
}

std::string strip_array_suffix(const std::string& type_name) {
    if (is_array_type_name(type_name)) {
        return type_name.substr(0, type_name.size() - 2);
    }
    return type_name;
}

} // namespace

void ArrayLexer::analyze(const Program& program) {
    tokens_.clear();
    errors_.clear();

    for (const auto& class_decl : program.classes) {
        if (class_decl) {
            analyzeClass(*class_decl);
        }
    }
}

const std::vector<ArrayToken>& ArrayLexer::tokens() const {
    return tokens_;
}

const std::vector<ArrayError>& ArrayLexer::errors() const {
    return errors_;
}

bool ArrayLexer::hasErrors() const {
    return !errors_.empty();
}

std::string ArrayLexer::extractTypeName(const TypeRef& type_ref) {
    return type_ref.name;
}

std::string ArrayLexer::extractElementType(const TypeRef& type_ref) {
    if (type_ref.isArray) {
        return strip_array_suffix(type_ref.name);
    }
    return type_ref.name;
}

bool ArrayLexer::isArrayType(const TypeRef& type_ref) {
    return type_ref.isArray;
}

void ArrayLexer::analyzeClass(const ClassDecl& class_decl) {
    for (const ClassMember& member : class_decl.members) {
        if (member.kind == ClassMember::Kind::Method && member.method) {
            analyzeMethod(*member.method);
        } else if (member.kind == ClassMember::Kind::Statement && member.statement) {
            analyzeStatement(*member.statement);
        }
    }
}

void ArrayLexer::analyzeMethod(const MethodDecl& method_decl) {
    for (const auto& stmt : method_decl.body) {
        if (stmt) {
            analyzeStatement(*stmt);
        }
    }
}

void ArrayLexer::analyzeStatement(const Stmt& stmt) {
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
            analyzeArrayAssignment(decl_stmt.name, decl_stmt.type, decl_stmt.initializer.get());
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

void ArrayLexer::analyzeArrayAssignment(const Token& name, const TypeRef& type_ref, const Expr* initializer) {
    if (isArrayType(type_ref)) {
        ArrayToken token;
        token.kind = ArrayTokenKind::ArrayDeclaration;
        token.array_name = name.lexeme;
        token.element_type = extractElementType(type_ref);
        token.location = name.start;

        if (initializer) {
            if (const auto* array_literal = dynamic_cast<const ArrayLiteralExpr*>(initializer)) {
                token.kind = ArrayTokenKind::ArrayLiteral;
                token.element_count = static_cast<int>(array_literal->elements.size());
                for (const auto& element : array_literal->elements) {
                    if (element) {
                        if (const auto* lit = dynamic_cast<const LiteralExpr*>(element.get())) {
                            token.element_values.push_back(lit->value);
                        } else {
                            token.element_values.push_back("<expr>");
                        }
                    }
                }
            }
        }

        tokens_.push_back(token);
    }
}

void ArrayLexer::analyzeExpression(const Expr& expr) {
    switch (expr.kind) {
        case ExprKind::Call: {
            const auto& call_expr = static_cast<const CallExpr&>(expr);
            if (const auto* member = dynamic_cast<const MemberExpr*>(call_expr.callee.get())) {
                if (const auto* object_ident = dynamic_cast<const IdentifierExpr*>(member->object.get())) {
                    std::string method_name = member->member.lexeme;

                    if (method_name == "contains" || method_name == "add" || method_name == "find" ||
                        method_name == "size" || method_name == "get" || method_name == "remove" ||
                        method_name == "filter" || method_name == "join" || method_name == "sort") {

                        ArrayToken token;
                        token.kind = ArrayTokenKind::ArrayElement;
                        token.array_name = object_ident->name;
                        token.element_type = "Operation:" + method_name;
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
            analyzeIndexAccess(index_expr);
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
            analyzeArrayLiteral(array_expr, "Unknown");
            break;
        }
        default:
            break;
    }
}

void ArrayLexer::analyzeIndexAccess(const IndexExpr& expr) {
    if (const auto* object_ident = dynamic_cast<const IdentifierExpr*>(expr.object.get())) {
        ArrayToken token;
        token.kind = ArrayTokenKind::ArrayIndex;
        token.array_name = object_ident->name;
        token.element_type = "Indexed";
        token.location = expr.start;
        tokens_.push_back(token);
    }
}

void ArrayLexer::analyzeArrayLiteral(const ArrayLiteralExpr& expr, const std::string& context_type) {
    ArrayToken token;
    token.kind = ArrayTokenKind::ArrayLiteral;
    token.array_name = "<literal>";
    token.element_type = context_type;
    token.element_count = static_cast<int>(expr.elements.size());
    token.location = expr.start;

    for (const auto& element : expr.elements) {
        if (element) {
            if (const auto* lit = dynamic_cast<const LiteralExpr*>(element.get())) {
                token.element_values.push_back(lit->value);
            } else {
                token.element_values.push_back("<expr>");
            }
        }
    }

    tokens_.push_back(token);
}

void ArrayLexer::analyzeTypeRef(const TypeRef& type_ref) {
    if (isArrayType(type_ref)) {
        // Type reference analysis handled in variable declarations
    }
}

void ArrayLexer::addError(const SourceLocation& location, const std::string& message) {
    errors_.push_back(ArrayError{message, location});
}
