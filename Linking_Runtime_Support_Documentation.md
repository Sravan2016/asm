# Bada Compiler - Linking & Runtime Support Documentation

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Calling Convention (Windows x64 MS ABI)](#2-calling-convention-windows-x64-ms-abi)
3. [Runtime Object Files](#3-runtime-object-files)
4. [Object Memory Layouts](#4-object-memory-layouts)
5. [Function Signatures](#5-function-signatures)
6. [Code Generation to Assembly Mapping](#6-code-generation-to-assembly-mapping)
7. [Linking Process](#7-linking-process)
8. [Runtime Initialization](#8-runtime-initialization)
9. [Windows API Wrapper Layer](#9-windows-api-wrapper-layer)
10. [External Library Dependencies](#10-external-library-dependencies)
11. [Known Limitations & Future Work](#11-known-limitations--future-work)
12. [Quick Reference Card](#12-quick-reference-card)

---

## 1. Architecture Overview

The Bada language compiler transforms source code into native x86-64 Windows executables through a multi-stage pipeline that generates assembly code which links with a pre-compiled runtime library written in pure NASM assembly.

### Pipeline Stages

| Stage | Description | Input → Output | Implementation |
|-------|-------------|----------------|----------------|
| 1 | Lexical Analysis | Source text → Token stream | `lexer.h/cpp` |
| 2 | Parsing | Token stream → AST | `parser.h/cpp` |
| 3 | Semantic Analysis | AST → Type-checked AST with symbol table | `SemanticAnalyser.h/cpp` |
| 4 | IR Generation | AST → Intermediate Representation (Three-Address Code) | `IRGenerator.h/cpp` |
| 5 | Code Generation | IR → x86-64 Intel-syntax Assembly (.s) | `CodeGenerator.h/cpp` |
| 6 | Assembly | Assembly (.s) → COFF Object (.obj) | NASM (`nasm.exe`) |
| 7 | Linking | User .obj + Runtime .obj → Executable (.exe) | GCC (`gcc.exe`) |

### Runtime Architecture

The bada runtime is a collection of hand-written x86-64 NASM assembly modules compiled into `.obj` files. Unlike typical runtimes that use heap-allocated memory, the bada runtime uses a unique **file-backed object model** where all data types (strings, arrays, integers, etc.) store their values in temporary files on disk, accessed through Windows Native API (Nt*) syscalls.

### Key Design Decisions

- **File-backed storage**: All objects use temporary files instead of heap memory for data storage
- **Static pools**: Arrays and maps use pre-allocated static pools with fixed maximum counts
- **Native API usage**: Runtime uses Windows Native API (ntdll.dll) directly instead of kernel32.dll wrappers
- **Pure assembly**: All runtime code is written in NASM assembly with no C library dependencies
- **Microsoft x64 ABI**: Strict adherence to Windows x64 calling convention

---

## 2. Calling Convention (Windows x64 MS ABI)

The bada compiler and runtime strictly follow the Microsoft x64 calling convention. This is fundamentally different from the System V AMD64 ABI used on Linux/macOS.

### Parameter Passing

First four integer/pointer arguments are passed in registers:

| Position | Register | Usage | Example |
|----------|----------|-------|---------|
| 1st | RCX | First argument (often "this" pointer / object) | `array_get(rcx, rdx)` |
| 2nd | RDX | Second argument | `int_add(rcx, rdx)` |
| 3rd | R8 | Third argument | `string_concat(rcx, rdx, r8)` |
| 4th | R9 | Fourth argument | `map_init(rcx, rdx, r8, r9)` |
| 5th+ | Stack | Fifth and subsequent arguments (pushed right-to-left) | `call function` (args on stack) |

### Shadow Space

The caller **MUST** allocate 32 bytes of "shadow space" (home space) on the stack before every function call. This space is used by the called function to spill register parameters if needed.

```nasm
    sub rsp, 32        ; allocate shadow space
    mov rcx, arg1
    mov rdx, arg2
    call some_function
    add rsp, 32        ; deallocate shadow space
```

### Return Values

| Type | Register | Notes |
|------|----------|-------|
| Integer / Pointer | RAX | 64-bit return value |
| Small Integer (32-bit) | EAX | Upper bits undefined |
| Boolean (1/0) | RAX | 1 for true, 0 for false |
| Floating-point (double) | XMM0 | IEEE 754 double precision |

### Stack Alignment

The stack must be 16-byte aligned before executing a `CALL` instruction. After the CALL pushes the return address (8 bytes), RSP is congruent to 8 mod 16. The shadow space allocation (32 bytes) maintains this alignment.

### Callee-Saved Registers

The following registers must be preserved across function calls:

- `RBX`
- `RBP`
- `R12`
- `R13`
- `R14`
- `R15`

---

## 3. Runtime Object Files

The runtime is split into two directories of pre-compiled NASM object files.

### asm_pure_obj/ - Core Runtime

| File | Size (bytes) | Purpose |
|------|-------------|---------|
| `string.obj` | 13,802 | String manipulation, I/O, parsing, printing |
| `badaapi_ptrs.obj` | 6,336 | Windows Native API (Nt*) wrappers |
| `file.obj` | 5,212 | File reading utilities and line processing |
| `array.obj` | 5,373 | Dynamic array operations (create, add, get, sort, etc.) |
| `thread.obj` | 4,221 | Thread creation, TLS, synchronization |
| `map.obj` | 4,243 | Hash map with key-value storage |
| `httpclient.obj` | 1,605 | HTTP client over TCP sockets |
| `httpserver.obj` | 2,182 | HTTP server with socket management |
| `sock.obj` | 1,700 | Raw TCP socket operations |
| `integer.obj` | 2,148 | 32-bit integer arithmetic and conversions |
| `long.obj` | 2,163 | 64-bit integer arithmetic and conversions |
| `double.obj` | 2,233 | IEEE 754 double-precision floating-point operations |
| `boolean.obj` | 2,210 | Boolean logic and type conversions |

### asm_file_obj/ - File & Heap Support

| File | Size (bytes) | Purpose |
|------|-------------|---------|
| `readwritefile.obj` | 5,212 | File read/write operations (duplicates file.obj) |
| `heap.obj` | 1,014 | Custom heap allocator (8MB arena with free list) |

**Total Runtime Size: ~56 KB of compiled object code**

---

## 4. Object Memory Layouts

All bada objects use a file-backed storage model. Each object is represented by a small in-memory header that contains a file handle and metadata. The actual data is stored in temporary files on disk.

### 4.1 String Objects

Strings are stored as file-backed objects with a 16-byte header:

| Offset | Size | Field | Description |
|--------|------|-------|-------------|
| 0 | 8 bytes (qword) | `file_handle` | Windows file handle to temporary string file |
| 8 | 8 bytes (qword) | `length` | Current string length in characters |

```
String Layout (16 bytes):
  [0]  = file_handle (qword)
  [8]  = length (qword)

File naming: filestring_<hex_object_ptr>.txt
```

String content is accessed via file operations: `SetFilePointerEx` to position, then `ReadFile`/`WriteFile` to access characters.

### 4.2 Array Objects

Arrays use a 32-byte header with static pool allocation:

| Offset | Size | Field | Description |
|--------|------|-------|-------------|
| 0 | 8 bytes (qword) | `file_handle` | File handle to array data file |
| 8 | 8 bytes (qword) | `length` | Current number of elements |
| 16 | 8 bytes (qword) | `capacity` | Maximum element capacity |
| 24 | 8 bytes (qword) | `element_size` | Size of each element in bytes |

```
Array Layout (32 bytes):
  [0]  = file_handle (qword)
  [8]  = length (qword)
  [16] = capacity (qword)
  [24] = element_size (qword)

File naming: fielarray_<hex_object_ptr>.bin
Storage: Static pool (array_pool) - max 16 arrays x 32 bytes
```

Elements are accessed via file operations at offset `index * elem_size`.

### 4.3 Integer / Long / Double / Boolean Objects

| Type | Header Size | Value Size | File Naming | Storage Functions |
|------|------------|------------|-------------|-------------------|
| Integer | 16 bytes | 4 bytes (stored in file) | `fileint_<ptr>.bin` | `fileint_get` / `fileint_set` |
| Long | 16 bytes | 8 bytes (stored in file) | `filelong_<ptr>.bin` | `filelong_get` / `filelong_set` |
| Double | 16 bytes | 8 bytes (stored in file) | `filedouble_<ptr>.bin` | `filedouble_get` / `filedouble_set` |
| Boolean | 16 bytes | 1 byte (stored in file) | `filebool_<ptr>.bin` | `filebool_get` / `filebool_set` |

All primitive types share the same header structure: `[0] = file_handle`, `[8] = size_marker`.

### 4.4 Map Objects

| Offset | Size | Field | Description |
|--------|------|-------|-------------|
| 0 | 8 bytes | `file_handle` | File handle to map entries file |
| 8 | 8 bytes | `bucket_count` | Number of hash buckets |
| 16 | 8 bytes | `size` | Current number of key-value pairs |
| 24 | 8 bytes | `hash_fn` | Pointer to hash callback function |
| 32 | 8 bytes | `equals_fn` | Pointer to equality callback function |

```
Map Entry Layout (32 bytes per entry, stored in file):
  [0]  = used_flag (qword) - 1 if occupied, 0 if empty
  [8]  = key (qword)
  [16] = value (qword)
  [24] = hash (qword)

Limits: Max 128 entries (MAP_MAX_ENTRIES)
Storage: Static pool (map_pool) - max 16 maps x 40 bytes
Algorithm: Open addressing with linear probing
```

---

## 5. Function Signatures

### 5.1 String Functions (`string.obj`)

| Function | RCX | RDX | R8 | R9 | Returns | Description |
|----------|-----|-----|----|----|---------|-------------|
| `string_from_cstr` | String* | C string | - | - | success (1/0) | Create string from C string |
| `string_copy` | dest* | src* | - | - | - | Copy string content |
| `string_free` | String* | - | - | - | - | Close handle, delete file |
| `string_length` | String* | - | - | - | length | Get string length |
| `string_char_at` | String* | index | - | - | char | Get character at index |
| `string_concat` | out* | str_a* | str_b* | - | - | Concatenate a + b into out |
| `string_equals` | str_a* | str_b* | - | - | 1/0 | Compare strings |
| `string_equals_icase` | str_a* | str_b* | - | - | 1/0 | Case-insensitive compare |
| `string_contains_sub` | haystack* | needle* | - | - | 1/0 | Substring check |
| `string_split` | out* | input* | delimiter | - | 1/0 | Split by delimiter |
| `string_trim` | out* | input | - | - | 1/0 | Trim whitespace |
| `string_trimall` | out* | input | - | - | 1/0 | Remove all whitespace |
| `string_between_two_symbols` | out* | input | start_char | end_char | 1/0 | Extract between chars |
| `string_regex_digits_matches` | out* | input | - | - | 1/0 | Extract digits |
| `string_regex_digits_nonmatches` | out* | input | - | - | 1/0 | Extract non-digits |
| `print_string` | String* | - | - | - | - | Print string to stdout |
| `print_cstr` | C string | - | - | - | - | Print C string to stdout |
| `print_uint` | uint64 | - | - | - | - | Print unsigned int to stdout |
| `runtime_init` | - | - | - | - | - | Initialize stdout handle |

### 5.2 Integer Functions (`integer.obj`)

| Function | Input Registers | Returns | Description |
|----------|----------------|---------|-------------|
| `int_add` | ECX=a, EDX=b | EAX=a+b | Integer addition |
| `int_sub` | ECX=a, EDX=b | EAX=a-b | Integer subtraction |
| `int_mul` | ECX=a, EDX=b | EAX=a*b | Integer multiplication |
| `int_div` | ECX=a, EDX=b | EAX=a/b | Signed integer division |
| `int_mod` | ECX=a, EDX=b | EAX=a%b | Signed integer modulo |
| `int_eq` | ECX=a, EDX=b | RAX=1/0 | Equality comparison |
| `int_lt` | ECX=a, EDX=b | RAX=1/0 | Less than comparison |
| `int_gt` | ECX=a, EDX=b | RAX=1/0 | Greater than comparison |
| `fromStringToInteger` | RCX=C string | EAX=int | Parse string to int |
| `fromLongToInteger` | ECX=long | EAX=int | Convert long to int |
| `fromDoubleToInteger` | XMM0=double | EAX=int | Convert double to int |
| `fileint_get` | RCX=FileInt* | EAX=value | Read integer from file |
| `fileint_set` | RCX=FileInt*, EDX=val | success | Write integer to file |
| `fileint_free` | RCX=FileInt* | - | Free file-backed int |

### 5.3 Long Functions (`long.obj`)

| Function | Input Registers | Returns | Description |
|----------|----------------|---------|-------------|
| `long_add` | RCX=a, RDX=b | RAX=a+b | 64-bit addition |
| `long_sub` | RCX=a, RDX=b | RAX=a-b | 64-bit subtraction |
| `long_mul` | RCX=a, RDX=b | RAX=a*b | 64-bit multiplication |
| `long_div` | RCX=a, RDX=b | RAX=a/b | 64-bit signed division |
| `long_mod` | RCX=a, RDX=b | RAX=a%b | 64-bit signed modulo |
| `long_eq` | RCX=a, RDX=b | RAX=1/0 | 64-bit equality |
| `long_lt` | RCX=a, RDX=b | RAX=1/0 | 64-bit less than |
| `long_gt` | RCX=a, RDX=b | RAX=1/0 | 64-bit greater than |
| `fromStringToLong` | RCX=C string | RAX=long | Parse string to long |
| `fromIntegerToLong` | ECX=int | RAX=long | Convert int to long |
| `fromDoubleToLong` | XMM0=double | RAX=long | Convert double to long |
| `filelong_get` | RCX=FileLong* | RAX=value | Read long from file |
| `filelong_set` | RCX=FileLong*, RDX=val | success | Write long to file |
| `filelong_free` | RCX=FileLong* | - | Free file-backed long |

### 5.4 Double Functions (`double.obj`)

| Function | Input Registers | Returns | Description |
|----------|----------------|---------|-------------|
| `double_add` | XMM0=a, XMM1=b | XMM0=a+b | Double addition |
| `double_sub` | XMM0=a, XMM1=b | XMM0=a-b | Double subtraction |
| `double_mul` | XMM0=a, XMM1=b | XMM0=a*b | Double multiplication |
| `double_div` | XMM0=a, XMM1=b | XMM0=a/b | Double division |
| `double_eq` | XMM0=a, XMM1=b | RAX=1/0 | Double equality |
| `double_lt` | XMM0=a, XMM1=b | RAX=1/0 | Double less than |
| `double_gt` | XMM0=a, XMM1=b | RAX=1/0 | Double greater than |
| `fromStringToDouble` | RCX=C string | XMM0=double | Parse string to double |
| `fromIntegerToDouble` | ECX=int | XMM0=double | Convert int to double |
| `fromLongToDouble` | RCX=long | XMM0=double | Convert long to double |
| `filedouble_get` | RCX=FileDouble* | XMM0=value | Read double from file |
| `filedouble_set` | RCX=FileDouble*, XMM1=val | success | Write double to file |
| `filedouble_free` | RCX=FileDouble* | - | Free file-backed double |

### 5.5 Boolean Functions (`boolean.obj`)

| Function | Input | Returns | Description |
|----------|-------|---------|-------------|
| `bool_not` | ECX=a | RAX=1/0 | Logical NOT |
| `bool_and` | ECX=a, EDX=b | RAX=1/0 | Logical AND |
| `bool_or` | ECX=a, EDX=b | RAX=1/0 | Logical OR |
| `bool_xor` | ECX=a, EDX=b | RAX=1/0 | Logical XOR |
| `bool_eq` | ECX=a, EDX=b | RAX=1/0 | Boolean equality |
| `fromStringToBoolean` | RCX=C string | RAX=1/0 | Parse string to bool |
| `fromIntegerToBoolean` | ECX=int | RAX=1/0 | Convert int to bool |
| `fromLongToBoolean` | RCX=long | RAX=1/0 | Convert long to bool |
| `fromDoubleToBoolean` | XMM0=double | RAX=1/0 | Convert double to bool |

### 5.6 Array Functions (`array.obj`)

| Function | RCX | RDX | R8 | Returns | Description |
|----------|-----|-----|----|---------|-------------|
| `array_create` | capacity | elem_size | - | array* | Create new array |
| `array_add` | array* | elem_ptr | - | success | Append element |
| `array_get` | array* | index | - | elem_ptr* | Get element pointer |
| `array_size` | array* | - | - | size | Get element count |
| `array_remove` | array* | index | - | success | Remove at index |
| `array_find` | array* | callback | - | success | Find with predicate |
| `array_filter` | src* | callback | - | new array* | Filter elements |
| `array_map` | src* | dst* | callback | - | Map elements |
| `array_sort` | array* | cmp_cb | - | - | Bubble sort |
| `array_join` | src* | delim* | out* | - | Join to string |
| `array_free` | array* | - | - | - | Close and delete |

### 5.7 Map Functions (`map.obj`)

| Function | RCX | RDX | R8 | R9 | Returns | Description |
|----------|-----|-----|----|----|---------|-------------|
| `map_create` | bucket_count | hash_fn | equals_fn | - | map* | Create new map |
| `map_put` | map* | key | value | - | old_value | Insert key-value |
| `map_get` | map* | key | - | - | value/0 | Lookup by key |
| `map_contains_key` | map* | key | - | - | 1/0 | Key existence check |
| `map_remove` | map* | key | - | - | old_value | Remove key-value |
| `map_size` | map* | - | - | - | size | Entry count |
| `map_is_empty` | map* | - | - | - | 1/0 | Empty check |
| `map_clear` | map* | - | - | - | - | Remove all entries |
| `map_free` | map* | - | - | - | - | Free map resources |

### 5.8 Thread Functions (`thread.obj`)

| Function | RCX | RDX | R8 | Returns | Description |
|----------|-----|-----|----|---------|-------------|
| `thread_init` | - | - | - | - | Initialize TLS + critical section |
| `thread_run` | name | callback | user_data | handle | Start new thread |
| `thread_join` | handle | - | - | success | Wait for thread exit |
| `thread_cache_set_string` | name | String* | - | - | Set TLS string |
| `thread_cache_get_string` | name | out* | - | success | Get TLS string |
| `thread_cache_set_int` | name | int (EDX) | - | - | Set TLS int |
| `thread_cache_get_int` | name | out* | - | success | Get TLS int |
| `thread_cache_set_long` | name | long | - | - | Set TLS long |
| `thread_cache_get_long` | name | out* | - | success | Get TLS long |
| `thread_cache_set_double` | name | double (XMM1) | - | - | Set TLS double |
| `thread_cache_get_double` | name | out* | - | success | Get TLS double |
| `thread_cache_set_array` | name | Array* | - | - | Set TLS array |
| `thread_cache_get_array` | name | out* | - | success | Get TLS array |

### 5.9 File Functions (`readwritefile.obj` / `file.obj`)

| Function | RCX | RDX | R8 | Returns | Description |
|----------|-----|-----|----|---------|-------------|
| `file_read_all` | path_cstr | AsmString* | - | success | Read entire file |
| `file_count_lines` | path_cstr | - | - | line_count | Count lines |
| `file_get_line_at` | path | index | out* | success | Get specific line |
| `file_line_reader_open` | path_cstr | - | - | success | Open for reading |
| `file_line_reader_next` | out* | - | - | success | Get next line |
| `file_line_reader_close` | - | - | - | - | Close reader |
| `file_line_reader_line_count` | - | - | - | total | Get total lines |
| `file_print_lines_count` | path_cstr | - | - | - | Print with line numbers |

### 5.10 Heap Functions (`heap.obj`)

| Function | RCX | RDX | R8 | Returns | Description |
|----------|-----|-----|----|---------|-------------|
| `HeapAlloc` | heap_handle | flags | size | ptr/0 | Allocate memory |
| `HeapFree` | heap_handle | ptr | - | success | Free memory |

Heap allocator details: 8MB arena, 16-byte alignment, free list management, `HEAP_ZERO_MEMORY` flag support.

---

## 6. Code Generation to Assembly Mapping

### 6.1 IR Instructions to Assembly

The CodeGenerator translates each IR instruction into equivalent x86-64 assembly:

| IR Opcode | Generated Assembly Pattern | Notes |
|-----------|--------------------------|-------|
| `ConstInt` | `mov rax, <value>`<br>`mov [rbp-<offset>], rax` | Immediate integer constant |
| `ConstLong` | `mov rax, <value>`<br>`mov [rbp-<offset>], rax` | Same as ConstInt (64-bit) |
| `ConstBool` | `mov rax, <0 or 1>`<br>`mov [rbp-<offset>], rax` | Boolean as integer |
| `ConstPtr` | `lea rax, [rel <string_label>]`<br>`mov [rbp-<offset>], rax` | Pointer to string object |
| `Add (int)` | `mov rax, [rbp-a]`<br>`mov rbx, [rbp-b]`<br>`add rax, rbx`<br>`mov [rbp-dest], rax` | Integer arithmetic |
| `Add (string)` | `sub rsp, 32`<br>`mov rcx, a`<br>`mov rdx, b`<br>`call string_concat`<br>`add rsp, 32` | Runtime call |
| `Sub` | `mov rax, [rbp-a]`<br>`mov rbx, [rbp-b]`<br>`sub rax, rbx` | Integer subtraction |
| `Mul` | `mov rax, [rbp-a]`<br>`mov rbx, [rbp-b]`<br>`imul rax, rbx` | Signed multiplication |
| `Div` | `mov rax, [rbp-a]`<br>`mov rbx, [rbp-b]`<br>`cqo`<br>`idiv rbx` | Signed division (uses rdx:rax) |
| `EQ/NE/LT/GT/LE/GE` | `mov rax, [rbp-a]`<br>`mov rbx, [rbp-b]`<br>`cmp rax, rbx`<br>`setXX al`<br>`movzx rax, al` | Condition codes |
| `Branch` | `mov rax, [rbp-cond]`<br>`test rax, rax`<br>`jne <then_label>`<br>`jmp <else_label>` | Conditional branch |
| `Jmp` | `jmp <label>` | Unconditional jump |
| `Load` | `mov rax, [rbp-<addr>]`<br>`mov [rbp-<dest>], rax` | Load from stack slot |
| `Store` | `mov rax, [rbp-<value>]`<br>`mov [rbp-<addr>], rax` | Store to stack slot |
| `Call` / `CallRuntime` | `sub rsp, 32`<br>`mov rcx, arg1 ...`<br>`call <func>`<br>`add rsp, 32` | Windows x64 ABI |
| `ArrayNew` | `sub rsp, 32`<br>`mov rcx, capacity`<br>`mov rdx, 8`<br>`call array_create`<br>`add rsp, 32` | Runtime call |
| `ArrayGet` | `sub rsp, 32`<br>`mov rcx, array`<br>`mov rdx, index`<br>`call array_get`<br>`add rsp, 32` | Runtime call |
| `ArraySet` | `sub rsp, 32`<br>`mov rcx, array`<br>`mov rdx, value`<br>`call array_add`<br>`add rsp, 32` | Uses `array_add` |
| `ArrayLen` | `sub rsp, 32`<br>`mov rcx, array`<br>`call array_size`<br>`add rsp, 32` | Runtime call |
| `Ret` | `pop r15...rbx`<br>`leave`<br>`ret` | Epilogue + return |

### 6.2 String Constant Emission

String literals in the IR are emitted as structured objects in the `.data` section:

```nasm
section .data
    str_0_data db 'hello world', 0
    str_0 dq str_0_data, 11     ; (pointer, length) pair
```

Each string constant produces two labels:
- `<name>_data` for the raw bytes
- `<name>` for the `(ptr, length)` struct that the runtime expects

### 6.3 Function Prologue/Epilogue

Every generated function follows this structure:

```nasm
function_name:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov [rbp-<offset>], rcx   ; parameter 1
    mov [rbp-<offset>], rdx   ; parameter 2
    ; ... more parameters ...
    
    ; class field initialization
    ; function body
    
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
```

---

## 7. Linking Process

### 7.1 Build System Integration (CMakeLists.txt)

The CMake build system handles the multi-stage compilation:

```cmake
# 1. Assemble runtime .s -> .obj
add_custom_command(
    OUTPUT asm_pure_obj/string.obj
    COMMAND nasm -f win64 -o ${CMAKE_BINARY_DIR}/asm_pure_obj/string.obj
    ${CMAKE_SOURCE_DIR}/asm_pure/string.s
    DEPENDS asm_pure/string.s
)

# 2. Compile compiler C++ -> compiler.exe
add_executable(compiler
    compiler/compiler.cpp
    compiler/IR.cpp
    compiler/IRGenerator.cpp
    compiler/CodeGenerator.cpp
    # ... other sources
)

# 3. Use compiler to compile .bada -> .s
add_custom_command(
    OUTPUT sample.s
    COMMAND compiler sample.bada
    DEPENDS sample.bada compiler
)
```

### 7.2 Assembly to Object

Generated assembly files are assembled using NASM:

```bash
nasm -f win64 -o output.obj source.s
```

Flags: `-f win64` produces a 64-bit COFF (Common Object File Format) object file compatible with the MSVC ABI and GCC MinGW-w64 linker.

### 7.3 Object to Executable

Final linking uses GCC MinGW-w64 to combine user code with runtime objects:

```bash
gcc -o output.exe \
    output.obj \
    build/asm_pure_obj/string.obj \
    build/asm_pure_obj/integer.obj \
    build/asm_pure_obj/array.obj \
    build/asm_pure_obj/boolean.obj \
    build/asm_pure_obj/double.obj \
    build/asm_pure_obj/long.obj \
    build/asm_pure_obj/map.obj \
    build/asm_pure_obj/badaapi_ptrs.obj \
    build/asm_pure_obj/thread.obj \
    build/asm_pure_obj/httpclient.obj \
    build/asm_pure_obj/httpserver.obj \
    build/asm_pure_obj/sock.obj \
    build/asm_pure_obj/file.obj \
    build/asm_file_obj/heap.obj \
    -lntdll -lws2_32
```

### System Library Dependencies

| Library | Purpose | Key Symbols Used |
|---------|---------|-----------------|
| `ntdll.dll` (-lntdll) | Windows Native API | NtClose, NtCreateFile, NtReadFile, NtWriteFile, NtQueryInformationFile, RtlGetFullPathName_U, etc. |
| `ws2_32.dll` (-lws2_32) | Windows Sockets 2 | WSAStartup, WSACleanup, socket, bind, listen, accept, connect, send, recv, closesocket, htons, inet_addr |

> **Note**: `heap.obj` and `readwritefile.obj` share symbols (`heap_handle`, `HeapAlloc`, etc.). Only include one set to avoid multiple definition errors.

---

## 8. Runtime Initialization

### Required Initialization Calls

Before using any runtime functions, the following initialization must be performed:

| Function | Module | What it does |
|----------|--------|-------------|
| `runtime_init` | `string.obj` | Initializes stdout handle via `GetStdHandle(STD_OUTPUT_HANDLE)`. Required before `print_string`/`print_cstr`/`print_uint`. |
| `thread_init` | `thread.obj` | Allocates TLS slot and initializes critical section. Required before any `thread_cache_*` operations. |

### Program Entry Point Pattern

```nasm
main:
    push rbp
    mov rbp, rsp

    ; Initialize runtime
    sub rsp, 32
    call runtime_init
    add rsp, 32

    ; Call user code
    sub rsp, 32
    mov rcx, 0            ; this pointer
    call UserClass_main
    add rsp, 32

    mov rax, 0
    leave
    ret
```

The compiler generates a simple `main` entry point that calls the first user-defined function. `runtime_init` should be called first in production code.

---

## 9. Windows API Wrapper Layer (badaapi_ptrs.obj)

The `badaapi_ptrs` module provides a thin wrapper layer around Windows Native API (ntdll.dll) syscalls. This bypasses the standard C runtime and provides direct kernel access.

### File Operations

| Wrapper | Native API | Purpose |
|---------|-----------|---------|
| `pCreateFileA` | `NtCreateFile` | Create or open files |
| `pReadFile` | `NtReadFile` | Read from file handles |
| `pWriteFile` | `NtWriteFile` | Write to file handles |
| `pSetFilePointerEx` | `NtSetInformationFile` | Seek in files |
| `pGetFileSizeEx` | `NtQueryInformationFile` | Query file size |
| `pCloseHandle` | `NtClose` | Close any handle |
| `pDeleteFileA` | `NtDeleteFile` | Delete files |

### Thread Operations

| Wrapper | Native API / API | Purpose |
|---------|-----------------|---------|
| `pCreateThread` | `RtlCreateUserThread` | Create new thread |
| `pWaitForSingleObject` | `NtWaitForSingleObject` | Wait on kernel object |
| `pInitializeCriticalSection` | `RtlInitializeCriticalSection` | Initialize critical section |
| `pEnterCriticalSection` | `RtlEnterCriticalSection` | Enter critical section |
| `pLeaveCriticalSection` | `RtlLeaveCriticalSection` | Leave critical section |
| `pTlsAlloc` | `TlsAlloc` | Allocate TLS index |
| `pTlsSetValue` | `TlsSetValue` | Set TLS value |

### Path Resolution

| Wrapper | Native API | Purpose |
|---------|-----------|---------|
| `RtlGetFullPathName_U` | `RtlGetFullPathName_U` | Convert relative to absolute path |
| `RtlDosPathNameToNtPathName_U` | `RtlDosPathNameToNtPathName_U` | Convert DOS path to NT path |
| `RtlFreeUnicodeString` | `RtlFreeUnicodeString` | Free UNICODE_STRING buffer |

### Status and Handle Tracking Variables

```nasm
; Global tracking variables (badaapi_ptrs.obj)
last_ntstatus_create    - NTSTATUS from last NtCreateFile
last_ntstatus_write       - NTSTATUS from last NtWriteFile
last_io_info_write        - IO_STATUS_BLOCK from write
last_handle_create        - Handle from last create
last_handle_write         - Handle from last write
last_writefile_lp_ptr     - Last LARGE_INTEGER pointer
last_writefile_lp_value   - Last LARGE_INTEGER value
last_lpnumber_written     - Last bytes written count
last_lpnumber_readback    - Last bytes read count
```

---

## 10. External Library Dependencies

### Build Tools

| Tool | Version | Purpose |
|------|---------|---------|
| CMake | >= 3.20 | Build system configuration |
| NASM | >= 2.15 | Netwide Assembler - .s to .obj |
| GCC (MinGW-w64) | >= 13.0 | Linker for .obj to .exe |
| Ninja | >= 1.10 | Build executor |

### Runtime DLL Dependencies

| DLL | Dependency Type | Key Symbols |
|-----|----------------|-------------|
| `ntdll.dll` | Direct import (via -lntdll) | NtClose, NtCreateFile, NtReadFile, NtWriteFile, NtQueryInformationFile, NtSetInformationFile, NtDeleteFile, NtWaitForSingleObject, RtlGetFullPathName_U, RtlDosPathNameToNtPathName_U, RtlFreeUnicodeString, RtlCreateUserThread, RtlInitializeCriticalSection |
| `ws2_32.dll` | Direct import (via -lws2_32) | WSAStartup, WSACleanup, socket, bind, listen, accept, connect, send, recv, closesocket, htons, inet_addr |
| `kernel32.dll` | Indirect (via ntdll) | GetStdHandle (referenced by runtime) |

### IDE / Compiler Infrastructure

| Component | Purpose |
|-----------|---------|
| CLion / IntelliJ | IDE for compiler development |
| MSYS2 / MinGW-w64 | Unix-like environment and toolchain on Windows |
| C++17 | Compiler implementation language |

---

## 11. Known Limitations & Future Work

### Current Limitations

| Issue | Description | Severity | Fix |
|-------|-------------|----------|-----|
| **No integer-to-string conversion** | Runtime lacks int→string conversion. String concatenation with integers (e.g., `"value: " + 42`) cannot be resolved. | Medium | Add `toString(int)` function to integer.obj |
| **File-backed performance** | All objects store data in files, causing significant I/O overhead for compute-intensive operations. | High | Implement hybrid memory/file storage or pure memory mode |
| **Static pool limits** | Arrays and maps use static pools (max 16 instances each). Exceeding causes undefined behavior. | Medium | Implement dynamic pool expansion or heap-based allocation |
| **No garbage collection** | Objects must be explicitly freed. Memory leaks possible if `free` is not called. | High | Implement reference counting or mark-and-sweep GC |
| **No closure support** | Lambdas cannot capture variables from enclosing scope. Only parameter passing supported. | Medium | Implement closure struct generation in codegen |
| **No dynamic method dispatch** | Trait inheritance resolves method calls at compile time. Runtime polymorphism not supported. | Medium | Implement vtable-based dynamic dispatch |
| **No floating-point code generation** | IR supports Double type but CodeGenerator does not emit XMM register operations. | Medium | Add double arithmetic cases to `CodeGenerator::emit_instruction` |
| **No stack-based arguments** | Functions with >4 parameters not properly handled. Additional args should be pushed on stack. | Low | Implement stack argument passing for i > 4 |

### Completed Improvements

- Windows x64 ABI compliance (RCX/RDX/R8/R9 with 32-byte shadow space)
- String object layout matching runtime expectations (ptr + length struct)
- Function label scoping (`FuncName_blockName` pattern prevents label collisions)
- Proper epilogue generation (no duplicate `ret` instructions)
- Correct method call name mangling (`ClassName_methodName`)
- Class field initialization injected at method entry
- Eliminated hardcoded `%0` temporary references
- Runtime symbol name alignment (`print_uint`, `array_add`, etc.)
- Stack-based variable allocation for all temporaries

---

## 12. Quick Reference Card

### Compiler Usage

```bash
# Compile a bada source file:
./cmake-build-debug/compiler.exe source.bada

# Dump IR for debugging:
./cmake-build-debug/compiler.exe source.bada --dump-ir

# Assemble generated code:
nasm -f win64 -o source.obj source.s

# Link with runtime:
gcc -o source.exe source.obj build/asm_pure_obj/*.obj build/asm_file_obj/heap.obj -lntdll -lws2_32
```

### Register Quick Reference

| Register | Calling Convention Role | Code Generation Use |
|----------|------------------------|---------------------|
| `RAX` | Return value | Temporary for arithmetic, return values |
| `RCX` | 1st argument | First function parameter |
| `RDX` | 2nd argument | Second function parameter |
| `RBX` | Callee-saved | Temporary (saved/restored in prologue/epilogue) |
| `R8` | 3rd argument | Third function parameter |
| `R9` | 4th argument | Fourth function parameter |
| `R12-R15` | Callee-saved | Temporaries (saved/restored in prologue/epilogue) |
| `RBP` | Frame pointer | Stack frame base pointer |
| `RSP` | Stack pointer | Stack management |
| `XMM0` | FP return value | Double-precision floating-point results |

### Object Type Quick Reference

| Type | Header Size | Runtime Functions | Create Pattern |
|------|------------|-------------------|----------------|
| String | 16 bytes (handle + length) | `string_concat`, `string_equals`, `string_free` | `dq str_data, len` |
| Integer | 16 bytes (handle + size) | `int_add`, `int_sub`, `int_mul`, `int_div` | Immediate in register |
| Long | 16 bytes (handle + size) | `long_add`, `long_sub`, `long_mul`, `long_div` | Immediate in register |
| Double | 16 bytes (handle + size) | `double_add`, `double_sub` (XMM) | Immediate in XMM |
| Boolean | 16 bytes (handle + size) | `bool_and`, `bool_or`, `bool_not` | 0 or 1 in register |
| Array | 32 bytes (handle + len + cap + elem_size) | `array_create`, `array_add`, `array_get` | `call array_create(cap, elem_size)` |
| Map | 40 bytes (handle + buckets + size + fn ptrs) | `map_create`, `map_put`, `map_get` | `call map_create(buckets, hash, eq)` |

### Key File Locations

```
Compiler Sources:    compiler/IR.h, compiler/IRGenerator.h, compiler/CodeGenerator.h
Runtime Sources:     asm_pure/*.s, asm_file/*.s
Runtime Objects:     build/asm_pure_obj/*.obj, build/asm_file_obj/*.obj
Generated Assembly:  <source>.s (next to input file)
Generated Object:    <source>.obj (via nasm)
Sample Input:        project/sample.bada
```
