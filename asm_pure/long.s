.intel_syntax noprefix

.global long_add
.global long_sub
.global long_mul
.global long_div
.global long_mod
.global long_eq
.global long_lt
.global long_gt
.global fromStringToLong
.global fromIntegerToLong
.global fromDoubleToLong
.global filelong_create_auto
.global filelong_get
.global filelong_set
.global filelong_free

.extern strtoll
.extern pCreateFileA
.extern pReadFile
.extern pWriteFile
.extern pSetFilePointerEx
.extern pCloseHandle
.extern pDeleteFileA

.equ GENERIC_READ, 0x80000000
.equ GENERIC_WRITE, 0x40000000
.equ FILE_SHARE_READ, 1
.equ CREATE_ALWAYS, 2
.equ FILE_ATTRIBUTE_NORMAL, 0x00000080
.equ FILE_BEGIN, 0
.equ INVALID_HANDLE_VALUE, -1

.section .data
hex_digits: .asciz "0123456789ABCDEF"

.section .text

long_add:
    mov rax, rcx
    add rax, rdx
    ret

long_sub:
    mov rax, rcx
    sub rax, rdx
    ret

long_mul:
    mov rax, rcx
    imul rax, rdx
    ret

long_div:
    mov r8, rdx
    mov rax, rcx
    cqo
    idiv r8
    ret

long_mod:
    mov r8, rdx
    mov rax, rcx
    cqo
    idiv r8
    mov rax, rdx
    ret

long_eq:
    cmp rcx, rdx
    sete al
    movzx eax, al
    ret

long_lt:
    cmp rcx, rdx
    setl al
    movzx eax, al
    ret

long_gt:
    cmp rcx, rdx
    setg al
    movzx eax, al
    ret

fromStringToLong:
    # rcx = const char* -> long long
    xor rdx, rdx
    mov r8d, 10
    sub rsp, 40
    call strtoll
    add rsp, 40
    ret

fromIntegerToLong:
    # rcx = int -> long long
    movsxd rax, ecx
    ret

fromDoubleToLong:
    # xmm0 = double -> long long
    cvttsd2si rax, xmm0
    ret

filelong_make_path:
    # rcx=obj, rdx=path buffer
    mov byte ptr [rdx], 'f'
    mov byte ptr [rdx + 1], 'i'
    mov byte ptr [rdx + 2], 'l'
    mov byte ptr [rdx + 3], 'e'
    mov byte ptr [rdx + 4], 'l'
    mov byte ptr [rdx + 5], 'o'
    mov byte ptr [rdx + 6], 'n'
    mov byte ptr [rdx + 7], 'g'
    mov byte ptr [rdx + 8], '_'
    mov rax, rcx
    lea r10, [rip + hex_digits]
    mov r11, 16
    lea r8, [rdx + 9]
.fl_hex_loop:
    rol rax, 4
    mov r9, rax
    and r9, 0x0f
    mov r9b, byte ptr [r10 + r9]
    mov byte ptr [r8], r9b
    inc r8
    dec r11
    jnz .fl_hex_loop
    mov byte ptr [rdx + 25], '.'
    mov byte ptr [rdx + 26], 'b'
    mov byte ptr [rdx + 27], 'i'
    mov byte ptr [rdx + 28], 'n'
    mov byte ptr [rdx + 29], 0
    ret

filelong_create_auto:
    # rcx=FileLong*, rdx=value -> rax=1/0
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 136
    mov rbx, rcx
    mov r13, rdx
    lea r12, [rsp + 32]
    mov rcx, rbx
    mov rdx, r12
    call filelong_make_path

    mov rcx, r12
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
    je .fl_create_fail
    mov [rbx], rax
    mov qword ptr [rbx + 8], 8

    mov rcx, rbx
    mov rdx, r13
    call filelong_set
    test rax, rax
    jz .fl_create_fail_close

    mov rax, 1
    add rsp, 136
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.fl_create_fail_close:
    mov rcx, [rbx]
    sub rsp, 32
    call qword ptr [rip + pCloseHandle]
    add rsp, 32
    mov qword ptr [rbx], 0
    mov qword ptr [rbx + 8], 0
.fl_create_fail:
    xor rax, rax
    add rsp, 136
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

filelong_get:
    # rcx=FileLong* -> rax=value
    push rbx
    sub rsp, 64
    mov rbx, rcx
    mov rcx, [rbx]
    xor edx, edx
    xor r8, r8
    mov r9d, FILE_BEGIN
    call qword ptr [rip + pSetFilePointerEx]
    mov rcx, [rbx]
    lea rdx, [rsp + 48]
    mov r8d, 8
    lea r9, [rsp + 40]
    mov qword ptr [rsp + 32], 0
    call qword ptr [rip + pReadFile]
    mov rax, qword ptr [rsp + 48]
    add rsp, 64
    pop rbx
    ret

filelong_set:
    # rcx=FileLong*, rdx=value -> rax=1/0
    push rbx
    sub rsp, 64
    mov rbx, rcx
    mov qword ptr [rsp + 48], rdx
    mov rcx, [rbx]
    xor edx, edx
    xor r8, r8
    mov r9d, FILE_BEGIN
    call qword ptr [rip + pSetFilePointerEx]
    mov rcx, [rbx]
    lea rdx, [rsp + 48]
    mov r8d, 8
    lea r9, [rsp + 40]
    mov qword ptr [rsp + 32], 0
    call qword ptr [rip + pWriteFile]
    test eax, eax
    jz .fl_set_fail
    mov eax, dword ptr [rsp + 40]
    cmp eax, 8
    jne .fl_set_fail
    mov rax, 1
    add rsp, 64
    pop rbx
    ret
.fl_set_fail:
    xor rax, rax
    add rsp, 64
    pop rbx
    ret

filelong_free:
    # rcx=FileLong*
    push rbx
    push r12
    sub rsp, 136
    mov rbx, rcx
    lea r12, [rsp + 32]
    mov rcx, rbx
    mov rdx, r12
    call filelong_make_path
    mov rcx, [rbx]
    test rcx, rcx
    jz .fl_delete
    sub rsp, 32
    call qword ptr [rip + pCloseHandle]
    add rsp, 32
    mov qword ptr [rbx], 0
    mov qword ptr [rbx + 8], 0
.fl_delete:
    mov rcx, r12
    call qword ptr [rip + pDeleteFileA]
    add rsp, 136
    pop r12
    pop rbx
    ret
