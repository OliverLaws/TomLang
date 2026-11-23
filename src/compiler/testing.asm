global TransformSource
global TestMode
extern SysAlloc

section .bss
TestMode   resq 1
Depth      resq 1
LnEnd      resq 1
LnCode     resq 1
FirstPtr   resq 1
FirstLen   resq 1
EndPos     resq 64
EndN       resq 1
ModeStack  resb 64
TaskTop    resq 1
TaskStack  resq 5 * 256
TaskKind   resq 1
AliasN     resq 1
AliasTab   resq 4 * 32
RnMode     resb 64
CmpUsed    resq 1
OpPos      resq 1
OpLen      resq 1
OpName     resq 1
TestCount  resq 1
TestNames  resq 4096 * 2
TestMain   resq 1
OutStart   resq 1
LineNo     resq 1

section .data
WordTest   db "test "
WordExpect db "expect "
DoText     db "do _tlTest"
DoTextLen  equ $ - DoText
ExpText    db "if not ("
ExpTextLen equ $ - ExpText
ExpMid     db ') fail "'
ExpMidLen  equ $ - ExpMid
ExpLine    db "line "
ExpLineLen equ $ - ExpLine
ExpWord    db "expected "
ExpWordLen equ $ - ExpWord
ExpEnd     db '" end'
ExpEndLen  equ $ - ExpEnd
Prelude:
    db 10
PreludeLen equ $ - Prelude
CmpPrelude:
    db "set _tlLastGot = ", 34, 34, 10
    db "do _tlEq(a, b): bool", 10, "    _tlLastGot = ", 34, "{a}", 34, 10, "    return a == b", 10, "end", 10
    db "do _tlNe(a, b): bool", 10, "    _tlLastGot = ", 34, "{a}", 34, 10, "    return a != b", 10, "end", 10
    db "do _tlLt(a, b): bool", 10, "    _tlLastGot = ", 34, "{a}", 34, 10, "    return a < b", 10, "end", 10
    db "do _tlGt(a, b): bool", 10, "    _tlLastGot = ", 34, "{a}", 34, 10, "    return a > b", 10, "end", 10
    db "do _tlLe(a, b): bool", 10, "    _tlLastGot = ", 34, "{a}", 34, 10, "    return a <= b", 10, "end", 10
    db "do _tlGe(a, b): bool", 10, "    _tlLastGot = ", 34, "{a}", 34, 10, "    return a >= b", 10, "end", 10
CmpPreludeLen equ $ - CmpPrelude
CmpIf      db "if not _tl"
CmpIfLen   equ $ - CmpIf
CmpGot     db ", got {_tlLastGot}"
CmpGotLen  equ $ - CmpGot
TestPrelude:
    db "set _tlPassed = 0", 10
    db "set _tlFailed = 0", 10
    db "do _tlRun(name: text, body: do())", 10
    db "    try", 10
    db "        body()", 10
    db "        _tlPassed += 1", 10
    db "        say ", 34, "  ok    {name}", 34, 10
    db "    otherwise", 10
    db "        _tlFailed += 1", 10
    db "        say ", 34, "  FAIL  {name}: {error}", 34, 10
    db "    end", 10
    db "end", 10
    db "say ", 34, 34, 10
TestPreludeLen equ $ - TestPrelude
TestEnding:
    db "say ", 34, 34, 10
    db "say ", 34, "{_tlPassed} passed, {_tlFailed} failed", 34, 10
TestEndingLen equ $ - TestEnding
TaskHead   db "do _tlTask"
TaskHeadLen equ $ - TaskHead
SpawnEvery db " __every("
SpawnEveryLen equ $ - SpawnEvery
SpawnAfter db " __after("
SpawnAfterLen equ $ - SpawnAfter
SpawnTask  db " __task("
SpawnTaskLen equ $ - SpawnTask
SpawnThread  db " __thread("
SpawnThreadLen equ $ - SpawnThread
SpawnWhen  db " __when(() => "
SpawnWhenLen equ $ - SpawnWhen
SpawnMid   db ", _tlTask"
SpawnMidLen equ $ - SpawnMid
RunText    db "_tlRun("
RunTextLen equ $ - RunText
RunMid     db ", _tlTest"
RunMidLen  equ $ - RunMid

section .text

LineKind:
    mov r10, rsi
.Indent:
    cmp r10, r9
    jae .None
    mov al, [r10]
    cmp al, ' '
    je .Next
    cmp al, 9
    je .Next
    jmp .Word
.Next:
    inc r10
    jmp .Indent
.Word:
    lea rax, [r10 + 6]
    cmp rax, r9
    jae .None
    mov eax, [r10]
    cmp eax, 'test'
    jne .TryExpect
    cmp byte [r10 + 4], ' '
    jne .TryExpect
    lea r11, [r10 + 5]
.TestSpace:
    cmp r11, r9
    jae .None
    cmp byte [r11], ' '
    jne .TestQuote
    inc r11
    jmp .TestSpace
.TestQuote:
    cmp byte [r11], '"'
    jne .None
    mov eax, 1
    ret
.TryExpect:
    lea rax, [r10 + 8]
    cmp rax, r9
    jae .None
    mov eax, [r10]
    cmp eax, 'expe'
    jne .None
    cmp word [r10 + 4], 'ct'
    jne .None
    cmp byte [r10 + 6], ' '
    jne .None
    lea r11, [r10 + 7]
.ExpSpace:
    cmp r11, r9
    jae .None
    cmp byte [r11], ' '
    jne .ExpWord
    inc r11
    jmp .ExpSpace
.ExpWord:
    mov al, [r11]
    cmp al, '='
    je .None
    cmp al, 10
    je .None
    cmp al, 13
    je .None
    cmp al, '+'
    je .None
    mov eax, 2
    ret
.None:
    xor eax, eax
    ret

LineEnd:
    mov rax, rsi
.Loop:
    cmp rax, r9
    jae .Done
    cmp byte [rax], 10
    je .Done
    inc rax
    jmp .Loop
.Done:
    ret

PutByte:
    mov [rdi], al
    inc rdi
    ret

PutRange:
    push rax
.Loop:
    cmp rcx, rdx
    jae .Done
    mov al, [rcx]
    mov [rdi], al
    inc rdi
    inc rcx
    jmp .Loop
.Done:
    pop rax
    ret

PutNumber:
    push rbx
    push rcx
    push rdx
    push r11
    sub rsp, 32
    mov rbx, rsp
    xor ecx, ecx
.Digit:
    xor edx, edx
    mov r11, 10
    div r11
    add dl, '0'
    mov [rbx + rcx], dl
    inc rcx
    test rax, rax
    jnz .Digit
.Out:
    dec rcx
    mov al, [rbx + rcx]
    mov [rdi], al
    inc rdi
    test rcx, rcx
    jnz .Out
    add rsp, 32
    pop r11
    pop rdx
    pop rcx
    pop rbx
    ret

IsWordByte:
    cmp al, '_'
    je .Yes
    cmp al, '0'
    jb .No
    cmp al, '9'
    jbe .Yes
    cmp al, 'A'
    jb .No
    cmp al, 'Z'
    jbe .Yes
    cmp al, 'a'
    jb .No
    cmp al, 'z'
    jbe .Yes
    cmp al, 128
    jae .Yes
.No:
    xor edx, edx
    ret
.Yes:
    mov edx, 1
    ret

ScanWords:
    push rbx
    push rcx
    push rdx
    push r8
    mov qword [rel EndN], 0
    mov qword [rel FirstLen], 0
    mov rbx, rsi
    xor r8d, r8d
.Loop:
    cmp rbx, r9
    jae .Stop
    mov al, [rbx]
    cmp al, 10
    je .Stop
    test r8, r8
    jz .Code
    lea rcx, [rel ModeStack]
    cmp byte [rcx + r8 - 1], 'S'
    jne .Code
    cmp al, '\'
    jne .StrNotEsc
    add rbx, 2
    jmp .Loop
.StrNotEsc:
    cmp al, '"'
    jne .StrNotEnd
    dec r8
    inc rbx
    jmp .Loop
.StrNotEnd:
    cmp al, '{'
    jne .StrNext
    cmp r8, 60
    jae .StrNext
    mov byte [rcx + r8], 'C'
    inc r8
.StrNext:
    inc rbx
    jmp .Loop
.Code:
    cmp al, '"'
    jne .NotQuote
    cmp r8, 60
    jae .Skip1
    lea rcx, [rel ModeStack]
    mov byte [rcx + r8], 'S'
    inc r8
.Skip1:
    inc rbx
    jmp .Loop
.NotQuote:
    cmp al, '}'
    jne .NotClose
    test r8, r8
    jz .Skip1
    dec r8
    inc rbx
    jmp .Loop
.NotClose:
    test r8, r8
    jnz .NotComment
    cmp al, '#'
    je .Stop
.NotComment:
    call IsWordByte
    test edx, edx
    jz .Skip1
    mov rcx, rbx
.Word:
    inc rbx
    cmp rbx, r9
    jae .WordDone
    mov al, [rbx]
    call IsWordByte
    test edx, edx
    jnz .Word
.WordDone:
    mov rdx, rbx
    sub rdx, rcx
    test r8, r8
    jnz .Loop
    cmp qword [rel FirstLen], 0
    jne .NotFirst
    mov [rel FirstPtr], rcx
    mov [rel FirstLen], rdx
.NotFirst:
    cmp rdx, 3
    jne .Loop
    cmp word [rcx], 'en'
    jne .Loop
    cmp byte [rcx + 2], 'd'
    jne .Loop
    mov rax, [rel EndN]
    cmp rax, 64
    jae .Loop
    lea rdx, [rel EndPos]
    mov [rdx + rax * 8], rbx
    inc qword [rel EndN]
    jmp .Loop
.Stop:
    mov rax, rbx
.Trim:
    cmp rax, rsi
    jbe .Trimmed
    mov cl, [rax - 1]
    cmp cl, ' '
    je .TrimOne
    cmp cl, 9
    je .TrimOne
    cmp cl, 13
    je .TrimOne
    jmp .Trimmed
.TrimOne:
    dec rax
    jmp .Trim
.Trimmed:
    mov [rel LnCode], rax
    mov rax, rbx
.ToEnd:
    cmp rax, r9
    jae .Ended
    cmp byte [rax], 10
    je .Ended
    inc rax
    jmp .ToEnd
.Ended:
    mov [rel LnEnd], rax
    pop r8
    pop rdx
    pop rcx
    pop rbx
    ret

FirstIs:
    cmp [rel FirstLen], rdx
    jne .No
    push rsi
    push rdi
    push rcx
    mov rsi, [rel FirstPtr]
    mov rdi, rcx
    mov rcx, rdx
    repe cmpsb
    pop rcx
    pop rdi
    pop rsi
    jne .No
    mov eax, 1
    ret
.No:
    xor eax, eax
    ret

%macro IsFirst 1
[section .data]
%%Str: db %1
%%End:
__SECT__
    lea rcx, [rel %%Str]
    mov edx, %%End - %%Str
    call FirstIs
%endmacro

AfterFirst:
    mov rax, [rel FirstPtr]
    add rax, [rel FirstLen]
.Space:
    cmp rax, [rel LnCode]
    jae .Done
    cmp byte [rax], ' '
    je .Next
    cmp byte [rax], 9
    jne .Done
.Next:
    inc rax
    jmp .Space
.Done:
    ret

TaskLineKind:
    cmp qword [rel FirstLen], 0
    je .None
    call AfterFirst
    mov r10, rax
    IsFirst "task"
    test eax, eax
    jz .NotTask
    cmp r10, [rel LnCode]
    jb .None
    mov eax, 5
    ret
.NotTask:
    IsFirst "thread"
    test eax, eax
    jz .NotThread
    cmp r10, [rel LnCode]
    jb .None
    mov eax, 7
    ret
.NotThread:
    cmp r10, [rel LnCode]
    jae .None
    mov al, [r10]
    cmp al, '='
    je .None
    cmp al, '('
    je .None
    cmp al, ','
    je .None
    cmp al, '.'
    je .None
    cmp byte [r10 + 1], '='
    jne .Keyword
    cmp al, '+'
    je .None
    cmp al, '-'
    je .None
    cmp al, '*'
    je .None
    cmp al, '/'
    je .None
.Keyword:
    IsFirst "every"
    test eax, eax
    jz .NotEvery
    mov eax, 3
    ret
.NotEvery:
    IsFirst "after"
    test eax, eax
    jz .NotAfter
    mov eax, 4
    ret
.NotAfter:
    IsFirst "when"
    test eax, eax
    jz .None
    mov eax, 6
    ret
.None:
    xor eax, eax
    ret

IsOpener:
    cmp qword [rel FirstPtr], 0
    je .No
    cmp qword [rel FirstLen], 0
    je .No
    IsFirst "do"
    test eax, eax
    jnz .Yes
    IsFirst "if"
    test eax, eax
    jnz .Yes
    IsFirst "repeat"
    test eax, eax
    jnz .Yes
    IsFirst "check"
    test eax, eax
    jnz .Yes
    IsFirst "try"
    test eax, eax
    jnz .Yes
    IsFirst "dll"
    test eax, eax
    jnz .Yes
    IsFirst "record"
    test eax, eax
    jnz .MaybeEq
    IsFirst "interface"
    test eax, eax
    jnz .MaybeEq
    IsFirst "kind"
    test eax, eax
    jnz .MaybeEq
