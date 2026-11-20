%include "macros.inc"

global FindWord
global Latest
extern PrimAdd
extern PrimSub
extern PrimMul
extern PrimDiv
extern PrimMod
extern PrimDup
extern PrimDrop
extern PrimSwap
extern PrimPrint
extern PrimBye
extern PrimFetch
extern PrimStore
extern PrimLess
extern PrimGreater
extern PrimEq
extern PrimNotEq
extern PrimLessEq
extern PrimGreaterEq
extern CompVariable
extern SayWord
extern SetWord
extern IfWord
extern OtherwiseWord
extern EndWord
extern RepeatWord
extern StopWord
extern SkipWord
extern DoWord
extern ReturnWord

section .data
DefWord "+", PrimAdd
DefWord "-", PrimSub
DefWord "*", PrimMul
DefWord "/", PrimDiv
DefWord "%", PrimMod
DefWord "dup", PrimDup
DefWord "drop", PrimDrop
DefWord "swap", PrimSwap
DefWord "print", PrimPrint
DefWord "bye", PrimBye
DefWord "@", PrimFetch
DefWord "!", PrimStore
DefWord "<", PrimLess
DefWord ">", PrimGreater
DefWord "==", PrimEq
DefWord "!=", PrimNotEq
DefWord "<=", PrimLessEq
DefWord ">=", PrimGreaterEq
DefImm "var", CompVariable
DefImm "say", SayWord
DefImm "set", SetWord
DefImm "keep", SetWord
DefImm "if", IfWord
DefImm "otherwise", OtherwiseWord
DefImm "end", EndWord
DefImm "repeat", RepeatWord
DefImm "stop", StopWord
DefImm "skip", SkipWord
DefImm "do", DoWord
DefImm "return", ReturnWord
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
    xor eax, eax
    ret