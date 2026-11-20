%include "macros.inc"

global PrimSayText
global PrimConcat
global PrimToText
global PrimToNumber
global PrimTextEq
global PrimAsk
global PrimRandom
global PrimMakeList
global PrimIndex
global PrimSetIndex
global PrimListAdd
global PrimLength
extern PrintString
extern PrintNewLine
extern ReadLine
extern InputBuf
extern Abort

section .data
HeapHere     dq HeapSpace
ErrIndex     db "list index out of range", 10
ErrIndexLen  equ $ - ErrIndex

section .bss
HeapSpace resb 16777216
RandState resq 1
TmpBuf    resb 24

section .text
Alloc:
    mov rax, [rel HeapHere]
    add rcx, 7
    and rcx, -8
    lea r8, [rax + rcx]
    mov [rel HeapHere], r8
    ret

MemCopy:
    xor r9d, r9d
.Loop:
    cmp r9, r8
    jae .Done
    mov r10b, [rcx + r9]
    mov [rdx + r9], r10b
    inc r9
    jmp .Loop
.Done:
    ret

PrimSayText:
    DPop rax
    lea rcx, [rax + 8]
    mov rdx, [rax]
    call PrintString
    call PrintNewLine
    NEXT

PrimConcat:
    DPop rdi
    DPop rsi
    mov rcx, [rsi]
    add rcx, [rdi]
    add rcx, 8
    call Alloc
    mov rbx, rax
    mov rdx, [rsi]
    add rdx, [rdi]
    mov [rbx], rdx
    lea rcx, [rsi + 8]
    lea rdx, [rbx + 8]
    mov r8, [rsi]
    call MemCopy
    lea rcx, [rdi + 8]
    lea rdx, [rbx + 8]
    add rdx, [rsi]
    mov r8, [rdi]
    call MemCopy
    DPush rbx
    NEXT

PrimToText:
    DPop rax
    mov r11, rax
    test rax, rax
    jns .Positive
    neg rax
.Positive:
    lea rsi, [rel TmpBuf + 24]
    mov rdi, rsi
    mov r8, 10
.Loop:
    xor edx, edx
    div r8
    add dl, '0'
    dec rsi
    mov [rsi], dl
    test rax, rax
    jnz .Loop
    test r11, r11
    jns .Make
    dec rsi
    mov byte [rsi], '-'
.Make:
    sub rdi, rsi
    lea rcx, [rdi + 8]
    call Alloc
    mov rbx, rax
    mov [rbx], rdi
    mov rcx, rsi
    lea rdx, [rbx + 8]
    mov r8, rdi
    call MemCopy
    DPush rbx
    NEXT

PrimToNumber:
    DPop rsi
    mov rcx, [rsi]
    lea rsi, [rsi + 8]
    xor eax, eax
    xor ebx, ebx
    test rcx, rcx
    jz .Done
    cmp byte [rsi], '-'
    jne .Loop
    mov ebx, 1
    inc rsi
    dec rcx
.Loop:
    test rcx, rcx
    jz .Done
    movzx edx, byte [rsi]
    sub edx, '0'
    cmp edx, 9
    ja .Done
    imul rax, rax, 10
    add rax, rdx
    inc rsi
    dec rcx
    jmp .Loop
.Done:
    test rbx, rbx
    jz .Push
    neg rax
.Push:
    DPush rax
    NEXT

PrimTextEq:
    DPop rdi
    DPop rsi
    xor eax, eax
    mov rcx, [rsi]
    cmp rcx, [rdi]
    jne .Push
    xor edx, edx
.Loop:
    cmp rdx, rcx
    jae .Same
    mov r8b, [rsi + 8 + rdx]
    cmp r8b, [rdi + 8 + rdx]
    jne .Push
    inc rdx
    jmp .Loop
.Same:
    mov eax, 1
.Push:
    DPush rax
    NEXT

PrimAsk:
    DPop rax
    test rax, rax
    jz .Read
    lea rcx, [rax + 8]
    mov rdx, [rax]
    call PrintString
.Read:
    call ReadLine
    mov rdi, rax
    lea rcx, [rax + 8]
    call Alloc
    mov rbx, rax
    mov [rbx], rdi
    lea rcx, [rel InputBuf]
    lea rdx, [rbx + 8]
    mov r8, rdi
    call MemCopy
    DPush rbx
    NEXT

PrimRandom:
    DPop rbx
    DPop rsi
    mov rax, [rel RandState]
    test rax, rax
    jnz .Have
    rdtsc
    shl rdx, 32
    or rax, rdx
    or rax, 1
.Have:
    mov rdx, rax
    shl rdx, 13
    xor rax, rdx
    mov rdx, rax
    shr rdx, 7
    xor rax, rdx
    mov rdx, rax
    shl rdx, 17
    xor rax, rdx
    mov [rel RandState], rax
    mov rcx, rbx
    sub rcx, rsi
    inc rcx
    cmp rcx, 0
    jle .Low
    xor edx, edx
    div rcx
    lea rax, [rsi + rdx]
    DPush rax
    NEXT
.Low:
    DPush rsi
    NEXT

PrimMakeList:
    DPop rbx
    mov ecx, 24
    call Alloc
    mov rdi, rax
    mov rcx, rbx
    cmp rcx, 4
    jae .Cap
    mov ecx, 4
.Cap:
    mov [rdi + 8], rcx
    shl rcx, 3
    call Alloc
    mov [rdi + 16], rax
    mov [rdi], rbx
    mov r8, rbx
    shl r8, 3
    sub r15, r8
    mov rcx, r15
    mov rdx, [rdi + 16]
    call MemCopy
    DPush rdi
    NEXT

PrimIndex:
    DPop rbx
    DPop rax
    cmp rbx, 1
    jl IndexError
    cmp rbx, [rax]
    jg IndexError
    mov rcx, [rax + 16]
    mov rax, [rcx + rbx * 8 - 8]
    DPush rax
    NEXT

PrimSetIndex:
    DPop rsi
    DPop rbx
    DPop rax
    cmp rbx, 1
    jl IndexError
    cmp rbx, [rax]
    jg IndexError
    mov rcx, [rax + 16]
    mov [rcx + rbx * 8 - 8], rsi
    NEXT

IndexError:
    lea rcx, [rel ErrIndex]
    mov edx, ErrIndexLen
    jmp Abort

PrimListAdd:
    DPop rsi
    DPop rdi
    mov rax, [rdi]
    cmp rax, [rdi + 8]
    jb .Room
    mov rcx, [rdi + 8]
    shl rcx, 4
    call Alloc
    mov rbx, rax
    mov rcx, [rdi + 16]
    mov rdx, rbx
    mov r8, [rdi]
    shl r8, 3
    call MemCopy
    mov [rdi + 16], rbx
    shl qword [rdi + 8], 1
.Room:
    mov rax, [rdi]
    mov rcx, [rdi + 16]
    mov [rcx + rax * 8], rsi
    inc qword [rdi]
    NEXT

PrimLength:
    DPop rax
    mov rax, [rax]
    DPush rax
    NEXT
