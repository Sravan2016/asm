.intel_syntax noprefix

.extern pBadaFileOpen
.extern pBadaFileRead
.extern pBadaFileWrite
.extern pBadaFileSeek
.extern pBadaFileSize
.extern pBadaFileClose
.extern pBadaFileDelete
.extern bada_heap_alloc
.extern bada_heap_free
.extern print_cstr
.extern print_string
.extern print_uint
.extern filestring_open
.extern filestring_close
.extern string_from_cstr
.extern string_free
.extern string_length
.extern string_char_at

.global file_read_all
.global bada_file_open
.global bada_file_close
.global bada_file_read
.global bada_file_write
.global bada_file_seek
.global bada_file_delete
.global bada_file_size
.global bada_mem_alloc
.global bada_mem_free
.global file_print_lines_count
.global file_print_lines_string
.global file_line_reader_open
.global file_line_reader_open_string
.global file_line_reader_next
.global file_line_reader_close
.global file_line_reader_line_count
.global file_count_lines
.global file_get_line_at

.equ GENERIC_READ, 0x80000000
.equ GENERIC_WRITE, 0x40000000
.equ FILE_SHARE_READ, 1
.equ CREATE_ALWAYS, 2
.equ OPEN_EXISTING, 3
.equ OPEN_ALWAYS, 4
.equ FILE_ATTRIBUTE_NORMAL, 0x00000080
.equ HEAP_ZERO_MEMORY, 0x00000008
.equ INVALID_HANDLE_VALUE, -1
.section .data
msg_total_lines: .asciz "Total lines: "
msg_nl:          .asciz "\n"
mode_r:          .asciz "r"
mode_w:          .asciz "w"
mode_a:          .asciz "a"

.section .text

bada_mem_alloc:
    # rcx=size -> rax=ptr
    mov r8, rcx
    xor rcx, rcx
    mov rdx, HEAP_ZERO_MEMORY
    sub rsp, 32
    call bada_heap_alloc
    add rsp, 32
    ret

bada_mem_free:
    # rcx=ptr -> rax=status
    mov rdx, rcx
    xor rcx, rcx
    xor r8, r8
    sub rsp, 32
    call bada_heap_free
    add rsp, 32
    ret

bada_file_open:
    # rcx=path_ptr, rdx=mode_ptr -> rax=handle or 0
    sub rsp, 32
    call qword ptr [rip + pBadaFileOpen]
    add rsp, 32
    ret

bada_file_close:
    # rcx=handle -> rax=status
    sub rsp, 32
    call qword ptr [rip + pBadaFileClose]
    add rsp, 32
    ret

bada_file_read:
    # rcx=handle, rdx=buffer_ptr, r8=size -> rax=bytes_read
    sub rsp, 32
    call qword ptr [rip + pBadaFileRead]
    add rsp, 32
    ret

bada_file_write:
    # rcx=handle, rdx=buffer_ptr, r8=size -> rax=bytes_written
    sub rsp, 32
    call qword ptr [rip + pBadaFileWrite]
    add rsp, 32
    ret

bada_file_seek:
    # rcx=handle, rdx=offset, r8=origin -> rax=status
    sub rsp, 32
    call qword ptr [rip + pBadaFileSeek]
    add rsp, 32
    ret

bada_file_delete:
    # rcx=path_ptr -> rax=status
    sub rsp, 32
    call qword ptr [rip + pBadaFileDelete]
    add rsp, 32
    ret

bada_file_size:
    # rcx=handle -> rax=size
    sub rsp, 32
    call qword ptr [rip + pBadaFileSize]
    add rsp, 32
    ret

file_read_all:
    # rcx=path cstr, rdx=AsmString* out -> rax=1/0
    push rbx
    push r12
    push r13
    push r14
    push r15
    push rdi
    push rsi

    mov r12, rdx
    mov r15, rcx

    sub rsp, 544
    lea rdi, [rsp + 32]
    mov rsi, r15
    mov al, byte ptr [rsi]
    cmp al, '.'
    jne .normalize_copy
    mov al, byte ptr [rsi + 1]
    cmp al, '\\'
    je .normalize_skip_dot
    cmp al, '/'
    je .normalize_skip_dot
    jmp .normalize_copy
.normalize_skip_dot:
    add rsi, 2
.normalize_copy:
    mov al, byte ptr [rsi]
    test al, al
    jz .normalize_done
    cmp al, '/'
    jne .normalize_store
    mov al, '\\'
.normalize_store:
    mov byte ptr [rdi], al
    inc rdi
    inc rsi
    jmp .normalize_copy
.normalize_done:
    mov byte ptr [rdi], 0

    mov r13, rsp
    lea rcx, [r13]
    lea rdx, [r13 + 32]
    sub rsp, 32
    call filestring_open
    add rsp, 32
    test rax, rax
    jne .have_handle

    # if relative path, try "..\\" + path
    mov al, byte ptr [r15]
    cmp al, '\\'
    je .fail
    mov al, byte ptr [r15 + 1]
    cmp al, ':'
    je .fail
    lea rdi, [rsp + 288]
    mov byte ptr [rdi], '.'
    mov byte ptr [rdi + 1], '.'
    mov byte ptr [rdi + 2], '\\'
    lea rsi, [rsp + 32]
    lea rbx, [rdi + 3]
.copy_loop:
    mov al, byte ptr [rsi]
    mov byte ptr [rbx], al
    test al, al
    jz .copy_done
    inc rsi
    inc rbx
    jmp .copy_loop
.copy_done:
    lea rcx, [r13]
    mov rdx, rdi
    sub rsp, 32
    call filestring_open
    add rsp, 32
    test rax, rax
    jz .fail

.have_handle:
    lea rcx, [r13]
    sub rsp, 32
    call string_length
    add rsp, 32
    mov rbx, rax

    lea rcx, [rbx + 1]
    sub rsp, 32
    call bada_mem_alloc
    add rsp, 32
    test rax, rax
    jz .close_fail
    mov r14, rax          # buffer
    xor r15, r15
.read_loop:
    cmp r15, rbx
    jae .read_done
    sub rsp, 32
    lea rcx, [r13]
    mov rdx, r15
    call string_char_at
    add rsp, 32
    mov byte ptr [r14 + r15], al
    inc r15
    jmp .read_loop
.read_done:
    mov byte ptr [r14 + rbx], 0
    mov qword ptr [r12], r14
    mov qword ptr [r12 + 8], rbx

    lea rcx, [r13]
    sub rsp, 32
    call filestring_close
    add rsp, 32

    mov rax, 1
    add rsp, 544
    pop rsi
    pop rdi
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.close_fail:
    sub rsp, 32
    lea rcx, [r13]
    call filestring_close
    add rsp, 32
.fail:
    add rsp, 544
    xor rax, rax
    pop rsi
    pop rdi
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

file_print_lines_count:
    # rcx=path cstr -> rax=line count (prints total and lines)
    push rbx
    push r12
    push r13
    push r14
    push r15
    push rdi
    push rsi

    sub rsp, 48           # 32 shadow + 16 bytes for AsmString
    lea rdx, [rsp + 32]
    call file_read_all
    test rax, rax
    jz .fail_lines

    mov r14, [rsp + 32]   # buffer
    mov r15, [rsp + 40]   # length

    # count lines
    xor r13, r13          # line count
    mov rbx, r15
    mov rsi, r14
    test rbx, rbx
    jz .count_done
.count_loop:
    mov al, byte ptr [rsi]
    cmp al, 10            # '\n'
    jne .count_next
    inc r13
.count_next:
    inc rsi
    dec rbx
    jnz .count_loop
.count_done:
    test r15, r15
    jz .count_after
    mov al, byte ptr [r14 + r15 - 1]
    cmp al, 10
    je .count_after
    inc r13
.count_after:
    sub rsp, 32
    lea rcx, [rip + msg_total_lines]
    call print_cstr
    mov rcx, r13
    call print_uint
    lea rcx, [rip + msg_nl]
    call print_cstr
    add rsp, 32

    # print lines (loop over buffer)
    mov rsi, r14          # cursor
    mov r12, r14          # line start
    mov rcx, r15          # remaining
    test rcx, rcx
    jz .lines_done
.lines_loop:
    mov al, byte ptr [rsi]
    cmp al, 10            # '\n'
    jne .lines_next
    mov byte ptr [rsi], 0
    xor r9d, r9d
    cmp rsi, r12
    je .print_line
    mov al, byte ptr [rsi - 1]
    cmp al, 13            # '\r'
    jne .print_line
    mov byte ptr [rsi - 1], 0
    mov r9b, 1
.print_line:
    sub rsp, 32
    mov rcx, r12
    call print_cstr
    lea rcx, [rip + msg_nl]
    call print_cstr
    add rsp, 32
    cmp r9b, 1
    jne .restore_nl
    mov byte ptr [rsi - 1], 13
.restore_nl:
    mov byte ptr [rsi], 10
    lea r12, [rsi + 1]
.lines_next:
    inc rsi
    dec rcx
    jnz .lines_loop

    # print last line if file doesn't end with '\n'
    lea rdx, [r14 + r15]
    cmp r12, rdx
    je .lines_done
    sub rsp, 32
    mov rcx, r12
    call print_cstr
    lea rcx, [rip + msg_nl]
    call print_cstr
    add rsp, 32

.lines_done:
    mov rcx, r14
    sub rsp, 32
    call bada_mem_free
    add rsp, 32

    mov rax, r13
    add rsp, 48
    pop rsi
    pop rdi
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.fail_lines:
    add rsp, 48
    xor rax, rax
    pop rsi
    pop rdi
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

file_print_lines_string:
    # rcx=AsmString* path -> rax=1/0
    push rbx
    push r12
    push r13
    push r14
    push r15
    push rdi
    push rsi
    test rcx, rcx
    jz .fpls_fail
    mov rbx, rcx

    sub rsp, 32
    mov rcx, rbx
    call string_length
    add rsp, 32
    mov r12, rax

    lea rcx, [r12 + 1]
    sub rsp, 32
    call bada_mem_alloc
    add rsp, 32
    test rax, rax
    jz .fpls_fail
    mov r13, rax

    xor r14, r14
.fpls_copy_loop:
    cmp r14, r12
    jae .fpls_copy_done
    sub rsp, 32
    mov rcx, rbx
    mov rdx, r14
    call string_char_at
    add rsp, 32
    mov byte ptr [r13 + r14], al
    inc r14
    jmp .fpls_copy_loop
.fpls_copy_done:
    mov byte ptr [r13 + r12], 0

    sub rsp, 48
    mov rcx, r13
    call file_line_reader_open
    test rax, rax
    jz .fpls_cleanup_stack
.fpls_loop:
    lea rcx, [rsp + 32]
    call file_line_reader_next
    test rax, rax
    jz .fpls_close
    sub rsp, 32
    lea rcx, [rsp + 64]
    call print_string
    lea rcx, [rip + msg_nl]
    call print_cstr
    lea rcx, [rsp + 64]
    call string_free
    add rsp, 32
    jmp .fpls_loop
.fpls_close:
    sub rsp, 32
    call file_line_reader_close
    add rsp, 32
    add rsp, 48
    mov rcx, r13
    sub rsp, 32
    call bada_mem_free
    add rsp, 32
    mov rax, 1
    pop rsi
    pop rdi
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.fpls_cleanup_stack:
    add rsp, 48
    mov rcx, r13
    sub rsp, 32
    call bada_mem_free
    add rsp, 32
.fpls_fail:
    xor rax, rax
    pop rsi
    pop rdi
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

file_count_lines:
    # rcx=path cstr -> rax=line count
    push rbx
    push r12
    push r13
    push r14
    push r15
    push rdi
    push rsi

    sub rsp, 48           # 32 shadow + 16 bytes for AsmString
    lea rdx, [rsp + 32]
    call file_read_all
    test rax, rax
    jz .count_fail

    mov r14, [rsp + 32]   # buffer
    mov r15, [rsp + 40]   # length

    xor r13, r13          # line count
    mov rbx, r15
    mov rsi, r14
    test rbx, rbx
    jz .count_done2
.count_loop2:
    mov al, byte ptr [rsi]
    cmp al, 10
    jne .count_next2
    inc r13
.count_next2:
    inc rsi
    dec rbx
    jnz .count_loop2
.count_done2:
    test r15, r15
    jz .count_after2
    mov al, byte ptr [r14 + r15 - 1]
    cmp al, 10
    je .count_after2
    inc r13
.count_after2:
    mov rcx, r14
    sub rsp, 32
    call bada_mem_free
    add rsp, 32

    mov rax, r13
    add rsp, 48
    pop rsi
    pop rdi
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.count_fail:
    add rsp, 48
    xor rax, rax
    pop rsi
    pop rdi
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

file_get_line_at:
    # rcx=path cstr, rdx=index (0-based), r8=AsmString* out -> rax=1/0
    push rbx
    push r12
    push r13
    push r14
    push r15
    push rdi
    push rsi
    mov rbx, r8           # out pointer
    mov r12, rdx          # target index

    sub rsp, 48           # 32 shadow + 16 bytes for AsmString
    lea rdx, [rsp + 32]
    call file_read_all
    test rax, rax
    jz .get_fail_stack

    mov r14, [rsp + 32]   # buffer
    mov r15, [rsp + 40]   # length
    add rsp, 48

    lea r11, [r14 + r15]  # end
    mov r13, r14          # line start
    mov rsi, r14          # scan ptr
    xor r10, r10          # current index
    test r15, r15
    jz .get_no_line
.scan_loop2:
    cmp rsi, r11
    jae .scan_end2
    mov al, byte ptr [rsi]
    cmp al, 10
    jne .scan_next2
    # found line end at rsi
    cmp r10, r12
    je .have_line_nl
    inc r10
    lea r13, [rsi + 1]
.scan_next2:
    inc rsi
    jmp .scan_loop2
.scan_end2:
    cmp r13, r11
    jae .get_no_line
    cmp r10, r12
    jne .get_no_line
    mov rsi, r11
.have_line_nl:
    mov r9, rsi
    sub r9, r13           # line length
    mov r12, r9           # preserve length across calls
    test r12, r12
    jz .alloc_line
    mov al, byte ptr [r13 + r12 - 1]
    cmp al, 13
    jne .alloc_line
    dec r12
.alloc_line:
    lea rcx, [r12 + 1]
    sub rsp, 32
    call bada_mem_alloc
    add rsp, 32
    test rax, rax
    jz .get_fail_free
    mov r8, rax           # new buffer (preserve across AL use)
    mov rdi, rax

    mov r11, r12
    test r11, r11
    jz .copy_done2
    mov rsi, r13
.copy_loop2:
    mov al, byte ptr [rsi]
    mov byte ptr [rdi], al
    inc rsi
    inc rdi
    dec r11
    jnz .copy_loop2
.copy_done2:
    mov byte ptr [r8 + r12], 0
    mov [rbx], r8
    mov [rbx + 8], r12

    mov rcx, r14
    sub rsp, 32
    call bada_mem_free
    add rsp, 32

    mov rax, 1
    pop rsi
    pop rdi
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.get_no_line:
    # no such line
    mov rcx, r14
    sub rsp, 32
    call bada_mem_free
    add rsp, 32
    jmp .get_fail

.get_fail_free:
    mov rcx, r14
    sub rsp, 40
    call bada_mem_free
    add rsp, 40
.get_fail_stack:
    add rsp, 48
.get_fail:
    xor rax, rax
    pop rsi
    pop rdi
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

file_line_reader_open:
    # rcx=path cstr -> rax=1/0
    push rbx
    push r12
    push r13
    push r14
    push r15

    # close any existing buffer
    lea rax, [rip + line_buf_ptr]
    mov rdx, [rax]
    test rdx, rdx
    jz .open_read
    mov rcx, rdx
    sub rsp, 32
    call bada_mem_free
    add rsp, 32
    lea rax, [rip + line_buf_ptr]
    mov qword ptr [rax], 0

.open_read:
    sub rsp, 48           # 32 shadow + 16 bytes for AsmString
    lea rdx, [rsp + 32]
    call file_read_all
    test rax, rax
    jz .open_fail

    mov r14, [rsp + 32]   # buffer
    mov r15, [rsp + 40]   # length
    add rsp, 48

    lea rax, [rip + line_buf_ptr]
    mov [rax], r14
    lea rax, [rip + line_buf_len]
    mov [rax], r15
    lea rax, [rip + line_cursor]
    mov [rax], r14

    # count lines
    xor r13, r13
    mov rbx, r15
    mov r12, r14
    test rbx, rbx
    jz .count_done_lr
.count_loop_lr:
    mov al, byte ptr [r12]
    cmp al, 10
    jne .count_next_lr
    inc r13
.count_next_lr:
    inc r12
    dec rbx
    jnz .count_loop_lr
.count_done_lr:
    test r15, r15
    jz .count_after_lr
    mov al, byte ptr [r14 + r15 - 1]
    cmp al, 10
    je .count_after_lr
    inc r13
.count_after_lr:
    lea rax, [rip + line_total]
    mov [rax], r13

    mov rax, 1
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.open_fail:
    add rsp, 48
    xor rax, rax
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

file_line_reader_open_string:
    # rcx=AsmString* path -> rax=1/0
    push rbx
    push r12
    push r13
    push r14
    test rcx, rcx
    jz .open_string_fail
    mov rbx, rcx

    sub rsp, 32
    mov rcx, rbx
    call string_length
    add rsp, 32
    mov r12, rax

    lea rcx, [r12 + 1]
    sub rsp, 32
    call bada_mem_alloc
    add rsp, 32
    test rax, rax
    jz .open_string_fail_pop
    mov r13, rax

    xor r14, r14
.open_string_copy_loop:
    cmp r14, r12
    jae .open_string_copy_done
    sub rsp, 32
    mov rcx, rbx
    mov rdx, r14
    call string_char_at
    add rsp, 32
    mov byte ptr [r13 + r14], al
    inc r14
    jmp .open_string_copy_loop
.open_string_copy_done:
    mov byte ptr [r13 + r12], 0

    sub rsp, 32
    mov rcx, r13
    call file_line_reader_open
    add rsp, 32
    mov r12, rax

    mov rcx, r13
    sub rsp, 32
    call bada_mem_free
    add rsp, 32

    mov rax, r12
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.open_string_fail:
    xor rax, rax
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.open_string_fail_pop:
    xor rax, rax
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

file_line_reader_line_count:
    # returns total line count
    lea rax, [rip + line_total]
    mov rax, [rax]
    ret

file_line_reader_next:
    # rcx=AsmString* out -> rax=1/0
    push rbx
    push rdi
    push rsi
    push r12
    push r13
    push r14
    push r15
    mov rbx, rcx          # save out pointer

    lea rax, [rip + line_buf_ptr]
    mov r14, [rax]
    test r14, r14
    jz .next_fail
    lea rax, [rip + line_buf_len]
    mov r15, [rax]
    lea rax, [rip + line_cursor]
    mov r12, [rax]
    lea r11, [r14 + r15]
    cmp r12, r11
    jae .next_fail

    # find line end
    mov r13, r12          # scan ptr
.scan_loop:
    cmp r13, r11
    jae .scan_done
    mov al, byte ptr [r13]
    cmp al, 10
    je .scan_done
    inc r13
    jmp .scan_loop
.scan_done:
    mov r9, r13
    sub r9, r12           # line length
    test r9, r9
    jz .maybe_empty
    mov al, byte ptr [r13 - 1]
    cmp al, 13            # '\r'
    jne .maybe_empty
    dec r9
.maybe_empty:
    mov rsi, r9
    # allocate line (len + 1)
    lea rcx, [rsi + 1]
    sub rsp, 32
    call bada_mem_alloc
    add rsp, 32
    test rax, rax
    jz .next_fail
    mov r10, rax          # new buffer

    # copy bytes
    mov r11, rsi          # count
    test r11, r11
    jz .copy_done_lr
    mov r9, r12
    mov rdi, r10
.copy_loop_lr:
    mov al, byte ptr [r9]
    mov byte ptr [rdi], al
    inc r9
    inc rdi
    dec r11
    jnz .copy_loop_lr
.copy_done_lr:
    mov byte ptr [r10 + rsi], 0

    # convert the temporary C string into a real String object
    sub rsp, 32
    mov rcx, rbx
    mov rdx, r10
    call string_from_cstr
    add rsp, 32

    # free the temporary heap buffer
    mov rcx, r10
    sub rsp, 32
    call bada_mem_free
    add rsp, 32

    # advance cursor
    lea r11, [r14 + r15]
    cmp r13, r11
    jae .set_cursor_done
    mov al, byte ptr [r13]
    cmp al, 10
    jne .set_cursor_done
    inc r13
.set_cursor_done:
    lea rax, [rip + line_cursor]
    mov [rax], r13

    mov rax, 1
    pop r15
    pop r14
    pop r13
    pop r12
    pop rsi
    pop rdi
    pop rbx
    ret

.next_fail:
    xor rax, rax
    pop r15
    pop r14
    pop r13
    pop r12
    pop rsi
    pop rdi
    pop rbx
    ret

file_line_reader_close:
    push rbx
    lea rax, [rip + line_buf_ptr]
    mov rbx, [rax]
    test rbx, rbx
    jz .close_done
    mov rcx, rbx
    sub rsp, 32
    call bada_mem_free
    add rsp, 32
    lea rax, [rip + line_buf_ptr]
    mov qword ptr [rax], 0
    lea rax, [rip + line_buf_len]
    mov qword ptr [rax], 0
    lea rax, [rip + line_cursor]
    mov qword ptr [rax], 0
    lea rax, [rip + line_total]
    mov qword ptr [rax], 0
.close_done:
    pop rbx
    ret

.section .bss
.align 8
bytes_read: .quad 0
line_buf_ptr: .quad 0
line_buf_len: .quad 0
line_cursor:  .quad 0
line_total:   .quad 0
