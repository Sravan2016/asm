.intel_syntax noprefix

.equ TOKEN_SIZE, 40
.equ ERROR_SIZE, 16

.equ STATE_TOKENS, 0
.equ STATE_TOKEN_COUNT, 8
.equ STATE_TOKEN_CAPACITY, 16
.equ STATE_ERRORS, 24
.equ STATE_ERROR_COUNT, 32
.equ STATE_ERROR_CAPACITY, 40

.equ TOKEN_KIND, 0
.equ TOKEN_NAME, 8
.equ TOKEN_TYPE, 16
.equ TOKEN_TYPE_LEN, 24
.equ TOKEN_ELEMENT_COUNT, 32
.equ TOKEN_LOCATION, 36

.equ ERROR_MESSAGE, 0
.equ ERROR_LOCATION, 8

.equ TYPEREF_NAME, 0
.equ TYPEREF_IS_ARRAY, 8

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
.equ STMT_NAME, 16
.equ STMT_TYPE, 24
.equ STMT_INITIALIZER_KIND, 32
.equ STMT_ELEMENT_COUNT, 40
.equ STMT_BODY, 48
.equ STMT_BODY_COUNT, 56

.equ EXPR_KIND, 0
.equ EXPR_OBJECT_NAME, 8
.equ EXPR_METHOD_NAME, 16
.equ EXPR_CHILDREN, 24
.equ EXPR_CHILD_COUNT, 32
.equ EXPR_ELEMENT_COUNT, 40
.equ EXPR_LOCATION, 44

.equ ARRAY_TOKEN_DECLARATION, 0
.equ ARRAY_TOKEN_LITERAL, 1
.equ ARRAY_TOKEN_INDEX, 2
.equ ARRAY_TOKEN_ELEMENT, 3
.equ ARRAY_TOKEN_ASSIGNMENT, 4
.equ ARRAY_TOKEN_UNKNOWN, 5

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
arraylexer_literal_name:
    .asciz "<literal>"
arraylexer_unknown_type:
    .asciz "Unknown"
arraylexer_indexed_type:
    .asciz "Indexed"
arraylexer_error_text:
    .asciz "ArrayLexer error"

method_contains:
    .asciz "contains"
method_add:
    .asciz "add"
method_find:
    .asciz "find"
method_size:
    .asciz "size"
method_get:
    .asciz "get"
method_remove:
    .asciz "remove"
method_filter:
    .asciz "filter"
method_join:
    .asciz "join"
method_sort:
    .asciz "sort"

operation_contains:
    .asciz "Operation:contains"
operation_add:
    .asciz "Operation:add"
operation_find:
    .asciz "Operation:find"
operation_size:
    .asciz "Operation:size"
operation_get:
    .asciz "Operation:get"
operation_remove:
    .asciz "Operation:remove"
operation_filter:
    .asciz "Operation:filter"
operation_join:
    .asciz "Operation:join"
operation_sort:
    .asciz "Operation:sort"

.text
.globl arraylexer_strlen
.def arraylexer_strlen; .scl 2; .type 32; .endef
arraylexer_strlen:
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

.globl arraylexer_streq
.def arraylexer_streq; .scl 2; .type 32; .endef
arraylexer_streq:
    test rcx, rcx
    je .streq_no
    test rdx, rdx
    je .streq_no
.streq_loop:
    mov r8b, byte ptr [rcx]
    mov r9b, byte ptr [rdx]
    cmp r8b, r9b
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

.globl arraylexer_is_array_type_name
.def arraylexer_is_array_type_name; .scl 2; .type 32; .endef
arraylexer_is_array_type_name:
    sub rsp, 40
    mov r10, rcx
    call arraylexer_strlen
    cmp rax, 2
    jb .is_array_no
    cmp byte ptr [r10 + rax - 2], '['
    jne .is_array_no
    cmp byte ptr [r10 + rax - 1], ']'
    jne .is_array_no
    mov eax, 1
    add rsp, 40
    ret
.is_array_no:
    xor eax, eax
    add rsp, 40
    ret

.globl arraylexer_element_type_length
.def arraylexer_element_type_length; .scl 2; .type 32; .endef
arraylexer_element_type_length:
    sub rsp, 40
    mov r10, rcx
    call arraylexer_strlen
    cmp rax, 2
    jb .element_done
    cmp byte ptr [r10 + rax - 2], '['
    jne .element_done
    cmp byte ptr [r10 + rax - 1], ']'
    jne .element_done
    sub rax, 2
.element_done:
    add rsp, 40
    ret

.globl arraylexer_operation_label
.def arraylexer_operation_label; .scl 2; .type 32; .endef
arraylexer_operation_label:
    push rbx
    sub rsp, 32
    mov rbx, rcx

    mov rcx, rbx
    lea rdx, [rip + method_contains]
    call arraylexer_streq
    test eax, eax
    jne .op_contains

    mov rcx, rbx
    lea rdx, [rip + method_add]
    call arraylexer_streq
    test eax, eax
    jne .op_add

    mov rcx, rbx
    lea rdx, [rip + method_find]
    call arraylexer_streq
    test eax, eax
    jne .op_find

    mov rcx, rbx
    lea rdx, [rip + method_size]
    call arraylexer_streq
    test eax, eax
    jne .op_size

    mov rcx, rbx
    lea rdx, [rip + method_get]
    call arraylexer_streq
    test eax, eax
    jne .op_get

    mov rcx, rbx
    lea rdx, [rip + method_remove]
    call arraylexer_streq
    test eax, eax
    jne .op_remove

    mov rcx, rbx
    lea rdx, [rip + method_filter]
    call arraylexer_streq
    test eax, eax
    jne .op_filter

    mov rcx, rbx
    lea rdx, [rip + method_join]
    call arraylexer_streq
    test eax, eax
    jne .op_join

    mov rcx, rbx
    lea rdx, [rip + method_sort]
    call arraylexer_streq
    test eax, eax
    jne .op_sort

    xor eax, eax
    jmp .op_done
.op_contains:
    lea rax, [rip + operation_contains]
    jmp .op_done
.op_add:
    lea rax, [rip + operation_add]
    jmp .op_done
.op_find:
    lea rax, [rip + operation_find]
    jmp .op_done
.op_size:
    lea rax, [rip + operation_size]
    jmp .op_done
.op_get:
    lea rax, [rip + operation_get]
    jmp .op_done
.op_remove:
    lea rax, [rip + operation_remove]
    jmp .op_done
.op_filter:
    lea rax, [rip + operation_filter]
    jmp .op_done
.op_join:
    lea rax, [rip + operation_join]
    jmp .op_done
.op_sort:
    lea rax, [rip + operation_sort]
.op_done:
    add rsp, 32
    pop rbx
    ret

.globl arraylexer_is_supported_array_method
.def arraylexer_is_supported_array_method; .scl 2; .type 32; .endef
arraylexer_is_supported_array_method:
    sub rsp, 40
    call arraylexer_operation_label
    test rax, rax
    setne al
    movzx eax, al
    add rsp, 40
    ret

.globl arraylexer_init
.def arraylexer_init; .scl 2; .type 32; .endef
arraylexer_init:
    test rcx, rcx
    je .init_done
    mov [rcx + STATE_TOKENS], rdx
    mov [rcx + STATE_TOKEN_COUNT], qword ptr 0
    mov [rcx + STATE_TOKEN_CAPACITY], r8
    mov [rcx + STATE_ERRORS], r9
    mov rax, [rsp + 40]
    mov [rcx + STATE_ERROR_COUNT], qword ptr 0
    mov [rcx + STATE_ERROR_CAPACITY], rax
.init_done:
    ret

.globl arraylexer_tokens_count
.def arraylexer_tokens_count; .scl 2; .type 32; .endef
arraylexer_tokens_count:
    xor eax, eax
    test rcx, rcx
    je .tokens_count_done
    mov rax, [rcx + STATE_TOKEN_COUNT]
.tokens_count_done:
    ret

.globl arraylexer_errors_count
.def arraylexer_errors_count; .scl 2; .type 32; .endef
arraylexer_errors_count:
    xor eax, eax
    test rcx, rcx
    je .errors_count_done
    mov rax, [rcx + STATE_ERROR_COUNT]
.errors_count_done:
    ret

.globl arraylexer_has_errors
.def arraylexer_has_errors; .scl 2; .type 32; .endef
arraylexer_has_errors:
    xor eax, eax
    test rcx, rcx
    je .has_errors_done
    cmp qword ptr [rcx + STATE_ERROR_COUNT], 0
    setne al
    movzx eax, al
.has_errors_done:
    ret

.globl arraylexer_extract_type_name
.def arraylexer_extract_type_name; .scl 2; .type 32; .endef
arraylexer_extract_type_name:
    xor eax, eax
    test rcx, rcx
    je .extract_type_done
    mov rax, [rcx + TYPEREF_NAME]
.extract_type_done:
    ret

.globl arraylexer_extract_element_type_name
.def arraylexer_extract_element_type_name; .scl 2; .type 32; .endef
arraylexer_extract_element_type_name:
    xor eax, eax
    test rcx, rcx
    je .extract_element_name_done
    mov rax, [rcx + TYPEREF_NAME]
.extract_element_name_done:
    ret

.globl arraylexer_extract_element_type_length
.def arraylexer_extract_element_type_length; .scl 2; .type 32; .endef
arraylexer_extract_element_type_length:
    test rcx, rcx
    je .extract_element_len_zero
    cmp dword ptr [rcx + TYPEREF_IS_ARRAY], 0
    je .extract_element_len_full
    mov rcx, [rcx + TYPEREF_NAME]
    jmp arraylexer_element_type_length
.extract_element_len_full:
    mov rcx, [rcx + TYPEREF_NAME]
    jmp arraylexer_strlen
.extract_element_len_zero:
    xor eax, eax
    ret

.globl arraylexer_is_array_type
.def arraylexer_is_array_type; .scl 2; .type 32; .endef
arraylexer_is_array_type:
    xor eax, eax
    test rcx, rcx
    je .is_array_type_done
    mov eax, [rcx + TYPEREF_IS_ARRAY]
    test eax, eax
    setne al
    movzx eax, al
.is_array_type_done:
    ret

.globl arraylexer_emit_token
.def arraylexer_emit_token; .scl 2; .type 32; .endef
arraylexer_emit_token:
    push rbx
    push rsi
    push rdi
    mov r10, [rsp + 64]
    mov r11d, [rsp + 72]
    mov ebx, [rsp + 80]

    xor eax, eax
    test rcx, rcx
    je .emit_done
    mov rsi, [rcx + STATE_TOKEN_COUNT]
    cmp rsi, [rcx + STATE_TOKEN_CAPACITY]
    jae .emit_done
    mov rdi, [rcx + STATE_TOKENS]
    test rdi, rdi
    je .emit_done
    lea rax, [rsi + rsi * 4]
    shl rax, 3
    add rdi, rax
    mov [rdi + TOKEN_KIND], edx
    mov [rdi + TOKEN_NAME], r8
    mov [rdi + TOKEN_TYPE], r9
    mov [rdi + TOKEN_TYPE_LEN], r10
    mov [rdi + TOKEN_ELEMENT_COUNT], r11d
    mov [rdi + TOKEN_LOCATION], ebx
    inc rsi
    mov [rcx + STATE_TOKEN_COUNT], rsi
    mov eax, 1
.emit_done:
    pop rdi
    pop rsi
    pop rbx
    ret

.globl arraylexer_add_error
.def arraylexer_add_error; .scl 2; .type 32; .endef
arraylexer_add_error:
    push rbx
    push rsi
    push rdi
    xor eax, eax
    test rcx, rcx
    je .add_error_done
    test rdx, rdx
    jne .add_error_have_message
    lea rdx, [rip + arraylexer_error_text]
.add_error_have_message:
    mov rsi, [rcx + STATE_ERROR_COUNT]
    cmp rsi, [rcx + STATE_ERROR_CAPACITY]
    jae .add_error_done
    mov rdi, [rcx + STATE_ERRORS]
    test rdi, rdi
    je .add_error_done
    mov rax, rsi
    shl rax, 4
    add rdi, rax
    mov [rdi + ERROR_MESSAGE], rdx
    mov [rdi + ERROR_LOCATION], r8d
    inc rsi
    mov [rcx + STATE_ERROR_COUNT], rsi
    mov eax, 1
.add_error_done:
    pop rdi
    pop rsi
    pop rbx
    ret

.globl arraylexer_analyze_array_assignment
.def arraylexer_analyze_array_assignment; .scl 2; .type 32; .endef
arraylexer_analyze_array_assignment:
    mov r10d, r9d
    mov r11d, [rsp + 40]
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    sub rsp, 64
    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8
    mov r12d, r10d
    mov r13d, r11d
    xor eax, eax
    test rbx, rbx
    je .assignment_done
    test rdi, rdi
    je .assignment_done
    cmp dword ptr [rdi + TYPEREF_IS_ARRAY], 0
    je .assignment_done
    mov rcx, rdi
    call arraylexer_extract_element_type_length
    mov r14, rax
    mov edx, ARRAY_TOKEN_DECLARATION
    cmp r12d, 1
    jne .assignment_kind_ready
    mov edx, ARRAY_TOKEN_LITERAL
.assignment_kind_ready:
    mov rcx, rbx
    mov r8, rsi
    mov r9, [rdi + TYPEREF_NAME]
    mov [rsp + 32], r14
    mov [rsp + 40], r13d
    mov dword ptr [rsp + 48], 0
    call arraylexer_emit_token
.assignment_done:
    add rsp, 64
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

.globl arraylexer_analyze_array_literal
.def arraylexer_analyze_array_literal; .scl 2; .type 32; .endef
arraylexer_analyze_array_literal:
    push rbx
    sub rsp, 64
    mov rbx, rcx
    lea r8, [rip + arraylexer_literal_name]
    lea r9, [rip + arraylexer_unknown_type]
    mov [rsp + 32], qword ptr 7
    mov [rsp + 40], edx
    mov dword ptr [rsp + 48], 0
    mov edx, ARRAY_TOKEN_LITERAL
    call arraylexer_emit_token
    add rsp, 64
    pop rbx
    ret

.globl arraylexer_analyze_index_access
.def arraylexer_analyze_index_access; .scl 2; .type 32; .endef
arraylexer_analyze_index_access:
    sub rsp, 56
    lea r9, [rip + arraylexer_indexed_type]
    mov [rsp + 32], qword ptr 7
    mov [rsp + 40], dword ptr 0
    mov [rsp + 48], r8d
    mov r8, rdx
    mov edx, ARRAY_TOKEN_INDEX
    call arraylexer_emit_token
    add rsp, 56
    ret

.globl arraylexer_analyze_expression
.def arraylexer_analyze_expression; .scl 2; .type 32; .endef
arraylexer_analyze_expression:
    push rbx
    push rsi
    push rdi
    push r12
    sub rsp, 56
    mov rbx, rcx
    mov rsi, rdx
    test rbx, rbx
    je .expr_done
    test rsi, rsi
    je .expr_done
    mov eax, [rsi + EXPR_KIND]
    cmp eax, EXPR_CALL
    je .expr_call
    cmp eax, EXPR_INDEX
    je .expr_index
    cmp eax, EXPR_ARRAY_LITERAL
    je .expr_literal
    mov rdi, [rsi + EXPR_CHILDREN]
    mov r12, [rsi + EXPR_CHILD_COUNT]
    jmp .expr_children_loop
.expr_call:
    mov rcx, [rsi + EXPR_METHOD_NAME]
    call arraylexer_operation_label
    test rax, rax
    je .expr_call_children
    mov rcx, rbx
    mov edx, ARRAY_TOKEN_ELEMENT
    mov r8, [rsi + EXPR_OBJECT_NAME]
    mov r9, rax
    mov [rsp + 32], qword ptr 0
    mov [rsp + 40], dword ptr 0
    mov eax, [rsi + EXPR_LOCATION]
    mov [rsp + 48], eax
    call arraylexer_emit_token
.expr_call_children:
    mov rdi, [rsi + EXPR_CHILDREN]
    mov r12, [rsi + EXPR_CHILD_COUNT]
    jmp .expr_children_loop
.expr_index:
    mov rcx, rbx
    mov rdx, [rsi + EXPR_OBJECT_NAME]
    mov r8d, [rsi + EXPR_LOCATION]
    call arraylexer_analyze_index_access
    mov rdi, [rsi + EXPR_CHILDREN]
    mov r12, [rsi + EXPR_CHILD_COUNT]
    jmp .expr_children_loop
.expr_literal:
    mov rcx, rbx
    mov edx, [rsi + EXPR_ELEMENT_COUNT]
    call arraylexer_analyze_array_literal
    mov rdi, [rsi + EXPR_CHILDREN]
    mov r12, [rsi + EXPR_CHILD_COUNT]
.expr_children_loop:
    test rdi, rdi
    je .expr_done
    test r12, r12
    je .expr_done
    mov rdx, [rdi]
    mov rcx, rbx
    call arraylexer_analyze_expression
    add rdi, 8
    dec r12
    jmp .expr_children_loop
.expr_done:
    add rsp, 56
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

.globl arraylexer_analyze_statement
.def arraylexer_analyze_statement; .scl 2; .type 32; .endef
arraylexer_analyze_statement:
    push rbx
    push rsi
    push rdi
    push r12
    sub rsp, 40
    mov rbx, rcx
    mov rsi, rdx
    test rbx, rbx
    je .stmt_done
    test rsi, rsi
    je .stmt_done
    mov eax, [rsi + STMT_KIND]
    cmp eax, STMT_VARIABLE_DECL
    je .stmt_var
    cmp eax, STMT_EXPRESSION
    je .stmt_expr
    cmp eax, STMT_PRINT
    je .stmt_expr
    cmp eax, STMT_GUARD_BLOCK
    je .stmt_body
    cmp eax, STMT_FOR_EACH
    je .stmt_expr_body
    cmp eax, STMT_SWITCH
    je .stmt_expr_body
    jmp .stmt_done
.stmt_var:
    mov rcx, rbx
    mov rdx, [rsi + STMT_NAME]
    mov r8, [rsi + STMT_TYPE]
    mov r9d, [rsi + STMT_INITIALIZER_KIND]
    mov eax, [rsi + STMT_ELEMENT_COUNT]
    mov [rsp + 32], eax
    call arraylexer_analyze_array_assignment
    mov rdx, [rsi + STMT_EXPR]
    test rdx, rdx
    je .stmt_done
    mov rcx, rbx
    call arraylexer_analyze_expression
    jmp .stmt_done
.stmt_expr:
    mov rdx, [rsi + STMT_EXPR]
    test rdx, rdx
    je .stmt_done
    mov rcx, rbx
    call arraylexer_analyze_expression
    jmp .stmt_done
.stmt_expr_body:
    mov rdx, [rsi + STMT_EXPR]
    test rdx, rdx
    je .stmt_body
    mov rcx, rbx
    call arraylexer_analyze_expression
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
    call arraylexer_analyze_statement
    add rdi, 64
    dec r12
    jmp .stmt_body_loop
.stmt_done:
    add rsp, 40
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

.globl arraylexer_analyze_method
.def arraylexer_analyze_method; .scl 2; .type 32; .endef
arraylexer_analyze_method:
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
    call arraylexer_analyze_statement
    add rsi, 64
    dec rdi
    jmp .method_loop
.method_done:
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret

.globl arraylexer_analyze_class
.def arraylexer_analyze_class; .scl 2; .type 32; .endef
arraylexer_analyze_class:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    sub rsp, 32
    mov rbx, rcx
    test rdx, rdx
    je .class_done
    mov r12, rdx
    mov rsi, [r12 + CLASS_METHODS]
    mov rdi, [r12 + CLASS_METHOD_COUNT]
.class_method_loop:
    test rsi, rsi
    je .class_statements
    test rdi, rdi
    je .class_statements
    mov rcx, rbx
    mov rdx, rsi
    call arraylexer_analyze_method
    add rsi, 16
    dec rdi
    jmp .class_method_loop
.class_statements:
    mov rsi, [r12 + CLASS_STATEMENTS]
    mov r13, [r12 + CLASS_STATEMENT_COUNT]
.class_statement_loop:
    test rsi, rsi
    je .class_done
    test r13, r13
    je .class_done
    mov rcx, rbx
    mov rdx, rsi
    call arraylexer_analyze_statement
    add rsi, 64
    dec r13
    jmp .class_statement_loop
.class_done:
    add rsp, 32
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

.globl arraylexer_analyze
.def arraylexer_analyze; .scl 2; .type 32; .endef
arraylexer_analyze:
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
    call arraylexer_analyze_class
    add rsi, 32
    dec rdi
    jmp .analyze_loop
.analyze_done:
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret

.globl arraylexer_analyze_type_ref
.def arraylexer_analyze_type_ref; .scl 2; .type 32; .endef
arraylexer_analyze_type_ref:
    jmp arraylexer_is_array_type
