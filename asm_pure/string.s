.intel_syntax noprefix



.global runtime_init
.global string_demo

.global string_from_cstr
.global string_copy
.global string_free
.global string_equals_icase
.global string_length
.global string_char_at
.global string_concat
.global string_contains_char
.global string_contains_sub
.global string_ends_with
.global string_equals
.global string_regex_digits_matches
.global string_regex_digits_nonmatches
.global string_between_symbol
.global string_between_two_symbols
.global string_split
.global string_before_token
.global string_after_token
.global string_trim
.global string_trimall

.global print_cstr
.global print_string
.global print_uint

.global fromInteger
.global fromLong
.global fromDouble

.global filestring_create_auto_from_cstr
.global filestring_create_from_cstr
.global filestring_open
.global filestring_length
.global filestring_char_at
.global filestring_write_at
.global filestring_replace_char_at
.global filestring_replace_char
.global filestring_close
.global filestring_free

.equ STD_OUTPUT_HANDLE, -11
.equ GENERIC_READ, 0x80000000
.equ GENERIC_WRITE, 0x40000000
.equ FILE_SHARE_READ, 1
.equ CREATE_ALWAYS, 2
.equ OPEN_EXISTING, 3
.equ FILE_ATTRIBUTE_NORMAL, 0x00000080
.equ FILE_BEGIN, 0
.equ INVALID_HANDLE_VALUE, -1

.section .data
alpha:     .asciz "alpha"
bravo:     .asciz "bravo"
delta:     .asciz "delta"
ha:        .asciz "ha"
zz:        .asciz "zz"
empty_str: .asciz ""

msg_concat: .asciz "Concat = "
msg_len:    .asciz "Length = "
msg_char:   .asciz "Char at 1 = "
msg_eq:     .asciz "Equals alpha? "
msg_cntc:   .asciz "Contains 'l'? "
msg_cnts:   .asciz "Contains \"ha\"? "
msg_true:   .asciz "true\n"
msg_false:  .asciz "false\n"
msg_nl:     .asciz "\n"
hex_digits: .asciz "0123456789ABCDEF"
const_1e6:  .double 1000000.0
const_0_5:  .double 0.5
.align 16
abs_mask:   .quad 0x7fffffffffffffff, 0x7fffffffffffffff

.section .bss
.align 8
.global stdout_handle
stdout_handle: .quad 0
uint_buf:      .space 32
string_registry: .space 2560  # 64 entries: handle qword + 32-byte path
 .align 8
 .global last_write_at_seek_ret
 .global last_write_at_write_ret
 .global last_write_at_bytes
 .global last_write_at_expected
.global last_write_at_lp_ptr
last_write_at_seek_ret:  .long 0
.align 4
last_write_at_write_ret: .long 0
.align 8
last_write_at_bytes:     .quad 0
.align 8
last_write_at_expected:  .quad 0
.align 8
last_write_at_lp_ptr:    .quad 0
.align 1
tmp_char: .byte 0

# File-backed String/FileString struct: [0]=file handle (qword), [8]=len (qword)

.section .text
.extern pCreateFileA
.extern pReadFile
.extern pSetFilePointerEx
.extern pGetFileSizeEx
.extern pCloseHandle
.extern pDeleteFileA
.extern pGetStdHandle
.extern pWriteFile

strlen_asm:
    # rdx = cstr, returns rax=len
    push rdi
    xor rax, rax
    mov rcx, -1
    mov rdi, rdx
    cld
    repne scasb
    not rcx
    dec rcx
    mov rax, rcx
    pop rdi
    ret

tolower_asm:
    # al = input, returns al
    cmp al, 'A'
    jb 1f
    cmp al, 'Z'
    ja 1f
    add al, 32
1:  ret

ensure_kernel32:
    ret

i64_to_cstr_asm:
    # rcx = signed value, rdx = buffer_end (points to last byte usable, we write NUL at [rdx])
    # returns rax = pointer to start of cstr (within the buffer)
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

double_to_cstr_fixed6_asm:
    # xmm0 = double value, rcx = buffer_base, rdx = buffer_end (NUL written)
    # returns rax = pointer to cstr (buffer_base)
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 32
    mov r12, rcx
    mov r13, rdx

    cvttsd2si r14, xmm0

    movapd xmm1, xmm0
    andpd xmm1, xmmword ptr [rip + abs_mask]

    mov rax, r14
    cvtsi2sd xmm2, rax
    andpd xmm2, xmmword ptr [rip + abs_mask]

    subsd xmm1, xmm2
    mulsd xmm1, qword ptr [rip + const_1e6]
    addsd xmm1, qword ptr [rip + const_0_5]
    cvttsd2si rbx, xmm1

    cmp rbx, 1000000
    jb .dbl_no_carry
    sub rbx, 1000000
    cmp r14, 0
    jl .dbl_carry_neg
    inc r14
    jmp .dbl_no_carry
.dbl_carry_neg:
    dec r14
.dbl_no_carry:

    mov rcx, r14
    mov rdx, r13
    call i64_to_cstr_asm
    mov r8, rax
    mov r9, r12
.dbl_copy_int:
    mov al, byte ptr [r8]
    mov byte ptr [r9], al
    inc r8
    inc r9
    test al, al
    jnz .dbl_copy_int

    dec r9
    mov byte ptr [r9], '.'
    inc r9

    mov r11, r9
    mov rax, rbx
    mov r9d, 6
.dbl_frac_loop:
    xor rdx, rdx
    mov rcx, 10
    div rcx
    add dl, '0'
    mov byte ptr [rsp + r9 - 1], dl
    dec r9
    jnz .dbl_frac_loop

    xor r9d, r9d
.dbl_frac_copy:
    mov al, byte ptr [rsp + r9]
    mov byte ptr [r11 + r9], al
    inc r9
    cmp r9d, 6
    jne .dbl_frac_copy

    mov byte ptr [r11 + 6], 0
    mov rax, r12
    add rsp, 32
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

runtime_init:
    call ensure_kernel32
    mov rax, qword ptr [rip + pGetStdHandle]
    test rax, rax
    jz 1f
    mov rcx, STD_OUTPUT_HANDLE
    sub rsp, 40
    call rax
    add rsp, 40
    lea rdx, [rip + stdout_handle]
    mov qword ptr [rdx], rax
1:
    ret

filestring_make_auto_path:
    # rcx=String*, rdx=path buffer
    mov byte ptr [rdx], 'f'
    mov byte ptr [rdx + 1], 'i'
    mov byte ptr [rdx + 2], 'l'
    mov byte ptr [rdx + 3], 'e'
    mov byte ptr [rdx + 4], 's'
    mov byte ptr [rdx + 5], 't'
    mov byte ptr [rdx + 6], 'r'
    mov byte ptr [rdx + 7], 'i'
    mov byte ptr [rdx + 8], 'n'
    mov byte ptr [rdx + 9], 'g'
    mov byte ptr [rdx + 10], '_'
    mov rax, rcx
    lea r10, [rip + hex_digits]
    mov r11, 16
    lea r8, [rdx + 11]
.make_hex:
    rol rax, 4
    mov r9, rax
    and r9, 0x0f
    mov r9b, byte ptr [r10 + r9]
    mov byte ptr [r8], r9b
    inc r8
    dec r11
    jnz .make_hex
    mov byte ptr [rdx + 27], '.'
    mov byte ptr [rdx + 28], 't'
    mov byte ptr [rdx + 29], 'x'
    mov byte ptr [rdx + 30], 't'
    mov byte ptr [rdx + 31], 0
    ret

string_registry_add:
    # rcx=handle, rdx=path
    push rbx
    push rsi
    push rdi
    mov rbx, rcx
    lea rdi, [rip + string_registry]
    mov r10, 64
.reg_add_loop:
    cmp qword ptr [rdi], 0
    je .reg_add_slot
    add rdi, 40
    dec r10
    jnz .reg_add_loop
    pop rdi
    pop rsi
    pop rbx
    ret
.reg_add_slot:
    mov [rdi], rbx
    lea rdi, [rdi + 8]
    mov rsi, rdx
    mov rcx, 32
    cld
    rep movsb
    pop rdi
    pop rsi
    pop rbx
    ret

string_registry_take:
    # rcx=handle, rdx=out path -> rax=1/0
    push rbx
    push rsi
    push rdi
    mov rbx, rcx
    lea rsi, [rip + string_registry]
    mov r10, 64
.reg_take_loop:
    cmp [rsi], rbx
    je .reg_take_slot
    add rsi, 40
    dec r10
    jnz .reg_take_loop
    xor rax, rax
    pop rdi
    pop rsi
    pop rbx
    ret
.reg_take_slot:
    mov qword ptr [rsi], 0
    lea rsi, [rsi + 8]
    mov rdi, rdx
    mov rcx, 32
    cld
    rep movsb
    mov rax, 1
    pop rdi
    pop rsi
    pop rbx
    ret

filestring_create_auto_from_cstr:
string_from_cstr:
    # rcx=String*, rdx=source cstr -> rax=1/0
    push rbx
    push r12
    sub rsp, 136
    mov rbx, rcx
    mov r12, rdx
    lea rdx, [rsp + 32]
    mov rcx, rbx
    call filestring_make_auto_path
    mov rcx, rbx
    lea rdx, [rsp + 32]
    mov r8, r12
    call filestring_create_from_cstr
    add rsp, 136
    pop r12
    pop rbx
    ret

filestring_create_from_cstr:
    # rcx=String*, rdx=path cstr, r8=source cstr -> rax=1/0
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 72
    mov rbx, rcx
    mov r12, rdx
    mov r13, r8
    mov rdx, r13
    call strlen_asm
    mov r14, rax

    call ensure_kernel32
    mov rcx, r12
    mov rdx, GENERIC_READ
    or rdx, GENERIC_WRITE
    mov r8, FILE_SHARE_READ
    xor r9, r9
    mov qword ptr [rsp + 32], CREATE_ALWAYS
    mov qword ptr [rsp + 40], FILE_ATTRIBUTE_NORMAL
    mov qword ptr [rsp + 48], 0
    call qword ptr [rip + pCreateFileA]
    cmp rax, INVALID_HANDLE_VALUE
    je .create_fail

    mov qword ptr [rbx], rax
    mov qword ptr [rbx + 8], r14
    test r14, r14
    jz .create_ok

    mov rcx, rbx
    xor rdx, rdx
    mov r8, r13
    mov r9, r14
    call filestring_write_at
    test rax, rax
    jnz .create_ok

    mov rcx, [rbx]
    call qword ptr [rip + pCloseHandle]
    mov qword ptr [rbx], 0
    mov qword ptr [rbx + 8], 0
.create_fail:
    xor rax, rax
    add rsp, 72
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.create_ok:
    mov rcx, [rbx]
    mov rdx, r12
    call string_registry_add
    mov rax, 1
    add rsp, 72
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

filestring_open:
    # rcx=String*, rdx=path cstr -> rax=1/0
    push rbx
    push r12
    sub rsp, 56
    mov rbx, rcx
    mov r12, rdx
    call ensure_kernel32
    mov rcx, r12
    mov rdx, GENERIC_READ
    or rdx, GENERIC_WRITE
    mov r8, FILE_SHARE_READ
    xor r9, r9
    mov qword ptr [rsp + 32], OPEN_EXISTING
    mov qword ptr [rsp + 40], FILE_ATTRIBUTE_NORMAL
    mov qword ptr [rsp + 48], 0
    call qword ptr [rip + pCreateFileA]
    cmp rax, INVALID_HANDLE_VALUE
    je .open_fail
    mov [rbx], rax
    mov rcx, [rbx]
    lea rdx, [rsp + 32]
    call qword ptr [rip + pGetFileSizeEx]
    test eax, eax
    jz .open_size_fail
    mov rax, [rsp + 32]
    mov [rbx + 8], rax
    mov rax, 1
    add rsp, 56
    pop r12
    pop rbx
    ret
.open_size_fail:
    mov rcx, [rbx]
    call qword ptr [rip + pCloseHandle]
    mov qword ptr [rbx], 0
    mov qword ptr [rbx + 8], 0
.open_fail:
    xor rax, rax
    add rsp, 56
    pop r12
    pop rbx
    ret

filestring_length:
string_length:
    # rcx=String* -> rax=len
    mov rax, [rcx + 8]
    ret

filestring_char_at:
string_char_at:
    # rcx=String*, rdx=index -> al=char, or 0 on failure
    push rbx
    push r12
    sub rsp, 56
    mov rbx, rcx
    mov r12, rdx
    cmp r12, [rbx + 8]
    jae .char_fail
    call ensure_kernel32
    mov rcx, [rbx]
    mov rdx, r12
    xor r8, r8
    mov r9d, FILE_BEGIN
    call qword ptr [rip + pSetFilePointerEx]
    mov rcx, [rbx]
    lea rdx, [rsp + 47]
    mov r8d, 1
    lea r9, [rsp + 24]
    mov qword ptr [rsp + 32], 0
    call qword ptr [rip + pReadFile]
    test eax, eax
    jz .char_fail
    mov eax, dword ptr [rsp + 24]
    cmp eax, 1
    jne .char_fail
    movzx eax, byte ptr [rsp + 47]
    add rsp, 56
    pop r12
    pop rbx
    ret
.char_fail:
    xor rax, rax
    add rsp, 56
    pop r12
    pop rbx
    ret

filestring_write_at:
    # rcx=String*, rdx=index, r8=buffer, r9=len -> rax=1/0
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 56
    mov rbx, rcx
    mov r12, rdx
    mov r13, r8
    mov r14, r9
    call ensure_kernel32
    mov rcx, [rbx]
    mov rdx, r12
    xor r8, r8
    mov r9d, FILE_BEGIN
    call qword ptr [rip + pSetFilePointerEx]
    mov dword ptr [rip + last_write_at_seek_ret], eax
    mov rcx, [rbx]
    mov rdx, r13
    mov r8d, r14d
    lea r9, [rsp + 24]
    mov qword ptr [rip + last_write_at_lp_ptr], r9
    mov qword ptr [rsp + 32], 0
    call qword ptr [rip + pWriteFile]
    mov dword ptr [rip + last_write_at_write_ret], eax
    test eax, eax
    jz .write_fail
    mov eax, dword ptr [rsp + 24]
    mov qword ptr [rip + last_write_at_bytes], rax
    mov qword ptr [rip + last_write_at_expected], r14
    cmp rax, r14
    jne .write_fail
    mov rax, r12
    add rax, r14
    cmp rax, [rbx + 8]
    jbe .write_ok
    mov [rbx + 8], rax
.write_ok:
    mov rax, 1
    add rsp, 56
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.write_fail:
    xor rax, rax
    add rsp, 56
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

filestring_replace_char_at:
    # rcx=String*, rdx=index, r8b=char -> rax=1/0
    sub rsp, 40
    mov byte ptr [rsp + 39], r8b
    lea r8, [rsp + 39]
    mov r9, 1
    call filestring_write_at
    add rsp, 40
    ret

filestring_replace_char:
    # rcx=String*, rdx=target cstr, r8=replacement cstr -> rax=1/0
    # Replaces every occurrence of target[0] with replacement.
    push rbx
    push r12
    push r13
    push r14
    push r15
    push rsi
    push rdi
    sub rsp, 56
    mov rbx, rcx
    mov r12, rdx
    mov r13, r8
    test rbx, rbx
    jz .replace_fail
    test r12, r12
    jz .replace_fail
    test r13, r13
    jz .replace_fail

    movzx r14d, byte ptr [r12]
    test r14b, r14b
    jz .replace_fail

    mov rdx, r13
    call strlen_asm
    mov r15, rax

    xor rsi, rsi
    xor rdi, rdi
.replace_count_loop:
    cmp rdi, [rbx + 8]
    jae .replace_count_done
    mov rcx, rbx
    mov rdx, rdi
    call filestring_char_at
    cmp al, r14b
    jne .replace_count_next
    inc rsi
.replace_count_next:
    inc rdi
    jmp .replace_count_loop
.replace_count_done:
    test rsi, rsi
    jz .replace_ok

    cmp r15, 0
    je .replace_remove
    cmp r15, 1
    je .replace_single

    mov rax, r15
    dec rax
    imul rax, rsi
    add rax, [rbx + 8]
    mov [rsp + 40], rax
    mov [rsp + 48], rax
    mov rdi, [rbx + 8]
.replace_expand_loop:
    test rdi, rdi
    jz .replace_expand_done
    dec rdi
    mov rcx, rbx
    mov rdx, rdi
    call filestring_char_at
    cmp al, r14b
    je .replace_expand_match
    mov rdx, [rsp + 48]
    dec rdx
    mov rcx, rbx
    mov r8b, al
    call filestring_replace_char_at
    test rax, rax
    jz .replace_fail
    dec qword ptr [rsp + 48]
    jmp .replace_expand_loop
.replace_expand_match:
    mov rax, [rsp + 48]
    sub rax, r15
    mov rcx, rbx
    mov rdx, rax
    mov r8, r13
    mov r9, r15
    call filestring_write_at
    test rax, rax
    jz .replace_fail
    sub qword ptr [rsp + 48], r15
    jmp .replace_expand_loop
.replace_expand_done:
    mov rax, [rsp + 40]
    mov [rbx + 8], rax
    jmp .replace_ok

.replace_single:
    xor rdi, rdi
.replace_single_loop:
    cmp rdi, [rbx + 8]
    jae .replace_ok
    mov rcx, rbx
    mov rdx, rdi
    call filestring_char_at
    cmp al, r14b
    jne .replace_single_next
    movzx r8d, byte ptr [r13]
    mov rcx, rbx
    mov rdx, rdi
    call filestring_replace_char_at
    test rax, rax
    jz .replace_fail
.replace_single_next:
    inc rdi
    jmp .replace_single_loop

.replace_remove:
    xor rdi, rdi
    xor rsi, rsi
.replace_remove_loop:
    cmp rdi, [rbx + 8]
    jae .replace_remove_done
    mov rcx, rbx
    mov rdx, rdi
    call filestring_char_at
    cmp al, r14b
    je .replace_remove_next
    mov rcx, rbx
    mov rdx, rsi
    mov r8b, al
    call filestring_replace_char_at
    test rax, rax
    jz .replace_fail
    inc rsi
.replace_remove_next:
    inc rdi
    jmp .replace_remove_loop
.replace_remove_done:
    mov [rbx + 8], rsi
    jmp .replace_ok

.replace_ok:
    mov rax, 1
    add rsp, 56
    pop rdi
    pop rsi
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.replace_fail:
    xor rax, rax
    add rsp, 56
    pop rdi
    pop rsi
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

string_regex_digits_matches:
    push rbx
    push r12
    push r13
    push r14
    push r15
    push rsi
    push rdi
    sub rsp, 32
    mov rbx, rcx
    mov r12, rdx
    test rbx, rbx
    jz .rdm_fail
    test r12, r12
    jz .rdm_fail

    mov rcx, rbx
    lea rdx, [rip + empty_str]
    call string_from_cstr
    test eax, eax
    jz .rdm_fail

    xor r14d, r14d
    xor r15, r15
.rdm_outer:
    cmp r15, [r12 + 8]
    jae .rdm_ok
    mov rcx, r12
    mov rdx, r15
    call string_char_at
    cmp al, '0'
    jb .rdm_skip_non
    cmp al, '9'
    ja .rdm_skip_non
    test r14d, r14d
    jz .rdm_run
    mov byte ptr [rip + tmp_char], ','
    mov rcx, rbx
    mov rdx, [rbx + 8]
    lea r8, [rip + tmp_char]
    mov r9, 1
    call filestring_write_at
    test eax, eax
    jz .rdm_fail
.rdm_run:
    mov rcx, r12
    mov rdx, r15
    call string_char_at
    cmp al, '0'
    jb .rdm_run_done
    cmp al, '9'
    ja .rdm_run_done
    mov byte ptr [rip + tmp_char], al
    mov rcx, rbx
    mov rdx, [rbx + 8]
    lea r8, [rip + tmp_char]
    mov r9, 1
    call filestring_write_at
    test eax, eax
    jz .rdm_fail
    inc r15
    jmp .rdm_run
.rdm_run_done:
    mov r14d, 1
    jmp .rdm_outer

.rdm_skip_non:
    inc r15
    jmp .rdm_outer

.rdm_ok:
    mov eax, 1
    add rsp, 32
    pop rdi
    pop rsi
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.rdm_fail:
    xor eax, eax
    add rsp, 32
    pop rdi
    pop rsi
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

string_regex_digits_nonmatches:
    push rbx
    push r12
    push r13
    push r14
    push r15
    push rsi
    push rdi
    sub rsp, 32
    mov rbx, rcx
    mov r12, rdx
    test rbx, rbx
    jz .rdn_fail
    test r12, r12
    jz .rdn_fail

    mov rcx, rbx
    lea rdx, [rip + empty_str]
    call string_from_cstr
    test eax, eax
    jz .rdn_fail

    xor r14d, r14d
    xor r15, r15
.rdn_outer:
    cmp r15, [r12 + 8]
    jae .rdn_ok
    mov rcx, r12
    mov rdx, r15
    call string_char_at
    cmp al, '0'
    jb .rdn_nd_run
    cmp al, '9'
    ja .rdn_nd_run
.rdn_skip_digits:
    inc r15
    cmp r15, [r12 + 8]
    jae .rdn_outer
    mov rcx, r12
    mov rdx, r15
    call string_char_at
    cmp al, '0'
    jb .rdn_outer
    cmp al, '9'
    jbe .rdn_skip_digits
    jmp .rdn_outer

.rdn_nd_run:
    test r14d, r14d
    jz .rdn_nd_loop
    mov byte ptr [rip + tmp_char], ','
    mov rcx, rbx
    mov rdx, [rbx + 8]
    lea r8, [rip + tmp_char]
    mov r9, 1
    call filestring_write_at
    test eax, eax
    jz .rdn_fail
.rdn_nd_loop:
    mov rcx, r12
    mov rdx, r15
    call string_char_at
    cmp al, '0'
    jb .rdn_nd_emit
    cmp al, '9'
    jbe .rdn_nd_done
.rdn_nd_emit:
    mov byte ptr [rip + tmp_char], al
    mov rcx, rbx
    mov rdx, [rbx + 8]
    lea r8, [rip + tmp_char]
    mov r9, 1
    call filestring_write_at
    test eax, eax
    jz .rdn_fail
    inc r15
    cmp r15, [r12 + 8]
    jae .rdn_nd_done2
    mov rcx, r12
    mov rdx, r15
    call string_char_at
    cmp al, '0'
    jb .rdn_nd_loop
    cmp al, '9'
    ja .rdn_nd_loop
.rdn_nd_done:
    mov r14d, 1
    jmp .rdn_outer
.rdn_nd_done2:
    mov r14d, 1
    jmp .rdn_ok

.rdn_ok:
    mov eax, 1
    add rsp, 32
    pop rdi
    pop rsi
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.rdn_fail:
    xor eax, eax
    add rsp, 32
    pop rdi
    pop rsi
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

string_between_symbol:
    mov r9, r8
    jmp string_between_two_symbols

string_between_two_symbols:
    push rbx
    push r12
    push r13
    push r14
    push r15
    push rsi
    push rdi
    sub rsp, 64
    mov rbx, rcx
    mov r12, rdx
    mov r13, r8
    mov r14, r9
    test rbx, rbx
    jz .sb2_fail
    test r12, r12
    jz .sb2_fail
    test r13, r13
    jz .sb2_fail
    test r14, r14
    jz .sb2_fail
    mov r15, [r13 + 8]
    mov [rsp + 0], r15
    test r15, r15
    jz .sb2_fail
    mov rax, [r14 + 8]
    mov [rsp + 8], rax
    test rax, rax
    jz .sb2_fail

    mov rcx, rbx
    lea rdx, [rip + empty_str]
    call string_from_cstr
    test eax, eax
    jz .sb2_fail

    mov rax, [r12 + 8]
    cmp rax, r15
    jb .sb2_fail
    sub rax, r15
    mov [rsp + 16], rax
    xor rdi, rdi
.sb2_find_start:
    cmp rdi, qword ptr [rsp + 16]
    ja .sb2_fail
    xor rsi, rsi
.sb2_start_cmp:
    cmp rsi, qword ptr [rsp + 0]
    jae .sb2_start_found
    mov rax, rdi
    add rax, rsi
    mov rcx, r12
    mov rdx, rax
    call string_char_at
    mov byte ptr [rip + tmp_char], al
    mov rcx, r13
    mov rdx, rsi
    call string_char_at
    cmp al, byte ptr [rip + tmp_char]
    jne .sb2_start_next
    inc rsi
    jmp .sb2_start_cmp
.sb2_start_next:
    inc rdi
    jmp .sb2_find_start
.sb2_start_found:
    mov rax, rdi
    add rax, qword ptr [rsp + 0]
    mov [rsp + 32], rax

    mov rax, [r12 + 8]
    mov rcx, qword ptr [rsp + 8]
    cmp rax, rcx
    jb .sb2_fail
    sub rax, rcx
    mov [rsp + 24], rax
    mov rdi, qword ptr [rsp + 32]
.sb2_find_end:
    cmp rdi, qword ptr [rsp + 24]
    ja .sb2_fail
    xor rsi, rsi
.sb2_end_cmp:
    cmp rsi, qword ptr [rsp + 8]
    jae .sb2_have_end
    mov rax, rdi
    add rax, rsi
    mov rcx, r12
    mov rdx, rax
    call string_char_at
    mov byte ptr [rip + tmp_char], al
    mov rcx, r14
    mov rdx, rsi
    call string_char_at
    cmp al, byte ptr [rip + tmp_char]
    jne .sb2_end_next
    inc rsi
    jmp .sb2_end_cmp
.sb2_end_next:
    inc rdi
    jmp .sb2_find_end
.sb2_have_end:
    mov [rsp + 40], rdi

    mov rdi, qword ptr [rsp + 32]
.sb2_copy:
    cmp rdi, qword ptr [rsp + 40]
    jae .sb2_ok
    mov rcx, r12
    mov rdx, rdi
    call string_char_at
    mov byte ptr [rip + tmp_char], al
    mov rcx, rbx
    mov rdx, [rbx + 8]
    lea r8, [rip + tmp_char]
    mov r9, 1
    call filestring_write_at
    test eax, eax
    jz .sb2_fail
    inc rdi
    jmp .sb2_copy

.sb2_ok:
    mov eax, 1
    add rsp, 64
    pop rdi
    pop rsi
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.sb2_fail:
    xor eax, eax
    add rsp, 64
    pop rdi
    pop rsi
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

string_split:
    push rbx
    push r12
    push r13
    push r14
    push r15
    push rsi
    push rdi
    sub rsp, 64
    mov rbx, rcx
    mov r12, rdx
    mov r13, r8
    test rbx, rbx
    jz .spl_fail
    test r12, r12
    jz .spl_fail
    test r13, r13
    jz .spl_fail
    mov r14, [r12 + 8]
    mov r15, [r13 + 8]
    test r15, r15
    jz .spl_fail

    mov rcx, rbx
    lea rdx, [rip + empty_str]
    call string_from_cstr
    test eax, eax
    jz .spl_fail

    xor rdi, rdi
    xor rsi, rsi
    mov dword ptr [rsp + 0], 1

    cmp r14, r15
    jb .spl_emit_last
    mov rax, r14
    sub rax, r15
    mov [rsp + 8], rax

.spl_scan:
    cmp rdi, qword ptr [rsp + 8]
    ja .spl_emit_last
    xor r10, r10
.spl_cmp:
    cmp r10, r15
    jae .spl_found
    mov rax, rdi
    add rax, r10
    mov rcx, r12
    mov rdx, rax
    mov [rsp + 24], r10
    call string_char_at
    mov r10, [rsp + 24]
    mov byte ptr [rip + tmp_char], al
    mov rcx, r13
    mov rdx, r10
    mov [rsp + 24], r10
    call string_char_at
    mov r10, [rsp + 24]
    cmp al, byte ptr [rip + tmp_char]
    jne .spl_next
    inc r10
    jmp .spl_cmp

.spl_found:
    mov [rsp + 16], rdi
    mov eax, dword ptr [rsp + 0]
    test eax, eax
    jnz .spl_copy_token
    mov byte ptr [rip + tmp_char], ','
    mov rcx, rbx
    mov rdx, [rbx + 8]
    lea r8, [rip + tmp_char]
    mov r9, 1
    call filestring_write_at
    test eax, eax
    jz .spl_fail
.spl_copy_token:
    mov dword ptr [rsp + 0], 0
    mov r11, rsi
.spl_tok_loop:
    cmp r11, qword ptr [rsp + 16]
    jae .spl_tok_done
    mov rcx, r12
    mov rdx, r11
    mov [rsp + 24], r11
    call string_char_at
    mov r11, [rsp + 24]
    mov byte ptr [rip + tmp_char], al
    mov rcx, rbx
    mov rdx, [rbx + 8]
    lea r8, [rip + tmp_char]
    mov r9, 1
    mov [rsp + 24], r11
    call filestring_write_at
    mov r11, [rsp + 24]
    test eax, eax
    jz .spl_fail
    inc r11
    jmp .spl_tok_loop
.spl_tok_done:
    add rdi, r15
    mov rsi, rdi
    jmp .spl_scan

.spl_next:
    inc rdi
    jmp .spl_scan

.spl_emit_last:
    mov eax, dword ptr [rsp + 0]
    test eax, eax
    jnz .spl_last_copy
    mov byte ptr [rip + tmp_char], ','
    mov rcx, rbx
    mov rdx, [rbx + 8]
    lea r8, [rip + tmp_char]
    mov r9, 1
    call filestring_write_at
    test eax, eax
    jz .spl_fail
.spl_last_copy:
    mov r11, rsi
.spl_last_loop:
    cmp r11, r14
    jae .spl_ok
    mov rcx, r12
    mov rdx, r11
    mov [rsp + 24], r11
    call string_char_at
    mov r11, [rsp + 24]
    mov byte ptr [rip + tmp_char], al
    mov rcx, rbx
    mov rdx, [rbx + 8]
    lea r8, [rip + tmp_char]
    mov r9, 1
    mov [rsp + 24], r11
    call filestring_write_at
    mov r11, [rsp + 24]
    test eax, eax
    jz .spl_fail
    inc r11
    jmp .spl_last_loop

.spl_ok:
    mov eax, 1
    add rsp, 64
    pop rdi
    pop rsi
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.spl_fail:
    xor eax, eax
    add rsp, 64
    pop rdi
    pop rsi
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

string_before_token:
    push rbx
    push r12
    push r13
    push r14
    push r15
    push rsi
    push rdi
    sub rsp, 32
    mov rbx, rcx
    mov r12, rdx
    mov r13, r8
    test rbx, rbx
    jz .sbt_fail
    test r12, r12
    jz .sbt_fail
    test r13, r13
    jz .sbt_fail

    mov r14, [r12 + 8]
    mov r15, [r13 + 8]
    test r15, r15
    jz .sbt_fail
    cmp r14, r15
    jb .sbt_fail

    mov rcx, rbx
    lea rdx, [rip + empty_str]
    call string_from_cstr
    test eax, eax
    jz .sbt_fail

    mov rax, r14
    sub rax, r15
    mov [rsp + 0], rax
    xor rdi, rdi
.sbt_outer:
    cmp rdi, qword ptr [rsp + 0]
    ja .sbt_fail
    xor rsi, rsi
.sbt_inner:
    cmp rsi, r15
    jae .sbt_found
    mov rax, rdi
    add rax, rsi
    mov rcx, r12
    mov rdx, rax
    call string_char_at
    mov byte ptr [rip + tmp_char], al
    mov rcx, r13
    mov rdx, rsi
    call string_char_at
    cmp al, byte ptr [rip + tmp_char]
    jne .sbt_next
    inc rsi
    jmp .sbt_inner
.sbt_next:
    inc rdi
    jmp .sbt_outer

.sbt_found:
    xor rsi, rsi
.sbt_copy:
    cmp rsi, rdi
    jae .sbt_ok
    mov rcx, r12
    mov rdx, rsi
    call string_char_at
    mov byte ptr [rip + tmp_char], al
    mov rcx, rbx
    mov rdx, [rbx + 8]
    lea r8, [rip + tmp_char]
    mov r9, 1
    call filestring_write_at
    test eax, eax
    jz .sbt_fail
    inc rsi
    jmp .sbt_copy

.sbt_ok:
    mov eax, 1
    add rsp, 32
    pop rdi
    pop rsi
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.sbt_fail:
    xor eax, eax
    add rsp, 32
    pop rdi
    pop rsi
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

string_after_token:
    push rbx
    push r12
    push r13
    push r14
    push r15
    push rsi
    push rdi
    sub rsp, 32
    mov rbx, rcx
    mov r12, rdx
    mov r13, r8
    test rbx, rbx
    jz .sat_fail
    test r12, r12
    jz .sat_fail
    test r13, r13
    jz .sat_fail

    mov r14, [r12 + 8]
    mov r15, [r13 + 8]
    test r15, r15
    jz .sat_fail
    cmp r14, r15
    jb .sat_fail

    mov rcx, rbx
    lea rdx, [rip + empty_str]
    call string_from_cstr
    test eax, eax
    jz .sat_fail

    mov rax, r14
    sub rax, r15
    mov [rsp + 0], rax
    xor rdi, rdi
.sat_outer:
    cmp rdi, qword ptr [rsp + 0]
    ja .sat_fail
    xor rsi, rsi
.sat_inner:
    cmp rsi, r15
    jae .sat_found
    mov rax, rdi
    add rax, rsi
    mov rcx, r12
    mov rdx, rax
    call string_char_at
    mov byte ptr [rip + tmp_char], al
    mov rcx, r13
    mov rdx, rsi
    call string_char_at
    cmp al, byte ptr [rip + tmp_char]
    jne .sat_next
    inc rsi
    jmp .sat_inner
.sat_next:
    inc rdi
    jmp .sat_outer

.sat_found:
    mov rsi, rdi
    add rsi, r15
.sat_copy:
    cmp rsi, r14
    jae .sat_ok
    mov rcx, r12
    mov rdx, rsi
    call string_char_at
    mov byte ptr [rip + tmp_char], al
    mov rcx, rbx
    mov rdx, [rbx + 8]
    lea r8, [rip + tmp_char]
    mov r9, 1
    call filestring_write_at
    test eax, eax
    jz .sat_fail
    inc rsi
    jmp .sat_copy

.sat_ok:
    mov eax, 1
    add rsp, 32
    pop rdi
    pop rsi
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.sat_fail:
    xor eax, eax
    add rsp, 32
    pop rdi
    pop rsi
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

string_trim:
    push rbx
    push r12
    push r13
    push r14
    push r15
    push rsi
    push rdi
    sub rsp, 64
    mov rbx, rcx
    mov r12, rdx
    test rbx, rbx
    jz .trim_fail
    test r12, r12
    jz .trim_fail

    mov rcx, rbx
    lea rdx, [rip + empty_str]
    call string_from_cstr
    test eax, eax
    jz .trim_fail

    mov r14, [r12 + 8]
    xor r13, r13
.trim_left:
    cmp r13, r14
    jae .trim_done_bounds
    mov rcx, r12
    mov rdx, r13
    mov [rsp + 0], r13
    call string_char_at
    mov r13, [rsp + 0]
    cmp al, ' '
    je .trim_left_inc
    cmp al, 9
    je .trim_left_inc
    cmp al, 10
    je .trim_left_inc
    cmp al, 13
    je .trim_left_inc
    jmp .trim_right_init
.trim_left_inc:
    inc r13
    jmp .trim_left

.trim_right_init:
    mov r15, r14
.trim_right:
    cmp r15, r13
    jbe .trim_done_bounds
    mov rax, r15
    dec rax
    mov rcx, r12
    mov rdx, rax
    mov [rsp + 8], r15
    mov [rsp + 16], r13
    call string_char_at
    mov r15, [rsp + 8]
    mov r13, [rsp + 16]
    cmp al, ' '
    je .trim_right_dec
    cmp al, 9
    je .trim_right_dec
    cmp al, 10
    je .trim_right_dec
    cmp al, 13
    je .trim_right_dec
    jmp .trim_done_bounds
.trim_right_dec:
    dec r15
    jmp .trim_right

.trim_done_bounds:
    mov rsi, r13
.trim_copy:
    cmp rsi, r15
    jae .trim_ok
    mov rcx, r12
    mov rdx, rsi
    mov [rsp + 24], rsi
    call string_char_at
    mov rsi, [rsp + 24]
    mov byte ptr [rip + tmp_char], al
    mov rcx, rbx
    mov rdx, [rbx + 8]
    lea r8, [rip + tmp_char]
    mov r9, 1
    mov [rsp + 24], rsi
    call filestring_write_at
    mov rsi, [rsp + 24]
    test eax, eax
    jz .trim_fail
    inc rsi
    jmp .trim_copy

.trim_ok:
    mov eax, 1
    add rsp, 64
    pop rdi
    pop rsi
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.trim_fail:
    xor eax, eax
    add rsp, 64
    pop rdi
    pop rsi
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

string_trimall:
    push rbx
    push r12
    push r13
    push r14
    push r15
    push rsi
    push rdi
    sub rsp, 64
    mov rbx, rcx
    mov r12, rdx
    test rbx, rbx
    jz .tall_fail
    test r12, r12
    jz .tall_fail

    mov rcx, rbx
    lea rdx, [rip + empty_str]
    call string_from_cstr
    test eax, eax
    jz .tall_fail

    mov r14, [r12 + 8]
    xor r13, r13
.tall_loop:
    cmp r13, r14
    jae .tall_ok
    mov rcx, r12
    mov rdx, r13
    call string_char_at
    cmp al, ' '
    je .tall_next
    cmp al, 9
    je .tall_next
    cmp al, 10
    je .tall_next
    cmp al, 13
    je .tall_next

    mov byte ptr [rip + tmp_char], al
    mov rcx, rbx
    mov rdx, [rbx + 8]
    lea r8, [rip + tmp_char]
    mov r9, 1
    call filestring_write_at
    test eax, eax
    jz .tall_fail

.tall_next:
    inc r13
    jmp .tall_loop

.tall_ok:
    mov eax, 1
    add rsp, 64
    pop rdi
    pop rsi
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.tall_fail:
    xor eax, eax
    add rsp, 64
    pop rdi
    pop rsi
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

filestring_close:
    # rcx=String*
    push rbx
    mov rbx, rcx
    mov rcx, [rbx]
    test rcx, rcx
    jz .close_done
    sub rsp, 32
    call ensure_kernel32
    mov rcx, [rbx]
    call qword ptr [rip + pCloseHandle]
    add rsp, 32
    mov qword ptr [rbx], 0
    mov qword ptr [rbx + 8], 0
.close_done:
    pop rbx
    ret

filestring_free:
string_free:
    # rcx=String*. Closes handle and deletes this object's auto backing file.
    push rbx
    push r12
    sub rsp, 136
    mov rbx, rcx
    lea r12, [rsp + 32]
    mov rcx, [rbx]
    mov rdx, r12
    call string_registry_take
    test rax, rax
    jnz .free_have_path
    mov rcx, rbx
    mov rdx, r12
    call filestring_make_auto_path
.free_have_path:
    mov rcx, rbx
    call filestring_close
    mov rcx, r12
    call ensure_kernel32
    mov rcx, r12
    call qword ptr [rip + pDeleteFileA]
    add rsp, 136
    pop r12
    pop rbx
    ret

string_copy:
    # rcx=dst, rdx=src
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 56
    mov rbx, rcx
    mov r12, rdx
    mov [rsp + 48], r12
    lea rdx, [rip + msg_nl + 1] # empty cstr
    call string_from_cstr
    mov r12, [rsp + 48]
    mov r13, [r12 + 8]
    mov qword ptr [rbx + 8], r13
    xor r14, r14
.copy_loop:
    cmp r14, r13
    jae .copy_done
    mov rcx, r12
    mov rdx, r14
    call string_char_at
    mov rcx, rbx
    mov rdx, r14
    mov r8b, al
    call filestring_replace_char_at
    inc r14
    jmp .copy_loop
.copy_done:
    add rsp, 56
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

string_concat:
    # rcx=dst, rdx=a, r8=b
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 80
    mov rbx, rcx
    mov [rsp + 64], rdx
    mov [rsp + 72], r8
    lea rdx, [rip + msg_nl + 1]
    call string_from_cstr
    mov r12, [rsp + 64]
    mov r13, [rsp + 72]
    mov r14, [r12 + 8]
    mov r15, [r13 + 8]
    mov rax, r14
    add rax, r15
    mov [rbx + 8], rax
    xor rax, rax
    mov [rsp + 48], rax
.concat_a:
    mov rax, [rsp + 48]
    cmp rax, r14
    jae .concat_b_start
    mov rcx, r12
    mov rdx, rax
    call string_char_at
    mov rcx, rbx
    mov rdx, [rsp + 48]
    mov r8b, al
    call filestring_replace_char_at
    mov rax, [rsp + 48]
    inc rax
    mov [rsp + 48], rax
    jmp .concat_a
.concat_b_start:
    xor rax, rax
    mov [rsp + 48], rax
.concat_b:
    mov rax, [rsp + 48]
    cmp rax, r15
    jae .concat_done
    mov rcx, r13
    mov rdx, rax
    call string_char_at
    mov rcx, rbx
    mov rdx, r14
    add rdx, [rsp + 48]
    mov r8b, al
    call filestring_replace_char_at
    mov rax, [rsp + 48]
    inc rax
    mov [rsp + 48], rax
    jmp .concat_b
.concat_done:
    add rsp, 80
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

string_equals:
    # rcx=a, rdx=b -> rax=1/0
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 40
    mov rbx, rcx
    mov r12, rdx
    mov r13, [rbx + 8]
    cmp r13, [r12 + 8]
    jne .eq_no
    xor r14, r14
.eq_loop:
    cmp r14, r13
    jae .eq_yes
    mov rcx, rbx
    mov rdx, r14
    call string_char_at
    mov byte ptr [rsp + 39], al
    mov rcx, r12
    mov rdx, r14
    call string_char_at
    cmp al, byte ptr [rsp + 39]
    jne .eq_no
    inc r14
    jmp .eq_loop
.eq_yes:
    mov rax, 1
    add rsp, 40
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.eq_no:
    xor rax, rax
    add rsp, 40
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

string_equals_icase:
    # rcx=a, rdx=b -> rax=1/0
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 40
    mov rbx, rcx
    mov r12, rdx
    mov r13, [rbx + 8]
    cmp r13, [r12 + 8]
    jne .ieq_no
    xor r14, r14
.ieq_loop:
    cmp r14, r13
    jae .ieq_yes
    mov rcx, rbx
    mov rdx, r14
    call string_char_at
    call tolower_asm
    mov byte ptr [rsp + 39], al
    mov rcx, r12
    mov rdx, r14
    call string_char_at
    call tolower_asm
    cmp al, byte ptr [rsp + 39]
    jne .ieq_no
    inc r14
    jmp .ieq_loop
.ieq_yes:
    mov rax, 1
    add rsp, 40
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.ieq_no:
    xor rax, rax
    add rsp, 40
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

string_contains_char:
    # rcx=String*, dl=char -> rax=1/0
    push rbx
    push r12
    push r13
    sub rsp, 32
    mov rbx, rcx
    mov r13b, dl
    xor r12, r12
.cc_loop:
    cmp r12, [rbx + 8]
    jae .cc_no
    mov rcx, rbx
    mov rdx, r12
    call string_char_at
    cmp al, r13b
    je .cc_yes
    inc r12
    jmp .cc_loop
.cc_yes:
    mov rax, 1
    add rsp, 32
    pop r13
    pop r12
    pop rbx
    ret
.cc_no:
    xor rax, rax
    add rsp, 32
    pop r13
    pop r12
    pop rbx
    ret

string_contains_sub:
    # rcx=hay, rdx=needle -> rax=1/0
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 48
    mov rbx, rcx
    mov r12, rdx
    mov r13, [rbx + 8]
    mov r14, [r12 + 8]
    test r14, r14
    jz .sub_yes
    cmp r14, r13
    ja .sub_no
    xor r15, r15
.sub_outer:
    mov rax, r13
    sub rax, r14
    cmp r15, rax
    ja .sub_no
    xor r10, r10
.sub_inner:
    cmp r10, r14
    jae .sub_yes
    mov [rsp + 40], r10
    mov rcx, rbx
    lea rdx, [r15 + r10]
    call string_char_at
    mov byte ptr [rsp + 39], al
    mov r10, [rsp + 40]
    mov rcx, r12
    mov rdx, r10
    call string_char_at
    cmp al, byte ptr [rsp + 39]
    jne .sub_next
    mov r10, [rsp + 40]
    inc r10
    jmp .sub_inner
.sub_next:
    inc r15
    jmp .sub_outer
.sub_yes:
    mov rax, 1
    add rsp, 48
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.sub_no:
    xor rax, rax
    add rsp, 48
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

string_ends_with:
    # rcx=hay cstr, rdx=needle cstr -> rax=1/0
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 32
    mov rbx, rcx
    mov r12, rdx

    mov rdx, rbx
    call strlen_asm
    mov r13, rax

    mov rdx, r12
    call strlen_asm
    mov r14, rax

    test r14, r14
    jz .ew_yes
    cmp r14, r13
    ja .ew_no
    sub r13, r14
    xor r10, r10
.ew_loop:
    cmp r10, r14
    jae .ew_yes
    lea r11, [rbx + r13]
    mov al, byte ptr [r11 + r10]
    cmp al, byte ptr [r12 + r10]
    jne .ew_no
    inc r10
    jmp .ew_loop
.ew_yes:
    mov rax, 1
    add rsp, 32
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.ew_no:
    xor rax, rax
    add rsp, 32
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

write_buf:
    # rcx=buf, rdx=len
    push rbx
    push r12
    mov rbx, rcx
    mov r12, rdx
    sub rsp, 56
    call ensure_kernel32
    lea rax, [rip + stdout_handle]
    mov rcx, [rax]
    mov rdx, rbx
    mov r8, r12
    lea r9, [rsp + 40]
    mov qword ptr [rsp + 32], 0
    mov rax, qword ptr [rip + pWriteFile]
    test rax, rax
    jz 1f
    call rax
1:
    add rsp, 56
    pop r12
    pop rbx
    ret

print_cstr:
    # rcx=ptr
    mov r11, rcx
    mov rdx, r11
    call strlen_asm
    mov rdx, rax
    mov rcx, r11
    call write_buf
    ret

print_string:
    # rcx=String*
    push rbx
    push r12
    sub rsp, 40
    mov rbx, rcx
    xor r12, r12
.ps_loop:
    cmp r12, [rbx + 8]
    jae .ps_done
    mov rcx, rbx
    mov rdx, r12
    call string_char_at
    mov byte ptr [rsp + 39], al
    lea rcx, [rsp + 39]
    mov rdx, 1
    call write_buf
    inc r12
    jmp .ps_loop
.ps_done:
    add rsp, 40
    pop r12
    pop rbx
    ret

print_uint:
    # rcx=value
    mov rax, rcx
    lea r10, [rip + uint_buf + 31]
    mov byte ptr [r10], 0
    cmp rax, 0
    jne .loop_uint
    dec r10
    mov byte ptr [r10], '0'
    jmp .out_uint
.loop_uint:
    xor rdx, rdx
    mov rcx, 10
    div rcx
    add dl, '0'
    dec r10
    mov byte ptr [r10], dl
    test rax, rax
    jnz .loop_uint
.out_uint:
    mov rcx, r10
    call print_cstr
    ret

fromInteger:
    # rcx = String*, edx = int value
    push rbx
    push r12
    sub rsp, 136
    mov rbx, rcx
    movsxd rax, edx
    mov rcx, rax
    lea rdx, [rsp + 71]
    call i64_to_cstr_asm
    mov rdx, rax
    mov rcx, rbx
    call string_from_cstr
    add rsp, 136
    pop r12
    pop rbx
    ret

fromLong:
    # rcx = String*, rdx = long long value
    push rbx
    push r12
    sub rsp, 136
    mov rbx, rcx
    mov rcx, rdx
    lea rdx, [rsp + 71]
    call i64_to_cstr_asm
    mov rdx, rax
    mov rcx, rbx
    call string_from_cstr
    add rsp, 136
    pop r12
    pop rbx
    ret

fromDouble:
    # rcx = String*, xmm1 = double value
    push rbx
    sub rsp, 112
    mov rbx, rcx
    movapd xmm0, xmm1
    mov rcx, rbx
    lea rcx, [rsp + 40]
    lea rdx, [rsp + 103]
    call double_to_cstr_fixed6_asm
    mov rdx, rax
    mov rcx, rbx
    call string_from_cstr
    add rsp, 112
    pop rbx
    ret

string_demo:
    sub rsp, 112
    lea rcx, [rsp + 32]
    lea rdx, [rip + alpha]
    call string_from_cstr
    lea rcx, [rsp + 48]
    lea rdx, [rip + bravo]
    call string_from_cstr

    lea rcx, [rip + msg_concat]
    call print_cstr
    lea rcx, [rsp + 64]
    lea rdx, [rsp + 32]
    lea r8, [rsp + 48]
    call string_concat
    lea rcx, [rsp + 64]
    call print_string
    lea rcx, [rip + msg_nl]
    call print_cstr

    lea rcx, [rsp + 32]
    call string_free
    lea rcx, [rsp + 48]
    call string_free
    lea rcx, [rsp + 64]
    call string_free
    add rsp, 112
    ret
