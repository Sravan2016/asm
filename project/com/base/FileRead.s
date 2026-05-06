section .data
    str_0_data db 10, 0
    str_0 dq str_0_data, 1

section .bss
    ; Global uninitialized variables (if any)

section .text
    extern print_cstr
    extern print_string
    extern print_uint
    extern string_equals
    extern string_concat
    extern string_copy
    extern string_free
    extern string_from_cstr
    extern string_length
    extern string_equals_icase
    extern string_contains_sub
    extern string_char_at
    extern string_trim
    extern string_split
    extern fromInteger
    extern fromLong
    extern fromDouble
    extern int_add
    extern int_sub
    extern int_mul
    extern int_div
    extern int_mod
    extern int_eq
    extern int_lt
    extern int_gt
    extern fileint_create_auto
    extern fileint_get
    extern fileint_set
    extern fileint_free
    extern long_add
    extern long_sub
    extern long_mul
    extern long_div
    extern long_mod
    extern long_eq
    extern long_lt
    extern long_gt
    extern filelong_create_auto
    extern filelong_get
    extern filelong_set
    extern filelong_free
    extern bool_and
    extern bool_or
    extern bool_not
    extern bool_eq
    extern filebool_create_auto
    extern filebool_get
    extern filebool_set
    extern filebool_free
    extern filedouble_create_auto
    extern filedouble_get
    extern filedouble_set
    extern filedouble_free
    extern filestring_create_auto_from_cstr
    extern filestring_open
    extern filestring_length
    extern filestring_char_at
    extern filestring_replace_char_at
    extern filestring_free
    extern array_create
    extern array_add
    extern array_get
    extern array_size
    extern array_remove
    extern array_free
    extern array_sort
    extern array_filter
    extern array_map
    extern array_join
    extern array_join_int
    extern array_join_long
    extern array_join_double
    extern array_join_bool
    extern map_init
    extern map_create
    extern map_put
    extern map_get
    extern map_contains_key
    extern map_remove
    extern map_size
    extern map_is_empty
    extern map_clear
    extern map_free
    extern map_to_string
    extern file_read_all
    extern file_print_lines_count
    extern file_line_reader_open
    extern file_line_reader_open_string
    extern file_line_reader_next
    extern file_line_reader_close
    extern file_line_reader_line_count
    extern file_count_lines
    extern file_get_line_at
    extern thread_init
    extern thread_run
    extern thread_join
    extern runtime_init
    extern file_line_reader_open_string
    extern file_line_reader_next
    extern print_string
    extern string_free

    global FileRead_readFile

FileRead_readFile:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 232  ; local variables + shadow space
    mov [rbp-88], rcx  ; param 'this'
    mov [rbp-96], rdx  ; param 'path'
    lea rcx, [rel str_0]
    lea rdx, [rel str_0_data]
    call string_from_cstr
FileRead_readFile_entry:
    mov rax, [rbp-88]
    mov [rbp-104], rax
    mov rax, [rbp-96]
    mov [rbp-120], rax
    mov rax, [rbp-120]
    mov [rbp-136], rax
    xor rax, rax
    mov [rbp-144], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-136]
    call file_line_reader_open_string
    add rsp, 32  ; clean shadow space
    mov rax, [rbp-144]
    mov [rbp-128], rax
    jmp FileRead_readFile_L0
FileRead_readFile_L0:
    mov rax, [rbp-128]
    mov [rbp-152], rax
    sub rsp, 32  ; shadow space
    lea rcx, [rbp-168]
    call file_line_reader_next
    add rsp, 32  ; clean shadow space
    mov [rbp-176], rax
    mov rax, [rbp-176]
    test rax, rax
    jne FileRead_readFile_L1
    jmp FileRead_readFile_L2
FileRead_readFile_L1:
    mov rax, [rbp-128]
    mov [rbp-200], rax
    lea rax, [rbp-168]
    mov [rbp-192], rax
    mov rax, [rbp-192]
    mov [rbp-208], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-208]
    call print_string
    add rsp, 32  ; clean shadow space
    lea rax, [rel str_0]
    mov [rbp-216], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-216]
    call print_string
    add rsp, 32  ; clean shadow space
    mov rax, [rbp-192]
    mov [rbp-224], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-224]
    call string_free
    add rsp, 32  ; clean shadow space
    jmp FileRead_readFile_L0
FileRead_readFile_L2:
    xor rax, rax  ; default return 0
    add rsp, 232  ; clean stack frame
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret

