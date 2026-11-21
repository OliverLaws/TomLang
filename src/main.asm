%include "macros.inc"

global Start
global Abort
global FileMode
global Warn

extern InitIO
extern PrintString
extern PrintNumber
extern PrintNewLine
extern ExitProcess
extern InitStack
extern ReadLine
extern InputBuf
extern LoadFileArg
extern SetInput
extern GetInput
extern NextToken
extern DataStack
extern ReturnStack
extern FindWord
extern CodeBuf
extern Here
extern Compile
extern OpenBlocks
extern ResetCompiler
extern StmtExpr
extern TokPtr
extern TokLen
extern ErrTokPtr
extern ErrTokLen
extern CheckMode
extern ErrPos
extern PrevTokPtr
extern MakingConst
extern EndWord
extern OtherwiseWord
extern ReturnWord
extern StopWord
extern SkipWord
extern DoWord
extern IfWord
extern RepeatWord
extern CheckWord
extern TryWord
extern IsWord
extern TryDepth
extern TryStack
extern LastError
extern MakeTextFrom

section .data
Prompt         db "> "
PromptLen      equ $ - Prompt
More           db ". "
MoreLen        equ $ - More
Underflow      db "stack underflow", 10
UnderflowLen   equ $ - Underflow
MissingEnd     db "missing its end:"
MissingEndLen  equ $ - MissingEnd
LineWord       db "line "
WarnWord       db "warning "
WarnDead       db "this line never runs (it comes after return, stop or skip)"
WarnDeadLen    equ $ - WarnDead
WarnIndent     db "this might be missing its end (the end that closes it is lined up differently):"
WarnIndentLen  equ $ - WarnIndent
IfName         db "if"
RepeatName     db "repeat"
DoName         db "do"
Colon          db ": "
Quote          db " '"
EndQuote       db "'"

%define MaxLines 65536

DoWordAddr     dq DoWord, IfWord, RepeatWord, CheckWord, TryWord

section .bss
RecoverPos  resq 1
AtEof       resq 1
LineTable   resq 2 * MaxLines
LineCount   resq 1
LinePos     resq 1
LineNum     resq 1
ReplRsp     resq 1
FileMode    resq 1
Running     resq 1
SourceStart resq 1
SourceEnd   resq 1
ErrMsg      resq 1
ErrLen      resq 1
ErrorCount  resq 1
StmtTok     resq 1
StmtTokLen  resq 1
StmtR15     resq 1
StmtBlocks  resq 1
StmtWord    resq 1
DeadCode    resq 1
BlockPos    resq 4096
BlockLen    resq 4096

section .text
Start:
    sub rsp, 40
    mov [rel ReplRsp], rsp
    call InitIO
    call InitStack
    call LoadFileArg
    test rdx, rdx
    jz Repl
    mov qword [rel FileMode], 1
    mov [rel SourceStart], rax
    lea rcx, [rax + rdx]
    mov [rel SourceEnd], rcx
    mov rcx, rax
    call SetInput
    lea rax, [rel CodeBuf]
    mov [rel Here], rax
    jmp Tokens

Repl:
    mov qword [rel Running], 0
    lea rcx, [rel Prompt]
    mov rdx, PromptLen
    call PrintString
    call ReadLine
    call StartLine
    lea rax, [rel CodeBuf]
    mov [rel Here], rax

Tokens:
    call NextToken
    test rdx, rdx
    jz .EndInput
    mov r12, rax
    mov r13, rdx
    call RecordLine
    mov [rel StmtTok], r12
    mov [rel StmtTokLen], r13
    mov [rel StmtR15], r15
    mov rax, [rel OpenBlocks]
    mov [rel StmtBlocks], rax
    mov rcx, r12
    mov rdx, r13
    call FindWord
    mov [rel StmtWord], rax
    push rax
    push rdx
    call CheckDead
    pop rdx
    pop rax
    test rax, rax
    jz .Expression
    cmp rdx, 2
    je .Immediate
    cmp rdx, 4
    je .Call
.Expression:
    mov ecx, 1
    call StmtExpr
    jmp Tokens
.Call:
    mov ecx, 1
    call StmtExpr
    jmp Tokens
.Immediate:
    mov r12, [rel StmtTok]
    mov r13, [rel StmtTokLen]
    mov [rel PrevTokPtr], r12
    mov [rel TokPtr], r12
    mov [rel TokLen], r13
    call rax
    call AfterBlockWord
    jmp Tokens
.EndInput:
    cmp qword [rel OpenBlocks], 0
    je .Run
    cmp qword [rel FileMode], 0
    jne .NoEnd
    lea rcx, [rel More]
    mov rdx, MoreLen
    call PrintString
    call ReadLine
    call StartLine
    jmp Tokens
.NoEnd:
    mov rax, [rel OpenBlocks]
    dec rax
    cmp rax, 4096
    jae .NoPos
    lea rcx, [rel BlockPos]
    mov rdx, [rcx + rax * 8]
    mov [rel ErrPos], rdx
    mov [rel ErrTokPtr], rdx
    lea rcx, [rel BlockLen]
    mov rdx, [rcx + rax * 8]
    mov [rel ErrTokLen], rdx
    jmp .HavePos
.NoPos:
    mov qword [rel ErrPos], 0
.HavePos:
    mov qword [rel AtEof], 1
    mov qword [rel OpenBlocks], 0
    lea rcx, [rel MissingEnd]
    mov rdx, MissingEndLen
    jmp Abort
.Run:
    cmp qword [rel CheckMode], 0
    jne CheckDone
    mov qword [rel Running], 1
    lea rbp, [rel ReturnStack]
    mov r13, rbp
    CompilePrim LineDone
    lea r14, [rel CodeBuf]
    NEXT

RecordLine:
    cmp qword [rel FileMode], 0
    je .Done
    mov rax, [rel LineCount]
    cmp rax, MaxLines
    jae .Done
    mov rcx, [rel LinePos]
    mov rdx, [rel LineNum]
    test rcx, rcx
    jz .Restart
    cmp r12, rcx
    jae .Count
.Restart:
    mov rcx, [rel SourceStart]
    mov edx, 1
.Count:
    cmp rcx, r12
    jae .Counted
    cmp byte [rcx], 10
    jne .Next
    inc rdx
.Next:
    inc rcx
    jmp .Count
.Counted:
    mov [rel LinePos], rcx
    mov [rel LineNum], rdx
    lea r8, [rel LineTable]
    shl rax, 4
    mov rcx, [rel Here]
    mov [r8 + rax], rcx
    mov [r8 + rax + 8], rdx
    inc qword [rel LineCount]
.Done:
    ret

RuntimeLine:
    xor eax, eax
    xor edx, edx
    lea r8, [rel LineTable]
    xor ecx, ecx
.Loop:
    cmp rcx, [rel LineCount]
    jae .Done
    mov r9, [r8]
    cmp r9, r14
    ja .Next
    cmp r9, rdx
    jb .Next
    mov rdx, r9
    mov rax, [r8 + 8]
.Next:
    add r8, 16
    inc rcx
    jmp .Loop
.Done:
    ret

Caught:
    mov rcx, [rel ErrMsg]
    mov rdx, [rel ErrLen]
    call MakeTextFrom
    mov [rel LastError], rax
    mov qword [rel ErrTokLen], 0
    mov qword [rel ErrPos], 0
    dec qword [rel TryDepth]
    mov rax, [rel TryDepth]
    shl rax, 5
    lea rcx, [rel TryStack]
    add rcx, rax
    mov r14, [rcx]
    mov r15, [rcx + 8]
    mov rbp, [rcx + 16]
    mov r13, [rcx + 24]
    mov rsp, [rel ReplRsp]
    NEXT

CheckDone:
    xor ecx, ecx
    cmp qword [rel ErrorCount], 0
    je .Exit
    mov ecx, 1
.Exit:
    call ExitProcess

CheckDead:
    mov rax, [rel StmtWord]
    lea rcx, [rel EndWord]
    cmp rax, rcx
    je .Clear
    lea rcx, [rel OtherwiseWord]
    cmp rax, rcx
    je .Clear
    lea rcx, [rel IsWord]
    cmp rax, rcx
    je .Clear
    cmp qword [rel DeadCode], 0
    je .Done
    lea rcx, [rel WarnDead]
    mov edx, WarnDeadLen
    mov r8, [rel StmtTok]
    xor r9d, r9d
    call Warn
.Clear:
    mov qword [rel DeadCode], 0
.Done:
    ret

AfterBlockWord:
    mov rax, [rel StmtWord]
    lea rcx, [rel ReturnWord]
    cmp rax, rcx
    je .Dead
    lea rcx, [rel StopWord]
    cmp rax, rcx
    je .Dead
    lea rcx, [rel SkipWord]
    cmp rax, rcx
    je .Dead
    lea rcx, [rel EndWord]
    cmp rax, rcx
    je .Ended
    mov rax, [rel OpenBlocks]
    cmp rax, [rel StmtBlocks]
    jbe .Done
    dec rax
    cmp rax, 4096
    jae .Done
    mov rcx, [rel StmtTok]
    lea rdx, [rel BlockPos]
    mov [rdx + rax * 8], rcx
    mov rcx, [rel StmtTokLen]
    lea rdx, [rel BlockLen]
    mov [rdx + rax * 8], rcx
    ret
.Dead:
    mov qword [rel DeadCode], 1
    ret
.Ended:
    mov rax, [rel OpenBlocks]
    cmp rax, 4096
    jae .Done
    lea rdx, [rel BlockPos]
    mov rcx, [rdx + rax * 8]
    push rcx
    call IndentOf
    push rax
    mov rcx, [rel StmtTok]
    call IndentOf
    pop r8
    pop rcx
    cmp rax, r8
    je .Done
    mov r8, rcx
    mov rax, [rel OpenBlocks]
    lea rdx, [rel BlockLen]
    mov r9, [rdx + rax * 8]
    lea rcx, [rel WarnIndent]
    mov edx, WarnIndentLen
    call Warn
.Done:
    ret

IndentOf:
    mov rdx, [rel SourceStart]
    mov rax, rcx
.Back:
    cmp rax, rdx
    jbe .Count
    cmp byte [rax - 1], 10
    je .Count
    dec rax
    jmp .Back
.Count:
    xor r8d, r8d
.Loop:
    cmp rax, rcx
    jae .Done
    cmp byte [rax], ' '
    je .Space
    cmp byte [rax], 9
    jne .Done
    add r8, 4
    inc rax
    jmp .Loop
.Space:
    inc r8
    inc rax
    jmp .Loop
.Done:
    mov rax, r8
    ret

LineOf:
    mov rax, rcx
    mov rcx, [rel SourceStart]
    mov edx, 1
.Loop:
    cmp rcx, rax
    jae .Done
    cmp byte [rcx], 10
    jne .Next
    inc rdx
.Next:
    inc rcx
    jmp .Loop
.Done:
    mov rax, rdx
    ret

Warn:
    cmp qword [rel CheckMode], 0
    je .Skip
    cmp qword [rel FileMode], 0
    je .Skip
    push rax
    push rcx
    push rdx
    push r8
    push r9
    push r10
    push r11
    push rsi
    push rdi
    push rbx
    push rbp
    push r12
    mov rbp, rsp
    and rsp, -16
    sub rsp, 32
    mov rbx, rcx
    mov r12, rdx
    push r8
    push r9
    lea rcx, [rel WarnWord]
    mov edx, 8
    call PrintString
    lea rcx, [rel LineWord]
    mov edx, 5
    call PrintString
    mov rcx, [rsp + 8]
    call LineOf
    mov rcx, rax
    call PrintNumber
    lea rcx, [rel Colon]
    mov edx, 2
    call PrintString
    mov rcx, rbx
    mov rdx, r12
    call PrintString
    cmp qword [rsp], 0
    je .NoTok
    lea rcx, [rel Quote]
    mov edx, 2
    call PrintString
    mov rcx, [rsp + 8]
    mov rdx, [rsp]
    call PrintString
    lea rcx, [rel EndQuote]
    mov edx, 1
    call PrintString
.NoTok:
    call PrintNewLine
    mov rsp, rbp
    pop r12
    pop rbp
    pop rbx
    pop rdi
    pop rsi
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rax
.Skip:
    ret

Recover:
    inc qword [rel ErrorCount]
    cmp qword [rel ErrorCount], 20
    jae CheckDone
    mov rax, [rel RecoverPos]
    mov rdx, [rel SourceEnd]
.Skip:
    cmp rax, rdx
    jae .AtEnd
    cmp byte [rax], 10
    je .Found
    inc rax
    jmp .Skip
.Found:
    inc rax
.AtEnd:
    mov rcx, rax
    sub rdx, rax
    call SetInput
    mov r15, [rel StmtR15]
    mov rax, [rel StmtBlocks]
    mov [rel OpenBlocks], rax
    mov qword [rel MakingConst], 0
    mov qword [rel DeadCode], 0
    mov rax, [rel StmtWord]
    xor r8d, r8d
    lea rcx, [rel DoWordAddr]
    cmp rax, [rcx]
    je .Fn
    cmp rax, [rcx + 8]
    je .Block
    cmp rax, [rcx + 16]
    je .Block
    cmp rax, [rcx + 24]
    je .Block
    cmp rax, [rcx + 32]
    je .Block
    jmp Tokens
.Fn:
    mov r8d, 1
.Block:
    DPush 0
    DPush 0
    DPush 0
    mov [r15 - 16], r8
    DPush 0
    DPush 4
    mov rax, [rel OpenBlocks]
    inc qword [rel OpenBlocks]
    cmp rax, 4096
    jae Tokens
    mov rcx, [rel StmtTok]
    lea rdx, [rel BlockPos]
    mov [rdx + rax * 8], rcx
    mov rcx, [rel StmtTokLen]
    lea rdx, [rel BlockLen]
    mov [rdx + rax * 8], rcx
    jmp Tokens

StartLine:
    lea rcx, [rel InputBuf]
    mov [rel SourceStart], rcx
    lea rdx, [rcx + rax]
    mov [rel SourceEnd], rdx
    mov rdx, rax
    jmp SetInput

LineDone:
    cmp qword [rel FileMode], 0
    jne .Exit
    lea rax, [rel DataStack]
    cmp r15, rax
    jae Repl
    lea rcx, [rel Underflow]
    mov rdx, UnderflowLen
    call PrintString
    call InitStack
    jmp Repl
.Exit:
    xor ecx, ecx
    call ExitProcess

ErrorLine:
    mov rax, [rel ErrPos]
    mov rcx, [rel SourceStart]
    cmp rax, rcx
    jb .UseInput
    cmp rax, [rel SourceEnd]
    jbe .Count
.UseInput:
    call GetInput
    mov rcx, [rel SourceStart]
.Count:
    mov edx, 1
.Loop:
    cmp rcx, rax
    jae .Done
    cmp byte [rcx], 10
    jne .Next
    inc rdx
.Next:
    inc rcx
    jmp .Loop
.Done:
    mov rax, rdx
    ret

Abort:
    mov rsp, [rel ReplRsp]
    mov [rel ErrMsg], rcx
    mov [rel ErrLen], rdx
    push rcx
    push rdx
    mov rax, [rel ErrPos]
    cmp rax, [rel SourceStart]
    jb .UseIn
    cmp rax, [rel SourceEnd]
    jbe .HaveRecover
.UseIn:
    call GetInput
    cmp rax, [rel SourceStart]
    jb .UseStmt
    cmp rax, [rel SourceEnd]
    jbe .HaveRecover
.UseStmt:
    mov rax, [rel StmtTok]
.HaveRecover:
    mov [rel RecoverPos], rax
    pop rdx
    pop rcx
    cmp qword [rel Running], 0
    je .NoTry
    cmp qword [rel TryDepth], 0
    jne Caught
.NoTry:
    cmp qword [rel FileMode], 0
    je .Message
    cmp qword [rel Running], 0
    je .CompileLine
    call RuntimeLine
    test rax, rax
    jz .Message
    jmp .PrintLine
.CompileLine:
    call ErrorLine
.PrintLine:
    mov rbx, rax
    lea rcx, [rel LineWord]
    mov edx, 5
    call PrintString
    mov rcx, rbx
    call PrintNumber
    lea rcx, [rel Colon]
    mov edx, 2
    call PrintString
.Message:
    mov rcx, [rel ErrMsg]
    mov rdx, [rel ErrLen]
    call PrintString
    cmp qword [rel ErrTokLen], 0
    je .Newline
    lea rcx, [rel Quote]
    mov edx, 2
    call PrintString
    mov rcx, [rel ErrTokPtr]
    mov rdx, [rel ErrTokLen]
    call PrintString
    lea rcx, [rel EndQuote]
    mov edx, 1
    call PrintString
.Newline:
    call PrintNewLine
    mov qword [rel ErrTokLen], 0
    mov qword [rel ErrPos], 0
    cmp qword [rel FileMode], 0
    je .Repl
    cmp qword [rel CheckMode], 0
    je .Exit
    cmp qword [rel Running], 0
    jne .Exit
    cmp qword [rel AtEof], 0
    jne .EofDone
    jmp Recover
.EofDone:
    inc qword [rel ErrorCount]
    jmp CheckDone
.Repl:
    call ResetCompiler
    jmp Repl
.Exit:
    mov ecx, 1
    call ExitProcess
