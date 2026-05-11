.intel_syntax noprefix

.equ TOKEN_SIZE, 296
.equ ERROR_SIZE, 132
.equ INFO_SIZE, 296

.equ STATE_TOKENS, 0
.equ STATE_TOKEN_COUNT, 8
.equ STATE_TOKEN_CAPACITY, 16
.equ STATE_ERRORS, 24
.equ STATE_ERROR_COUNT, 32
.equ STATE_ERROR_CAPACITY, 40
.equ STATE_ELEMENT_TYPE, 48

.equ TOKEN_KIND, 0
.equ TOKEN_LOCATION, 4
.equ TOKEN_NAME, 8
.equ TOKEN_ARG, 40
.equ TOKEN_RET, 168

.equ ERROR_MESSAGE, 0
.equ ERROR_LOCATION, 128

.equ INFO_KIND, 0
.equ INFO_HAS_LAMBDA, 4
.equ INFO_NAME, 8
.equ INFO_ARG, 40
.equ INFO_RET, 168

.equ PROGRAM_CLASSES, 0
.equ PROGRAM_CLASS_COUNT, 8
.equ CLASS_METHODS, 0
.equ CLASS_METHOD_COUNT, 8
.equ CLASS_STATEMENTS, 16
.equ CLASS_STATEMENT_COUNT, 24
.equ METHOD_STATEMENTS, 0
.equ METHOD_STATEMENT_COUNT, 8

.equ STMT_KIND, 0
.equ STMT_EXPR, 8
.equ STMT_BODY, 16
.equ STMT_BODY_COUNT, 24

.equ EXPR_KIND, 0
.equ EXPR_OBJECT_NAME, 8
.equ EXPR_METHOD_NAME, 16
.equ EXPR_CHILDREN, 24
.equ EXPR_CHILD_COUNT, 32
.equ EXPR_LOCATION, 40

.equ COLLECTION_METHOD, 0
.equ COLLECTION_ARGUMENT, 1
.equ COLLECTION_RETURN_TYPE, 2
.equ COLLECTION_LAMBDA_PARAM, 3
.equ COLLECTION_UNKNOWN_TOKEN, 4

.equ METHOD_CONTAINS, 0
.equ METHOD_ADD, 1
.equ METHOD_FIND, 2
.equ METHOD_SIZE, 3
.equ METHOD_GET, 4
.equ METHOD_REMOVE, 5
.equ METHOD_FILTER, 6
.equ METHOD_JOIN, 7
.equ METHOD_SORT, 8
.equ METHOD_UNKNOWN, 9

.equ STMT_EXPRESSION, 0
.equ STMT_VARIABLE_DECL, 1
.equ STMT_PRINT, 2
.equ STMT_GUARD_BLOCK, 3
.equ STMT_FOR_EACH, 4
.equ STMT_SWITCH, 5

.equ EXPR_CALL, 0
.equ EXPR_MEMBER, 1
.equ EXPR_ASSIGNMENT, 2
.equ EXPR_BINARY, 3
.equ EXPR_UNARY, 4
.equ EXPR_POSTFIX, 5
.equ EXPR_GROUPING, 6
.equ EXPR_INDEX, 7
.equ EXPR_ARRAY_LITERAL, 8

.section .rdata
s_contains: .asciz "contains"
s_add: .asciz "add"
s_find: .asciz "find"
s_size: .asciz "size"
s_get: .asciz "get"
s_remove: .asciz "remove"
s_filter: .asciz "filter"
s_join: .asciz "join"
s_sort: .asciz "sort"
s_unknown: .asciz "unknown"
s_boolean: .asciz "Boolean"
s_void: .asciz "Void"
s_integer: .asciz "Integer"
s_none: .asciz "None"
s_string: .asciz "String"
s_lambda_one: .asciz "Lambda<Boolean("
s_lambda_sort_mid: .asciz ","
s_lambda_end: .asciz ")>"
s_array_suffix: .asciz "[]"
s_default_element: .asciz "Unknown"
s_error: .asciz "CollectionLexer error"

