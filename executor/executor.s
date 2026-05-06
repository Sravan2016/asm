.intel_syntax noprefix

.extern CreateFileA
.extern ReadFile
.extern WriteFile
.extern CloseHandle
.extern VirtualAlloc
.extern GetStdHandle
.extern FindFirstFileA
.extern FindNextFileA
.extern FindClose
.extern GetFileSizeEx
.extern SetFilePointer
.extern DeleteFileA
.extern CreateProcessA
.extern GetExitCodeProcess
.extern system
.extern _i64toa
.extern _gcvt
.extern strtol
.extern strtoll
.extern strtod
.extern CreateThread
.extern WaitForSingleObject
.extern InitializeCriticalSection
.extern EnterCriticalSection
.extern LeaveCriticalSection
.extern TlsAlloc
.extern TlsSetValue

.global main

.equ GENERIC_READ, 0x80000000
.equ FILE_SHARE_READ, 1
.equ OPEN_EXISTING, 3
.equ FILE_ATTRIBUTE_NORMAL, 0x00000080
.equ INVALID_HANDLE_VALUE, -1
.equ MEM_COMMIT_RESERVE, 0x3000
.equ PAGE_EXECUTE_READWRITE, 0x40
.equ PAGE_READWRITE, 0x04
.equ STD_INPUT_HANDLE, -10
.equ STD_OUTPUT_HANDLE, -11
.equ STD_ERROR_HANDLE, -12
.equ INFINITE, 0xFFFFFFFF
.equ STARTF_USESTDHANDLES, 0x00000100
.equ CMDLINE_MAX, 8192

.equ IMAGE_REL_AMD64_ADDR64, 1
.equ IMAGE_REL_AMD64_ADDR32, 2
.equ IMAGE_REL_AMD64_REL32, 4
.equ IMAGE_REL_AMD64_REL32_1, 5
.equ IMAGE_REL_AMD64_REL32_2, 6
.equ IMAGE_REL_AMD64_REL32_3, 7
.equ IMAGE_REL_AMD64_REL32_4, 8
.equ IMAGE_REL_AMD64_REL32_5, 9

.equ COFF_SEC_SIZE, 40
.equ COFF_SYM_SIZE, 18
.equ COFF_RELOC_SIZE, 10

.equ FIND_DATA_CFILE_NAME, 44
.equ MAX_SECTIONS, 96
.equ MAX_SYMS, 16384
.equ SYM_NAME_STORAGE, 262144

.section .data
default_prog_obj: .asciz "sample.obj"
default_runtime_dir: .asciz "..\\build\\asm_pure_obj"
alt_runtime_dir: .asciz ".\\build\\asm_pure_obj"
default_heap_dir: .asciz "..\\build\\asm_file_obj"
alt_heap_dir: .asciz ".\\build\\asm_file_obj"
dash_d: .asciz "-d"
dash_link: .asciz "--link"
dash_o: .asciz " -o "
link_manifest_ext: .asciz ".link"

pat_star_obj: .asciz "*.obj"
name_main: .asciz "main"
msg_load_fail: .asciz "executor_asm: load failed\r\n"
msg_no_main: .asciz "executor_asm: main not found\r\n"
msg_missing_sym: .asciz "executor_asm: missing symbol "
msg_nl: .asciz "\r\n"
msg_fail_file: .asciz "executor_asm: failed file "
msg_run_main: .asciz "executor_asm: running main\r\n"
msg_start: .asciz "executor_asm: start\r\n"
msg_load_string: .asciz "executor_asm: load string\r\n"
msg_load_integer: .asciz "executor_asm: load integer\r\n"
msg_load_prog: .asciz "executor_asm: load program\r\n"
msg_read_ok: .asciz "executor_asm: read ok\r\n"
msg_load_ok: .asciz "executor_asm: load ok\r\n"
msg_coff_start: .asciz "executor_asm: coff start\r\n"
msg_coff_copied: .asciz "executor_asm: coff sections ok\r\n"
msg_coff_syms: .asciz "executor_asm: coff syms ok\r\n"
msg_coff_reloc: .asciz "executor_asm: coff reloc start\r\n"
msg_coff_done: .asciz "executor_asm: coff done\r\n"
runtime_string_obj: .asciz "string.obj"
runtime_integer_obj: .asciz "integer.obj"
runtime_array_obj: .asciz "array.obj"
runtime_boolean_obj: .asciz "boolean.obj"
runtime_double_obj: .asciz "double.obj"
runtime_file_obj: .asciz "file.obj"
runtime_httpclient_obj: .asciz "httpclient.obj"
runtime_httpserver_obj: .asciz "httpserver.obj"
runtime_long_obj: .asciz "long.obj"
runtime_map_obj: .asciz "map.obj"
runtime_sock_obj: .asciz "sock.obj"
runtime_thread_obj: .asciz "thread.obj"
runtime_badaapi_ptrs_obj: .asciz "badaapi_ptrs.obj"
runtime_heap_obj: .asciz "heap.obj"

gcc_path: .asciz "C:\\Strawberry\\c\\bin\\gcc.exe"
out_exe: .asciz "bada_run.exe"
link_libs: .asciz " -lntdll -lws2_32 -lkernel32 -lkernel32 -luser32 -lgdi32 -lwinspool -lshell32 -lole32 -loleaut32 -luuid -lcomdlg32 -ladvapi32"
msg_link_fail: .asciz "executor_asm: link failed\r\n"
msg_run_fail: .asciz "executor_asm: run failed\r\n"

