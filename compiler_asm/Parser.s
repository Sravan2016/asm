.intel_syntax noprefix

.equ TOK_KIND, 0
.equ TOK_LEXEME, 8
.equ TOK_SIZE, 16

.equ PS_TOKENS, 0
.equ PS_COUNT, 8
.equ PS_CURRENT, 16
.equ PS_ERRORS, 24
.equ PS_IMPORTS, 32
.equ PS_CLASSES, 40
.equ PS_METHODS, 48
.equ PS_STATEMENTS, 56
.equ PS_EXPRESSIONS, 64
.equ PS_LAST_TYPE, 72
.equ PS_LAST_FLAGS, 80

.equ EndOfFile, 0
.equ Invalid, 1
.equ Identifier, 2
.equ IntegerLiteral, 3
.equ LongLiteral, 4
.equ DoubleLiteral, 5
.equ StringLiteral, 6
.equ KeywordIf, 10
.equ KeywordElse, 11
.equ KeywordWhile, 12
.equ KeywordSwitch, 13
.equ KeywordFor, 14
.equ KeywordCase, 15
.equ KeywordDefault, 16
.equ KeywordPrint, 17
.equ KeywordPrintln, 18
.equ KeywordInteger, 19
.equ KeywordFileInteger, 20
.equ KeywordString, 21
.equ KeywordFileString, 22
.equ KeywordLong, 23
.equ KeywordFileLong, 24
.equ KeywordDouble, 25
.equ KeywordFileDouble, 26
.equ KeywordBoolean, 27
.equ KeywordFileBoolean, 28
.equ KeywordArray, 29
.equ KeywordMap, 30
.equ KeywordThread, 31
.equ KeywordFrom, 32
.equ KeywordTrue, 33
.equ KeywordFalse, 34
.equ KeywordPrivate, 35
.equ ArrowClassStart, 36
.equ ArrowClassEnd, 37
.equ ArrowMethodStart, 38
.equ ArrowMethodEnd, 39
.equ FatArrow, 40
.equ Plus, 41
.equ PlusPlus, 42
.equ Minus, 43
.equ MinusMinus, 44
.equ Star, 45
.equ Slash, 46
.equ Percent, 47
.equ Assign, 48
.equ EqualEqual, 49
.equ Bang, 50
.equ BangEqual, 51
.equ Less, 52
.equ LessEqual, 53
.equ Greater, 54
.equ GreaterEqual, 55
.equ AndAnd, 56
.equ OrOr, 57
.equ Question, 58
.equ Comma, 59
.equ Colon, 60
.equ Semicolon, 61
.equ Dot, 62
.equ DoubleColon, 63
.equ LeftParen, 64
.equ RightParen, 65
.equ LeftBrace, 66
.equ RightBrace, 67
.equ LeftBracket, 68
.equ RightBracket, 69

.section .rdata
s_from: .asciz "from"
s_return: .asciz "return"
s_unknown: .asciz "Unknown"

.text
.globl parser_streq
.def parser_streq; .scl 2; .type 32; .endef
parser_streq:
    test rcx, rcx
    je .peq_no
    test rdx, rdx
    je .peq_no
.peq_loop:
    mov r8b, [rcx]
    cmp r8b, [rdx]
    jne .peq_no
    test r8b, r8b
    je .peq_yes
    inc rcx
    inc rdx
    jmp .peq_loop
.peq_yes:
    mov eax, 1
    ret
.peq_no:
    xor eax, eax
    ret

.globl parser_init
.def parser_init; .scl 2; .type 32; .endef
parser_init:
    test rcx, rcx
    je .pinit_done
    mov [rcx+PS_TOKENS], rdx
    mov [rcx+PS_COUNT], r8
    mov qword ptr [rcx+PS_CURRENT], 0
    mov qword ptr [rcx+PS_ERRORS], 0
    mov qword ptr [rcx+PS_IMPORTS], 0
    mov qword ptr [rcx+PS_CLASSES], 0
    mov qword ptr [rcx+PS_METHODS], 0
    mov qword ptr [rcx+PS_STATEMENTS], 0
    mov qword ptr [rcx+PS_EXPRESSIONS], 0
    mov qword ptr [rcx+PS_LAST_TYPE], 0
    mov qword ptr [rcx+PS_LAST_FLAGS], 0
.pinit_done:
    ret

