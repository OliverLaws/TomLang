[section .data]
SelfName db "self"
NameNum db "number"
NameDec db "decimal"
NameText db "text"
NameBool db "bool"
__SECT__

[section .bss]
MethodSelf resq 1
OpMode resq 1
OpBuf resb 64
CompStack resq 1
__SECT__

TypeNameOf:
    cmp rcx, TNum
    je .Num
    cmp rcx, TDec
    je .Dec
    cmp rcx, TText
    je .Text
    cmp rcx, TBool
    je .Bool
    test rcx, rcx
    jz .None
    mov rax, rcx
    shl rax, 5
    lea rdx, [rel TypeTable]
    add rax, rdx
    mov r8, [rax]
    cmp r8, KRec
    je .Named
    cmp r8, KEnum
    je .Named
    cmp r8, KIface
    jne .None
.Named:
    mov rax, [rax + 8]
    test rax, rax
    jz .None
    movzx edx, byte [rax + 17]
    lea rax, [rax + 18]
    ret
.Num:
    lea rax, [rel NameNum]
    mov edx, 6
    ret
.Dec:
    lea rax, [rel NameDec]
    mov edx, 7
    ret
.Text:
    lea rax, [rel NameText]
    mov edx, 4
    ret
.Bool:
    lea rax, [rel NameBool]
    mov edx, 4
    ret
.None:
    xor eax, eax
    ret

FindMethod:
    push rbx
    push rsi
    push rdi
    push r12
    sub rsp, 264
    mov r12, rdx
    mov rbx, r8
    call TypeNameOf
    test rax, rax
    jz .No
    lea r10, [rdx + rbx + 1]
    cmp r10, 250
    ja .No
    mov [rsp + 256], r10
    mov rdi, rsp
    mov rsi, rax
    mov rcx, rdx
    rep movsb
    mov byte [rdi], '.'
    inc rdi
    mov rsi, r12
    mov rcx, rbx
    rep movsb
    mov rcx, rsp
    mov rdx, [rsp + 256]
    call FindWord
    test rax, rax
    jnz .Found
    cmp qword [rel PreScanActive], MaxPre
    jae .No
    mov rcx, rsp
    mov rdx, [rsp + 256]
    mov r8, [rel NamePrefixLen]
    test r8, r8
    jz .Fwd
    cmp rdx, r8
    jbe .Fwd
    mov rsi, [rel NamePrefixPtr]
    xor r9d, r9d
.Pre:
    cmp r9, r8
    jae .Strip
    mov al, [rsi + r9]
    cmp al, [rcx + r9]
    jne .Fwd
    inc r9
    jmp .Pre
.Strip:
    add rcx, r8
    sub rdx, r8
.Fwd:
    call TryForward
    mov rcx, rsp
    mov rdx, [rsp + 256]
    call FindWord
    test rax, rax
    jz .No
.Found:
    cmp rdx, 4
    je .Out
    cmp rdx, 7
    je .Out
.No:
    xor eax, eax
.Out:
    add rsp, 264
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

RecvCall:
    mov [rel RecvType], rcx
    jmp ParsePrimary.CallSetup

WordCall:
    xor r9d, r9d
    cmp rdx, 4
    je .Go
    mov r9d, 1
    cmp rdx, 7
    jne .Bad
.Go:
    push rax
    push r9
    push rcx
    call Advance
    mov qword [rel RecvBare], 0
    IfTok "(", .Paren
    mov qword [rel RecvBare], 1
.Paren:
    pop rcx
    pop r9
    pop rax
    jmp RecvCall
.Bad:
    Fail ErrPipe

PipeTarget:
    push rbx
    mov rbx, rcx
    cmp qword [rel TokLen], 0
    je .Bad
    call TryDotted
    test rax, rax
    jnz .Word
    IfTok "text", .ToText
    IfTok "number", .ToNumber
    IfTok "decimal", .ToDecimal
    IfTok "round", .Round
    call IsNameStart
    test eax, eax
    jz .Bad
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call LookupVar
    test rax, rax
    jnz .Value
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call FindWord
    test rax, rax
    jnz .Word
    cmp qword [rel PreScanActive], MaxPre
    jae .Bad
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call TryForward
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call FindWord
    test rax, rax
    jz .Bad
.Word:
    mov rcx, rbx
    pop rbx
    jmp WordCall
.Bad:
    pop rbx
    Fail ErrPipe
.ToText:
    mov rax, rbx
    call ToTextRaw
    SetType TText
    jmp .Out
.ToNumber:
    mov [rel ExprType], rbx
    cmp rbx, TNum
    je .NumDone
    cmp rbx, TDec
    je .NumDec
    NeedType TText
    CompilePrim PrimToNumber
    jmp .NumDone
.NumDec:
    CompilePrim PrimDecToNum
.NumDone:
    SetType TNum
    jmp .Out
.ToDecimal:
    mov [rel ExprType], rbx
    cmp rbx, TDec
    je .DecDone
    cmp rbx, TNum
    je .DecNum
    NeedType TText
    CompilePrim PrimTextToDec
    jmp .DecDone
.DecNum:
    CompilePrim PrimToDec
.DecDone:
    SetType TDec
    jmp .Out
.Round:
    mov [rel ExprType], rbx
    cmp rbx, TNum
    je .RoundDone
    NeedType TDec
    CompilePrim PrimRound
.RoundDone:
    SetType TNum
.Out:
    pop rbx
    jmp Advance
.Value:
    push rax
    mov rcx, rax
    call TypeOf
    push rax
    call KindOfType
    cmp rax, KFunc
    jne .NotFn
    mov rcx, [rsp]
    shl rcx, 5
    lea rax, [rel TypeTable]
    add rax, rcx
    cmp qword [rax + 16], 0
    je .Count
    mov rax, [rax + 24]
    mov rax, [rax]
    mov [rel ExprType], rbx
    call CheckArg
    mov rcx, [rsp + 8]
    call EmitLoad
    CompilePrim PrimSwap
    pop rcx
    add rsp, 8
    shl rcx, 5
    lea rax, [rel TypeTable]
    add rax, rcx
    push qword [rax + 8]
    push qword [rax + 16]
    push qword [rax + 24]
    push 1
    call Advance
    IfTok "(", .Args
    jmp .ArgsDone
.Args:
    call SameLine
    test eax, eax
    jz .ArgsDone
    call Advance
    IfTok ")", .ArgsClose
.ArgLoop:
    mov rax, [rsp]
    cmp rax, [rsp + 16]
    jae .Count
    mov rcx, [rsp + 8]
    mov rax, [rcx + rax * 8]
    call SetHint
    call ParseExpr
    mov rax, [rsp]
    mov rcx, [rsp + 8]
    mov rax, [rcx + rax * 8]
    call CheckArg
    inc qword [rsp]
    IfTok ",", .ArgComma
    Expect ")", ErrParen
.ArgsClose:
    call Advance
.ArgsDone:
    mov rax, [rsp]
    cmp rax, [rsp + 16]
    jne .Count
    CompilePrim PrimCallValue
    mov rcx, [rsp]
    call Compile
    add rsp, 24
    pop rax
    mov qword [rel VoidCall], 0
    test rax, rax
    jnz .ValType
    mov qword [rel VoidCall], 1
    mov eax, TNum
.ValType:
    mov [rel ExprType], rax
    pop rbx
    ret
.ArgComma:
    call Advance
    jmp .ArgLoop
.Count:
    Fail ErrArgs
.NotFn:
    add rsp, 16
    pop rbx
    Fail ErrPipe

MemberCall:
    push rbx
    mov rbx, [rel ExprType]
    mov rcx, rbx
    call TypeKind
    cmp rax, KIface
    je .Iface
    mov rcx, rbx
    mov rdx, [rel TokPtr]
    mov r8, [rel TokLen]
    call FindMethod
    test rax, rax
    jnz .Word
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call FindWord
    test rax, rax
    jnz .Plain
    cmp qword [rel PreScanActive], MaxPre
    jae .No
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    cmp byte [rcx + rdx], '('
    jne .No
    call TryForward
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call FindWord
    test rax, rax
    jz .No
.Plain:
    cmp rdx, 4
    je .Word
    cmp rdx, 7
    jne .No
.Word:
    mov rcx, rbx
    call WordCall
    mov eax, 1
    pop rbx
    ret
.No:
    xor eax, eax
    pop rbx
    ret
.Iface:
    mov rcx, rbx
    mov rdx, [rel TokPtr]
    mov r8, [rel TokLen]
    call FindField
    cmp rax, -1
    je .No
    push rax
    shl rdx, 5
    lea rax, [rel TypeTable]
    add rax, rdx
    push qword [rax + 8]
    push qword [rax + 16]
    push qword [rax + 24]
    push 0
    call Advance
    IfTok "(", .IArgs
    jmp .IDone
.IArgs:
    call SameLine
    test eax, eax
    jz .IDone
    call Advance
    IfTok ")", .IClose
.ILoop:
    mov rax, [rsp]
    cmp rax, [rsp + 16]
    jae .ICount
    mov rcx, [rsp + 8]
    mov rax, [rcx + rax * 8]
    call SetHint
    call ParseExpr
    mov rax, [rsp]
    mov rcx, [rsp + 8]
    mov rax, [rcx + rax * 8]
    call CheckArg
    inc qword [rsp]
    IfTok ",", .IComma
    Expect ")", ErrParen
.IClose:
    call Advance
.IDone:
    mov rax, [rsp]
    cmp rax, [rsp + 16]
    jne .ICount
    CompilePrim PrimIfaceCall
    mov rcx, [rsp + 32]
    call Compile
    mov rcx, [rsp]
    call Compile
    add rsp, 24
    pop rax
    add rsp, 8
    mov qword [rel VoidCall], 0
    test rax, rax
    jnz .IType
    mov qword [rel VoidCall], 1
    mov eax, TNum
.IType:
    mov [rel ExprType], rax
    mov eax, 1
    pop rbx
    ret
.IComma:
    call Advance
    jmp .ILoop
.ICount:
    Fail ErrArgs

RegisterType:
    push rbx
    push rsi
    push rdi
    mov rsi, rcx
    mov rdi, rdx
    mov rbx, r8
    mov ecx, 40
    call PermAlloc
    mov qword [rax], 0
    mov qword [rax + 8], 0
    mov qword [rax + 16], 0
    mov qword [rax + 24], 0
    mov [rax + 32], rbx
    push rax
    push rax
    mov rax, [rel Here]
    mov [rel FfiSavedHere], rax
    mov rax, [rel DictHere]
    mov [rel Here], rax
    mov rcx, rsi
    mov rdx, rdi
    call CreateEntry
    pop rcx
    pop rcx
    mov rax, [rel Latest]
    mov byte [rax + 16], 8
    mov [rax + 8], rcx
    mov rdx, rbx
    shl rdx, 5
    lea r8, [rel TypeTable]
    mov [r8 + rdx + 8], rax
    mov rax, [rel Here]
    mov [rel DictHere], rax
    mov rax, [rel FfiSavedHere]
    mov [rel Here], rax
    pop rdi
    pop rsi
    pop rbx
    ret

TypeDeclStart:
    cmp qword [rel InFn], 0
    jne .Where
    cmp qword [rel OpenBlocks], 0
    jne .Where
    call Advance
    call IsNameStart
    test eax, eax
    jz .BadName
    call IsReserved
    test eax, eax
    jnz .BadName
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call FindWord
    test rax, rax
    jnz .Taken
    ret
.Where:
    Fail ErrTypeWhere
.BadName:
    FailTok ErrKindName
.Taken:
    FailTok ErrKindTaken

RecordWord:
    call TypeDeclStart
    call NewPlaceholder
    push rax
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    mov r8, rax
    call RegisterType
    pop rax
    push rax
    push qword [rel TempTop]
    push 0
    push 0
    call Advance
    IfTok "=", .OneLine
    mov qword [rsp], 1
    jmp .Field
.OneLine:
    call Advance
.Field:
    call IsNameStart
    test eax, eax
    jz .Bad
    mov rax, [rsp + 8]
    cmp rax, 60
    jae .Many
    lea rax, [rax + rax * 2]
    mov rcx, [rsp + 16]
    lea r8, [rcx + rax * 8]
    mov rax, [rel TokPtr]
    mov [r8], rax
    mov rax, [rel TokLen]
    mov [r8 + 8], rax
    inc qword [rsp + 8]
    mov rax, [rsp + 8]
    lea rax, [rax + rax * 2]
    shl rax, 3
    add rax, [rsp + 16]
    mov [rel TempTop], rax
    push r8
    call TempRoom
    call Advance
    Expect ":", ErrRecordColon
    call Advance
    call ParseTypeName
    pop r8
    mov [r8 + 16], rax
    call Advance
    IfTok ",", .Comma
    cmp qword [rsp], 0
    je .Finish
    IfTok "end", .BlockEnd
    jmp .Field
.Comma:
    call Advance
    cmp qword [rsp], 0
    je .Field
    IfTok "end", .BlockEnd
    jmp .Field
.BlockEnd:
    call Advance
.Finish:
    mov rcx, [rsp + 8]
    mov rdx, [rsp + 16]
    call NewRecordType
    add rsp, 16
    pop rcx
    mov [rel TempTop], rcx
    pop rcx
    mov edx, 1
    call FillPlaceholder
    jmp Pushback
.Bad:
    Fail ErrRecordName
.Many:
    Fail ErrTooMany

InterfaceWord:
    call TypeDeclStart
    call NewPlaceholder
    push rax
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    mov r8, rax
    call RegisterType
    pop rax
    push rax
    push qword [rel TempTop]
    push 0
    push 0
    call Advance
    IfTok "=", .OneLine
    mov qword [rsp], 1
    jmp .Method
.OneLine:
    call Advance
.Method:
    call IsNameStart
    test eax, eax
    jz .Bad
    mov rax, [rsp + 8]
    cmp rax, 60
    jae .Many
    lea rax, [rax + rax * 2]
    mov rcx, [rsp + 16]
    lea r8, [rcx + rax * 8]
    mov rax, [rel TokPtr]
    mov [r8], rax
    mov rax, [rel TokLen]
    mov [r8 + 8], rax
    inc qword [rsp + 8]
    mov rax, [rsp + 8]
    lea rax, [rax + rax * 2]
    shl rax, 3
    add rax, [rsp + 16]
    mov [rel TempTop], rax
    push r8
    call TempRoom
    sub rsp, 136
    mov qword [rsp + 128], 0
    call Advance
    Expect "(", ErrParen
    call Advance
    IfTok ")", .Params
.PLoop:
    call IsNameStart
    test eax, eax
    jz .PType
    call PeekColon
    test eax, eax
    jz .PType
    call Advance
    call Advance
.PType:
    call ParseTypeName
    mov rcx, [rsp + 128]
    cmp rcx, 15
    jae .Many
    mov [rsp + rcx * 8], rax
    inc qword [rsp + 128]
    call Advance
    IfTok ",", .PNext
    Expect ")", ErrParen
    jmp .Params
.PNext:
    call Advance
    jmp .PLoop
.Params:
    call Advance
    xor ecx, ecx
    IfTok ":", .Ret
    jmp .Make
.Ret:
    call Advance
    call ParseTypeName
    push rax
    push rax
    call Advance
    pop rcx
    pop rcx
.Make:
    mov rdx, [rsp + 128]
    mov r8, rsp
    call FuncOf
    add rsp, 136
    pop r8
    mov [r8 + 16], rax
    IfTok ",", .Comma
    cmp qword [rsp], 0
    je .Finish
    IfTok "end", .BlockEnd
    jmp .Method
.Comma:
    call Advance
    cmp qword [rsp], 0
    je .Method
    IfTok "end", .BlockEnd
    jmp .Method
.BlockEnd:
    call Advance
.Finish:
    mov rcx, [rsp + 8]
    mov rdx, [rsp + 16]
    call NewRecordType
    push rax
    shl rax, 5
    lea rcx, [rel TypeTable]
    mov qword [rcx + rax], KIface
    pop rax
    add rsp, 16
    pop rcx
    mov [rel TempTop], rcx
    pop rcx
    mov edx, 1
    call FillPlaceholder
    jmp Pushback
.Bad:
    Fail ErrRecordName
.Many:
    Fail ErrTooMany

DefaultFor:
    cmp rax, TNum
    je .Zero
    cmp rax, TBool
    je .Zero
    cmp rax, TDec
    je .Zero
    push rax
    call KindOfType
    pop rcx
    cmp rax, KUnion
    je .Zero
    cmp rax, KEnum
    je .One
    mov rax, rcx
    call EmitDefault
    test eax, eax
    jz .None
    ret
.Zero:
    CompileNum 0
    mov eax, 1
    ret
.One:
    CompileNum 1
    mov eax, 1
    ret
.None:
    xor eax, eax
    ret

ConstructRecord:
    sub rsp, 552
    mov rcx, [rax + 32]
    mov [rsp + 512], rcx
    mov qword [rsp + 520], 0
    mov qword [rsp + 528], 0
    mov qword [rsp + 536], 0
    call Advance
    Expect "(", ErrParen
    call Advance
    IfTok ")", .Close
.Loop:
    call IsNameStart
    test eax, eax
    jz .Positional
    call PeekColon
    test eax, eax
    jz .Positional
    mov rcx, [rsp + 512]
    mov rdx, [rel TokPtr]
    mov r8, [rel TokLen]
    call FindField
    cmp rax, -1
    je .NoField
    mov rcx, [rsp + 528]
    bt rcx, rax
    jc .Twice
    mov [rsp + 544], rax
    call Advance
    call Advance
    mov rax, [rsp + 544]
    jmp .Have
.Positional:
    mov rcx, [rsp + 512]
    call FieldCount
    mov rcx, [rsp + 520]
    cmp rcx, rax
    jae .Args
    mov rax, rcx
    inc qword [rsp + 520]
.Have:
    mov rcx, [rsp + 528]
    bt rcx, rax
    jc .Twice
    bts rcx, rax
    mov [rsp + 528], rcx
    mov rcx, [rsp + 536]
    mov [rsp + rcx * 8], rax
    inc qword [rsp + 536]
    mov rcx, [rsp + 512]
    mov rdx, rax
    call FieldInfo
    mov rax, [rax + 16]
    mov [rsp + 544], rax
    call SetHint
    call ParseExpr
    mov rax, [rsp + 544]
    call CheckArg
    IfTok ",", .Comma
    Expect ")", ErrParen
.Close:
    mov qword [rsp + 520], 0
.Fill:
    mov rcx, [rsp + 512]
    call FieldCount
    mov rdx, [rsp + 520]
    cmp rdx, rax
    jae .Make
    mov rcx, [rsp + 528]
    bt rcx, rdx
    jc .FillNext
    mov rcx, [rsp + 512]
    call FieldInfo
    mov [rsp + 544], rax
    mov rax, [rax + 16]
    call DefaultFor
    test eax, eax
    jz .Missing
    mov rcx, [rsp + 536]
    mov rdx, [rsp + 520]
    mov [rsp + rcx * 8], rdx
    inc qword [rsp + 536]
.FillNext:
    inc qword [rsp + 520]
    jmp .Fill
.Make:
    CompilePrim PrimMakeRecord
    mov rcx, [rsp + 536]
    call Compile
    mov qword [rsp + 520], 0
.Slots:
    mov rax, [rsp + 520]
    cmp rax, [rsp + 536]
    jae .Done
    mov rcx, [rsp + rax * 8]
    call Compile
    inc qword [rsp + 520]
    jmp .Slots
.Done:
    mov rax, [rsp + 512]
    mov [rel ExprType], rax
    mov qword [rel LastVarRef], 0
    add rsp, 552
    jmp Advance
.Comma:
    call Advance
    jmp .Loop
.NoField:
    FailTok ErrNoField
.Args:
    Fail ErrArgs
.Twice:
    FailTok ErrArgTwice
.Missing:
    mov rcx, [rsp + 544]
    mov r8, [rcx]
    mov r9, [rcx + 8]
    mov rax, [rel TokPtr]
    mov [rel ErrPos], rax
    mov [rel ErrTokPtr], r8
    mov [rel ErrTokLen], r9
    lea rcx, [rel ErrMissingArg]
    mov edx, ErrMissingArgLen
    jmp Abort

IfaceCoerce:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    mov rbx, rax
    mov r12, rdx
    mov rcx, rdx
    call TypeKind
    cmp rax, KIface
    je .Out
    mov rcx, rbx
    call FieldCount
    mov r13, rax
    sub rsp, 520
    xor esi, esi
.Each:
    cmp rsi, r13
    jae .Emit
    mov rcx, rbx
    mov rdx, rsi
    call FieldInfo
    mov rdi, rax
    mov rcx, r12
    mov rdx, [rdi]
    mov r8, [rdi + 8]
    call FindMethod
    test rax, rax
    jz .Missing
    cmp rdx, 4
    jne .Missing
    mov [rsp + rsi * 8], rax
    mov rcx, [rdi + 16]
    shl rcx, 5
    lea rdx, [rel TypeTable]
    add rcx, rdx
    mov rdx, [rcx + 16]
    inc rdx
    cmp rdx, [rax - 16]
    jne .Wrong
    mov rdx, [rcx + 8]
    cmp rdx, [rax - 8]
    jne .Wrong
    xor r8d, r8d
.Params:
    cmp r8, [rcx + 16]
    jae .Next
    mov r9, [rcx + 24]
    mov r9, [r9 + r8 * 8]
    lea rdx, [r8 + 1]
    shl rdx, 3
    neg rdx
    mov rdx, [rax - 24 + rdx]
    cmp rdx, r9
    jne .Wrong
    inc r8
    jmp .Params
.Next:
    inc rsi
    jmp .Each
.Emit:
    CompilePrim PrimMakeIface
    mov rcx, r12
    call Compile
    mov rcx, r13
    call Compile
    xor esi, esi
.EmitFns:
    cmp rsi, r13
    jae .Emitted
    mov rcx, [rsp + rsi * 8]
    call Compile
    inc rsi
    jmp .EmitFns
.Emitted:
    add rsp, 520
    mov [rel ExprType], rbx
.Out:
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret
.Missing:
    mov r8, [rdi]
    mov r9, [rdi + 8]
    mov rax, [rel PrevTokPtr]
    mov [rel ErrPos], rax
    mov [rel ErrTokPtr], r8
    mov [rel ErrTokLen], r9
    lea rcx, [rel ErrNoMethod]
    mov edx, ErrNoMethodLen
    jmp Abort
.Wrong:
    mov r8, [rdi]
    mov r9, [rdi + 8]
    mov rax, [rel PrevTokPtr]
    mov [rel ErrPos], rax
    mov [rel ErrTokPtr], r8
    mov [rel ErrTokLen], r9
    lea rcx, [rel ErrMethodShape]
    mov edx, ErrMethodShapeLen
    jmp Abort

AddSelfParam:
    push rbx
    lea rcx, [rel SelfName]
    mov edx, 4
    call AddLocal
    mov rbx, [rel LocalCount]
    dec rbx
    lea rcx, [rel SelfName]
    mov edx, 4
    call CopyString
    mov r8, [rel FnSig]
    mov r9, rbx
    shl r9, 4
    neg r9
    mov [r8 - SigName + r9], rax
    mov qword [r8 - SigName - 8 + r9], 4
    mov rax, [rel MethodSelf]
    mov qword [rel MethodSelf], 0
    lea r8, [rel LocalType]
    mov [r8 + rbx * 8], rax
    mov r8, [rel FnSig]
    mov r9, rbx
    shl r9, 3
    sub r8, 24
    sub r8, r9
    mov [r8], rax
    pop rbx
    ret

MethodOwner:
    IfTok "number", .Num
    IfTok "decimal", .Dec
    IfTok "text", .Text
    IfTok "bool", .Bool
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call FindWord
    test rax, rax
    jz .Bad
    cmp rdx, 8
    je .Struct
    cmp rdx, 6
    je .Done
.Bad:
    FailTok ErrMethodOwner
.Struct:
    mov rax, [rax + 32]
.Done:
    ret
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

OpName:
    push rsi
    push rdi
    push rbx
    lea rdi, [rel OpBuf]
    mov rsi, rcx
    mov rcx, rdx
    rep movsb
    mov rax, r8
    call .Num
    mov rax, r9
    call .Num
    lea rcx, [rel OpBuf]
    mov rdx, rdi
    sub rdx, rcx
    pop rbx
    pop rdi
    pop rsi
    ret
.Num:
    mov byte [rdi], ' '
    inc rdi
    sub rsp, 32
    xor ecx, ecx
    mov ebx, 10
.Div:
    xor edx, edx
    div rbx
    add dl, '0'
    mov [rsp + rcx], dl
    inc rcx
    test rax, rax
    jnz .Div
.Put:
    dec rcx
    mov al, [rsp + rcx]
    mov [rdi], al
    inc rdi
    test rcx, rcx
    jnz .Put
    add rsp, 32
    ret

OpFind:
    push rcx
    push rdx
    push r8
    push r9
    call OpFindOnce
    test rax, rax
    jnz .Got
    cmp qword [rel PreScanActive], MaxPre
    jae .Got
    call ForwardOps
    mov r9, [rsp]
    mov r8, [rsp + 8]
    mov rdx, [rsp + 16]
    mov rcx, [rsp + 24]
    call OpFindOnce
.Got:
    add rsp, 32
    ret

OpFindOnce:
    push r8
    push r9
    call OpName
    mov r8, [rel NamePrefixLen]
    push r8
    mov qword [rel NamePrefixLen], 0
    call FindWord
    pop r8
    mov [rel NamePrefixLen], r8
    pop r9
    pop r8
    test rax, rax
    jz .No
    cmp rdx, 4
    jne .No
    ret
.No:
    xor eax, eax
    ret

TryOverload:
    cmp rax, TDec
    ja .Maybe
    cmp rdx, TDec
    ja .Maybe
    xor eax, eax
    ret
.Maybe:
    cmp rax, TNil
    je .No
    cmp rdx, TNil
    je .No
    push rbx
    push rsi
    push rdi
    push r12
    mov rsi, rcx
    mov rdi, r8
    mov rbx, rax
    mov r12, rdx
    mov rcx, rsi
    mov rdx, rdi
    mov r8, rbx
    mov r9, r12
    call OpFind
    test rax, rax
    jnz .Emit
    cmp r12, TNum
    jne .TryLeft
    mov rcx, rsi
    mov rdx, rdi
    mov r8, rbx
    mov r9d, TDec
    call OpFind
    test rax, rax
    jz .TryLeft
    push rax
    push rax
    CompilePrim PrimToDec
    pop rax
    pop rax
    jmp .Emit
.TryLeft:
    cmp rbx, TNum
    jne .None
    mov rcx, rsi
    mov rdx, rdi
    mov r8d, TDec
    mov r9, r12
    call OpFind
    test rax, rax
    jz .None
    push rax
    push rax
    CompilePrim PrimToDecUnder
    pop rax
    pop rax
.Emit:
    push rax
    push rax
    CompilePrim PrimCall
    mov rcx, [rsp]
    call Compile
    pop rax
    pop rax
    mov rax, [rax - 8]
    test rax, rax
    jnz .Typed
    mov eax, TNum
.Typed:
    mov [rel ExprType], rax
    mov qword [rel LastVarRef], 0
    mov eax, 1
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret
.None:
    xor eax, eax
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret
.No:
    xor eax, eax
    ret

OperatorHead:
    call GetInput
    push rax
    push qword [rel TokPtr]
    call Advance
    call Advance
    Expect ":", ErrOpHead
    call Advance
    call ParseTypeName
    push rax
    call Advance
    Expect ")", ErrOpHead
    call Advance
    push qword [rel TokPtr]
    push qword [rel TokLen]
    call Advance
    Expect "(", ErrOpHead
    call Advance
    call Advance
    Expect ":", ErrOpHead
    call Advance
    call ParseTypeName
    mov r9, rax
    pop rdx
    pop rcx
    pop r8
    mov rax, [rsp]
    push r9
    push r8
    push rdx
    push rcx
    mov rcx, rax
    call Unread
    pop rcx
    pop rdx
    pop r8
    pop r9
    add rsp, 16
    call OpName
    ret

[section .data]
OpLt db "<"
OpGt db ">"
OpLe db "<="
OpGe db ">="
__SECT__

OrderOverload:
    cmp rax, TDec
    ja .Maybe
    cmp qword [rel ExprType], TDec
    ja .Maybe
    xor eax, eax
    ret
.Maybe:
    push rbx
    push r12
    push r13
    mov rbx, rax
    mov r12, [rel ExprType]
    mov r13, rcx
    lea rcx, [rel OpLt]
    mov r8d, 1
    cmp r13, 1
    jne .NotGt
    lea rcx, [rel OpGt]
.NotGt:
    cmp r13, 2
    jne .NotLe
    lea rcx, [rel OpLe]
    mov r8d, 2
.NotLe:
    cmp r13, 3
    jne .NotGe
    lea rcx, [rel OpGe]
    mov r8d, 2
.NotGe:
    mov rax, rbx
    mov rdx, r12
    call TryOverload
    test eax, eax
    jnz .Yes
    test r13, r13
    jz .No
    cmp r13, 3
    je .Ge
    push qword [rel Here]
    CompilePrim PrimSwap
    mov rax, r12
    mov rdx, rbx
    lea rcx, [rel OpLt]
    mov r8d, 1
    call TryOverload
    test eax, eax
    pop rcx
    jnz .Swapped
    mov [rel Here], rcx
    jmp .No
.Swapped:
    cmp r13, 2
    jne .Yes
.Not:
    CompileNum 0
    CompilePrim PrimEq
    jmp .Yes
.Ge:
    mov rax, rbx
    mov rdx, r12
    lea rcx, [rel OpLt]
    mov r8d, 1
    call TryOverload
    test eax, eax
    jnz .Not
.No:
    xor eax, eax
    jmp .Out
.Yes:
    mov eax, 1
.Out:
    pop r13
    pop r12
    pop rbx
    ret

ScanFor:
    mov rcx, [rel TokPtr]
    mov rdx, [rel SourceEnd]
    xor r8d, r8d
.Loop:
    cmp rcx, rdx
    jae .None
    movzx eax, byte [rcx]
    cmp al, '"'
    je .Str
    cmp al, '('
    je .Open
    cmp al, '['
    je .Open
    cmp al, '{'
    je .Open
    cmp al, ')'
    je .Close
    cmp al, '}'
    je .Close
    cmp al, ']'
    je .CloseSq
    cmp al, '#'
    je .Comment
    cmp al, 'f'
    jne .Next
    test r8, r8
    jnz .Next
    lea r9, [rcx + 3]
    cmp r9, rdx
    jae .Next
    cmp byte [rcx + 1], 'o'
    jne .Next
    cmp byte [rcx + 2], 'r'
    jne .Next
    movzx eax, byte [rcx + 3]
    cmp al, ' '
    je .Before
    cmp al, 13
    je .Before
    cmp al, 10
    je .Before
    cmp al, 9
    jne .Next
.Before:
    movzx eax, byte [rcx - 1]
    cmp al, ' '
    je .Found
    cmp al, 9
    je .Found
    cmp al, 10
    je .Found
    cmp al, ')'
    je .Found
    cmp al, ']'
    je .Found
    cmp al, '"'
    je .Found
    cmp al, '}'
    je .Found
    jmp .Next
.Open:
    inc r8
    jmp .Next
.Close:
    test r8, r8
    jz .None
    dec r8
    jmp .Next
.CloseSq:
    test r8, r8
    jz .None
    dec r8
    jmp .Next
.Str:
    inc rcx
.StrLoop:
    cmp rcx, rdx
    jae .None
    movzx eax, byte [rcx]
    cmp al, 92
    je .Esc
    cmp al, '"'
    je .Next
    cmp al, 10
    je .None
    inc rcx
    jmp .StrLoop
.Esc:
    add rcx, 2
    jmp .StrLoop
.Comment:
    inc rcx
    cmp rcx, rdx
    jae .None
    cmp byte [rcx], 10
    jne .Comment
    jmp .Loop
.Next:
    inc rcx
    jmp .Loop
.Found:
    mov rax, rcx
    ret
.None:
    xor eax, eax
    ret

ListComp:
    sub rsp, 104
    mov [rsp], rax
    mov rcx, [rel TokPtr]
    mov [rsp + 8], rcx
    xor eax, eax
    mov rcx, [rel CurHintType]
    test rcx, rcx
    jz .NoHint
    push rcx
    call TypeKind
    pop rcx
    cmp rax, KList
    mov eax, 0
    jne .NoHint
    call ElemOf
.NoHint:
    mov [rsp + 16], rax
    mov rcx, [rsp]
    call Unread
    call Advance
    call Advance
    IfTok "each", .Each
    jmp .Name
.Each:
    call Advance
.Name:
    call IsNameStart
    test eax, eax
    jz .Bad
    mov rax, [rel TokPtr]
    mov [rsp + 24], rax
    mov rax, [rel TokLen]
    mov [rsp + 32], rax
    call Advance
    Expect "in", ErrComp
    call Advance
    call ParsePipe
    mov rax, [rel ExprType]
    cmp rax, TText
    jne .NotText
    CompilePrim PrimTextChars
    mov ecx, TText
    call ListOf
    mov [rel ExprType], rax
    jmp .IsList
.NotText:
    call KindOfType
    cmp rax, KList
    jne TypeError
.IsList:
    mov rcx, [rel ExprType]
    call ElemOf
    test rax, rax
    jz TypeError
    mov [rsp + 40], rax
    call NewHidden
    mov [rsp + 48], rax
    mov rcx, rax
    call EmitStore
    call NewHidden
    mov [rsp + 56], rax
    CompileNum 0
    mov rcx, [rsp + 56]
    call EmitStore
    call NewHidden
    mov [rsp + 64], rax
    CompileNum 0
    CompilePrim PrimMakeList
    mov rcx, [rsp + 64]
    call EmitStore
    mov rcx, [rsp + 24]
    mov rdx, [rsp + 32]
    call ResolveLoopVar
    mov [rsp + 72], rax
    mov rcx, rax
    call TypeOf
    test rax, rax
    jz .SetVarType
    cmp rax, [rsp + 40]
    jne TypeError
    jmp .VarTyped
.SetVarType:
    mov rcx, [rsp + 72]
    mov rdx, [rsp + 40]
    call SetTypeOf
.VarTyped:
    mov rax, [rel Here]
    mov [rsp + 80], rax
    mov rcx, [rsp + 56]
    call EmitLoad
    mov rcx, [rsp + 48]
    call EmitLoad
    CompilePrim PrimLength
    CompilePrim PrimLess
    lea rcx, [rel PrimBranch0]
    call EmitJump
    mov [rsp + 88], rax
    mov rcx, [rsp + 48]
    call EmitLoad
    mov rcx, [rsp + 56]
    call EmitLoad
    CompileNum 1
    CompilePrim PrimAdd
    CompilePrim PrimIndex
    mov rcx, [rsp + 72]
    call EmitStore
    mov rcx, [rsp + 56]
    call EmitLoad
    CompileNum 1
    CompilePrim PrimAdd
    mov rcx, [rsp + 56]
    call EmitStore
    IfTok "if", .Cond
    jmp .Body
.Cond:
    call Advance
    call ParseExpr
    call NeedCondition
    lea rcx, [rel PrimBranch0]
    call EmitJump
    mov rcx, [rsp + 80]
    mov [rax], rcx
.Body:
    Expect "]", ErrComp
    mov rax, [rel TokPtr]
    mov [rsp], rax
    mov rcx, [rsp + 8]
    call Unread
    call Advance
    mov rcx, [rsp + 64]
    call EmitLoad
    mov rax, [rsp + 16]
    call SetHint
    call ParseExpr
    mov rax, [rsp + 16]
    call CoerceElem
    mov rax, [rel ExprType]
    test rax, rax
    jz TypeError
    mov [rsp + 8], rax
    IfTok "for", .ElemOk
    Fail ErrComp
.ElemOk:
    CompilePrim PrimListAdd
    CompilePrim PrimBranch
    mov rcx, [rsp + 80]
    call Compile
    mov rcx, [rsp + 88]
    mov rdx, [rel Here]
    mov [rcx], rdx
    mov rcx, [rsp + 64]
    call EmitLoad
    mov rcx, [rsp]
    call Unread
    call Advance
    call Advance
    mov rcx, [rsp + 8]
    call ListOf
    mov [rel ExprType], rax
    mov qword [rel LastVarRef], 0
    add rsp, 104
    ret
.Bad:
    Fail ErrComp

LibraryPrefix:
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    cmp byte [rcx + rdx], '.'
    jne .No
    lea r10, [rdx + 1]
    mov r8, [rel Latest]
.Next:
    test r8, r8
    jz .No
    movzx r9d, byte [r8 + 17]
    cmp r9, r10
    jbe .Skip
    xor r11d, r11d
.Cmp:
    cmp r11, r10
    jae .Yes
    mov al, [rcx + r11]
    cmp al, [r8 + 18 + r11]
    jne .Skip
    inc r11
    jmp .Cmp
.Skip:
    mov r8, [r8]
    jmp .Next
.Yes:
    mov eax, 1
    ret
.No:
    xor eax, eax
    ret

[section .bss]
FolderBuf resb 4096
FolderTmp resb 4096
__SECT__

FolderText:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    cmp rcx, [rel FileCount]
    jae .Dot
    shl rcx, 4
    lea rax, [rel FilePath]
    mov rsi, [rax + rcx]
    mov rdx, [rax + rcx + 8]
    test rsi, rsi
    jz .Dot
    test rdx, rdx
    jz .Dot
    cmp rdx, 2000
    jae .Dot
    lea rbx, [rel FolderTmp]
    xor r12d, r12d
    mov al, [rsi]
    cmp al, '/'
    je .Abs
    cmp al, 92
    je .Abs
    cmp rdx, 2
    jb .Rel
    cmp byte [rsi + 1], ':'
    je .Abs
.Rel:
    push rsi
    push rdx
    mov rcx, rbx
    mov edx, 2000
    call SysCurrentDir
    pop rdx
    pop rsi
    mov r12, rax
    cmp r12, 2000
    jae .Dot
    test r12, r12
    jz .Abs
    mov byte [rbx + r12], '/'
    inc r12
.Abs:
    xor ecx, ecx
.CopyIn:
    cmp rcx, rdx
    jae .Cut
    mov al, [rsi + rcx]
    cmp al, 92
    jne .PutIn
    mov al, '/'
.PutIn:
    mov [rbx + r12], al
    inc r12
    inc rcx
    jmp .CopyIn
.Cut:
    test r12, r12
    jz .Dot
    cmp byte [rbx + r12 - 1], '/'
    je .CutSlash
    dec r12
    jmp .Cut
.CutSlash:
    dec r12
    lea rdi, [rel FolderBuf]
    xor r8d, r8d
    xor r9d, r9d
    xor r10d, r10d
    cmp byte [rbx], '/'
    jne .Seg
    mov byte [rdi], '/'
    mov r8d, 1
    mov r10d, 1
    mov r9d, 1
.Seg:
    cmp r9, r12
    jae .Finish
    mov r11, r9
.SegEnd:
    cmp r9, r12
    jae .Got
    cmp byte [rbx + r9], '/'
    je .Got
    inc r9
    jmp .SegEnd
.Got:
    mov r13, r9
    sub r13, r11
    inc r9
    test r13, r13
    jz .Seg
    cmp r13, 1
    jne .NotDot
    cmp byte [rbx + r11], '.'
    je .Seg
.NotDot:
    cmp r13, 2
    jne .Write
    cmp word [rbx + r11], '..'
    jne .Write
    cmp r8, r10
    jbe .Write
    mov rax, r8
.Find:
    cmp rax, r10
    jbe .Found
    cmp byte [rdi + rax - 1], '/'
    je .Found
    dec rax
    jmp .Find
.Found:
    mov rcx, r8
    sub rcx, rax
    cmp rcx, 2
    jne .NotUp
    cmp word [rdi + rax], '..'
    je .Write
.NotUp:
    cmp byte [rdi + r8 - 1], ':'
    je .Seg
    mov r8, rax
    cmp r8, r10
    jbe .Seg
    dec r8
    jmp .Seg
.Write:
    cmp r8, r10
    jbe .NoSep
    mov byte [rdi + r8], '/'
    inc r8
.NoSep:
    xor ecx, ecx
    lea rdx, [rbx + r11]
.CopySeg:
    cmp rcx, r13
    jae .Seg
    mov al, [rdx + rcx]
    mov [rdi + r8], al
    inc r8
    inc rcx
    jmp .CopySeg
.Finish:
    test r8, r8
    jnz .Emit
.Dot:
    lea rdi, [rel FolderBuf]
    mov byte [rdi], '.'
    mov r8d, 1
.Emit:
    mov rcx, rdi
    mov rdx, r8
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    jmp EmitTextLiteral

FillPlaceholder:
    shl rax, 5
    shl rcx, 5
    lea r8, [rel TypeTable]
    mov r9, [r8 + rax]
    mov [r8 + rcx], r9
    test edx, edx
    jnz .KeepName
    mov r9, [r8 + rax + 8]
    mov [r8 + rcx + 8], r9
.KeepName:
    mov r9, [r8 + rax + 16]
    mov [r8 + rcx + 16], r9
    mov r9, [r8 + rax + 24]
    mov [r8 + rcx + 24], r9
    ret

TypeWord:
    call TypeDeclStart
    push qword [rel TokPtr]
    push qword [rel TokLen]
    call NewPlaceholder
    push rax
    mov rcx, [rsp + 16]
    mov rdx, [rsp + 8]
    mov r8, rax
    call RegisterType
    push qword [rel PendingType]
    push qword [rel PendingUsed]
    mov rax, [rsp + 16]
    mov [rel PendingType], rax
    mov qword [rel PendingUsed], 0
    call Advance
    Expect "=", ErrTypeAlias
    call Advance
    call ParseTypeName
    mov rcx, [rel PendingUsed]
    pop qword [rel PendingUsed]
    pop qword [rel PendingType]
    test rcx, rcx
    jz .Alias
    mov rcx, [rsp]
    cmp rax, rcx
    je .BadSelf
    xor edx, edx
    call FillPlaceholder
    jmp .Done
.Alias:
    mov rcx, [rel Latest]
    mov rcx, [rcx + 8]
    mov [rcx + 32], rax
.Done:
    add rsp, 24
    call Advance
    jmp Pushback
.BadSelf:
    Fail ErrTypeAlias

PickHint:
    mov rcx, [rel CurHintType]
    test rcx, rcx
    jz .Done
    call TypeKind
    cmp rax, KUnion
    jne .Done
    IfTok "[", .WantList
    IfTok "{", .WantMap
.Done:
    ret
.WantList:
    mov edx, KList
    call .Find
    ret
.WantMap:
    mov edx, KMap
    call .Find
    test eax, eax
    jnz .Done
    mov edx, KRec
.Find:
    mov rcx, [rel CurHintType]
    shl rcx, 5
    lea r8, [rel TypeTable]
    add r8, rcx
    mov r9, [r8 + 24]
    mov r10, [r8 + 16]
    xor r11d, r11d
.Loop:
    cmp r11, r10
    jae .Miss
    mov rcx, [r9 + r11 * 8]
    push rcx
    push rdx
    call TypeKind
    pop rdx
    pop rcx
    cmp rax, rdx
    je .Hit
    inc r11
    jmp .Loop
.Hit:
    mov [rel CurHintType], rcx
    mov eax, 1
    ret
.Miss:
    xor eax, eax
    ret

ElseIsNothing:
    add rcx, 9
.Skip:
    mov al, [rcx]
    cmp al, ' '
    je .Next
    cmp al, 9
    jne .Check
.Next:
    inc rcx
    jmp .Skip
.Check:
    cmp dword [rcx], 'noth'
    jne .No
    cmp word [rcx + 4], 'in'
    jne .No
    cmp byte [rcx + 6], 'g'
    jne .No
    movzx eax, byte [rcx + 7]
    cmp al, '_'
    je .No
    or al, 32
    cmp al, 'a'
    jb .Digit
    cmp al, 'z'
    jbe .No
.Digit:
    movzx eax, byte [rcx + 7]
    cmp al, '0'
    jb .Yes
    cmp al, '9'
    jbe .No
.Yes:
    mov eax, 1
    ret
.No:
    xor eax, eax
    ret

[section .data]
NegName db "-u"
__SECT__

UnaryHead:
    call Advance
    push qword [rel TokPtr]
    call Advance
    call Advance
    Expect ":", ErrOpHead
    call Advance
    call ParseTypeName
    mov r8, rax
    pop rcx
    push r8
    push r8
    call Unread
    pop r8
    pop r8
    lea rcx, [rel NegName]
    mov edx, 2
    xor r9d, r9d
    jmp OpName

TryNegate:
    mov rax, [rel ExprType]
    cmp rax, TDec
    jbe .No
    cmp rax, TNil
    je .No
    push rax
    lea rcx, [rel NegName]
    mov edx, 2
    mov r8, rax
    xor r9d, r9d
    call OpFind
    pop rcx
    test rax, rax
    jz .No
    push rax
    push rax
    CompilePrim PrimCall
    mov rcx, [rsp]
    call Compile
    CompilePrim PrimSwap
    CompilePrim PrimDrop
    pop rax
    pop rax
    mov rax, [rax - 8]
    mov [rel ExprType], rax
    mov eax, 1
    ret
.No:
    xor eax, eax
    ret
