StmtExpr:
    push rcx
    mov [rel StmtStart], r12
    mov rax, [rel Here]
    mov [rel StmtHere], rax
    mov [rel PrevTokPtr], r12
    mov [rel TokPtr], r12
    mov [rel TokLen], r13
    mov qword [rel VoidCall], 0
    call ParseExpr
    IfTok ",", .Multi
    IfTok ":", .TypeHint
    IfTok "=", .Assign
    IfTok "+=", .Assign
    IfTok "-=", .Assign
    IfTok "*=", .Assign
    IfTok "/=", .Assign
    pop rcx
    cmp qword [rel ExprType], TNone
    jne .HasValue
    cmp qword [rel VoidCall], 2
    je .Drop
    jmp .Done
.HasValue:
    test rcx, rcx
    jz .Drop
    cmp qword [rel FileMode], 0
    jne .Drop
    cmp qword [rel VoidCall], 0
    jne .Drop
    call EmitSay
    jmp .Done
.Drop:
    CompilePrim PrimDrop
.Done:
    jmp Pushback
.Assign:
    pop rcx
    mov rax, [rel StmtHere]
    mov [rel Here], rax
    mov rcx, [rel StmtStart]
    call Unread
    jmp AssignStmt
.TypeHint:
    Fail ErrTypeOnSet
.Multi:
    pop rcx
    mov rax, [rel StmtHere]
    mov [rel Here], rax
    mov rcx, [rel StmtStart]
    call Unread
    call Advance
    xor ecx, ecx
    jmp MultiAssign

SayWord:
    call Advance
    call ParseExpr
    call EmitSay
    jmp Pushback

FuseIncrement:
    mov r8, [rel Here]
    mov r9, [rel CompoundHere]
    mov rax, r8
    sub rax, r9
    cmp rax, 40
    jne .No
    lea rcx, [rel PrimLit]
    cmp [r9 + 16], rcx
    je .LitOk
    lea rcx, [rel F_Lit_PrimAdd]
    cmp [r9 + 16], rcx
    je .LitOk
    lea rcx, [rel F_Lit_PrimSub]
    cmp [r9 + 16], rcx
    jne .No
.LitOk:
    mov rdx, [r9 + 32]
    lea rcx, [rel PrimAdd]
    cmp rdx, rcx
    je .Add
    lea rcx, [rel PrimSub]
    cmp rdx, rcx
    jne .No
    mov rax, [r9 + 24]
    neg rax
    jmp .Have
.Add:
    mov rax, [r9 + 24]
.Have:
    mov rdx, [r9]
    lea rcx, [rel PrimGetG]
    cmp rdx, rcx
    je .Global
    lea rcx, [rel F_GetG_Lit_PrimAdd]
    cmp rdx, rcx
    je .Global
    lea rcx, [rel F_GetG_Lit_PrimSub]
    cmp rdx, rcx
    je .Global
    lea rcx, [rel F_LocalGet_Lit_PrimAdd]
    cmp rdx, rcx
    je .LocalInc
    lea rcx, [rel F_LocalGet_Lit_PrimSub]
    cmp rdx, rcx
    je .LocalInc
    lea rcx, [rel PrimLocalGet]
    cmp rdx, rcx
    jne .No
.LocalInc:
    lea rcx, [rel PrimIncL]
    jmp .Write
.Global:
    lea rcx, [rel PrimIncG]
.Write:
    mov [r9], rcx
    mov [r9 + 16], rax
    add r9, 24
    mov [rel Here], r9
    mov eax, 1
    ret
.No:
    xor eax, eax
    ret

TakeForwardVar:
    xor eax, eax
    xor edx, edx
.Loop:
    cmp rdx, [rel ForwardVarCount]
    jae .No
    lea r8, [rel ForwardVars]
    cmp [r8 + rdx * 8], rcx
    je .Yes
    inc rdx
    jmp .Loop
.Yes:
    mov qword [r8 + rdx * 8], 0
    mov eax, 1
.No:
    ret

NoteForwardVar:
    mov rdx, [rel ForwardVarCount]
    cmp rdx, 256
    jae .Full
    lea r8, [rel ForwardVars]
    mov [r8 + rdx * 8], rax
    inc qword [rel ForwardVarCount]
.Full:
    ret

FailWord:
    call Advance
    call ParseExpr
    mov rax, [rel ExprType]
    call ToTextRaw
    CompilePrim PrimFail
    jmp Pushback

ByeWord:
    CompilePrim PrimBye
    ret

AssignStmt:
    call Advance
    call TryDotted
    test rax, rax
    jz .Plain
    cmp rdx, 5
    je .Const
    cmp rdx, 3
    jne .Unknown
    push rax
    call Advance
    jmp AssignTail
.Plain:
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call LookupVar
    test rax, rax
    jnz .Found
    cmp qword [rel InFn], 0
    je .Unknown
    cmp qword [rel PreScanActive], MaxPre
    jae .Unknown
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call TryForwardVar
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call LookupVar
    test rax, rax
    jz .Unknown
.Found:
    test rdx, rdx
    jnz .Const
    push rax
    call Advance
    jmp AssignTail
.Unknown:
    FailTok ErrNotExist
.Const:
    Fail ErrConst

ResolveLoopVar:
    cmp qword [rel InFn], 0
    jne .Local
    push rcx
    push rdx
    call LookupVar
    pop r8
    pop r9
    test rax, rax
    jz .NewGlobal
    test rdx, rdx
    jnz .Const
    ret
.NewGlobal:
    mov rcx, r9
    mov rdx, r8
    jmp CreateVar
.Local:
    push rcx
    push rdx
    call FindLocal
    pop rdx
    pop rcx
    test rax, rax
    jz AddLocal
    mov r8, rax
    shr r8, 3
    lea r9, [rel LocalConst]
    cmp qword [r9 + r8 * 8], 0
    jne .Const
    ret
.Const:
    Fail ErrConst

KeepWord:
    mov qword [rel MakingConst], 1

SetWord:
    call Advance
    cmp qword [rel TokLen], 0
    je .Bad
    call IsNameStart
    test eax, eax
    jz .BadName
    push qword [rel TokPtr]
    push qword [rel TokLen]
    call Advance
    IfTok ",", .Multi
    IfTok "[", .Existing
    IfTok ".", .Existing
    mov rcx, [rsp + 8]
    mov rdx, [rsp]
    cmp qword [rel InFn], 0
    jne .InFunction
    call LookupVar
    jmp .Resolved
.InFunction:
    call FindLocal
    xor edx, edx
    test rax, rax
    jz .Resolved
    mov r8, rax
    shr r8, 3
    lea r9, [rel LocalConst]
    mov rdx, [r9 + r8 * 8]
.Resolved:
    test rax, rax
    jz .Create
    push rax
    push rdx
    mov rcx, rax
    call TakeForwardVar
    mov rcx, rax
    pop rdx
    pop rax
    test rcx, rcx
    jnz .Have
    cmp qword [rel MakingConst], 0
    jne .Exists
    test rdx, rdx
    jnz .Const
    mov rcx, [rsp + 8]
    mov [rel ReplacePtr], rcx
    mov rcx, [rsp]
    mov [rel ReplaceLen], rcx
    jmp .Have
.Create:
    push qword [rel TokPtr]
    push qword [rel TokLen]
    mov rax, [rsp + 24]
    mov [rel TokPtr], rax
    mov rax, [rsp + 16]
    mov [rel TokLen], rax
    call IsReserved
    test eax, eax
    jnz .BadName
    cmp qword [rel InFn], 0
    jne .NameOk
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call FindWord
    test rax, rax
    jz .NameOk
    cmp rdx, 3
    je .NameOk
    cmp rdx, 5
    jne .BadName
.NameOk:
    pop qword [rel TokLen]
    pop qword [rel TokPtr]
    mov rcx, [rsp + 8]
    mov rdx, [rsp]
    call NewVar
    cmp qword [rel MakingConst], 0
    je .Have
    call MarkConst
.Have:
    add rsp, 16
    mov qword [rel MakingConst], 0
    push rax
    jmp AssignTail
.Existing:
    mov rcx, [rsp + 8]
    mov rdx, [rsp]
    call LookupVar
    test rax, rax
    jz .Missing
    test rdx, rdx
    jnz .Const
    add rsp, 16
    push rax
    jmp AssignTail
.Missing:
    mov rax, [rsp + 8]
    mov [rel TokPtr], rax
    mov rax, [rsp]
    mov [rel TokLen], rax
    FailTok ErrNotExist
.Multi:
    cmp qword [rel MakingConst], 0
    jne .Bad
    pop rax
    pop rcx
    call Unread
    call Advance
    mov ecx, 1
    jmp MultiAssign
.Bad:
    Fail ErrSet
.BadName:
    FailTok ErrSetName
.Const:
    Fail ErrConst
.Exists:
    Fail ErrKeepExists

AssignTail:
    mov rax, [rel ReplacePtr]
    mov [rel CurReplacePtr], rax
    mov rax, [rel ReplaceLen]
    mov [rel CurReplaceLen], rax
    mov qword [rel ReplaceLen], 0
    mov qword [rel ReplaceType], 0
    IfTok "[", .Path
    IfTok ".", .Path
    IfTok ":", .Type
    jmp .Op
.Type:
    call Advance
    call ParseTypeName
    push rax
    mov rcx, [rsp + 8]
    call TypeOf
    pop rdx
    test rax, rax
    jz .Declare
    cmp rax, rdx
    je .Declare
    cmp qword [rel CurReplaceLen], 0
    je TypeError
    mov [rel ReplaceType], rdx
    call Advance
    jmp .Op
.Declare:
    mov rcx, [rsp]
    call SetTypeOf
    call Advance
    cmp qword [rel TokLen], 0
    je .DefaultValue
    call SameLine
    test eax, eax
    jz .DefaultValue
.Op:
    IfTok "=", .Assign
    IfTok "+=", .AddAssign
    IfTok "-=", .SubAssign
    IfTok "*=", .MulAssign
    IfTok "/=", .DivAssign
    IfTok "==", .DoubleEq
    Fail ErrSet
.DoubleEq:
    Fail ErrDoubleEq
.DefaultValue:
    mov rcx, [rsp]
    call TypeOf
    cmp rax, TNum
    je .DefaultZero
    cmp rax, TBool
    je .DefaultZero
    cmp rax, TDec
    je .DefaultZero
    cmp rax, TText
    je .DefaultText
    push rax
    call KindOfType
    pop rcx
    cmp rax, KList
    je .DefaultList
    cmp rax, KMap
    je .DefaultMap
    cmp rax, KEnum
    je .DefaultKind
    cmp rax, KUnion
    je .DefaultZero
    Fail ErrNeedValue
.DefaultZero:
    CompileNum 0
    jmp .Store
.DefaultKind:
    CompileNum 1
    jmp .Store
.DefaultText:
    mov rcx, [rel TokPtr]
    xor edx, edx
    call CompileText
    jmp .Store
.DefaultList:
    CompileNum 0
    CompilePrim PrimMakeList
    jmp .Store
.DefaultMap:
    CompileNum 0
    CompilePrim PrimMakeMap
    jmp .Store
.Assign:
    mov rcx, [rsp]
    call TryAppendAssign
    test eax, eax
    jz .NotAppend
    pop rcx
    jmp Pushback
.NotAppend:
    mov rax, [rel ReplaceType]
    test rax, rax
    jnz .AssignHint
    mov rcx, [rsp]
    call TypeOf
.AssignHint:
    call SetHint
    call Advance
    call ParseExpr
    mov rcx, [rsp]
    call NarrowOf
    test rax, rax
    jz .KeepNarrow
    mov rdx, [rel ExprType]
    cmp rax, rdx
    je .KeepNarrow
    cmp rax, TDec
    jne .UnNarrow
    cmp rdx, TNum
    je .KeepNarrow
.UnNarrow:
    mov rcx, [rsp]
    call UnNarrow
.KeepNarrow:
    mov rax, [rel ReplaceType]
    test rax, rax
    jnz .Coerce
    mov rcx, [rsp]
    call TypeOf
.Coerce:
    call CoerceTo
    mov rax, [rel ReplaceType]
    test rax, rax
    jz .NoDeclared
    mov rdx, [rel ExprType]
    cmp rax, rdx
    je .Fresh
    cmp rax, TDec
    jne .DeclaredCompat
    cmp rdx, TNum
    jne TypeError
    CompilePrim PrimToDec
    jmp .Fresh
.DeclaredCompat:
    push rax
    call Compatible
    pop rcx
    cmp rax, rcx
    jne TypeError
    jmp .Fresh
.NoDeclared:
    mov rcx, [rsp]
    call TypeOf
    mov rdx, [rel ExprType]
    cmp rax, TDec
    jne .AssignCheck
    cmp rdx, TNum
    jne .AssignCheck
    CompilePrim PrimToDec
    jmp .Store
.AssignCheck:
    push rax
    call Compatible
    pop rcx
    test rax, rax
    jz .Replace
    cmp rax, rcx
    jne .NotSame
    call WarnReset
    jmp .Store
.NotSame:
    mov rdx, rax
    mov rcx, [rsp]
    call SetTypeOf
    jmp .Store
.Replace:
    cmp qword [rel CurReplaceLen], 0
    je .ChangeType
    mov rax, [rel ExprType]
    mov [rel ReplaceType], rax
.Fresh:
    mov rcx, [rsp]
    call UsedByFunction
    test eax, eax
    jnz .UsedElsewhere
    mov rcx, [rel CurReplacePtr]
    mov rdx, [rel CurReplaceLen]
    call NewVar
    mov [rsp], rax
    mov rcx, rax
    mov rdx, [rel ReplaceType]
    call SetTypeOf
    jmp .Store
.UsedElsewhere:
    Fail ErrTypeUsed
.AddAssign:
    mov rcx, [rsp]
    call TypeOf
    test rax, rax
    jz .NewCompound
    cmp rax, TText
    je .Append
    lea rbx, [rel PrimAdd]
    lea rsi, [rel PrimDAdd]
    jmp .Compound
.SubAssign:
    lea rbx, [rel PrimSub]
    lea rsi, [rel PrimDSub]
    jmp .Compound
.MulAssign:
    lea rbx, [rel PrimMul]
    lea rsi, [rel PrimDMul]
    jmp .Compound
.DivAssign:
    xor ebx, ebx
    lea rsi, [rel PrimDDiv]
.Compound:
    push rsi
    push rbx
    mov rcx, [rsp + 16]
    call TypeOf
    test rax, rax
    jz .NewCompound
    mov rax, [rel Here]
    mov [rel CompoundHere], rax
    mov rcx, [rsp + 16]
    call EmitLoad
    mov rcx, [rsp + 16]
    call TypeOf
    push rax
    call Advance
    call ParseExpr
    pop rax
    call NumericPair
    pop rbx
    pop rsi
    test rbx, rbx
    jnz .Pick
    cmp rax, TDec
    je .Pick
    CompilePrim PrimToDec
    CompilePrim PrimToDecUnder
    mov eax, TDec
.Pick:
    mov rcx, rbx
    cmp rax, TDec
    jne .Emit
    mov rcx, rsi
.Emit:
    push rax
    call Compile
    mov rcx, [rsp + 8]
    call TypeOf
    pop rdx
    cmp rax, rdx
    jne TypeError
    cmp rax, TNum
    jne .Store
    call FuseIncrement
    test eax, eax
    jz .Store
    add rsp, 8
    jmp Pushback
.NewCompound:
    Fail ErrCompoundNew
.ChangeType:
    Fail ErrChangeType
.Append:
    mov rcx, [rsp]
    call CanAppend
    test eax, eax
    jz .SlowAppend
    call Advance
    call ParseExpr
    mov rax, [rel ExprType]
    call ToTextRaw
    mov rcx, [rsp]
    call EmitAppend
    pop rcx
    jmp Pushback
.SlowAppend:
    mov rcx, [rsp]
    call EmitLoad
    call Advance
    call ParseExpr
    mov rax, [rel ExprType]
    call ToTextRaw
    CompilePrim PrimConcat
.Store:
    mov rcx, [rsp]
    call MarkNumberList
    pop rcx
    push rcx
    push rcx
    xor edx, edx
    mov rax, [rel LastFnValHere]
    cmp rax, [rel Here]
    jne .NoSig
    mov rdx, [rel LastFnValSig]
.NoSig:
    call RecordVarSig
    pop rcx
    pop rcx
    call EmitStore
    jmp Pushback
.Path:
    mov rcx, [rsp]
    call EmitLoad
    mov rcx, [rsp]
    call TypeOf
    mov [rel PathType], rax
    mov rax, [rsp]
    mov [rel PathRef], rax
    mov qword [rel PathDepth], 0
.Step:
    IfTok "[", .PathIndex
    IfTok ".", .PathField
    Fail ErrSet
.PathIndex:
    mov qword [rel PathIsField], 0
    mov rax, [rel PathType]
    call KindOfType
    cmp rax, KList
    je .PathList
    cmp rax, KMap
    je .PathMap
    jmp TypeError
.PathList:
    mov qword [rel PathKey], TNum
    lea rax, [rel PrimIndex]
    mov [rel PathGet], rax
    lea rax, [rel PrimSetIndex]
    mov [rel PathSet], rax
    jmp .PathKeyParse
.PathMap:
    mov rcx, [rel PathType]
    call KeyOf
    mov [rel PathKey], rax
    cmp rax, TText
    je .PathTextKey
    lea rax, [rel PrimMapGetInt]
    mov [rel PathGet], rax
    lea rax, [rel PrimMapSetInt]
    mov [rel PathSet], rax
    jmp .PathKeyParse
.PathTextKey:
    lea rax, [rel PrimMapGet]
    mov [rel PathGet], rax
    lea rax, [rel PrimMapSet]
    mov [rel PathSet], rax
.PathKeyParse:
    call Advance
    call ParseExpr
    mov rax, [rel PathKey]
    cmp [rel ExprType], rax
    jne TypeError
    lea rax, [rel PrimIndex]
    cmp [rel PathGet], rax
    jne .PathKeyDone
    call EmitIndexFix
.PathKeyDone:
    Expect "]", ErrBracket
    call Advance
    mov rcx, [rel PathType]
    call ElemOf
    mov [rel PathElem], rax
    call PathFinalOp
    test eax, eax
    jnz .PathFinal
    mov rcx, [rel PathGet]
    call Compile
    mov rax, [rel PathElem]
    mov [rel PathType], rax
    inc qword [rel PathDepth]
    jmp .Step
.PathField:
    mov rax, [rel PathType]
    call KindOfType
    cmp rax, KRec
    jne TypeError
    call Advance
    mov rcx, [rel PathType]
    mov rdx, [rel TokPtr]
    mov r8, [rel TokLen]
    call FindField
    cmp rax, -1
    je .NoField
    mov [rel PathElem], rdx
    shl rax, 3
    mov [rel PathOffset], rax
    lea rax, [rel PrimGetField]
    mov [rel PathGet], rax
    lea rax, [rel PrimSetField]
    mov [rel PathSet], rax
    mov qword [rel PathIsField], 1
    call Advance
    call PathFinalOp
    test eax, eax
    jnz .PathFinal
    CompilePrim PrimGetField
    mov rcx, [rel PathOffset]
    call Compile
    mov rax, [rel PathElem]
    mov [rel PathType], rax
    inc qword [rel PathDepth]
    jmp .Step
.NoField:
    FailTok ErrNoField
.PathFinal:
    cmp qword [rel PathOp], 1
    jne .PathCompound
    call Advance
    mov rax, [rel PathElem]
    call SetHint
    call ParseExpr
    mov rax, [rel PathElem]
    test rax, rax
    jz .PathNoCoerce
    call CoerceTo
.PathNoCoerce:
    mov rax, [rel PathElem]
    mov rdx, [rel ExprType]
    test rdx, rdx
    jz TypeError
    test rax, rax
    jz .PathUnknown
    cmp rax, rdx
    je .PathEmit
    cmp rax, TDec
    jne .PathCompat
    cmp rdx, TNum
    jne TypeError
    CompilePrim PrimToDec
    jmp .PathEmit
.PathCompat:
    push rax
    call Compatible
    pop rcx
    cmp rax, rcx
    jne TypeError
    jmp .PathEmit
.PathUnknown:
    cmp qword [rel PathDepth], 0
    jne TypeError
    push rdx
    mov rax, [rel PathType]
    call KindOfType
    pop rcx
    cmp rax, KList
    je .PathNewList
    call MapOf
    jmp .PathSetType
.PathNewList:
    call ListOf
.PathSetType:
    mov rdx, rax
    mov rcx, [rel PathRef]
    call SetTypeOf
.PathEmit:
    mov rcx, [rel PathSet]
    call Compile
    cmp qword [rel PathIsField], 0
    je .PathDone
    mov rcx, [rel PathOffset]
    call Compile
.PathDone:
    pop rax
    jmp Pushback
.PathCompound:
    cmp qword [rel PathIsField], 0
    jne .CompoundField
    CompilePrim PrimDup2
    mov rcx, [rel PathGet]
    call Compile
    jmp .CompoundGot
.CompoundField:
    CompilePrim PrimDup
    CompilePrim PrimGetField
    mov rcx, [rel PathOffset]
    call Compile
.CompoundGot:
    mov rax, [rel PathElem]
    cmp rax, TText
    jne .CompoundNumber
    cmp qword [rel PathOp], 2
    jne TypeError
    call Advance
    call ParseExpr
    mov rax, [rel ExprType]
    call ToTextRaw
    CompilePrim PrimConcat
    jmp .PathEmit
.CompoundNumber:
    push rax
    call Advance
    call ParseExpr
    mov rax, [rsp]
    call NumericPair
    pop rcx
    cmp rax, rcx
    jne TypeError
    lea rcx, [rel PrimAdd]
    lea rdx, [rel PrimDAdd]
    cmp qword [rel PathOp], 2
    je .CompoundPick
    lea rcx, [rel PrimSub]
    lea rdx, [rel PrimDSub]
.CompoundPick:
    cmp rax, TDec
    jne .CompoundEmit
    mov rcx, rdx
.CompoundEmit:
    call Compile
    jmp .PathEmit

PathFinalOp:
    IfTok "=", .Set
    IfTok "+=", .Add
    IfTok "-=", .Sub
    xor eax, eax
    ret
.Set:
    mov qword [rel PathOp], 1
    mov eax, 1
    ret
.Add:
    mov qword [rel PathOp], 2
    mov eax, 1
    ret
.Sub:
    mov qword [rel PathOp], 3
    mov eax, 1
    ret

CanAppend:
    xor eax, eax
    test rcx, 4
    jnz .No
    test rcx, 2
    jnz .Local
    lea r8, [rel DataSpace]
    cmp rcx, r8
    jb .No
    cmp rcx, [rel DataHere]
    jae .No
    cmp qword [rcx - 8], TText
    jne .No
    mov eax, 1
.No:
    ret
.Local:
    mov r8, rcx
    shr r8, 3
    lea r9, [rel LocalType]
    cmp qword [r9 + r8 * 8], TText
    jne .No
    mov eax, 1
    ret

EmitAppend:
    push rcx
    push rcx
    test rcx, 2
    jnz .Local
    call MarkGlobalUse
    CompilePrim PrimAppendG
    pop rcx
    pop rcx
    jmp Compile
.Local:
    CompilePrim PrimAppendL
    pop rcx
    pop rcx
    and rcx, -8
    jmp Compile

[section .data]
PlusText db "+"
__SECT__

TryAppendAssign:
    sub rsp, 40
    mov [rsp + 8], rcx
    xor eax, eax
    cmp qword [rel CurReplaceLen], 0
    jne .Out
    cmp qword [rel ReplaceType], 0
    jne .Out
    call CanAppend
    test eax, eax
    jz .Out
    call Advance
    mov rax, [rel TokPtr]
    mov [rsp + 16], rax
    mov rcx, rax
    mov rdx, [rel TokLen]
    test rdx, rdx
    jz .Restore
    call LookupVar
    cmp rax, [rsp + 8]
    jne .Restore
    mov rax, [rel TokPtr]
    add rax, [rel TokLen]
    movzx eax, byte [rax]
    cmp al, '.'
    je .Restore
    cmp al, '['
    je .Restore
    cmp al, '('
    je .Restore
    call Advance
    IfTok "+", .Plus
    jmp .Restore
.Plus:
    call Advance
    mov rax, [rel TokPtr]
    mov [rsp + 24], rax
    mov qword [rsp], 0
.Scan:
    cmp qword [rel TokLen], 0
    je .ScanEnd
    mov rax, [rel TokPtr]
    cmp rax, [rsp + 24]
    je .First
    cmp qword [rsp], 0
    jne .Depth
    call SameLine
    test eax, eax
    jz .ScanEnd
.First:
    cmp qword [rsp], 0
    jne .Depth
    IfTok "+", .Restore
    IfTok "-", .Restore
    IfTok "==", .Restore
    IfTok "!=", .Restore
    IfTok "<", .Restore
    IfTok ">", .Restore
    IfTok "<=", .Restore
    IfTok ">=", .Restore
    IfTok "and", .Restore
    IfTok "or", .Restore
    IfTok "xor", .Restore
    IfTok "if", .Restore
    IfTok "otherwise", .Restore
    IfTok "is", .Restore
    IfTok "in", .Restore
    IfTok "..", .Restore
    IfTok "|>", .Restore
    IfTok "&", .Restore
    IfTok "|", .Restore
    IfTok "<<", .Restore
    IfTok ">>", .Restore
    IfTok "not", .Restore
    IfTok "for", .Restore
.Depth:
    IfTok "(", .Open
    IfTok "[", .Open
    IfTok "{", .Open
    IfTok ")", .Close
    IfTok "]", .Close
    IfTok "}", .Close
    jmp .ScanNext
.Open:
    inc qword [rsp]
    jmp .ScanNext
.Close:
    dec qword [rsp]
.ScanNext:
    call Advance
    jmp .Scan
.ScanEnd:
    mov rcx, [rsp + 24]
    call Unread
    call Advance
    call ParseProduct
    mov rax, [rel ExprType]
    cmp rax, TDec
    ja .Stack
    call ToTextRaw
    mov rcx, [rsp + 8]
    call EmitAppend
    mov eax, 1
    jmp .Out
.Stack:
    mov [rsp + 32], rax
    mov rcx, [rsp + 8]
    call EmitLoad
    CompilePrim PrimSwap
    mov rax, [rsp + 32]
    mov [rel ExprType], rax
    mov eax, TText
    mov rdx, [rel ExprType]
    lea rcx, [rel PlusText]
    mov r8d, 1
    call TryOverload
    test eax, eax
    jnz .Overloaded
    mov rax, [rel ExprType]
    call ToTextRaw
    CompilePrim PrimConcat
    mov qword [rel ExprType], TText
.Overloaded:
    cmp qword [rel ExprType], TText
    jne TypeError
    mov rcx, [rsp + 8]
    call EmitStore
    mov eax, 1
    jmp .Out
.Restore:
    mov rcx, [rsp + 16]
    call Unread
    xor eax, eax
.Out:
    add rsp, 40
    ret

MarkNumberList:
    call TypeOf
    test rax, rax
    jz .No
    push rax
    push rax
    mov rcx, rax
    call TypeKind
    pop rcx
    pop rcx
    cmp rax, KList
    jne .No
    call ElemOf
    cmp rax, TNum
    je .Yes
    cmp rax, TDec
    je .Yes
    cmp rax, TBool
    je .Yes
    test rax, rax
    jz .No
    mov rcx, rax
    call TypeKind
    cmp rax, KEnum
    jne .No
.Yes:
    CompilePrim PrimNoPtrs
.No:
    ret

UsedByFunction:
    xor eax, eax
    cmp qword [rel CurReplaceLen], 0
    je .Done
    test rcx, 6
    jnz .Done
    lea r8, [rel DataSpace]
    cmp rcx, r8
    jb .Done
    cmp rcx, [rel DataHere]
    jae .Done
    mov rax, [rcx - 16]
.Done:
    ret

WarnReset:
    cmp qword [rel CurReplaceLen], 0
    je .Done
    mov rax, [rel OpenBlocks]
    cmp qword [rel InFn], 0
    je .Level
    dec rax
.Level:
    test rax, rax
    jnz .Done
    push rcx
    lea rcx, [rel WarnSetAgain]
    mov edx, WarnSetAgainLen
    mov r8, [rel CurReplacePtr]
    mov r9, [rel CurReplaceLen]
    call Warn
    pop rcx
.Done:
    ret

VarSigKey:
    xor eax, eax
    test rcx, 6
    jz .Global
    mov rax, [rel CurFnId]
    inc rax
.Global:
    ret

RecordVarSig:
    push rbx
    call VarSigKey
    lea r8, [rel VarSigTab]
    xor ebx, ebx
.Find:
    cmp rbx, [rel VarSigCount]
    jae .New
    mov r9, rbx
    imul r9, r9, 24
    cmp [r8 + r9], rax
    jne .Next
    cmp [r8 + r9 + 8], rcx
    jne .Next
    mov [r8 + r9 + 16], rdx
    jmp .Done
.Next:
    inc rbx
    jmp .Find
.New:
    test rdx, rdx
    jz .Done
    cmp rbx, 1024
    jae .Done
    imul r9, rbx, 24
    mov [r8 + r9], rax
    mov [r8 + r9 + 8], rcx
    mov [r8 + r9 + 16], rdx
    inc qword [rel VarSigCount]
.Done:
    pop rbx
    ret

FindVarSig:
    push rbx
    call VarSigKey
    lea r8, [rel VarSigTab]
    xor ebx, ebx
.Find:
    cmp rbx, [rel VarSigCount]
    jae .None
    imul r9, rbx, 24
    cmp [r8 + r9], rax
    jne .Next
    cmp [r8 + r9 + 8], rcx
    jne .Next
    mov rax, [r8 + r9 + 16]
    pop rbx
    ret
.Next:
    inc rbx
    jmp .Find
.None:
    xor eax, eax
    pop rbx
    ret

FileZero:
    mov rax, [rel CurFile]
    cmp rax, 256
    jae .No
    lea rcx, [rel FileZeroTab]
    cmp byte [rcx + rax], 0
    ret
.No:
    cmp eax, eax
    ret

EmitIndexFix:
    call FileZero
    jz .Done
    CompileNum 1
    CompilePrim PrimAdd
.Done:
    ret

EmitSliceFix:
    call FileZero
    jz .Done
    CompileNum 1
    CompilePrim PrimAdd
    CompilePrim PrimSwap
    CompileNum 1
    CompilePrim PrimAdd
    CompilePrim PrimSwap
.Done:
    ret

SettingWord:
    call Advance
    IfTok "lists", .Lists
    Fail ErrSetting
.Lists:
    call Advance
    Expect "start", ErrSetting
    call Advance
    Expect "at", ErrSetting
    call Advance
    IfTok "0", .Zero
    IfTok "1", .One
    Fail ErrSetting
.Zero:
    mov al, 1
    jmp .Store
.One:
    xor eax, eax
.Store:
    mov rcx, [rel CurFile]
    cmp rcx, 256
    jae .Done
    lea rdx, [rel FileZeroTab]
    mov [rdx + rcx], al
.Done:
    call Advance
    jmp Pushback
