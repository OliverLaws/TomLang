%include "macros.inc"

global Start

extern InitIO
extern PrintString
extern ExitProcess
extern InitStack
extern PrintNumber
extern PrintNewLine
extern ReadLine
extern InputBuf
extern SetInput
extern NextToken
extern ParseNumber
extern DataStack
extern ReturnStack
extern FindWord
extern CodeBuf
extern Here
extern Compile
extern DictHere
extern SavedHere
extern CreateEntry
extern PrimLit
extern PrimCall
extern PrimExit

section .data
Prompt       db "> "
PromptLen    equ $ - Prompt
Underflow    db "stack underflow", 10
UnderflowLen equ $ - Underflow
Unknown      db " ?", 10
UnknownLen   equ $ - Unknown

section .text
Start:
    sub rsp, 40
    call InitIO
    call InitStack
Repl:
    lea rcx, [rel Prompt]
    mov rdx, PromptLen
    call PrintString
    call ReadLine
    lea rcx, [rel InputBuf]
    mov rdx, rax
    call SetInput
    lea rax, [rel CodeBuf]
    mov [rel Here], rax
.Tokens:
    call NextToken
    test rdx, rdx
    jz .Run
    mov r12, rax
    mov r13, rdx
    cmp rdx, 1
    jne .NotSpecial
    cmp byte [rax], ':'
    je .Define
    cmp byte [rax], ';'
    je .EndDefine
.NotSpecial:
    mov rcx, rax
    call ParseNumber
    test rdx, rdx
    jz .Word
    mov rbx, rax
    lea rcx, [rel PrimLit]
    call Compile
    mov rcx, rbx
    call Compile
    jmp .Tokens
.Word:
    mov rcx, r12
    mov rdx, r13
    call FindWord
    test rax, rax
    jz .Unknown
    cmp rdx, 2
    je .Immediate
    test rdx, rdx
    jz .Prim
    mov rbx, rax
    lea rcx, [rel PrimCall]
    call Compile
    mov rcx, rbx
    call Compile
    jmp .Tokens
.Immediate:
    call rax
    jmp .Tokens
.Prim:
    mov rcx, rax
    call Compile
    jmp .Tokens
.Unknown:
    mov rcx, r12
    mov rdx, r13
    call PrintString
    lea rcx, [rel Unknown]
    mov rdx, UnknownLen
    call PrintString
    jmp Repl
.Define:
    mov rax, [rel Here]
    mov [rel SavedHere], rax
    mov rax, [rel DictHere]
    mov [rel Here], rax
    call NextToken
    test rdx, rdx
    jz Repl
    mov rcx, rax
    call CreateEntry
    jmp .Tokens
.EndDefine:
    lea rcx, [rel PrimExit]
    call Compile
    mov rax, [rel Here]
    mov [rel DictHere], rax
    mov rax, [rel SavedHere]
    mov [rel Here], rax
    jmp .Tokens
.Run:
    lea rbp, [rel ReturnStack]
    lea rcx, [rel LineDone]
    call Compile
    lea r14, [rel CodeBuf]
    NEXT

LineDone:
    lea rax, [rel DataStack]
    cmp r15, rax
    jae Repl
    lea rcx, [rel Underflow]
    mov rdx, UnderflowLen
    call PrintString
    call InitStack
    jmp Repl