%include "macros.inc"

global PrimLit
global PrimFloorDiv
global PrimPow
global PrimLocalGet
global PrimLocalSet
global PrimEnter
global PrimReturn
global PrimNoReturn
global PrimSayBool
global PrimBoolToText
global PrimAdd
global PrimSub
global PrimMul
global PrimDiv
global PrimMod
global PrimDup
global PrimDup2
global PrimDrop
global PrimSwap
global PrimPrint
global PrimSayStr
global PrimBye
global PrimCall
global PrimExit
global PrimCallValue
global PrimTry
global PrimTryEnd
global PrimLastError
global TryDepth
global TryStack
global LastError
global PrimBranch
global PrimBranch0
global PrimFetch
global PrimStore
global PrimToR
global PrimFromR
global PrimAnd
global PrimOr
global PrimLess
global PrimGreater
global PrimEq
global PrimNotEq
global PrimLessEq
global PrimGreaterEq
extern PrintNumber
extern PrintNewLine
extern PrintString
extern ExitProcess
extern Abort
extern DataStackEnd
extern ReturnStackEnd

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

section .data
ErrDivZero     db "can't divide by 0"
ErrDivZeroLen  equ $ - ErrDivZero
align 8
NoError dq 0
ErrOverflow    db "too much recursion (the stack is full)"
ErrOverflowLen equ $ - ErrOverflow
ErrNoReturn    db "function ended without a return"
ErrNoReturnLen equ $ - ErrNoReturn
TrueWord       db "true"
FalseWord      db "false"
align 8
TrueText       dq 4
               db "true"
align 8
FalseText      dq 5
               db "false"

section .bss
TryStack resq 4 * 256
TryDepth resq 1
LastError resq 1

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
    test rbx, rbx
    jz DivZero
    cqo
    idiv rbx
    DPush rax
    NEXT

PrimFloorDiv:
    DPop rbx
    DPop rax
    test rbx, rbx
    jz DivZero
    cqo
    idiv rbx
    test rdx, rdx
    jz .Push
    xor rdx, rbx
    jns .Push
    dec rax
.Push:
    DPush rax
    NEXT

PrimMod:
    DPop rbx
    DPop rax
    test rbx, rbx
    jz DivZero
    cqo
    idiv rbx
    test rdx, rdx
    jz .Push
    mov rcx, rdx
    xor rcx, rbx
    jns .Push
    add rdx, rbx
.Push:
    DPush rdx
    NEXT

DivZero:
    lea rcx, [rel ErrDivZero]
    mov edx, ErrDivZeroLen
    jmp Abort

PrimPow:
    DPop rcx
    DPop rax
    mov ebx, 1
    test rcx, rcx
    jns .Loop
    xor ebx, ebx
    jmp .Done
.Loop:
    test rcx, rcx
    jz .Done
    test rcx, 1
    jz .Square
    imul rbx, rax
.Square:
    imul rax, rax
    shr rcx, 1
    jmp .Loop
.Done:
    DPush rbx
    NEXT

PrimAnd:
    DPop rax
    DPop rbx
    and rbx, rax
    DPush rbx
    NEXT

PrimOr:
    DPop rax
    DPop rbx
    or rbx, rax
    DPush rbx
    NEXT

PrimDup:
    mov rax, [r15-8]
    DPush rax
    NEXT

PrimDup2:
    mov rax, [r15-16]
    mov rbx, [r15-8]
    DPush rax
    DPush rbx
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

PrimSayStr:
    mov rcx, [r14]
    mov rdx, [r14+8]
    add r14, 16
    call PrintString
    call PrintNewLine
    NEXT

PrimBye:
    xor ecx, ecx
    call ExitProcess

PrimCall:
    lea rcx, [rel DataStackEnd - 512]
    cmp r15, rcx
    ja Overflow
    mov rax, [r14]
    add r14, 8
    RPush r14
    mov r14, rax
    NEXT

PrimExit:
    RPop r14
    NEXT

PrimTry:
    mov rax, [rel TryDepth]
    cmp rax, 256
    jae Overflow
    shl rax, 5
    lea rcx, [rel TryStack]
    add rcx, rax
    mov rax, [r14]
    add r14, 8
    mov [rcx], rax
    mov [rcx + 8], r15
    mov [rcx + 16], rbp
    mov [rcx + 24], r13
    inc qword [rel TryDepth]
    NEXT

PrimTryEnd:
    dec qword [rel TryDepth]
    NEXT

PrimLastError:
    mov rax, [rel LastError]
    test rax, rax
    jnz .Have
    lea rax, [rel NoError]
.Have:
    DPush rax
    NEXT

PrimCallValue:
    lea rcx, [rel DataStackEnd - 512]
    cmp r15, rcx
    ja Overflow
    mov rcx, [r14]
    add r14, 8
    lea rdx, [rcx * 8 + 8]
    mov rax, r15
    sub rax, rdx
    mov rbx, [rax]
.Shift:
    test rcx, rcx
    jz .Shifted
    mov rdx, [rax + 8]
    mov [rax], rdx
    add rax, 8
    dec rcx
    jmp .Shift
.Shifted:
    sub r15, 8
    RPush r14
    mov r14, rbx
    NEXT

PrimEnter:
    mov rcx, [r14]
    add r14, 8
    RPush r13
    mov r13, rbp
    lea rdx, [rbp + rcx * 8]
    lea rax, [rel ReturnStackEnd - 64]
    cmp rdx, rax
    ja Overflow
.Clear:
    cmp rbp, rdx
    jae .Done
    mov qword [rbp], 0
    add rbp, 8
    jmp .Clear
.Done:
    NEXT

PrimReturn:
    mov rbp, r13
    RPop r13
    RPop r14
    NEXT

PrimLocalGet:
    mov rax, [r14]
    add r14, 8
    mov rax, [r13 + rax]
    DPush rax
    NEXT

PrimLocalSet:
    mov rax, [r14]
    add r14, 8
    DPop rbx
    mov [r13 + rax], rbx
    NEXT

PrimNoReturn:
    lea rcx, [rel ErrNoReturn]
    mov edx, ErrNoReturnLen
    jmp Abort

Overflow:
    lea rcx, [rel ErrOverflow]
    mov edx, ErrOverflowLen
    jmp Abort

PrimSayBool:
    DPop rax
    lea rcx, [rel TrueWord]
    mov edx, 4
    test rax, rax
    jnz .Print
    lea rcx, [rel FalseWord]
    mov edx, 5
.Print:
    call PrintString
    call PrintNewLine
    NEXT

PrimBoolToText:
    DPop rax
    lea rbx, [rel TrueText]
    test rax, rax
    jnz .Push
    lea rbx, [rel FalseText]
.Push:
    DPush rbx
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

PrimToR:
    DPop rax
    RPush rax
    NEXT

PrimFromR:
    RPop rax
    DPush rax
    NEXT

CmpPrim PrimLess, setl
CmpPrim PrimGreater, setg
CmpPrim PrimEq, sete
CmpPrim PrimNotEq, setne
CmpPrim PrimLessEq, setle
CmpPrim PrimGreaterEq, setge
