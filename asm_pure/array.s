.intel_syntax noprefix

.extern pCreateFileA
.extern pReadFile
.extern pWriteFile
.extern pSetFilePointerEx
.extern pCloseHandle
.extern pDeleteFileA

.extern string_from_cstr
.extern string_equals_icase
.extern string_char_at
.extern string_length
.extern string_contains_char
.extern string_concat
.extern string_copy
.extern string_free
.extern print_cstr
.extern print_string
.extern print_uint
.extern fromInteger
.extern fromLong
.extern fromDouble

.global array_demo
.global array_init
.global array_create
.global array_add
.global array_find
.global array_remove
.global array_size
.global array_get
.global array_filter
.global array_free
.global array_sort
.global array_map
.global array_join
.global array_join_int
.global array_join_long
.global array_join_double
.global array_join_bool

.equ GENERIC_READ, 0x80000000
.equ GENERIC_WRITE, 0x40000000
.equ FILE_SHARE_READ, 1
.equ CREATE_ALWAYS, 2
.equ FILE_ATTRIBUTE_NORMAL, 0x00000080
.equ FILE_BEGIN, 0
.equ INVALID_HANDLE_VALUE, -1

.section .data
alpha:     .asciz "alpha"
bravo:     .asciz "bravo"
charlie:   .asciz "charlie"
delta:     .asciz "delta"
echo:      .asciz "echo"
foxtrot:   .asciz "foxtrot"
empty_str: .asciz ""

msg_size:  .asciz "Array size = "
msg_found: .asciz "Find alpha (ignore case)? "
msg_true:  .asciz "true\n"
msg_false: .asciz "false\n"
msg_nl:    .asciz "\n"
msg_idx0:  .asciz "[0] = "
msg_idx1:  .asciz "[1] = "
msg_idx2:  .asciz "[2] = "
msg_idx3:  .asciz "[3] = "
msg_idx4:  .asciz "[4] = "
msg_add_extra: .asciz "Add extra element? "
msg_found_no: .asciz "Find \"zz\"? "
msg_remove_ok: .asciz "Remove index 2? "
msg_remove_bad: .asciz "Remove index 9? "
hex_digits: .asciz "0123456789ABCDEF"
line_prefix_0: .asciz "["
line_prefix_1: .asciz "]= "

.section .bss
.align 8
array_get_buf: .space 4096
array_tmp_buf: .space 4096
array_txt_buf: .space 8192
array_pool:    .space 512       # 16 array structs * 32 bytes
array_pool_next: .quad 0

.section .text

# File-backed Array struct: [0]=file handle, [8]=len, [16]=cap, [24]=elem_size

array_strlen:
    # rcx=cstr -> rax=len
    mov rax, rcx
.strlen_loop:
    cmp byte ptr [rax], 0
    je .strlen_done
    inc rax
    jmp .strlen_loop
.strlen_done:
    sub rax, rcx
    ret

array_i64_to_cstr:
    # rcx=signed value, rdx=buffer_end -> rax=start_ptr
    mov rax, rcx
    mov r10, rdx
    mov byte ptr [r10], 0
    test rax, rax
    jnz .i64_not_zero
    dec r10
    mov byte ptr [r10], '0'
    mov rax, r10
    ret
.i64_not_zero:
    xor r11d, r11d
    test rax, rax
    jns .i64_pos
    neg rax
    mov r11b, 1
.i64_pos:
.i64_loop:
    xor rdx, rdx
    mov rcx, 10
    div rcx
    add dl, '0'
    dec r10
    mov byte ptr [r10], dl
    test rax, rax
    jnz .i64_loop
    test r11b, r11b
    jz .i64_done
    dec r10
    mov byte ptr [r10], '-'
.i64_done:
    mov rax, r10
    ret

array_append_cstr:
    # rcx=dst cursor, rdx=src cstr -> rax=updated cursor
    mov rax, rcx
