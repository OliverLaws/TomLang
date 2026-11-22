global SetInput
global NextToken
global ParseNumber
extern Abort
global Unread
global GetInput

section .bss
InPtr resq 1
InEnd resq 1

section .data
ErrBigNumber db "this number is too big (the biggest whole number is 9223372036854775807, use a decimal for bigger)"
ErrBigNumberLen equ $ - ErrBigNumber

section .text
SetInput:
    mov [rel InPtr], rcx
    add rcx, rdx
    mov [rel InEnd], rcx
    ret

GetInput:
    mov rax, [rel InPtr]
    mov rdx, [rel InEnd]
    ret

Unread:
    mov [rel InPtr], rcx
    ret

IsWordChar:
    cmp cl, '0'
    jb .No
    cmp cl, '9'
    jbe .Yes
    cmp cl, 'A'
    jb .No
    cmp cl, 'Z'
    jbe .Yes
    cmp cl, '_'
    je .Yes
    cmp cl, 'a'
    jb .No
    cmp cl, 'z'
    jbe .Yes
.No:
    xor eax, eax
    ret
.Yes:
    mov eax, 1
    ret

NextToken:
    mov r8, [rel InPtr]
    mov r9, [rel InEnd]
.Skip:
    cmp r8, r9
    jae .End
    cmp byte [r8], ' '
    ja .NotSpace
    inc r8
    jmp .Skip
.NotSpace:
    cmp byte [r8], '#'
    jne .Start
    lea r10, [r8 + 1]
    cmp r10, r9
    jae .Comment
    cmp byte [r10], '['
    je .Block
.Comment:
    inc r8
    cmp r8, r9
    jae .End
    cmp byte [r8], 10
    jne .Comment
    jmp .Skip
.Block:
    add r8, 2
.BlockLoop:
    lea r10, [r8 + 1]
    cmp r10, r9
    jae .End
    cmp byte [r8], ']'
    jne .BlockNext
    cmp byte [r10], '#'
    jne .BlockNext
    add r8, 2
    jmp .Skip
.BlockNext:
    inc r8
    jmp .BlockLoop
.Start:
    mov r10, r8
    mov cl, [r8]
    inc r8
    cmp cl, '"'
    je .String
    call IsWordChar
    test eax, eax
    jz .Symbol
.Run:
    cmp r8, r9
    jae .Decimal
    mov cl, [r8]
    call IsWordChar
    test eax, eax
    jz .Decimal
    inc r8
    jmp .Run
.Decimal:
    mov cl, [r10]
    cmp cl, '0'
    jb .Done
    cmp cl, '9'
    ja .Done
    lea r11, [r8 + 1]
    cmp r11, r9
    jae .Done
    cmp byte [r8], '.'
    jne .Done
    mov cl, [r11]
    cmp cl, '0'
    jb .Done
    cmp cl, '9'
    ja .Done
    mov r8, r11
.Fraction:
    cmp r8, r9
    jae .Done
    mov cl, [r8]
    cmp cl, '0'
    jb .Done
    cmp cl, '9'
    ja .Done
    inc r8
    jmp .Fraction
.String:
    xor r11d, r11d
.StringLoop:
    cmp r8, r9
    jae .Done
    mov cl, [r8]
    inc r8
    cmp cl, 92
    je .Escape
    cmp cl, '{'
    jne .NotOpen
    inc r11
    jmp .StringLoop
.NotOpen:
    cmp cl, '}'
    jne .NotClose
    test r11, r11
    jz .StringLoop
    dec r11
    jmp .StringLoop
.NotClose:
    cmp cl, '"'
    jne .StringLoop
    test r11, r11
    jz .Done
.Nested:
    cmp r8, r9
    jae .Done
    mov cl, [r8]
    inc r8
    cmp cl, 92
    jne .NestedChar
    inc r8
    jmp .Nested
.NestedChar:
    cmp cl, '"'
    jne .Nested
    jmp .StringLoop
.Escape:
    cmp r8, r9
    jae .Done
    inc r8
    jmp .StringLoop
.Symbol:
    cmp r8, r9
    jae .Done
    mov cl, [r8]
    cmp cl, '='
    je .Join
    cmp cl, '>'
    jne .NotArrow
    cmp byte [r10], '='
    je .Join
    cmp byte [r10], '|'
    je .Join
.NotArrow:
    cmp cl, [r10]
    jne .Done
    cmp cl, '/'
    je .Join
    cmp cl, '.'
    je .Dots
    cmp cl, '<'
    je .Join
    cmp cl, '>'
    je .Join
    cmp cl, '&'
    je .Join
    cmp cl, '|'
    jne .Done
.Join:
    inc r8
    jmp .Done
.Dots:
    inc r8
    cmp r8, r9
    jae .Done
    cmp byte [r8], '.'
    jne .Done
    inc r8
.Done:
    mov [rel InPtr], r8
    mov rax, r10
    mov rdx, r8
    sub rdx, r10
    ret
.End:
    mov [rel InPtr], r8
    xor edx, edx
    ret

ParseNumber:
    xor eax, eax
    test rdx, rdx
    jz .Fail
    cmp rdx, 2
    jbe .Loop
    cmp byte [rcx], '0'
    jne .Loop
    movzx r8d, byte [rcx + 1]
    or r8d, 32
    cmp r8d, 'x'
    je .Hex
    cmp r8d, 'b'
    je .Bin
.Loop:
    movzx r8d, byte [rcx]
    cmp r8d, '_'
    je .Skip
    sub r8d, '0'
    cmp r8d, 9
    ja .Fail
    imul rax, rax, 10
    jo .Big
    add rax, r8
    jo .Big
.Skip:
    inc rcx
    dec rdx
    jnz .Loop
    mov edx, 1
    ret
.Hex:
    add rcx, 2
    sub rdx, 2
.HexLoop:
    movzx r8d, byte [rcx]
    cmp r8d, '_'
    je .HexNext
    sub r8d, '0'
    cmp r8d, 9
    jbe .HexDigit
    movzx r8d, byte [rcx]
    or r8d, 32
    sub r8d, 'a'
    cmp r8d, 5
    ja .Fail
    add r8d, 10
.HexDigit:
    mov r9, rax
    shr r9, 60
    jnz .Big
    shl rax, 4
    or rax, r8
.HexNext:
    inc rcx
    dec rdx
    jnz .HexLoop
    mov edx, 1
    ret
.Bin:
    add rcx, 2
    sub rdx, 2
.BinLoop:
    movzx r8d, byte [rcx]
    cmp r8d, '_'
    je .BinNext
    sub r8d, '0'
    cmp r8d, 1
    ja .Fail
    bt rax, 63
    jc .Big
    shl rax, 1
    or rax, r8
.BinNext:
    inc rcx
    dec rdx
    jnz .BinLoop
    mov edx, 1
    ret
.Fail:
    xor edx, edx
    ret
.Big:
    lea rcx, [rel ErrBigNumber]
    mov edx, ErrBigNumberLen
    jmp Abort
