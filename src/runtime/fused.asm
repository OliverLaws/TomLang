%include "macros.inc"

global FuseTable
global BranchTable
global PrimAndJump
global F_Lit_PrimAdd
global F_Lit_PrimSub
global StoreTable
global F_LocalGet_Lit_PrimAdd
global F_LocalGet_Lit_PrimSub
global F_GetG_Lit_PrimAdd
global F_GetG_Lit_PrimSub
extern PrimAdd
extern PrimConcat
extern PrimDAdd
extern PrimDDiv
extern PrimDEq
extern PrimDFloorDiv
extern PrimDGreater
extern PrimDGreaterEq
extern PrimDLess
extern PrimDLessEq
extern PrimDMod
extern PrimDMul
extern PrimDNotEq
extern PrimDSub
extern PrimDiv
extern PrimEq
extern PrimFloorDiv
extern PrimGetG
extern PrimGreater
extern PrimGreaterEq
extern PrimIndex
extern PrimLess
extern PrimLessEq
extern PrimLit
extern PrimLocalGet
extern PrimLocalSet
extern PrimMod
extern PrimMul
extern PrimNotEq
extern PrimSetG
extern PrimSub
extern PrimTextEq
extern PrimToDec
extern PrimToDecUnder
section .text
PrimLessBr:
    DPop rax
    DPop rbx
    cmp rbx, rax
    jge .No
    add r14, 16
    NEXT
.No:
    mov r14, [r14 + 8]
    NEXT

PrimGreaterBr:
    DPop rax
    DPop rbx
    cmp rbx, rax
    jle .No
    add r14, 16
    NEXT
.No:
    mov r14, [r14 + 8]
    NEXT

PrimEqBr:
    DPop rax
    DPop rbx
    cmp rbx, rax
    jne .No
    add r14, 16
    NEXT
.No:
    mov r14, [r14 + 8]
    NEXT

PrimNotEqBr:
    DPop rax
    DPop rbx
    cmp rbx, rax
    je .No
    add r14, 16
    NEXT
.No:
    mov r14, [r14 + 8]
    NEXT

PrimLessEqBr:
    DPop rax
    DPop rbx
    cmp rbx, rax
    jg .No
    add r14, 16
    NEXT
.No:
    mov r14, [r14 + 8]
    NEXT

PrimGreaterEqBr:
    DPop rax
    DPop rbx
    cmp rbx, rax
    jl .No
    add r14, 16
    NEXT
.No:
    mov r14, [r14 + 8]
    NEXT

PrimDLessBr:
    DPop rax
    movq xmm1, rax
    DPop rax
    movq xmm0, rax
    ucomisd xmm0, xmm1
    setb cl
    test cl, cl
    jz .No
    add r14, 16
    NEXT
.No:
    mov r14, [r14 + 8]
    NEXT

PrimDGreaterBr:
    DPop rax
    movq xmm1, rax
    DPop rax
    movq xmm0, rax
    ucomisd xmm0, xmm1
    seta cl
    test cl, cl
    jz .No
    add r14, 16
    NEXT
.No:
    mov r14, [r14 + 8]
    NEXT

PrimDLessEqBr:
    DPop rax
    movq xmm1, rax
    DPop rax
    movq xmm0, rax
    ucomisd xmm0, xmm1
    setbe cl
    test cl, cl
    jz .No
    add r14, 16
    NEXT
.No:
    mov r14, [r14 + 8]
    NEXT

PrimDGreaterEqBr:
    DPop rax
    movq xmm1, rax
    DPop rax
    movq xmm0, rax
    ucomisd xmm0, xmm1
    setae cl
    test cl, cl
    jz .No
    add r14, 16
    NEXT
.No:
    mov r14, [r14 + 8]
    NEXT

PrimDEqBr:
    DPop rax
    movq xmm1, rax
    DPop rax
    movq xmm0, rax
    ucomisd xmm0, xmm1
    sete cl
    test cl, cl
    jz .No
    add r14, 16
    NEXT
.No:
    mov r14, [r14 + 8]
    NEXT

PrimDNotEqBr:
    DPop rax
    movq xmm1, rax
    DPop rax
    movq xmm0, rax
    ucomisd xmm0, xmm1
    setne cl
    test cl, cl
    jz .No
    add r14, 16
    NEXT
.No:
    mov r14, [r14 + 8]
    NEXT

PrimAndJump:
    mov rax, [r15 - 8]
    test rax, rax
    jz .Jump
    sub r15, 8
    add r14, 24
    NEXT
.Jump:
    mov r14, [r14 + 8]
    NEXT

F_LocalGet_PrimAdd:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 16
    jmp PrimAdd

F_LocalGet_PrimSub:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 16
    jmp PrimSub

F_LocalGet_PrimMul:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 16
    jmp PrimMul

F_LocalGet_PrimDiv:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 16
    jmp PrimDiv

F_LocalGet_PrimFloorDiv:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 16
    jmp PrimFloorDiv

F_LocalGet_PrimMod:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 16
    jmp PrimMod

F_LocalGet_PrimLess:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 16
    jmp PrimLess

F_LocalGet_PrimGreater:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 16
    jmp PrimGreater

F_LocalGet_PrimEq:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 16
    jmp PrimEq

F_LocalGet_PrimNotEq:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 16
    jmp PrimNotEq

F_LocalGet_PrimLessEq:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 16
    jmp PrimLessEq

F_LocalGet_PrimGreaterEq:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 16
    jmp PrimGreaterEq

F_LocalGet_PrimDAdd:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 16
    jmp PrimDAdd

F_LocalGet_PrimDSub:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 16
    jmp PrimDSub

F_LocalGet_PrimDMul:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 16
    jmp PrimDMul

F_LocalGet_PrimDDiv:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 16
    jmp PrimDDiv

F_LocalGet_PrimDFloorDiv:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 16
    jmp PrimDFloorDiv

F_LocalGet_PrimDMod:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 16
    jmp PrimDMod

F_LocalGet_PrimDLess:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 16
    jmp PrimDLess

F_LocalGet_PrimDGreater:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 16
    jmp PrimDGreater

F_LocalGet_PrimDLessEq:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 16
    jmp PrimDLessEq

F_LocalGet_PrimDGreaterEq:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 16
    jmp PrimDGreaterEq

F_LocalGet_PrimDEq:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 16
    jmp PrimDEq

F_LocalGet_PrimDNotEq:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 16
    jmp PrimDNotEq

F_LocalGet_PrimIndex:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 16
    jmp PrimIndex

F_LocalGet_PrimToDecUnder:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 16
    jmp PrimToDecUnder

F_LocalGet_PrimTextEq:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 16
    jmp PrimTextEq

F_LocalGet_PrimConcat:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 16
    jmp PrimConcat

F_LocalGet_PrimToDec:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 16
    jmp PrimToDec

F_LocalGet_PrimLessBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 16
    jmp PrimLessBr

F_LocalGet_PrimGreaterBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 16
    jmp PrimGreaterBr

F_LocalGet_PrimEqBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 16
    jmp PrimEqBr

F_LocalGet_PrimNotEqBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 16
    jmp PrimNotEqBr

F_LocalGet_PrimLessEqBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 16
    jmp PrimLessEqBr

F_LocalGet_PrimGreaterEqBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 16
    jmp PrimGreaterEqBr

F_LocalGet_PrimDLessBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 16
    jmp PrimDLessBr

F_LocalGet_PrimDGreaterBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 16
    jmp PrimDGreaterBr

F_LocalGet_PrimDLessEqBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 16
    jmp PrimDLessEqBr

F_LocalGet_PrimDGreaterEqBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 16
    jmp PrimDGreaterEqBr

F_LocalGet_PrimDEqBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 16
    jmp PrimDEqBr

F_LocalGet_PrimDNotEqBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 16
    jmp PrimDNotEqBr

F_Lit_PrimAdd:
    mov rax, [r14]
    DPush rax
    add r14, 16
    jmp PrimAdd

F_Lit_PrimSub:
    mov rax, [r14]
    DPush rax
    add r14, 16
    jmp PrimSub

F_Lit_PrimMul:
    mov rax, [r14]
    DPush rax
    add r14, 16
    jmp PrimMul

F_Lit_PrimDiv:
    mov rax, [r14]
    DPush rax
    add r14, 16
    jmp PrimDiv

F_Lit_PrimFloorDiv:
    mov rax, [r14]
    DPush rax
    add r14, 16
    jmp PrimFloorDiv

F_Lit_PrimMod:
    mov rax, [r14]
    DPush rax
    add r14, 16
    jmp PrimMod

F_Lit_PrimLess:
    mov rax, [r14]
    DPush rax
    add r14, 16
    jmp PrimLess

F_Lit_PrimGreater:
    mov rax, [r14]
    DPush rax
    add r14, 16
    jmp PrimGreater

F_Lit_PrimEq:
    mov rax, [r14]
    DPush rax
    add r14, 16
    jmp PrimEq

F_Lit_PrimNotEq:
    mov rax, [r14]
    DPush rax
    add r14, 16
    jmp PrimNotEq

F_Lit_PrimLessEq:
    mov rax, [r14]
    DPush rax
    add r14, 16
    jmp PrimLessEq

F_Lit_PrimGreaterEq:
    mov rax, [r14]
    DPush rax
    add r14, 16
    jmp PrimGreaterEq

F_Lit_PrimDAdd:
    mov rax, [r14]
    DPush rax
    add r14, 16
    jmp PrimDAdd

F_Lit_PrimDSub:
    mov rax, [r14]
    DPush rax
    add r14, 16
    jmp PrimDSub

F_Lit_PrimDMul:
    mov rax, [r14]
    DPush rax
    add r14, 16
    jmp PrimDMul

F_Lit_PrimDDiv:
    mov rax, [r14]
    DPush rax
    add r14, 16
    jmp PrimDDiv

F_Lit_PrimDFloorDiv:
    mov rax, [r14]
    DPush rax
    add r14, 16
    jmp PrimDFloorDiv

F_Lit_PrimDMod:
    mov rax, [r14]
    DPush rax
    add r14, 16
    jmp PrimDMod

F_Lit_PrimDLess:
    mov rax, [r14]
    DPush rax
    add r14, 16
    jmp PrimDLess

F_Lit_PrimDGreater:
    mov rax, [r14]
    DPush rax
    add r14, 16
    jmp PrimDGreater

F_Lit_PrimDLessEq:
    mov rax, [r14]
    DPush rax
    add r14, 16
    jmp PrimDLessEq

F_Lit_PrimDGreaterEq:
    mov rax, [r14]
    DPush rax
    add r14, 16
    jmp PrimDGreaterEq

F_Lit_PrimDEq:
    mov rax, [r14]
    DPush rax
    add r14, 16
    jmp PrimDEq

F_Lit_PrimDNotEq:
    mov rax, [r14]
    DPush rax
    add r14, 16
    jmp PrimDNotEq

F_Lit_PrimIndex:
    mov rax, [r14]
    DPush rax
    add r14, 16
    jmp PrimIndex

F_Lit_PrimToDecUnder:
    mov rax, [r14]
    DPush rax
    add r14, 16
    jmp PrimToDecUnder

F_Lit_PrimTextEq:
    mov rax, [r14]
    DPush rax
    add r14, 16
    jmp PrimTextEq

F_Lit_PrimConcat:
    mov rax, [r14]
    DPush rax
    add r14, 16
    jmp PrimConcat

F_Lit_PrimToDec:
    mov rax, [r14]
    DPush rax
    add r14, 16
    jmp PrimToDec

F_Lit_PrimLessBr:
    mov rax, [r14]
    DPush rax
    add r14, 16
    jmp PrimLessBr

F_Lit_PrimGreaterBr:
    mov rax, [r14]
    DPush rax
    add r14, 16
    jmp PrimGreaterBr

F_Lit_PrimEqBr:
    mov rax, [r14]
    DPush rax
    add r14, 16
    jmp PrimEqBr

F_Lit_PrimNotEqBr:
    mov rax, [r14]
    DPush rax
    add r14, 16
    jmp PrimNotEqBr

F_Lit_PrimLessEqBr:
    mov rax, [r14]
    DPush rax
    add r14, 16
    jmp PrimLessEqBr

F_Lit_PrimGreaterEqBr:
    mov rax, [r14]
    DPush rax
    add r14, 16
    jmp PrimGreaterEqBr

F_Lit_PrimDLessBr:
    mov rax, [r14]
    DPush rax
    add r14, 16
    jmp PrimDLessBr

F_Lit_PrimDGreaterBr:
    mov rax, [r14]
    DPush rax
    add r14, 16
    jmp PrimDGreaterBr

F_Lit_PrimDLessEqBr:
    mov rax, [r14]
    DPush rax
    add r14, 16
    jmp PrimDLessEqBr

F_Lit_PrimDGreaterEqBr:
    mov rax, [r14]
    DPush rax
    add r14, 16
    jmp PrimDGreaterEqBr

F_Lit_PrimDEqBr:
    mov rax, [r14]
    DPush rax
    add r14, 16
    jmp PrimDEqBr

F_Lit_PrimDNotEqBr:
    mov rax, [r14]
    DPush rax
    add r14, 16
    jmp PrimDNotEqBr

F_GetG_PrimAdd:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    add r14, 16
    jmp PrimAdd

F_GetG_PrimSub:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    add r14, 16
    jmp PrimSub

F_GetG_PrimMul:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    add r14, 16
    jmp PrimMul

F_GetG_PrimDiv:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    add r14, 16
    jmp PrimDiv

F_GetG_PrimFloorDiv:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    add r14, 16
    jmp PrimFloorDiv

F_GetG_PrimMod:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    add r14, 16
    jmp PrimMod

F_GetG_PrimLess:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    add r14, 16
    jmp PrimLess

F_GetG_PrimGreater:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    add r14, 16
    jmp PrimGreater

F_GetG_PrimEq:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    add r14, 16
    jmp PrimEq

F_GetG_PrimNotEq:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    add r14, 16
    jmp PrimNotEq

F_GetG_PrimLessEq:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    add r14, 16
    jmp PrimLessEq

F_GetG_PrimGreaterEq:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    add r14, 16
    jmp PrimGreaterEq

F_GetG_PrimDAdd:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    add r14, 16
    jmp PrimDAdd

F_GetG_PrimDSub:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    add r14, 16
    jmp PrimDSub

F_GetG_PrimDMul:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    add r14, 16
    jmp PrimDMul

F_GetG_PrimDDiv:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    add r14, 16
    jmp PrimDDiv

F_GetG_PrimDFloorDiv:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    add r14, 16
    jmp PrimDFloorDiv

F_GetG_PrimDMod:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    add r14, 16
    jmp PrimDMod

F_GetG_PrimDLess:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    add r14, 16
    jmp PrimDLess

F_GetG_PrimDGreater:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    add r14, 16
    jmp PrimDGreater

F_GetG_PrimDLessEq:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    add r14, 16
    jmp PrimDLessEq

F_GetG_PrimDGreaterEq:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    add r14, 16
    jmp PrimDGreaterEq

F_GetG_PrimDEq:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    add r14, 16
    jmp PrimDEq

F_GetG_PrimDNotEq:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    add r14, 16
    jmp PrimDNotEq

F_GetG_PrimIndex:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    add r14, 16
    jmp PrimIndex

F_GetG_PrimToDecUnder:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    add r14, 16
    jmp PrimToDecUnder

F_GetG_PrimTextEq:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    add r14, 16
    jmp PrimTextEq

F_GetG_PrimConcat:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    add r14, 16
    jmp PrimConcat

F_GetG_PrimToDec:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    add r14, 16
    jmp PrimToDec

F_GetG_PrimLessBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    add r14, 16
    jmp PrimLessBr

F_GetG_PrimGreaterBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    add r14, 16
    jmp PrimGreaterBr

F_GetG_PrimEqBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    add r14, 16
    jmp PrimEqBr

F_GetG_PrimNotEqBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    add r14, 16
    jmp PrimNotEqBr

F_GetG_PrimLessEqBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    add r14, 16
    jmp PrimLessEqBr

F_GetG_PrimGreaterEqBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    add r14, 16
    jmp PrimGreaterEqBr

F_GetG_PrimDLessBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    add r14, 16
    jmp PrimDLessBr

F_GetG_PrimDGreaterBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    add r14, 16
    jmp PrimDGreaterBr

F_GetG_PrimDLessEqBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    add r14, 16
    jmp PrimDLessEqBr

F_GetG_PrimDGreaterEqBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    add r14, 16
    jmp PrimDGreaterEqBr

F_GetG_PrimDEqBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    add r14, 16
    jmp PrimDEqBr

F_GetG_PrimDNotEqBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    add r14, 16
    jmp PrimDNotEqBr

F_LocalGet_LocalGet_PrimAdd:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimAdd

F_LocalGet_LocalGet_PrimSub:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimSub

F_LocalGet_LocalGet_PrimMul:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimMul

F_LocalGet_LocalGet_PrimDiv:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimDiv

F_LocalGet_LocalGet_PrimFloorDiv:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimFloorDiv

F_LocalGet_LocalGet_PrimMod:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimMod

F_LocalGet_LocalGet_PrimLess:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimLess

F_LocalGet_LocalGet_PrimGreater:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimGreater

F_LocalGet_LocalGet_PrimEq:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimEq

F_LocalGet_LocalGet_PrimNotEq:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimNotEq

F_LocalGet_LocalGet_PrimLessEq:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimLessEq

F_LocalGet_LocalGet_PrimGreaterEq:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimGreaterEq

F_LocalGet_LocalGet_PrimDAdd:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimDAdd

F_LocalGet_LocalGet_PrimDSub:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimDSub

F_LocalGet_LocalGet_PrimDMul:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimDMul

F_LocalGet_LocalGet_PrimDDiv:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimDDiv

F_LocalGet_LocalGet_PrimDFloorDiv:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimDFloorDiv

F_LocalGet_LocalGet_PrimDMod:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimDMod

F_LocalGet_LocalGet_PrimDLess:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimDLess

F_LocalGet_LocalGet_PrimDGreater:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimDGreater

F_LocalGet_LocalGet_PrimDLessEq:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimDLessEq

F_LocalGet_LocalGet_PrimDGreaterEq:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimDGreaterEq

F_LocalGet_LocalGet_PrimDEq:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimDEq

F_LocalGet_LocalGet_PrimDNotEq:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimDNotEq

F_LocalGet_LocalGet_PrimIndex:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimIndex

F_LocalGet_LocalGet_PrimToDecUnder:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimToDecUnder

F_LocalGet_LocalGet_PrimTextEq:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimTextEq

F_LocalGet_LocalGet_PrimConcat:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimConcat

F_LocalGet_LocalGet_PrimLessBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimLessBr

F_LocalGet_LocalGet_PrimGreaterBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimGreaterBr

F_LocalGet_LocalGet_PrimEqBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimEqBr

F_LocalGet_LocalGet_PrimNotEqBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimNotEqBr

F_LocalGet_LocalGet_PrimLessEqBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimLessEqBr

F_LocalGet_LocalGet_PrimGreaterEqBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimGreaterEqBr

F_LocalGet_LocalGet_PrimDLessBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimDLessBr

F_LocalGet_LocalGet_PrimDGreaterBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimDGreaterBr

F_LocalGet_LocalGet_PrimDLessEqBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimDLessEqBr

F_LocalGet_LocalGet_PrimDGreaterEqBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimDGreaterEqBr

F_LocalGet_LocalGet_PrimDEqBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimDEqBr

F_LocalGet_LocalGet_PrimDNotEqBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimDNotEqBr

F_LocalGet_Lit_PrimAdd:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimAdd

F_LocalGet_Lit_PrimSub:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimSub

F_LocalGet_Lit_PrimMul:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimMul

F_LocalGet_Lit_PrimDiv:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimDiv

F_LocalGet_Lit_PrimFloorDiv:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimFloorDiv

F_LocalGet_Lit_PrimMod:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimMod

F_LocalGet_Lit_PrimLess:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimLess

F_LocalGet_Lit_PrimGreater:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimGreater

F_LocalGet_Lit_PrimEq:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimEq

F_LocalGet_Lit_PrimNotEq:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimNotEq

F_LocalGet_Lit_PrimLessEq:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimLessEq

F_LocalGet_Lit_PrimGreaterEq:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimGreaterEq

F_LocalGet_Lit_PrimDAdd:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimDAdd

F_LocalGet_Lit_PrimDSub:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimDSub

F_LocalGet_Lit_PrimDMul:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimDMul

F_LocalGet_Lit_PrimDDiv:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimDDiv

F_LocalGet_Lit_PrimDFloorDiv:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimDFloorDiv

F_LocalGet_Lit_PrimDMod:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimDMod

F_LocalGet_Lit_PrimDLess:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimDLess

F_LocalGet_Lit_PrimDGreater:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimDGreater

F_LocalGet_Lit_PrimDLessEq:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimDLessEq

F_LocalGet_Lit_PrimDGreaterEq:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimDGreaterEq

F_LocalGet_Lit_PrimDEq:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimDEq

F_LocalGet_Lit_PrimDNotEq:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimDNotEq

F_LocalGet_Lit_PrimIndex:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimIndex

F_LocalGet_Lit_PrimToDecUnder:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimToDecUnder

F_LocalGet_Lit_PrimTextEq:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimTextEq

F_LocalGet_Lit_PrimConcat:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimConcat

F_LocalGet_Lit_PrimLessBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimLessBr

F_LocalGet_Lit_PrimGreaterBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimGreaterBr

F_LocalGet_Lit_PrimEqBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimEqBr

F_LocalGet_Lit_PrimNotEqBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimNotEqBr

F_LocalGet_Lit_PrimLessEqBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimLessEqBr

F_LocalGet_Lit_PrimGreaterEqBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimGreaterEqBr

F_LocalGet_Lit_PrimDLessBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimDLessBr

F_LocalGet_Lit_PrimDGreaterBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimDGreaterBr

F_LocalGet_Lit_PrimDLessEqBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimDLessEqBr

F_LocalGet_Lit_PrimDGreaterEqBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimDGreaterEqBr

F_LocalGet_Lit_PrimDEqBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimDEqBr

F_LocalGet_Lit_PrimDNotEqBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimDNotEqBr

F_GetG_LocalGet_PrimAdd:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimAdd

F_GetG_LocalGet_PrimSub:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimSub

F_GetG_LocalGet_PrimMul:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimMul

F_GetG_LocalGet_PrimDiv:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimDiv

F_GetG_LocalGet_PrimFloorDiv:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimFloorDiv

F_GetG_LocalGet_PrimMod:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimMod

F_GetG_LocalGet_PrimLess:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimLess

F_GetG_LocalGet_PrimGreater:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimGreater

F_GetG_LocalGet_PrimEq:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimEq

F_GetG_LocalGet_PrimNotEq:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimNotEq

F_GetG_LocalGet_PrimLessEq:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimLessEq

F_GetG_LocalGet_PrimGreaterEq:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimGreaterEq

F_GetG_LocalGet_PrimDAdd:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimDAdd

F_GetG_LocalGet_PrimDSub:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimDSub

F_GetG_LocalGet_PrimDMul:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimDMul

F_GetG_LocalGet_PrimDDiv:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimDDiv

F_GetG_LocalGet_PrimDFloorDiv:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimDFloorDiv

F_GetG_LocalGet_PrimDMod:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimDMod

F_GetG_LocalGet_PrimDLess:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimDLess

F_GetG_LocalGet_PrimDGreater:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimDGreater

F_GetG_LocalGet_PrimDLessEq:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimDLessEq

F_GetG_LocalGet_PrimDGreaterEq:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimDGreaterEq

F_GetG_LocalGet_PrimDEq:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimDEq

F_GetG_LocalGet_PrimDNotEq:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimDNotEq

F_GetG_LocalGet_PrimIndex:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimIndex

F_GetG_LocalGet_PrimToDecUnder:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimToDecUnder

F_GetG_LocalGet_PrimTextEq:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimTextEq

F_GetG_LocalGet_PrimConcat:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimConcat

F_GetG_LocalGet_PrimLessBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimLessBr

F_GetG_LocalGet_PrimGreaterBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimGreaterBr

F_GetG_LocalGet_PrimEqBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimEqBr

F_GetG_LocalGet_PrimNotEqBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimNotEqBr

F_GetG_LocalGet_PrimLessEqBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimLessEqBr

F_GetG_LocalGet_PrimGreaterEqBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimGreaterEqBr

F_GetG_LocalGet_PrimDLessBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimDLessBr

F_GetG_LocalGet_PrimDGreaterBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimDGreaterBr

F_GetG_LocalGet_PrimDLessEqBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimDLessEqBr

F_GetG_LocalGet_PrimDGreaterEqBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimDGreaterEqBr

F_GetG_LocalGet_PrimDEqBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimDEqBr

F_GetG_LocalGet_PrimDNotEqBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [r13 + rax]
    DPush rax
    add r14, 32
    jmp PrimDNotEqBr

F_LocalGet_GetG_PrimAdd:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimAdd

F_LocalGet_GetG_PrimSub:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimSub

F_LocalGet_GetG_PrimMul:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimMul

F_LocalGet_GetG_PrimDiv:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimDiv

F_LocalGet_GetG_PrimFloorDiv:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimFloorDiv

F_LocalGet_GetG_PrimMod:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimMod

F_LocalGet_GetG_PrimLess:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimLess

F_LocalGet_GetG_PrimGreater:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimGreater

F_LocalGet_GetG_PrimEq:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimEq

F_LocalGet_GetG_PrimNotEq:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimNotEq

F_LocalGet_GetG_PrimLessEq:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimLessEq

F_LocalGet_GetG_PrimGreaterEq:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimGreaterEq

F_LocalGet_GetG_PrimDAdd:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimDAdd

F_LocalGet_GetG_PrimDSub:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimDSub

F_LocalGet_GetG_PrimDMul:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimDMul

F_LocalGet_GetG_PrimDDiv:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimDDiv

F_LocalGet_GetG_PrimDFloorDiv:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimDFloorDiv

F_LocalGet_GetG_PrimDMod:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimDMod

F_LocalGet_GetG_PrimDLess:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimDLess

F_LocalGet_GetG_PrimDGreater:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimDGreater

F_LocalGet_GetG_PrimDLessEq:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimDLessEq

F_LocalGet_GetG_PrimDGreaterEq:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimDGreaterEq

F_LocalGet_GetG_PrimDEq:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimDEq

F_LocalGet_GetG_PrimDNotEq:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimDNotEq

F_LocalGet_GetG_PrimIndex:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimIndex

F_LocalGet_GetG_PrimToDecUnder:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimToDecUnder

F_LocalGet_GetG_PrimTextEq:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimTextEq

F_LocalGet_GetG_PrimConcat:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimConcat

F_LocalGet_GetG_PrimLessBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimLessBr

F_LocalGet_GetG_PrimGreaterBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimGreaterBr

F_LocalGet_GetG_PrimEqBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimEqBr

F_LocalGet_GetG_PrimNotEqBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimNotEqBr

F_LocalGet_GetG_PrimLessEqBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimLessEqBr

F_LocalGet_GetG_PrimGreaterEqBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimGreaterEqBr

F_LocalGet_GetG_PrimDLessBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimDLessBr

F_LocalGet_GetG_PrimDGreaterBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimDGreaterBr

F_LocalGet_GetG_PrimDLessEqBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimDLessEqBr

F_LocalGet_GetG_PrimDGreaterEqBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimDGreaterEqBr

F_LocalGet_GetG_PrimDEqBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimDEqBr

F_LocalGet_GetG_PrimDNotEqBr:
    mov rax, [r14]
    mov rax, [r13 + rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimDNotEqBr

F_GetG_Lit_PrimAdd:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimAdd

F_GetG_Lit_PrimSub:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimSub

F_GetG_Lit_PrimMul:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimMul

F_GetG_Lit_PrimDiv:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimDiv

F_GetG_Lit_PrimFloorDiv:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimFloorDiv

F_GetG_Lit_PrimMod:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimMod

F_GetG_Lit_PrimLess:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimLess

F_GetG_Lit_PrimGreater:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimGreater

F_GetG_Lit_PrimEq:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimEq

F_GetG_Lit_PrimNotEq:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimNotEq

F_GetG_Lit_PrimLessEq:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimLessEq

F_GetG_Lit_PrimGreaterEq:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimGreaterEq

F_GetG_Lit_PrimDAdd:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimDAdd

F_GetG_Lit_PrimDSub:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimDSub

F_GetG_Lit_PrimDMul:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimDMul

F_GetG_Lit_PrimDDiv:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimDDiv

F_GetG_Lit_PrimDFloorDiv:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimDFloorDiv

F_GetG_Lit_PrimDMod:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimDMod

F_GetG_Lit_PrimDLess:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimDLess

F_GetG_Lit_PrimDGreater:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimDGreater

F_GetG_Lit_PrimDLessEq:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimDLessEq

F_GetG_Lit_PrimDGreaterEq:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimDGreaterEq

F_GetG_Lit_PrimDEq:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimDEq

F_GetG_Lit_PrimDNotEq:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimDNotEq

F_GetG_Lit_PrimIndex:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimIndex

F_GetG_Lit_PrimToDecUnder:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimToDecUnder

F_GetG_Lit_PrimTextEq:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimTextEq

F_GetG_Lit_PrimConcat:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimConcat

F_GetG_Lit_PrimLessBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimLessBr

F_GetG_Lit_PrimGreaterBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimGreaterBr

F_GetG_Lit_PrimEqBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimEqBr

F_GetG_Lit_PrimNotEqBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimNotEqBr

F_GetG_Lit_PrimLessEqBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimLessEqBr

F_GetG_Lit_PrimGreaterEqBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimGreaterEqBr

F_GetG_Lit_PrimDLessBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimDLessBr

F_GetG_Lit_PrimDGreaterBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimDGreaterBr

F_GetG_Lit_PrimDLessEqBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimDLessEqBr

F_GetG_Lit_PrimDGreaterEqBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimDGreaterEqBr

F_GetG_Lit_PrimDEqBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimDEqBr

F_GetG_Lit_PrimDNotEqBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    DPush rax
    add r14, 32
    jmp PrimDNotEqBr

F_GetG_GetG_PrimAdd:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimAdd

F_GetG_GetG_PrimSub:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimSub

F_GetG_GetG_PrimMul:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimMul

F_GetG_GetG_PrimDiv:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimDiv

F_GetG_GetG_PrimFloorDiv:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimFloorDiv

F_GetG_GetG_PrimMod:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimMod

F_GetG_GetG_PrimLess:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimLess

F_GetG_GetG_PrimGreater:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimGreater

F_GetG_GetG_PrimEq:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimEq

F_GetG_GetG_PrimNotEq:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimNotEq

F_GetG_GetG_PrimLessEq:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimLessEq

F_GetG_GetG_PrimGreaterEq:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimGreaterEq

F_GetG_GetG_PrimDAdd:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimDAdd

F_GetG_GetG_PrimDSub:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimDSub

F_GetG_GetG_PrimDMul:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimDMul

F_GetG_GetG_PrimDDiv:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimDDiv

F_GetG_GetG_PrimDFloorDiv:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimDFloorDiv

F_GetG_GetG_PrimDMod:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimDMod

F_GetG_GetG_PrimDLess:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimDLess

F_GetG_GetG_PrimDGreater:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimDGreater

F_GetG_GetG_PrimDLessEq:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimDLessEq

F_GetG_GetG_PrimDGreaterEq:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimDGreaterEq

F_GetG_GetG_PrimDEq:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimDEq

F_GetG_GetG_PrimDNotEq:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimDNotEq

F_GetG_GetG_PrimIndex:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimIndex

F_GetG_GetG_PrimToDecUnder:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimToDecUnder

F_GetG_GetG_PrimTextEq:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimTextEq

F_GetG_GetG_PrimConcat:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimConcat

F_GetG_GetG_PrimLessBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimLessBr

F_GetG_GetG_PrimGreaterBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimGreaterBr

F_GetG_GetG_PrimEqBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimEqBr

F_GetG_GetG_PrimNotEqBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimNotEqBr

F_GetG_GetG_PrimLessEqBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimLessEqBr

F_GetG_GetG_PrimGreaterEqBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimGreaterEqBr

F_GetG_GetG_PrimDLessBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimDLessBr

F_GetG_GetG_PrimDGreaterBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimDGreaterBr

F_GetG_GetG_PrimDLessEqBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimDLessEqBr

F_GetG_GetG_PrimDGreaterEqBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimDGreaterEqBr

F_GetG_GetG_PrimDEqBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimDEqBr

F_GetG_GetG_PrimDNotEqBr:
    mov rax, [r14]
    mov rax, [rax]
    DPush rax
    mov rax, [r14 + 16]
    mov rax, [rax]
    DPush rax
    add r14, 32
    jmp PrimDNotEqBr

S_PrimAdd_LocalSet:
    DPop rax
    DPop rbx
    add rbx, rax
    mov rcx, [r14 + 8]
    mov [r13 + rcx], rbx
    add r14, 16
    NEXT

S_PrimAdd_SetG:
    DPop rax
    DPop rbx
    add rbx, rax
    mov rcx, [r14 + 8]
    mov [rcx], rbx
    add r14, 16
    NEXT

S_PrimSub_LocalSet:
    DPop rax
    DPop rbx
    sub rbx, rax
    mov rcx, [r14 + 8]
    mov [r13 + rcx], rbx
    add r14, 16
    NEXT

S_PrimSub_SetG:
    DPop rax
    DPop rbx
    sub rbx, rax
    mov rcx, [r14 + 8]
    mov [rcx], rbx
    add r14, 16
    NEXT

S_PrimMul_LocalSet:
    DPop rax
    DPop rbx
    imul rbx, rax
    mov rcx, [r14 + 8]
    mov [r13 + rcx], rbx
    add r14, 16
    NEXT

S_PrimMul_SetG:
    DPop rax
    DPop rbx
    imul rbx, rax
    mov rcx, [r14 + 8]
    mov [rcx], rbx
    add r14, 16
    NEXT

S_PrimDAdd_LocalSet:
    DPop rax
    movq xmm1, rax
    DPop rax
    movq xmm0, rax
    addsd xmm0, xmm1
    movq rbx, xmm0
    mov rcx, [r14 + 8]
    mov [r13 + rcx], rbx
    add r14, 16
    NEXT

S_PrimDAdd_SetG:
    DPop rax
    movq xmm1, rax
    DPop rax
    movq xmm0, rax
    addsd xmm0, xmm1
    movq rbx, xmm0
    mov rcx, [r14 + 8]
    mov [rcx], rbx
    add r14, 16
    NEXT

S_PrimDSub_LocalSet:
    DPop rax
    movq xmm1, rax
    DPop rax
    movq xmm0, rax
    subsd xmm0, xmm1
    movq rbx, xmm0
    mov rcx, [r14 + 8]
    mov [r13 + rcx], rbx
    add r14, 16
    NEXT

S_PrimDSub_SetG:
    DPop rax
    movq xmm1, rax
    DPop rax
    movq xmm0, rax
    subsd xmm0, xmm1
    movq rbx, xmm0
    mov rcx, [r14 + 8]
    mov [rcx], rbx
    add r14, 16
    NEXT

S_PrimDMul_LocalSet:
    DPop rax
    movq xmm1, rax
    DPop rax
    movq xmm0, rax
    mulsd xmm0, xmm1
    movq rbx, xmm0
    mov rcx, [r14 + 8]
    mov [r13 + rcx], rbx
    add r14, 16
    NEXT

S_PrimDMul_SetG:
    DPop rax
    movq xmm1, rax
    DPop rax
    movq xmm0, rax
    mulsd xmm0, xmm1
    movq rbx, xmm0
    mov rcx, [r14 + 8]
    mov [rcx], rbx
    add r14, 16
    NEXT

S_PrimDDiv_LocalSet:
    DPop rax
    movq xmm1, rax
    DPop rax
    movq xmm0, rax
    divsd xmm0, xmm1
    movq rbx, xmm0
    mov rcx, [r14 + 8]
    mov [r13 + rcx], rbx
    add r14, 16
    NEXT

S_PrimDDiv_SetG:
    DPop rax
    movq xmm1, rax
    DPop rax
    movq xmm0, rax
    divsd xmm0, xmm1
    movq rbx, xmm0
    mov rcx, [r14 + 8]
    mov [rcx], rbx
    add r14, 16
    NEXT

section .data
align 8
FuseTable:
    dq PrimLocalGet, 0, PrimAdd, F_LocalGet_PrimAdd
    dq PrimLocalGet, 0, PrimSub, F_LocalGet_PrimSub
    dq PrimLocalGet, 0, PrimMul, F_LocalGet_PrimMul
    dq PrimLocalGet, 0, PrimDiv, F_LocalGet_PrimDiv
    dq PrimLocalGet, 0, PrimFloorDiv, F_LocalGet_PrimFloorDiv
    dq PrimLocalGet, 0, PrimMod, F_LocalGet_PrimMod
    dq PrimLocalGet, 0, PrimLess, F_LocalGet_PrimLess
    dq PrimLocalGet, 0, PrimGreater, F_LocalGet_PrimGreater
    dq PrimLocalGet, 0, PrimEq, F_LocalGet_PrimEq
    dq PrimLocalGet, 0, PrimNotEq, F_LocalGet_PrimNotEq
    dq PrimLocalGet, 0, PrimLessEq, F_LocalGet_PrimLessEq
    dq PrimLocalGet, 0, PrimGreaterEq, F_LocalGet_PrimGreaterEq
    dq PrimLocalGet, 0, PrimDAdd, F_LocalGet_PrimDAdd
    dq PrimLocalGet, 0, PrimDSub, F_LocalGet_PrimDSub
    dq PrimLocalGet, 0, PrimDMul, F_LocalGet_PrimDMul
    dq PrimLocalGet, 0, PrimDDiv, F_LocalGet_PrimDDiv
    dq PrimLocalGet, 0, PrimDFloorDiv, F_LocalGet_PrimDFloorDiv
    dq PrimLocalGet, 0, PrimDMod, F_LocalGet_PrimDMod
    dq PrimLocalGet, 0, PrimDLess, F_LocalGet_PrimDLess
    dq PrimLocalGet, 0, PrimDGreater, F_LocalGet_PrimDGreater
    dq PrimLocalGet, 0, PrimDLessEq, F_LocalGet_PrimDLessEq
    dq PrimLocalGet, 0, PrimDGreaterEq, F_LocalGet_PrimDGreaterEq
    dq PrimLocalGet, 0, PrimDEq, F_LocalGet_PrimDEq
    dq PrimLocalGet, 0, PrimDNotEq, F_LocalGet_PrimDNotEq
    dq PrimLocalGet, 0, PrimIndex, F_LocalGet_PrimIndex
    dq PrimLocalGet, 0, PrimToDecUnder, F_LocalGet_PrimToDecUnder
    dq PrimLocalGet, 0, PrimTextEq, F_LocalGet_PrimTextEq
    dq PrimLocalGet, 0, PrimConcat, F_LocalGet_PrimConcat
    dq PrimLocalGet, 0, PrimToDec, F_LocalGet_PrimToDec
    dq PrimLocalGet, 0, PrimLessBr, F_LocalGet_PrimLessBr
    dq PrimLocalGet, 0, PrimGreaterBr, F_LocalGet_PrimGreaterBr
    dq PrimLocalGet, 0, PrimEqBr, F_LocalGet_PrimEqBr
    dq PrimLocalGet, 0, PrimNotEqBr, F_LocalGet_PrimNotEqBr
    dq PrimLocalGet, 0, PrimLessEqBr, F_LocalGet_PrimLessEqBr
    dq PrimLocalGet, 0, PrimGreaterEqBr, F_LocalGet_PrimGreaterEqBr
    dq PrimLocalGet, 0, PrimDLessBr, F_LocalGet_PrimDLessBr
    dq PrimLocalGet, 0, PrimDGreaterBr, F_LocalGet_PrimDGreaterBr
    dq PrimLocalGet, 0, PrimDLessEqBr, F_LocalGet_PrimDLessEqBr
    dq PrimLocalGet, 0, PrimDGreaterEqBr, F_LocalGet_PrimDGreaterEqBr
    dq PrimLocalGet, 0, PrimDEqBr, F_LocalGet_PrimDEqBr
    dq PrimLocalGet, 0, PrimDNotEqBr, F_LocalGet_PrimDNotEqBr
    dq PrimLit, 0, PrimAdd, F_Lit_PrimAdd
    dq PrimLit, 0, PrimSub, F_Lit_PrimSub
    dq PrimLit, 0, PrimMul, F_Lit_PrimMul
    dq PrimLit, 0, PrimDiv, F_Lit_PrimDiv
    dq PrimLit, 0, PrimFloorDiv, F_Lit_PrimFloorDiv
    dq PrimLit, 0, PrimMod, F_Lit_PrimMod
    dq PrimLit, 0, PrimLess, F_Lit_PrimLess
    dq PrimLit, 0, PrimGreater, F_Lit_PrimGreater
    dq PrimLit, 0, PrimEq, F_Lit_PrimEq
    dq PrimLit, 0, PrimNotEq, F_Lit_PrimNotEq
    dq PrimLit, 0, PrimLessEq, F_Lit_PrimLessEq
    dq PrimLit, 0, PrimGreaterEq, F_Lit_PrimGreaterEq
    dq PrimLit, 0, PrimDAdd, F_Lit_PrimDAdd
    dq PrimLit, 0, PrimDSub, F_Lit_PrimDSub
    dq PrimLit, 0, PrimDMul, F_Lit_PrimDMul
    dq PrimLit, 0, PrimDDiv, F_Lit_PrimDDiv
    dq PrimLit, 0, PrimDFloorDiv, F_Lit_PrimDFloorDiv
    dq PrimLit, 0, PrimDMod, F_Lit_PrimDMod
    dq PrimLit, 0, PrimDLess, F_Lit_PrimDLess
    dq PrimLit, 0, PrimDGreater, F_Lit_PrimDGreater
    dq PrimLit, 0, PrimDLessEq, F_Lit_PrimDLessEq
    dq PrimLit, 0, PrimDGreaterEq, F_Lit_PrimDGreaterEq
    dq PrimLit, 0, PrimDEq, F_Lit_PrimDEq
    dq PrimLit, 0, PrimDNotEq, F_Lit_PrimDNotEq
    dq PrimLit, 0, PrimIndex, F_Lit_PrimIndex
    dq PrimLit, 0, PrimToDecUnder, F_Lit_PrimToDecUnder
    dq PrimLit, 0, PrimTextEq, F_Lit_PrimTextEq
    dq PrimLit, 0, PrimConcat, F_Lit_PrimConcat
    dq PrimLit, 0, PrimToDec, F_Lit_PrimToDec
    dq PrimLit, 0, PrimLessBr, F_Lit_PrimLessBr
    dq PrimLit, 0, PrimGreaterBr, F_Lit_PrimGreaterBr
    dq PrimLit, 0, PrimEqBr, F_Lit_PrimEqBr
    dq PrimLit, 0, PrimNotEqBr, F_Lit_PrimNotEqBr
    dq PrimLit, 0, PrimLessEqBr, F_Lit_PrimLessEqBr
    dq PrimLit, 0, PrimGreaterEqBr, F_Lit_PrimGreaterEqBr
    dq PrimLit, 0, PrimDLessBr, F_Lit_PrimDLessBr
    dq PrimLit, 0, PrimDGreaterBr, F_Lit_PrimDGreaterBr
    dq PrimLit, 0, PrimDLessEqBr, F_Lit_PrimDLessEqBr
    dq PrimLit, 0, PrimDGreaterEqBr, F_Lit_PrimDGreaterEqBr
    dq PrimLit, 0, PrimDEqBr, F_Lit_PrimDEqBr
    dq PrimLit, 0, PrimDNotEqBr, F_Lit_PrimDNotEqBr
    dq PrimGetG, 0, PrimAdd, F_GetG_PrimAdd
    dq PrimGetG, 0, PrimSub, F_GetG_PrimSub
    dq PrimGetG, 0, PrimMul, F_GetG_PrimMul
    dq PrimGetG, 0, PrimDiv, F_GetG_PrimDiv
    dq PrimGetG, 0, PrimFloorDiv, F_GetG_PrimFloorDiv
    dq PrimGetG, 0, PrimMod, F_GetG_PrimMod
    dq PrimGetG, 0, PrimLess, F_GetG_PrimLess
    dq PrimGetG, 0, PrimGreater, F_GetG_PrimGreater
    dq PrimGetG, 0, PrimEq, F_GetG_PrimEq
    dq PrimGetG, 0, PrimNotEq, F_GetG_PrimNotEq
    dq PrimGetG, 0, PrimLessEq, F_GetG_PrimLessEq
    dq PrimGetG, 0, PrimGreaterEq, F_GetG_PrimGreaterEq
    dq PrimGetG, 0, PrimDAdd, F_GetG_PrimDAdd
    dq PrimGetG, 0, PrimDSub, F_GetG_PrimDSub
    dq PrimGetG, 0, PrimDMul, F_GetG_PrimDMul
    dq PrimGetG, 0, PrimDDiv, F_GetG_PrimDDiv
    dq PrimGetG, 0, PrimDFloorDiv, F_GetG_PrimDFloorDiv
    dq PrimGetG, 0, PrimDMod, F_GetG_PrimDMod
    dq PrimGetG, 0, PrimDLess, F_GetG_PrimDLess
    dq PrimGetG, 0, PrimDGreater, F_GetG_PrimDGreater
    dq PrimGetG, 0, PrimDLessEq, F_GetG_PrimDLessEq
    dq PrimGetG, 0, PrimDGreaterEq, F_GetG_PrimDGreaterEq
    dq PrimGetG, 0, PrimDEq, F_GetG_PrimDEq
    dq PrimGetG, 0, PrimDNotEq, F_GetG_PrimDNotEq
    dq PrimGetG, 0, PrimIndex, F_GetG_PrimIndex
    dq PrimGetG, 0, PrimToDecUnder, F_GetG_PrimToDecUnder
    dq PrimGetG, 0, PrimTextEq, F_GetG_PrimTextEq
    dq PrimGetG, 0, PrimConcat, F_GetG_PrimConcat
    dq PrimGetG, 0, PrimToDec, F_GetG_PrimToDec
    dq PrimGetG, 0, PrimLessBr, F_GetG_PrimLessBr
    dq PrimGetG, 0, PrimGreaterBr, F_GetG_PrimGreaterBr
    dq PrimGetG, 0, PrimEqBr, F_GetG_PrimEqBr
    dq PrimGetG, 0, PrimNotEqBr, F_GetG_PrimNotEqBr
    dq PrimGetG, 0, PrimLessEqBr, F_GetG_PrimLessEqBr
    dq PrimGetG, 0, PrimGreaterEqBr, F_GetG_PrimGreaterEqBr
    dq PrimGetG, 0, PrimDLessBr, F_GetG_PrimDLessBr
    dq PrimGetG, 0, PrimDGreaterBr, F_GetG_PrimDGreaterBr
    dq PrimGetG, 0, PrimDLessEqBr, F_GetG_PrimDLessEqBr
    dq PrimGetG, 0, PrimDGreaterEqBr, F_GetG_PrimDGreaterEqBr
    dq PrimGetG, 0, PrimDEqBr, F_GetG_PrimDEqBr
    dq PrimGetG, 0, PrimDNotEqBr, F_GetG_PrimDNotEqBr
    dq PrimLocalGet, PrimLocalGet, PrimAdd, F_LocalGet_LocalGet_PrimAdd
    dq PrimLocalGet, PrimLocalGet, PrimSub, F_LocalGet_LocalGet_PrimSub
    dq PrimLocalGet, PrimLocalGet, PrimMul, F_LocalGet_LocalGet_PrimMul
    dq PrimLocalGet, PrimLocalGet, PrimDiv, F_LocalGet_LocalGet_PrimDiv
    dq PrimLocalGet, PrimLocalGet, PrimFloorDiv, F_LocalGet_LocalGet_PrimFloorDiv
    dq PrimLocalGet, PrimLocalGet, PrimMod, F_LocalGet_LocalGet_PrimMod
    dq PrimLocalGet, PrimLocalGet, PrimLess, F_LocalGet_LocalGet_PrimLess
    dq PrimLocalGet, PrimLocalGet, PrimGreater, F_LocalGet_LocalGet_PrimGreater
    dq PrimLocalGet, PrimLocalGet, PrimEq, F_LocalGet_LocalGet_PrimEq
    dq PrimLocalGet, PrimLocalGet, PrimNotEq, F_LocalGet_LocalGet_PrimNotEq
    dq PrimLocalGet, PrimLocalGet, PrimLessEq, F_LocalGet_LocalGet_PrimLessEq
    dq PrimLocalGet, PrimLocalGet, PrimGreaterEq, F_LocalGet_LocalGet_PrimGreaterEq
    dq PrimLocalGet, PrimLocalGet, PrimDAdd, F_LocalGet_LocalGet_PrimDAdd
    dq PrimLocalGet, PrimLocalGet, PrimDSub, F_LocalGet_LocalGet_PrimDSub
    dq PrimLocalGet, PrimLocalGet, PrimDMul, F_LocalGet_LocalGet_PrimDMul
    dq PrimLocalGet, PrimLocalGet, PrimDDiv, F_LocalGet_LocalGet_PrimDDiv
    dq PrimLocalGet, PrimLocalGet, PrimDFloorDiv, F_LocalGet_LocalGet_PrimDFloorDiv
    dq PrimLocalGet, PrimLocalGet, PrimDMod, F_LocalGet_LocalGet_PrimDMod
    dq PrimLocalGet, PrimLocalGet, PrimDLess, F_LocalGet_LocalGet_PrimDLess
    dq PrimLocalGet, PrimLocalGet, PrimDGreater, F_LocalGet_LocalGet_PrimDGreater
    dq PrimLocalGet, PrimLocalGet, PrimDLessEq, F_LocalGet_LocalGet_PrimDLessEq
    dq PrimLocalGet, PrimLocalGet, PrimDGreaterEq, F_LocalGet_LocalGet_PrimDGreaterEq
    dq PrimLocalGet, PrimLocalGet, PrimDEq, F_LocalGet_LocalGet_PrimDEq
    dq PrimLocalGet, PrimLocalGet, PrimDNotEq, F_LocalGet_LocalGet_PrimDNotEq
    dq PrimLocalGet, PrimLocalGet, PrimIndex, F_LocalGet_LocalGet_PrimIndex
    dq PrimLocalGet, PrimLocalGet, PrimToDecUnder, F_LocalGet_LocalGet_PrimToDecUnder
    dq PrimLocalGet, PrimLocalGet, PrimTextEq, F_LocalGet_LocalGet_PrimTextEq
    dq PrimLocalGet, PrimLocalGet, PrimConcat, F_LocalGet_LocalGet_PrimConcat
    dq PrimLocalGet, PrimLocalGet, PrimLessBr, F_LocalGet_LocalGet_PrimLessBr
    dq PrimLocalGet, PrimLocalGet, PrimGreaterBr, F_LocalGet_LocalGet_PrimGreaterBr
    dq PrimLocalGet, PrimLocalGet, PrimEqBr, F_LocalGet_LocalGet_PrimEqBr
    dq PrimLocalGet, PrimLocalGet, PrimNotEqBr, F_LocalGet_LocalGet_PrimNotEqBr
    dq PrimLocalGet, PrimLocalGet, PrimLessEqBr, F_LocalGet_LocalGet_PrimLessEqBr
    dq PrimLocalGet, PrimLocalGet, PrimGreaterEqBr, F_LocalGet_LocalGet_PrimGreaterEqBr
    dq PrimLocalGet, PrimLocalGet, PrimDLessBr, F_LocalGet_LocalGet_PrimDLessBr
    dq PrimLocalGet, PrimLocalGet, PrimDGreaterBr, F_LocalGet_LocalGet_PrimDGreaterBr
    dq PrimLocalGet, PrimLocalGet, PrimDLessEqBr, F_LocalGet_LocalGet_PrimDLessEqBr
    dq PrimLocalGet, PrimLocalGet, PrimDGreaterEqBr, F_LocalGet_LocalGet_PrimDGreaterEqBr
    dq PrimLocalGet, PrimLocalGet, PrimDEqBr, F_LocalGet_LocalGet_PrimDEqBr
    dq PrimLocalGet, PrimLocalGet, PrimDNotEqBr, F_LocalGet_LocalGet_PrimDNotEqBr
    dq PrimLocalGet, PrimLit, PrimAdd, F_LocalGet_Lit_PrimAdd
    dq PrimLocalGet, PrimLit, PrimSub, F_LocalGet_Lit_PrimSub
    dq PrimLocalGet, PrimLit, PrimMul, F_LocalGet_Lit_PrimMul
    dq PrimLocalGet, PrimLit, PrimDiv, F_LocalGet_Lit_PrimDiv
    dq PrimLocalGet, PrimLit, PrimFloorDiv, F_LocalGet_Lit_PrimFloorDiv
    dq PrimLocalGet, PrimLit, PrimMod, F_LocalGet_Lit_PrimMod
    dq PrimLocalGet, PrimLit, PrimLess, F_LocalGet_Lit_PrimLess
    dq PrimLocalGet, PrimLit, PrimGreater, F_LocalGet_Lit_PrimGreater
    dq PrimLocalGet, PrimLit, PrimEq, F_LocalGet_Lit_PrimEq
    dq PrimLocalGet, PrimLit, PrimNotEq, F_LocalGet_Lit_PrimNotEq
    dq PrimLocalGet, PrimLit, PrimLessEq, F_LocalGet_Lit_PrimLessEq
    dq PrimLocalGet, PrimLit, PrimGreaterEq, F_LocalGet_Lit_PrimGreaterEq
    dq PrimLocalGet, PrimLit, PrimDAdd, F_LocalGet_Lit_PrimDAdd
    dq PrimLocalGet, PrimLit, PrimDSub, F_LocalGet_Lit_PrimDSub
    dq PrimLocalGet, PrimLit, PrimDMul, F_LocalGet_Lit_PrimDMul
    dq PrimLocalGet, PrimLit, PrimDDiv, F_LocalGet_Lit_PrimDDiv
    dq PrimLocalGet, PrimLit, PrimDFloorDiv, F_LocalGet_Lit_PrimDFloorDiv
    dq PrimLocalGet, PrimLit, PrimDMod, F_LocalGet_Lit_PrimDMod
    dq PrimLocalGet, PrimLit, PrimDLess, F_LocalGet_Lit_PrimDLess
    dq PrimLocalGet, PrimLit, PrimDGreater, F_LocalGet_Lit_PrimDGreater
    dq PrimLocalGet, PrimLit, PrimDLessEq, F_LocalGet_Lit_PrimDLessEq
    dq PrimLocalGet, PrimLit, PrimDGreaterEq, F_LocalGet_Lit_PrimDGreaterEq
    dq PrimLocalGet, PrimLit, PrimDEq, F_LocalGet_Lit_PrimDEq
    dq PrimLocalGet, PrimLit, PrimDNotEq, F_LocalGet_Lit_PrimDNotEq
    dq PrimLocalGet, PrimLit, PrimIndex, F_LocalGet_Lit_PrimIndex
    dq PrimLocalGet, PrimLit, PrimToDecUnder, F_LocalGet_Lit_PrimToDecUnder
    dq PrimLocalGet, PrimLit, PrimTextEq, F_LocalGet_Lit_PrimTextEq
    dq PrimLocalGet, PrimLit, PrimConcat, F_LocalGet_Lit_PrimConcat
    dq PrimLocalGet, PrimLit, PrimLessBr, F_LocalGet_Lit_PrimLessBr
    dq PrimLocalGet, PrimLit, PrimGreaterBr, F_LocalGet_Lit_PrimGreaterBr
    dq PrimLocalGet, PrimLit, PrimEqBr, F_LocalGet_Lit_PrimEqBr
    dq PrimLocalGet, PrimLit, PrimNotEqBr, F_LocalGet_Lit_PrimNotEqBr
    dq PrimLocalGet, PrimLit, PrimLessEqBr, F_LocalGet_Lit_PrimLessEqBr
    dq PrimLocalGet, PrimLit, PrimGreaterEqBr, F_LocalGet_Lit_PrimGreaterEqBr
    dq PrimLocalGet, PrimLit, PrimDLessBr, F_LocalGet_Lit_PrimDLessBr
    dq PrimLocalGet, PrimLit, PrimDGreaterBr, F_LocalGet_Lit_PrimDGreaterBr
    dq PrimLocalGet, PrimLit, PrimDLessEqBr, F_LocalGet_Lit_PrimDLessEqBr
    dq PrimLocalGet, PrimLit, PrimDGreaterEqBr, F_LocalGet_Lit_PrimDGreaterEqBr
    dq PrimLocalGet, PrimLit, PrimDEqBr, F_LocalGet_Lit_PrimDEqBr
    dq PrimLocalGet, PrimLit, PrimDNotEqBr, F_LocalGet_Lit_PrimDNotEqBr
    dq PrimGetG, PrimLocalGet, PrimAdd, F_GetG_LocalGet_PrimAdd
    dq PrimGetG, PrimLocalGet, PrimSub, F_GetG_LocalGet_PrimSub
    dq PrimGetG, PrimLocalGet, PrimMul, F_GetG_LocalGet_PrimMul
    dq PrimGetG, PrimLocalGet, PrimDiv, F_GetG_LocalGet_PrimDiv
    dq PrimGetG, PrimLocalGet, PrimFloorDiv, F_GetG_LocalGet_PrimFloorDiv
    dq PrimGetG, PrimLocalGet, PrimMod, F_GetG_LocalGet_PrimMod
    dq PrimGetG, PrimLocalGet, PrimLess, F_GetG_LocalGet_PrimLess
    dq PrimGetG, PrimLocalGet, PrimGreater, F_GetG_LocalGet_PrimGreater
    dq PrimGetG, PrimLocalGet, PrimEq, F_GetG_LocalGet_PrimEq
    dq PrimGetG, PrimLocalGet, PrimNotEq, F_GetG_LocalGet_PrimNotEq
    dq PrimGetG, PrimLocalGet, PrimLessEq, F_GetG_LocalGet_PrimLessEq
    dq PrimGetG, PrimLocalGet, PrimGreaterEq, F_GetG_LocalGet_PrimGreaterEq
    dq PrimGetG, PrimLocalGet, PrimDAdd, F_GetG_LocalGet_PrimDAdd
    dq PrimGetG, PrimLocalGet, PrimDSub, F_GetG_LocalGet_PrimDSub
    dq PrimGetG, PrimLocalGet, PrimDMul, F_GetG_LocalGet_PrimDMul
    dq PrimGetG, PrimLocalGet, PrimDDiv, F_GetG_LocalGet_PrimDDiv
    dq PrimGetG, PrimLocalGet, PrimDFloorDiv, F_GetG_LocalGet_PrimDFloorDiv
    dq PrimGetG, PrimLocalGet, PrimDMod, F_GetG_LocalGet_PrimDMod
    dq PrimGetG, PrimLocalGet, PrimDLess, F_GetG_LocalGet_PrimDLess
    dq PrimGetG, PrimLocalGet, PrimDGreater, F_GetG_LocalGet_PrimDGreater
    dq PrimGetG, PrimLocalGet, PrimDLessEq, F_GetG_LocalGet_PrimDLessEq
    dq PrimGetG, PrimLocalGet, PrimDGreaterEq, F_GetG_LocalGet_PrimDGreaterEq
    dq PrimGetG, PrimLocalGet, PrimDEq, F_GetG_LocalGet_PrimDEq
    dq PrimGetG, PrimLocalGet, PrimDNotEq, F_GetG_LocalGet_PrimDNotEq
    dq PrimGetG, PrimLocalGet, PrimIndex, F_GetG_LocalGet_PrimIndex
    dq PrimGetG, PrimLocalGet, PrimToDecUnder, F_GetG_LocalGet_PrimToDecUnder
    dq PrimGetG, PrimLocalGet, PrimTextEq, F_GetG_LocalGet_PrimTextEq
    dq PrimGetG, PrimLocalGet, PrimConcat, F_GetG_LocalGet_PrimConcat
    dq PrimGetG, PrimLocalGet, PrimLessBr, F_GetG_LocalGet_PrimLessBr
    dq PrimGetG, PrimLocalGet, PrimGreaterBr, F_GetG_LocalGet_PrimGreaterBr
    dq PrimGetG, PrimLocalGet, PrimEqBr, F_GetG_LocalGet_PrimEqBr
    dq PrimGetG, PrimLocalGet, PrimNotEqBr, F_GetG_LocalGet_PrimNotEqBr
    dq PrimGetG, PrimLocalGet, PrimLessEqBr, F_GetG_LocalGet_PrimLessEqBr
    dq PrimGetG, PrimLocalGet, PrimGreaterEqBr, F_GetG_LocalGet_PrimGreaterEqBr
    dq PrimGetG, PrimLocalGet, PrimDLessBr, F_GetG_LocalGet_PrimDLessBr
    dq PrimGetG, PrimLocalGet, PrimDGreaterBr, F_GetG_LocalGet_PrimDGreaterBr
    dq PrimGetG, PrimLocalGet, PrimDLessEqBr, F_GetG_LocalGet_PrimDLessEqBr
    dq PrimGetG, PrimLocalGet, PrimDGreaterEqBr, F_GetG_LocalGet_PrimDGreaterEqBr
    dq PrimGetG, PrimLocalGet, PrimDEqBr, F_GetG_LocalGet_PrimDEqBr
    dq PrimGetG, PrimLocalGet, PrimDNotEqBr, F_GetG_LocalGet_PrimDNotEqBr
    dq PrimLocalGet, PrimGetG, PrimAdd, F_LocalGet_GetG_PrimAdd
    dq PrimLocalGet, PrimGetG, PrimSub, F_LocalGet_GetG_PrimSub
    dq PrimLocalGet, PrimGetG, PrimMul, F_LocalGet_GetG_PrimMul
    dq PrimLocalGet, PrimGetG, PrimDiv, F_LocalGet_GetG_PrimDiv
    dq PrimLocalGet, PrimGetG, PrimFloorDiv, F_LocalGet_GetG_PrimFloorDiv
    dq PrimLocalGet, PrimGetG, PrimMod, F_LocalGet_GetG_PrimMod
    dq PrimLocalGet, PrimGetG, PrimLess, F_LocalGet_GetG_PrimLess
    dq PrimLocalGet, PrimGetG, PrimGreater, F_LocalGet_GetG_PrimGreater
    dq PrimLocalGet, PrimGetG, PrimEq, F_LocalGet_GetG_PrimEq
    dq PrimLocalGet, PrimGetG, PrimNotEq, F_LocalGet_GetG_PrimNotEq
    dq PrimLocalGet, PrimGetG, PrimLessEq, F_LocalGet_GetG_PrimLessEq
    dq PrimLocalGet, PrimGetG, PrimGreaterEq, F_LocalGet_GetG_PrimGreaterEq
    dq PrimLocalGet, PrimGetG, PrimDAdd, F_LocalGet_GetG_PrimDAdd
    dq PrimLocalGet, PrimGetG, PrimDSub, F_LocalGet_GetG_PrimDSub
    dq PrimLocalGet, PrimGetG, PrimDMul, F_LocalGet_GetG_PrimDMul
    dq PrimLocalGet, PrimGetG, PrimDDiv, F_LocalGet_GetG_PrimDDiv
    dq PrimLocalGet, PrimGetG, PrimDFloorDiv, F_LocalGet_GetG_PrimDFloorDiv
    dq PrimLocalGet, PrimGetG, PrimDMod, F_LocalGet_GetG_PrimDMod
    dq PrimLocalGet, PrimGetG, PrimDLess, F_LocalGet_GetG_PrimDLess
    dq PrimLocalGet, PrimGetG, PrimDGreater, F_LocalGet_GetG_PrimDGreater
    dq PrimLocalGet, PrimGetG, PrimDLessEq, F_LocalGet_GetG_PrimDLessEq
    dq PrimLocalGet, PrimGetG, PrimDGreaterEq, F_LocalGet_GetG_PrimDGreaterEq
    dq PrimLocalGet, PrimGetG, PrimDEq, F_LocalGet_GetG_PrimDEq
    dq PrimLocalGet, PrimGetG, PrimDNotEq, F_LocalGet_GetG_PrimDNotEq
    dq PrimLocalGet, PrimGetG, PrimIndex, F_LocalGet_GetG_PrimIndex
    dq PrimLocalGet, PrimGetG, PrimToDecUnder, F_LocalGet_GetG_PrimToDecUnder
    dq PrimLocalGet, PrimGetG, PrimTextEq, F_LocalGet_GetG_PrimTextEq
    dq PrimLocalGet, PrimGetG, PrimConcat, F_LocalGet_GetG_PrimConcat
    dq PrimLocalGet, PrimGetG, PrimLessBr, F_LocalGet_GetG_PrimLessBr
    dq PrimLocalGet, PrimGetG, PrimGreaterBr, F_LocalGet_GetG_PrimGreaterBr
    dq PrimLocalGet, PrimGetG, PrimEqBr, F_LocalGet_GetG_PrimEqBr
    dq PrimLocalGet, PrimGetG, PrimNotEqBr, F_LocalGet_GetG_PrimNotEqBr
    dq PrimLocalGet, PrimGetG, PrimLessEqBr, F_LocalGet_GetG_PrimLessEqBr
    dq PrimLocalGet, PrimGetG, PrimGreaterEqBr, F_LocalGet_GetG_PrimGreaterEqBr
    dq PrimLocalGet, PrimGetG, PrimDLessBr, F_LocalGet_GetG_PrimDLessBr
    dq PrimLocalGet, PrimGetG, PrimDGreaterBr, F_LocalGet_GetG_PrimDGreaterBr
    dq PrimLocalGet, PrimGetG, PrimDLessEqBr, F_LocalGet_GetG_PrimDLessEqBr
    dq PrimLocalGet, PrimGetG, PrimDGreaterEqBr, F_LocalGet_GetG_PrimDGreaterEqBr
    dq PrimLocalGet, PrimGetG, PrimDEqBr, F_LocalGet_GetG_PrimDEqBr
    dq PrimLocalGet, PrimGetG, PrimDNotEqBr, F_LocalGet_GetG_PrimDNotEqBr
    dq PrimGetG, PrimLit, PrimAdd, F_GetG_Lit_PrimAdd
    dq PrimGetG, PrimLit, PrimSub, F_GetG_Lit_PrimSub
    dq PrimGetG, PrimLit, PrimMul, F_GetG_Lit_PrimMul
    dq PrimGetG, PrimLit, PrimDiv, F_GetG_Lit_PrimDiv
    dq PrimGetG, PrimLit, PrimFloorDiv, F_GetG_Lit_PrimFloorDiv
    dq PrimGetG, PrimLit, PrimMod, F_GetG_Lit_PrimMod
    dq PrimGetG, PrimLit, PrimLess, F_GetG_Lit_PrimLess
    dq PrimGetG, PrimLit, PrimGreater, F_GetG_Lit_PrimGreater
    dq PrimGetG, PrimLit, PrimEq, F_GetG_Lit_PrimEq
    dq PrimGetG, PrimLit, PrimNotEq, F_GetG_Lit_PrimNotEq
    dq PrimGetG, PrimLit, PrimLessEq, F_GetG_Lit_PrimLessEq
    dq PrimGetG, PrimLit, PrimGreaterEq, F_GetG_Lit_PrimGreaterEq
    dq PrimGetG, PrimLit, PrimDAdd, F_GetG_Lit_PrimDAdd
    dq PrimGetG, PrimLit, PrimDSub, F_GetG_Lit_PrimDSub
    dq PrimGetG, PrimLit, PrimDMul, F_GetG_Lit_PrimDMul
    dq PrimGetG, PrimLit, PrimDDiv, F_GetG_Lit_PrimDDiv
    dq PrimGetG, PrimLit, PrimDFloorDiv, F_GetG_Lit_PrimDFloorDiv
    dq PrimGetG, PrimLit, PrimDMod, F_GetG_Lit_PrimDMod
    dq PrimGetG, PrimLit, PrimDLess, F_GetG_Lit_PrimDLess
    dq PrimGetG, PrimLit, PrimDGreater, F_GetG_Lit_PrimDGreater
    dq PrimGetG, PrimLit, PrimDLessEq, F_GetG_Lit_PrimDLessEq
    dq PrimGetG, PrimLit, PrimDGreaterEq, F_GetG_Lit_PrimDGreaterEq
    dq PrimGetG, PrimLit, PrimDEq, F_GetG_Lit_PrimDEq
    dq PrimGetG, PrimLit, PrimDNotEq, F_GetG_Lit_PrimDNotEq
    dq PrimGetG, PrimLit, PrimIndex, F_GetG_Lit_PrimIndex
    dq PrimGetG, PrimLit, PrimToDecUnder, F_GetG_Lit_PrimToDecUnder
    dq PrimGetG, PrimLit, PrimTextEq, F_GetG_Lit_PrimTextEq
    dq PrimGetG, PrimLit, PrimConcat, F_GetG_Lit_PrimConcat
    dq PrimGetG, PrimLit, PrimLessBr, F_GetG_Lit_PrimLessBr
    dq PrimGetG, PrimLit, PrimGreaterBr, F_GetG_Lit_PrimGreaterBr
    dq PrimGetG, PrimLit, PrimEqBr, F_GetG_Lit_PrimEqBr
    dq PrimGetG, PrimLit, PrimNotEqBr, F_GetG_Lit_PrimNotEqBr
    dq PrimGetG, PrimLit, PrimLessEqBr, F_GetG_Lit_PrimLessEqBr
    dq PrimGetG, PrimLit, PrimGreaterEqBr, F_GetG_Lit_PrimGreaterEqBr
    dq PrimGetG, PrimLit, PrimDLessBr, F_GetG_Lit_PrimDLessBr
    dq PrimGetG, PrimLit, PrimDGreaterBr, F_GetG_Lit_PrimDGreaterBr
    dq PrimGetG, PrimLit, PrimDLessEqBr, F_GetG_Lit_PrimDLessEqBr
    dq PrimGetG, PrimLit, PrimDGreaterEqBr, F_GetG_Lit_PrimDGreaterEqBr
    dq PrimGetG, PrimLit, PrimDEqBr, F_GetG_Lit_PrimDEqBr
    dq PrimGetG, PrimLit, PrimDNotEqBr, F_GetG_Lit_PrimDNotEqBr
    dq PrimGetG, PrimGetG, PrimAdd, F_GetG_GetG_PrimAdd
    dq PrimGetG, PrimGetG, PrimSub, F_GetG_GetG_PrimSub
    dq PrimGetG, PrimGetG, PrimMul, F_GetG_GetG_PrimMul
    dq PrimGetG, PrimGetG, PrimDiv, F_GetG_GetG_PrimDiv
    dq PrimGetG, PrimGetG, PrimFloorDiv, F_GetG_GetG_PrimFloorDiv
    dq PrimGetG, PrimGetG, PrimMod, F_GetG_GetG_PrimMod
    dq PrimGetG, PrimGetG, PrimLess, F_GetG_GetG_PrimLess
    dq PrimGetG, PrimGetG, PrimGreater, F_GetG_GetG_PrimGreater
    dq PrimGetG, PrimGetG, PrimEq, F_GetG_GetG_PrimEq
    dq PrimGetG, PrimGetG, PrimNotEq, F_GetG_GetG_PrimNotEq
    dq PrimGetG, PrimGetG, PrimLessEq, F_GetG_GetG_PrimLessEq
    dq PrimGetG, PrimGetG, PrimGreaterEq, F_GetG_GetG_PrimGreaterEq
    dq PrimGetG, PrimGetG, PrimDAdd, F_GetG_GetG_PrimDAdd
    dq PrimGetG, PrimGetG, PrimDSub, F_GetG_GetG_PrimDSub
    dq PrimGetG, PrimGetG, PrimDMul, F_GetG_GetG_PrimDMul
    dq PrimGetG, PrimGetG, PrimDDiv, F_GetG_GetG_PrimDDiv
    dq PrimGetG, PrimGetG, PrimDFloorDiv, F_GetG_GetG_PrimDFloorDiv
    dq PrimGetG, PrimGetG, PrimDMod, F_GetG_GetG_PrimDMod
    dq PrimGetG, PrimGetG, PrimDLess, F_GetG_GetG_PrimDLess
    dq PrimGetG, PrimGetG, PrimDGreater, F_GetG_GetG_PrimDGreater
    dq PrimGetG, PrimGetG, PrimDLessEq, F_GetG_GetG_PrimDLessEq
    dq PrimGetG, PrimGetG, PrimDGreaterEq, F_GetG_GetG_PrimDGreaterEq
    dq PrimGetG, PrimGetG, PrimDEq, F_GetG_GetG_PrimDEq
    dq PrimGetG, PrimGetG, PrimDNotEq, F_GetG_GetG_PrimDNotEq
    dq PrimGetG, PrimGetG, PrimIndex, F_GetG_GetG_PrimIndex
    dq PrimGetG, PrimGetG, PrimToDecUnder, F_GetG_GetG_PrimToDecUnder
    dq PrimGetG, PrimGetG, PrimTextEq, F_GetG_GetG_PrimTextEq
    dq PrimGetG, PrimGetG, PrimConcat, F_GetG_GetG_PrimConcat
    dq PrimGetG, PrimGetG, PrimLessBr, F_GetG_GetG_PrimLessBr
    dq PrimGetG, PrimGetG, PrimGreaterBr, F_GetG_GetG_PrimGreaterBr
    dq PrimGetG, PrimGetG, PrimEqBr, F_GetG_GetG_PrimEqBr
    dq PrimGetG, PrimGetG, PrimNotEqBr, F_GetG_GetG_PrimNotEqBr
    dq PrimGetG, PrimGetG, PrimLessEqBr, F_GetG_GetG_PrimLessEqBr
    dq PrimGetG, PrimGetG, PrimGreaterEqBr, F_GetG_GetG_PrimGreaterEqBr
    dq PrimGetG, PrimGetG, PrimDLessBr, F_GetG_GetG_PrimDLessBr
    dq PrimGetG, PrimGetG, PrimDGreaterBr, F_GetG_GetG_PrimDGreaterBr
    dq PrimGetG, PrimGetG, PrimDLessEqBr, F_GetG_GetG_PrimDLessEqBr
    dq PrimGetG, PrimGetG, PrimDGreaterEqBr, F_GetG_GetG_PrimDGreaterEqBr
    dq PrimGetG, PrimGetG, PrimDEqBr, F_GetG_GetG_PrimDEqBr
    dq PrimGetG, PrimGetG, PrimDNotEqBr, F_GetG_GetG_PrimDNotEqBr
    dq 0, 0, 0, 0
BranchTable:
    dq PrimLess, PrimLessBr
    dq PrimGreater, PrimGreaterBr
    dq PrimEq, PrimEqBr
    dq PrimNotEq, PrimNotEqBr
    dq PrimLessEq, PrimLessEqBr
    dq PrimGreaterEq, PrimGreaterEqBr
    dq PrimDLess, PrimDLessBr
    dq PrimDGreater, PrimDGreaterBr
    dq PrimDLessEq, PrimDLessEqBr
    dq PrimDGreaterEq, PrimDGreaterEqBr
    dq PrimDEq, PrimDEqBr
    dq PrimDNotEq, PrimDNotEqBr
    dq 0, 0
StoreTable:
    dq PrimAdd, PrimLocalSet, S_PrimAdd_LocalSet
    dq PrimAdd, PrimSetG, S_PrimAdd_SetG
    dq PrimSub, PrimLocalSet, S_PrimSub_LocalSet
    dq PrimSub, PrimSetG, S_PrimSub_SetG
    dq PrimMul, PrimLocalSet, S_PrimMul_LocalSet
    dq PrimMul, PrimSetG, S_PrimMul_SetG
    dq PrimDAdd, PrimLocalSet, S_PrimDAdd_LocalSet
    dq PrimDAdd, PrimSetG, S_PrimDAdd_SetG
    dq PrimDSub, PrimLocalSet, S_PrimDSub_LocalSet
    dq PrimDSub, PrimSetG, S_PrimDSub_SetG
    dq PrimDMul, PrimLocalSet, S_PrimDMul_LocalSet
    dq PrimDMul, PrimSetG, S_PrimDMul_SetG
    dq PrimDDiv, PrimLocalSet, S_PrimDDiv_LocalSet
    dq PrimDDiv, PrimSetG, S_PrimDDiv_SetG
    dq 0, 0, 0