.append_cstr_loop:
    mov r8b, byte ptr [rdx]
    test r8b, r8b
    jz .append_cstr_done
    mov byte ptr [rax], r8b
    inc rax
    inc rdx
    jmp .append_cstr_loop
.append_cstr_done:
    ret

array_append_i64:
    # rcx=dst cursor, rdx=signed value -> rax=updated cursor
    sub rsp, 56
    mov qword ptr [rsp + 40], rcx
    lea r8, [rsp + 31]
    mov rcx, rdx
    mov rdx, r8
    call array_i64_to_cstr
    mov rdx, rax
    mov rcx, qword ptr [rsp + 40]
    call array_append_cstr
    add rsp, 56
    ret

array_make_txt_path:
    # rcx=array*, rdx=path buffer
    call array_make_path
    mov byte ptr [rdx + 27], 't'
    mov byte ptr [rdx + 28], 'x'
    mov byte ptr [rdx + 29], 't'
    ret

array_append_string_value:
    # rcx=dst cursor, rdx=String* -> rax=updated cursor
    push rbx
    push r12
    push r13
    sub rsp, 32
    mov rbx, rcx
    mov r12, rdx
    mov rcx, r12
    call string_length
    mov r13, rax
    xor r8, r8
.append_string_loop:
    cmp r8, r13
    jae .append_string_done
    mov rcx, r12
    mov rdx, r8
    call string_char_at
    mov byte ptr [rbx], al
    inc rbx
    inc r8
    jmp .append_string_loop
.append_string_done:
    mov rax, rbx
    add rsp, 32
    pop r13
    pop r12
    pop rbx
    ret

array_append_hex_bytes:
    # rcx=dst cursor, rdx=data ptr, r8=size -> rax=updated cursor
    push rbx
    push r12
    push r13
    mov rbx, rcx
    mov r12, rdx
    mov r13, r8
    lea r10, [rip + hex_digits]
    xor r11, r11
.append_hex_loop:
    cmp r11, r13
    jae .append_hex_done
    cmp r11, 0
    je .append_hex_no_space
    mov byte ptr [rbx], ' '
    inc rbx
.append_hex_no_space:
    movzx eax, byte ptr [r12 + r11]
    mov edx, eax
    shr eax, 4
    and edx, 0x0f
    mov al, byte ptr [r10 + rax]
    mov byte ptr [rbx], al
    inc rbx
    mov dl, byte ptr [r10 + rdx]
    mov byte ptr [rbx], dl
    inc rbx
    inc r11
    jmp .append_hex_loop
.append_hex_done:
    mov rax, rbx
    pop r13
    pop r12
    pop rbx
    ret

array_sync_txt:
    # rcx=array*
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 240
    mov rbx, rcx
    test rbx, rbx
    jz .sync_done
    lea r12, [rsp + 80]
    mov rcx, rbx
    mov rdx, r12
    call array_make_txt_path

    mov rcx, r12
    mov rdx, GENERIC_WRITE
    mov r8, FILE_SHARE_READ
    xor r9, r9
    mov qword ptr [rsp + 32], CREATE_ALWAYS
    mov qword ptr [rsp + 40], FILE_ATTRIBUTE_NORMAL
    mov qword ptr [rsp + 48], 0
    call qword ptr [rip + pCreateFileA]
    cmp rax, INVALID_HANDLE_VALUE
    je .sync_done
    mov r14, rax
    xor r13, r13
.sync_loop:
    cmp r13, [rbx + 8]
    jae .sync_close
    lea rcx, [rip + array_txt_buf]
    lea rdx, [rip + line_prefix_0]
    call array_append_cstr
    mov rcx, rax
    mov rdx, r13
    call array_append_i64
    mov rcx, rax
    lea rdx, [rip + line_prefix_1]
    call array_append_cstr
    mov r15, rax

    mov rcx, rbx
    mov rdx, r13
    call array_get
    mov r12, rax
    mov rcx, qword ptr [rbx + 24]
    cmp rcx, 16
    je .sync_string
    cmp rcx, 8
    je .sync_i64
    jmp .sync_hex
