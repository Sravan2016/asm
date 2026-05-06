.intel_syntax noprefix

.extern bada_sock_init
.extern bada_sock_cleanup
.extern bada_sock_tcp
.extern bada_sock_bind_any
.extern bada_sock_listen
.extern bada_sock_accept
.extern bada_sock_recv
.extern bada_sock_send
.extern bada_sock_close

.global http_server_once
.global http_server_forever

.equ INVALID_SOCKET, -1

.section .data
http_resp_head: .asciz "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\n"

.section .bss
.align 8
server_recv_buf: .space 2049

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

http_server_once:
    # ecx=port, rdx=response_body cstr -> rax=1/0
    # Opens a socket, accepts one client, sends a plain text HTTP response, then closes.
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 72
    mov r12d, ecx             # port
    mov r13, rdx              # body

    call bada_sock_init
    test rax, rax
    jz .server_fail

    call bada_sock_tcp
    cmp rax, INVALID_SOCKET
    je .server_cleanup_fail
    mov [rsp + 40], rax       # listen socket

    mov rcx, [rsp + 40]
    mov edx, r12d
    call bada_sock_bind_any
    test rax, rax
    je .server_close_listen_fail

    mov rcx, [rsp + 40]
    call bada_sock_listen
    test rax, rax
    je .server_close_listen_fail

    mov rcx, [rsp + 40]
    call bada_sock_accept
    cmp rax, INVALID_SOCKET
    je .server_close_listen_fail
    mov [rsp + 48], rax       # client socket

    mov rcx, [rsp + 48]
    lea rdx, [rip + server_recv_buf]
    mov r8d, 2048
    call bada_sock_recv       # ignore request contents

    lea rcx, [rip + http_resp_head]
    call strlen_c
    mov r14, rax
    mov rcx, [rsp + 48]
    lea rdx, [rip + http_resp_head]
    mov r8d, r14d
    call bada_sock_send
    cmp rax, -1
    je .server_close_both_fail

    mov rcx, r13
    call strlen_c
    mov r14, rax
    mov rcx, [rsp + 48]
    mov rdx, r13
    mov r8d, r14d
    call bada_sock_send
    cmp rax, -1
    je .server_close_both_fail

    mov rcx, [rsp + 48]
    call bada_sock_close
    mov rcx, [rsp + 40]
    call bada_sock_close
    call bada_sock_cleanup
    mov rax, 1
    add rsp, 72
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.server_close_both_fail:
    mov rcx, [rsp + 48]
    call bada_sock_close
.server_close_listen_fail:
    mov rcx, [rsp + 40]
    call bada_sock_close
.server_cleanup_fail:
    call bada_sock_cleanup
.server_fail:
    xor rax, rax
    add rsp, 72
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

http_server_forever:
    # ecx=port, rdx=response_body cstr, r8=on_request callback(buf, bytes) or 0
    # Keeps the listen socket open. Each client is accepted, read, printed by callback,
    # answered, closed, then the server waits for the next client.
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 80
    mov r12d, ecx             # port
    mov r13, rdx              # body
    mov r15, r8               # callback

    call bada_sock_init
    test rax, rax
    jz .forever_fail

    call bada_sock_tcp
    cmp rax, INVALID_SOCKET
    je .forever_cleanup_fail
    mov [rsp + 40], rax       # listen socket

    mov rcx, [rsp + 40]
    mov edx, r12d
    call bada_sock_bind_any
    test rax, rax
    je .forever_close_listen_fail

    mov rcx, [rsp + 40]
    call bada_sock_listen
    test rax, rax
    je .forever_close_listen_fail

.forever_accept_loop:
    mov rcx, [rsp + 40]
    call bada_sock_accept
    cmp rax, INVALID_SOCKET
    je .forever_accept_loop
    mov [rsp + 48], rax       # client socket

    mov rcx, [rsp + 48]
    lea rdx, [rip + server_recv_buf]
    mov r8d, 2048
    call bada_sock_recv
    mov r14d, eax             # bytes read
    cmp eax, 0
    jle .forever_close_client

    lea r10, [rip + server_recv_buf]
    mov byte ptr [r10 + r14], 0

    test r15, r15
    jz .forever_send_response
    lea rcx, [rip + server_recv_buf]
    mov edx, r14d
    call r15

.forever_send_response:
    lea rcx, [rip + http_resp_head]
    call strlen_c
    mov r14, rax
    mov rcx, [rsp + 48]
    lea rdx, [rip + http_resp_head]
    mov r8d, r14d
    call bada_sock_send
    cmp rax, -1
    je .forever_close_client

    mov rcx, r13
    call strlen_c
    mov r14, rax
    mov rcx, [rsp + 48]
    mov rdx, r13
    mov r8d, r14d
    call bada_sock_send

.forever_close_client:
    mov rcx, [rsp + 48]
    call bada_sock_close
    jmp .forever_accept_loop

.forever_close_listen_fail:
    mov rcx, [rsp + 40]
    call bada_sock_close
.forever_cleanup_fail:
    call bada_sock_cleanup
.forever_fail:
    xor rax, rax
    add rsp, 80
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
