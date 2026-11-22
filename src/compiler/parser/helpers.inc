Advance:
    mov rax, [rel TokPtr]
    mov [rel PrevTokPtr], rax
    call NextToken
    mov [rel TokPtr], rax
    mov [rel TokLen], rdx
    ret

TryDotted:
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    test rdx, rdx
    jz .No
    lea r8, [rcx + rdx]
    cmp byte [r8], '.'
    jne .No
    lea r9, [r8 + 1]
.Scan:
    movzx eax, byte [r9]
    cmp al, '_'
    je .Ok
    cmp al, '0'
    jb .End
    cmp al, '9'
    jbe .Digit
    or al, 32
    cmp al, 'a'
    jb .End
    cmp al, 'z'
    ja .End
.Ok:
    inc r9
    jmp .Scan
.Digit:
    cmp r9, r8
    je .End
    inc r9
    jmp .Scan
.End:
    lea r10, [r8 + 1]
    cmp r9, r10
    je .No
    mov rax, r9
    sub rax, rcx
    cmp rax, 250
    ja .No
    push rsi
    push rdi
    mov rsi, rcx
    lea rdi, [rel DotBuf]
    mov rcx, rax
    push rax
    rep movsb
    pop rdx
    pop rdi
    pop rsi
    lea rcx, [rel DotBuf]
    call FindWord
    test rax, rax
    jz .No
    push rax
    push rdx
    call Advance
    call Advance
    pop rdx
    pop rax
    ret
.No:
    xor eax, eax
    ret

Pushback:
    cmp qword [rel TokLen], 0
    je .Done
    mov rcx, [rel TokPtr]
    call Unread
.Done:
    ret

IsTok:
    cmp rdx, [rel TokLen]
    jne .No
    mov r8, [rel TokPtr]
    xor r9d, r9d
.Loop:
    cmp r9, rdx
    je .Yes
    mov al, [rcx + r9]
    cmp al, [r8 + r9]
    jne .No
    inc r9
    jmp .Loop
.Yes:
    mov eax, 1
    ret
.No:
    xor eax, eax
    ret

TypeError:
    cmp qword [rel VoidCall], 2
    je LaterResult
    Fail ErrType
LaterResult:
    Fail ErrLaterResult

EmitJump:
    call Compile
    mov r10, [rel Here]
    xor ecx, ecx
    call Compile
    mov rax, r10
    ret

PatchChain:
    test rcx, rcx
    jz .Done
    mov r9, [rcx]
    mov [rcx], rdx
    mov rcx, r9
    jmp PatchChain
.Done:
    ret

ParseTypeName:
    inc qword [rel TypeDepth]
    cmp qword [rel TypeDepth], 100
    ja .TooDeepType
    call ParseTypeNameInner
    dec qword [rel TypeDepth]
    ret
.TooDeepType:
    mov qword [rel TypeDepth], 0
    Fail ErrTooDeep

ParseTypeNameInner:
    call TryDotted
    test rax, rax
    jz .Plain
    cmp rdx, 8
    je .StructType
    cmp rdx, 6
    jne .NotVar
    ret
.Plain:
    IfTok "number", .Num
    IfTok "decimal", .Dec
    IfTok "text", .Text
    IfTok "bool", .Bool
    IfTok "list", .List
    IfTok "map", .Map
    IfTok "{", .Record
    IfTok "do", .Func
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call FindWord
    test rax, rax
    jz .BadName
    cmp rdx, 8
    je .StructType
    cmp rdx, 6
    jne .BadName
    ret
.StructType:
    mov rax, [rax + 32]
    ret
.BadName:
    cmp qword [rel TokLen], 1
    jne .NotVar
    mov rax, [rel TokPtr]
    movzx eax, byte [rax]
    sub eax, 'A'
    cmp eax, 25
    ja .NotVar
    cmp qword [rel InstanceMode], 0
    jne .Bound
    cmp qword [rel NestInInstance], 0
    je .Unbound
    cmp qword [rel ForwardMode], 0
    je .Bound
.Unbound:
    cmp qword [rel AllowTypeVars], 0
    je .NotVar
    mov qword [rel GenericFound], 1
    mov ecx, eax
    jmp VarTypeOf
