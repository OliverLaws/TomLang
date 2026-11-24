ParsePrimary:
    mov rax, [rel HintCount]
    mov [rel CurHintCount], rax
    mov rax, [rel HintPtr]
    mov [rel CurHintPtr], rax
    mov rax, [rel HintFn]
    mov [rel CurHintFn], rax
    mov qword [rel HintFn], 0
    mov rax, [rel HintType]
    mov [rel CurHintType], rax
    mov qword [rel HintType], 0
    mov qword [rel HintCount], 0
    cmp qword [rel TokLen], 0
    je .Missing
    call PickHint
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
    IfTok "nothing", .Nothing
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
    cmp rdx, 2
    jb .FindDot
    movzx eax, byte [rcx + 1]
    or eax, 32
    cmp eax, 'x'
    je .Integer
    cmp eax, 'b'
    je .Integer
.FindDot:
    cmp r8, rdx
    jae .Integer
    cmp byte [rcx + r8], '.'
    je .Decimal
    movzx eax, byte [rcx + r8]
    or eax, 32
    cmp eax, 'e'
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
.Nothing:
    CompileNum 0
    SetType TNil
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
    cmp rdx, 8
    je ConstructRecord
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
    cmp rdx, 8
    je ConstructRecord
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
    mov rcx, rax
    call TypeKind
    cmp rax, KFunc
    jne Advance
    mov rcx, rbx
    call FindVarSig
    test rax, rax
    jz Advance
    push rax
    call Advance
    IfTok "(", .SigValueCall
    add rsp, 8
    ret
.SigValueCall:
    pop rax
    mov qword [rel LastVarRef], 0
    mov r9d, 2
    jmp .CallSetup
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
    mov [rel LastFnValSig], rcx
    mov rax, [rel Here]
    mov [rel LastFnValHere], rax
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
    pop rcx
    call GenericValue
    ret
.GenericCall:
    pop rax
    mov r9d, 1
.CallSetup:
    sub rsp, 960
    mov [rsp + 928], r9
    mov [rsp + 640], rax
    xor ecx, ecx
.ClearBind:
    mov qword [rsp + 704 + rcx * 8], 0
    inc ecx
    cmp ecx, 27
    jb .ClearBind
    mov qword [rsp + 648], 0
    mov qword [rsp + 656], 0
    xor ecx, ecx
.ClearPos:
    mov qword [rsp + rcx * 8], 0
    inc ecx
    cmp ecx, 16
    jb .ClearPos
    mov rax, [rel RecvType]
    mov [rsp + 944], rax
    mov rcx, [rel RecvBare]
    mov [rsp + 952], rcx
    mov qword [rel RecvType], 0
    mov qword [rel RecvBare], 0
    test rax, rax
    jz .NoRecv
    mov qword [rsp], 1
    mov qword [rsp + 648], 1
    test qword [rsp + 928], 1
    je .NoRecv
    mov qword [rsp + 936], 0
    mov [rel ExprType], rax
    call CallUnify
.NoRecv:
    cmp qword [rsp + 952], 0
    jne .BareCall
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
    mov [rsp + 936], rax
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
    mov [rsp + 936], rax
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
    mov [rsp + 936], rax
    inc qword [rsp + 648]
    mov rdx, [rsp + 640]
    call ParamTypeOf
    call CallHint
.P1Parse:
    call ParseExpr
    test qword [rsp + 928], 1
    je .P1Typed
    call CallUnify
.P1Typed:
    IfTok ",", .P1Comma
    Expect ")", ErrParen
    jmp .P1Done
.BareCall:
    mov rax, [rel Here]
    mov [rsp + 664], rax
.P1Done:
    mov rax, [rel TokPtr]
    mov [rsp + 672], rax
    mov rax, [rsp + 664]
    mov [rel Here], rax
    mov qword [rsp + 680], 0
    test qword [rsp + 928], 1
    je .P2Start
    call CallInstance
.P2Start:
    mov qword [rsp + 696], 0
    call ArgOrder
    test eax, eax
    jz .P2Loop
    mov qword [rsp + 696], 1
    mov rax, [rsp + 128]
    mov [rsp + 680], rax
    jmp .P2Body
.P2Loop:
    mov rax, [rsp + 680]
    mov rdx, [rsp + 640]
    cmp rax, [rdx - 16]
    jae .P2Done
.P2Body:
    mov rax, [rsp + 680]
    mov rdx, [rsp + 640]
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
    cmp rcx, 1
    je .P2Recv
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
.P2Recv:
    mov rcx, [rsp + 944]
    mov [rel ExprType], rcx
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
    cmp qword [rsp + 696], 0
    jne .P2Ordered
    inc qword [rsp + 680]
    jmp .P2Loop
.P2Ordered:
    mov rax, [rsp + 696]
    mov rdx, [rsp + 640]
    cmp rax, [rdx - 16]
    jae .P2Reorder
    mov rcx, [rsp + 128 + rax * 8]
    mov [rsp + 680], rcx
    inc qword [rsp + 696]
    jmp .P2Body
.P2Reorder:
    CompilePrim PrimReorder
    mov rdx, [rsp + 640]
    mov rcx, [rdx - 16]
    call Compile
    mov rdx, [rsp + 640]
    mov rax, [rel Here]
    mov rcx, [rdx - 16]
.P2Space:
    test rcx, rcx
    jz .P2Fill
    push rax
    push rcx
    xor ecx, ecx
    call Compile
    pop rcx
    pop rax
    dec rcx
    jmp .P2Space
.P2Fill:
    xor ecx, ecx
.P2FillLoop:
    mov rdx, [rsp + 640]
    cmp rcx, [rdx - 16]
    jae .P2Done
    mov r8, [rsp + 128 + rcx * 8]
    mov [rax + r8 * 8], rcx
    inc rcx
    jmp .P2FillLoop
.P2Done:
    cmp qword [rsp + 952], 0
    jne .P2Bare
    mov rcx, [rsp + 672]
    call Unread
    call Advance
    call Advance
.P2Bare:
    test qword [rsp + 928], 2
    jz .DirectCall
    CompilePrim PrimCallValue
    mov rcx, [rsp + 640]
    mov rcx, [rcx - 16]
    call Compile
    jmp .CallEmitted
.DirectCall:
    mov rax, [rsp + 640]
    test qword [rax - SigFlags], 4
    jz .NoLink
    call EmitLink
.NoLink:
    CompilePrim PrimCall
    mov rcx, [rsp + 640]
    call Compile
.CallEmitted:
    mov rcx, [rsp + 640]
    add rsp, 960
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
    call ScanFor
    test rax, rax
    jnz ListComp
    xor eax, eax
    mov rcx, [rel CurHintType]
    test rcx, rcx
    jz .ListNoHint
    push rcx
    call TypeKind
    pop rcx
    cmp rax, KList
    mov eax, 0
    jne .ListNoHint
    call ElemOf
.ListNoHint:
    push rax
    push 0
    push 0
.ListLoop:
    mov rax, [rsp + 16]
    call SetHint
    call ParseExpr
    mov rax, [rsp + 16]
    call CoerceElem
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
    cmp qword [rsp + 8], 200000
    ja .LongList
    IfTok ",", .ListComma
    Expect "]", ErrBracket
.ListFinish:
    call Advance
    pop rbx
    pop rsi
    add rsp, 8
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
    mov rcx, [rel CurHintType]
    test rcx, rcx
    jz Advance
    push rcx
    call TypeKind
    pop rcx
    cmp rax, KList
    jne Advance
    mov [rel ExprType], rcx
    jmp Advance
.Brace:
    call Advance
    IfTok "}", .EmptyMap
    mov rax, [rel TokPtr]
    cmp byte [rax], '"'
    je .MapLiteral
    cmp byte [rax], '-'
    je .MapLiteral
    movzx ecx, byte [rax]
    sub ecx, '0'
    cmp ecx, 9
    jbe .MapLiteral
    IfTok "true", .MapLiteral
    IfTok "false", .MapLiteral
    IfTok "[", .MapLiteral
    call IsNameStart
    test eax, eax
    jz RecordLiteral
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call LookupVar
    test rax, rax
    jz .BraceKind
    mov rcx, rax
    call TypeOf
    call KindOfType
    cmp rax, KEnum
    je .MapLiteral
    jmp RecordLiteral
.BraceKind:
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call FindWord
    test rax, rax
    jz RecordLiteral
    cmp rdx, 6
    je .MapLiteral
    cmp rdx, 5
    jne RecordLiteral
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call LookupVar
    jmp RecordLiteral
.EmptyMap:
    CompileNum 0
    CompilePrim PrimMakeMap
    xor ecx, ecx
    call MapOf
    mov [rel ExprType], rax
    mov rcx, [rel CurHintType]
    test rcx, rcx
    jz Advance
    push rcx
    call TypeKind
    pop rcx
    cmp rax, KMap
    jne Advance
    mov [rel ExprType], rcx
    jmp Advance
