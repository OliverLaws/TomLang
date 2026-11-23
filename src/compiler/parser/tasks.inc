TaskSeconds:
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    cmp rdx, 2
    jb .Expr
    movzx eax, byte [rcx]
    sub eax, '0'
    cmp eax, 9
    ja .Expr
    cmp byte [rcx + rdx - 1], 's'
    jne .Expr
    xor r8d, r8d
    dec rdx
    cmp rdx, 1
    jb .Expr
    cmp byte [rcx + rdx - 1], 'm'
    jne .Digits
    mov r8d, 1
    dec rdx
.Digits:
    test rdx, rdx
    jz .Expr
    push r8
    call ParseNumber
    pop r8
    test rdx, rdx
    jz .Expr
    cvtsi2sd xmm0, rax
    test r8, r8
    jz .Whole
    mov rax, 0x3F50624DD2F1A9FC
    movq xmm1, rax
    mulsd xmm0, xmm1
.Whole:
    movq rax, xmm0
    push rax
    CompilePrim PrimLit
    pop rcx
    call Compile
    SetType TDec
    jmp Advance
.Expr:
    call ParseExpr
    cmp qword [rel ExprType], TNum
    jne .NotNum
    CompilePrim PrimToDec
    SetType TDec
.NotNum:
    NeedType TDec
    IfTok "seconds", .Plain
    IfTok "second", .Plain
    IfTok "s", .Plain
    IfTok "ms", .Milli
    IfTok "milliseconds", .Milli
    IfTok "millisecond", .Milli
    IfTok "minutes", .Minute
    IfTok "minute", .Minute
    ret
.Plain:
    jmp Advance
.Milli:
    mov rax, 0x3F50624DD2F1A9FC
    jmp .Scale
.Minute:
    mov rax, 0x404E000000000000
.Scale:
    push rax
    CompilePrim PrimLit
    pop rcx
    call Compile
    CompilePrim PrimDMul
    jmp Advance

WaitWord:
    call Advance
    call TaskSeconds
    CompilePrim PrimWait
    jmp Pushback

TaskFnArg:
    call ParseExpr
    mov rcx, [rel ExprType]
    call TypeKind
    cmp rax, KFunc
    jne TypeError
    ret

SpawnTaskWord:
    call Advance
    Expect "(", ErrParen
    call Advance
    call TaskFnArg
    Expect ")", ErrParen
    call Advance
    CompilePrim PrimSpawn
    xor ecx, ecx
    call Compile
    jmp Pushback

SpawnThreadWord:
    call Advance
    Expect "(", ErrParen
    call Advance
    call TaskFnArg
    Expect ")", ErrParen
    call Advance
    CompilePrim PrimSpawnThread
    jmp Pushback

SpawnTimedWord:
    push rax
    call Advance
    Expect "(", ErrParen
    call Advance
    call TaskSeconds
    Expect ",", ErrComma
    call Advance
    call TaskFnArg
    Expect ")", ErrParen
    call Advance
    CompilePrim PrimSpawn
    pop rcx
    call Compile
    jmp Pushback

SpawnAfterWord:
    mov eax, 1
    jmp SpawnTimedWord

SpawnEveryWord:
    mov eax, 2
    jmp SpawnTimedWord

SpawnWhenWord:
    call Advance
    Expect "(", ErrParen
    call Advance
    call TaskFnArg
    Expect ",", ErrComma
    call Advance
    call TaskFnArg
    Expect ")", ErrParen
    call Advance
    CompilePrim PrimSpawn
    mov ecx, 3
    call Compile
    jmp Pushback