.text
.globl collectionlexer_strlen
.def collectionlexer_strlen; .scl 2; .type 32; .endef
collectionlexer_strlen:
    xor rax, rax
    test rcx, rcx
    je .strlen_done
.strlen_loop:
    cmp byte ptr [rcx + rax], 0
    je .strlen_done
    inc rax
    jmp .strlen_loop
.strlen_done:
    ret

.globl collectionlexer_streq
.def collectionlexer_streq; .scl 2; .type 32; .endef
collectionlexer_streq:
    test rcx, rcx
    je .streq_no
    test rdx, rdx
    je .streq_no
.streq_loop:
    mov r8b, [rcx]
    cmp r8b, [rdx]
    jne .streq_no
    test r8b, r8b
    je .streq_yes
    inc rcx
    inc rdx
    jmp .streq_loop
.streq_yes:
    mov eax, 1
    ret
.streq_no:
    xor eax, eax
    ret

.globl collectionlexer_copy_cstr
.def collectionlexer_copy_cstr; .scl 2; .type 32; .endef
collectionlexer_copy_cstr:
    xor eax, eax
    test rcx, rcx
    je .copy_done
    test r8, r8
    je .copy_done
    test rdx, rdx
    jne .copy_loop
    mov byte ptr [rcx], 0
    ret
.copy_loop:
    cmp r8, 1
    jbe .copy_term
    mov al, [rdx]
    test al, al
    je .copy_term
    mov [rcx], al
    inc rcx
    inc rdx
    dec r8
    jmp .copy_loop
.copy_term:
    mov byte ptr [rcx], 0
    mov eax, 1
.copy_done:
    ret

.globl collectionlexer_append_cstr
.def collectionlexer_append_cstr; .scl 2; .type 32; .endef
collectionlexer_append_cstr:
    push rbx
    push rsi
    push rdi
    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8
    test rbx, rbx
    je .append_done
    test rdi, rdi
    je .append_done
    test rsi, rsi
    je .append_done
.append_seek:
    cmp rdi, 1
    jbe .append_done
    cmp byte ptr [rbx], 0
    je .append_copy
    inc rbx
    dec rdi
    jmp .append_seek
.append_copy:
    mov rcx, rbx
    mov rdx, rsi
    mov r8, rdi
    call collectionlexer_copy_cstr
.append_done:
    pop rdi
    pop rsi
    pop rbx
    ret

.globl collectionlexer_method_name
.def collectionlexer_method_name; .scl 2; .type 32; .endef
collectionlexer_method_name:
    cmp ecx, METHOD_CONTAINS
    je .mn_contains
    cmp ecx, METHOD_ADD
    je .mn_add
    cmp ecx, METHOD_FIND
    je .mn_find
    cmp ecx, METHOD_SIZE
    je .mn_size
    cmp ecx, METHOD_GET
    je .mn_get
    cmp ecx, METHOD_REMOVE
    je .mn_remove
    cmp ecx, METHOD_FILTER
    je .mn_filter
    cmp ecx, METHOD_JOIN
    je .mn_join
    cmp ecx, METHOD_SORT
    je .mn_sort
    lea rax, [rip + s_unknown]
    ret
.mn_contains: lea rax, [rip + s_contains]; ret
.mn_add: lea rax, [rip + s_add]; ret
.mn_find: lea rax, [rip + s_find]; ret
.mn_size: lea rax, [rip + s_size]; ret
.mn_get: lea rax, [rip + s_get]; ret
.mn_remove: lea rax, [rip + s_remove]; ret
.mn_filter: lea rax, [rip + s_filter]; ret
.mn_join: lea rax, [rip + s_join]; ret
.mn_sort: lea rax, [rip + s_sort]; ret

