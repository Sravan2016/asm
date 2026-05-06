.intel_syntax noprefix

.section .data
.align 8
.global pCreateFileA
.global pReadFile
.global pSetFilePointerEx
.global pGetFileSizeEx
.global pCloseHandle
.global pDeleteFileA
.global pBadaFileOpen
.global pBadaFileRead
.global pBadaFileWrite
.global pBadaFileSeek
.global pBadaFileSize
.global pBadaFileClose
.global pBadaFileDelete
.global pGetStdHandle
.global pWriteFile
.global pCreateThread
.global pWaitForSingleObject
.global pInitializeCriticalSection
.global pEnterCriticalSection
.global pLeaveCriticalSection
.global pTlsAlloc
.global pTlsSetValue
.global last_ntstatus_create
.global last_ntstatus_write
.global last_io_info_write
.global last_handle_create
.global last_handle_write
.global last_writefile_lp_ptr
.global last_writefile_lp_value
.global last_lpnumber_written
.global last_lpnumber_readback
pCreateFileA:      .quad my_CreateFileA
pReadFile:         .quad my_ReadFile
pSetFilePointerEx: .quad my_SetFilePointerEx
pGetFileSizeEx:    .quad my_GetFileSizeEx
pCloseHandle:      .quad my_CloseHandle
pDeleteFileA:      .quad my_DeleteFileA
pBadaFileOpen:     .quad my_BadaFileOpen
pBadaFileRead:     .quad my_BadaFileRead
pBadaFileWrite:    .quad my_BadaFileWrite
pBadaFileSeek:     .quad my_BadaFileSeek
pBadaFileSize:     .quad my_BadaFileSize
pBadaFileClose:    .quad my_BadaFileClose
pBadaFileDelete:   .quad my_BadaFileDelete
pGetStdHandle:     .quad my_GetStdHandle
pWriteFile:        .quad my_WriteFile
pCreateThread:     .quad my_CreateThread
pWaitForSingleObject: .quad my_WaitForSingleObject
pInitializeCriticalSection: .quad my_InitializeCriticalSection
pEnterCriticalSection: .quad my_EnterCriticalSection
pLeaveCriticalSection: .quad my_LeaveCriticalSection
pTlsAlloc:         .quad my_TlsAlloc
pTlsSetValue:      .quad my_TlsSetValue
.align 4
last_ntstatus_create: .long 0
.align 4
last_ntstatus_write: .long 0
.align 8
last_io_info_write: .quad 0
.align 8
last_handle_create: .quad 0
.align 8
last_handle_write: .quad 0
.align 8
last_writefile_lp_ptr: .quad 0
.align 4
last_writefile_lp_value: .long 0
.align 4
last_lpnumber_written: .long 0
.align 4
last_lpnumber_readback: .long 0

.section .text

.extern NtCreateFile
.extern NtReadFile
.extern NtWriteFile
.extern NtClose
.extern NtQueryInformationFile
.extern NtSetInformationFile
.extern NtDeleteFile
.extern RtlDosPathNameToNtPathName_U
.extern RtlGetFullPathName_U
.extern RtlFreeUnicodeString
.extern RtlCreateUserThread
.extern NtWaitForSingleObject
.extern RtlInitializeCriticalSection
.extern RtlEnterCriticalSection
.extern RtlLeaveCriticalSection
.extern TlsAlloc
.extern TlsSetValue
.extern stdout_handle

.equ INVALID_HANDLE_VALUE, -1
.equ OBJ_CASE_INSENSITIVE, 0x40
.equ FILE_SYNCHRONOUS_IO_NONALERT, 0x20
.equ FILE_NON_DIRECTORY_FILE, 0x40
.equ FILE_OPEN, 1
.equ FILE_CREATE, 2
.equ FILE_OPEN_IF, 3
.equ FILE_OVERWRITE, 4
.equ FILE_OVERWRITE_IF, 5
.equ FILE_BEGIN, 0
.equ FILE_CURRENT, 1
.equ FILE_END, 2
.equ FilePositionInformation, 14
.equ FileStandardInformation, 5
.equ INFINITE, 0xFFFFFFFF
.equ WAIT_OBJECT_0, 0
.equ WAIT_TIMEOUT, 258
.equ WAIT_FAILED, 0xFFFFFFFF
.equ STATUS_TIMEOUT, 0x00000102

ansi_to_wide:
    xor eax, eax
.atw_loop:
    cmp eax, r8d
    jae .atw_done
    movzx r9d, byte ptr [rcx]
    mov word ptr [rdx + rax*2], r9w
    inc rcx
    test r9b, r9b
    jz .atw_done
    inc eax
    jmp .atw_loop
.atw_done:
    ret

my_GetStdHandle:
    mov rax, qword ptr gs:[0x60]
    mov rax, [rax + 0x20]
    cmp ecx, -11
    je .gsh_out
    cmp ecx, -12
    je .gsh_err
    mov rax, [rax + 0x20]
    ret
.gsh_out:
    mov rax, [rax + 0x28]
    ret
.gsh_err:
    mov rax, [rax + 0x30]
    ret

my_CloseHandle:
    sub rsp, 40
    call NtClose
    add rsp, 40
    test eax, eax
    js .ch_fail
    mov eax, 1
    ret
.ch_fail:
    xor eax, eax
    ret

my_BadaFileOpen:
    # rcx=path_ptr, rdx=mode_ptr -> rax=handle or 0
    push rbx
    push r12
    mov rbx, rcx
    mov r12, rdx
    mov edx, 0x80000000
    mov r8d, 1
    mov r9d, 3
    test r12, r12
    jz .bfo_call
    mov al, byte ptr [r12]
    cmp al, 'w'
    je .bfo_write
    cmp al, 'a'
    je .bfo_append
    jmp .bfo_call
.bfo_write:
    mov edx, 0xC0000000
    mov r9d, 2
    jmp .bfo_call
.bfo_append:
    mov edx, 0xC0000000
    mov r9d, 4
.bfo_call:
    mov rcx, rbx
    sub rsp, 64
    mov qword ptr [rsp + 32], r9
    mov qword ptr [rsp + 40], 0x80
    mov qword ptr [rsp + 48], 0
    call my_CreateFileA
    add rsp, 64
    cmp rax, -1
    je .bfo_fail
    test r12, r12
    jz .bfo_done
    mov al, byte ptr [r12]
    cmp al, 'a'
    jne .bfo_done
    mov rcx, rax
    xor rdx, rdx
    mov r8, 2
    call my_BadaFileSeek
.bfo_done:
    pop r12
    pop rbx
    ret
.bfo_fail:
    xor eax, eax
    pop r12
    pop rbx
    ret

my_BadaFileClose:
    jmp my_CloseHandle

my_BadaFileRead:
    # rcx=handle, rdx=buffer_ptr, r8=size -> rax=bytes_read
    sub rsp, 40
    lea r9, [rsp + 32]
    call my_ReadFile
    test eax, eax
    jz .bfr_fail
    mov eax, dword ptr [rsp + 32]
    add rsp, 40
    ret
.bfr_fail:
    add rsp, 40
    xor eax, eax
    ret

my_BadaFileWrite:
    # rcx=handle, rdx=buffer_ptr, r8=size -> rax=bytes_written
    sub rsp, 40
    lea r9, [rsp + 32]
    call my_WriteFile
    test eax, eax
    jz .bfw_fail
    mov eax, dword ptr [rsp + 32]
    add rsp, 40
    ret
.bfw_fail:
    add rsp, 40
    xor eax, eax
    ret

my_BadaFileSeek:
    # rcx=handle, rdx=offset, r8=origin -> rax=status
    xor r9d, r9d
    jmp my_SetFilePointerEx

my_BadaFileSize:
    # rcx=handle -> rax=size
    sub rsp, 40
    lea rdx, [rsp + 32]
    call my_GetFileSizeEx
    test eax, eax
    jz .bfs_fail
    mov rax, [rsp + 32]
    add rsp, 40
    ret
.bfs_fail:
    add rsp, 40
    xor eax, eax
    ret

my_BadaFileDelete:
    jmp my_DeleteFileA

my_CreateFileA:
    mov r11, rsp
    push rbx
    push rsi
    sub rsp, 4608
    mov rbx, rsp
    mov qword ptr [rbx + 0], rcx
    mov qword ptr [rbx + 8], rdx
    mov qword ptr [rbx + 16], r8
    mov eax, dword ptr [r11 + 40]
    mov dword ptr [rbx + 24], eax

    mov rcx, qword ptr [rbx + 0]
    lea rdx, [rbx + 64]
    mov r8d, 1024
    call ansi_to_wide

    lea rcx, [rbx + 64]
    mov edx, 2048
    lea r8,  [rbx + 2112]
    xor r9d, r9d
    sub rsp, 40
    call RtlGetFullPathName_U
    add rsp, 40
    test eax, eax
    jz .cf_fail

    lea rcx, [rbx + 2112]
    lea rdx, [rbx + 4160]
    xor r8d, r8d
    xor r9d, r9d
    sub rsp, 40
    call RtlDosPathNameToNtPathName_U
    add rsp, 40
    test al, al
    jz .cf_fail

    lea rsi, [rbx + 4160]
    lea rax, [rbx + 4176]
    mov dword ptr [rax + 0], 48
    mov dword ptr [rax + 4], 0
    mov qword ptr [rax + 8], 0
    mov qword ptr [rax + 16], rsi
    mov qword ptr [rax + 24], OBJ_CASE_INSENSITIVE
    mov qword ptr [rax + 32], 0
    mov qword ptr [rax + 40], 0

    mov eax, dword ptr [rbx + 24]
    cmp eax, 1
    je 1f
    cmp eax, 2
    je 2f
    cmp eax, 3
    je 3f
    cmp eax, 4
    je 4f
    cmp eax, 5
    je 5f
    mov eax, FILE_OPEN
    jmp 6f
1:  mov eax, FILE_CREATE
    jmp 6f
2:  mov eax, FILE_OVERWRITE_IF
    jmp 6f
3:  mov eax, FILE_OPEN
    jmp 6f
4:  mov eax, FILE_OPEN_IF
    jmp 6f
5:  mov eax, FILE_OVERWRITE
6:  mov dword ptr [rbx + 28], eax

    lea rcx, [rbx + 4240]
    mov rdx, qword ptr [rbx + 8]
    or rdx, 0x00100000
    lea r8,  [rbx + 4176]
    lea r9,  [rbx + 4224]
    sub rsp, 104
    mov qword ptr [rsp + 32], 0
    mov qword ptr [rsp + 40], 0
    mov eax, dword ptr [rbx + 16]
    or eax, 7
    mov qword ptr [rsp + 48], rax
    mov eax, dword ptr [rbx + 28]
    mov qword ptr [rsp + 56], rax
    mov eax, (FILE_SYNCHRONOUS_IO_NONALERT | FILE_NON_DIRECTORY_FILE)
    mov qword ptr [rsp + 64], rax
    mov qword ptr [rsp + 72], 0
    mov qword ptr [rsp + 80], 0
    call NtCreateFile
    mov dword ptr [rip + last_ntstatus_create], eax
    add rsp, 104
    test eax, eax
    js .cf_fail_free
    mov rax, qword ptr [rbx + 4240]
    mov qword ptr [rip + last_handle_create], rax
    mov qword ptr [rbx + 32], rax
    lea rcx, [rbx + 4160]
    sub rsp, 40
    call RtlFreeUnicodeString
    add rsp, 40
    mov rax, qword ptr [rbx + 32]
    add rsp, 4608
    pop rsi
    pop rbx
    ret

.cf_fail_free:
    lea rcx, [rbx + 4160]
    sub rsp, 40
    call RtlFreeUnicodeString
    add rsp, 40
.cf_fail:
    mov rax, INVALID_HANDLE_VALUE
    mov qword ptr [rip + last_handle_create], rax
    add rsp, 4608
    pop rsi
    pop rbx
    ret

my_ReadFile:
    sub rsp, 136
    mov qword ptr [rsp + 104], r9
    lea rax, [rsp + 72]
    mov qword ptr [rsp + 32], rax
    mov qword ptr [rsp + 40], rdx
    mov eax, r8d
    mov qword ptr [rsp + 48], rax
    mov qword ptr [rsp + 56], 0
    mov qword ptr [rsp + 64], 0
    xor edx, edx
    xor r8d, r8d
    xor r9d, r9d
    call NtReadFile
    test eax, eax
    js .rf_fail2
    mov eax, dword ptr [rsp + 72 + 8]
    mov r10, qword ptr [rsp + 104]
    test r10, r10
    jz .rf_ok
    mov dword ptr [r10], eax
.rf_ok:
    mov eax, 1
    add rsp, 136
    ret
.rf_fail2:
    add rsp, 136
    xor eax, eax
    ret

my_WriteFile:
    sub rsp, 136
    mov qword ptr [rsp + 104], r9
    mov qword ptr [rsp + 96], rcx
    lea rax, [rsp + 72]
    mov qword ptr [rsp + 32], rax
    mov qword ptr [rsp + 40], rdx
    mov eax, r8d
    mov qword ptr [rsp + 48], rax
    mov qword ptr [rsp + 56], 0
    mov qword ptr [rsp + 64], 0
    xor edx, edx
    xor r8d, r8d
    xor r9d, r9d
    call NtWriteFile
    mov dword ptr [rsp + 88], eax
    mov r11, qword ptr [rsp + 96]
    mov rax, qword ptr [rip + stdout_handle]
    cmp r11, rax
    je .wf_skip_dbg
    mov qword ptr [rip + last_handle_write], r11
    mov eax, dword ptr [rsp + 88]
    mov dword ptr [rip + last_ntstatus_write], eax
.wf_skip_dbg:
    mov eax, dword ptr [rsp + 88]
    test eax, eax
    js .wf_fail2
    mov rax, qword ptr [rsp + 72 + 8]
    mov r11, qword ptr [rsp + 96]
    mov rdx, qword ptr [rip + stdout_handle]
    cmp r11, rdx
    je .wf_skip_dbg2
    mov qword ptr [rip + last_io_info_write], rax
.wf_skip_dbg2:
    mov eax, dword ptr [rsp + 72 + 8]
    mov r10, qword ptr [rsp + 104]
    mov qword ptr [rip + last_writefile_lp_ptr], r10
    test r10, r10
    jz .wf_ok
    mov dword ptr [r10], eax
    mov dword ptr [rip + last_writefile_lp_value], eax
    mov r11, qword ptr [rsp + 96]
    mov rdx, qword ptr [rip + stdout_handle]
    cmp r11, rdx
    je .wf_ok
    mov dword ptr [rip + last_lpnumber_written], eax
    mov ecx, dword ptr [r10]
    mov dword ptr [rip + last_lpnumber_readback], ecx
.wf_ok:
    mov eax, 1
    add rsp, 136
    ret
.wf_fail2:
    add rsp, 136
    xor eax, eax
    ret

my_SetFilePointerEx:
    push rbx
    sub rsp, 136
    mov rbx, rsp
    mov qword ptr [rbx + 0], rcx
    mov qword ptr [rbx + 8], rdx
    mov qword ptr [rbx + 16], r8
    mov dword ptr [rbx + 24], r9d

    mov eax, dword ptr [rbx + 24]
    cmp eax, FILE_BEGIN
    je .sfp_begin
    cmp eax, FILE_CURRENT
    je .sfp_current
    cmp eax, FILE_END
    je .sfp_end
    jmp .sfp_fail

.sfp_begin:
    mov rax, qword ptr [rbx + 8]
    jmp .sfp_set

.sfp_current:
    mov rcx, qword ptr [rbx + 0]
    lea rdx, [rbx + 48]
    lea r8,  [rbx + 96]
    mov r9d, 8
    sub rsp, 40
    mov dword ptr [rsp + 32], FilePositionInformation
    call NtQueryInformationFile
    add rsp, 40
    test eax, eax
    js .sfp_fail
    mov rax, qword ptr [rbx + 96]
    add rax, qword ptr [rbx + 8]
    jmp .sfp_set

.sfp_end:
    mov rcx, qword ptr [rbx + 0]
    lea rdx, [rbx + 48]
    lea r8,  [rbx + 96]
    mov r9d, 32
    sub rsp, 40
    mov dword ptr [rsp + 32], FileStandardInformation
    call NtQueryInformationFile
    add rsp, 40
    test eax, eax
    js .sfp_fail
    mov rax, qword ptr [rbx + 96 + 8]
    add rax, qword ptr [rbx + 8]

.sfp_set:
    mov qword ptr [rbx + 96], rax
    mov rcx, qword ptr [rbx + 0]
    lea rdx, [rbx + 48]
    lea r8,  [rbx + 96]
    mov r9d, 8
    sub rsp, 40
    mov dword ptr [rsp + 32], FilePositionInformation
    call NtSetInformationFile
    add rsp, 40
    test eax, eax
    js .sfp_fail
    mov r10, qword ptr [rbx + 16]
    test r10, r10
    jz .sfp_ok
    mov rax, qword ptr [rbx + 96]
    mov qword ptr [r10], rax
.sfp_ok:
    mov eax, 1
    add rsp, 136
    pop rbx
    ret

.sfp_fail:
    xor eax, eax
    add rsp, 136
    pop rbx
    ret

my_GetFileSizeEx:
    sub rsp, 136
    mov qword ptr [rsp + 104], rdx
    lea rdx, [rsp + 40]
    lea r8,  [rsp + 56]
    mov r9d, 32
    mov dword ptr [rsp + 32], FileStandardInformation
    call NtQueryInformationFile
    test eax, eax
    js .gfs_fail2
    mov r10, qword ptr [rsp + 104]
    mov rax, qword ptr [rsp + 56 + 8]
    mov [r10], rax
    mov eax, 1
    add rsp, 136
    ret
.gfs_fail2:
    add rsp, 136
    xor eax, eax
    ret

my_DeleteFileA:
    push rbx
    push rsi
    sub rsp, 4608
    mov rbx, rsp
    mov qword ptr [rbx + 0], rcx

    mov rcx, qword ptr [rbx + 0]
    lea rdx, [rbx + 64]
    mov r8d, 1024
    call ansi_to_wide

    lea rcx, [rbx + 64]
    mov edx, 2048
    lea r8,  [rbx + 2112]
    xor r9d, r9d
    sub rsp, 40
    call RtlGetFullPathName_U
    add rsp, 40
    test eax, eax
    jz .df_fail

    lea rcx, [rbx + 2112]
    lea rdx, [rbx + 4160]
    xor r8d, r8d
    xor r9d, r9d
    sub rsp, 40
    call RtlDosPathNameToNtPathName_U
    add rsp, 40
    test al, al
    jz .df_fail

    lea rsi, [rbx + 4160]
    lea rax, [rbx + 4176]
    mov dword ptr [rax + 0], 48
    mov dword ptr [rax + 4], 0
    mov qword ptr [rax + 8], 0
    mov qword ptr [rax + 16], rsi
    mov qword ptr [rax + 24], OBJ_CASE_INSENSITIVE
    mov qword ptr [rax + 32], 0
    mov qword ptr [rax + 40], 0

    mov rcx, rax
    sub rsp, 40
    call NtDeleteFile
    add rsp, 40
    test eax, eax
    js .df_fail_free
    lea rcx, [rbx + 4160]
    sub rsp, 40
    call RtlFreeUnicodeString
    add rsp, 40
    mov eax, 1
    add rsp, 4608
    pop rsi
    pop rbx
    ret

my_CreateThread:
    # rcx=lpThreadAttributes, rdx=dwStackSize, r8=lpStartAddress, r9=lpParameter
    # [rsp+40]=dwCreationFlags, [rsp+48]=lpThreadId
    sub rsp, 120
    mov qword ptr [rsp + 96], r8
    mov qword ptr [rsp + 104], r9
    mov eax, dword ptr [rsp + 120 + 40]
    and eax, 4
    setnz al
    movzx r8d, al

    mov qword ptr [rsp + 32], -1
    mov qword ptr [rsp + 40], 0
    mov byte ptr  [rsp + 48], r8b
    mov qword ptr [rsp + 56], 0
    mov qword ptr [rsp + 64], 0
    mov qword ptr [rsp + 72], 0
    mov rax, qword ptr [rsp + 96]
    mov qword ptr [rsp + 80], rax
    mov rax, qword ptr [rsp + 104]
    mov qword ptr [rsp + 88], rax
    lea rax, [rsp + 16]
    mov qword ptr [rsp + 96], rax
    lea rax, [rsp + 0]
    mov qword ptr [rsp + 104], rax
    lea rax, [rsp + 8]
    mov qword ptr [rsp + 112], rax
    call RtlCreateUserThread
    test eax, eax
    js .ct_fail
    mov r10, qword ptr [rsp + 120 + 48]
    test r10, r10
    jz .ct_ok
    mov rax, qword ptr [rsp + 8]
    mov dword ptr [r10], eax
.ct_ok:
    mov rax, qword ptr [rsp + 0]
    add rsp, 120
    ret
.ct_fail:
    xor eax, eax
    add rsp, 120
    ret

my_WaitForSingleObject:
    # rcx=hHandle, edx=dwMilliseconds -> eax=WAIT_*
    sub rsp, 80
    mov qword ptr [rsp + 64], rcx
    mov eax, edx
    cmp eax, INFINITE
    je .wso_inf
    mov rax, rdx
    imul rax, rax, 10000
    neg rax
    mov qword ptr [rsp + 32], rax
    lea r8, [rsp + 32]
    jmp .wso_call
.wso_inf:
    xor r8, r8
.wso_call:
    mov rcx, qword ptr [rsp + 64]
    xor edx, edx
    call NtWaitForSingleObject
    test eax, eax
    js .wso_fail
    cmp eax, STATUS_TIMEOUT
    je .wso_timeout
    mov eax, WAIT_OBJECT_0
    add rsp, 80
    ret
.wso_timeout:
    mov eax, WAIT_TIMEOUT
    add rsp, 80
    ret
.wso_fail:
    mov eax, WAIT_FAILED
    add rsp, 80
    ret

my_InitializeCriticalSection:
    sub rsp, 40
    call RtlInitializeCriticalSection
    add rsp, 40
    test eax, eax
    js .ics_fail
    mov eax, 1
    ret
.ics_fail:
    xor eax, eax
    ret

my_EnterCriticalSection:
    sub rsp, 40
    call RtlEnterCriticalSection
    add rsp, 40
    test eax, eax
    js .ecs_fail
    mov eax, 1
    ret
.ecs_fail:
    xor eax, eax
    ret

my_LeaveCriticalSection:
    sub rsp, 40
    call RtlLeaveCriticalSection
    add rsp, 40
    test eax, eax
    js .lcs_fail
    mov eax, 1
    ret
.lcs_fail:
    xor eax, eax
    ret

my_TlsAlloc:
    sub rsp, 40
    call TlsAlloc
    add rsp, 40
    ret

my_TlsSetValue:
    sub rsp, 40
    call TlsSetValue
    add rsp, 40
    ret

.df_fail_free:
    lea rcx, [rbx + 4160]
    sub rsp, 40
    call RtlFreeUnicodeString
    add rsp, 40
.df_fail:
    xor eax, eax
    add rsp, 4608
    pop rsi
    pop rbx
    ret