sym_CreateFileA: .asciz "CreateFileA"
sym_ReadFile: .asciz "ReadFile"
sym_WriteFile: .asciz "WriteFile"
sym_CloseHandle: .asciz "CloseHandle"
sym_VirtualAlloc: .asciz "VirtualAlloc"
sym_GetStdHandle: .asciz "GetStdHandle"
sym_GetFileSizeEx: .asciz "GetFileSizeEx"
sym_SetFilePointer: .asciz "SetFilePointer"
sym_DeleteFileA: .asciz "DeleteFileA"
sym__i64toa: .asciz "_i64toa"
sym__gcvt: .asciz "_gcvt"
sym_strtol: .asciz "strtol"
sym_strtoll: .asciz "strtoll"
sym_strtod: .asciz "strtod"
sym_CreateThread: .asciz "CreateThread"
sym_WaitForSingleObject: .asciz "WaitForSingleObject"
sym_InitializeCriticalSection: .asciz "InitializeCriticalSection"
sym_EnterCriticalSection: .asciz "EnterCriticalSection"
sym_LeaveCriticalSection: .asciz "LeaveCriticalSection"
sym_TlsAlloc: .asciz "TlsAlloc"
sym_TlsSetValue: .asciz "TlsSetValue"
sym_runtime_init: .asciz "runtime_init"
sym_print_cstr: .asciz "print_cstr"
sym_print_string: .asciz "print_string"
sym_print_uint: .asciz "print_uint"
sym_string_from_cstr: .asciz "string_from_cstr"
sym_string_free: .asciz "string_free"
sym_int_add: .asciz "int_add"
sym_int_sub: .asciz "int_sub"
sym_int_mul: .asciz "int_mul"
sym_int_div: .asciz "int_div"
test_msg: .asciz "runtime print_cstr ok\r\n"

.section .bss
.align 8
bytes_read: .quad 0
file_size:  .quad 0
file_buf:   .quad 0

find_data:   .space 320
obj_path:    .space 512
pattern_buf: .space 512

section_offs: .space (MAX_SECTIONS * 4)
section_size: .space (MAX_SECTIONS * 4)
section_base: .space ((MAX_SECTIONS + 1) * 8)

sym_count: .quad 0
sym_name_off: .quad 0
sym_name_ptrs: .space (MAX_SYMS * 8)
sym_addrs:     .space (MAX_SYMS * 8)
sym_name_storage: .space SYM_NAME_STORAGE
sym_tmp_name: .space 32
cmdline_buf: .space CMDLINE_MAX
link_path:   .space 512

.section .text

strlen_asm:
    xor rax, rax
.sl_loop:
    mov dl, byte ptr [rcx + rax]
    test dl, dl
    jz .sl_done
    inc rax
    jmp .sl_loop
.sl_done:
    ret

string_equals:
.eq_loop:
    mov al, byte ptr [rcx]
    mov r8b, byte ptr [rdx]
    cmp al, r8b
    jne .eq_no
    test al, al
    jz .eq_yes
    inc rcx
    inc rdx
    jmp .eq_loop
.eq_yes:
    mov eax, 1
    ret
.eq_no:
    xor eax, eax
    ret

mem_copy:
    push rsi
    push rdi
    mov rdi, rcx
    mov rsi, rdx
    mov rcx, r8
    cld
    rep movsb
    pop rdi
    pop rsi
    ret

mem_zero:
    push rdi
    xor eax, eax
    mov rdi, rcx
    mov rcx, rdx
    cld
    rep stosb
    pop rdi
    ret

write_console:
    push rbx
    sub rsp, 64
    mov rbx, rcx
    mov ecx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov r10, rax
    mov rcx, rbx
    call strlen_asm
    mov r8, rax
    mov rcx, r10
    mov rdx, rbx
    lea r9, [rsp + 56]
    mov qword ptr [rsp + 32], 0
    call WriteFile
    add rsp, 64
    pop rbx
    ret

sym_find:
    push rbx
    push r12
    mov r12, rcx
    mov rbx, qword ptr [rip + sym_count]
    xor r9d, r9d
.sf_loop:
    cmp r9, rbx
    jae .sf_none
    mov r8, r9
    shl r8, 3
    lea r10, [rip + sym_name_ptrs]
    mov rax, qword ptr [r10 + r8]
    mov rcx, r12
    mov rdx, rax
    call string_equals
    test eax, eax
    jnz .sf_yes
    inc r9
    jmp .sf_loop
.sf_yes:
    lea r10, [rip + sym_addrs]
    mov rax, qword ptr [r10 + r8]
    pop r12
    pop rbx
    ret
.sf_none:
    xor rax, rax
    pop r12
    pop rbx
    ret

sym_add:
    push rbx
    push r12
    push r13
    sub rsp, 32
    mov r12, rcx
    mov r13, rdx

    mov rcx, r12
    call sym_find
    test rax, rax
    jnz .sa_ok

    mov rax, qword ptr [rip + sym_count]
    cmp rax, MAX_SYMS
    jae .sa_fail

    mov rcx, r12
    call strlen_asm
    inc rax
    mov rbx, qword ptr [rip + sym_name_off]
    lea r11, [rbx + rax]
    cmp r11, SYM_NAME_STORAGE
    ja .sa_fail

    lea rdx, [rip + sym_name_storage]
    add rdx, rbx
    mov r8, rdx
.sa_copy:
    mov al, byte ptr [r12]
    mov byte ptr [r8], al
    inc r12
    inc r8
    inc rbx
    test al, al
    jnz .sa_copy

    mov qword ptr [rip + sym_name_off], rbx
    mov rax, qword ptr [rip + sym_count]
    mov r9, rax
    shl r9, 3
    lea r10, [rip + sym_name_ptrs]
    mov qword ptr [r10 + r9], rdx
    lea r10, [rip + sym_addrs]
    mov qword ptr [r10 + r9], r13
    inc rax
    mov qword ptr [rip + sym_count], rax
.sa_ok:
    mov eax, 1
    add rsp, 32
    pop r13
    pop r12
    pop rbx
    ret
.sa_fail:
    xor eax, eax
    add rsp, 32
    pop r13
    pop r12
    pop rbx
    ret

get_sym_name:
    push rbx
    push r12
    mov r12, rcx
    mov rbx, rdx
    mov eax, dword ptr [r12]
    test eax, eax
    jnz .gs_inline
    mov eax, dword ptr [r12 + 4]
    lea rax, [rbx + rax]
    pop r12
    pop rbx
    ret
.gs_inline:
    lea rax, [rip + sym_tmp_name]
    xor ecx, ecx
.gs_inl:
    cmp ecx, 8
    jae .gs_term
    mov dl, byte ptr [r12 + rcx]
    mov byte ptr [rax + rcx], dl
    test dl, dl
    jz .gs_done
    inc ecx
    jmp .gs_inl
.gs_term:
    mov byte ptr [rax + 8], 0
.gs_done:
    mov byte ptr [rax + rcx], 0
    pop r12
    pop rbx
    ret

align16_u32:
    mov eax, ecx
    add eax, 15
    and eax, 0xFFFFFFF0
    ret

read_entire_file:
    push rbx
    sub rsp, 96
    mov rbx, rcx

    mov rcx, rbx
    mov edx, GENERIC_READ
    mov r8d, FILE_SHARE_READ
    xor r9d, r9d
    mov qword ptr [rsp + 32], OPEN_EXISTING
    mov qword ptr [rsp + 40], FILE_ATTRIBUTE_NORMAL
    mov qword ptr [rsp + 48], 0
    call CreateFileA
    cmp rax, INVALID_HANDLE_VALUE
    je .ref_fail
    mov qword ptr [rsp + 88], rax

    mov rcx, qword ptr [rsp + 88]
    lea rdx, [rip + file_size]
    call GetFileSizeEx
    test eax, eax
    jz .ref_close_fail

    mov rax, qword ptr [rip + file_size]
    test rax, rax
    jz .ref_close_fail

    xor ecx, ecx
    mov rdx, rax
    mov r8d, MEM_COMMIT_RESERVE
    mov r9d, PAGE_READWRITE
    call VirtualAlloc
    test rax, rax
    jz .ref_close_fail
    mov qword ptr [rip + file_buf], rax

    mov rcx, qword ptr [rsp + 88]
    mov rdx, qword ptr [rip + file_buf]
    mov r8, qword ptr [rip + file_size]
    lea r9, [rip + bytes_read]
    mov qword ptr [rsp + 32], 0
    call ReadFile
    test eax, eax
    jz .ref_close_fail

    mov rcx, qword ptr [rsp + 88]
    call CloseHandle

    mov rax, qword ptr [rip + file_buf]
    mov rdx, qword ptr [rip + file_size]
    add rsp, 96
    pop rbx
    ret

.ref_close_fail:
    mov rcx, qword ptr [rsp + 88]
    call CloseHandle
.ref_fail:
    xor rax, rax
    xor rdx, rdx
    add rsp, 96
    pop rbx
    ret

load_coff_obj:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 160
    mov r12, rcx
    mov r13, rdx
    lea rcx, [rip + msg_coff_start]
    call write_console

    movzx r14d, word ptr [r12 + 2]
    test r14d, r14d
    jz .lco_fail
    cmp r14d, MAX_SECTIONS
    ja .lco_fail

    mov eax, dword ptr [r12 + 8]
    mov dword ptr [rsp + 120], eax
    mov eax, dword ptr [r12 + 12]
    mov dword ptr [rsp + 116], eax

    movzx eax, word ptr [r12 + 16]
    lea r15, [r12 + 20]
    add r15, rax
    mov qword ptr [rsp + 104], r15

    xor ebx, ebx
    xor r11d, r11d
.lco_layout:
    cmp ebx, r14d
    jae .lco_layout_done
    mov eax, ebx
    imul eax, COFF_SEC_SIZE
    mov r15, qword ptr [rsp + 104]
    lea r10, [r15 + rax]
    mov eax, dword ptr [r10 + 8]
    mov edx, dword ptr [r10 + 16]
    cmp eax, edx
    cmovb eax, edx
    mov ecx, eax
    call align16_u32
    mov ecx, ebx
    inc ecx
    lea r8, [rip + section_offs]
    mov dword ptr [r8 + rcx*4], r11d
    lea r8, [rip + section_size]
    mov dword ptr [r8 + rcx*4], eax
    add r11d, eax
    inc ebx
    jmp .lco_layout
.lco_layout_done:
    mov dword ptr [rsp + 112], r11d

    xor ecx, ecx
    mov edx, r11d
    mov r8d, MEM_COMMIT_RESERVE
    mov r9d, PAGE_EXECUTE_READWRITE
    call VirtualAlloc
    test rax, rax
    jz .lco_fail
    mov qword ptr [rsp + 96], rax

    xor ebx, ebx
.lco_copy:
    cmp ebx, r14d
    jae .lco_copy_done
    mov eax, ebx
    imul eax, COFF_SEC_SIZE
    mov r15, qword ptr [rsp + 104]
    lea r10, [r15 + rax]
    mov ecx, ebx
    inc ecx
    lea r8, [rip + section_offs]
    mov edx, dword ptr [r8 + rcx*4]
    mov rax, qword ptr [rsp + 96]
    lea r9, [rax + rdx]
    lea r8, [rip + section_base]
    mov qword ptr [r8 + rcx*8], r9
    mov eax, dword ptr [r10 + 16]
    test eax, eax
    jz .lco_zero
    mov edx, dword ptr [r10 + 20]
    test edx, edx
    jz .lco_zero_raw
    lea rcx, [r9]
    lea rdx, [r12 + rdx]
    mov r8d, eax
    call mem_copy
    jmp .lco_next
.lco_zero_raw:
    lea rcx, [r9]
    mov edx, eax
    call mem_zero
    jmp .lco_next
.lco_zero:
    mov eax, dword ptr [r10 + 8]
    test eax, eax
    jz .lco_next
    lea rcx, [r9]
    mov edx, eax
    call mem_zero
.lco_next:
    inc ebx
    jmp .lco_copy
.lco_copy_done:
    lea rcx, [rip + msg_coff_copied]
    call write_console

    mov eax, dword ptr [rsp + 120]
    test eax, eax
    jz .lco_fail
    lea rbx, [r12 + rax]
    mov eax, dword ptr [rsp + 116]
    imul eax, COFF_SYM_SIZE
    lea rdx, [rbx + rax]
    mov qword ptr [rsp + 88], rdx

    xor ebx, ebx
.lco_add_syms:
    mov eax, dword ptr [rsp + 116]
    cmp ebx, eax
    jae .lco_relocate
    mov eax, ebx
    imul eax, COFF_SYM_SIZE
    mov edx, dword ptr [rsp + 120]
    lea r10, [r12 + rdx]
    add r10, rax
    movzx eax, byte ptr [r10 + 16]
    cmp eax, 2
    jne .lco_sym_skip
    movsx eax, word ptr [r10 + 12]
    cmp eax, 0
    jle .lco_sym_skip
    mov r15d, eax
    mov rcx, r10
    mov rdx, qword ptr [rsp + 88]
    call get_sym_name
    mov r11, rax
    lea r8, [rip + section_base]
    mov rax, qword ptr [r8 + r15*8]
    mov edx, dword ptr [r10 + 8]
    add rax, rdx
    mov rcx, r11
    mov rdx, rax
    call sym_add
.lco_sym_skip:
    movzx eax, byte ptr [r10 + 17]
    inc ebx
    add ebx, eax
    jmp .lco_add_syms

.lco_relocate:
    lea rcx, [rip + msg_coff_syms]
    call write_console
    lea rcx, [rip + msg_coff_reloc]
    call write_console
    xor ebx, ebx
.lco_reloc_sec:
    cmp ebx, r14d
    jae .lco_ok
    mov eax, ebx
    imul eax, COFF_SEC_SIZE
    mov r15, qword ptr [rsp + 104]
    lea r10, [r15 + rax]
    movzx eax, word ptr [r10 + 32]
    test eax, eax
    jz .lco_reloc_next_sec
    mov dword ptr [rsp + 44], eax
    mov eax, dword ptr [r10 + 24]
    test eax, eax
    jz .lco_fail
    lea rax, [r12 + rax]
    mov qword ptr [rsp + 48], rax
    mov dword ptr [rsp + 40], 0
.lco_reloc_loop:
    mov eax, dword ptr [rsp + 40]
    cmp eax, dword ptr [rsp + 44]
    jae .lco_reloc_next_sec
    mov ecx, eax
    imul ecx, COFF_RELOC_SIZE
    mov rdx, qword ptr [rsp + 48]
    lea rdx, [rdx + rcx]
    mov rax, r12
    add rax, r13
    lea r8, [rdx + COFF_RELOC_SIZE]
    cmp r8, rax
    ja .lco_fail
    mov eax, dword ptr [rdx + 0]
    mov dword ptr [rsp + 80], eax
    mov eax, dword ptr [rdx + 4]
    mov dword ptr [rsp + 76], eax
    movzx eax, word ptr [rdx + 8]
    mov dword ptr [rsp + 72], eax

    mov eax, dword ptr [rsp + 76]
    mov edx, dword ptr [rsp + 116]
    cmp eax, edx
    jae .lco_fail
    imul eax, COFF_SYM_SIZE
    mov edx, dword ptr [rsp + 120]
    lea r10, [r12 + rdx]
    add r10, rax

    movsx eax, word ptr [r10 + 12]
    cmp eax, 0
    jg .lco_int_target
    cmp eax, -1
    je .lco_abs_target
    jmp .lco_ext_target
.lco_abs_target:
    mov eax, dword ptr [r10 + 8]
    mov rax, rax
    jmp .lco_have_target
.lco_int_target:
    mov r15d, eax
    cmp r15d, r14d
    ja .lco_ext_target
    lea r8, [rip + section_base]
    mov rax, qword ptr [r8 + r15*8]
    mov edx, dword ptr [r10 + 8]
    add rax, rdx
    jmp .lco_have_target
.lco_ext_target:
    mov rcx, r10
    mov rdx, qword ptr [rsp + 88]
    call get_sym_name
    mov r11, rax
    mov rax, r12
    add rax, r13
    cmp r11, r12
    jb .lco_fail
    cmp r11, rax
    jae .lco_fail
    mov rcx, r11
    call sym_find
    test rax, rax
    jnz .lco_have_target
    lea rcx, [rip + msg_missing_sym]
    call write_console
    mov rcx, r11
    call write_console
    lea rcx, [rip + msg_nl]
    call write_console
    jmp .lco_fail
.lco_have_target:
    mov qword ptr [rsp + 64], rax

    mov ecx, ebx
    inc ecx
    lea r8, [rip + section_base]
    mov rax, qword ptr [r8 + rcx*8]
    mov edx, dword ptr [rsp + 80]
    add rax, rdx
    mov r15, rax

    mov eax, dword ptr [rsp + 72]
    cmp eax, IMAGE_REL_AMD64_REL32
    jb .lco_chk_addr64
    cmp eax, IMAGE_REL_AMD64_REL32_5
    jbe .lco_do_rel32_any
.lco_chk_addr64:
    cmp eax, IMAGE_REL_AMD64_ADDR64
    je .lco_do_addr64
    cmp eax, IMAGE_REL_AMD64_ADDR32
    je .lco_do_addr32
    jmp .lco_reloc_next
.lco_do_rel32_any:
    mov rax, qword ptr [rsp + 96]
    cmp r15, rax
    jb .lco_reloc_next
    mov eax, dword ptr [rsp + 112]
    add rax, qword ptr [rsp + 96]
    lea rdx, [r15 + 4]
    cmp rdx, rax
    ja .lco_reloc_next
    mov ecx, dword ptr [rsp + 72]
    sub ecx, IMAGE_REL_AMD64_REL32
    movsxd rax, dword ptr [r15]
    mov rdx, qword ptr [rsp + 64]
    add rdx, rax
    lea rax, [r15 + 4]
    sub rdx, rax
    add rdx, rcx
    mov dword ptr [r15], edx
    jmp .lco_reloc_next
.lco_do_addr32:
    mov rax, qword ptr [rsp + 96]
    cmp r15, rax
    jb .lco_reloc_next
    mov eax, dword ptr [rsp + 112]
    add rax, qword ptr [rsp + 96]
    lea rdx, [r15 + 4]
    cmp rdx, rax
    ja .lco_reloc_next
    mov eax, dword ptr [r15]
    mov rdx, qword ptr [rsp + 64]
    add rdx, rax
    mov dword ptr [r15], edx
    jmp .lco_reloc_next
.lco_do_addr64:
    mov rax, qword ptr [rsp + 96]
    cmp r15, rax
    jb .lco_reloc_next
    mov eax, dword ptr [rsp + 112]
    add rax, qword ptr [rsp + 96]
    lea rdx, [r15 + 8]
    cmp rdx, rax
    ja .lco_reloc_next
    mov rax, qword ptr [r15]
    mov rdx, qword ptr [rsp + 64]
    add rdx, rax
    mov qword ptr [r15], rdx
.lco_reloc_next:
    inc dword ptr [rsp + 40]
    jmp .lco_reloc_loop

.lco_reloc_next_sec:
    inc ebx
    jmp .lco_reloc_sec

.lco_ok:
    mov rax, qword ptr [rsp + 96]
    add rsp, 160
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.lco_fail:
    xor rax, rax
    add rsp, 160
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

force_add_export:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 32
    mov r12, rcx
    mov r13, rdx

    mov eax, dword ptr [r12 + 8]
    test eax, eax
    jz .fae_no
    mov r14d, eax
    mov ebx, dword ptr [r12 + 12]
    test ebx, ebx
    jz .fae_no
    lea r10, [r12 + r14]
    mov eax, ebx
    imul eax, COFF_SYM_SIZE
    lea r11, [r10 + rax]

    xor r14d, r14d
.fae_loop:
    cmp r14d, ebx
    jae .fae_no
    mov eax, r14d
    imul eax, COFF_SYM_SIZE
    lea r15, [r10 + rax]
    movzx eax, byte ptr [r15 + 16]
    cmp eax, 2
    jne .fae_next
    movsx eax, word ptr [r15 + 12]
    cmp eax, 0
    jle .fae_next
    mov r9d, eax
    mov rcx, r15
    mov rdx, r11
    call get_sym_name
    mov r8, rax
    mov rcx, r8
    mov rdx, r13
    call string_equals
    test eax, eax
    jz .fae_next
    lea r8, [rip + section_base]
    mov rax, qword ptr [r8 + r9*8]
    mov edx, dword ptr [r15 + 8]
    add rax, rdx
    mov rcx, r13
    mov rdx, rax
    call sym_add
    mov eax, 1
    add rsp, 32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.fae_next:
    inc r14d
    jmp .fae_loop
.fae_no:
    xor eax, eax
    add rsp, 32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

build_dir_pattern:
    xor r9d, r9d
.bdp_copy:
    mov al, byte ptr [rdx]
    test al, al
    jz .bdp_done_dir
    mov byte ptr [rcx], al
    mov r9b, al
    inc rcx
    inc rdx
    jmp .bdp_copy
.bdp_done_dir:
    cmp r9b, '\\'
    je .bdp_star
    cmp r9b, '/'
    je .bdp_star
    mov byte ptr [rcx], '\\'
    inc rcx
.bdp_star:
    lea rdx, [rip + pat_star_obj]
.bdp_star_copy:
    mov al, byte ptr [rdx]
    mov byte ptr [rcx], al
    inc rcx
    inc rdx
    test al, al
    jnz .bdp_star_copy
    ret

build_dir_file_path:
    xor r9d, r9d
.bdf_copy:
    mov al, byte ptr [rdx]
    test al, al
    jz .bdf_done_dir
    mov byte ptr [rcx], al
    mov r9b, al
    inc rcx
    inc rdx
    jmp .bdf_copy
.bdf_done_dir:
    cmp r9b, '\\'
    je .bdf_copy_file
    cmp r9b, '/'
    je .bdf_copy_file
    mov byte ptr [rcx], '\\'
    inc rcx
.bdf_copy_file:
    mov al, byte ptr [r8]
    mov byte ptr [rcx], al
    inc rcx
    inc r8
    test al, al
    jne .bdf_copy_file
    ret

append_str:
    push rbx
    push r12
    sub rsp, 40
    mov r12, rcx
    mov rbx, rdx
    mov rcx, r12
    call strlen_asm
    lea r11, [r12 + rax]
    mov rcx, rbx
    call strlen_asm
    inc rax
    mov rcx, r11
    mov rdx, rbx
    mov r8, rax
    call mem_copy
    add rsp, 40
    pop r12
    pop rbx
    ret

append_char:
    push r12
    sub rsp, 32
    mov r12, rcx
    mov r8b, dl
    mov rcx, r12
    call strlen_asm
    lea r11, [r12 + rax]
    mov byte ptr [r11], r8b
    mov byte ptr [r11 + 1], 0
    add rsp, 32
    pop r12
    ret

append_bytes:
    push rbx
    push r12
    push r13
    mov rbx, rcx
    mov r12, rdx
    mov r13, r8
    mov rcx, rbx
    call strlen_asm
    lea rbx, [rbx + rax]
.ab_loop:
    test r13, r13
    jz .ab_done
    mov al, byte ptr [r12]
    mov byte ptr [rbx], al
    inc r12
    inc rbx
    dec r13
    jmp .ab_loop
.ab_done:
    mov byte ptr [rbx], 0
    pop r13
    pop r12
    pop rbx
    ret

append_manifest_objects:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 32
    mov rbx, rcx
    mov r12, rdx
    mov r13, r8

.amo_skip:
    test r13, r13
    jz .amo_done
    mov al, byte ptr [r12]
    cmp al, ' '
    je .amo_advance_one
    cmp al, 9
    je .amo_advance_one
    cmp al, 10
    je .amo_advance_one
    cmp al, 13
    je .amo_advance_one
    cmp al, '"'
    je .amo_start_quoted
    jmp .amo_start_plain
.amo_advance_one:
    inc r12
    dec r13
    jmp .amo_skip

.amo_start_quoted:
    inc r12
    dec r13
    lea r14, [rip + obj_path]
.amo_q_loop:
    test r13, r13
    jz .amo_emit
    mov al, byte ptr [r12]
    cmp al, '"'
    je .amo_q_end
    mov byte ptr [r14], al
    inc r14
    inc r12
    dec r13
    jmp .amo_q_loop
.amo_q_end:
    inc r12
    dec r13
    jmp .amo_emit

.amo_start_plain:
    lea r14, [rip + obj_path]
.amo_p_loop:
    test r13, r13
    jz .amo_emit
    mov al, byte ptr [r12]
    cmp al, ' '
    je .amo_emit
    cmp al, 9
    je .amo_emit
    cmp al, 10
    je .amo_emit
    cmp al, 13
    je .amo_emit
    mov byte ptr [r14], al
    inc r14
    inc r12
    dec r13
    jmp .amo_p_loop

.amo_emit:
    mov byte ptr [r14], 0
    lea rcx, [rip + obj_path]
    call strlen_asm
    test rax, rax
    jz .amo_skip
    mov rcx, rbx
    lea rdx, [rip + obj_path]
    call append_quoted_path
    jmp .amo_skip

.amo_done:
    add rsp, 32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

build_link_manifest_path:
    push rbx
    push r12
    push r13
    mov rbx, rcx
    mov r12, rdx
    xor r13d, r13d
.blm_copy:
    mov al, byte ptr [r12]
    mov byte ptr [rbx], al
    test al, al
    jz .blm_done_copy
    cmp al, '/'
    je .blm_reset
    cmp al, '\\'
    je .blm_reset
    cmp al, '.'
    jne .blm_next
    mov r13, rbx
    jmp .blm_next
.blm_reset:
    xor r13d, r13d
.blm_next:
    inc r12
    inc rbx
    jmp .blm_copy
.blm_done_copy:
    test r13, r13
    jnz .blm_have_dot
    mov r13, rbx
.blm_have_dot:
    mov byte ptr [r13], 0
    mov rcx, r13
    lea rdx, [rip + link_manifest_ext]
    call append_str
    pop r13
    pop r12
    pop rbx
    ret

append_quoted_path:
    push rbx
    push r12
    sub rsp, 40
    mov r12, rcx
    mov rbx, rdx
    mov dl, 34
    mov rcx, r12
    call append_char
    mov rdx, rbx
    mov rcx, r12
    call append_str
    mov dl, 34
    mov rcx, r12
    call append_char
    mov dl, 32
    mov rcx, r12
    call append_char
    add rsp, 40
    pop r12
    pop rbx
    ret

file_exists:
    push rbx
    sub rsp, 64
    mov rbx, rcx
    mov rcx, rbx
    mov edx, GENERIC_READ
    mov r8d, FILE_SHARE_READ
    xor r9d, r9d
    mov qword ptr [rsp + 32], OPEN_EXISTING
    mov qword ptr [rsp + 40], FILE_ATTRIBUTE_NORMAL
    mov qword ptr [rsp + 48], 0
    call CreateFileA
    cmp rax, INVALID_HANDLE_VALUE
    je .fe_no
    mov rcx, rax
    call CloseHandle
    mov eax, 1
    add rsp, 64
    pop rbx
    ret
.fe_no:
    xor eax, eax
    add rsp, 64
    pop rbx
    ret

append_runtime_obj:
    push rbx
    push r12
    push r13
    sub rsp, 32
    mov rbx, rcx
    mov r12, rdx
    mov r13, r8

    lea rcx, [rip + obj_path]
    mov rdx, r12
    mov r8, r13
    call build_dir_file_path

    lea rcx, [rip + obj_path]
    call file_exists
    test eax, eax
    jnz .aro_append

    lea rcx, [rip + obj_path]
    lea rdx, [rip + alt_runtime_dir]
    mov r8, r13
    call build_dir_file_path

    lea rcx, [rip + obj_path]
    call file_exists
    test eax, eax
    jnz .aro_append

    lea rcx, [rip + obj_path]
    lea rdx, [rip + default_runtime_dir]
    mov r8, r13
    call build_dir_file_path

.aro_append:
    mov rcx, rbx
    lea rdx, [rip + obj_path]
    call append_quoted_path

    add rsp, 32
    pop r13
    pop r12
    pop rbx
    ret

append_heap_obj:
    push rbx
    push r12
    sub rsp, 32
    mov rbx, rcx
    mov r12, rdx

    lea rcx, [rip + obj_path]
    mov rdx, r12
    lea r8, [rip + runtime_heap_obj]
    call build_dir_file_path

    lea rcx, [rip + obj_path]
    call file_exists
    test eax, eax
    jnz .aho_append

    lea rcx, [rip + obj_path]
    lea rdx, [rip + alt_heap_dir]
    lea r8, [rip + runtime_heap_obj]
    call build_dir_file_path

    lea rcx, [rip + obj_path]
    call file_exists
    test eax, eax
    jnz .aho_append

    lea rcx, [rip + obj_path]
    lea rdx, [rip + default_heap_dir]
    lea r8, [rip + runtime_heap_obj]
    call build_dir_file_path

.aho_append:
    mov rcx, rbx
    lea rdx, [rip + obj_path]
    call append_quoted_path

    add rsp, 32
    pop r12
    pop rbx
    ret

create_process_wait:
    sub rsp, 32
    call system
    test eax, eax
    jnz .cpw_fail
    mov eax, 1
    add rsp, 32
    ret
.cpw_fail:
    xor eax, eax
    add rsp, 32
    ret

load_obj_file_by_path:
    push rbx
    sub rsp, 64
    mov rbx, rcx
    mov rcx, rbx
    call read_entire_file
    test rax, rax
    jz .lof_fail
    mov qword ptr [rsp + 32], rax
    mov qword ptr [rsp + 40], rdx
    lea rcx, [rip + msg_read_ok]
    call write_console
    mov rcx, qword ptr [rsp + 32]
    mov rdx, qword ptr [rsp + 40]
    call load_coff_obj
    test rax, rax
    jz .lof_fail
    lea rcx, [rip + msg_load_ok]
    call write_console
    mov eax, 1
    add rsp, 64
    pop rbx
    ret
.lof_fail:
    xor eax, eax
    add rsp, 64
    pop rbx
    ret

load_obj_directory:
    push rbx
    push r12
    sub rsp, 48
    mov r12, rcx

    lea rcx, [rip + pattern_buf]
    mov rdx, r12
    call build_dir_pattern

    lea rcx, [rip + pattern_buf]
    lea rdx, [rip + find_data]
    call FindFirstFileA
    cmp rax, INVALID_HANDLE_VALUE
    je .lod_fail
    mov rbx, rax
.lod_loop:
    lea rcx, [rip + obj_path]
    mov rdx, r12
    lea r8, [rip + find_data + FIND_DATA_CFILE_NAME]
    call build_dir_file_path
    lea rcx, [rip + obj_path]
    call load_obj_file_by_path
    test eax, eax
    jz .lod_close_fail
    mov rcx, rbx
    lea rdx, [rip + find_data]
    call FindNextFileA
    test eax, eax
    jnz .lod_loop

    mov rcx, rbx
    call FindClose
    mov eax, 1
    add rsp, 48
    pop r12
    pop rbx
    ret
.lod_close_fail:
    mov rcx, rbx
    call FindClose
.lod_fail:
    xor eax, eax
    add rsp, 48
    pop r12
    pop rbx
    ret

main:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 64
    mov r14d, ecx
    mov r15, rdx

    lea rbx, [rip + default_runtime_dir]
    lea r13, [rip + default_prog_obj]
    xor r12d, r12d

    mov esi, 1
.arg_loop:
    cmp esi, r14d
    jge .args_done
    mov rax, [r15 + rsi*8]
    mov r10, rax

    mov rdx, r10
    lea rcx, [rip + dash_d]
    call string_equals
    test eax, eax
    jz .check_link_arg
    inc esi
    cmp esi, r14d
    jge .args_done
    mov rbx, [r15 + rsi*8]
    inc esi
    jmp .arg_loop

.check_link_arg:
    mov rdx, r10
    lea rcx, [rip + dash_link]
    call string_equals
    test eax, eax
    jz .use_prog_arg
    inc esi
    cmp esi, r14d
    jge .args_done
    mov r12, [r15 + rsi*8]
    inc esi
    jmp .arg_loop

.use_prog_arg:
    mov r13, r10
    inc esi
    jmp .arg_loop
.args_done:

    lea rcx, [rip + cmdline_buf]
    mov edx, CMDLINE_MAX
    call mem_zero

    lea rcx, [rip + cmdline_buf]
    lea rdx, [rip + gcc_path]
    call append_quoted_path

    lea rcx, [rip + cmdline_buf]
    mov rdx, r13
    call append_quoted_path

    test r12, r12
    jnz .have_manifest_path
    lea rcx, [rip + link_path]
    mov rdx, r13
    call build_link_manifest_path
    lea r12, [rip + link_path]
.have_manifest_path:
    mov rcx, r12
    call read_entire_file
    test rax, rax
    jz .skip_link_manifest
    mov r11, rax
    mov r10, rdx
    lea rcx, [rip + cmdline_buf]
    mov rdx, r11
    mov r8, r10
    call append_manifest_objects
.skip_link_manifest:

    lea rcx, [rip + obj_path]
    lea rdx, [rip + alt_runtime_dir]
    lea r8, [rip + runtime_string_obj]
    call build_dir_file_path
    lea rcx, [rip + cmdline_buf]
    lea rdx, [rip + obj_path]
    call append_quoted_path

    lea rcx, [rip + obj_path]
    lea rdx, [rip + alt_runtime_dir]
    lea r8, [rip + runtime_integer_obj]
    call build_dir_file_path
    lea rcx, [rip + cmdline_buf]
    lea rdx, [rip + obj_path]
    call append_quoted_path

    lea rcx, [rip + obj_path]
    lea rdx, [rip + alt_runtime_dir]
    lea r8, [rip + runtime_array_obj]
    call build_dir_file_path
    lea rcx, [rip + cmdline_buf]
    lea rdx, [rip + obj_path]
    call append_quoted_path

    lea rcx, [rip + obj_path]
    lea rdx, [rip + alt_runtime_dir]
    lea r8, [rip + runtime_boolean_obj]
    call build_dir_file_path
    lea rcx, [rip + cmdline_buf]
    lea rdx, [rip + obj_path]
    call append_quoted_path

    lea rcx, [rip + obj_path]
    lea rdx, [rip + alt_runtime_dir]
    lea r8, [rip + runtime_double_obj]
    call build_dir_file_path
    lea rcx, [rip + cmdline_buf]
    lea rdx, [rip + obj_path]
    call append_quoted_path

    lea rcx, [rip + obj_path]
    lea rdx, [rip + alt_runtime_dir]
    lea r8, [rip + runtime_file_obj]
    call build_dir_file_path
    lea rcx, [rip + cmdline_buf]
    lea rdx, [rip + obj_path]
    call append_quoted_path

    lea rcx, [rip + obj_path]
    lea rdx, [rip + alt_runtime_dir]
    lea r8, [rip + runtime_httpclient_obj]
    call build_dir_file_path
    lea rcx, [rip + cmdline_buf]
    lea rdx, [rip + obj_path]
    call append_quoted_path

    lea rcx, [rip + obj_path]
    lea rdx, [rip + alt_runtime_dir]
    lea r8, [rip + runtime_httpserver_obj]
    call build_dir_file_path
    lea rcx, [rip + cmdline_buf]
    lea rdx, [rip + obj_path]
    call append_quoted_path

    lea rcx, [rip + obj_path]
    lea rdx, [rip + alt_runtime_dir]
    lea r8, [rip + runtime_long_obj]
    call build_dir_file_path
    lea rcx, [rip + cmdline_buf]
    lea rdx, [rip + obj_path]
    call append_quoted_path

    lea rcx, [rip + obj_path]
    lea rdx, [rip + alt_runtime_dir]
    lea r8, [rip + runtime_map_obj]
    call build_dir_file_path
    lea rcx, [rip + cmdline_buf]
    lea rdx, [rip + obj_path]
    call append_quoted_path

    lea rcx, [rip + obj_path]
    lea rdx, [rip + alt_runtime_dir]
    lea r8, [rip + runtime_sock_obj]
    call build_dir_file_path
    lea rcx, [rip + cmdline_buf]
    lea rdx, [rip + obj_path]
    call append_quoted_path

    lea rcx, [rip + obj_path]
    lea rdx, [rip + alt_runtime_dir]
    lea r8, [rip + runtime_thread_obj]
    call build_dir_file_path
    lea rcx, [rip + cmdline_buf]
    lea rdx, [rip + obj_path]
    call append_quoted_path

    lea rcx, [rip + obj_path]
    lea rdx, [rip + alt_runtime_dir]
    lea r8, [rip + runtime_badaapi_ptrs_obj]
    call build_dir_file_path
    lea rcx, [rip + cmdline_buf]
    lea rdx, [rip + obj_path]
    call append_quoted_path

    lea rcx, [rip + obj_path]
    lea rdx, [rip + alt_heap_dir]
    lea r8, [rip + runtime_heap_obj]
    call build_dir_file_path
    lea rcx, [rip + cmdline_buf]
    lea rdx, [rip + obj_path]
    call append_quoted_path

    lea rcx, [rip + cmdline_buf]
    lea rdx, [rip + dash_o]
    call append_str
    lea rcx, [rip + cmdline_buf]
    lea rdx, [rip + out_exe]
    call append_quoted_path
    lea rcx, [rip + cmdline_buf]
    lea rdx, [rip + link_libs]
    call append_str

    lea rcx, [rip + cmdline_buf]
    call create_process_wait
    test eax, eax
    jz .link_fail

    lea rcx, [rip + cmdline_buf]
    mov edx, CMDLINE_MAX
    call mem_zero
    lea rcx, [rip + cmdline_buf]
    lea rdx, [rip + out_exe]
    call append_quoted_path
    lea rcx, [rip + cmdline_buf]
    call create_process_wait
    test eax, eax
    jz .run_fail

    xor eax, eax
    add rsp, 64
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.link_fail:
    lea rcx, [rip + msg_link_fail]
    call write_console
    mov eax, 1
    add rsp, 64
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.run_fail:
    lea rcx, [rip + msg_run_fail]
    call write_console
    mov eax, 1
    add rsp, 64
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