.globl collectionlexer_method_kind
.def collectionlexer_method_kind; .scl 2; .type 32; .endef
collectionlexer_method_kind:
    push rbx
    sub rsp, 32
    mov rbx, rcx
    lea rdx, [rip + s_contains]
    call collectionlexer_streq
    test eax, eax
    jne .mk_contains
    mov rcx, rbx
    lea rdx, [rip + s_add]
    call collectionlexer_streq
    test eax, eax
    jne .mk_add
    mov rcx, rbx
    lea rdx, [rip + s_find]
    call collectionlexer_streq
    test eax, eax
    jne .mk_find
    mov rcx, rbx
    lea rdx, [rip + s_size]
    call collectionlexer_streq
    test eax, eax
    jne .mk_size
    mov rcx, rbx
    lea rdx, [rip + s_get]
    call collectionlexer_streq
    test eax, eax
    jne .mk_get
    mov rcx, rbx
    lea rdx, [rip + s_remove]
    call collectionlexer_streq
    test eax, eax
    jne .mk_remove
    mov rcx, rbx
    lea rdx, [rip + s_filter]
    call collectionlexer_streq
    test eax, eax
    jne .mk_filter
    mov rcx, rbx
    lea rdx, [rip + s_join]
    call collectionlexer_streq
    test eax, eax
    jne .mk_join
    mov rcx, rbx
    lea rdx, [rip + s_sort]
    call collectionlexer_streq
    test eax, eax
    jne .mk_sort
    mov eax, METHOD_UNKNOWN
    jmp .mk_done
.mk_contains: mov eax, METHOD_CONTAINS; jmp .mk_done
.mk_add: mov eax, METHOD_ADD; jmp .mk_done
.mk_find: mov eax, METHOD_FIND; jmp .mk_done
.mk_size: mov eax, METHOD_SIZE; jmp .mk_done
.mk_get: mov eax, METHOD_GET; jmp .mk_done
.mk_remove: mov eax, METHOD_REMOVE; jmp .mk_done
.mk_filter: mov eax, METHOD_FILTER; jmp .mk_done
.mk_join: mov eax, METHOD_JOIN; jmp .mk_done
.mk_sort: mov eax, METHOD_SORT
.mk_done:
    add rsp, 32
    pop rbx
    ret

.globl collectionlexer_is_collection_method
.def collectionlexer_is_collection_method; .scl 2; .type 32; .endef
collectionlexer_is_collection_method:
    sub rsp, 40
    call collectionlexer_method_kind
    cmp eax, METHOD_UNKNOWN
    setne al
    movzx eax, al
    add rsp, 40
    ret

.globl collectionlexer_identify_method
.def collectionlexer_identify_method; .scl 2; .type 32; .endef
collectionlexer_identify_method:
    push rbx
    push rsi
    push rdi
    push r12
    sub rsp, 32
    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8
    test rdi, rdi
    jne .identify_have_element
    lea rdi, [rip + s_default_element]
.identify_have_element:
    test rbx, rbx
    je .identify_done
    mov dword ptr [rbx + INFO_KIND], METHOD_UNKNOWN
    mov dword ptr [rbx + INFO_HAS_LAMBDA], 0
    lea rcx, [rbx + INFO_NAME]
    mov rdx, rsi
    mov r8, 32
    call collectionlexer_copy_cstr
    lea rcx, [rbx + INFO_ARG]
    xor edx, edx
    mov r8, 128
    call collectionlexer_copy_cstr
    lea rcx, [rbx + INFO_RET]
    xor edx, edx
    mov r8, 128
    call collectionlexer_copy_cstr
    mov rcx, rsi
    call collectionlexer_method_kind
    mov r12d, eax
    mov [rbx + INFO_KIND], eax
    cmp eax, METHOD_CONTAINS
    je .id_contains
    cmp eax, METHOD_ADD
    je .id_add
    cmp eax, METHOD_FIND
    je .id_find
    cmp eax, METHOD_SIZE
    je .id_size
    cmp eax, METHOD_GET
    je .id_get
    cmp eax, METHOD_REMOVE
    je .id_remove
    cmp eax, METHOD_FILTER
    je .id_filter
    cmp eax, METHOD_JOIN
    je .id_join
    cmp eax, METHOD_SORT
    je .id_sort
    jmp .identify_done
.id_contains:
    lea rcx, [rbx + INFO_ARG]
    mov rdx, rdi
    mov r8, 128
    call collectionlexer_copy_cstr
    lea rcx, [rbx + INFO_RET]
    lea rdx, [rip + s_boolean]
    jmp .id_copy_ret
.id_add:
    lea rcx, [rbx + INFO_ARG]
    mov rdx, rdi
    mov r8, 128
    call collectionlexer_copy_cstr
    lea rcx, [rbx + INFO_RET]
    lea rdx, [rip + s_void]
    jmp .id_copy_ret
.id_find:
    lea rcx, [rbx + INFO_ARG]
    mov rdx, rdi
    mov r8, 128
    call collectionlexer_copy_cstr
    lea rcx, [rbx + INFO_RET]
    lea rdx, [rip + s_integer]
    jmp .id_copy_ret
.id_size:
    lea rcx, [rbx + INFO_ARG]
    lea rdx, [rip + s_none]
    mov r8, 128
    call collectionlexer_copy_cstr
    lea rcx, [rbx + INFO_RET]
    lea rdx, [rip + s_integer]
    jmp .id_copy_ret
.id_get:
    lea rcx, [rbx + INFO_ARG]
    lea rdx, [rip + s_integer]
    mov r8, 128
    call collectionlexer_copy_cstr
    lea rcx, [rbx + INFO_RET]
    mov rdx, rdi
    jmp .id_copy_ret
.id_remove:
    lea rcx, [rbx + INFO_ARG]
    lea rdx, [rip + s_integer]
    mov r8, 128
    call collectionlexer_copy_cstr
    lea rcx, [rbx + INFO_RET]
    lea rdx, [rip + s_void]
    jmp .id_copy_ret
.id_join:
    lea rcx, [rbx + INFO_ARG]
    lea rdx, [rip + s_string]
    mov r8, 128
    call collectionlexer_copy_cstr
    lea rcx, [rbx + INFO_RET]
    lea rdx, [rip + s_string]
.id_copy_ret:
    mov r8, 128
    call collectionlexer_copy_cstr
    jmp .identify_done
.id_filter:
    mov dword ptr [rbx + INFO_HAS_LAMBDA], 1
    lea rcx, [rbx + INFO_ARG]
    lea rdx, [rip + s_lambda_one]
    mov r8, 128
    call collectionlexer_copy_cstr
    lea rcx, [rbx + INFO_ARG]
    mov rdx, rdi
    mov r8, 128
    call collectionlexer_append_cstr
    lea rcx, [rbx + INFO_ARG]
    lea rdx, [rip + s_lambda_end]
    mov r8, 128
    call collectionlexer_append_cstr
    lea rcx, [rbx + INFO_RET]
    mov rdx, rdi
    mov r8, 128
    call collectionlexer_copy_cstr
    lea rcx, [rbx + INFO_RET]
    lea rdx, [rip + s_array_suffix]
    mov r8, 128
    call collectionlexer_append_cstr
    jmp .identify_done
.id_sort:
    mov dword ptr [rbx + INFO_HAS_LAMBDA], 1
    lea rcx, [rbx + INFO_ARG]
    lea rdx, [rip + s_lambda_one]
    mov r8, 128
    call collectionlexer_copy_cstr
    lea rcx, [rbx + INFO_ARG]
    mov rdx, rdi
    mov r8, 128
    call collectionlexer_append_cstr
    lea rcx, [rbx + INFO_ARG]
    lea rdx, [rip + s_lambda_sort_mid]
    mov r8, 128
    call collectionlexer_append_cstr
    lea rcx, [rbx + INFO_ARG]
    mov rdx, rdi
    mov r8, 128
    call collectionlexer_append_cstr
    lea rcx, [rbx + INFO_ARG]
    lea rdx, [rip + s_lambda_end]
    mov r8, 128
    call collectionlexer_append_cstr
    lea rcx, [rbx + INFO_RET]
    mov rdx, rdi
    mov r8, 128
    call collectionlexer_copy_cstr
    lea rcx, [rbx + INFO_RET]
    lea rdx, [rip + s_array_suffix]
    mov r8, 128
    call collectionlexer_append_cstr
.identify_done:
    add rsp, 32
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

.globl collectionlexer_init
.def collectionlexer_init; .scl 2; .type 32; .endef
collectionlexer_init:
    test rcx, rcx
    je .init_done
    mov [rcx + STATE_TOKENS], rdx
    mov [rcx + STATE_TOKEN_COUNT], qword ptr 0
    mov [rcx + STATE_TOKEN_CAPACITY], r8
    mov [rcx + STATE_ERRORS], r9
    mov rax, [rsp + 40]
    mov [rcx + STATE_ERROR_COUNT], qword ptr 0
    mov [rcx + STATE_ERROR_CAPACITY], rax
    mov rax, [rsp + 48]
    test rax, rax
    jne .init_elem
    lea rax, [rip + s_default_element]
.init_elem:
    mov [rcx + STATE_ELEMENT_TYPE], rax
.init_done:
    ret

.globl collectionlexer_tokens_count
.def collectionlexer_tokens_count; .scl 2; .type 32; .endef
collectionlexer_tokens_count:
    xor eax, eax
    test rcx, rcx
    je .tc_done
    mov rax, [rcx + STATE_TOKEN_COUNT]
.tc_done:
    ret

.globl collectionlexer_errors_count
.def collectionlexer_errors_count; .scl 2; .type 32; .endef
collectionlexer_errors_count:
    xor eax, eax
    test rcx, rcx
    je .ec_done
    mov rax, [rcx + STATE_ERROR_COUNT]
.ec_done:
    ret

.globl collectionlexer_has_errors
.def collectionlexer_has_errors; .scl 2; .type 32; .endef
collectionlexer_has_errors:
    xor eax, eax
    test rcx, rcx
    je .he_done
    cmp qword ptr [rcx + STATE_ERROR_COUNT], 0
    setne al
    movzx eax, al
.he_done:
    ret

.globl collectionlexer_emit_token
.def collectionlexer_emit_token; .scl 2; .type 32; .endef
collectionlexer_emit_token:
    push rbx
    push rsi
    push rdi
    push r12
    sub rsp, 32
    mov rbx, rcx
    mov r12d, [rsp + 112]
    xor eax, eax
    test rbx, rbx
    je .emit_done
    mov rsi, [rbx + STATE_TOKEN_COUNT]
    cmp rsi, [rbx + STATE_TOKEN_CAPACITY]
    jae .emit_done
    mov rdi, [rbx + STATE_TOKENS]
    test rdi, rdi
    je .emit_done
    imul rax, rsi, TOKEN_SIZE
    add rdi, rax
    mov [rdi + TOKEN_KIND], edx
    mov [rdi + TOKEN_LOCATION], r12d
    lea rcx, [rdi + TOKEN_NAME]
    mov rdx, r8
    mov r8, 32
    call collectionlexer_copy_cstr
    lea rcx, [rdi + TOKEN_ARG]
    mov rdx, r9
    mov r8, 128
    call collectionlexer_copy_cstr
    lea rcx, [rdi + TOKEN_RET]
    mov rdx, [rsp + 104]
    mov r8, 128
    call collectionlexer_copy_cstr
    inc rsi
    mov [rbx + STATE_TOKEN_COUNT], rsi
    mov eax, 1
.emit_done:
    add rsp, 32
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

.globl collectionlexer_add_error
.def collectionlexer_add_error; .scl 2; .type 32; .endef
collectionlexer_add_error:
    push rbx
    push rsi
    push rdi
    sub rsp, 32
    mov rbx, rcx
    xor eax, eax
    test rbx, rbx
    je .err_done
    test rdx, rdx
    jne .err_msg_ready
    lea rdx, [rip + s_error]
.err_msg_ready:
    mov rsi, [rbx + STATE_ERROR_COUNT]
    cmp rsi, [rbx + STATE_ERROR_CAPACITY]
    jae .err_done
    mov rdi, [rbx + STATE_ERRORS]
    test rdi, rdi
    je .err_done
    imul rax, rsi, ERROR_SIZE
    add rdi, rax
    mov [rdi + ERROR_LOCATION], r8d
    lea rcx, [rdi + ERROR_MESSAGE]
    mov r8, 128
    call collectionlexer_copy_cstr
    inc rsi
    mov [rbx + STATE_ERROR_COUNT], rsi
    mov eax, 1
.err_done:
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret

.globl collectionlexer_analyze_expression
.def collectionlexer_analyze_expression; .scl 2; .type 32; .endef
collectionlexer_analyze_expression:
    push rbx
    push rsi
    push rdi
    push r12
    sub rsp, 360
    mov rbx, rcx
    mov rsi, rdx
    test rbx, rbx
    je .expr_done
    test rsi, rsi
    je .expr_done
    cmp dword ptr [rsi + EXPR_KIND], EXPR_CALL
    jne .expr_children
    mov rcx, [rsi + EXPR_METHOD_NAME]
    call collectionlexer_is_collection_method
    test eax, eax
    je .expr_children
    lea rcx, [rsp + 64]
    mov rdx, [rsi + EXPR_METHOD_NAME]
    mov r8, [rbx + STATE_ELEMENT_TYPE]
    call collectionlexer_identify_method
    mov eax, [rsp + 64 + INFO_KIND]
    cmp eax, METHOD_UNKNOWN
    je .expr_children
    mov rcx, rbx
    mov edx, COLLECTION_METHOD
    lea r8, [rsp + 64 + INFO_NAME]
    lea r9, [rsp + 64 + INFO_ARG]
    lea rax, [rsp + 64 + INFO_RET]
    mov [rsp + 32], rax
    mov eax, [rsi + EXPR_LOCATION]
    mov [rsp + 40], eax
    call collectionlexer_emit_token
.expr_children:
    mov rdi, [rsi + EXPR_CHILDREN]
    mov r12, [rsi + EXPR_CHILD_COUNT]
.expr_loop:
    test rdi, rdi
    je .expr_done
    test r12, r12
    je .expr_done
    mov rcx, rbx
    mov rdx, [rdi]
    call collectionlexer_analyze_expression
    add rdi, 8
    dec r12
    jmp .expr_loop
.expr_done:
    add rsp, 360
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

.globl collectionlexer_analyze_statement
.def collectionlexer_analyze_statement; .scl 2; .type 32; .endef
collectionlexer_analyze_statement:
    push rbx
    push rsi
    push rdi
    push r12
    sub rsp, 32
    mov rbx, rcx
    mov rsi, rdx
    test rbx, rbx
    je .stmt_done
    test rsi, rsi
    je .stmt_done
    mov eax, [rsi + STMT_KIND]
    cmp eax, STMT_EXPRESSION
    je .stmt_expr
    cmp eax, STMT_VARIABLE_DECL
    je .stmt_expr
    cmp eax, STMT_PRINT
    je .stmt_expr
    cmp eax, STMT_GUARD_BLOCK
    je .stmt_expr_body
    cmp eax, STMT_FOR_EACH
    je .stmt_expr_body
    cmp eax, STMT_SWITCH
    je .stmt_expr_body
    jmp .stmt_done
.stmt_expr_body:
    mov rdx, [rsi + STMT_EXPR]
    test rdx, rdx
    je .stmt_body
    mov rcx, rbx
    call collectionlexer_analyze_expression
.stmt_body:
    mov rdi, [rsi + STMT_BODY]
    mov r12, [rsi + STMT_BODY_COUNT]
.stmt_body_loop:
    test rdi, rdi
    je .stmt_done
    test r12, r12
    je .stmt_done
    mov rcx, rbx
    mov rdx, rdi
    call collectionlexer_analyze_statement
    add rdi, 32
    dec r12
    jmp .stmt_body_loop
.stmt_expr:
    mov rdx, [rsi + STMT_EXPR]
    test rdx, rdx
    je .stmt_done
    mov rcx, rbx
    call collectionlexer_analyze_expression
.stmt_done:
    add rsp, 32
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

.globl collectionlexer_analyze_method
.def collectionlexer_analyze_method; .scl 2; .type 32; .endef
collectionlexer_analyze_method:
    push rbx
    push rsi
    push rdi
    sub rsp, 32
    mov rbx, rcx
    test rdx, rdx
    je .method_done
    mov rsi, [rdx + METHOD_STATEMENTS]
    mov rdi, [rdx + METHOD_STATEMENT_COUNT]
.method_loop:
    test rsi, rsi
    je .method_done
    test rdi, rdi
    je .method_done
    mov rcx, rbx
    mov rdx, rsi
    call collectionlexer_analyze_statement
    add rsi, 32
    dec rdi
    jmp .method_loop
.method_done:
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret

.globl collectionlexer_analyze_class
.def collectionlexer_analyze_class; .scl 2; .type 32; .endef
collectionlexer_analyze_class:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    sub rsp, 32
    mov rbx, rcx
    mov r13, rdx
    test rbx, rbx
    je .class_done
    test r13, r13
    je .class_done
    mov rsi, [r13 + CLASS_METHODS]
    mov rdi, [r13 + CLASS_METHOD_COUNT]
.class_method_loop:
    test rsi, rsi
    je .class_statements
    test rdi, rdi
    je .class_statements
    mov rcx, rbx
    mov rdx, rsi
    call collectionlexer_analyze_method
    add rsi, 16
    dec rdi
    jmp .class_method_loop
.class_statements:
    mov rsi, [r13 + CLASS_STATEMENTS]
    mov r12, [r13 + CLASS_STATEMENT_COUNT]
.class_stmt_loop:
    test rsi, rsi
    je .class_done
    test r12, r12
    je .class_done
    mov rcx, rbx
    mov rdx, rsi
    call collectionlexer_analyze_statement
    add rsi, 32
    dec r12
    jmp .class_stmt_loop
.class_done:
    add rsp, 32
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

.globl collectionlexer_analyze
.def collectionlexer_analyze; .scl 2; .type 32; .endef
collectionlexer_analyze:
    push rbx
    push rsi
    push rdi
    sub rsp, 32
    mov rbx, rcx
    test rbx, rbx
    je .analyze_done
    mov qword ptr [rbx + STATE_TOKEN_COUNT], 0
    mov qword ptr [rbx + STATE_ERROR_COUNT], 0
    test rdx, rdx
    je .analyze_done
    mov rsi, [rdx + PROGRAM_CLASSES]
    mov rdi, [rdx + PROGRAM_CLASS_COUNT]
.analyze_loop:
    test rsi, rsi
    je .analyze_done
    test rdi, rdi
    je .analyze_done
    mov rcx, rbx
    mov rdx, rsi
    call collectionlexer_analyze_class
    add rsi, 32
    dec rdi
    jmp .analyze_loop
.analyze_done:
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret
