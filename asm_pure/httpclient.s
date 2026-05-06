.intel_syntax noprefix

.extern bada_sock_init
.extern bada_sock_cleanup
.extern bada_sock_tcp
.extern bada_sock_connect_ipv4
.extern bada_sock_send
.extern bada_sock_recv
.extern bada_sock_close

.global http_client_get

.equ INVALID_SOCKET, -1

.section .data
http_get_prefix: .asciz "GET "
http_get_mid:    .asciz " HTTP/1.0\r\nHost: "
http_get_end:    .asciz "\r\n\r\n"

.section .bss
.align 8
client_req:      .space 2048

.section .text

strlen_c:
    # rcx=cstr -> rax=len
    push rdi
    xor rax, rax
    mov rdi, rcx
    mov rcx, -1
    cld
    repne scasb
    not rcx
    dec rcx
    mov rax, rcx
    pop rdi
    ret

copy_cstr:
    # rcx=dst, rdx=src -> rax=new dst cursor
    push rsi
    push rdi
    mov rdi, rcx
    mov rsi, rdx
.copy_loop:
    mov al, byte ptr [rsi]
    test al, al
    jz .copy_done
    mov byte ptr [rdi], al
    inc rsi
    inc rdi
    jmp .copy_loop
.copy_done:
    mov rax, rdi
    pop rdi
    pop rsi
    ret

http_client_get:
    # rcx=ip cstr, edx=port, r8=path cstr, r9=out buf, [rsp+40]=out cap
    # returns bytes received, or -1 on failure
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 64
    mov r12, rcx              # host/ip
    mov r13d, edx             # port
    mov r14, r8               # path
    mov r15, r9               # out
    mov ebx, dword ptr [rsp + 144] # out cap from caller stack

    call bada_sock_init
    test rax, rax
    jz .client_fail

    call bada_sock_tcp
    cmp rax, INVALID_SOCKET
    je .client_cleanup_fail
    mov [rsp + 40], rax       # socket

    mov rcx, [rsp + 40]
    mov rdx, r12
    mov r8d, r13d
    call bada_sock_connect_ipv4
    test rax, rax
    je .client_close_fail

    lea rcx, [rip + client_req]
    lea rdx, [rip + http_get_prefix]
    call copy_cstr
    mov rcx, rax
    mov rdx, r14
    call copy_cstr
    mov rcx, rax
    lea rdx, [rip + http_get_mid]
    call copy_cstr
    mov rcx, rax
    mov rdx, r12
    call copy_cstr
    mov rcx, rax
    lea rdx, [rip + http_get_end]
    call copy_cstr

    lea rcx, [rip + client_req]
    call strlen_c
    mov r10, rax
    mov rcx, [rsp + 40]
    lea rdx, [rip + client_req]
    mov r8d, r10d
    call bada_sock_send
    cmp rax, -1
    je .client_close_fail

    xor r13, r13              # total bytes
.recv_loop:
    cmp r13, rbx
    jae .recv_done
    mov rax, rbx
    sub rax, r13
    cmp rax, 4096
    jbe .recv_size_ok
    mov rax, 4096
.recv_size_ok:
    mov rcx, [rsp + 40]
    lea rdx, [r15 + r13]
    mov r8d, eax
    call bada_sock_recv
    cmp eax, 0
    jle .recv_done
    add r13d, eax
    jmp .recv_loop

.recv_done:
    mov rcx, [rsp + 40]
    call bada_sock_close
    call bada_sock_cleanup
    mov rax, r13
    add rsp, 64
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.client_close_fail:
    mov rcx, [rsp + 40]
    call bada_sock_close
.client_cleanup_fail:
    call bada_sock_cleanup
.client_fail:
    mov rax, -1
    add rsp, 64
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
