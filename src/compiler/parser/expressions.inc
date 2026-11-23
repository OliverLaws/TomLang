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
    call ParsePipe
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
    call ParsePipe
    mov rcx, [rsp]
    call ElseIsNothing
    test eax, eax
    jz .NoBoxFirst
    mov rcx, [rel ExprType]
    cmp rcx, TNil
    je .NoBoxFirst
    mov edx, TNil
    call UnionOf2
    call CoerceTo
.NoBoxFirst:
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
    cmp rdx, TNil
    je .ElseNil
    cmp rax, TNil
    je .FirstNil
    call Compatible
    test rax, rax
    jz TypeError
    mov [rel ExprType], rax
    jmp .Join
.ElseNil:
    push rax
    mov rcx, rax
    mov edx, TNil
    call UnionHas
    pop rcx
    test eax, eax
    jz TypeError
    mov [rel ExprType], rcx
    jmp .Join
.FirstNil:
    mov rcx, rdx
    mov edx, TNil
    call UnionOf2
    call CoerceTo
    jmp .Join

ParsePipe:
    call ParseOr
.Loop:
    IfTok "|>", .Pipe
    ret
.Pipe:
    call Advance
    mov rcx, [rel ExprType]
    test rcx, rcx
    jz TypeError
    call PipeTarget
    mov qword [rel LastVarRef], 0
    jmp .Loop

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
    push rax
    mov rcx, rax
    call KindOfType
    pop rcx
    cmp rax, KUnion
    je .Optional
    mov rax, rcx
    cmp rax, TText
    je .Fallback
    call KindOfType
    cmp rax, KList
    je .Fallback
    cmp rax, KMap
    je .Fallback
.Logic:
    mov qword [rel OrSeen], 1
    push qword [rel ExprType]
    CompilePrim PrimDup
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
    call CheckLogic
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
.Optional:
    mov edx, TNil
    push rcx
    call UnionHas
    pop rcx
    test eax, eax
    jz TypeError
    mov edx, TNil
    call UnionWithout
    push rax
    CompilePrim PrimDup
    lea rcx, [rel PrimBranch0]
    call EmitJump
    push rax
    mov rax, [rsp + 8]
    call KindOfType
    cmp rax, KUnion
    je .OptKeep
    CompilePrim PrimUnbox
.OptKeep:
    lea rcx, [rel PrimBranch]
    call EmitJump
    pop rcx
    push rax
    mov rdx, [rel Here]
    mov [rcx], rdx
    CompilePrim PrimDrop
    call Advance
    call ParseAnd
    mov rax, [rsp + 8]
    call CoerceTo
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
    mov qword [rel AndSeen], 1
    push qword [rel NarrowCount]
    mov rax, [rel NarrowCandHere]
    cmp rax, [rel Here]
    jne .AndNoNarrow
    cmp qword [rel NarrowCandVar], 0
    je .AndNoNarrow
    mov rcx, [rel NarrowCandVar]
    mov rdx, [rel NarrowCandType]
    call NarrowPush
.AndNoNarrow:
    push qword [rel ExprType]
    CompilePrim PrimDup
    lea rcx, [rel PrimBranch0]
    call EmitJump
    push rax
    CompilePrim PrimDrop
    mov rax, [rsp]
    lea rcx, [rel PrimAndJump]
    mov [rax - 16], rcx
    call Advance
    call ParseNot
    pop rcx
    mov rdx, [rel Here]
    mov [rcx], rdx
    pop rax
    call CheckLogic
    pop rax
    mov [rel NarrowCount], rax
    SetType TBool
    jmp .Loop
.Hint:
    Fail ErrAndHint

ParseNot:
    IfTok "not", .Not
    jmp ParseCompare
.Not:
    mov qword [rel AndSeen], 1
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
    IfTok "is", .IsType
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
    mov qword [rel NilCmpVar], 0
    call .Equal
    mov rcx, [rel NilCmpVar]
    test rcx, rcx
    jz .EqNoNeg
    push rax
    push rcx
    mov rcx, [rel NilCmpType]
    mov edx, TNil
    call UnionWithout
    mov [rel NegCandType], rax
    pop rcx
    mov [rel NegCandVar], rcx
    mov rax, [rel Here]
    add rax, 8
    mov [rel NegCandHere], rax
    mov rax, [rel ExprDepth]
    mov [rel NegCandDepth], rax
    call NegAdd
    pop rax
.EqNoNeg:
    cmp rax, 4
    je .EqDone
    cmp rax, 5
    je .EqDeep
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
.EqDeep:
    CompileNum [rel EqType]
    CompilePrim PrimDeepEq
    SetType TBool
    ret
.EqDec:
    CompilePrim PrimDEq
.EqDone:
    SetType TBool
    ret
.Ne:
    mov qword [rel NilCmpVar], 0
    call .Equal
    push rax
    mov rcx, [rel NilCmpVar]
    test rcx, rcx
    jz .NeNoNarrow
    mov rax, [rel NilCmpType]
    push rcx
    push rax
    mov rcx, rax
    mov edx, TNil
    call UnionWithout
    mov [rel NarrowCandType], rax
    pop rax
    pop rcx
    mov [rel NarrowCandVar], rcx
    mov rax, [rel Here]
    add rax, 8
    mov [rel NarrowCandHere], rax
.NeNoNarrow:
    pop rax
    cmp rax, 4
    je .NeUser
    cmp rax, 5
    je .NeDeep
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
.NeDeep:
    CompileNum [rel EqType]
    CompilePrim PrimDeepEq
.NeUser:
    CompileNum 0
    CompilePrim PrimEq
    SetType TBool
    ret
.Equal:
    push qword [rel LastVarRef]
    push qword [rel ExprType]
    call Advance
    mov rcx, [rsp]
    call TypeKind
    cmp rax, KList
    je .EqHint
    cmp rax, KMap
    je .EqHint
    cmp rax, KUnion
    jne .EqParse
.EqHint:
    mov rax, [rsp]
    call SetHint
.EqParse:
    call ParseRange
    pop rax
    TryOp "==", .EqUser
    pop r8
    mov rdx, [rel ExprType]
    cmp rax, TNil
    je .NilCompare
    cmp rdx, TNil
    je .NilCompare
    cmp rax, rdx
    jne .MaybeEmpty
.SameType:
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
    je .EnumEq
    cmp rax, KList
    je .DeepEq
    cmp rax, KMap
    je .DeepEq
    cmp rax, KRec
    je .DeepEq
    cmp rax, KUnion
    je .DeepEq
    cmp rax, KIface
    je .DeepEq
    pop rax
    jmp TypeError
.EnumEq:
    pop rax
    jmp .IsInt
.DeepEq:
    pop rax
    mov [rel EqType], rax
    mov eax, 5
    ret
.MaybeEmpty:
    push rax
    push rdx
    mov rcx, rax
    call TypeKind
    push rax
    mov rcx, [rsp + 8]
    call TypeKind
    pop r8
    pop rdx
    pop rcx
    cmp rax, r8
    jne .MixedBack
    cmp rax, KList
    je .EmptyCheck
    cmp rax, KMap
    jne .MixedBack
.EmptyCheck:
    push rcx
    push rdx
    call ElemOf
    pop rdx
    pop rcx
    test rax, rax
    jz .TakeRight
    push rcx
    push rdx
    mov rcx, rdx
    call ElemOf
    pop rdx
    pop rcx
    test rax, rax
    jnz .MixedBack
    mov rax, rcx
    jmp .DeepEqSet
.TakeRight:
    mov rax, rdx
.DeepEqSet:
    mov [rel EqType], rax
    mov eax, 5
    ret
.MixedBack:
    mov rax, rcx
    jmp .Mixed
.EqUser:
    add rsp, 8
    mov eax, 4
    ret
.NilCompare:
    mov [rel NilCmpVar], r8
    mov [rel NilCmpType], rax
    cmp rax, TNil
    jne .NilOk
    mov [rel NilCmpType], rdx
    mov qword [rel NilCmpVar], 0