.sync_string:
    mov rcx, r15
    mov rdx, r12
    call array_append_string_value
    jmp .sync_line_end
.sync_i64:
    mov rdx, qword ptr [r12]
    mov rcx, r15
    call array_append_i64
    jmp .sync_line_end
.sync_hex:
    mov rcx, r15
    mov rdx, r12
    mov r8, [rbx + 24]
    call array_append_hex_bytes

.sync_line_end:
    mov byte ptr [rax], 13
    mov byte ptr [rax + 1], 10
    mov byte ptr [rax + 2], 0
    lea rcx, [rip + array_txt_buf]
    call array_strlen
    mov rcx, r14
    lea rdx, [rip + array_txt_buf]
    mov r8, rax
    lea r9, [rsp + 64]
    mov qword ptr [rsp + 32], 0
    call qword ptr [rip + pWriteFile]
    inc r13
    jmp .sync_loop
.sync_close:
    mov rcx, r14
    sub rsp, 32
    call qword ptr [rip + pCloseHandle]
    add rsp, 32
.sync_done:
    add rsp, 240
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

array_make_path:
    # rcx=array*, rdx=path buffer
    mov byte ptr [rdx], 'f'
    mov byte ptr [rdx + 1], 'i'
    mov byte ptr [rdx + 2], 'l'
    mov byte ptr [rdx + 3], 'e'
    mov byte ptr [rdx + 4], 'a'
    mov byte ptr [rdx + 5], 'r'
    mov byte ptr [rdx + 6], 'r'
    mov byte ptr [rdx + 7], 'a'
    mov byte ptr [rdx + 8], 'y'
    mov byte ptr [rdx + 9], '_'
    mov rax, rcx
    lea r10, [rip + hex_digits]
    mov r11, 16
    lea r8, [rdx + 10]
.make_hex:
    rol rax, 4
    mov r9, rax
    and r9, 0x0f
    mov r9b, byte ptr [r10 + r9]
    mov byte ptr [r8], r9b
    inc r8
    dec r11
    jnz .make_hex
    mov byte ptr [rdx + 26], '.'
    mov byte ptr [rdx + 27], 'b'
    mov byte ptr [rdx + 28], 'i'
    mov byte ptr [rdx + 29], 'n'
    mov byte ptr [rdx + 30], 0
    ret

array_init:
    # rcx=array*, rdx=cap, r8=elem_size
    push rbx
    push r12
    push r13
    sub rsp, 128
    mov rbx, rcx
    mov r12, rdx
    mov r13, r8
    mov qword ptr [rbx + 8], 0
    mov qword ptr [rbx + 16], r12
    mov qword ptr [rbx + 24], r13
    lea rdx, [rsp + 32]
    mov rcx, rbx
    call array_make_path

    lea rcx, [rsp + 32]
    mov rdx, GENERIC_READ
    or rdx, GENERIC_WRITE
    mov r8, FILE_SHARE_READ
    xor r9, r9
    sub rsp, 64
    mov qword ptr [rsp + 32], CREATE_ALWAYS
    mov qword ptr [rsp + 40], FILE_ATTRIBUTE_NORMAL
    mov qword ptr [rsp + 48], 0
    call qword ptr [rip + pCreateFileA]
    add rsp, 64
    cmp rax, INVALID_HANDLE_VALUE
    je .init_fail
    mov qword ptr [rbx], rax
    jmp .init_done
.init_fail:
    mov qword ptr [rbx], 0
    mov qword ptr [rbx + 8], 0
    mov qword ptr [rbx + 16], 0
    mov qword ptr [rbx + 24], 0
.init_done:
    mov rcx, rbx
    call array_sync_txt
    add rsp, 128
    pop r13
    pop r12
    pop rbx
    ret

