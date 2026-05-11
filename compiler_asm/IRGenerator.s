.intel_syntax noprefix

.equ STATE_INSTS, 0
.equ STATE_INST_COUNT, 8
.equ STATE_INST_CAP, 16
.equ STATE_TEMP, 24
.equ STATE_LABEL, 28
.equ STATE_LAMBDA, 32
.equ STATE_SCOPE, 36
.equ STATE_OWNED, 40
.equ STATE_STRINGS, 48
.equ STATE_STRING_COUNT, 56
.equ STATE_STRING_CAP, 64
.equ STATE_SYMBOLS, 72
.equ STATE_SYMBOL_COUNT, 80
.equ STATE_SYMBOL_CAP, 88
.equ STATE_CURRENT_CLASS, 96
.equ STATE_CURRENT_FUNCTION, 128
.equ STATE_FILE_LINE_SLOT, 160

.equ INST_OPCODE, 0
.equ INST_TYPE, 4
.equ INST_RESULT, 8
.equ INST_OP0, 40
.equ INST_OP1, 72
.equ INST_OP2, 104
.equ INST_INT, 136
.equ INST_SIZE, 144

.equ STRING_NAME, 0
.equ STRING_VALUE, 32
.equ STRING_RAW, 96
.equ STRING_SIZE, 104

.equ SYMBOL_NAME, 0
.equ SYMBOL_VALUE, 32
.equ SYMBOL_TYPE, 64
.equ SYMBOL_SIZE, 72

.equ TYPE_KIND, 0
.equ TYPE_FILE, 4
.equ TYPE_ARRAY, 8
.equ TYPE_NAME, 12

.equ EXPR_KIND, 0
.equ EXPR_TYPE, 4
.equ EXPR_TEXT, 20
.equ EXPR_LEFT, 56
.equ EXPR_RIGHT, 64
.equ EXPR_EXTRA, 72
.equ EXPR_INT, 80
.equ EXPR_SIZE, 88

.equ STMT_KIND, 0
.equ STMT_NAME, 8
.equ STMT_TYPE, 40
.equ STMT_EXPR, 56
.equ STMT_BODY, 64
.equ STMT_BODY_COUNT, 72
.equ STMT_SIZE, 80

.equ METHOD_NAME, 0
.equ METHOD_BODY, 32
.equ METHOD_BODY_COUNT, 40
.equ METHOD_SIZE, 48

.equ CLASS_NAME, 0
.equ CLASS_METHODS, 32
.equ CLASS_METHOD_COUNT, 40
.equ CLASS_FIELDS, 48
.equ CLASS_FIELD_COUNT, 56
.equ CLASS_SIZE, 64

.equ PROGRAM_CLASSES, 0
.equ PROGRAM_CLASS_COUNT, 8

.equ TYPE_VOID, 0
.equ TYPE_INTEGER, 1
.equ TYPE_LONG, 2
.equ TYPE_DOUBLE, 3
.equ TYPE_BOOLEAN, 4
.equ TYPE_POINTER, 5
.equ TYPE_ARRAY_KIND, 6
.equ TYPE_STRING, 7

.equ EXPR_IDENTIFIER, 0
.equ EXPR_LITERAL, 1
.equ EXPR_BINARY, 2
.equ EXPR_UNARY, 3
.equ EXPR_ASSIGNMENT, 4
.equ EXPR_CONDITIONAL, 5
.equ EXPR_CALL, 6
.equ EXPR_MEMBER, 7
.equ EXPR_INDEX, 8
.equ EXPR_GROUPING, 9
.equ EXPR_ARRAY_LITERAL, 10
.equ EXPR_LAMBDA, 11

.equ STMT_VARIABLE, 0
.equ STMT_EXPR, 1
.equ STMT_PRINT, 2
.equ STMT_GUARD, 3
.equ STMT_WHILE, 4
.equ STMT_FOREACH, 5
.equ STMT_SWITCH, 6
.equ STMT_RETURN, 7

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
s_empty: .asciz ""
s_fileint_create: .asciz "fileint_create_auto"
s_filelong_create: .asciz "filelong_create_auto"
s_filedouble_create: .asciz "filedouble_create_auto"
s_filebool_create: .asciz "filebool_create_auto"
s_fileint_get: .asciz "fileint_get"
s_filelong_get: .asciz "filelong_get"
s_filedouble_get: .asciz "filedouble_get"
s_filebool_get: .asciz "filebool_get"
s_fileint_set: .asciz "fileint_set"
s_filelong_set: .asciz "filelong_set"
s_filedouble_set: .asciz "filedouble_set"
s_filebool_set: .asciz "filebool_set"
s_map_create: .asciz "map_create"
s_map_put: .asciz "map_put"
s_map_get: .asciz "map_get"
s_map_contains_key: .asciz "map_contains_key"
s_map_remove: .asciz "map_remove"
s_map_size: .asciz "map_size"
s_map_is_empty: .asciz "map_is_empty"
s_map_clear: .asciz "map_clear"
s_map_free: .asciz "map_free"
s_map_to_string: .asciz "map_to_string"
s_file_read_all: .asciz "file_read_all"
s_file_print_lines_count: .asciz "file_print_lines_count"
s_file_line_reader_open: .asciz "file_line_reader_open"
s_file_line_reader_next: .asciz "file_line_reader_next"
s_file_line_reader_close: .asciz "file_line_reader_close"
s_file_line_reader_line_count: .asciz "file_line_reader_line_count"
s_file_count_lines: .asciz "file_count_lines"
s_file_get_line_at: .asciz "file_get_line_at"
s_array_join: .asciz "array_join"
s_array_join_int: .asciz "array_join_int"
s_array_join_long: .asciz "array_join_long"
s_array_join_double: .asciz "array_join_double"
s_array_join_bool: .asciz "array_join_bool"
s_containsKey: .asciz "containsKey"
s_contains_key: .asciz "contains_key"
s_isEmpty: .asciz "isEmpty"
s_is_empty: .asciz "is_empty"
s_create: .asciz "create"
s_put: .asciz "put"
s_get: .asciz "get"
s_remove: .asciz "remove"
s_size: .asciz "size"
s_clear: .asciz "clear"
s_free: .asciz "free"
s_toString: .asciz "toString"
s_read_all: .asciz "read_all"
s_print_lines_count: .asciz "print_lines_count"
s_line_reader_open: .asciz "line_reader_open"
s_line_reader_next: .asciz "line_reader_next"
s_line_reader_close: .asciz "line_reader_close"
s_line_reader_line_count: .asciz "line_reader_line_count"
s_count_lines: .asciz "count_lines"
s_get_line_at: .asciz "get_line_at"
s_tmp_prefix: .asciz "%t"
s_label_prefix: .asciz "L"
s_lambda_prefix: .asciz "lambda_"
s_str_prefix: .asciz "str_"
s_file_line_slot: .asciz "__file_line_slot"
s_this: .asciz "this"
s_unknown: .asciz "unknown"
s_void_suffix: .asciz ""
s_int_suffix: .asciz "_int"
s_long_suffix: .asciz "_long"
s_double_suffix: .asciz "_double"
s_bool_suffix: .asciz "_bool"
s_string_suffix: .asciz "_string"
s_array_suffix: .asciz "_array"
s_string_free: .asciz "string_free"
s_array_free: .asciz "array_free"
s_map_free_runtime: .asciz "map_free"
s_direct: .asciz "direct"
s_load: .asciz "load"
s_address: .asciz "address"

.text
.globl irgen_strlen
.def irgen_strlen; .scl 2; .type 32; .endef
irgen_strlen:
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

.globl irgen_streq
.def irgen_streq; .scl 2; .type 32; .endef
irgen_streq:
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

.globl irgen_copy_cstr
.def irgen_copy_cstr; .scl 2; .type 32; .endef
irgen_copy_cstr:
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

.globl irgen_append_cstr
.def irgen_append_cstr; .scl 2; .type 32; .endef
irgen_append_cstr:
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
    call irgen_copy_cstr
.append_done:
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret

.globl irgen_append_int
.def irgen_append_int; .scl 2; .type 32; .endef
irgen_append_int:
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
    jge .int_loop
    neg rax
    mov r9d, 1
.int_loop:
    xor edx, edx
    mov r10d, 10
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
    call irgen_append_cstr
    add rsp, 80
    pop rdi
    pop rsi
    pop rbx
    ret

.globl irgen_init
.def irgen_init; .scl 2; .type 32; .endef
irgen_init:
    test rcx, rcx
    je .init_done
    mov [rcx + STATE_INSTS], rdx
    mov [rcx + STATE_INST_COUNT], qword ptr 0
    mov [rcx + STATE_INST_CAP], r8
    mov [rcx + STATE_STRINGS], r9
    mov rax, [rsp + 40]
    mov [rcx + STATE_STRING_CAP], rax
    mov rax, [rsp + 48]
    mov [rcx + STATE_SYMBOLS], rax
    mov rax, [rsp + 56]
    mov [rcx + STATE_SYMBOL_CAP], rax
    mov qword ptr [rcx + STATE_STRING_COUNT], 0
    mov qword ptr [rcx + STATE_SYMBOL_COUNT], 0
    mov dword ptr [rcx + STATE_TEMP], 0
    mov dword ptr [rcx + STATE_LABEL], 0
    mov dword ptr [rcx + STATE_LAMBDA], 0
    mov dword ptr [rcx + STATE_SCOPE], 0
    mov dword ptr [rcx + STATE_OWNED], 0
    mov byte ptr [rcx + STATE_CURRENT_CLASS], 0
    mov byte ptr [rcx + STATE_CURRENT_FUNCTION], 0
    mov byte ptr [rcx + STATE_FILE_LINE_SLOT], 0
.init_done:
    ret

.globl irgen_instruction_count
.def irgen_instruction_count; .scl 2; .type 32; .endef
irgen_instruction_count:
    xor eax, eax
    test rcx, rcx
    je .cnt_done
    mov rax, [rcx + STATE_INST_COUNT]
.cnt_done:
    ret

.globl irgen_string_count
.def irgen_string_count; .scl 2; .type 32; .endef
irgen_string_count:
    xor eax, eax
    test rcx, rcx
    je .strcnt_done
    mov rax, [rcx + STATE_STRING_COUNT]
.strcnt_done:
    ret

.globl irgen_decode_string_literal
.def irgen_decode_string_literal; .scl 2; .type 32; .endef
irgen_decode_string_literal:
    push rbx
    push rsi
    push rdi
    mov rsi, rcx
    mov rdi, rdx
    mov rbx, r8
    xor eax, eax
    test rdi, rdi
    je .dec_done
    test rbx, rbx
    je .dec_done
    test rsi, rsi
    jne .dec_skip_quote_check
    mov byte ptr [rdi], 0
    jmp .dec_done
.dec_skip_quote_check:
    cmp byte ptr [rsi], '"'
    jne .dec_loop
    inc rsi
.dec_loop:
    cmp rbx, 1
    jbe .dec_term
    mov al, [rsi]
    test al, al
    je .dec_term
    cmp al, '"'
    je .dec_term
    cmp al, '\\'
    jne .dec_copy
    inc rsi
    mov al, [rsi]
    cmp al, 'n'
    je .dec_newline
    cmp al, 't'
    je .dec_tab
    cmp al, '"'
    je .dec_copy
    cmp al, '\\'
    je .dec_copy
    mov byte ptr [rdi], '\\'
    inc rdi
    dec rbx
    cmp rbx, 1
    jbe .dec_term
    jmp .dec_copy
.dec_newline:
    mov al, 10
    jmp .dec_copy
.dec_tab:
    mov al, 9
.dec_copy:
    mov [rdi], al
    inc rdi
    inc rsi
    dec rbx
    jmp .dec_loop
.dec_term:
    mov byte ptr [rdi], 0
.dec_done:
    pop rdi
    pop rsi
    pop rbx
    ret

.globl irgen_file_create_runtime
.def irgen_file_create_runtime; .scl 2; .type 32; .endef
irgen_file_create_runtime:
    xor eax, eax
    test rcx, rcx
    je .fcr_empty
    cmp dword ptr [rcx + TYPE_FILE], 0
    je .fcr_empty
    mov edx, [rcx + TYPE_KIND]
    cmp edx, TYPE_INTEGER
    je .fcr_i
    cmp edx, TYPE_LONG
    je .fcr_l
    cmp edx, TYPE_DOUBLE
    je .fcr_d
    cmp edx, TYPE_BOOLEAN
    je .fcr_b
.fcr_empty: lea rax, [rip + s_empty]; ret
.fcr_i: lea rax, [rip + s_fileint_create]; ret
.fcr_l: lea rax, [rip + s_filelong_create]; ret
.fcr_d: lea rax, [rip + s_filedouble_create]; ret
.fcr_b: lea rax, [rip + s_filebool_create]; ret

.globl irgen_file_get_runtime
.def irgen_file_get_runtime; .scl 2; .type 32; .endef
irgen_file_get_runtime:
    xor eax, eax
    test rcx, rcx
    je .fgr_empty
    cmp dword ptr [rcx + TYPE_FILE], 0
    je .fgr_empty
    mov edx, [rcx + TYPE_KIND]
    cmp edx, TYPE_INTEGER
    je .fgr_i
    cmp edx, TYPE_LONG
    je .fgr_l
    cmp edx, TYPE_DOUBLE
    je .fgr_d
    cmp edx, TYPE_BOOLEAN
    je .fgr_b
.fgr_empty: lea rax, [rip + s_empty]; ret
.fgr_i: lea rax, [rip + s_fileint_get]; ret
.fgr_l: lea rax, [rip + s_filelong_get]; ret
.fgr_d: lea rax, [rip + s_filedouble_get]; ret
.fgr_b: lea rax, [rip + s_filebool_get]; ret

.globl irgen_file_set_runtime
.def irgen_file_set_runtime; .scl 2; .type 32; .endef
irgen_file_set_runtime:
    xor eax, eax
    test rcx, rcx
    je .fsr_empty
    cmp dword ptr [rcx + TYPE_FILE], 0
    je .fsr_empty
    mov edx, [rcx + TYPE_KIND]
    cmp edx, TYPE_INTEGER
    je .fsr_i
    cmp edx, TYPE_LONG
    je .fsr_l
    cmp edx, TYPE_DOUBLE
    je .fsr_d
    cmp edx, TYPE_BOOLEAN
    je .fsr_b
.fsr_empty: lea rax, [rip + s_empty]; ret
.fsr_i: lea rax, [rip + s_fileint_set]; ret
.fsr_l: lea rax, [rip + s_filelong_set]; ret
.fsr_d: lea rax, [rip + s_filedouble_set]; ret
.fsr_b: lea rax, [rip + s_filebool_set]; ret

.globl irgen_normalize_map_method
.def irgen_normalize_map_method; .scl 2; .type 32; .endef
irgen_normalize_map_method:
    push rbx
    sub rsp, 32
    mov rbx, rcx
    lea rdx, [rip + s_containsKey]
    call irgen_streq
    test eax, eax
    jne .norm_contains
    mov rcx, rbx
    lea rdx, [rip + s_isEmpty]
    call irgen_streq
    test eax, eax
    jne .norm_empty
    mov rax, rbx
    jmp .norm_done
.norm_contains: lea rax, [rip + s_contains_key]; jmp .norm_done
.norm_empty: lea rax, [rip + s_is_empty]
.norm_done:
    add rsp, 32
    pop rbx
    ret

.globl irgen_map_runtime_name
.def irgen_map_runtime_name; .scl 2; .type 32; .endef
irgen_map_runtime_name:
    push rbx
    sub rsp, 32
    call irgen_normalize_map_method
    mov rbx, rax
    mov rcx, rbx
    lea rdx, [rip + s_create]
    call irgen_streq
    test eax, eax
    jne .map_create
    mov rcx, rbx
    lea rdx, [rip + s_put]
    call irgen_streq
    test eax, eax
    jne .map_put
    mov rcx, rbx
    lea rdx, [rip + s_get]
    call irgen_streq
    test eax, eax
    jne .map_get
    mov rcx, rbx
    lea rdx, [rip + s_contains_key]
    call irgen_streq
    test eax, eax
    jne .map_contains
    mov rcx, rbx
    lea rdx, [rip + s_remove]
    call irgen_streq
    test eax, eax
    jne .map_remove
    mov rcx, rbx
    lea rdx, [rip + s_size]
    call irgen_streq
    test eax, eax
    jne .map_size
    mov rcx, rbx
    lea rdx, [rip + s_is_empty]
    call irgen_streq
    test eax, eax
    jne .map_empty
    mov rcx, rbx
    lea rdx, [rip + s_clear]
    call irgen_streq
    test eax, eax
    jne .map_clear
    mov rcx, rbx
    lea rdx, [rip + s_free]
    call irgen_streq
    test eax, eax
    jne .map_free
    mov rcx, rbx
    lea rdx, [rip + s_toString]
    call irgen_streq
    test eax, eax
    jne .map_tostr
    lea rax, [rip + s_empty]
    jmp .map_done
.map_create: lea rax, [rip + s_map_create]; jmp .map_done
.map_put: lea rax, [rip + s_map_put]; jmp .map_done
.map_get: lea rax, [rip + s_map_get]; jmp .map_done
.map_contains: lea rax, [rip + s_map_contains_key]; jmp .map_done
.map_remove: lea rax, [rip + s_map_remove]; jmp .map_done
.map_size: lea rax, [rip + s_map_size]; jmp .map_done
.map_empty: lea rax, [rip + s_map_is_empty]; jmp .map_done
.map_clear: lea rax, [rip + s_map_clear]; jmp .map_done
.map_free: lea rax, [rip + s_map_free]; jmp .map_done
.map_tostr: lea rax, [rip + s_map_to_string]
.map_done:
    add rsp, 32
    pop rbx
    ret

.globl irgen_file_runtime_name
.def irgen_file_runtime_name; .scl 2; .type 32; .endef
irgen_file_runtime_name:
    push rbx
    sub rsp, 32
    mov rbx, rcx
    lea rdx, [rip + s_read_all]
    call irgen_streq
    test eax, eax
    jne .file_read
    mov rcx, rbx
    lea rdx, [rip + s_print_lines_count]
    call irgen_streq
    test eax, eax
    jne .file_plc
    mov rcx, rbx
    lea rdx, [rip + s_line_reader_open]
    call irgen_streq
    test eax, eax
    jne .file_lro
    mov rcx, rbx
    lea rdx, [rip + s_line_reader_next]
    call irgen_streq
    test eax, eax
    jne .file_lrn
    mov rcx, rbx
    lea rdx, [rip + s_line_reader_close]
    call irgen_streq
    test eax, eax
    jne .file_lrc
    mov rcx, rbx
    lea rdx, [rip + s_line_reader_line_count]
    call irgen_streq
    test eax, eax
    jne .file_lrlc
    mov rcx, rbx
    lea rdx, [rip + s_count_lines]
    call irgen_streq
    test eax, eax
    jne .file_cl
    mov rcx, rbx
    lea rdx, [rip + s_get_line_at]
    call irgen_streq
    test eax, eax
    jne .file_gla
    lea rax, [rip + s_empty]
    jmp .file_done
.file_read: lea rax, [rip + s_file_read_all]; jmp .file_done
.file_plc: lea rax, [rip + s_file_print_lines_count]; jmp .file_done
.file_lro: lea rax, [rip + s_file_line_reader_open]; jmp .file_done
.file_lrn: lea rax, [rip + s_file_line_reader_next]; jmp .file_done
.file_lrc: lea rax, [rip + s_file_line_reader_close]; jmp .file_done
.file_lrlc: lea rax, [rip + s_file_line_reader_line_count]; jmp .file_done
.file_cl: lea rax, [rip + s_file_count_lines]; jmp .file_done
.file_gla: lea rax, [rip + s_file_get_line_at]
.file_done:
    add rsp, 32
    pop rbx
    ret

.globl irgen_aleka_json_type_tag
.def irgen_aleka_json_type_tag; .scl 2; .type 32; .endef
irgen_aleka_json_type_tag:
    xor eax, eax
    test rcx, rcx
    je .tag_done
    cmp dword ptr [rcx + TYPE_ARRAY], 0
    jne .tag_done
    mov edx, [rcx + TYPE_KIND]
    cmp edx, TYPE_INTEGER
    je .tag_i
    cmp edx, TYPE_LONG
    je .tag_l
    cmp edx, TYPE_DOUBLE
    je .tag_d
    cmp edx, TYPE_BOOLEAN
    je .tag_b
    cmp edx, TYPE_STRING
    je .tag_s
    ret
.tag_i: mov eax, 1; ret
.tag_l: mov eax, 2; ret
.tag_d: mov eax, 3; ret
.tag_b: mov eax, 4; ret
.tag_s: mov eax, 5
.tag_done:
    ret

.globl irgen_aleka_json_field_descriptor
.def irgen_aleka_json_field_descriptor; .scl 2; .type 32; .endef
irgen_aleka_json_field_descriptor:
    push rbx
    sub rsp, 32
    mov rbx, rcx
    mov rcx, rdx
    call irgen_aleka_json_type_tag
    test eax, eax
    je .desc_done
    shl rbx, 8
    or rax, rbx
.desc_done:
    add rsp, 32
    pop rbx
    ret

.globl irgen_accessor_suffix_for_field_name
.def irgen_accessor_suffix_for_field_name; .scl 2; .type 32; .endef
irgen_accessor_suffix_for_field_name:
    push rbx
    sub rsp, 32
    mov rbx, rdx
    mov r9, rcx
    mov rcx, rdx
    mov rdx, r9
    call irgen_copy_cstr
    test rbx, rbx
    je .suffix_done
    mov al, [rbx]
    cmp al, 'a'
    jb .suffix_done
    cmp al, 'z'
    ja .suffix_done
    sub al, 32
    mov [rbx], al
.suffix_done:
    add rsp, 32
    pop rbx
    ret

.globl irgen_array_join_runtime_name
.def irgen_array_join_runtime_name; .scl 2; .type 32; .endef
irgen_array_join_runtime_name:
    test rcx, rcx
    je .join_default
    cmp dword ptr [rcx + TYPE_KIND], TYPE_ARRAY_KIND
    jne .join_default
    mov edx, [rcx + TYPE_NAME]
    cmp edx, TYPE_INTEGER
    je .join_i
    cmp edx, TYPE_LONG
    je .join_l
    cmp edx, TYPE_DOUBLE
    je .join_d
    cmp edx, TYPE_BOOLEAN
    je .join_b
.join_default: lea rax, [rip + s_array_join]; ret
.join_i: lea rax, [rip + s_array_join_int]; ret
.join_l: lea rax, [rip + s_array_join_long]; ret
.join_d: lea rax, [rip + s_array_join_double]; ret
.join_b: lea rax, [rip + s_array_join_bool]; ret

.globl irgen_type_suffix
.def irgen_type_suffix; .scl 2; .type 32; .endef
irgen_type_suffix:
    test rcx, rcx
    je .suffix_empty
    mov eax, [rcx + TYPE_KIND]
    cmp eax, TYPE_INTEGER
    je .suffix_i
    cmp eax, TYPE_LONG
    je .suffix_l
    cmp eax, TYPE_DOUBLE
    je .suffix_d
    cmp eax, TYPE_BOOLEAN
    je .suffix_b
    cmp eax, TYPE_STRING
    je .suffix_s
    cmp eax, TYPE_ARRAY_KIND
    je .suffix_a
.suffix_empty: lea rax, [rip + s_void_suffix]; ret
.suffix_i: lea rax, [rip + s_int_suffix]; ret
.suffix_l: lea rax, [rip + s_long_suffix]; ret
.suffix_d: lea rax, [rip + s_double_suffix]; ret
.suffix_b: lea rax, [rip + s_bool_suffix]; ret
.suffix_s: lea rax, [rip + s_string_suffix]; ret
.suffix_a: lea rax, [rip + s_array_suffix]; ret

.globl irgen_new_temporary
.def irgen_new_temporary; .scl 2; .type 32; .endef
irgen_new_temporary:
    push rbx
    push rsi
    push rdi
    sub rsp, 32
    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8
    mov rcx, rsi
    lea rdx, [rip + s_tmp_prefix]
    mov r8, rdi
    call irgen_copy_cstr
    test rbx, rbx
    je .temp_zero
    mov edx, [rbx + STATE_TEMP]
    inc dword ptr [rbx + STATE_TEMP]
    jmp .temp_append
.temp_zero:
    xor edx, edx
.temp_append:
    mov rcx, rsi
    mov r8, rdi
    call irgen_append_int
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret

.globl irgen_new_label
.def irgen_new_label; .scl 2; .type 32; .endef
irgen_new_label:
    push rbx
    push rsi
    push rdi
    sub rsp, 32
    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8
    mov rcx, rsi
    lea rdx, [rip + s_label_prefix]
    mov r8, rdi
    call irgen_copy_cstr
    test rbx, rbx
    je .label_zero
    mov edx, [rbx + STATE_LABEL]
    inc dword ptr [rbx + STATE_LABEL]
    jmp .label_append
.label_zero:
    xor edx, edx
.label_append:
    mov rcx, rsi
    mov r8, rdi
    call irgen_append_int
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret

.globl irgen_new_lambda_name
.def irgen_new_lambda_name; .scl 2; .type 32; .endef
irgen_new_lambda_name:
    push rbx
    push rsi
    push rdi
    sub rsp, 32
    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8
    mov rcx, rsi
    lea rdx, [rip + s_lambda_prefix]
    mov r8, rdi
    call irgen_copy_cstr
    test rbx, rbx
    je .lambda_zero
    mov edx, [rbx + STATE_LAMBDA]
    inc dword ptr [rbx + STATE_LAMBDA]
    jmp .lambda_append
.lambda_zero:
    xor edx, edx
.lambda_append:
    mov rcx, rsi
    mov r8, rdi
    call irgen_append_int
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret

.globl irgen_emit
.def irgen_emit; .scl 2; .type 32; .endef
irgen_emit:
    push rbx
    push rsi
    push rdi
    push r12
    sub rsp, 32
    mov rbx, rcx
    mov r12d, edx
    mov rsi, r8
    mov rdi, r9
    xor eax, eax
    test rbx, rbx
    je .emit_done
    mov rax, [rbx + STATE_INST_COUNT]
    cmp rax, [rbx + STATE_INST_CAP]
    jae .emit_full
    mov rcx, [rbx + STATE_INSTS]
    imul rdx, rax, INST_SIZE
    add rcx, rdx
    mov [rcx + INST_OPCODE], r12d
    mov dword ptr [rcx + INST_TYPE], 0
    lea rdx, [rcx + INST_RESULT]
    mov r12, rcx
    mov rcx, rdx
    mov rdx, rsi
    mov r8, 32
    call irgen_copy_cstr
    lea rcx, [r12 + INST_OP0]
    mov rdx, rdi
    mov r8, 32
    call irgen_copy_cstr
    mov rax, [rsp + 96]
    lea rcx, [r12 + INST_OP1]
    mov rdx, rax
    mov r8, 32
    call irgen_copy_cstr
    inc qword ptr [rbx + STATE_INST_COUNT]
    mov eax, 1
    jmp .emit_done
.emit_full:
    xor eax, eax
.emit_done:
    add rsp, 32
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

.globl irgen_push_scope
.def irgen_push_scope; .scl 2; .type 32; .endef
irgen_push_scope:
    test rcx, rcx
    je .push_done
    inc dword ptr [rcx + STATE_SCOPE]
.push_done:
    ret

.globl irgen_pop_scope
.def irgen_pop_scope; .scl 2; .type 32; .endef
irgen_pop_scope:
    test rcx, rcx
    je .pop_done
    cmp dword ptr [rcx + STATE_SCOPE], 0
    je .pop_done
    dec dword ptr [rcx + STATE_SCOPE]
.pop_done:
    ret

.globl irgen_scope_depth
.def irgen_scope_depth; .scl 2; .type 32; .endef
irgen_scope_depth:
    xor eax, eax
    test rcx, rcx
    je .scope_done
    mov eax, [rcx + STATE_SCOPE]
.scope_done:
    ret

.globl irgen_register_owned_value
.def irgen_register_owned_value; .scl 2; .type 32; .endef
irgen_register_owned_value:
    test rcx, rcx
    je .owned_done
    inc dword ptr [rcx + STATE_OWNED]
.owned_done:
    ret

.globl irgen_release_owned_value
.def irgen_release_owned_value; .scl 2; .type 32; .endef
irgen_release_owned_value:
    test rcx, rcx
    je .rel_done
    cmp dword ptr [rcx + STATE_OWNED], 0
    je .rel_done
    dec dword ptr [rcx + STATE_OWNED]
.rel_done:
    ret

.globl irgen_owned_count
.def irgen_owned_count; .scl 2; .type 32; .endef
irgen_owned_count:
    xor eax, eax
    test rcx, rcx
    je .oc_done
    mov eax, [rcx + STATE_OWNED]
.oc_done:
    ret

.globl irgen_transfer_ownership
.def irgen_transfer_ownership; .scl 2; .type 32; .endef
irgen_transfer_ownership:
    ret

.globl irgen_cleanup_info_for_ir_type
.def irgen_cleanup_info_for_ir_type; .scl 2; .type 32; .endef
irgen_cleanup_info_for_ir_type:
    test rcx, rcx
    je .cleanup_empty
    mov eax, [rcx + TYPE_KIND]
    cmp eax, TYPE_STRING
    je .cleanup_string
    cmp eax, TYPE_ARRAY_KIND
    je .cleanup_array
    cmp eax, TYPE_POINTER
    je .cleanup_map
.cleanup_empty: lea rax, [rip + s_empty]; ret
.cleanup_string: lea rax, [rip + s_string_free]; ret
.cleanup_array: lea rax, [rip + s_array_free]; ret
.cleanup_map: lea rax, [rip + s_map_free_runtime]; ret

.globl irgen_emit_cleanup
.def irgen_emit_cleanup; .scl 2; .type 32; .endef
irgen_emit_cleanup:
    mov r9, rdx
    mov edx, OP_CALL_RUNTIME
    mov r8, r9
    jmp irgen_emit

.globl irgen_emit_all_scope_cleanups
.def irgen_emit_all_scope_cleanups; .scl 2; .type 32; .endef
irgen_emit_all_scope_cleanups:
    ret

.globl irgen_assign_owned_value
.def irgen_assign_owned_value; .scl 2; .type 32; .endef
irgen_assign_owned_value:
    mov r9, rdx
    mov edx, OP_STORE
    mov r8, r9
    jmp irgen_emit

.globl irgen_free_owned_storage_before_store
.def irgen_free_owned_storage_before_store; .scl 2; .type 32; .endef
irgen_free_owned_storage_before_store:
    ret

.globl irgen_preserved_owner_for_return
.def irgen_preserved_owner_for_return; .scl 2; .type 32; .endef
irgen_preserved_owner_for_return:
    mov rax, rdx
    ret

.globl irgen_emit_string_constant
.def irgen_emit_string_constant; .scl 2; .type 32; .endef
irgen_emit_string_constant:
    push rbx
    push rsi
    push rdi
    sub rsp, 32
    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8
    test rbx, rbx
    je .esc_fail
    mov rax, [rbx + STATE_STRING_COUNT]
    cmp rax, [rbx + STATE_STRING_CAP]
    jae .esc_fail
    mov rcx, rdi
    lea rdx, [rip + s_str_prefix]
    mov r8, 32
    call irgen_copy_cstr
    mov rdx, [rbx + STATE_STRING_COUNT]
    mov rcx, rdi
    mov r8, 32
    call irgen_append_int
    mov rax, [rbx + STATE_STRINGS]
    mov rdx, [rbx + STATE_STRING_COUNT]
    imul rdx, rdx, STRING_SIZE
    add rax, rdx
    mov rcx, rax
    mov rdx, rdi
    mov r8, 32
    call irgen_copy_cstr
    mov rax, [rbx + STATE_STRINGS]
    mov rdx, [rbx + STATE_STRING_COUNT]
    imul rdx, rdx, STRING_SIZE
    add rax, rdx
    lea rcx, [rax + STRING_VALUE]
    mov rdx, rsi
    mov r8, 64
    call irgen_copy_cstr
    inc qword ptr [rbx + STATE_STRING_COUNT]
    mov rax, rdi
    jmp .esc_done
