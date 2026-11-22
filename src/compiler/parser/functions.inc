ReturnWord:
    cmp qword [rel InFn], 0
    je .Bad
    call Advance
    call ParseExpr
    IfTok ",", .Tuple
    jmp .Typed
.Tuple:
    call ParseTuple
.Typed:
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
    CompilePrim PrimReturn
    jmp Pushback
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
    call Advance
    cmp qword [rel TokLen], 0
    je .Bad
    call IsNameStart
    test eax, eax
    jz .Bad
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    cmp qword [rel InstanceMode], 0
    je .Named
    xor edx, edx
.Named:
    call BeginDef
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
    cmp qword [rel NestDepth], 0
    jne .NoPatch
    call PatchForward
.NoPatch:
    call InstanceStarted
    mov qword [rel InFn], 1
    mov qword [rel LocalCount], 0
    mov qword [rel LaterCount], 0
    CompilePrim PrimEnter
    mov rax, [rel Here]
    mov [rel FnFrameSlot], rax
    xor ecx, ecx
    call Compile
    call Advance
    Expect "(", ErrParen
    call Advance
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
    IfTok ",", .NextParam
    IfTok ")", .ParamsDone
.BadParen:
    Fail ErrParen
.NextParam:
    call Advance
    jmp .ParamLoop
.ParamsDone:
    mov rax, [rel LocalCount]
    mov r8, [rel FnSig]
    mov [r8 - 16], rax
    call Advance
    IfTok ":", .ReturnType
    call Pushback
    jmp .Prologue
.ReturnType:
    call Advance
    call ParseTypeName
    mov r8, [rel FnSig]
    mov [r8 - 8], rax
.Prologue:
    mov qword [rel AllowTypeVars], 0
    cmp qword [rel ForwardMode], 0
    jne ForwardFinish
    cmp qword [rel NestDepth], 0
    je .NotNested
    cmp qword [rel GenericFound], 0
    jne .NestGeneric
    lea rcx, [rel LinkName]
    mov edx, 6
    call AddLocal
    and rax, -8
    mov [rel NestLinkOff], rax
    mov r8, [rel FnSig]
    or qword [r8 - SigFlags], 4
    mov rax, [rel FnEntry]
    mov [rel NestEntry], rax
    mov qword [rel NestHeaderDone], 1
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
    DPush 0
    DPush 0
    DPush 0
    DPush 0
    DPush TagFn
    inc qword [rel OpenBlocks]
    ret
.TooMany:
    Fail ErrTooMany
.NestGeneric:
    Fail ErrNestGeneric
.MaybeNested:
    cmp qword [rel ForwardMode], 0
    jne .Bad
    cmp qword [rel FileMode], 0
    je .Bad
    cmp qword [rel OuterFrame], 0
    jne .Bad
    cmp qword [rel NestDepth], 0
    jne .NestDeep
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
    lea rsi, [rel ParserState]
    lea rdi, [rel NestSave]
    mov rcx, (ParserStateEnd - ParserState) / 8
    rep movsq
    mov rax, [rel Here]
    mov [rel NestVars], rax
    mov rax, [rel SavedHere]
    mov [rel NestVars + 8], rax
    mov rax, [rel FnEntry]
    mov [rel NestVars + 16], rax
    mov ecx, NestRegion
    call EnterInstanceSpace
    mov rax, [rel InstanceMode]
    mov [rel NestInInstance], rax
    mov qword [rel NestDepth], 1
    mov qword [rel NestHeaderDone], 0
    mov qword [rel NestPending], 0
    mov qword [rel InFn], 0
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
    pop rdi
    pop rsi
    ret

NestEnd:
    mov qword [rel NestPending], 0
    cmp qword [rel NestHeaderDone], 0
    je NestAbort
    call NestAbort
    mov rax, [rel NestListCount]
    cmp rax, 64
    jae .Full
    lea rcx, [rel NestList]
    mov rdx, [rel NestEntry]
    mov [rcx + rax * 8], rdx
    inc qword [rel NestListCount]
.Full:
    ret
NestAbort:
    push rsi
    push rdi
    lea rsi, [rel NestSave]
    lea rdi, [rel ParserState]
    mov rcx, (ParserStateEnd - ParserState) / 8
    rep movsq
    mov rax, [rel NestVars]
    mov [rel Here], rax
    mov rax, [rel NestVars + 8]
    mov [rel SavedHere], rax
    mov rax, [rel NestVars + 16]
    mov [rel FnEntry], rax
    mov ecx, NestRegion
    call LeaveInstanceSpace
    mov qword [rel NestDepth], 0
    mov qword [rel NestHeaderDone], 0
    mov qword [rel NestInInstance], 0
    pop rdi
    pop rsi
    ret

EmitLink:
    cmp qword [rel OuterFrame], 0
    jne .Bad
    cmp qword [rel InFn], 0
    je .Bad
    cmp qword [rel NestDepth], 0
    je .Frame
    cmp qword [rel NestHeaderDone], 0
    je .Bad
    CompilePrim PrimLocalGet
    mov rcx, [rel NestLinkOff]
    jmp Compile
.Frame:
    CompilePrim PrimPushFrame
    ret
.Bad:
    Fail ErrNestCall

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

FindOuter:
    xor eax, eax
    cmp qword [rel NestDepth], 0
    je .None
    cmp qword [rel InFn], 0
    je .None
    cmp qword [rel OuterFrame], 0
    jne .None
    push rbx
    push rsi
    push rdi
    mov r8, rcx
    mov r9, rdx
    lea r10, [rel NestSave]
    mov r11, [r10 + (LocalCount - ParserState)]
    xor ebx, ebx
.Scan:
    cmp rbx, r11
    jae .NotFound
    mov rax, [r10 + (LocalLen - ParserState) + rbx * 8]
    cmp rax, r9
    jne .Next
    test rax, rax
    jz .Next
    mov rsi, [r10 + (LocalPtr - ParserState) + rbx * 8]
    mov rdi, r8
    mov rcx, r9
    repe cmpsb
    je .Found
.Next:
    inc rbx
    jmp .Scan
.Found:
    mov rdx, [r10 + (LocalConst - ParserState) + rbx * 8]
    lea rax, [rbx * 8 + 4]
    pop rdi
    pop rsi
    pop rbx
    ret
.NotFound:
    xor eax, eax
    pop rdi
    pop rsi
    pop rbx
.None:
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
    test rax, rax
    jz .Find
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
    lea rsi, [rel ParserState]
    lea rdi, [rel PreScanSave]
    mov rcx, (ParserStateEnd - ParserState) / 8
    rep movsq
    lea rdi, [rel PreScanVars]
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
    mov ecx, ForwardRegion
    call EnterInstanceSpace
    mov [rel PreScanRsp], rsp
    mov qword [rel PreScanActive], 1
    mov qword [rel ForwardMode], 1
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
    call DoWord
    call PreRestore
    jmp PreDeclareOut

PreScanFail:
    mov rsp, [rel PreScanRsp]
    call PreRestore
    lea rdi, [rel PreScanVars]
    mov rax, [rdi]
    mov [rel Latest], rax
PreDeclareOut:
    mov ecx, ForwardRegion
    call LeaveInstanceSpace
    mov qword [rel PreScanActive], 0
    mov qword [rel ForwardMode], 0
    pop rbp
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

PreRestore:
    lea rsi, [rel PreScanSave]
    lea rdi, [rel ParserState]
    mov rcx, (ParserStateEnd - ParserState) / 8
    rep movsq
    lea rdi, [rel PreScanVars]
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
