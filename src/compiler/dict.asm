%include "macros.inc"

%define HashSize 65536
%define HashMask 65535
%define HashTempMax 65536


global FindWord
global Latest
extern SayWord
extern SetWord
extern KeepWord
extern IfWord
extern OtherwiseWord
extern EndWord
extern RecordWord
extern InterfaceWord
extern TypeWord
extern RepeatWord
extern StopWord
extern SkipWord
extern DoWord
extern ReturnWord
extern ByeWord
extern FailWord
extern WaitWord
extern SettingWord
extern SpawnTaskWord
extern SpawnThreadWord
extern SpawnAfterWord
extern SpawnEveryWord
extern SpawnWhenWord
extern NamePrefixLen
extern NamePrefixPtr
extern HintElse
extern HintElif
extern HintThen
extern HintFor
extern HintWhile
extern HintFunction
extern HintLocal
extern KindWord
extern CheckWord
extern IsWord
extern TryWord
extern LaterWord
extern UseWord
extern DllWord

section .data
DefImm "say", SayWord
DefImm "print", SayWord
DefImm "set", SetWord
DefImm "keep", KeepWord
DefImm "if", IfWord
DefImm "otherwise", OtherwiseWord
DefImm "end", EndWord
DefImm "repeat", RepeatWord
DefImm "stop", StopWord
DefImm "skip", SkipWord
DefImm "do", DoWord
DefImm "return", ReturnWord
DefImm "bye", ByeWord
DefImm "fail", FailWord
DefImm "wait", WaitWord
DefImm "setting", SettingWord
DefImm "__task", SpawnTaskWord
DefImm "__thread", SpawnThreadWord
DefImm "__after", SpawnAfterWord
DefImm "__every", SpawnEveryWord
DefImm "__when", SpawnWhenWord
DefImm "kind", KindWord
DefImm "record", RecordWord
DefImm "interface", InterfaceWord
DefImm "type", TypeWord
DefImm "check", CheckWord
DefImm "is", IsWord
DefImm "try", TryWord
DefImm "later", LaterWord
DefImm "use", UseWord
DefImm "dll", DllWord
DefImm "else", HintElse
DefImm "elif", HintElif
DefImm "elseif", HintElif
DefImm "then", HintThen
DefImm "for", HintFor
DefImm "while", HintWhile
DefImm "function", HintFunction
DefImm "def", HintFunction
DefImm "func", HintFunction
DefImm "fn", HintFunction
DefImm "local", HintLocal
DefImm "let", HintLocal
DefImm "var", HintLocal
Latest dq LastEntry

section .text
FindWord:
    cmp byte [rel HashOff], 0
    jne FindWordSlow
    mov r8, [rel Latest]
    cmp r8, [rel HashedLatest]
    je .Synced
    call HashSync
    cmp byte [rel HashOff], 0
    jne FindWordSlow
.Synced:
    push rcx
    push rdx
    call HashName
    pop rdx
    pop rcx
    lea r9, [rel HashTab]
.Probe:
    and eax, HashMask
    mov r8, [r9 + rax * 8]
    test r8, r8
    jz .NotFound
    movzx r11d, byte [r8 + 17]
    cmp r11, rdx
    jne .Again
    push rax
    xor r11d, r11d
.Compare:
    cmp r11, rdx
    je .Hit
    mov al, [rcx + r11]
    cmp al, [r8 + 18 + r11]
    jne .Miss
    inc r11
    jmp .Compare
.Miss:
    pop rax
.Again:
    inc eax
    jmp .Probe
.Hit:
    pop rax
    mov rax, [r8 + 8]
    movzx edx, byte [r8 + 16]
    ret

FindWordSlow:
    mov r8, [rel Latest]
.Next:
    test r8, r8
    jz FindWord.NotFound
    movzx r9d, byte [r8 + 17]
    cmp r9, rdx
    jne .Skip
    xor r11d, r11d
