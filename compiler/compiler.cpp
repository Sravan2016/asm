#include "compiler.h"

#include "ArrayLexer.h"
#include "CodeGenerator.h"
#include "CollectionLexer.h"
#include "IRGenerator.h"
#include "LinkingRuntime.h"
#include "SemanticAnalyser.h"
#include "lexer.h"
#include "parser.h"

#include <cctype>
#include <fstream>
#include <iostream>
#include <memory>
#include <set>
#include <sstream>
#include <stdlib.h>
#include <string>
#include <unordered_set>
#include <vector>

namespace {

bool ends_with_bada(const std::string& path) {
    static const std::string suffix = ".bada";
    return path.size() >= suffix.size() &&
           path.compare(path.size() - suffix.size(), suffix.size(), suffix) == 0;
}

std::string import_to_path(const std::string& base_dir, const ImportDecl& import) {
    std::string result = base_dir;
    if (!result.empty() && result.back() != '\\' && result.back() != '/') {
        result += '/';
    }
    for (std::size_t i = 0; i < import.path.size(); ++i) {
        if (i > 0) result += '/';
        result += import.path[i].lexeme;
    }
    result += ".bada";
    return result;
}

std::string parent_directory(const std::string& path) {
    std::size_t pos = path.find_last_of('/');
    if (pos == std::string::npos) pos = path.find_last_of('\\');
    if (pos == std::string::npos) return "";
    return path.substr(0, pos);
}

std::string replace_extension(const std::string& path, const std::string& ext) {
    std::size_t slash_pos = path.find_last_of("/\\");
    std::size_t dot_pos = path.find_last_of('.');
    if (dot_pos == std::string::npos || (slash_pos != std::string::npos && dot_pos < slash_pos)) {
        return path + ext;
    }
    return path.substr(0, dot_pos) + ext;
}

std::string normalize_path(const std::string& path) {
    std::string normalized = path;
    for (char& ch : normalized) {
        if (ch == '/') ch = '\\';
    }
    return normalized;
}

void append_unique(std::vector<std::string>& items, const std::string& value) {
    const std::string normalized = normalize_path(value);
    for (const auto& item : items) {
        if (normalize_path(item) == normalized) return;
    }
    items.push_back(normalized);
}

bool read_file_text(const std::string& path, std::string* out) {
    if (!out) return false;
    std::ifstream input(path, std::ios::binary);
    if (!input) return false;

    std::ostringstream buffer;
    buffer << input.rdbuf();
    *out = buffer.str();
    return true;
}

bool path_exists(const std::string& path) {
    std::ifstream input(path, std::ios::binary);
    return static_cast<bool>(input);
}

bool is_builtin_class_name(const std::string& name) {
    return name == "Map" || name == "File" || name == "Thread" || name == "Aleka";
}

bool looks_like_class_name(const std::string& name) {
    return !name.empty() && std::isupper(static_cast<unsigned char>(name[0])) != 0;
}

bool program_has_class_named(const Program& program, const std::string& class_name) {
    for (const auto& cls : program.classes) {
        if (cls && cls->name.lexeme == class_name) {
            return true;
        }
    }
    return false;
}

std::string class_name_to_path(const std::string& base_dir, const Token& class_name) {
    std::string result = base_dir;
    if (!result.empty() && result.back() != '\\' && result.back() != '/') {
        result += '/';
    }
    result += class_name.lexeme;
    result += ".bada";
    return result;
}

bool parse_file(const std::string& path, Program& out_program, std::vector<LexError>& out_lex_errors, std::vector<ParseError>& out_parse_errors) {
    std::string source;
    if (!read_file_text(path, &source)) return false;

    Lexer lexer(source, path);
    std::vector<Token> tokens = lexer.tokenizeAll();
    if (lexer.hasError()) {
        out_lex_errors.insert(out_lex_errors.end(), lexer.errors().begin(), lexer.errors().end());
        return false;
    }

    Parser parser(tokens);
    out_program = parser.parseProgram();
    if (parser.hasError()) {
        out_parse_errors.insert(out_parse_errors.end(), parser.errors().begin(), parser.errors().end());
        return false;
    }
    return true;
}

bool resolve_imports(Program& program, const std::string& source_file_path, std::set<std::string>& visited);

void collect_class_refs_from_type(const TypeRef& type_ref, std::unordered_set<std::string>& out) {
    if (looks_like_class_name(type_ref.name) && !is_builtin_class_name(type_ref.name) &&
        type_ref.name != "Integer" && type_ref.name != "Long" && type_ref.name != "Double" &&
        type_ref.name != "Boolean" && type_ref.name != "String" && type_ref.name != "Array") {
        out.insert(type_ref.name);
    }
}

void collect_class_refs_from_expr(const Expr* expr, std::unordered_set<std::string>& out);

void collect_class_refs_from_stmt(const Stmt* stmt, std::unordered_set<std::string>& out) {
    if (!stmt) return;
    switch (stmt->kind) {
        case StmtKind::Expression: {
            const auto& expr_stmt = static_cast<const ExprStmt&>(*stmt);
            collect_class_refs_from_expr(expr_stmt.expression.get(), out);
            break;
        }
        case StmtKind::VariableDecl: {
            const auto& decl_stmt = static_cast<const VariableDeclStmt&>(*stmt);
            collect_class_refs_from_type(decl_stmt.type, out);
            collect_class_refs_from_expr(decl_stmt.initializer.get(), out);
            break;
        }
        case StmtKind::Print: {
            const auto& print_stmt = static_cast<const PrintStmt&>(*stmt);
            collect_class_refs_from_expr(print_stmt.expression.get(), out);
            break;
        }
        case StmtKind::GuardBlock: {
            const auto& guard_stmt = static_cast<const GuardBlockStmt&>(*stmt);
            collect_class_refs_from_expr(guard_stmt.condition.get(), out);
            for (const auto& body_stmt : guard_stmt.body) {
                collect_class_refs_from_stmt(body_stmt.get(), out);
            }
            for (const auto& body_stmt : guard_stmt.elseBody) {
                collect_class_refs_from_stmt(body_stmt.get(), out);
            }
            break;
        }
        case StmtKind::ForEach: {
            const auto& foreach_stmt = static_cast<const ForEachStmt&>(*stmt);
            collect_class_refs_from_type(foreach_stmt.type, out);
            collect_class_refs_from_expr(foreach_stmt.iterable.get(), out);
            for (const auto& body_stmt : foreach_stmt.body) {
                collect_class_refs_from_stmt(body_stmt.get(), out);
            }
            break;
        }
        case StmtKind::Switch: {
            const auto& switch_stmt = static_cast<const SwitchStmt&>(*stmt);
            collect_class_refs_from_expr(switch_stmt.subject.get(), out);
            for (const auto& switch_case : switch_stmt.cases) {
                collect_class_refs_from_expr(switch_case.label.get(), out);
                for (const auto& body_stmt : switch_case.body) {
                    collect_class_refs_from_stmt(body_stmt.get(), out);
                }
            }
            break;
        }
        case StmtKind::Return: {
            const auto& return_stmt = static_cast<const ReturnStmt&>(*stmt);
            collect_class_refs_from_expr(return_stmt.expression.get(), out);
            break;
        }
    }
}

void collect_class_refs_from_expr(const Expr* expr, std::unordered_set<std::string>& out) {
    if (!expr) return;
    switch (expr->kind) {
        case ExprKind::Identifier: {
            const auto& ident = static_cast<const IdentifierExpr&>(*expr);
            if (looks_like_class_name(ident.name) && !is_builtin_class_name(ident.name)) {
                out.insert(ident.name);
            }
            break;
        }
        case ExprKind::Unary:
            collect_class_refs_from_expr(static_cast<const UnaryExpr&>(*expr).operand.get(), out);
            break;
        case ExprKind::Binary: {
            const auto& binary = static_cast<const BinaryExpr&>(*expr);
            collect_class_refs_from_expr(binary.left.get(), out);
            collect_class_refs_from_expr(binary.right.get(), out);
            break;
        }
        case ExprKind::Assignment: {
            const auto& assign = static_cast<const AssignmentExpr&>(*expr);
            collect_class_refs_from_expr(assign.target.get(), out);
            collect_class_refs_from_expr(assign.value.get(), out);
            break;
        }
        case ExprKind::Call: {
            const auto& call = static_cast<const CallExpr&>(*expr);
            collect_class_refs_from_expr(call.callee.get(), out);
            for (const auto& arg : call.arguments) {
                collect_class_refs_from_expr(arg.get(), out);
            }
            break;
        }
        case ExprKind::Member:
            collect_class_refs_from_expr(static_cast<const MemberExpr&>(*expr).object.get(), out);
            break;
        case ExprKind::Index: {
            const auto& index = static_cast<const IndexExpr&>(*expr);
            collect_class_refs_from_expr(index.object.get(), out);
            collect_class_refs_from_expr(index.index.get(), out);
            break;
        }
        case ExprKind::Postfix:
            collect_class_refs_from_expr(static_cast<const PostfixExpr&>(*expr).operand.get(), out);
            break;
        case ExprKind::Grouping:
            collect_class_refs_from_expr(static_cast<const GroupingExpr&>(*expr).inner.get(), out);
            break;
        case ExprKind::ArrayLiteral: {
            const auto& array = static_cast<const ArrayLiteralExpr&>(*expr);
            for (const auto& element : array.elements) {
                collect_class_refs_from_expr(element.get(), out);
            }
            break;
        }
        case ExprKind::Conditional: {
            const auto& cond = static_cast<const ConditionalExpr&>(*expr);
            collect_class_refs_from_expr(cond.condition.get(), out);
            collect_class_refs_from_expr(cond.thenBranch.get(), out);
            collect_class_refs_from_expr(cond.elseBranch.get(), out);
            break;
        }
        case ExprKind::Lambda: {
            const auto& lambda = static_cast<const LambdaExpr&>(*expr);
            for (const auto& param : lambda.parameters) {
                collect_class_refs_from_type(param.type, out);
            }
            for (const auto& body_stmt : lambda.body) {
                collect_class_refs_from_stmt(body_stmt.get(), out);
            }
            break;
        }
        case ExprKind::IntegerLiteral:
        case ExprKind::LongLiteral:
        case ExprKind::DoubleLiteral:
        case ExprKind::StringLiteral:
        case ExprKind::BooleanLiteral:
            break;
    }
}

void collect_class_refs_from_program(const Program& program, std::unordered_set<std::string>& out) {
    for (const auto& cls : program.classes) {
        if (!cls) continue;
        for (const auto& parent : cls->parents) {
            if (parent.lexeme == "Aleka") continue;
            if (looks_like_class_name(parent.lexeme) && !is_builtin_class_name(parent.lexeme)) {
                out.insert(parent.lexeme);
            }
        }
        for (const auto& member : cls->members) {
            if (member.kind == ClassMember::Kind::Statement) {
                collect_class_refs_from_stmt(member.statement.get(), out);
            } else if (member.kind == ClassMember::Kind::Method && member.method) {
                for (const auto& param : member.method->parameters) {
                    collect_class_refs_from_type(param.type, out);
                }
                for (const auto& stmt : member.method->body) {
                    collect_class_refs_from_stmt(stmt.get(), out);
                }
                collect_class_refs_from_expr(member.method->returnValue.get(), out);
            }
        }
    }
}

bool resolve_same_folder_class_refs(const Program& program,
                                    const std::string& base_dir,
                                    const std::string& source_file_path,
                                    std::set<std::string>& visited,
                                    std::vector<Program>& imported_programs,
                                    std::vector<LexError>& lex_errors,
                                    std::vector<ParseError>& parse_errors) {
    std::unordered_set<std::string> class_refs;
    collect_class_refs_from_program(program, class_refs);
    for (const auto& class_name : class_refs) {
        Token token;
        token.lexeme = class_name;
        const std::string class_path = class_name_to_path(base_dir, token);
        if (class_path == source_file_path || !path_exists(class_path) || visited.count(class_path)) {
            continue;
        }
        visited.insert(class_path);
        Program imported;
        if (!parse_file(class_path, imported, lex_errors, parse_errors)) {
            return false;
        }
        if (!resolve_imports(imported, class_path, visited)) {
            return false;
        }
        imported_programs.push_back(std::move(imported));
    }
    return true;
}

bool collect_module_paths(const std::string& source_file_path,
                          std::set<std::string>& visited,
                          std::vector<std::string>& ordered_paths,
                          std::vector<LexError>& out_lex_errors,
                          std::vector<ParseError>& out_parse_errors) {
    if (visited.count(source_file_path)) return true;
    visited.insert(source_file_path);

    Program program;
    if (!parse_file(source_file_path, program, out_lex_errors, out_parse_errors)) {
        return false;
    }

    const std::string base_dir = parent_directory(source_file_path);
    for (const ImportDecl& import : program.imports) {
        const std::string import_path = import_to_path(base_dir, import);
        if (!collect_module_paths(import_path, visited, ordered_paths, out_lex_errors, out_parse_errors)) {
            return false;
        }
    }

    for (const auto& cls : program.classes) {
        if (!cls) continue;
        for (const Token& parent : cls->parents) {
            if (parent.lexeme == "Aleka") continue;
            const std::string parent_path = class_name_to_path(base_dir, parent);
            if (parent_path == source_file_path) continue;
            if (!path_exists(parent_path)) continue;
            if (!collect_module_paths(parent_path, visited, ordered_paths, out_lex_errors, out_parse_errors)) {
                return false;
            }
        }
    }

    std::unordered_set<std::string> class_refs;
    collect_class_refs_from_program(program, class_refs);
    for (const auto& class_name : class_refs) {
        Token token;
        token.lexeme = class_name;
        const std::string class_path = class_name_to_path(base_dir, token);
        if (class_path == source_file_path || !path_exists(class_path)) continue;
        if (!collect_module_paths(class_path, visited, ordered_paths, out_lex_errors, out_parse_errors)) {
            return false;
        }
    }

    ordered_paths.push_back(source_file_path);
    return true;
}

bool resolve_imports(Program& program, const std::string& source_file_path, std::set<std::string>& visited) {
    std::string base_dir = parent_directory(source_file_path);
    std::vector<Program> imported_programs;
    std::vector<LexError> lex_errors;
    std::vector<ParseError> parse_errors;

    for (const ImportDecl& import : program.imports) {
        std::string import_path = import_to_path(base_dir, import);
        if (visited.count(import_path)) continue;
        visited.insert(import_path);

        Program imported;
        bool parse_ok = parse_file(import_path, imported, lex_errors, parse_errors);
        if (!parse_ok) {
            Token stub_name;
            if (!import.path.empty()) {
                stub_name = import.path.back();
            } else {
                stub_name = import.fromToken;
            }
            bool already_has_class = false;
            for (const auto& cls : imported.classes) {
                if (cls && cls->name.lexeme == stub_name.lexeme) {
                    already_has_class = true;
                    break;
                }
            }
            if (!already_has_class) {
                auto stub_class = std::make_unique<ClassDecl>();
                stub_class->name = stub_name;
                imported.classes.push_back(std::move(stub_class));
            }
        }

        if (!resolve_imports(imported, import_path, visited)) {
            return false;
        }

        imported_programs.push_back(std::move(imported));
    }

    for (const auto& cls : program.classes) {
        if (!cls) continue;
        for (const Token& parent : cls->parents) {
            if (parent.lexeme == "Aleka") continue;
            std::string parent_path = class_name_to_path(base_dir, parent);
            if (parent_path == source_file_path) continue;
            if (!path_exists(parent_path)) continue;
            if (visited.count(parent_path)) continue;
            visited.insert(parent_path);

            Program imported;
            bool parse_ok = parse_file(parent_path, imported, lex_errors, parse_errors);
            if (!parse_ok) {
                auto stub_class = std::make_unique<ClassDecl>();
                stub_class->name = parent;
                imported.classes.push_back(std::move(stub_class));
            }

            if (!resolve_imports(imported, parent_path, visited)) {
                return false;
            }

            imported_programs.push_back(std::move(imported));
        }
    }

    if (!resolve_same_folder_class_refs(program, base_dir, source_file_path, visited,
                                        imported_programs, lex_errors, parse_errors)) {
        return false;
    }

    for (Program& imported : imported_programs) {
        for (auto& cls : imported.classes) {
            if (!cls) continue;
            if (program_has_class_named(program, cls->name.lexeme)) {
                continue;
            }
            program.classes.push_back(std::move(cls));
        }
    }

    for (const auto& cls : program.classes) {
        if (!cls) continue;
        for (const Token& parent : cls->parents) {
            bool found = false;
            for (const auto& existing : program.classes) {
                if (existing && existing->name.lexeme == parent.lexeme) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                auto stub_class = std::make_unique<ClassDecl>();
                stub_class->name = parent;
                program.classes.push_back(std::move(stub_class));
            }
        }
    }

    return lex_errors.empty() && parse_errors.empty();
}

void print_location(std::ostream& os, const SourceLocation& location) {
    if (!location.file_path.empty()) {
        auto pos = location.file_path.find("com/");
        if (pos != std::string::npos) {
            os << location.file_path.substr(pos);
        } else {
            pos = location.file_path.find("com\\");
            if (pos != std::string::npos) {
                os << location.file_path.substr(pos);
            } else {
                os << location.file_path;
            }
        }
        os << ":";
    }
    os << location.line << ":" << location.column;
}

void print_lex_errors(const std::vector<LexError>& errors) {
    for (const auto& error : errors) {
        std::cerr << "lex error ";
        print_location(std::cerr, error.location);
        std::cerr << ": " << error.message << "\n";
    }
}

void print_parse_errors(const std::vector<ParseError>& errors) {
    for (const auto& error : errors) {
        std::cerr << "parse error ";
        print_location(std::cerr, error.location);
        std::cerr << ": " << error.message << "\n";
    }
}

void print_semantic_errors(const std::vector<SemanticError>& errors) {
    for (const auto& error : errors) {
        std::cerr << "semantic error ";
        print_location(std::cerr, error.location);
        std::cerr << ": " << error.message << "\n";
    }
}

void print_collection_errors(const std::vector<CollectionError>& errors) {
    for (const auto& error : errors) {
        std::cerr << "collection error ";
        print_location(std::cerr, error.location);
        std::cerr << ": " << error.message << "\n";
    }
}

void print_collection_tokens(const std::vector<CollectionToken>& tokens) {
    for (const auto& token : tokens) {
        std::cout << "collection token [" << token.name << "] args=" << token.argument_type << " returns=" << token.return_type << " at ";
        print_location(std::cout, token.location);
        std::cout << "\n";
    }
}

void print_array_errors(const std::vector<ArrayError>& errors) {
    for (const auto& error : errors) {
        std::cerr << "array error ";
        print_location(std::cerr, error.location);
        std::cerr << ": " << error.message << "\n";
    }
}

void print_array_tokens(const std::vector<ArrayToken>& tokens) {
    for (const auto& token : tokens) {
        std::cout << "array token [" << token.array_name << "] type=" << token.element_type << " count=" << token.element_count << " at ";
        print_location(std::cout, token.location);
        std::cout << "\n";
        for (const auto& value : token.element_values) {
            std::cout << "  element: " << value << "\n";
        }
    }
}

void print_program_summary(const Program& program, const SemanticAnalyser& analyser) {
    std::cout << "classes: " << program.classes.size() << "\n";
    std::cout << "imports: " << program.imports.size() << "\n";
    std::cout << "semantic classes: " << analyser.classes().size() << "\n";
}

void dump_tokens_if_requested(const std::vector<Token>& tokens) {
    for (const Token& token : tokens) {
        if (token.start.line < 41 || token.start.line > 46) continue;
        std::cout << token.start.line << ":" << token.start.column << " "
                  << token_kind_name(token.kind) << " `" << token.lexeme << "`\n";
    }
}

std::string strip_unresolved_stubs(const std::string& assembly) {
    const std::string stub_prefix = "; Stub for unresolved:";
    std::string output;
    std::size_t pos = 0;

    while (pos < assembly.size()) {
        std::size_t stub_pos = assembly.find(stub_prefix, pos);
        if (stub_pos == std::string::npos) {
            output.append(assembly, pos, std::string::npos);
            break;
        }

        output.append(assembly, pos, stub_pos - pos);

        std::size_t next_pos = assembly.find(stub_prefix, stub_pos + stub_prefix.size());
        if (next_pos == std::string::npos) {
            break;
        }
        pos = next_pos;
    }

    return output;
}

std::string strip_internal_externs(const std::string& assembly) {
    std::unordered_set<std::string> defined_symbols;
    std::istringstream scan(assembly);
    std::string line;

    while (std::getline(scan, line)) {
        std::size_t first = line.find_first_not_of(" \t");
        if (first == std::string::npos) continue;
        std::string trimmed = line.substr(first);
        if (trimmed.rfind("global ", 0) == 0) {
            defined_symbols.insert(trimmed.substr(7));
            continue;
        }
        if (!trimmed.empty() && trimmed.back() == ':') {
            defined_symbols.insert(trimmed.substr(0, trimmed.size() - 1));
        }
    }

    std::ostringstream out;
    std::istringstream input(assembly);
    while (std::getline(input, line)) {
        std::size_t first = line.find_first_not_of(" \t");
        if (first != std::string::npos) {
            std::string trimmed = line.substr(first);
            if (trimmed.rfind("extern ", 0) == 0) {
                std::string name = trimmed.substr(7);
                if (defined_symbols.count(name)) {
                    continue;
                }
            }
        }
        out << line << "\n";
    }

    return out.str();
}

bool compile_module_to_object(const std::string& path,
                              bool dump_ir,
                              bool log_outputs,
                              bool emit_entry_point,
                              std::string* out_obj_path) {
    auto* source = new std::string();
    if (!read_file_text(path, source)) {
        std::cerr << "Failed to open file\n";
        return false;
    }

    Lexer lexer(*source, path);
    std::vector<Token> tokens = lexer.tokenizeAll();
    if (lexer.hasError()) {
        print_lex_errors(lexer.errors());
        return false;
    }

    Parser parser(tokens);
    Program program = parser.parseProgram();
    if (parser.hasError()) {
        print_parse_errors(parser.errors());
        return false;
    }

    std::unordered_set<std::string> emitted_class_names;
    for (const auto& cls : program.classes) {
        if (cls) {
            emitted_class_names.insert(cls->name.lexeme);
        }
    }

    std::set<std::string> visited;
    resolve_imports(program, path, visited);

    SemanticAnalyser analyser;
    bool semantic_ok = analyser.analyse(program);
    if (!semantic_ok) {
        print_semantic_errors(analyser.errors());
        return false;
    }

    IRGenerator ir_gen;
    IRModule ir_module = ir_gen.generate(program, analyser, &emitted_class_names);

    if (dump_ir) {
        std::cerr << "=== Intermediate Representation ===" << std::endl;
        ir_module.dump();
    }

    LinkingRuntime runtime(ABIKind::Windows_x64);
    runtime.set_runtime_dir("build/asm_pure_obj");

    auto* asm_path_for_write = new std::string(replace_extension(path, ".s"));
    char full_path[260];
    _fullpath(full_path, asm_path_for_write->c_str(), 260);
    *asm_path_for_write = full_path;
    std::ofstream asm_file(*asm_path_for_write);
    if (!asm_file.is_open()) {
        std::cerr << "Failed to write assembly output" << std::endl;
        return false;
    }
    auto* assembly_text = new std::string(runtime.generate_assembly(ir_module, emit_entry_point));
    asm_file << *assembly_text;
    asm_file.close();

    auto* asm_path_for_assemble = new std::string(replace_extension(path, ".s"));
    _fullpath(full_path, asm_path_for_assemble->c_str(), 260);
    *asm_path_for_assemble = full_path;
    auto* obj_path_for_assemble = new std::string(replace_extension(path, ".obj"));
    _fullpath(full_path, obj_path_for_assemble->c_str(), 260);
    *obj_path_for_assemble = full_path;
    if (!runtime.assemble_to_object(*asm_path_for_assemble, *obj_path_for_assemble)) {
        std::cerr << "Failed to generate object: " << *obj_path_for_assemble << std::endl;
        return false;
    }

    if (log_outputs) {
        std::cerr << "Generated assembly: " << *asm_path_for_assemble << std::endl;
        std::cerr << "Generated object: " << *obj_path_for_assemble << std::endl;
    }

    if (out_obj_path) *out_obj_path = *obj_path_for_assemble;
    return true;
}

bool write_link_manifest(const std::string& root_obj_path, const std::vector<std::string>& imported_obj_paths) {
    const std::string manifest_path = replace_extension(root_obj_path, ".link");
    std::ofstream output(manifest_path, std::ios::binary);
    if (!output) return false;
    bool first = true;
    for (const auto& obj_path : imported_obj_paths) {
        if (!first) output << ' ';
        first = false;
        output << '"' << obj_path << '"';
    }
    return true;
}

std::vector<std::string> parse_link_manifest(const std::string& manifest_path) {
    std::vector<std::string> result;
    std::string content;
    if (!read_file_text(manifest_path, &content)) return result;

    std::size_t pos = 0;
    while (pos < content.size()) {
        while (pos < content.size() && std::isspace(static_cast<unsigned char>(content[pos]))) {
            ++pos;
        }
        if (pos >= content.size()) break;
        if (content[pos] == '"') {
            ++pos;
            std::size_t end = content.find('"', pos);
            if (end == std::string::npos) break;
            append_unique(result, content.substr(pos, end - pos));
            pos = end + 1;
        } else {
            std::size_t end = pos;
            while (end < content.size() && !std::isspace(static_cast<unsigned char>(content[end]))) {
                ++end;
            }
            append_unique(result, content.substr(pos, end - pos));
            pos = end;
        }
    }

    return result;
}

void collect_manifest_dependencies(const std::string& obj_path,
                                   std::set<std::string>& visited,
                                   std::vector<std::string>& ordered_objects) {
    if (visited.count(obj_path)) return;
    visited.insert(obj_path);

    const std::string manifest_path = replace_extension(obj_path, ".link");
    for (const auto& dep_obj : parse_link_manifest(manifest_path)) {
        collect_manifest_dependencies(dep_obj, visited, ordered_objects);
        append_unique(ordered_objects, dep_obj);
    }
}

} // namespace

