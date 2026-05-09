#pragma once

#include "IR.h"
#include "SemanticAnalyser.h"
#include "parser.h"

#include <string>
#include <unordered_set>
#include <unordered_map>
#include <vector>

class IRGenerator {
public:
    IRModule generate(const Program& program,
                      const SemanticAnalyser& analyser,
                      const std::unordered_set<std::string>* emit_only_classes = nullptr);

private:
    // Class and method visitation
    void visitClass(const ClassDecl& cls);
    void visitMethod(const MethodDecl& method, const ClassDecl& cls, const std::vector<std::string>& parents);
    void visitSyntheticAlekaAccessor(const ClassDecl& cls,
                                     const VariableDeclStmt& field,
                                     std::size_t field_index,
                                     const std::vector<std::string>& parents,
                                     bool is_getter);
    void visitSyntheticAlekaFactory(const ClassDecl& cls,
                                    const std::vector<const VariableDeclStmt*>& fields,
                                    const std::vector<std::string>& parents);
    void visitSyntheticAlekaToString(const ClassDecl& cls,
                                     const std::vector<const VariableDeclStmt*>& fields,
                                     const std::vector<std::string>& parents);
    void visitSyntheticAlekaToObject(const ClassDecl& cls,
                                     const std::vector<const VariableDeclStmt*>& fields,
                                     const std::vector<std::string>& parents);

    // Statement visitation
    void visitStatementSequence(const std::vector<std::unique_ptr<Stmt>>& statements);
    void visitStatement(const Stmt& stmt);
    void visitVariableDecl(const VariableDeclStmt& stmt);
    void visitExpressionStmt(const ExprStmt& stmt);
    void visitPrintStmt(const PrintStmt& stmt);
    void visitGuardBlock(const GuardBlockStmt& stmt);
    void visitWhileBlock(const GuardBlockStmt& stmt);
    void visitForEach(const ForEachStmt& stmt);
    void visitSwitch(const SwitchStmt& stmt);
    void visitReturn(const ReturnStmt& stmt);

    // Expression visitation (returns IR value name)
    std::string visitExpression(const Expr& expr);
    std::string visitIdentifier(const IdentifierExpr& expr);
    std::string visitLiteral(const LiteralExpr& expr);
    std::string visitBinary(const BinaryExpr& expr);
    std::string visitUnary(const UnaryExpr& expr);
    std::string visitPostfix(const PostfixExpr& expr);
    std::string visitAssignment(const AssignmentExpr& expr);
    std::string visitConditional(const ConditionalExpr& expr);
    std::string visitCall(const CallExpr& expr);
    std::string visitMember(const MemberExpr& expr);
    std::string visitIndex(const IndexExpr& expr);
    std::string visitGrouping(const GroupingExpr& expr);
    std::string visitArrayLiteral(const ArrayLiteralExpr& expr);
    std::string visitLambda(const LambdaExpr& expr);
    std::string load_symbol_value(const std::string& name, const IRType& type);
    std::string emit_string_constant(const std::string& value, bool raw_cstr_data = false);
    std::string ensure_file_line_slot();
    IRType ir_type_for_typeref(const TypeRef& type_ref) const;

    // Helpers
    std::string new_temporary();
    std::string new_label();
    void emit(const IRInstruction& inst);
    void add_successor(const std::string& name);
    void push_scope();
    void pop_scope();
    void emit_all_scope_cleanups(const std::unordered_set<std::string>& preserved = {});
    enum class CleanupOperandKind {
        DirectValue,
        LoadFromAddress,
        PassAddress
    };
    struct OwnedValueInfo {
        std::string runtime_func;
        CleanupOperandKind operand_kind = CleanupOperandKind::DirectValue;
    };
    void emit_cleanup(const std::string& value_name, const OwnedValueInfo& info);
    void register_owned_value(const std::string& value_name, const std::string& runtime_func,
                              CleanupOperandKind operand_kind = CleanupOperandKind::DirectValue);
    void release_owned_value(const std::string& value_name);
    void transfer_ownership(const std::string& from_value, const std::string& to_value,
                            CleanupOperandKind operand_kind);
    void assign_owned_value(const std::string& target_addr, const std::string& value_name, const IRType& type);
    void free_owned_storage_before_store(const std::string& target_addr);
    OwnedValueInfo cleanup_info_for_ir_type(const IRType& type, bool for_storage) const;
    std::string preserved_owner_for_return(const Expr& expr, const std::string& value_name) const;

    IRType get_expr_type(const Expr& expr);
    std::string type_suffix(const IRType& type);

    // State
    IRModule module_;
    IRFunction* current_function_;
    const SemanticAnalyser* analyser_;
    int temp_counter_;
    int label_counter_;
    int lambda_counter_;

    // Symbol table: variable name -> IR value name
    std::unordered_map<std::string, std::string> symbol_table_;
    std::unordered_map<std::string, OwnedValueInfo> owned_values_;
    std::unordered_map<std::string, std::string> value_aliases_;
    struct ScopeFrame {
        std::vector<std::string> owned_value_order;
    };
    std::vector<ScopeFrame> scope_stack_;

    // Parent class names for method dispatch
    std::vector<std::string> current_parents_;
    std::string current_class_name_;

    // Class-level field declarations (for initialization)
    std::vector<const Stmt*> class_field_stmts_;

    // String constants registry
    std::unordered_map<std::string, std::string> string_constants_;
    std::unordered_map<std::string, std::vector<std::string>> class_parent_map_;
    std::unordered_map<std::string, std::unordered_set<std::string>> class_method_map_;
};
