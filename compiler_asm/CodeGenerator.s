.intel_syntax noprefix

.equ STATE_BUF, 0
.equ STATE_LEN, 8
.equ STATE_CAP, 16
.equ STATE_VARS, 24
.equ STATE_VAR_COUNT, 32
.equ STATE_VAR_CAP, 40
.equ STATE_LOCAL_OFFSET, 48
.equ STATE_CURRENT_FUNCTION, 56

.equ VAR_NAME, 0
.equ VAR_OFFSET, 8
.equ VAR_TYPE, 16
.equ VAR_SIZE, 24

.equ MODULE_STRINGS, 0
.equ MODULE_STRING_COUNT, 8
.equ MODULE_EXTERNS, 16
.equ MODULE_EXTERN_COUNT, 24
.equ MODULE_FUNCTIONS, 32
.equ MODULE_FUNCTION_COUNT, 40

.equ FUNCTION_NAME, 0
.equ FUNCTION_PARAMS, 8
.equ FUNCTION_PARAM_COUNT, 16
.equ FUNCTION_BLOCKS, 24
.equ FUNCTION_BLOCK_COUNT, 32
.equ FUNCTION_SIZE, 40

.equ PARAM_NAME, 0
.equ PARAM_TYPE, 8
.equ PARAM_SIZE, 16

.equ BLOCK_NAME, 0
.equ BLOCK_INSTRUCTIONS, 8
.equ BLOCK_INSTRUCTION_COUNT, 16
.equ BLOCK_SIZE, 24

.equ INST_OPCODE, 0
.equ INST_TYPE, 4
.equ INST_RESULT, 8
.equ INST_OPERANDS, 16
.equ INST_OPERAND_COUNT, 24
.equ INST_LABEL, 32
.equ INST_STRING, 40
.equ INST_INT, 48
.equ INST_DOUBLE_BITS, 56
.equ INST_SIZE, 64

.equ TYPE_VOID, 0
.equ TYPE_INTEGER, 1
.equ TYPE_LONG, 2
.equ TYPE_DOUBLE, 3
.equ TYPE_BOOLEAN, 4
.equ TYPE_POINTER, 5
.equ TYPE_ARRAY, 6
.equ TYPE_STRING, 7

.equ OP_CONST_INT, 0
.equ OP_CONST_LONG, 1
.equ OP_CONST_DOUBLE, 2
.equ OP_CONST_BOOL, 3
.equ OP_CONST_PTR, 4
.equ OP_ADD, 5
.equ OP_SUB, 6
.equ OP_MUL, 7
.equ OP_DIV, 8
.equ OP_MOD, 9
.equ OP_NEG, 10
.equ OP_EQ, 11
.equ OP_NE, 12
.equ OP_LT, 13
.equ OP_LE, 14
.equ OP_GT, 15
.equ OP_GE, 16
.equ OP_AND, 17
.equ OP_OR, 18
.equ OP_NOT, 19
.equ OP_LABEL, 20
.equ OP_JMP, 21
.equ OP_BRANCH, 22
.equ OP_RET, 23
.equ OP_CALL, 24
.equ OP_LOAD, 25
.equ OP_STORE, 26
.equ OP_ALLOCA, 27
.equ OP_ARRAY_NEW, 35
.equ OP_ARRAY_GET, 36
.equ OP_ARRAY_SET, 37
.equ OP_ARRAY_LEN, 38
.equ OP_ARRAY_PUSH, 39
.equ OP_CALL_RUNTIME, 40

.section .rdata
s_data: .asciz "section .data\n"
s_bss: .asciz "\nsection .bss\n\n"
s_text: .asciz "section .text\n"
s_global_main: .asciz "    global main\n\n"
s_main_label: .asciz "main:\n    push rbp\n    mov rbp, rsp\n"
s_main_this: .asciz "    mov rdi, 0\n"
s_main_tail: .asciz "    mov rax, 0\n    leave\n    ret\n\n"
s_prologue: .asciz ":\n    push rbp\n    mov rbp, rsp\n    push rbx\n    push r12\n    push r13\n    push r14\n    push r15\n"
s_epilogue_zero: .asciz "    mov rax, 0\n"
s_epilogue: .asciz "    pop r15\n    pop r14\n    pop r13\n    pop r12\n    pop rbx\n    leave\n    ret\n\n"
s_colon_nl: .asciz ":\n"
s_func_sep: .asciz "_"
s_indent: .asciz "    "
s_mov_rax: .asciz "    mov rax, "
s_mov_store_prefix: .asciz "    mov [rbp-"
s_store_mid: .asciz "], rax\n"
s_mov_load_prefix: .asciz "    mov "
s_load_mid: .asciz ", [rbp-"
s_load_end: .asciz "]\n"
s_lea_prefix: .asciz "    lea "
s_lea_mid: .asciz ", [rbp-"
s_lea_rel_mid: .asciz ", [rel "
s_xor_prefix: .asciz "    xor "
s_xor_mid: .asciz ", "
s_nl: .asciz "\n"
s_comma_space: .asciz ", "
s_extern: .asciz "    extern "
s_string_data_suffix: .asciz "_data db '"
s_string_obj_mid: .asciz "' , 0\n    "
s_string_obj_dq: .asciz " dq "
s_string_len_mid: .asciz "_data, "
s_call: .asciz "    call "
s_sub_rsp: .asciz "    sub rsp, "
s_add_rsp: .asciz "    add rsp, "
s_mov_stack_arg: .asciz "    mov [rsp+"
s_stack_arg_end: .asciz "], rax\n"
s_add: .asciz "    add rax, rbx\n"
s_sub: .asciz "    sub rax, rbx\n"
s_mul: .asciz "    imul rax, rbx\n"
s_cqo_idiv: .asciz "    cqo\n    idiv rbx\n"
s_store_rdx_prefix: .asciz "    mov [rbp-"
s_store_rdx_end: .asciz "], rdx\n"
s_cmp: .asciz "    cmp rax, rbx\n"
s_sete: .asciz "    sete al\n    movzx rax, al\n"
s_setne: .asciz "    setne al\n    movzx rax, al\n"
s_setl: .asciz "    setl al\n    movzx rax, al\n"
s_setle: .asciz "    setle al\n    movzx rax, al\n"
s_setg: .asciz "    setg al\n    movzx rax, al\n"
s_setge: .asciz "    setge al\n    movzx rax, al\n"
s_and: .asciz "    and rax, rbx\n"
s_or: .asciz "    or rax, rbx\n"
s_not: .asciz "    xor rax, 1\n"
s_jmp: .asciz "    jmp "
s_test: .asciz "    test rax, rax\n    jne "
s_jmp_plain: .asciz "\n    jmp "
s_xor_rax: .asciz "    xor rax, rax\n"
s_array_create: .asciz "array_create"
s_array_get: .asciz "array_get"
s_array_add: .asciz "array_add"
s_array_size: .asciz "array_size"
s_string_concat: .asciz "string_concat"
s_unknown: .asciz "    ; unknown instruction\n"
s_rcx: .asciz "rcx"
s_rdx: .asciz "rdx"
s_r8: .asciz "r8"
s_r9: .asciz "r9"
s_rax: .asciz "rax"
s_rbx: .asciz "rbx"
s_al: .asciz "al"
s_ptr: .asciz "str_"
s_runtime_funcs:
    .quad rt_print_cstr, rt_print_string, rt_print_uint, rt_string_equals
    .quad rt_string_concat, rt_string_copy, rt_string_free, rt_string_from_cstr
    .quad rt_int_add, rt_int_sub, rt_int_mul, rt_int_div, rt_int_mod
    .quad rt_int_eq, rt_int_lt, rt_int_gt
    .quad rt_array_create, rt_array_add, rt_array_find, rt_array_remove
    .quad rt_array_size, rt_array_get, rt_array_free
    .quad rt_array_filter, rt_array_sort, rt_array_map, rt_array_join
    .quad rt_map_init, rt_map_create, rt_map_put, rt_map_get
    .quad rt_map_contains_key, rt_map_remove, rt_map_size, rt_map_clear, rt_map_free
    .quad rt_malloc, rt_free, rt_realloc, rt_fileint_get, rt_fileint_set, rt_print
    .quad 0
rt_print_cstr: .asciz "print_cstr"
rt_print_string: .asciz "print_string"
rt_print_uint: .asciz "print_uint"
rt_string_equals: .asciz "string_equals"
rt_string_concat: .asciz "string_concat"
rt_string_copy: .asciz "string_copy"
rt_string_free: .asciz "string_free"
rt_string_from_cstr: .asciz "string_from_cstr"
rt_int_add: .asciz "int_add"
rt_int_sub: .asciz "int_sub"
rt_int_mul: .asciz "int_mul"
rt_int_div: .asciz "int_div"
rt_int_mod: .asciz "int_mod"
rt_int_eq: .asciz "int_eq"
rt_int_lt: .asciz "int_lt"
rt_int_gt: .asciz "int_gt"
rt_array_create: .asciz "array_create"
rt_array_add: .asciz "array_add"
rt_array_find: .asciz "array_find"
rt_array_remove: .asciz "array_remove"
rt_array_size: .asciz "array_size"
rt_array_get: .asciz "array_get"
rt_array_free: .asciz "array_free"
rt_array_filter: .asciz "array_filter"
rt_array_sort: .asciz "array_sort"
rt_array_map: .asciz "array_map"
rt_array_join: .asciz "array_join"
rt_map_init: .asciz "map_init"
rt_map_create: .asciz "map_create"
rt_map_put: .asciz "map_put"
rt_map_get: .asciz "map_get"
rt_map_contains_key: .asciz "map_contains_key"
rt_map_remove: .asciz "map_remove"
rt_map_size: .asciz "map_size"
rt_map_clear: .asciz "map_clear"
rt_map_free: .asciz "map_free"
rt_malloc: .asciz "malloc"
rt_free: .asciz "free"
rt_realloc: .asciz "realloc"
rt_fileint_get: .asciz "fileint_get"
rt_fileint_set: .asciz "fileint_set"
rt_print: .asciz "print"

.text
.globl codegen_strlen
.def codegen_strlen; .scl 2; .type 32; .endef
codegen_strlen:
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

.globl codegen_starts_with
.def codegen_starts_with; .scl 2; .type 32; .endef
codegen_starts_with:
    test rcx, rcx
    je .starts_no
    test rdx, rdx
    je .starts_no
.starts_loop:
    mov r8b, [rdx]
    test r8b, r8b
    je .starts_yes
    cmp [rcx], r8b
    jne .starts_no
    inc rcx
    inc rdx
    jmp .starts_loop
.starts_yes:
    mov eax, 1
    ret
.starts_no:
    xor eax, eax
    ret

.globl codegen_init
.def codegen_init; .scl 2; .type 32; .endef
codegen_init:
    test rcx, rcx
    je .init_done
    mov [rcx + STATE_BUF], rdx
    mov [rcx + STATE_CAP], r8
    mov [rcx + STATE_VARS], r9
    mov rax, [rsp + 40]
    mov [rcx + STATE_VAR_CAP], rax
    mov qword ptr [rcx + STATE_LEN], 0
    mov qword ptr [rcx + STATE_VAR_COUNT], 0
    mov qword ptr [rcx + STATE_CURRENT_FUNCTION], 0
    mov dword ptr [rcx + STATE_LOCAL_OFFSET], 8
    test rdx, rdx
    je .init_done
    mov byte ptr [rdx], 0
.init_done:
    ret

.globl codegen_output_length
.def codegen_output_length; .scl 2; .type 32; .endef
codegen_output_length:
    xor eax, eax
    test rcx, rcx
    je .out_len_done
    mov rax, [rcx + STATE_LEN]
.out_len_done:
    ret

.globl codegen_output
.def codegen_output; .scl 2; .type 32; .endef
codegen_output:
    xor eax, eax
    test rcx, rcx
    je .out_done
    mov rax, [rcx + STATE_BUF]
.out_done:
    ret

.globl codegen_append_cstr
.def codegen_append_cstr; .scl 2; .type 32; .endef
codegen_append_cstr:
    push rbx
    push rsi
    push rdi
    xor eax, eax
    test rcx, rcx
    je .append_done
    test rdx, rdx
    je .append_done
    mov rbx, rcx
    mov rsi, rdx
    mov rdi, [rbx + STATE_BUF]
    test rdi, rdi
    je .append_done
    add rdi, [rbx + STATE_LEN]
.append_loop:
    mov al, [rsi]
    test al, al
    je .append_finish
    mov r8, [rbx + STATE_LEN]
    add r8, 1
    cmp r8, [rbx + STATE_CAP]
    jae .append_finish
    mov [rdi], al
    inc rdi
    inc rsi
    inc qword ptr [rbx + STATE_LEN]
    jmp .append_loop
.append_finish:
    mov byte ptr [rdi], 0
    mov eax, 1
.append_done:
    pop rdi
    pop rsi
    pop rbx
    ret

.globl codegen_append_int
.def codegen_append_int; .scl 2; .type 32; .endef
codegen_append_int:
    push rbx
    push rsi
    sub rsp, 72
    mov rbx, rcx
    mov rax, rdx
    lea rsi, [rsp + 63]
    mov byte ptr [rsi], 0
    mov r8d, 0
    test rax, rax
    jge .int_abs
    neg rax
    mov r8d, 1
.int_abs:
    mov r9d, 10
.int_loop:
    xor edx, edx
    div r9
    add dl, '0'
    dec rsi
    mov [rsi], dl
    test rax, rax
    jne .int_loop
    test r8d, r8d
    je .int_emit
    dec rsi
    mov byte ptr [rsi], '-'
.int_emit:
    mov rcx, rbx
    mov rdx, rsi
    call codegen_append_cstr
    add rsp, 72
    pop rsi
    pop rbx
    ret

.globl codegen_reg_for_param
.def codegen_reg_for_param; .scl 2; .type 32; .endef
codegen_reg_for_param:
    cmp rcx, 0
    je .reg_rcx
    cmp rcx, 1
    je .reg_rdx
    cmp rcx, 2
    je .reg_r8
    cmp rcx, 3
    je .reg_r9
    lea rax, [rip + s_rax]
    ret
.reg_rcx: lea rax, [rip + s_rcx]; ret
.reg_rdx: lea rax, [rip + s_rdx]; ret
.reg_r8: lea rax, [rip + s_r8]; ret
.reg_r9: lea rax, [rip + s_r9]; ret

.globl codegen_reg_for_type
.def codegen_reg_for_type; .scl 2; .type 32; .endef
codegen_reg_for_type:
    cmp ecx, TYPE_BOOLEAN
    jne .type_rax
    lea rax, [rip + s_al]
    ret
.type_rax:
    lea rax, [rip + s_rax]
    ret

.globl codegen_var_location
.def codegen_var_location; .scl 2; .type 32; .endef
codegen_var_location:
    push rbx
    push rsi
    push rdi
    mov rbx, rcx
    mov rsi, rdx
    xor eax, eax
    test rbx, rbx
    je .var_done
    mov rdi, [rbx + STATE_VARS]
    mov r9, [rbx + STATE_VAR_COUNT]
.var_loop:
    test r9, r9
    je .var_done
    mov rcx, [rdi + VAR_NAME]
    mov rdx, rsi
    call codegen_str_eq
    test eax, eax
    jne .var_found
    add rdi, VAR_SIZE
    dec r9
    jmp .var_loop
.var_found:
    mov rax, [rdi + VAR_OFFSET]
.var_done:
    pop rdi
    pop rsi
    pop rbx
    ret

.globl codegen_str_eq
.def codegen_str_eq; .scl 2; .type 32; .endef
codegen_str_eq:
    test rcx, rcx
    je .eq_no
    test rdx, rdx
    je .eq_no
.eq_loop:
    mov r8b, [rcx]
    cmp r8b, [rdx]
    jne .eq_no
    test r8b, r8b
    je .eq_yes
    inc rcx
    inc rdx
    jmp .eq_loop
.eq_yes:
    mov eax, 1
    ret
.eq_no:
    xor eax, eax
    ret

.globl codegen_assign_location
.def codegen_assign_location; .scl 2; .type 32; .endef
codegen_assign_location:
    push rbx
    push rdi
    xor eax, eax
    test rcx, rcx
    je .assign_done
    mov rbx, rcx
    mov rax, [rbx + STATE_VAR_COUNT]
    cmp rax, [rbx + STATE_VAR_CAP]
    jae .assign_full
    mov rdi, [rbx + STATE_VARS]
    imul rax, rax, VAR_SIZE
    add rdi, rax
    mov [rdi + VAR_NAME], rdx
    mov eax, [rbx + STATE_LOCAL_OFFSET]
    mov [rdi + VAR_OFFSET], rax
    mov [rdi + VAR_TYPE], r8d
    add dword ptr [rbx + STATE_LOCAL_OFFSET], 8
    inc qword ptr [rbx + STATE_VAR_COUNT]
    mov rax, [rdi + VAR_OFFSET]
.assign_done:
    pop rdi
    pop rbx
    ret
.assign_full:
    xor eax, eax
    jmp .assign_done

.globl codegen_emit_move_to_reg
.def codegen_emit_move_to_reg; .scl 2; .type 32; .endef
codegen_emit_move_to_reg:
    push rbx
    push rsi
    push rdi
    sub rsp, 32
    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8
    test rsi, rsi
    je .move_zero
    mov al, [rsi]
    cmp al, '-'
    je .move_number
    cmp al, '0'
    jb .move_lookup
    cmp al, '9'
    jbe .move_number
