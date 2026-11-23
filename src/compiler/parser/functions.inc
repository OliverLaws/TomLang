ReturnWord:
    cmp qword [rel InFn], 0
    je .Bad
    cmp qword [rel LaterEmitting], 0
    jne .Bad
    mov r8, [rel FnSig]
    mov rax, [r8 - 8]
    call SetHint
    call Advance
    cmp qword [rel TokLen], 0
    je .Bare
    call SameLine
    test eax, eax
    jz .Bare
    IfTok "end", .Bare
    call ParseExpr
    IfTok ",", .Tuple
    jmp .Typed
.Tuple:
    call ParseTuple
.Typed:
    mov r8, [rel FnSig]
    mov rax, [r8 - 8]
    call CoerceTo
    mov rax, [rel ExprType]
    test rax, rax
    jz TypeError
    mov r8, [rel FnSig]
    mov rdx, [r8 - 8]
    test rdx, rdx
    jz .SetReturn
    cmp rdx, rax
    je .Emit
    cmp rdx, TDec
    jne .ReturnCompat
    cmp rax, TNum
    jne TypeError
    CompilePrim PrimToDec
    jmp .Emit
.ReturnCompat:
    xchg rax, rdx
    push rax
    call Compatible
    pop rcx
    cmp rax, rcx
    jne TypeError
    jmp .Emit
.SetReturn:
    mov [r8 - 8], rax
.Emit:
    mov ecx, TagFn
    call EndTries
    call EmitLaters
    call EmitReturn
    jmp Pushback
.Bare:
    mov r8, [rel FnSig]
    mov rax, [r8 - 8]
    test rax, rax
    jnz .NeedValue
    CompileNum 0
    mov ecx, TagFn
    call EndTries
    call EmitLaters
    call EmitReturn
    jmp Pushback
.NeedValue:
    Fail ErrReturnValue
.Bad:
    Fail ErrReturn

DoWord:
    mov rax, [rel TokPtr]
    mov [rel DoStart], rax
    cmp qword [rel InFn], 0
    jne .MaybeNested
    cmp qword [rel OpenBlocks], 0
    jne .Bad
.Begin:
    mov qword [rel ImplicitScanned], 0
    mov qword [rel InParams], 0
    call Advance
    cmp qword [rel TokLen], 0
    je .Bad
    mov qword [rel MethodSelf], 0
    mov qword [rel OpMode], 0
    mov qword [rel NarrowCount], 0
    IfTok "(", .Operator
    IfTok "-", .Unary
    call IsNameStart
    test eax, eax
    jz .Bad
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    mov [rel DefNamePtr], rcx
    mov [rel DefNameLen], rdx
    cmp byte [rcx + rdx], '.'
    jne .NameSet
    cmp qword [rel NestDepth], 0
    jne .Bad
    call MethodOwner
    mov [rel MethodSelf], rax
    call Advance
    call Advance
    call IsNameStart
    test eax, eax
    jz .Bad
    mov rcx, [rel DefNamePtr]
    mov rdx, [rel TokPtr]
    add rdx, [rel TokLen]
    sub rdx, rcx
    mov [rel DefNameLen], rdx
    jmp .NameSet
.Unary:
    cmp qword [rel NestDepth], 0
    jne .Bad
    call UnaryHead
    push rdx
    call CopyString
    pop rdx
    mov [rel DefNamePtr], rax
    mov [rel DefNameLen], rdx
    mov qword [rel OpMode], 3
    jmp .OpCheck
.Operator:
    cmp qword [rel NestDepth], 0
    jne .Bad
    call OperatorHead
    push rdx
    call CopyString
    pop rdx
    mov [rel DefNamePtr], rax
    mov [rel DefNameLen], rdx
    mov qword [rel OpMode], 1
.OpCheck:
    cmp qword [rel PreScanActive], 0
    jne .NotDone
    cmp qword [rel InstanceMode], 0
    jne .NotDone
    push qword [rel NamePrefixLen]
    push rax
    mov qword [rel NamePrefixLen], 0
    mov rcx, [rel DefNamePtr]
    mov rdx, [rel DefNameLen]
    call ForwardDone
    pop rcx
    pop qword [rel NamePrefixLen]
    test eax, eax
    jz .NotDone
    mov qword [rel OpMode], 0
    call SkipBody
    mov qword [rel TokLen], 0
    ret