.esc_fail:
    xor eax, eax
.esc_done:
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret

.globl irgen_ensure_file_line_slot
.def irgen_ensure_file_line_slot; .scl 2; .type 32; .endef
irgen_ensure_file_line_slot:
    test rcx, rcx
    je .slot_null
    lea rax, [rcx + STATE_FILE_LINE_SLOT]
    cmp byte ptr [rax], 0
    jne .slot_done
    push rax
    sub rsp, 32
    mov rcx, rax
    lea rdx, [rip + s_file_line_slot]
    mov r8, 32
    call irgen_copy_cstr
    add rsp, 32
    pop rax
.slot_done:
    ret
.slot_null:
    xor eax, eax
    ret

.globl irgen_load_symbol_value
.def irgen_load_symbol_value; .scl 2; .type 32; .endef
irgen_load_symbol_value:
    mov r9, rdx
    mov edx, OP_LOAD
    mov r8, r9
    call irgen_emit
    mov rax, r9
    ret

.globl irgen_add_successor
.def irgen_add_successor; .scl 2; .type 32; .endef
irgen_add_successor:
    ret

.globl irgen_ir_type_for_typeref
.def irgen_ir_type_for_typeref; .scl 2; .type 32; .endef
irgen_ir_type_for_typeref:
    test rcx, rcx
    je .typeref_done
    test rdx, rdx
    je .typeref_ptr
    mov eax, [rdx + TYPE_KIND]
    mov [rcx + TYPE_KIND], eax
    mov eax, [rdx + TYPE_FILE]
    mov [rcx + TYPE_FILE], eax
    mov eax, [rdx + TYPE_ARRAY]
    mov [rcx + TYPE_ARRAY], eax
    mov eax, [rdx + TYPE_NAME]
    mov [rcx + TYPE_NAME], eax
    ret
.typeref_ptr:
    mov dword ptr [rcx + TYPE_KIND], TYPE_POINTER
    mov dword ptr [rcx + TYPE_FILE], 0
    mov dword ptr [rcx + TYPE_ARRAY], 0
    mov dword ptr [rcx + TYPE_NAME], 0
.typeref_done:
    ret

.globl irgen_get_expr_type
.def irgen_get_expr_type; .scl 2; .type 32; .endef
irgen_get_expr_type:
    test rcx, rcx
    je .gettype_done
    test rdx, rdx
    je .gettype_ptr
    lea rdx, [rdx + EXPR_TYPE]
    jmp irgen_ir_type_for_typeref
.gettype_ptr:
    mov dword ptr [rcx + TYPE_KIND], TYPE_POINTER
.gettype_done:
    ret

.globl irgen_visit_identifier
.def irgen_visit_identifier; .scl 2; .type 32; .endef
irgen_visit_identifier:
    test rdx, rdx
    je .vid_null
    lea rax, [rdx + EXPR_TEXT]
    ret
.vid_null:
    lea rax, [rip + s_empty]
    ret

.globl irgen_visit_literal
.def irgen_visit_literal; .scl 2; .type 32; .endef
irgen_visit_literal:
    push rbx
    push rsi
    push rdi
    push r12
    sub rsp, 32
    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8
    mov r12, r9
    mov rdx, rdi
    mov r8, r12
    mov rcx, rbx
    call irgen_new_temporary
    test rsi, rsi
    je .vl_done
    mov eax, [rsi + EXPR_TYPE + TYPE_KIND]
    mov edx, OP_CONST_PTR
    cmp eax, TYPE_INTEGER
    je .vl_int
    cmp eax, TYPE_LONG
    je .vl_long
    cmp eax, TYPE_BOOLEAN
    je .vl_bool
    cmp eax, TYPE_STRING
    je .vl_emit
    jmp .vl_emit
.vl_int: mov edx, OP_CONST_INT; jmp .vl_emit
.vl_long: mov edx, OP_CONST_LONG; jmp .vl_emit
.vl_bool: mov edx, OP_CONST_BOOL
.vl_emit:
    mov rcx, rbx
    mov r8, rdi
    lea r9, [rsi + EXPR_TEXT]
    call irgen_emit
.vl_done:
    mov rax, rdi
    add rsp, 32
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

.globl irgen_visit_binary
.def irgen_visit_binary; .scl 2; .type 32; .endef
irgen_visit_binary:
    push rbx
    push rsi
    push rdi
    push r12
    sub rsp, 32
    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8
    mov r12, r9
    mov rcx, rbx
    mov rdx, rdi
    mov r8, r12
    call irgen_new_temporary
    mov edx, OP_ADD
    test rsi, rsi
    je .vb_emit
    mov eax, [rsi + EXPR_INT]
    cmp eax, 1
    je .vb_sub
    cmp eax, 2
    je .vb_mul
    cmp eax, 3
    je .vb_div
    cmp eax, 4
    je .vb_eq
    jmp .vb_emit
.vb_sub: mov edx, OP_SUB; jmp .vb_emit
.vb_mul: mov edx, OP_MUL; jmp .vb_emit
.vb_div: mov edx, OP_DIV; jmp .vb_emit
.vb_eq: mov edx, OP_EQ
.vb_emit:
    mov rcx, rbx
    mov r8, rdi
    test rsi, rsi
    je .vb_noop
    mov r9, [rsi + EXPR_LEFT]
    test r9, r9
    je .vb_noop
    lea r9, [r9 + EXPR_TEXT]
    jmp .vb_call
.vb_noop:
    lea r9, [rip + s_empty]
.vb_call:
    call irgen_emit
    mov rax, rdi
    add rsp, 32
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

.globl irgen_visit_unary
.def irgen_visit_unary; .scl 2; .type 32; .endef
irgen_visit_unary:
    mov r10, r8
    push r10
    sub rsp, 32
    mov edx, OP_NEG
    mov r8, r10
    lea r9, [rip + s_empty]
    call irgen_emit
    add rsp, 32
    pop rax
    ret

.globl irgen_visit_postfix
.def irgen_visit_postfix; .scl 2; .type 32; .endef
irgen_visit_postfix:
    jmp irgen_visit_unary

.globl irgen_visit_assignment
.def irgen_visit_assignment; .scl 2; .type 32; .endef
irgen_visit_assignment:
    mov r10, r8
    push r10
    sub rsp, 32
    mov edx, OP_STORE
    mov r8, r10
    lea r9, [rip + s_empty]
    call irgen_emit
    add rsp, 32
    pop rax
    ret

.globl irgen_visit_conditional
.def irgen_visit_conditional; .scl 2; .type 32; .endef
irgen_visit_conditional:
    push r8
    sub rsp, 32
    mov edx, OP_BRANCH
    lea r9, [rip + s_empty]
    call irgen_emit
    add rsp, 32
    pop rax
    ret

.globl irgen_visit_call
.def irgen_visit_call; .scl 2; .type 32; .endef
irgen_visit_call:
    mov r10, r8
    push r10
    sub rsp, 32
    mov edx, OP_CALL
    mov r8, r10
    test rdx, rdx
    lea r9, [rip + s_empty]
    call irgen_emit
    add rsp, 32
    pop rax
    ret

.globl irgen_visit_member
.def irgen_visit_member; .scl 2; .type 32; .endef
irgen_visit_member:
    test rdx, rdx
    je .vm_null
    lea rax, [rdx + EXPR_TEXT]
    ret
.vm_null:
    lea rax, [rip + s_empty]
    ret

.globl irgen_visit_index
.def irgen_visit_index; .scl 2; .type 32; .endef
irgen_visit_index:
    mov r10, r8
    push r10
    sub rsp, 32
    mov edx, OP_ARRAY_GET
    mov r8, r10
    lea r9, [rip + s_empty]
    call irgen_emit
    add rsp, 32
    pop rax
    ret

.globl irgen_visit_grouping
.def irgen_visit_grouping; .scl 2; .type 32; .endef
irgen_visit_grouping:
    jmp irgen_visit_expression

.globl irgen_visit_array_literal
.def irgen_visit_array_literal; .scl 2; .type 32; .endef
irgen_visit_array_literal:
    mov r10, r8
    push r10
    sub rsp, 32
    mov edx, OP_ARRAY_NEW
    mov r8, r10
    lea r9, [rip + s_empty]
    call irgen_emit
    add rsp, 32
    pop rax
    ret

.globl irgen_visit_lambda
.def irgen_visit_lambda; .scl 2; .type 32; .endef
irgen_visit_lambda:
    jmp irgen_new_lambda_name

.globl irgen_visit_expression
.def irgen_visit_expression; .scl 2; .type 32; .endef
irgen_visit_expression:
    test rdx, rdx
    je .ve_null
    mov eax, [rdx + EXPR_KIND]
    cmp eax, EXPR_IDENTIFIER
    je irgen_visit_identifier
    cmp eax, EXPR_LITERAL
    je irgen_visit_literal
    cmp eax, EXPR_BINARY
    je irgen_visit_binary
    cmp eax, EXPR_UNARY
    je irgen_visit_unary
    cmp eax, EXPR_ASSIGNMENT
    je irgen_visit_assignment
    cmp eax, EXPR_CONDITIONAL
    je irgen_visit_conditional
    cmp eax, EXPR_CALL
    je irgen_visit_call
    cmp eax, EXPR_MEMBER
    je irgen_visit_member
    cmp eax, EXPR_INDEX
    je irgen_visit_index
    cmp eax, EXPR_GROUPING
    je irgen_visit_grouping
    cmp eax, EXPR_ARRAY_LITERAL
    je irgen_visit_array_literal
    cmp eax, EXPR_LAMBDA
    je irgen_visit_lambda
.ve_null:
    lea rax, [rip + s_empty]
    ret

.globl irgen_visit_variable_decl
.def irgen_visit_variable_decl; .scl 2; .type 32; .endef
irgen_visit_variable_decl:
    push rbx
    sub rsp, 32
    mov rbx, rdx
    mov edx, OP_ALLOCA
    test rbx, rbx
    je .vvd_empty
    lea r8, [rbx + STMT_NAME]
    jmp .vvd_emit
.vvd_empty:
    lea r8, [rip + s_empty]
.vvd_emit:
    lea r9, [rip + s_empty]
    call irgen_emit
    add rsp, 32
    pop rbx
    ret

.globl irgen_visit_expression_stmt
.def irgen_visit_expression_stmt; .scl 2; .type 32; .endef
irgen_visit_expression_stmt:
    test rdx, rdx
    je .ves_done
    mov rdx, [rdx + STMT_EXPR]
    sub rsp, 40
    lea r8, [rsp + 8]
    mov r9, 32
    call irgen_visit_expression
    add rsp, 40
.ves_done:
    ret

.globl irgen_visit_print_stmt
.def irgen_visit_print_stmt; .scl 2; .type 32; .endef
irgen_visit_print_stmt:
    push rdx
    sub rsp, 32
    mov edx, OP_CALL_RUNTIME
    lea r8, [rip + s_empty]
    lea r9, [rip + s_toString]
    call irgen_emit
    add rsp, 32
    pop rdx
    ret

.globl irgen_visit_return
.def irgen_visit_return; .scl 2; .type 32; .endef
irgen_visit_return:
    sub rsp, 40
    mov edx, OP_RET
    lea r8, [rip + s_empty]
    lea r9, [rip + s_empty]
    call irgen_emit
    add rsp, 40
    ret

.globl irgen_visit_guard_block
.def irgen_visit_guard_block; .scl 2; .type 32; .endef
irgen_visit_guard_block:
    sub rsp, 40
    mov edx, OP_BRANCH
    lea r8, [rip + s_empty]
    lea r9, [rip + s_empty]
    call irgen_emit
    add rsp, 40
    ret

.globl irgen_visit_while_block
.def irgen_visit_while_block; .scl 2; .type 32; .endef
irgen_visit_while_block:
    jmp irgen_visit_guard_block

.globl irgen_visit_for_each
.def irgen_visit_for_each; .scl 2; .type 32; .endef
irgen_visit_for_each:
    sub rsp, 40
    mov edx, OP_ARRAY_LEN
    lea r8, [rip + s_empty]
    lea r9, [rip + s_empty]
    call irgen_emit
    add rsp, 40
    ret

.globl irgen_visit_switch
.def irgen_visit_switch; .scl 2; .type 32; .endef
irgen_visit_switch:
    jmp irgen_visit_guard_block

.globl irgen_visit_statement
.def irgen_visit_statement; .scl 2; .type 32; .endef
irgen_visit_statement:
    test rdx, rdx
    je .vs_done
    mov eax, [rdx + STMT_KIND]
    cmp eax, STMT_VARIABLE
    je irgen_visit_variable_decl
    cmp eax, STMT_EXPR
    je irgen_visit_expression_stmt
    cmp eax, STMT_PRINT
    je irgen_visit_print_stmt
    cmp eax, STMT_GUARD
    je irgen_visit_guard_block
    cmp eax, STMT_WHILE
    je irgen_visit_while_block
    cmp eax, STMT_FOREACH
    je irgen_visit_for_each
    cmp eax, STMT_SWITCH
    je irgen_visit_switch
    cmp eax, STMT_RETURN
    je irgen_visit_return
.vs_done:
    ret

.globl irgen_visit_statement_sequence
.def irgen_visit_statement_sequence; .scl 2; .type 32; .endef
irgen_visit_statement_sequence:
    push rbx
    push rsi
    push rdi
    sub rsp, 32
    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8
.seq_loop:
    test rsi, rsi
    je .seq_done
    test rdi, rdi
    je .seq_done
    push rsi
    push rdi
    sub rsp, 32
    mov rcx, rbx
    mov rdx, rsi
    call irgen_visit_statement
    add rsp, 32
    pop rdi
    pop rsi
    add rsi, STMT_SIZE
    dec rdi
    jmp .seq_loop
.seq_done:
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret

.globl irgen_visit_method
.def irgen_visit_method; .scl 2; .type 32; .endef
irgen_visit_method:
    push rbx
    push rsi
    sub rsp, 32
    mov rsi, rcx
    mov rbx, rdx
    test rcx, rcx
    je .method_done
    test rbx, rbx
    je .method_done
    lea rdx, [rbx + METHOD_NAME]
    lea rcx, [rsi + STATE_CURRENT_FUNCTION]
    mov r8, 32
    call irgen_copy_cstr
    mov rcx, rsi
    mov rdx, [rbx + METHOD_BODY]
    mov r8, [rbx + METHOD_BODY_COUNT]
    call irgen_visit_statement_sequence
.method_done:
    add rsp, 32
    pop rsi
    pop rbx
    ret

.globl irgen_visit_synthetic_aleka_accessor
.def irgen_visit_synthetic_aleka_accessor; .scl 2; .type 32; .endef
irgen_visit_synthetic_aleka_accessor:
    sub rsp, 40
    mov edx, OP_CALL_RUNTIME
    lea r8, [rip + s_empty]
    lea r9, [rip + s_get]
    call irgen_emit
    add rsp, 40
    ret

.globl irgen_visit_synthetic_aleka_factory
.def irgen_visit_synthetic_aleka_factory; .scl 2; .type 32; .endef
irgen_visit_synthetic_aleka_factory:
    sub rsp, 40
    mov edx, OP_CALL_RUNTIME
    lea r8, [rip + s_empty]
    lea r9, [rip + s_create]
    call irgen_emit
    add rsp, 40
    ret

.globl irgen_visit_synthetic_aleka_to_string
.def irgen_visit_synthetic_aleka_to_string; .scl 2; .type 32; .endef
irgen_visit_synthetic_aleka_to_string:
    sub rsp, 40
    mov edx, OP_CALL_RUNTIME
    lea r8, [rip + s_empty]
    lea r9, [rip + s_toString]
    call irgen_emit
    add rsp, 40
    ret

.globl irgen_visit_synthetic_aleka_to_object
.def irgen_visit_synthetic_aleka_to_object; .scl 2; .type 32; .endef
irgen_visit_synthetic_aleka_to_object:
    sub rsp, 40
    mov edx, OP_CALL_RUNTIME
    lea r8, [rip + s_empty]
    lea r9, [rip + s_put]
    call irgen_emit
    add rsp, 40
    ret

.globl irgen_visit_class
.def irgen_visit_class; .scl 2; .type 32; .endef
irgen_visit_class:
    push rbx
    push rsi
    push rdi
    sub rsp, 32
    mov rbx, rcx
    mov rsi, rdx
    test rbx, rbx
    je .class_done
    test rsi, rsi
    je .class_done
    lea rcx, [rbx + STATE_CURRENT_CLASS]
    lea rdx, [rsi + CLASS_NAME]
    mov r8, 32
    call irgen_copy_cstr
    mov rdi, [rsi + CLASS_METHODS]
    cmp qword ptr [rsi + CLASS_METHOD_COUNT], 0
    je .class_done
    test rdi, rdi
    je .class_done
    lea rcx, [rbx + STATE_CURRENT_FUNCTION]
    lea rdx, [rdi + METHOD_NAME]
    mov r8, 32
    call irgen_copy_cstr
    mov rcx, rbx
    mov edx, OP_ALLOCA
    lea r8, [rip + s_this]
    lea r9, [rip + s_empty]
    call irgen_emit
    mov rcx, rbx
    mov edx, OP_CALL_RUNTIME
    lea r8, [rip + s_empty]
    lea r9, [rip + s_toString]
    call irgen_emit
    mov rcx, rbx
    mov edx, OP_RET
    lea r8, [rip + s_empty]
    lea r9, [rip + s_empty]
    call irgen_emit
.class_done:
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret

.globl irgen_generate
.def irgen_generate; .scl 2; .type 32; .endef
irgen_generate:
    push rbx
    push rsi
    push rdi
    sub rsp, 32
    mov rbx, rcx
    mov rsi, rdx
    test rbx, rbx
    je .gen_done
    mov qword ptr [rbx + STATE_INST_COUNT], 0
    mov qword ptr [rbx + STATE_STRING_COUNT], 0
    mov dword ptr [rbx + STATE_TEMP], 0
    mov dword ptr [rbx + STATE_LABEL], 0
    test rsi, rsi
    je .gen_done
    mov rdi, [rsi + PROGRAM_CLASSES]
    mov r9, [rsi + PROGRAM_CLASS_COUNT]
.gen_loop:
    test rdi, rdi
    je .gen_done
    test r9, r9
    je .gen_done
    push rdi
    push r9
    sub rsp, 32
    mov rcx, rbx
    mov rdx, rdi
    call irgen_visit_class
    add rsp, 32
    pop r9
    pop rdi
    add rdi, CLASS_SIZE
    dec r9
    jmp .gen_loop
.gen_done:
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret
