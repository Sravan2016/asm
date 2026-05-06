.intel_syntax noprefix

.extern pCreateFileA
.extern pReadFile
.extern pWriteFile
.extern pSetFilePointerEx
.extern pCloseHandle
.extern pDeleteFileA
.extern HeapAlloc
.extern string_from_cstr
.extern string_concat
.extern string_copy
.extern string_free
.extern heap_handle

.global map_init
.global map_create
.global map_put
.global map_get
.global map_contains_key
.global map_remove
.global map_size
.global map_is_empty
.global map_clear
.global map_free
.global map_to_string
.global map_string_hash
.global map_string_equals

.equ GENERIC_READ, 0x80000000
.equ GENERIC_WRITE, 0x40000000
.equ FILE_SHARE_READ, 1
.equ CREATE_ALWAYS, 2
.equ FILE_ATTRIBUTE_NORMAL, 0x00000080
.equ FILE_BEGIN, 0
.equ INVALID_HANDLE_VALUE, -1
.equ HEAP_ZERO_MEMORY, 0x00000008
.equ MAP_MAX_ENTRIES, 128
.equ MAP_ENTRY_SIZE, 32

.section .data
hex_digits: .asciz "0123456789ABCDEF"
map_empty_str: .asciz ""
map_stub_str: .asciz "{map}"
map_lbrace: .asciz "{"
map_rbrace: .asciz "}"
map_sep: .asciz ", "
map_eq: .asciz "="

.section .bss
.align 8
map_pool:      .space 640       # 16 map structs * 40 bytes
map_pool_next: .quad 0
map_entry_pool: .space 65536    # 16 maps * 128 entries * 32 bytes
map_entry_buf: .space 32
map_entry_buf2: .space 32

.section .text

# File-backed Map.bada struct:
#   [0]  = file handle
#   [8]  = bucket_count/capacity hint
#   [16] = size
#   [24] = hash_fn
#   [32] = equals_fn
#
# File entry: [0]=used qword, [8]=key qword, [16]=value qword, [24]=hash qword

map_make_path:
    # rcx=map*, rdx=path buffer
    mov byte ptr [rdx], 'f'
    mov byte ptr [rdx + 1], 'i'
    mov byte ptr [rdx + 2], 'l'
    mov byte ptr [rdx + 3], 'e'
    mov byte ptr [rdx + 4], 'm'
    mov byte ptr [rdx + 5], 'a'
    mov byte ptr [rdx + 6], 'p'
    mov byte ptr [rdx + 7], '_'
    mov rax, rcx
    lea r10, [rip + hex_digits]
    mov r11, 16
    lea r8, [rdx + 8]
.make_hex:
    rol rax, 4
    mov r9, rax
    and r9, 0x0f
    mov r9b, byte ptr [r10 + r9]
    mov byte ptr [r8], r9b
    inc r8
    dec r11
    jnz .make_hex
    mov byte ptr [rdx + 24], '.'
    mov byte ptr [rdx + 25], 'b'
    mov byte ptr [rdx + 26], 'i'
    mov byte ptr [rdx + 27], 'n'
    mov byte ptr [rdx + 28], 0
    ret

map_string_hash:
    # rcx=key -> rax=hash
    test rcx, rcx
    jz .string_hash_null
    push rbx
    push r12
    push r13
    sub rsp, 32
    mov rbx, rcx
    mov rcx, rbx
    call string_length
    mov r12, rax
    mov r13, 1469598103934665603
    xor r10, r10
.string_hash_loop:
    cmp r10, r12
    jae .string_hash_done
    mov rcx, rbx
    mov rdx, r10
    call string_char_at
    movzx rax, al
    xor r13, rax
    mov r11, 1099511628211
    imul r13, r11
    inc r10
    jmp .string_hash_loop
.string_hash_done:
    mov rax, r13
    add rsp, 32
    pop r13
    pop r12
    pop rbx
    ret
.string_hash_null:
    xor rax, rax
    ret

map_string_equals:
    # rcx=lhs, rdx=rhs -> rax=1/0
    test rcx, rcx
    jz .string_equals_ptr
    test rdx, rdx
    jz .string_equals_ptr
    sub rsp, 40
    call string_equals
    add rsp, 40
    ret
.string_equals_ptr:
    cmp rcx, rdx
    sete al
    movzx eax, al
    ret

map_seek_entry:
    # rcx=map*, rdx=index -> rax=entry*
    mov rax, [rcx]
    mov r10, rdx
    shl r10, 5
    add rax, r10
    ret

map_read_entry:
    # rcx=map*, rdx=index, r8=buf -> rax=1/0
    test rcx, rcx
    jz .read_fail
    cmp rdx, MAP_MAX_ENTRIES
    jae .read_fail
    call map_seek_entry
    mov r10, [rax]
    mov [r8], r10
    mov r10, [rax + 8]
    mov [r8 + 8], r10
    mov r10, [rax + 16]
    mov [r8 + 16], r10
    mov r10, [rax + 24]
    mov [r8 + 24], r10
    mov rax, 1
    ret
.read_fail:
    xor rax, rax
    ret

map_write_entry:
    # rcx=map*, rdx=index, r8=buf -> rax=1/0
    test rcx, rcx
    jz .write_fail
    cmp rdx, MAP_MAX_ENTRIES
    jae .write_fail
    call map_seek_entry
    mov r10, [r8]
    mov [rax], r10
    mov r10, [r8 + 8]
    mov [rax + 8], r10
    mov r10, [r8 + 16]
    mov [rax + 16], r10
    mov r10, [r8 + 24]
    mov [rax + 24], r10
    mov rax, 1
    ret
.write_fail:
    xor rax, rax
    ret

map_hash_key:
    # rcx=map*, rdx=key -> rax=hash
    mov r10, [rcx + 24]
    test r10, r10
    jz .hash_default
    mov rcx, rdx
    sub rsp, 40
    call r10
    add rsp, 40
    ret
.hash_default:
    test rdx, rdx
    jz .hash_ptr
    push rbx
    push r12
    push r13
    sub rsp, 32
    mov rbx, rdx
    mov rcx, rbx
    call string_length
    mov r12, rax
    mov r13, 1469598103934665603
    xor r10, r10
.hash_string_loop:
    cmp r10, r12
    jae .hash_string_done
    mov rcx, rbx
    mov rdx, r10
    call string_char_at
    movzx rax, al
    xor r13, rax
    mov r11, 1099511628211
    imul r13, r11
    inc r10
    jmp .hash_string_loop
.hash_string_done:
    mov rax, r13
    add rsp, 32
    pop r13
    pop r12
    pop rbx
    ret
.hash_ptr:
    mov rax, rdx
    ret

map_keys_equal:
    # rcx=map*, rdx=entry_key, r8=query_key -> rax=1/0
    mov r10, [rcx + 32]
    test r10, r10
    jz .key_default_eq
    mov rcx, rdx
    mov rdx, r8
    sub rsp, 40
    call r10
    add rsp, 40
    ret
.key_default_eq:
    test rdx, rdx
    jz .key_ptr_eq
    test r8, r8
    jz .key_ptr_eq
    mov rcx, rdx
    mov rdx, r8
    sub rsp, 40
    call string_equals
    add rsp, 40
    ret
.key_ptr_eq:
    cmp rdx, r8
    sete al
    movzx eax, al
    ret

map_init:
    # rcx=map*, rdx=bucket_count, r8=hash_fn, r9=equals_fn
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 136
    mov rbx, rcx
    mov r12, rdx
    mov r13, r8
    mov r14, r9
    mov qword ptr [rbx + 16], 0
    mov qword ptr [rbx + 8], r12
    mov qword ptr [rbx + 24], r13
    mov qword ptr [rbx + 32], r14
    lea r8, [rip + map_entry_buf]
    mov qword ptr [r8], 0
    mov qword ptr [r8 + 8], 0
    mov qword ptr [r8 + 16], 0
    mov qword ptr [r8 + 24], 0
    xor r12, r12
.init_zero_loop:
    cmp r12, MAP_MAX_ENTRIES
    jae .init_done
    mov rcx, rbx
    mov rdx, r12
    lea r8, [rip + map_entry_buf]
    call map_write_entry
    inc r12
    jmp .init_zero_loop
.init_done:
    add rsp, 136
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

map_create:
    # rcx=bucket_count, rdx=hash_fn, r8=equals_fn -> rax=map*
    push rbx
    push r12
    push r13
    sub rsp, 8
    mov rbx, rcx
    mov r12, rdx
    mov r13, r8
    lea rax, [rip + map_pool_next]
    mov r9, [rax]
    cmp r9, 16
    jae .create_fail
    inc qword ptr [rax]
    mov r8, r9
    imul r8, r8, 40
    lea rax, [rip + map_pool]
    add rax, r8
    mov r10, r9
    imul r10, r10, 4096
    lea r11, [rip + map_entry_pool]
    add r11, r10
    mov qword ptr [rax], r11
    mov qword ptr [rax + 8], 0
    mov qword ptr [rax + 16], 0
    mov qword ptr [rax + 24], 0
    mov qword ptr [rax + 32], 0
    mov rcx, rax
    mov rdx, rbx
    mov r8, r12
    mov r9, r13
    mov rbx, rax
    sub rsp, 40
    call map_init
    add rsp, 40
    mov rax, rbx
    add rsp, 8
    pop r13
    pop r12
    pop rbx
    ret
.create_fail:
    xor rax, rax
    add rsp, 8
    pop r13
    pop r12
    pop rbx
    ret

map_put:
    # rcx=map*, rdx=key, r8=value -> rax=old_value (0 if none)
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 40
    mov rbx, rcx
    mov r12, rdx
    mov r13, r8
    test rbx, rbx
    jz .put_fail
    mov rcx, rbx
    mov rdx, r12
    call map_hash_key
    mov r14, rax
    xor r15, r15
    mov qword ptr [rsp + 32], -1
.put_scan:
    cmp r15, MAP_MAX_ENTRIES
    jae .put_insert
    mov rcx, rbx
    mov rdx, r15
    lea r8, [rip + map_entry_buf]
    call map_read_entry
    test rax, rax
    jz .put_next
    lea r10, [rip + map_entry_buf]
    cmp qword ptr [r10], 0
    je .put_empty
    cmp [r10 + 24], r14
    jne .put_next
    mov rcx, rbx
    mov rdx, [r10 + 8]
    mov r8, r12
    call map_keys_equal
    test rax, rax
    jz .put_next
    lea r10, [rip + map_entry_buf]
    mov rax, [r10 + 16]
    mov [r10 + 16], r13
    mov rcx, rbx
    mov rdx, r15
    lea r8, [rip + map_entry_buf]
    mov [rsp + 32], rax
    call map_write_entry
    mov rax, [rsp + 32]
    jmp .put_done
.put_empty:
    cmp qword ptr [rsp + 32], -1
    jne .put_next
    mov [rsp + 32], r15
.put_next:
    inc r15
    jmp .put_scan
.put_insert:
    mov r15, [rsp + 32]
    cmp r15, -1
    je .put_fail
    lea r10, [rip + map_entry_buf]
    mov qword ptr [r10], 1
    mov [r10 + 8], r12
    mov [r10 + 16], r13
    mov [r10 + 24], r14
    mov rcx, rbx
    mov rdx, r15
    lea r8, [rip + map_entry_buf]
    call map_write_entry
    test rax, rax
    jz .put_fail
    inc qword ptr [rbx + 16]
    xor rax, rax
    jmp .put_done
.put_fail:
    xor rax, rax
.put_done:
    add rsp, 40
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

map_get:
    # rcx=map*, rdx=key -> rax=value or 0
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 32
    mov rbx, rcx
    mov r12, rdx
    test rbx, rbx
    jz .get_fail
    mov rcx, rbx
    mov rdx, r12
    call map_hash_key
    mov r13, rax
    xor r14, r14
.get_scan:
    cmp r14, MAP_MAX_ENTRIES
    jae .get_fail
    mov rcx, rbx
    mov rdx, r14
    lea r8, [rip + map_entry_buf]
    call map_read_entry
    lea r10, [rip + map_entry_buf]
    cmp qword ptr [r10], 0
    je .get_next
    cmp [r10 + 24], r13
    jne .get_next
    mov rcx, rbx
    mov rdx, [r10 + 8]
    mov r8, r12
    call map_keys_equal
    test rax, rax
    jz .get_next
    lea r10, [rip + map_entry_buf]
    mov rax, [r10 + 16]
    jmp .get_done
.get_next:
    inc r14
    jmp .get_scan
.get_fail:
    xor rax, rax
.get_done:
    add rsp, 32
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

map_contains_key:
    call map_get
    test rax, rax
    setne al
    movzx eax, al
    ret

map_remove:
    # rcx=map*, rdx=key -> rax=old_value or 0
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 40
    mov rbx, rcx
    mov r12, rdx
    test rbx, rbx
    jz .rm_fail
    mov rcx, rbx
    mov rdx, r12
    call map_hash_key
    mov r13, rax
    xor r14, r14
.rm_scan:
    cmp r14, MAP_MAX_ENTRIES
    jae .rm_fail
    mov rcx, rbx
    mov rdx, r14
    lea r8, [rip + map_entry_buf]
    call map_read_entry
    lea r10, [rip + map_entry_buf]
    cmp qword ptr [r10], 0
    je .rm_next
    cmp [r10 + 24], r13
    jne .rm_next
    mov rcx, rbx
    mov rdx, [r10 + 8]
    mov r8, r12
    call map_keys_equal
    test rax, rax
    jz .rm_next
    lea r10, [rip + map_entry_buf]
    mov rax, [r10 + 16]
    mov [rsp + 32], rax
    mov qword ptr [r10], 0
    mov qword ptr [r10 + 8], 0
    mov qword ptr [r10 + 16], 0
    mov qword ptr [r10 + 24], 0
    mov rcx, rbx
    mov rdx, r14
    lea r8, [rip + map_entry_buf]
    call map_write_entry
    dec qword ptr [rbx + 16]
    mov rax, [rsp + 32]
    jmp .rm_done
.rm_next:
    inc r14
    jmp .rm_scan
.rm_fail:
    xor rax, rax
.rm_done:
    add rsp, 40
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

map_size:
    test rcx, rcx
    jz .size_zero
    mov rax, [rcx + 16]
    ret
.size_zero:
    xor rax, rax
    ret

map_is_empty:
    test rcx, rcx
    jz .empty_true
    mov rax, [rcx + 16]
    test rax, rax
    setz al
    movzx eax, al
    ret
.empty_true:
    mov eax, 1
    ret

map_clear:
    # rcx=map*
    push rbx
    push r12
    sub rsp, 40
    mov rbx, rcx
    test rbx, rbx
    jz .clear_done
    lea r8, [rip + map_entry_buf]
    mov qword ptr [r8], 0
    mov qword ptr [r8 + 8], 0
    mov qword ptr [r8 + 16], 0
    mov qword ptr [r8 + 24], 0
    xor r12, r12
.clear_loop:
    cmp r12, MAP_MAX_ENTRIES
    jae .clear_finish
    mov rcx, rbx
    mov rdx, r12
    lea r8, [rip + map_entry_buf]
    call map_write_entry
    inc r12
    jmp .clear_loop
.clear_finish:
    mov qword ptr [rbx + 16], 0
.clear_done:
    add rsp, 40
    pop r12
    pop rbx
    ret

map_free:
    # rcx=map*
    test rcx, rcx
    jz .free_done
    mov qword ptr [rcx], 0
    mov qword ptr [rcx + 8], 0
    mov qword ptr [rcx + 16], 0
    mov qword ptr [rcx + 24], 0
    mov qword ptr [rcx + 32], 0
    lea rax, [rip + map_pool]
    cmp rcx, rax
    jb .free_done
    lea rdx, [rip + map_pool + 640]
    cmp rcx, rdx
    jae .free_done
    sub rcx, rax
    mov rax, rcx
    xor rdx, rdx
    mov r8, 40
    div r8
    inc rax
    lea rdx, [rip + map_pool_next]
    cmp rax, [rdx]
    jne .free_done
    dec qword ptr [rdx]
.free_done:
    ret

map_to_string:
    # rcx=map*, rdx=AsmString* out
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 160
    mov rbx, rcx
    mov r14, rdx

    lea rcx, [rsp + 32]
    lea rdx, [rip + map_lbrace]
    call string_from_cstr
    lea rcx, [rsp + 48]
    lea rdx, [rip + map_sep]
    call string_from_cstr
    lea rcx, [rsp + 64]
    lea rdx, [rip + map_eq]
    call string_from_cstr
    lea rcx, [rsp + 80]
    lea rdx, [rip + map_rbrace]
    call string_from_cstr

    xor r12, r12
    xor r13, r13
.to_string_loop:
    cmp r12, MAP_MAX_ENTRIES
    jae .to_string_done
    mov rcx, rbx
    mov rdx, r12
    lea r8, [rip + map_entry_buf]
    call map_read_entry
    test rax, rax
    jz .to_string_next
    lea r10, [rip + map_entry_buf]
    cmp qword ptr [r10], 0
    je .to_string_next

    cmp r13, 0
    je .to_string_key
    lea rcx, [rsp + 96]
    lea rdx, [rsp + 32]
    lea r8, [rsp + 48]
    call string_concat
    lea rcx, [rsp + 32]
    call string_free
    lea rcx, [rsp + 32]
    lea rdx, [rsp + 96]
    call string_copy
    lea rcx, [rsp + 96]
    call string_free

.to_string_key:
    lea r10, [rip + map_entry_buf]
    lea rcx, [rsp + 96]
    lea rdx, [rsp + 32]
    mov r8, [r10 + 8]
    call string_concat
    lea rcx, [rsp + 32]
    call string_free
    lea rcx, [rsp + 32]
    lea rdx, [rsp + 96]
    call string_copy
    lea rcx, [rsp + 96]
    call string_free

    lea rcx, [rsp + 96]
    lea rdx, [rsp + 32]
    lea r8, [rsp + 64]
    call string_concat
    lea rcx, [rsp + 32]
    call string_free
    lea rcx, [rsp + 32]
    lea rdx, [rsp + 96]
    call string_copy
    lea rcx, [rsp + 96]
    call string_free

    lea r10, [rip + map_entry_buf]
    lea rcx, [rsp + 96]
    lea rdx, [rsp + 32]
    mov r8, [r10 + 16]
    call string_concat
    lea rcx, [rsp + 32]
    call string_free
    lea rcx, [rsp + 32]
    lea rdx, [rsp + 96]
    call string_copy
    lea rcx, [rsp + 96]
    call string_free

    mov r13, 1
.to_string_next:
    inc r12
    jmp .to_string_loop

.to_string_done:
    lea rcx, [rsp + 96]
    lea rdx, [rsp + 32]
    lea r8, [rsp + 80]
    call string_concat
    mov rcx, r14
    lea rdx, [rsp + 96]
    call string_copy
    lea rcx, [rsp + 96]
    call string_free
    lea rcx, [rsp + 80]
    call string_free
    lea rcx, [rsp + 64]
    call string_free
    lea rcx, [rsp + 48]
    call string_free
    lea rcx, [rsp + 32]
    call string_free
    add rsp, 160
    pop r14
    pop r13
    pop r12
    pop rbx
    mov rax, 1
    ret
