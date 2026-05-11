.intel_syntax noprefix

.equ T_ERROR, 0
.equ T_UNKNOWN, 1
.equ T_VOID, 2
.equ T_INTEGER, 3
.equ T_STRING, 4
.equ T_LONG, 5
.equ T_DOUBLE, 6
.equ T_BOOLEAN, 7
.equ T_ARRAY, 8
.equ T_CLASS, 9

.equ SA_ERRORS, 0
.equ SA_CLASSES, 8
.equ SA_FIELDS, 16
.equ SA_METHODS, 24
.equ SA_SCOPES, 32
.equ SA_VARIABLES, 40
.equ SA_EXPR_TYPES, 48
.equ SA_IMPLICIT_METHODS, 56
.equ SA_CLASS_NAMES, 64
.equ SA_VAR_NAMES, 320
.equ SA_VAR_KINDS, 576

.section .rdata
s_error: .asciz "error"
s_unknown: .asciz "unknown"
s_void: .asciz "Void"
s_integer: .asciz "Integer"
s_file_integer: .asciz "FileInteger"
s_string: .asciz "String"
s_file_string: .asciz "FileString"
s_long: .asciz "Long"
s_file_long: .asciz "FileLong"
s_double: .asciz "Double"
s_file_double: .asciz "FileDouble"
s_boolean: .asciz "Boolean"
s_file_boolean: .asciz "FileBoolean"
s_array: .asciz "Array"
s_class: .asciz "Class"
s_map: .asciz "Map"
s_file: .asciz "File"
s_aleka: .asciz "Aleka"
s_contains: .asciz "contains"
s_add: .asciz "add"
s_find: .asciz "find"
s_size: .asciz "size"
s_remove: .asciz "remove"
s_join: .asciz "join"
s_of: .asciz "of"
s_create: .asciz "create"
s_contains_key: .asciz "containsKey"
s_is_empty: .asciz "isEmpty"
s_to_string: .asciz "toString"
s_clear: .asciz "clear"
s_free: .asciz "free"
s_next_line: .asciz "nextLine"
s_get_line: .asciz "getLine"
s_close: .asciz "close"
s_line_reader_close: .asciz "line_reader_close"
s_line_reader_line_count: .asciz "line_reader_line_count"
s_count_lines: .asciz "count_lines"
s_read_all: .asciz "readAll"
s_read_all_text: .asciz "read_all_text"
s_get_line_at: .asciz "get_line_at"
s_length: .asciz "length"

.text
.globl semantic_streq
.def semantic_streq; .scl 2; .type 32; .endef
semantic_streq:
    test rcx, rcx
    je .ss_no
    test rdx, rdx
    je .ss_no
.ss_loop:
    mov r8b, [rcx]
    cmp r8b, [rdx]
    jne .ss_no
    test r8b, r8b
    je .ss_yes
    inc rcx
    inc rdx
    jmp .ss_loop
.ss_yes:
    mov eax, 1
    ret
.ss_no:
    xor eax, eax
    ret

.globl semantic_init
.def semantic_init; .scl 2; .type 32; .endef
semantic_init:
    test rcx, rcx
    je .si_done
    xor rax, rax
    mov [rcx+SA_ERRORS], rax
    mov [rcx+SA_CLASSES], rax
    mov [rcx+SA_FIELDS], rax
    mov [rcx+SA_METHODS], rax
    mov [rcx+SA_SCOPES], rax
    mov [rcx+SA_VARIABLES], rax
    mov [rcx+SA_EXPR_TYPES], rax
    mov [rcx+SA_IMPLICIT_METHODS], rax
    mov r8, 0
.si_clear_classes:
    cmp r8, 32
    jae .si_clear_vars
    mov qword ptr [rcx+SA_CLASS_NAMES+r8*8], 0
    inc r8
    jmp .si_clear_classes
.si_clear_vars:
    mov r8, 0
.si_var_loop:
    cmp r8, 32
    jae .si_done
    mov qword ptr [rcx+SA_VAR_NAMES+r8*8], 0
    mov qword ptr [rcx+SA_VAR_KINDS+r8*8], 0
    inc r8
    jmp .si_var_loop
.si_done:
    ret

.globl semantic_error_count
.def semantic_error_count; .scl 2; .type 32; .endef
semantic_error_count:
    xor rax, rax
    test rcx, rcx
    je .sec_done
    mov rax, [rcx+SA_ERRORS]
.sec_done:
    ret

.globl semantic_has_errors
.def semantic_has_errors; .scl 2; .type 32; .endef
semantic_has_errors:
    xor eax, eax
    test rcx, rcx
    je .she_done
    cmp qword ptr [rcx+SA_ERRORS], 0
    setne al
.she_done:
    ret

.globl semantic_add_error
.def semantic_add_error; .scl 2; .type 32; .endef
semantic_add_error:
    test rcx, rcx
    je .sae_done
    inc qword ptr [rcx+SA_ERRORS]
.sae_done:
    ret

.globl semantic_type_name
.def semantic_type_name; .scl 2; .type 32; .endef
semantic_type_name:
    cmp ecx, T_ERROR
    je .stn_error
    cmp ecx, T_UNKNOWN
    je .stn_unknown
    cmp ecx, T_VOID
    je .stn_void
    cmp ecx, T_INTEGER
    je .stn_integer
    cmp ecx, T_STRING
    je .stn_string
    cmp ecx, T_LONG
    je .stn_long
    cmp ecx, T_DOUBLE
    je .stn_double
    cmp ecx, T_BOOLEAN
    je .stn_boolean
    cmp ecx, T_ARRAY
    je .stn_array
    cmp ecx, T_CLASS
    je .stn_class
.stn_unknown:
    lea rax, [rip+s_unknown]
    ret
.stn_error:
    lea rax, [rip+s_error]
    ret
.stn_void:
    lea rax, [rip+s_void]
    ret
.stn_integer:
    test edx, edx
    jne .stn_file_integer
    lea rax, [rip+s_integer]
    ret
.stn_file_integer:
    lea rax, [rip+s_file_integer]
    ret
.stn_string:
    test edx, edx
    jne .stn_file_string
    lea rax, [rip+s_string]
    ret
.stn_file_string:
    lea rax, [rip+s_file_string]
    ret
.stn_long:
    test edx, edx
    jne .stn_file_long
    lea rax, [rip+s_long]
    ret
.stn_file_long:
    lea rax, [rip+s_file_long]
    ret
.stn_double:
    test edx, edx
    jne .stn_file_double
    lea rax, [rip+s_double]
    ret
.stn_file_double:
    lea rax, [rip+s_file_double]
    ret
.stn_boolean:
    test edx, edx
    jne .stn_file_boolean
    lea rax, [rip+s_boolean]
    ret
.stn_file_boolean:
    lea rax, [rip+s_file_boolean]
    ret
.stn_array:
    lea rax, [rip+s_array]
    ret
.stn_class:
    lea rax, [rip+s_class]
    ret

.globl semantic_is_numeric
.def semantic_is_numeric; .scl 2; .type 32; .endef
semantic_is_numeric:
    cmp ecx, T_INTEGER
    je .sin_yes
    cmp ecx, T_LONG
    je .sin_yes
    cmp ecx, T_DOUBLE
    je .sin_yes
    xor eax, eax
    ret
.sin_yes:
    mov eax, 1
    ret

.globl semantic_is_boolean
.def semantic_is_boolean; .scl 2; .type 32; .endef
semantic_is_boolean:
    xor eax, eax
    cmp ecx, T_BOOLEAN
    sete al
    ret

.globl semantic_is_string
.def semantic_is_string; .scl 2; .type 32; .endef
semantic_is_string:
    xor eax, eax
    cmp ecx, T_STRING
    sete al
    ret

.globl semantic_are_types_equal
.def semantic_are_types_equal; .scl 2; .type 32; .endef
semantic_are_types_equal:
    xor eax, eax
    cmp ecx, edx
    sete al
    ret

.globl semantic_is_assignable
.def semantic_is_assignable; .scl 2; .type 32; .endef
semantic_is_assignable:
    cmp ecx, T_ERROR
    je .sia_yes
    cmp edx, T_ERROR
    je .sia_yes
    cmp ecx, T_UNKNOWN
    je .sia_yes
    cmp edx, T_UNKNOWN
    je .sia_yes
    cmp ecx, edx
    je .sia_yes
    cmp ecx, T_DOUBLE
    jne .sia_long
    cmp edx, T_INTEGER
    je .sia_yes
    cmp edx, T_LONG
    je .sia_yes
.sia_long:
    cmp ecx, T_LONG
    jne .sia_no
    cmp edx, T_INTEGER
    je .sia_yes
.sia_no:
    xor eax, eax
    ret
.sia_yes:
    mov eax, 1
    ret

.globl semantic_lookup_class
.def semantic_lookup_class; .scl 2; .type 32; .endef
semantic_lookup_class:
    push rbx
    push rsi
    sub rsp, 40
    mov rbx, rcx
    mov rsi, rdx
    xor r9, r9
.slc_loop:
    cmp r9, [rbx+SA_CLASSES]
    jae .slc_no
    mov rcx, [rbx+SA_CLASS_NAMES+r9*8]
    mov rdx, rsi
    call semantic_streq
    test eax, eax
    jne .slc_yes
    inc r9
    jmp .slc_loop
.slc_no:
    xor eax, eax
    jmp .slc_done
.slc_yes:
    mov eax, 1
.slc_done:
    add rsp, 40
    pop rsi
    pop rbx
    ret

.globl semantic_collect_class
.def semantic_collect_class; .scl 2; .type 32; .endef
semantic_collect_class:
    push rbx
    push rsi
    push rdi
    sub rsp, 32
    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8
    test rbx, rbx
    je .scc_fail
    mov rcx, rbx
    mov rdx, rsi
    call semantic_lookup_class
    test eax, eax
    jne .scc_dup
    mov r9, [rbx+SA_CLASSES]
    cmp r9, 32
    jae .scc_dup
    mov [rbx+SA_CLASS_NAMES+r9*8], rsi
    inc qword ptr [rbx+SA_CLASSES]
    test rdi, rdi
    je .scc_ok
    mov rcx, rdi
    lea rdx, [rip+s_aleka]
    call semantic_streq
    test eax, eax
    je .scc_ok
    add qword ptr [rbx+SA_IMPLICIT_METHODS], 4
    add qword ptr [rbx+SA_METHODS], 4
.scc_ok:
    mov eax, 1
    jmp .scc_done
.scc_dup:
    mov rcx, rbx
    call semantic_add_error
.scc_fail:
    xor eax, eax
.scc_done:
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret

.globl semantic_collect_field
.def semantic_collect_field; .scl 2; .type 32; .endef
semantic_collect_field:
    test rcx, rcx
    je .scf_fail
    inc qword ptr [rcx+SA_FIELDS]
    mov eax, 1
    ret
.scf_fail:
    xor eax, eax
    ret

.globl semantic_collect_method
.def semantic_collect_method; .scl 2; .type 32; .endef
semantic_collect_method:
    test rcx, rcx
    je .scm_fail
    inc qword ptr [rcx+SA_METHODS]
    mov eax, 1
    ret
.scm_fail:
    xor eax, eax
    ret

.globl semantic_push_scope
.def semantic_push_scope; .scl 2; .type 32; .endef
semantic_push_scope:
    test rcx, rcx
    je .sps_done
    inc qword ptr [rcx+SA_SCOPES]
.sps_done:
    ret

.globl semantic_pop_scope
.def semantic_pop_scope; .scl 2; .type 32; .endef
semantic_pop_scope:
    test rcx, rcx
    je .spos_done
    cmp qword ptr [rcx+SA_SCOPES], 0
    je .spos_done
    dec qword ptr [rcx+SA_SCOPES]
.spos_done:
    ret

.globl semantic_declare_variable
.def semantic_declare_variable; .scl 2; .type 32; .endef
semantic_declare_variable:
    push rbx
    push rsi
    push rdi
    push r12
    sub rsp, 40
    mov rbx, rcx
    mov rsi, rdx
    mov r12d, r8d
    test rbx, rbx
    je .sdv_fail
    xor rdi, rdi
.sdv_check:
    cmp rdi, [rbx+SA_VARIABLES]
    jae .sdv_add
    mov rcx, [rbx+SA_VAR_NAMES+rdi*8]
    mov rdx, rsi
    call semantic_streq
    test eax, eax
    jne .sdv_dup
    inc rdi
    jmp .sdv_check
.sdv_add:
    mov rdi, [rbx+SA_VARIABLES]
    cmp rdi, 32
    jae .sdv_dup
    mov [rbx+SA_VAR_NAMES+rdi*8], rsi
    mov [rbx+SA_VAR_KINDS+rdi*8], r12
    inc qword ptr [rbx+SA_VARIABLES]
    mov eax, 1
    jmp .sdv_done