.Bound:
    lea rcx, [rel InstanceBindings]
    mov rax, [rcx + rax * 8]
    test rax, rax
    jz .NotVar
    ret
.NotVar:
    Fail ErrTypeName
.Num:
    mov eax, TNum
    ret
.Dec:
    mov eax, TDec
    ret
.Text:
    mov eax, TText
    ret
.Bool:
    mov eax, TBool
    ret
.List:
    call OfType
    mov rcx, rax
    jmp ListOf
.Map:
    call OfType
    mov rcx, rax
    jmp MapOf
.Func:
    sub rsp, 136
    mov qword [rsp + 128], 0
    call Advance
    Expect "(", ErrParen
    call Advance
    IfTok ")", .FuncParams
.FuncLoop:
    call ParseTypeName
    mov rcx, [rsp + 128]
    cmp rcx, 16
    jae .FuncMany
    mov [rsp + rcx * 8], rax
    inc qword [rsp + 128]
    call Advance
    IfTok ",", .FuncNext
    Expect ")", ErrParen
    jmp .FuncParams
.FuncNext:
    call Advance
    jmp .FuncLoop
.FuncParams:
    push qword [rel TokPtr]
    push qword [rel TokLen]
    call Advance
    IfTok ":", .FuncRet
    mov rcx, [rel TokPtr]
    call Unread
    pop qword [rel TokLen]
    pop qword [rel TokPtr]
    xor ecx, ecx
    jmp .FuncMake
.FuncRet:
    add rsp, 16
    call Advance
    call ParseTypeName
    mov rcx, rax
.FuncMake:
    mov rdx, [rsp + 128]
    mov r8, rsp
    call FuncOf
    add rsp, 136
    ret
.FuncMany:
    Fail ErrTooMany
.Record:
    push qword [rel TempTop]
    push 0
.RecordLoop:
    call Advance
    IfTok "}", .RecordDone
    call IsNameStart
    test eax, eax
    jz .RecordBad
    mov rax, [rsp]
    lea rax, [rax + rax * 2]
    mov rcx, [rsp + 8]
    lea r8, [rcx + rax * 8]
    mov rax, [rel TokPtr]
    mov [r8], rax
    mov rax, [rel TokLen]
    mov [r8 + 8], rax
    inc qword [rsp]
    mov rax, [rsp]
    lea rax, [rax + rax * 2]
    shl rax, 3
    add rax, [rsp + 8]
    mov [rel TempTop], rax
    call TempRoom
    push r8
    call Advance
    Expect ":", ErrTypeName
    call Advance
    call ParseTypeName
    pop r8
    mov [r8 + 16], rax
    call Advance
    IfTok ",", .RecordLoop
    Expect "}", ErrTypeName
.RecordDone:
    pop rcx
    pop rdx
    mov [rel TempTop], rdx
    jmp InternRecord
.RecordBad:
    Fail ErrTypeName

TempRoom:
    push rax
    mov rax, [rel TempTop]
    lea rcx, [rel TempFields + 3 * 1024 * 8 - 48]
    cmp rax, rcx
    pop rax
    jae .Full
    ret
.Full:
    Fail ErrTooManyFields

OfType:
    call GetInput
    push rax
    push qword [rel TokPtr]
    push qword [rel TokLen]
    call Advance
    IfTok "of", .Of
    pop qword [rel TokLen]
    pop qword [rel TokPtr]
    pop rcx
    call Unread
    xor eax, eax
    ret
.Of:
    add rsp, 24
    call Advance
    jmp ParseTypeName

Compatible:
    test rdx, rdx
    jz .No
    test rax, rax
    jz .TakeExpr
    cmp rax, rdx
    je .Same
    push rax
    push rdx
    mov rcx, rax
    call TypeKind
    mov r10, rax
    mov rcx, [rsp]
    call TypeKind
    mov r11, rax
    pop rdx
    pop rax
    cmp r10, r11
    jne .No
    cmp r10, KList
    je .Container
    cmp r10, KMap
    jne .No
.Container:
    push rax
    push rdx
    mov rcx, rax
    call ElemOf
    test rax, rax
    pop rdx
    pop rax
    jz .TakeExpr
    push rax
    push rdx
    mov rcx, rdx
    call ElemOf
    test rax, rax
    pop rdx
    pop rax
    jz .Same
.No:
    xor eax, eax
    ret
.TakeExpr:
    mov rax, rdx
    ret
.Same:
    ret

KindOfType:
    mov rcx, rax
    jmp TypeKind

ToTextRaw:
    cmp rax, TText
    je .Done
    cmp rax, TNum
    je .Num
    cmp rax, TBool
    je .Bool
    cmp rax, TDec
    je .Dec
    test rax, rax
    jz TypeError
    push rax
    CompilePrim PrimShow
    pop rcx
    jmp Compile
.Bool:
    CompilePrim PrimBoolToText
    ret
.Dec:
    CompilePrim PrimDecToText
    ret
.Num:
    CompilePrim PrimToText
.Done:
    ret

EmitSay:
    mov rax, [rel ExprType]
    cmp rax, TText
    je .Text
    cmp rax, TBool
    je .Bool
    cmp rax, TNum
    je .Num
    test rax, rax
    jz .Nothing
    call ToTextRaw
.Text:
    CompilePrim PrimSayText
    ret
.Num:
    CompilePrim PrimPrint
    ret
.Bool:
    CompilePrim PrimSayBool
    ret
.Nothing:
    cmp qword [rel VoidCall], 2
    je LaterResult
    Fail ErrNothing

IsNameStart:
    mov rax, [rel TokPtr]
    mov cl, [rax]
    cmp cl, '_'
    je .Yes
    or cl, 0x20
    cmp cl, 'a'
    jb .No
    cmp cl, 'z'
    ja .No
.Yes:
    mov eax, 1
    ret
.No:
    xor eax, eax
    ret

IsReserved:
    IfTok "true", .Yes
    IfTok "false", .Yes
    IfTok "ask", .Yes
    IfTok "random", .Yes
    IfTok "number", .Yes
    IfTok "text", .Yes
    IfTok "and", .Yes
    IfTok "or", .Yes
    IfTok "not", .Yes
    IfTok "times", .Yes
    IfTok "in", .Yes
    IfTok "decimal", .Yes
    IfTok "round", .Yes
    IfTok "charCode", .Yes
    IfTok "charFrom", .Yes
    IfTok "xor", .Yes
    IfTok "of", .Yes
    IfTok "error", .Yes
    xor eax, eax
    ret
.Yes:
    mov eax, 1
    ret

DropFn:
    mov rax, [rel FnEntry]
    test rax, rax
    jz .NoFn
    lea rcx, [rel BrokenBody]
    mov [rax + 8], rcx
    call EndDef
.NoFn:
    mov qword [rel InFn], 0
    mov qword [rel LocalCount], 0
    ret

ResetCompiler:
    call UnwindLambdas
    mov qword [rel ExprDepth], 0
    mov qword [rel TypeDepth], 0
    mov rax, [rel FnEntry]
    test rax, rax
    jz .NoFn
    lea rcx, [rel BrokenBody]
    mov [rax + 8], rcx
    call EndDef
.NoFn:
    mov qword [rel InFn], 0
    mov qword [rel OpenBlocks], 0
    mov qword [rel LocalCount], 0
    mov qword [rel MakingConst], 0
    call InitStack
    ret

FindLocal:
    xor eax, eax
    cmp qword [rel InFn], 0
    je .Done
    mov r8, [rel LocalCount]
.Loop:
    test r8, r8
    jz .None
    dec r8
    lea r9, [rel LocalLen]
    cmp rdx, [r9 + r8 * 8]
    jne .Loop
    lea r9, [rel LocalPtr]
    mov r9, [r9 + r8 * 8]
    xor r10d, r10d
.Compare:
    cmp r10, rdx
    je .Found
    mov al, [rcx + r10]
    cmp al, [r9 + r10]
    jne .Loop
    inc r10
    jmp .Compare
.Found:
    lea rax, [r8 * 8 + 2]
    ret
.None:
    xor eax, eax
.Done:
    ret

AddLocal:
    mov rax, [rel LocalCount]
    cmp rax, MaxLocals
    jae .TooMany
    push rdx
    xor eax, eax
    test rdx, rdx
    jz .Store
    call CopyString
.Store:
    pop rdx
    mov r8, [rel LocalCount]
    lea r9, [rel LocalPtr]
    mov [r9 + r8 * 8], rax
    lea r9, [rel LocalLen]
    mov [r9 + r8 * 8], rdx
    lea r9, [rel LocalType]
    mov qword [r9 + r8 * 8], 0
    lea r9, [rel LocalConst]
    mov qword [r9 + r8 * 8], 0
    xor eax, eax
    cmp qword [rel OpenBlocks], 1
    jbe .Top
    mov eax, 1
.Top:
    lea r9, [rel LocalInit]
    mov [r9 + r8 * 8], rax
    inc qword [rel LocalCount]
    lea rax, [r8 * 8 + 2]
    ret
.TooMany:
    Fail ErrTooMany

LookupVar:
    push rcx
    push rdx
    call FindLocal
    test rax, rax
    jz .Outer
    add rsp, 16
    mov rcx, rax
    shr rcx, 3
    lea r8, [rel LocalConst]
    mov rdx, [r8 + rcx * 8]
    ret
.Outer:
    mov rcx, [rsp + 8]
    mov rdx, [rsp]
    call FindOuter
    test rax, rax
    jz .Global
    add rsp, 16
    ret
.Global:
    pop rdx
    pop rcx
    call FindWord
    test rax, rax
    jz .None
    cmp rdx, 3
    je .Var
    cmp rdx, 5
    je .Const
.None:
    xor eax, eax
    xor edx, edx
    ret
.Var:
    xor edx, edx
    ret
.Const:
    mov edx, 1
    ret

NewVar:
    cmp qword [rel InFn], 0
    jne AddLocal
    cmp qword [rel OpenBlocks], 0
    je CreateVar
    call CreateVar
    mov rcx, [rel InitVarCount]
    cmp rcx, 4096
    jae .Full
    lea rdx, [rel InitVars]
    mov [rdx + rcx * 8], rax
    inc qword [rel InitVarCount]
.Full:
    ret

EmitDefault:
    cmp rax, TText
    je .Text
    push rax
    call KindOfType
    pop rcx
    cmp rax, KList
    je .List
    cmp rax, KMap
    je .Map
    xor eax, eax
    ret
.Text:
    lea rcx, [rel InitVarCount]
    xor edx, edx
    call CompileText
    mov eax, 1
    ret
.List:
    CompileNum 0
    CompilePrim PrimMakeList
    mov eax, 1
    ret
.Map:
    CompileNum 0
    CompilePrim PrimMakeMap
    mov eax, 1
    ret

EmitLocalInits:
    push rbx
    push r12
    xor ebx, ebx
    xor r12d, r12d
.Loop:
    cmp rbx, [rel LocalCount]
    jae .Done
    lea rax, [rel LocalInit]
    cmp qword [rax + rbx * 8], 0
    je .Next
    lea rax, [rel LocalType]
    mov rax, [rax + rbx * 8]
    test rax, rax
    jz .Next
    test r12, r12
    jnz .Have
    mov r12, [rel Here]
.Have:
    call EmitDefault
    test eax, eax
    jnz .Store
    cmp r12, [rel Here]
    jne .Next
    xor r12d, r12d
    jmp .Next
.Store:
    CompilePrim PrimLocalSet
    mov rcx, rbx
    shl rcx, 3
    call Compile
.Next:
    inc rbx
    jmp .Loop
.Done:
    test r12, r12
    jz .Out
    mov rax, [rel FnInitCell]
    test rax, rax
    jz .Out
    CompilePrim PrimBranch
    mov rcx, [rel FnInitCell]
    add rcx, 8
    call Compile
    mov rax, [rel FnInitCell]
    mov [rax], r12
.Out:
    pop r12
    pop rbx
    ret

EmitGlobalInits:
    push rbx
    xor ebx, ebx
.Loop:
    cmp rbx, [rel InitVarCount]
    jae .Done
    lea rax, [rel InitVars]
    mov rcx, [rax + rbx * 8]
    push rcx
    push rcx
    call TypeOf
    test rax, rax
    jz .Skip
    call EmitDefault
    test eax, eax
    jz .Skip
    mov rcx, [rsp]
    call EmitStore
.Skip:
    add rsp, 16
    inc rbx
    jmp .Loop
.Done:
    pop rbx
    ret

NewHidden:
    cmp qword [rel InFn], 0
    je AllocSlot
    xor ecx, ecx
    xor edx, edx
    jmp AddLocal

MarkConst:
    test rax, 2
    jnz .Local
    mov r8, [rel Latest]
    mov byte [r8 + 16], 5
    ret
.Local:
    mov r8, rax
    shr r8, 3
    lea r9, [rel LocalConst]
    mov qword [r9 + r8 * 8], 1
    ret

TypeOf:
    test rcx, 2
    jnz .Local
    test rcx, 4
    jnz .Outer
    mov rax, [rcx - 8]
    ret
.Outer:
    shr rcx, 3
    lea rax, [rel NestSave]
    mov rax, [rax + (LocalType - ParserState) + rcx * 8]
    ret
.Local:
    shr rcx, 3
    lea rax, [rel LocalType]
    mov rax, [rax + rcx * 8]
    ret

SetTypeOf:
    test rcx, 2
    jnz .Local
    test rcx, 4
    jnz .Outer
    mov [rcx - 8], rdx
    ret
.Outer:
    shr rcx, 3
    lea rax, [rel NestSave]
    mov [rax + (LocalType - ParserState) + rcx * 8], rdx
    ret
.Local:
    shr rcx, 3
    lea rax, [rel LocalType]
    mov [rax + rcx * 8], rdx
    ret

EmitLoad:
    push rcx
    test rcx, 2
    jnz .Local
    test rcx, 4
    jnz .Outer
    CompilePrim PrimLit
    pop rcx
    call Compile
    CompilePrim PrimFetch
    ret
.Local:
    CompilePrim PrimLocalGet
    pop rcx
    and rcx, -8
    jmp Compile
.Outer:
    CompilePrim PrimLinkGet
    mov rcx, [rel NestLinkOff]
    call Compile
    pop rcx
    and rcx, -8
    jmp Compile

EmitStore:
    push rcx
    test rcx, 2
    jnz .Local
    test rcx, 4
    jnz .Outer
    CompilePrim PrimLit
    pop rcx
    call Compile
    CompilePrim PrimStore
    ret
.Local:
    CompilePrim PrimLocalSet
    pop rcx
    and rcx, -8
    jmp Compile
.Outer:
    CompilePrim PrimLinkSet
    mov rcx, [rel NestLinkOff]
    call Compile
    pop rcx
    and rcx, -8
    jmp Compile

NeedCondition:
    IfTok ":", .Colon
    IfTok "then", .Then
    cmp qword [rel ExprType], TBool
    jne .NotBool
    ret
.Colon:
    Fail ErrColon
.Then:
    Fail ErrThen
.NotBool:
    Fail ErrCond

CheckLogic:
    cmp rax, TBool
    jne .Bad
    cmp qword [rel ExprType], TBool
    jne .Bad
    ret
.Bad:
    Fail ErrLogic

NumericPair:
    mov rdx, [rel ExprType]
    cmp rax, TNum
    jne .Check
    cmp rdx, TNum
    jne .Check
    mov eax, TNum
    ret
.Check:
    cmp rax, TNum
    je .LeftOk
    cmp rax, TDec
    jne TypeError
.LeftOk:
    cmp rdx, TNum
    je .RightOk
    cmp rdx, TDec
    jne TypeError
.RightOk:
    cmp rdx, TNum
    jne .RightDec
    push rax
    CompilePrim PrimToDec
    pop rax
.RightDec:
    cmp rax, TNum
    jne .Done
    CompilePrim PrimToDecUnder
.Done:
    mov eax, TDec
    ret
