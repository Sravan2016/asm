section .data
    str_0_data db 72, 105, 0
    str_0 dq str_0_data, 2
    str_1_data db 66, 121, 101, 0
    str_1 dq str_1_data, 3
    str_2_data db 72, 101, 121, 0
    str_2 dq str_2_data, 3
    str_3_data db 83, 97, 100, 0
    str_3 dq str_3_data, 3
    str_4_data db 72, 105, 0
    str_4 dq str_4_data, 2
    str_5_data db 110, 106, 0
    str_5 dq str_5_data, 2
    str_6_data db 72, 105, 0
    str_6 dq str_6_data, 2
    str_7_data db 72, 105, 0
    str_7 dq str_7_data, 2
    str_8_data db 44, 0
    str_8 dq str_8_data, 1
    str_9_data db 10, 0
    str_9 dq str_9_data, 1
    str_10_data db 44, 0
    str_10 dq str_10_data, 1
    str_11_data db 10, 0
    str_11 dq str_11_data, 1
    str_12_data db 44, 0
    str_12 dq str_12_data, 1
    str_13_data db 10, 0
    str_13 dq str_13_data, 1
    str_14_data db 44, 0
    str_14 dq str_14_data, 1
    str_15_data db 10, 0
    str_15 dq str_15_data, 1
    str_16_data db 104, 105, 0
    str_16 dq str_16_data, 2
    str_17_data db 46, 47, 65, 114, 114, 97, 121, 83, 97, 109, 112, 108, 101, 46, 98, 97, 100, 97, 0
    str_17 dq str_17_data, 18

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
    extern array_create
    extern array_remove
    extern array_join
    extern print_string
    extern array_join_int
    extern array_join_long
    extern array_join_double
    extern Map_mapFunctions
    extern FileRead_readFile
    extern string_free
    extern array_free

    global ArraySample_createArray
    global __lambda_0
    global __lambda_1
    global __lambda_2
    global __lambda_3
    global __lambda_4
    global __lambda_5
    global __lambda_6
    global __lambda_7

ArraySample_createArray:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 1608  ; local variables + shadow space
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
    lea rcx, [rel str_11]
    lea rdx, [rel str_11_data]
    call string_from_cstr
    lea rcx, [rel str_12]
    lea rdx, [rel str_12_data]
    call string_from_cstr
    lea rcx, [rel str_13]
    lea rdx, [rel str_13_data]
    call string_from_cstr
    lea rcx, [rel str_14]
    lea rdx, [rel str_14_data]
    call string_from_cstr
    lea rcx, [rel str_15]
    lea rdx, [rel str_15_data]
    call string_from_cstr
    lea rcx, [rel str_16]
    lea rdx, [rel str_16_data]
    call string_from_cstr
    lea rcx, [rel str_17]
    lea rdx, [rel str_17_data]
    call string_from_cstr
ArraySample_createArray_entry:
    mov rax, [rbp-88]
    mov [rbp-96], rax
    mov rax, 4
    mov [rbp-112], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-112]
    mov rdx, 8  ; element size
    call array_create
    add rsp, 32  ; clean shadow space
    mov [rbp-120], rax
    mov rax, 0
    mov [rbp-128], rax
    mov rax, 10
    mov [rbp-136], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-120]
    mov rax, [rbp-136]
    mov [rbp-144], rax
    lea rdx, [rbp-144]
    call array_add
    add rsp, 32  ; clean shadow space
    mov rax, 1
    mov [rbp-144], rax
    mov rax, 20
    mov [rbp-152], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-120]
    mov rax, [rbp-152]
    mov [rbp-160], rax
    lea rdx, [rbp-160]
    call array_add
    add rsp, 32  ; clean shadow space
    mov rax, 2
    mov [rbp-160], rax
    mov rax, 30
    mov [rbp-168], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-120]
    mov rax, [rbp-168]
    mov [rbp-176], rax
    lea rdx, [rbp-176]
    call array_add
    add rsp, 32  ; clean shadow space
    mov rax, 3
    mov [rbp-176], rax
    mov rax, 40
    mov [rbp-184], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-120]
    mov rax, [rbp-184]
    mov [rbp-192], rax
    lea rdx, [rbp-192]
    call array_add
    add rsp, 32  ; clean shadow space
    mov rax, [rbp-120]
    mov [rbp-104], rax
    mov rax, 4
    mov [rbp-208], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-208]
    mov rdx, 8  ; element size
    call array_create
    add rsp, 32  ; clean shadow space
    mov [rbp-216], rax
    mov rax, 0
    mov [rbp-224], rax
    lea rax, [rel str_0]
    mov [rbp-232], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-216]
    mov rax, [rbp-232]
    mov [rbp-240], rax
    lea rdx, [rbp-240]
    call array_add
    add rsp, 32  ; clean shadow space
    mov rax, 1
    mov [rbp-240], rax
    lea rax, [rel str_1]
    mov [rbp-248], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-216]
    mov rax, [rbp-248]
    mov [rbp-256], rax
    lea rdx, [rbp-256]
    call array_add
    add rsp, 32  ; clean shadow space
    mov rax, 2
    mov [rbp-256], rax
    lea rax, [rel str_2]
    mov [rbp-264], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-216]
    mov rax, [rbp-264]
    mov [rbp-272], rax
    lea rdx, [rbp-272]
    call array_add
    add rsp, 32  ; clean shadow space
    mov rax, 3
    mov [rbp-272], rax
    lea rax, [rel str_3]
    mov [rbp-280], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-216]
    mov rax, [rbp-280]
    mov [rbp-288], rax
    lea rdx, [rbp-288]
    call array_add
    add rsp, 32  ; clean shadow space
    mov rax, [rbp-216]
    mov [rbp-200], rax
    mov rax, 5
    mov [rbp-296], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-296]
    mov rdx, 8  ; element size
    call array_create
    add rsp, 32  ; clean shadow space
    mov [rbp-304], rax
    mov rax, 0
    mov [rbp-312], rax
    mov rax, 0
    mov [rbp-320], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-304]
    mov rax, [rbp-320]
    mov [rbp-328], rax
    lea rdx, [rbp-328]
    call array_add
    add rsp, 32  ; clean shadow space
    mov rax, 1
    mov [rbp-328], rax
    mov rax, 1
    mov [rbp-336], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-304]
    mov rax, [rbp-336]
    mov [rbp-344], rax
    lea rdx, [rbp-344]
    call array_add
    add rsp, 32  ; clean shadow space
    mov rax, 2
    mov [rbp-344], rax
    mov rax, 2
    mov [rbp-352], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-304]
    mov rax, [rbp-352]
    mov [rbp-360], rax
    lea rdx, [rbp-360]
    call array_add
    add rsp, 32  ; clean shadow space
    mov rax, 3
    mov [rbp-360], rax
    mov rax, 3
    mov [rbp-368], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-304]
    mov rax, [rbp-368]
    mov [rbp-376], rax
    lea rdx, [rbp-376]
    call array_add
    add rsp, 32  ; clean shadow space
    mov rax, 4
    mov [rbp-376], rax
    mov rax, 4
    mov [rbp-384], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-304]
    mov rax, [rbp-384]
    mov [rbp-392], rax
    lea rdx, [rbp-392]
    call array_add
    add rsp, 32  ; clean shadow space
    mov rax, [rbp-304]
    mov [rbp-288], rax
    mov rax, 5
    mov [rbp-400], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-400]
    mov rdx, 8  ; element size
    call array_create
    add rsp, 32  ; clean shadow space
    mov [rbp-408], rax
    mov rax, 0
    mov [rbp-416], rax
    mov rax, 0
    mov [rbp-424], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-408]
    mov rax, [rbp-424]
    mov [rbp-432], rax
    lea rdx, [rbp-432]
    call array_add
    add rsp, 32  ; clean shadow space
    mov rax, 1
    mov [rbp-432], rax
    mov rax, 1
    mov [rbp-440], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-408]
    mov rax, [rbp-440]
    mov [rbp-448], rax
    lea rdx, [rbp-448]
    call array_add
    add rsp, 32  ; clean shadow space
    mov rax, 2
    mov [rbp-448], rax
    mov rax, 2
    mov [rbp-456], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-408]
    mov rax, [rbp-456]
    mov [rbp-464], rax
    lea rdx, [rbp-464]
    call array_add
    add rsp, 32  ; clean shadow space
    mov rax, 3
    mov [rbp-464], rax
    mov rax, 3
    mov [rbp-472], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-408]
    mov rax, [rbp-472]
    mov [rbp-480], rax
    lea rdx, [rbp-480]
    call array_add
    add rsp, 32  ; clean shadow space
    mov rax, 4
    mov [rbp-480], rax
    mov rax, 4
    mov [rbp-488], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-408]
    mov rax, [rbp-488]
    mov [rbp-496], rax
    lea rdx, [rbp-496]
    call array_add
    add rsp, 32  ; clean shadow space
    mov rax, [rbp-408]
    mov [rbp-392], rax
    mov rax, [rbp-200]
    mov [rbp-496], rax
    lea rax, [rel str_4]
    mov [rbp-504], rax
    mov rax, 0
    mov [rbp-512], rax
    mov rax, [rbp-200]
    mov [rbp-520], rax
    lea rax, [rel str_5]
    mov [rbp-528], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-520]
    mov rax, [rbp-528]
    mov [rbp-536], rax
    lea rdx, [rbp-536]
    call array_add
    add rsp, 32  ; clean shadow space
    mov rax, [rbp-200]
    mov [rbp-544], rax
    lea rax, [rel str_6]
    mov [rbp-552], rax
    mov rax, 0
    mov [rbp-560], rax
    mov rax, [rbp-560]
    mov [rbp-536], rax
    mov rax, [rbp-200]
    mov [rbp-576], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-576]
    call array_size
    add rsp, 32  ; clean shadow space
    mov [rbp-584], rax
    mov rax, [rbp-584]
    mov [rbp-568], rax
    mov rax, [rbp-200]
    mov [rbp-608], rax
    mov rax, 1
    mov [rbp-616], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-608]
    mov rdx, [rbp-616]
    call array_get
    add rsp, 32  ; clean shadow space
    mov rdx, [rax]
    mov [rbp-624], rdx
    mov rax, [rbp-624]
    mov [rbp-600], rax
    mov rax, [rbp-200]
    mov [rbp-632], rax
    mov rax, 1
    mov [rbp-640], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-632]
    mov rdx, [rbp-640]
    call array_remove
    add rsp, 32  ; clean shadow space
    mov rax, [rbp-200]
    mov [rbp-664], rax
    lea rax, [rel __lambda_0]
    mov [rbp-672], rax
    mov rax, [rbp-664]
    mov [rbp-656], rax
    mov rax, [rbp-200]
    mov [rbp-696], rax
    lea rax, [rel str_8]
    mov [rbp-704], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-696]
    mov rdx, [rbp-704]
    lea r8, [rbp-720]
    call array_join
    add rsp, 32  ; clean shadow space
    lea rax, [rbp-720]
    mov [rbp-688], rax
    mov rax, [rbp-688]
    mov [rbp-728], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-728]
    call print_string
    add rsp, 32  ; clean shadow space
    lea rax, [rel str_9]
    mov [rbp-736], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-736]
    call print_string
    add rsp, 32  ; clean shadow space
    mov rax, [rbp-200]
    mov [rbp-760], rax
    lea rax, [rel __lambda_1]
    mov [rbp-768], rax
    mov rax, [rbp-760]
    mov [rbp-752], rax
    mov rax, [rbp-104]
    mov [rbp-776], rax
    mov rax, 10
    mov [rbp-784], rax
    mov rax, 0
    mov [rbp-792], rax
    mov rax, [rbp-104]
    mov [rbp-800], rax
    mov rax, 2
    mov [rbp-808], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-800]
    mov rax, [rbp-808]
    mov [rbp-816], rax
    lea rdx, [rbp-816]
    call array_add
    add rsp, 32  ; clean shadow space
    mov rax, [rbp-104]
    mov [rbp-824], rax
    mov rax, 2
    mov [rbp-832], rax
    mov rax, 0
    mov [rbp-840], rax
    mov rax, [rbp-840]
    mov [rbp-816], rax
    mov rax, [rbp-104]
    mov [rbp-856], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-856]
    call array_size
    add rsp, 32  ; clean shadow space
    mov [rbp-864], rax
    mov rax, [rbp-864]
    mov [rbp-848], rax
    mov rax, [rbp-104]
    mov [rbp-880], rax
    mov rax, 1
    mov [rbp-888], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-880]
    mov rdx, [rbp-888]
    call array_get
    add rsp, 32  ; clean shadow space
    mov rdx, [rax]
    mov [rbp-896], rdx
    mov rax, [rbp-896]
    mov [rbp-872], rax
    mov rax, [rbp-104]
    mov [rbp-904], rax
    mov rax, 1
    mov [rbp-912], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-904]
    mov rdx, [rbp-912]
    call array_remove
    add rsp, 32  ; clean shadow space
    mov rax, [rbp-104]
    mov [rbp-928], rax
    lea rax, [rel __lambda_2]
    mov [rbp-936], rax
    mov rax, [rbp-928]
    mov [rbp-920], rax
    mov rax, [rbp-104]
    mov [rbp-960], rax
    lea rax, [rel str_10]
    mov [rbp-968], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-960]
    mov rdx, [rbp-968]
    lea r8, [rbp-984]
    call array_join_int
    add rsp, 32  ; clean shadow space
    lea rax, [rbp-984]
    mov [rbp-952], rax
    mov rax, [rbp-952]
    mov [rbp-992], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-992]
    call print_string
    add rsp, 32  ; clean shadow space
    lea rax, [rel str_11]
    mov [rbp-1000], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-1000]
    call print_string
    add rsp, 32  ; clean shadow space
    mov rax, [rbp-104]
    mov [rbp-1016], rax
    lea rax, [rel __lambda_3]
    mov [rbp-1024], rax
    mov rax, [rbp-1016]
    mov [rbp-1008], rax
    mov rax, [rbp-288]
    mov [rbp-1032], rax
    mov rax, 1
    mov [rbp-1040], rax
    mov rax, 0
    mov [rbp-1048], rax
    mov rax, [rbp-288]
    mov [rbp-1056], rax
    mov rax, 2
    mov [rbp-1064], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-1056]
    mov rax, [rbp-1064]
    mov [rbp-1072], rax
    lea rdx, [rbp-1072]
    call array_add
    add rsp, 32  ; clean shadow space
    mov rax, [rbp-288]
    mov [rbp-1080], rax
    mov rax, 2
    mov [rbp-1088], rax
    mov rax, 0
    mov [rbp-1096], rax
    mov rax, [rbp-1096]
    mov [rbp-1072], rax
    mov rax, [rbp-288]
    mov [rbp-1112], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-1112]
    call array_size
    add rsp, 32  ; clean shadow space
    mov [rbp-1120], rax
    mov rax, [rbp-1120]
    mov [rbp-1104], rax
    mov rax, [rbp-288]
    mov [rbp-1136], rax
    mov rax, 1
    mov [rbp-1144], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-1136]
    mov rdx, [rbp-1144]
    call array_get
    add rsp, 32  ; clean shadow space
    mov rdx, [rax]
    mov [rbp-1152], rdx
    mov rax, [rbp-1152]
    mov [rbp-1128], rax
    mov rax, [rbp-288]
    mov [rbp-1160], rax
    mov rax, 1
    mov [rbp-1168], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-1160]
    mov rdx, [rbp-1168]
    call array_remove
    add rsp, 32  ; clean shadow space
    mov rax, [rbp-288]
    mov [rbp-1184], rax
    lea rax, [rel __lambda_4]
    mov [rbp-1192], rax
    mov rax, [rbp-1184]
    mov [rbp-1176], rax
    mov rax, [rbp-288]
    mov [rbp-1216], rax
    lea rax, [rel str_12]
    mov [rbp-1224], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-1216]
    mov rdx, [rbp-1224]
    lea r8, [rbp-1240]
    call array_join_long
    add rsp, 32  ; clean shadow space
    lea rax, [rbp-1240]
    mov [rbp-1208], rax
    mov rax, [rbp-1208]
    mov [rbp-1248], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-1248]
    call print_string
    add rsp, 32  ; clean shadow space
    lea rax, [rel str_13]
    mov [rbp-1256], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-1256]
    call print_string
    add rsp, 32  ; clean shadow space
    mov rax, [rbp-288]
    mov [rbp-1272], rax
    lea rax, [rel __lambda_5]
    mov [rbp-1280], rax
    mov rax, [rbp-1272]
    mov [rbp-1264], rax
    mov rax, [rbp-392]
    mov [rbp-1288], rax
    mov rax, 1
    mov [rbp-1296], rax
    mov rax, 0
    mov [rbp-1304], rax
    mov rax, [rbp-392]
    mov [rbp-1312], rax
    mov rax, 2
    mov [rbp-1320], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-1312]
    mov rax, [rbp-1320]
    mov [rbp-1328], rax
    lea rdx, [rbp-1328]
    call array_add
    add rsp, 32  ; clean shadow space
    mov rax, [rbp-392]
    mov [rbp-1336], rax
    mov rax, 2
    mov [rbp-1344], rax
    mov rax, 0
    mov [rbp-1352], rax
    mov rax, [rbp-1352]
    mov [rbp-1328], rax
    mov rax, [rbp-392]
    mov [rbp-1368], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-1368]
    call array_size
    add rsp, 32  ; clean shadow space
    mov [rbp-1376], rax
    mov rax, [rbp-1376]
    mov [rbp-1360], rax
    mov rax, [rbp-392]
    mov [rbp-1392], rax
    mov rax, 1
    mov [rbp-1400], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-1392]
    mov rdx, [rbp-1400]
    call array_get
    add rsp, 32  ; clean shadow space
    movsd xmm0, qword [rax]
    movsd qword [rbp-1408], xmm0
    mov rax, [rbp-1408]
    mov [rbp-1384], rax
    mov rax, [rbp-392]
    mov [rbp-1416], rax
    mov rax, 1
    mov [rbp-1424], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-1416]
    mov rdx, [rbp-1424]
    call array_remove
    add rsp, 32  ; clean shadow space
    mov rax, [rbp-392]
    mov [rbp-1440], rax
    lea rax, [rel __lambda_6]
    mov [rbp-1448], rax
    mov rax, [rbp-1440]
    mov [rbp-1432], rax
    mov rax, [rbp-392]
    mov [rbp-1472], rax
    lea rax, [rel str_14]
    mov [rbp-1480], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-1472]
    mov rdx, [rbp-1480]
    lea r8, [rbp-1496]
    call array_join_double
    add rsp, 32  ; clean shadow space
    lea rax, [rbp-1496]
    mov [rbp-1464], rax
    mov rax, [rbp-1464]
    mov [rbp-1504], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-1504]
    call print_string
    add rsp, 32  ; clean shadow space
    lea rax, [rel str_15]
    mov [rbp-1512], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-1512]
    call print_string
    add rsp, 32  ; clean shadow space
    mov rax, [rbp-392]
    mov [rbp-1528], rax
    lea rax, [rel __lambda_7]
    mov [rbp-1536], rax
    mov rax, [rbp-1528]
    mov [rbp-1520], rax
    lea rax, [rel str_16]
    mov [rbp-1544], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-1544]
    call print_string
    add rsp, 32  ; clean shadow space
    mov rax, [rbp-96]
    mov [rbp-1552], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-1552]
    call Map_mapFunctions
    add rsp, 32  ; clean shadow space
    mov [rbp-1560], rax
    mov rax, [rbp-96]
    mov [rbp-1568], rax
    lea rax, [rel str_17]
    mov [rbp-1576], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-1568]
    mov rdx, [rbp-1576]
    call FileRead_readFile
    add rsp, 32  ; clean shadow space
    mov [rbp-1584], rax
    sub rsp, 32  ; shadow space
    lea rcx, [rbp-1464]
    call string_free
    add rsp, 32  ; clean shadow space
    sub rsp, 32  ; shadow space
    lea rcx, [rbp-1208]
    call string_free
    add rsp, 32  ; clean shadow space
    sub rsp, 32  ; shadow space
    lea rcx, [rbp-952]
    call string_free
    add rsp, 32  ; clean shadow space
    mov rax, [rbp-752]
    mov [rbp-1592], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-1592]
    call string_free
    add rsp, 32  ; clean shadow space
    sub rsp, 32  ; shadow space
    lea rcx, [rbp-688]
    call string_free
    add rsp, 32  ; clean shadow space
    mov rax, [rbp-656]
    mov [rbp-1600], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-1600]
    call string_free
    add rsp, 32  ; clean shadow space
    mov rax, [rbp-600]
    mov [rbp-1608], rax
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-1608]
    call string_free
    add rsp, 32  ; clean shadow space
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-408]
    call array_free
    add rsp, 32  ; clean shadow space
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-304]
    call array_free
    add rsp, 32  ; clean shadow space
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-200]
    call array_free
    add rsp, 32  ; clean shadow space
    sub rsp, 32  ; shadow space
    mov rcx, [rbp-120]
    call array_free
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

__lambda_0:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 152  ; local variables + shadow space
    mov [rbp-88], rcx  ; param 'this'
    mov [rbp-96], rdx  ; param 'value'
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
    lea rcx, [rel str_11]
    lea rdx, [rel str_11_data]
    call string_from_cstr
    lea rcx, [rel str_12]
    lea rdx, [rel str_12_data]
    call string_from_cstr
    lea rcx, [rel str_13]
    lea rdx, [rel str_13_data]
    call string_from_cstr
    lea rcx, [rel str_14]
    lea rdx, [rel str_14_data]
    call string_from_cstr
    lea rcx, [rel str_15]
    lea rdx, [rel str_15_data]
    call string_from_cstr
    lea rcx, [rel str_16]
    lea rdx, [rel str_16_data]
    call string_from_cstr
    lea rcx, [rel str_17]
    lea rdx, [rel str_17_data]
    call string_from_cstr
__lambda_0_entry:
    mov rax, [rbp-88]
    mov [rbp-104], rax
    mov rax, [rbp-96]
    mov [rbp-112], rax
    mov rax, [rbp-112]
    mov [rbp-128], rax
    lea rax, [rel str_7]
    mov [rbp-136], rax
    xor rax, rax  ; unresolved: %t76
    mov [rbp-120], rax
    mov rax, [rbp-120]
    mov [rbp-144], rax
    mov rax, [rbp-144]
    add rsp, 0  ; clean stack frame
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret

__lambda_1:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 168  ; local variables + shadow space
    mov [rbp-88], rcx  ; param 'this'
    mov [rbp-96], rdx  ; param 'a'
    mov [rbp-104], r8  ; param 'b'
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
    lea rcx, [rel str_11]
    lea rdx, [rel str_11_data]
    call string_from_cstr
    lea rcx, [rel str_12]
    lea rdx, [rel str_12_data]
    call string_from_cstr
    lea rcx, [rel str_13]
    lea rdx, [rel str_13_data]
    call string_from_cstr
    lea rcx, [rel str_14]
    lea rdx, [rel str_14_data]
    call string_from_cstr
    lea rcx, [rel str_15]
    lea rdx, [rel str_15_data]
    call string_from_cstr
    lea rcx, [rel str_16]
    lea rdx, [rel str_16_data]
    call string_from_cstr
    lea rcx, [rel str_17]
    lea rdx, [rel str_17_data]
    call string_from_cstr
__lambda_1_entry:
    mov rax, [rbp-88]
    mov [rbp-112], rax
    mov rax, [rbp-96]
    mov [rbp-120], rax
    mov rax, [rbp-104]
    mov [rbp-128], rax
    mov rax, [rbp-120]
    mov [rbp-144], rax
    mov rax, [rbp-136]
    mov [rbp-152], rax
    mov rax, [rbp-144]
    mov rbx, [rbp-152]
    cmp rax, rbx
    setg al
    movzx rax, al
    mov [rbp-160], rax
    mov rax, [rbp-160]
    mov [rbp-136], rax
    mov rax, [rbp-136]
    mov [rbp-168], rax
    mov rax, [rbp-168]
    add rsp, 0  ; clean stack frame
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret

__lambda_2:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 152  ; local variables + shadow space
    mov [rbp-88], rcx  ; param 'this'
    mov [rbp-96], rdx  ; param 'value'
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
    lea rcx, [rel str_11]
    lea rdx, [rel str_11_data]
    call string_from_cstr
    lea rcx, [rel str_12]
    lea rdx, [rel str_12_data]
    call string_from_cstr
    lea rcx, [rel str_13]
    lea rdx, [rel str_13_data]
    call string_from_cstr
    lea rcx, [rel str_14]
    lea rdx, [rel str_14_data]
    call string_from_cstr
    lea rcx, [rel str_15]
    lea rdx, [rel str_15_data]
    call string_from_cstr
    lea rcx, [rel str_16]
    lea rdx, [rel str_16_data]
    call string_from_cstr
    lea rcx, [rel str_17]
    lea rdx, [rel str_17_data]
    call string_from_cstr
__lambda_2_entry:
    mov rax, [rbp-88]
    mov [rbp-104], rax
    mov rax, [rbp-96]
    mov [rbp-112], rax
    mov rax, [rbp-112]
    mov [rbp-128], rax
    mov rax, 2
    mov [rbp-136], rax
    xor rax, rax  ; unresolved: %t123
    mov [rbp-120], rax
    mov rax, [rbp-120]
    mov [rbp-144], rax
    mov rax, [rbp-144]
    add rsp, 0  ; clean stack frame
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret

__lambda_3:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 168  ; local variables + shadow space
    mov [rbp-88], rcx  ; param 'this'
    mov [rbp-96], rdx  ; param 'a'
    mov [rbp-104], r8  ; param 'b'
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
    lea rcx, [rel str_11]
    lea rdx, [rel str_11_data]
    call string_from_cstr
    lea rcx, [rel str_12]
    lea rdx, [rel str_12_data]
    call string_from_cstr
    lea rcx, [rel str_13]
    lea rdx, [rel str_13_data]
    call string_from_cstr
    lea rcx, [rel str_14]
    lea rdx, [rel str_14_data]
    call string_from_cstr
    lea rcx, [rel str_15]
    lea rdx, [rel str_15_data]
    call string_from_cstr
    lea rcx, [rel str_16]
    lea rdx, [rel str_16_data]
    call string_from_cstr
    lea rcx, [rel str_17]
    lea rdx, [rel str_17_data]
    call string_from_cstr
__lambda_3_entry:
    mov rax, [rbp-88]
    mov [rbp-112], rax
    mov rax, [rbp-96]
    mov [rbp-120], rax
    mov rax, [rbp-104]
    mov [rbp-128], rax
    mov rax, [rbp-120]
    mov [rbp-144], rax
    mov rax, [rbp-136]
    mov [rbp-152], rax
    mov rax, [rbp-144]
    mov rbx, [rbp-152]
    cmp rax, rbx
    setg al
    movzx rax, al
    mov [rbp-160], rax
    mov rax, [rbp-160]
    mov [rbp-136], rax
    mov rax, [rbp-136]
    mov [rbp-168], rax
    mov rax, [rbp-168]
    add rsp, 0  ; clean stack frame
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret

__lambda_4:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 152  ; local variables + shadow space
    mov [rbp-88], rcx  ; param 'this'
    mov [rbp-96], rdx  ; param 'value'
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
    lea rcx, [rel str_11]
    lea rdx, [rel str_11_data]
    call string_from_cstr
    lea rcx, [rel str_12]
    lea rdx, [rel str_12_data]
    call string_from_cstr
    lea rcx, [rel str_13]
    lea rdx, [rel str_13_data]
    call string_from_cstr
    lea rcx, [rel str_14]
    lea rdx, [rel str_14_data]
    call string_from_cstr
    lea rcx, [rel str_15]
    lea rdx, [rel str_15_data]
    call string_from_cstr
    lea rcx, [rel str_16]
    lea rdx, [rel str_16_data]
    call string_from_cstr
    lea rcx, [rel str_17]
    lea rdx, [rel str_17_data]
    call string_from_cstr
__lambda_4_entry:
    mov rax, [rbp-88]
    mov [rbp-104], rax
    mov rax, [rbp-96]
    mov [rbp-112], rax
    mov rax, [rbp-112]
    mov [rbp-128], rax
    mov rax, 2
    mov [rbp-136], rax
    xor rax, rax  ; unresolved: %t170
    mov [rbp-120], rax
    mov rax, [rbp-120]
    mov [rbp-144], rax
    mov rax, [rbp-144]
    add rsp, 0  ; clean stack frame
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret

__lambda_5:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 168  ; local variables + shadow space
    mov [rbp-88], rcx  ; param 'this'
    mov [rbp-96], rdx  ; param 'a'
    mov [rbp-104], r8  ; param 'b'
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
    lea rcx, [rel str_11]
    lea rdx, [rel str_11_data]
    call string_from_cstr
    lea rcx, [rel str_12]
    lea rdx, [rel str_12_data]
    call string_from_cstr
    lea rcx, [rel str_13]
    lea rdx, [rel str_13_data]
    call string_from_cstr
    lea rcx, [rel str_14]
    lea rdx, [rel str_14_data]
    call string_from_cstr
    lea rcx, [rel str_15]
    lea rdx, [rel str_15_data]
    call string_from_cstr
    lea rcx, [rel str_16]
    lea rdx, [rel str_16_data]
    call string_from_cstr
    lea rcx, [rel str_17]
    lea rdx, [rel str_17_data]
    call string_from_cstr
__lambda_5_entry:
    mov rax, [rbp-88]
    mov [rbp-112], rax
    mov rax, [rbp-96]
    mov [rbp-120], rax
    mov rax, [rbp-104]
    mov [rbp-128], rax
    mov rax, [rbp-120]
    mov [rbp-144], rax
    mov rax, [rbp-136]
    mov [rbp-152], rax
    mov rax, [rbp-144]
    mov rbx, [rbp-152]
    cmp rax, rbx
    setg al
    movzx rax, al
    mov [rbp-160], rax
    mov rax, [rbp-160]
    mov [rbp-136], rax
    mov rax, [rbp-136]
    mov [rbp-168], rax
    mov rax, [rbp-168]
    add rsp, 0  ; clean stack frame
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret

__lambda_6:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 152  ; local variables + shadow space
    mov [rbp-88], rcx  ; param 'this'
    mov [rbp-96], rdx  ; param 'value'
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
    lea rcx, [rel str_11]
    lea rdx, [rel str_11_data]
    call string_from_cstr
    lea rcx, [rel str_12]
    lea rdx, [rel str_12_data]
    call string_from_cstr
    lea rcx, [rel str_13]
    lea rdx, [rel str_13_data]
    call string_from_cstr
    lea rcx, [rel str_14]
    lea rdx, [rel str_14_data]
    call string_from_cstr
    lea rcx, [rel str_15]
    lea rdx, [rel str_15_data]
    call string_from_cstr
    lea rcx, [rel str_16]
    lea rdx, [rel str_16_data]
    call string_from_cstr
    lea rcx, [rel str_17]
    lea rdx, [rel str_17_data]
    call string_from_cstr
__lambda_6_entry:
    mov rax, [rbp-88]
    mov [rbp-104], rax
    mov rax, [rbp-96]
    mov [rbp-112], rax
    mov rax, [rbp-112]
    mov [rbp-128], rax
    mov rax, 2
    mov [rbp-136], rax
    xor rax, rax  ; unresolved: %t217
    mov [rbp-120], rax
    mov rax, [rbp-120]
    mov [rbp-144], rax
    mov rax, [rbp-144]
    add rsp, 0  ; clean stack frame
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret

__lambda_7:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 168  ; local variables + shadow space
    mov [rbp-88], rcx  ; param 'this'
    mov [rbp-96], rdx  ; param 'a'
    mov [rbp-104], r8  ; param 'b'
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
    lea rcx, [rel str_11]
    lea rdx, [rel str_11_data]
    call string_from_cstr
    lea rcx, [rel str_12]
    lea rdx, [rel str_12_data]
    call string_from_cstr
    lea rcx, [rel str_13]
    lea rdx, [rel str_13_data]
    call string_from_cstr
    lea rcx, [rel str_14]
    lea rdx, [rel str_14_data]
    call string_from_cstr
    lea rcx, [rel str_15]
    lea rdx, [rel str_15_data]
    call string_from_cstr
    lea rcx, [rel str_16]
    lea rdx, [rel str_16_data]
    call string_from_cstr
    lea rcx, [rel str_17]
    lea rdx, [rel str_17_data]
    call string_from_cstr
__lambda_7_entry:
    mov rax, [rbp-88]
    mov [rbp-112], rax
    mov rax, [rbp-96]
    mov [rbp-120], rax
    mov rax, [rbp-104]
    mov [rbp-128], rax
    mov rax, [rbp-120]
    mov [rbp-144], rax
    mov rax, [rbp-136]
    mov [rbp-152], rax
    mov rax, [rbp-144]
    mov rbx, [rbp-152]
    cmp rax, rbx
    setg al
    movzx rax, al
    mov [rbp-160], rax
    mov rax, [rbp-160]
    mov [rbp-136], rax
    mov rax, [rbp-136]
    mov [rbp-168], rax
    mov rax, [rbp-168]
    add rsp, 0  ; clean stack frame
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret

