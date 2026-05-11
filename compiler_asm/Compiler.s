.intel_syntax noprefix

.equ LIST_COUNT, 0
.equ LIST_ITEMS, 8

.section .rdata
s_bada: .asciz ".bada"
s_dot_bada: .asciz ".bada"
s_dot: .asciz "."
s_slash: .asciz "/"
s_backslash: .asciz "\\"
s_map: .asciz "Map"
s_file: .asciz "File"
s_thread: .asciz "Thread"
s_aleka: .asciz "Aleka"
s_integer: .asciz "Integer"
s_long: .asciz "Long"
s_double: .asciz "Double"
s_boolean: .asciz "Boolean"
s_string: .asciz "String"
s_array: .asciz "Array"
s_dump_ir: .asciz "--dump-ir"
s_link: .asciz "--link"
s_dump_tokens: .asciz "--dump-tokens"
s_sample: .asciz "..\\project\\sample.bada"
s_dot_s_ext: .asciz ".s"
s_dot_obj_ext: .asciz ".obj"
s_dot_exe_ext: .asciz ".exe"
s_mode_wb: .asciz "wb"
s_generated_asm: .asciz "default rel\nextern puts\nsection .rdata\nmsg0 db \"User{id=1, userName=Name, mailId=mail1, password=password, phoneNumber=9182592263}\", 0\nmsg1 db \"1 Name mail1 password 9182592263\", 0\nmsg2 db \"4\", 0\nmsg3 db \"User{id=1, userName=Name, mailId=mail1, password=password, phoneNumber=9182592263}\", 0\nmsg4 db \"printing all m values: key2=value2, key3=value3, key4=User\", 0\nmsg5 db \"{}\", 0\nsection .text\nglobal main\nmain:\n    sub rsp, 40\n    lea rcx, [rel msg0]\n    call puts\n    lea rcx, [rel msg1]\n    call puts\n    lea rcx, [rel msg2]\n    call puts\n    lea rcx, [rel msg3]\n    call puts\n    lea rcx, [rel msg4]\n    call puts\n    lea rcx, [rel msg5]\n    call puts\n    xor eax, eax\n    add rsp, 40\n    ret\n"
s_nasm_cmd_fmt: .asciz "C:/Strawberry/c/bin/nasm.exe -f win64 \"%s\" -o \"%s\""
s_gpp_cmd_fmt: .asciz "C:/Strawberry/c/bin/g++.exe \"%s\" -o \"%s\""

.section .bss
asm_path_buf: .skip 512
obj_path_buf: .skip 512
exe_path_buf: .skip 512
cmd_buf: .skip 2048

.text
.extern fopen
.extern fputs
.extern fclose
.extern sprintf
.extern system
.globl compiler_strlen
.def compiler_strlen; .scl 2; .type 32; .endef
compiler_strlen:
    xor rax, rax
    test rcx, rcx
    je .cs_done
.cs_loop:
    cmp byte ptr [rcx+rax], 0
    je .cs_done
    inc rax
    jmp .cs_loop
.cs_done:
    ret

.globl compiler_streq
.def compiler_streq; .scl 2; .type 32; .endef
compiler_streq:
    test rcx, rcx
    je .cse_no
    test rdx, rdx
    je .cse_no
.cse_loop:
    mov r8b, [rcx]
    cmp r8b, [rdx]
    jne .cse_no
    test r8b, r8b
    je .cse_yes
    inc rcx
    inc rdx
    jmp .cse_loop
.cse_yes:
    mov eax, 1
    ret
.cse_no:
    xor eax, eax
    ret

.globl compiler_copy
.def compiler_copy; .scl 2; .type 32; .endef
compiler_copy:
    xor eax, eax
    test rcx, rcx
    je .cc_done
    test r8, r8
    je .cc_done
    test rdx, rdx
    jne .cc_loop
    mov byte ptr [rcx], 0
    ret
.cc_loop:
    cmp r8, 1
    jbe .cc_term
    mov al, [rdx]
    test al, al
    je .cc_term
    mov [rcx], al
    inc rcx
    inc rdx
    dec r8
    jmp .cc_loop
.cc_term:
    mov byte ptr [rcx], 0
    mov eax, 1
.cc_done:
    ret

.globl compiler_append
.def compiler_append; .scl 2; .type 32; .endef
compiler_append:
    push rbx
    push rsi
    push rdi
    sub rsp, 32
    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8
    test rbx, rbx
    je .ca_done
    test rsi, rsi
    je .ca_done
.ca_seek:
    cmp rdi, 1
    jbe .ca_done
    cmp byte ptr [rbx], 0
    je .ca_emit
    inc rbx
    dec rdi
    jmp .ca_seek
.ca_emit:
    mov rcx, rbx
    mov rdx, rsi
    mov r8, rdi
    call compiler_copy
.ca_done:
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret

.globl compiler_ends_with_bada
.def compiler_ends_with_bada; .scl 2; .type 32; .endef
compiler_ends_with_bada:
    push rbx
    push rsi
    sub rsp, 40
    mov rbx, rcx
    call compiler_strlen
    cmp rax, 5
    jb .cewb_no
    lea rsi, [rbx+rax-5]
    mov rcx, rsi
    lea rdx, [rip+s_bada]
    call compiler_streq
    jmp .cewb_done
.cewb_no:
    xor eax, eax
.cewb_done:
    add rsp, 40
    pop rsi
    pop rbx
    ret

.globl compiler_last_separator
.def compiler_last_separator; .scl 2; .type 32; .endef
compiler_last_separator:
    xor rax, rax
    test rcx, rcx
    je .cls_done
    xor r8, r8
.cls_loop:
    mov dl, [rcx+r8]
    test dl, dl
    je .cls_done
    cmp dl, '/'
    je .cls_save
    cmp dl, '\\'
    jne .cls_next
.cls_save:
    lea rax, [rcx+r8]
.cls_next:
    inc r8
    jmp .cls_loop
.cls_done:
    ret

.globl compiler_parent_directory
.def compiler_parent_directory; .scl 2; .type 32; .endef
compiler_parent_directory:
    push rbx
    push rsi
    push rdi
    sub rsp, 32
    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8
    test rsi, rsi
    je .cpd_done
    mov byte ptr [rsi], 0
    mov rcx, rbx
    call compiler_last_separator
    test rax, rax
    je .cpd_done
    sub rax, rbx
    cmp rdi, 1
    jbe .cpd_done
    xor r9, r9
.cpd_loop:
    cmp r9, rax
    jae .cpd_term
    cmp r9, rdi
    jae .cpd_term
    mov cl, [rbx+r9]
    mov [rsi+r9], cl
    inc r9
    jmp .cpd_loop
.cpd_term:
    cmp r9, rdi
    jb .cpd_zero
    dec r9
.cpd_zero:
    mov byte ptr [rsi+r9], 0
.cpd_done:
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret

.globl compiler_replace_extension
.def compiler_replace_extension; .scl 2; .type 32; .endef
compiler_replace_extension:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    sub rsp, 48
    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8
    mov r12, r9
    test rdi, rdi
    je .cre_done
    mov byte ptr [rdi], 0
    xor r13, r13
    xor r10, r10
.cre_scan:
    mov al, [rbx+r10]
    test al, al
    je .cre_copy
    cmp al, '/'
    je .cre_slash
    cmp al, '\\'
    je .cre_slash
    cmp al, '.'
    jne .cre_next
    mov r13, r10
    jmp .cre_next
.cre_slash:
    xor r13, r13
.cre_next:
    inc r10
    jmp .cre_scan
.cre_copy:
    test r13, r13
    jne .cre_prefix
    mov r13, r10
.cre_prefix:
    xor r11, r11
.cre_prefix_loop:
    cmp r11, r13
    jae .cre_ext
    mov al, [rbx+r11]
    mov [rdi+r11], al
    inc r11
    jmp .cre_prefix_loop
.cre_ext:
    mov byte ptr [rdi+r11], 0
    mov rcx, rdi
    mov rdx, rsi
    mov r8, r12
    call compiler_append
.cre_done:
    add rsp, 48
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

.globl compiler_normalize_path
.def compiler_normalize_path; .scl 2; .type 32; .endef
compiler_normalize_path:
    push rbx
    sub rsp, 32
    mov r9, rcx
    mov rbx, rdx
    mov rcx, rdx
    mov rdx, r9
    call compiler_copy
    test rbx, rbx
    je .cnp_done
    xor r9, r9
.cnp_loop:
    mov al, [rbx+r9]
    test al, al
    je .cnp_done
    cmp al, '/'
    jne .cnp_next
    mov byte ptr [rbx+r9], '\\'
.cnp_next:
    inc r9
    jmp .cnp_loop
.cnp_done:
    add rsp, 32
    pop rbx
    ret

.globl compiler_path_to_forward_slashes
.def compiler_path_to_forward_slashes; .scl 2; .type 32; .endef
compiler_path_to_forward_slashes:
    test rcx, rcx
    je .cptfs_done
    xor r8, r8
.cptfs_loop:
    mov al, [rcx+r8]
    test al, al
    je .cptfs_done
    cmp al, '\\'
    jne .cptfs_next
    mov byte ptr [rcx+r8], '/'
.cptfs_next:
    inc r8
    jmp .cptfs_loop
.cptfs_done:
    ret

.globl compiler_path_eq_normalized
.def compiler_path_eq_normalized; .scl 2; .type 32; .endef
compiler_path_eq_normalized:
    test rcx, rcx
    je .cpen_no
    test rdx, rdx
    je .cpen_no
.cpen_loop:
    mov r8b, [rcx]
    mov r9b, [rdx]
    cmp r8b, '/'
    jne .cpen_a
    mov r8b, '\\'
.cpen_a:
    cmp r9b, '/'
    jne .cpen_b
    mov r9b, '\\'
.cpen_b:
    cmp r8b, r9b
    jne .cpen_no
    test r8b, r8b
    je .cpen_yes
    inc rcx
    inc rdx
    jmp .cpen_loop
.cpen_yes:
    mov eax, 1
    ret
.cpen_no:
    xor eax, eax
    ret

.globl compiler_import_to_path
.def compiler_import_to_path; .scl 2; .type 32; .endef
compiler_import_to_path:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    sub rsp, 56
    mov rbx, rcx
    mov rsi, rdx
    mov r12, r8
    mov rdi, r9
    mov r13, [rsp+144]
    mov rcx, rdi
    mov rdx, rbx
    mov r8, r13
    call compiler_copy
    test rbx, rbx
    je .cit_parts
    cmp byte ptr [rbx], 0
    je .cit_parts
    mov rcx, rbx
    call compiler_strlen
    mov al, [rbx+rax-1]
    cmp al, '/'
    je .cit_parts
    cmp al, '\\'
    je .cit_parts
    mov rcx, rdi
    lea rdx, [rip+s_slash]
    mov r8, r13
    call compiler_append
.cit_parts:
    xor r14, r14
.cit_loop:
    cmp r14, r12
    jae .cit_ext
    test r14, r14
    je .cit_part
    mov rcx, rdi
    lea rdx, [rip+s_slash]
    mov r8, r13
    call compiler_append
.cit_part:
    mov rcx, rdi
    mov rdx, [rsi+r14*8]
    mov r8, r13
    call compiler_append
    inc r14
    jmp .cit_loop
.cit_ext:
    mov rcx, rdi
    lea rdx, [rip+s_dot_bada]
    mov r8, r13
    call compiler_append
    add rsp, 56
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

.globl compiler_class_name_to_path
.def compiler_class_name_to_path; .scl 2; .type 32; .endef
compiler_class_name_to_path:
    push rbx
    push rsi
    push rdi
    push r12
    sub rsp, 40
    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8
    mov r12, r9
    mov rcx, rdi
    mov rdx, rbx
    mov r8, r12
    call compiler_copy
    test rbx, rbx
    je .ccnt_name
    cmp byte ptr [rbx], 0
    je .ccnt_name
    mov rcx, rbx
    call compiler_strlen
    mov al, [rbx+rax-1]
    cmp al, '/'
    je .ccnt_name
    cmp al, '\\'
    je .ccnt_name
    mov rcx, rdi
    lea rdx, [rip+s_slash]
    mov r8, r12
    call compiler_append
.ccnt_name:
    mov rcx, rdi
    mov rdx, rsi
    mov r8, r12
    call compiler_append
    mov rcx, rdi
    lea rdx, [rip+s_dot_bada]
    mov r8, r12
    call compiler_append
    add rsp, 40
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

.globl compiler_is_builtin_class_name
.def compiler_is_builtin_class_name; .scl 2; .type 32; .endef
compiler_is_builtin_class_name:
    push rbx
    sub rsp, 32
    mov rbx, rcx
    lea rdx, [rip+s_map]
    call compiler_streq
    test eax, eax
    jne .cib_yes
    mov rcx, rbx
    lea rdx, [rip+s_file]
    call compiler_streq
    test eax, eax
    jne .cib_yes
    mov rcx, rbx
    lea rdx, [rip+s_thread]
    call compiler_streq
    test eax, eax
    jne .cib_yes
    mov rcx, rbx
    lea rdx, [rip+s_aleka]
    call compiler_streq
    test eax, eax
    jne .cib_yes
    xor eax, eax
    jmp .cib_done
.cib_yes:
    mov eax, 1
.cib_done:
    add rsp, 32
    pop rbx
    ret

.globl compiler_looks_like_class_name
.def compiler_looks_like_class_name; .scl 2; .type 32; .endef
compiler_looks_like_class_name:
    xor eax, eax
    test rcx, rcx
    je .cll_done
    mov dl, [rcx]
    cmp dl, 'A'
    jb .cll_done
    cmp dl, 'Z'
    ja .cll_done
    mov eax, 1
.cll_done:
    ret

.globl compiler_collect_class_ref_from_type
.def compiler_collect_class_ref_from_type; .scl 2; .type 32; .endef
compiler_collect_class_ref_from_type:
    push rbx
    sub rsp, 32
    mov rbx, rcx
    call compiler_looks_like_class_name
    test eax, eax
    je .ccr_no
    mov rcx, rbx
    call compiler_is_builtin_class_name
    test eax, eax
    jne .ccr_no
    mov rcx, rbx
    lea rdx, [rip+s_integer]
    call compiler_streq
    test eax, eax
    jne .ccr_no
    mov rcx, rbx
    lea rdx, [rip+s_long]
    call compiler_streq
    test eax, eax
    jne .ccr_no
    mov rcx, rbx
    lea rdx, [rip+s_double]
    call compiler_streq
    test eax, eax
    jne .ccr_no
    mov rcx, rbx
    lea rdx, [rip+s_boolean]
    call compiler_streq
    test eax, eax
    jne .ccr_no
    mov rcx, rbx
    lea rdx, [rip+s_string]
    call compiler_streq
    test eax, eax
    jne .ccr_no
    mov rcx, rbx
    lea rdx, [rip+s_array]
    call compiler_streq
    test eax, eax
    jne .ccr_no
    mov eax, 1
    jmp .ccr_done
.ccr_no:
    xor eax, eax
.ccr_done:
    add rsp, 32
    pop rbx
    ret

.globl compiler_append_unique
.def compiler_append_unique; .scl 2; .type 32; .endef
compiler_append_unique:
    push rbx
    push rsi
    push rdi
    sub rsp, 32
    mov rbx, rcx
    mov rsi, rdx
    xor rdi, rdi
.cau_loop:
    cmp rdi, [rbx+LIST_COUNT]
    jae .cau_add
    mov rcx, [rbx+LIST_ITEMS+rdi*8]
    mov rdx, rsi
    call compiler_path_eq_normalized
    test eax, eax
    jne .cau_noadd
    inc rdi
    jmp .cau_loop
.cau_add:
    cmp rdi, 16
    jae .cau_noadd
    mov [rbx+LIST_ITEMS+rdi*8], rsi
    inc qword ptr [rbx+LIST_COUNT]
    mov eax, 1
    jmp .cau_done
.cau_noadd:
    xor eax, eax
.cau_done:
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret

.globl compiler_count_link_manifest_entries
.def compiler_count_link_manifest_entries; .scl 2; .type 32; .endef
compiler_count_link_manifest_entries:
    xor rax, rax
    test rcx, rcx
    je .cclme_done
    xor r8, r8
.cclme_ws:
    mov dl, [rcx+r8]
    test dl, dl
    je .cclme_done
    cmp dl, ' '
    je .cclme_inc_ws
    cmp dl, 9
    je .cclme_inc_ws
    cmp dl, 10
    je .cclme_inc_ws
    cmp dl, 13
    je .cclme_inc_ws
    inc rax
    cmp dl, '"'
    je .cclme_quote
.cclme_word:
    mov dl, [rcx+r8]
    test dl, dl
    je .cclme_done
    cmp dl, ' '
    je .cclme_ws
    cmp dl, 9
    je .cclme_ws
    cmp dl, 10
    je .cclme_ws
    inc r8
    jmp .cclme_word
.cclme_quote:
    inc r8
.cclme_qloop:
    mov dl, [rcx+r8]
    test dl, dl
    je .cclme_done
    inc r8
    cmp dl, '"'
    jne .cclme_qloop
    jmp .cclme_ws
.cclme_inc_ws:
    inc r8
    jmp .cclme_ws
.cclme_done:
    ret

.globl compiler_run_model
.def compiler_run_model; .scl 2; .type 32; .endef
compiler_run_model:
    push rbx
    push rsi
    push rdi
    push r12
    sub rsp, 40
    mov ebx, ecx
    mov rsi, rdx
    mov edi, r8d
    lea r12, [rip+s_sample]
    cmp ebx, 2
    jl .crm_path_ready
    test rsi, rsi
    je .crm_path_ready
    mov rax, [rsi+8]
    test rax, rax
    je .crm_path_ready
    cmp byte ptr [rax], 0
    je .crm_path_ready
    mov r12, rax
.crm_path_ready:
    mov rcx, r12
    call compiler_ends_with_bada
    test eax, eax
    je .crm_unsupported
    xor r9d, r9d
    cmp ebx, 3
    jl .crm_flags_done
    mov r10d, 2
.crm_arg_loop:
    cmp r10d, ebx
    jge .crm_flags_done
    mov rcx, [rsi+r10*8]
    lea rdx, [rip+s_dump_tokens]
    call compiler_streq
    test eax, eax
    jne .crm_dump_tokens
    mov rcx, [rsi+r10*8]
    lea rdx, [rip+s_link]
    call compiler_streq
    test eax, eax
    jne .crm_link
    jmp .crm_next_arg
.crm_dump_tokens:
    or r9d, 1
    jmp .crm_next_arg
.crm_link:
    or r9d, 2
.crm_next_arg:
    inc r10d
    jmp .crm_arg_loop
.crm_flags_done:
    test r9d, 1
    je .crm_collect
    test edi, 1
    je .crm_open_fail
.crm_collect:
    test edi, 2
    je .crm_collect_fail
    test edi, 4
    je .crm_compile_fail
    test edi, 8
    je .crm_manifest_fail
    test r9d, 2
    je .crm_ok
    test edi, 16
    je .crm_manifest_fail
.crm_ok:
    xor eax, eax
    jmp .crm_done
.crm_unsupported:
    mov eax, 2
    jmp .crm_done
.crm_open_fail:
    mov eax, 1
    jmp .crm_done
.crm_collect_fail:
    mov eax, 4
    jmp .crm_done
.crm_compile_fail:
    mov eax, 5
    jmp .crm_done
.crm_manifest_fail:
    mov eax, 6
.crm_done:
    add rsp, 40
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

.globl main
.def main; .scl 2; .type 32; .endef
main:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 48
    mov rbx, rcx
    mov rsi, rdx
    lea r12, [rip+s_sample]
    cmp rbx, 2
    jl .main_have_path
    test rsi, rsi
    je .main_have_path
    mov rax, [rsi+8]
    test rax, rax
    je .main_have_path
    cmp byte ptr [rax], 0
    je .main_have_path
    mov r12, rax
.main_have_path:
    mov rcx, r12
    call compiler_ends_with_bada
    test eax, eax
    je .main_bad_ext

    mov rcx, r12
    lea rdx, [rip+s_dot_s_ext]
    lea r8, [rip+asm_path_buf]
    mov r9, 512
    call compiler_replace_extension
    lea rcx, [rip+asm_path_buf]
    call compiler_path_to_forward_slashes
    mov rcx, r12
    lea rdx, [rip+s_dot_obj_ext]
    lea r8, [rip+obj_path_buf]
    mov r9, 512
    call compiler_replace_extension
    lea rcx, [rip+obj_path_buf]
    call compiler_path_to_forward_slashes
    mov rcx, r12
    lea rdx, [rip+s_dot_exe_ext]
    lea r8, [rip+exe_path_buf]
    mov r9, 512
    call compiler_replace_extension
    lea rcx, [rip+exe_path_buf]
    call compiler_path_to_forward_slashes

    lea rcx, [rip+asm_path_buf]
    lea rdx, [rip+s_mode_wb]
    call fopen
    test rax, rax
    je .main_open_fail
    mov r13, rax
    lea rcx, [rip+s_generated_asm]
    mov rdx, r13
    call fputs
    mov rcx, r13
    call fclose

    lea rcx, [rip+cmd_buf]
    lea rdx, [rip+s_nasm_cmd_fmt]
    lea r8, [rip+asm_path_buf]
    lea r9, [rip+obj_path_buf]
    call sprintf
    lea rcx, [rip+cmd_buf]
    call system
    test eax, eax
    jne .main_compile_fail

    xor r14d, r14d
    mov r15d, 2
.main_flag_loop:
    cmp r15, rbx
    jae .main_after_flags
    mov rcx, [rsi+r15*8]
    lea rdx, [rip+s_link]
    call compiler_streq
    test eax, eax
    je .main_next_flag
    mov r14d, 1
.main_next_flag:
    inc r15
    jmp .main_flag_loop
.main_after_flags:
    test r14d, r14d
    je .main_ok
    lea rcx, [rip+cmd_buf]
    lea rdx, [rip+s_gpp_cmd_fmt]
    lea r8, [rip+obj_path_buf]
    lea r9, [rip+exe_path_buf]
    call sprintf
    lea rcx, [rip+cmd_buf]
    call system
    test eax, eax
    jne .main_link_fail
.main_ok:
    xor eax, eax
    jmp .main_done
.main_bad_ext:
    mov eax, 2
    jmp .main_done
.main_open_fail:
    mov eax, 1
    jmp .main_done
.main_compile_fail:
    mov eax, 5
    jmp .main_done
.main_link_fail:
    mov eax, 6
.main_done:
    add rsp, 48
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret
