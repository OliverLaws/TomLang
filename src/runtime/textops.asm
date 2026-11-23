%include "macros.inc"

global PrimTextStarts
global PrimTextEnds
global PrimTextTrim
global PrimTextReplace
global PrimTextSplit
global PrimTextUpper
global PrimTextLower
global PrimFlatTop
global PrimAppendG
global PrimAppendL
extern MakeTextFrom
extern Alloc
extern AllocAtomic
extern MemCopy
extern PrimTextChars

section .text

PrimTextStarts:
    mov rdx, [r15 - 8]
    mov rcx, [r15 - 16]
    sub r15, 16
    mov r8, [rdx]
    cmp r8, [rcx]
    ja .No
    xor r9d, r9d
.Loop:
    cmp r9, r8
    jae .Yes
    mov al, [rcx + 8 + r9]
    cmp al, [rdx + 8 + r9]
    jne .No
    inc r9
    jmp .Loop
.Yes:
    DPush 1
    NEXT
.No:
    DPush 0
    NEXT

PrimTextEnds:
    mov rdx, [r15 - 8]
    mov rcx, [r15 - 16]
    sub r15, 16
    mov r8, [rdx]
    mov r10, [rcx]
    cmp r8, r10
    ja .No
    sub r10, r8
    xor r9d, r9d
.Loop:
    cmp r9, r8
    jae .Yes
    lea r11, [r10 + r9]
    mov al, [rcx + 8 + r11]
    cmp al, [rdx + 8 + r9]
    jne .No
    inc r9
    jmp .Loop
.Yes:
    DPush 1
    NEXT
.No:
    DPush 0
    NEXT

IsSpaceByte:
    cmp al, ' '
    je .Yes
    cmp al, 9
    je .Yes
    cmp al, 10
    je .Yes
    cmp al, 13
    je .Yes
    xor edx, edx
    ret
.Yes:
    mov edx, 1
    ret

NewText:
    push rcx
    add rcx, 8
    call AllocAtomic
    pop rcx
    mov [rax], rcx
    ret

PrimTextTrim:
    push rbx
    push r12
    push r13
    mov rbx, [r15 - 8]
    xor r12d, r12d
    mov r13, [rbx]
.Front:
    cmp r12, r13
    jae .Cut
    mov al, [rbx + 8 + r12]
    call IsSpaceByte
    test edx, edx
    jz .Back
    inc r12
    jmp .Front
.Back:
    cmp r13, r12
    jbe .Cut
    mov al, [rbx + 7 + r13]
    call IsSpaceByte
    test edx, edx
    jz .Cut
    dec r13
    jmp .Back
.Cut:
    test r12, r12
    jnz .Make
    cmp r13, [rbx]
    je .Done
.Make:
    mov rcx, r13
    sub rcx, r12
    call NewText
    push rax
    lea rcx, [rbx + 8 + r12]
    lea rdx, [rax + 8]
    mov r8, [rax]
    call MemCopy
    pop rax
    mov [r15 - 8], rax
.Done:
    pop r13
    pop r12
    pop rbx
    NEXT

MatchAt:
    xor r9d, r9d
.Loop:
    cmp r9, [rsi]
    jae .Yes
    lea rax, [rcx + r9]
    mov al, [rbx + 8 + rax]
    cmp al, [rsi + 8 + r9]
    jne .No
    inc r9
    jmp .Loop
.Yes:
    mov eax, 1
    ret
.No:
    xor eax, eax
    ret

PrimTextReplace:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    mov rbx, [r15 - 24]
    mov rsi, [r15 - 16]
    mov rdi, [r15 - 8]
    cmp qword [rsi], 0
    je .Same
    xor r12d, r12d
    xor ecx, ecx
.Count:
    mov rax, [rbx]
    sub rax, [rsi]
    cmp rcx, rax
    jg .Counted
    call MatchAt
    test eax, eax
    jz .CountNext
    inc r12
    add rcx, [rsi]
    jmp .Count
.CountNext:
    inc rcx
    jmp .Count
.Counted:
    test r12, r12
    jz .Same
    mov rax, [rdi]
    sub rax, [rsi]
    imul rax, r12
    mov rcx, [rbx]
    add rcx, rax
    call NewText
    mov r13, rax
    mov rbx, [r15 - 24]
    mov rsi, [r15 - 16]
    mov rdi, [r15 - 8]
    xor ecx, ecx
    xor r14d, r14d
.Build:
    cmp rcx, [rbx]
    jae .Built
    mov rax, [rbx]
    sub rax, [rsi]
    cmp rcx, rax
    jg .Plain
    push rcx
    call MatchAt
    pop rcx
    test eax, eax
    jz .Plain
    xor r9d, r9d
.CopyWith:
    cmp r9, [rdi]
    jae .Copied
    mov al, [rdi + 8 + r9]
    mov [r13 + 8 + r14], al
    inc r14
    inc r9
    jmp .CopyWith
.Copied:
    add rcx, [rsi]
    jmp .Build
.Plain:
    mov al, [rbx + 8 + rcx]
    mov [r13 + 8 + r14], al
    inc r14
    inc rcx
    jmp .Build
.Built:
    mov rax, r13
    jmp .Out
.Same:
    mov rax, rbx
.Out:
    sub r15, 24
    DPush rax
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    NEXT

ListPush:
    push rbx
    push rsi
    mov rbx, rcx
    mov rsi, rdx
    mov rax, [rbx]
    cmp rax, [rbx + 8]
    jb .Room
    mov rcx, [rbx + 8]
    shl rcx, 4
    call Alloc
    mov rcx, [rbx + 16]
    mov rdx, rax
    mov r8, [rbx]
    shl r8, 3
    push rax
    call MemCopy
    pop rax
    mov [rbx + 16], rax
    shl qword [rbx + 8], 1
.Room:
    mov rax, [rbx]
    mov rcx, [rbx + 16]
    mov [rcx + rax * 8], rsi
    inc qword [rbx]
    pop rsi
    pop rbx
    ret

PrimTextSplit:
    mov rax, [r15 - 8]
    cmp qword [rax], 0
    jne .Split
    sub r15, 8
    jmp PrimTextChars
.Split:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    mov ecx, 24
    call Alloc
    mov rdi, rax
    mov qword [rdi], 0
    mov qword [rdi + 8], 8
    mov qword [rdi + 16], 0
    DPush rdi
    mov ecx, 64
    call Alloc
    mov [rdi + 16], rax
    xor r12d, r12d
    xor ecx, ecx
.Scan:
    mov rbx, [r15 - 24]
    mov rsi, [r15 - 16]
    cmp qword [rsi], 1
    jne .Multi
    movzx edx, byte [rsi + 8]
    mov rax, [rbx]
.Find1:
    cmp rcx, rax
    jae .Last
    cmp [rbx + 8 + rcx], dl
    je .Found
    inc rcx
    jmp .Find1
.Multi:
    mov rax, [rbx]
    sub rax, [rsi]
    cmp rcx, rax
    jg .Last
    push rcx
    call MatchAt
    pop rcx
    test eax, eax
    jz .Next
.Found:
    mov r13, rcx
    push rcx
    mov rcx, r13
    sub rcx, r12
    call .Piece
    pop rcx
    mov rsi, [r15 - 16]
    add rcx, [rsi]
    mov r12, rcx
    jmp .Scan
.Next:
    inc rcx
    jmp .Scan
.Last:
    mov rbx, [r15 - 24]
    mov rcx, [rbx]
    sub rcx, r12
    call .Piece
    mov rax, [r15 - 8]
    sub r15, 24
    DPush rax
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    NEXT
.Piece:
    push rcx
    call NewText
    pop r8
    push rax
    mov rbx, [r15 - 24]
    lea rcx, [rbx + 8 + r12]
    lea rdx, [rax + 8]
    call MemCopy
    mov rcx, [r15 - 8]
    pop rdx
    jmp ListPush

LowerCode:
    cmp eax, 65
    jb .Same
    cmp eax, 90
    jbe .Plus32
    cmp eax, 192
    jb .Same
    cmp eax, 222
    ja .ExtA
    cmp eax, 215
    je .Same
    jmp .Plus32
.ExtA:
    cmp eax, 256
    jb .Same
    cmp eax, 383
    ja .Greek
    cmp eax, 376
    je .Y
    cmp eax, 313
    jb .Even
    cmp eax, 328
    jbe .OddUp
    cmp eax, 377
    jb .Even
    cmp eax, 382
    ja .Even
.OddUp:
    test eax, 1
    jz .Same
    inc eax
    ret
.Even:
    test eax, 1
    jnz .Same
    cmp eax, 304
    je .Same
    cmp eax, 312
    je .Same
    inc eax
    ret
.Y:
    mov eax, 255
    ret
.Greek:
    cmp eax, 913
    jb .Same
    cmp eax, 939
    ja .Cyr
    cmp eax, 930
    je .Same
    jmp .Plus32
.Cyr:
    cmp eax, 1024
    jb .Same
    cmp eax, 1039
    jbe .Plus80
    cmp eax, 1071
    jbe .Plus32
.Same:
    ret
.Plus32:
    add eax, 32
    ret
.Plus80:
    add eax, 80
    ret

UpperCode:
    cmp eax, 97
    jb .Same
    cmp eax, 122
    jbe .Minus32
    cmp eax, 224
    jb .Same
    cmp eax, 254
    ja .Y
    cmp eax, 247
    je .Same
    jmp .Minus32
.Y:
    cmp eax, 255
    jne .ExtA
    mov eax, 376
    ret
.ExtA:
    cmp eax, 256
    jb .Same
    cmp eax, 383
    ja .Greek
    cmp eax, 313
    jb .Odd
    cmp eax, 328
    jbe .EvenDown
    cmp eax, 377
    jb .Odd
    cmp eax, 382
    ja .Odd
.EvenDown:
    test eax, 1
    jnz .Same
    dec eax
    ret
.Odd:
    test eax, 1
    jz .Same
    cmp eax, 305
    je .Same
    cmp eax, 312
    je .Same
    cmp eax, 329
    je .Same
    cmp eax, 383
    je .Same
    dec eax
    ret
.Greek:
    cmp eax, 945
    jb .Same
    cmp eax, 971
    ja .Cyr
    cmp eax, 962
    je .Same
    jmp .Minus32
.Cyr:
    cmp eax, 1072
    jb .Same
    cmp eax, 1103
    jbe .Minus32
    cmp eax, 1119
    jbe .Minus80
.Same:
    ret
.Minus32:
    sub eax, 32
    ret
.Minus80:
    sub eax, 80
    ret

PrimTextUpper:
    lea r10, [rel UpperCode]
    jmp CaseCommon
PrimTextLower:
    lea r10, [rel LowerCode]
CaseCommon:
    push rbx
    push r12
    push r13
    mov r13, r10
    mov rbx, [r15 - 8]
    mov rcx, [rbx]
    call NewText
    mov r12, rax
    mov rbx, [r15 - 8]
    xor ecx, ecx
.Loop:
    lea rax, [rcx + 8]
    cmp rax, [rbx]
    ja .Bytewise
    mov rax, [rbx + 8 + rcx]
    mov rdx, 0x8080808080808080
    test rax, rdx
    jnz .Bytewise
    lea rdx, [rel UpperCode]
    cmp r13, rdx
    jne .LowerWord
    mov rdx, 0x1F1F1F1F1F1F1F1F
    mov r8, 0x0505050505050505
    jmp .Swar
.LowerWord:
    mov rdx, 0x3F3F3F3F3F3F3F3F
    mov r8, 0x2525252525252525
.Swar:
    add rdx, rax
    add r8, rax
    xor rdx, r8
    mov r8, 0x8080808080808080
    and rdx, r8
    shr rdx, 2
    xor rax, rdx
    mov [r12 + 8 + rcx], rax
    add rcx, 8
    jmp .Loop
.Bytewise:
    cmp rcx, [rbx]
    jae .Done
    movzx eax, byte [rbx + 8 + rcx]
    cmp eax, 0x80
    jb .One
    cmp eax, 0xC0
    jb .Copy
    cmp eax, 0xF0
    jae .Copy4
    cmp eax, 0xE0
    jae .Copy3
    lea rdx, [rcx + 1]
    cmp rdx, [rbx]
    jae .Copy
    movzx edx, byte [rbx + 9 + rcx]
    and eax, 0x1F
    shl eax, 6
    and edx, 0x3F
    or eax, edx
    call r13
    mov edx, eax
    shr edx, 6
    or edx, 0xC0
    mov [r12 + 8 + rcx], dl
    and eax, 0x3F
    or eax, 0x80
    mov [r12 + 9 + rcx], al
    add rcx, 2
    jmp .Loop
.One:
    lea rdx, [rel UpperCode]
    cmp r13, rdx
    jne .LowerOne
    lea edx, [rax - 'a']
    cmp edx, 25
    ja .PutOne
    sub eax, 32
    jmp .PutOne
.LowerOne:
    lea edx, [rax - 'A']
    cmp edx, 25
    ja .PutOne
    add eax, 32
.PutOne:
    mov [r12 + 8 + rcx], al
    inc rcx
    jmp .Loop
.Copy4:
    mov r8d, 4
    jmp .CopyN
.Copy3:
    mov r8d, 3
.CopyN:
    cmp rcx, [rbx]
    jae .Loop
    mov al, [rbx + 8 + rcx]
    mov [r12 + 8 + rcx], al
    inc rcx
    dec r8d
    jnz .CopyN
    jmp .Loop
.Copy:
    mov al, [rbx + 8 + rcx]
    mov [r12 + 8 + rcx], al
    inc rcx
    jmp .Loop
.Done:
    mov [r15 - 8], r12
    pop r13
    pop r12
    pop rbx
    NEXT

PrimFlatTop:
    mov rax, [r15 - 8]
    test rax, rax
    jz .Done
    bt qword [rax], 62
    jnc .Done
    mov rcx, [rax + 24]
    test rcx, rcx
    jnz .Have
    mov rdx, [rax]
    btr rdx, 62
    mov rcx, [rax + 16]
    call MakeTextFrom
    mov rdx, [r15 - 8]
    mov [rdx + 24], rax
    mov rcx, rax
.Have:
    mov [r15 - 8], rcx
.Done:
    NEXT

PrimAppendL:
    mov rax, [r14]
    add r14, 8
    lea rbx, [r13 + rax]
    jmp AppendSlot

PrimAppendG:
    mov rbx, [r14]
    add r14, 8

AppendSlot:
    mov rsi, [rbx]
    mov rdi, [r15 - 8]
    test rsi, rsi
    jz .Replace
    bt qword [rsi], 62
    jc .Builder
    mov rcx, [rsi]
    add rcx, [rdi]
    cmp rcx, 256
    jae .MakeBuilder
    push rcx
    push rcx
    add rcx, 8
    call AllocAtomic
    pop rcx
    pop rcx
    mov [rax], rcx
    mov rsi, [rbx]
    mov rdi, [r15 - 8]
    push rax
    push rax
    lea rdx, [rax + 8]
    lea rcx, [rsi + 8]
    mov r8, [rsi]
    call MemCopy
    mov rax, [rsp]
    mov rsi, [rbx]
    mov rdi, [r15 - 8]
    lea rdx, [rax + 8]
    add rdx, [rsi]
    lea rcx, [rdi + 8]
    mov r8, [rdi]
    call MemCopy
    pop rax
    pop rax
    mov [rbx], rax
    sub r15, 8
    NEXT
.Replace:
    mov [rbx], rdi
    sub r15, 8
    NEXT
.MakeBuilder:
    shl rcx, 1
    push rcx
    push rcx
    call AllocAtomic
    pop rcx
    pop rcx
    DPush rax
    DPush rcx
    mov ecx, 32
    call Alloc
    DPop rcx
    mov [rax + 8], rcx
    DPop rcx
    mov [rax + 16], rcx
    mov qword [rax + 24], 0
    mov rsi, [rbx]
    mov rdx, [rsi]
    mov [rax], rdx
    push rax
    push rax
    lea rcx, [rsi + 8]
    mov rdx, [rax + 16]
    mov r8, [rsi]
    call MemCopy
    pop rax
    pop rax
    bts qword [rax], 62
    mov [rbx], rax
    mov rsi, rax
    mov rdi, [r15 - 8]
.Builder:
    mov rax, [rsi]
    btr rax, 62
    mov rcx, rax
    add rcx, [rdi]
    cmp rcx, [rsi + 8]
    jbe .Room
    shl rcx, 1
    push rcx
    push rcx
    call AllocAtomic
    pop rcx
    pop rcx
    mov rsi, [rbx]
    mov [rsi + 8], rcx
    push rax
    push rax
    mov rcx, [rsi + 16]
    mov rdx, rax
    mov r8, [rsi]
    btr r8, 62
    call MemCopy
    pop rax
    pop rax
    mov rsi, [rbx]
    mov [rsi + 16], rax
    mov rdi, [r15 - 8]
.Room:
    mov rax, [rsi]
    btr rax, 62
    mov rdx, [rsi + 16]
    add rdx, rax
    lea rcx, [rdi + 8]
    mov r8, [rdi]
    add rax, r8
    bts rax, 62
    mov [rsi], rax
    mov qword [rsi + 24], 0
    call MemCopy
    sub r15, 8
    NEXT
