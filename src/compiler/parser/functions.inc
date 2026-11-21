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
    jne .Bad
    cmp qword [rel OpenBlocks], 0
    jne .Bad
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
    DPush 0
    DPush 0
    DPush 0
    DPush 0
    DPush TagFn
    inc qword [rel OpenBlocks]
    ret
.TooMany:
    Fail ErrTooMany
.RestNotLast:
    Fail ErrRestLast
.RestDefault:
    Fail ErrRestDefault
.Bad:
    Fail ErrDo

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