.NameSet:
    cmp qword [rel PreScanActive], 0
    jne .NotDone
    cmp qword [rel InstanceMode], 0
    jne .NotDone
    mov rax, [rel NestDepth]
    cmp rax, [rel NestFloor]
    jne .NotDone
    mov rcx, [rel DefNamePtr]
    mov rdx, [rel DefNameLen]
    call ForwardDone
    test eax, eax
    jz .NotDone
    mov qword [rel MethodSelf], 0
    call SkipBody
    mov qword [rel TokLen], 0
    ret
.NotDone:
    mov rcx, [rel DefNamePtr]
    mov rdx, [rel DefNameLen]
    cmp qword [rel InstanceMode], 0
    je .Named
    xor edx, edx
.Named:
    cmp qword [rel OpMode], 0
    je .PlainDef
    push qword [rel NamePrefixLen]
    push rax
    mov qword [rel NamePrefixLen], 0
    call BeginDef
    pop rax
    pop qword [rel NamePrefixLen]
    jmp .Defined
.PlainDef:
    call BeginDef
.Defined:
    mov rax, [rel Latest]
    mov byte [rax + 16], 4
    mov ebx, SigCells
.Sig:
    xor ecx, ecx
    call Compile
    dec ebx
    jnz .Sig
    mov rax, [rel Here]
    mov rcx, [rel Latest]
    mov [rcx + 8], rax
    mov [rel FnSig], rax
    cmp qword [rel ForwardMode], 0
    jne .NoPatch
    cmp qword [rel InstanceMode], 0
    jne .NoPatch
    mov rax, [rel NestDepth]
    cmp rax, [rel NestFloor]
    jne .NoPatch
    call PatchForward
.NoPatch:
    call InstanceStarted
    mov qword [rel InFn], 1
    mov qword [rel LocalCount], 0
    mov qword [rel LaterCount], 0
    call NextFnId
    mov [rel CurFnId], rax
    mov qword [rel CurLinkOff], -1
    mov qword [rel CurHeap], 0
    cmp qword [rel ForwardMode], 0
    jne .StackFrame
    mov rcx, [rel DoStart]
    call ScanClosures
    mov [rel CurHeap], rax
    test rax, rax
    jz .StackFrame
    CompilePrim PrimEnterHeap
    jmp .Entered
.StackFrame:
    CompilePrim PrimEnter
.Entered:
    mov rax, [rel Here]
    mov [rel FnFrameSlot], rax
    xor ecx, ecx
    call Compile
    call Advance
    Expect "(", ErrParen
    call Advance
    cmp qword [rel MethodSelf], 0
    je .NoSelf
    call AddSelfParam
.NoSelf:
    mov qword [rel InParams], 1
    IfTok ")", .ParamsDone
.ParamLoop:
    cmp qword [rel TokLen], 0
    je .BadParen
    call IsNameStart
    test eax, eax
    jz .BadParen
    mov r8, [rel FnSig]
    test qword [r8 - SigFlags], 1
    jnz .RestNotLast
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call AddLocal
    mov rbx, [rel LocalCount]
    dec rbx
    cmp rbx, 16
    jae .TooMany
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    push rdx
    call CopyString
    pop rdx
    mov r8, [rel FnSig]
    mov r9, rbx
    shl r9, 4
    neg r9
    mov [r8 - SigName + r9], rax
    mov [r8 - SigName - 8 + r9], rdx
    call Advance
    IfTok "...", .Rest
    jmp .AfterRest
.Rest:
    mov r8, [rel FnSig]
    or qword [r8 - SigFlags], 1
    call Advance
.AfterRest:
    push rbx
    push 0
    IfTok ":", .ParamType
    jmp .MaybeDefault
.ParamType:
    call Advance
    call ParseTypeName
    mov [rsp], rax
    call Advance
.MaybeDefault:
    IfTok "=", .Default
    pop rax
    pop rbx
    test rax, rax
    jnz .SetParamType
    mov eax, TNum
    mov r8, [rel FnSig]
    test qword [r8 - SigFlags], 1
    jnz .SetParamType
    call ImplicitParamType
    jmp .SetParamType
.Default:
    mov r8, [rel FnSig]
    test qword [r8 - SigFlags], 1
    jnz .RestDefault
    call Advance
    mov qword [rel InFn], 0
    lea rcx, [rel PrimBranch]
    call EmitJump
    push rax
    push qword [rel Here]
    call ParseExpr
    mov qword [rel InFn], 1
    mov rax, [rsp + 16]
    mov rdx, [rel ExprType]
    test rax, rax
    jz .DefaultTakes
    cmp rax, rdx
    je .DefaultTyped
    cmp rax, TDec
    jne .DefaultCompat
    cmp rdx, TNum
    jne TypeError
    CompilePrim PrimToDec
    jmp .DefaultTyped
.DefaultCompat:
    call Compatible
    cmp rax, [rsp + 16]
    jne TypeError
    jmp .DefaultTyped
.DefaultTakes:
    test rdx, rdx
    jz TypeError
    mov [rsp + 16], rdx
.DefaultTyped:
    CompilePrim PrimExit
    pop rcx
    pop rdx
    mov rax, [rel Here]
    mov [rdx], rax
    pop rax
    pop rbx
    mov r8, [rel FnSig]
    mov r9, rbx
    shl r9, 3
    neg r9
    mov [r8 - SigDef + r9], rcx
.SetParamType:
    mov r8, [rel FnSig]
    test qword [r8 - SigFlags], 1
    jz .NotRest
    mov rcx, rax
    call ListOf
.NotRest:
    push rax
    call KindOfType
    pop rcx
    cmp rax, KList
    jne .ParamTypeKeep
    push rcx
    call ElemOf
    pop rcx
    test rax, rax
    jnz .ParamTypeKeep
    mov ecx, TNum
    call ListOf
    mov rcx, rax
.ParamTypeKeep:
    mov rax, rcx
.ParamTypeOk:
    lea r8, [rel LocalType]
    mov [r8 + rbx * 8], rax
    mov r8, [rel FnSig]
    mov r9, rbx
    shl r9, 3
    sub r8, 24
    sub r8, r9
    mov [r8], rax
    cmp qword [rel OpMode], 1
    jne .NotOp
    Expect ")", ErrOpHead
    call Advance
    call Advance
    Expect "(", ErrOpHead
    call Advance
    mov qword [rel OpMode], 2
    jmp .ParamLoop
.NotOp:
    IfTok ",", .NextParam
    IfTok ")", .ParamsDone
.BadParen:
    Fail ErrParen
.NextParam:
    call Advance
    jmp .ParamLoop
.ParamsDone:
    mov rax, [rel LocalCount]
    cmp qword [rel OpMode], 0
    je .ParamsOk
    cmp qword [rel OpMode], 3
    jne .TwoParams
    mov qword [rel OpMode], 0
    cmp rax, 1
    jne .OpBad
    jmp .ParamsOk
.TwoParams:
    mov qword [rel OpMode], 0
    cmp rax, 2
    jne .OpBad
.ParamsOk:
    mov r8, [rel FnSig]
    mov [r8 - 16], rax
    call Advance
    IfTok ":", .ReturnType
    call Pushback
    jmp .Prologue
.ReturnType:
    mov qword [rel InParams], 0
    call Advance
    call ParseTypeName
    mov r8, [rel FnSig]
    mov [r8 - 8], rax
.Prologue:
    mov qword [rel InParams], 0
    mov qword [rel AllowTypeVars], 0
    cmp qword [rel ForwardMode], 0
    jne ForwardFinish
    mov rax, [rel NestDepth]
    cmp rax, [rel NestFloor]
    je .NotNested
    cmp qword [rel GenericFound], 0
    jne .NestGeneric
    lea rcx, [rel LinkName]
    mov edx, 6
    call AddLocal
    and rax, -8
    mov [rel CurLinkOff], rax
    mov rcx, [rel ScopeCount]
    dec rcx
    shl rcx, 6
    lea rdx, [rel ScopeTab]
    mov rax, [rdx + rcx + 48]
    shl rax, 8
    or rax, 4
    mov r8, [rel FnSig]
    or [r8 - SigFlags], rax
    mov rcx, [rel NestDepth]
    mov rax, [rel FnEntry]
    lea rdx, [rel NestEntryTab]
    mov [rdx + rcx * 8 - 8], rax
    lea rdx, [rel NestDoneTab]
    mov qword [rdx + rcx * 8 - 8], 1
