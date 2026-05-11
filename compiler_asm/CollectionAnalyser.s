.intel_syntax noprefix

.equ TOKENS, 0
.equ ERRORS, 8
.equ CLASSES, 16
.equ METHODS, 24
.equ STATEMENTS, 32
.equ EXPRESSIONS, 40
.equ CURRENT_ELEMENT, 48
.equ LAST_KIND, 56
.equ LAST_ARG, 64
.equ LAST_RET, 72
.equ LAST_LAMBDA, 80

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

.section .rdata
s_unknown: .asciz "Unknown"
s_none: .asciz "None"
s_boolean: .asciz "Boolean"
s_void: .asciz "Void"
s_integer: .asciz "Integer"
s_string: .asciz "String"
s_array: .asciz "[]"
s_lambda_filter: .asciz "Lambda<Boolean(T)>"
s_lambda_sort: .asciz "Lambda<Boolean(T,T)>"
s_contains: .asciz "contains"
s_add: .asciz "add"
s_find: .asciz "find"
s_size: .asciz "size"
s_get: .asciz "get"
s_remove: .asciz "remove"
s_filter: .asciz "filter"
s_join: .asciz "join"
s_sort: .asciz "sort"

.text
.globl collection_analyser_streq
.def collection_analyser_streq; .scl 2; .type 32; .endef
collection_analyser_streq:
    test rcx, rcx
    je .cas_no
    test rdx, rdx
    je .cas_no
.cas_loop:
    mov r8b, [rcx]
    cmp r8b, [rdx]
    jne .cas_no
    test r8b, r8b
    je .cas_yes
    inc rcx
    inc rdx
    jmp .cas_loop
.cas_yes:
    mov eax, 1
    ret
.cas_no:
    xor eax, eax
    ret

.globl collection_analyser_init
.def collection_analyser_init; .scl 2; .type 32; .endef
collection_analyser_init:
    test rcx, rcx
    je .cai_done
    xor rax, rax
    mov [rcx+TOKENS], rax
    mov [rcx+ERRORS], rax
    mov [rcx+CLASSES], rax
    mov [rcx+METHODS], rax
    mov [rcx+STATEMENTS], rax
    mov [rcx+EXPRESSIONS], rax
    lea rax, [rip+s_unknown]
    mov [rcx+CURRENT_ELEMENT], rax
    mov qword ptr [rcx+LAST_KIND], METHOD_UNKNOWN
    mov [rcx+LAST_ARG], rax
    mov [rcx+LAST_RET], rax
    mov qword ptr [rcx+LAST_LAMBDA], 0
.cai_done:
    ret

.globl collection_analyser_token_count
.def collection_analyser_token_count; .scl 2; .type 32; .endef
collection_analyser_token_count:
    xor rax, rax
    test rcx, rcx
    je .catc_done
    mov rax, [rcx+TOKENS]
.catc_done:
    ret

.globl collection_analyser_error_count
.def collection_analyser_error_count; .scl 2; .type 32; .endef
collection_analyser_error_count:
    xor rax, rax
    test rcx, rcx
    je .caec_done
    mov rax, [rcx+ERRORS]
.caec_done:
    ret

.globl collection_analyser_has_errors
.def collection_analyser_has_errors; .scl 2; .type 32; .endef
collection_analyser_has_errors:
    xor eax, eax
    test rcx, rcx
    je .cahe_done
    cmp qword ptr [rcx+ERRORS], 0
    setne al
.cahe_done:
    ret

.globl collection_analyser_add_error
.def collection_analyser_add_error; .scl 2; .type 32; .endef
collection_analyser_add_error:
    test rcx, rcx
    je .caae_done
    inc qword ptr [rcx+ERRORS]
.caae_done:
    ret

.globl collection_analyser_set_element_type
.def collection_analyser_set_element_type; .scl 2; .type 32; .endef
collection_analyser_set_element_type:
    test rcx, rcx
    je .caset_done
    test rdx, rdx
    jne .caset_set
    lea rdx, [rip+s_unknown]
.caset_set:
    mov [rcx+CURRENT_ELEMENT], rdx
.caset_done:
    ret

.globl collection_analyser_identify_method
.def collection_analyser_identify_method; .scl 2; .type 32; .endef
collection_analyser_identify_method:
    push rbx
    push rsi
    sub rsp, 40
    mov rbx, rcx
    mov rsi, rdx
    test rsi, rsi
    jne .caim_have_elem
    lea rsi, [rip+s_unknown]
.caim_have_elem:
    mov rcx, rbx
    lea rdx, [rip+s_contains]
    call collection_analyser_streq
    test eax, eax
    jne .caim_contains
    mov rcx, rbx
    lea rdx, [rip+s_add]
    call collection_analyser_streq
    test eax, eax
    jne .caim_add
    mov rcx, rbx
    lea rdx, [rip+s_find]
    call collection_analyser_streq
    test eax, eax
    jne .caim_find
    mov rcx, rbx
    lea rdx, [rip+s_size]
    call collection_analyser_streq
    test eax, eax
    jne .caim_size
    mov rcx, rbx
    lea rdx, [rip+s_get]
    call collection_analyser_streq
    test eax, eax
    jne .caim_get
    mov rcx, rbx
    lea rdx, [rip+s_remove]
    call collection_analyser_streq
    test eax, eax
    jne .caim_remove
    mov rcx, rbx
    lea rdx, [rip+s_filter]
    call collection_analyser_streq
    test eax, eax
    jne .caim_filter
    mov rcx, rbx
    lea rdx, [rip+s_join]
    call collection_analyser_streq
    test eax, eax
    jne .caim_join
    mov rcx, rbx
    lea rdx, [rip+s_sort]
    call collection_analyser_streq
    test eax, eax
    jne .caim_sort
    mov eax, METHOD_UNKNOWN
    jmp .caim_done
.caim_contains:
    mov eax, METHOD_CONTAINS
    jmp .caim_done
.caim_add:
    mov eax, METHOD_ADD
    jmp .caim_done
.caim_find:
    mov eax, METHOD_FIND
    jmp .caim_done
.caim_size:
    mov eax, METHOD_SIZE
    jmp .caim_done
.caim_get:
    mov eax, METHOD_GET
    jmp .caim_done
.caim_remove:
    mov eax, METHOD_REMOVE
    jmp .caim_done
.caim_filter:
    mov eax, METHOD_FILTER
    jmp .caim_done
.caim_join:
    mov eax, METHOD_JOIN
    jmp .caim_done
.caim_sort:
    mov eax, METHOD_SORT
.caim_done:
    add rsp, 40
    pop rsi
    pop rbx
    ret

.globl collection_analyser_fill_method_info
.def collection_analyser_fill_method_info; .scl 2; .type 32; .endef
collection_analyser_fill_method_info:
    push rbx
    push rsi
    push rdi
    sub rsp, 32
    mov rbx, rcx
    mov rsi, rdx
    test rsi, rsi
    jne .cafmi_elem
    lea rsi, [rip+s_unknown]
.cafmi_elem:
    mov rcx, r8
    mov rdx, rsi
    call collection_analyser_identify_method
    mov rdi, rax
    mov [rbx+LAST_KIND], rdi
    mov qword ptr [rbx+LAST_LAMBDA], 0
    lea rax, [rip+s_unknown]
    mov [rbx+LAST_ARG], rax
    mov [rbx+LAST_RET], rax
    cmp rdi, METHOD_CONTAINS
    je .cafmi_contains
    cmp rdi, METHOD_ADD
    je .cafmi_add
    cmp rdi, METHOD_FIND
    je .cafmi_find
    cmp rdi, METHOD_SIZE
    je .cafmi_size
    cmp rdi, METHOD_GET
    je .cafmi_get
    cmp rdi, METHOD_REMOVE
    je .cafmi_remove
    cmp rdi, METHOD_FILTER
    je .cafmi_filter
    cmp rdi, METHOD_JOIN
    je .cafmi_join
    cmp rdi, METHOD_SORT
    je .cafmi_sort
    jmp .cafmi_done
.cafmi_contains:
    mov [rbx+LAST_ARG], rsi
    lea rax, [rip+s_boolean]
    mov [rbx+LAST_RET], rax
    jmp .cafmi_done
.cafmi_add:
    mov [rbx+LAST_ARG], rsi
    lea rax, [rip+s_void]
    mov [rbx+LAST_RET], rax
    jmp .cafmi_done
.cafmi_find:
    mov [rbx+LAST_ARG], rsi
    lea rax, [rip+s_integer]
    mov [rbx+LAST_RET], rax
    jmp .cafmi_done
