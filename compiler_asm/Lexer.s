.intel_syntax noprefix

.equ ST_SOURCE, 0
.equ ST_LENGTH, 8
.equ ST_POS, 16
.equ ST_LINE, 24
.equ ST_COL, 28
.equ ST_ERRORS, 32
.equ ST_ERROR_COUNT, 40
.equ ST_ERROR_CAP, 48
.equ ST_TOKENS, 56
.equ ST_TOKEN_COUNT, 64
.equ ST_TOKEN_CAP, 72

.equ TOK_KIND, 0
.equ TOK_LEXEME, 4
.equ TOK_START_LINE, 68
.equ TOK_START_COL, 72
.equ TOK_END_LINE, 76
.equ TOK_END_COL, 80
.equ TOK_SIZE, 84

.equ ERR_MSG, 0
.equ ERR_LINE, 96
.equ ERR_COL, 100
.equ ERR_SIZE, 104

.equ TK_EOF, 0
.equ TK_INVALID, 1
.equ TK_IDENTIFIER, 2
.equ TK_INT, 3
.equ TK_LONG, 4
.equ TK_DOUBLE, 5
.equ TK_STRING, 6
.equ TK_KW_CLASS, 7
.equ TK_KW_INHERITANCE, 8
.equ TK_KW_METHODCALL, 9
.equ TK_KW_IF, 10
.equ TK_KW_ELSE, 11
.equ TK_KW_WHILE, 12
.equ TK_KW_SWITCH, 13
.equ TK_KW_FOR, 14
.equ TK_KW_CASE, 15
.equ TK_KW_DEFAULT, 16
.equ TK_KW_PRINT, 17
.equ TK_KW_PRINTLN, 18
.equ TK_KW_INTEGER, 19
.equ TK_KW_FILEINTEGER, 20
.equ TK_KW_STRING, 21
.equ TK_KW_FILESTRING, 22
.equ TK_KW_LONG, 23
.equ TK_KW_FILELONG, 24
.equ TK_KW_DOUBLE, 25
.equ TK_KW_FILEDOUBLE, 26
.equ TK_KW_BOOLEAN, 27
.equ TK_KW_FILEBOOLEAN, 28
.equ TK_KW_ARRAY, 29
.equ TK_KW_MAP, 30
.equ TK_KW_THREAD, 31
.equ TK_KW_FROM, 32
.equ TK_KW_TRUE, 33
.equ TK_KW_FALSE, 34
.equ TK_KW_PRIVATE, 35
.equ TK_ARROW_CLASS_START, 36
.equ TK_ARROW_CLASS_END, 37
.equ TK_ARROW_METHOD_START, 38
.equ TK_ARROW_METHOD_END, 39
.equ TK_FAT_ARROW, 40
.equ TK_PLUS, 41
.equ TK_PLUSPLUS, 42
.equ TK_MINUS, 43
.equ TK_MINUSMINUS, 44
.equ TK_STAR, 45
.equ TK_SLASH, 46
.equ TK_PERCENT, 47
.equ TK_ASSIGN, 48
.equ TK_EQUAL_EQUAL, 49
.equ TK_BANG, 50
.equ TK_BANG_EQUAL, 51
.equ TK_LESS, 52
.equ TK_LESS_EQUAL, 53
.equ TK_GREATER, 54
.equ TK_GREATER_EQUAL, 55
.equ TK_AND_AND, 56
.equ TK_OR_OR, 57
.equ TK_QUESTION, 58
.equ TK_COMMA, 59
.equ TK_COLON, 60
.equ TK_SEMICOLON, 61
.equ TK_DOT, 62
.equ TK_DOUBLE_COLON, 63
.equ TK_LPAREN, 64
.equ TK_RPAREN, 65
.equ TK_LBRACE, 66
.equ TK_RBRACE, 67
.equ TK_LBRACKET, 68
.equ TK_RBRACKET, 69
.equ TK_LEFT_ANGLE, 70
.equ TK_RIGHT_ANGLE, 71

.section .rdata
s_unexpected_amp: .asciz "unexpected character '&'"
s_unexpected_pipe: .asciz "unexpected character '|'"
s_unexpected_char: .asciz "unexpected character"
s_unterminated_comment: .asciz "unterminated block comment"
s_unterminated_string: .asciz "unterminated string literal"
s_invalid_escape: .asciz "invalid escape sequence"

kw_class: .asciz "class"
kw_inheritence: .asciz "inheritence"
kw_methodcall: .asciz "methodcall"
kw_if: .asciz "if"
kw_else: .asciz "else"
kw_while: .asciz "while"
kw_switch: .asciz "switch"
kw_for: .asciz "for"
kw_case: .asciz "case"
kw_default: .asciz "default"
kw_print: .asciz "print"
kw_println: .asciz "println"
kw_Integer: .asciz "Integer"
kw_FileInteger: .asciz "FileInteger"
kw_String: .asciz "String"
kw_FileString: .asciz "FileString"
kw_Long: .asciz "Long"
kw_FileLong: .asciz "FileLong"
kw_Double: .asciz "Double"
kw_FileDouble: .asciz "FileDouble"
kw_Boolean: .asciz "Boolean"
kw_FileBoolean: .asciz "FileBoolean"
kw_Array: .asciz "Array"
kw_Map: .asciz "Map"
kw_Thread: .asciz "Thread"
kw_from: .asciz "from"
kw_true: .asciz "true"
kw_false: .asciz "false"
kw_private: .asciz "private"

name_table:
    .quad n_eof,n_invalid,n_identifier,n_int,n_long,n_double,n_string
    .quad n_kw_class,n_kw_inheritance,n_kw_methodcall,n_kw_if,n_kw_else,n_kw_while,n_kw_switch,n_kw_for,n_kw_case,n_kw_default,n_kw_print,n_kw_println
    .quad n_kw_integer,n_kw_fileinteger,n_kw_kwstring,n_kw_filestring,n_kw_long,n_kw_filelong,n_kw_double,n_kw_filedouble,n_kw_boolean,n_kw_fileboolean,n_kw_array,n_kw_map,n_kw_thread,n_kw_from,n_kw_true,n_kw_false,n_kw_private
    .quad n_arrow_class_start,n_arrow_class_end,n_arrow_method_start,n_arrow_method_end,n_fat_arrow,n_plus,n_plusplus,n_minus,n_minusminus,n_star,n_slash,n_percent,n_assign,n_equal_equal,n_bang,n_bang_equal,n_less,n_less_equal,n_greater,n_greater_equal,n_and_and,n_or_or,n_question,n_comma,n_colon,n_semicolon,n_dot,n_double_colon,n_lparen,n_rparen,n_lbrace,n_rbrace,n_lbracket,n_rbracket,n_left_angle,n_right_angle
n_eof: .asciz "EndOfFile"
n_invalid: .asciz "Invalid"
n_identifier: .asciz "Identifier"
n_int: .asciz "IntegerLiteral"
n_long: .asciz "LongLiteral"
n_double: .asciz "DoubleLiteral"
n_string: .asciz "StringLiteral"
n_kw_class: .asciz "KeywordClass"
n_kw_inheritance: .asciz "KeywordInheritance"
n_kw_methodcall: .asciz "KeywordMethodCall"
n_kw_if: .asciz "KeywordIf"
n_kw_else: .asciz "KeywordElse"
n_kw_while: .asciz "KeywordWhile"
n_kw_switch: .asciz "KeywordSwitch"
n_kw_for: .asciz "KeywordFor"
n_kw_case: .asciz "KeywordCase"
n_kw_default: .asciz "KeywordDefault"
n_kw_print: .asciz "KeywordPrint"
n_kw_println: .asciz "KeywordPrintln"
n_kw_integer: .asciz "KeywordInteger"
n_kw_fileinteger: .asciz "KeywordFileInteger"
n_kw_kwstring: .asciz "KeywordString"
n_kw_filestring: .asciz "KeywordFileString"
n_kw_long: .asciz "KeywordLong"
n_kw_filelong: .asciz "KeywordFileLong"
n_kw_double: .asciz "KeywordDouble"
n_kw_filedouble: .asciz "KeywordFileDouble"
n_kw_boolean: .asciz "KeywordBoolean"
n_kw_fileboolean: .asciz "KeywordFileBoolean"
n_kw_array: .asciz "KeywordArray"
n_kw_map: .asciz "KeywordMap"
n_kw_thread: .asciz "KeywordThread"
n_kw_from: .asciz "KeywordFrom"
n_kw_true: .asciz "KeywordTrue"
n_kw_false: .asciz "KeywordFalse"
n_kw_private: .asciz "KeywordPrivate"
n_arrow_class_start: .asciz "ArrowClassStart"
n_arrow_class_end: .asciz "ArrowClassEnd"
n_arrow_method_start: .asciz "ArrowMethodStart"
n_arrow_method_end: .asciz "ArrowMethodEnd"
n_fat_arrow: .asciz "FatArrow"
n_plus: .asciz "Plus"
n_plusplus: .asciz "PlusPlus"
n_minus: .asciz "Minus"
n_minusminus: .asciz "MinusMinus"
n_star: .asciz "Star"
n_slash: .asciz "Slash"
n_percent: .asciz "Percent"
n_assign: .asciz "Assign"
n_equal_equal: .asciz "EqualEqual"
n_bang: .asciz "Bang"
n_bang_equal: .asciz "BangEqual"
n_less: .asciz "Less"
n_less_equal: .asciz "LessEqual"
n_greater: .asciz "Greater"
n_greater_equal: .asciz "GreaterEqual"
n_and_and: .asciz "AndAnd"
n_or_or: .asciz "OrOr"
n_question: .asciz "Question"
n_comma: .asciz "Comma"
n_colon: .asciz "Colon"
n_semicolon: .asciz "Semicolon"
n_dot: .asciz "Dot"
n_double_colon: .asciz "DoubleColon"
n_lparen: .asciz "LeftParen"
n_rparen: .asciz "RightParen"
n_lbrace: .asciz "LeftBrace"
n_rbrace: .asciz "RightBrace"
n_lbracket: .asciz "LeftBracket"
n_rbracket: .asciz "RightBracket"
n_left_angle: .asciz "LeftAngle"
n_right_angle: .asciz "RightAngle"
n_unknown: .asciz "Unknown"

