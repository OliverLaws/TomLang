InstanceStarted:
    cmp qword [rel InstanceMode], 0
    je .Allow
    mov rcx, [rel PendingNode]
    test rcx, rcx
    jz .Done
    mov [rcx + 224], rax
    mov rdx, [rcx + 232]
    mov r8, [rdx + 48]
    mov [rcx], r8
    mov [rdx + 48], rcx
    mov qword [rel PendingNode], 0
.Done:
    ret
.Allow:
    mov qword [rel AllowTypeVars], 1
    ret

GenericDefine:
    mov qword [rel GenericFound], 0
    mov ecx, 80
    call PermAlloc
    mov rcx, [rel NamePrefixPtr]
    mov [rax + 64], rcx
    mov rcx, [rel NamePrefixLen]
    mov [rax + 72], rcx
    mov rcx, [rel FnSig]
    mov [rax], rcx
    mov rcx, [rel DoStart]
    mov [rax + 8], rcx
    mov rcx, [rel SourceStart]
    mov [rax + 24], rcx
    mov rcx, [rel SourceEnd]
    mov [rax + 32], rcx
    mov rcx, [rel CurFile]
    mov [rax + 40], rcx
    mov qword [rax + 48], 0
    mov rcx, [rel Latest]
    mov [rax + 56], rcx
    mov byte [rcx + 16], 7
    mov rdx, [rel GenericCount]
    cmp rdx, 256
    jae .Many
    shl rdx, 4
    lea r8, [rel GenericTable]
    mov rcx, [rel FnSig]
    mov [r8 + rdx], rcx
    mov [r8 + rdx + 8], rax
    inc qword [rel GenericCount]
    push rax
    call SkipBody
    pop rcx
    mov [rcx + 16], rax
    mov rdx, [rel SourceEnd]
    mov [rcx + 32], rdx
    call EndDef
    mov qword [rel InFn], 0
    mov qword [rel LocalCount], 0
    mov qword [rel LaterCount], 0
    ret
.Many:
    Fail ErrTooMany

SkipBody:
    push rbx
    mov ebx, 1
.Loop:
    call NextToken
    test rdx, rdx
    jnz .Have
    cmp qword [rel FileMode], 0
    jne .Missing
    call ReadMoreLine
    jmp .Loop
.Have:
    mov [rel TokPtr], rax
    mov [rel TokLen], rdx
    IfTok "end", .End
    call SameLine
    test eax, eax
    jnz .Loop
    IfTok "if", .Open
    IfTok "repeat", .Open
    IfTok "check", .Open
    IfTok "try", .Open
    IfTok "do", .Open
    jmp .Loop
.Open:
    inc rbx
    jmp .Loop
.End:
    dec rbx
    jnz .Loop
    call GetInput
    pop rbx
    ret
.Missing:
    pop rbx
    cmp qword [rel FileMode], 0
    je .Prompt
    mov rax, [rel DoStart]
    mov [rel ErrPos], rax
    mov [rel PrevTokPtr], rax
    Fail ErrGenericEnd
.Prompt:
    Fail ErrGenericPrompt

Subst:
    test rax, rax
    jz .Ret
    push rax
    mov rcx, rax
    call TypeKind
    mov rcx, rax
    pop rax
    cmp rcx, KVar
    je .Var
    cmp rcx, KList
    je .List
    cmp rcx, KMap
    je .Map
    cmp rcx, KFunc
    je .Func
.Ret:
    ret
.Var:
    shl rax, 5
    lea rcx, [rel TypeTable]
    mov rax, [rcx + rax + 8]
    mov rax, [rbx + rax * 8]
    test rax, rax
    jnz .Ret
    mov qword [rel SubstFail], 1
    ret
.List:
    mov rcx, rax
    call ElemOf
    call Subst
    test rax, rax
    jz .Ret
    push rbx
    mov rcx, rax
    call ListOf
    pop rbx
    ret
.Map:
    push rax
    mov rcx, rax
    call ElemOf
    call Subst
    pop rcx
    test rax, rax
    jz .Ret
    push rbx
    push rax
    call KeyOf
    mov rdx, rax
    pop rcx
    call MapKeyed
    pop rbx
    ret
.Func:
    push r12
    push r13
    sub rsp, 136
    mov r12, rax
    shl r12, 5
    lea rcx, [rel TypeTable]
    add r12, rcx
    xor r13d, r13d
.FuncParam:
    cmp r13, [r12 + 16]
    jae .FuncRet
    mov rax, [r12 + 24]
    mov rax, [rax + r13 * 8]
    call Subst
    mov [rsp + r13 * 8], rax
    inc r13
    jmp .FuncParam
.FuncRet:
    mov rax, [r12 + 8]
    call Subst
    mov rcx, rax
    mov rdx, [r12 + 16]
    mov r8, rsp
    push rbx
    call FuncOf
    pop rbx
    add rsp, 136
    pop r13
    pop r12
    ret

Unify:
    cmp rcx, rdx
    je .Ok
    test rdx, rdx
    jz .Ok
    test rcx, rcx
    jz .Ok
    push rcx
    push rdx
    call TypeKind
    mov r8, rax
    pop rdx
    pop rcx
    cmp r8, KVar
    je .Var
    cmp r8, KList
    je .Elem
    cmp r8, KMap
    je .Elem
    cmp r8, KFunc
    je .Func
.Ok:
    ret
.Var:
    shl rcx, 5
    lea rax, [rel TypeTable]
    mov rcx, [rax + rcx + 8]
    mov rax, [rbx + rcx * 8]
    test rax, rax
    jz .Bind
    cmp rax, rdx
    je .Ok
    Fail ErrGenericBoth
.Bind:
    cmp rcx, 26
    jne .BindOk
    cmp rdx, TNum
    je .BindOk
    cmp rdx, TDec
    je .BindOk
    Fail ErrNumericType
.BindOk:
    mov [rbx + rcx * 8], rdx
    ret
.Elem:
    push rcx
    push r8
    mov rcx, rdx
    push rdx
    call TypeKind
    pop rdx
    pop r8
    pop rcx
    cmp rax, r8
    jne .Bad
    push rdx
    call ElemOf
    pop rcx
    push rax
    call ElemOf
    mov rdx, rax
    pop rcx
    jmp Unify
.Func:
    push rcx
    push rdx
    mov rcx, rdx
    call TypeKind
    pop rdx
    pop rcx
    cmp rax, KFunc
    jne .Bad
    push r12
    push r13
    push r14
    lea rax, [rel TypeTable]
    shl rcx, 5
    lea r12, [rax + rcx]
    shl rdx, 5
    lea r13, [rax + rdx]
    mov rax, [r12 + 16]
    cmp rax, [r13 + 16]
    jne .BadPop
    xor r14d, r14d
.FuncLoop:
    cmp r14, [r12 + 16]
    jae .FuncRet
    mov rcx, [r12 + 24]
    mov rcx, [rcx + r14 * 8]
    mov rdx, [r13 + 24]
    mov rdx, [rdx + r14 * 8]
    call Unify
    inc r14
    jmp .FuncLoop
.FuncRet:
    mov rcx, [r12 + 8]
    mov rdx, [r13 + 8]
    call Unify
    pop r14
    pop r13
    pop r12
    ret
.BadPop:
    pop r14
    pop r13
    pop r12
.Bad:
    Fail ErrArgType

GetInstance:
    push rbx
    push rsi
    push rdi
    push r12
    mov r12, rdx
    xor eax, eax
    lea r8, [rel GenericTable]
.Find:
    cmp rax, [rel GenericCount]
    jae .Lost
    mov r9, rax
    shl r9, 4
    cmp [r8 + r9], rcx
    je .GotInfo
    inc rax
    jmp .Find
.Lost:
    Fail ErrGenericUnknown
.GotInfo:
    mov rbx, [r8 + r9 + 8]
    mov rsi, [rbx + 48]
.Node:
    test rsi, rsi
    jz .New
    xor ecx, ecx
.Cmp:
    cmp ecx, 27
    je .Found
    mov rax, [rsi + 8 + rcx * 8]
    cmp rax, [r12 + rcx * 8]
    jne .NextNode
    inc ecx
    jmp .Cmp
.NextNode:
    mov rsi, [rsi]
    jmp .Node
.Found:
    mov rax, [rsi + 224]
    jmp .Out
.New:
    cmp qword [rel InstanceDepth], 32
    jae .Deep
    mov ecx, 240
    call PermAlloc
    mov rsi, rax
    xor ecx, ecx
.Copy:
    cmp ecx, 27
    je .Copied
    mov rax, [r12 + rcx * 8]
    mov [rsi + 8 + rcx * 8], rax
    inc ecx
    jmp .Copy
.Copied:
    mov qword [rsi], 0
    mov qword [rsi + 224], 0
    mov [rsi + 232], rbx
    push rsi
    mov [rel PendingNode], rsi
    mov rcx, rbx
    call CompileInstance
    pop rsi
    mov rax, [rsi + 224]
.Out:
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret
.Deep:
    Fail ErrGenericDeep

%define PSize (ParserStateEnd - ParserState)

CompileInstance:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push rbp
    mov rbx, rcx
    mov rax, [rel InstanceDepth]
    imul rax, rax, PSize + 256
    lea r12, [rel InstanceSaves]
    add r12, rax
    lea rsi, [rel ParserState]
    mov rdi, r12
    mov rcx, PSize / 8
    rep movsq
    lea rbp, [r12 + PSize]
    mov rax, [rel TempTop]
    mov [rbp], rax
    mov rax, [rel Here]
    mov [rbp + 8], rax
    mov rax, [rel SavedHere]
    mov [rbp + 16], rax
    mov rax, [rel FnEntry]
    mov [rbp + 24], rax
    call GetInput
    mov [rbp + 32], rax
    mov [rbp + 40], rdx
    mov rax, [rel NamePrefixPtr]
    mov [rbp + 48], rax
    mov rax, [rel NamePrefixLen]
    mov [rbp + 56], rax
    mov rax, [rbx + 64]
    mov [rel NamePrefixPtr], rax
    mov rax, [rbx + 72]
    mov [rel NamePrefixLen], rax
    lea rcx, [rbp + 64]
    call SaveMain
    mov rsi, [rel PendingNode]
    add rsi, 8
    lea rdi, [rel InstanceBindings]
    mov ecx, 27
    rep movsq
    mov qword [rel InstanceMode], 1
    mov qword [rel AllowTypeVars], 0
    mov qword [rel GenericFound], 0
    mov qword [rel InFn], 0
    mov qword [rel OpenBlocks], 0
    mov qword [rel LocalCount], 0
    mov qword [rel HintCount], 0
    mov qword [rel CurHintCount], 0
    mov qword [rel OuterFrame], 0
    mov qword [rel ExprDepth], 0
    mov qword [rel TypeDepth], 0
    mov qword [rel MakingConst], 0
    mov qword [rel LaterCount], 0
    mov qword [rel ReplaceLen], 0
    mov qword [rel NestListCount], 0
    mov qword [rel ScopeCount], 0
    mov rax, [rel NestDepth]
    mov [rel NestFloor], rax
    mov rcx, [rel InstanceDepth]
    call EnterInstanceSpace
    inc qword [rel InstanceDepth]
    mov rcx, [rbx + 24]
    mov rdx, [rbx + 32]
    mov r8, [rbx + 40]
    call SetMainFile
    mov rcx, [rbx + 8]
    mov rdx, [rbx + 16]
    sub rdx, rcx
    call SetInput
    call NextToken
    mov [rel TokPtr], rax
    mov [rel TokLen], rdx
    mov [rel PrevTokPtr], rax
    call DoWord
.Body:
    cmp qword [rel OpenBlocks], 0
    je .Done
    call ParseAnyStatement
    jmp .Body
.Done:
    dec qword [rel InstanceDepth]
    mov rcx, [rel InstanceDepth]
    call LeaveInstanceSpace
    mov rax, [rel InstanceDepth]
    imul rax, rax, PSize + 256
    lea r12, [rel InstanceSaves]
    add r12, rax
    lea rbp, [r12 + PSize]
    mov rsi, r12
    lea rdi, [rel ParserState]
    mov rcx, PSize / 8
    rep movsq
    mov rax, [rbp]
    mov [rel TempTop], rax
    mov rax, [rbp + 8]
    mov [rel Here], rax
    mov rax, [rbp + 16]
    mov [rel SavedHere], rax
    mov rax, [rbp + 24]
    mov [rel FnEntry], rax
    mov rax, [rbp + 48]
    mov [rel NamePrefixPtr], rax
    mov rax, [rbp + 56]
    mov [rel NamePrefixLen], rax
    lea rcx, [rbp + 64]
    call RestoreMain
    mov rcx, [rbp + 32]
    mov rdx, [rbp + 40]
    sub rdx, rcx
    call SetInput
    pop rbp
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

ParseAnyStatement:
    call NextToken
    test rdx, rdx
    jz .Missing
    mov r12, rax
    mov r13, rdx
    call RecordLine
    mov rcx, r12
    mov rdx, r13
    call FindWord
    test rax, rax
    jz .Expr
    cmp rdx, 2
    jne .Expr
    push rax
    mov rcx, rax
    call NoteStmt
    pop rax
    mov [rel PrevTokPtr], r12
    mov [rel TokPtr], r12
    mov [rel TokLen], r13
    jmp rax
.Expr:
    xor ecx, ecx
    call NoteStmt
    mov ecx, 1
    jmp StmtExpr
.Missing:
    Fail ErrGenericEnd

CallHint:
    cmp qword [rsp + 8 + 928], 0
    je SetHint
    push rbx
    lea rbx, [rsp + 16 + 704]
    mov qword [rel SubstFail], 0
    call Subst
    pop rbx
    jmp SetHint

CallUnify:
    push rbx
    lea rbx, [rsp + 16 + 704]
    mov rax, [rsp + 16 + 936]
    mov r10, rax
    btr rax, 40
    mov rdx, [rsp + 16 + 640]
    call ParamTypeOf
    bt r10, 40
    jnc .Have
    mov rcx, rax
    call ElemOf
.Have:
    mov rcx, rax
    mov rdx, [rel ExprType]
    call Unify
    pop rbx
    ret

CallInstance:
    push rbx
    push r12
    lea rbx, [rsp + 24 + 704]
    mov qword [rel SubstFail], 0
    xor r12d, r12d
.Params:
    mov rdx, [rsp + 24 + 640]
    cmp r12, [rdx - 16]
    jae .Ret
    mov rax, r12
    call ParamTypeOf
    call Subst
    inc r12
    jmp .Params
.Ret:
    mov rdx, [rsp + 24 + 640]
    mov rax, [rdx - 8]
    call Subst
    cmp qword [rel SubstFail], 0
    jne .Unknown
    mov rcx, [rsp + 24 + 640]
    mov rdx, rbx
    call GetInstance
    mov [rsp + 24 + 640], rax
    mov qword [rsp + 24 + 928], 0
    pop r12
    pop rbx
    ret
.Unknown:
    Fail ErrGenericUnknown
