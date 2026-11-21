SameLine:
    mov rax, [rel TokPtr]
    mov rcx, rax
.Back:
    dec rcx
    movzx edx, byte [rcx]
    cmp edx, ' '
    je .Back
    cmp edx, 9
    je .Back
    cmp edx, 10
    je .No
    cmp edx, 13
    je .No
    mov eax, 1
    ret
.No:
    xor eax, eax
    ret

ParseExpr:
    inc qword [rel ExprDepth]
    cmp qword [rel ExprDepth], 200
    ja .TooDeep
    call ParseExprInner
    dec qword [rel ExprDepth]
    ret
.TooDeep:
    mov qword [rel ExprDepth], 0
    Fail ErrTooDeep

ParseExprInner:
    push qword [rel TokPtr]
    push qword [rel Here]
    call ParseOr
    IfTok "if", .Maybe
.Done:
    add rsp, 16
    ret
.Maybe:
    call SameLine
    test eax, eax
    jz .Done
    pop rax
    mov [rel Here], rax
    call Advance
    call ParseOr
    call NeedCondition
    lea rcx, [rel PrimBranch0]
    call EmitJump
    push rax
    Expect "otherwise", ErrChoice
    push qword [rel TokPtr]
    mov rcx, [rsp + 16]
    call Unread
    call Advance
    call ParseOr
    push qword [rel ExprType]
    lea rcx, [rel PrimBranch]
    call EmitJump
    mov rcx, [rsp + 16]
    mov [rsp + 16], rax
    mov rdx, [rel Here]
    mov [rcx], rdx
    mov rcx, [rsp + 8]
    call Unread
    call Advance
    call Advance
    call ParseExpr
    pop rax
    mov rdx, [rel ExprType]
    cmp rax, rdx
    jne .Mismatch
.Join:
    pop rcx
    pop rcx
    mov rdx, [rel Here]
    mov [rcx], rdx
    add rsp, 8
    ret
.Mismatch:
    call Compatible
    test rax, rax
    jz TypeError
    mov [rel ExprType], rax
    jmp .Join

ParseOr:
    call ParseAnd
.Loop:
    IfTok "or", .Or
    IfTok "||", .Hint
    ret
.Or:
    mov rax, [rel ExprType]
    cmp rax, TBool
    je .Logic
    cmp rax, TText
    je .Fallback
    call KindOfType
    cmp rax, KList
    je .Fallback
    cmp rax, KMap
    je .Fallback
.Logic:
    push qword [rel ExprType]
    call Advance
    call ParseAnd
    pop rax
    call CheckLogic
    CompilePrim PrimOr
    SetType TBool
    jmp .Loop
.Fallback:
    push qword [rel ExprType]
    CompilePrim PrimDup
    CompilePrim PrimLength
    lea rcx, [rel PrimBranch0]
    call EmitJump
    push rax
    lea rcx, [rel PrimBranch]
    call EmitJump
    pop rcx
    push rax
    mov rdx, [rel Here]
    mov [rcx], rdx
    CompilePrim PrimDrop
    call Advance
    call ParseAnd
    pop rcx
    mov rdx, [rel Here]
    mov [rcx], rdx
    pop rax
    cmp rax, [rel ExprType]
    jne TypeError
    jmp .Loop
.Hint:
    Fail ErrOrHint

ParseAnd:
    call ParseNot
.Loop:
    IfTok "and", .And
    IfTok "&&", .Hint
    ret
.And:
    push qword [rel ExprType]
    call Advance
    call ParseNot
    pop rax
    call CheckLogic
    CompilePrim PrimAnd
    SetType TBool
    jmp .Loop
.Hint:
    Fail ErrAndHint

ParseNot:
    IfTok "not", .Not
    jmp ParseCompare
.Not:
    call Advance
    call ParseNot
    mov eax, TBool
    call CheckLogic
    CompileNum 0
    CompilePrim PrimEq
    SetType TBool
    ret

ParseCompare:
    call ParseRange
    IfTok "==", .Eq
    IfTok "!=", .Ne
    IfTok "<=", .Le
    IfTok ">=", .Ge
    IfTok "<", .Lt
    IfTok ">", .Gt
    IfTok "in", .In
    IfTok "not", .MaybeNotIn
    ret
.Eq:
    call .Equal
    cmp rax, 2
    je .EqText
    cmp rax, 3
    je .EqDec
    CompilePrim PrimEq
    SetType TBool
    ret
.EqText:
    CompilePrim PrimTextEq
    SetType TBool
    ret
.EqDec:
    CompilePrim PrimDEq
    SetType TBool
    ret
.Ne:
    call .Equal
    cmp rax, 2
    je .NeText
    cmp rax, 3
    je .NeDec
    CompilePrim PrimNotEq
    SetType TBool
    ret
.NeText:
    CompilePrim PrimTextEq
    CompileNum 0
    CompilePrim PrimEq
    SetType TBool
    ret
.NeDec:
    CompilePrim PrimDNotEq
    SetType TBool
    ret
.Equal:
    push qword [rel ExprType]
    call Advance
    call ParseRange
    pop rax
    mov rdx, [rel ExprType]
    cmp rax, rdx
    jne .Mixed
    cmp rax, TText
    je .IsText
    cmp rax, TNum
    je .IsInt
    cmp rax, TBool
    je .IsInt
    cmp rax, TDec
    je .IsDec
    push rax
    call KindOfType
    cmp rax, KEnum
    pop rax
    je .IsInt
    jmp TypeError
.Mixed:
    call NumericPair
.IsDec:
    mov eax, 3
    ret
.IsText:
    mov eax, 2
    ret
.IsInt:
    mov eax, 1
    ret
.Le:
    lea rbx, [rel PrimLessEq]
    lea rsi, [rel PrimDLessEq]
    jmp .Order
.Ge:
    lea rbx, [rel PrimGreaterEq]
    lea rsi, [rel PrimDGreaterEq]
    jmp .Order
.Lt:
    lea rbx, [rel PrimLess]
    lea rsi, [rel PrimDLess]
    jmp .Order
.Gt:
    lea rbx, [rel PrimGreater]
    lea rsi, [rel PrimDGreater]
.Order:
    push rbx
    push rsi
    push qword [rel ExprType]
    call Advance
    call ParseRange
    pop rax
    call NumericPair
    pop rsi
    pop rbx
    mov rcx, rbx
    cmp rax, TDec
    jne .OrderEmit
    mov rcx, rsi
.OrderEmit:
    call Compile
    SetType TBool
    ret
.MaybeNotIn:
    call GetInput
    push rax
    push qword [rel TokPtr]
    push qword [rel TokLen]
    call Advance
    IfTok "in", .NotIn
    pop qword [rel TokLen]
    pop qword [rel TokPtr]
    pop rcx
    jmp Unread
.NotIn:
    add rsp, 24
    call .Membership
    CompileNum 0
    CompilePrim PrimEq
    SetType TBool
    ret
.In:
    call .Membership
    SetType TBool
    ret
.Membership:
    push qword [rel ExprType]
    call Advance
    call ParseRange
    pop rbx
    mov rax, [rel ExprType]
    cmp rax, TText
    je .InText
    mov rcx, rax
    call TypeKind
    cmp rax, KList
    je .InList
    cmp rax, KMap
    je .InMap
    jmp TypeError
.InText:
    cmp rbx, TText
    jne TypeError
    CompilePrim PrimTextHas
    ret
.InMap:
    cmp rbx, TText
    jne TypeError
    CompilePrim PrimMapHas
    ret
.InList:
    mov rcx, [rel ExprType]
    call ElemOf
    test rax, rax
    jz .InListAny
    cmp rax, rbx
    jne TypeError
.InListAny:
    cmp rbx, TText
    je .InListText
    CompilePrim PrimListHas
    ret
.InListText:
    CompilePrim PrimListHasText
    ret

ParseRange:
    call ParseBits
    IfTok "..", .Range
    ret
.Range:
    NeedType TNum
    call Advance
    call ParseBits
    NeedType TNum
    CompilePrim PrimRange
    mov ecx, TNum
    call ListOf
    mov [rel ExprType], rax
    ret

ParseBits:
    call ParseShift
.Loop:
    IfTok "&", .And
    IfTok "|", .Or
    IfTok "xor", .Xor
    ret
NumOp .And, ParseShift, PrimBitAnd, TNum
    jmp .Loop
NumOp .Or, ParseShift, PrimBitOr, TNum
    jmp .Loop
NumOp .Xor, ParseShift, PrimBitXor, TNum
    jmp .Loop

ParseShift:
    call ParseSum
.Loop:
    IfTok "<<", .Left
    IfTok ">>", .Right
    ret
NumOp .Left, ParseSum, PrimShiftLeft, TNum
    jmp .Loop
NumOp .Right, ParseSum, PrimShiftRight, TNum
    jmp .Loop

ParseSum:
    call ParseProduct
.Loop:
    IfTok "+", .Add
    IfTok "-", .Sub
    ret
.Add:
    push qword [rel ExprType]
    call Advance
    call ParseProduct
    pop rax
    mov rdx, [rel ExprType]
    cmp rax, TText
    je .Text
    cmp rdx, TText
    je .Text
    call NumericPair
    lea rcx, [rel PrimAdd]
    cmp rax, TDec
    jne .AddEmit
    lea rcx, [rel PrimDAdd]
.AddEmit:
    mov [rel ExprType], rax
    call Compile
    jmp .Loop
.Text:
    push rax
    mov rax, rdx
    call ToTextRaw
    pop rax
    cmp rax, TText
    je .Join
    push rax
    CompilePrim PrimSwap
    pop rax
    call ToTextRaw
    CompilePrim PrimSwap
.Join:
    CompilePrim PrimConcat
    SetType TText
    jmp .Loop
ArithOp .Sub, ParseProduct, PrimSub, PrimDSub
    jmp .Loop

ParseProduct:
    call ParsePower
.Loop:
    IfTok "*", .Mul
    IfTok "//", .FloorDiv
    IfTok "/", .Div
    IfTok "%", .Mod
    ret
ArithOp .Mul, ParsePower, PrimMul, PrimDMul
    jmp .Loop
.FloorDiv:
    push qword [rel ExprType]
    call Advance
    call ParsePower
    pop rax
    call NumericPair
    cmp rax, TDec
    je .FloorDivDec
    CompilePrim PrimFloorDiv
    SetType TNum
    jmp .Loop
.FloorDivDec:
    CompilePrim PrimDFloorDiv
    SetType TNum
    jmp .Loop
.Mod:
    push qword [rel ExprType]
    call Advance
    call ParsePower
    pop rax
    call NumericPair
    cmp rax, TDec
    je .ModDec
    CompilePrim PrimMod
    SetType TNum
    jmp .Loop
.ModDec:
    CompilePrim PrimDMod
    SetType TDec
    jmp .Loop
.Div:
    push qword [rel ExprType]
    call Advance
    call ParsePower
    pop rax
    call NumericPair
    cmp rax, TDec
    je .DivEmit
    CompilePrim PrimToDec
    CompilePrim PrimToDecUnder
.DivEmit:
    CompilePrim PrimDDiv
    SetType TDec
    jmp .Loop

ParsePower:
    call ParseAtom
    IfTok "^", .Pow
    ret
NumOp .Pow, ParsePower, PrimPow, TNum
    ret

ParseAtom:
    mov qword [rel LastVarRef], 0
    call ParsePrimary
.Post:
    IfTok "[", .Index
    IfTok ".", .Member
    IfTok "(", .MaybeCall
    ret
.MaybeCall:
    mov rax, [rel ExprType]
    call KindOfType
    cmp rax, KFunc
    je .CallValue
    ret
.CallValue:
    call SameLine
    test eax, eax
    jz .NotCall
    mov rcx, [rel ExprType]
    shl rcx, 5
    lea rax, [rel TypeTable]
    add rax, rcx
    push qword [rax + 8]
    push qword [rax + 16]
    push qword [rax + 24]
    push 0
    call Advance
    IfTok ")", .CallArgsDone
.CallArg:
    mov rax, [rsp]
    cmp rax, [rsp + 16]
    jae .CallCount
    mov rcx, [rsp + 8]
    mov rax, [rcx + rax * 8]
    call SetHint
    call ParseExpr
    mov rax, [rsp]
    mov rcx, [rsp + 8]
    mov rax, [rcx + rax * 8]
    call CheckArg
    inc qword [rsp]
    IfTok ",", .CallComma
    Expect ")", ErrParen
.CallArgsDone:
    mov rax, [rsp]
    cmp rax, [rsp + 16]
    jne .CallCount
    call Advance
    CompilePrim PrimCallValue
    mov rcx, [rsp]
    call Compile
    add rsp, 24
    pop rax
    mov qword [rel VoidCall], 0
    test rax, rax
    jnz .CallType
    mov qword [rel VoidCall], 1
    mov eax, TNum
.CallType:
    mov [rel ExprType], rax
    mov qword [rel LastVarRef], 0
    jmp .Post
.CallComma:
    call Advance
    jmp .CallArg
.CallCount:
    Fail ErrArgs
.NotCall:
    ret
.Index:
    mov rax, [rel ExprType]
    cmp rax, TText
    je .TextIndex
    call KindOfType
    cmp rax, KList
    je .ListIndex
    cmp rax, KMap
    je .MapIndex
    jmp TypeError
.TextIndex:
    call Advance
    call ParseExpr
    NeedType TNum
    Expect "]", ErrBracket
    call Advance
    CompilePrim PrimTextAt
    SetType TText
    jmp .IndexDone
.ListIndex:
    push qword [rel ExprType]
    call Advance
    call ParseExpr
    NeedType TNum
    Expect "]", ErrBracket
    call Advance
    CompilePrim PrimIndex
    jmp .ElemType
.MapIndex:
    push qword [rel ExprType]
    call Advance
    call ParseExpr
    NeedType TText
    Expect "]", ErrBracket
    call Advance
    CompilePrim PrimMapGet
.ElemType:
    pop rcx
    call ElemOf
    mov [rel ExprType], rax
.IndexDone:
    mov qword [rel LastVarRef], 0
    jmp .Post
.Member:
    call Advance
    mov rax, [rel ExprType]
    call KindOfType
    cmp rax, KRec
    je .Field
    IfTok "length", .Length
    IfTok "add", .Add
    IfTok "keys", .Keys
    IfTok "filter", .Filter
    IfTok "map", .Map
    Fail ErrMember
.Filter:
    mov ecx, 1
    jmp ListLoop
.Map:
    mov ecx, 2
    jmp ListLoop
.Field:
    mov rcx, [rel ExprType]
    mov rdx, [rel TokPtr]
    mov r8, [rel TokLen]
    call FindField
    cmp rax, -1
    je .NoField
    push rdx
    push rax
    CompilePrim PrimGetField
    pop rcx
    shl rcx, 3
    call Compile
    pop rax
    mov [rel ExprType], rax
    mov qword [rel LastVarRef], 0
    call Advance
    jmp .Post
.NoField:
    FailTok ErrNoField
.Length:
    mov rax, [rel ExprType]
    cmp rax, TText
    je .LengthOk
    call KindOfType
    cmp rax, KList
    je .LengthOk
    cmp rax, KMap
    jne TypeError
.LengthOk:
    CompilePrim PrimLength
    SetType TNum
    mov qword [rel LastVarRef], 0
    call Advance
    jmp .Post
.Keys:
    mov rax, [rel ExprType]
    call KindOfType
    cmp rax, KMap
    jne TypeError
    CompilePrim PrimMapKeys
    mov ecx, TText
    call ListOf
    mov [rel ExprType], rax
    mov qword [rel LastVarRef], 0
    call Advance
    jmp .Post
.Add:
    mov rax, [rel ExprType]
    call KindOfType
    cmp rax, KList
    jne TypeError
    push qword [rel ExprType]
    push qword [rel LastVarRef]
    call Advance
    Expect "(", ErrParen
    call Advance
    call ParseExpr
    Expect ")", ErrParen
    call Advance
    pop rbx
    pop rcx
    call ElemOf
    mov rdx, [rel ExprType]
    test rdx, rdx
    jz TypeError
    test rax, rax
    jz .AddUnknown
    cmp rax, rdx
    jne TypeError
    jmp .AddEmit
.AddUnknown:
    test rbx, rbx
    jz .AddEmit
    mov rcx, rdx
    call ListOf
    mov rdx, rax
    mov rcx, rbx
    call SetTypeOf
.AddEmit:
    CompilePrim PrimListAdd
    SetType TNone
    ret