.move_lookup:
    mov rcx, rbx
    mov rdx, rsi
    call codegen_var_location
    test rax, rax
    jne .move_var
    mov rcx, rsi
    lea rdx, [rip + s_ptr]
    call codegen_starts_with
    test eax, eax
    jne .move_rel
    jmp .move_zero
.move_number:
    mov rcx, rbx
    lea rdx, [rip + s_mov_load_prefix]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, rdi
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_comma_space]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, rsi
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_nl]
    call codegen_append_cstr
    jmp .move_done
.move_var:
    mov r9, rax
    mov rcx, rbx
    lea rdx, [rip + s_mov_load_prefix]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, rdi
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_load_mid]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, r9
    call codegen_append_int
    mov rcx, rbx
    lea rdx, [rip + s_load_end]
    call codegen_append_cstr
    jmp .move_done
.move_rel:
    mov rcx, rbx
    lea rdx, [rip + s_lea_prefix]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, rdi
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_lea_rel_mid]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, rsi
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_load_end]
    call codegen_append_cstr
    jmp .move_done
.move_zero:
    mov rcx, rbx
    lea rdx, [rip + s_xor_prefix]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, rdi
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_xor_mid]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, rdi
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_nl]
    call codegen_append_cstr
.move_done:
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret

.globl codegen_emit_address_to_reg
.def codegen_emit_address_to_reg; .scl 2; .type 32; .endef
codegen_emit_address_to_reg:
    push rbx
    push rsi
    push rdi
    sub rsp, 32
    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8
    test rsi, rsi
    je .addr_zero
    cmp byte ptr [rsi], '&'
    jne .addr_base_ready
    inc rsi
.addr_base_ready:
    mov rcx, rbx
    mov rdx, rsi
    call codegen_var_location
    test rax, rax
    jne .addr_var
    mov rcx, rsi
    lea rdx, [rip + s_ptr]
    call codegen_starts_with
    test eax, eax
    jne .addr_rel
    jmp .addr_zero
.addr_var:
    mov r9, rax
    mov rcx, rbx
    lea rdx, [rip + s_lea_prefix]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, rdi
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_lea_mid]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, r9
    call codegen_append_int
    mov rcx, rbx
    lea rdx, [rip + s_load_end]
    call codegen_append_cstr
    jmp .addr_done
.addr_rel:
    mov rcx, rbx
    lea rdx, [rip + s_lea_prefix]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, rdi
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_lea_rel_mid]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, rsi
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_load_end]
    call codegen_append_cstr
    jmp .addr_done
.addr_zero:
    mov rcx, rbx
    lea rdx, [rip + s_xor_prefix]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, rdi
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_xor_mid]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, rdi
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_nl]
    call codegen_append_cstr
.addr_done:
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret

.globl codegen_emit_move_from_reg
.def codegen_emit_move_from_reg; .scl 2; .type 32; .endef
codegen_emit_move_from_reg:
    push rbx
    push rsi
    sub rsp, 32
    mov rbx, rcx
    mov rsi, rdx
    mov rdx, r8
    call codegen_var_location
    test rax, rax
    je .from_done
    mov r9, rax
    mov rcx, rbx
    lea rdx, [rip + s_mov_store_prefix]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, r9
    call codegen_append_int
    mov rcx, rbx
    lea rdx, [rip + s_store_mid]
    call codegen_append_cstr
.from_done:
    add rsp, 32
    pop rsi
    pop rbx
    ret

.globl codegen_mangle_symbol
.def codegen_mangle_symbol; .scl 2; .type 32; .endef
codegen_mangle_symbol:
    xor rax, rax
    test rcx, rcx
    je .mangle_done
    test rdx, rdx
    je .mangle_done
    mov r8, rcx
.mangle_loop:
    mov al, [r8]
    cmp al, 0
    je .mangle_term
    cmp al, '.'
    jne .mangle_copy
    mov al, '_'
.mangle_copy:
    mov [rdx], al
    inc r8
    inc rdx
    jmp .mangle_loop
.mangle_term:
    mov byte ptr [rdx], 0
    mov eax, 1
.mangle_done:
    ret

.globl codegen_emit_data_section
.def codegen_emit_data_section; .scl 2; .type 32; .endef
codegen_emit_data_section:
    push rbx
    push rsi
    push rdi
    push r12
    sub rsp, 32
    mov rbx, rcx
    mov rsi, rdx
    lea rdx, [rip + s_data]
    call codegen_append_cstr
    test rsi, rsi
    je .data_bss
    mov rdi, [rsi + MODULE_STRINGS]
    mov r12, [rsi + MODULE_STRING_COUNT]
.data_loop:
    test rdi, rdi
    je .data_bss
    test r12, r12
    je .data_bss
    mov rcx, rbx
    lea rdx, [rip + s_indent]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, [rdi]
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_string_data_suffix]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, [rdi + 8]
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_string_obj_mid]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, [rdi]
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_string_obj_dq]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, [rdi]
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_string_len_mid]
    call codegen_append_cstr
    mov rcx, [rdi + 8]
    call codegen_strlen
    mov rcx, rbx
    mov rdx, rax
    call codegen_append_int
    mov rcx, rbx
    lea rdx, [rip + s_nl]
    call codegen_append_cstr
    add rdi, 16
    dec r12
    jmp .data_loop
.data_bss:
    mov rcx, rbx
    lea rdx, [rip + s_bss]
    call codegen_append_cstr
    add rsp, 32
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

.globl codegen_emit_text_section
.def codegen_emit_text_section; .scl 2; .type 32; .endef
codegen_emit_text_section:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    sub rsp, 32
    mov rbx, rcx
    mov rsi, rdx
    mov r13d, r8d
    lea rdx, [rip + s_text]
    call codegen_append_cstr
    lea rdi, [rip + s_runtime_funcs]
