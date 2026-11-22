ParsePrimary:
    mov rax, [rel HintCount]
    mov [rel CurHintCount], rax
    mov rax, [rel HintPtr]
    mov [rel CurHintPtr], rax
    mov qword [rel HintCount], 0
    cmp qword [rel TokLen], 0
    je .Missing
    call TryDotted
    test rax, rax
    jnz .Dotted
    IfTok "(", .Paren
    IfTok "[", .List
    IfTok "{", .Brace
    IfTok "-", .Neg
    IfTok "true", .True
    IfTok "false", .False
    IfTok "error", .LastError
    IfTok "ask", .Ask
    IfTok "random", .Random
    IfTok "number", .ToNumber
    IfTok "decimal", .ToDecimal
    IfTok "round", .Round
    IfTok "text", .ToText
    IfTok "charCode", .Code
    IfTok "charFrom", .Char
    IfTok ".", .DotNumber
    mov rax, [rel TokPtr]
    cmp byte [rax], '"'
    je .String
    mov cl, [rax]
    cmp cl, '0'
    jb .NotNumber
    cmp cl, '9'
    ja .NotNumber
    mov rcx, rax
    mov rdx, [rel TokLen]
    xor r8d, r8d
.FindDot:
    cmp r8, rdx
    jae .Integer
    cmp byte [rcx + r8], '.'
    je .Decimal
    inc r8
    jmp .FindDot
.Decimal:
    call ParseDecimalText
    mov rbx, rax
    CompileNum rbx
    SetType TDec
    jmp Advance
.DotNumber:
    mov rax, [rel TokPtr]
    movzx ecx, byte [rax + 1]
    sub ecx, '0'
    cmp ecx, 9
    ja .Missing
    push rax
    call Advance
    pop rcx
    mov rdx, [rel TokPtr]
    add rdx, [rel TokLen]
    sub rdx, rcx
    call ParseDecimalText
    mov rbx, rax
    CompileNum rbx
    SetType TDec
    jmp Advance
.Integer:
    call ParseNumber
    test rdx, rdx
    jz .Missing
    mov rbx, rax
    CompileNum rbx
    SetType TNum
    jmp Advance
.NotNumber:
    jmp .Name
.LastError:
    CompilePrim PrimLastError
    SetType TText
    jmp Advance
.True:
    CompileNum 1
    SetType TBool
    jmp Advance
.False:
    CompileNum 0
    SetType TBool
    jmp Advance
.Dotted:
    cmp rdx, 4
    je .Func
    cmp rdx, 6
    je .Kind
    cmp rdx, 7
    je .Generic
    cmp rdx, 3
    je .Var
    cmp rdx, 5
    je .Var
    jmp .Missing
.Name:
    call PeekArrow
    test eax, eax
    jnz ParseLambda
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call LookupVar
    test rax, rax
    jnz .Var
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call FindWord
    test rax, rax
    jz .Unknown
    cmp rdx, 4
    je .Func
    cmp rdx, 6
    je .Kind
    cmp rdx, 7
    je .Generic
    jmp .Missing
.Kind:
    push rax
    call Advance
    IfTok ".", .KindValue
.KindList:
    mov rcx, [rsp]
    call FieldCount
    push rax
    xor ebx, ebx
.KindAll:
    cmp rbx, [rsp]
    jae .KindAllDone
    inc rbx
    CompileNum rbx
    jmp .KindAll
.KindAllDone:
    pop rbx
    CompileNum rbx
    CompilePrim PrimMakeList
    pop rcx
    call ListOf
    mov [rel ExprType], rax
    ret
.KindValue:
    push qword [rel TokPtr]
    call Advance
    mov rcx, [rsp + 8]
    call FindKindName
    test rax, rax
    jz .KindMember
    add rsp, 8
    push rax
    CompilePrim PrimLit
    pop rcx
    call Compile
    pop rax
    mov [rel ExprType], rax
    jmp Advance
.KindMember:
    IfTok "filter", .KindBack
    IfTok "map", .KindBack
    IfTok "length", .KindBack
    add rsp, 8
    FailTok ErrNoKindValue
.KindBack:
    pop rcx
    call Unread
    call Advance
    jmp .KindList
.Var:
    mov rbx, rax
    mov rcx, rbx
    call EmitLoad
    mov rcx, rbx
    call TypeOf
    mov [rel ExprType], rax
    mov [rel LastVarRef], rbx
    jmp Advance
.Func:
    push rax
    call Advance
    IfTok "(", .FuncCall
    mov rax, [rsp]
    test qword [rax - SigFlags], 4
    jnz .NestValue
    CompilePrim PrimLit
    mov rcx, [rsp]
    call Compile
    pop rcx
    call FuncTypeOfSig
    mov [rel ExprType], rax
    ret
.FuncCall:
    pop rax
    xor r9d, r9d
    jmp .CallSetup
.Generic:
    push rax
    call Advance
    IfTok "(", .GenericCall
    Fail ErrGenericValue
.GenericCall:
    pop rax
    mov r9d, 1
.CallSetup:
    sub rsp, 928
    mov [rsp + 912], r9
    mov [rsp + 640], rax
    xor ecx, ecx
.ClearBind:
    mov qword [rsp + 704 + rcx * 8], 0
    inc ecx
    cmp ecx, 26
    jb .ClearBind
    mov qword [rsp + 648], 0
    mov qword [rsp + 656], 0
    xor ecx, ecx
.ClearPos:
    mov qword [rsp + rcx * 8], 0
    inc ecx
    cmp ecx, 16
    jb .ClearPos
    call Advance
    mov rax, [rel Here]
    mov [rsp + 664], rax
    IfTok ")", .P1Done
.P1Loop:
    call IsNameStart
    test eax, eax
    jz .Positional
    call PeekColon
    test eax, eax
    jz .Positional
    mov rcx, [rsp + 640]
    mov rdx, [rel TokPtr]
    mov r8, [rel TokLen]
    call FindParam
    cmp rax, -1
    je .NoParam
    cmp qword [rsp + rax * 8], 0
    jne .Twice
    push rax
    call Advance
    call Advance
    pop rax
    mov rcx, [rel TokPtr]
    mov [rsp + rax * 8], rcx
    mov [rsp + 920], rax
    mov rdx, [rsp + 640]
    call ParamTypeOf
    call CallHint
    jmp .P1Parse
.Positional:
    mov rax, [rsp + 648]
    mov rdx, [rsp + 640]
    mov rcx, [rdx - 16]
    test qword [rdx - SigFlags], 1
    jz .Plain
    dec rcx
    cmp rax, rcx
    jb .Plain
    mov rax, [rsp + 656]
    cmp rax, 64
    jae .ArgCount
    mov rcx, [rel TokPtr]
    mov [rsp + 128 + rax * 8], rcx
    inc qword [rsp + 656]
    mov rax, [rsp + 648]
    bts rax, 40
    mov [rsp + 920], rax
    mov rax, [rsp + 648]
    mov rdx, [rsp + 640]
    call ParamTypeOf
    mov rcx, rax
    call ElemOf
    call CallHint
    jmp .P1Parse
.Plain:
    cmp rax, rcx
    jae .ArgCount
    cmp qword [rsp + rax * 8], 0
    jne .Twice
    mov rcx, [rel TokPtr]
    mov [rsp + rax * 8], rcx
    mov [rsp + 920], rax
    inc qword [rsp + 648]
    mov rdx, [rsp + 640]
    call ParamTypeOf
    call CallHint
.P1Parse:
    call ParseExpr
    cmp qword [rsp + 912], 0
    je .P1Typed
    call CallUnify
.P1Typed:
    IfTok ",", .P1Comma
    Expect ")", ErrParen
.P1Done:
    mov rax, [rel TokPtr]
    mov [rsp + 672], rax
    mov rax, [rsp + 664]
    mov [rel Here], rax
    mov qword [rsp + 680], 0
    cmp qword [rsp + 912], 0
    je .P2Loop
    call CallInstance
.P2Loop:
    mov rax, [rsp + 680]
    mov rdx, [rsp + 640]
    cmp rax, [rdx - 16]
    jae .P2Done
    mov rcx, [rsp + rax * 8]
    test rcx, rcx
    jnz .P2Given
    mov rcx, [rdx - 16]
    dec rcx
    cmp rax, rcx
    jne .P2Default
    test qword [rdx - SigFlags], 1
    jnz .P2Rest
.P2Default:
    mov r8, rax
    shl r8, 3
    neg r8
    mov rcx, [rdx - SigDef + r8]
    test rcx, rcx
    jz .MissingArg
    push rcx
    CompilePrim PrimCall
    pop rcx
    call Compile
    jmp .P2Next
.P2Given:
    push rcx
    call ParamTypeOf
    call SetHint
    pop rcx
    call Unread
    call Advance
    call ParseExpr
    mov rax, [rsp + 680]
    mov rdx, [rsp + 640]
    call ParamTypeOf
    call CheckArg
    jmp .P2Next
.P2Rest:
    mov qword [rsp + 688], 0
.RestLoop:
    mov rax, [rsp + 688]
    cmp rax, [rsp + 656]
    jae .RestDone
    mov rax, [rsp + 680]
    mov rdx, [rsp + 640]
    call ParamTypeOf
    mov rcx, rax
    call ElemOf
    call SetHint
    mov rax, [rsp + 688]
    mov rcx, [rsp + 128 + rax * 8]
    call Unread
    call Advance
    call ParseExpr
    mov rax, [rsp + 680]
    mov rdx, [rsp + 640]
    call ParamTypeOf
    mov rcx, rax
    call ElemOf
    call CheckArg
    inc qword [rsp + 688]
    jmp .RestLoop
.RestDone:
    CompileNum [rsp + 656]
    CompilePrim PrimMakeList
.P2Next:
    inc qword [rsp + 680]
    jmp .P2Loop
.P2Done:
    mov rcx, [rsp + 672]
    call Unread
    call Advance
    call Advance
    mov rax, [rsp + 640]
    test qword [rax - SigFlags], 4
    jz .NoLink
    call EmitLink
.NoLink:
    CompilePrim PrimCall
    mov rcx, [rsp + 640]
    call Compile
    mov rcx, [rsp + 640]
    add rsp, 928
    mov rax, [rcx - 8]
    mov qword [rel VoidCall], 0
    test qword [rcx - SigFlags], 2
    jnz .FuncLater
    test rax, rax
    jnz .FuncType
    mov qword [rel VoidCall], 1
    mov eax, TNum
.FuncType:
    mov [rel ExprType], rax
    ret
.FuncLater:
    mov qword [rel VoidCall], 2
    mov qword [rel ExprType], TNone
    ret
.P1Comma:
    call Advance
    jmp .P1Loop
.ArgCount:
    Fail ErrArgs
.Twice:
    FailTok ErrArgTwice
.NoParam:
    FailTok ErrNoParam
.MissingArg:
    mov rcx, rax
    shl rcx, 4
    neg rcx
    mov r8, [rdx - SigName + rcx]
    mov r9, [rdx - SigName - 8 + rcx]
    mov rax, [rsp + 672]
    mov [rel ErrPos], rax
    mov [rel ErrTokPtr], r8
    mov [rel ErrTokLen], r9
    lea rcx, [rel ErrMissingArg]
    mov edx, ErrMissingArgLen
    jmp Abort
.Paren:
    call ParenArrow
    test eax, eax
    jnz ParseLambda
    call Advance
    call ParseExpr
    Expect ")", ErrParen
    jmp Advance
.List:
    call Advance
    IfTok "]", .EmptyList
    push 0
    push 0
.ListLoop:
    call ParseExpr
    mov rax, [rel ExprType]
    test rax, rax
    jz TypeError
    mov rdx, [rsp]
    test rdx, rdx
    jz .FirstElem
    cmp rax, rdx
    jne TypeError
    jmp .ElemOk
.FirstElem:
    mov [rsp], rax
.ElemOk:
    inc qword [rsp + 8]
    cmp qword [rsp + 8], 4000
    ja .LongList
    IfTok ",", .ListComma
    Expect "]", ErrBracket
.ListFinish:
    call Advance
    pop rbx
    pop rsi
    CompileNum rsi
    CompilePrim PrimMakeList
    mov rcx, rbx
    call ListOf
    mov [rel ExprType], rax
    ret
.ListComma:
    call Advance
    IfTok "]", .ListFinish
    jmp .ListLoop
.EmptyList:
    CompileNum 0
    CompilePrim PrimMakeList
    xor ecx, ecx
    call ListOf
    mov [rel ExprType], rax
    jmp Advance
.Brace:
    call Advance
    IfTok "}", .EmptyMap
    mov rax, [rel TokPtr]
    cmp byte [rax], '"'
    je .MapLiteral
    jmp RecordLiteral
.EmptyMap:
    CompileNum 0
    CompilePrim PrimMakeMap
    xor ecx, ecx
    call MapOf
    mov [rel ExprType], rax
    jmp Advance
.MapLiteral:
    push 0
    push 0
.MapLoop:
    call ParseExpr
    NeedType TText
    Expect ":", ErrMapColon
    call Advance
    call ParseExpr
    mov rax, [rel ExprType]
    test rax, rax
    jz TypeError
    mov rdx, [rsp]
    test rdx, rdx
    jz .MapFirst
    cmp rax, rdx
    jne TypeError
    jmp .MapOk
.MapFirst:
    mov [rsp], rax
.MapOk:
    inc qword [rsp + 8]
    cmp qword [rsp + 8], 2000
    ja .LongList
    IfTok ",", .MapComma
    Expect "}", ErrBraceClose
.MapFinish:
    call Advance
    pop rbx
    pop rsi
    CompileNum rsi
    CompilePrim PrimMakeMap
    mov rcx, rbx
    call MapOf
    mov [rel ExprType], rax
    ret
.MapComma:
    call Advance
    IfTok "}", .MapFinish
    jmp .MapLoop
.LongList:
    Fail ErrLongList
.Neg:
    call Advance
    CompileNum 0
    call ParsePower
    mov rax, [rel ExprType]
    cmp rax, TDec
    je .NegDec
    NeedType TNum
    CompilePrim PrimSub
    ret
.NegDec:
    CompilePrim PrimDSub
    ret
.Ask:
    call Advance
    cmp qword [rel TokLen], 0
    je .AskNoPrompt
    mov rax, [rel TokPtr]
    cmp byte [rax], '"'
    je .AskPrompt
    IfTok "(", .AskPrompt
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call LookupVar
    test rax, rax
    jnz .AskPrompt
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call FindWord
    test rax, rax
    jz .AskNoPrompt
    cmp rdx, 4
    je .AskPrompt
.AskNoPrompt:
    CompileNum 0
    jmp .AskCompile
.AskPrompt:
    call ParseSum
    mov rax, [rel ExprType]
    call ToTextRaw
.AskCompile:
    CompilePrim PrimAsk
    SetType TText
    ret
.Random:
    call Advance
    Expect "(", ErrParen
    call Advance
    call ParseExpr
    NeedType TNum
    Expect ",", ErrComma
    call Advance
    call ParseExpr
    NeedType TNum
    Expect ")", ErrParen
    CompilePrim PrimRandom
    SetType TNum
    jmp Advance
.ToNumber:
    call ParseArg
    mov rax, [rel ExprType]
    cmp rax, TNum
    je .ToNumberDone
    cmp rax, TDec
    je .ToNumberDec
    NeedType TText
    CompilePrim PrimToNumber
    jmp .ToNumberDone
.ToNumberDec:
    CompilePrim PrimDecToNum
.ToNumberDone:
    SetType TNum
    jmp Advance
.ToDecimal:
    call ParseArg
    mov rax, [rel ExprType]
    cmp rax, TDec
    je .ToDecimalDone
    cmp rax, TNum
    je .ToDecimalNum
    NeedType TText
    CompilePrim PrimTextToDec
    jmp .ToDecimalDone
.ToDecimalNum:
    CompilePrim PrimToDec
.ToDecimalDone:
    SetType TDec
    jmp Advance
.Round:
    call ParseArg
    cmp qword [rel ExprType], TNum
    je .RoundDone
    NeedType TDec
    CompilePrim PrimRound
.RoundDone:
    SetType TNum
    jmp Advance
.ToText:
    call ParseArg
    mov rax, [rel ExprType]
    call ToTextRaw
    SetType TText
    jmp Advance
.Code:
    call ParseArg
    NeedType TText
    CompilePrim PrimCode
    SetType TNum
    jmp Advance
.Char:
    call ParseArg
    NeedType TNum
    CompilePrim PrimChar
    SetType TText
    jmp Advance
.String:
    mov rdx, [rel TokLen]
    cmp rdx, 2
    jb .BadString
    cmp byte [rax + rdx - 1], '"'
    jne .BadString
    lea rcx, [rax + 1]
    sub rdx, 2
    call CompileText
    jmp Advance
.BadString:
    Fail ErrString
.Missing:
    Fail ErrExpect
.NestValue:
    Fail ErrNestValue
.Unknown:
    cmp qword [rel PreScanActive], 0
    jne .NoForward
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    cmp byte [rcx + rdx], '('
    jne .NoForward
    call TryForward
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call FindWord
    test rax, rax
    jz .NoForward
    cmp rdx, 4
    je .Func
    cmp rdx, 7
    je .Generic
.NoForward:
    call CaptureName
    test rax, rax
    jnz .Var
    push qword [rel TokPtr]
    push qword [rel TokLen]
    call Advance
    IfTok "=", .WantSet
    IfTok "+=", .WantSet
    IfTok "-=", .WantSet
    IfTok ",", .WantSet
    pop qword [rel TokLen]
    pop qword [rel TokPtr]
    FailTok ErrName
.WantSet:
    pop qword [rel TokLen]
    pop qword [rel TokPtr]
    FailTok ErrNotExist
.Captured:
    FailTok ErrCapture

RecordLiteral:
    push qword [rel TempTop]
    push 0
.Loop:
    call IsNameStart
    test eax, eax
    jz .Bad
    mov rax, [rsp]
    lea rax, [rax + rax * 2]
    mov rcx, [rsp + 8]
    lea r8, [rcx + rax * 8]
    mov rax, [rel TokPtr]
    mov [r8], rax
    mov rax, [rel TokLen]
    mov [r8 + 8], rax
    push r8
    inc qword [rsp + 8]
    mov rax, [rsp + 8]
    lea rax, [rax + rax * 2]
    shl rax, 3
    add rax, [rsp + 16]
    mov [rel TempTop], rax
    call TempRoom
    call Advance
    Expect ":", ErrRecordColon
    call Advance
    call ParseExpr
    pop r8
    mov rax, [rel ExprType]
    test rax, rax
    jz TypeError
    mov [r8 + 16], rax
    IfTok ",", .Comma
    Expect "}", ErrBraceClose
.Finish:
    call Advance
    mov rcx, [rsp]
    mov rdx, [rsp + 8]
    call InternRecord
    mov rbx, rax
    CompilePrim PrimMakeRecord
    mov rcx, [rsp]
    call Compile
    xor esi, esi
.Slots:
    cmp rsi, [rsp]
    jae .Done
    lea rax, [rsi + rsi * 2]
    mov rdi, [rsp + 8]
    lea rdi, [rdi + rax * 8]
    mov rcx, rbx
    mov rdx, [rdi]
    mov r8, [rdi + 8]
    call FindField
    mov rcx, rax
    call Compile
    inc rsi
    jmp .Slots
.Done:
    mov [rel ExprType], rbx
    pop rax
    pop rax
    mov [rel TempTop], rax
    ret
.Comma:
    call Advance
    IfTok "}", .Finish
    jmp .Loop
.Bad:
    Fail ErrRecordName

EmitTextLiteral:
    call MakeText
    push rax
    CompilePrim PrimLit
    pop rcx
    jmp Compile

FindSpecColon:
    xor r9d, r9d
    xor r10d, r10d
    mov rax, rcx
.Loop:
    cmp rax, rdx
    jae .None
    mov r8b, [rax]
    cmp r8b, '"'
    jne .NotQuote
    xor r10d, 1
    jmp .Next
.NotQuote:
    test r10d, r10d
    jnz .Next
    cmp r8b, '('
    je .Open
    cmp r8b, '['
    je .Open
    cmp r8b, '{'
    je .Open
    cmp r8b, ')'
    je .Close
    cmp r8b, ']'
    je .Close
    cmp r8b, '}'
    je .Close
    cmp r8b, ':'
    jne .Next
    test r9, r9
    jz .Found
    jmp .Next
.Open:
    inc r9
    jmp .Next
.Close:
    dec r9
.Next:
    inc rax
    jmp .Loop
.None:
    mov rax, rdx
.Found:
    ret
