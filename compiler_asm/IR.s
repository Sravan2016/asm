.intel_syntax noprefix

.equ TYPE_KIND, 0
.equ TYPE_FILE, 4
.equ TYPE_ELEMENT, 8

.equ SEM_KIND, 0
.equ SEM_FILE, 4
.equ SEM_ELEMENT, 8

.equ INST_OPCODE, 0
.equ INST_TYPE, 8
.equ INST_RESULT, 24
.equ INST_OPERANDS, 56
.equ INST_OPERAND_COUNT, 88
.equ INST_LABEL, 96
.equ INST_STRING, 128
.equ INST_INT, 160
.equ INST_DOUBLE_TEXT, 168
.equ INST_SIZE, 200

.equ BLOCK_NAME, 0
.equ BLOCK_INSTRUCTIONS, 32
.equ BLOCK_COUNT, 40
.equ BLOCK_CAP, 48
.equ BLOCK_SIZE, 56

.equ PARAM_NAME, 0
.equ PARAM_TYPE, 32
.equ PARAM_SIZE, 48

.equ FUNCTION_NAME, 0
.equ FUNCTION_RETURN, 32
.equ FUNCTION_PARAMS, 48
.equ FUNCTION_PARAM_COUNT, 56
.equ FUNCTION_BLOCKS, 64
.equ FUNCTION_BLOCK_COUNT, 72
.equ FUNCTION_BLOCK_CAP, 80
.equ FUNCTION_CURRENT, 88
.equ FUNCTION_SIZE, 96

.equ GLOBAL_NAME, 0
.equ GLOBAL_TYPE, 32
.equ GLOBAL_SIZE, 48

.equ STRING_NAME, 0
.equ STRING_VALUE, 32
.equ STRING_SIZE, 96

.equ MODULE_FUNCTIONS, 0
.equ MODULE_FUNCTION_COUNT, 8
.equ MODULE_FUNCTION_CAP, 16
.equ MODULE_GLOBALS, 24
.equ MODULE_GLOBAL_COUNT, 32
.equ MODULE_GLOBAL_CAP, 40
.equ MODULE_STRINGS, 48
.equ MODULE_STRING_COUNT, 56
.equ MODULE_STRING_CAP, 64
.equ MODULE_EXTERNALS, 72
.equ MODULE_EXTERNAL_COUNT, 80
.equ MODULE_EXTERNAL_CAP, 88

.equ TYPE_VOID, 0
.equ TYPE_INTEGER, 1
.equ TYPE_LONG, 2
.equ TYPE_DOUBLE, 3
.equ TYPE_BOOLEAN, 4
.equ TYPE_POINTER, 5
.equ TYPE_ARRAY, 6
.equ TYPE_STRING, 7

.equ SEM_VOID, 0
.equ SEM_INTEGER, 1
.equ SEM_LONG, 2
.equ SEM_DOUBLE, 3
.equ SEM_BOOLEAN, 4
.equ SEM_STRING, 5
.equ SEM_CLASS, 6
.equ SEM_ARRAY, 7
.equ SEM_UNKNOWN, 8
.equ SEM_ERROR, 9

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
.equ OP_ZEXT, 28
.equ OP_SEXT, 29
.equ OP_ARRAY_NEW, 35
.equ OP_ARRAY_GET, 36
.equ OP_ARRAY_SET, 37
.equ OP_ARRAY_LEN, 38
.equ OP_ARRAY_PUSH, 39
.equ OP_CALL_RUNTIME, 40

.section .rdata
s_void: .asciz "void"
s_i32: .asciz "i32"
s_file_i32: .asciz "file<i32>"
s_i64: .asciz "i64"
s_file_i64: .asciz "file<i64>"
s_f64: .asciz "f64"
s_file_f64: .asciz "file<f64>"
s_bool: .asciz "bool"
s_file_bool: .asciz "file<bool>"
s_ptr: .asciz "ptr"
s_string: .asciz "string"
s_file_string: .asciz "file<string>"
s_array_prefix: .asciz "array<"
s_array_suffix: .asciz ">"
s_array: .asciz "array"
s_unknown: .asciz "unknown"
s_indent: .asciz "    "
s_const_i32: .asciz " = const i32 "
s_const_i64: .asciz " = const i64 "
s_const_f64: .asciz " = const f64 "
s_const_bool: .asciz " = const bool "
s_true: .asciz "true"
s_false: .asciz "false"
s_const_ptr: .asciz " = const ptr "
s_null: .asciz "null"
s_add: .asciz " = add "
s_sub: .asciz " = sub "
s_mul: .asciz " = mul "
s_div: .asciz " = div "
s_mod: .asciz " = mod "
s_neg: .asciz " = neg "
s_eq: .asciz " = eq "
s_ne: .asciz " = ne "
s_lt: .asciz " = lt "
s_le: .asciz " = le "
s_gt: .asciz " = gt "
s_ge: .asciz " = ge "
s_and: .asciz " = and "
s_or: .asciz " = or "
s_not: .asciz " = not "
s_load: .asciz " = load "
s_store: .asciz "store "
s_alloca: .asciz " = alloca "
s_jmp: .asciz "    jmp "
s_br: .asciz "    br "
s_ret: .asciz "    ret"
s_ret_sp: .asciz "    ret "
s_call_eq: .asciz " = call "
s_call: .asciz "    call "
s_call_runtime_eq: .asciz " = call_runtime "
s_call_runtime: .asciz "    call_runtime "
s_array_new: .asciz " = array_new "
s_array_get: .asciz " = array_get "
s_array_set: .asciz "    array_set "
s_array_len: .asciz " = array_len "
s_array_push: .asciz "    array_push "
s_zext: .asciz " = zext "
s_sext: .asciz " = sext "
s_to: .asciz " to "
s_unknown_inst: .asciz "    <unknown>"
s_comma: .asciz ", "
s_colon: .asciz ":"
s_q: .asciz "?"
s_entry: .asciz "entry"
s_global: .asciz "global "
s_func: .asciz "func "
s_lparen: .asciz "("
s_rparen_arrow: .asciz ") -> "
s_open_brace: .asciz " {\n"
s_close_brace: .asciz "}\n\n"
s_param_sep: .asciz ": "
s_nl: .asciz "\n"
s_two_spaces: .asciz "  "

.text
.globl ir_strlen
.def ir_strlen; .scl 2; .type 32; .endef
ir_strlen:
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

.globl ir_streq
.def ir_streq; .scl 2; .type 32; .endef
ir_streq:
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

.globl ir_copy_cstr
.def ir_copy_cstr; .scl 2; .type 32; .endef
ir_copy_cstr:
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

.globl ir_append_cstr
.def ir_append_cstr; .scl 2; .type 32; .endef
ir_append_cstr:
    push rbx
    push rsi
    push rdi
    sub rsp, 32
    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8
    test rbx, rbx
    je .append_done
    test rsi, rsi
    je .append_done
    test rdi, rdi
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
    call ir_copy_cstr
.append_done:
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret

.globl ir_append_int
.def ir_append_int; .scl 2; .type 32; .endef
ir_append_int:
    push rbx
    push rsi
    push rdi
    sub rsp, 80
    mov rbx, rcx
    mov rdi, r8
    mov rax, rdx
    lea rsi, [rsp + 71]
    mov byte ptr [rsi], 0
    xor r9d, r9d
    test rax, rax
    jge .int_abs
    neg rax
    mov r9d, 1
.int_abs:
    mov r10d, 10
.int_loop:
    xor edx, edx
    div r10
    add dl, '0'
    dec rsi
    mov [rsi], dl
    test rax, rax
    jne .int_loop
    test r9d, r9d
    je .int_emit
    dec rsi
    mov byte ptr [rsi], '-'
.int_emit:
    mov rcx, rbx
    mov rdx, rsi
    mov r8, rdi
    call ir_append_cstr
    add rsp, 80
    pop rdi
    pop rsi
    pop rbx
    ret

.globl ir_type_init
.def ir_type_init; .scl 2; .type 32; .endef
ir_type_init:
    test rcx, rcx
    je .ti_done
    mov [rcx + TYPE_KIND], edx
    mov [rcx + TYPE_FILE], r8d
    mov [rcx + TYPE_ELEMENT], r9
.ti_done:
    ret

.globl ir_type_to_string
.def ir_type_to_string; .scl 2; .type 32; .endef
ir_type_to_string:
    push rbx
    push rsi
    push rdi
    sub rsp, 160
    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8
    test rsi, rsi
    je .type_string_done
    test rdi, rdi
    je .type_string_done
    test rbx, rbx
    je .type_unknown
    mov eax, [rbx + TYPE_KIND]
    cmp eax, TYPE_VOID
    je .type_void
    cmp eax, TYPE_INTEGER
    je .type_i32
    cmp eax, TYPE_LONG
    je .type_i64
    cmp eax, TYPE_DOUBLE
    je .type_f64
    cmp eax, TYPE_BOOLEAN
    je .type_bool
    cmp eax, TYPE_POINTER
    je .type_ptr
    cmp eax, TYPE_STRING
    je .type_string
    cmp eax, TYPE_ARRAY
    je .type_array
    jmp .type_unknown
.type_void: lea rdx, [rip + s_void]; jmp .type_copy
.type_i32:
    cmp dword ptr [rbx + TYPE_FILE], 0
    jne .type_file_i32
    lea rdx, [rip + s_i32]; jmp .type_copy
.type_file_i32: lea rdx, [rip + s_file_i32]; jmp .type_copy
.type_i64:
    cmp dword ptr [rbx + TYPE_FILE], 0
    jne .type_file_i64
    lea rdx, [rip + s_i64]; jmp .type_copy
.type_file_i64: lea rdx, [rip + s_file_i64]; jmp .type_copy
.type_f64:
    cmp dword ptr [rbx + TYPE_FILE], 0
    jne .type_file_f64
    lea rdx, [rip + s_f64]; jmp .type_copy
.type_file_f64: lea rdx, [rip + s_file_f64]; jmp .type_copy
.type_bool:
    cmp dword ptr [rbx + TYPE_FILE], 0
    jne .type_file_bool
    lea rdx, [rip + s_bool]; jmp .type_copy
.type_file_bool: lea rdx, [rip + s_file_bool]; jmp .type_copy
.type_ptr: lea rdx, [rip + s_ptr]; jmp .type_copy
.type_string:
    cmp dword ptr [rbx + TYPE_FILE], 0
    jne .type_file_string
    lea rdx, [rip + s_string]; jmp .type_copy
.type_file_string: lea rdx, [rip + s_file_string]; jmp .type_copy
.type_array:
    cmp qword ptr [rbx + TYPE_ELEMENT], 0
    je .type_array_plain
    mov rcx, rsi
    lea rdx, [rip + s_array_prefix]
    mov r8, rdi
    call ir_copy_cstr
    mov rcx, [rbx + TYPE_ELEMENT]
    lea rdx, [rsp + 32]
    mov r8, 128
    call ir_type_to_string
    mov rcx, rsi
    lea rdx, [rsp + 32]
    mov r8, rdi
    call ir_append_cstr
    mov rcx, rsi
    lea rdx, [rip + s_array_suffix]
    mov r8, rdi
    call ir_append_cstr
    jmp .type_string_done
.type_array_plain: lea rdx, [rip + s_array]; jmp .type_copy
.type_unknown: lea rdx, [rip + s_unknown]
.type_copy:
    mov rcx, rsi
    mov r8, rdi
    call ir_copy_cstr
.type_string_done:
    add rsp, 160
    pop rdi
    pop rsi
    pop rbx
    ret

.globl ir_type_size_bytes
.def ir_type_size_bytes; .scl 2; .type 32; .endef
ir_type_size_bytes:
    mov eax, 8
    test rcx, rcx
    je .size_done
    mov edx, [rcx + TYPE_KIND]
    cmp edx, TYPE_VOID
    je .size_void
    cmp edx, TYPE_STRING
    je .size_16
    cmp edx, TYPE_BOOLEAN
    je .size_file_or_8
    cmp edx, TYPE_INTEGER
    je .size_file_or_8
    cmp edx, TYPE_LONG
    je .size_file_or_8
    cmp edx, TYPE_DOUBLE
    je .size_file_or_8
    mov eax, 8
    ret
.size_file_or_8:
    cmp dword ptr [rcx + TYPE_FILE], 0
    jne .size_16
    mov eax, 8
    ret
.size_16:
    mov eax, 16
    ret
.size_void:
    xor eax, eax
.size_done:
    ret

.globl ir_type_is_integer_family
.def ir_type_is_integer_family; .scl 2; .type 32; .endef
ir_type_is_integer_family:
    xor eax, eax
    test rcx, rcx
    je .intfam_done
    mov edx, [rcx + TYPE_KIND]
    cmp edx, TYPE_INTEGER
    je .intfam_yes
    cmp edx, TYPE_LONG
    je .intfam_yes
    cmp edx, TYPE_BOOLEAN
    je .intfam_yes
    ret
.intfam_yes:
    mov eax, 1
.intfam_done:
    ret

.globl ir_type_is_numeric
.def ir_type_is_numeric; .scl 2; .type 32; .endef
ir_type_is_numeric:
    xor eax, eax
    test rcx, rcx
    je .num_done
    mov edx, [rcx + TYPE_KIND]
    cmp edx, TYPE_INTEGER
    je .num_yes
    cmp edx, TYPE_LONG
    je .num_yes
    cmp edx, TYPE_DOUBLE
    je .num_yes
    ret
.num_yes:
    mov eax, 1
.num_done:
    ret

.globl ir_semantic_to_ir_type
.def ir_semantic_to_ir_type; .scl 2; .type 32; .endef
ir_semantic_to_ir_type:
    push rbx
    push rsi
    push rdi
    sub rsp, 32
    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8
    test rbx, rbx
    je .sem_done
    test rsi, rsi
    je .sem_ptr
    mov eax, [rsi + SEM_KIND]
    mov r8d, [rsi + SEM_FILE]
    cmp eax, SEM_VOID
    je .sem_void
    cmp eax, SEM_INTEGER
    je .sem_i32
    cmp eax, SEM_LONG
    je .sem_i64
    cmp eax, SEM_DOUBLE
    je .sem_f64
    cmp eax, SEM_BOOLEAN
    je .sem_bool
    cmp eax, SEM_STRING
    je .sem_string
    cmp eax, SEM_CLASS
    je .sem_ptr_file
    cmp eax, SEM_ARRAY
    je .sem_array
    jmp .sem_ptr
.sem_void: mov edx, TYPE_VOID; xor r8d, r8d; xor r9d, r9d; jmp .sem_set
.sem_i32: mov edx, TYPE_INTEGER; xor r9d, r9d; jmp .sem_set
.sem_i64: mov edx, TYPE_LONG; xor r9d, r9d; jmp .sem_set
.sem_f64: mov edx, TYPE_DOUBLE; xor r9d, r9d; jmp .sem_set
.sem_bool: mov edx, TYPE_BOOLEAN; xor r9d, r9d; jmp .sem_set
.sem_string: mov edx, TYPE_STRING; xor r9d, r9d; jmp .sem_set
.sem_ptr_file: mov edx, TYPE_POINTER; xor r9d, r9d; jmp .sem_set
.sem_ptr: mov edx, TYPE_POINTER; xor r8d, r8d; xor r9d, r9d; jmp .sem_set
.sem_array:
    mov edx, TYPE_ARRAY
    mov r9, rdi
    mov r8d, [rsi + SEM_FILE]
    jmp .sem_set
.sem_set:
    mov rcx, rbx
    call ir_type_init
.sem_done:
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret

.globl ir_instruction_to_string
.def ir_instruction_to_string; .scl 2; .type 32; .endef
ir_instruction_to_string:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    sub rsp, 192
    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8
    test rsi, rsi
    je .inst_done
    test rdi, rdi
    je .inst_done
    mov rcx, rsi
    xor edx, edx
    mov r8, rdi
    call ir_copy_cstr
    test rbx, rbx
    je .inst_unknown
    mov eax, [rbx + INST_OPCODE]
    mov r13d, eax
    cmp eax, OP_LABEL
    je .inst_label
    mov rcx, rsi
    lea rdx, [rip + s_indent]
    mov r8, rdi
    call ir_append_cstr
    mov eax, r13d
    cmp eax, OP_STORE
    je .inst_store
    cmp eax, OP_JMP
    je .inst_jmp
    cmp eax, OP_BRANCH
    je .inst_branch
    cmp eax, OP_RET
    je .inst_ret
    cmp eax, OP_CALL
    je .inst_call
    cmp eax, OP_CALL_RUNTIME
    je .inst_call_runtime
    cmp eax, OP_ARRAY_SET
    je .inst_array_set
    cmp eax, OP_ARRAY_PUSH
    je .inst_array_push
    mov rcx, rsi
    lea rdx, [rbx + INST_RESULT]
    mov r8, rdi
    call ir_append_cstr
    mov eax, r13d
    cmp eax, OP_CONST_INT
    je .inst_const_i32
    cmp eax, OP_CONST_LONG
    je .inst_const_i64
    cmp eax, OP_CONST_DOUBLE
    je .inst_const_f64
    cmp eax, OP_CONST_BOOL
    je .inst_const_bool
    cmp eax, OP_CONST_PTR
    je .inst_const_ptr
    cmp eax, OP_ADD
    je .inst_bin_add
    cmp eax, OP_SUB
    je .inst_bin_sub
    cmp eax, OP_MUL
    je .inst_bin_mul
    cmp eax, OP_DIV
    je .inst_bin_div
    cmp eax, OP_MOD
    je .inst_bin_mod
    cmp eax, OP_NEG
    je .inst_un_neg
    cmp eax, OP_EQ
    je .inst_bin_eq
    cmp eax, OP_NE
    je .inst_bin_ne
    cmp eax, OP_LT
    je .inst_bin_lt
    cmp eax, OP_LE
    je .inst_bin_le
    cmp eax, OP_GT
    je .inst_bin_gt
    cmp eax, OP_GE
    je .inst_bin_ge
    cmp eax, OP_AND
    je .inst_bin_and
    cmp eax, OP_OR
    je .inst_bin_or
    cmp eax, OP_NOT
    je .inst_un_not
    cmp eax, OP_LOAD
    je .inst_load
    cmp eax, OP_ALLOCA
    je .inst_alloca
    cmp eax, OP_ARRAY_NEW
    je .inst_array_new
    cmp eax, OP_ARRAY_GET
    je .inst_array_get
    cmp eax, OP_ARRAY_LEN
    je .inst_array_len
    cmp eax, OP_ZEXT
    je .inst_zext
    cmp eax, OP_SEXT
    je .inst_sext
    jmp .inst_unknown
.inst_const_i32: lea r12, [rip + s_const_i32]; jmp .inst_append_int
.inst_const_i64: lea r12, [rip + s_const_i64]; jmp .inst_append_int
.inst_const_f64:
    lea r12, [rip + s_const_f64]
    call .append_r12
    mov rcx, rsi
    lea rdx, [rbx + INST_DOUBLE_TEXT]
    mov r8, rdi
    call ir_append_cstr
    jmp .inst_done
.inst_const_bool:
    lea r12, [rip + s_const_bool]
    call .append_r12
    mov rcx, rsi
    cmp qword ptr [rbx + INST_INT], 0
    jne .bool_true
    lea rdx, [rip + s_false]
    jmp .bool_copy
.bool_true:
    lea rdx, [rip + s_true]
.bool_copy:
    mov r8, rdi
    call ir_append_cstr
    jmp .inst_done
.inst_const_ptr:
    lea r12, [rip + s_const_ptr]
    call .append_r12
    mov rcx, rsi
    lea rdx, [rbx + INST_STRING]
    test rdx, rdx
    jne .ptr_value
    lea rdx, [rip + s_null]
    jmp .ptr_append
.ptr_value:
    cmp byte ptr [rdx], 0
    jne .ptr_append
    lea rdx, [rip + s_null]
.ptr_append:
    mov r8, rdi
    call ir_append_cstr
    jmp .inst_done
.inst_append_int:
    call .append_r12
    mov rcx, rsi
    mov rdx, [rbx + INST_INT]
    mov r8, rdi
    call ir_append_int
    jmp .inst_done
.inst_bin_add: lea r12, [rip + s_add]; jmp .inst_binary
.inst_bin_sub: lea r12, [rip + s_sub]; jmp .inst_binary
.inst_bin_mul: lea r12, [rip + s_mul]; jmp .inst_binary
.inst_bin_div: lea r12, [rip + s_div]; jmp .inst_binary
.inst_bin_mod: lea r12, [rip + s_mod]; jmp .inst_binary
.inst_bin_eq: lea r12, [rip + s_eq]; jmp .inst_binary
.inst_bin_ne: lea r12, [rip + s_ne]; jmp .inst_binary
.inst_bin_lt: lea r12, [rip + s_lt]; jmp .inst_binary
.inst_bin_le: lea r12, [rip + s_le]; jmp .inst_binary
.inst_bin_gt: lea r12, [rip + s_gt]; jmp .inst_binary
.inst_bin_ge: lea r12, [rip + s_ge]; jmp .inst_binary
.inst_bin_and: lea r12, [rip + s_and]; jmp .inst_binary
.inst_bin_or: lea r12, [rip + s_or]
.inst_binary:
    call .append_r12
    lea r12, [rbx + INST_OPERANDS]
    mov rcx, rsi
    mov rdx, [r12]
    mov r8, rdi
    call ir_append_cstr
    mov rcx, rsi
    lea rdx, [rip + s_comma]
    mov r8, rdi
    call ir_append_cstr
    mov rcx, rsi
    mov rdx, [r12 + 8]
    mov r8, rdi
    call ir_append_cstr
    jmp .inst_done
.inst_un_neg: lea r12, [rip + s_neg]; jmp .inst_unary
.inst_un_not: lea r12, [rip + s_not]
.inst_unary:
    call .append_r12
    lea r12, [rbx + INST_OPERANDS]
    mov rcx, rsi
    mov rdx, [r12]
    mov r8, rdi
    call ir_append_cstr
    jmp .inst_done
.inst_load:
    lea r12, [rip + s_load]
    jmp .inst_unary
.inst_store:
    mov rcx, rsi
    lea rdx, [rip + s_store]
    mov r8, rdi
    call ir_append_cstr
    lea r12, [rbx + INST_OPERANDS]
    mov rcx, rsi
    mov rdx, [r12]
    mov r8, rdi
    call ir_append_cstr
    mov rcx, rsi
    lea rdx, [rip + s_comma]
    mov r8, rdi
    call ir_append_cstr
    mov rcx, rsi
    mov rdx, [r12 + 8]
    mov r8, rdi
    call ir_append_cstr
    jmp .inst_done
.inst_alloca:
    lea r12, [rip + s_alloca]
    call .append_r12
    lea rcx, [rbx + INST_TYPE]
    lea rdx, [rsp + 32]
    mov r8, 128
    call ir_type_to_string
    mov rcx, rsi
    lea rdx, [rsp + 32]
    mov r8, rdi
    call ir_append_cstr
    jmp .inst_done
.inst_label:
    mov rcx, rsi
    lea rdx, [rbx + INST_LABEL]
    mov r8, rdi
    call ir_copy_cstr
    mov rcx, rsi
    lea rdx, [rip + s_colon]
    mov r8, rdi
    call ir_append_cstr
    jmp .inst_done
.inst_jmp:
    mov rcx, rsi
    lea rdx, [rip + s_jmp]
    mov r8, rdi
    call ir_copy_cstr
    mov rcx, rsi
    lea rdx, [rbx + INST_LABEL]
    mov r8, rdi
    call ir_append_cstr
    jmp .inst_done
.inst_branch:
    mov rcx, rsi
    lea rdx, [rip + s_br]
    mov r8, rdi
    call ir_copy_cstr
    lea r12, [rbx + INST_OPERANDS]
    mov rcx, rsi
    mov rdx, [r12]
    mov r8, rdi
    call ir_append_cstr
    mov rcx, rsi
    lea rdx, [rip + s_comma]
    mov r8, rdi
    call ir_append_cstr
    mov rcx, rsi
    cmp qword ptr [rbx + INST_OPERAND_COUNT], 1
    jbe .br_q1
    mov rdx, [r12 + 8]
    jmp .br_append1
.br_q1: lea rdx, [rip + s_q]
.br_append1:
    mov r8, rdi
    call ir_append_cstr
    mov rcx, rsi
    lea rdx, [rip + s_comma]
    mov r8, rdi
    call ir_append_cstr
    mov rcx, rsi
    cmp qword ptr [rbx + INST_OPERAND_COUNT], 2
    jbe .br_q2
    mov rdx, [r12 + 16]
    jmp .br_append2
.br_q2: lea rdx, [rip + s_q]
.br_append2:
    mov r8, rdi
    call ir_append_cstr
    jmp .inst_done
.inst_ret:
    cmp qword ptr [rbx + INST_OPERAND_COUNT], 0
    je .ret_empty
    mov rcx, rsi
    lea rdx, [rip + s_ret_sp]
    mov r8, rdi
    call ir_copy_cstr
    lea r12, [rbx + INST_OPERANDS]
    mov rcx, rsi
    mov rdx, [r12]
    mov r8, rdi
    call ir_append_cstr
    jmp .inst_done
.ret_empty:
    mov rcx, rsi
    lea rdx, [rip + s_ret]
    mov r8, rdi
    call ir_copy_cstr
    jmp .inst_done
.inst_call:
    lea r12, [rip + s_call_eq]
    lea r9, [rip + s_call]
    jmp .inst_call_common
.inst_call_runtime:
    lea r12, [rip + s_call_runtime_eq]
    lea r9, [rip + s_call_runtime]
.inst_call_common:
    cmp byte ptr [rbx + INST_RESULT], 0
    je .call_no_result
    mov rcx, rsi
    lea rdx, [rbx + INST_RESULT]
    mov r8, rdi
    call ir_copy_cstr
    call .append_r12
    jmp .call_func
.call_no_result:
    mov rcx, rsi
    mov rdx, r9
    mov r8, rdi
    call ir_copy_cstr
.call_func:
    lea r12, [rbx + INST_OPERANDS]
    mov rcx, rsi
    cmp qword ptr [rbx + INST_OPERAND_COUNT], 0
    je .call_q
    mov rdx, [r12]
    jmp .call_append_func
.call_q: lea rdx, [rip + s_q]
.call_append_func:
    mov r8, rdi
    call ir_append_cstr
    mov r9, 1
.call_arg_loop:
    cmp r9, [rbx + INST_OPERAND_COUNT]
    jae .inst_done
    mov rcx, rsi
    lea rdx, [rip + s_comma]
    mov r8, rdi
    call ir_append_cstr
    mov rcx, rsi
    mov rdx, [r12 + r9 * 8]
    mov r8, rdi
    call ir_append_cstr
    inc r9
    jmp .call_arg_loop
.inst_array_new:
    lea r12, [rip + s_array_new]
    call .append_r12
    lea rcx, [rbx + INST_TYPE]
    lea rdx, [rsp + 32]
    mov r8, 128
    call ir_type_to_string
    mov rcx, rsi
    lea rdx, [rsp + 32]
    mov r8, rdi
    call ir_append_cstr
    mov rcx, rsi
    lea rdx, [rip + s_comma]
    mov r8, rdi
    call ir_append_cstr
    lea r12, [rbx + INST_OPERANDS]
    mov rcx, rsi
    mov rdx, [r12]
    mov r8, rdi
    call ir_append_cstr
    jmp .inst_done
.inst_array_get: lea r12, [rip + s_array_get]; jmp .inst_binary
.inst_array_set:
    mov rcx, rsi
    lea rdx, [rip + s_array_set]
    mov r8, rdi
    call ir_copy_cstr
    lea r12, [rbx + INST_OPERANDS]
    mov rcx, rsi
    mov rdx, [r12]
    mov r8, rdi
    call ir_append_cstr
    mov rcx, rsi
    lea rdx, [rip + s_comma]
    mov r8, rdi
    call ir_append_cstr
    mov rcx, rsi
    mov rdx, [r12 + 8]
    mov r8, rdi
    call ir_append_cstr
    mov rcx, rsi
    lea rdx, [rip + s_comma]
    mov r8, rdi
    call ir_append_cstr
    mov rcx, rsi
    mov rdx, [r12 + 16]
    mov r8, rdi
    call ir_append_cstr
    jmp .inst_done
.inst_array_len: lea r12, [rip + s_array_len]; jmp .inst_unary
.inst_array_push:
    mov rcx, rsi
    lea rdx, [rip + s_array_push]
    mov r8, rdi
    call ir_copy_cstr
    lea r12, [rbx + INST_OPERANDS]
    mov rcx, rsi
    mov rdx, [r12]
    mov r8, rdi
    call ir_append_cstr
    mov rcx, rsi
    lea rdx, [rip + s_comma]
    mov r8, rdi
    call ir_append_cstr
    mov rcx, rsi
    mov rdx, [r12 + 8]
    mov r8, rdi
    call ir_append_cstr
    jmp .inst_done
.inst_zext: lea r12, [rip + s_zext]; jmp .inst_cast
.inst_sext: lea r12, [rip + s_sext]
.inst_cast:
    call .append_r12
    lea r12, [rbx + INST_OPERANDS]
    mov rcx, rsi
    mov rdx, [r12]
    mov r8, rdi
    call ir_append_cstr
    mov rcx, rsi
    lea rdx, [rip + s_to]
    mov r8, rdi
    call ir_append_cstr
    lea rcx, [rbx + INST_TYPE]
    lea rdx, [rsp + 32]
    mov r8, 128
    call ir_type_to_string
    mov rcx, rsi
    lea rdx, [rsp + 32]
    mov r8, rdi
    call ir_append_cstr
    jmp .inst_done
.inst_unknown:
    mov rcx, rsi
    lea rdx, [rip + s_unknown_inst]
    mov r8, rdi
    call ir_copy_cstr
    jmp .inst_done
.append_r12:
    mov rcx, rsi
    mov rdx, r12
    mov r8, rdi
    call ir_append_cstr
    ret
.inst_done:
    add rsp, 192
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

.globl ir_block_is_terminated
.def ir_block_is_terminated; .scl 2; .type 32; .endef
ir_block_is_terminated:
    xor eax, eax
    test rcx, rcx
    je .term_done
    mov rdx, [rcx + BLOCK_COUNT]
    test rdx, rdx
    je .term_done
    dec rdx
    imul rdx, rdx, INST_SIZE
    add rdx, [rcx + BLOCK_INSTRUCTIONS]
    mov ecx, [rdx + INST_OPCODE]
    cmp ecx, OP_RET
    je .term_yes
    cmp ecx, OP_JMP
    je .term_yes
    cmp ecx, OP_BRANCH
    je .term_yes
    ret
.term_yes:
    mov eax, 1
.term_done:
    ret

.globl ir_block_add_instruction
.def ir_block_add_instruction; .scl 2; .type 32; .endef
ir_block_add_instruction:
    push rbx
    push rsi
    push rdi
    xor eax, eax
    mov rbx, rcx
    mov rsi, rdx
    test rbx, rbx
    je .add_inst_done
    test rsi, rsi
    je .add_inst_done
    mov rax, [rbx + BLOCK_COUNT]
    cmp rax, [rbx + BLOCK_CAP]
    jae .add_inst_full
    mov rdi, [rbx + BLOCK_INSTRUCTIONS]
    imul rdx, rax, INST_SIZE
    add rdi, rdx
    mov rcx, rdi
    mov rdx, rsi
    mov r8, INST_SIZE
    call ir_memcpy
    inc qword ptr [rbx + BLOCK_COUNT]
    mov eax, 1
    jmp .add_inst_done
.add_inst_full:
    xor eax, eax
.add_inst_done:
    pop rdi
    pop rsi
    pop rbx
    ret

.globl ir_memcpy
.def ir_memcpy; .scl 2; .type 32; .endef
ir_memcpy:
    mov rax, rcx
    test rcx, rcx
    je .mem_done
    test rdx, rdx
    je .mem_done
.mem_loop:
    test r8, r8
    je .mem_done
    mov r9b, [rdx]
    mov [rcx], r9b
    inc rcx
    inc rdx
    dec r8
    jmp .mem_loop
.mem_done:
    ret

.globl ir_function_entry_block
.def ir_function_entry_block; .scl 2; .type 32; .endef
ir_function_entry_block:
    push rbx
    sub rsp, 32
    mov rbx, rcx
    test rcx, rcx
    je .entry_null
    cmp qword ptr [rcx + FUNCTION_BLOCK_COUNT], 0
    jne .entry_return
    mov rdx, [rbx + FUNCTION_BLOCKS]
    test rdx, rdx
    je .entry_null
    lea r8, [rip + s_entry]
    mov [rdx + BLOCK_COUNT], qword ptr 0
    mov rcx, rdx
    mov rdx, r8
    mov r8, 32
    call ir_copy_cstr
    mov qword ptr [rbx + FUNCTION_BLOCK_COUNT], 1
    mov qword ptr [rbx + FUNCTION_CURRENT], 0
    mov rax, [rbx + FUNCTION_BLOCKS]
    jmp .entry_out
.entry_return:
    mov rax, [rbx + FUNCTION_BLOCKS]
    jmp .entry_out
.entry_null:
    xor eax, eax
.entry_out:
    add rsp, 32
    pop rbx
    ret

.globl ir_function_add_block
.def ir_function_add_block; .scl 2; .type 32; .endef
ir_function_add_block:
    push rbx
    push rdi
    xor eax, eax
    mov rbx, rcx
    test rbx, rbx
    je .fb_done
    mov rax, [rbx + FUNCTION_BLOCK_COUNT]
    cmp rax, [rbx + FUNCTION_BLOCK_CAP]
    jae .fb_full
    mov rdi, [rbx + FUNCTION_BLOCKS]
    imul rax, rax, BLOCK_SIZE
    add rdi, rax
    mov rcx, rdi
    mov r8, 32
    call ir_copy_cstr
    mov [rdi + BLOCK_COUNT], qword ptr 0
    inc qword ptr [rbx + FUNCTION_BLOCK_COUNT]
    mov rax, rdi
.fb_done:
    pop rdi
    pop rbx
    ret
.fb_full:
    xor eax, eax
    jmp .fb_done

.globl ir_function_find_block
.def ir_function_find_block; .scl 2; .type 32; .endef
ir_function_find_block:
    push rbx
    push rsi
    push rdi
    mov rbx, rcx
    mov rsi, rdx
    xor eax, eax
    test rbx, rbx
    je .findb_done
    mov rdi, [rbx + FUNCTION_BLOCKS]
    mov r9, [rbx + FUNCTION_BLOCK_COUNT]
.findb_loop:
    test r9, r9
    je .findb_done
    mov rcx, rdi
    mov rdx, rsi
    call ir_streq
    test eax, eax
    jne .findb_found
    add rdi, BLOCK_SIZE
    dec r9
    jmp .findb_loop
.findb_found:
    mov rax, rdi
.findb_done:
    pop rdi
    pop rsi
    pop rbx
    ret

.globl ir_function_current_block
.def ir_function_current_block; .scl 2; .type 32; .endef
ir_function_current_block:
    xor eax, eax
    test rcx, rcx
    je .cur_done
    mov rdx, [rcx + FUNCTION_CURRENT]
    cmp rdx, [rcx + FUNCTION_BLOCK_COUNT]
    jae .cur_done
    imul rdx, rdx, BLOCK_SIZE
    mov rax, [rcx + FUNCTION_BLOCKS]
    add rax, rdx
.cur_done:
    ret

.globl ir_function_set_current_block
.def ir_function_set_current_block; .scl 2; .type 32; .endef
ir_function_set_current_block:
    test rcx, rcx
    je .setcur_done
    mov [rcx + FUNCTION_CURRENT], rdx
.setcur_done:
    ret

.globl ir_module_add_function
.def ir_module_add_function; .scl 2; .type 32; .endef
ir_module_add_function:
    push rbx
    push rsi
    push rdi
    sub rsp, 32
    mov rbx, rcx
    mov rsi, r9
    xor eax, eax
    test rbx, rbx
    je .mf_done
    mov rax, [rbx + MODULE_FUNCTION_COUNT]
    cmp rax, [rbx + MODULE_FUNCTION_CAP]
    jae .mf_full
    mov rdi, [rbx + MODULE_FUNCTIONS]
    imul rax, rax, FUNCTION_SIZE
    add rdi, rax
    mov rcx, rdi
    mov r8, 32
    call ir_copy_cstr
    lea rcx, [rdi + FUNCTION_RETURN]
    mov rdx, rsi
    mov r8, 16
    call ir_memcpy
    mov qword ptr [rdi + FUNCTION_PARAM_COUNT], 0
    mov qword ptr [rdi + FUNCTION_BLOCK_COUNT], 0
    mov qword ptr [rdi + FUNCTION_CURRENT], 0
    inc qword ptr [rbx + MODULE_FUNCTION_COUNT]
    mov rax, rdi
.mf_done:
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret
.mf_full:
    xor eax, eax
    jmp .mf_done

.globl ir_module_find_function
.def ir_module_find_function; .scl 2; .type 32; .endef
ir_module_find_function:
    push rbx
    push rsi
    push rdi
    mov rbx, rcx
    mov rsi, rdx
    xor eax, eax
    test rbx, rbx
    je .ff_done
    mov rdi, [rbx + MODULE_FUNCTIONS]
    mov r9, [rbx + MODULE_FUNCTION_COUNT]
.ff_loop:
    test r9, r9
    je .ff_done
    mov rcx, rdi
    mov rdx, rsi
    call ir_streq
    test eax, eax
    jne .ff_found
    add rdi, FUNCTION_SIZE
    dec r9
    jmp .ff_loop
.ff_found:
    mov rax, rdi
.ff_done:
    pop rdi
    pop rsi
    pop rbx
    ret

.globl ir_module_add_global
.def ir_module_add_global; .scl 2; .type 32; .endef
ir_module_add_global:
    push rbx
    push rsi
    push rdi
    push r12
    sub rsp, 32
    mov rbx, rcx
    mov rsi, rdx
    mov r12, r8
    xor eax, eax
    test rbx, rbx
    je .mg_done
    mov rdi, [rbx + MODULE_GLOBALS]
    mov r9, [rbx + MODULE_GLOBAL_COUNT]
.mg_dup_loop:
    test r9, r9
    je .mg_add
    mov rcx, rdi
    mov rdx, rsi
    call ir_streq
    test eax, eax
    jne .mg_exists
    add rdi, GLOBAL_SIZE
    dec r9
    jmp .mg_dup_loop
.mg_add:
    mov rax, [rbx + MODULE_GLOBAL_COUNT]
    cmp rax, [rbx + MODULE_GLOBAL_CAP]
    jae .mg_full
    mov rdi, [rbx + MODULE_GLOBALS]
    imul rax, rax, GLOBAL_SIZE
    add rdi, rax
    mov rcx, rdi
    mov rdx, rsi
    mov r8, 32
    call ir_copy_cstr
    lea rcx, [rdi + GLOBAL_TYPE]
    mov rdx, r12
    mov r8, 16
    call ir_memcpy
    inc qword ptr [rbx + MODULE_GLOBAL_COUNT]
    mov eax, 1
    jmp .mg_done
.mg_exists:
    mov eax, 1
.mg_done:
    add rsp, 32
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret
.mg_full:
    xor eax, eax
    jmp .mg_done

.globl ir_module_add_external_symbol
.def ir_module_add_external_symbol; .scl 2; .type 32; .endef
ir_module_add_external_symbol:
    push rbx
    push rsi
    push rdi
    mov rbx, rcx
    mov rsi, rdx
    xor eax, eax
    test rbx, rbx
    je .ex_done
    mov rdi, [rbx + MODULE_EXTERNALS]
    mov r9, [rbx + MODULE_EXTERNAL_COUNT]
.ex_dup_loop:
    test r9, r9
    je .ex_add
    mov rcx, [rdi]
    mov rdx, rsi
    call ir_streq
    test eax, eax
    jne .ex_exists
    add rdi, 8
    dec r9
    jmp .ex_dup_loop
.ex_add:
    mov rax, [rbx + MODULE_EXTERNAL_COUNT]
    cmp rax, [rbx + MODULE_EXTERNAL_CAP]
    jae .ex_full
    mov rdi, [rbx + MODULE_EXTERNALS]
    mov [rdi + rax * 8], rsi
    inc qword ptr [rbx + MODULE_EXTERNAL_COUNT]
    mov eax, 1
    jmp .ex_done
.ex_exists:
    mov eax, 1
.ex_done:
    pop rdi
    pop rsi
    pop rbx
    ret
.ex_full:
    xor eax, eax
    jmp .ex_done

.globl ir_module_add_string_constant
.def ir_module_add_string_constant; .scl 2; .type 32; .endef
ir_module_add_string_constant:
    push rbx
    push rsi
    push rdi
    sub rsp, 32
    mov rbx, rcx
    mov rsi, r8
    xor eax, eax
    test rbx, rbx
    je .sc_done
    mov rax, [rbx + MODULE_STRING_COUNT]
    cmp rax, [rbx + MODULE_STRING_CAP]
    jae .sc_full
    mov rdi, [rbx + MODULE_STRINGS]
    imul rax, rax, STRING_SIZE
    add rdi, rax
    mov rcx, rdi
    mov r8, 32
    call ir_copy_cstr
    lea rcx, [rdi + STRING_VALUE]
    mov rdx, rsi
    mov r8, 64
    call ir_copy_cstr
    inc qword ptr [rbx + MODULE_STRING_COUNT]
    mov eax, 1
.sc_done:
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret
.sc_full:
    xor eax, eax
    jmp .sc_done

.globl ir_module_dump_to_string
.def ir_module_dump_to_string; .scl 2; .type 32; .endef
ir_module_dump_to_string:
    push rbx
    push rsi
    push rdi
    push r12
    sub rsp, 192
    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8
    test rsi, rsi
    je .dump_done
    xor edx, edx
    mov rcx, rsi
    mov r8, rdi
    call ir_copy_cstr
    test rbx, rbx
    je .dump_done
    mov r12, [rbx + MODULE_GLOBAL_COUNT]
    mov r9, [rbx + MODULE_GLOBALS]
.dump_global_loop:
    test r12, r12
    je .dump_funcs
    mov rcx, rsi
    lea rdx, [rip + s_global]
    mov r8, rdi
    call ir_append_cstr
    mov rcx, rsi
    mov rdx, r9
    mov r8, rdi
    call ir_append_cstr
    mov rcx, rsi
    lea rdx, [rip + s_param_sep]
    mov r8, rdi
    call ir_append_cstr
    lea rcx, [r9 + GLOBAL_TYPE]
    lea rdx, [rsp + 32]
    mov r8, 128
    call ir_type_to_string
    mov rcx, rsi
    lea rdx, [rsp + 32]
    mov r8, rdi
    call ir_append_cstr
    mov rcx, rsi
    lea rdx, [rip + s_nl]
    mov r8, rdi
    call ir_append_cstr
    add r9, GLOBAL_SIZE
    dec r12
    jmp .dump_global_loop
.dump_funcs:
    mov r12, [rbx + MODULE_FUNCTION_COUNT]
    mov r9, [rbx + MODULE_FUNCTIONS]
.dump_func_loop:
    test r12, r12
    je .dump_done
    mov rcx, rsi
    lea rdx, [rip + s_func]
    mov r8, rdi
    call ir_append_cstr
    mov rcx, rsi
    mov rdx, r9
    mov r8, rdi
    call ir_append_cstr
    mov rcx, rsi
    lea rdx, [rip + s_lparen]
    mov r8, rdi
    call ir_append_cstr
    mov rcx, rsi
    lea rdx, [rip + s_rparen_arrow]
    mov r8, rdi
    call ir_append_cstr
    lea rcx, [r9 + FUNCTION_RETURN]
    lea rdx, [rsp + 32]
    mov r8, 128
    call ir_type_to_string
    mov rcx, rsi
    lea rdx, [rsp + 32]
    mov r8, rdi
    call ir_append_cstr
    mov rcx, rsi
    lea rdx, [rip + s_open_brace]
    mov r8, rdi
    call ir_append_cstr
    mov rcx, rsi
    lea rdx, [rip + s_close_brace]
    mov r8, rdi
    call ir_append_cstr
    add r9, FUNCTION_SIZE
    dec r12
    jmp .dump_func_loop
.dump_done:
    add rsp, 192
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret
