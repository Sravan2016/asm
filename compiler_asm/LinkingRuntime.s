.intel_syntax noprefix

.equ ST_ABI, 0
.equ ST_NASM, 8
.equ ST_GCC, 136
.equ ST_RUNTIME, 264
.equ ST_BUFFER, 392
.equ ST_LEN, 400
.equ ST_CAP, 408

.equ MODULE_STRINGS, 0
.equ MODULE_STRING_COUNT, 8
.equ MODULE_GLOBALS, 16
.equ MODULE_GLOBAL_COUNT, 24
.equ MODULE_FUNCTIONS, 32
.equ MODULE_FUNCTION_COUNT, 40

.equ STRING_NAME, 0
.equ STRING_VALUE, 32
.equ STRING_SIZE, 96
.equ GLOBAL_NAME, 0
.equ GLOBAL_SIZE, 32
.equ FUNC_NAME, 0
.equ FUNC_SIZE, 32

.section .rdata
s_nasm: .asciz "nasm"
s_gcc: .asciz "g++"
s_runtime: .asciz "build/asm_pure_obj"
s_slash: .asciz "/"
s_dot_s: .asciz ".s"
s_dot_obj: .asciz ".obj"
s_section_data: .asciz "section .data\n"
s_section_bss: .asciz "\nsection .bss\n"
s_section_text: .asciz "\nsection .text\n"
s_db: .asciz "_data db "
s_zero_nl: .asciz "0\n"
s_dq: .asciz " dq "
s_data_len: .asciz "_data, "
s_resq: .asciz " resq 1\n"
s_extern_print: .asciz "    extern print_cstr\n    extern print_string\n    extern string_concat\n    extern int_add\n    extern array_create\n    extern map_create\n"
s_global_main: .asciz "    global main\n"
s_main: .asciz "main:\n    push rbp\n    mov rbp, rsp\n    call "
s_main_tail: .asciz "\n    xor rax, rax\n    leave\n    ret\n"
s_func_tail: .asciz ":\n    push rbp\n    mov rbp, rsp\n    xor rax, rax\n    leave\n    ret\n"
s_runtime_init: .asciz "    ; === Runtime Initialization (System V AMD64 ABI) ===\n    ; Stack is already 16-byte aligned after prologue\n    call runtime_init    ; initialize stdout handle\n    call thread_init     ; initialize TLS and critical section\n\n"
s_mov: .asciz "    mov "
s_comma: .asciz ", "
s_nl: .asciz "\n"
s_push_extra: .asciz "    ; Push extra args beyond 6th\n"
s_push_rax: .asciz "    push rax\n"
s_align: .asciz "    ; Ensure 16-byte stack alignment before call\n    and rsp, -16\n"
s_call: .asciz "    call "
s_add_rsp: .asciz "    add rsp, "
s_mov_result: .asciz "    mov "
s_rax: .asciz "rax"
s_void: .asciz "void"
s_quote: .asciz "\""
s_space: .asciz " "
s_quote_comma_zero_nl: .asciz "\", 0\n"
s_comma_space: .asciz ", "
s_global_main_call: .asciz "    ; generated entry point\n"
s_assemble_prefix: .asciz " -f win64 "
s_link_obj_sep: .asciz " "
s_build_generated: .asciz "; build_executable generated assembly and link commands\n"
s_known_objects: .asciz "string.obj integer.obj array.obj boolean.obj map.obj readwritefile.obj heap.obj"
s_known_libraries: .asciz "ntdll ws2_32"
s_file_open: .asciz "file_open"
s_file_read_all: .asciz "file_read_all"
s_file_get_line_at: .asciz "file_get_line_at"
s_file_write: .asciz "file_write"
s_file_append: .asciz "file_append"
s_file_exists: .asciz "file_exists"
s_array_join: .asciz "array_join"
s_array_join_strings: .asciz "array_join_strings"
s_map_to_string: .asciz "map_to_string"
s_gcc_o: .asciz " -o "
s_lntdll: .asciz " -lntdll -lws2_32"
s_nasm_win: .asciz " -f win64 -o "
s_string_obj: .asciz "string.obj"
s_integer_obj: .asciz "integer.obj"
s_array_obj: .asciz "array.obj"
s_boolean_obj: .asciz "boolean.obj"
s_map_obj: .asciz "map.obj"
s_readwrite_obj: .asciz "readwritefile.obj"
s_heap_obj: .asciz "heap.obj"
s_print_cstr: .asciz "print_cstr"
s_string_mod: .asciz "string.obj"
s_int_add: .asciz "int_add"
s_integer_mod: .asciz "integer.obj"
s_array_create: .asciz "array_create"
s_array_mod: .asciz "array.obj"
s_map_create: .asciz "map_create"
s_map_mod: .asciz "map.obj"
s_empty: .asciz ""
s_rdi: .asciz "rdi"
s_rsi: .asciz "rsi"
s_rdx: .asciz "rdx"
s_rcx: .asciz "rcx"
s_r8: .asciz "r8"
s_r9: .asciz "r9"
s_win_rcx: .asciz "rcx"
s_rbx: .asciz "rbx"
s_r12: .asciz "r12"
s_r13: .asciz "r13"
s_r14: .asciz "r14"
s_r15: .asciz "r15"
s_unknown: .asciz "Unknown"

.text
.globl linking_strlen
.def linking_strlen; .scl 2; .type 32; .endef
linking_strlen:
    xor rax, rax
    test rcx, rcx
    je .strlen_done
.strlen_loop:
    cmp byte ptr [rcx+rax], 0
    je .strlen_done
    inc rax
    jmp .strlen_loop
.strlen_done:
    ret

.globl linking_streq
.def linking_streq; .scl 2; .type 32; .endef
linking_streq:
    test rcx, rcx
    je .eq_no
    test rdx, rdx
    je .eq_no
.eq_loop:
    mov r8b, [rcx]
    cmp r8b, [rdx]
    jne .eq_no
    test r8b, r8b
    je .eq_yes
    inc rcx
    inc rdx
    jmp .eq_loop
.eq_yes:
    mov eax, 1
    ret
.eq_no:
    xor eax, eax
    ret

.globl linking_copy_cstr
.def linking_copy_cstr; .scl 2; .type 32; .endef
linking_copy_cstr:
    xor eax, eax
    test rcx, rcx
    je .copy_done
    test r8, r8
    je .copy_done
    test rdx, rdx
    jne .copy_loop
    mov byte ptr [rcx], 0
    ret
.copy_loop:
    cmp r8, 1
    jbe .copy_term
    mov al, [rdx]
    test al, al
    je .copy_term
    mov [rcx], al
    inc rcx
    inc rdx
    dec r8
    jmp .copy_loop
.copy_term:
    mov byte ptr [rcx], 0
    mov eax, 1
.copy_done:
    ret

.globl linking_append_cstr
.def linking_append_cstr; .scl 2; .type 32; .endef
linking_append_cstr:
    push rbx
    push rsi
    push rdi
    sub rsp, 32
    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8
    test rbx, rbx
    je .append_done
    test rsi, rsi
    je .append_done
.seek:
    cmp rdi, 1
    jbe .append_done
    cmp byte ptr [rbx], 0
    je .emit
    inc rbx
    dec rdi
    jmp .seek
.emit:
    mov rcx, rbx
    mov rdx, rsi
    mov r8, rdi
    call linking_copy_cstr
.append_done:
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret

.globl linking_append_int
.def linking_append_int; .scl 2; .type 32; .endef
linking_append_int:
    push rbx
    push rsi
    push rdi
    sub rsp, 80
    mov rbx, rcx
    mov rdi, r8
    mov rax, rdx
    lea rsi, [rsp+71]
    mov byte ptr [rsi], 0
.int_loop:
    xor edx, edx
    mov r10d, 10
    div r10
    add dl, '0'
    dec rsi
    mov [rsi], dl
    test rax, rax
    jne .int_loop
    mov rcx, rbx
    mov rdx, rsi
    mov r8, rdi
    call linking_append_cstr
    add rsp, 80
    pop rdi
    pop rsi
    pop rbx
    ret

.globl linking_init
.def linking_init; .scl 2; .type 32; .endef
linking_init:
    push rbx
    sub rsp, 32
    mov rbx, rcx
    test rbx, rbx
    je .init_done
    mov [rbx+ST_ABI], edx
    lea rcx, [rbx+ST_NASM]
    lea rdx, [rip+s_nasm]
    mov r8, 128
    call linking_copy_cstr
    lea rcx, [rbx+ST_GCC]
    lea rdx, [rip+s_gcc]
    mov r8, 128
    call linking_copy_cstr
    lea rcx, [rbx+ST_RUNTIME]
    lea rdx, [rip+s_runtime]
    mov r8, 128
    call linking_copy_cstr
    mov qword ptr [rbx+ST_BUFFER], 0
    mov qword ptr [rbx+ST_LEN], 0
    mov qword ptr [rbx+ST_CAP], 0
.init_done:
    add rsp, 32
    pop rbx
    ret

.globl linking_set_nasm_path
.def linking_set_nasm_path; .scl 2; .type 32; .endef
linking_set_nasm_path:
    add rcx, ST_NASM
    mov r8, 128
    jmp linking_copy_cstr

.globl linking_set_gcc_path
.def linking_set_gcc_path; .scl 2; .type 32; .endef
linking_set_gcc_path:
    add rcx, ST_GCC
    mov r8, 128
    jmp linking_copy_cstr

.globl linking_set_runtime_dir
.def linking_set_runtime_dir; .scl 2; .type 32; .endef
linking_set_runtime_dir:
    add rcx, ST_RUNTIME
    mov r8, 128
    jmp linking_copy_cstr

.globl linking_get_abi
.def linking_get_abi; .scl 2; .type 32; .endef
linking_get_abi:
    xor eax, eax
    test rcx, rcx
    je .ga_done
    mov eax, [rcx+ST_ABI]
.ga_done:
    ret

.globl linking_param_reg_sysv
.def linking_param_reg_sysv; .scl 2; .type 32; .endef
linking_param_reg_sysv:
    cmp ecx, 1
    jne .sysv
    cmp rdx, 0
    je .p_rcx
    cmp rdx, 1
    je .p_rdx
    cmp rdx, 2
    je .p_r8
    cmp rdx, 3
    je .p_r9
    jmp .p_rax
.sysv:
    cmp rdx, 0
    je .p_rdi
    cmp rdx, 1
    je .p_rsi
    cmp rdx, 2
    je .p_rdx
    cmp rdx, 3
    je .p_rcx
    cmp rdx, 4
    je .p_r8
    cmp rdx, 5
    je .p_r9
.p_rax: lea rax, [rip+s_rax]; ret
.p_rdi: lea rax, [rip+s_rdi]; ret
.p_rsi: lea rax, [rip+s_rsi]; ret
.p_rdx: lea rax, [rip+s_rdx]; ret
.p_rcx: lea rax, [rip+s_rcx]; ret
.p_r8: lea rax, [rip+s_r8]; ret
.p_r9: lea rax, [rip+s_r9]; ret

.globl linking_callee_saved_reg
.def linking_callee_saved_reg; .scl 2; .type 32; .endef
linking_callee_saved_reg:
    cmp rcx, 0
    je .c_rbx
    cmp rcx, 1
    je .c_r12
    cmp rcx, 2
    je .c_r13
    cmp rcx, 3
    je .c_r14
    cmp rcx, 4
    je .c_r15
    lea rax, [rip+s_rax]; ret
.c_rbx: lea rax, [rip+s_rbx]; ret
.c_r12: lea rax, [rip+s_r12]; ret
.c_r13: lea rax, [rip+s_r13]; ret
.c_r14: lea rax, [rip+s_r14]; ret
.c_r15: lea rax, [rip+s_r15]; ret

.globl linking_join_path
.def linking_join_path; .scl 2; .type 32; .endef
linking_join_path:
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
    call linking_copy_cstr
    test rbx, rbx
    je .jp_leaf
    cmp byte ptr [rbx], 0
    je .jp_leaf
    mov rcx, rbx
    call linking_strlen
    mov dl, [rbx+rax-1]
    cmp dl, '/'
    je .jp_leaf
    cmp dl, '\\'
    je .jp_leaf
    mov rcx, rdi
    lea rdx, [rip+s_slash]
    mov r8, r12
    call linking_append_cstr
.jp_leaf:
    mov rcx, rdi
    mov rdx, rsi
    mov r8, r12
    call linking_append_cstr
    mov rax, rdi
    add rsp, 40
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

.globl linking_set_output
.def linking_set_output; .scl 2; .type 32; .endef
linking_set_output:
    test rcx, rcx
    je .set_out_done
    mov [rcx+ST_BUFFER], rdx
    mov [rcx+ST_CAP], r8
    mov qword ptr [rcx+ST_LEN], 0
    test rdx, rdx
    je .set_out_done
    test r8, r8
    je .set_out_done
    mov byte ptr [rdx], 0
.set_out_done:
    ret

.globl linking_clear_output
.def linking_clear_output; .scl 2; .type 32; .endef
linking_clear_output:
    test rcx, rcx
    je .clear_done
    mov qword ptr [rcx+ST_LEN], 0
    mov rax, [rcx+ST_BUFFER]
    test rax, rax
    je .clear_done
    mov byte ptr [rax], 0
.clear_done:
    ret

.globl linking_output_append
.def linking_output_append; .scl 2; .type 32; .endef
linking_output_append:
    push rbx
    sub rsp, 32
    mov rbx, rcx
    test rbx, rbx
    je .out_append_done
    mov rcx, [rbx+ST_BUFFER]
    test rcx, rcx
    je .out_append_done
    mov r8, [rbx+ST_CAP]
    call linking_append_cstr
    mov rcx, [rbx+ST_BUFFER]
    call linking_strlen
    mov [rbx+ST_LEN], rax
.out_append_done:
    add rsp, 32
    pop rbx
    ret

.globl linking_generate_runtime_init
.def linking_generate_runtime_init; .scl 2; .type 32; .endef
linking_generate_runtime_init:
    lea rdx, [rip+s_runtime_init]
    jmp linking_output_append

.globl linking_generate_runtime_call
.def linking_generate_runtime_call; .scl 2; .type 32; .endef
linking_generate_runtime_call:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 48
    mov r12, rcx
    mov rbx, rdx
    mov rsi, r8
    mov r13, r9
    mov r14, [rsp+144]
    cmp r13, 6
    jbe .rtc_regs
    mov rcx, r12
    lea rdx, [rip+s_push_extra]
    call linking_output_append
    mov rdi, r13
    dec rdi
.rtc_extra_loop:
    cmp rdi, 6
    jb .rtc_regs
    mov rcx, r12
    lea rdx, [rip+s_mov]
    call linking_output_append
    mov rcx, r12
    lea rdx, [rip+s_rax]
    call linking_output_append
    mov rcx, r12
    lea rdx, [rip+s_comma]
    call linking_output_append
    mov rcx, r12
    mov rdx, [rsi+rdi*8]
    call linking_output_append
    mov rcx, r12
    lea rdx, [rip+s_nl]
    call linking_output_append
    mov rcx, r12
    lea rdx, [rip+s_push_rax]
    call linking_output_append
    dec rdi
    jmp .rtc_extra_loop
.rtc_regs:
    xor rdi, rdi
.rtc_reg_loop:
    cmp rdi, r13
    jae .rtc_call
    cmp rdi, 6
    jae .rtc_call
    mov rcx, r12
    lea rdx, [rip+s_mov]
    call linking_output_append
    xor ecx, ecx
    mov rdx, rdi
    call linking_param_reg_sysv
    mov rcx, r12
    mov rdx, rax
    call linking_output_append
    mov rcx, r12
    lea rdx, [rip+s_comma]
    call linking_output_append
    mov rcx, r12
    mov rdx, [rsi+rdi*8]
    call linking_output_append
    mov rcx, r12
    lea rdx, [rip+s_nl]
    call linking_output_append
    inc rdi
    jmp .rtc_reg_loop
.rtc_call:
    mov rcx, r12
    lea rdx, [rip+s_align]
    call linking_output_append
    mov rcx, r12
    lea rdx, [rip+s_call]
    call linking_output_append
    mov rcx, r12
    mov rdx, rbx
    call linking_output_append
    mov rcx, r12
    lea rdx, [rip+s_nl]
    call linking_output_append
    cmp r13, 6
    jbe .rtc_result
    mov rcx, r12
    lea rdx, [rip+s_add_rsp]
    call linking_output_append
    mov rax, r13
    sub rax, 6
    shl rax, 3
    mov rcx, [r12+ST_BUFFER]
    mov rdx, rax
    mov r8, [r12+ST_CAP]
    call linking_append_int
    mov rcx, r12
    lea rdx, [rip+s_nl]
    call linking_output_append
.rtc_result:
    test r14, r14
    je .rtc_done
    mov rcx, r14
    lea rdx, [rip+s_void]
    call linking_streq
    test eax, eax
    jne .rtc_done
    mov rcx, r12
    lea rdx, [rip+s_mov_result]
    call linking_output_append
    mov rcx, r12
    mov rdx, r14
    call linking_output_append
    mov rcx, r12
    lea rdx, [rip+s_comma]
    call linking_output_append
    mov rcx, r12
    lea rdx, [rip+s_rax]
    call linking_output_append
    mov rcx, r12
    lea rdx, [rip+s_nl]
    call linking_output_append
.rtc_done:
    mov rcx, [r12+ST_BUFFER]
    call linking_strlen
    mov [r12+ST_LEN], rax
    add rsp, 48
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

.globl linking_emit_data_section
.def linking_emit_data_section; .scl 2; .type 32; .endef
linking_emit_data_section:
    push rbx
    push rsi
    push rdi
    push r12
    sub rsp, 40
    mov r12, rcx
    mov rbx, rdx
    mov rcx, r12
    lea rdx, [rip+s_section_data]
    call linking_output_append
    test rbx, rbx
    je .data_done
    mov rsi, [rbx+MODULE_STRINGS]
    mov rdi, [rbx+MODULE_STRING_COUNT]
    xor rbx, rbx
.data_loop:
    cmp rbx, rdi
    jae .data_done
    mov rcx, r12
    lea rdx, [rsi+STRING_NAME]
    call linking_output_append
    mov rcx, r12
    lea rdx, [rip+s_db]
    call linking_output_append
    mov rcx, r12
    lea rdx, [rip+s_quote]
    call linking_output_append
    mov rcx, r12
    lea rdx, [rsi+STRING_VALUE]
    call linking_output_append
    mov rcx, r12
    lea rdx, [rip+s_quote_comma_zero_nl]
    call linking_output_append
    mov rcx, r12
    lea rdx, [rsi+STRING_NAME]
    call linking_output_append
    mov rcx, r12
    lea rdx, [rip+s_dq]
    call linking_output_append
    mov rcx, r12
    lea rdx, [rsi+STRING_NAME]
    call linking_output_append
    mov rcx, r12
    lea rdx, [rip+s_data_len]
    call linking_output_append
    lea rcx, [rsi+STRING_VALUE]
    call linking_strlen
    mov rcx, [r12+ST_BUFFER]
    mov rdx, rax
    mov r8, [r12+ST_CAP]
    call linking_append_int
    mov rcx, r12
    lea rdx, [rip+s_nl]
    call linking_output_append
    add rsi, STRING_SIZE
    inc rbx
    jmp .data_loop
.data_done:
    add rsp, 40
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

.globl linking_emit_bss_section
.def linking_emit_bss_section; .scl 2; .type 32; .endef
linking_emit_bss_section:
    push rbx
    push rsi
    push rdi
    push r12
    sub rsp, 40
    mov r12, rcx
    mov rbx, rdx
    mov rcx, r12
    lea rdx, [rip+s_section_bss]
    call linking_output_append
    test rbx, rbx
    je .bss_done
    mov rsi, [rbx+MODULE_GLOBALS]
    mov rdi, [rbx+MODULE_GLOBAL_COUNT]
    xor rbx, rbx
.bss_loop:
    cmp rbx, rdi
    jae .bss_done
    mov rcx, r12
    lea rdx, [rsi+GLOBAL_NAME]
    call linking_output_append
    mov rcx, r12
    lea rdx, [rip+s_resq]
    call linking_output_append
    add rsi, GLOBAL_SIZE
    inc rbx
    jmp .bss_loop
.bss_done:
    add rsp, 40
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

.globl linking_emit_text_section
.def linking_emit_text_section; .scl 2; .type 32; .endef
linking_emit_text_section:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    sub rsp, 48
    mov r12, rcx
    mov rbx, rdx
    mov r13, r8
    mov rcx, r12
    lea rdx, [rip+s_section_text]
    call linking_output_append
    mov rcx, r12
    lea rdx, [rip+s_extern_print]
    call linking_output_append
    test r13, r13
    je .text_functions
    mov rcx, r12
    lea rdx, [rip+s_global_main]
    call linking_output_append
.text_functions:
    test rbx, rbx
    je .text_done
    mov rsi, [rbx+MODULE_FUNCTIONS]
    mov rdi, [rbx+MODULE_FUNCTION_COUNT]
    test r13, r13
    je .func_loop_setup
    test rdi, rdi
    je .func_loop_setup
    mov rcx, r12
    lea rdx, [rip+s_global_main_call]
    call linking_output_append
    mov rcx, r12
    lea rdx, [rip+s_main]
    call linking_output_append
    mov rcx, r12
    lea rdx, [rsi+FUNC_NAME]
    call linking_output_append
    mov rcx, r12
    lea rdx, [rip+s_main_tail]
    call linking_output_append
.func_loop_setup:
    xor rbx, rbx
.func_loop:
    cmp rbx, rdi
    jae .text_done
    mov rcx, r12
    lea rdx, [rsi+FUNC_NAME]
    call linking_output_append
    mov rcx, r12
    lea rdx, [rip+s_func_tail]
    call linking_output_append
    add rsi, FUNC_SIZE
    inc rbx
    jmp .func_loop
.text_done:
    add rsp, 48
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

.globl linking_generate_assembly
.def linking_generate_assembly; .scl 2; .type 32; .endef
linking_generate_assembly:
    push rbx
    push rsi
    push rdi
    sub rsp, 32
    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8
    call linking_clear_output
    mov rcx, rbx
    mov rdx, rsi
    call linking_emit_data_section
    mov rcx, rbx
    mov rdx, rsi
    call linking_emit_bss_section
    mov rcx, rbx
    mov rdx, rsi
    mov r8, rdi
    call linking_emit_text_section
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret

.globl linking_assemble_to_object
.def linking_assemble_to_object; .scl 2; .type 32; .endef
linking_assemble_to_object:
    push rbx
    push rsi
    push rdi
    sub rsp, 32
    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8
    test rsi, rsi
    je .asm_fail
    cmp byte ptr [rsi], 0
    je .asm_fail
    test rdi, rdi
    je .asm_fail
    cmp byte ptr [rdi], 0
    je .asm_fail
    mov rcx, rbx
    call linking_clear_output
    mov rcx, rbx
    lea rdx, [rbx+ST_NASM]
    call linking_output_append
    mov rcx, rbx
    lea rdx, [rip+s_nasm_win]
    call linking_output_append
    mov rcx, rbx
    mov rdx, rdi
    call linking_output_append
    mov rcx, rbx
    lea rdx, [rip+s_space]
    call linking_output_append
    mov rcx, rbx
    mov rdx, rsi
    call linking_output_append
    mov eax, 1
    jmp .asm_done
.asm_fail:
    xor eax, eax
.asm_done:
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret

.globl linking_link_executable
.def linking_link_executable; .scl 2; .type 32; .endef
linking_link_executable:
    push rbx
    push rsi
    push rdi
    push r12
    sub rsp, 40
    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8
    test rsi, rsi
    je .link_fail
    cmp byte ptr [rsi], 0
    je .link_fail
    test rdi, rdi
    je .link_fail
    cmp byte ptr [rdi], 0
    je .link_fail
    mov rcx, rbx
    call linking_clear_output
    mov rcx, rbx
    lea rdx, [rbx+ST_GCC]
    call linking_output_append
    mov rcx, rbx
    lea rdx, [rip+s_space]
    call linking_output_append
    mov rcx, rbx
    mov rdx, rsi
    call linking_output_append
    mov rcx, rbx
    lea rdx, [rip+s_gcc_o]
    call linking_output_append
    mov rcx, rbx
    mov rdx, rdi
    call linking_output_append
    mov rcx, rbx
    lea rdx, [rip+s_lntdll]
    call linking_output_append
    mov eax, 1
    jmp .link_done
.link_fail:
    xor eax, eax
.link_done:
    add rsp, 40
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

.globl linking_build_executable
.def linking_build_executable; .scl 2; .type 32; .endef
linking_build_executable:
    push rbx
    push rsi
    sub rsp, 40
    mov rbx, rcx
    mov rsi, r8
    test rsi, rsi
    je .build_fail
    cmp byte ptr [rsi], 0
    je .build_fail
    mov rcx, rbx
    call linking_clear_output
    mov rcx, rbx
    lea rdx, [rip+s_build_generated]
    call linking_output_append
    mov rcx, rbx
    mov rdx, rsi
    call linking_output_append
    mov eax, 1
    jmp .build_done
.build_fail:
    xor eax, eax
.build_done:
    add rsp, 40
    pop rsi
    pop rbx
    ret

.globl linking_registry_lookup
.def linking_registry_lookup; .scl 2; .type 32; .endef
linking_registry_lookup:
    push rbx
    sub rsp, 32
    mov rbx, rcx
    mov rcx, rbx
    lea rdx, [rip+s_print_cstr]
    call linking_streq
    test eax, eax
    jne .reg_string
    mov rcx, rbx
    lea rdx, [rip+s_int_add]
    call linking_streq
    test eax, eax
    jne .reg_integer
    mov rcx, rbx
    lea rdx, [rip+s_array_create]
    call linking_streq
    test eax, eax
    jne .reg_array
    mov rcx, rbx
    lea rdx, [rip+s_map_create]
    call linking_streq
    test eax, eax
    jne .reg_map
    xor rax, rax
    jmp .reg_done
.reg_string:
    lea rax, [rip+s_string_mod]
    jmp .reg_done
.reg_integer:
    lea rax, [rip+s_integer_mod]
    jmp .reg_done
.reg_array:
    lea rax, [rip+s_array_mod]
    jmp .reg_done
.reg_map:
    lea rax, [rip+s_map_mod]
.reg_done:
    add rsp, 32
    pop rbx
    ret

.globl linking_registry_required_objects
.def linking_registry_required_objects; .scl 2; .type 32; .endef
linking_registry_required_objects:
    mov r8, rdx
    lea rdx, [rip+s_known_objects]
    jmp linking_copy_cstr

.globl linking_registry_required_libraries
.def linking_registry_required_libraries; .scl 2; .type 32; .endef
linking_registry_required_libraries:
    mov r8, rdx
    lea rdx, [rip+s_known_libraries]
    jmp linking_copy_cstr

.globl linking_runtime_arg_passes_slot_address
.def linking_runtime_arg_passes_slot_address; .scl 2; .type 32; .endef
linking_runtime_arg_passes_slot_address:
    push rbx
    push r12
    sub rsp, 40
    mov r12, rcx
    mov rbx, rdx
    cmp rbx, 0
    jne .slot_second
    mov rcx, r12
    lea rdx, [rip+s_file_open]
    call linking_streq
    test eax, eax
    jne .slot_yes
    mov rcx, r12
    lea rdx, [rip+s_file_write]
    call linking_streq
    test eax, eax
    jne .slot_yes
    mov rcx, r12
    lea rdx, [rip+s_file_append]
    call linking_streq
    test eax, eax
    jne .slot_yes
    mov rcx, r12
    lea rdx, [rip+s_file_exists]
    call linking_streq
    test eax, eax
    jne .slot_yes
    jmp .slot_no
.slot_second:
    cmp rbx, 1
    jne .slot_third
    mov rcx, r12
    lea rdx, [rip+s_file_read_all]
    call linking_streq
    test eax, eax
    jne .slot_yes
    mov rcx, r12
    lea rdx, [rip+s_file_get_line_at]
    call linking_streq
    test eax, eax
    jne .slot_yes
    mov rcx, r12
    lea rdx, [rip+s_map_to_string]
    call linking_streq
    test eax, eax
    jne .slot_yes
    jmp .slot_no
.slot_third:
    cmp rbx, 2
    jne .slot_no
    mov rcx, r12
    lea rdx, [rip+s_array_join]
    call linking_streq
    test eax, eax
    jne .slot_yes
    mov rcx, r12
    lea rdx, [rip+s_array_join_strings]
    call linking_streq
    test eax, eax
    jne .slot_yes
.slot_no:
    xor eax, eax
    jmp .slot_done
.slot_yes:
    mov eax, 1
.slot_done:
    add rsp, 40
    pop r12
    pop rbx
    ret

.globl linking_resolve_runtime_object_path
.def linking_resolve_runtime_object_path; .scl 2; .type 32; .endef
linking_resolve_runtime_object_path:
    jmp linking_join_path