array_create:
    # rcx=cap, rdx=elem_size -> rax=array*
    push rbx
    push r12
    mov rbx, rcx
    mov r12, rdx
    lea rax, [rip + array_pool_next]
    mov r8, [rax]
    cmp r8, 16
    jae .create_fail
    inc qword ptr [rax]
    shl r8, 5
    lea rax, [rip + array_pool]
    add rax, r8
    mov qword ptr [rax], 0
    mov qword ptr [rax + 8], 0
    mov qword ptr [rax + 16], 0
    mov qword ptr [rax + 24], 0
    mov rcx, rax
    mov rdx, rbx
    mov r8, r12
    mov rbx, rax
    sub rsp, 40
    call array_init
    add rsp, 40
    mov rax, rbx
    pop r12
    pop rbx
    ret
.create_fail:
    xor rax, rax
    pop r12
    pop rbx
    ret

array_add:
    # rcx=array*, rdx=elem_ptr -> rax=1/0
    push rbx
    push r12
    push r13
    sub rsp, 48
    mov rbx, rcx
    mov r12, rdx
    mov r13, [rbx + 8]
    cmp r13, [rbx + 16]
    jb .add_have_capacity
    mov rax, [rbx + 16]
    test rax, rax
    jnz .add_grow
    mov rax, 1
    jmp .add_set_capacity
.add_grow:
    add rax, rax
.add_set_capacity:
    mov [rbx + 16], rax
.add_have_capacity:
    mov rax, r13
    imul rax, [rbx + 24]
    mov rcx, [rbx]
    mov edx, eax
    xor r8, r8
    mov r9d, FILE_BEGIN
    call qword ptr [rip + pSetFilePointerEx]
    mov rcx, [rbx]
    mov rdx, r12
    mov r8d, dword ptr [rbx + 24]
    lea r9, [rsp + 40]
    mov qword ptr [rsp + 32], 0
    call qword ptr [rip + pWriteFile]
    test eax, eax
    jz .add_fail
    inc qword ptr [rbx + 8]
    mov rcx, rbx
    call array_sync_txt
    mov rax, 1
    add rsp, 48
    pop r13
    pop r12
    pop rbx
    ret
.add_fail:
    xor rax, rax
    add rsp, 48
    pop r13
    pop r12
    pop rbx
    ret

array_get:
    # rcx=array*, rdx=index -> rax=temp elem ptr
    push rbx
    push r12
    sub rsp, 56
    mov rbx, rcx
    mov r12, rdx
    cmp r12, [rbx + 8]
    jae .get_fail
    mov rax, r12
    imul rax, [rbx + 24]
    mov rcx, [rbx]
    mov edx, eax
    xor r8, r8
    mov r9d, FILE_BEGIN
    call qword ptr [rip + pSetFilePointerEx]
    mov rcx, [rbx]
    lea rdx, [rip + array_get_buf]
    mov r8d, dword ptr [rbx + 24]
    lea r9, [rsp + 40]
    mov qword ptr [rsp + 32], 0
    call qword ptr [rip + pReadFile]
    lea rax, [rip + array_get_buf]
    add rsp, 56
    pop r12
    pop rbx
    ret
.get_fail:
    xor rax, rax
    add rsp, 56
    pop r12
    pop rbx
    ret

array_size:
    mov rax, [rcx + 8]
    ret

array_find:
    # rcx=array*, rdx=callback(elem_ptr)->rax
    push rbx
    push r12
    push r13
    sub rsp, 32
    mov rbx, rcx
    mov r13, rdx
    xor r12, r12
.find_loop:
    cmp r12, [rbx + 8]
    jae .find_no
    mov rcx, rbx
    mov rdx, r12
    call array_get
    mov rcx, rax
    call r13
    test rax, rax
    jnz .find_yes
    inc r12
    jmp .find_loop
.find_yes:
    mov rax, 1
    add rsp, 32
    pop r13
    pop r12
    pop rbx
    ret
.find_no:
    xor rax, rax
    add rsp, 32
    pop r13
    pop r12
    pop rbx
    ret

array_filter:
    # rcx=src*, rdx=callback(elem_ptr)->rax -> rax = new array*
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 40
    mov rbx, rcx
    mov r13, rdx
    mov rcx, [rbx + 8]
    mov rdx, [rbx + 24]
    call array_create
    mov r14, rax
    xor r12, r12
.filter_loop:
    cmp r12, [rbx + 8]
    jae .filter_done
    mov rcx, rbx
    mov rdx, r12
    call array_get
    mov rcx, rax
    call r13
    test rax, rax
    jz .filter_next
    mov rcx, r14
    lea rdx, [rip + array_get_buf]
    call array_add
.filter_next:
    inc r12
    jmp .filter_loop
.filter_done:
    mov rax, r14
    add rsp, 40
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

array_map:
    # rcx=src*, rdx=dst*, r8=callback(elem_ptr,out_elem_ptr)->rax
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 40
    mov rbx, rcx
    mov r13, rdx
    mov r14, r8
    xor r12, r12
.map_loop:
    cmp r12, [rbx + 8]
    jae .map_done
    mov rcx, rbx
    mov rdx, r12
    call array_get
    mov rcx, rax
    lea rdx, [rip + array_tmp_buf]
    call r14
    mov rcx, r13
    lea rdx, [rip + array_tmp_buf]
    call array_add
    inc r12
    jmp .map_loop
.map_done:
    add rsp, 40
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

array_remove:
    # rcx=array*, rdx=index -> rax=1/0
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 56
    mov rbx, rcx
    mov r12, rdx
    cmp r12, [rbx + 8]
    jae .rem_bad
    mov r13, r12
.rem_loop:
    mov r14, [rbx + 8]
    dec r14
    cmp r13, r14
    jae .rem_dec
    mov rcx, rbx
    lea rdx, [r13 + 1]
    call array_get
    mov rax, r13
    imul rax, [rbx + 24]
    mov rcx, [rbx]
    mov edx, eax
    xor r8, r8
    mov r9d, FILE_BEGIN
    call qword ptr [rip + pSetFilePointerEx]
    mov rcx, [rbx]
    lea rdx, [rip + array_get_buf]
    mov r8d, dword ptr [rbx + 24]
    lea r9, [rsp + 40]
    mov qword ptr [rsp + 32], 0
    call qword ptr [rip + pWriteFile]
    inc r13
    jmp .rem_loop
.rem_dec:
    dec qword ptr [rbx + 8]
    mov rcx, rbx
    call array_sync_txt
    mov rax, 1
    add rsp, 56
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.rem_bad:
    xor rax, rax
    add rsp, 56
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

array_sort:
    # rcx=array*, rdx=cmp(a,b)->rax. File-backed generic bubble sort.
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 64
    mov rbx, rcx
    mov r15, rdx
    mov r13, [rbx + 8]
    cmp r13, 1
    jbe .sort_done
    xor r12, r12
.sort_outer:
    mov r14, r13
    dec r14
    cmp r12, r14
    jae .sort_done
    xor r11, r11
.sort_inner:
    mov r10, r13
    dec r10
    sub r10, r12
    cmp r11, r10
    jae .sort_next_i
    mov [rsp + 40], r11
    mov rcx, rbx
    mov rdx, r11
    call array_get
    lea rdi, [rip + array_tmp_buf]
    lea rsi, [rip + array_get_buf]
    mov rcx, [rbx + 24]
    cld
    rep movsb
    mov r11, [rsp + 40]
    mov rcx, rbx
    lea rdx, [r11 + 1]
    call array_get
    lea rcx, [rip + array_tmp_buf]
    lea rdx, [rip + array_get_buf]
    call r15
    cmp rax, 0
    jle .sort_no_swap
    mov r11, [rsp + 40]
    # write b to slot j
    mov rax, r11
    imul rax, [rbx + 24]
    mov rcx, [rbx]
    mov edx, eax
    xor r8, r8
    mov r9d, FILE_BEGIN
    call qword ptr [rip + pSetFilePointerEx]
    mov rcx, [rbx]
    lea rdx, [rip + array_get_buf]
    mov r8d, dword ptr [rbx + 24]
    lea r9, [rsp + 56]
    mov qword ptr [rsp + 32], 0
    call qword ptr [rip + pWriteFile]
    # write a to slot j+1
    mov r11, [rsp + 40]
    lea rax, [r11 + 1]
    imul rax, [rbx + 24]
    mov rcx, [rbx]
    mov edx, eax
    xor r8, r8
    mov r9d, FILE_BEGIN
    call qword ptr [rip + pSetFilePointerEx]
    mov rcx, [rbx]
    lea rdx, [rip + array_tmp_buf]
    mov r8d, dword ptr [rbx + 24]
    lea r9, [rsp + 56]
    mov qword ptr [rsp + 32], 0
    call qword ptr [rip + pWriteFile]
.sort_no_swap:
    mov r11, [rsp + 40]
    inc r11
    jmp .sort_inner
.sort_next_i:
    inc r12
    jmp .sort_outer
.sort_done:
    mov rcx, rbx
    call array_sync_txt
    add rsp, 64
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

array_join:
    # rcx=src*, rdx=delim, r8=out. Assumes elements are AsmString structs.
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 104
    mov rbx, rcx
    mov r13, rdx
    mov r14, r8
    lea rcx, [rsp + 32]
    lea rdx, [rip + empty_str]
    call string_from_cstr
    xor r12, r12
.join_loop:
    cmp r12, [rbx + 8]
    jae .join_done
    cmp r12, 0
    je .join_elem
    lea rcx, [rsp + 48]
    lea rdx, [rsp + 32]
    mov r8, r13
    call string_concat
    lea rcx, [rsp + 32]
    call string_free
    lea rcx, [rsp + 32]
    lea rdx, [rsp + 48]
    call string_copy
    lea rcx, [rsp + 48]
    call string_free
.join_elem:
    mov rcx, rbx
    mov rdx, r12
    call array_get
    lea rcx, [rsp + 64]
    lea rdx, [rsp + 32]
    mov r8, qword ptr [rax]
    call string_concat
    lea rcx, [rsp + 32]
    call string_free
    lea rcx, [rsp + 32]
    lea rdx, [rsp + 64]
    call string_copy
    lea rcx, [rsp + 64]
    call string_free
    inc r12
    jmp .join_loop
.join_done:
    mov rcx, r14
    lea rdx, [rsp + 32]
    call string_copy
    lea rcx, [rsp + 32]
    call string_free
    add rsp, 104
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

array_join_int:
    # rcx=src*, rdx=delim, r8=out. Elements are 64-bit ints.
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 120
    mov rbx, rcx
    mov r13, rdx
    mov r14, r8
    lea rcx, [rsp + 32]
    lea rdx, [rip + empty_str]
    call string_from_cstr
    xor r12, r12
.join_int_loop:
    cmp r12, [rbx + 8]
    jae .join_int_done
    cmp r12, 0
    je .join_int_elem
    lea rcx, [rsp + 48]
    lea rdx, [rsp + 32]
    mov r8, r13
    call string_concat
    lea rcx, [rsp + 32]
    call string_free
    lea rcx, [rsp + 32]
    lea rdx, [rsp + 48]
    call string_copy
    lea rcx, [rsp + 48]
    call string_free
.join_int_elem:
    mov rcx, rbx
    mov rdx, r12
    call array_get
    lea rcx, [rsp + 64]
    mov edx, dword ptr [rax]
    call fromInteger
    lea rcx, [rsp + 80]
    lea rdx, [rsp + 32]
    lea r8, [rsp + 64]
    call string_concat
    lea rcx, [rsp + 32]
    call string_free
    lea rcx, [rsp + 32]
    lea rdx, [rsp + 80]
    call string_copy
    lea rcx, [rsp + 80]
    call string_free
    lea rcx, [rsp + 64]
    call string_free
    inc r12
    jmp .join_int_loop
.join_int_done:
    mov rcx, r14
    lea rdx, [rsp + 32]
    call string_copy
    lea rcx, [rsp + 32]
    call string_free
    add rsp, 120
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

array_join_long:
    # rcx=src*, rdx=delim, r8=out. Elements are 64-bit longs.
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 120
    mov rbx, rcx
    mov r13, rdx
    mov r14, r8
    lea rcx, [rsp + 32]
    lea rdx, [rip + empty_str]
    call string_from_cstr
    xor r12, r12
.join_long_loop:
    cmp r12, [rbx + 8]
    jae .join_long_done
    cmp r12, 0
    je .join_long_elem
    lea rcx, [rsp + 48]
    lea rdx, [rsp + 32]
    mov r8, r13
    call string_concat
    lea rcx, [rsp + 32]
    call string_free
    lea rcx, [rsp + 32]
    lea rdx, [rsp + 48]
    call string_copy
    lea rcx, [rsp + 48]
    call string_free
.join_long_elem:
    mov rcx, rbx
    mov rdx, r12
    call array_get
    lea rcx, [rsp + 64]
    mov rdx, qword ptr [rax]
    call fromLong
    lea rcx, [rsp + 80]
    lea rdx, [rsp + 32]
    lea r8, [rsp + 64]
    call string_concat
    lea rcx, [rsp + 32]
    call string_free
    lea rcx, [rsp + 32]
    lea rdx, [rsp + 80]
    call string_copy
    lea rcx, [rsp + 80]
    call string_free
    lea rcx, [rsp + 64]
    call string_free
    inc r12
    jmp .join_long_loop
.join_long_done:
    mov rcx, r14
    lea rdx, [rsp + 32]
    call string_copy
    lea rcx, [rsp + 32]
    call string_free
    add rsp, 120
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

array_join_double:
    # rcx=src*, rdx=delim, r8=out. Elements are doubles.
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 120
    mov rbx, rcx
    mov r13, rdx
    mov r14, r8
    lea rcx, [rsp + 32]
    lea rdx, [rip + empty_str]
    call string_from_cstr
    xor r12, r12
.join_double_loop:
    cmp r12, [rbx + 8]
    jae .join_double_done
    cmp r12, 0
    je .join_double_elem
    lea rcx, [rsp + 48]
    lea rdx, [rsp + 32]
    mov r8, r13
    call string_concat
    lea rcx, [rsp + 32]
    call string_free
    lea rcx, [rsp + 32]
    lea rdx, [rsp + 48]
    call string_copy
    lea rcx, [rsp + 48]
    call string_free
.join_double_elem:
    mov rcx, rbx
    mov rdx, r12
    call array_get
    lea rcx, [rsp + 64]
    movsd xmm1, qword ptr [rax]
    call fromDouble
    lea rcx, [rsp + 80]
    lea rdx, [rsp + 32]
    lea r8, [rsp + 64]
    call string_concat
    lea rcx, [rsp + 32]
    call string_free
    lea rcx, [rsp + 32]
    lea rdx, [rsp + 80]
    call string_copy
    lea rcx, [rsp + 80]
    call string_free
    lea rcx, [rsp + 64]
    call string_free
    inc r12
    jmp .join_double_loop
.join_double_done:
    mov rcx, r14
    lea rdx, [rsp + 32]
    call string_copy
    lea rcx, [rsp + 32]
    call string_free
    add rsp, 120
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

