.intel_syntax noprefix

.global double_add
.global double_sub
.global double_mul
.global double_div
.global double_eq
.global double_lt
.global double_gt
.global fromStringToDouble
.global fromIntegerToDouble
.global fromLongToDouble
.global filedouble_create_auto
.global filedouble_get
.global filedouble_set
.global filedouble_free

.extern strtod
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

double_add:
    addsd xmm0, xmm1
    ret

double_sub:
    subsd xmm0, xmm1
    ret

double_mul:
    mulsd xmm0, xmm1
    ret

double_div:
    divsd xmm0, xmm1
    ret

double_eq:
    ucomisd xmm0, xmm1
    sete al
    movzx eax, al
    ret

double_lt:
    ucomisd xmm0, xmm1
    setb al
    movzx eax, al
    ret

double_gt:
    ucomisd xmm0, xmm1
    seta al
    movzx eax, al
    ret

fromStringToDouble:
    # rcx = const char* -> double
    xor rdx, rdx
    sub rsp, 40
    call strtod
    add rsp, 40
    ret

fromIntegerToDouble:
    # ecx = int -> double
    cvtsi2sd xmm0, ecx
    ret

fromLongToDouble:
    # rcx = long long -> double
    cvtsi2sd xmm0, rcx
    ret

filedouble_make_path:
    # rcx=obj, rdx=path buffer
    mov byte ptr [rdx], 'f'
    mov byte ptr [rdx + 1], 'i'
    mov byte ptr [rdx + 2], 'l'
    mov byte ptr [rdx + 3], 'e'
    mov byte ptr [rdx + 4], 'd'
    mov byte ptr [rdx + 5], 'o'
    mov byte ptr [rdx + 6], 'u'
    mov byte ptr [rdx + 7], 'b'
    mov byte ptr [rdx + 8], 'l'
    mov byte ptr [rdx + 9], 'e'
    mov byte ptr [rdx + 10], '_'
    mov rax, rcx
    lea r10, [rip + hex_digits]
    mov r11, 16
    lea r8, [rdx + 11]
.fd_hex_loop:
    rol rax, 4
    mov r9, rax
    and r9, 0x0f
    mov r9b, byte ptr [r10 + r9]
    mov byte ptr [r8], r9b
    inc r8
    dec r11
    jnz .fd_hex_loop
    mov byte ptr [rdx + 27], '.'
    mov byte ptr [rdx + 28], 'b'
    mov byte ptr [rdx + 29], 'i'
    mov byte ptr [rdx + 30], 'n'
    mov byte ptr [rdx + 31], 0
    ret

filedouble_create_auto:
    # rcx=FileDouble*, xmm1=value -> rax=1/0
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 152
    mov rbx, rcx
    movsd qword ptr [rsp + 128], xmm1
    lea r12, [rsp + 32]
    mov rcx, rbx
    mov rdx, r12
    call filedouble_make_path

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
    je .fd_create_fail
    mov [rbx], rax
    mov qword ptr [rbx + 8], 8

    mov rcx, rbx
    movsd xmm1, qword ptr [rsp + 128]
    call filedouble_set
    test rax, rax
    jz .fd_create_fail_close

    mov rax, 1
    add rsp, 152
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.fd_create_fail_close:
    mov rcx, [rbx]
    sub rsp, 32
    call qword ptr [rip + pCloseHandle]
    add rsp, 32
    mov qword ptr [rbx], 0
    mov qword ptr [rbx + 8], 0
.fd_create_fail:
    xor rax, rax
    add rsp, 152
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

filedouble_get:
    # rcx=FileDouble* -> xmm0=value
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
    movsd xmm0, qword ptr [rsp + 48]
    add rsp, 64
    pop rbx
    ret

filedouble_set:
    # rcx=FileDouble*, xmm1=value -> rax=1/0
    push rbx
    sub rsp, 64
    mov rbx, rcx
    movsd qword ptr [rsp + 48], xmm1
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
    jz .fd_set_fail
    mov eax, dword ptr [rsp + 40]
    cmp eax, 8
    jne .fd_set_fail
    mov rax, 1
    add rsp, 64
    pop rbx
    ret
.fd_set_fail:
    xor rax, rax
    add rsp, 64
    pop rbx
    ret

filedouble_free:
    # rcx=FileDouble*
    push rbx
    push r12
    sub rsp, 136
    mov rbx, rcx
    lea r12, [rsp + 32]
    mov rcx, rbx
    mov rdx, r12
    call filedouble_make_path
    mov rcx, [rbx]
    test rcx, rcx
    jz .fd_delete
    sub rsp, 32
    call qword ptr [rip + pCloseHandle]
    add rsp, 32
    mov qword ptr [rbx], 0
    mov qword ptr [rbx + 8], 0
.fd_delete:
    mov rcx, r12
    call qword ptr [rip + pDeleteFileA]
    add rsp, 136
    pop r12
    pop rbx
    ret
