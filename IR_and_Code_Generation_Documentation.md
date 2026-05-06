# Intermediate Representation and Code Generation

## bada Compiler Architecture Document

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [What is Intermediate Representation?](#2-what-is-intermediate-representation)
3. [Why Use IR in the bada Compiler?](#3-why-use-ir-in-the-bada-compiler)
4. [IR Design for bada Language](#4-ir-design-for-bada-language)
5. [IR Instruction Set](#5-ir-instruction-set)
6. [IR Data Structures](#6-ir-data-structures)
7. [AST to IR Translation](#7-ast-to-ir-translation)
8. [IR Optimization Passes](#8-ir-optimization-passes)
9. [Code Generation](#9-code-generation)
10. [Target Backend: x86-64 Assembly](#10-target-backend-x86-64-assembly)
11. [Runtime System](#11-runtime-system)
12. [Implementation Details](#12-implementation-details)
13. [Examples](#13-examples)
14. [Future Enhancements](#14-future-enhancements)

---

## 1. Introduction

The bada compiler transforms high-level bada source code into executable machine code through multiple compilation phases. After lexical analysis, parsing, and semantic analysis, the compiler enters the Intermediate Representation (IR) generation phase, followed by code generation. This document details the design, implementation, and rationale behind these critical compilation stages.

### Current Compiler Pipeline

```
Source Code (.bada)
    ↓
Lexer (Tokenization)
    ↓
Parser (AST Construction)
    ↓
Semantic Analyzer (Type Checking, Symbol Resolution)
    ↓
IR Generator ← [THIS DOCUMENT]
    ↓
IR Optimizer
    ↓
Code Generator ← [THIS DOCUMENT]
    ↓
Assembly Output (.s)
    ↓
Assembler/Linker
    ↓
Executable
```

---

## 2. What is Intermediate Representation?

An Intermediate Representation (IR) is a data structure that sits between the high-level Abstract Syntax Tree (AST) and the low-level target machine code. It serves as a bridge that captures the program's semantics in a form that is:

- **Language-independent**: Not tied to the source language syntax
- **Machine-independent**: Not tied to any specific target architecture
- **Optimization-friendly**: Easy to analyze and transform
- **Explicit**: All implicit operations are made explicit

### IR vs AST

| Property | AST | IR |
|----------|-----|-----|
| Structure | Tree | Linear/Graph |
| Abstraction | High (language-specific) | Medium (language-agnostic) |
| Purpose | Represent source structure | Enable optimization |
| Control Flow | Implicit via nesting | Explicit via jumps |
| Types | Rich type information | Lowered to primitives |

### Common IR Forms

1. **Three-Address Code (TAC)**: Each instruction has at most 3 operands
   ```
   t1 = a + b
   t2 = t1 * c
   result = t2
   ```

2. **Static Single Assignment (SSA)**: Each variable assigned exactly once
   ```
   t1 = a + b
   t2 = t1 * c
   t3 = t2 + d
   ```

3. **Control Flow Graph (CFG)**: Basic blocks connected by edges
   ```
   [Block 1] --> [Block 2]
       |              |
       v              v
   [Block 3] <-- [Block 4]
   ```

4. **Abstract Syntax Tree (Lowered)**: Simplified AST
   ```
   (assign result
     (add (mul (add a b) c) d))
   ```

---

## 3. Why Use IR in the bada Compiler?

### 3.1 Language Characteristics Requiring IR

The bada language has several features that benefit from IR translation:

1. **Unique Block Delimiters**: `<` and `>` instead of `{` and `}`
2. **Multi-trait Inheritance**: `Class :: Trait1 :: Trait2->`
3. **Lambda Expressions**: `(params)=> < body >`
4. **Guard Blocks**: `(condition)< body >`
5. **Switch Blocks**: `(expr)< value,[ body ] >`
6. **Array Operations**: `arr.contains()`, `arr.filter()`, `arr.sort()`
7. **Return Lists**: `[expr]<--` syntax

### 3.2 Benefits for bada

- **Optimization**: Array operations can be optimized (e.g., filter+sort fusion)
- **Code Reuse**: Same IR can target x86-64, ARM, or WebAssembly
- **Debugging**: IR can be dumped and inspected for correctness
- **Testing**: IR-level tests verify semantic correctness before code generation
- **Future Extensions**: New backends only need IR → Target mapping

---

## 4. IR Design for bada Language

### 4.1 IR Philosophy

The bada IR follows these principles:

1. **Three-Address Code Based**: Instructions have at most 3 operands
2. **SSA Form (Optional)**: Variables assigned once for easier optimization
3. **Typed Instructions**: Each instruction carries type information
4. **Explicit Control Flow**: Jumps, branches, and labels replace nested blocks
5. **Runtime Calls**: Library functions (print, array operations) are explicit calls

### 4.2 IR Architecture

```
┌─────────────────────────────────────────────────────┐
│                    IR Module                         │
├─────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────┐   │
│  │              IR Function                     │   │
│  │  ┌───────────────────────────────────────┐  │   │
│  │  │           Basic Block 1               │  │   │
│  │  │  [IR Instruction]                     │  │   │
│  │  │  [IR Instruction]                     │  │   │
│  │  │  [IR Instruction]                     │  │   │
│  │  └───────────────────────────────────────┘  │   │
│  │                    ↓                         │   │
│  │  ┌───────────────────────────────────────┐  │   │
│  │  │           Basic Block 2               │  │   │
│  │  │  [IR Instruction]                     │  │   │
│  │  │  [IR Instruction]                     │  │   │
│  │  └───────────────────────────────────────┘  │   │
│  └─────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

### 4.3 Type System in IR

The IR uses a simplified type system:

| IR Type | Description | bada Source Types |
|---------|-------------|-------------------|
| `i32` | 32-bit signed integer | `Integer` |
| `i64` | 64-bit signed integer | `Long` |
| `f64` | 64-bit floating point | `Double` |
| `ptr` | Pointer/reference | `String`, class references |
| `bool` | Boolean value | `Boolean` |
| `void` | No value | Method return with no value |
| `array<T>` | Dynamic array | `T[]` |

---

## 5. IR Instruction Set

### 5.1 Arithmetic Instructions

| Instruction | Format | Description | Example |
|-------------|--------|-------------|---------|
| `add` | `t1 = add t2, t3` | Addition | `t1 = add a, b` |
| `sub` | `t1 = sub t2, t3` | Subtraction | `t1 = sub a, b` |
| `mul` | `t1 = mul t2, t3` | Multiplication | `t1 = mul a, b` |
| `div` | `t1 = div t2, t3` | Division | `t1 = div a, b` |
| `mod` | `t1 = mod t2, t3` | Modulo | `t1 = mod a, b` |
| `neg` | `t1 = neg t2` | Negation | `t1 = neg a` |

### 5.2 Comparison Instructions

| Instruction | Format | Description | Example |
|-------------|--------|-------------|---------|
| `eq` | `t1 = eq t2, t3` | Equal | `t1 = eq a, b` |
| `ne` | `t1 = ne t2, t3` | Not equal | `t1 = ne a, b` |
| `lt` | `t1 = lt t2, t3` | Less than | `t1 = lt a, b` |
| `le` | `t1 = le t2, t3` | Less or equal | `t1 = le a, b` |
| `gt` | `t1 = gt t2, t3` | Greater than | `t1 = gt a, b` |
| `ge` | `t1 = ge t2, t3` | Greater or equal | `t1 = ge a, b` |

### 5.3 Logical Instructions

| Instruction | Format | Description | Example |
|-------------|--------|-------------|---------|
| `and` | `t1 = and t2, t3` | Logical AND | `t1 = and a, b` |
| `or` | `t1 = or t2, t3` | Logical OR | `t1 = or a, b` |
| `not` | `t1 = not t2` | Logical NOT | `t1 = not a` |

### 5.4 Control Flow Instructions

| Instruction | Format | Description | Example |
|-------------|--------|-------------|---------|
| `label` | `label name` | Define label | `label L1` |
| `jmp` | `jmp label` | Unconditional jump | `jmp L1` |
| `br` | `br cond, true_label, false_label` | Conditional branch | `br t1, L1, L2` |
| `ret` | `ret [value]` | Return from function | `ret t1` |
| `call` | `t1 = call func, args...` | Function call | `t1 = call print, a` |

### 5.5 Memory Instructions

| Instruction | Format | Description | Example |
|-------------|--------|-------------|---------|
| `load` | `t1 = load addr` | Load from memory | `t1 = load ptr` |
| `store` | `store t1, addr` | Store to memory | `store t1, ptr` |
| `alloc` | `t1 = alloc type` | Allocate memory | `t1 = alloc i32` |
| `alloca` | `t1 = alloca type, count` | Stack allocation | `t1 = alloca i32, 10` |

### 5.6 Type Conversion Instructions

| Instruction | Format | Description | Example |
|-------------|--------|-------------|---------|
| `zext` | `t1 = zext t2` | Zero extend | `t1 = zext i32 t2 to i64` |
| `sext` | `t1 = sext t2` | Sign extend | `t1 = sext i32 t2 to i64` |
| `fptoui` | `t1 = fptoui t2` | Float to uint | `t1 = fptoui f64 t2 to i32` |
| `uitofp` | `t1 = uitofp t2` | Uint to float | `t1 = uitofp i32 t2 to f64` |

### 5.7 Array-Specific Instructions

| Instruction | Format | Description | Example |
|-------------|--------|-------------|---------|
| `array_new` | `t1 = array_new type, size` | Create array | `t1 = array_new i32, 10` |
| `array_get` | `t1 = array_get arr, idx` | Get element | `t1 = array_get arr, 0` |
| `array_set` | `array_set arr, idx, val` | Set element | `array_set arr, 0, t1` |
| `array_len` | `t1 = array_len arr` | Get length | `t1 = array_len arr` |
| `array_push` | `array_push arr, val` | Append element | `array_push arr, t1` |

---

## 6. IR Data Structures

### 6.1 Core IR Types

```cpp
// IR Value - base class for all values
enum class IRValueKind {
    Constant,
    Variable,
    Temporary,
    Parameter,
    Function,
    BasicBlock
};

struct IRValue {
    IRValueKind kind;
    IRType type;
    std::string name;
    // ...
};

// IR Type
enum class IRTypeKind {
    Void,
    Integer,    // i32
    Long,       // i64
    Double,     // f64
    Boolean,    // bool
    Pointer,    // ptr
    Array,      // array<T>
    String      // string
};

struct IRType {
    IRTypeKind kind;
    std::shared_ptr<IRType> element_type;  // For arrays
    std::string name;                       // For custom types
};
```

### 6.2 IR Instructions

```cpp
enum class IROpcode {
    // Arithmetic
    Add, Sub, Mul, Div, Mod, Neg,

    // Comparison
    EQ, NE, LT, LE, GT, GE,

    // Logical
    And, Or, Not,

    // Control Flow
    Label, Jmp, Branch, Ret, Call,

    // Memory
    Load, Store, Alloc, Alloca,

    // Type Conversion
    ZExt, SExt, FPToUI, UIToFP,

    // Array Operations
    ArrayNew, ArrayGet, ArraySet, ArrayLen, ArrayPush,

    // Phi (for SSA)
    Phi
};

struct IRInstruction {
    IROpcode opcode;
    IRType type;
    std::string result;        // Result variable (if any)
    std::vector<std::string> operands;
    std::vector<std::string> phi_sources;  // For phi nodes
    std::string label;         // For labels and jumps
    std::vector<std::string> phi_labels;   // For phi nodes

    std::string to_string() const;
};
```

### 6.3 Basic Blocks and Functions

```cpp
struct IRBasicBlock {
    std::string name;
    std::vector<IRInstruction> instructions;
    std::vector<std::string> predecessors;
    std::vector<std::string> successors;

    bool is_terminated() const;
    void add_instruction(const IRInstruction& inst);
};

struct IRFunction {
    std::string name;
    IRType return_type;
    std::vector<std::pair<std::string, IRType>> parameters;
    std::vector<IRBasicBlock> blocks;
    std::unordered_map<std::string, IRType> local_variables;

    IRBasicBlock& entry_block();
    IRBasicBlock& add_block(const std::string& name);
};

struct IRModule {
    std::vector<IRFunction> functions;
    std::vector<IRType> global_variables;

    void dump() const;
};
```

---

## 7. AST to IR Translation

### 7.1 Translation Strategy

The AST → IR translation uses a visitor pattern that walks the AST and emits IR instructions:

```cpp
class IRGenerator {
public:
    IRModule generate(const Program& program);

private:
    void visitClass(const ClassDecl& cls);
    void visitMethod(const MethodDecl& method);
    void visitStatement(const Stmt& stmt);
    std::string visitExpression(const Expr& expr);

    // Helper methods
    std::string new_temporary();
    void emit(const IRInstruction& inst);
    IRBasicBlock& current_block();

    // State
    IRModule module_;
    IRFunction* current_function_;
    int temp_counter_;
    int label_counter_;
};
```

### 7.2 Expression Translation

#### 7.2.1 Binary Expressions

**bada Source:**
```
Integer result = a + b * c;
```

**AST:**
```
VariableDecl(result, Integer)
  └─ BinaryExpr(+)
       ├─ Identifier(a)
       └─ BinaryExpr(*)
            ├─ Identifier(b)
            └─ Identifier(c)
```

**Generated IR:**
```
%t1 = load b
%t2 = load c
%t3 = mul %t1, %t2
%t4 = load a
%t5 = add %t4, %t3
store %t5, result
```

#### 7.2.2 Comparison Expressions

**bada Source:**
```
Boolean b = a > b;
```

**Generated IR:**
```
%t1 = load a
%t2 = load b
%t3 = gt %t1, %t2
store %t3, b
```

### 7.3 Statement Translation

#### 7.3.1 Variable Declaration

**bada Source:**
```
Integer x = 10;
```

**Generated IR:**
```
%t1 = const i32 10
store %t1, x
```

#### 7.3.2 Guard Block (Conditional)

**bada Source:**
```
(x > 0)<
    println("positive");
>
```

**Generated IR:**
```
%t1 = load x
%t2 = const i32 0
%t3 = gt %t1, %t2
br %t3, L_then, L_end

label L_then
%t4 = const ptr "positive"
call println, %t4
jmp L_end

label L_end
```

#### 7.3.3 For-Each Loop

**bada Source:**
```
(Integer num: arr)<
    println(num);
>
```

**Generated IR:**
```
%t1 = load arr
%t2 = array_len %t1
%t3 = const i32 0
store %t3, __idx

label L_loop
%t4 = load __idx
%t5 = lt %t4, %t2
br %t5, L_body, L_end

label L_body
%t6 = array_get %t1, %t4
store %t6, num
call println, num
%t7 = load __idx
%t8 = add %t7, 1
store %t8, __idx
jmp L_loop

label L_end
```

#### 7.3.4 Switch Block

**bada Source:**
```
(value)<
    1,[
        println("one");
    ]
    2,[
        println("two");
    ]
>
```

**Generated IR:**
```
%t1 = load value
%t2 = const i32 1
%t3 = eq %t1, %t2
br %t3, L_case1, L_check2

label L_check2
%t4 = const i32 2
%t5 = eq %t1, %t4
br %t5, L_case2, L_end

label L_case1
%t6 = const ptr "one"
call println, %t6
jmp L_end

label L_case2
%t7 = const ptr "two"
call println, %t7
jmp L_end

label L_end
```

### 7.4 Lambda Translation

**bada Source:**
```
arr.filter((value)=> <
    Boolean b = value.equals("Hi");
    return b;
>);
```

**Generated IR:**
```
// Lambda becomes a separate function
func __lambda_0(value: ptr) -> bool {
    %t1 = call string_equals, value, "Hi"
    store %t1, b
    ret %t1
}

// In the calling function
%t1 = load arr
%t2 = const ptr __lambda_0
call array_filter, %t1, %t2
```

### 7.5 Array Operations Translation

**bada Source:**
```
arr.contains(10);
arr.add(2);
Integer s = arr.find(2);
Integer s = arr.size();
Integer getI = arr.get(1);
arr.remove(1);
```

**Generated IR:**
```
%t1 = load arr
%t2 = const i32 10
call array_contains, %t1, %t2

%t3 = load arr
%t4 = const i32 2
call array_add, %t3, %t4

%t5 = load arr
%t6 = const i32 2
%t7 = call array_find, %t5, %t6
store %t7, s

%t8 = load arr
%t9 = call array_size, %t8
store %t9, s

%t10 = load arr
%t11 = const i32 1
%t12 = call array_get, %t10, %t11
store %t12, getI

%t13 = load arr
%t14 = const i32 1
call array_remove, %t13, %t14
```

---

## 8. IR Optimization Passes

### 8.1 Optimization Philosophy

After AST → IR translation, the IR undergoes several optimization passes to improve performance and reduce code size.

### 8.2 Optimization Passes

#### 8.2.1 Constant Folding

Evaluate constant expressions at compile time.

**Before:**
```
%t1 = const i32 10
%t2 = const i32 20
%t3 = add %t1, %t2
```

**After:**
```
%t3 = const i32 30
```

#### 8.2.2 Constant Propagation

Replace variables with their known constant values.

**Before:**
```
%t1 = const i32 10
store %t1, x
%t2 = load x
%t3 = add %t2, 5
```

**After:**
```
%t1 = const i32 10
store %t1, x
%t3 = const i32 15
```

#### 8.2.3 Dead Code Elimination

Remove instructions whose results are never used.

**Before:**
```
%t1 = add a, b    ; never used
%t2 = mul c, d    ; used below
store %t2, result
```

**After:**
```
%t2 = mul c, d
store %t2, result
```

#### 8.2.4 Common Subexpression Elimination

Reuse computed values instead of recalculating.

**Before:**
```
%t1 = add a, b
%t2 = add a, b
%t3 = mul %t1, %t2
```

**After:**
```
%t1 = add a, b
%t3 = mul %t1, %t1
```

#### 8.2.5 Loop Invariant Code Motion

Move computations outside loops if they don't change.

**Before:**
```
label L_loop
%t1 = load x
%t2 = mul %t1, 10   ; x doesn't change in loop
%t3 = add i, %t2
```

**After:**
```
%t1 = load x
%t2 = mul %t1, 10   ; moved outside loop

label L_loop
%t3 = add i, %t2
```

#### 8.2.6 Array Access Optimization

Optimize repeated array accesses.

**Before:**
```
%t1 = array_get arr, i
%t2 = add %t1, 1
array_set arr, i, %t2
%t3 = array_get arr, i  ; redundant load
```

**After:**
```
%t1 = array_get arr, i
%t2 = add %t1, 1
array_set arr, i, %t2
%t3 = %t2  ; reuse previous value
```

### 8.3 SSA Construction

For advanced optimizations, the IR can be converted to Static Single Assignment form:

**Before SSA:**
```
x = 10
x = x + 5
y = x * 2
```

**After SSA:**
```
x1 = 10
x2 = add x1, 5
y1 = mul x2, 2
```

### 8.4 Optimization Pipeline

```
IR (from AST)
    ↓
Constant Folding
    ↓
Constant Propagation
    ↓
Dead Code Elimination
    ↓
Common Subexpression Elimination
    ↓
Loop Invariant Code Motion
    ↓
Array Access Optimization
    ↓
(Optional) SSA Construction
    ↓
Optimized IR
```

---

## 9. Code Generation

### 9.1 Code Generation Strategy

The code generator translates optimized IR into target-specific assembly. For bada, the primary target is x86-64 assembly.

```cpp
class CodeGenerator {
public:
    std::string generate(const IRModule& module);

private:
    void emitFunction(const IRFunction& func);
    void emitBlock(const IRBasicBlock& block);
    void emitInstruction(const IRInstruction& inst);

    // Helper methods
    std::string register_for_value(const std::string& value);
    std::string assembly_type(IRType type);
    void emit_prologue(const IRFunction& func);
    void emit_epilogue(const IRFunction& func);

    // State
    std::ostringstream output_;
    std::unordered_map<std::string, std::string> value_locations_;
    int label_counter_;
};
```

### 9.2 x86-64 Calling Convention

The bada compiler uses the System V AMD64 ABI:

| Parameter | Register |
|-----------|----------|
| 1st argument | `rdi` |
| 2nd argument | `rsi` |
| 3rd argument | `rdx` |
| 4th argument | `rcx` |
| 5th argument | `r8` |
| 6th argument | `r9` |
| Return value | `rax` |

### 9.3 Register Allocation

The code generator uses a simple register allocation strategy:

**Caller-Saved Registers:** `rax`, `rcx`, `rdx`, `rsi`, `rdi`, `r8`, `r9`, `r10`, `r11`

**Callee-Saved Registers:** `rbx`, `rbp`, `r12`, `r13`, `r14`, `r15`

**Allocation Strategy:**
1. Use caller-saved registers for temporaries
2. Spill to stack when registers are exhausted
3. Save/restore callee-saved registers in function prologue/epilogue

### 9.4 Instruction Mapping

#### 9.4.1 Arithmetic Instructions

| IR Instruction | x86-64 Assembly |
|----------------|-----------------|
| `add t1, t2, t3` | `mov rax, t2` / `add rax, t3` / `mov t1, rax` |
| `sub t1, t2, t3` | `mov rax, t2` / `sub rax, t3` / `mov t1, rax` |
| `mul t1, t2, t3` | `mov rax, t2` / `imul rax, t3` / `mov t1, rax` |
| `div t1, t2, t3` | `mov rax, t2` / `cqo` / `idiv t3` / `mov t1, rax` |
| `neg t1, t2` | `mov rax, t2` / `neg rax` / `mov t1, rax` |

#### 9.4.2 Comparison Instructions

| IR Instruction | x86-64 Assembly |
|----------------|-----------------|
| `eq t1, t2, t3` | `mov rax, t2` / `cmp rax, t3` / `sete al` / `movzx t1, al` |
| `ne t1, t2, t3` | `mov rax, t2` / `cmp rax, t3` / `setne al` / `movzx t1, al` |
| `lt t1, t2, t3` | `mov rax, t2` / `cmp rax, t3` / `setl al` / `movzx t1, al` |
| `gt t1, t2, t3` | `mov rax, t2` / `cmp rax, t3` / `setg al` / `movzx t1, al` |

#### 9.4.3 Control Flow Instructions

| IR Instruction | x86-64 Assembly |
|----------------|-----------------|
| `label L` | `L:` |
| `jmp L` | `jmp L` |
| `br cond, L1, L2` | `test cond, cond` / `jne L1` / `jmp L2` |
| `ret` | `leave` / `ret` |
| `call func, args` | Move args to registers / `call func` |

#### 9.4.4 Memory Instructions

| IR Instruction | x86-64 Assembly |
|----------------|-----------------|
| `load t1, addr` | `mov rax, [addr]` / `mov t1, rax` |
| `store t1, addr` | `mov rax, t1` / `mov [addr], rax` |
| `alloc type` | `call malloc` |

### 9.5 Function Prologue/Epilogue

**Prologue:**
```assembly
func_name:
    push rbp
    mov rbp, rsp
    sub rsp, <local_stack_size>
    ; Save callee-saved registers
    push rbx
    push r12
    push r13
    push r14
    push r15
```

**Epilogue:**
```assembly
    ; Restore callee-saved registers
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    leave
    ret
```

---

## 10. Target Backend: x86-64 Assembly

### 10.1 Data Representation

| bada Type | x86-64 Representation |
|-----------|----------------------|
| `Integer` | `rax` (64-bit, but value is 32-bit) |
| `Long` | `rax` (64-bit) |
| `Double` | `xmm0` (64-bit floating point) |
| `Boolean` | `al` (8-bit, 0 or 1) |
| `String` | `rdi` (pointer to string data) |
| `Array<T>` | `rdi` (pointer to array struct) |
| Class reference | `rdi` (pointer to object) |

### 10.2 Array Structure in Memory

```
Array Struct:
┌─────────────────┐
│ capacity (i64)  │ 8 bytes
├─────────────────┤
│ length (i64)    │ 8 bytes
├─────────────────┤
│ element_size    │ 8 bytes
├─────────────────┤
│ data* (ptr)     │ 8 bytes
└─────────────────┘
     ↓
┌─────────────────┐
│ element 0       │
├─────────────────┤
│ element 1       │
├─────────────────┤
│ ...             │
├─────────────────┤
│ element n-1     │
└─────────────────┘
```

### 10.3 Runtime Functions

The compiler relies on a runtime library for common operations:

```assembly
; String operations
extern print
extern println
extern string_equals
extern string_concat

; Array operations
extern array_new
extern array_get
extern array_set
extern array_push
extern array_contains
extern array_find
extern array_size
extern array_remove
extern array_filter
extern array_sort
extern array_join

; Memory management
extern malloc
extern free
extern realloc

; File operations (for FileRead trait)
extern file_read
extern file_write
```

### 10.4 Complete Example: bada → Assembly

**bada Source:**
```
Sample->
    main{} -->
        Integer x = 10;
        Integer y = 20;
        Integer result = x + y;
        println(result);
    []<--
<-
```

**Generated x86-64 Assembly:**
```assembly
section .data
    fmt_int db "%ld", 0
    newline db 10, 0

section .text
    global main
    extern println

main:
    ; Prologue
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; Integer x = 10
    mov rax, 10
    mov [rbp-8], rax        ; x

    ; Integer y = 20
    mov rax, 20
    mov [rbp-16], rax       ; y

    ; Integer result = x + y
    mov rax, [rbp-8]        ; load x
    mov rbx, [rbp-16]       ; load y
    add rax, rbx
    mov [rbp-24], rax       ; result

    ; println(result)
    mov rdi, [rbp-24]       ; first arg = result
    call println

    ; Return
    mov rax, 0              ; return 0
    leave
    ret
```

---

## 11. Runtime System

### 11.1 Runtime Components

The bada runtime system provides:

1. **Memory Management**: Dynamic allocation for arrays and objects
2. **String Operations**: String manipulation and comparison
3. **Array Operations**: Dynamic array with automatic resizing
4. **I/O Operations**: Console input/output
5. **Exception Handling**: Error handling for runtime errors
6. **Trait Support**: Method dispatch for inherited methods

### 11.2 Array Runtime Implementation

```cpp
struct ArrayHeader {
    int64_t capacity;
    int64_t length;
    int64_t element_size;
    void* data;
};

ArrayHeader* array_new(int64_t initial_capacity, int64_t element_size) {
    ArrayHeader* arr = (ArrayHeader*)malloc(sizeof(ArrayHeader));
    arr->capacity = initial_capacity;
    arr->length = 0;
    arr->element_size = element_size;
    arr->data = malloc(initial_capacity * element_size);
    return arr;
}

void* array_get(ArrayHeader* arr, int64_t index) {
    if (index < 0 || index >= arr->length) {
        // Runtime error: index out of bounds
        return nullptr;
    }
    return (char*)arr->data + (index * arr->element_size);
}

void array_set(ArrayHeader* arr, int64_t index, void* value) {
    if (index < 0 || index >= arr->length) {
        // Runtime error: index out of bounds
        return;
    }
    memcpy((char*)arr->data + (index * arr->element_size), value, arr->element_size);
}

void array_push(ArrayHeader* arr, void* value) {
    if (arr->length >= arr->capacity) {
        arr->capacity *= 2;
        arr->data = realloc(arr->data, arr->capacity * arr->element_size);
    }
    memcpy((char*)arr->data + (arr->length * arr->element_size), value, arr->element_size);
    arr->length++;
}
```

### 11.3 Lambda/Function Pointer Support

```cpp
typedef int64_t (*LambdaFunction)(void* closure, void** args);

struct Closure {
    LambdaFunction function;
    void** captured_variables;
    int64_t captured_count;
};

int64_t execute_closure(Closure* closure, void** args) {
    return closure->function(closure->captured_variables, args);
}
```

---

## 12. Implementation Details

### 12.1 File Structure

```
compiler/
├── IRGenerator.h          # IR generation interface
├── IRGenerator.cpp        # AST → IR translation
├── IR.h                   # IR data structures
├── IROptimizer.h          # Optimization interface
├── IROptimizer.cpp        # Optimization passes
├── CodeGenerator.h        # Code generation interface
├── CodeGenerator.cpp      # IR → Assembly translation
└── Runtime.h              # Runtime declarations
```

### 12.2 IR Generator Implementation

```cpp
IRModule IRGenerator::generate(const Program& program) {
    for (const auto& cls : program.classes) {
        visitClass(*cls);
    }
    return module_;
}

void IRGenerator::visitClass(const ClassDecl& cls) {
    // Generate IR for each method in the class
    for (const auto& member : cls.members) {
        if (member.kind == ClassMember::Kind::Method) {
            visitMethod(*member.method, cls);
        }
    }
}

void IRGenerator::visitMethod(const MethodDecl& method, const ClassDecl& cls) {
    IRFunction func;
    func.name = cls.name.lexeme + "_" + method.name.lexeme;
    func.return_type = SemanticType_to_IRType(method.return_type);

    // Add parameters
    for (const auto& param : method.parameters) {
        func.parameters.emplace_back(param.name.lexeme,
                                     SemanticType_to_IRType(param.type));
    }

    // Add 'this' parameter for methods
    func.parameters.emplace_back("this", IRType::makePointer());

    current_function_ = &func;
    temp_counter_ = 0;

    // Generate IR for method body
    auto& entry = func.add_block("entry");
    for (const auto& stmt : method.body) {
        visitStatement(*stmt);
    }

    // Add return instruction if needed
    if (func.return_type.kind != IRTypeKind::Void) {
        if (method.returnValue) {
            std::string ret_val = visitExpression(*method.returnValue);
            IRInstruction ret{IROpcode::Ret, func.return_type};
            ret.operands.push_back(ret_val);
            current_block().add_instruction(ret);
        } else {
            IRInstruction ret{IROpcode::Ret, func.return_type};
            current_block().add_instruction(ret);
        }
    }

    module_.functions.push_back(std::move(func));
}
```

### 12.3 Code Generator Implementation

```cpp
std::string CodeGenerator::generate(const IRModule& module) {
    output_.str("");
    output_.clear();

    // Emit data section
    emit_data_section(module);

    // Emit text section
    output_ << "section .text" << std::endl;
    output_ << "global main" << std::endl;

    // Emit external function declarations
    for (const auto& func_name : runtime_functions_) {
        output_ << "extern " << func_name << std::endl;
    }
    output_ << std::endl;

    // Emit each function
    for (const auto& func : module.functions) {
        emitFunction(func);
    }

    return output_.str();
}

void CodeGenerator::emitFunction(const IRFunction& func) {
    output_ << func.name << ":" << std::endl;

    // Prologue
    output_ << "    push rbp" << std::endl;
    output_ << "    mov rbp, rsp" << std::endl;

    // Calculate local variable space
    int64_t local_size = func.local_variables.size() * 8;
    if (local_size > 0) {
        output_ << "    sub rsp, " << local_size << std::endl;
    }

    // Assign stack locations to parameters
    for (size_t i = 0; i < func.parameters.size(); ++i) {
        const std::string& param_name = func.parameters[i].first;
        const std::string& reg = get_parameter_register(i);
        output_ << "    mov [rbp-" << (8 * (i + 1)) << "], " << reg << std::endl;
        value_locations_[param_name] = "[rbp-" + std::to_string(8 * (i + 1)) + "]";
    }

    // Emit each basic block
    for (const auto& block : func.blocks) {
        emitBlock(block);
    }

    // Epilogue (if not already terminated)
    if (!func.blocks.back().is_terminated()) {
        output_ << "    mov rax, 0" << std::endl;
        output_ << "    leave" << std::endl;
        output_ << "    ret" << std::endl;
    }
    output_ << std::endl;
}
```

---

## 13. Examples

### 13.1 Example 1: Simple Arithmetic

**bada Source:**
```
Math->
    calculate{} -->
        Integer a = 10;
        Integer b = 20;
        Integer sum = a + b;
        Integer product = sum * 2;
        println(product);
    []<--
<-
```

**Generated IR:**
```
func Math_calculate(this: ptr) -> void {
entry:
    %t1 = const i32 10
    store %t1, a

    %t2 = const i32 20
    store %t2, b

    %t3 = load a
    %t4 = load b
    %t5 = add %t3, %t4
    store %t5, sum

    %t6 = load sum
    %t7 = const i32 2
    %t8 = mul %t6, %t7
    store %t8, product

    %t9 = load product
    call println, %t9

    ret
}
```

### 13.2 Example 2: Array Operations

**bada Source:**
```
ArrayDemo->
    demo{} -->
        Integer[] arr = {10, 20, 30, 40};
        arr.contains(20);
        Integer s = arr.size();
        Integer idx = arr.find(30);
        println(s);
        println(idx);
    []<--
<-
```

**Generated IR:**
```
func ArrayDemo_demo(this: ptr) -> void {
entry:
    %t1 = array_new i32, 4
    %t2 = const i32 10
    array_set %t1, 0, %t2
    %t3 = const i32 20
    array_set %t1, 1, %t3
    %t4 = const i32 30
    array_set %t1, 2, %t4
    %t5 = const i32 40
    array_set %t1, 3, %t5
    store %t1, arr

    %t6 = load arr
    %t7 = const i32 20
    call array_contains, %t6, %t7

    %t8 = load arr
    %t9 = call array_size, %t8
    store %t9, s

    %t10 = load arr
    %t11 = const i32 30
    %t12 = call array_find, %t10, %t11
    store %t12, idx

    %t13 = load s
    call println, %t13

    %t14 = load idx
    call println, %t14

    ret
}
```

### 13.3 Example 3: Lambda with Filter

**bada Source:**
```
FilterDemo->
    demo{} -->
        Integer[] arr = {1, 2, 3, 4, 5};
        Integer[] filtered = arr.filter((value)=> <
            Boolean b = value > 2;
            return b;
        >);
        println(filtered.size());
    []<--
<-
```

**Generated IR:**
```
func __lambda_0(this: ptr, value: i32) -> bool {
entry:
    %t1 = load value
    %t2 = const i32 2
    %t3 = gt %t1, %t2
    store %t3, b
    ret %t3
}

func FilterDemo_demo(this: ptr) -> void {
entry:
    %t1 = array_new i32, 5
    ; ... initialize array ...
    store %t1, arr

    %t2 = load arr
    %t3 = const ptr __lambda_0
    %t4 = call array_filter, %t2, %t3
    store %t4, filtered

    %t5 = load filtered
    %t6 = call array_size, %t5
    call println, %t6

    ret
}
```

### 13.4 Example 4: Guard Block

**bada Source:**
```
GuardDemo->
    demo{} -->
        Integer x = 10;
        (x > 5)<
            println("x is greater than 5");
        >
        (x <= 5)<
            println("x is not greater than 5");
        >
    []<--
<-
```

**Generated IR:**
```
func GuardDemo_demo(this: ptr) -> void {
entry:
    %t1 = const i32 10
    store %t1, x

    %t2 = load x
    %t3 = const i32 5
    %t4 = gt %t2, %t3
    br %t4, L_then_1, L_end_1

L_then_1:
    %t5 = const ptr "x is greater than 5"
    call println, %t5
    jmp L_end_1

L_end_1:
    %t6 = load x
    %t7 = const i32 5
    %t8 = le %t6, %t7
    br %t8, L_then_2, L_end_2

L_then_2:
    %t9 = const ptr "x is not greater than 5"
    call println, %t9
    jmp L_end_2

L_end_2:
    ret
}
```

---

## 14. Future Enhancements

### 14.1 Advanced Optimizations

1. **Loop Unrolling**: Unroll small loops for better performance
2. **Function Inlining**: Inline small functions to reduce call overhead
3. **Dead Store Elimination**: Remove stores that are immediately overwritten
4. **Copy Propagation**: Replace copies with original values
5. **Global Value Numbering**: Identify equivalent expressions globally

### 14.2 Multi-Target Support

1. **ARM64 Backend**: Generate ARM64 assembly for Apple Silicon
2. **WebAssembly Backend**: Generate Wasm for web deployment
3. **LLVM Backend**: Use LLVM for advanced optimization and multi-target support
4. **JIT Compilation**: Compile and execute at runtime

### 14.3 Debugging Support

1. **DWARF Debug Info**: Generate debug information for debuggers
2. **Source Maps**: Map IR/assembly back to original bada source
3. **IR Dumping**: Allow dumping IR at various stages
4. **Profiling**: Add instrumentation for performance profiling

### 14.4 Language Features

1. **Garbage Collection**: Automatic memory management
2. **Exception Handling**: Try/catch blocks
3. **Generics**: Type-parameterized classes and methods
4. **Concurrency**: Thread support and synchronization primitives
5. **Pattern Matching**: Advanced pattern matching syntax

### 14.5 Tooling

1. **IR Visualizer**: Graphical visualization of IR control flow
2. **Performance Analyzer**: Identify bottlenecks in generated code
3. **Interactive Debugger**: Step through IR execution
4. **Benchmarking Suite**: Compare optimization strategies

---

## Appendix A: Complete IR Instruction Reference

| Category | Opcode | Operands | Result | Description |
|----------|--------|----------|--------|-------------|
| Arithmetic | Add | val, val | val | Integer addition |
| Arithmetic | Sub | val, val | val | Integer subtraction |
| Arithmetic | Mul | val, val | val | Integer multiplication |
| Arithmetic | Div | val, val | val | Integer division |
| Arithmetic | Mod | val, val | val | Integer modulo |
| Arithmetic | Neg | val | val | Integer negation |
| Comparison | EQ | val, val | bool | Equal comparison |
| Comparison | NE | val, val | bool | Not equal comparison |
| Comparison | LT | val, val | bool | Less than comparison |
| Comparison | LE | val, val | bool | Less or equal comparison |
| Comparison | GT | val, val | bool | Greater than comparison |
| Comparison | GE | val, val | bool | Greater or equal comparison |
| Logical | And | bool, bool | bool | Logical AND |
| Logical | Or | bool, bool | bool | Logical OR |
| Logical | Not | bool | bool | Logical NOT |
| Control | Label | name | - | Define label |
| Control | Jmp | label | - | Unconditional jump |
| Control | Branch | bool, label, label | - | Conditional branch |
| Control | Ret | [val] | - | Return from function |
| Control | Call | func, args... | val | Function call |
| Memory | Load | ptr | val | Load from memory |
| Memory | Store | val, ptr | - | Store to memory |
| Memory | Alloc | type, count | ptr | Allocate memory |
| Memory | Alloca | type, count | ptr | Stack allocation |
| Array | ArrayNew | type, size | ptr | Create array |
| Array | ArrayGet | ptr, idx | val | Get array element |
| Array | ArraySet | ptr, idx, val | - | Set array element |
| Array | ArrayLen | ptr | val | Get array length |
| Array | ArrayPush | ptr, val | - | Append to array |
| Conversion | ZExt | val, type | val | Zero extend |
| Conversion | SExt | val, type | val | Sign extend |
| Conversion | FPToUI | val, type | val | Float to uint |
| Conversion | UIToFP | val, type | val | Uint to float |

---

## Appendix B: bada to IR Type Mapping

| bada Type | IR Type | Size | Notes |
|-----------|---------|------|-------|
| `Integer` | `i32` | 4 bytes | 32-bit signed integer |
| `Long` | `i64` | 8 bytes | 64-bit signed integer |
| `Double` | `f64` | 8 bytes | 64-bit IEEE 754 float |
| `Boolean` | `bool` | 1 byte | 0 or 1 |
| `String` | `ptr` | 8 bytes | Pointer to string data |
| `T[]` | `array<T>` | 32 bytes + data | Array header + elements |
| `Class` | `ptr` | 8 bytes | Pointer to object |
| `void` | `void` | 0 bytes | No return value |

---

## Appendix C: Generated Assembly Template

```assembly
; Standard template for bada programs
section .data
    ; Constants and string literals go here

section .bss
    ; Uninitialized data goes here

section .text
    global main
    extern println, print, malloc, free
    extern array_new, array_get, array_set, array_push
    extern array_contains, array_find, array_size, array_remove
    extern string_equals, string_concat

main:
    ; Program entry point
    push rbp
    mov rbp, rsp
    ; ... program code ...
    mov rax, 0
    leave
    ret

; Generated functions follow
```

---

## Conclusion

The Intermediate Representation and Code Generation phases are critical components of the bada compiler. The IR provides a clean, optimizable representation of the program that bridges the gap between high-level bada syntax and low-level machine code. The code generator then translates this IR into efficient x86-64 assembly, leveraging the System V AMD64 ABI for function calls and a runtime library for common operations.

Future work includes expanding the optimization pipeline, adding support for multiple target architectures, and implementing advanced language features like garbage collection and concurrency.