section .data
    str_0_data db 107, 101, 121, 49, 0
    str_0 dq str_0_data, 4
    str_1_data db 118, 97, 108, 117, 101, 49, 0
    str_1 dq str_1_data, 6
    str_2_data db 107, 101, 121, 50, 0
    str_2 dq str_2_data, 4
    str_3_data db 118, 97, 108, 117, 101, 50, 0
    str_3 dq str_3_data, 6
    str_4_data db 107, 101, 121, 51, 0
    str_4 dq str_4_data, 4
    str_5_data db 118, 97, 108, 117, 101, 51, 0
    str_5 dq str_5_data, 6
    str_6_data db 107, 101, 121, 51, 0
    str_6 dq str_6_data, 4
    str_7_data db 107, 101, 121, 51, 0
    str_7 dq str_7_data, 4
    str_8_data db 107, 101, 121, 49, 0
    str_8 dq str_8_data, 4
    str_9_data db 10, 0
    str_9 dq str_9_data, 1
    str_10_data db 10, 0
    str_10 dq str_10_data, 1

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
    extern map_create
    extern map_put
    extern map_get
    extern map_contains_key
    extern map_remove
    extern map_size
    extern map_is_empty
    extern map_to_string
    extern print_string
    extern map_clear
    extern string_free
    extern map_free

    global Map_mapFunctions

Map_mapFunctions:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 392  ; local variables + shadow space
    mov [rbp-88], rcx  ; param 'this'
    lea rcx, [rel str_0]
    lea rdx, [rel str_0_data]
    call string_from_cstr
    lea rcx, [rel str_1]
    lea rdx, [rel str_1_data]
    call string_from_cstr
    lea rcx, [rel str_2]
    lea rdx, [rel str_2_data]
    call string_from_cstr
    lea rcx, [rel str_3]
    lea rdx, [rel str_3_data]
    call string_from_cstr
    lea rcx, [rel str_4]
    lea rdx, [rel str_4_data]
    call string_from_cstr
    lea rcx, [rel str_5]
    lea rdx, [rel str_5_data]
    call string_from_cstr
    lea rcx, [rel str_6]
    lea rdx, [rel str_6_data]
    call string_from_cstr
    lea rcx, [rel str_7]
    lea rdx, [rel str_7_data]
    call string_from_cstr
    lea rcx, [rel str_8]
    lea rdx, [rel str_8_data]
    call string_from_cstr
    lea rcx, [rel str_9]
    lea rdx, [rel str_9_data]
    call string_from_cstr
    lea rcx, [rel str_10]
    lea rdx, [rel str_10_data]
    call string_from_cstr
Map_mapFunctions_entry:
    mov rax, [rbp-88]
    mov [rbp-96], rax
    lea rax, [rel str_0]
    mov [rbp-112], rax
    lea rax, [rel str_1]
    mov [rbp-120], rax
    lea rax, [rel str_2]
    mov [rbp-128], rax
    lea rax, [rel str_3]
    mov [rbp-136], rax
    mov rax, 2
    mov [rbp-144], rax
    xor rax, rax
    mov [rbp-152], rax
    xor rax, rax
    mov [rbp-160], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-144]
    mov rdx, [rbp-152]
    mov r8, [rbp-160]
    call map_create
    add rsp, 32  ; clean shadow space
    mov [rbp-168], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-168]
    mov rdx, [rbp-112]
    mov r8, [rbp-120]
    call map_put
    add rsp, 32  ; clean shadow space
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-168]
    mov rdx, [rbp-128]
    mov r8, [rbp-136]
    call map_put
    add rsp, 32  ; clean shadow space
    mov rax, [rbp-168]
    mov [rbp-104], rax
    mov rax, [rbp-104]
    mov [rbp-176], rax
    lea rax, [rel str_4]
    mov [rbp-184], rax
    lea rax, [rel str_5]
    mov [rbp-192], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-176]
    mov rdx, [rbp-184]
    mov r8, [rbp-192]
    call map_put
    add rsp, 32  ; clean shadow space
    mov [rbp-200], rax
    mov rax, [rbp-104]
    mov [rbp-208], rax
    lea rax, [rel str_6]
    mov [rbp-216], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-208]
    mov rdx, [rbp-216]
    call map_get
    add rsp, 32  ; clean shadow space
    mov [rbp-224], rax
    mov rax, [rbp-104]
    mov [rbp-232], rax
    lea rax, [rel str_7]
    mov [rbp-240], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-232]
    mov rdx, [rbp-240]
    call map_contains_key
    add rsp, 32  ; clean shadow space
    mov [rbp-248], rax
    mov rax, [rbp-104]
    mov [rbp-256], rax
    lea rax, [rel str_8]
    mov [rbp-264], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-256]
    mov rdx, [rbp-264]
    call map_remove
    add rsp, 32  ; clean shadow space
    mov [rbp-272], rax
    mov rax, [rbp-104]
    mov [rbp-280], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-280]
    call map_size
    add rsp, 32  ; clean shadow space
    mov [rbp-288], rax
    mov rax, [rbp-104]
    mov [rbp-296], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-296]
    call map_is_empty
    add rsp, 32  ; clean shadow space
    mov [rbp-304], rax
    mov rax, [rbp-104]
    mov [rbp-312], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-312]
    lea rdx, [rbp-328]
    call map_to_string
    add rsp, 32  ; clean shadow space
    sub rsp, 32  ; shadow space
    lea rcx, [rbp-328]
    call print_string
    add rsp, 32  ; clean shadow space
    lea rax, [rel str_9]
    mov [rbp-336], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-336]
    call print_string
    add rsp, 32  ; clean shadow space
    mov rax, [rbp-104]
    mov [rbp-344], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-344]
    call map_clear
    add rsp, 32  ; clean shadow space
    mov [rbp-352], rax
    mov rax, [rbp-104]
    mov [rbp-360], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-360]
    lea rdx, [rbp-376]
    call map_to_string
    add rsp, 32  ; clean shadow space
    sub rsp, 32  ; shadow space
    lea rcx, [rbp-376]
    call print_string
    add rsp, 32  ; clean shadow space
    lea rax, [rel str_10]
    mov [rbp-384], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-384]
    call print_string
    add rsp, 32  ; clean shadow space
    sub rsp, 32  ; shadow space
    lea rcx, [rbp-376]
    call string_free
    add rsp, 32  ; clean shadow space
    sub rsp, 32  ; shadow space
    lea rcx, [rbp-328]
    call string_free
    add rsp, 32  ; clean shadow space
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-168]
    call map_free
    add rsp, 32  ; clean shadow space
    xor rax, rax
    add rsp, 0  ; clean stack frame
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret

