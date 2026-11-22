CheckWord:
    call Advance
    mov qword [rel LastVarRef], 0
    call ParseExpr
    mov rcx, [rel OpenBlocks]
    cmp rcx, 64
    jae .NoSubj
    lea rdx, [rel CheckVars]
    mov rax, [rel LastVarRef]
    mov [rdx + rcx * 8], rax
.NoSubj:
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
    mov rcx, [rel OpenBlocks]
    call NarrowPopLevel
    mov rax, [r15 - 16]
    call KindOfType
    cmp rax, KUnion
    je .TypeCase
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
    jmp .Joined
.TypeCase:
    mov rcx, [r15 - 24]
    call EmitLoad
    call Advance
    IfTok "nothing", .NilCase
    call ParseTypeName
    jmp .HaveCase
.NilCase:
    mov eax, TNil
.HaveCase:
    push rax
    mov rcx, [r15 - 16]
    mov rdx, rax
    call UnionHas
    test eax, eax
    jz TypeError
    CompilePrim PrimTagIs
    mov rcx, [rsp]
    call Compile
    call Advance
    pop rdx
    cmp qword [rsp], 0
    jne .Joined
    push rdx
    push rdx
    IfTok ",", .CaseMany
    pop rdx
    pop rdx
    cmp rdx, TNil
    je .Joined
    mov rcx, [rel OpenBlocks]
    dec rcx
    cmp rcx, 64
    jae .Joined
    lea rax, [rel CheckVars]
    mov rcx, [rax + rcx * 8]
    test rcx, rcx
    jz .Joined
    call NarrowPush
    jmp .Joined
.CaseMany:
    pop rdx
    pop rdx
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
    cmp rax, 64
    jae .TooMany
    call GetInput
    mov rcx, [rel LaterCount]
    lea rdx, [rel LaterPos]
    mov [rdx + rcx * 8], rax
    lea rdx, [rel LaterBlock]
    mov qword [rdx + rcx * 8], 0
    inc qword [rel LaterCount]
    mov rcx, [rel TokPtr]
    add rcx, [rel TokLen]
.Peek:
    movzx eax, byte [rcx]
    cmp eax, ' '
    je .PeekNext
    cmp eax, 9
    je .PeekNext
    cmp eax, 13
    je .Block
    cmp eax, 10
    je .Block
    cmp eax, '#'
    je .Block
    test eax, eax
    jz .Block
    push qword [rel Here]
    call ParseOneStatement
    pop qword [rel Here]
    ret
.PeekNext:
    inc rcx
    jmp .Peek
.Block:
    mov rcx, [rel LaterCount]
    lea rdx, [rel LaterBlock]
    mov qword [rdx + rcx * 8 - 8], 1
    mov rax, [rel TokPtr]
    mov [rel DoStart], rax
    call SkipBody
    mov qword [rel TokLen], 0
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
    mov rax, [rsp]
    lea rcx, [rel LaterBlock]
    cmp qword [rcx + rax * 8], 0
    jne .Block
    call ParseOneStatement
    jmp .Loop
.Block:
    inc qword [rel LaterEmitting]
    push qword [rel OpenBlocks]
.BlockLoop:
    call GetInput
    push rax
    call NextToken
    mov [rel TokPtr], rax
    mov [rel TokLen], rdx
    pop rcx
    push rcx
    IfTok "end", .MaybeEnd
.Stmt:
    pop rcx
    call Unread
    call ParseAnyStatement
    jmp .BlockLoop
.MaybeEnd:
    mov rax, [rel OpenBlocks]
    cmp rax, [rsp + 8]
    jne .Stmt
    pop rcx
    pop rax
    dec qword [rel LaterEmitting]
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
