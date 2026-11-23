%include "macros.inc"
extern TryStackPtr
extern GilDrop
extern GilYield

global PrimLit
global PrimFloorDiv
global PrimPow
global PrimLocalGet
global PrimLocalSet
global PrimEnter
extern DataLimit
extern ReturnLimit
global PrimEnterArgs
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
global PrimDPow
global PrimPushFrame
global PrimBox
global PrimUnbox
global PrimTagIs
global PrimGetG
global PrimSetG
global PrimIncG
global PrimIncL
global PrimEnterHeap
global PrimReturnHeap
global PrimFetchOff
global PrimStoreOff
global PrimReorder
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
ErrIsNothing db "this is nothing"
ErrIsNothingLen equ $ - ErrIsNothing
ErrFnUnset db "this function value hasn't been set yet"
ErrFnUnsetLen equ $ - ErrFnUnset
ErrPowBig db "that power is too big for a whole number (use a decimal, like 2.0 ^ 100)"
ErrPowBigLen equ $ - ErrPowBig
ErrPowNeg db "a negative number to a fractional power has no answer"
ErrPowNegLen equ $ - ErrPowNeg
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
    jo PowBig
.Square:
    shr rcx, 1
    jz .Done
    imul rax, rax
    jo PowBig
    jmp .Loop
.Done:
    DPush rbx
    NEXT

PowBig:
    lea rcx, [rel ErrPowBig]
    mov edx, ErrPowBigLen
    jmp Abort

PrimDPow:
    DPop rax
    movq xmm1, rax
    DPop rax
    movq xmm0, rax
    cvttsd2si rcx, xmm1
    cvtsi2sd xmm2, rcx
    ucomisd xmm2, xmm1
    jne .Real
    jp .Real
    mov rdx, rcx
    test rdx, rdx
    jns .AbsOk
    neg rdx
.AbsOk:
    cmp rdx, 4096
    ja .Real
    sub rsp, 16
    fnstcw [rsp + 8]
    mov word [rsp + 10], 0x37F
    fldcw [rsp + 10]
    movsd [rsp], xmm0
    fld1
    fld qword [rsp]
.IntLoop:
    test rdx, rdx
    jz .IntDone
    test rdx, 1
    jz .IntSq
    fmul st1, st0
.IntSq:
    fmul st0, st0
    shr rdx, 1
    jmp .IntLoop
.IntDone:
    fstp st0
    test rcx, rcx
    jns .IntStore
    fld1
    fdivrp st1, st0
.IntStore:
    fstp qword [rsp]
    fldcw [rsp + 8]
    mov rax, [rsp]
    add rsp, 16
    DPush rax
    NEXT
.Real:
    xorpd xmm2, xmm2
    ucomisd xmm0, xmm2
    jb .Negative
    je .Zero
    sub rsp, 24
    fnstcw [rsp + 16]
    mov word [rsp + 18], 0x37F
    fldcw [rsp + 18]
    movsd [rsp], xmm1
    movsd [rsp + 8], xmm0
    fld qword [rsp]
    fld qword [rsp + 8]
    fyl2x
    fld st0
    frndint
    fsub st1, st0
    fxch st1
    f2xm1
    fld1
    faddp st1, st0
    fscale
    fstp st1
    fstp qword [rsp]
    fldcw [rsp + 16]
    mov rax, [rsp]
    add rsp, 24
    DPush rax
    NEXT
.Zero:
    xorpd xmm2, xmm2
    ucomisd xmm1, xmm2
    jb PowBig
    movq rax, xmm2
    DPush rax
    NEXT
.Negative:
    lea rcx, [rel ErrPowNeg]
    mov edx, ErrPowNegLen
    jmp Abort

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
    cmp r15, [rel DataLimit]
    ja Overflow
    cmp qword [rel GilDrop], 0
    jne .Yield
.Go:
    mov rax, [r14]
    add r14, 8
    RPush r14
    lea rcx, [rel PrimEnterArgs]
    cmp [rax], rcx
    jne .Plain
    lea r14, [rax + 8]
    jmp PrimEnterArgs
.Plain:
    mov r14, rax
    NEXT
.Yield:
    call GilYield
    jmp .Go

PrimExit:
    RPop r14
    NEXT

PrimTry:
    mov rax, [rel TryDepth]
    cmp rax, 256
    jae Overflow
    shl rax, 6
    mov rcx, [rel TryStackPtr]
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
    cmp r15, [rel DataLimit]
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
    test rbx, rbx
    jz .Unset
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
.Unset:
    lea rcx, [rel ErrFnUnset]
    mov edx, ErrFnUnsetLen
    jmp Abort

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
    cmp rdx, [rel ReturnLimit]
    ja Overflow
.Clear:
    cmp rbp, rdx
    jae .Done
    mov qword [rbp], 0
    add rbp, 8
    jmp .Clear
.Done:
    NEXT

PrimEnterArgs:
    mov rcx, [r14]
    add r14, 8
    RPush r13
    mov r13, rbp
    lea rdx, [rbp + rcx * 8]
    cmp rdx, [rel ReturnLimit]
    ja Overflow
.Clear:
    cmp rbp, rdx
    jae .Args
    mov qword [rbp], 0
    add rbp, 8
    jmp .Clear
.Args:
    lea rcx, [rel PrimLocalSet]
.ArgLoop:
    cmp [r14], rcx
    jne .Branch
    mov rax, [r14 + 8]
    DPop rdx
    mov [r13 + rax], rdx
    add r14, 16
    jmp .ArgLoop
.Branch:
    lea rcx, [rel PrimBranch]
    cmp [r14], rcx
    jne .Go
    mov r14, [r14 + 8]
.Go:
    NEXT

PrimReturn:
    mov rbp, r13
    RPop r13
    RPop r14
    NEXT

PrimReorder:
    mov rcx, [r14]
    add r14, 8
    mov rax, rcx
    shl rax, 3
    mov rdx, r15
    sub rdx, rax
    sub rsp, 136
    xor r8d, r8d
.Copy:
    cmp r8, rcx
    jae .Copied
    mov rax, [rdx + r8 * 8]
    mov [rsp + r8 * 8], rax
    inc r8
    jmp .Copy
.Copied:
    xor r8d, r8d
.Put:
    cmp r8, rcx
    jae .Done
    mov r9, [r14 + r8 * 8]
    mov rax, [rsp + r9 * 8]
    mov [rdx + r8 * 8], rax
    inc r8
    jmp .Put
.Done:
    add rsp, 136
    lea r14, [r14 + rcx * 8]
    NEXT

PrimEnterHeap:
    mov rcx, [r14]
    add r14, 8
    RPush r13
    cmp rbp, [rel ReturnLimit]
    ja Overflow
    push rcx
    push rcx
    lea rcx, [rcx * 8 + 8]
    call Alloc
    pop rcx
    pop rcx
    xor edx, edx
.Clear:
    cmp rdx, rcx
    jae .Done
    mov qword [rax + rdx * 8], 0
    inc rdx
    jmp .Clear
.Done:
    mov r13, rax
    NEXT

PrimReturnHeap:
    RPop r13
    RPop r14
    NEXT

PrimFetchOff:
    mov rcx, [r14]
    add r14, 8
    mov rax, [r15 - 8]
    mov rax, [rax + rcx]
    mov [r15 - 8], rax
    NEXT

PrimStoreOff:
    mov rcx, [r14]
    add r14, 8
    DPop rax
    DPop rbx
    mov [rax + rcx], rbx
    NEXT

PrimGetG:
    mov rax, [r14]
    add r14, 8
    mov rax, [rax]
    DPush rax
    NEXT

PrimSetG:
    mov rax, [r14]
    add r14, 8
    DPop rbx
    mov [rax], rbx
    NEXT

PrimIncG:
    mov rax, [r14]
    mov rcx, [r14 + 8]
    add r14, 16
    add [rax], rcx
    NEXT

PrimIncL:
    mov rax, [r14]
    mov rcx, [r14 + 8]
    add r14, 16
    add [r13 + rax], rcx
    NEXT

PrimBox:
    mov rcx, [r14]
    add r14, 8
    push rcx
    push rcx
    mov ecx, 16
    call Alloc
    pop rcx
    pop rcx
    mov [rax], rcx
    mov rdx, [r15 - 8]
    mov [rax + 8], rdx
    mov [r15 - 8], rax
    NEXT

PrimUnbox:
    mov rax, [r15 - 8]
    test rax, rax
    jz .Nil
    mov rax, [rax + 8]
    mov [r15 - 8], rax
    NEXT
.Nil:
    lea rcx, [rel ErrIsNothing]
    mov edx, ErrIsNothingLen
    jmp Abort

PrimTagIs:
    mov rcx, [r14]
    add r14, 8
    mov rax, [r15 - 8]
    xor edx, edx
    cmp rcx, 5
    je .Nil
    test rax, rax
    jz .Put
    cmp [rax], rcx
    sete dl
    jmp .Put
.Nil:
    test rax, rax
    sete dl
.Put:
    mov [r15 - 8], rdx
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