.NilOk:
    mov eax, 1
    ret
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
    mov qword [rel OrderOp], 2
    lea rbx, [rel PrimLessEq]
    lea rsi, [rel PrimDLessEq]
    jmp .Order
.Ge:
    mov qword [rel OrderOp], 3
    lea rbx, [rel PrimGreaterEq]
    lea rsi, [rel PrimDGreaterEq]
    jmp .Order
.Lt:
    mov qword [rel OrderOp], 0
    lea rbx, [rel PrimLess]
    lea rsi, [rel PrimDLess]
    jmp .Order
.Gt:
    mov qword [rel OrderOp], 1
    lea rbx, [rel PrimGreater]
    lea rsi, [rel PrimDGreater]
.Order:
    push rbx
    push rsi
    push qword [rel OrderOp]
    push qword [rel ExprType]
    call Advance
    call ParseRange
    pop rax
    pop rcx
    push rax
    call OrderOverload
    test eax, eax
    pop rax
    jnz .OrderUser
    cmp rax, TText
    je .OrderText
    cmp rax, [rel ExprType]
    jne .OrderNum
    push rax
    call KindOfType
    cmp rax, KEnum
    pop rax
    je .OrderInt
.OrderNum:
    call NumericPair
    pop rsi
    pop rbx
    mov rcx, rbx
    cmp rax, TDec
    jne .OrderEmit
    mov rcx, rsi
.OrderEmit:
    call CompileOp
    SetType TBool
    ret
.OrderUser:
    add rsp, 16
    SetType TBool
    ret
.OrderText:
    cmp qword [rel ExprType], TText
    jne TypeError
    CompilePrim PrimTextCompare
    CompileNum 0
.OrderInt:
    pop rsi
    pop rbx
    mov rcx, rbx
    jmp .OrderEmit
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
    mov rcx, [rel ExprType]
    call KeyOf
    cmp rbx, rax
    jne TypeError
    mov rcx, [rel ExprType]
    lea rdx, [rel PrimMapHas]
    lea r8, [rel PrimMapHasInt]
    call MapOp
    SetType TBool
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

.IsType:
    mov rcx, [rel TokPtr]
.IsBack:
    movzx eax, byte [rcx - 1]
    cmp eax, ' '
    je .IsPrev
    cmp eax, 9
    je .IsPrev
    cmp eax, 10
    je .IsNot
    cmp eax, 13
    je .IsNot
    jmp .IsSame
.IsPrev:
    dec rcx
    jmp .IsBack
.IsNot:
    ret
.IsSame:
    mov rax, [rel ExprType]
    push qword [rel LastVarRef]
    push rax
    mov rcx, rax
    call KindOfType
    cmp rax, KIface
    je .IsIface
    cmp rax, KUnion
    jne TypeError
    call Advance
    call ParseTypeName
    push rax
    call Advance
    mov rcx, [rsp + 8]
    mov rdx, [rsp]
    call UnionHas
    test eax, eax
    jz TypeError
    CompilePrim PrimTagIs
    mov rcx, [rsp]
    call Compile
    pop rdx
    pop rax
    pop rcx
    test rcx, rcx
    jz .IsDone
    mov [rel NarrowCandVar], rcx
    mov [rel NarrowCandType], rdx
    mov [rel NegCandVar], rcx
    mov rcx, rax
    call UnionWithout
    mov [rel NegCandType], rax
    mov rax, [rel Here]
    mov [rel NarrowCandHere], rax
    mov [rel NegCandHere], rax
    mov rax, [rel ExprDepth]
    mov [rel NegCandDepth], rax
    call NegAdd
.IsDone:
    SetType TBool
    ret
.IsIface:
    call Advance
    call ParseTypeName
    push rax
    call Advance
    mov rax, [rsp]
    call KindOfType
    cmp rax, KRec
    jne TypeError
    CompilePrim PrimTagIs
    mov rcx, [rsp]
    call Compile
    pop rdx
    pop rax
    pop rcx
    test rcx, rcx
    jz .IsDone
    mov [rel NarrowCandVar], rcx
    mov [rel NarrowCandType], rdx
    mov rax, [rel Here]
    mov [rel NarrowCandHere], rax
    jmp .IsDone

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
    TryOp "+", .Loop
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
    call CompileOp
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
ArithOp .Sub, ParseProduct, PrimSub, PrimDSub, "-"
    jmp .Loop

ParseProduct:
    call ParsePower
.Loop:
    IfTok "*", .Mul
    IfTok "//", .FloorDiv
    IfTok "/", .Div
    IfTok "%", .Mod
    ret
ArithOp .Mul, ParsePower, PrimMul, PrimDMul, "*"
    jmp .Loop
.FloorDiv:
    push qword [rel ExprType]
    call Advance
    call ParsePower
    pop rax
    TryOp "//", .Loop
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
    TryOp "%", .Loop
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
    TryOp "/", .Loop
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
.Pow:
    push qword [rel ExprType]
    call Advance
    call ParsePower
    pop rax
    TryOp "^", .PowOver
    call NumericPair
    cmp rax, TDec
    je .PowDec
    CompilePrim PrimPow
    SetType TNum
    ret
.PowDec:
    CompilePrim PrimDPow
    SetType TDec
.PowOver:
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
    call SliceCheck
    test eax, eax
    jnz .TextSlice
    NeedType TNum
    call EmitIndexFix
    Expect "]", ErrBracket
    call Advance
    CompilePrim PrimTextAt
    SetType TText
    jmp .IndexDone
.TextSlice:
    call EmitSliceFix
    Expect "]", ErrBracket
    call Advance
    CompilePrim PrimTextSlice
    SetType TText
    jmp .IndexDone
.ListIndex:
    push qword [rel ExprType]
    call Advance
    call ParseExpr
    call SliceCheck
    test eax, eax
    jnz .ListSlice
    NeedType TNum
    call EmitIndexFix
    Expect "]", ErrBracket
    call Advance
    CompilePrim PrimIndex
    jmp .ElemType
.ListSlice:
    call EmitSliceFix
    Expect "]", ErrBracket
    call Advance
    CompilePrim PrimListSlice
    pop rax
    mov [rel ExprType], rax
    jmp .IndexDone
.MapIndex:
    push qword [rel ExprType]
    call Advance
    call ParseExpr
    mov rcx, [rsp]
    call KeyOf
    cmp rax, [rel ExprType]
    jne TypeError
    Expect "]", ErrBracket
    call Advance
    mov rcx, [rsp]
    lea rdx, [rel PrimMapGet]
    lea r8, [rel PrimMapGetInt]
    call MapOp
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
    cmp qword [rel ExprType], TText
    jne .NotTextMethod
    IfTok "split", .TSplit
    IfTok "upper", .TUpper
    IfTok "lower", .TLower
    IfTok "trim", .TTrim
    IfTok "replace", .TReplace
    IfTok "contains", .TContains
    IfTok "startsWith", .TStarts
    IfTok "endsWith", .TEnds
.NotTextMethod:
    IfTok "length", .Length
    IfTok "add", .Add
    IfTok "keys", .Keys
    IfTok "filter", .Filter
    IfTok "map", .Map
    IfTok "copy", .Copy
    IfTok "sort", .Sort
    IfTok "pop", .Pop
    IfTok "removeAt", .Remove
    IfTok "remove", .RemoveValue
    IfTok "get", .MapGetOr
    IfTok "insert", .Insert
    IfTok "join", .Join
.TryMethod:
    call MemberCall
    test eax, eax
    jz .NoMember
    mov qword [rel LastVarRef], 0
    jmp .Post
.NoMember:
    Fail ErrMember
.Copy:
    call NeedList
    call EmptyParens
    CompilePrim PrimListCopy
    jmp .MethodDone
.Sort:
    call NeedList
    call EmptyParens
    mov rcx, [rel ExprType]
    call ElemOf
    xor ebx, ebx
    cmp rax, TNum
    je .SortKind
    cmp rax, TBool
    je .SortKind
    mov ebx, 1
    cmp rax, TDec
    je .SortKind
    mov ebx, 2
    cmp rax, TText
    je .SortKind
    push rax
    call KindOfType
    pop rcx
    xor ebx, ebx
    cmp rax, KEnum
    je .SortKind
    Fail ErrSortType
.SortKind:
    CompileNum rbx
    CompilePrim PrimListSort
    SetType TNone
    jmp .MethodDone
.Pop:
    call NeedList
    call EmptyParens
    CompilePrim PrimListPop
    mov rcx, [rel ExprType]
    call ElemOf
    mov [rel ExprType], rax
    jmp .MethodDone
.Remove:
    call NeedList
    push qword [rel ExprType]
    call Advance
    Expect "(", ErrParen
    call Advance
    call ParseExpr
    NeedType TNum
    call EmitIndexFix
    Expect ")", ErrParen
    call Advance
    CompilePrim PrimListRemove
    pop rcx
    call ElemOf
    mov [rel ExprType], rax
    jmp .MethodDone
.TextArgs:
    push rcx
    push rcx
    call Advance
    Expect "(", ErrParen
    call Advance
    cmp qword [rsp], 0
    je .TextArgsEnd
.TextArgLoop:
    call ParseExpr
    NeedType TText
    dec qword [rsp]
    jz .TextArgsEnd
    Expect ",", ErrComma
    call Advance
    jmp .TextArgLoop
.TextArgsEnd:
    Expect ")", ErrParen
    call Advance
    add rsp, 16
    ret
.TSplit:
    mov ecx, 1
    call .TextArgs
    CompilePrim PrimTextSplit
    mov ecx, TText
    call ListOf
    mov [rel ExprType], rax
    jmp .MethodDone
.TUpper:
    xor ecx, ecx
    call .TextArgs
    CompilePrim PrimTextUpper
    SetType TText
    jmp .MethodDone
.TLower:
    xor ecx, ecx
    call .TextArgs
    CompilePrim PrimTextLower
    SetType TText
    jmp .MethodDone
.TTrim:
    xor ecx, ecx
    call .TextArgs
    CompilePrim PrimTextTrim
    SetType TText
    jmp .MethodDone
.TReplace:
    mov ecx, 2
    call .TextArgs
    CompilePrim PrimTextReplace
    SetType TText
    jmp .MethodDone
.TContains:
    mov ecx, 1
    call .TextArgs
    CompilePrim PrimSwap
    CompilePrim PrimTextHas
    SetType TBool
    jmp .MethodDone
.TStarts:
    mov ecx, 1
    call .TextArgs
    CompilePrim PrimTextStarts
    SetType TBool
    jmp .MethodDone
.TEnds:
    mov ecx, 1
    call .TextArgs
    CompilePrim PrimTextEnds
    SetType TBool
    jmp .MethodDone
.RemoveValue:
    mov rax, [rel ExprType]
    call KindOfType
    cmp rax, KMap
    je .MapRemove
    call NeedList
    push qword [rel ExprType]
    call Advance
    Expect "(", ErrParen
    call Advance
    mov rcx, [rsp]
    call ElemOf
    push rax
    push rax
    call SetHint
    call ParseExpr
    pop rax
    pop rax
    call CoerceElem
    Expect ")", ErrParen
    call Advance
    pop rcx
    call ElemOf
    cmp rax, [rel ExprType]
    jne TypeError
    push rax
    CompilePrim PrimListRemoveValue
    pop rcx
    call Compile
    SetType TBool
    jmp .MethodDone
.MapRemove:
    push qword [rel ExprType]
    call Advance
    Expect "(", ErrParen
    call Advance
    call ParseExpr
    mov rcx, [rsp]
    call KeyOf
    cmp rax, [rel ExprType]
    jne TypeError
    Expect ")", ErrParen
    call Advance
    pop rcx
    lea rdx, [rel PrimMapRemove]
    lea r8, [rel PrimMapRemoveInt]
    call MapOp
    SetType TBool
    jmp .MethodDone
.MapGetOr:
    mov rax, [rel ExprType]
    call KindOfType
    cmp rax, KMap
    jne TypeError
    push qword [rel ExprType]
    call Advance
    Expect "(", ErrParen
    call Advance
    call ParseExpr
    mov rcx, [rsp]
    call KeyOf
    cmp rax, [rel ExprType]
    jne TypeError
    Expect ",", ErrComma
    call Advance
    mov rcx, [rsp]
    call ElemOf
    push rax
    push rax
    call SetHint
    call ParseExpr
    pop rax
    pop rax
    call CoerceElem
    Expect ")", ErrParen
    call Advance
    mov rcx, [rsp]
    call ElemOf
    cmp rax, [rel ExprType]
    jne TypeError
    pop rcx
    push rax
    lea rdx, [rel PrimMapGetOr]
    lea r8, [rel PrimMapGetOrInt]
    call MapOp
    pop rax
    mov [rel ExprType], rax
    jmp .MethodDone
.Insert:
    call NeedList
    push qword [rel ExprType]
    push qword [rel LastVarRef]
    call Advance
    Expect "(", ErrParen
    call Advance
    call ParseExpr
    NeedType TNum
    Expect ",", ErrInsertArgs
    call Advance
    mov rcx, [rsp + 8]
    call ElemOf
    push rax
    call SetHint
    call ParseExpr
    pop rax
    mov rdx, [rel ExprType]
    test rax, rax
    jz .InsertAny
    cmp rax, rdx
    je .InsertOk
    cmp rax, TDec
    jne .InsertCompat
    cmp rdx, TNum
    jne TypeError
    CompilePrim PrimToDec
    jmp .InsertOk
.InsertCompat:
    push rax
    call Compatible
    pop rcx
    cmp rax, rcx
    jne TypeError
    jmp .InsertOk
.InsertAny:
    test rdx, rdx
    jz TypeError
    mov rax, [rsp]
    test rax, rax
    jz .InsertOk
    mov rcx, rdx
    call ListOf
    mov rdx, rax
    mov rcx, [rsp]
    call SetTypeOf
.InsertOk:
    Expect ")", ErrParen
    call Advance
    add rsp, 16
    call FileZero
    jz .InsertPlain
    CompilePrim PrimSwap
    CompileNum 1
    CompilePrim PrimAdd
    CompilePrim PrimSwap
.InsertPlain:
    CompilePrim PrimListInsert
    SetType TNone
    ret
.MethodDone:
    mov qword [rel LastVarRef], 0
    jmp .Post
.Join:
    mov rax, [rel ExprType]
    push rax
    call KindOfType
    pop rcx
    cmp rax, KList
    jne .TryMethod
    call ElemOf
    cmp rax, TText
    jne .TryMethod
    call Advance
    Expect "(", ErrParen
    call Advance
    IfTok ")", .JoinEmpty
    call ParseExpr
    NeedType TText
    Expect ")", ErrParen
    jmp .JoinEmit
.JoinEmpty:
    mov rcx, [rel TokPtr]
    xor edx, edx
    call CompileText
.JoinEmit:
    call Advance
    CompilePrim PrimJoin
    SetType TText
    jmp .MethodDone
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
    je .TryMethod
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
    cmp qword [rel ExprType], TText
    je .TextLength
    CompilePrim PrimLength
    SetType TNum
    mov qword [rel LastVarRef], 0
    call Advance
    jmp .Post
.TextLength:
    CompilePrim PrimTextLength
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
    mov rcx, [rel ExprType]
    call KeyOf
    mov rcx, rax
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
    mov rcx, [rsp + 8]
    call ElemOf
    push rax
    push rax
    call SetHint
    call ParseExpr
    pop rax
    pop rax
    call CoerceElem
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

SliceCheck:
    mov rax, [rel Here]
    lea rcx, [rel PrimRange]
    cmp [rax - 8], rcx
    jne .No
    mov rax, [rel ExprType]
    call KindOfType
    cmp rax, KList
    jne .No
    sub qword [rel Here], 8
    mov eax, 1
    ret
.No:
    xor eax, eax
    ret

NeedList:
    mov rax, [rel ExprType]
    call KindOfType
    cmp rax, KList
    jne TypeError
    ret

EmptyParens:
    call Advance
    IfTok "(", .Open
    ret
.Open:
    call Advance
    Expect ")", ErrParen
    jmp Advance
