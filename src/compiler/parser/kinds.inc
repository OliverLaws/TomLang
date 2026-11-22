FindKindName:
    push rbx
    push rsi
    mov rbx, rcx
    call FieldCount
    mov r10, rax
    mov rcx, rbx
    shl rcx, 5
    lea rax, [rel TypeTable]
    mov r11, [rax + rcx + 24]
    mov rdx, [rel TokPtr]
    mov r8, [rel TokLen]
    xor eax, eax
.Loop:
    cmp rax, r10
    jae .None
    mov rsi, rax
    shl rsi, 4
    add rsi, r11
    cmp r8, [rsi + 8]
    jne .Next
    mov rsi, [rsi]
    xor r9d, r9d
.Cmp:
    cmp r9, r8
    je .Found
    mov cl, [rsi + r9]
    cmp cl, [rdx + r9]
    jne .Next
    inc r9
    jmp .Cmp
.Next:
    inc rax
    jmp .Loop
.Found:
    inc rax
    pop rsi
    pop rbx
    ret
.None:
    xor eax, eax
    pop rsi
    pop rbx
    ret

KindWord:
    cmp qword [rel InFn], 0
    jne .Where
    cmp qword [rel OpenBlocks], 0
    jne .Where
    call Advance
    call IsNameStart
    test eax, eax
    jz .BadName
    call IsReserved
    test eax, eax
    jnz .BadName
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call FindWord
    test rax, rax
    jnz .Taken
    xor ecx, ecx
    mov rdx, [rel EnumTop]
    call NewEnum
    push rax
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call CreateVar
    mov r8, [rel Latest]
    mov byte [r8 + 16], 6
    mov rcx, [rsp]
    mov [r8 + 8], rcx
    shl rcx, 5
    lea rax, [rel TypeTable]
    mov [rax + rcx + 8], r8
    call Advance
    Expect "=", ErrKindEq
    xor ebx, ebx
.Value:
    call Advance
    call IsNameStart
    test eax, eax
    jz .BadValue
    call IsReserved
    test eax, eax
    jnz .BadValue
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call FindWord
    test rax, rax
    jnz .Taken
    lea rax, [rel EnumNames]
    mov rcx, [rel EnumTop]
    sub rcx, rax
    cmp rcx, 16 * 4090
    jae .TooMany
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    push rdx
    call CopyString
    pop rdx
    mov r8, [rel EnumTop]
    mov [r8], rax
    mov [r8 + 8], rdx
    add qword [rel EnumTop], 16
    inc rbx
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call CreateVar
    mov [rax], rbx
    mov rcx, rax
    mov rdx, [rsp]
    call SetTypeOf
    mov r8, [rel Latest]
    mov byte [r8 + 16], 5
    call Advance
    IfTok ",", .Value
    pop rcx
    shl rcx, 5
    lea rax, [rel TypeTable]
    mov [rax + rcx + 16], rbx
    jmp Pushback
.Where:
    Fail ErrKindWhere
.BadName:
    FailTok ErrKindName
.BadValue:
    FailTok ErrKindName
.Taken:
    FailTok ErrKindTaken
.TooMany:
    Fail ErrKindMany