.Compare:
    cmp r11, rdx
    je .Found
    mov al, [rcx + r11]
    cmp al, [r8 + 18 + r11]
    jne .Skip
    inc r11
    jmp .Compare
.Skip:
    mov r8, [r8]
    jmp .Next
.Found:
    mov rax, [r8 + 8]
    movzx edx, byte [r8 + 16]
    ret

HashName:
    mov eax, 2166136261
    xor r11d, r11d
.Loop:
    cmp r11, rdx
    je .Done
    movzx r8d, byte [rcx + r11]
    xor eax, r8d
    imul eax, eax, 16777619
    inc r11
    jmp .Loop
.Done:
    ret

HashSync:
    push r10
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    mov rbx, [rel Latest]
    lea rdi, [rel HashTemp]
    xor esi, esi
.Walk:
    cmp rbx, [rel HashedLatest]
    je .Insert
    test rbx, rbx
    jz .Rebuild
    cmp rsi, HashTempMax
    jae .Rebuild
    mov [rdi + rsi * 8], rbx
    inc rsi
    mov rbx, [rbx]
    jmp .Walk
.Insert:
    test rsi, rsi
    jz .Done
    dec rsi
    mov rbx, [rdi + rsi * 8]
    mov r10b, 1
    call HashPut
    jmp .Insert
.Rebuild:
    lea rdi, [rel HashTab]
    mov ecx, HashSize
    xor eax, eax
    rep stosq
    mov qword [rel HashCount], 0
    mov rbx, [rel Latest]
.All:
    test rbx, rbx
    jz .Done
    xor r10d, r10d
    call HashPut
    mov rbx, [rbx]
    jmp .All
.Done:
    mov rax, [rel Latest]
    mov [rel HashedLatest], rax
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop r10
    ret

HashPut:
    push r10
    lea rcx, [rbx + 18]
    movzx edx, byte [rbx + 17]
    call HashName
    pop r10
    lea r9, [rel HashTab]
.Probe:
    and eax, HashMask
    mov r8, [r9 + rax * 8]
    test r8, r8
    jz .Empty
    movzx r11d, byte [r8 + 17]
    cmp r11, rdx
    jne .Again
    push rsi
    push rdi
    push rcx
    lea rsi, [r8 + 18]
    mov rdi, rcx
    mov rcx, rdx
    repe cmpsb
    pop rcx
    pop rdi
    pop rsi
    jne .Again
    test r10b, r10b
    jz .Keep
    mov [r9 + rax * 8], rbx
.Keep:
    ret
.Again:
    inc eax
    jmp .Probe
.Empty:
    mov [r9 + rax * 8], rbx
    inc qword [rel HashCount]
    cmp qword [rel HashCount], HashSize * 3 / 4
    jb .Keep
    mov byte [rel HashOff], 1
    ret

FindWord.NotFound:
    cmp qword [rel NamePrefixLen], 0
    je .None
    cmp byte [rel InRetry], 0
    jne .None
    mov r8, [rel NamePrefixLen]
    lea r9, [r8 + rdx]
    cmp r9, 250
    ja .None
    push rsi
    push rdi
    push rcx
    push rdx
    lea rdi, [rel RetryBuf]
    mov rsi, [rel NamePrefixPtr]
    mov rcx, r8
    rep movsb
    pop rdx
    pop rsi
    push rsi
    push rdx
    mov rcx, rdx
    rep movsb
    pop rdx
    pop rcx
    pop rdi
    pop rsi
    push rcx
    push rdx
    lea rcx, [rel RetryBuf]
    add rdx, [rel NamePrefixLen]
    mov byte [rel InRetry], 1
    call FindWord
    mov byte [rel InRetry], 0
    test rax, rax
    jz .Restore
    add rsp, 16
    ret
.Restore:
    pop rdx
    pop rcx
.None:
    xor eax, eax
    ret

section .bss
HashTab resq HashSize
HashTemp resq HashTempMax
HashedLatest resq 1
HashCount resq 1
HashOff resb 8
InRetry  resb 8
RetryBuf resb 512
