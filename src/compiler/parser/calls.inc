PeekColon:
    mov rcx, [rel TokPtr]
    add rcx, [rel TokLen]
.Skip:
    movzx eax, byte [rcx]
    cmp eax, ' '
    je .Next
    cmp eax, 9
    je .Next
    cmp eax, ':'
    jne .No
    mov eax, 1
    ret
.Next:
    inc rcx
    jmp .Skip
.No:
    xor eax, eax
    ret

FindParam:
    push rbx
    push rsi
    mov r10, [rcx - 16]
    xor eax, eax
.Loop:
    cmp rax, r10
    jae .None
    mov r11, rax
    shl r11, 4
    neg r11
    cmp r8, [rcx - SigName - 8 + r11]
    jne .Next
    mov rsi, [rcx - SigName + r11]
    xor r9d, r9d
.Compare:
    cmp r9, r8
    je .Found
    mov bl, [rsi + r9]
    cmp bl, [rdx + r9]
    jne .Next
    inc r9
    jmp .Compare
.Next:
    inc rax
    jmp .Loop
.None:
    mov rax, -1
.Found:
    pop rsi
    pop rbx
    ret

ParamTypeOf:
    shl rax, 3
    neg rax
    mov rax, [rdx - 24 + rax]
    ret

CheckArg:
    test rax, rax
    jz .Ok
    push rax
    call CoerceTo
    pop rax
    mov rdx, [rel ExprType]
    cmp rax, rdx
    je .Ok
    cmp rax, TDec
    jne .Compat
    cmp rdx, TNum
    jne .Bad
    CompilePrim PrimToDec
.Ok:
    ret
.Compat:
    push rax
    call Compatible
    pop rcx
    cmp rax, rcx
    je .Ok
.Bad:
    mov rax, [rel ExprType]
    cmp rax, TNil
    je TypeError
    call KindOfType
    cmp rax, KUnion
    je TypeError
    Fail ErrArgType

FuncTypeOfSig:
    sub rsp, 136
    mov rdx, [rcx - 16]
    xor eax, eax
.Copy:
    cmp rax, rdx
    jae .Done
    mov r8, rax
    shl r8, 3
    neg r8
    mov r8, [rcx - 24 + r8]
    mov [rsp + rax * 8], r8
    inc rax
    jmp .Copy
.Done:
    mov rcx, [rcx - 8]
    mov r8, rsp
    call FuncOf
    add rsp, 136
    ret

SetHint:
    mov [rel HintType], rax
    mov qword [rel HintCount], 0
    mov qword [rel HintFn], 0
    test rax, rax
    jz .Done
    push rax
    mov rcx, rax
    call TypeKind
    pop rcx
    cmp rax, KFunc
    jne .Done
    mov [rel HintFn], rcx
    shl rcx, 5
    lea rax, [rel TypeTable]
    mov rdx, [rax + rcx + 16]
    mov [rel HintCount], rdx
    mov rdx, [rax + rcx + 24]
    mov [rel HintPtr], rdx
.Done:
    ret

PeekArrow:
    mov rcx, [rel TokPtr]
    add rcx, [rel TokLen]
.Skip:
    movzx eax, byte [rcx]
    cmp eax, ' '
    je .Next
    cmp eax, 9
    je .Next
    cmp eax, '='
    jne .No
    cmp byte [rcx + 1], '>'
    jne .No
    mov eax, 1
    ret
.Next:
    inc rcx
    jmp .Skip
.No:
    xor eax, eax
    ret

ParenArrow:
    call GetInput
    mov rcx, [rel TokPtr]
    inc rcx
    mov r8d, 1
.Scan:
    cmp rcx, rdx
    jae .No
    movzx eax, byte [rcx]
    inc rcx
    cmp eax, '('
    je .Open
    cmp eax, ')'
    je .Close
    cmp eax, '"'
    je .No
    cmp eax, 10
    je .No
    jmp .Scan
.Open:
    inc r8
    jmp .Scan
.Close:
    dec r8
    jnz .Scan
.Skip:
    cmp rcx, rdx
    jae .No
    movzx eax, byte [rcx]
    cmp eax, ' '
    je .SkipNext
    cmp eax, 9
    je .SkipNext
    cmp eax, '='
    jne .No
    cmp byte [rcx + 1], '>'
    jne .No
    mov eax, 1
    ret
.SkipNext:
    inc rcx
    jmp .Skip
.No:
    xor eax, eax
    ret

UnwindLambdas:
    mov qword [rel HintCount], 0
    mov qword [rel CurHintCount], 0
    mov r8, [rel OuterFrame]
    test r8, r8
    jz .Done
.Find:
    mov rax, [r8 + LfOuter]
    test rax, rax
    jz .Got
    mov r8, rax
    jmp .Find
.Got:
    mov rcx, r8
    call LambdaRestore
    cmp qword [r8 + LfJump], 0
    jne .Cleared
    mov rax, [r8 + LfHere]
    mov [rel Here], rax
.Cleared:
    mov qword [rel OuterFrame], 0
.Done:
    ret

LambdaSave:
    push rsi
    push rdi
    mov rdi, rcx
    lea rsi, [rel LocalPtr]
    mov ecx, MaxLocals
    rep movsq
    lea rsi, [rel LocalLen]
    mov ecx, MaxLocals
    rep movsq
    lea rsi, [rel LocalType]
    mov ecx, MaxLocals
    rep movsq
    lea rsi, [rel LocalConst]
    mov ecx, MaxLocals
    rep movsq
    lea rsi, [rel LocalInit]
    mov ecx, MaxLocals
    rep movsq
    sub rdi, LfCount
    mov rax, [rel LocalCount]
    mov [rdi + LfCount], rax
    mov rax, [rel InFn]
    mov [rdi + LfInFn], rax
    mov rax, [rel FnSig]
    mov [rdi + LfSig], rax
    mov rax, [rel FnFrameSlot]
    mov [rdi + LfFrame], rax
    mov rax, [rel CurLinkOff]
    mov [rdi + LfLink], rax
    mov rax, [rel CurFnId]
    mov [rdi + LfId], rax
    mov rax, [rel CurHeap]
    mov [rdi + LfHeap], rax
    mov rax, [rel ScopeCount]
    mov [rdi + LfScopes], rax
    mov rax, [rel FnInitCell]
    mov [rdi + LfInit], rax
    pop rdi
    pop rsi
    ret

LambdaRestore:
    push rsi
    push rdi
    push rcx
    mov rsi, rcx
    lea rdi, [rel LocalPtr]
    mov ecx, MaxLocals
    rep movsq
    lea rdi, [rel LocalLen]
    mov ecx, MaxLocals
    rep movsq
    lea rdi, [rel LocalType]
    mov ecx, MaxLocals
    rep movsq
    lea rdi, [rel LocalConst]
    mov ecx, MaxLocals
    rep movsq
    lea rdi, [rel LocalInit]
    mov ecx, MaxLocals
    rep movsq
    pop rsi
    mov rax, [rsi + LfCount]
    mov [rel LocalCount], rax
    mov rax, [rsi + LfInFn]
    mov [rel InFn], rax
    mov rax, [rsi + LfSig]
    mov [rel FnSig], rax
    mov rax, [rsi + LfFrame]
    mov [rel FnFrameSlot], rax
    mov rax, [rsi + LfLink]
    mov [rel CurLinkOff], rax
    mov rax, [rsi + LfId]
    mov [rel CurFnId], rax
    mov rax, [rsi + LfHeap]
    mov [rel CurHeap], rax
    mov rax, [rsi + LfScopes]
    mov [rel ScopeCount], rax
    mov rax, [rsi + LfInit]
    mov [rel FnInitCell], rax
    pop rdi
    pop rsi
    ret

CaptureName:
    xor eax, eax
    ret

ParseLambda:
    push rsi
    push rdi
    push rbx
    sub rsp, LFrame
    mov rcx, rsp
    call LambdaSave
    mov rax, [rel CurHintCount]
    mov [rsp + LfHintCount], rax
    mov rax, [rel CurHintPtr]
    mov [rsp + LfHintPtr], rax
    mov qword [rel HintCount], 0
    mov qword [rel CurHintCount], 0
    mov rax, [rel OuterFrame]
    mov [rsp + LfOuter], rax
    mov [rel OuterFrame], rsp
    mov qword [rsp + LfParent], 0
    cmp qword [rel InFn], 0
    je .TopLevel
    mov qword [rsp + LfParent], 1
    lea rax, [rsp + LfCount]
    push rax
    lea rcx, [rsp + 8]
    lea rdx, [rsp + 8 + MaxLocals * 8]
    lea r8, [rsp + 8 + MaxLocals * 16]
    lea r9, [rsp + 8 + MaxLocals * 24]
    call ScopeAdd
    lea rcx, [rel PrimBranch]
    call EmitJump
    mov [rsp + LfJump], rax
    jmp .Placed
.TopLevel:
    mov rax, [rel Here]
    mov [rsp + LfHere], rax
    mov qword [rsp + LfJump], 0
    mov rax, [rel DictHere]
    mov [rel Here], rax
.Placed:
    mov ebx, SigCells
.Sig:
    xor ecx, ecx
    call Compile
    dec ebx
    jnz .Sig
    mov rax, [rel Here]
    mov [rel FnSig], rax
    mov qword [rel InFn], 1
    mov qword [rel LocalCount], 0
    mov qword [rel CurLinkOff], -1
    mov qword [rel CurHeap], 0
    mov qword [rel FnInitCell], 0
    call NextFnId
    mov [rel CurFnId], rax
    CompilePrim PrimEnter
    mov rax, [rel Here]
    mov [rel FnFrameSlot], rax
    xor ecx, ecx
    call Compile
    IfTok "(", .Many
    call .Param
    call Advance
    jmp .Arrow
.Many:
    call Advance
    IfTok ")", .ManyDone
.ManyLoop:
    call .Param
    call Advance
    IfTok ":", .Typed
    jmp .ManyNext
.Typed:
    call Advance
    call ParseTypeName
    mov rbx, [rel LocalCount]
    dec rbx
    call .SetParam
    call Advance
.ManyNext:
    IfTok ",", .ManyComma
    Expect ")", ErrParen
.ManyDone:
    call Advance
    jmp .Arrow
.ManyComma:
    call Advance
    jmp .ManyLoop
.Arrow:
    Expect "=>", ErrArrow
    mov rcx, [rel TokPtr]
    add rcx, 2
    call LineHasArrow
    test eax, eax
    jz .NoHeap
    mov qword [rel CurHeap], 1
    mov rax, [rel FnFrameSlot]
    lea rcx, [rel PrimEnterHeap]
    mov [rax - 8], rcx
.NoHeap:
    mov rax, [rel LocalCount]
    mov r8, [rel FnSig]
    mov [r8 - 16], rax
    cmp qword [rsp + LfParent], 0
    je .NoLink
    lea rcx, [rel LinkName]
    mov edx, 6
    call AddLocal
    and rax, -8
    mov [rel CurLinkOff], rax
.NoLink:
    mov rax, [rel LocalCount]
    mov [rsp + LfParams], rax
    lea rcx, [rel PrimBranch]
    call EmitJump
    mov [rsp + LfBranch], rax
    mov rax, [rel Here]
    mov [rsp + LfBody], rax
    call Advance
    call ParseExpr
    mov rax, [rel ExprType]
    test rax, rax
    jz TypeError
    mov r8, [rel FnSig]
    mov [r8 - 8], rax
    call EmitReturn
    mov rax, [rsp + LfBranch]
    mov rdx, [rel Here]
    mov [rax], rdx
    mov rbx, [rsp + LfParams]
.ParamLoop:
    test rbx, rbx
    jz .Jump
    dec rbx
    CompilePrim PrimLocalSet
    mov rcx, rbx
    shl rcx, 3
    call Compile
    jmp .ParamLoop
.Jump:
    CompilePrim PrimBranch
    mov rcx, [rsp + LfBody]
    call Compile
    mov rax, [rel FnFrameSlot]
    mov rcx, [rel LocalCount]
    mov [rax], rcx
    mov rax, [rsp + LfJump]
    test rax, rax
    jz .FromDict
    mov rdx, [rel Here]
    mov [rax], rdx
    jmp .Restore
.FromDict:
    mov rax, [rel Here]
    mov [rel DictHere], rax
    mov rax, [rsp + LfHere]
    mov [rel Here], rax
.Restore:
    mov rbx, [rel FnSig]
    mov rcx, rsp
    call LambdaRestore
    mov rax, [rsp + LfOuter]
    mov [rel OuterFrame], rax
    cmp qword [rsp + LfParent], 0
    je .Plain
    cmp qword [rel CurHeap], 0
    je .NeedHeap
    CompilePrim PrimPushFrame
    CompilePrim PrimLit
    mov rcx, rbx
    call Compile
    CompileNum 1
    CompilePrim PrimMakeClosure
    jmp .Typed2
.Plain:
    CompilePrim PrimLit
    mov rcx, rbx
    call Compile
.Typed2:
    mov rcx, rbx
    call FuncTypeOfSig
    mov [rel ExprType], rax
    add rsp, LFrame
    pop rbx
    pop rdi
    pop rsi
    ret
.NeedHeap:
    Fail ErrScopeFrame
.Param:
    call IsNameStart
    test eax, eax
    jz .BadParam
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call AddLocal
    mov rbx, [rel LocalCount]
    dec rbx
    cmp rbx, 16
    jae .TooMany
    mov eax, TNum
    cmp rbx, [rsp + 8 + LfHintCount]
    jae .SetParam
    mov rax, [rsp + 8 + LfHintPtr]
    mov rax, [rax + rbx * 8]
    test rax, rax
    jnz .SetParam
    mov eax, TNum
.SetParam:
    lea r8, [rel LocalType]
    mov [r8 + rbx * 8], rax
    mov r8, [rel FnSig]
    mov r9, rbx
    shl r9, 3
    neg r9
    mov [r8 - 24 + r9], rax
    ret
.BadParam:
    Fail ErrParen
.TooMany:
    Fail ErrTooMany

ListLoop:
    sub rsp, 64
    mov [rsp + 56], rcx
    mov rax, [rel ExprType]
    mov [rsp + 48], rax
    call KindOfType
    cmp rax, KList
    jne TypeError
    mov rcx, [rsp + 48]
    call ElemOf
    test rax, rax
    jz TypeError
    mov [rsp + 40], rax
    mov [rel HintOne], rax
    call NewHidden
    mov [rsp], rax
    mov rcx, rax
    call EmitStore
    call Advance
    Expect "(", ErrParen
    call Advance
    xor ecx, ecx
    cmp qword [rsp + 56], 1
    jne .AnyRet
    mov ecx, TBool
.AnyRet:
    mov edx, 1
    lea r8, [rel HintOne]
    call FuncOf
    mov [rel HintFn], rax
    mov qword [rel HintCount], 1
    lea rax, [rel HintOne]
    mov [rel HintPtr], rax
    call ParseExpr
    mov rax, [rel ExprType]
    call KindOfType
    cmp rax, KFunc
    jne .NotFunc
    mov rcx, [rel ExprType]
    shl rcx, 5
    lea rax, [rel TypeTable]
    add rax, rcx
    cmp qword [rax + 16], 1
    jne .BadFunc
    mov rdx, [rax + 24]
    mov rdx, [rdx]
    cmp rdx, [rsp + 40]
    jne .BadFunc
    mov rdx, [rax + 8]
    mov [rsp + 32], rdx
    test rdx, rdx
    jz .BadFunc
    cmp qword [rsp + 56], 1
    jne .FuncOk
    cmp rdx, TBool
    jne .BadFunc
.FuncOk:
    Expect ")", ErrParen
    call NewHidden
    mov [rsp + 8], rax
    mov rcx, rax
    call EmitStore
    CompileNum 0
    CompilePrim PrimMakeList
    call NewHidden
    mov [rsp + 16], rax
    mov rcx, rax
    call EmitStore
    CompileNum 1
    call NewHidden
    mov [rsp + 24], rax
    mov rcx, rax
    call EmitStore
    mov rax, [rsp]
    mov [rel ItemList], rax
    mov rax, [rsp + 24]
    mov [rel ItemIndex], rax
    mov rbx, [rel Here]
    mov rcx, [rsp + 24]
    call EmitLoad
    mov rcx, [rsp]
    call EmitLoad
    CompilePrim PrimLength
    CompilePrim PrimLessEq
    lea rcx, [rel PrimBranch0]
    call EmitJump
    push rax
    push rbx
    cmp qword [rsp + 16 + 56], 1
    jne .MapBody
    mov rcx, [rsp + 16 + 8]
    call EmitLoad
    call .Item
    CompilePrim PrimCallValue
    mov ecx, 1
    call Compile
    lea rcx, [rel PrimBranch0]
    call EmitJump
    push rax
    mov rcx, [rsp + 24 + 16]
    call EmitLoad
    call .Item
    CompilePrim PrimListAdd
    pop rcx
    mov rdx, [rel Here]
    mov [rcx], rdx
    jmp .Step
.MapBody:
    mov rcx, [rsp + 16 + 16]
    call EmitLoad
    mov rcx, [rsp + 16 + 8]
    call EmitLoad
    call .Item
    CompilePrim PrimCallValue
    mov ecx, 1
    call Compile
    CompilePrim PrimListAdd
.Step:
    mov rcx, [rsp + 16 + 24]
    call EmitLoad
    CompileNum 1
    CompilePrim PrimAdd
    mov rcx, [rsp + 16 + 24]
    call EmitStore
    CompilePrim PrimBranch
    pop rcx
    call Compile
    pop rcx
    mov rdx, [rel Here]
    mov [rcx], rdx
    mov rcx, [rsp + 16]
    call EmitLoad
    call Advance
    cmp qword [rsp + 56], 1
    jne .MapType
    mov rax, [rsp + 48]
    jmp .Typed
.MapType:
    mov rcx, [rsp + 32]
    call ListOf
.Typed:
    mov [rel ExprType], rax
    mov qword [rel LastVarRef], 0
    add rsp, 64
    jmp ParseAtom.Post
.Item:
    mov rcx, [rel ItemList]
    call EmitLoad
    mov rcx, [rel ItemIndex]
    call EmitLoad
    CompilePrim PrimIndex
    ret
.NotFunc:
    Fail ErrNotFunc
.BadFunc:
    Fail ErrBadFunc

ParseArg:
    call Advance
    Expect "(", ErrParen
    call Advance
    call ParseExpr
    Expect ")", ErrParen
    ret
