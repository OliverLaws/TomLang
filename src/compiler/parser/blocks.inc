IfWord:
    call Advance
    call ParseExpr
    call NeedCondition
    lea rcx, [rel PrimBranch0]
    call EmitJump
    DPush 0
    DPush rax
    DPush 0
    DPush 0
    DPush TagIf
    inc qword [rel OpenBlocks]
    jmp Pushback

OtherwiseWord:
    cmp qword [rel OpenBlocks], 0
    je .Bad
    cmp qword [r15 - 8], TagIf
    je .IfOk
    cmp qword [r15 - 8], TagCheck
    je .CheckOtherwise
    cmp qword [r15 - 8], TagTry
    je .TryOtherwise
    cmp qword [r15 - 8], TagDummy
    jne .Bad
.IfOk:
    lea rcx, [rel PrimBranch]
    call EmitJump
    lea r8, [r15 - 40]
    mov rdx, [r8]
    mov [rax], rdx
    mov [r8], rax
    mov rcx, [r8 + 8]
    test rcx, rcx
    jz .NoPending
    mov rdx, [rel Here]
    mov [rcx], rdx
    mov qword [r8 + 8], 0
.NoPending:
    call Advance
    IfTok "if", .ElseIf
    IfTok ":", .Colon
    jmp Pushback
.ElseIf:
    call SameLine
    test eax, eax
    jz Pushback
    call Advance
    call ParseExpr
    call NeedCondition
    lea rcx, [rel PrimBranch0]
    call EmitJump
    mov [r15 - 32], rax
    jmp Pushback
.TryOtherwise:
    cmp qword [r15 - 32], 0
    jne .Bad
    CompilePrim PrimTryEnd
    lea rcx, [rel PrimBranch]
    call EmitJump
    mov [r15 - 32], rax
    mov rcx, [r15 - 40]
    mov rdx, [rel Here]
    mov [rcx], rdx
    ret
.CheckOtherwise:
    mov rax, [r15 - 32]
    test rax, rax
    jz .Bad
    lea rcx, [rel PrimBranch]
    call EmitJump
    mov rdx, [r15 - 40]
    mov [rax], rdx
    mov [r15 - 40], rax
    mov rcx, [r15 - 32]
    mov rdx, [rel Here]
    mov [rcx], rdx
    mov qword [r15 - 32], 0
    ret
.Colon:
    Fail ErrColon
.Bad:
    Fail ErrOther

EndWord:
    cmp qword [rel OpenBlocks], 0
    je .Bad
    mov rax, [r15 - 8]
    cmp rax, TagIf
    je .If
    cmp rax, TagLoop
    je .Loop
    cmp rax, TagCheck
    je .Check
    cmp rax, TagTry
    je .Try
    cmp rax, TagDummy
    jne .Fn
    cmp qword [r15 - 16], 0
    je .Pop
    call DropFn
    jmp .Pop
.Try:
    mov rcx, [r15 - 32]
    test rcx, rcx
    jnz .TryHandled
    CompilePrim PrimTryEnd
    mov rcx, [r15 - 40]
    mov rdx, [rel Here]
    mov [rcx], rdx
    jmp .Pop
.TryHandled:
    mov rdx, [rel Here]
    mov [rcx], rdx
    jmp .Pop
.Check:
.If:
    mov rcx, [r15 - 32]
    test rcx, rcx
    jz .NoPending
    mov rdx, [rel Here]
    mov [rcx], rdx
.NoPending:
    mov rcx, [r15 - 40]
    mov rdx, [rel Here]
    call PatchChain
    jmp .Pop
.Loop:
    mov rcx, [r15 - 16]
    mov rdx, [rel Here]
    call PatchChain
    mov rbx, [r15 - 24]
    test rbx, rbx
    jz .NoCounter
    lea rax, [rel PrimSub]
    test rbx, 1
    jz .Count
    lea rax, [rel PrimAdd]
    and rbx, -2
.Count:
    push rax
    mov rcx, rbx
    call EmitLoad
    CompileNum 1
    pop rcx
    call Compile
    mov rcx, rbx
    call EmitStore
.NoCounter:
    CompilePrim PrimBranch
    mov rcx, [r15 - 40]
    call Compile
    mov rcx, [r15 - 32]
    mov rdx, [rel Here]
    call PatchChain
    jmp .Pop
.Fn:
    call EmitLaters
    mov qword [rel LaterCount], 0
    mov r8, [rel FnSig]
    mov rax, [r8 - 8]
    cmp rax, TDec
    ja .NoReturn
    cmp rax, TText
    je .NoReturn
    CompileNum 0
    CompilePrim PrimReturn
    jmp .FnFinish
.NoReturn:
    CompilePrim PrimNoReturn
.FnFinish:
    mov rax, [rel FnFrameSlot]
    mov rcx, [rel LocalCount]
    mov [rax], rcx
    call EndDef
    mov qword [rel InFn], 0
    mov qword [rel LocalCount], 0
.Pop:
    sub r15, 40
    dec qword [rel OpenBlocks]
    ret
.Bad:
    Fail ErrEnd

RepeatWord:
    call Advance
    IfTok "forever", .Forever
    IfTok "while", .While
    IfTok "until", .Until
    IfTok "each", .Each
    call NewHidden
    push rax
    call ParseExpr
    NeedType TNum
    IfTok "times", .Times
    Fail ErrTimes
.Times:
    pop rbx
    mov rcx, rbx
    call EmitStore
    mov rax, [rel Here]
    push rax
    mov rcx, rbx
    call EmitLoad
    CompileNum 0
    CompilePrim PrimGreater
    lea rcx, [rel PrimBranch0]
    call EmitJump
    pop rdx
    DPush rdx
    DPush rax
    DPush rbx
    DPush 0
    DPush TagLoop
    inc qword [rel OpenBlocks]
    ret
.Forever:
    mov rax, [rel Here]
    DPush rax
    DPush 0
    DPush 0
    DPush 0
    DPush TagLoop
    inc qword [rel OpenBlocks]
    ret
.While:
    call Advance
    mov rax, [rel Here]
    push rax
    call ParseExpr
    call NeedCondition
    jmp .Cond
.Until:
    call Advance
    mov rax, [rel Here]
    push rax
    call ParseExpr
    call NeedCondition
    CompileNum 0
    CompilePrim PrimEq
.Cond:
    lea rcx, [rel PrimBranch0]
    call EmitJump
    pop rdx
    DPush rdx
    DPush rax
    DPush 0
    DPush 0
    DPush TagLoop
    inc qword [rel OpenBlocks]
    jmp Pushback
.Each:
    call Advance
    cmp qword [rel TokLen], 0
    je .BadEach
    call IsNameStart
    test eax, eax
    jz .BadEach
    push qword [rel TokPtr]
    push qword [rel TokLen]
    call Advance
    Expect "in", ErrEach
    call Advance
    call ParseBits
    IfTok "..", .EachRange
    mov rax, [rel ExprType]
    call KindOfType
    cmp rax, KList
    je .EachList
    cmp rax, KMap
    jne TypeError
    CompilePrim PrimMapKeys
    mov ecx, TText
    call ListOf
    mov [rel ExprType], rax
.EachList:
    mov rcx, [rel ExprType]
    call ElemOf
    push rax
    call NewHidden
    push rax
    mov rcx, rax
    call EmitStore
    call NewHidden
    push rax
    CompileNum 0
    mov rcx, [rsp]
    call EmitStore
    mov rcx, [rsp + 32]
    mov rdx, [rsp + 24]
    call ResolveLoopVar
    push rax
    mov rcx, rax
    call TypeOf
    mov rdx, [rsp + 24]
    test rax, rax
    jz .EachSetType
    test rdx, rdx
    jz .EachTyped
    cmp rax, rdx
    jne TypeError
    jmp .EachTyped
.EachSetType:
    mov rcx, [rsp]
    call SetTypeOf
.EachTyped:
    mov rax, [rel Here]
    push rax
    mov rcx, [rsp + 16]
    call EmitLoad
    mov rcx, [rsp + 24]
    call EmitLoad
    CompilePrim PrimLength
    CompilePrim PrimLess
    lea rcx, [rel PrimBranch0]
    call EmitJump
    push rax
    mov rcx, [rsp + 32]
    call EmitLoad
    mov rcx, [rsp + 24]
    call EmitLoad
    CompileNum 1
    CompilePrim PrimAdd
    CompilePrim PrimIndex
    mov rcx, [rsp + 16]
    call EmitStore
    pop rax
    pop rdx
    pop rcx
    pop rbx
    add rsp, 32
    or rbx, 1
    DPush rdx
    DPush rax
    DPush rbx
    DPush 0
    DPush TagLoop
    inc qword [rel OpenBlocks]
    jmp Pushback
.EachRange:
    NeedType TNum
    call Advance
    call ParseBits
    NeedType TNum
    call NewHidden
    push rax
    mov rcx, rax
    call EmitStore
    mov rcx, [rsp + 16]
    mov rdx, [rsp + 8]
    call ResolveLoopVar
    push rax
    mov rcx, rax
    call TypeOf
    test rax, rax
    jz .RangeSetType
    cmp rax, TNum
    jne TypeError
    jmp .RangeTyped
.RangeSetType:
    mov rcx, [rsp]
    mov edx, TNum
    call SetTypeOf
.RangeTyped:
    mov rcx, [rsp]
    call EmitStore
    mov rax, [rel Here]
    push rax
    mov rcx, [rsp + 8]
    call EmitLoad
    mov rcx, [rsp + 16]
    call EmitLoad
    CompilePrim PrimLessEq
    lea rcx, [rel PrimBranch0]
    call EmitJump
    pop rdx
    pop rbx
    add rsp, 24
    or rbx, 1
    DPush rdx
    DPush rax
    DPush rbx
    DPush 0
    DPush TagLoop
    inc qword [rel OpenBlocks]
    jmp Pushback
.BadEach:
    Fail ErrEach

FindLoopFrame:
    mov rcx, [rel OpenBlocks]
    mov rax, r15
.Loop:
    test rcx, rcx
    jz .None
    cmp qword [rax - 8], TagLoop
    je .Found
    cmp qword [rax - 8], TagFn
    je .None
    sub rax, 40
    dec rcx
    jmp .Loop
.Found:
    sub rax, 40
    ret
.None:
    Fail ErrLoop

EndTries:
    mov r8, [rel OpenBlocks]
    mov r9, r15
    xor r10d, r10d
.Loop:
    test r8, r8
    jz .Emit
    mov rax, [r9 - 8]
    cmp rax, rcx
    je .Emit
    cmp rax, TagFn
    je .Emit
    cmp rax, TagTry
    jne .Next
    cmp qword [r9 - 32], 0
    jne .Next
    inc r10
.Next:
    sub r9, 40
    dec r8
    jmp .Loop
.Emit:
    test r10, r10
    jz .Done
    push r10
    CompilePrim PrimTryEnd
    pop r10
    dec r10
    jmp .Emit
.Done:
    ret

StopWord:
    mov ecx, TagLoop
    call EndTries
    call FindLoopFrame
    mov r11, rax
    lea rcx, [rel PrimBranch]
    call EmitJump
    mov rdx, [r11 + 8]
    mov [rax], rdx
    mov [r11 + 8], rax
    ret

SkipWord:
    mov ecx, TagLoop
    call EndTries
    call FindLoopFrame
    mov r11, rax
    lea rcx, [rel PrimBranch]
    call EmitJump
    mov rdx, [r11 + 24]
    mov [rax], rdx
    mov [r11 + 24], rax
    ret
