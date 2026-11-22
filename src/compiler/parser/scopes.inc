NextFnId:
    inc qword [rel FnIdCounter]
    mov rax, [rel FnIdCounter]
    ret

LineStart:
    mov rax, rcx
.Back:
    cmp rax, [rel SourceStart]
    jbe .Yes
    movzx edx, byte [rax - 1]
    cmp edx, 10
    je .Yes
    cmp edx, ' '
    je .Prev
    cmp edx, 9
    je .Prev
    xor eax, eax
    ret
.Prev:
    dec rax
    jmp .Back
.Yes:
    mov eax, 1
    ret

ScanClosures:
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 8
    mov r14, rcx
    call GetInput
    mov r12, rax
    mov r13, rdx
    mov rcx, r14
    mov rdx, r13
    sub rdx, r14
    call SetInput
    call NextToken
    mov ebx, 1
.Loop:
    call NextToken
    test rdx, rdx
    jz .No
    cmp rdx, 2
    jne .NotArrow
    cmp word [rax], '=>'
    je .Yes
.NotArrow:
    cmp rdx, 3
    jne .NotEnd
    cmp word [rax], 'en'
    jne .NotEnd
    cmp byte [rax + 2], 'd'
    jne .NotEnd
    dec rbx
    jz .No
    jmp .Loop
.NotEnd:
    push rax
    push rdx
    mov rcx, rax
    call LineStart
    mov r8d, eax
    pop rdx
    pop rax
    test r8d, r8d
    jz .Loop
    cmp rdx, 2
    jne .Opener
    cmp word [rax], 'do'
    je .Yes
    cmp word [rax], 'if'
    je .Open
    jmp .Loop
.Opener:
    cmp rdx, 6
    jne .Five
    cmp dword [rax], 'repe'
    jne .Loop
    cmp word [rax + 4], 'at'
    je .Open
    jmp .Loop
.Five:
    cmp rdx, 5
    jne .Three
    cmp dword [rax], 'chec'
    jne .Later
    cmp byte [rax + 4], 'k'
    je .Open
    jmp .Loop
.Later:
    cmp dword [rax], 'late'
    jne .Loop
    cmp byte [rax + 4], 'r'
    jne .Loop
    lea rcx, [rax + 5]
    call RestEmpty
    test eax, eax
    jnz .Open
    jmp .Loop
.Three:
    cmp rdx, 3
    jne .Loop
    cmp word [rax], 'tr'
    jne .Loop
    cmp byte [rax + 2], 'y'
    jne .Loop
.Open:
    inc rbx
    jmp .Loop
.Yes:
    mov r14d, 1
    jmp .Out
.No:
    xor r14d, r14d
.Out:
    mov rcx, r12
    mov rdx, r13
    sub rdx, r12
    call SetInput
    mov rax, r14
    add rsp, 8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

RestEmpty:
    movzx eax, byte [rcx]
    cmp eax, ' '
    je .Next
    cmp eax, 9
    je .Next
    cmp eax, 13
    je .Yes
    cmp eax, 10
    je .Yes
    cmp eax, '#'
    je .Yes
    test eax, eax
    jz .Yes
    xor eax, eax
    ret
.Next:
    inc rcx
    jmp RestEmpty
.Yes:
    mov eax, 1
    ret

LineHasArrow:
    xor r8d, r8d
.Loop:
    movzx eax, byte [rcx]
    cmp eax, 10
    je .No
    test eax, eax
    jz .No
    cmp eax, '"'
    jne .NotQuote
    xor r8d, 1
.NotQuote:
    test r8d, r8d
    jnz .Next
    cmp eax, '='
    jne .Next
    cmp byte [rcx + 1], '>'
    je .Yes
.Next:
    inc rcx
    jmp .Loop
.Yes:
    mov eax, 1
    ret
.No:
    xor eax, eax
    ret

ScopeAdd:
    mov rax, [rel ScopeCount]
    cmp rax, MaxScopes
    jae .Many
    shl rax, 6
    lea r10, [rel ScopeTab]
    add r10, rax
    mov [r10], rcx
    mov [r10 + 8], rdx
    mov [r10 + 16], r8
    mov [r10 + 24], r9
    mov rax, [rsp + 8]
    mov [r10 + 32], rax
    mov rax, [rel CurLinkOff]
    mov [r10 + 40], rax
    mov rax, [rel CurFnId]
    mov [r10 + 48], rax
    mov rax, [rel CurHeap]
    mov [r10 + 56], rax
    inc qword [rel ScopeCount]
    ret 8
.Many:
    Fail ErrNestDeep

ScopePushSaved:
    lea rax, [rcx + (LocalCount - ParserState)]
    push rax
    lea rdx, [rcx + (LocalLen - ParserState)]
    lea r8, [rcx + (LocalType - ParserState)]
    lea r9, [rcx + (LocalConst - ParserState)]
    lea rcx, [rcx + (LocalPtr - ParserState)]
    call ScopeAdd
    ret

FindScoped:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    mov r12, rcx
    mov r13, rdx
    xor eax, eax
    cmp qword [rel InFn], 0
    je .None
    mov r14, 1
.Level:
    cmp r14, [rel ScopeCount]
    ja .None
    mov rax, [rel ScopeCount]
    sub rax, r14
    shl rax, 6
    lea r10, [rel ScopeTab]
    add r10, rax
    mov r11, [r10 + 32]
    mov r11, [r11]
    xor ebx, ebx
.Scan:
    cmp rbx, r11
    jae .NextLevel
    mov rax, [r10 + 8]
    mov rax, [rax + rbx * 8]
    cmp rax, r13
    jne .Next
    test rax, rax
    jz .Next
    mov rsi, [r10]
    mov rsi, [rsi + rbx * 8]
    mov rdi, r12
    mov rcx, r13
    repe cmpsb
    je .Found
.Next:
    inc rbx
    jmp .Scan
.NextLevel:
    inc r14
    jmp .Level
.Found:
    mov rdx, [r10 + 24]
    mov rdx, [rdx + rbx * 8]
    lea rax, [rbx * 8 + 4]
    shl r14, 16
    or rax, r14
    jmp .Out
.None:
    xor eax, eax
    xor edx, edx
.Out:
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

ScopeEntryOf:
    mov rax, rcx
    shr rax, 16
    mov rdx, [rel ScopeCount]
    sub rdx, rax
    shl rdx, 6
    lea rax, [rel ScopeTab]
    add rax, rdx
    ret

ScopedType:
    call ScopeEntryOf
    and rcx, 0xFFF8
    shr rcx, 3
    mov rax, [rax + 16]
    mov rax, [rax + rcx * 8]
    ret

ScopedSetType:
    call ScopeEntryOf
    and rcx, 0xFFF8
    shr rcx, 3
    mov rax, [rax + 16]
    mov [rax + rcx * 8], rdx
    ret

OwnerDistance:
    cmp rcx, [rel CurFnId]
    je .Zero
    mov rax, 1
.Loop:
    cmp rax, [rel ScopeCount]
    ja .None
    mov rdx, [rel ScopeCount]
    sub rdx, rax
    shl rdx, 6
    lea r8, [rel ScopeTab]
    cmp rcx, [r8 + rdx + 48]
    je .Out
    inc rax
    jmp .Loop
.Zero:
    xor eax, eax
.Out:
    ret
.None:
    mov rax, -1
    ret

EmitFrameOf:
    push rbx
    push r12
    sub rsp, 8
    mov rbx, rcx
    test rbx, rbx
    jnz .Up
    cmp qword [rel CurHeap], 0
    je .NotHeap
    CompilePrim PrimPushFrame
    jmp .Out
.Up:
    mov rax, [rel ScopeCount]
    sub rax, rbx
    shl rax, 6
    lea rdx, [rel ScopeTab]
    cmp qword [rdx + rax + 56], 0
    je .NotHeap
    cmp qword [rel CurLinkOff], 0
    jl .NotHeap
    CompilePrim PrimLocalGet
    mov rcx, [rel CurLinkOff]
    call Compile
    mov r12, 1
.Chain:
    cmp r12, rbx
    jae .Out
    CompilePrim PrimFetchOff
    mov rax, [rel ScopeCount]
    sub rax, r12
    shl rax, 6
    lea rdx, [rel ScopeTab]
    mov rcx, [rdx + rax + 40]
    call Compile
    inc r12
    jmp .Chain
.Out:
    add rsp, 8
    pop r12
    pop rbx
    ret
.NotHeap:
    Fail ErrScopeFrame

EmitScopedLoad:
    push rcx
    push rcx
    shr rcx, 16
    call EmitFrameOf
    CompilePrim PrimFetchOff
    pop rcx
    pop rcx
    and rcx, 0xFFF8
    jmp Compile

EmitScopedStore:
    push rcx
    push rcx
    shr rcx, 16
    call EmitFrameOf
    CompilePrim PrimStoreOff
    pop rcx
    pop rcx
    and rcx, 0xFFF8
    jmp Compile

EmitReturn:
    cmp qword [rel CurHeap], 0
    jne .Heap
    CompilePrim PrimReturn
    ret
.Heap:
    CompilePrim PrimReturnHeap
    ret

EmitNestValue:
    push rax
    push rax
    mov rcx, [rax - SigFlags]
    shr rcx, 8
    call OwnerDistance
    cmp rax, -1
    je .Bad
    mov rcx, rax
    call EmitFrameOf
    CompilePrim PrimLit
    mov rcx, [rsp]
    call Compile
    CompileNum 1
    CompilePrim PrimMakeClosure
    pop rcx
    pop rcx
    call FuncTypeOfSig
    mov [rel ExprType], rax
    ret
.Bad:
    Fail ErrNestCall
