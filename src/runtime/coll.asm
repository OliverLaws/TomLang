%include "macros.inc"

global PrimMakeMap
global PrimMakeIface
global PrimIfaceCall
global PrimMapHasInt
global PrimMapSetInt
global PrimMapGetInt
global PrimMakeMapInt
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
global PrimTextLength
global PrimTextChars
global Utf8Offset
global U8Text
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
ErrCharRange db "charFrom needs a number from 0 to 1114111"
ErrCharRangeLen equ $ - ErrCharRange
ErrNoKey     db "that key isn't in the dictionary"
ErrNoKeyLen  equ $ - ErrNoKey
ErrIndex     db "text index out of range"
ErrIndexLen  equ $ - ErrIndex

section .bss
CharBuf resb 8
U8Text resq 1
U8Index resq 1
U8Off resq 1

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

KeyHash:
    test r8, r8
    jnz .Int
    mov rax, 0xcbf29ce484222325
    mov r10, [rdx]
    xor r11d, r11d
.Byte:
    cmp r11, r10
    jae .Done
    movzx r9d, byte [rdx + 8 + r11]
    xor rax, r9
    mov r9, 0x100000001b3
    imul rax, r9
    inc r11
    jmp .Byte
.Int:
    mov rax, rdx
    mov r9, 0x9E3779B97F4A7C15
    imul rax, r9
    mov r9, rax
    shr r9, 29
    xor rax, r9
.Done:
    ret

KeyEqual:
    test r8, r8
    jnz .Int
    jmp TextEqual
.Int:
    xor eax, eax
    cmp rcx, rdx
    sete al
    ret

MapFind:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    mov rbx, rcx
    mov rsi, rdx
    mov r12, r8
    cmp qword [rbx + 32], 0
    jne .Hashed
    xor edi, edi
.Loop:
    cmp rdi, [rbx]
    jae .None
    mov rcx, [rbx + 16]
    mov rcx, [rcx + rdi * 8]
    mov rdx, rsi
    mov r8, r12
    call KeyEqual
    test eax, eax
    jnz .Found
    inc rdi
    jmp .Loop
.Hashed:
    mov rdx, rsi
    mov r8, r12
    call KeyHash
    mov r13, [rbx + 40]
    dec r13
    and rax, r13
    mov rdi, rax
.Probe:
    mov rax, [rbx + 32]
    mov rax, [rax + rdi * 8]
    test rax, rax
    jz .None
    dec rax
    push rax
    mov rcx, [rbx + 16]
    mov rcx, [rcx + rax * 8]
    mov rdx, rsi
    mov r8, r12
    call KeyEqual
    pop rcx
    test eax, eax
    jnz .FoundSlot
    inc rdi
    and rdi, r13
    jmp .Probe
.FoundSlot:
    mov rax, rcx
    jmp .Done
.Found:
    mov rax, rdi
    jmp .Done
.None:
    mov rax, -1
.Done:
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

MapIndexAdd:
    push rbx
    push rsi
    mov rbx, rcx
    mov rsi, rdx
    mov rcx, [rbx + 16]
    mov rdx, [rcx + rsi * 8]
    call KeyHash
    mov r9, [rbx + 40]
    dec r9
    and rax, r9
    mov rcx, [rbx + 32]
.Probe:
    cmp qword [rcx + rax * 8], 0
    je .Put
    inc rax
    and rax, r9
    jmp .Probe
.Put:
    lea rdx, [rsi + 1]
    mov [rcx + rax * 8], rdx
    pop rsi
    pop rbx
    ret

MapRehash:
    push rbx
    push rsi
    push r12
    push r13
    mov rbx, rcx
    mov r12, r8
    mov r13, 32
.Size:
    mov rax, [rbx]
    shl rax, 2
    cmp r13, rax
    jae .Sized
    shl r13, 1
    jmp .Size
.Sized:
    lea rcx, [r13 * 8]
    call Alloc
    xor ecx, ecx
.Zero:
    cmp rcx, r13
    jae .Zeroed
    mov qword [rax + rcx * 8], 0
    inc rcx
    jmp .Zero
.Zeroed:
    mov [rbx + 32], rax
    mov [rbx + 40], r13
    xor esi, esi
.Fill:
    cmp rsi, [rbx]
    jae .Done
    mov rcx, rbx
    mov rdx, rsi
    mov r8, r12
    call MapIndexAdd
    inc rsi
    jmp .Fill
.Done:
    pop r13
    pop r12
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
    mov ecx, 48
    call Alloc
    push rax
    mov qword [rax], 0
    mov [rax + 8], rbx
    mov qword [rax + 16], 0
    mov qword [rax + 24], 0
    mov qword [rax + 32], 0
    mov qword [rax + 40], 0
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
    push r12
    mov rbx, rcx
    mov rsi, rdx
    mov rdi, r8
    mov r12, r9
    mov rcx, rbx
    mov rdx, rsi
    mov r8, r12
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
    push r13
    push r14
    mov r13, [rbx + 8]
    shl r13, 1
    lea rcx, [r13 * 8]
    call Alloc
    mov r14, rax
    xor ecx, ecx
.CopyKeys:
    cmp rcx, [rbx]
    jae .KeysDone
    mov rdx, [rbx + 16]
    mov rdx, [rdx + rcx * 8]
    mov [r14 + rcx * 8], rdx
    inc rcx
    jmp .CopyKeys
.KeysDone:
    mov [rbx + 16], r14
    lea rcx, [r13 * 8]
    call Alloc
    mov r14, rax
    xor ecx, ecx
.CopyVals:
    cmp rcx, [rbx]
    jae .ValsDone
    mov rdx, [rbx + 24]
    mov rdx, [rdx + rcx * 8]
    mov [r14 + rcx * 8], rdx
    inc rcx
    jmp .CopyVals
.ValsDone:
    mov [rbx + 24], r14
    mov [rbx + 8], r13
    pop r14
    pop r13
.Room:
    mov rax, [rbx]
    mov rcx, [rbx + 16]
    mov [rcx + rax * 8], rsi
    mov rcx, [rbx + 24]
    mov [rcx + rax * 8], rdi
    inc qword [rbx]
    mov rax, [rbx]
    cmp qword [rbx + 32], 0
    jne .HasIndex
    cmp rax, 8
    jb .Done
    mov rcx, rbx
    mov r8, r12
    call MapRehash
    jmp .Done
.HasIndex:
    shl rax, 1
    cmp rax, [rbx + 40]
    jbe .AddOne
    mov rcx, rbx
    mov r8, r12
    call MapRehash
    jmp .Done
.AddOne:
    mov rcx, rbx
    mov rdx, [rbx]
    dec rdx
    mov r8, r12
    call MapIndexAdd
.Done:
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

PrimMakeMapInt:
    mov r12, 1
    jmp MakeMapCommon
PrimMakeMap:
    xor r12d, r12d
MakeMapCommon:
    DPop rcx
    push r12
    push rcx
    call NewMap
    pop rcx
    pop r12
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
    mov r9, r12
    call MapPut
    add rdi, 16
    dec rsi
    jmp .Loop
.Done:
    DPush rbx
    NEXT

PrimMapGetInt:
    mov r8d, 1
    jmp MapGetCommon
PrimMapGet:
    xor r8d, r8d
MapGetCommon:
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

PrimMapSetInt:
    mov r9d, 1
    jmp MapSetCommon
PrimMapSet:
    xor r9d, r9d
MapSetCommon:
    DPop r8
    DPop rdx
    DPop rcx
    call MapPut
    NEXT

PrimMapHasInt:
    mov r8d, 1
    jmp MapHasCommon
PrimMapHas:
    xor r8d, r8d
MapHasCommon:
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

Utf8Offset:
    cmp rcx, [rel U8Text]
    jne .Fresh
    mov r8, [rel U8Index]
    mov r9, [rel U8Off]
    cmp rdx, r8
    jae .Scan
    test rdx, rdx
    jz .Fresh
.Back:
    dec r9
.BackCont:
    test r9, r9
    jz .BackStep
    movzx eax, byte [rcx + 8 + r9]
    and eax, 0xC0
    cmp eax, 0x80
    jne .BackStep
    dec r9
    jmp .BackCont
.BackStep:
    dec r8
    cmp r8, rdx
    ja .Back
    jmp .Found
.Fresh:
    mov [rel U8Text], rcx
    mov r8, 1
    xor r9d, r9d
.Scan:
    mov r10, [rcx]
.Loop:
    cmp r9, r10
    jae .None
    cmp r8, rdx
    je .Found
    inc r9
.Cont:
    cmp r9, r10
    jae .Step
    movzx eax, byte [rcx + 8 + r9]
    and eax, 0xC0
    cmp eax, 0x80
    jne .Step
    inc r9
    jmp .Cont
.Step:
    inc r8
    jmp .Loop
.Found:
    mov [rel U8Index], r8
    mov [rel U8Off], r9
    mov rax, r9
    ret
.None:
    cmp r8, rdx
    jne .Bad
    mov rax, r9
    ret
.Bad:
    mov qword [rel U8Text], 0
    mov rax, -1
    ret

CharBytes:
    movzx eax, byte [rcx + 8 + rdx]
    mov r8d, 1
    cmp eax, 0xC0
    jb .Done
    mov r8d, 2
    cmp eax, 0xE0
    jb .Done
    mov r8d, 3
    cmp eax, 0xF0
    jb .Done
    mov r8d, 4
.Done:
    mov rax, [rcx]
    sub rax, rdx
    cmp r8, rax
    jbe .Ok
    mov r8, rax
.Ok:
    mov rax, r8
    ret

Utf8Count:
    mov r10, [rcx]
    xor eax, eax
    xor r9d, r9d
.Loop:
    cmp r9, r10
    jae .Done
    movzx edx, byte [rcx + 8 + r9]
    and edx, 0xC0
    cmp edx, 0x80
    je .Next
    inc rax
.Next:
    inc r9
    jmp .Loop
.Done:
    ret

PrimTextLength:
    mov rcx, [r15 - 8]
    call Utf8Count
    mov [r15 - 8], rax
    NEXT

PrimTextAt:
    DPop rdx
    mov rcx, [r15 - 8]
    cmp rdx, 1
    jl .Bad
    call Utf8Offset
    cmp rax, -1
    je .Bad
    mov rcx, [r15 - 8]
    cmp rax, [rcx]
    jae .Bad
    mov rdx, rax
    push rdx
    call CharBytes
    pop rdx
    mov rcx, [r15 - 8]
    lea rcx, [rcx + 8 + rdx]
    mov rdx, rax
    call MakeTextFrom
    mov [r15 - 8], rax
    NEXT
.Bad:
    lea rcx, [rel ErrIndex]
    mov edx, ErrIndexLen
    jmp Abort

PrimTextChars:
    mov rcx, [r15 - 8]
    call Utf8Count
    push rax
    mov ecx, 24
    call Alloc
    pop rcx
    mov [rax], rcx
    mov qword [rax + 16], 0
    push rax
    push rax
    cmp rcx, 4
    jae .Cap
    mov ecx, 4
.Cap:
    mov [rax + 8], rcx
    shl rcx, 3
    call Alloc
    mov rdi, [rsp]
    mov [rdi + 16], rax
    xor ebx, ebx
    xor esi, esi
.Each:
    mov rcx, [r15 - 8]
    cmp rsi, [rcx]
    jae .Done
    mov rdx, rsi
    call CharBytes
    mov rcx, [r15 - 8]
    lea rcx, [rcx + 8 + rsi]
    add rsi, rax
    mov rdx, rax
    call MakeTextFrom
    mov rdi, [rsp]
    mov rdx, [rdi + 16]
    mov [rdx + rbx * 8], rax
    inc rbx
    jmp .Each
.Done:
    pop rdi
    pop rdi
    mov [r15 - 8], rdi
    NEXT

PrimCode:
    DPop rax
    xor ecx, ecx
    cmp qword [rax], 0
    je .Push
    movzx ecx, byte [rax + 8]
    cmp ecx, 0x80
    jb .Push
    mov r8, [rax]
    mov edx, 1
    cmp ecx, 0xE0
    jb .Two
    cmp ecx, 0xF0
    jb .Three
    and ecx, 0x07
    mov r9d, 4
    jmp .Rest
.Two:
    and ecx, 0x1F
    mov r9d, 2
    jmp .Rest
.Three:
    and ecx, 0x0F
    mov r9d, 3
.Rest:
    cmp rdx, r9
    jae .Push
    cmp rdx, r8
    jae .Push
    shl ecx, 6
    movzx r10d, byte [rax + 8 + rdx]
    and r10d, 0x3F
    or ecx, r10d
    inc rdx
    jmp .Rest
.Push:
    DPush rcx
    NEXT

PrimChar:
    DPop rax
    cmp rax, 0x10FFFF
    ja .Bad
    test rax, rax
    js .Bad
    lea rcx, [rel CharBuf]
    cmp rax, 0x80
    jae .Multi
    mov [rcx], al
    mov edx, 1
    jmp .Make
.Multi:
    cmp rax, 0x800
    jae .Three
    mov edx, eax
    shr edx, 6
    or edx, 0xC0
    mov [rcx], dl
    and eax, 0x3F
    or eax, 0x80
    mov [rcx + 1], al
    mov edx, 2
    jmp .Make
.Three:
    cmp rax, 0x10000
    jae .Four
    mov edx, eax
    shr edx, 12
    or edx, 0xE0
    mov [rcx], dl
    mov edx, eax
    shr edx, 6
    and edx, 0x3F
    or edx, 0x80
    mov [rcx + 1], dl
    and eax, 0x3F
    or eax, 0x80
    mov [rcx + 2], al
    mov edx, 3
    jmp .Make
.Four:
    mov edx, eax
    shr edx, 18
    or edx, 0xF0
    mov [rcx], dl
    mov edx, eax
    shr edx, 12
    and edx, 0x3F
    or edx, 0x80
    mov [rcx + 1], dl
    mov edx, eax
    shr edx, 6
    and edx, 0x3F
    or edx, 0x80
    mov [rcx + 2], dl
    and eax, 0x3F
    or eax, 0x80
    mov [rcx + 3], al
    mov edx, 4
.Make:
    call MakeTextFrom
    DPush rax
    NEXT
.Bad:
    lea rcx, [rel ErrCharRange]
    mov edx, ErrCharRangeLen
    jmp Abort

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

PrimMakeIface:
    mov rbx, [r14 + 8]
    lea rcx, [rbx * 8 + 16]
    call Alloc
    mov rcx, [r14]
    mov [rax], rcx
    mov rdx, [r15 - 8]
    mov [rax + 8], rdx
    xor ecx, ecx
.Copy:
    cmp rcx, rbx
    jae .Done
    mov rdx, [r14 + 16 + rcx * 8]
    mov [rax + 16 + rcx * 8], rdx
    inc rcx
    jmp .Copy
.Done:
    mov [r15 - 8], rax
    lea r14, [r14 + 16 + rbx * 8]
    NEXT

PrimIfaceCall:
    mov rcx, [r14]
    mov rdx, [r14 + 8]
    add r14, 16
    lea rax, [rdx * 8 + 8]
    mov r8, r15
    sub r8, rax
    mov r9, [r8]
    mov r10, [r9 + 8]
    mov [r8], r10
    mov rax, [r9 + 16 + rcx * 8]
    RPush r14
    mov r14, rax
    NEXT
