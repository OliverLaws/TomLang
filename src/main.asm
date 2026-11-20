%include "macros.inc"

global Start
global Abort

extern InitIO
extern PrintString
extern ExitProcess
extern InitStack
extern ReadLine
extern InputBuf
extern LoadFileArg
extern SetInput
extern NextToken
extern ParseNumber
extern DataStack
extern ReturnStack
extern FindWord
extern CodeBuf
extern Here
extern Compile
extern BeginDef
extern EndDef
extern OpenBlocks
extern ResetCompiler
extern StmtExpr
extern PrimLit
extern PrimCall
extern PrimExit

section .data
Prompt         db "> "
PromptLen      equ $ - Prompt
More           db ". "
MoreLen        equ $ - More
Underflow      db "stack underflow", 10
UnderflowLen   equ $ - Underflow
Unknown        db " ?", 10
UnknownLen     equ $ - Unknown
MissingEnd     db "missing end", 10
MissingEndLen  equ $ - MissingEnd

section .bss
ReplRsp  resq 1
FileMode resq 1

section .text
Start:
    sub rsp, 40
    mov [rel ReplRsp], rsp
    call InitIO
    call InitStack
    call LoadFileArg
    test rdx, rdx
    jz Repl
    mov qword [rel FileMode], 1
    mov rcx, rax
    call SetInput
    lea rax, [rel CodeBuf]
    mov [rel Here], rax
    jmp Tokens

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

Tokens:
    call NextToken
    test rdx, rdx
    jz .EndInput
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
    CompilePrim PrimLit
    mov rcx, rbx
    call Compile
    jmp Tokens
.Word:
    mov rcx, r12
    mov rdx, r13
    call FindWord
    test rax, rax
    jz .Unknown
    cmp rdx, 2
    je .Immediate
    cmp rdx, 3
    je .Variable
    cmp rdx, 4
    je .Function
    test rdx, rdx
    jz .Prim
    mov rbx, rax
    CompilePrim PrimCall
    mov rcx, rbx
    call Compile
    jmp Tokens
.Prim:
    mov rcx, rax
    call Compile
    jmp Tokens
.Immediate:
    call rax
    jmp Tokens
.Variable:
    call StmtExpr
    jmp Tokens
.Function:
    call StmtExpr
    jmp Tokens
.Unknown:
    mov rcx, r12
    mov rdx, r13
    call PrintString
    lea rcx, [rel Unknown]
    mov rdx, UnknownLen
    jmp Abort
.Define:
    call NextToken
    test rdx, rdx
    jz Tokens
    mov rcx, rax
    call BeginDef
    jmp Tokens
.EndDefine:
    CompilePrim PrimExit
    call EndDef
    jmp Tokens
.EndInput:
    cmp qword [rel OpenBlocks], 0
    je .Run
    cmp qword [rel FileMode], 0
    jne .NoEnd
    lea rcx, [rel More]
    mov rdx, MoreLen
    call PrintString
    call ReadLine
    lea rcx, [rel InputBuf]
    mov rdx, rax
    call SetInput
    jmp Tokens
.NoEnd:
    lea rcx, [rel MissingEnd]
    mov rdx, MissingEndLen
    jmp Abort
.Run:
    lea rbp, [rel ReturnStack]
    CompilePrim LineDone
    lea r14, [rel CodeBuf]
    NEXT

LineDone:
    cmp qword [rel FileMode], 0
    jne .Exit
    lea rax, [rel DataStack]
    cmp r15, rax
    jae Repl
    lea rcx, [rel Underflow]
    mov rdx, UnderflowLen
    call PrintString
    call InitStack
    jmp Repl
.Exit:
    xor ecx, ecx
    call ExitProcess

Abort:
    mov rsp, [rel ReplRsp]
    call PrintString
    cmp qword [rel FileMode], 0
    jne .Exit
    call ResetCompiler
    jmp Repl
.Exit:
    mov ecx, 1
    call ExitProcess
