%include "macros.inc"

global PrimSayText
extern Alloc
extern MakeTextFrom
extern Utf8Offset
global PrimConcat
global PrimJoin
global PrimToText
global PrimToNumber
global PrimTextEq
global PrimTextCompare
global PrimAsk
global PrimRandom
global PrimMakeList
global PrimIndex
global PrimSetIndex
global PrimListAdd
global PrimTextSlice
global PrimListSlice
global PrimListInsert
global PrimListRemove
global PrimListPop
global PrimListCopy
global PrimLength
extern PrintString
extern PrintNewLine
extern ReadLine
extern InputBuf
extern Abort

section .data
ErrNotNumber db "that text isn't a whole number"
ErrNotNumberLen equ $ - ErrNotNumber
ErrIndex     db "list index out of range"
ErrIndexLen  equ $ - ErrIndex
ErrEmptyList db "can't take from an empty list"
ErrEmptyListLen equ $ - ErrEmptyList
ErrTextRange db "text index out of range"
ErrTextRangeLen equ $ - ErrTextRange

section .bss
RandState resq 1
TmpBuf    resb 24

section .text
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
.TrimStart:
    test rcx, rcx
    jz .Bad
    cmp byte [rsi], ' '
    jne .TrimEnd
    inc rsi
    dec rcx
    jmp .TrimStart
.TrimEnd:
    cmp byte [rsi + rcx - 1], ' '
    jne .Trimmed
    dec rcx
    jmp .TrimEnd
.Trimmed:
    xor eax, eax
    xor ebx, ebx
    cmp byte [rsi], '-'
    je .Minus
    cmp byte [rsi], '+'
    jne .First
    jmp .Sign
.Minus:
    mov ebx, 1
.Sign:
    inc rsi
    dec rcx
.First:
    test rcx, rcx
    jz .Bad
.Loop:
    test rcx, rcx
    jz .Done
    movzx edx, byte [rsi]
    sub edx, '0'
    cmp edx, 9
    ja .Bad
    imul rax, rax, 10
    jo .Bad
    add rax, rdx
    jo .Bad
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
.Bad:
    lea rcx, [rel ErrNotNumber]
    mov edx, ErrNotNumberLen
    jmp Abort

PrimTextCompare:
    DPop rdi
    DPop rsi
    mov rcx, [rsi]
    mov r9, [rdi]
    cmp rcx, r9
    cmova rcx, r9
    xor edx, edx
.Loop:
    cmp rdx, rcx
    jae .Prefix
    mov r8b, [rsi + 8 + rdx]
    cmp r8b, [rdi + 8 + rdx]
    jb .Less
    ja .More
    inc rdx
    jmp .Loop
.Prefix:
    mov rax, [rsi]
    cmp rax, r9
    jb .Less
    ja .More
    xor eax, eax
    jmp .Push
.Less:
    mov rax, -1
    jmp .Push
.More:
    mov eax, 1
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

PrimListCopy:
    mov ecx, 24
    call Alloc
    mov qword [rax], 0
    mov qword [rax + 16], 0
    push rax
    push rax
    mov rdx, [r15 - 8]
    mov rcx, [rdx]
    cmp rcx, 4
    jae .Cap
    mov ecx, 4
.Cap:
    mov [rax + 8], rcx
    shl rcx, 3
    call Alloc
    pop rdi
    pop rdi
    mov [rdi + 16], rax
    mov rsi, [r15 - 8]
    mov r8, [rsi]
    mov [rdi], r8
    mov rcx, [rsi + 16]
    mov rdx, rax
    shl r8, 3
    call MemCopy
    mov [r15 - 8], rdi
    NEXT

PrimListPop:
    DPop rax
    mov rcx, [rax]
    test rcx, rcx
    jz EmptyList
    dec rcx
    mov [rax], rcx
    mov rdx, [rax + 16]
    mov rax, [rdx + rcx * 8]
    mov qword [rdx + rcx * 8], 0
    DPush rax
    NEXT

EmptyList:
    lea rcx, [rel ErrEmptyList]
    mov edx, ErrEmptyListLen
    jmp Abort

PrimListRemove:
    DPop rbx
    DPop rax
    cmp rbx, 1
    jl IndexError
    cmp rbx, [rax]
    jg IndexError
    mov rdx, [rax + 16]
    mov rsi, [rdx + rbx * 8 - 8]
    mov rcx, [rax]
.Shift:
    cmp rbx, rcx
    jae .Done
    mov r8, [rdx + rbx * 8]
    mov [rdx + rbx * 8 - 8], r8
    inc rbx
    jmp .Shift
.Done:
    dec rcx
    mov [rax], rcx
    mov qword [rdx + rcx * 8], 0
    DPush rsi
    NEXT

PrimListInsert:
    DPop rsi
    DPop rbx
    DPop rdi
    cmp rbx, 1
    jl IndexError
    mov rax, [rdi]
    inc rax
    cmp rbx, rax
    jg IndexError
    mov rax, [rdi]
    cmp rax, [rdi + 8]
    jb .Room
    mov rcx, [rdi + 8]
    shl rcx, 4
    call Alloc
    push rax
    push rax
    mov rcx, [rdi + 16]
    mov rdx, rax
    mov r8, [rdi]
    shl r8, 3
    call MemCopy
    pop rax
    pop rax
    mov [rdi + 16], rax
    shl qword [rdi + 8], 1
.Room:
    mov rcx, [rdi]
    mov rdx, [rdi + 16]
.Up:
    cmp rcx, rbx
    jl .Put
    mov r8, [rdx + rcx * 8 - 8]
    mov [rdx + rcx * 8], r8
    dec rcx
    jmp .Up
.Put:
    mov [rdx + rbx * 8 - 8], rsi
    inc qword [rdi]
    NEXT

PrimListSlice:
    DPop rsi
    DPop rbx
    mov rax, [r15 - 8]
    cmp rbx, 1
    jl IndexError
    cmp rsi, [rax]
    jg IndexError
    mov rdi, rsi
    sub rdi, rbx
    inc rdi
    jg .Sized
    xor edi, edi
.Sized:
    mov ecx, 24
    call Alloc
    mov qword [rax], 0
    mov qword [rax + 16], 0
    push rax
    push rax
    mov rcx, rdi
    cmp rcx, 4
    jae .Cap
    mov ecx, 4
.Cap:
    mov [rax + 8], rcx
    shl rcx, 3
    call Alloc
    pop rdx
    pop rdx
    mov [rdx + 16], rax
    mov [rdx], rdi
    mov rsi, [r15 - 8]
    mov rcx, [rsi + 16]
    lea rcx, [rcx + rbx * 8 - 8]
    mov r8, rdi
    shl r8, 3
    mov rsi, rdx
    mov rdx, rax
    call MemCopy
    mov [r15 - 8], rsi
    NEXT

PrimTextSlice:
    DPop rsi
    DPop rbx
    cmp rbx, 1
    jl TextSliceError
    cmp rsi, rbx
    jge .Range
    mov rsi, rbx
    dec rsi
.Range:
    mov rcx, [r15 - 8]
    mov rdx, rbx
    call Utf8Offset
    cmp rax, -1
    je TextSliceError
    push rax
    push rax
    mov rcx, [r15 - 8]
    lea rdx, [rsi + 1]
    call Utf8Offset
    pop rcx
    pop rcx
    cmp rax, -1
    je TextSliceError
    mov rdx, rax
    sub rdx, rcx
    mov rax, [r15 - 8]
    lea rcx, [rax + 8 + rcx]
    call MakeTextFrom
    mov [r15 - 8], rax
    NEXT

TextSliceError:
    lea rcx, [rel ErrTextRange]
    mov edx, ErrTextRangeLen
    jmp Abort

PrimLength:
    DPop rax
    mov rax, [rax]
    DPush rax
    NEXT

PrimJoin:
    mov rsi, [r15 - 16]
    mov rdi, [r15 - 8]
    mov rcx, [rsi]
    mov r8, [rsi + 16]
    xor eax, eax
    xor edx, edx
.Size:
    cmp rdx, rcx
    jae .Sized
    mov r9, [r8 + rdx * 8]
    add rax, [r9]
    inc rdx
    jmp .Size
.Sized:
    test rcx, rcx
    jz .NoSep
    dec rcx
    imul rcx, [rdi]
    add rax, rcx
.NoSep:
    push rax
    push rax
    lea rcx, [rax + 8]
    call Alloc
    mov rbx, rax
    pop rax
    pop rax
    mov [rbx], rax
    lea rax, [rbx + 8]
    push rax
    push 0
.Copy:
    mov rsi, [r15 - 16]
    mov rdx, [rsp]
    cmp rdx, [rsi]
    jae .Done
    test rdx, rdx
    jz .Item
    mov rdi, [r15 - 8]
    lea rcx, [rdi + 8]
    mov rdx, [rsp + 8]
    mov r8, [rdi]
    add [rsp + 8], r8
    call MemCopy
    mov rsi, [r15 - 16]
    mov rdx, [rsp]
.Item:
    mov r8, [rsi + 16]
    mov rdi, [r8 + rdx * 8]
    lea rcx, [rdi + 8]
    mov rdx, [rsp + 8]
    mov r8, [rdi]
    add [rsp + 8], r8
    call MemCopy
    inc qword [rsp]
    jmp .Copy
.Done:
    add rsp, 16
    sub r15, 8
    mov [r15 - 8], rbx
    NEXT
