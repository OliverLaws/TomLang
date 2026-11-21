%include "macros.inc"

global PrimMakeMap
global PrimMapGet
global PrimMapSet
global PrimMapHas
global PrimMapKeys
global PrimMakeRecord
global PrimGetField
global PrimSetField
global PrimListHas
global PrimListHasText
global PrimTextHas
global PrimRange
global PrimTextAt
global PrimCode
global PrimChar
global PrimBitAnd
global PrimBitOr
global PrimBitXor
global PrimShiftLeft
global PrimShiftRight
extern Alloc
extern Abort
extern MakeTextFrom

section .data
ErrNoKey     db "that key isn't in the map"
ErrNoKeyLen  equ $ - ErrNoKey
ErrIndex     db "text index out of range"
ErrIndexLen  equ $ - ErrIndex

section .bss
CharBuf resb 8

section .text
TextEqual:
    mov rax, [rcx]
    cmp rax, [rdx]
    jne .No
    xor r8d, r8d
.Loop:
    cmp r8, rax
    jae .Yes
    mov r9b, [rcx + 8 + r8]
    cmp r9b, [rdx + 8 + r8]
    jne .No
    inc r8
    jmp .Loop
.Yes:
    mov eax, 1
    ret
.No:
    xor eax, eax
    ret

MapFind:
    push rbx
    push rsi
    push rdi
    mov rbx, rcx
    mov rsi, rdx
    xor edi, edi
.Loop:
    cmp rdi, [rbx]
    jae .None
    mov rcx, [rbx + 16]
    mov rcx, [rcx + rdi * 8]
    mov rdx, rsi
    call TextEqual
    test eax, eax
    jnz .Found
    inc rdi
    jmp .Loop
.Found:
    mov rax, rdi
    jmp .Done
.None:
    mov rax, -1
.Done:
    pop rdi
    pop rsi
    pop rbx
    ret

NewMap:
    push rbx
    mov rbx, rcx
    cmp rbx, 4
    jae .Cap
    mov ebx, 4
.Cap:
    mov ecx, 32
    call Alloc
    push rax
    mov qword [rax], 0
    mov [rax + 8], rbx
    lea rcx, [rbx * 8]
    call Alloc
    mov rdx, [rsp]
    mov [rdx + 16], rax
    lea rcx, [rbx * 8]
    call Alloc
    pop rdx
    mov [rdx + 24], rax
    mov rax, rdx
    pop rbx
    ret

MapPut:
    push rbx
    push rsi
    push rdi
    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8
    mov rcx, rbx
    mov rdx, rsi
    call MapFind
    cmp rax, -1
    je .Insert
    mov rcx, [rbx + 24]
    mov [rcx + rax * 8], rdi
    jmp .Done
.Insert:
    mov rax, [rbx]
    cmp rax, [rbx + 8]
    jb .Room
    push r12
    push r13
    mov r12, [rbx + 8]
    shl r12, 1
    lea rcx, [r12 * 8]
    call Alloc
    mov r13, rax
    xor ecx, ecx
.CopyKeys:
    cmp rcx, [rbx]
    jae .KeysDone
    mov rdx, [rbx + 16]
    mov rdx, [rdx + rcx * 8]
    mov [r13 + rcx * 8], rdx
    inc rcx
    jmp .CopyKeys
.KeysDone:
    mov [rbx + 16], r13
    lea rcx, [r12 * 8]
    call Alloc
    mov r13, rax
    xor ecx, ecx
.CopyVals:
    cmp rcx, [rbx]
    jae .ValsDone
    mov rdx, [rbx + 24]
    mov rdx, [rdx + rcx * 8]
    mov [r13 + rcx * 8], rdx
    inc rcx
    jmp .CopyVals
.ValsDone:
    mov [rbx + 24], r13
    mov [rbx + 8], r12
    pop r13
    pop r12
.Room:
    mov rax, [rbx]
    mov rcx, [rbx + 16]
    mov [rcx + rax * 8], rsi
    mov rcx, [rbx + 24]
    mov [rcx + rax * 8], rdi
    inc qword [rbx]
.Done:
    pop rdi
    pop rsi
    pop rbx
    ret

PrimMakeMap:
    DPop rcx
    push rcx
    call NewMap
    pop rcx
    mov rbx, rax
    mov rsi, rcx
    shl rcx, 4
    sub r15, rcx
    mov rdi, r15
.Loop:
    test rsi, rsi
    jz .Done
    mov rcx, rbx
    mov rdx, [rdi]
    mov r8, [rdi + 8]
    call MapPut
    add rdi, 16
    dec rsi
    jmp .Loop
.Done:
    DPush rbx
    NEXT

PrimMapGet:
    DPop rdx
    DPop rbx
    mov rcx, rbx
    call MapFind
    cmp rax, -1
    je .Missing
    mov rcx, [rbx + 24]
    mov rax, [rcx + rax * 8]
    DPush rax
    NEXT
.Missing:
    lea rcx, [rel ErrNoKey]
    mov edx, ErrNoKeyLen
    jmp Abort

PrimMapSet:
    DPop r8
    DPop rdx
    DPop rcx
    call MapPut
    NEXT

PrimMapHas:
    DPop rcx
    DPop rdx
    call MapFind
    xor ecx, ecx
    cmp rax, -1
    setne cl
    DPush rcx
    NEXT

PrimMapKeys:
    DPop rbx
    mov ecx, 24
    call Alloc
    mov rdi, rax
    mov rcx, [rbx]
    mov [rdi], rcx
    cmp rcx, 4
    jae .Cap
    mov ecx, 4
.Cap:
    mov [rdi + 8], rcx
    shl rcx, 3
    call Alloc
    mov [rdi + 16], rax
    xor ecx, ecx
.Copy:
    cmp rcx, [rbx]
    jae .Done
    mov rdx, [rbx + 16]
    mov rdx, [rdx + rcx * 8]
    mov [rax + rcx * 8], rdx
    inc rcx
    jmp .Copy
.Done:
    DPush rdi
    NEXT

PrimMakeRecord:
    mov rbx, [r14]
    add r14, 8
    lea rcx, [rbx * 8]
    test rcx, rcx
    jnz .Size
    mov ecx, 8
.Size:
    call Alloc
    mov rdi, rax
    mov rsi, rbx
.Loop:
    test rsi, rsi
    jz .Done
    dec rsi
    mov rcx, [r14 + rsi * 8]
    DPop rax
    mov [rdi + rcx * 8], rax
    jmp .Loop
.Done:
    lea r14, [r14 + rbx * 8]
    DPush rdi
    NEXT

PrimGetField:
    mov rcx, [r14]
    add r14, 8
    DPop rax
    mov rax, [rax + rcx]
    DPush rax
    NEXT

PrimSetField:
    mov rcx, [r14]
    add r14, 8
    DPop rdx
    DPop rax
    mov [rax + rcx], rdx
    NEXT

PrimListHas:
    DPop rbx
    DPop rax
    mov rcx, [rbx + 16]
    xor edx, edx
.Loop:
    cmp rdx, [rbx]
    jae .No
    cmp rax, [rcx + rdx * 8]
    je .Yes
    inc rdx
    jmp .Loop
.Yes:
    DPush 1
    NEXT
.No:
    DPush 0
    NEXT

PrimListHasText:
    DPop rbx
    DPop rsi
    xor edi, edi
.Loop:
    cmp rdi, [rbx]
    jae .No
    mov rcx, [rbx + 16]
    mov rcx, [rcx + rdi * 8]
    mov rdx, rsi
    call TextEqual
    test eax, eax
    jnz .Yes
    inc rdi
    jmp .Loop
.Yes:
    DPush 1
    NEXT
.No:
    DPush 0
    NEXT

PrimTextHas:
    DPop rbx
    DPop rsi
    mov r8, [rsi]
    mov r9, [rbx]
    xor ecx, ecx
.Outer:
    mov rax, r9
    sub rax, r8
    cmp rcx, rax
    jg .No
    xor edx, edx
.Inner:
    cmp rdx, r8
    jae .Yes
    lea rax, [rcx + rdx]
    mov r10b, [rbx + 8 + rax]
    cmp r10b, [rsi + 8 + rdx]
    jne .Next
    inc rdx
    jmp .Inner
.Next:
    inc rcx
    jmp .Outer
.Yes:
    DPush 1
    NEXT
.No:
    DPush 0
    NEXT

PrimRange:
    DPop rsi
    DPop rbx
    mov rdi, rsi
    sub rdi, rbx
    inc rdi
    test rdi, rdi
    jg .Sized
    xor edi, edi
.Sized:
    mov ecx, 24
    call Alloc
    push rax
    mov [rax], rdi
    mov rcx, rdi
    cmp rcx, 4
    jae .Cap
    mov ecx, 4
.Cap:
    mov [rax + 8], rcx
    shl rcx, 3
    call Alloc
    pop rdx
    mov [rdx + 16], rax
    xor ecx, ecx
.Fill:
    cmp rcx, rdi
    jae .Done
    lea r8, [rbx + rcx]
    mov [rax + rcx * 8], r8
    inc rcx
    jmp .Fill
.Done:
    DPush rdx
    NEXT

PrimTextAt:
    DPop rcx
    DPop rax
    cmp rcx, 1
    jl .Bad
    cmp rcx, [rax]
    jg .Bad
    lea rcx, [rax + 7 + rcx]
    mov edx, 1
    call MakeTextFrom
    DPush rax
    NEXT
.Bad:
    lea rcx, [rel ErrIndex]
    mov edx, ErrIndexLen
    jmp Abort

PrimCode:
    DPop rax
    xor ecx, ecx
    cmp qword [rax], 0
    je .Push
    movzx ecx, byte [rax + 8]
.Push:
    DPush rcx
    NEXT

PrimChar:
    DPop rax
    mov [rel CharBuf], al
    lea rcx, [rel CharBuf]
    mov edx, 1
    call MakeTextFrom
    DPush rax
    NEXT

%macro BitOp 2
%1:
    DPop rax
    DPop rbx
    %2 rbx, rax
    DPush rbx
    NEXT
%endmacro

BitOp PrimBitAnd, and
BitOp PrimBitOr, or
BitOp PrimBitXor, xor

PrimShiftLeft:
    DPop rcx
    DPop rax
    shl rax, cl
    DPush rax
    NEXT

PrimShiftRight:
    DPop rcx
    DPop rax
    sar rax, cl
    DPush rax
    NEXT