.globl parser_error_count
.def parser_error_count; .scl 2; .type 32; .endef
parser_error_count:
    xor rax, rax
    test rcx, rcx
    je .pec_done
    mov rax, [rcx+PS_ERRORS]
.pec_done:
    ret

.globl parser_has_error
.def parser_has_error; .scl 2; .type 32; .endef
parser_has_error:
    xor eax, eax
    test rcx, rcx
    je .phe_done
    cmp qword ptr [rcx+PS_ERRORS], 0
    setne al
.phe_done:
    ret

.globl parser_add_error
.def parser_add_error; .scl 2; .type 32; .endef
parser_add_error:
    test rcx, rcx
    je .pae_done
    inc qword ptr [rcx+PS_ERRORS]
.pae_done:
    ret

.globl parser_token_kind_at
.def parser_token_kind_at; .scl 2; .type 32; .endef
parser_token_kind_at:
    mov eax, EndOfFile
    test rcx, rcx
    je .ptka_done
    cmp rdx, [rcx+PS_COUNT]
    jae .ptka_done
    mov r8, [rcx+PS_TOKENS]
    shl rdx, 4
    add r8, rdx
    mov eax, [r8+TOK_KIND]
.ptka_done:
    ret

.globl parser_token_lexeme_at
.def parser_token_lexeme_at; .scl 2; .type 32; .endef
parser_token_lexeme_at:
    xor rax, rax
    test rcx, rcx
    je .ptla_done
    cmp rdx, [rcx+PS_COUNT]
    jae .ptla_done
    mov r8, [rcx+PS_TOKENS]
    shl rdx, 4
    add r8, rdx
    mov rax, [r8+TOK_LEXEME]
.ptla_done:
    ret

.globl parser_peek_kind
.def parser_peek_kind; .scl 2; .type 32; .endef
parser_peek_kind:
    test rcx, rcx
    je .ppk_eof
    mov rdx, [rcx+PS_CURRENT]
    jmp parser_token_kind_at
.ppk_eof:
    mov eax, EndOfFile
    ret

.globl parser_previous_kind
.def parser_previous_kind; .scl 2; .type 32; .endef
parser_previous_kind:
    test rcx, rcx
    je .pprev_eof
    mov rdx, [rcx+PS_CURRENT]
    test rdx, rdx
    je .pprev_eof
    dec rdx
    jmp parser_token_kind_at
.pprev_eof:
    mov eax, EndOfFile
    ret

.globl parser_is_at_end
.def parser_is_at_end; .scl 2; .type 32; .endef
parser_is_at_end:
    sub rsp, 40
    call parser_peek_kind
    cmp eax, EndOfFile
    sete al
    movzx eax, al
    add rsp, 40
    ret

.globl parser_check
.def parser_check; .scl 2; .type 32; .endef
parser_check:
    push rbx
    sub rsp, 32
    mov ebx, edx
    call parser_peek_kind
    cmp eax, ebx
    sete al
    movzx eax, al
    add rsp, 32
    pop rbx
    ret

.globl parser_advance
.def parser_advance; .scl 2; .type 32; .endef
parser_advance:
    push rbx
    sub rsp, 32
    mov rbx, rcx
    call parser_is_at_end
    test eax, eax
    jne .padv_kind
    inc qword ptr [rbx+PS_CURRENT]
.padv_kind:
    mov rcx, rbx
    call parser_previous_kind
    add rsp, 32
    pop rbx
    ret

.globl parser_match
.def parser_match; .scl 2; .type 32; .endef
parser_match:
    push rbx
    push rsi
    sub rsp, 40
    mov rbx, rcx
    mov esi, edx
    call parser_check
    test eax, eax
    je .pm_no
    mov rcx, rbx
    call parser_advance
    mov eax, 1
    jmp .pm_done
.pm_no:
    xor eax, eax
.pm_done:
    add rsp, 40
    pop rsi
    pop rbx
    ret

.globl parser_consume
.def parser_consume; .scl 2; .type 32; .endef
parser_consume:
    push rbx
    push rsi
    sub rsp, 40
    mov rbx, rcx
    mov esi, edx
    call parser_match
    test eax, eax
    jne .pc_ok
    mov rcx, rbx
    call parser_add_error
    xor eax, eax
    jmp .pc_done
.pc_ok:
    mov eax, 1
.pc_done:
    add rsp, 40
    pop rsi
    pop rbx
    ret

.globl parser_is_type_kind
.def parser_is_type_kind; .scl 2; .type 32; .endef
parser_is_type_kind:
    cmp ecx, KeywordInteger
    je .pit_yes
    cmp ecx, KeywordFileInteger
    je .pit_yes
    cmp ecx, KeywordString
    je .pit_yes
    cmp ecx, KeywordFileString
    je .pit_yes
    cmp ecx, KeywordLong
    je .pit_yes
    cmp ecx, KeywordFileLong
    je .pit_yes
    cmp ecx, KeywordDouble
    je .pit_yes
    cmp ecx, KeywordFileDouble
    je .pit_yes
    cmp ecx, KeywordBoolean
    je .pit_yes
    cmp ecx, KeywordFileBoolean
    je .pit_yes
    cmp ecx, KeywordArray
    je .pit_yes
    cmp ecx, KeywordMap
    je .pit_yes
    cmp ecx, KeywordThread
    je .pit_yes
    xor eax, eax
    ret
.pit_yes:
    mov eax, 1
    ret

.globl parser_is_file_type_kind
.def parser_is_file_type_kind; .scl 2; .type 32; .endef
parser_is_file_type_kind:
    cmp ecx, KeywordFileInteger
    je .pift_yes
    cmp ecx, KeywordFileString
    je .pift_yes
    cmp ecx, KeywordFileLong
    je .pift_yes
    cmp ecx, KeywordFileDouble
    je .pift_yes
    cmp ecx, KeywordFileBoolean
    je .pift_yes
    xor eax, eax
    ret
.pift_yes:
    mov eax, 1
    ret

.globl parser_is_statement_boundary
.def parser_is_statement_boundary; .scl 2; .type 32; .endef
parser_is_statement_boundary:
    cmp ecx, KeywordIf
    je .pisb_yes
    cmp ecx, KeywordWhile
    je .pisb_yes
    cmp ecx, KeywordFor
    je .pisb_yes
    cmp ecx, KeywordSwitch
    je .pisb_yes
    cmp ecx, KeywordPrint
    je .pisb_yes
    cmp ecx, KeywordPrintln
    je .pisb_yes
    cmp ecx, LeftParen
    je .pisb_yes
    cmp ecx, Identifier
    je .pisb_yes
    jmp parser_is_type_kind
.pisb_yes:
    mov eax, 1
    ret

.globl parser_looks_like_method_decl
.def parser_looks_like_method_decl; .scl 2; .type 32; .endef
parser_looks_like_method_decl:
    push rbx
    push rsi
    sub rsp, 40
    mov rbx, rcx
    mov rsi, [rbx+PS_CURRENT]
    mov rcx, rbx
    mov rdx, rsi
    call parser_token_kind_at
    cmp eax, KeywordPrivate
    jne .plmd_check
    inc rsi
.plmd_check:
    mov rcx, rbx
    mov rdx, rsi
    call parser_token_kind_at
    cmp eax, Identifier
    jne .plmd_no
    inc rsi
    mov rcx, rbx
    mov rdx, rsi
    call parser_token_kind_at
    cmp eax, LeftBrace
    jne .plmd_no
    mov eax, 1
    jmp .plmd_done
.plmd_no:
    xor eax, eax
.plmd_done:
    add rsp, 40
    pop rsi
    pop rbx
    ret

.globl parser_looks_like_lambda
.def parser_looks_like_lambda; .scl 2; .type 32; .endef
parser_looks_like_lambda:
    push rbx
    push rsi
    push rdi
    sub rsp, 32
    mov rbx, rcx
    call parser_peek_kind
    cmp eax, LeftParen
    jne .pll_no
    mov rsi, [rbx+PS_CURRENT]
    inc rsi
    mov edi, 1
.pll_loop:
    mov rcx, rbx
    mov rdx, rsi
    call parser_token_kind_at
    cmp eax, EndOfFile
    je .pll_no
    cmp eax, LeftParen
    jne .pll_rp
    inc edi
    jmp .pll_next
.pll_rp:
    cmp eax, RightParen
    jne .pll_next
    dec edi
    cmp edi, 0
    jne .pll_next
    inc rsi
    mov rcx, rbx
    mov rdx, rsi
    call parser_token_kind_at
    cmp eax, FatArrow
    sete al
    movzx eax, al
    jmp .pll_done
.pll_next:
    inc rsi
    jmp .pll_loop
.pll_no:
    xor eax, eax
.pll_done:
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret

.globl parser_is_method_return_start
.def parser_is_method_return_start; .scl 2; .type 32; .endef
parser_is_method_return_start:
    push rbx
    push rsi
    push rdi
    sub rsp, 32
    mov rbx, rcx
    call parser_peek_kind
    cmp eax, LeftBracket
    jne .pmrs_no
    mov rsi, [rbx+PS_CURRENT]
    inc rsi
    mov edi, 1
.pmrs_loop:
    mov rcx, rbx
    mov rdx, rsi
    call parser_token_kind_at
    cmp eax, EndOfFile
    je .pmrs_no
    cmp eax, LeftBracket
    jne .pmrs_rb
    inc edi
    jmp .pmrs_next
.pmrs_rb:
    cmp eax, RightBracket
    jne .pmrs_next
    dec edi
    cmp edi, 0
    jne .pmrs_next
    inc rsi
    mov rcx, rbx
    mov rdx, rsi
    call parser_token_kind_at
    cmp eax, ArrowMethodEnd
    sete al
    movzx eax, al
    jmp .pmrs_done
.pmrs_next:
    inc rsi
    jmp .pmrs_loop
.pmrs_no:
    xor eax, eax
.pmrs_done:
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret

.globl parser_looks_like_switch_block
.def parser_looks_like_switch_block; .scl 2; .type 32; .endef
parser_looks_like_switch_block:
    push rbx
    push rsi
    sub rsp, 40
    mov rbx, rcx
    mov rsi, [rbx+PS_CURRENT]
.plsb_loop:
    mov rcx, rbx
    mov rdx, rsi
    call parser_token_kind_at
    cmp eax, EndOfFile
    je .plsb_no
    cmp eax, Greater
    je .plsb_no
    cmp eax, IntegerLiteral
    je .plsb_label
    cmp eax, Identifier
    je .plsb_label
    cmp eax, StringLiteral
    je .plsb_label
    cmp eax, KeywordTrue
    je .plsb_label
    cmp eax, KeywordFalse
    je .plsb_label
    inc rsi
    jmp .plsb_loop
.plsb_label:
    inc rsi
    mov rcx, rbx
    mov rdx, rsi
    call parser_token_kind_at
    cmp eax, LeftBracket
    sete al
    movzx eax, al
    jmp .plsb_done
.plsb_no:
    xor eax, eax
.plsb_done:
    add rsp, 40
    pop rsi
    pop rbx
    ret

.globl parser_parse_type
.def parser_parse_type; .scl 2; .type 32; .endef
parser_parse_type:
    push rbx
    push rsi
    sub rsp, 40
    mov rbx, rcx
    call parser_peek_kind
    mov esi, eax
    mov qword ptr [rbx+PS_LAST_FLAGS], 0
    mov rcx, rsi
    call parser_is_type_kind
    test eax, eax
    jne .ppt_valid
    cmp esi, Identifier
    je .ppt_valid
    mov rcx, rbx
    call parser_add_error
    mov eax, 0
    jmp .ppt_done
.ppt_valid:
    mov qword ptr [rbx+PS_LAST_FLAGS], 1
    mov rcx, rsi
    call parser_is_file_type_kind
    test eax, eax
    je .ppt_name
    or qword ptr [rbx+PS_LAST_FLAGS], 4
.ppt_name:
    mov rcx, rbx
    mov rdx, [rbx+PS_CURRENT]
    call parser_token_lexeme_at
    mov [rbx+PS_LAST_TYPE], rax
    mov rcx, rbx
    call parser_advance
    mov rcx, rbx
    mov edx, LeftBracket
    call parser_match
    test eax, eax
    je .ppt_return
    or qword ptr [rbx+PS_LAST_FLAGS], 2
    mov rcx, rbx
    mov edx, RightBracket
    call parser_consume
.ppt_return:
    mov rax, [rbx+PS_LAST_FLAGS]
.ppt_done:
    add rsp, 40
    pop rsi
    pop rbx
    ret

.globl parser_parse_expression
.def parser_parse_expression; .scl 2; .type 32; .endef
parser_parse_expression:
    push rbx
    sub rsp, 32
    mov rbx, rcx
    call parser_peek_kind
    cmp eax, EndOfFile
    je .pexpr_bad
    cmp eax, Semicolon
    je .pexpr_bad
    cmp eax, RightParen
    je .pexpr_bad
    cmp eax, RightBrace
    je .pexpr_bad
    cmp eax, RightBracket
    je .pexpr_bad
    cmp eax, Greater
    je .pexpr_bad
    inc qword ptr [rbx+PS_EXPRESSIONS]
