.intel_syntax noprefix

.extern pCreateThread
.extern pWaitForSingleObject
.extern pCloseHandle
.extern pInitializeCriticalSection
.extern pEnterCriticalSection
.extern pLeaveCriticalSection
.extern pTlsAlloc
.extern pTlsSetValue

.extern string_copy
.extern string_free
.extern string_from_cstr
.extern print_cstr
.extern print_uint

.global thread_init
.global thread_run
.global thread_join
.global thread_cache_set_string
.global thread_cache_get_string
.global thread_cache_set_int
.global thread_cache_get_int
.global thread_cache_set_long
.global thread_cache_get_long
.global thread_cache_set_double
.global thread_cache_get_double
.global thread_cache_set_array
.global thread_cache_get_array

.equ INFINITE, 0xFFFFFFFF

.section .data
init_flag: .quad 0
tls_index: .long -1
pad_tls:   .long 0
msg_hello: .asciz "hello-from-thread"
msg_no_entry: .asciz "get_string: no entry\n"
msg_null_str: .asciz "get_string: null str\n"
msg_last_entry: .asciz "get_string: last_entry set\n"

.section .bss
.align 8
crit_sec:  .space 40
map_head:  .quad 0
last_entry: .quad 0
entry_pool: .space 1024      # 32 entries * 32 bytes
entry_pool_next: .quad 0
cache_pool: .space 1536      # 32 caches * 48 bytes
cache_pool_next: .quad 0
param_pool: .space 512       # 16 params * 32 bytes
param_pool_next: .quad 0

.section .text

strlen_asm:
    # rcx = cstr -> rax=len
    push rdi
    xor rax, rax
    mov rdi, rcx
    mov rcx, -1
    mov al, 0
    cld
    repne scasb
    not rcx
    dec rcx
    mov rax, rcx
    pop rdi
    ret

memcpy_asm:
    # rcx=dst, rdx=src, r8=len
    push rdi
    push rsi
    mov rdi, rcx
    mov rsi, rdx
    mov rcx, r8
    cld
    rep movsb
    pop rsi
    pop rdi
    ret

thread_init:
    mov rax, [rip + init_flag]
    test rax, rax
    jnz .init_done
    sub rsp, 40
    call qword ptr [rip + pTlsAlloc]
    add rsp, 40
    mov dword ptr [rip + tls_index], eax
    lea rcx, [rip + crit_sec]
    sub rsp, 40
    call qword ptr [rip + pInitializeCriticalSection]
    add rsp, 40
    mov qword ptr [rip + init_flag], 1
.init_done:
    ret

enter_cs:
    lea rcx, [rip + crit_sec]
    sub rsp, 40
    call qword ptr [rip + pEnterCriticalSection]
    add rsp, 40
    ret

leave_cs:
    lea rcx, [rip + crit_sec]
    sub rsp, 40
    call qword ptr [rip + pLeaveCriticalSection]
    add rsp, 40
    ret

get_entry:
    # rcx=name cstr -> rax=entry or 0
    push rbx
    push r12
    push r13
    mov r12, rcx
    call strlen_asm
    mov r13, rax
    mov rbx, [rip + map_head]
.find_loop:
    test rbx, rbx
    jz .not_found
    mov rcx, [rbx + 8]     # entry name
    call strlen_asm
    cmp rax, r13
    jne .next
    mov rdx, [rbx + 8]     # name_ptr
    mov rcx, r12
    mov r8, r13
    call memcmp_asm
    test rax, rax
    jz .found
.next:
    mov rbx, [rbx]
    jmp .find_loop
.found:
    mov rax, rbx
    pop r13
    pop r12
    pop rbx
    ret
.not_found:
    xor rax, rax
    pop r13
    pop r12
    pop rbx
    ret

memcmp_asm:
    # rcx=a, rdx=b, r8=len -> rax=0 if equal
    push rbx
    mov rbx, r8
    test rbx, rbx
    jz .eq
.cmp_loop:
    mov al, byte ptr [rcx]
    mov r9b, byte ptr [rdx]
    cmp al, r9b
    jne .ne
    inc rcx
    inc rdx
    dec rbx
    jnz .cmp_loop
.eq:
    xor rax, rax
    pop rbx
    ret
.ne:
    mov rax, 1
    pop rbx
    ret

create_entry:
    # rcx=name cstr -> rax=entry
    push rbx
    push r12
    push r13
    mov r12, rcx
    xor r13, r13
    mov rax, r12
.len_loop:
    mov dl, byte ptr [rax]
    test dl, dl
    jz .len_done
    inc r13
    inc rax
    jmp .len_loop
.len_done:
    # allocate entry from static pool
    lea rax, [rip + entry_pool_next]
    mov r8, [rax]
    cmp r8, 32
    jae .create_fail
    inc qword ptr [rax]
    shl r8, 5
    lea rbx, [rip + entry_pool]
    add rbx, r8
    mov qword ptr [rbx], 0
    mov qword ptr [rbx + 8], 0
    mov qword ptr [rbx + 16], 0
    mov qword ptr [rbx + 24], 0
    mov qword ptr [rbx + 8], r12     # name_ptr; caller-owned cstr
    mov qword ptr [rbx + 16], r13    # name_len
    # allocate cache from static pool
    lea rax, [rip + cache_pool_next]
    mov r8, [rax]
    cmp r8, 32
    jae .create_fail
    inc qword ptr [rax]
    imul r8, r8, 48
    lea r9, [rip + cache_pool]
    add r9, r8
    mov qword ptr [r9], 0
    mov qword ptr [r9 + 8], 0
    mov qword ptr [r9 + 16], 0
    mov qword ptr [r9 + 24], 0
    mov qword ptr [r9 + 32], 0
    mov qword ptr [r9 + 40], 0
    mov qword ptr [rbx + 24], r9     # cache_ptr
    # insert into map
    mov rax, [rip + map_head]
    mov qword ptr [rbx], rax
    mov qword ptr [rip + map_head], rbx
    mov rax, rbx
    pop r13
    pop r12
    pop rbx
    ret
.create_fail:
    xor rax, rax
    pop r13
    pop r12
    pop rbx
    ret

get_or_create_entry:
    # rcx=name cstr -> rax=entry
    push rcx
    sub rsp, 32
    call get_entry
    add rsp, 32
    test rax, rax
    jnz .done
    pop rcx
    sub rsp, 32
    call create_entry
    add rsp, 32
    ret
.done:
    pop rcx
    ret

thread_cache_set_string:
    # rcx=name cstr, rdx=AsmString*
    push rbx
    push r12
    mov rbx, rdx
    sub rsp, 40
    call get_or_create_entry
    add rsp, 40
    mov r12, [rax + 24]    # cache
    lea rcx, [r12]         # cache->str
    sub rsp, 40
    call string_free
    add rsp, 40
    lea rcx, [r12]
    mov rdx, rbx
    sub rsp, 40
    call string_copy
    add rsp, 40
    pop r12
    pop rbx
    ret

thread_cache_get_string:
    # rcx=name cstr, rdx=AsmString* out -> rax=1/0
    push rbx
    push r12
    mov r12, rdx
    sub rsp, 40
    call get_entry
    add rsp, 40
    test rax, rax
    jz .gs_no_entry
    mov rbx, [rax + 24]
    mov rax, [rbx]
    test rax, rax
    jz .gs_no_str
    lea rcx, [r12]
    lea rdx, [rbx]
    sub rsp, 40
    call string_copy
    add rsp, 40
    mov rax, 1
    pop r12
    pop rbx
    ret
.gs_no_entry:
    xor rax, rax
    pop r12
    pop rbx
    ret
.gs_no_str:
    xor rax, rax
    pop r12
    pop rbx
    ret

thread_cache_set_int:
    # rcx=name cstr, edx=int
    push rbx
    mov rbx, rdx
    sub rsp, 32
    call get_or_create_entry
    add rsp, 32
    mov rax, [rax + 24]
    mov dword ptr [rax + 16], ebx
    pop rbx
    ret

thread_cache_get_int:
    # rcx=name cstr, rdx=int* out -> rax=1/0
    push r12
    mov r12, rdx
    sub rsp, 32
    call get_entry
    add rsp, 32
    test rax, rax
    jz .gi_no
    mov rax, [rax + 24]
    mov eax, dword ptr [rax + 16]
    mov dword ptr [r12], eax
    mov rax, 1
    pop r12
    ret
.gi_no:
    xor rax, rax
    pop r12
    ret

thread_cache_set_long:
    # rcx=name cstr, rdx=long long
    push rbx
    mov rbx, rdx
    sub rsp, 32
    call get_or_create_entry
    add rsp, 32
    mov rax, [rax + 24]
    mov qword ptr [rax + 24], rbx
    pop rbx
    ret

thread_cache_get_long:
    # rcx=name cstr, rdx=long long* out -> rax=1/0
    push r12
    mov r12, rdx
    sub rsp, 32
    call get_entry
    add rsp, 32
    test rax, rax
    jz .gl_no
    mov rax, [rax + 24]
    mov rax, [rax + 24]
    mov qword ptr [r12], rax
    mov rax, 1
    pop r12
    ret
.gl_no:
    xor rax, rax
    pop r12
    ret

thread_cache_set_double:
    # rcx=name cstr, xmm1=double
    sub rsp, 24
    movsd qword ptr [rsp + 16], xmm1
    sub rsp, 40
    call get_or_create_entry
    add rsp, 40
    mov rax, [rax + 24]
    movsd xmm1, qword ptr [rsp + 16]
    movsd qword ptr [rax + 32], xmm1
    add rsp, 24
    ret

thread_cache_get_double:
    # rcx=name cstr, rdx=double* out -> rax=1/0
    push r12
    mov r12, rdx
    sub rsp, 32
    call get_entry
    add rsp, 32
    test rax, rax
    jz .gd_no
    mov rax, [rax + 24]
    movsd xmm0, qword ptr [rax + 32]
    movsd qword ptr [r12], xmm0
    mov rax, 1
    pop r12
    ret
.gd_no:
    xor rax, rax
    pop r12
    ret

thread_cache_set_array:
    # rcx=name cstr, rdx=AsmArray*
    sub rsp, 32
    call get_or_create_entry
    add rsp, 32
    mov rax, [rax + 24]
    mov qword ptr [rax + 40], rdx
    ret

thread_cache_get_array:
    # rcx=name cstr, rdx=AsmArray** out -> rax=1/0
    push r12
    mov r12, rdx
    sub rsp, 32
    call get_entry
    add rsp, 32
    test rax, rax
    jz .ga_no
    mov rax, [rax + 24]
    mov rax, [rax + 40]
    mov qword ptr [r12], rax
    mov rax, 1
    pop r12
    ret
.ga_no:
    xor rax, rax
    pop r12
    ret

thread_proc:
    # rcx=param
    push rbx
    mov rbx, rcx
    mov rax, [rbx + 24]     # cache
    mov r9, rax
    mov eax, dword ptr [rip + tls_index]
    cmp eax, -1
    je .tls_skip
    mov ecx, eax
    mov rdx, r9
    sub rsp, 32
    call qword ptr [rip + pTlsSetValue]
    add rsp, 32
.tls_skip:
    mov rax, [rbx + 8]      # cb
    test rax, rax
    jz .thread_done
    mov rcx, [rbx]          # name
    mov rdx, [rbx + 24]     # cache
    mov r8, [rbx + 16]      # user_data
    sub rsp, 32
    call rax
    add rsp, 32
.thread_done:
    xor eax, eax
    pop rbx
    ret

thread_run:
    # rcx=name cstr, rdx=callback, r8=user_data -> rax=handle or 0
    test rcx, rcx
    jz .tr_fail
    test rdx, rdx
    jz .tr_fail
    push r14
    mov r14, rcx
    call thread_init
    mov rcx, r14
    push rbx
    push r12
    push r13
    sub rsp, 56
    mov r12, rdx          # cb
    mov rbx, r8           # user_data
    call get_or_create_entry
    mov r13, rax          # entry
    mov qword ptr [rip + last_entry], r13
    mov qword ptr [rip + map_head], r13
    # allocate param from static pool
    lea rax, [rip + param_pool_next]
    mov r10, [rax]
    cmp r10, 16
    jae .tr_fail_pop
    inc qword ptr [rax]
    shl r10, 5
    lea rax, [rip + param_pool]
    add r10, rax          # param
    mov rax, [r13 + 8]
    mov qword ptr [r10], rax        # name
    mov qword ptr [r10 + 8], r12    # cb
    mov qword ptr [r10 + 16], rbx   # user_data
    mov rax, [r13 + 24]
    mov qword ptr [r10 + 24], rax   # cache
    xor rcx, rcx
    xor rdx, rdx
    lea r8, [rip + thread_proc]
    mov r9, r10
    sub rsp, 48
    mov qword ptr [rsp + 32], 0
    mov qword ptr [rsp + 40], 0
    call qword ptr [rip + pCreateThread]
    add rsp, 48
    test rax, rax
    jz .tr_fail_free
    add rsp, 56
    pop r13
    pop r12
    pop rbx
    pop r14
    ret
.tr_fail_free:
.tr_fail_pop:
    add rsp, 56
    pop r13
    pop r12
    pop rbx
    pop r14
.tr_fail:
    xor rax, rax
    ret

thread_join:
    # rcx=handle -> rax=1/0
    test rcx, rcx
    jz .tj_no
    push rbx
    mov rbx, rcx
    mov rcx, rbx
    mov rdx, INFINITE
    sub rsp, 32
    call qword ptr [rip + pWaitForSingleObject]
    add rsp, 32
    cmp eax, 0
    jne .tj_fail
    mov rcx, rbx
    sub rsp, 32
    call qword ptr [rip + pCloseHandle]
    add rsp, 32
    pop rbx
    mov rax, 1
    ret
.tj_fail:
    mov rcx, rbx
    sub rsp, 32
    call qword ptr [rip + pCloseHandle]
    add rsp, 32
    pop rbx
    xor rax, rax
    ret
.tj_no:
    xor rax, rax
    ret
