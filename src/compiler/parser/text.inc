%macro WordIs 2
[section .data]
%%Str: db %1
%%End:
__SECT__
    cmp r11, %%End - %%Str
    jne %%No
    push rcx
    push rdx
    push r8
    lea rcx, [rel %%Str]
    mov rdx, r10
    mov r8, r11
    call SameWord
    pop r8
    pop rdx
    pop rcx
    test r9d, r9d
    jnz %2
%%No:
%endmacro

SameWord:
    test r8, r8
    jz .Yes
    movzx r9d, byte [rdx]
    or r9d, 32
    cmp r9b, [rcx]
    jne .No
    inc rcx
    inc rdx
    dec r8
    jmp SameWord
.Yes:
    mov r9d, 1
    ret
.No:
    xor r9d, r9d
    ret

SpecError:
    mov rax, [rel SpecStart]
    mov [rel ErrPos], rax
    mov [rel ErrTokPtr], rax
    mov rax, [rel SpecEnd]
    sub rax, [rel SpecStart]
    mov [rel ErrTokLen], rax
    lea rcx, [rel ErrBadSpec]
    mov edx, ErrBadSpecLen
    jmp Abort

ParseSpec:
.TrimStart:
    cmp rcx, rdx
    jae .Trimmed
    cmp byte [rcx], ' '
    jne .TrimEnd
    inc rcx
    jmp .TrimStart
.TrimEnd:
    cmp byte [rdx - 1], ' '
    jne .Trimmed
    dec rdx
    jmp .TrimEnd
.Trimmed:
    mov [rel SpecStart], rcx
    mov [rel SpecEnd], rdx
    mov r8, rcx
.Scan:
    cmp r8, rdx
    jae ShortSpec
    movzx eax, byte [r8]
    or eax, 32
    cmp eax, 'a'
    jb .Next
    cmp eax, 'z'
    ja .Next
    lea r9, [r8 + 1]
    cmp r9, rdx
    jne WordSpec
    cmp r8, rcx
    je WordSpec
.Next:
    inc r8
    jmp .Scan

WordSpec:
    mov eax, 0xFF << 16
.Part:
    cmp rcx, rdx
    jae .Done
    movzx r9d, byte [rcx]
    cmp r9d, ' '
    je .Skip
    cmp r9d, ','
    je .Skip
    sub r9d, '0'
    cmp r9d, 9
    jbe .Count
    call .ReadWord
    WordIs "commas", .Commas
    WordIs "comma", .Commas
    WordIs "sign", .Sign
    WordIs "and", .Part
    WordIs "left", .Left
    WordIs "right", .Right
    jmp SpecError
.Skip:
    inc rcx
    jmp .Part
.Commas:
    or eax, 1 << 28
    jmp .Part
.Sign:
    or eax, 1 << 26
    jmp .Part
.Left:
    or eax, 1 << 24
    jmp .Width
.Right:
    or eax, 2 << 24
.Width:
    call .ReadNumber
    and eax, ~0xFFFF
    or eax, r8d
    jmp .Part
.Count:
    call .ReadNumber
    call .ReadWord
    WordIs "places", .Places
    WordIs "place", .Places
    WordIs "decimals", .Places
    WordIs "digits", .Digits
    WordIs "digit", .Digits
    WordIs "wide", .Wide
    jmp SpecError
.Places:
    cmp r8d, 15
    jbe .PlacesOk
    mov r8d, 15
.PlacesOk:
    and eax, ~(0xFF << 16)
    shl r8d, 16
    or eax, r8d
    jmp .Part
.Digits:
    or eax, 1 << 27
.Wide:
    and eax, ~0xFFFF
    or eax, r8d
    jmp .Part
.Done:
    ret

.ReadWord:
.WordSpaces:
    cmp rcx, rdx
    jae .WordStart
    cmp byte [rcx], ' '
    jne .WordStart
    inc rcx
    jmp .WordSpaces
.WordStart:
    mov r10, rcx
.WordLoop:
    cmp rcx, rdx
    jae .WordEnd
    movzx r9d, byte [rcx]
    or r9d, 32
    cmp r9d, 'a'
    jb .WordEnd
    cmp r9d, 'z'
    ja .WordEnd
    inc rcx
    jmp .WordLoop
.WordEnd:
    mov r11, rcx
    sub r11, r10
    ret

.ReadNumber:
.NumSpaces:
    cmp rcx, rdx
    jae .NumStart
    cmp byte [rcx], ' '
    jne .NumStart
    inc rcx
    jmp .NumSpaces
.NumStart:
    xor r8d, r8d
    mov r9, rcx
.NumLoop:
    cmp rcx, rdx
    jae .NumEnd
    movzx r10d, byte [rcx]
    sub r10d, '0'
    cmp r10d, 9
    ja .NumEnd
    imul r8d, r8d, 10
    add r8d, r10d
    inc rcx
    jmp .NumLoop
.NumEnd:
    cmp rcx, r9
    je SpecError
    and r8d, 0xFFFF
    ret

ShortSpec:
    mov eax, 0xFF << 16
    cmp rcx, rdx
    jae .Done
    cmp byte [rcx], '<'
    jne .NotLeft
    or eax, 1 << 24
    inc rcx
    jmp .Sign
.NotLeft:
    cmp byte [rcx], '>'
    jne .Sign
    or eax, 2 << 24
    inc rcx
.Sign:
    cmp rcx, rdx
    jae .Done
    cmp byte [rcx], '+'
    jne .Zero
    or eax, 1 << 26
    inc rcx
.Zero:
    cmp rcx, rdx
    jae .Done
    cmp byte [rcx], '0'
    jne .Width
    or eax, 1 << 27
    inc rcx
.Width:
    xor r8d, r8d
.WidthLoop:
    cmp rcx, rdx
    jae .WidthDone
    movzx r9d, byte [rcx]
    sub r9d, '0'
    cmp r9d, 9
    ja .WidthDone
    imul r8d, r8d, 10
    add r8d, r9d
    inc rcx
    jmp .WidthLoop
.WidthDone:
    and r8d, 0xFFFF
    or eax, r8d
    cmp rcx, rdx
    jae .Done
    cmp byte [rcx], ','
    jne .Precision
    or eax, 1 << 28
    inc rcx
.Precision:
    cmp rcx, rdx
    jae .Done
    cmp byte [rcx], '.'
    jne .Letter
    inc rcx
    xor r8d, r8d
.PrecisionLoop:
    cmp rcx, rdx
    jae .PrecisionDone
    movzx r9d, byte [rcx]
    sub r9d, '0'
    cmp r9d, 9
    ja .PrecisionDone
    imul r8d, r8d, 10
    add r8d, r9d
    inc rcx
    jmp .PrecisionLoop
.PrecisionDone:
    cmp r8d, 15
    jbe .PrecisionOk
    mov r8d, 15
.PrecisionOk:
    and eax, ~(0xFF << 16)
    shl r8d, 16
    or eax, r8d
.Letter:
    cmp rcx, rdx
    jae .Done
    movzx r9d, byte [rcx]
    or r9d, 32
    cmp r9d, 'f'
    je .SkipLetter
    cmp r9d, 'd'
    je .SkipLetter
    cmp r9d, 's'
    jne .Done
.SkipLetter:
    inc rcx
.Done:
    cmp rcx, rdx
    jne SpecError
    ret

CompileText:
    push rbx
    push rsi
    push rdi
    push r12
    mov rsi, rcx
    lea rdi, [rcx + rdx]
    xor r12d, r12d
.Segment:
    mov rbx, rsi
.Find:
    cmp rsi, rdi
    jae .Tail
    cmp byte [rsi], 92
    je .Escape
    cmp byte [rsi], '{'
    je .Brace
    inc rsi
    jmp .Find
.Escape:
    add rsi, 2
    jmp .Find
.Brace:
    mov rcx, rbx
    mov rdx, rsi
    sub rdx, rbx
    test rdx, rdx
    jz .NoLiteral
    call EmitTextLiteral
    call .Join
.NoLiteral:
    inc rsi
    mov rbx, rsi
    xor ecx, ecx
.FindClose:
    cmp rsi, rdi
    jae .Bad
    mov al, [rsi]
    cmp al, '"'
    je .InnerString
    cmp al, '{'
    jne .NotOpen
    inc ecx
    jmp .CloseNext
.NotOpen:
    cmp al, '}'
    jne .CloseNext
    test ecx, ecx
    jz .Close
    dec ecx
.CloseNext:
    inc rsi
    jmp .FindClose
.InnerString:
    inc rsi
.InnerLoop:
    cmp rsi, rdi
    jae .Bad
    mov al, [rsi]
    inc rsi
    cmp al, 92
    jne .InnerNotEscape
    inc rsi
    jmp .InnerLoop
.InnerNotEscape:
    cmp al, '"'
    jne .InnerLoop
    jmp .FindClose
.Close:
    mov rcx, rbx
    mov rdx, rsi
    call FindSpecColon
    push rax
    cmp rax, rsi
    je .NoSpec
    lea rcx, [rax + 1]
    mov rdx, rsi
    call ParseSpec
    jmp .HaveSpec
.NoSpec:
    mov rax, -1
.HaveSpec:
    push rax
    push rbx
    push rsi
    push rdi
    push r12
    call GetInput
    push rax
    push rdx
    push qword [rel TokPtr]
    push qword [rel TokLen]
    mov rcx, rbx
    mov rdx, [rsp + 72]
    sub rdx, rbx
    call SetInput
    call Advance
    call ParseExpr
    cmp qword [rel TokLen], 0
    jne .Bad
    mov rax, [rsp + 64]
    cmp rax, -1
    je .Plain
    CompilePrim PrimFormat
    mov rcx, [rsp + 64]
    call Compile
    mov rcx, [rel ExprType]
    call Compile
    jmp .Typed
.Plain:
    mov rax, [rel ExprType]
    call ToTextRaw
.Typed:
    pop qword [rel TokLen]
    pop qword [rel TokPtr]
    pop rdx
    pop rcx
    sub rdx, rcx
    call SetInput
    pop r12
    pop rdi
    pop rsi
    pop rbx
    add rsp, 16
    call .Join
    inc rsi
    jmp .Segment
.Tail:
    cmp rsi, rdi
    jbe .TailOk
    mov rsi, rdi
.TailOk:
    mov rcx, rbx
    mov rdx, rsi
    sub rdx, rbx
    test rdx, rdx
    jnz .TailLiteral
    test r12, r12
    jnz .Finish
.TailLiteral:
    call EmitTextLiteral
    call .Join
.Finish:
    SetType TText
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret
.Join:
    test r12, r12
    jz .First
    CompilePrim PrimConcat
.First:
    mov r12d, 1
    ret
.Bad:
    Fail ErrString
