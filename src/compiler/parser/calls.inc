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
    mov qword [rel HintCount], 0
    test rax, rax
    jz .Done
    push rax
    mov rcx, rax
    call TypeKind
    pop rcx
    cmp rax, KFunc
    jne .Done
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
    mov rax, [r8 + 2096]
    test rax, rax
    jz .Got
    mov r8, rax
    jmp .Find
.Got:
    lea rsi, [r8]
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
    mov rax, [r8 + 2048]
    mov [rel LocalCount], rax
    mov rax, [r8 + 2056]
    mov [rel InFn], rax
    mov rax, [r8 + 2064]
    mov [rel FnSig], rax
    mov rax, [r8 + 2072]
    mov [rel FnFrameSlot], rax
    cmp qword [r8 + 2128], 0
    jne .Cleared
    mov rax, [r8 + 2136]
    mov [rel Here], rax
.Cleared:
    mov qword [rel OuterFrame], 0
.Done:
    ret

CaptureFind:
    cmp qword [r12 + 2056], 0
    je .None
    mov r9, [r12 + 2048]
.Search:
    test r9, r9
    jz .Up
    dec r9
    mov rdx, [rel TokLen]
    cmp rdx, [r12 + 512 + r9 * 8]
    jne .Search
    mov r10, [r12 + r9 * 8]
    mov r11, [rel TokPtr]
    xor ecx, ecx
.Cmp:
    cmp rcx, rdx
    je .Found
    mov al, [r10 + rcx]
    cmp al, [r11 + rcx]
    jne .Search
    inc rcx
    jmp .Cmp
.Found:
    mov rax, r9
    ret
.Up:
    mov r13, [r12 + 2096]
    test r13, r13
    jz .None
    push r12
    mov r12, r13
    call CaptureFind
    mov r13, r12
    pop r12
    cmp rax, -1
    je .None
    mov r9, [r12 + 2048]
    cmp r9, MaxLocals
    jae .Many
    cmp qword [r13 + 2144], 16
    jae .Many
    mov rcx, [rel TokPtr]
    mov [r12 + r9 * 8], rcx
    mov rcx, [rel TokLen]
    mov [r12 + 512 + r9 * 8], rcx
    mov rcx, [r13 + 1024 + rax * 8]
    mov [r12 + 1024 + r9 * 8], rcx
    mov rcx, [r13 + 1536 + rax * 8]
    mov [r12 + 1536 + r9 * 8], rcx
    inc qword [r12 + 2048]
    mov rcx, [r13 + 2144]
    mov [r13 + 2152 + rcx * 8], rax
    mov [r13 + 2280 + rcx * 8], r9
    inc qword [r13 + 2144]
    mov rax, r9
    ret
.None:
    mov rax, -1
    ret
.Many:
    Fail ErrCaptureMany

CaptureName:
    mov r8, [rel OuterFrame]
    test r8, r8
    jz .No
    push r12
    push r13
    mov r12, r8
    call CaptureFind
    mov r13, r12
    pop r13
    pop r12
    cmp rax, -1
    je .No
    mov r8, [rel OuterFrame]
    cmp qword [r8 + 2144], 16
    jae CaptureFind.Many
    push rax
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call AddLocal
    pop rcx
    mov r8, [rel OuterFrame]
    mov r9, [r8 + 1024 + rcx * 8]
    mov r10, rax
    shr r10, 3
    lea r11, [rel LocalType]
    mov [r11 + r10 * 8], r9
    mov r9, [r8 + 1536 + rcx * 8]
    lea r11, [rel LocalConst]
    mov [r11 + r10 * 8], r9
    mov rdx, [r8 + 2144]
    mov [r8 + 2152 + rdx * 8], rcx
    mov [r8 + 2280 + rdx * 8], r10
    inc qword [r8 + 2144]
    ret
.No:
    xor eax, eax
    ret

OuterLocal:
    mov r8, [rel OuterFrame]
    test r8, r8
    jz .No
    cmp qword [r8 + 2056], 0
    je .No
    mov r9, [r8 + 2048]
    mov rdx, [rel TokLen]
    mov r11, [rel TokPtr]
.Loop:
    test r9, r9
    jz .No
    dec r9
    cmp rdx, [r8 + 512 + r9 * 8]
    jne .Loop
    mov r10, [r8 + r9 * 8]
    xor ecx, ecx
.Cmp:
    cmp rcx, rdx
    je .Yes
    mov al, [r10 + rcx]
    cmp al, [r11 + rcx]
    jne .Loop
    inc rcx
    jmp .Cmp
.Yes:
    mov eax, 1
    ret
.No:
    xor eax, eax
    ret

ParseLambda:
    push rsi
    push rdi
    push rbx
    sub rsp, LFrame
    mov qword [rsp + 2144], 0
    lea rsi, [rel LocalPtr]
    lea rdi, [rsp]
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
    mov rax, [rel LocalCount]
    mov [rsp + 2048], rax
    mov rax, [rel InFn]
    mov [rsp + 2056], rax
    mov rax, [rel FnSig]
    mov [rsp + 2064], rax
    mov rax, [rel FnFrameSlot]
    mov [rsp + 2072], rax
    mov rax, [rel CurHintCount]
    mov [rsp + 2080], rax
    mov rax, [rel CurHintPtr]
    mov [rsp + 2088], rax
    mov qword [rel HintCount], 0
    mov qword [rel CurHintCount], 0
    mov rax, [rel OuterFrame]
    mov [rsp + 2096], rax
    mov [rel OuterFrame], rsp
    cmp qword [rel InFn], 0
    jne .Inline
    mov rax, [rel Here]
    mov [rsp + 2040 + 96], rax
    mov qword [rsp + 2032 + 96], 0
    mov rax, [rel DictHere]
    mov [rel Here], rax
    jmp .Placed
.Inline:
    lea rcx, [rel PrimBranch]
    call EmitJump
    mov [rsp + 2032 + 96], rax
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
    mov rax, [rel LocalCount]
    mov r8, [rel FnSig]
    mov [r8 - 16], rax
    mov [rsp + 2408], rax
    lea rcx, [rel PrimBranch]
    call EmitJump
    mov [rsp + 2112], rax
    mov rax, [rel Here]
    mov [rsp + 2120], rax
    call Advance
    call ParseExpr
    mov rax, [rel ExprType]
    test rax, rax
    jz TypeError
    mov r8, [rel FnSig]
    mov [r8 - 8], rax
    CompilePrim PrimReturn
    mov rax, [rsp + 2112]
    mov rdx, [rel Here]
    mov [rax], rdx
    mov rbx, [rsp + 2144]
.CapSets:
    test rbx, rbx
    jz .ParamSets
    dec rbx
    CompilePrim PrimLocalSet
    mov rcx, [rsp + 2280 + rbx * 8]
    shl rcx, 3
    call Compile
    jmp .CapSets
.ParamSets:
    mov rbx, [rsp + 2408]
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
    mov rcx, [rsp + 2120]
    call Compile
    mov rax, [rel FnFrameSlot]
    mov rcx, [rel LocalCount]
    mov [rax], rcx
    mov rax, [rsp + 2032 + 96]
    test rax, rax
    jz .FromDict
    mov rdx, [rel Here]
    mov [rax], rdx
    jmp .Restore
.FromDict:
    mov rax, [rel Here]
    mov [rel DictHere], rax
    mov rax, [rsp + 2040 + 96]
    mov [rel Here], rax
.Restore:
    mov rbx, [rel FnSig]
    lea rsi, [rsp]
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
    mov rax, [rsp + 2048]
    mov [rel LocalCount], rax
    mov rax, [rsp + 2056]
    mov [rel InFn], rax
    mov rax, [rsp + 2064]
    mov [rel FnSig], rax
    mov rax, [rsp + 2072]
    mov [rel FnFrameSlot], rax
    mov rax, [rsp + 2096]
    mov [rel OuterFrame], rax
    mov [rsp + 2104], rbx
    xor ebx, ebx
.CapLoads:
    cmp rbx, [rsp + 2144]
    jae .CapsLoaded
    mov rcx, [rsp + 2152 + rbx * 8]
    shl rcx, 3
    or rcx, 2
    call EmitLoad
    inc rbx
    jmp .CapLoads
.CapsLoaded:
    mov rbx, [rsp + 2104]
    CompilePrim PrimLit
    mov rcx, rbx
    call Compile
    cmp qword [rsp + 2144], 0
    je .Plain
    CompileNum [rsp + 2144]
    CompilePrim PrimMakeClosure
.Plain:
    mov rcx, rbx
    call FuncTypeOfSig
    mov [rel ExprType], rax
    add rsp, LFrame
    pop rbx
    pop rdi
    pop rsi
    ret
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
    cmp rbx, [rsp + 8 + 2080]
    jae .SetParam
    mov rax, [rsp + 8 + 2088]
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
