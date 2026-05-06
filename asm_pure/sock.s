.intel_syntax noprefix

.extern WSAStartup
.extern WSACleanup
.extern socket
.extern bind
.extern listen
.extern accept
.extern connect
.extern send
.extern recv
.extern closesocket
.extern inet_addr
.extern htons

.global bada_sock_init
.global bada_sock_cleanup
.global bada_sock_tcp
.global bada_sock_bind_any
.global bada_sock_listen
.global bada_sock_accept
.global bada_sock_connect_ipv4
.global bada_sock_send
.global bada_sock_recv
.global bada_sock_close

.equ AF_INET, 2
.equ SOCK_STREAM, 1
.equ IPPROTO_TCP, 6
.equ INVALID_SOCKET, -1
.equ SOCKET_ERROR, -1
.equ SOMAXCONN, 0x7fffffff
.equ INADDR_ANY, 0

.section .bss
.align 8
sock_wsa:      .space 512
sock_addr:     .space 16

.section .text

bada_sock_init:
    sub rsp, 40
    mov ecx, 0x0202
    lea rdx, [rip + sock_wsa]
    call WSAStartup
    test eax, eax
    setz al
    movzx eax, al
    add rsp, 40
    ret

bada_sock_cleanup:
    sub rsp, 40
    call WSACleanup
    add rsp, 40
    ret

bada_sock_tcp:
    sub rsp, 40
    mov ecx, AF_INET
    mov edx, SOCK_STREAM
    mov r8d, IPPROTO_TCP
    call socket
    add rsp, 40
    ret

bada_sock_bind_any:
    # rcx=sock, edx=port -> rax=1/0
    push rbx
    sub rsp, 40
    mov rbx, rcx
    mov ecx, edx
    call htons
    lea r10, [rip + sock_addr]
    mov word ptr [r10], AF_INET
    mov word ptr [r10 + 2], ax
    mov dword ptr [r10 + 4], INADDR_ANY
    mov qword ptr [r10 + 8], 0
    mov rcx, rbx
    lea rdx, [rip + sock_addr]
    mov r8d, 16
    call bind
    cmp eax, SOCKET_ERROR
    setne al
    movzx eax, al
    add rsp, 40
    pop rbx
    ret

bada_sock_listen:
    # rcx=sock -> rax=1/0
    sub rsp, 40
    mov edx, SOMAXCONN
    call listen
    cmp eax, SOCKET_ERROR
    setne al
    movzx eax, al
    add rsp, 40
    ret

bada_sock_accept:
    # rcx=sock -> rax=client sock
    sub rsp, 40
    xor rdx, rdx
    xor r8, r8
    call accept
    add rsp, 40
    ret

bada_sock_connect_ipv4:
    # rcx=sock, rdx=ip cstr, r8d=port -> rax=1/0
    push rbx
    push r12
    sub rsp, 40
    mov rbx, rcx
    mov r12, rdx
    mov ecx, r8d
    call htons
    lea r10, [rip + sock_addr]
    mov word ptr [r10], AF_INET
    mov word ptr [r10 + 2], ax
    mov rcx, r12
    call inet_addr
    lea r10, [rip + sock_addr]
    mov dword ptr [r10 + 4], eax
    mov qword ptr [r10 + 8], 0
    mov rcx, rbx
    lea rdx, [rip + sock_addr]
    mov r8d, 16
    call connect
    cmp eax, SOCKET_ERROR
    setne al
    movzx eax, al
    add rsp, 40
    pop r12
    pop rbx
    ret

bada_sock_send:
    # rcx=sock, rdx=buf, r8=len -> rax=bytes or -1
    sub rsp, 40
    xor r9d, r9d
    call send
    add rsp, 40
    ret

bada_sock_recv:
    # rcx=sock, rdx=buf, r8=len -> rax=bytes or -1
    sub rsp, 40
    xor r9d, r9d
    call recv
    add rsp, 40
    ret

bada_sock_close:
    # rcx=sock
    sub rsp, 40
    call closesocket
    add rsp, 40
    ret
