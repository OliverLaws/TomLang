%include "macros.inc"

global PrimLit
global PrimAdd
global PrimSub
global PrimMul
global PrimDiv
global PrimMod
global PrimDup
global PrimDrop
global PrimSwap
global PrimPrint
global PrimBye
global PrimCall
global PrimExit
global PrimBranch
global PrimBranch0
global PrimFetch
global PrimStore
global PrimLess
global PrimGreater
global PrimEq
global PrimNotEq
global PrimLessEq
global PrimGreaterEq
extern PrintNumber
extern PrintNewLine
extern ExitProcess

%macro CmpPrim 2
%1:
    DPop rax
    DPop rbx
    cmp rbx, rax
    %2 cl
    movzx rcx, cl
    DPush rcx
    NEXT
%endmacro

section .text
PrimLit:
    mov rax, [r14]
    add r14, 8
    DPush rax
    NEXT

PrimAdd:
    DPop rax
    DPop rbx
    add rbx, rax
    DPush rbx
    NEXT

PrimSub:
    DPop rax
    DPop rbx
    sub rbx, rax
    DPush rbx
    NEXT

PrimMul:
    DPop rax
    DPop rbx
    imul rbx, rax
    DPush rbx
    NEXT

PrimDiv:
    DPop rbx
    DPop rax
    cqo
    idiv rbx
    DPush rax
    NEXT

PrimMod:
    DPop rbx
    DPop rax
    cqo
    idiv rbx
    DPush rdx
    NEXT

PrimDup:
    mov rax, [r15-8]
    DPush rax
    NEXT

PrimDrop:
    sub r15, 8
    NEXT

PrimSwap:
    mov rax, [r15-8]
    mov rbx, [r15-16]
    mov [r15-8], rbx
    mov [r15-16], rax
    NEXT

PrimPrint:
    DPop rcx
    call PrintNumber
    call PrintNewLine
    NEXT

PrimBye:
    xor ecx, ecx
    call ExitProcess

PrimCall:
    mov rax, [r14]
    add r14, 8
    RPush r14
    mov r14, rax
    NEXT

PrimExit:
    RPop r14
    NEXT

PrimBranch:
    mov r14, [r14]
    NEXT

PrimBranch0:
    DPop rax
    test rax, rax
    jz PrimBranch
    add r14, 8
    NEXT

PrimFetch:
    DPop rax
    mov rax, [rax]
    DPush rax
    NEXT

PrimStore:
    DPop rax
    DPop rbx
    mov [rax], rbx
    NEXT

CmpPrim PrimLess, setl
CmpPrim PrimGreater, setg
CmpPrim PrimEq, sete
CmpPrim PrimNotEq, setne
CmpPrim PrimLessEq, setle
CmpPrim PrimGreaterEq, setge