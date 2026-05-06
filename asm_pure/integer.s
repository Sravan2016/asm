.intel_syntax noprefix

.global int_add
.global int_sub
.global int_mul
.global int_div
.global int_mod
.global int_eq
.global int_lt
.global int_gt
.global fromStringToInteger
.global fromLongToInteger
.global fromDoubleToInteger
.global fileint_create_auto
.global fileint_get
.global fileint_set
.global fileint_free

.extern strtol
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

int_add:
    # int a, int b -> int
    mov eax, ecx
    add eax, edx
    ret

int_sub:
    mov eax, ecx
    sub eax, edx
    ret

int_mul:
    mov eax, ecx
    imul eax, edx
    ret

int_div:
    # signed divide a / b
    mov r8d, edx
    mov eax, ecx
    cdq
    idiv r8d
    ret

int_mod:
    # signed a % b
    mov r8d, edx
    mov eax, ecx
    cdq
    idiv r8d
    mov eax, edx
    ret

int_eq:
    cmp ecx, edx
    sete al
    movzx eax, al
    ret

int_lt:
    cmp ecx, edx
    setl al
    movzx eax, al
    ret

int_gt:
    cmp ecx, edx
    setg al
    movzx eax, al
    ret

fromStringToInteger:
    # rcx = const char* -> int
    xor rdx, rdx
    mov r8d, 10
    sub rsp, 40
    call strtol
    add rsp, 40
    ret

fromLongToInteger:
    # rcx = long long -> int
    mov eax, ecx
    ret

fromDoubleToInteger:
    # xmm0 = double -> int
    cvttsd2si eax, xmm0
    ret

fileint_make_path:
    # rcx=obj, rdx=path buffer
    mov byte ptr [rdx], 'f'
    mov byte ptr [rdx + 1], 'i'
    mov byte ptr [rdx + 2], 'l'
    mov byte ptr [rdx + 3], 'e'
    mov byte ptr [rdx + 4], 'i'
    mov byte ptr [rdx + 5], 'n'
    mov byte ptr [rdx + 6], 't'
    mov byte ptr [rdx + 7], '_'
    mov rax, rcx
    lea r10, [rip + hex_digits]
    mov r11, 16
    lea r8, [rdx + 8]
.fi_hex_loop:
    rol rax, 4
    mov r9, rax
    and r9, 0x0f
    mov r9b, byte ptr [r10 + r9]
    mov byte ptr [r8], r9b
    inc r8
    dec r11
    jnz .fi_hex_loop
    mov byte ptr [rdx + 24], '.'
    mov byte ptr [rdx + 25], 'b'
    mov byte ptr [rdx + 26], 'i'
    mov byte ptr [rdx + 27], 'n'
    mov byte ptr [rdx + 28], 0
    ret

fileint_create_auto:
    # rcx=FileInt*, edx=value -> rax=1/0
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 136
    mov rbx, rcx
    mov r13d, edx
    lea r12, [rsp + 32]
    mov rcx, rbx
    mov rdx, r12
    call fileint_make_path

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
    je .fi_create_fail
    mov [rbx], rax
    mov qword ptr [rbx + 8], 4

    mov rcx, rbx
    mov edx, r13d
    call fileint_set
    test rax, rax
    jz .fi_create_fail_close

    mov rax, 1
    add rsp, 136
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.fi_create_fail_close:
    mov rcx, [rbx]
    sub rsp, 32
    call qword ptr [rip + pCloseHandle]
    add rsp, 32
    mov qword ptr [rbx], 0
    mov qword ptr [rbx + 8], 0
.fi_create_fail:
    xor rax, rax
    add rsp, 136
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

fileint_get:
    # rcx=FileInt* -> eax=value
    push rbx
    sub rsp, 64
    mov rbx, rcx
    mov rcx, [rbx]
    xor edx, edx
    xor r8, r8
    mov r9d, FILE_BEGIN
    call qword ptr [rip + pSetFilePointerEx]
    mov rcx, [rbx]
    lea rdx, [rsp + 44]
    mov r8d, 4
    lea r9, [rsp + 40]
    mov qword ptr [rsp + 32], 0
    call qword ptr [rip + pReadFile]
    mov eax, dword ptr [rsp + 44]
    add rsp, 64
    pop rbx
    ret

fileint_set:
    # rcx=FileInt*, edx=value -> rax=1/0
    push rbx
    sub rsp, 64
    mov rbx, rcx
    mov dword ptr [rsp + 44], edx
    mov rcx, [rbx]
    xor edx, edx
    xor r8, r8
    mov r9d, FILE_BEGIN
    call qword ptr [rip + pSetFilePointerEx]
    mov rcx, [rbx]
    lea rdx, [rsp + 44]
    mov r8d, 4
    lea r9, [rsp + 40]
    mov qword ptr [rsp + 32], 0
    call qword ptr [rip + pWriteFile]
    test eax, eax
    jz .fi_set_fail
    mov eax, dword ptr [rsp + 40]
    cmp eax, 4
    jne .fi_set_fail
    mov rax, 1
    add rsp, 64
    pop rbx
    ret
.fi_set_fail:
    xor rax, rax
    add rsp, 64
    pop rbx
    ret

fileint_free:
    # rcx=FileInt*
    push rbx
    push r12
    sub rsp, 136
    mov rbx, rcx
    lea r12, [rsp + 32]
    mov rcx, rbx
    mov rdx, r12
    call fileint_make_path
    mov rcx, [rbx]
    test rcx, rcx
    jz .fi_delete
    sub rsp, 32
    call qword ptr [rip + pCloseHandle]
    add rsp, 32
    mov qword ptr [rbx], 0
    mov qword ptr [rbx + 8], 0
.fi_delete:
    mov rcx, r12
    call qword ptr [rip + pDeleteFileA]
    add rsp, 136
    pop r12
    pop rbx
    ret
