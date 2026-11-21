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