.text
.globl lexer_strlen
.def lexer_strlen; .scl 2; .type 32; .endef
lexer_strlen:
    xor rax, rax
    test rcx, rcx
    je .strlen_done
.strlen_loop:
    cmp byte ptr [rcx + rax], 0
    je .strlen_done
    inc rax
    jmp .strlen_loop
.strlen_done:
    ret

.globl lexer_streq_range
.def lexer_streq_range; .scl 2; .type 32; .endef
lexer_streq_range:
    push rbx
    push rsi
    push rdi
    sub rsp, 40
    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8
    mov rcx, rsi
    call lexer_strlen
    cmp rax, rdi
    jne .range_no
.range_loop:
    test rdi, rdi
    je .range_yes
    mov al, [rbx]
    cmp al, [rsi]
    jne .range_no
    inc rbx
    inc rsi
    dec rdi
    jmp .range_loop
.range_yes:
    mov eax, 1
    jmp .range_done
.range_no:
    xor eax, eax
.range_done:
    add rsp, 40
    pop rdi
    pop rsi
    pop rbx
    ret

.globl lexer_copy_range
.def lexer_copy_range; .scl 2; .type 32; .endef
lexer_copy_range:
    mov r10, [rsp + 40]
    xor eax, eax
    test rcx, rcx
    je .copy_done
    test r10, r10
    je .copy_done
.copy_loop:
    cmp r10, 1
    jbe .copy_term
    test r8, r8
    je .copy_term
    mov al, [rdx]
    mov [rcx], al
    inc rcx
    inc rdx
    dec r8
    dec r10
    jmp .copy_loop
.copy_term:
    mov byte ptr [rcx], 0
    mov eax, 1
.copy_done:
    ret

.globl lexer_copy_cstr
.def lexer_copy_cstr; .scl 2; .type 32; .endef
lexer_copy_cstr:
    push rbx
    push rsi
    push rdi
    sub rsp, 40
    mov rdi, rcx
    mov rbx, rdx
    mov rsi, r9
    mov rcx, rdx
    call lexer_strlen
    mov r8, rax
    mov rdx, rbx
    mov rcx, rdi
    mov [rsp + 32], rsi
    call lexer_copy_range
    add rsp, 40
    pop rdi
    pop rsi
    pop rbx
    ret

.globl lexer_init
.def lexer_init; .scl 2; .type 32; .endef
lexer_init:
    test rcx, rcx
    je .init_done
    mov [rcx + ST_SOURCE], rdx
    mov [rcx + ST_LENGTH], r8
    mov [rcx + ST_TOKENS], r9
    mov rax, [rsp + 40]
    mov [rcx + ST_TOKEN_CAP], rax
    mov rax, [rsp + 48]
    mov [rcx + ST_ERRORS], rax
    mov rax, [rsp + 56]
    mov [rcx + ST_ERROR_CAP], rax
    mov qword ptr [rcx + ST_POS], 0
    mov qword ptr [rcx + ST_TOKEN_COUNT], 0
    mov qword ptr [rcx + ST_ERROR_COUNT], 0
    mov dword ptr [rcx + ST_LINE], 1
    mov dword ptr [rcx + ST_COL], 1
.init_done:
    ret

.globl lexer_is_at_end
.def lexer_is_at_end; .scl 2; .type 32; .endef
lexer_is_at_end:
    xor eax, eax
    test rcx, rcx
    je .at_end_yes
    mov rdx, [rcx + ST_POS]
    cmp rdx, [rcx + ST_LENGTH]
    jae .at_end_yes
    ret
.at_end_yes:
    mov eax, 1
    ret

.globl lexer_peek
.def lexer_peek; .scl 2; .type 32; .endef
lexer_peek:
    xor eax, eax
    test rcx, rcx
    je .peek_done
    mov rdx, [rcx + ST_POS]
    cmp rdx, [rcx + ST_LENGTH]
    jae .peek_done
    mov r8, [rcx + ST_SOURCE]
    movzx eax, byte ptr [r8 + rdx]
.peek_done:
    ret

.globl lexer_peek_next
.def lexer_peek_next; .scl 2; .type 32; .endef
lexer_peek_next:
    xor eax, eax
    test rcx, rcx
    je .peekn_done
    mov rdx, [rcx + ST_POS]
    inc rdx
    cmp rdx, [rcx + ST_LENGTH]
    jae .peekn_done
    mov r8, [rcx + ST_SOURCE]
    movzx eax, byte ptr [r8 + rdx]
.peekn_done:
    ret

.globl lexer_advance
.def lexer_advance; .scl 2; .type 32; .endef
lexer_advance:
    xor eax, eax
    test rcx, rcx
    je .adv_done
    mov rdx, [rcx + ST_POS]
    cmp rdx, [rcx + ST_LENGTH]
    jae .adv_done
    mov r8, [rcx + ST_SOURCE]
    movzx eax, byte ptr [r8 + rdx]
    inc qword ptr [rcx + ST_POS]
    cmp al, 10
    jne .adv_col
    inc dword ptr [rcx + ST_LINE]
    mov dword ptr [rcx + ST_COL], 1
    ret
.adv_col:
    inc dword ptr [rcx + ST_COL]
.adv_done:
    ret

.globl lexer_match
.def lexer_match; .scl 2; .type 32; .endef
lexer_match:
    push rbx
    push r12
    sub rsp, 32
    mov rbx, rcx
    mov r12b, dl
    call lexer_peek
    cmp al, r12b
    jne .match_no
    mov rcx, rbx
    call lexer_advance
    mov eax, 1
    jmp .match_done
.match_no:
    xor eax, eax
.match_done:
    add rsp, 32
    pop r12
    pop rbx
    ret

.globl lexer_next_token
.def lexer_next_token; .scl 2; .type 32; .endef
lexer_next_token:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    sub rsp, 64
    mov rbx, rcx
    mov r13, rdx
    test rbx, rbx
    je .next_done
    mov rcx, rbx
    call lexer_skip_whitespace_and_comments
    mov rsi, [rbx + ST_POS]
    mov r12d, [rbx + ST_LINE]
    mov edi, [rbx + ST_COL]
    mov rcx, rbx
    call lexer_is_at_end
    test eax, eax
    jne .next_eof
    mov rcx, rbx
    call lexer_advance
    movzx r10d, al
    mov cl, al
    call lexer_is_identifier_start
    test eax, eax
    jne .next_identifier
    mov eax, r10d
    cmp al, '0'
    jb .next_switch
    cmp al, '9'
    jbe .next_number
.next_switch:
    mov edx, TK_INVALID
    cmp r10b, '"'
    je .next_string
    cmp r10b, '+'
    je .tok_plus
    cmp r10b, '-'
    je .tok_minus
    cmp r10b, '*'
    je .tok_star
    cmp r10b, '/'
    je .tok_slash
    cmp r10b, '%'
    je .tok_percent
    cmp r10b, '='
    je .tok_equal
    cmp r10b, '!'
    je .tok_bang
    cmp r10b, '<'
    je .tok_less
    cmp r10b, '>'
    je .tok_greater
    cmp r10b, '&'
    je .tok_amp
    cmp r10b, '|'
    je .tok_pipe
    cmp r10b, '?'
    je .tok_question
    cmp r10b, '('
    je .tok_lparen
    cmp r10b, ')'
    je .tok_rparen
    cmp r10b, '{'
    je .tok_lbrace
    cmp r10b, '}'
    je .tok_rbrace
    cmp r10b, '['
    je .tok_lbracket
    cmp r10b, ']'
    je .tok_rbracket
    cmp r10b, ','
    je .tok_comma
    cmp r10b, ':'
    je .tok_colon
    cmp r10b, ';'
    je .tok_semicolon
    cmp r10b, '.'
    je .tok_dot
    jmp .next_invalid_unexpected
.next_identifier:
    mov rcx, rbx
    mov rdx, r13
    call lexer_scan_identifier_or_keyword
    jmp .next_done
.next_number:
    mov rcx, rbx
    mov rdx, r13
    call lexer_scan_number
    jmp .next_done
.next_string:
    mov rcx, rbx
    mov rdx, r13
    call lexer_scan_string
    jmp .next_done
.tok_plus:
    mov rcx, rbx
    mov dl, '+'
    call lexer_match
    mov edx, TK_PLUS
    test eax, eax
    cmovne edx, dword ptr [rip + const_plusplus]
    jmp .next_make
.tok_minus:
    mov rcx, rbx
    mov dl, '-'
    call lexer_match
    test eax, eax
    jne .tok_minus_second
    mov rcx, rbx
    mov dl, '>'
    call lexer_match
    mov edx, TK_MINUS
    test eax, eax
    cmovne edx, dword ptr [rip + const_arrow_class_start]
    jmp .next_make
.tok_minus_second:
    mov rcx, rbx
    mov dl, '>'
    call lexer_match
    mov edx, TK_MINUSMINUS
    test eax, eax
    cmovne edx, dword ptr [rip + const_arrow_method_start]
    jmp .next_make
.tok_star: mov edx, TK_STAR; jmp .next_make
.tok_slash: mov edx, TK_SLASH; jmp .next_make
.tok_percent: mov edx, TK_PERCENT; jmp .next_make
.tok_equal:
    mov rcx, rbx
    mov dl, '>'
    call lexer_match
    test eax, eax
    jne .eq_fat
    mov rcx, rbx
    mov dl, '='
    call lexer_match
    mov edx, TK_ASSIGN
    test eax, eax
    cmovne edx, dword ptr [rip + const_equal_equal]
    jmp .next_make
.eq_fat: mov edx, TK_FAT_ARROW; jmp .next_make
.tok_bang:
    mov rcx, rbx
    mov dl, '='
    call lexer_match
    mov edx, TK_BANG
    test eax, eax
    cmovne edx, dword ptr [rip + const_bang_equal]
    jmp .next_make
