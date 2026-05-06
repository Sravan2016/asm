.intel_syntax noprefix

.global HeapAlloc
.global HeapFree
.global heap_handle

.equ HEAP_ZERO_MEMORY, 0x00000008
.equ HEAP_ARENA_SIZE, 8388608

.section .data
.align 8
heap_handle: .quad 0

.section .bss
.align 16
heap_arena: .space HEAP_ARENA_SIZE
.align 8
heap_arena_off: .quad 0
.align 8
heap_free_head: .quad 0

.section .text

HeapAlloc:
    push rbx
    push rdi
    push rsi
    mov rbx, rdx
    mov rax, r8
    test rax, rax
    jnz 1f
    mov eax, 1
1:
    add rax, 15
    and rax, -16
    mov r8, rax

    lea rdi, [rip + heap_free_head]
    mov rsi, [rdi]
    xor r9, r9
.free_loop:
    test rsi, rsi
    jz .alloc_new
    mov rdx, [rsi + 8]
    cmp rdx, r8
    jb .free_next
    mov rax, [rsi]
    test r9, r9
    jz .free_unlink_head
    mov [r9], rax
    jmp .free_unlinked
.free_unlink_head:
    mov [rdi], rax
.free_unlinked:
    lea rax, [rsi + 16]
    jmp .maybe_zero
.free_next:
    mov r9, rsi
    mov rsi, [rsi]
    jmp .free_loop

.alloc_new:
    lea rdi, [rip + heap_arena_off]
    mov rax, [rdi]
    lea rdx, [rax + r8 + 16]
    cmp rdx, HEAP_ARENA_SIZE
    ja .oom
    lea rsi, [rip + heap_arena]
    add rsi, rax
    mov qword ptr [rsi], 0
    mov [rsi + 8], r8
    mov [rdi], rdx
    lea rax, [rsi + 16]
    jmp .maybe_zero

.oom:
    xor eax, eax
    pop rsi
    pop rdi
    pop rbx
    ret

.maybe_zero:
    test ebx, HEAP_ZERO_MEMORY
    jz .done
    mov rdi, rax
    mov rcx, r8
    xor eax, eax
    rep stosb
    mov rax, rdi
    sub rax, r8
.done:
    pop rsi
    pop rdi
    pop rbx
    ret

HeapFree:
    test rdx, rdx
    jz 1f
    lea rax, [rdx - 16]
    lea r8, [rip + heap_free_head]
    mov rcx, [r8]
    mov [rax], rcx
    mov [r8], rax
1:
    mov eax, 1
    ret
