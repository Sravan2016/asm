.intel_syntax noprefix

.global aleka_create
.global aleka_set
.global aleka_get
.global aleka_free
.global aleka_json_apply
.global aleka_json_extract

.section .text
.extern bada_mem_alloc
.extern bada_mem_free
.extern string_from_cstr
.extern string_length
.extern string_char_at
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

# File-backed Aleka object:
# [0]  file handle qword
# [8]  field_count qword
# [16] path buffer: "aleka_" + 16 hex chars + ".bin" + NUL

is_space:
    cmp al, 32
    je .space_yes
    cmp al, 9
    je .space_yes
    cmp al, 10
    je .space_yes
    cmp al, 13
    je .space_yes
    xor eax, eax
    ret
.space_yes:
    mov eax, 1
    ret

cstrlen:
    # rcx=cstr -> rax=len
    xor rax, rax
.len_loop:
    cmp byte ptr [rcx + rax], 0
    je .len_done
    inc rax
    jmp .len_loop
.len_done:
    ret

skip_ws:
    # rcx=cursor -> rax=first non-ws
    mov rax, rcx
.skip_loop:
    mov r10b, byte ptr [rax]
    test r10b, r10b
    jz .skip_done
    push rax
    mov al, r10b
    call is_space
    mov r10d, eax
    pop rax
    test r10d, r10d
    jz .skip_done
    inc rax
    jmp .skip_loop
.skip_done:
    ret

trim_right:
    # rcx=start, rdx=end_exclusive -> rax=trimmed_end
    mov rax, rdx
.trim_loop:
    cmp rax, rcx
    jbe .trim_done
    mov r10b, byte ptr [rax - 1]
    push rcx
    push rdx
    push rax
    mov al, r10b
    call is_space
    mov r11d, eax
    pop rax
    pop rdx
    pop rcx
    test r11d, r11d
    jz .trim_done
    dec rax
    jmp .trim_loop
.trim_done:
    ret

json_to_cstr:
    # rcx=AsmString* -> rax=cstr buffer, rdx=len
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 40
    mov rbx, rcx
    call string_length
    mov r12, rax
    lea rcx, [r12 + 1]
    call bada_mem_alloc
    test rax, rax
    jz .jt_fail
    mov r13, rax
    xor r14, r14
.jt_loop:
    cmp r14, r12
    jae .jt_done
    mov rcx, rbx
    mov rdx, r14
    call string_char_at
    mov byte ptr [r13 + r14], al
    inc r14
    jmp .jt_loop
.jt_done:
    mov byte ptr [r13 + r12], 0
    mov rax, r13
    mov rdx, r12
    add rsp, 40
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret
.jt_fail:
    xor rax, rax
    xor rdx, rdx
    add rsp, 40
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

key_matches:
    # rcx=text after opening quote, rdx=key -> rax=1 if exact key then closing quote
    push rbx
    push r12
    xor rax, rax
    mov rbx, rcx
    mov r12, rdx
.km_loop:
    mov r10b, byte ptr [r12]
    test r10b, r10b
    jz .km_key_end
    cmp byte ptr [rbx], r10b
    jne .km_no
    inc rbx
    inc r12
    jmp .km_loop
.km_key_end:
    cmp byte ptr [rbx], '"'
    jne .km_no
    mov rax, 1
.km_no:
    pop r12
    pop rbx
    ret

extract_span:
    # rcx=json cstr, rdx=key -> rax=start, rdx=len, r8=quoted flag. rax=0 means not found.
    push rbp
    mov rbp, rsp
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 40
    mov rbx, rcx
    mov r12, rdx
    mov rsi, rcx
.scan_loop:
    mov al, byte ptr [rsi]
    test al, al
    jz .not_found
    cmp al, '"'
    jne .scan_next
    lea rcx, [rsi + 1]
    mov rdx, r12
    call key_matches
    test rax, rax
    jz .scan_next
    mov rcx, r12
    call cstrlen
    lea rdi, [rsi + rax + 2]
    mov rcx, rdi
    call skip_ws
    mov rdi, rax
    cmp byte ptr [rdi], ':'
    jne .scan_next
    inc rdi
    mov rcx, rdi
    call skip_ws
    mov rdi, rax
    cmp byte ptr [rdi], 0
    je .not_found
    xor r15, r15
    cmp byte ptr [rdi], '"'
    jne .unquoted
    mov r15, 1
    inc rdi
    mov r13, rdi
.quoted_loop:
    mov al, byte ptr [rdi]
    test al, al
    jz .not_found
    cmp al, '\\'
    jne .quoted_maybe_end
    cmp byte ptr [rdi + 1], 0
    je .not_found
    add rdi, 2
    jmp .quoted_loop
.quoted_maybe_end:
    cmp al, '"'
    je .span_done
    inc rdi
    jmp .quoted_loop
.unquoted:
    mov r13, rdi
    xor r14d, r14d      # depth
    xor r15d, r15d      # in string
.unquoted_loop:
    mov al, byte ptr [rdi]
    test al, al
    jz .unquoted_end
    test r15d, r15d
    jz .not_in_string
    cmp al, '\\'
    jne .string_maybe_end
    cmp byte ptr [rdi + 1], 0
    je .unquoted_end
    add rdi, 2
    jmp .unquoted_loop
.string_maybe_end:
    cmp al, '"'
    jne .string_continue
    xor r15d, r15d
.string_continue:
    inc rdi
    jmp .unquoted_loop
.not_in_string:
    cmp al, '"'
    jne .check_open
    mov r15d, 1
    inc rdi
    jmp .unquoted_loop
.check_open:
    cmp al, '{'
    je .depth_open
    cmp al, '['
    je .depth_open
    cmp al, '}'
    je .depth_close
    cmp al, ']'
    je .depth_close
    cmp al, ','
    jne .plain_continue
    test r14d, r14d
    jz .unquoted_end
.plain_continue:
    inc rdi
    jmp .unquoted_loop
.depth_open:
    inc r14d
    inc rdi
    jmp .unquoted_loop
.depth_close:
    test r14d, r14d
    jz .unquoted_end
    dec r14d
    inc rdi
    test r14d, r14d
    jz .unquoted_end
    jmp .unquoted_loop
.unquoted_end:
    mov rcx, r13
    mov rdx, rdi
    call trim_right
    mov rdi, rax
    xor r15, r15
.span_done:
    cmp rdi, r13
    jb .not_found
    mov rax, r13
    mov rdx, rdi
    sub rdx, r13
    mov r8, r15
    jmp .extract_exit
.scan_next:
    inc rsi
    jmp .scan_loop
.not_found:
    xor rax, rax
    xor rdx, rdx
    xor r8, r8
.extract_exit:
    add rsp, 40
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    pop rbp
    ret

parse_int64_span:
    # rcx=start, rdx=len -> rax
    push rbx
    push r12
    mov rbx, rcx
    mov r12, rdx
    xor rax, rax
    xor r11d, r11d
    test r12, r12
    jz .pi_done
    cmp byte ptr [rbx], '-'
    jne .pi_loop
    mov r11d, 1
    inc rbx
    dec r12
.pi_loop:
    test r12, r12
    jz .pi_sign
    movzx r10, byte ptr [rbx]
    cmp r10b, '0'
    jb .pi_sign
    cmp r10b, '9'
    ja .pi_sign
    imul rax, rax, 10
    sub r10, '0'
    add rax, r10
    inc rbx
    dec r12
    jmp .pi_loop
.pi_sign:
    test r11d, r11d
    jz .pi_done
    neg rax
.pi_done:
    pop r12
    pop rbx
    ret

make_string_from_span:
    # rcx=start, rdx=len -> rax=AsmString*
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 40
    mov rbx, rcx
    mov r12, rdx
    lea rcx, [r12 + 1]
    call bada_mem_alloc
    test rax, rax
    jz .ms_fail
    mov r13, rax
    xor r14, r14
.ms_copy:
    cmp r14, r12
    jae .ms_copy_done
    mov al, byte ptr [rbx + r14]
    mov byte ptr [r13 + r14], al
    inc r14
    jmp .ms_copy
.ms_copy_done:
    mov byte ptr [r13 + r12], 0
    mov rcx, 16
    call bada_mem_alloc
    test rax, rax
    jz .ms_free_buf
    mov r14, rax
    mov rcx, r14
    mov rdx, r13
    call string_from_cstr
    mov rcx, r13
    call bada_mem_free
    mov rax, r14
    jmp .ms_exit
.ms_free_buf:
    mov rcx, r13
    call bada_mem_free
.ms_fail:
    xor rax, rax
.ms_exit:
    add rsp, 40
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

parse_slot_value:
    # rcx=start, rdx=len, r8=type tag -> rax=value
    cmp r8, 5
    je .ps_string
    cmp r8, 4
    je .ps_bool
    cmp r8, 1
    je .ps_int
    cmp r8, 2
    je .ps_int
    xor rax, rax
    ret
.ps_int:
    jmp parse_int64_span
.ps_bool:
    test rdx, rdx
    jz .ps_false
    mov al, byte ptr [rcx]
    cmp al, '1'
    je .ps_true
    cmp al, 't'
    je .ps_true
    cmp al, 'T'
    je .ps_true
    cmp al, 'y'
    je .ps_true
    cmp al, 'Y'
    je .ps_true
.ps_false:
    xor rax, rax
    ret
.ps_true:
    mov rax, 1
    ret
.ps_string:
    jmp make_string_from_span

make_aleka_path:
    # rcx=object, rdx=out path
    mov byte ptr [rdx], 'a'
    mov byte ptr [rdx + 1], 'l'
    mov byte ptr [rdx + 2], 'e'
    mov byte ptr [rdx + 3], 'k'
    mov byte ptr [rdx + 4], 'a'
    mov byte ptr [rdx + 5], '_'
    mov rax, rcx
    lea r10, [rip + hex_digits]
    mov r11, 16
    lea r8, [rdx + 6]
.map_hex:
    rol rax, 4
    mov r9, rax
    and r9, 0x0f
    mov r9b, byte ptr [r10 + r9]
    mov byte ptr [r8], r9b
    inc r8
    dec r11
    jnz .map_hex
    mov byte ptr [rdx + 22], '.'
    mov byte ptr [rdx + 23], 'b'
    mov byte ptr [rdx + 24], 'i'
    mov byte ptr [rdx + 25], 'n'
    mov byte ptr [rdx + 26], 0
    ret

aleka_seek_slot:
    # rcx=object, rdx=index -> rax=1/0
    push rbx
    sub rsp, 32
    mov rbx, rcx
    mov rax, rdx
    shl rax, 3
    mov rcx, [rbx]
    mov rdx, rax
    xor r8, r8
    mov r9d, FILE_BEGIN
    call qword ptr [rip + pSetFilePointerEx]
    add rsp, 32
    pop rbx
    ret

aleka_create:
    # rcx=field_count -> rax=object
    push rbp
    mov rbp, rsp
    push rbx
    sub rsp, 80
    mov rbx, rcx
    mov rcx, 48
    call bada_mem_alloc
    test rax, rax
    jz .ac_fail
    mov r10, rbx
    mov rbx, rax
    mov qword ptr [rbx], INVALID_HANDLE_VALUE
    mov [rbx + 8], r10
    mov rcx, rbx
    lea rdx, [rbx + 16]
    call make_aleka_path
    lea rcx, [rbx + 16]
    mov rdx, GENERIC_READ
    or rdx, GENERIC_WRITE
    mov r8, FILE_SHARE_READ
    xor r9, r9
    mov qword ptr [rsp + 32], CREATE_ALWAYS
    mov qword ptr [rsp + 40], FILE_ATTRIBUTE_NORMAL
    mov qword ptr [rsp + 48], 0
    call qword ptr [rip + pCreateFileA]
    cmp rax, INVALID_HANDLE_VALUE
    je .ac_file_fail
    mov [rbx], rax
    mov rax, rbx
    jmp .ac_exit
.ac_file_fail:
    mov rcx, rbx
    call bada_mem_free
.ac_fail:
    xor rax, rax
.ac_exit:
    add rsp, 80
    pop rbx
    pop rbp
    ret

aleka_set:
    # rcx=object, rdx=index, r8=value
    push rbx
    push r12
    push r13
    sub rsp, 80
    test rcx, rcx
    jz .as_ret
    mov rbx, rcx
    mov r12, rdx
    mov r13, r8
    cmp r12, [rbx + 8]
    jae .as_ret
    mov rcx, rbx
    mov rdx, r12
    call aleka_seek_slot
    test rax, rax
    jz .as_ret
    mov [rsp + 56], r13
    mov rcx, [rbx]
    lea rdx, [rsp + 56]
    mov r8d, 8
    lea r9, [rsp + 64]
    mov qword ptr [rsp + 32], 0
    call qword ptr [rip + pWriteFile]
.as_ret:
    add rsp, 80
    pop r13
    pop r12
    pop rbx
    ret

aleka_get:
    # rcx=object, rdx=index -> rax=value
    push rbx
    push r12
    sub rsp, 56
    test rcx, rcx
    jz .ag_zero
    mov rbx, rcx
    mov r12, rdx
    cmp r12, [rbx + 8]
    jae .ag_zero
    mov rcx, rbx
    mov rdx, r12
    call aleka_seek_slot
    test rax, rax
    jz .ag_zero
    mov qword ptr [rsp + 32], 0
    mov rcx, [rbx]
    lea rdx, [rsp + 32]
    mov r8d, 8
    lea r9, [rsp + 24]
    mov qword ptr [rsp + 40], 0
    call qword ptr [rip + pReadFile]
    test rax, rax
    jz .ag_zero
    mov eax, dword ptr [rsp + 24]
    cmp rax, 8
    jne .ag_zero
    mov rax, [rsp + 32]
    jmp .ag_exit
.ag_zero:
    xor rax, rax
.ag_exit:
    add rsp, 56
    pop r12
    pop rbx
    ret

aleka_free:
    # rcx=object
    push rbx
    sub rsp, 32
    test rcx, rcx
    jz .af_ret
    mov rbx, rcx
    mov rcx, [rbx]
    cmp rcx, INVALID_HANDLE_VALUE
    je .af_delete
    call qword ptr [rip + pCloseHandle]
    mov qword ptr [rbx], INVALID_HANDLE_VALUE
.af_delete:
    lea rcx, [rbx + 16]
    call qword ptr [rip + pDeleteFileA]
    mov rcx, rbx
    call bada_mem_free
.af_ret:
    add rsp, 32
    pop rbx
    ret

aleka_json_apply:
    # rcx=object, rdx=AsmString* json, r8=key cstr, r9=descriptor
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 40
    mov rbx, rcx
    mov r12, rdx
    mov r13, r8
    mov r14, r9
    test rbx, rbx
    jz .aja_exit
    test r12, r12
    jz .aja_exit
    test r13, r13
    jz .aja_exit
    test r14, r14
    jz .aja_exit
    mov rcx, r12
    call json_to_cstr
    test rax, rax
    jz .aja_exit
    mov r15, rax
    mov rcx, r15
    mov rdx, r13
    call extract_span
    test rax, rax
    jz .aja_free_json
    mov rcx, rax
    # rdx already length
    mov r8, r14
    and r8, 0xff
    call parse_slot_value
    mov rcx, rbx
    mov rdx, r14
    shr rdx, 8
    mov r8, rax
    call aleka_set
.aja_free_json:
    mov rcx, r15
    call bada_mem_free
.aja_exit:
    add rsp, 40
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

aleka_json_extract:
    # rcx=AsmString* json, rdx=key cstr, r8=out AsmString*
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 40
    mov rbx, rcx
    mov r12, rdx
    mov r13, r8
    test rbx, rbx
    jz .aje_exit
    test r12, r12
    jz .aje_exit
    test r13, r13
    jz .aje_exit
    mov rcx, rbx
    call json_to_cstr
    test rax, rax
    jz .aje_exit
    mov r14, rax
    mov rcx, r14
    mov rdx, r12
    call extract_span
    test rax, rax
    jz .aje_free_json
    mov rcx, rax
    # rdx is length
    call make_string_from_span
    test rax, rax
    jz .aje_free_json
    mov r10, [rax]
    mov r11, [rax + 8]
    mov [r13], r10
    mov [r13 + 8], r11
    mov rcx, rax
    call bada_mem_free
.aje_free_json:
    mov rcx, r14
    call bada_mem_free
.aje_exit:
    add rsp, 40
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret
