.intel_syntax noprefix

.global bool_not
.global bool_and
.global bool_or
.global bool_xor
.global bool_eq
.global fromStringToBoolean
.global fromIntegerToBoolean
.global fromLongToBoolean
.global fromDoubleToBoolean
.global filebool_create_auto
.global filebool_get
.global filebool_set
.global filebool_free

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

bool_not:
    # int a -> int
    test ecx, ecx
    sete al
    movzx eax, al
    ret

bool_and:
    # int a, int b -> int
    test ecx, ecx
    setne al
    test edx, edx
    setne dl
    and al, dl
    movzx eax, al
    ret

bool_or:
    test ecx, ecx
    setne al
    test edx, edx
    setne dl
    or al, dl
    movzx eax, al
    ret

bool_xor:
    test ecx, ecx
    setne al
    test edx, edx
    setne dl
    xor al, dl
    movzx eax, al
    ret

bool_eq:
    cmp ecx, edx
    sete al
    movzx eax, al
    ret

fromStringToBoolean:
    # rcx = const char* -> int (yes/no)
    mov al, byte ptr [rcx]
    cmp al, 'y'
    je .yes
    cmp al, 'Y'
    je .yes
    cmp al, 'n'
    je .no
    cmp al, 'N'
    je .no
    xor eax, eax
    ret
.yes:
    mov eax, 1
    ret
.no:
    xor eax, eax
    ret

fromIntegerToBoolean:
    # ecx = int -> int (1 if >0)
    cmp ecx, 0
    setg al
    movzx eax, al
    ret

fromLongToBoolean:
    # rcx = long long -> int (1 if >0)
    cmp rcx, 0
    setg al
    movzx eax, al
    ret

fromDoubleToBoolean:
    # xmm0 = double -> int (1 if >0.0)
    xorpd xmm1, xmm1
    ucomisd xmm0, xmm1
    seta al
    movzx eax, al
    ret

filebool_make_path:
    # rcx=obj, rdx=path buffer
    mov byte ptr [rdx], 'f'
    mov byte ptr [rdx + 1], 'i'
    mov byte ptr [rdx + 2], 'l'
    mov byte ptr [rdx + 3], 'e'
    mov byte ptr [rdx + 4], 'b'
    mov byte ptr [rdx + 5], 'o'
    mov byte ptr [rdx + 6], 'o'
    mov byte ptr [rdx + 7], 'l'
    mov byte ptr [rdx + 8], '_'
    mov rax, rcx
    lea r10, [rip + hex_digits]
    mov r11, 16
    lea r8, [rdx + 9]
.fb_hex_loop:
    rol rax, 4
    mov r9, rax
    and r9, 0x0f
    mov r9b, byte ptr [r10 + r9]
    mov byte ptr [r8], r9b
    inc r8
    dec r11
    jnz .fb_hex_loop
    mov byte ptr [rdx + 25], '.'
    mov byte ptr [rdx + 26], 'b'
    mov byte ptr [rdx + 27], 'i'
    mov byte ptr [rdx + 28], 'n'
    mov byte ptr [rdx + 29], 0
    ret

filebool_create_auto:
    # rcx=FileBool*, edx=value -> rax=1/0
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 136
    mov rbx, rcx
    test edx, edx
    setne r13b
    movzx r13d, r13b
    lea r12, [rsp + 32]
    mov rcx, rbx
    mov rdx, r12
    call filebool_make_path

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
    je .fb_create_fail
    mov [rbx], rax
    mov qword ptr [rbx + 8], 1

    mov rcx, rbx
    mov edx, r13d
    call filebool_set
    test rax, rax
    jz .fb_create_fail_close

    mov rax, 1
    add rsp, 136
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.fb_create_fail_close:
    mov rcx, [rbx]
    sub rsp, 32
    call qword ptr [rip + pCloseHandle]
    add rsp, 32
    mov qword ptr [rbx], 0
    mov qword ptr [rbx + 8], 0
.fb_create_fail:
    xor rax, rax
    add rsp, 136
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

filebool_get:
    # rcx=FileBool* -> eax=0/1
    push rbx
    sub rsp, 64
    mov rbx, rcx
    mov rcx, [rbx]
    xor edx, edx
    xor r8, r8
    mov r9d, FILE_BEGIN
    call qword ptr [rip + pSetFilePointerEx]
    mov rcx, [rbx]
    lea rdx, [rsp + 47]
    mov r8d, 1
    lea r9, [rsp + 40]
    mov qword ptr [rsp + 32], 0
    call qword ptr [rip + pReadFile]
    movzx eax, byte ptr [rsp + 47]
    test eax, eax
    setne al
    movzx eax, al
    add rsp, 64
    pop rbx
    ret

filebool_set:
    # rcx=FileBool*, edx=value -> rax=1/0
    push rbx
    sub rsp, 64
    mov rbx, rcx
    test edx, edx
    setne al
    mov byte ptr [rsp + 47], al
    mov rcx, [rbx]
    xor edx, edx
    xor r8, r8
    mov r9d, FILE_BEGIN
    call qword ptr [rip + pSetFilePointerEx]
    mov rcx, [rbx]
    lea rdx, [rsp + 47]
    mov r8d, 1
    lea r9, [rsp + 40]
    mov qword ptr [rsp + 32], 0
    call qword ptr [rip + pWriteFile]
    test eax, eax
    jz .fb_set_fail
    mov eax, dword ptr [rsp + 40]
    cmp eax, 1
    jne .fb_set_fail
    mov rax, 1
    add rsp, 64
    pop rbx
    ret
.fb_set_fail:
    xor rax, rax
    add rsp, 64
    pop rbx
    ret

filebool_free:
    # rcx=FileBool*
    push rbx
    push r12
    sub rsp, 136
    mov rbx, rcx
    lea r12, [rsp + 32]
    mov rcx, rbx
    mov rdx, r12
    call filebool_make_path
    mov rcx, [rbx]
    test rcx, rcx
    jz .fb_delete
    sub rsp, 32
    call qword ptr [rip + pCloseHandle]
    add rsp, 32
    mov qword ptr [rbx], 0
    mov qword ptr [rbx + 8], 0
.fb_delete:
    mov rcx, r12
    call qword ptr [rip + pDeleteFileA]
    add rsp, 136
    pop r12
    pop rbx
    ret