.NotNested:
    cmp qword [rel GenericFound], 0
    jne GenericDefine
    mov rbx, [rel LocalCount]
.PLoop:
    test rbx, rbx
    jz .PDone
    dec rbx
    CompilePrim PrimLocalSet
    mov rcx, rbx
    shl rcx, 3
    call Compile
    jmp .PLoop
.PDone:
    CompilePrim PrimBranch
    mov rax, [rel Here]
    mov [rel FnInitCell], rax
    lea rcx, [rax + 8]
    call Compile
    mov rax, [rel FnFrameSlot]
    lea rcx, [rel PrimEnter]
    cmp [rax - 8], rcx
    jne .KeepEnter
    lea rcx, [rel PrimEnterArgs]
    mov [rax - 8], rcx
.KeepEnter:
    DPush 0
    DPush 0
    DPush 0
    xor eax, eax
    mov rcx, [rel DefNamePtr]
    cmp qword [rel DefNameLen], 7
    jb .NotTaskFn
    cmp dword [rcx], '_tlT'
    jne .NotTaskFn
    cmp word [rcx + 4], 'as'
    jne .NotTaskFn
    cmp byte [rcx + 6], 'k'
    jne .NotTaskFn
    mov eax, 1
.NotTaskFn:
    DPush rax
    DPush TagFn
    inc qword [rel OpenBlocks]
    ret
.TooMany:
    Fail ErrTooMany
.OpBad:
    Fail ErrOpHead
.NestGeneric:
    Fail ErrNestGeneric
.MaybeNested:
    cmp qword [rel ForwardMode], 0
    jne .Bad
    cmp qword [rel FileMode], 0
    je .Bad
    cmp qword [rel OuterFrame], 0
    jne .Bad
    cmp qword [rel NestDepth], MaxNest
    jae .NestDeep
    call NestBegin
    jmp .Begin
.NestDeep:
    Fail ErrNestDeep
.RestNotLast:
    Fail ErrRestLast
.RestDefault:
    Fail ErrRestDefault
.Bad:
    Fail ErrDo

NestBegin:
    push rsi
    push rdi
    push rbx
    mov rbx, [rel NestDepth]
    imul rdi, rbx, (ParserStateEnd - ParserState)
    lea rax, [rel NestSaves]
    add rdi, rax
    push rdi
    lea rsi, [rel ParserState]
    mov rcx, (ParserStateEnd - ParserState) / 8
    rep movsq
    pop rdi
    mov rcx, rdi
    call ScopePushSaved
    lea rdx, [rel NestVarTab]
    mov rax, rbx
    shl rax, 5
    add rdx, rax
    mov rax, [rel Here]
    mov [rdx], rax
    mov rax, [rel SavedHere]
    mov [rdx + 8], rax
    mov rax, [rel FnEntry]
    mov [rdx + 16], rax
    lea ecx, [rbx + NestRegion]
    call EnterInstanceSpace
    lea rdx, [rel NestInstTab]
    mov rax, [rel InstanceMode]
    or rax, [rel NestInInstance]
    mov [rdx + rbx * 8], rax
    mov [rel NestInInstance], rax
    lea rdx, [rel NestDoneTab]
    mov qword [rdx + rbx * 8], 0
    inc qword [rel NestDepth]
    mov qword [rel NestPending], 0
    mov qword [rel InFn], 0
    mov rax, [rel OpenBlocks]
    add [rel BlockBase], rax
    mov qword [rel OpenBlocks], 0
    mov qword [rel LocalCount], 0
    mov qword [rel LaterCount], 0
    mov qword [rel InstanceMode], 0
    mov qword [rel AllowTypeVars], 0
    mov qword [rel GenericFound], 0
    mov qword [rel HintCount], 0
    mov qword [rel CurHintCount], 0
    mov qword [rel OuterFrame], 0
    mov qword [rel MakingConst], 0
    mov qword [rel ReplaceLen], 0
    pop rbx
    pop rdi
    pop rsi
    ret