.tok_less:
    mov rcx, rbx
    mov dl, '-'
    call lexer_match
    test eax, eax
    jne .less_arrow
    mov rcx, rbx
    mov dl, '='
    call lexer_match
    mov edx, TK_LESS
    test eax, eax
    cmovne edx, dword ptr [rip + const_less_equal]
    jmp .next_make
.less_arrow:
    mov rcx, rbx
    mov dl, '-'
    call lexer_match
    mov edx, TK_ARROW_CLASS_END
    test eax, eax
    cmovne edx, dword ptr [rip + const_arrow_method_end]
    jmp .next_make
.tok_greater:
    mov rcx, rbx
    mov dl, '='
    call lexer_match
    mov edx, TK_GREATER
    test eax, eax
    cmovne edx, dword ptr [rip + const_greater_equal]
    jmp .next_make
.tok_amp:
    mov rcx, rbx
    mov dl, '&'
    call lexer_match
    test eax, eax
    jne .amp_ok
    lea r9, [rip + s_unexpected_amp]
    jmp .next_invalid
.amp_ok: mov edx, TK_AND_AND; jmp .next_make
.tok_pipe:
    mov rcx, rbx
    mov dl, '|'
    call lexer_match
    test eax, eax
    jne .pipe_ok
    lea r9, [rip + s_unexpected_pipe]
    jmp .next_invalid
.pipe_ok: mov edx, TK_OR_OR; jmp .next_make
.tok_question: mov edx, TK_QUESTION; jmp .next_make
.tok_lparen: mov edx, TK_LPAREN; jmp .next_make
.tok_rparen: mov edx, TK_RPAREN; jmp .next_make
.tok_lbrace: mov edx, TK_LBRACE; jmp .next_make
.tok_rbrace: mov edx, TK_RBRACE; jmp .next_make
.tok_lbracket: mov edx, TK_LBRACKET; jmp .next_make
.tok_rbracket: mov edx, TK_RBRACKET; jmp .next_make
.tok_comma: mov edx, TK_COMMA; jmp .next_make
.tok_colon:
    mov rcx, rbx
    mov dl, ':'
    call lexer_match
    mov edx, TK_COLON
    test eax, eax
    cmovne edx, dword ptr [rip + const_double_colon]
    jmp .next_make
.tok_semicolon: mov edx, TK_SEMICOLON; jmp .next_make
.tok_dot: mov edx, TK_DOT; jmp .next_make
.next_eof:
    mov edx, TK_EOF
    mov rdi, rsi
    jmp .next_make_at
.next_invalid_unexpected:
    lea r9, [rip + s_unexpected_char]
.next_invalid:
    mov rcx, rbx
    mov rdx, rsi
    mov r8, [rbx + ST_POS]
    mov [rsp + 32], r13
    mov [rsp + 40], r12d
    mov [rsp + 48], edi
    call lexer_make_invalid_token
    jmp .next_done
.next_make:
    mov rdi, [rbx + ST_POS]
.next_make_at:
    mov rcx, rbx
    mov r8, rsi
    mov r9, rdi
    mov [rsp + 32], r13
    mov [rsp + 40], r12d
    mov [rsp + 48], edi
    call lexer_make_token
.next_done:
    add rsp, 64
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

.section .rdata
const_plusplus: .long TK_PLUSPLUS
const_arrow_class_start: .long TK_ARROW_CLASS_START
const_arrow_method_start: .long TK_ARROW_METHOD_START
const_equal_equal: .long TK_EQUAL_EQUAL
const_bang_equal: .long TK_BANG_EQUAL
const_less_equal: .long TK_LESS_EQUAL
const_arrow_method_end: .long TK_ARROW_METHOD_END
const_greater_equal: .long TK_GREATER_EQUAL
const_double_colon: .long TK_DOUBLE_COLON
.text

.globl lexer_tokenize_all
.def lexer_tokenize_all; .scl 2; .type 32; .endef
lexer_tokenize_all:
    push rbx
    push rsi
    sub rsp, 32
    mov rbx, rcx
.tokall_loop:
    test rbx, rbx
    je .tokall_done
    mov rax, [rbx + ST_TOKEN_COUNT]
    cmp rax, [rbx + ST_TOKEN_CAP]
    jae .tokall_done
    mov rcx, rbx
    xor edx, edx
    call lexer_next_token
    mov rax, [rbx + ST_TOKEN_COUNT]
    test rax, rax
    je .tokall_done
    dec rax
    mov rsi, [rbx + ST_TOKENS]
    imul rdx, rax, TOK_SIZE
    add rsi, rdx
    cmp dword ptr [rsi + TOK_KIND], TK_EOF
    jne .tokall_loop
.tokall_done:
    add rsp, 32
    pop rsi
    pop rbx
    ret

.globl lexer_has_error
.def lexer_has_error; .scl 2; .type 32; .endef
lexer_has_error:
    xor eax, eax
    test rcx, rcx
    je .he_done
    cmp qword ptr [rcx + ST_ERROR_COUNT], 0
    setne al
    movzx eax, al
.he_done:
    ret

.globl lexer_error_count
.def lexer_error_count; .scl 2; .type 32; .endef
lexer_error_count:
    xor eax, eax
    test rcx, rcx
    je .ec_done
    mov rax, [rcx + ST_ERROR_COUNT]
.ec_done:
    ret

.globl lexer_token_count
.def lexer_token_count; .scl 2; .type 32; .endef
lexer_token_count:
    xor eax, eax
    test rcx, rcx
    je .tc_done
    mov rax, [rcx + ST_TOKEN_COUNT]
.tc_done:
    ret

.globl lexer_token_kind_name
.def lexer_token_kind_name; .scl 2; .type 32; .endef
lexer_token_kind_name:
    cmp ecx, 0
    jl .name_unknown
    cmp ecx, TK_RIGHT_ANGLE
    jg .name_unknown
    lea rax, [rip + name_table]
    movsxd rcx, ecx
    mov rax, [rax + rcx * 8]
    ret
.name_unknown:
    lea rax, [rip + n_unknown]
    ret

.globl lexer_is_identifier_start
.def lexer_is_identifier_start; .scl 2; .type 32; .endef
lexer_is_identifier_start:
    xor eax, eax
    cmp cl, '_'
    je .id_yes
    cmp cl, 'A'
    jb .id_no
    cmp cl, 'Z'
    jbe .id_yes
    cmp cl, 'a'
    jb .id_no
    cmp cl, 'z'
    jbe .id_yes
.id_no:
    ret
.id_yes:
    mov eax, 1
    ret

.globl lexer_is_identifier_part
.def lexer_is_identifier_part; .scl 2; .type 32; .endef
lexer_is_identifier_part:
    call lexer_is_identifier_start
    test eax, eax
    jne .part_done
    xor eax, eax
    cmp cl, '0'
    jb .part_done
    cmp cl, '9'
    ja .part_done
    mov eax, 1
.part_done:
    ret

.globl lexer_keyword_kind
.def lexer_keyword_kind; .scl 2; .type 32; .endef
lexer_keyword_kind:
    push rbx
    push rsi
    push rdi
    sub rsp, 32
    mov rbx, rcx
    mov rsi, rdx
    mov edi, TK_IDENTIFIER
.macro KW label kind
    mov rcx, rbx
    lea rdx, [rip + \label]
    mov r8, rsi
    call lexer_streq_range
    test eax, eax
    jne .kw_\kind
.endm
    KW kw_class, 7
    KW kw_inheritence, 8
    KW kw_methodcall, 9
    KW kw_if, 10
    KW kw_else, 11
    KW kw_while, 12
    KW kw_switch, 13
    KW kw_for, 14
    KW kw_case, 15
    KW kw_default, 16
    KW kw_print, 17
    KW kw_println, 18
    KW kw_Integer, 19
    KW kw_FileInteger, 20
    KW kw_String, 21
    KW kw_FileString, 22
    KW kw_Long, 23
    KW kw_FileLong, 24
    KW kw_Double, 25
    KW kw_FileDouble, 26
    KW kw_Boolean, 27
    KW kw_FileBoolean, 28
    KW kw_Array, 29
    KW kw_Map, 30
    KW kw_Thread, 31
    KW kw_from, 32
    KW kw_true, 33
    KW kw_false, 34
    KW kw_private, 35
    mov eax, edi
    jmp .kw_done
.kw_7: mov eax, 7; jmp .kw_done
.kw_8: mov eax, 8; jmp .kw_done
.kw_9: mov eax, 9; jmp .kw_done
.kw_10: mov eax, 10; jmp .kw_done
.kw_11: mov eax, 11; jmp .kw_done
.kw_12: mov eax, 12; jmp .kw_done
.kw_13: mov eax, 13; jmp .kw_done
.kw_14: mov eax, 14; jmp .kw_done
.kw_15: mov eax, 15; jmp .kw_done
.kw_16: mov eax, 16; jmp .kw_done
.kw_17: mov eax, 17; jmp .kw_done
.kw_18: mov eax, 18; jmp .kw_done
.kw_19: mov eax, 19; jmp .kw_done
.kw_20: mov eax, 20; jmp .kw_done
.kw_21: mov eax, 21; jmp .kw_done
.kw_22: mov eax, 22; jmp .kw_done
.kw_23: mov eax, 23; jmp .kw_done
.kw_24: mov eax, 24; jmp .kw_done
.kw_25: mov eax, 25; jmp .kw_done
.kw_26: mov eax, 26; jmp .kw_done
.kw_27: mov eax, 27; jmp .kw_done
.kw_28: mov eax, 28; jmp .kw_done
.kw_29: mov eax, 29; jmp .kw_done
.kw_30: mov eax, 30; jmp .kw_done
.kw_31: mov eax, 31; jmp .kw_done
.kw_32: mov eax, 32; jmp .kw_done
.kw_33: mov eax, 33; jmp .kw_done
.kw_34: mov eax, 34; jmp .kw_done
.kw_35: mov eax, 35
.kw_done:
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret

.globl lexer_add_error
.def lexer_add_error; .scl 2; .type 32; .endef
lexer_add_error:
    push rbx
    push rsi
    push rdi
    sub rsp, 32
    mov rbx, rcx
    mov rsi, rdx
    xor eax, eax
    test rbx, rbx
    je .err_done
    mov rax, [rbx + ST_ERROR_COUNT]
    cmp rax, [rbx + ST_ERROR_CAP]
    jae .err_done
    mov rdi, [rbx + ST_ERRORS]
    imul rax, rax, ERR_SIZE
    add rdi, rax
    mov rcx, rdi
    mov rdx, rsi
    mov r9, 96
    call lexer_copy_cstr
    mov eax, [rbx + ST_LINE]
    mov [rdi + ERR_LINE], eax
    mov eax, [rbx + ST_COL]
    mov [rdi + ERR_COL], eax
    inc qword ptr [rbx + ST_ERROR_COUNT]
    mov eax, 1
.err_done:
    add rsp, 32
    pop rdi
    pop rsi
    pop rbx
    ret

.globl lexer_make_token
.def lexer_make_token; .scl 2; .type 32; .endef
lexer_make_token:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    sub rsp, 48
    mov rbx, rcx
    mov r12d, edx
    mov rsi, r8
    mov rdi, r9
    mov r13, [rsp + 128]
    test r13, r13
    jne .mt_have
    test rbx, rbx
    je .mt_done
    mov rax, [rbx + ST_TOKEN_COUNT]
    cmp rax, [rbx + ST_TOKEN_CAP]
    jae .mt_done
    mov r13, [rbx + ST_TOKENS]
    imul rax, rax, TOK_SIZE
    add r13, rax
    inc qword ptr [rbx + ST_TOKEN_COUNT]
.mt_have:
    mov [r13 + TOK_KIND], r12d
    mov eax, [rsp + 136]
    mov [r13 + TOK_START_LINE], eax
    mov eax, [rsp + 144]
    mov [r13 + TOK_START_COL], eax
    test rbx, rbx
    je .mt_no_end
    mov eax, [rbx + ST_LINE]
    mov [r13 + TOK_END_LINE], eax
    mov eax, [rbx + ST_COL]
    mov [r13 + TOK_END_COL], eax
    mov rdx, [rbx + ST_SOURCE]
    add rdx, rsi
    mov r8, rdi
    sub r8, rsi
    lea rcx, [r13 + TOK_LEXEME]
    mov qword ptr [rsp + 32], 64
    call lexer_copy_range
.mt_no_end:
    mov rax, r13
.mt_done:
    add rsp, 48
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

.globl lexer_make_invalid_token
.def lexer_make_invalid_token; .scl 2; .type 32; .endef
lexer_make_invalid_token:
    push rbx
    push rsi
    push rdi
    push r12
    sub rsp, 56
    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8
    mov r12, r9
    mov rcx, rbx
    mov rdx, r12
    call lexer_add_error
    mov rcx, rbx
    mov edx, TK_INVALID
    mov r8, rsi
    mov r9, rdi
    mov rax, [rsp + 128]
    mov [rsp + 32], rax
    mov eax, [rsp + 136]
    mov [rsp + 40], eax
    mov eax, [rsp + 144]
    mov [rsp + 48], eax
    call lexer_make_token
    add rsp, 56
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

.globl lexer_skip_whitespace_and_comments
.def lexer_skip_whitespace_and_comments; .scl 2; .type 32; .endef
lexer_skip_whitespace_and_comments:
    push rbx
    sub rsp, 32
    mov rbx, rcx
.skip_loop:
    mov rcx, rbx
    call lexer_peek
    cmp al, ' '
    je .skip_adv
    cmp al, 9
    je .skip_adv
    cmp al, 13
    je .skip_adv
    cmp al, 10
    je .skip_adv
    cmp al, '/'
    jne .skip_done
    mov rcx, rbx
    call lexer_peek_next
    cmp al, '/'
    je .line_comment
    cmp al, '*'
    je .block_comment
    jmp .skip_done
.skip_adv:
    mov rcx, rbx
    call lexer_advance
    jmp .skip_loop
.line_comment:
    mov rcx, rbx
    call lexer_advance
    mov rcx, rbx
    call lexer_advance
.line_loop:
    mov rcx, rbx
    call lexer_peek
    test al, al
    je .skip_loop
    cmp al, 10
    je .skip_loop
    mov rcx, rbx
    call lexer_advance
    jmp .line_loop
.block_comment:
    mov rcx, rbx
    call lexer_advance
    mov rcx, rbx
    call lexer_advance
.block_loop:
    mov rcx, rbx
    call lexer_peek
    test al, al
    je .block_unterminated
    cmp al, '*'
    jne .block_adv
    mov rcx, rbx
    call lexer_peek_next
    cmp al, '/'
    jne .block_adv
    mov rcx, rbx
    call lexer_advance
    mov rcx, rbx
    call lexer_advance
    jmp .skip_loop
.block_adv:
    mov rcx, rbx
    call lexer_advance
    jmp .block_loop
.block_unterminated:
    mov rcx, rbx
    lea rdx, [rip + s_unterminated_comment]
    call lexer_add_error
    jmp .skip_done
.skip_done:
    add rsp, 32
    pop rbx
    ret

.globl lexer_scan_identifier_or_keyword
.def lexer_scan_identifier_or_keyword; .scl 2; .type 32; .endef
lexer_scan_identifier_or_keyword:
    push rbx
    push rsi
    push rdi
    push r12
    sub rsp, 48
    mov rbx, rcx
    mov r12, rdx
    mov rsi, [rbx + ST_POS]
    dec rsi
.id_loop:
    mov rcx, rbx
    call lexer_peek
    mov cl, al
    call lexer_is_identifier_part
    test eax, eax
    je .id_done_scan
    mov rcx, rbx
    call lexer_advance
    jmp .id_loop
.id_done_scan:
    mov rdi, [rbx + ST_POS]
    mov rcx, [rbx + ST_SOURCE]
    add rcx, rsi
    mov rdx, rdi
    sub rdx, rsi
    call lexer_keyword_kind
    mov rcx, rbx
    mov edx, eax
    mov r8, rsi
    mov r9, rdi
    mov [rsp + 32], r12
    mov eax, [rbx + ST_LINE]
    mov [rsp + 40], eax
    mov eax, [rbx + ST_COL]
    mov [rsp + 48], eax
    call lexer_make_token
    add rsp, 48
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

.globl lexer_scan_number
.def lexer_scan_number; .scl 2; .type 32; .endef
lexer_scan_number:
    push rbx
    push rsi
    push rdi
    push r12
    sub rsp, 48
    mov rbx, rcx
    mov r12, rdx
    mov rsi, [rbx + ST_POS]
    dec rsi
.num_loop:
    mov rcx, rbx
    call lexer_peek
    cmp al, '0'
    jb .num_suffix
    cmp al, '9'
    ja .num_suffix
    mov rcx, rbx
    call lexer_advance
    jmp .num_loop
.num_suffix:
    mov edx, TK_INT
    cmp al, 'l'
    je .num_long
    cmp al, 'L'
    je .num_long
    cmp al, 'd'
    je .num_double
    cmp al, 'D'
    je .num_double
    jmp .num_make
.num_long:
    mov rcx, rbx
    call lexer_advance
    mov edx, TK_LONG
    jmp .num_make
.num_double:
    mov rcx, rbx
    call lexer_advance
    mov edx, TK_DOUBLE
.num_make:
    mov rdi, [rbx + ST_POS]
    mov rcx, rbx
    mov r8, rsi
    mov r9, rdi
    mov [rsp + 32], r12
    mov eax, [rbx + ST_LINE]
    mov [rsp + 40], eax
    mov eax, [rbx + ST_COL]
    mov [rsp + 48], eax
    call lexer_make_token
    add rsp, 48
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

.globl lexer_scan_string
.def lexer_scan_string; .scl 2; .type 32; .endef
lexer_scan_string:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    sub rsp, 56
    mov rbx, rcx
    mov r12, rdx
    mov rsi, [rbx + ST_POS]
    dec rsi
    xor r13d, r13d
.str_loop:
    mov rcx, rbx
    call lexer_is_at_end
    test eax, eax
    jne .str_unterminated
    mov rcx, rbx
    call lexer_advance
    test r13d, r13d
    je .str_not_escaped
    cmp al, 'n'
    je .str_escape_ok
    cmp al, 't'
    je .str_escape_ok
    cmp al, '\\'
    je .str_escape_ok
    cmp al, '"'
    je .str_escape_ok
    mov rcx, rbx
    mov rdx, rsi
    mov r8, [rbx + ST_POS]
    lea r9, [rip + s_invalid_escape]
    mov [rsp + 32], r12
    mov eax, [rbx + ST_LINE]
    mov [rsp + 40], eax
    mov eax, [rbx + ST_COL]
    mov [rsp + 48], eax
    call lexer_make_invalid_token
    jmp .str_done
.str_escape_ok:
    xor r13d, r13d
    jmp .str_loop
.str_not_escaped:
    cmp al, '\\'
    jne .str_check_quote
    mov r13d, 1
    jmp .str_loop
.str_check_quote:
    cmp al, '"'
    je .str_make
    cmp al, 10
    je .str_unterminated
    jmp .str_loop
.str_make:
    mov rdi, [rbx + ST_POS]
    mov rcx, rbx
    mov edx, TK_STRING
    mov r8, rsi
    mov r9, rdi
    mov [rsp + 32], r12
    mov eax, [rbx + ST_LINE]
    mov [rsp + 40], eax
    mov eax, [rbx + ST_COL]
    mov [rsp + 48], eax
    call lexer_make_token
    jmp .str_done
.str_unterminated:
    mov rcx, rbx
    mov rdx, rsi
    mov r8, [rbx + ST_POS]
    lea r9, [rip + s_unterminated_string]
    mov [rsp + 32], r12
    mov eax, [rbx + ST_LINE]
    mov [rsp + 40], eax
    mov eax, [rbx + ST_COL]
    mov [rsp + 48], eax
    call lexer_make_invalid_token
.str_done:
    add rsp, 56
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret
