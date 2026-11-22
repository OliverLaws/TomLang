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
global PrimFail
global PrimPushFrame
global PrimLinkGet
global PrimLinkSet
global PrimMissingFn
global PrimCall
global PrimExit
global PrimCallValue
global PrimMakeClosure
extern Alloc
global PrimTry
global PrimTryEnd
global PrimLastError
global TryDepth
global FfiVmDepth
global CbDepth
global FfiVmStack
global CbRspStack
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
ErrMissingFn   db "this function was never finished (its definition has a mistake)"
ErrMissingFnLen equ $ - ErrMissingFn
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
TryStack resq 8 * 256
FfiVmDepth resq 1
CbDepth resq 1
FfiVmStack resq 3 * 256
CbRspStack resq 256
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
    cmp rbx, -1
    je .MinusOne
    cqo
    idiv rbx
    DPush rax
    NEXT
.MinusOne:
    neg rax
    DPush rax
    NEXT

PrimFloorDiv:
    DPop rbx
    DPop rax
    test rbx, rbx
    jz DivZero
    cmp rbx, -1
    je .MinusOne
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
.MinusOne:
    neg rax
    DPush rax
    NEXT

PrimMod:
    DPop rbx
    DPop rax
    test rbx, rbx
    jz DivZero
    cmp rbx, -1
    je .MinusOne
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
.MinusOne:
    DPush 0
    NEXT

PrimMissingFn:
    lea rcx, [rel ErrMissingFn]
    mov edx, ErrMissingFnLen
    jmp Abort

PrimFail:
    mov rax, [r15 - 8]
    lea rcx, [rax + 8]
    mov rdx, [rax]
    jmp Abort

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
    and rsp, -16
    sub rsp, 32
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
    shl rax, 6
    lea rcx, [rel TryStack]
    add rcx, rax
    mov rax, [r14]
    add r14, 8
    mov [rcx], rax
    mov [rcx + 8], r15
    mov [rcx + 16], rbp
    mov [rcx + 24], r13
    mov rax, [rel FfiVmDepth]
    mov [rcx + 32], rax
    mov rax, [rel CbDepth]
    mov [rcx + 40], rax
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
    push rbx
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
    pop rbx
    test rbx, 1
    jz .Call
    dec rbx
    mov rcx, [rbx + 8]
    lea rdx, [rbx + 16]
.Caps:
    test rcx, rcx
    jz .CapsDone
    mov rax, [rdx]
    DPush rax
    add rdx, 8
    dec rcx
    jmp .Caps
.CapsDone:
    mov rbx, [rbx]
.Call:
    RPush r14
    mov r14, rbx
    NEXT

PrimMakeClosure:
    DPop rcx
    DPop rbx
    push rcx
    lea rcx, [rcx * 8 + 16]
    call Alloc
    pop rcx
    mov [rax], rbx
    mov [rax + 8], rcx
    mov rdx, rcx
    shl rdx, 3
    sub r15, rdx
    xor edx, edx
.Copy:
    cmp rdx, rcx
    jae .Done
    mov r8, [r15 + rdx * 8]
    mov [rax + 16 + rdx * 8], r8
    inc rdx
    jmp .Copy
.Done:
    inc rax
    DPush rax
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

PrimPushFrame:
    DPush r13
    NEXT

PrimLinkGet:
    mov rax, [r14]
    mov rcx, [r14 + 8]
    add r14, 16
    mov rax, [r13 + rax]
    mov rax, [rax + rcx]
    DPush rax
    NEXT

PrimLinkSet:
    mov rax, [r14]
    mov rcx, [r14 + 8]
    add r14, 16
    mov rax, [r13 + rax]
    DPop rbx
    mov [rax + rcx], rbx
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