.sdv_dup:
    mov rcx, rbx
    call semantic_add_error
.sdv_fail:
    xor eax, eax
.sdv_done:
    add rsp, 40
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

.globl semantic_lookup_variable
.def semantic_lookup_variable; .scl 2; .type 32; .endef
semantic_lookup_variable:
    push rbx
    push rsi
    push rdi
    sub rsp, 32
    mov rbx, rcx
    mov rsi, rdx
    xor rdi, rdi
.slv_loop:
    cmp rdi, [rbx+SA_VARIABLES]
    jae .slv_no
    mov rcx, [rbx+SA_VAR_NAMES+rdi*8]
    mov rdx, rsi
    call semantic_streq
    test eax, eax
    jne .slv_yes
    inc rdi
    jmp .slv_loop
.slv_no:
    mov eax, T_ERROR
    jmp .slv_done
.slv_yes:
    mov rax, [rbx+SA_VAR_KINDS+rdi*8]
.slv_done:
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret

.globl semantic_resolve_type
.def semantic_resolve_type; .scl 2; .type 32; .endef
semantic_resolve_type:
    push rbx
    push rsi
    push rdi
    push r12
    sub rsp, 40
    mov rbx, rcx
    mov rsi, rdx
    mov r12, r8
    mov rdi, r9
    mov rcx, rsi
    lea rdx, [rip+s_integer]
    call semantic_streq
    test eax, eax
    jne .srt_integer
    mov rcx, rsi
    lea rdx, [rip+s_string]
    call semantic_streq
    test eax, eax
    jne .srt_string
    mov rcx, rsi
    lea rdx, [rip+s_long]
    call semantic_streq
    test eax, eax
    jne .srt_long
    mov rcx, rsi
    lea rdx, [rip+s_double]
    call semantic_streq
    test eax, eax
    jne .srt_double
    mov rcx, rsi
    lea rdx, [rip+s_boolean]
    call semantic_streq
    test eax, eax
    jne .srt_boolean
    mov rcx, rbx
    mov rdx, rsi
    call semantic_lookup_class
    test eax, eax
    jne .srt_class
    mov rcx, rsi
    lea rdx, [rip+s_map]
    call semantic_streq
    test eax, eax
    jne .srt_class
    mov rcx, rsi
    lea rdx, [rip+s_file]
    call semantic_streq
    test eax, eax
    jne .srt_class
    mov rcx, rbx
    call semantic_add_error
    mov eax, T_ERROR
    jmp .srt_done
.srt_integer:
    mov eax, T_INTEGER
    jmp .srt_array
.srt_string:
    mov eax, T_STRING
    jmp .srt_array
.srt_long:
    mov eax, T_LONG
    jmp .srt_array
.srt_double:
    mov eax, T_DOUBLE
    jmp .srt_array
.srt_boolean:
    mov eax, T_BOOLEAN
    jmp .srt_array
.srt_class:
    mov eax, T_CLASS
.srt_array:
    test r12, r12
    je .srt_done
    mov eax, T_ARRAY
.srt_done:
    add rsp, 40
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

.globl semantic_analyse_variable_decl
.def semantic_analyse_variable_decl; .scl 2; .type 32; .endef
semantic_analyse_variable_decl:
    push rbx
    push rsi
    sub rsp, 40
    mov rbx, rcx
    mov esi, edx
    mov ecx, edx
    mov edx, r8d
    call semantic_is_assignable
    test eax, eax
    jne .sav_ok
    mov rcx, rbx
    call semantic_add_error
    xor eax, eax
    jmp .sav_done
.sav_ok:
    mov eax, 1
.sav_done:
    add rsp, 40
    pop rsi
    pop rbx
    ret

.globl semantic_analyse_guard_condition
.def semantic_analyse_guard_condition; .scl 2; .type 32; .endef
semantic_analyse_guard_condition:
    cmp edx, T_BOOLEAN
    je .sag_ok
    cmp edx, T_ERROR
    je .sag_ok
    cmp edx, T_UNKNOWN
    je .sag_ok
    call semantic_add_error
    xor eax, eax
    ret
.sag_ok:
    mov eax, 1
    ret

.globl semantic_analyse_foreach
.def semantic_analyse_foreach; .scl 2; .type 32; .endef
semantic_analyse_foreach:
    push rbx
    sub rsp, 32
    mov rbx, rcx
    cmp edx, T_ARRAY
    jne .saf_bad_source
    mov ecx, r8d
    mov edx, r9d
    call semantic_is_assignable
    test eax, eax
    jne .saf_ok
    mov rcx, rbx
    call semantic_add_error
    xor eax, eax
    jmp .saf_done
.saf_bad_source:
    mov rcx, rbx
    call semantic_add_error
    xor eax, eax
    jmp .saf_done
.saf_ok:
    mov eax, 1
.saf_done:
    add rsp, 32
    pop rbx
    ret

.globl semantic_analyse_binary
.def semantic_analyse_binary; .scl 2; .type 32; .endef
semantic_analyse_binary:
    push rbx
    push rsi
    push rdi
    push r12
    sub rsp, 40
    mov rbx, rcx
    mov esi, edx
    mov edi, r8d
    mov r12d, r9d
    cmp esi, '+'
    jne .sab_numeric
    cmp edi, T_STRING
    je .sab_string
    cmp r12d, T_STRING
    je .sab_string
.sab_numeric:
    cmp esi, '+'
    je .sab_arith
    cmp esi, '-'
    je .sab_arith
    cmp esi, '*'
    je .sab_arith
    cmp esi, '/'
    je .sab_arith
    cmp esi, '<'
    je .sab_compare
    cmp esi, '>'
    je .sab_compare
    cmp esi, '&'
    je .sab_bool
    cmp esi, '|'
    je .sab_bool
    cmp esi, '='
    je .sab_equal
    mov eax, T_ERROR
    jmp .sab_bad
.sab_string:
    mov eax, T_STRING
    jmp .sab_done
.sab_arith:
    mov ecx, edi
    call semantic_is_numeric
    test eax, eax
    je .sab_bad
    mov ecx, r12d
    call semantic_is_numeric
    test eax, eax
    je .sab_bad
    cmp edi, T_DOUBLE
    je .sab_double
    cmp r12d, T_DOUBLE
    je .sab_double
    cmp edi, T_LONG
    je .sab_long
    cmp r12d, T_LONG
    je .sab_long
    mov eax, T_INTEGER
    jmp .sab_done
.sab_double:
    mov eax, T_DOUBLE
    jmp .sab_done
.sab_long:
    mov eax, T_LONG
    jmp .sab_done
.sab_compare:
    mov ecx, edi
    call semantic_is_numeric
    test eax, eax
    je .sab_bad
    mov ecx, r12d
    call semantic_is_numeric
    test eax, eax
    je .sab_bad
    mov eax, T_BOOLEAN
    jmp .sab_done
.sab_bool:
    cmp edi, T_BOOLEAN
    jne .sab_bad
    cmp r12d, T_BOOLEAN
    jne .sab_bad
    mov eax, T_BOOLEAN
    jmp .sab_done
.sab_equal:
    cmp edi, r12d
    jne .sab_bad
    mov eax, T_BOOLEAN
    jmp .sab_done
.sab_bad:
    mov rcx, rbx
    call semantic_add_error
    mov eax, T_ERROR
.sab_done:
    add rsp, 40
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

.globl semantic_analyse_unary
.def semantic_analyse_unary; .scl 2; .type 32; .endef
semantic_analyse_unary:
    push rbx
    sub rsp, 32
    mov rbx, rcx
    cmp edx, '!'
    jne .sau_numeric
    cmp r8d, T_BOOLEAN
    je .sau_bool_ok
    jmp .sau_bad
.sau_bool_ok:
    mov eax, T_BOOLEAN
    jmp .sau_done
.sau_numeric:
    cmp edx, '-'
    jne .sau_bad
    mov ecx, r8d
    call semantic_is_numeric
    test eax, eax
    je .sau_bad
    mov eax, r8d
    jmp .sau_done
.sau_bad:
    mov rcx, rbx
    call semantic_add_error
    mov eax, T_ERROR
.sau_done:
    add rsp, 32
    pop rbx
    ret

.globl semantic_analyse_array_literal
.def semantic_analyse_array_literal; .scl 2; .type 32; .endef
semantic_analyse_array_literal:
    push rbx
    push rsi
    push rdi
    push r12
    sub rsp, 40
    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8
    test rdi, rdi
    je .saal_unknown
    mov r12d, [rsi]
    mov r9, 1
.saal_loop:
    cmp r9, rdi
    jae .saal_ok
    mov eax, [rsi+r9*4]
    cmp eax, r12d
    je .saal_next
    mov rcx, rbx
    call semantic_add_error
    mov eax, T_ERROR
    jmp .saal_done
.saal_next:
    inc r9
    jmp .saal_loop
.saal_unknown:
    mov eax, T_UNKNOWN
    jmp .saal_done
.saal_ok:
    mov eax, r12d
.saal_done:
    add rsp, 40
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

.globl semantic_builtin_member_type
.def semantic_builtin_member_type; .scl 2; .type 32; .endef
semantic_builtin_member_type:
    push rbx
    push rsi
    sub rsp, 40
    mov ebx, ecx
    mov rsi, rdx
    cmp ebx, T_ARRAY
    jne .sbm_map
    mov rcx, rsi
    lea rdx, [rip+s_contains]
    call semantic_streq
    test eax, eax
    jne .sbm_boolean
    mov rcx, rsi
    lea rdx, [rip+s_add]
    call semantic_streq
    test eax, eax
    jne .sbm_void
    mov rcx, rsi
    lea rdx, [rip+s_find]
    call semantic_streq
    test eax, eax
    jne .sbm_integer
    mov rcx, rsi
    lea rdx, [rip+s_size]
    call semantic_streq
    test eax, eax
    jne .sbm_integer
    mov rcx, rsi
    lea rdx, [rip+s_remove]
    call semantic_streq
    test eax, eax
    jne .sbm_void
    mov rcx, rsi
    lea rdx, [rip+s_join]
    call semantic_streq
    test eax, eax
    jne .sbm_string
    jmp .sbm_unknown
.sbm_map:
    cmp ebx, T_CLASS
    jne .sbm_string_obj
    mov rcx, rsi
    lea rdx, [rip+s_of]
    call semantic_streq
    test eax, eax
    jne .sbm_class
    mov rcx, rsi
    lea rdx, [rip+s_create]
    call semantic_streq
    test eax, eax
    jne .sbm_class
    mov rcx, rsi
    lea rdx, [rip+s_contains_key]
    call semantic_streq
    test eax, eax
    jne .sbm_boolean
    mov rcx, rsi
    lea rdx, [rip+s_is_empty]
    call semantic_streq
    test eax, eax
    jne .sbm_boolean
    mov rcx, rsi
    lea rdx, [rip+s_size]
    call semantic_streq
    test eax, eax
    jne .sbm_integer
    mov rcx, rsi
    lea rdx, [rip+s_to_string]
    call semantic_streq
    test eax, eax
    jne .sbm_string
    mov rcx, rsi
    lea rdx, [rip+s_clear]
    call semantic_streq
    test eax, eax
    jne .sbm_void
    mov rcx, rsi
    lea rdx, [rip+s_free]
    call semantic_streq
    test eax, eax
    jne .sbm_void
    jmp .sbm_unknown
.sbm_string_obj:
    cmp ebx, T_STRING
    jne .sbm_unknown
    mov rcx, rsi
    lea rdx, [rip+s_length]
    call semantic_streq
    test eax, eax
    jne .sbm_integer
    jmp .sbm_unknown
.sbm_error:
    mov eax, T_ERROR
    jmp .sbm_done
.sbm_unknown:
    mov eax, T_UNKNOWN
    jmp .sbm_done
.sbm_void:
    mov eax, T_VOID
    jmp .sbm_done
.sbm_integer:
    mov eax, T_INTEGER
    jmp .sbm_done
.sbm_string:
    mov eax, T_STRING
    jmp .sbm_done
.sbm_boolean:
    mov eax, T_BOOLEAN
    jmp .sbm_done
.sbm_class:
    mov eax, T_CLASS
.sbm_done:
    add rsp, 40
    pop rsi
    pop rbx
    ret

.globl semantic_remember_expr_type
.def semantic_remember_expr_type; .scl 2; .type 32; .endef
semantic_remember_expr_type:
    test rcx, rcx
    je .sret_done
    inc qword ptr [rcx+SA_EXPR_TYPES]
.sret_done:
    ret

.globl semantic_analyse_program
.def semantic_analyse_program; .scl 2; .type 32; .endef
semantic_analyse_program:
    test rcx, rcx
    je .sap_fail
    cmp qword ptr [rcx+SA_ERRORS], 0
    sete al
    movzx eax, al
    ret
.sap_fail:
    xor eax, eax
    ret
