CheckWord:
    call Advance
    call ParseExpr
    mov rax, [rel ExprType]
    test rax, rax
    jz TypeError
    push rax
    call NewHidden
    push rax
    mov rcx, rax
    call EmitStore
    pop rbx
    pop rax
    DPush 0
    DPush 0
    DPush rbx
    DPush rax
    DPush TagCheck
    inc qword [rel OpenBlocks]
    jmp Pushback

IsWord:
    cmp qword [rel OpenBlocks], 0
    je .Bad
    cmp qword [r15 - 8], TagDummy
    je .Dummy
    cmp qword [r15 - 8], TagCheck
    jne .Bad
    mov rax, [r15 - 32]
    or rax, [r15 - 40]
    jz .First
    cmp qword [r15 - 32], 0
    je .AfterOtherwise
    lea rcx, [rel PrimBranch]
    call EmitJump
    mov rdx, [r15 - 40]
    mov [rax], rdx
    mov [r15 - 40], rax
    mov rcx, [r15 - 32]
    mov rdx, [rel Here]
    mov [rcx], rdx
.First:
    xor ebx, ebx
.Alt:
    push rbx
    mov rcx, [r15 - 24]
    call EmitLoad
    call Advance
    call ParseExpr
    mov rbx, [r15 - 16]
    mov rax, [rel ExprType]
    cmp rax, rbx
    je .Equal
    mov rcx, rax
    call TypeKind
    cmp rax, KList
    jne .Mixed
    mov rcx, [rel ExprType]
    call ElemOf
    cmp rax, rbx
    jne TypeError
    cmp rbx, TText
    je .HasText
    CompilePrim PrimListHas
    jmp .Joined
.HasText:
    CompilePrim PrimListHasText
    jmp .Joined
.Mixed:
    mov rax, rbx
    call NumericPair
    CompilePrim PrimDEq
    jmp .Joined
.Equal:
    cmp rbx, TText
    je .EqText
    cmp rbx, TDec
    je .EqDec
    CompilePrim PrimEq
    jmp .Joined
.EqText:
    CompilePrim PrimTextEq
    jmp .Joined
.EqDec:
    CompilePrim PrimDEq
.Joined:
    pop rbx
    test rbx, rbx
    jz .NoOr
    CompilePrim PrimOr
.NoOr:
    mov ebx, 1
    IfTok ",", .Alt
    lea rcx, [rel PrimBranch0]
    call EmitJump
    mov [r15 - 32], rax
    jmp Pushback
.Dummy:
    call Advance
    call ParseExpr
    IfTok ",", .Dummy
    jmp Pushback
.AfterOtherwise:
    Fail ErrIsAfter
.Bad:
    Fail ErrIs

TryWord:
    lea rcx, [rel PrimTry]
    call EmitJump
    DPush rax
    DPush 0
    DPush 0
    DPush 0
    DPush TagTry
    inc qword [rel OpenBlocks]
    ret

LaterWord:
    cmp qword [rel InFn], 0
    je .Bad
    mov rax, [rel LaterCount]
    cmp rax, 16
    jae .TooMany
    call GetInput
    mov rcx, [rel LaterCount]
    lea rdx, [rel LaterPos]
    mov [rdx + rcx * 8], rax
    inc qword [rel LaterCount]
    push qword [rel Here]
    call ParseOneStatement
    pop qword [rel Here]
    ret
.Bad:
    Fail ErrLaterWhere
.TooMany:
    Fail ErrTooMany

EmitLaters:
    mov rax, [rel LaterCount]
    test rax, rax
    jz .None
    push r12
    push r13
    call GetInput
    push rax
    push qword [rel TokPtr]
    push qword [rel TokLen]
    push qword [rel PrevTokPtr]
    mov rax, [rel LaterCount]
    push rax
.Loop:
    cmp qword [rsp], 0
    je .Done
    dec qword [rsp]
    mov rax, [rsp]
    lea rcx, [rel LaterPos]
    mov rcx, [rcx + rax * 8]
    call Unread
    call ParseOneStatement
    jmp .Loop
.Done:
    pop rax
    pop qword [rel PrevTokPtr]
    pop qword [rel TokLen]
    pop qword [rel TokPtr]
    pop rcx
    call Unread
    pop r13
    pop r12
.None:
    ret

ParseOneStatement:
    call NextToken
    test rdx, rdx
    jz .Bad
    mov r12, rax
    mov r13, rdx
    mov rcx, rax
    call FindWord
    test rax, rax
    jz .Expr
    cmp rdx, 2
    jne .Expr
    lea rcx, [rel SayWord]
    cmp rax, rcx
    je .Imm
    lea rcx, [rel SetWord]
    cmp rax, rcx
    je .Imm
    lea rcx, [rel ByeWord]
    cmp rax, rcx
    je .Imm
.Bad:
    Fail ErrLaterWhat
.Imm:
    mov [rel PrevTokPtr], r12
    mov [rel TokPtr], r12
    mov [rel TokLen], r13
    jmp rax
.Expr:
    xor ecx, ecx
    jmp StmtExpr