.cafmi_size:
    lea rax, [rip+s_none]
    mov [rbx+LAST_ARG], rax
    lea rax, [rip+s_integer]
    mov [rbx+LAST_RET], rax
    jmp .cafmi_done
.cafmi_get:
    lea rax, [rip+s_integer]
    mov [rbx+LAST_ARG], rax
    mov [rbx+LAST_RET], rsi
    jmp .cafmi_done
.cafmi_remove:
    lea rax, [rip+s_integer]
    mov [rbx+LAST_ARG], rax
    lea rax, [rip+s_void]
    mov [rbx+LAST_RET], rax
    jmp .cafmi_done
.cafmi_filter:
    lea rax, [rip+s_lambda_filter]
    mov [rbx+LAST_ARG], rax
    lea rax, [rip+s_array]
    mov [rbx+LAST_RET], rax
    mov qword ptr [rbx+LAST_LAMBDA], 1
    jmp .cafmi_done
.cafmi_join:
    lea rax, [rip+s_string]
    mov [rbx+LAST_ARG], rax
    mov [rbx+LAST_RET], rax
    jmp .cafmi_done
.cafmi_sort:
    lea rax, [rip+s_lambda_sort]
    mov [rbx+LAST_ARG], rax
    lea rax, [rip+s_array]
    mov [rbx+LAST_RET], rax
    mov qword ptr [rbx+LAST_LAMBDA], 1
.cafmi_done:
    mov rax, rdi
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret

.globl collection_analyser_record_method_call
.def collection_analyser_record_method_call; .scl 2; .type 32; .endef
collection_analyser_record_method_call:
    push rbx
    push rsi
    push rdi
    sub rsp, 40
    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8
    test rbx, rbx
    je .carm_fail
    mov rdx, [rbx+CURRENT_ELEMENT]
    mov rcx, rbx
    mov r8, rsi
    call collection_analyser_fill_method_info
    cmp eax, METHOD_UNKNOWN
    je .carm_unknown
    inc qword ptr [rbx+TOKENS]
    inc qword ptr [rbx+EXPRESSIONS]
    cmp qword ptr [rbx+LAST_LAMBDA], 0
    je .carm_ok
    test rdi, rdi
    jne .carm_ok
    mov rcx, rbx
    call collection_analyser_add_error
    xor eax, eax
    jmp .carm_done
.carm_ok:
    mov eax, 1
    jmp .carm_done
.carm_unknown:
    mov rcx, rbx
    call collection_analyser_add_error
.carm_fail:
    xor eax, eax
.carm_done:
    add rsp, 40
    pop rdi
    pop rsi
    pop rbx
    ret

.globl collection_analyser_analyze_expression
.def collection_analyser_analyze_expression; .scl 2; .type 32; .endef
collection_analyser_analyze_expression:
    test rcx, rcx
    je .caae2_done
    inc qword ptr [rcx+EXPRESSIONS]
.caae2_done:
    ret

.globl collection_analyser_analyze_statement
.def collection_analyser_analyze_statement; .scl 2; .type 32; .endef
collection_analyser_analyze_statement:
    test rcx, rcx
    je .caas_done
    inc qword ptr [rcx+STATEMENTS]
    test rdx, rdx
    je .caas_done
    add [rcx+EXPRESSIONS], rdx
.caas_done:
    ret

.globl collection_analyser_analyze_method
.def collection_analyser_analyze_method; .scl 2; .type 32; .endef
collection_analyser_analyze_method:
    test rcx, rcx
    je .caam_done
    inc qword ptr [rcx+METHODS]
    add [rcx+STATEMENTS], rdx
.caam_done:
    ret

.globl collection_analyser_analyze_class
.def collection_analyser_analyze_class; .scl 2; .type 32; .endef
collection_analyser_analyze_class:
    test rcx, rcx
    je .caac_done
    inc qword ptr [rcx+CLASSES]
.caac_done:
    ret

.globl collection_analyser_analyze_program
.def collection_analyser_analyze_program; .scl 2; .type 32; .endef
collection_analyser_analyze_program:
    test rcx, rcx
    je .caap_fail
    mov [rcx+CLASSES], rdx
    mov [rcx+METHODS], r8
    mov [rcx+STATEMENTS], r9
    mov eax, 1
    ret
.caap_fail:
    xor eax, eax
    ret