.runtime_loop:
    mov rdx, [rdi]
    test rdx, rdx
    je .runtime_done
    mov rcx, rbx
    lea rdx, [rip + s_extern]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, [rdi]
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_nl]
    call codegen_append_cstr
    add rdi, 8
    jmp .runtime_loop
.runtime_done:
    test rsi, rsi
    je .after_externs
    mov rdi, [rsi + MODULE_EXTERNS]
    mov r12, [rsi + MODULE_EXTERN_COUNT]
.extern_loop:
    test rdi, rdi
    je .after_externs
    test r12, r12
    je .after_externs
    mov rcx, rbx
    lea rdx, [rip + s_extern]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, [rdi]
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_nl]
    call codegen_append_cstr
    add rdi, 8
    dec r12
    jmp .extern_loop
.after_externs:
    mov rcx, rbx
    lea rdx, [rip + s_nl]
    call codegen_append_cstr
    test r13d, r13d
    je .functions
    mov rcx, rbx
    lea rdx, [rip + s_global_main]
    call codegen_append_cstr
.functions:
    test rsi, rsi
    je .text_done
    mov rdi, [rsi + MODULE_FUNCTIONS]
    mov r12, [rsi + MODULE_FUNCTION_COUNT]
.function_loop:
    test rdi, rdi
    je .entry
    test r12, r12
    je .entry
    mov rcx, rbx
    mov rdx, rdi
    call codegen_emit_function
    add rdi, FUNCTION_SIZE
    dec r12
    jmp .function_loop
.entry:
    test r13d, r13d
    je .text_done
    test rsi, rsi
    je .text_done
    mov rcx, rbx
    lea rdx, [rip + s_main_label]
    call codegen_append_cstr
    cmp qword ptr [rsi + MODULE_FUNCTION_COUNT], 0
    je .entry_tail
    mov rcx, rbx
    lea rdx, [rip + s_main_this]
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_call]
    call codegen_append_cstr
    mov rdi, [rsi + MODULE_FUNCTIONS]
    mov rcx, rbx
    mov rdx, [rdi + FUNCTION_NAME]
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_nl]
    call codegen_append_cstr
.entry_tail:
    mov rcx, rbx
    lea rdx, [rip + s_main_tail]
    call codegen_append_cstr
.text_done:
    add rsp, 32
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

.globl codegen_generate
.def codegen_generate; .scl 2; .type 32; .endef
codegen_generate:
    push rbx
    push rsi
    push rdi
    sub rsp, 32
    mov rbx, rcx
    mov rsi, rdx
    mov edi, r8d
    test rbx, rbx
    je .generate_done
    mov qword ptr [rbx + STATE_LEN], 0
    mov qword ptr [rbx + STATE_VAR_COUNT], 0
    mov dword ptr [rbx + STATE_LOCAL_OFFSET], 8
    mov rax, [rbx + STATE_BUF]
    test rax, rax
    je .generate_emit
    mov byte ptr [rax], 0
.generate_emit:
    mov rcx, rbx
    mov rdx, rsi
    call codegen_emit_data_section
    mov rcx, rbx
    mov rdx, rsi
    mov r8d, edi
    call codegen_emit_text_section
.generate_done:
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret

.globl codegen_emit_function
.def codegen_emit_function; .scl 2; .type 32; .endef
codegen_emit_function:
    push rbx
    push rsi
    push rdi
    push r12
    sub rsp, 32
    mov rbx, rcx
    mov rsi, rdx
    test rbx, rbx
    je .func_done
    test rsi, rsi
    je .func_done
    mov rax, [rsi + FUNCTION_NAME]
    mov [rbx + STATE_CURRENT_FUNCTION], rax
    mov qword ptr [rbx + STATE_VAR_COUNT], 0
    mov dword ptr [rbx + STATE_LOCAL_OFFSET], 8
    mov rcx, rbx
    mov rdx, [rsi + FUNCTION_NAME]
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_prologue]
    call codegen_append_cstr
    add dword ptr [rbx + STATE_LOCAL_OFFSET], 40
    mov rdi, [rsi + FUNCTION_PARAMS]
    mov r12, [rsi + FUNCTION_PARAM_COUNT]
.param_loop:
    test rdi, rdi
    je .blocks_start
    test r12, r12
    je .blocks_start
    mov rcx, rbx
    mov rdx, [rdi + PARAM_NAME]
    mov r8d, [rdi + PARAM_TYPE]
    call codegen_assign_location
    add rdi, PARAM_SIZE
    dec r12
    jmp .param_loop
.blocks_start:
    mov rdi, [rsi + FUNCTION_BLOCKS]
    mov r12, [rsi + FUNCTION_BLOCK_COUNT]
.block_loop:
    test rdi, rdi
    je .func_epilogue
    test r12, r12
    je .func_epilogue
    mov rcx, rbx
    mov rdx, rdi
    call codegen_emit_block
    add rdi, BLOCK_SIZE
    dec r12
    jmp .block_loop
.func_epilogue:
    mov rcx, rbx
    lea rdx, [rip + s_epilogue_zero]
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_epilogue]
    call codegen_append_cstr
.func_done:
    add rsp, 32
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

.globl codegen_emit_block
.def codegen_emit_block; .scl 2; .type 32; .endef
codegen_emit_block:
    push rbx
    push rsi
    push rdi
    push r12
    sub rsp, 32
    mov rbx, rcx
    mov rsi, rdx
    test rbx, rbx
    je .block_done
    test rsi, rsi
    je .block_done
    mov rcx, rbx
    mov rdx, [rbx + STATE_CURRENT_FUNCTION]
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_func_sep]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, [rsi + BLOCK_NAME]
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_colon_nl]
    call codegen_append_cstr
    mov rdi, [rsi + BLOCK_INSTRUCTIONS]
    mov r12, [rsi + BLOCK_INSTRUCTION_COUNT]
.inst_loop:
    test rdi, rdi
    je .block_done
    test r12, r12
    je .block_done
    mov rcx, rbx
    mov rdx, rdi
    call codegen_emit_instruction
    add rdi, INST_SIZE
    dec r12
    jmp .inst_loop
.block_done:
    add rsp, 32
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

.globl codegen_store_result
.def codegen_store_result; .scl 2; .type 32; .endef
codegen_store_result:
    push rbx
    push rsi
    sub rsp, 32
    mov rbx, rcx
    mov rsi, rdx
    test rsi, rsi
    je .store_result_done
    cmp byte ptr [rsi], 0
    je .store_result_done
    mov rcx, rbx
    mov rdx, rsi
    mov r8d, r9d
    call codegen_assign_location
    mov r9, rax
    mov rcx, rbx
    lea rdx, [rip + s_mov_store_prefix]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, r9
    call codegen_append_int
    mov rcx, rbx
    lea rdx, [rip + s_store_mid]
    call codegen_append_cstr
.store_result_done:
    add rsp, 32
    pop rsi
    pop rbx
    ret

.globl codegen_emit_instruction
.def codegen_emit_instruction; .scl 2; .type 32; .endef
codegen_emit_instruction:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    sub rsp, 64
    mov rbx, rcx
    mov rsi, rdx
    test rbx, rbx
    je .inst_done
    test rsi, rsi
    je .inst_done
    mov eax, [rsi + INST_OPCODE]
    cmp eax, OP_CONST_INT
    je .const_int
    cmp eax, OP_CONST_LONG
    je .const_int
    cmp eax, OP_CONST_BOOL
    je .const_bool
    cmp eax, OP_CONST_DOUBLE
    je .const_double
    cmp eax, OP_CONST_PTR
    je .const_ptr
    cmp eax, OP_ADD
    je .binary_add
    cmp eax, OP_SUB
    je .binary_sub
    cmp eax, OP_MUL
    je .binary_mul
    cmp eax, OP_DIV
    je .binary_div
    cmp eax, OP_MOD
    je .binary_mod
    cmp eax, OP_EQ
    je .compare_eq
    cmp eax, OP_NE
    je .compare_ne
    cmp eax, OP_LT
    je .compare_lt
    cmp eax, OP_LE
    je .compare_le
    cmp eax, OP_GT
    je .compare_gt
    cmp eax, OP_GE
    je .compare_ge
    cmp eax, OP_AND
    je .logic_and
    cmp eax, OP_OR
    je .logic_or
    cmp eax, OP_NOT
    je .logic_not
    cmp eax, OP_LABEL
    je .label
    cmp eax, OP_JMP
    je .jmp
    cmp eax, OP_BRANCH
    je .branch
    cmp eax, OP_RET
    je .ret
    cmp eax, OP_CALL
    je .call
    cmp eax, OP_CALL_RUNTIME
    je .call
    cmp eax, OP_LOAD
    je .load
    cmp eax, OP_STORE
    je .store
    cmp eax, OP_ALLOCA
    je .alloca
    cmp eax, OP_ARRAY_NEW
    je .array_new
    cmp eax, OP_ARRAY_GET
    je .array_get
    cmp eax, OP_ARRAY_SET
    je .array_set
    cmp eax, OP_ARRAY_PUSH
    je .array_push
    cmp eax, OP_ARRAY_LEN
    je .array_len
    mov rcx, rbx
    lea rdx, [rip + s_unknown]
    call codegen_append_cstr
    jmp .inst_done
.const_bool:
    mov r13, [rsi + INST_INT]
    test r13, r13
    setne r13b
    movzx r13, r13b
    jmp .emit_mov_imm
.const_double:
    mov r13, [rsi + INST_DOUBLE_BITS]
    jmp .emit_mov_imm
.const_int:
    mov r13, [rsi + INST_INT]
.emit_mov_imm:
    mov rcx, rbx
    lea rdx, [rip + s_mov_rax]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, r13
    call codegen_append_int
    mov rcx, rbx
    lea rdx, [rip + s_nl]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, [rsi + INST_RESULT]
    mov r9d, [rsi + INST_TYPE]
    call codegen_store_result
    jmp .inst_done
.const_ptr:
    mov rdx, [rsi + INST_STRING]
    test rdx, rdx
    je .ptr_zero
    cmp byte ptr [rdx], 0
    je .ptr_zero
    mov rcx, rbx
    lea r8, [rip + s_rax]
    call codegen_emit_address_to_reg
    jmp .ptr_store
.ptr_zero:
    mov rcx, rbx
    lea rdx, [rip + s_xor_rax]
    call codegen_append_cstr
.ptr_store:
    mov rcx, rbx
    mov rdx, [rsi + INST_RESULT]
    mov r9d, [rsi + INST_TYPE]
    call codegen_store_result
    jmp .inst_done
.binary_add:
    cmp dword ptr [rsi + INST_TYPE], TYPE_STRING
    je .string_add
    cmp dword ptr [rsi + INST_TYPE], TYPE_POINTER
    je .string_add
    lea r13, [rip + s_add]
    jmp .binary_common
.binary_sub: lea r13, [rip + s_sub]; jmp .binary_common
.binary_mul: lea r13, [rip + s_mul]; jmp .binary_common
.binary_div: lea r13, [rip + s_cqo_idiv]; jmp .binary_common
.binary_mod: lea r13, [rip + s_cqo_idiv]; jmp .binary_common
.binary_common:
    mov rdi, [rsi + INST_OPERANDS]
    test rdi, rdi
    je .inst_done
    mov rcx, rbx
    mov rdx, [rdi]
    lea r8, [rip + s_rax]
    call codegen_emit_move_to_reg
    mov rcx, rbx
    mov rdx, [rdi + 8]
    lea r8, [rip + s_rbx]
    call codegen_emit_move_to_reg
    mov rcx, rbx
    mov rdx, r13
    call codegen_append_cstr
    cmp dword ptr [rsi + INST_OPCODE], OP_MOD
    jne .binary_store_rax
    mov rcx, rbx
    mov rdx, [rsi + INST_RESULT]
    mov r8d, [rsi + INST_TYPE]
    call codegen_assign_location
    mov r9, rax
    mov rcx, rbx
    lea rdx, [rip + s_store_rdx_prefix]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, r9
    call codegen_append_int
    mov rcx, rbx
    lea rdx, [rip + s_store_rdx_end]
    call codegen_append_cstr
    jmp .inst_done
.binary_store_rax:
    mov rcx, rbx
    mov rdx, [rsi + INST_RESULT]
    mov r9d, [rsi + INST_TYPE]
    call codegen_store_result
    jmp .inst_done
.string_add:
    mov rcx, rbx
    lea rdx, [rip + s_sub_rsp]
    call codegen_append_cstr
    mov rcx, rbx
    mov edx, 32
    call codegen_append_int
    mov rcx, rbx
    lea rdx, [rip + s_nl]
    call codegen_append_cstr
    mov rdi, [rsi + INST_OPERANDS]
    mov rcx, rbx
    mov rdx, [rdi]
    lea r8, [rip + s_rcx]
    call codegen_emit_move_to_reg
    mov rcx, rbx
    mov rdx, [rdi + 8]
    lea r8, [rip + s_rdx]
    call codegen_emit_move_to_reg
    mov rcx, rbx
    lea rdx, [rip + s_call]
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_string_concat]
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_nl]
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_add_rsp]
    call codegen_append_cstr
    mov rcx, rbx
    mov edx, 32
    call codegen_append_int
    mov rcx, rbx
    lea rdx, [rip + s_nl]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, [rsi + INST_RESULT]
    mov r9d, [rsi + INST_TYPE]
    call codegen_store_result
    jmp .inst_done
.compare_eq: lea r13, [rip + s_sete]; jmp .compare_common
.compare_ne: lea r13, [rip + s_setne]; jmp .compare_common
.compare_lt: lea r13, [rip + s_setl]; jmp .compare_common
.compare_le: lea r13, [rip + s_setle]; jmp .compare_common
.compare_gt: lea r13, [rip + s_setg]; jmp .compare_common
.compare_ge: lea r13, [rip + s_setge]; jmp .compare_common
.compare_common:
    mov rdi, [rsi + INST_OPERANDS]
    mov rcx, rbx
    mov rdx, [rdi]
    lea r8, [rip + s_rax]
    call codegen_emit_move_to_reg
    mov rcx, rbx
    mov rdx, [rdi + 8]
    lea r8, [rip + s_rbx]
    call codegen_emit_move_to_reg
    mov rcx, rbx
    lea rdx, [rip + s_cmp]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, r13
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, [rsi + INST_RESULT]
    mov r9d, TYPE_BOOLEAN
    call codegen_store_result
    jmp .inst_done
.logic_and: lea r13, [rip + s_and]; jmp .binary_common
.logic_or: lea r13, [rip + s_or]; jmp .binary_common
.logic_not:
    mov rdi, [rsi + INST_OPERANDS]
    mov rcx, rbx
    mov rdx, [rdi]
    lea r8, [rip + s_rax]
    call codegen_emit_move_to_reg
    mov rcx, rbx
    lea rdx, [rip + s_not]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, [rsi + INST_RESULT]
    mov r9d, [rsi + INST_TYPE]
    call codegen_store_result
    jmp .inst_done
.label:
    mov rcx, rbx
    mov rdx, [rbx + STATE_CURRENT_FUNCTION]
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_func_sep]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, [rsi + INST_LABEL]
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_colon_nl]
    call codegen_append_cstr
    jmp .inst_done
.jmp:
    mov rcx, rbx
    lea rdx, [rip + s_jmp]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, [rbx + STATE_CURRENT_FUNCTION]
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_func_sep]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, [rsi + INST_LABEL]
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_nl]
    call codegen_append_cstr
    jmp .inst_done
.branch:
    mov rdi, [rsi + INST_OPERANDS]
    mov rcx, rbx
    mov rdx, [rdi]
    lea r8, [rip + s_rax]
    call codegen_emit_move_to_reg
    mov rcx, rbx
    lea rdx, [rip + s_test]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, [rbx + STATE_CURRENT_FUNCTION]
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_func_sep]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, [rdi + 8]
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_jmp_plain]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, [rbx + STATE_CURRENT_FUNCTION]
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_func_sep]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, [rdi + 16]
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_nl]
    call codegen_append_cstr
    jmp .inst_done
.ret:
    cmp qword ptr [rsi + INST_OPERAND_COUNT], 0
    je .ret_zero
    mov rdi, [rsi + INST_OPERANDS]
    mov rcx, rbx
    mov rdx, [rdi]
    lea r8, [rip + s_rax]
    call codegen_emit_move_to_reg
    jmp .ret_tail
.ret_zero:
    mov rcx, rbx
    lea rdx, [rip + s_xor_rax]
    call codegen_append_cstr
.ret_tail:
    mov rcx, rbx
    lea rdx, [rip + s_epilogue]
    call codegen_append_cstr
    jmp .inst_done
.call:
    mov rdi, [rsi + INST_OPERANDS]
    mov r12, [rsi + INST_OPERAND_COUNT]
    test rdi, rdi
    je .inst_done
    mov r13, r12
    test r13, r13
    je .inst_done
    dec r13
    mov rax, r13
    cmp rax, 4
    jbe .call_frame
    sub rax, 4
    imul rax, rax, 8
    add rax, 32
    jmp .call_align
.call_frame:
    mov eax, 32
.call_align:
    test rax, 15
    je .call_frame_ready
    add rax, 8
.call_frame_ready:
    mov [rsp + 56], rax
    mov rcx, rbx
    lea rdx, [rip + s_sub_rsp]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, [rsp + 56]
    call codegen_append_int
    mov rcx, rbx
    lea rdx, [rip + s_nl]
    call codegen_append_cstr
    xor r12, r12
.arg_loop:
    cmp r12, r13
    jae .call_emit
    cmp r12, 4
    jae .arg_stack
    mov rcx, r12
    call codegen_reg_for_param
    mov rcx, rbx
    mov rdx, [rdi + 8 + r12 * 8]
    mov r8, rax
    call codegen_emit_move_to_reg
    inc r12
    jmp .arg_loop
.arg_stack:
    mov rcx, rbx
    mov rdx, [rdi + 8 + r12 * 8]
    lea r8, [rip + s_rax]
    call codegen_emit_move_to_reg
    mov rcx, rbx
    lea rdx, [rip + s_mov_stack_arg]
    call codegen_append_cstr
    mov rax, r12
    sub rax, 4
    imul rax, rax, 8
    add rax, 32
    mov rcx, rbx
    mov rdx, rax
    call codegen_append_int
    mov rcx, rbx
    lea rdx, [rip + s_stack_arg_end]
    call codegen_append_cstr
    inc r12
    jmp .arg_loop
.call_emit:
    mov rcx, rbx
    lea rdx, [rip + s_call]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, [rdi]
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_nl]
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_add_rsp]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, [rsp + 56]
    call codegen_append_int
    mov rcx, rbx
    lea rdx, [rip + s_nl]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, [rsi + INST_RESULT]
    mov r9d, [rsi + INST_TYPE]
    call codegen_store_result
    jmp .inst_done
.load:
    mov rdi, [rsi + INST_OPERANDS]
    mov rcx, rbx
    mov rdx, [rdi]
    lea r8, [rip + s_rax]
    call codegen_emit_move_to_reg
    mov rcx, rbx
    mov rdx, [rsi + INST_RESULT]
    mov r9d, [rsi + INST_TYPE]
    call codegen_store_result
    jmp .inst_done
.store:
    mov rdi, [rsi + INST_OPERANDS]
    mov rcx, rbx
    mov rdx, [rdi]
    lea r8, [rip + s_rax]
    call codegen_emit_move_to_reg
    mov rcx, rbx
    mov rdx, [rdi + 8]
    call codegen_var_location
    test rax, rax
    je .inst_done
    mov r9, rax
    mov rcx, rbx
    lea rdx, [rip + s_mov_store_prefix]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, r9
    call codegen_append_int
    mov rcx, rbx
    lea rdx, [rip + s_store_mid]
    call codegen_append_cstr
    jmp .inst_done
.alloca:
    mov rcx, rbx
    mov rdx, [rsi + INST_RESULT]
    mov r8d, [rsi + INST_TYPE]
    call codegen_assign_location
    jmp .inst_done
.array_new:
    lea r13, [rip + s_array_create]
    jmp .runtime_array_one_arg
.array_get:
    lea r13, [rip + s_array_get]
    jmp .runtime_array_two_args
.array_set:
    lea r13, [rip + s_array_add]
    jmp .runtime_array_two_args
.array_push:
    lea r13, [rip + s_array_add]
    jmp .runtime_array_two_args
.array_len:
    lea r13, [rip + s_array_size]
    jmp .runtime_array_one_arg
.runtime_array_one_arg:
    mov rcx, rbx
    lea rdx, [rip + s_sub_rsp]
    call codegen_append_cstr
    mov rcx, rbx
    mov edx, 32
    call codegen_append_int
    mov rcx, rbx
    lea rdx, [rip + s_nl]
    call codegen_append_cstr
    mov rdi, [rsi + INST_OPERANDS]
    cmp qword ptr [rsi + INST_OPERAND_COUNT], 0
    je .array_default_capacity
    mov rcx, rbx
    mov rdx, [rdi]
    lea r8, [rip + s_rcx]
    call codegen_emit_move_to_reg
    jmp .array_call
.array_default_capacity:
    mov rcx, rbx
    lea rdx, [rip + s_mov_load_prefix]
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_rcx]
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_comma_space]
    call codegen_append_cstr
    mov rcx, rbx
    mov edx, 4
    call codegen_append_int
    mov rcx, rbx
    lea rdx, [rip + s_nl]
    call codegen_append_cstr
    jmp .array_call
.runtime_array_two_args:
    mov rcx, rbx
    lea rdx, [rip + s_sub_rsp]
    call codegen_append_cstr
    mov rcx, rbx
    mov edx, 32
    call codegen_append_int
    mov rcx, rbx
    lea rdx, [rip + s_nl]
    call codegen_append_cstr
    mov rdi, [rsi + INST_OPERANDS]
    mov rcx, rbx
    mov rdx, [rdi]
    lea r8, [rip + s_rcx]
    call codegen_emit_move_to_reg
    mov rcx, rbx
    mov rdx, [rdi + 8]
    lea r8, [rip + s_rdx]
    call codegen_emit_move_to_reg
.array_call:
    cmp dword ptr [rsi + INST_OPCODE], OP_ARRAY_NEW
    jne .array_no_elem_size
    mov rcx, rbx
    lea rdx, [rip + s_mov_load_prefix]
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_rdx]
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_comma_space]
    call codegen_append_cstr
    mov rcx, rbx
    mov edx, 8
    call codegen_append_int
    mov rcx, rbx
    lea rdx, [rip + s_nl]
    call codegen_append_cstr
.array_no_elem_size:
    mov rcx, rbx
    lea rdx, [rip + s_call]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, r13
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_nl]
    call codegen_append_cstr
    mov rcx, rbx
    lea rdx, [rip + s_add_rsp]
    call codegen_append_cstr
    mov rcx, rbx
    mov edx, 32
    call codegen_append_int
    mov rcx, rbx
    lea rdx, [rip + s_nl]
    call codegen_append_cstr
    mov rcx, rbx
    mov rdx, [rsi + INST_RESULT]
    mov r9d, [rsi + INST_TYPE]
    call codegen_store_result
.inst_done:
    add rsp, 64
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret
