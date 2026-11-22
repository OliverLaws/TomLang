ParseTuple:
    push qword [rel TempTop]
    push 0
.Add:
    mov rax, [rel ExprType]
    test rax, rax
    jz TypeError
    mov rcx, [rsp]
    cmp rcx, 9
    jae .TooMany
    lea rdx, [rcx + rcx * 2]
    mov r8, [rsp + 8]
    lea r8, [r8 + rdx * 8]
    lea r9, [rel DigitNames]
    add r9, rcx
    mov [r8], r9
    mov qword [r8 + 8], 1
    mov [r8 + 16], rax
    inc qword [rsp]
    add r8, 24
    mov [rel TempTop], r8
    call TempRoom
    IfTok ",", .Next
    mov rcx, [rsp]
    mov rdx, [rsp + 8]
    call InternRecord
    mov rbx, rax
    push rbx
    CompilePrim PrimMakeRecord
    mov rcx, [rsp + 8]
    call Compile
    xor esi, esi
.Slots:
    cmp rsi, [rsp + 8]
    jae .Done
    lea rdx, [rel DigitNames]
    add rdx, rsi
    mov rcx, [rsp]
    mov r8d, 1
    call FindField
    mov rcx, rax
    call Compile
    inc rsi
    jmp .Slots
.Done:
    pop rbx
    mov [rel ExprType], rbx
    pop rax
    pop rax
    mov [rel TempTop], rax
    ret
.Next:
    call Advance
    call ParseExpr
    jmp .Add
.TooMany:
    Fail ErrTupleMany

MultiAssign:
    test rcx, rcx
    jnz .Go
    push rcx
    call MultiTargets
    pop rcx
    test rax, rax
    jnz ComplexMulti
.Go:
    sub rsp, 160
    mov [rsp + 152], rcx
    mov qword [rsp + 144], 0
.Name:
    call IsNameStart
    test eax, eax
    jz .BadName
    mov rax, [rsp + 144]
    cmp rax, 9
    jae .TooMany
    shl rax, 4
    mov rcx, [rel TokPtr]
    mov [rsp + rax], rcx
    mov rcx, [rel TokLen]
    mov [rsp + rax + 8], rcx
    inc qword [rsp + 144]
    call Advance
    IfTok ",", .More
    Expect "=", ErrSet
    call Advance
    call ParseExpr
    IfTok ",", .Tuple
    jmp .Check
.More:
    call Advance
    jmp .Name
.Tuple:
    call ParseTuple
.Check:
    mov rax, [rel ExprType]
    call KindOfType
    cmp rax, KRec
    jne .NotTuple
    mov rcx, [rel ExprType]
    call FieldCount
    cmp rax, [rsp + 144]
    jne .Count
    mov qword [rsp + 136], 0
.Store:
    mov rax, [rsp + 136]
    cmp rax, [rsp + 144]
    jae .Finish
    lea rdx, [rel DigitNames]
    add rdx, rax
    mov rcx, [rel ExprType]
    mov r8d, 1
    push qword [rel ExprType]
    call FindField
    cmp rax, -1
    je .NotTupleP
    push rdx
    push rax
    CompilePrim PrimDup
    CompilePrim PrimGetField
    pop rcx
    shl rcx, 3
    call Compile
    mov rax, [rsp + 16 + 136]
    shl rax, 4
    mov rcx, [rsp + 16 + rax]
    mov rdx, [rsp + 16 + rax + 8]
    cmp qword [rsp + 16 + 152], 0
    je .Change
    push rcx
    push rdx
    cmp qword [rel InFn], 0
    jne .FindLocal
    call LookupVar
    jmp .Found
.FindLocal:
    call FindLocal
    xor edx, edx
    test rax, rax
    jz .Found
    mov r8, rax
    shr r8, 3
    lea r9, [rel LocalConst]
    mov rdx, [r9 + r8 * 8]
.Found:
    test rax, rax
    jz .Create
    test rdx, rdx
    jnz .Const
    mov rcx, rax
    push rax
    call TypeOf
    mov rdx, [rsp + 24]
    mov rcx, rax
    pop rax
    test rcx, rcx
    jz .Reuse
    cmp rcx, rdx
    jne .Create
.Reuse:
    add rsp, 16
    jmp .Typed
.Create:
    pop rdx
    pop rcx
    call NewVar
    jmp .Typed
.Change:
    push rcx
    push rdx
    call LookupVar
    pop r9
    pop r8
    test rax, rax
    jz .Missing
    test rdx, rdx
    jnz .ConstChange
.Typed:
    push rax
    mov rcx, rax
    call TypeOf
    mov rdx, [rsp + 8]
    test rax, rax
    jz .SetType
    cmp rax, rdx
    je .Emit
    call Compatible
    test rax, rax
    jz TypeError
    jmp .Emit
.SetType:
    mov rcx, [rsp]
    call SetTypeOf
.Emit:
    pop rcx
    call EmitStore
    add rsp, 8
    pop rax
    mov [rel ExprType], rax
    inc qword [rsp + 136]
    jmp .Store
.Finish:
    CompilePrim PrimDrop
    add rsp, 160
    jmp Pushback
.NotTupleP:
    add rsp, 8
.NotTuple:
    Fail ErrNotTuple
.Count:
    Fail ErrTupleCount
.TooMany:
    Fail ErrTupleMany
.BadName:
    FailTok ErrSetName
.Const:
.ConstChange:
    Fail ErrConst
.Missing:
    mov [rel ErrTokPtr], r8
    mov [rel ErrPos], r8
    mov [rel ErrTokLen], r9
    lea rcx, [rel ErrNotExist]
    mov edx, ErrNotExistLen
    jmp Abort

MultiTargets:
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 8
    call GetInput
    mov r12, rax
    mov r13, rdx
    mov qword [rel MultiCount], 0
    xor ebx, ebx
    xor r14d, r14d
    mov rax, [rel TokPtr]
    mov rdx, [rel TokLen]
    lea r8, [rel MultiPtr]
    mov [r8], rax
.Tok:
    test rdx, rdx
    jz .No
    cmp rdx, 1
    jne .Other
    movzx ecx, byte [rax]
    cmp ecx, '['
    je .Open
    cmp ecx, '('
    je .Open
    cmp ecx, '{'
    je .Open
    cmp ecx, ']'
    je .Close
    cmp ecx, ')'
    je .Close
    cmp ecx, '}'
    je .Close
    test rbx, rbx
    jnz .Other
    cmp ecx, '='
    je .EndTarget
    cmp ecx, ','
    je .EndTarget
    cmp ecx, '.'
    jne .Other
    mov r14d, 1
    jmp .Other
.Open:
    test rbx, rbx
    jnz .Deeper
    cmp ecx, '['
    jne .Deeper
    mov r14d, 1
.Deeper:
    inc rbx
    jmp .Other
.Close:
    dec rbx
    jmp .Other
.EndTarget:
    push rcx
    mov rcx, [rel MultiCount]
    cmp rcx, 9
    jae .TooMany
    lea r8, [rel MultiPtr]
    lea r9, [rel MultiLen]
    mov r10, [rel MultiLast]
    sub r10, [r8 + rcx * 8]
    mov [r9 + rcx * 8], r10
    inc qword [rel MultiCount]
    pop rcx
    cmp ecx, '='
    je .Done
    call NextToken
    mov rcx, [rel MultiCount]
    lea r8, [rel MultiPtr]
    mov [r8 + rcx * 8], rax
    jmp .Tok
.Other:
    lea r8, [rax + rdx]
    mov [rel MultiLast], r8
    call NextToken
    jmp .Tok
.TooMany:
    pop rcx
.No:
    xor r14d, r14d
.Done:
    mov rcx, r12
    mov rdx, r13
    sub rdx, r12
    call SetInput
    mov rax, r14
    add rsp, 8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

ComplexMulti:
    sub rsp, 40
.Skip:
    IfTok "=", .Value
    cmp qword [rel TokLen], 0
    je .BadSet
    call Advance
    jmp .Skip
.Value:
    call Advance
    call ParseExpr
    IfTok ",", .Tuple
    jmp .Check
.Tuple:
    call ParseTuple
.Check:
    mov rax, [rel ExprType]
    call KindOfType
    cmp rax, KRec
    jne .NotTuple
    mov rcx, [rel ExprType]
    call FieldCount
    cmp rax, [rel MultiCount]
    jne .Count
    mov qword [rsp], 0
.Store:
    mov rax, [rsp]
    cmp rax, [rel MultiCount]
    jae .Stored
    lea rdx, [rel DigitNames]
    add rdx, rax
    mov rcx, [rel ExprType]
    mov r8d, 1
    push qword [rel ExprType]
    call FindField
    push rdx
    push rax
    CompilePrim PrimDup
    CompilePrim PrimGetField
    pop rcx
    shl rcx, 3
    call Compile
    mov rax, [rsp + 16]
    lea rcx, [rel HiddenNames]
    lea rcx, [rcx + rax * 4]
    mov edx, 4
    push rcx
    cmp qword [rel InFn], 0
    jne .FindHidden
    call LookupVar
    jmp .GotHidden
.FindHidden:
    call FindLocal
.GotHidden:
    pop rcx
    test rax, rax
    jz .NewHidden
    push rcx
    push rax
    mov rcx, rax
    call TypeOf
    mov rdx, rax
    pop rax
    pop rcx
    cmp rdx, [rsp]
    je .HaveHidden
.NewHidden:
    mov edx, 4
    call NewVar
.HaveHidden:
    push rax
    mov rcx, rax
    mov rdx, [rsp + 8]
    call SetTypeOf
    pop rcx
    call EmitStore
    add rsp, 8
    pop rax
    mov [rel ExprType], rax
    inc qword [rsp]
    jmp .Store
.Stored:
    CompilePrim PrimDrop
    call GetInput
    mov [rsp + 8], rax
    mov [rsp + 16], rdx
    mov rax, [rel TokPtr]
    mov [rsp + 24], rax
    mov qword [rsp], 0
.Each:
    mov rax, [rsp]
    cmp rax, [rel MultiCount]
    jae .Done
    lea r8, [rel MultiPtr]
    mov rsi, [r8 + rax * 8]
    lea r8, [rel MultiLen]
    mov rcx, [r8 + rax * 8]
    cmp rcx, 200
    ja .BadSet
    lea rdi, [rel MultiBuf]
    rep movsb
    mov dword [rdi], ' = _'
    mov byte [rdi + 4], '_'
    mov byte [rdi + 5], 'm'
    mov rax, [rsp]
    add al, '1'
    mov [rdi + 6], al
    mov byte [rdi + 7], 10
    lea rcx, [rel MultiBuf]
    lea rdx, [rdi + 8]
    sub rdx, rcx
    call SetInput
    call NextToken
    mov r12, rax
    mov r13, rdx
    xor ecx, ecx
    call StmtExpr
    inc qword [rsp]
    jmp .Each
.Done:
    mov rcx, [rsp + 24]
    mov rdx, [rsp + 16]
    sub rdx, rcx
    call SetInput
    call NextToken
    mov [rel TokPtr], rax
    mov [rel TokLen], rdx
    add rsp, 40
    jmp Pushback
.BadSet:
    Fail ErrSet
.NotTuple:
    Fail ErrNotTuple
.Count:
    Fail ErrTupleCount