array_join_bool:
    # rcx=src*, rdx=delim, r8=out. Elements are booleans stored as 64-bit ints.
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 120
    mov rbx, rcx
    mov r13, rdx
    mov r14, r8
    lea rcx, [rsp + 32]
    lea rdx, [rip + empty_str]
    call string_from_cstr
    xor r12, r12
.join_bool_loop:
    cmp r12, [rbx + 8]
    jae .join_bool_done
    cmp r12, 0
    je .join_bool_elem
    lea rcx, [rsp + 48]
    lea rdx, [rsp + 32]
    mov r8, r13
    call string_concat
    lea rcx, [rsp + 32]
    call string_free
    lea rcx, [rsp + 32]
    lea rdx, [rsp + 48]
    call string_copy
    lea rcx, [rsp + 48]
    call string_free
.join_bool_elem:
    mov rcx, rbx
    mov rdx, r12
    call array_get
    lea rcx, [rsp + 64]
    mov edx, dword ptr [rax]
    call fromInteger
    lea rcx, [rsp + 80]
    lea rdx, [rsp + 32]
    lea r8, [rsp + 64]
    call string_concat
    lea rcx, [rsp + 32]
    call string_free
    lea rcx, [rsp + 32]
    lea rdx, [rsp + 80]
    call string_copy
    lea rcx, [rsp + 80]
    call string_free
    lea rcx, [rsp + 64]
    call string_free
    inc r12
    jmp .join_bool_loop
.join_bool_done:
    mov rcx, r14
    lea rdx, [rsp + 32]
    call string_copy
    lea rcx, [rsp + 32]
    call string_free
    add rsp, 120
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

array_free:
    # rcx=array*
    push rbx
    push r12
    sub rsp, 152
    mov rbx, rcx
    test rbx, rbx
    jz .free_done
    lea r12, [rsp + 32]
    mov rcx, rbx
    mov rdx, r12
    call array_make_path
    mov rcx, [rbx]
    test rcx, rcx
    jz .delete_file
    sub rsp, 32
    call qword ptr [rip + pCloseHandle]
    add rsp, 32
    mov qword ptr [rbx], 0
    mov qword ptr [rbx + 8], 0
.delete_file:
    mov rcx, r12
    call qword ptr [rip + pDeleteFileA]

    mov qword ptr [rbx], 0
    mov qword ptr [rbx + 8], 0
    mov qword ptr [rbx + 16], 0
    mov qword ptr [rbx + 24], 0

    # Reclaim only the most recently created static-pool array.
    lea rax, [rip + array_pool]
    cmp rbx, rax
    jb .free_done
    lea rdx, [rip + array_pool + 512]
    cmp rbx, rdx
    jae .free_done
    mov rcx, rbx
    sub rcx, rax
    shr rcx, 5
    inc rcx
    lea rdx, [rip + array_pool_next]
    cmp rcx, [rdx]
    jne .free_done
    dec qword ptr [rdx]
.free_done:
    add rsp, 152
    pop r12
    pop rbx
    ret

array_demo:
    sub rsp, 128
    lea rcx, [rsp + 32]
    lea rdx, [rip + alpha]
    call string_from_cstr
    lea rcx, [rsp + 48]
    lea rdx, [rip + bravo]
    call string_from_cstr
    lea rcx, [rsp + 64]
    mov rdx, 2
    mov r8, 16
    call array_init
    lea rcx, [rsp + 64]
    lea rdx, [rsp + 32]
    call array_add
    lea rcx, [rsp + 64]
    lea rdx, [rsp + 48]
    call array_add
    lea rcx, [rip + msg_size]
    call print_cstr
    lea rcx, [rsp + 64]
    call array_size
    mov rcx, rax
    call print_uint
    lea rcx, [rip + msg_nl]
    call print_cstr
    lea rcx, [rsp + 32]
    call string_free
    lea rcx, [rsp + 48]
    call string_free
    lea rcx, [rsp + 64]
    call array_free
    add rsp, 128
    ret