.pexpr_loop:
    mov rcx, rbx
    call parser_peek_kind
    cmp eax, EndOfFile
    je .pexpr_ok
    cmp eax, Semicolon
    je .pexpr_ok
    cmp eax, Comma
    je .pexpr_ok
    cmp eax, RightParen
    je .pexpr_ok
    cmp eax, RightBrace
    je .pexpr_ok
    cmp eax, RightBracket
    je .pexpr_ok
    cmp eax, Greater
    je .pexpr_ok
    mov rcx, rbx
    call parser_advance
    jmp .pexpr_loop
.pexpr_bad:
    mov rcx, rbx
    call parser_add_error
    xor eax, eax
    jmp .pexpr_done
.pexpr_ok:
    mov eax, 1
.pexpr_done:
    add rsp, 32
    pop rbx
    ret

.globl parser_skip_until
.def parser_skip_until; .scl 2; .type 32; .endef
parser_skip_until:
    push rbx
    push rsi
    sub rsp, 40
    mov rbx, rcx
    mov esi, edx
.psu_loop:
    mov rcx, rbx
    call parser_peek_kind
    cmp eax, EndOfFile
    je .psu_done
    cmp eax, esi
    je .psu_done
    mov rcx, rbx
    call parser_advance
    jmp .psu_loop
.psu_done:
    add rsp, 40
    pop rsi
    pop rbx
    ret

.globl parser_parse_statement
.def parser_parse_statement; .scl 2; .type 32; .endef
parser_parse_statement:
    push rbx
    push rsi
    sub rsp, 40
    mov rbx, rcx
    call parser_peek_kind
    mov esi, eax
    cmp esi, EndOfFile
    je .pps_done
    inc qword ptr [rbx+PS_STATEMENTS]
    mov ecx, esi
    call parser_is_type_kind
    test eax, eax
    jne .pps_var
    cmp esi, Identifier
    jne .pps_control
    mov rcx, rbx
    mov rdx, [rbx+PS_CURRENT]
    call parser_token_lexeme_at
    mov rcx, rax
    lea rdx, [rip+s_return]
    call parser_streq
    test eax, eax
    jne .pps_return
.pps_control:
    cmp esi, KeywordPrint
    je .pps_print
    cmp esi, KeywordPrintln
    je .pps_print
    cmp esi, KeywordIf
    je .pps_block
    cmp esi, KeywordWhile
    je .pps_block
    cmp esi, KeywordFor
    je .pps_block
    cmp esi, KeywordSwitch
    je .pps_block
    mov rcx, rbx
    call parser_parse_expression
    mov rcx, rbx
    mov edx, Semicolon
    call parser_match
    jmp .pps_done
.pps_var:
    mov rcx, rbx
    call parser_parse_type
    mov rcx, rbx
    mov edx, Identifier
    call parser_consume
    mov rcx, rbx
    mov edx, Assign
    call parser_match
    test eax, eax
    je .pps_var_end
    mov rcx, rbx
    call parser_parse_expression
.pps_var_end:
    mov rcx, rbx
    mov edx, Semicolon
    call parser_match
    jmp .pps_done
.pps_return:
    mov rcx, rbx
    call parser_advance
    mov rcx, rbx
    call parser_parse_expression
    mov rcx, rbx
    mov edx, Semicolon
    call parser_match
    jmp .pps_done
.pps_print:
    mov rcx, rbx
    call parser_advance
    mov rcx, rbx
    mov edx, LeftParen
    call parser_consume
    mov rcx, rbx
    call parser_parse_expression
    mov rcx, rbx
    mov edx, RightParen
    call parser_consume
    mov rcx, rbx
    mov edx, Semicolon
    call parser_match
    jmp .pps_done
.pps_block:
    mov rcx, rbx
    mov edx, Semicolon
    call parser_skip_until
    mov rcx, rbx
    mov edx, Semicolon
    call parser_match
.pps_done:
    add rsp, 40
    pop rsi
    pop rbx
    ret

.globl parser_parse_method_decl
.def parser_parse_method_decl; .scl 2; .type 32; .endef
parser_parse_method_decl:
    push rbx
    sub rsp, 32
    mov rbx, rcx
    mov rcx, rbx
    mov edx, KeywordPrivate
    call parser_match
    mov rcx, rbx
    mov edx, Identifier
    call parser_consume
    mov rcx, rbx
    mov edx, LeftBrace
    call parser_consume
    mov rcx, rbx
    mov edx, RightBrace
    call parser_consume
    mov rcx, rbx
    mov edx, ArrowMethodStart
    call parser_consume
    inc qword ptr [rbx+PS_METHODS]
.ppmd_body:
    mov rcx, rbx
    call parser_is_method_return_start
    test eax, eax
    jne .ppmd_return
    mov rcx, rbx
    call parser_peek_kind
    cmp eax, ArrowMethodEnd
    je .ppmd_end
    cmp eax, EndOfFile
    je .ppmd_end
    mov rcx, rbx
    call parser_parse_statement
    jmp .ppmd_body
.ppmd_return:
    mov rcx, rbx
    mov edx, ArrowMethodEnd
    call parser_skip_until
.ppmd_end:
    mov rcx, rbx
    mov edx, ArrowMethodEnd
    call parser_consume
    add rsp, 32
    pop rbx
    ret

.globl parser_parse_class_decl
.def parser_parse_class_decl; .scl 2; .type 32; .endef
parser_parse_class_decl:
    push rbx
    sub rsp, 32
    mov rbx, rcx
    mov rcx, rbx
    mov edx, Identifier
    call parser_consume
.ppcd_parent_loop:
    mov rcx, rbx
    mov edx, Colon
    call parser_match
    test eax, eax
    jne .ppcd_parent
    mov rcx, rbx
    mov edx, DoubleColon
    call parser_match
    test eax, eax
    je .ppcd_arrow
.ppcd_parent:
    mov rcx, rbx
    call parser_advance
    jmp .ppcd_parent_loop
.ppcd_arrow:
    mov rcx, rbx
    mov edx, ArrowClassStart
    call parser_consume
    inc qword ptr [rbx+PS_CLASSES]
.ppcd_body:
    mov rcx, rbx
    call parser_peek_kind
    cmp eax, ArrowClassEnd
    je .ppcd_end
    cmp eax, EndOfFile
    je .ppcd_end
    mov rcx, rbx
    call parser_looks_like_method_decl
    test eax, eax
    je .ppcd_stmt
    mov rcx, rbx
    call parser_parse_method_decl
    jmp .ppcd_body
.ppcd_stmt:
    mov rcx, rbx
    call parser_parse_statement
    jmp .ppcd_body
.ppcd_end:
    mov rcx, rbx
    mov edx, ArrowClassEnd
    call parser_consume
    add rsp, 32
    pop rbx
    ret

.globl parser_parse_import_decl
.def parser_parse_import_decl; .scl 2; .type 32; .endef
parser_parse_import_decl:
    push rbx
    sub rsp, 32
    mov rbx, rcx
    mov rcx, rbx
    call parser_advance
    mov rcx, rbx
    mov edx, DoubleColon
    call parser_match
    test eax, eax
    jne .ppid_path
    mov rcx, rbx
    mov edx, Colon
    call parser_consume
.ppid_path:
    mov rcx, rbx
    mov edx, Identifier
    call parser_consume
.ppid_dot:
    mov rcx, rbx
    mov edx, Dot
    call parser_match
    test eax, eax
    je .ppid_end
    mov rcx, rbx
    mov edx, Identifier
    call parser_consume
    jmp .ppid_dot
.ppid_end:
    mov rcx, rbx
    mov edx, Semicolon
    call parser_match
    inc qword ptr [rbx+PS_IMPORTS]
    add rsp, 32
    pop rbx
    ret

.globl parser_parse_program
.def parser_parse_program; .scl 2; .type 32; .endef
parser_parse_program:
    push rbx
    sub rsp, 32
    mov rbx, rcx
.pp_imports:
    mov rcx, rbx
    call parser_peek_kind
    cmp eax, KeywordFrom
    je .pp_import
    cmp eax, Identifier
    jne .pp_classes
    mov rcx, rbx
    mov rdx, [rbx+PS_CURRENT]
    call parser_token_lexeme_at
    mov rcx, rax
    lea rdx, [rip+s_from]
    call parser_streq
    test eax, eax
    je .pp_classes
.pp_import:
    mov rcx, rbx
    call parser_parse_import_decl
    jmp .pp_imports
.pp_classes:
    mov rcx, rbx
    call parser_is_at_end
    test eax, eax
    jne .pp_done
    mov rcx, rbx
    call parser_parse_class_decl
    jmp .pp_classes
.pp_done:
    add rsp, 32
    pop rbx
    ret