int compiler_run(int argc, char** argv) {
    std::string path = "..\\project\\sample.bada";
    if (argc >= 2 && argv && argv[1] && argv[1][0]) {
        path = argv[1];
    }

    if (!ends_with_bada(path)) {
        std::cerr << "file not support\n";
        return 2;
    }

    bool dump_ir = false;
    bool use_linking_runtime = false;
    bool dump_tokens = false;
    if (argc >= 3) {
        for (int i = 2; i < argc; ++i) {
            if (std::string(argv[i]) == "--dump-ir") {
                dump_ir = true;
            } else if (std::string(argv[i]) == "--link") {
                use_linking_runtime = true;
            } else if (std::string(argv[i]) == "--dump-tokens") {
                dump_tokens = true;
            }
        }
    }

    if (dump_tokens) {
        std::string source;
        if (!read_file_text(path, &source)) {
            std::cerr << "Failed to open file\n";
            return 1;
        }
        Lexer lexer(source, path);
        std::vector<Token> tokens = lexer.tokenizeAll();
        if (lexer.hasError()) {
            print_lex_errors(lexer.errors());
            return 3;
        }
        dump_tokens_if_requested(tokens);
    }

    std::vector<LexError> import_lex_errors;
    std::vector<ParseError> import_parse_errors;
    std::set<std::string> visited_modules;
    std::vector<std::string> module_paths;
    if (!collect_module_paths(path, visited_modules, module_paths, import_lex_errors, import_parse_errors)) {
        print_lex_errors(import_lex_errors);
        print_parse_errors(import_parse_errors);
        return 4;
    }

    std::vector<std::string> imported_obj_paths;
    std::string root_obj_path;
    for (const auto& module_path : module_paths) {
        std::string built_obj_path;
        const bool is_root = (module_path == path);
        if (!compile_module_to_object(module_path, is_root && dump_ir, is_root, is_root, &built_obj_path)) {
            return 5;
        }
        if (is_root) {
            root_obj_path = built_obj_path;
        } else {
            append_unique(imported_obj_paths, built_obj_path);
        }
    }

    if (root_obj_path.empty()) {
        std::cerr << "Failed to determine root object path" << std::endl;
        return 6;
    }

    std::vector<std::string> flattened_imports;
    std::set<std::string> manifest_visited;
    for (const auto& obj_path : imported_obj_paths) {
        collect_manifest_dependencies(obj_path, manifest_visited, flattened_imports);
        append_unique(flattened_imports, obj_path);
    }

    if (!write_link_manifest(root_obj_path, flattened_imports)) {
        std::cerr << "Failed to write link manifest" << std::endl;
        return 6;
    }

    if (use_linking_runtime) {
        LinkingRuntime runtime(ABIKind::Windows_x64);
        runtime.set_runtime_dir("build/asm_pure_obj");

        const std::string exe_path = replace_extension(path, ".exe");
        if (runtime.link_executable(root_obj_path, exe_path, "build/asm_pure_obj", flattened_imports)) {
            std::cerr << "Built executable: " << exe_path << std::endl;
        } else {
            std::cerr << "Failed to build executable" << std::endl;
            return 6;
        }
    }
    return 0;
}

int main(int argc, char** argv) {
    return compiler_run(argc, argv);
}