.No:
    xor eax, eax
    ret
.MaybeEq:
    mov rax, [rel FirstPtr]
.EqScan:
    cmp rax, [rel LnCode]
    jae .Yes
    cmp byte [rax], '='
    je .No
    inc rax
    jmp .EqScan
.Yes:
    mov eax, 1
    ret

PutSpawn:
    push rbx
    mov rbx, [rel TaskTop]
    dec rbx
    mov [rel TaskTop], rbx
    imul rbx, rbx, 40
    lea rax, [rel TaskStack]
    add rbx, rax
    mov rax, [rbx + 8]
    cmp rax, 3
    je .Every
    cmp rax, 4
    je .After
    cmp rax, 5
    je .Task
    cmp rax, 7
    je .Thread
    lea rcx, [rel SpawnWhen]
    lea rdx, [rcx + SpawnWhenLen]
    jmp .Head
.Every:
    lea rcx, [rel SpawnEvery]
    lea rdx, [rcx + SpawnEveryLen]
    jmp .Head
.After:
    lea rcx, [rel SpawnAfter]
    lea rdx, [rcx + SpawnAfterLen]
    jmp .Head
.Task:
    lea rcx, [rel SpawnTask]
    lea rdx, [rcx + SpawnTaskLen]
    call PutRange
    jmp .Name
.Thread:
    lea rcx, [rel SpawnThread]
    lea rdx, [rcx + SpawnThreadLen]
    call PutRange
    jmp .Name
.Head:
    call PutRange
    mov rcx, [rbx + 24]
    mov rdx, [rbx + 32]
    call PutRange
    lea rcx, [rel SpawnMid]
    lea rdx, [rcx + SpawnMidLen]
    call PutRange
    mov rax, [rbx + 16]
    call PutNumber
    mov byte [rdi], ')'
    inc rdi
    pop rbx
    ret
.Name:
    mov word [rdi], '_t'
    mov byte [rdi + 2], 'l'
    add rdi, 3
    mov dword [rdi], 'Task'
    add rdi, 4
    mov rax, [rbx + 16]
    call PutNumber
    mov byte [rdi], ')'
    inc rdi
    pop rbx
    ret

CopyWithEnds:
    push rbx
    push r12
    mov rcx, rsi
    xor r12d, r12d
.Each:
    cmp r12, [rel EndN]
    jae .Rest
    lea rax, [rel EndPos]
    mov rbx, [rax + r12 * 8]
    dec qword [rel Depth]
    mov rax, [rel TaskTop]
    test rax, rax
    jz .NextEnd
    dec rax
    imul rax, rax, 40
    lea rdx, [rel TaskStack]
    mov rax, [rdx + rax]
    cmp rax, [rel Depth]
    jne .NextEnd
    mov rdx, rbx
    call PutRange
    call PutSpawn
    mov rcx, rbx
.NextEnd:
    inc r12
    jmp .Each
.Rest:
    mov rdx, [rel LnEnd]
    call PutRange
    pop r12
    pop rbx
    ret

FindCompare:
    push rbx
    mov r8, r14
    xor r10d, r10d
    xor r11d, r11d
    mov qword [rel OpPos], 0
.Loop:
    cmp r8, rbx
    jae .End
    mov al, [r8]
    cmp al, '"'
    je .String
    cmp al, '('
    je .Open
    cmp al, '['
    je .Open
    cmp al, '{'
    je .Open
    cmp al, ')'
    je .Close
    cmp al, ']'
    je .Close
    cmp al, '}'
    je .Close
    test r10, r10
    jnz .Next
    mov dl, [r8 + 1]
    cmp al, '='
    jne .NotEq
    cmp dl, '>'
    je .Skip2
    cmp dl, '='
    jne .Next
    mov eax, 'Eq'
    jmp .Found2
.NotEq:
    cmp al, '!'
    jne .NotNe
    cmp dl, '='
    jne .Next
    mov eax, 'Ne'
    jmp .Found2
.NotNe:
    cmp al, '<'
    jne .NotLt
    cmp dl, '<'
    je .Skip2
    cmp dl, '='
    jne .Lt1
    mov eax, 'Le'
    jmp .Found2
.Lt1:
    mov eax, 'Lt'
    jmp .Found1
.NotLt:
    cmp al, '>'
    jne .Word
    cmp dl, '>'
    je .Skip2
    movzx ecx, byte [r8 - 1]
    cmp cl, '|'
    je .Next
    cmp dl, '='
    jne .Gt1
    mov eax, 'Ge'
    jmp .Found2
.Gt1:
    mov eax, 'Gt'
    jmp .Found1
.Word:
    cmp al, 'a'
    jne .MaybeOr
    lea rcx, [r8 + 3]
    cmp rcx, rbx
    ja .Next
    cmp word [r8], 'an'
    jne .Next
    cmp byte [r8 + 2], 'd'
    jne .Next
    mov dl, 3
    jmp .Bound
.MaybeOr:
    cmp al, 'o'
    jne .MaybeNot
    lea rcx, [r8 + 2]
    cmp rcx, rbx
    ja .Next
    cmp word [r8], 'or'
    jne .Next
    mov dl, 2
    jmp .Bound
.MaybeNot:
    cmp al, 'n'
    jne .Next
    lea rcx, [r8 + 3]
    cmp rcx, rbx
    ja .Next
    cmp word [r8], 'no'
    jne .Next
    cmp byte [r8 + 2], 't'
    jne .Next
    mov dl, 3
.Bound:
    cmp r8, r14
    je .BoundAfter
    mov al, [r8 - 1]
    call IsWordByteSafe
    jnz .Next
.BoundAfter:
    movzx ecx, dl
    lea rcx, [r8 + rcx]
    cmp rcx, rbx
    jae .Bad
    mov al, [rcx]
    call IsWordByteSafe
    jnz .Next
.Bad:
    mov qword [rel OpPos], 0
    mov r11, 99
    jmp .Next
.Found1:
    mov ecx, 1
    jmp .Record
.Found2:
    mov ecx, 2
.Record:
    inc r11
    mov [rel OpPos], r8
    mov [rel OpLen], rcx
    mov [rel OpName], rax
    add r8, rcx
    jmp .Loop
.Skip2:
    add r8, 2
    jmp .Loop
.String:
    inc r8
.StrLoop:
    cmp r8, rbx
    jae .End
    mov al, [r8]
    inc r8
    cmp al, 92
    jne .StrNotEsc
    inc r8
    jmp .StrLoop
.StrNotEsc:
    cmp al, '"'
    jne .StrLoop
    jmp .Loop
.Open:
    inc r10
    jmp .Next
.Close:
    dec r10
.Next:
    inc r8
    jmp .Loop
.End:
    cmp r11, 1
    je .Done
    mov qword [rel OpPos], 0
.Done:
    pop rbx
    ret

IsWordByteSafe:
    push rdx
    call IsWordByte
    test edx, edx
    pop rdx
    ret

SkipSpaces:
.Loop:
    cmp rsi, r9
    jae .Done
    cmp byte [rsi], ' '
    je .Next
    cmp byte [rsi], 9
    jne .Done
.Next:
    inc rsi
    jmp .Loop
.Done:
    ret

ReadWord:
    mov rax, rsi
.Loop:
    cmp rsi, r9
    jae .Done
    mov al, [rsi]
    push rdx
    call IsWordByte
    test edx, edx
    pop rdx
    jz .Done
    inc rsi
    jmp .Loop
.Done:
    mov rax, rcx
    ret

SettingAlias:
    push rsi
    call SkipSpaces
    lea rax, [rsi + 8]
    cmp rax, r9
    jae .No
    cmp dword [rsi], 'sett'
    jne .No
    cmp dword [rsi + 4], 'ing '
    jne .No
    add rsi, 8
    call SkipSpaces
    mov r10, rsi
    mov rcx, rsi
    call ReadWord
    mov r11, rsi
    sub r11, r10
    jz .No
    call SkipSpaces
    lea rax, [rsi + 4]
    cmp rax, r9
    ja .No
    cmp dword [rsi], 'word'
    jne .No
    add rsi, 4
    call SkipSpaces
    cmp rsi, r9
    jae .No
    cmp byte [rsi], '='
    jne .No
    inc rsi
    call SkipSpaces
    cmp rsi, r9
    jae .No
    cmp byte [rsi], '"'
    jne .No
    inc rsi
    mov r8, rsi
    mov rcx, rsi
    call ReadWord
    cmp rsi, r9
    jae .No
    cmp byte [rsi], '"'
    jne .No
    mov rax, rsi
    sub rax, r8
    jz .No
    mov rcx, [rel AliasN]
    cmp rcx, 32
    jae .Yes
    shl rcx, 5
    lea rdx, [rel AliasTab]
    mov [rdx + rcx], r10
    mov [rdx + rcx + 8], r11
    mov [rdx + rcx + 16], r8
    mov [rdx + rcx + 24], rax
    inc qword [rel AliasN]
.Yes:
    pop rsi
    mov eax, 1
    ret
.No:
    pop rsi
    xor eax, eax
    ret

RenamePass:
    mov qword [rel AliasN], 0
    mov rsi, r12
    lea r9, [r12 + r13]
.Find:
    cmp rsi, r9
    jae .Found
    call SettingAlias
    call LineEnd
    lea rsi, [rax + 1]
    jmp .Find
.Found:
    cmp qword [rel AliasN], 0
    jne .Rewrite
    ret
.Rewrite:
    lea rcx, [r13 * 4 + 4096]
    push r9
    call SysAlloc
    pop r9
    test rax, rax
    jnz .Have
    ret
.Have:
    push rax
    mov rdi, rax
    mov rsi, r12
    xor r15d, r15d
.Line:
    cmp rsi, r9
    jae .Done
    call SettingAlias
    test eax, eax
    jz .Chars
    call LineEnd
    mov rsi, rax
    jmp .Newline
.Chars:
    cmp rsi, r9
    jae .Done
    mov al, [rsi]
    cmp al, 10
    je .Newline
    test r15, r15
    jz .CodeChar
    lea rcx, [rel RnMode]
    cmp byte [rcx + r15 - 1], 'S'
    jne .CodeChar
    cmp al, 92
    jne .StrNotEsc
    movsb
    cmp rsi, r9
    jae .Done
    movsb
    jmp .Chars
.StrNotEsc:
    cmp al, '"'
    jne .StrNotEnd
    dec r15
    movsb
    jmp .Chars
.StrNotEnd:
    cmp al, '{'
    jne .StrPlain
    cmp r15, 60
    jae .StrPlain
    mov byte [rcx + r15], 'C'
    inc r15
.StrPlain:
    movsb
    jmp .Chars
.CodeChar:
    cmp al, '"'
    jne .NotQuote
    cmp r15, 60
    jae .Copy1
    lea rcx, [rel RnMode]
    mov byte [rcx + r15], 'S'
    inc r15
    jmp .Copy1
.NotQuote:
    cmp al, '}'
    jne .NotClose
    test r15, r15
    jz .Copy1
    dec r15
    jmp .Copy1
.NotClose:
    test r15, r15
    jnz .NotComment
    cmp al, '#'
    jne .NotComment
.Comment:
    cmp rsi, r9
    jae .Done
    cmp byte [rsi], 10
    je .Newline
    movsb
    jmp .Comment
.NotComment:
    push rdx
    call IsWordByte
    test edx, edx
    pop rdx
    jz .Copy1
    mov rcx, rsi
    call ReadWord
    mov rdx, rsi
    sub rdx, rcx
    mov r10, rcx
    xor r8d, r8d
.Alias:
    cmp r8, [rel AliasN]
    jae .Keep
    mov rax, r8
    shl rax, 5
    lea r11, [rel AliasTab]
    add r11, rax
    cmp [r11 + 24], rdx
    jne .AliasNext
    push rsi
    push rdi
    push rcx
    mov rsi, r10
    mov rdi, [r11 + 16]
    mov rcx, rdx
    repe cmpsb
    pop rcx
    pop rdi
    pop rsi
    jne .AliasNext
    push rsi
    mov rsi, [r11]
    mov rcx, [r11 + 8]
    rep movsb
    pop rsi
    jmp .Chars
.AliasNext:
    inc r8
    jmp .Alias
.Keep:
    push rsi
    mov rsi, r10
    mov rcx, rdx
    rep movsb
    pop rsi
    jmp .Chars
.Copy1:
    movsb
    jmp .Chars
.Newline:
    cmp rsi, r9
    jae .Done
    movsb
    xor r15d, r15d
    jmp .Line
.Done:
    pop r12
    mov r13, rdi
    sub r13, r12
    ret

TransformSource:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    mov r12, rcx
    mov r13, rdx
    mov [rel TestMain], r8
    call RenamePass
    mov rsi, r12
    lea r9, [r12 + r13]
.Scan:
    cmp rsi, r9
    jae .Unchanged
    call LineKind
    test eax, eax
    jnz .Rewrite
    call ScanWords
    call TaskLineKind
    test eax, eax
    jnz .Rewrite
    call LineEnd
    lea rsi, [rax + 1]
    jmp .Scan
.Unchanged:
    mov rax, r12
    mov rdx, r13
    jmp .Return
.Rewrite:
    lea rcx, [r13 * 4 + 65536]
    mov rax, [rel TestCount]
    shl rax, 7
    add rcx, rax
    call SysAlloc
    test rax, rax
    jz .Unchanged
    mov rdi, rax
    mov [rel OutStart], rax
    mov rsi, r12
    lea r9, [r12 + r13]
    mov qword [rel LineNo], 1
    mov qword [rel Depth], 0
    mov qword [rel TaskTop], 0
    mov qword [rel CmpUsed], 0
.Line:
    cmp rsi, r9
    jae .Finish
    call LineKind
    cmp eax, 1
    je .TestLine
    cmp eax, 2
    je .ExpectLine
    call ScanWords
    call TaskLineKind
    test eax, eax
    jnz .TaskLine
    call IsOpener
    add [rel Depth], rax
    call CopyWithEnds
    mov rsi, [rel LnEnd]
    jmp .NextLine
.TaskLine:
    mov [rel TaskKind], rax
    mov rcx, rsi
    mov rdx, [rel FirstPtr]
    call PutRange
    lea rcx, [rel TaskHead]
    lea rdx, [rcx + TaskHeadLen]
    call PutRange
    inc qword [rel TestCount]
    mov rax, [rel TestCount]
    call PutNumber
    mov word [rdi], '()'
    add rdi, 2
    mov rax, [rel TaskTop]
    cmp rax, 256
    jae .TaskSkip
    imul rax, rax, 40
    lea rbx, [rel TaskStack]
    add rbx, rax
    mov rax, [rel Depth]
    mov [rbx], rax
    mov rax, [rel TaskKind]
    mov [rbx + 8], rax
    mov rax, [rel TestCount]
    mov [rbx + 16], rax
    call AfterFirst
    mov [rbx + 24], rax
    mov rax, [rel LnCode]
    mov [rbx + 32], rax
    inc qword [rel TaskTop]
.TaskSkip:
    inc qword [rel Depth]
    mov rsi, [rel LnEnd]
    jmp .NextLine
.TestLine:
    mov rcx, rsi
    mov rdx, r10
    call PutRange
    lea rcx, [rel DoText]
    lea rdx, [rcx + DoTextLen]
    call PutRange
    inc qword [rel TestCount]
    mov rax, [rel TestCount]
    call PutNumber
    mov word [rdi], '()'
    add rdi, 2
    inc qword [rel Depth]
    lea rbx, [r11 + 1]
.NameEnd:
    cmp rbx, r9
    jae .NameDone
    mov al, [rbx]
    cmp al, 10
    je .NameDone
    cmp al, '\'
    jne .NameChar
    inc rbx
    jmp .NameNext
.NameChar:
    cmp al, '"'
    je .NameDone
.NameNext:
    inc rbx
    jmp .NameEnd
.NameDone:
    cmp qword [rel TestMain], 0
    je .SkipName
    mov rax, [rel TestCount]
    cmp rax, 4096
    ja .SkipName
    lea rcx, [rel TestNames]
    shl rax, 4
    lea rdx, [r11 + 1]
    mov [rcx + rax - 16], rdx
    mov rdx, rbx
    sub rdx, r11
    dec rdx
    mov [rcx + rax - 8], rdx
.SkipName:
    lea rcx, [rbx + 1]
    call LineEnd
    mov rdx, rax
    cmp rcx, rdx
    jbe .TestRest
    mov rcx, rdx
.TestRest:
    call PutRange
    mov rsi, rax
    jmp .NextLine
.ExpectLine:
    mov rcx, rsi
    mov rdx, r10
    call PutRange
    mov r14, r11
    call LineEnd
    mov r15, rax
    mov rbx, r14
    xor ecx, ecx
.Comment:
    cmp rbx, r15
    jae .CommentDone
    mov al, [rbx]
    cmp al, '\'
    jne .NotEscape
    test ecx, ecx
    jz .NotEscape
    add rbx, 2
    jmp .Comment
.NotEscape:
    cmp al, '"'
    jne .NotQuote
    xor ecx, 1
    jmp .CommentNext
.NotQuote:
    test ecx, ecx
    jnz .CommentNext
    cmp al, '#'
    je .CommentDone
.CommentNext:
    inc rbx
    jmp .Comment
.CommentDone:
    cmp rbx, r15
    jbe .Trim
    mov rbx, r15
.Trim:
    cmp rbx, r14
    jbe .Trimmed
    mov al, [rbx - 1]
    cmp al, ' '
    je .TrimOne
    cmp al, 9
    je .TrimOne
    cmp al, 13
    je .TrimOne
    jmp .Trimmed
.TrimOne:
    dec rbx
    jmp .Trim
.Trimmed:
    call FindCompare
    cmp qword [rel OpPos], 0
    je .PlainExpect
    mov qword [rel CmpUsed], 1
    lea rcx, [rel CmpIf]
    lea rdx, [rcx + CmpIfLen]
    call PutRange
    mov rax, [rel OpName]
    mov [rdi], ax
    add rdi, 2
    mov byte [rdi], '('
    inc rdi
    mov rcx, r14
    mov rdx, [rel OpPos]
    call PutRange
    mov word [rdi], ', '
    add rdi, 2
    mov rcx, [rel OpPos]
    add rcx, [rel OpLen]
    mov rdx, rbx
    call PutRange
    mov byte [rdi], ')'
    inc rdi
    lea rcx, [rel ExpMid + 1]
    lea rdx, [rel ExpMid + ExpMidLen]
    call PutRange
    jmp .ExpMessage
.PlainExpect:
    lea rcx, [rel ExpText]
    lea rdx, [rcx + ExpTextLen]
    call PutRange
    mov rcx, r14
    mov rdx, rbx
    call PutRange
    lea rcx, [rel ExpMid]
    lea rdx, [rcx + ExpMidLen]
    call PutRange
.ExpMessage:
    cmp qword [rel TestMode], 0
    je .NoLine
    lea rcx, [rel ExpLine]
    lea rdx, [rcx + ExpLineLen]
    call PutRange
    mov rax, [rel LineNo]
    call PutNumber
    mov word [rdi], ': '
    add rdi, 2
.NoLine:
    lea rcx, [rel ExpWord]
    lea rdx, [rcx + ExpWordLen]
    call PutRange
    mov rcx, r14
.Escape:
    cmp rcx, rbx
    jae .Escaped
    mov al, [rcx]
    cmp al, '"'
    je .Backslash
    cmp al, '\'
    je .Backslash
    cmp al, '{'
    je .Backslash
    jmp .Plain
.Backslash:
    mov byte [rdi], '\'
    inc rdi
.Plain:
    mov [rdi], al
    inc rdi
    inc rcx
    jmp .Escape
.Escaped:
    cmp qword [rel OpPos], 0
    je .NoGot
    lea rcx, [rel CmpGot]
    lea rdx, [rcx + CmpGotLen]
    call PutRange
.NoGot:
    lea rcx, [rel ExpEnd]
    lea rdx, [rcx + ExpEndLen]
    call PutRange
    mov rcx, rbx
    mov rdx, r15
    call PutRange
    mov rsi, r15
.NextLine:
    cmp rsi, r9
    jae .Finish
    mov byte [rdi], 10
    inc rdi
    inc rsi
    inc qword [rel LineNo]
    jmp .Line
.Finish:
    lea rcx, [rel Prelude]
    lea rdx, [rcx + PreludeLen]
    call PutRange
    cmp qword [rel CmpUsed], 0
    je .NoCmp
    lea rcx, [rel CmpPrelude]
    lea rdx, [rcx + CmpPreludeLen]
    call PutRange
.NoCmp:
    cmp qword [rel TestMain], 0
    je .Done
    cmp qword [rel TestMode], 0
    je .Done
    lea rcx, [rel TestPrelude]
    lea rdx, [rcx + TestPreludeLen]
    call PutRange
    mov rbx, 1
.Register:
    cmp rbx, [rel TestCount]
    ja .Ending
    cmp rbx, 4096
    ja .Ending
    lea rax, [rel TestNames]
    mov rcx, rbx
    shl rcx, 4
    mov rdx, [rax + rcx - 8]
    mov rcx, [rax + rcx - 16]
    test rcx, rcx
    jz .RegNext
    add rdx, rcx
    push rcx
    push rdx
    lea rcx, [rel RunText]
    lea rdx, [rcx + RunTextLen]
    call PutRange
    mov byte [rdi], '"'
    inc rdi
    pop rdx
    pop rcx
    call PutRange
    mov byte [rdi], '"'
    inc rdi
    lea rcx, [rel RunMid]
    lea rdx, [rcx + RunMidLen]
    call PutRange
    mov rax, rbx
    call PutNumber
    mov byte [rdi], ')'
    mov byte [rdi + 1], 10
    add rdi, 2
.RegNext:
    inc rbx
    jmp .Register
.Ending:
    lea rcx, [rel TestEnding]
    lea rdx, [rcx + TestEndingLen]
    call PutRange
.Done:
    mov rax, [rel OutStart]
    mov rdx, rdi
    sub rdx, rax
.Return:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret
