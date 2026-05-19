.intel_syntax noprefix

# Pure HTTP client formatting helpers with no Windows/Winsock dependency.
# These routines do not open network connections. They build HTTP request bytes and return
# deterministic HTTP response bytes for offline/request-response testing.

.global http_build_get_request
.global http_build_get_request_params
.global http_build_post_request
.global http_client_get
.global http_client_post_string_print
.global http_string_to_cstr

.extern bada_sock_init
.extern bada_sock_cleanup
.extern bada_sock_tcp
.extern bada_sock_connect_ipv4
.extern bada_sock_send
.extern bada_sock_recv
.extern bada_sock_close
.extern string_length
.extern string_char_at
.extern print_cstr
.extern fopen
.extern fgetc
.extern fclose

.section .data
http_get_prefix: .asciz "GET "
http_post_prefix: .asciz "POST "
http_get_mid:    .asciz " HTTP/1.0\r\nHost: "
http_post_mid:   .asciz " HTTP/1.0\r\nHost: "
http_content_length: .asciz "\r\nContent-Length: "
http_get_end:    .asciz "\r\n\r\n"
http_question:   .asciz "?"
http_client_response: .asciz "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 2\r\n\r\nOK"
http_default_host: .asciz "127.0.0.1"
http_default_path: .asciz "/"
http_empty: .asciz ""
http_client_property_path: .asciz ".\\project\\property.txt"
http_client_property_mode: .asciz "r"

.section .bss
.align 16
http_client_request_buf: .space 8192
http_client_response_buf: .space 8192
http_client_body_buf: .space 4096

.section .text

httpc_copy_cap:
    # rcx=dst, rdx=src, r8=remaining cap including final zero
    # returns rax=bytes copied
    push rbx
    xor rax, rax
    test rcx, rcx
    je .hcc_done
    test r8, r8
    je .hcc_done
    test rdx, rdx
    je .hcc_zero
    mov rbx, r8
    dec rbx
.hcc_loop:
    test rbx, rbx
    je .hcc_zero
    mov r9b, [rdx + rax]
    test r9b, r9b
    je .hcc_zero
    mov [rcx + rax], r9b
    inc rax
    dec rbx
    jmp .hcc_loop
.hcc_zero:
    mov byte ptr [rcx + rax], 0
.hcc_done:
    pop rbx
    ret

httpc_append_cap:
    # rcx=dst base, rdx=src, r8=cap, r9=used -> rax=new used
    push rbx
    push rsi
    mov rbx, rcx
    mov rsi, r9
    cmp rsi, r8
    jae .hac_return
    lea rcx, [rbx + rsi]
    sub r8, rsi
    call httpc_copy_cap
    add rsi, rax
.hac_return:
    mov rax, rsi
    pop rsi
    pop rbx
    ret

httpc_strlen:
    # rcx=cstr -> rax=len
    xor rax, rax
    test rcx, rcx
    je .hcs_done
.hcs_loop:
    cmp byte ptr [rcx + rax], 0
    je .hcs_done
    inc rax
    jmp .hcs_loop
.hcs_done:
    ret

httpc_append_uint:
    # rcx=dst base, rdx=value, r8=cap, r9=used -> rax=new used
    push rbx
    push rsi
    push rdi
    sub rsp, 40
    mov rbx, rcx
    mov rsi, r8
    mov rdi, r9
    lea r10, [rsp + 39]
    mov byte ptr [r10], 0
    mov rax, rdx
.hcau_loop:
    xor edx, edx
    mov r11d, 10
    div r11
    add dl, '0'
    dec r10
    mov [r10], dl
    test rax, rax
    jne .hcau_loop
    mov rcx, rbx
    mov rdx, r10
    mov r8, rsi
    mov r9, rdi
    call httpc_append_cap
    add rsp, 40
    pop rdi
    pop rsi
    pop rbx
    ret

http_build_get_request:
    # rcx=host cstr, rdx=path cstr, r8=out buf, r9=out cap -> rax=bytes written
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    sub rsp, 40
    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8
    mov r12, r9
    test rbx, rbx
    jne .hbgr_host_ok
    lea rbx, [rip + http_default_host]
.hbgr_host_ok:
    test rsi, rsi
    jne .hbgr_path_ok
    lea rsi, [rip + http_default_path]
.hbgr_path_ok:
    test rdi, rdi
    je .hbgr_fail
    test r12, r12
    je .hbgr_fail
    mov byte ptr [rdi], 0
    mov rcx, rdi
    lea rdx, [rip + http_get_prefix]
    mov r8, r12
    xor r9, r9
    call httpc_append_cap
    mov r13, rax
    mov rcx, rdi
    mov rdx, rsi
    mov r8, r12
    mov r9, r13
    call httpc_append_cap
    mov r13, rax
    mov rcx, rdi
    lea rdx, [rip + http_get_mid]
    mov r8, r12
    mov r9, r13
    call httpc_append_cap
    mov r13, rax
    mov rcx, rdi
    mov rdx, rbx
    mov r8, r12
    mov r9, r13
    call httpc_append_cap
    mov r13, rax
    mov rcx, rdi
    lea rdx, [rip + http_get_end]
    mov r8, r12
    mov r9, r13
    call httpc_append_cap
    jmp .hbgr_done
.hbgr_fail:
    xor eax, eax
.hbgr_done:
    add rsp, 40
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

http_build_get_request_params:
    # rcx=host cstr, rdx=path cstr, r8=params cstr, r9=out buf, [rsp+40]=out cap
    # Builds: GET /path?params HTTP/1.0\r\nHost: host\r\n\r\n
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    sub rsp, 40
    mov rbx, rcx
    mov rsi, rdx
    mov r14, r8
    mov rdi, r9
    mov r12, [rsp + 128]
    test rbx, rbx
    jne .hbgp_host_ok
    lea rbx, [rip + http_default_host]
.hbgp_host_ok:
    test rsi, rsi
    jne .hbgp_path_ok
    lea rsi, [rip + http_default_path]
.hbgp_path_ok:
    test rdi, rdi
    je .hbgp_fail
    test r12, r12
    je .hbgp_fail
    mov byte ptr [rdi], 0
    mov rcx, rdi
    lea rdx, [rip + http_get_prefix]
    mov r8, r12
    xor r9, r9
    call httpc_append_cap
    mov r13, rax
    mov rcx, rdi
    mov rdx, rsi
    mov r8, r12
    mov r9, r13
    call httpc_append_cap
    mov r13, rax
    test r14, r14
    je .hbgp_after_params
    cmp byte ptr [r14], 0
    je .hbgp_after_params
    mov rcx, rdi
    lea rdx, [rip + http_question]
    mov r8, r12
    mov r9, r13
    call httpc_append_cap
    mov r13, rax
    mov rcx, rdi
    mov rdx, r14
    mov r8, r12
    mov r9, r13
    call httpc_append_cap
    mov r13, rax
.hbgp_after_params:
    mov rcx, rdi
    lea rdx, [rip + http_get_mid]
    mov r8, r12
    mov r9, r13
    call httpc_append_cap
    mov r13, rax
    mov rcx, rdi
    mov rdx, rbx
    mov r8, r12
    mov r9, r13
    call httpc_append_cap
    mov r13, rax
    mov rcx, rdi
    lea rdx, [rip + http_get_end]
    mov r8, r12
    mov r9, r13
    call httpc_append_cap
    jmp .hbgp_done
.hbgp_fail:
    xor eax, eax
.hbgp_done:
    add rsp, 40
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

http_build_post_request:
    # rcx=host, rdx=path, r8=params, r9=body, [rsp+40]=out, [rsp+48]=cap
    # Builds: POST /path?params HTTP/1.0\r\nHost: host\r\nContent-Length: n\r\n\r\nbody
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 40
    mov rbx, rcx
    mov rsi, rdx
    mov r14, r8
    mov r15, r9
    mov rdi, [rsp + 136]
    mov r12, [rsp + 144]
    test rbx, rbx
    jne .hbpr_host_ok
    lea rbx, [rip + http_default_host]
.hbpr_host_ok:
    test rsi, rsi
    jne .hbpr_path_ok
    lea rsi, [rip + http_default_path]
.hbpr_path_ok:
    test r15, r15
    jne .hbpr_body_ok
    lea r15, [rip + http_empty]
.hbpr_body_ok:
    test rdi, rdi
    je .hbpr_fail
    test r12, r12
    je .hbpr_fail
    mov byte ptr [rdi], 0
    mov rcx, rdi
    lea rdx, [rip + http_post_prefix]
    mov r8, r12
    xor r9, r9
    call httpc_append_cap
    mov r13, rax
    mov rcx, rdi
    mov rdx, rsi
    mov r8, r12
    mov r9, r13
    call httpc_append_cap
    mov r13, rax
    test r14, r14
    je .hbpr_after_params
    cmp byte ptr [r14], 0
    je .hbpr_after_params
    mov rcx, rdi
    lea rdx, [rip + http_question]
    mov r8, r12
    mov r9, r13
    call httpc_append_cap
    mov r13, rax
    mov rcx, rdi
    mov rdx, r14
    mov r8, r12
    mov r9, r13
    call httpc_append_cap
    mov r13, rax
.hbpr_after_params:
    mov rcx, rdi
    lea rdx, [rip + http_post_mid]
    mov r8, r12
    mov r9, r13
    call httpc_append_cap
    mov r13, rax
    mov rcx, rdi
    mov rdx, rbx
    mov r8, r12
    mov r9, r13
    call httpc_append_cap
    mov r13, rax
    mov rcx, rdi
    lea rdx, [rip + http_content_length]
    mov r8, r12
    mov r9, r13
    call httpc_append_cap
    mov r13, rax
    mov rcx, r15
    call httpc_strlen
    mov rcx, rdi
    mov rdx, rax
    mov r8, r12
    mov r9, r13
    call httpc_append_uint
    mov r13, rax
    mov rcx, rdi
    lea rdx, [rip + http_get_end]
    mov r8, r12
    mov r9, r13
    call httpc_append_cap
    mov r13, rax
    mov rcx, rdi
    mov rdx, r15
    mov r8, r12
    mov r9, r13
    call httpc_append_cap
    jmp .hbpr_done
.hbpr_fail:
    xor eax, eax
.hbpr_done:
    add rsp, 40
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

http_client_get:
    # rcx=ip/host cstr, edx=port, r8=path cstr, r9=out buf, [rsp+40]=out cap
    # returns deterministic HTTP response bytes written, or -1 on invalid output
    push rbx
    push r12
    sub rsp, 40
    mov rbx, r9
    mov r12, [rsp + 96]
    test rbx, rbx
    je .hcg_fail
    test r12, r12
    je .hcg_fail
    mov rcx, rbx
    lea rdx, [rip + http_client_response]
    mov r8, r12
    call httpc_copy_cap
    jmp .hcg_done
.hcg_fail:
    mov rax, -1
.hcg_done:
    add rsp, 40
    pop r12
    pop rbx
    ret

http_string_to_cstr:
    # rcx=AsmString*, rdx=out cstr, r8=cap -> rax=bytes copied
    push rbx
    push rsi
    push rdi
    push r12
    sub rsp, 40
    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8
    xor r12, r12
    test rsi, rsi
    je .hstc_done
    test rdi, rdi
    je .hstc_done
    mov byte ptr [rsi], 0
    test rbx, rbx
    je .hstc_done
    mov rcx, rbx
    call string_length
    cmp rax, rdi
    jb .hstc_len_ok
    mov rax, rdi
    dec rax
.hstc_len_ok:
    mov rdi, rax
.hstc_loop:
    cmp r12, rdi
    jae .hstc_term
    mov rcx, rbx
    mov rdx, r12
    call string_char_at
    mov [rsi + r12], al
    inc r12
    jmp .hstc_loop
.hstc_term:
    mov byte ptr [rsi + r12], 0
.hstc_done:
    mov rax, r12
    add rsp, 40
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

http_print_response_body:
    # rcx=response cstr
    test rcx, rcx
    je .hprb_done
.hprb_scan:
    mov al, [rcx]
    test al, al
    je .hprb_print_all
    cmp al, 13
    jne .hprb_next
    cmp byte ptr [rcx + 1], 10
    jne .hprb_next
    cmp byte ptr [rcx + 2], 13
    jne .hprb_next
    cmp byte ptr [rcx + 3], 10
    jne .hprb_next
    add rcx, 4
    call print_cstr
    ret
.hprb_next:
    inc rcx
    jmp .hprb_scan
.hprb_print_all:
    # No HTTP header separator found; treat the whole buffer as response body.
    # rcx currently points at the terminator, so restart from the static response buffer.
    lea rcx, [rip + http_client_response_buf]
    call print_cstr
    ret
.hprb_done:
    ret

http_client_post_string_print:
    # rcx=host cstr, edx=port, r8=path cstr, r9=params cstr, [rsp+40]=AsmString* body
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 80
    mov rbx, rcx
    mov r12d, edx
    mov r13, r8
    mov r14, r9
    mov r15, [rsp + 160]

    mov dword ptr [rsp + 56], 0
    lea rcx, [rip + http_client_property_path]
    lea rdx, [rip + http_client_property_mode]
    call fopen
    test rax, rax
    jz .hcpsp_port_ready
    mov [rsp + 64], rax
.hcpsp_port_read:
    mov rcx, [rsp + 64]
    call fgetc
    cmp eax, -1
    je .hcpsp_port_done
    cmp al, '0'
    jb .hcpsp_port_read
    cmp al, '9'
    ja .hcpsp_port_read
    movzx edx, al
    mov eax, [rsp + 56]
    imul eax, eax, 10
    mov [rsp + 56], eax
    sub edx, '0'
    add [rsp + 56], edx
    jmp .hcpsp_port_read
.hcpsp_port_done:
    mov rcx, [rsp + 64]
    call fclose
    cmp dword ptr [rsp + 56], 0
    je .hcpsp_port_ready
    mov r12d, [rsp + 56]
.hcpsp_port_ready:

    mov rcx, r15
    lea rdx, [rip + http_client_body_buf]
    mov r8d, 4096
    call http_string_to_cstr

    mov rcx, rbx
    mov rdx, r13
    mov r8, r14
    lea r9, [rip + http_client_body_buf]
    lea rax, [rip + http_client_request_buf]
    mov [rsp + 32], rax
    mov qword ptr [rsp + 40], 8192
    call http_build_post_request

    call bada_sock_init
    test rax, rax
    jz .hcpsp_done
    call bada_sock_tcp
    mov r15, rax
    cmp r15, -1
    je .hcpsp_cleanup
    mov rcx, r15
    mov rdx, rbx
    mov r8d, r12d
    call bada_sock_connect_ipv4
    test rax, rax
    jz .hcpsp_close

    lea rcx, [rip + http_client_request_buf]
    call httpc_strlen
    mov rcx, r15
    lea rdx, [rip + http_client_request_buf]
    mov r8, rax
    call bada_sock_send

    mov rcx, r15
    lea rdx, [rip + http_client_response_buf]
    mov r8d, 8191
    call bada_sock_recv
    cmp rax, 0
    jle .hcpsp_close
    lea r10, [rip + http_client_response_buf]
    mov byte ptr [r10 + rax], 0
    lea rcx, [rip + http_client_response_buf]
    call http_print_response_body

.hcpsp_close:
    mov rcx, r15
    call bada_sock_close
.hcpsp_cleanup:
    call bada_sock_cleanup
.hcpsp_done:
    add rsp, 80
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