.MapLiteral:
    xor eax, eax
    mov rcx, [rel CurHintType]
    test rcx, rcx
    jz .MapNoHint
    push rcx
    call TypeKind
    pop rcx
    cmp rax, KMap
    mov eax, 0
    jne .MapNoHint
    call ElemOf
.MapNoHint:
    push rax
    push 0
    push 0
    push 0
.MapLoop:
    IfTok "[", .BracketKey
    call ParseExpr
    jmp .KeyParsed
.BracketKey:
    call Advance
    call ParseExpr
    Expect "]", ErrBracket
    call Advance
.KeyParsed:
    mov rax, [rel ExprType]
    cmp rax, TText
    je .KeyOk
    cmp rax, TNum
    je .KeyOk
    cmp rax, TBool
    je .KeyOk
    call KindOfType
    cmp rax, KEnum
    jne TypeError
    mov rax, [rel ExprType]
.KeyOk:
    mov rdx, [rsp + 16]
    test rdx, rdx
    jz .KeyFirst
    cmp rax, rdx
    jne TypeError
.KeyFirst:
    mov [rsp + 16], rax
    Expect ":", ErrMapColon
    call Advance
    mov rax, [rsp + 24]
    call SetHint
    call ParseExpr
    mov rax, [rsp + 24]
    call CoerceElem
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
    cmp qword [rsp + 8], 200000
    ja .LongList
    IfTok ",", .MapComma
    Expect "}", ErrBraceClose
.MapFinish:
    call Advance
    pop rbx
    pop rsi
    pop rdi
    add rsp, 8
    CompileNum rsi
    cmp rdi, TText
    je .TextMap
    CompilePrim PrimMakeMapInt
    jmp .MapMade
.TextMap:
    CompilePrim PrimMakeMap
.MapMade:
    mov rcx, rbx
    mov rdx, rdi
    call MapKeyed
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
    call TryNegate
    test eax, eax
    jnz .NegDone
    mov rax, [rel ExprType]
    cmp rax, TDec
    je .NegDec
    NeedType TNum
    CompilePrim PrimSub
    ret
.NegDec:
    CompilePrim PrimDSub
.NegDone:
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
    pop rax
    jmp EmitNestValue

.Unknown:
    IfTok "here", .Here
    IfTok "builtExe", .BuiltExe
    IfTok "mainFolder", .MainFolder
    cmp qword [rel PreScanActive], MaxPre
    jae .NoForward
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
    cmp qword [rel InFn], 0
    je .NoForwardVar
    cmp qword [rel PreScanActive], MaxPre
    jae .NoForwardVar
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call TryForwardVar
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call LookupVar
    test rax, rax
    jnz .Var
.NoForwardVar:
    call CaptureName
    test rax, rax
    jnz .Var
    call LibraryPrefix
    test eax, eax
    jnz .NoMember
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
.BuiltExe:
    CompileNum [rel Packed]
    SetType TBool
    jmp Advance
.Here:
    mov rcx, [rel CurFile]
    jmp .Folder
.MainFolder:
    xor ecx, ecx
.Folder:
    call FolderText
    SetType TText
    mov qword [rel LastVarRef], 0
    jmp Advance
.NoMember:
    call Advance
    call Advance
    FailTok ErrLibMember

RecordLiteral:
    mov rax, [rel CurHintType]
    test rax, rax
    jz .NoHint
    push rax
    call KindOfType
    pop rcx
    cmp rax, KRec
    je .Hinted
.NoHint:
    xor ecx, ecx
.Hinted:
    push rcx
    push 1
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
    xor eax, eax
    mov rcx, [rsp + 32]
    test rcx, rcx
    jz .FieldHint
    mov r8, [rsp]
    mov rdx, [r8]
    mov r8, [r8 + 8]
    call FindField
    cmp rax, -1
    jne .HintFound
    mov qword [rsp + 24], 0
    xor eax, eax
    jmp .FieldHint
.HintFound:
    mov rax, rdx
.FieldHint:
    push rax
    push rax
    call SetHint
    call ParseExpr
    pop rax
    pop rax
    test rax, rax
    jz .FieldParsed
    call CheckArg
.FieldParsed:
    pop r8
    mov rax, [rel ExprType]
    test rax, rax
    jz TypeError
    mov [r8 + 16], rax
    IfTok ",", .Comma
    Expect "}", ErrBraceClose
.Finish:
    call Advance
    mov rbx, [rsp + 24]
    test rbx, rbx
    jz .Intern
    cmp qword [rsp + 16], 0
    je .Intern
    mov rcx, rbx
    call FieldCount
    cmp rax, [rsp]
    je .Interned
.Intern:
    mov rcx, [rsp]
    mov rdx, [rsp + 8]
    call InternRecord
    mov rbx, rax
.Interned:
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
    add rsp, 16
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

ArgOrder:
    mov rdx, [rsp + 8 + 640]
    test qword [rdx - SigFlags], 1
    jnz .No
    mov r9, [rdx - 16]
    xor r8d, r8d
    xor r10d, r10d
    xor r11d, r11d
.Check:
    cmp r8, r9
    jae .Checked
    mov rax, [rsp + 8 + r8 * 8]
    test rax, rax
    jz .CheckNext
    cmp rax, r10
    jae .InOrder
    mov r11d, 1
.InOrder:
    mov r10, rax
.CheckNext:
    inc r8
    jmp .Check
.Checked:
    test r11, r11
    jz .No
    xor ecx, ecx
    xor r10d, r10d
.Pick:
    mov r11, -1
    mov rax, -1
    xor r8d, r8d
.Scan:
    cmp r8, r9
    jae .Picked
    mov rdx, [rsp + 8 + r8 * 8]
    test rdx, rdx
    jz .ScanNext
    cmp rdx, r10
    jbe .ScanNext
    cmp rdx, rax
    jae .ScanNext
    mov rax, rdx
    mov r11, r8
.ScanNext:
    inc r8
    jmp .Scan
.Picked:
    cmp r11, -1
    je .Defaults
    mov [rsp + 8 + 128 + rcx * 8], r11
    inc rcx
    mov r10, rax
    jmp .Pick
.Defaults:
    xor r8d, r8d
.DefLoop:
    cmp r8, r9
    jae .Yes
    cmp qword [rsp + 8 + r8 * 8], 0
    jne .DefNext
    mov [rsp + 8 + 128 + rcx * 8], r8
    inc rcx
.DefNext:
    inc r8
    jmp .DefLoop
.Yes:
    mov eax, 1
    ret
.No:
    xor eax, eax
    ret

GenericValue:
    push rbx
    push r12
    push r13
    sub rsp, 224
    mov r12, rcx
    mov r13, [rel CurHintFn]
    test r13, r13
    jz .Numbers
    xor ecx, ecx
.Clear:
    mov qword [rsp + rcx * 8], 0
    inc ecx
    cmp ecx, 27
    jb .Clear
    mov rbx, rsp
    mov rax, r13
    shl rax, 5
    lea rdx, [rel TypeTable]
    add rax, rdx
    mov rcx, [rax + 16]
    cmp rcx, [r12 - 16]
    jne .Mismatch
    xor ecx, ecx
.Params:
    cmp rcx, [r12 - 16]
    jae .Ret
    push rcx
    push rcx
    mov rax, rcx
    mov rdx, r12
    call ParamTypeOf
    mov rcx, rax
    mov rax, r13
    shl rax, 5
    lea rdx, [rel TypeTable]
    mov rdx, [rdx + rax + 24]
    mov rax, [rsp]
    mov rdx, [rdx + rax * 8]
    call Unify
    pop rcx
    pop rcx
    inc rcx
    jmp .Params
.Ret:
    mov rcx, [r12 - 8]
    mov rax, r13
    shl rax, 5
    lea rdx, [rel TypeTable]
    mov rdx, [rdx + rax + 8]
    call Unify
    mov qword [rel SubstFail], 0
    xor ecx, ecx
.Check:
    mov rax, rcx
    push rcx
    push rcx
    mov rdx, r12
    call ParamTypeOf
    call Subst
    pop rcx
    pop rcx
    inc rcx
    cmp rcx, [r12 - 16]
    jb .Check
    cmp qword [rel SubstFail], 0
    jne .NoHint
.Make:
    mov rcx, r12
    mov rdx, rsp
    call GetInstance
    push rax
    push rax
    CompilePrim PrimLit
    mov rcx, [rsp]
    call Compile
    pop rcx
    pop rcx
    mov [rel LastFnValSig], rcx
    mov rax, [rel Here]
    mov [rel LastFnValHere], rax
    call FuncTypeOfSig
    mov [rel ExprType], rax
    add rsp, 224
    pop r13
    pop r12
    pop rbx
    ret
.Mismatch:
    Fail ErrArgType
.Numbers:
    xor ecx, ecx
.NumFill:
    mov qword [rsp + rcx * 8], TNum
    inc ecx
    cmp ecx, 27
    jb .NumFill
    jmp .Make
.NoHint:
    Fail ErrGenericValue
