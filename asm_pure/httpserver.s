.intel_syntax noprefix

# Pure HTTP response helpers with no Windows/Winsock dependency.
# These routines do not open network connections. They build HTTP response bytes in caller
# buffers so request/response formatting can be used without OS networking APIs.

.global http_build_response
.global http_extract_path
.global http_extract_query
.global http_extract_body
.global http_get_param
.global http_server_once
.global http_server_forever

.section .data
http_resp_head: .asciz "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: "
http_resp_mid:  .asciz "\r\n\r\n"
http_default_body: .asciz "OK"

.section .text

http_strlen:
    # rcx=cstr -> rax=len
    xor rax, rax
    test rcx, rcx
    je .hsl_done
.hsl_loop:
    cmp byte ptr [rcx + rax], 0
    je .hsl_done
    inc rax
    jmp .hsl_loop
.hsl_done:
    ret

http_copy_cap:
    # rcx=dst, rdx=src, r8=remaining cap including final zero
    # returns rax=bytes copied, dst is zero terminated when cap > 0
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

http_append_cap:
    # rcx=dst base, rdx=src, r8=cap, r9=used -> rax=new used
    push rbx
    push rsi
    mov rbx, rcx
    mov rsi, r9
    cmp rsi, r8
    jae .hac_return
    lea rcx, [rbx + rsi]
    sub r8, rsi
    call http_copy_cap
    add rsi, rax
.hac_return:
    mov rax, rsi
    pop rsi
    pop rbx
    ret

http_append_uint:
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
.hau_loop:
    xor edx, edx
    mov r11d, 10
    div r11
    add dl, '0'
    dec r10
    mov [r10], dl
    test rax, rax
    jne .hau_loop
    mov rcx, rbx
    mov rdx, r10
    mov r8, rsi
    mov r9, rdi
    call http_append_cap
    add rsp, 40
    pop rdi
    pop rsi
    pop rbx
    ret

http_build_response:
    # rcx=body cstr, rdx=out buf, r8=out cap -> rax=bytes written
    push rbx
    push rsi
    push rdi
    push r12
    sub rsp, 40
    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8
    test rbx, rbx
    jne .hbr_body_ok
    lea rbx, [rip + http_default_body]
.hbr_body_ok:
    test rsi, rsi
    je .hbr_fail
    test rdi, rdi
    je .hbr_fail
    mov byte ptr [rsi], 0
    lea rcx, [rip + http_resp_head]
    call http_strlen
    mov r12, rax
    mov rcx, rsi
    lea rdx, [rip + http_resp_head]
    mov r8, rdi
    xor r9, r9
    call http_append_cap
    mov r12, rax
    mov rcx, rbx
    call http_strlen
    mov rcx, rsi
    mov rdx, rax
    mov r8, rdi
    mov r9, r12
    call http_append_uint
    mov r12, rax
    mov rcx, rsi
    lea rdx, [rip + http_resp_mid]
    mov r8, rdi
    mov r9, r12
    call http_append_cap
    mov r12, rax
    mov rcx, rsi
    mov rdx, rbx
    mov r8, rdi
    mov r9, r12
    call http_append_cap
    jmp .hbr_done
.hbr_fail:
    xor eax, eax
.hbr_done:
    add rsp, 40
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

http_extract_path:
    # rcx=request cstr, rdx=out buf, r8=out cap -> rax=bytes copied
    push rbx
    push rsi
    push rdi
    sub rsp, 32
    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8
    xor rax, rax
    test rbx, rbx
    je .hep_done
    test rsi, rsi
    je .hep_done
    test rdi, rdi
    je .hep_done
    mov byte ptr [rsi], 0
.hep_method:
    mov dl, [rbx]
    test dl, dl
    je .hep_done
    cmp dl, ' '
    je .hep_skip_spaces
    inc rbx
    jmp .hep_method
.hep_skip_spaces:
    cmp byte ptr [rbx], ' '
    jne .hep_copy
    inc rbx
    jmp .hep_skip_spaces
.hep_copy:
    cmp rax, rdi
    jae .hep_term_back
    mov dl, [rbx]
    test dl, dl
    je .hep_term
    cmp dl, '?'
    je .hep_term
    cmp dl, ' '
    je .hep_term
    cmp dl, 13
    je .hep_term
    cmp dl, 10
    je .hep_term
    cmp rax, rdi
    jae .hep_term_back
    mov [rsi + rax], dl
    inc rax
    inc rbx
    cmp rax, rdi
    jb .hep_copy
.hep_term_back:
    dec rax
.hep_term:
    mov byte ptr [rsi + rax], 0
.hep_done:
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret

http_extract_query:
    # rcx=request cstr, rdx=out buf, r8=out cap -> rax=bytes copied
    push rbx
    push rsi
    push rdi
    sub rsp, 32
    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8
    xor rax, rax
    test rbx, rbx
    je .heq_done
    test rsi, rsi
    je .heq_done
    test rdi, rdi
    je .heq_done
    mov byte ptr [rsi], 0
.heq_skip_method:
    mov dl, [rbx]
    test dl, dl
    je .heq_done
    cmp dl, ' '
    je .heq_skip_spaces
    inc rbx
    jmp .heq_skip_method
.heq_skip_spaces:
    cmp byte ptr [rbx], ' '
    jne .heq_find
    inc rbx
    jmp .heq_skip_spaces
.heq_find:
    mov dl, [rbx]
    test dl, dl
    je .heq_done
    cmp dl, ' '
    je .heq_done
    cmp dl, 13
    je .heq_done
    cmp dl, 10
    je .heq_done
    cmp dl, '?'
    je .heq_found
    inc rbx
    jmp .heq_find
.heq_found:
    inc rbx
.heq_copy:
    mov dl, [rbx]
    test dl, dl
    je .heq_term
    cmp dl, ' '
    je .heq_term
    cmp dl, 13
    je .heq_term
    cmp dl, 10
    je .heq_term
    cmp rax, rdi
    jae .heq_term_back
    mov [rsi + rax], dl
    inc rax
    inc rbx
    cmp rax, rdi
    jb .heq_copy
.heq_term_back:
    dec rax
.heq_term:
    mov byte ptr [rsi + rax], 0
.heq_done:
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret

http_extract_body:
    # rcx=request cstr, rdx=out buf, r8=out cap -> rax=bytes copied
    push rbx
    push rsi
    push rdi
    sub rsp, 32
    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8
    xor rax, rax
    test rbx, rbx
    je .heb_done
    test rsi, rsi
    je .heb_done
    test rdi, rdi
    je .heb_done
    mov byte ptr [rsi], 0
.heb_find:
    cmp byte ptr [rbx], 0
    je .heb_done
    cmp byte ptr [rbx], 13
    jne .heb_next
    cmp byte ptr [rbx + 1], 10
    jne .heb_next
    cmp byte ptr [rbx + 2], 13
    jne .heb_next
    cmp byte ptr [rbx + 3], 10
    je .heb_found
.heb_next:
    inc rbx
    jmp .heb_find
.heb_found:
    add rbx, 4
.heb_copy:
    mov dl, [rbx + rax]
    test dl, dl
    je .heb_term
    cmp rax, rdi
    jae .heb_term_back
    mov [rsi + rax], dl
    inc rax
    cmp rax, rdi
    jb .heb_copy
.heb_term_back:
    dec rax
.heb_term:
    mov byte ptr [rsi + rax], 0
.heb_done:
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret

http_param_key_matches:
    # rcx=query cursor, rdx=key -> rax=1 if cursor starts key=
    push rbx
    push rsi
    mov rbx, rcx
    mov rsi, rdx
.hpkm_loop:
    mov al, [rsi]
    test al, al
    je .hpkm_key_done
    cmp al, [rbx]
    jne .hpkm_no
    inc rsi
    inc rbx
    jmp .hpkm_loop
.hpkm_key_done:
    cmp byte ptr [rbx], '='
    jne .hpkm_no
    mov eax, 1
    jmp .hpkm_done
.hpkm_no:
    xor eax, eax
.hpkm_done:
    pop rsi
    pop rbx
    ret

http_get_param:
    # rcx=query cstr, rdx=key cstr, r8=out buf, r9=out cap -> rax=bytes copied
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
    xor r13, r13
    test rbx, rbx
    je .hgp_done
    test rsi, rsi
    je .hgp_done
    test rdi, rdi
    je .hgp_done
    test r12, r12
    je .hgp_done
    mov byte ptr [rdi], 0
.hgp_scan:
    cmp byte ptr [rbx], 0
    je .hgp_done
    mov rcx, rbx
    mov rdx, rsi
    call http_param_key_matches
    test eax, eax
    jne .hgp_found
.hgp_skip:
    mov al, [rbx]
    test al, al
    je .hgp_done
    inc rbx
    cmp al, '&'
    je .hgp_scan
    cmp al, ';'
    jne .hgp_skip
    jmp .hgp_scan
.hgp_found:
    mov rcx, rsi
    call http_strlen
    lea rbx, [rbx + rax + 1]
    xor r13, r13
.hgp_copy:
    mov al, [rbx]
    test al, al
    je .hgp_term
    cmp al, '&'
    je .hgp_term
    cmp al, ';'
    je .hgp_term
    cmp r13, r12
    jae .hgp_term_back
    mov [rdi + r13], al
    inc r13
    inc rbx
    cmp r13, r12
    jb .hgp_copy
.hgp_term_back:
    dec r13
.hgp_term:
    mov byte ptr [rdi + r13], 0
.hgp_done:
    mov rax, r13
    add rsp, 40
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

http_server_once:
    # ecx=port, rdx=response_body cstr -> rax=1 when response body is usable
    xor eax, eax
    test rdx, rdx
    setne al
    ret

http_server_forever:
    # No network backend is used; no infinite server loop is possible.
    xor eax, eax
    ret
