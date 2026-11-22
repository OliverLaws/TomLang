%include "macros.inc"

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
    mov r8, [rel Latest]
.Next:
    test r8, r8
    jz .NotFound
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
.NotFound:
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
InRetry  resb 8
RetryBuf resb 512