NestEnd:
    mov qword [rel NestPending], 0
    mov rcx, [rel NestDepth]
    lea rdx, [rel NestDoneTab]
    cmp qword [rdx + rcx * 8 - 8], 0
    je NestAbort
    lea rdx, [rel NestEntryTab]
    mov rax, [rdx + rcx * 8 - 8]
    push rax
    push rax
    call NestAbort
    pop rdx
    pop rdx
    mov rax, [rel NestListCount]
    cmp rax, 64
    jae .Full
    lea rcx, [rel NestList]
    mov [rcx + rax * 8], rdx
    inc qword [rel NestListCount]
.Full:
    ret

NestAbort:
    push rsi
    push rdi
    push rbx
    dec qword [rel NestDepth]
    mov rbx, [rel NestDepth]
    imul rsi, rbx, (ParserStateEnd - ParserState)
    lea rax, [rel NestSaves]
    add rsi, rax
    lea rdi, [rel ParserState]
    mov rcx, (ParserStateEnd - ParserState) / 8
    rep movsq
    lea rdx, [rel NestVarTab]
    mov rax, rbx
    shl rax, 5
    add rdx, rax
    mov rax, [rdx]
    mov [rel Here], rax
    mov rax, [rdx + 8]
    mov [rel SavedHere], rax
    mov rax, [rdx + 16]
    mov [rel FnEntry], rax
    lea ecx, [rbx + NestRegion]
    call LeaveInstanceSpace
    xor eax, eax
    test rbx, rbx
    jz .Top
    lea rdx, [rel NestInstTab]
    mov rax, [rdx + rbx * 8 - 8]
.Top:
    mov [rel NestInInstance], rax
    pop rbx
    pop rdi
    pop rsi
    ret

NestHeaderDone:
    mov rax, [rel NestDepth]
    test rax, rax
    jz .Out
    lea rdx, [rel NestDoneTab]
    mov rax, [rdx + rax * 8 - 8]
.Out:
    ret

HideNested:
    xor eax, eax
.Loop:
    cmp rax, [rel NestListCount]
    jae .Done
    lea rcx, [rel NestList]
    mov rcx, [rcx + rax * 8]
    mov byte [rcx + 17], 0
    inc rax
    jmp .Loop
.Done:
    mov qword [rel NestListCount], 0
    ret

EmitLink:
    mov rcx, [rax - SigFlags]
    shr rcx, 8
    call OwnerDistance
    cmp rax, -1
    je .Bad
    mov rcx, rax
    jmp EmitFrameOf
.Bad:
    Fail ErrNestCall

FullForward:
    mov qword [rel ForwardMode], 0
    mov qword [rel FnEntry], 0
    call DoWord
    mov rax, [rel FnEntry]
    mov [rel FullEntry], rax
.Body:
    cmp qword [rel OpenBlocks], 0
    je .Done
    call ParseAnyStatement
    jmp .Body
.Done:
    cmp qword [rel FullEntry], 0
    je .Out
    cmp qword [rel ForwardCount], MaxForward
    jae .Out
    mov rcx, [rel ForwardCount]
    imul rcx, rcx, 24
    lea rdx, [rel ForwardTable]
    add rdx, rcx
    mov rax, [rel FullEntry]
    mov [rdx], rax
    mov qword [rdx + 8], 1
    mov rcx, [rel CurFile]
    mov [rdx + 16], rcx
    inc qword [rel ForwardCount]
.Out:
    ret

ForwardDone:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    mov r12, rcx
    mov r13, rdx
    mov r8, [rel NamePrefixLen]
    lea r9, [r8 + r13]
    cmp r9, 250
    ja .No
    lea rdi, [rel FwdNameBuf]
    mov rsi, [rel NamePrefixPtr]
    mov rcx, r8
    rep movsb
    mov rsi, r12
    mov rcx, r13
    rep movsb
    xor ebx, ebx
.Find:
    cmp rbx, [rel ForwardCount]
    jae .No
    imul rax, rbx, 24
    lea rdx, [rel ForwardTable]
    add rdx, rax
    inc rbx
    cmp qword [rdx + 8], 1
    jne .Find
    mov rax, [rdx + 16]
    cmp rax, [rel CurFile]
    jne .Find
    mov r10, [rdx]
    movzx eax, byte [r10 + 17]
    cmp rax, r9
    jne .Find
    lea rsi, [r10 + 18]
    lea rdi, [rel FwdNameBuf]
    mov rcx, r9
    repe cmpsb
    jne .Find
    mov qword [rdx + 8], 2
    mov eax, 1
    jmp .Out
.No:
    xor eax, eax
.Out:
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

ForwardFinish:
    cmp qword [rel GenericFound], 0
    jne GenericDefine
    cmp qword [rel ForwardCount], MaxForward
    jae PreScanFail
    mov rax, [rel FnSig]
    lea rcx, [rel PrimMissingFn]
    mov [rax], rcx
    mov qword [rax + 8], 0
    cmp qword [rax - 8], 0
    jne .Typed
    or qword [rax - SigFlags], 2
.Typed:
    mov rcx, [rel ForwardCount]
    imul rcx, rcx, 24
    lea rdx, [rel ForwardTable]
    add rdx, rcx
    mov rcx, [rel Latest]
    mov [rdx], rcx
    mov [rdx + 8], rax
    mov rcx, [rel CurFile]
    mov [rdx + 16], rcx
    inc qword [rel ForwardCount]
    jmp EndDef

PatchForward:
    push rbx
    push rsi
    push rdi
    mov r8, [rel Latest]
    movzx r9d, byte [r8 + 17]
    xor ebx, ebx
.Find:
    cmp rbx, [rel ForwardCount]
    jae .Out
    imul rax, rbx, 24
    lea rdx, [rel ForwardTable]
    add rdx, rax
    inc rbx
    mov rax, [rdx + 8]
    cmp rax, 2
    jbe .Find
    mov rax, [rdx + 16]
    cmp rax, [rel CurFile]
    jne .Find
    mov r10, [rdx]
    movzx eax, byte [r10 + 17]
    cmp eax, r9d
    jne .Find
    lea rsi, [r8 + 18]
    lea rdi, [r10 + 18]
    mov rcx, r9
    repe cmpsb
    jne .Find
    mov rax, [rdx + 8]
    mov qword [rdx + 8], 0
    lea rcx, [rel PrimBranch]
    mov [rax], rcx
    mov rcx, [rel FnSig]
    mov [rax + 8], rcx
.Out:
    pop rdi
    pop rsi
    pop rbx
    ret

PreDeclare:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push rbp
    mov r12, rcx
    mov r13, rdx
    mov rbx, [rel PreScanActive]
    imul rdi, rbx, (ParserStateEnd - ParserState)
    lea rax, [rel PreScanSaves]
    add rdi, rax
    lea rsi, [rel ParserState]
    mov rcx, (ParserStateEnd - ParserState) / 8
    rep movsq
    mov rdi, rbx
    shl rdi, 6
    lea rax, [rel PreScanVarTab]
    add rdi, rax
    mov rax, [rel Latest]
    mov [rdi], rax
    mov rax, [rel DictHere]
    mov [rdi + 8], rax
    mov rax, [rel Here]
    mov [rdi + 16], rax
    mov rax, [rel SavedHere]
    mov [rdi + 24], rax
    mov rax, [rel FnEntry]
    mov [rdi + 32], rax
    mov [rdi + 40], r15
    mov rax, [rel ForwardMode]
    mov [rdi + 48], rax
    lea ecx, [rbx + ForwardRegion]
    call EnterInstanceSpace
    lea rax, [rel PreScanRspTab]
    mov [rax + rbx * 8], rsp
    inc qword [rel PreScanActive]
    mov qword [rel ForwardMode], 1
    mov qword [rel ScopeCount], 0
    mov rax, [rel NestDepth]
    mov [rel NestFloor], rax
    mov qword [rel InFn], 0
    mov qword [rel OpenBlocks], 0
    mov qword [rel InstanceMode], 0
    mov qword [rel AllowTypeVars], 0
    mov qword [rel GenericFound], 0
    mov qword [rel LocalCount], 0
    mov qword [rel HintCount], 0
    mov qword [rel CurHintCount], 0
    mov qword [rel OuterFrame], 0
    mov qword [rel ExprDepth], 0
    mov qword [rel TypeDepth], 0
    mov qword [rel MakingConst], 0
    mov qword [rel LaterCount], 0
    mov qword [rel ReplaceLen], 0
    mov [rel TokPtr], r12
    mov [rel PrevTokPtr], r12
    mov [rel TokLen], r13
    call [rel PreHandler]
    call PreRestore
    jmp PreDeclareOut

PreScanFail:
    mov rbx, [rel PreScanActive]
    dec rbx
    lea rax, [rel PreScanRspTab]
    mov rsp, [rax + rbx * 8]
    call PreRestore
    mov rdi, rbx
    shl rdi, 6
    lea rax, [rel PreScanVarTab]
    mov rax, [rax + rdi]
    mov [rel Latest], rax
PreDeclareOut:
    mov rbx, [rel PreScanActive]
    dec rbx
    lea ecx, [rbx + ForwardRegion]
    call LeaveInstanceSpace
    mov rdi, rbx
    shl rdi, 6
    lea rax, [rel PreScanVarTab]
    mov rax, [rax + rdi + 48]
    mov [rel ForwardMode], rax
    dec qword [rel PreScanActive]
    pop rbp
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

PreRestore:
    mov rax, [rel PreScanActive]
    dec rax
    push rax
    imul rsi, rax, (ParserStateEnd - ParserState)
    lea rdx, [rel PreScanSaves]
    add rsi, rdx
    lea rdi, [rel ParserState]
    mov rcx, (ParserStateEnd - ParserState) / 8
    rep movsq
    pop rdi
    shl rdi, 6
    lea rax, [rel PreScanVarTab]
    add rdi, rax
    mov rax, [rdi + 16]
    mov [rel Here], rax
    mov rax, [rdi + 24]
    mov [rel SavedHere], rax
    mov rax, [rdi + 32]
    mov [rel FnEntry], rax
    mov r15, [rdi + 40]
    ret

HintElse:
    Fail ErrElse
HintElif:
    Fail ErrElif
HintThen:
    Fail ErrThen
HintFor:
    Fail ErrFor
HintWhile:
    Fail ErrWhile
HintFunction:
    Fail ErrFunction
HintLocal:
    Fail ErrLocal

ImplicitParamType:
    mov rax, [rel NestDepth]
    cmp rax, [rel NestFloor]
    jne .Number
    cmp qword [rel OpMode], 0
    jne .Number
    cmp qword [rel ImplicitScanned], 0
    jne .Pick
    mov qword [rel ImplicitScanned], 1
    mov qword [rel ImplicitUsed], 0
    mov qword [rel ImplicitNext], 25
    mov rcx, [rel DoStart]
.Scan:
    movzx eax, byte [rcx]
    cmp al, 10
    je .Pick
    test al, al
    je .Pick
    sub eax, 'A'
    cmp eax, 25
    ja .ScanNext
    movzx edx, byte [rcx - 1]
    call .WordChar
    jnz .ScanNext
    movzx edx, byte [rcx + 1]
    call .WordChar
    jnz .ScanNext
    bts qword [rel ImplicitUsed], rax
.ScanNext:
    inc rcx
    jmp .Scan
.Pick:
    mov rax, [rel ImplicitNext]
.Try:
    test rax, rax
    js .Number
    bt qword [rel ImplicitUsed], rax
    jnc .Got
    dec rax
    jmp .Try
.Got:
    bts qword [rel ImplicitUsed], rax
    lea rcx, [rax - 1]
    mov [rel ImplicitNext], rcx
    cmp qword [rel InstanceMode], 0
    jne .Bound
    cmp qword [rel NestInInstance], 0
    je .Unbound
    cmp qword [rel ForwardMode], 0
    je .Bound
.Unbound:
    cmp qword [rel AllowTypeVars], 0
    je .Number
    mov qword [rel GenericFound], 1
    mov ecx, eax
    jmp VarTypeOf
.Bound:
    lea rcx, [rel InstanceBindings]
    mov rax, [rcx + rax * 8]
    test rax, rax
    jz .Number
    ret
.Number:
    mov eax, TNum
    ret
.WordChar:
    cmp dl, '_'
    je .IsWord
    cmp dl, '0'
    jb .NotWord
    cmp dl, '9'
    jbe .IsWord
    or dl, 32
    cmp dl, 'a'
    jb .NotWord
    cmp dl, 'z'
    jbe .IsWord
.NotWord:
    cmp dl, dl
    ret
.IsWord:
    test dl, dl
    ret
