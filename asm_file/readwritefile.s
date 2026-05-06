.intel_syntax noprefix

.extern pCreateFileA
.extern pReadFile
.extern pGetFileSizeEx
.extern pCloseHandle
.extern HeapAlloc
.extern HeapFree
.extern print_cstr
.extern print_uint

.extern heap_handle

.global file_read_all
.global file_print_lines_count
.global file_line_reader_open
.global file_line_reader_open_string
.global file_line_reader_next
.global file_line_reader_close
.global file_line_reader_line_count
.global file_count_lines
.global file_get_line_at

.equ GENERIC_READ, 0x80000000
.equ FILE_SHARE_READ, 1
.equ OPEN_EXISTING, 3
.equ FILE_ATTRIBUTE_NORMAL, 0x00000080
.equ HEAP_ZERO_MEMORY, 0x00000008
.equ INVALID_HANDLE_VALUE, -1

.section .data
msg_total_lines: .asciz "Total lines: "
msg_nl:          .asciz "\n"

.section .text

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

    # CreateFileA(path, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL)
    mov rcx, r15
    mov rdx, GENERIC_READ
    mov r8, FILE_SHARE_READ
    xor r9, r9
    sub rsp, 64
    mov qword ptr [rsp + 32], OPEN_EXISTING
    mov qword ptr [rsp + 40], FILE_ATTRIBUTE_NORMAL
    mov qword ptr [rsp + 48], 0
    call qword ptr [rip + pCreateFileA]
    add rsp, 64
    cmp rax, INVALID_HANDLE_VALUE
    jne .have_handle

    # if relative path, try "..\\" + path
    mov al, byte ptr [r15]
    cmp al, '\\'
    je .fail
    mov al, byte ptr [r15 + 1]
    cmp al, ':'
    je .fail
    sub rsp, 544
    lea rdi, [rsp + 32]
    mov byte ptr [rdi], '.'
    mov byte ptr [rdi + 1], '.'
    mov byte ptr [rdi + 2], '\\'
    lea rsi, [r15]
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
    mov rcx, rdi
    mov rdx, GENERIC_READ
    mov r8, FILE_SHARE_READ
    xor r9, r9
    sub rsp, 64
    mov qword ptr [rsp + 32], OPEN_EXISTING
    mov qword ptr [rsp + 40], FILE_ATTRIBUTE_NORMAL
    mov qword ptr [rsp + 48], 0
    call qword ptr [rip + pCreateFileA]
    add rsp, 64
    add rsp, 544
    cmp rax, INVALID_HANDLE_VALUE
    je .fail

.have_handle:
    mov r13, rax
    # GetFileSizeEx(handle, &size)
    sub rsp, 32
    lea rdx, [rsp + 16]
    mov rcx, r13
    call qword ptr [rip + pGetFileSizeEx]
    test eax, eax
    jz .close_fail_size
    mov rbx, [rsp + 16]   # file size
    add rsp, 32

    # HeapAlloc(size+1)
    lea rax, [rip + heap_handle]
    mov rcx, [rax]
    mov rdx, HEAP_ZERO_MEMORY
    lea r8, [rbx + 1]
    sub rsp, 32
    call HeapAlloc
    add rsp, 32
    test rax, rax
    jz .close_fail
    mov r14, rax          # buffer

    # ReadFile(handle, buffer, size, &bytesRead, NULL)
    sub rsp, 48
    lea r9, [rip + bytes_read]
    mov rcx, r13
    mov rdx, r14
    mov r8d, ebx
    mov qword ptr [rsp + 32], 0
    call qword ptr [rip + pReadFile]
    test eax, eax
    jz .read_fail

    mov byte ptr [r14 + rbx], 0
    mov qword ptr [r12], r14
    mov qword ptr [r12 + 8], rbx
    add rsp, 48

    mov rcx, r13
    sub rsp, 32
    call qword ptr [rip + pCloseHandle]
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

.read_fail:
    add rsp, 48
    # free buffer
    lea rax, [rip + heap_handle]
    mov rcx, [rax]
    mov rdx, r14
    xor r8, r8
    sub rsp, 32
    call HeapFree
    add rsp, 32
    jmp .close_fail
.close_fail_size:
    add rsp, 32
.close_fail:
    mov rcx, r13
    sub rsp, 32
    call qword ptr [rip + pCloseHandle]
    add rsp, 32
.fail:
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
    # free buffer
    lea rax, [rip + heap_handle]
    mov rcx, [rax]
    mov rdx, r14
    xor r8, r8
    sub rsp, 32
    call HeapFree
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
    lea rax, [rip + heap_handle]
    mov rcx, [rax]
    mov rdx, r14
    xor r8, r8
    sub rsp, 32
    call HeapFree
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
    lea rax, [rip + heap_handle]
    mov rcx, [rax]
    mov rdx, HEAP_ZERO_MEMORY
    lea r8, [r12 + 1]
    sub rsp, 32
    call HeapAlloc
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

    lea rax, [rip + heap_handle]
    mov rcx, [rax]
    mov rdx, r14
    xor r8, r8
    sub rsp, 32
    call HeapFree
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
    lea rax, [rip + heap_handle]
    mov rcx, [rax]
    mov rdx, r14
    xor r8, r8
    sub rsp, 32
    call HeapFree
    add rsp, 32
    jmp .get_fail

.get_fail_free:
    lea rax, [rip + heap_handle]
    mov rcx, [rax]
    mov rdx, r14
    xor r8, r8
    sub rsp, 40
    call HeapFree
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
    lea rax, [rip + heap_handle]
    mov rcx, [rax]
    xor r8, r8
    sub rsp, 32
    call HeapFree
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
    test rcx, rcx
    jz .open_string_fail
    mov rcx, [rcx]
    jmp file_line_reader_open
.open_string_fail:
    xor rax, rax
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
    lea rax, [rip + heap_handle]
    mov rcx, [rax]
    mov rdx, HEAP_ZERO_MEMORY
    lea r8, [rsi + 1]
    sub rsp, 32
    call HeapAlloc
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

    # set out
    mov [rbx], r10
    mov [rbx + 8], rsi

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
    lea rax, [rip + heap_handle]
    mov rcx, [rax]
    mov rdx, rbx
    xor r8, r8
    sub rsp, 32
    call HeapFree
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
