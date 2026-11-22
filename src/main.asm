%include "macros.inc"

global Start
global Abort
global FileMode
global Warn
global UseWord
global RecordLine
global UseDepth
global SaveMain
global RestoreMain
global SetMainFile
global ForwardOps
global SourceStart
global SourceEnd
global CurFile
global FilePath
global FileCount
global TryForward
global TryForwardVar

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
extern NoteStmt
extern OtherwiseWord
extern ReturnWord
extern StopWord
extern SkipWord
extern DoWord
extern IfWord
extern RepeatWord
extern CheckWord
extern TryWord
extern DllWord
extern IsWord
extern TryDepth
extern InitHeap
extern RegisterNatives
extern ExprDepth
extern UnwindLambdas
extern TypeDepth
extern TryStack
extern FfiVmDepth
extern CbDepth
extern LastError
extern MakeTextFrom
extern LoadFile
extern ExeDir
extern MainPathPtr
extern Advance
extern Unread
extern Alloc
extern PermAlloc
extern Latest
extern StackBase
extern InFn
extern InstanceDepth
extern PreScanActive
extern PreScanFail
extern EmitGlobalInits
extern PrimBranch
extern PrimCall
extern PrimCallValue
extern InstEnd
extern NestDepth
extern NestHeaderDone
extern NestFloor
extern NestAbort
extern PreDeclare
extern PreHandler
extern FullForward
extern SetWord
extern KeepWord
extern NoteForwardVar
extern LookupVar
extern NamePrefixPtr
extern NamePrefixLen
extern CopyString

section .data
CalledFrom db "  called from line "
CalledFromLen equ $ - CalledFrom
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
InWord         db "in "
LineSpace      db " line "
ErrUseWhere    db "use goes outside functions and blocks"
ErrUseWhereLen equ $ - ErrUseWhere
ErrUseName     db "use needs a file name in quotes, like: use ", 34, "helpers.tom", 34
ErrUseNameLen  equ $ - ErrUseName
ErrUseFind     db "can't find that file (looked next to this file and in TomLang's lib folder):"
ErrUseFindLen  equ $ - ErrUseFind
ErrUseDeep     db "too many files used inside each other (16 at most) or too many files (64 at most)"
ErrUseDeepLen  equ $ - ErrUseDeep
TomExt         db ".tom"
ErrAlias       db "use ... as needs a name after as, like: use ", 34, "text", 34, " as text"
ErrAliasLen    equ $ - ErrAlias
LibDir         db "lib/"
UpLibDir       db "../lib/"

%define MaxLines 262144

DoWordAddr     dq DoWord, IfWord, RepeatWord, CheckWord, TryWord, DllWord

section .bss
RecoverPos  resq 1
UseDepth    resq 1
AliasPtr    resq 1
AliasLen    resq 1
ResolvedLen resq 1
ExeDirLen   resq 1
UseStack    resq 16 * 16
PrefixBuf   resb 256
CurFile     resq 1
FileAliasPtr resq 256
FileAliasLen resq 256
BareUse     resq 1
AllOfUse    resq 1
OpsScanned  resb 256
BarePtr     resq 1
BareLen     resq 1
FileCount   resq 1
FilePath    resq 2 * 256
PathTemp    resb 2048
NormBuf     resb 2048
SegPos      resq 256
SegDots     resb 256
ExeDirBuf   resb 1024
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
    mov [rel StackBase], rsp
    call InitIO
    call InitHeap
    call InitStack
    call RegisterNatives
    call LoadFileArg
    test rdx, rdx
    jz Repl
    mov qword [rel FileMode], 1
    push rax
    push rdx
    call SetMainPath
    pop rdx
    pop rax
    mov [rel SourceStart], rax
    lea rcx, [rax + rdx]
    mov [rel SourceEnd], rcx
    mov rcx, rax
    call SetInput
    lea rax, [rel CodeBuf]
    mov [rel Here], rax
    CompilePrim PrimBranch
    lea rcx, [rel CodeBuf + 16]
    call Compile
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
    push rax
    push rdx
    xor ecx, ecx
    cmp rdx, 2
    jne .NoteIt
    mov rcx, rax
.NoteIt:
    call NoteStmt
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
    cmp qword [rel UseDepth], 0
    je .MainEnd
    cmp qword [rel OpenBlocks], 0
    jne .NoEnd
    call EndUse
    jmp Tokens
.MainEnd:
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
    cmp qword [rel FileMode], 0
    je .NoInits
    mov rax, [rel Here]
    push rax
    push rax
    call EmitGlobalInits
    pop rax
    pop rax
    cmp rax, [rel Here]
    je .NoInits
    lea rcx, [rel CodeBuf + 8]
    mov [rcx], rax
    CompilePrim PrimBranch
    lea rcx, [rel CodeBuf + 16]
    call Compile
.NoInits:
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
    mov rcx, [rel CurFile]
    shl rcx, 32
    or rdx, rcx
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

PrintCallers:
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 8
    mov r12, rbp
    xor r13d, r13d
    call RuntimeLine
    mov [rsp], rax
.Walk:
    sub r12, 8
    lea rax, [rel ReturnStack]
    cmp r12, rax
    jb .Done
    cmp r13, 6
    jae .Done
    mov rax, [r12]
    test rax, 7
    jnz .Walk
    lea rcx, [rel CodeBuf]
    cmp rax, rcx
    jb .Walk
    lea rcx, [rel InstEnd]
    cmp rax, rcx
    jae .Walk
    mov rcx, [rax - 16]
    lea rdx, [rel PrimCall]
    cmp rcx, rdx
    je .Frame
    lea rdx, [rel PrimCallValue]
    cmp rcx, rdx
    jne .Walk
.Frame:
    lea r14, [rax - 8]
    call RuntimeLine
    test rax, rax
    jz .Walk
    cmp rax, [rsp]
    je .Walk
    mov [rsp], rax
    mov rbx, rax
    lea rcx, [rel CalledFrom]
    mov edx, CalledFromLen
    call PrintString
    mov ecx, ebx
    call PrintNumber
    mov rcx, rbx
    shr rcx, 32
    test rcx, rcx
    jz .NoFile
    call PrintFileIn
.NoFile:
    call PrintNewLine
    inc r13
    jmp .Walk
.Done:
    add rsp, 8
    pop r14
    pop r13
    pop r12
    pop rbx
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
    shl rax, 6
    lea rcx, [rel TryStack]
    add rcx, rax
    mov r14, [rcx]
    mov r15, [rcx + 8]
    mov rbp, [rcx + 16]
    mov r13, [rcx + 24]
    mov rax, [rcx + 32]
    mov [rel FfiVmDepth], rax
    mov rax, [rcx + 40]
    mov [rel CbDepth], rax
    mov rsp, [rel ReplRsp]
    NEXT

CountLines:
    mov edx, edx
    mov rax, 1
    mov r8, [rel UseStack]
.Loop:
    cmp r8, rcx
    jae .Done
    cmp byte [r8], 10
    jne .Next
    inc rax
.Next:
    inc r8
    jmp .Loop
.Done:
    ret

PrintFileIn:
    push rcx
    lea rcx, [rel LineSpace]
    mov edx, 1
    call PrintString
    lea rcx, [rel InWord]
    mov edx, 3
    call PrintString
    pop rcx
    jmp PrintFileName

PrintFileName:
    shl rcx, 4
    lea rax, [rel FilePath]
    mov rdx, [rax + rcx + 8]
    mov rcx, [rax + rcx]
    lea r8, [rcx + rdx]
    mov r9, r8
.Back:
    cmp r9, rcx
    jbe .Got
    cmp byte [r9 - 1], '/'
    je .Got
    cmp byte [r9 - 1], 92
    je .Got
    dec r9
    jmp .Back
.Got:
    mov rcx, r9
    mov rdx, r8
    sub rdx, r9
    jmp PrintString

UseFail:
    lea rcx, [rel ErrUseFind]
    mov edx, ErrUseFindLen
    jmp Abort

UseWord:
    cmp qword [rel InFn], 0
    jne .Where
    cmp qword [rel OpenBlocks], 0
    jne .Where
    call Advance
    mov qword [rel BareUse], 0
    mov qword [rel AllOfUse], 0
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    cmp rdx, 3
    jne .NotAll
    cmp word [rcx], 'al'
    jne .NotAll
    cmp byte [rcx + 2], 'l'
    jne .NotAll
    call Advance
    mov rcx, [rel TokPtr]
    cmp qword [rel TokLen], 2
    jne .BadName
    cmp word [rcx], 'of'
    jne .BadName
    call Advance
    mov qword [rel AllOfUse], 1
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
.NotAll:
    test rdx, rdx
    jz .BadName
    cmp byte [rcx], 34
    je .Quoted
    cmp rdx, 100
    ja .BadName
    movzx eax, byte [rcx]
    or al, 32
    cmp al, 'a'
    jb .BadName
    cmp al, 'z'
    ja .BadName
    mov qword [rel BareUse], 1
    mov [rel BarePtr], rcx
    mov [rel BareLen], rdx
    jmp .Named
.Quoted:
    cmp rdx, 3
    jb .BadName
    cmp byte [rcx + rdx - 1], 34
    jne .BadName
    cmp rdx, 800
    ja .BadName
    inc rcx
    sub rdx, 2
.Named:
    mov [rel ErrTokPtr], rcx
    mov [rel ErrTokLen], rdx
    call ResolveUse
    test rax, rax
    jz UseFail
    mov qword [rel ErrTokLen], 0
    push rax
    push rdx
    call NormalizePath
    call ReadAlias
    cmp qword [rel BareUse], 0
    je .AliasDone
    cmp qword [rel AliasLen], 0
    jne .AliasDone
    cmp qword [rel AllOfUse], 0
    jne .AliasDone
    call BareAlias
.AliasDone:
    call AlreadyUsed
    test eax, eax
    jnz .Skip
    mov rax, [rel UseDepth]
    cmp rax, 16
    jae .Deep
    cmp qword [rel FileCount], 256
    jae .Deep
    shl rax, 7
    lea r8, [rel UseStack]
    add r8, rax
    mov rax, [rel SourceStart]
    mov [r8], rax
    mov rax, [rel SourceEnd]
    mov [r8 + 8], rax
    push r8
    call GetInput
    pop r8
    mov [r8 + 16], rax
    mov [r8 + 24], rdx
    mov rax, [rel LinePos]
    mov [r8 + 32], rax
    mov rax, [rel LineNum]
    mov [r8 + 40], rax
    mov rax, [rel CurFile]
    mov [r8 + 48], rax
    mov rax, [rel StmtTok]
    mov [r8 + 56], rax
    mov rax, [rel NamePrefixPtr]
    mov [r8 + 64], rax
    mov rax, [rel NamePrefixLen]
    mov [r8 + 72], rax
    mov rax, [rel AliasPtr]
    mov [rel NamePrefixPtr], rax
    mov rax, [rel AliasLen]
    mov [rel NamePrefixLen], rax
    inc qword [rel UseDepth]
    call RegisterPath
    mov [rel CurFile], rax
    cmp rax, 256
    jae .NoAliasRecord
    lea rcx, [rel FileAliasPtr]
    mov rdx, [rel AliasPtr]
    mov [rcx + rax * 8], rdx
    lea rcx, [rel FileAliasLen]
    mov rdx, [rel AliasLen]
    mov [rcx + rax * 8], rdx
.NoAliasRecord:
    pop rdx
    pop rcx
    mov [rel SourceStart], rcx
    lea rax, [rcx + rdx]
    mov [rel SourceEnd], rax
    call SetInput
    mov qword [rel LinePos], 0
    mov qword [rel LineNum], 1
    ret
.Skip:
    add rsp, 16
    cmp qword [rel AliasLen], 0
    je .SkipDone
    cmp r10, 256
    jae .SkipDone
    lea rcx, [rel FileAliasLen]
    mov rdx, [rcx + r10 * 8]
    test rdx, rdx
    jz .SkipDone
    lea rcx, [rel FileAliasPtr]
    mov rcx, [rcx + r10 * 8]
    call AliasCopy
.SkipDone:
    ret
.Where:
    lea rcx, [rel ErrUseWhere]
    mov edx, ErrUseWhereLen
    jmp Abort
.BadName:
    lea rcx, [rel ErrUseName]
    mov edx, ErrUseNameLen
    jmp Abort
.Deep:
    lea rcx, [rel ErrUseDeep]
    mov edx, ErrUseDeepLen
    jmp Abort

TryForwardVar:
    push rbx
    push r12
    push r13
    push r14
    push rsi
    push rdi
    sub rsp, 8
    mov rsi, rcx
    mov rdi, rdx
    call GetInput
    mov r12, rax
    mov r13, rdx
    mov [rsp], rdx
    mov rcx, [rel StmtTok]
    cmp rcx, [rel SourceStart]
    jb .Out
    mov rdx, [rel SourceEnd]
    cmp rcx, rdx
    jae .Out
    mov r13, rdx
    sub rdx, rcx
    call SetInput
.Loop:
    call NextToken
    test rdx, rdx
    jz .Out
    cmp rax, [rel SourceStart]
    je .Col0
    movzx ecx, byte [rax - 1]
    cmp ecx, 10
    jne .Loop
.Col0:
    mov ebx, 3
    cmp rdx, 3
    jne .Keep
    cmp word [rax], 'se'
    jne .Loop
    cmp byte [rax + 2], 't'
    jne .Loop
    lea r8, [rel SetWord]
    jmp .Word
.Keep:
    cmp rdx, 4
    jne .Loop
    cmp dword [rax], 'keep'
    jne .Loop
    mov ebx, 4
    lea r8, [rel KeepWord]
.Word:
    mov [rel PreHandler], r8
    mov r14, rax
    call NextToken
    cmp rdx, rdi
    jne .Loop
    xor ecx, ecx
.Cmp:
    cmp rcx, rdi
    jae .Match
    mov r8b, [rax + rcx]
    cmp r8b, [rsi + rcx]
    jne .Loop
    inc rcx
    jmp .Cmp
.Match:
    movzx ecx, byte [rax + rdi]
    cmp ecx, ' '
    je .Ok
    cmp ecx, ':'
    je .Ok
    cmp ecx, '='
    jne .Loop
.Ok:
    lea rcx, [r14 + rbx]
    mov rdx, r13
    sub rdx, rcx
    call SetInput
    mov rcx, r14
    mov rdx, rbx
    call PreDeclare
    mov rcx, rsi
    mov rdx, rdi
    call LookupVar
    test rax, rax
    jz .Out
    call NoteForwardVar
.Out:
    mov rcx, r12
    mov rdx, [rsp]
    sub rdx, r12
    call SetInput
    add rsp, 8
    pop rdi
    pop rsi
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

ForwardOps:
    mov rax, [rel CurFile]
    cmp rax, 256
    jae .Skip
    lea rcx, [rel OpsScanned]
    cmp byte [rcx + rax], 0
    jne .Skip
    mov byte [rcx + rax], 1
    push rbx
    push r12
    push r13
    push r14
    push rsi
    push rdi
    sub rsp, 8
    call GetInput
    mov r12, rax
    mov r13, rdx
    mov [rsp], rdx
    mov rcx, [rel StmtTok]
    cmp rcx, [rel SourceStart]
    jb .Out
    mov rdx, [rel SourceEnd]
    cmp rcx, rdx
    jae .Out
    mov r13, rdx
    sub rdx, rcx
    call SetInput
.Loop:
    call NextToken
    test rdx, rdx
    jz .Out
    cmp rax, [rel SourceStart]
    je .Col0
    movzx ecx, byte [rax - 1]
    cmp ecx, 10
    je .Col0
    cmp ecx, 13
    jne .Loop
.Col0:
    cmp rdx, 2
    jne .Loop
    cmp word [rax], 'do'
    jne .Loop
    mov r14, rax
    call NextToken
    cmp rdx, 1
    jne .Loop
    cmp byte [rax], '('
    je .Found
    cmp byte [rax], '-'
    jne .Loop
.Found:
    lea rcx, [r14 + 2]
    mov rdx, r13
    sub rdx, rcx
    call SetInput
    lea rax, [rel FullForward]
    mov [rel PreHandler], rax
    mov rcx, r14
    mov edx, 2
    call PreDeclare
    lea rcx, [r14 + 2]
    mov rdx, r13
    sub rdx, rcx
    call SetInput
    jmp .Loop
.Out:
    mov rcx, r12
    mov rdx, [rsp]
    sub rdx, r12
    call SetInput
    add rsp, 8
    pop rdi
    pop rsi
    pop r14
    pop r13
    pop r12
    pop rbx
.Skip:
    ret

TryForward:
    push rbx
    push r12
    push r13
    push r14
    push rsi
    push rdi
    sub rsp, 8
    mov rsi, rcx
    mov rdi, rdx
    call GetInput
    mov r12, rax
    mov r13, rdx
    mov [rsp], rdx
    mov rcx, [rel StmtTok]
    cmp rcx, [rel SourceStart]
    jb .Out
    mov rdx, [rel SourceEnd]
    cmp rcx, rdx
    jae .Out
    mov r13, rdx
    sub rdx, rcx
    call SetInput
    xor ebx, ebx
.Loop:
    call NextToken
    test rdx, rdx
    jz .Out
    cmp rax, [rel SourceStart]
    je .Col0
    movzx ecx, byte [rax - 1]
    cmp ecx, 10
    je .Col0
    cmp ecx, 13
    jne .Loop
.Col0:
    cmp rdx, 3
    je .Three
    cmp rdx, 2
    jne .Loop
    cmp word [rax], 'do'
    jne .Loop
    test ebx, ebx
    jnz .Loop
    mov r14, rax
    call NextToken
    cmp rdx, rdi
    je .LenOk
    cmp byte [rax + rdx], '.'
    jne .Loop
    cmp rdx, rdi
    jae .Loop
.LenOk:
    xor ecx, ecx
.Cmp:
    cmp rcx, rdi
    jae .Match
    mov r8b, [rax + rcx]
    cmp r8b, [rsi + rcx]
    jne .Loop
    inc rcx
    jmp .Cmp
.Match:
    cmp byte [rax + rdi], '('
    jne .Loop
    push rsi
    push rdi
    lea rcx, [r14 + 2]
    mov rdx, r13
    sub rdx, rcx
    call SetInput
    lea rax, [rel FullForward]
    mov [rel PreHandler], rax
    mov rcx, r14
    mov edx, 2
    call PreDeclare
    pop rdi
    pop rsi
    mov rcx, rsi
    mov rdx, rdi
    call FindWord
    test rax, rax
    jnz .Out
    lea rcx, [r14 + 2]
    mov rdx, r13
    sub rdx, rcx
    call SetInput
    lea rax, [rel DoWord]
    mov [rel PreHandler], rax
    mov rcx, r14
    mov edx, 2
    call PreDeclare
    jmp .Out
.Three:
    movzx ecx, word [rax]
    movzx r8d, byte [rax + 2]
    shl r8d, 16
    or ecx, r8d
    cmp ecx, 'dll'
    je .Dll
    cmp ecx, 'end'
    jne .Loop
    xor ebx, ebx
    jmp .Loop
.Dll:
    mov ebx, 1
    jmp .Loop
.Out:
    mov rcx, r12
    mov rdx, [rsp]
    sub rdx, r12
    call SetInput
    add rsp, 8
    pop rdi
    pop rsi
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

EndUse:
    dec qword [rel UseDepth]
    mov rax, [rel UseDepth]
    shl rax, 7
    lea r8, [rel UseStack]
    add r8, rax
    mov rax, [r8]
    mov [rel SourceStart], rax
    mov rax, [r8 + 8]
    mov [rel SourceEnd], rax
    mov rax, [r8 + 32]
    mov [rel LinePos], rax
    mov rax, [r8 + 40]
    mov [rel LineNum], rax
    mov rax, [r8 + 48]
    mov [rel CurFile], rax
    mov rax, [r8 + 64]
    mov [rel NamePrefixPtr], rax
    mov rax, [r8 + 72]
    mov [rel NamePrefixLen], rax
    mov rcx, [r8 + 16]
    mov rdx, [r8 + 24]
    sub rdx, rcx
    jmp SetInput

NormalizePath:
    push rbx
    push rsi
    push rdi
    push r12
    lea rsi, [rel PathTemp]
    lea rdi, [rel NormBuf]
    mov r12, [rel ResolvedLen]
    xor r8d, r8d
    xor r9d, r9d
    xor r10d, r10d
    test r12, r12
    jz .Done
    mov al, [rsi]
    cmp al, '/'
    je .Root
    cmp al, 92
    jne .Loop
.Root:
    mov byte [rdi], '/'
    inc r9
.Loop:
    cmp r8, r12
    jae .Done
    mov al, [rsi + r8]
    cmp al, '/'
    je .Sep
    cmp al, 92
    je .Sep
    mov rbx, r8
.SegEnd:
    cmp r8, r12
    jae .Seg
    mov al, [rsi + r8]
    cmp al, '/'
    je .Seg
    cmp al, 92
    je .Seg
    inc r8
    jmp .SegEnd
.Sep:
    inc r8
    jmp .Loop
.Seg:
    mov rcx, r8
    sub rcx, rbx
    cmp rcx, 1
    jne .NotDot
    cmp byte [rsi + rbx], '.'
    je .Loop
.NotDot:
    cmp rcx, 2
    jne .Append
    cmp word [rsi + rbx], '..'
    jne .Append
    test r10, r10
    jz .AppendDots
    lea rdx, [rel SegDots]
    cmp byte [rdx + r10 - 1], 0
    jne .AppendDots
    dec r10
    lea rdx, [rel SegPos]
    mov r9, [rdx + r10 * 8]
    jmp .Loop
.AppendDots:
    mov r11b, 1
    jmp .Add
.Append:
    xor r11d, r11d
.Add:
    cmp r10, 256
    jae .Loop
    lea rdx, [rel SegPos]
    mov [rdx + r10 * 8], r9
    lea rdx, [rel SegDots]
    mov [rdx + r10], r11b
    inc r10
    test r9, r9
    jz .Copy
    cmp byte [rdi + r9 - 1], '/'
    je .Copy
    mov byte [rdi + r9], '/'
    inc r9
.Copy:
    cmp rbx, r8
    jae .Loop
    mov al, [rsi + rbx]
    mov [rdi + r9], al
    inc r9
    inc rbx
    jmp .Copy
.Done:
    xor ecx, ecx
.Back:
    cmp rcx, r9
    jae .Copied
    mov al, [rdi + rcx]
    mov [rsi + rcx], al
    inc rcx
    jmp .Back
.Copied:
    mov byte [rsi + r9], 0
    mov [rel ResolvedLen], r9
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

ReadAlias:
    mov qword [rel AliasLen], 0
    mov qword [rel AliasPtr], 0
    call Advance
    mov rcx, [rel TokPtr]
    cmp qword [rel TokLen], 2
    jne .None
    cmp word [rcx], 'as'
    jne .None
    call Advance
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    test rdx, rdx
    jz .BadAlias
    cmp rdx, 100
    ja .BadAlias
    movzx eax, byte [rcx]
    or al, 32
    cmp al, 'a'
    jb .BadAlias
    cmp al, 'z'
    ja .BadAlias
    push rsi
    push rdi
    mov rsi, rcx
    lea rdi, [rel PrefixBuf]
    mov rcx, rdx
    rep movsb
    mov byte [rdi], '.'
    pop rdi
    pop rsi
    lea rcx, [rel PrefixBuf]
    inc rdx
    push rdx
    push qword [rel NamePrefixLen]
    mov qword [rel NamePrefixLen], 0
    call CopyString
    pop qword [rel NamePrefixLen]
    pop rdx
    mov [rel AliasPtr], rax
    mov [rel AliasLen], rdx
    ret

.None:
    mov rcx, [rel TokPtr]
    jmp Unread
.BadAlias:
    lea rcx, [rel ErrAlias]
    mov edx, ErrAliasLen
    jmp Abort

BareAlias:
    push rsi
    push rdi
    mov rsi, [rel BarePtr]
    mov rdx, [rel BareLen]
    lea rdi, [rel PrefixBuf]
    mov rcx, rdx
    rep movsb
    mov byte [rdi], '.'
    pop rdi
    pop rsi
    lea rcx, [rel PrefixBuf]
    mov rdx, [rel BareLen]
    inc rdx
    push rdx
    push qword [rel NamePrefixLen]
    mov qword [rel NamePrefixLen], 0
    call CopyString
    pop qword [rel NamePrefixLen]
    pop rdx
    mov [rel AliasPtr], rax
    mov [rel AliasLen], rdx
    ret

AliasCopy:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    mov r12, rcx
    mov r13, rdx
    mov r15, [rel Latest]
    cmp r13, [rel AliasLen]
    jne .Differ
    mov rsi, r12
    mov rdi, [rel AliasPtr]
    mov rcx, r13
    repe cmpsb
    je .Out
.Differ:
    mov rbx, [rel Latest]
    mov r15, rbx
.Walk:
    test rbx, rbx
    jz .Out
    movzx r14d, byte [rbx + 17]
    cmp r14, r13
    jbe .Next
    lea rsi, [rbx + 18]
    mov rdi, r12
    mov rcx, r13
    repe cmpsb
    jne .Next
    mov rcx, r14
    sub rcx, r13
    add rcx, [rel AliasLen]
    cmp rcx, 250
    ja .Next
    add rcx, 32
    call PermAlloc
    mov rdx, r15
    mov [rax], rdx
    mov rdx, [rbx + 8]
    mov [rax + 8], rdx
    mov dl, [rbx + 16]
    mov [rax + 16], dl
    mov rcx, r14
    sub rcx, r13
    add rcx, [rel AliasLen]
    mov [rax + 17], cl
    lea rdi, [rax + 18]
    mov rsi, [rel AliasPtr]
    mov rcx, [rel AliasLen]
    rep movsb
    lea rsi, [rbx + 18 + r13]
    mov rcx, r14
    sub rcx, r13
    rep movsb
    mov r15, rax
.Next:
    mov rbx, [rbx]
    jmp .Walk
.Out:
    mov [rel Latest], r15
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

AlreadyUsed:
    xor eax, eax
    xor r10d, r10d
.Loop:
    cmp r10, [rel FileCount]
    jae .No
    mov r11, r10
    shl r11, 4
    lea r8, [rel FilePath]
    mov rcx, [r8 + r11 + 8]
    cmp rcx, [rel ResolvedLen]
    jne .Next
    mov r9, [r8 + r11]
    xor edx, edx
.Cmp:
    cmp rdx, rcx
    je .Yes
    mov al, [r9 + rdx]
    lea r8, [rel PathTemp]
    mov r11b, [r8 + rdx]
    cmp al, 'A'
    jb .LowA
    cmp al, 'Z'
    ja .LowA
    add al, 32
.LowA:
    cmp r11b, 'A'
    jb .LowB
    cmp r11b, 'Z'
    ja .LowB
    add r11b, 32
.LowB:
    cmp al, r11b
    jne .Next
    inc rdx
    jmp .Cmp
.Next:
    inc r10
    jmp .Loop
.Yes:
    mov eax, 1
    ret
.No:
    xor eax, eax
    ret

RegisterPath:
    mov rcx, [rel ResolvedLen]
    inc rcx
    call PermAlloc
    mov r9, rax
    mov rcx, [rel ResolvedLen]
    xor edx, edx
    lea r8, [rel PathTemp]
.Copy:
    cmp rdx, rcx
    jae .Copied
    mov r10b, [r8 + rdx]
    mov [r9 + rdx], r10b
    inc rdx
    jmp .Copy
.Copied:
    mov rax, [rel FileCount]
    mov r11, rax
    shl r11, 4
    lea r8, [rel FilePath]
    mov [r8 + r11], r9
    mov [r8 + r11 + 8], rcx
    inc qword [rel FileCount]
    ret

SetMainPath:
    mov rcx, [rel MainPathPtr]
    test rcx, rcx
    jz .None
    xor edx, edx
.Len:
    cmp byte [rcx + rdx], 0
    je .Got
    inc rdx
    jmp .Len
.Got:
    cmp rdx, 2000
    jae .None
    lea rdi, [rel PathTemp]
    mov rsi, rcx
    mov [rel ResolvedLen], rdx
    mov rcx, rdx
    rep movsb
    call NormalizePath
    call RegisterPath
    ret
.None:
    lea r8, [rel FilePath]
    mov qword [r8], 0
    mov qword [r8 + 8], 0
    mov qword [rel FileCount], 1
    ret

ResolveUse:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    mov r12, rcx
    mov r13, rdx
    xor ebx, ebx
    cmp r13, 4
    jb .NoExt
    mov eax, [r12 + r13 - 4]
    cmp eax, [rel TomExt]
    je .HasExt
.NoExt:
    mov ebx, 1
.HasExt:
    lea rdi, [rel PathTemp]
    mov rax, [rel CurFile]
    shl rax, 4
    lea r8, [rel FilePath]
    mov rsi, [r8 + rax]
    mov rcx, [r8 + rax + 8]
    test rsi, rsi
    jz .NoDir
.FindSlash:
    test rcx, rcx
    jz .NoDir
    cmp byte [rsi + rcx - 1], '/'
    je .CopyDir
    cmp byte [rsi + rcx - 1], 92
    je .CopyDir
    dec rcx
    jmp .FindSlash
.CopyDir:
    rep movsb
.NoDir:
    call .AddName
    call .Try
    test rax, rax
    jnz .Found
    lea rcx, [rel ExeDirBuf]
    mov edx, 1000
    call ExeDir
    mov [rel ExeDirLen], rax
    lea rdi, [rel PathTemp]
    lea rsi, [rel ExeDirBuf]
    mov rcx, [rel ExeDirLen]
    rep movsb
    lea rsi, [rel LibDir]
    mov ecx, 4
    rep movsb
    call .AddName
    call .Try
    test rax, rax
    jnz .Found
    lea rdi, [rel PathTemp]
    lea rsi, [rel ExeDirBuf]
    mov rcx, [rel ExeDirLen]
    rep movsb
    lea rsi, [rel UpLibDir]
    mov ecx, 7
    rep movsb
    call .AddName
    call .Try
.Found:
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret
.AddName:
    mov rsi, r12
    mov rcx, r13
    rep movsb
    test ebx, ebx
    jz .NameDone
    lea rsi, [rel TomExt]
    mov ecx, 4
    rep movsb
.NameDone:
    mov byte [rdi], 0
    lea rax, [rel PathTemp]
    sub rdi, rax
    mov [rel ResolvedLen], rdi
    ret
.Try:
    lea rcx, [rel PathTemp]
    sub rsp, 8
    call LoadFile
    add rsp, 8
    ret

SaveMain:
    mov rax, [rel SourceStart]
    mov [rcx], rax
    mov rax, [rel SourceEnd]
    mov [rcx + 8], rax
    mov rax, [rel LinePos]
    mov [rcx + 16], rax
    mov rax, [rel LineNum]
    mov [rcx + 24], rax
    mov rax, [rel CurFile]
    mov [rcx + 32], rax
    mov rax, [rel StmtTok]
    mov [rcx + 40], rax
    mov rax, [rel StmtTokLen]
    mov [rcx + 48], rax
    mov rax, [rel StmtR15]
    mov [rcx + 56], rax
    mov rax, [rel StmtBlocks]
    mov [rcx + 64], rax
    mov rax, [rel StmtWord]
    mov [rcx + 72], rax
    mov rax, [rel DeadCode]
    mov [rcx + 80], rax
    ret

RestoreMain:
    mov rax, [rcx]
    mov [rel SourceStart], rax
    mov rax, [rcx + 8]
    mov [rel SourceEnd], rax
    mov rax, [rcx + 16]
    mov [rel LinePos], rax
    mov rax, [rcx + 24]
    mov [rel LineNum], rax
    mov rax, [rcx + 32]
    mov [rel CurFile], rax
    mov rax, [rcx + 40]
    mov [rel StmtTok], rax
    mov rax, [rcx + 48]
    mov [rel StmtTokLen], rax
    mov rax, [rcx + 56]
    mov [rel StmtR15], rax
    mov rax, [rcx + 64]
    mov [rel StmtBlocks], rax
    mov rax, [rcx + 72]
    mov [rel StmtWord], rax
    mov rax, [rcx + 80]
    mov [rel DeadCode], rax
    ret

SetMainFile:
    mov [rel SourceStart], rcx
    mov [rel SourceEnd], rdx
    mov [rel CurFile], r8
    mov qword [rel LinePos], 0
    mov qword [rel LineNum], 1
    ret

CheckDone:
    xor ecx, ecx
    cmp qword [rel ErrorCount], 0
    je .Exit
    mov ecx, 1
.Exit:
    and rsp, -16
    sub rsp, 32
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
    cmp qword [rel PreScanActive], 0
    jne .Skip
    cmp qword [rel UseDepth], 0
    jne .Skip
    cmp qword [rel InstanceDepth], 0
    jne .Skip
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
    call UnwindLambdas
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
    mov qword [rel ExprDepth], 0
    mov qword [rel TypeDepth], 0
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
    cmp rax, [rcx + 40]
    je .Block
    jmp Tokens
.Fn:
    mov r8d, 1
    mov rax, [rel NestDepth]
    cmp rax, [rel NestFloor]
    je .Block
    xor r8d, r8d
    call NestHeaderDone
    test rax, rax
    jnz .Block
    call NestAbort
    xor r8d, r8d
.Block:
    DPush 0
    DPush 0
    DPush 0
    DPush 0
    DPush 4
    mov [r15 - 16], r8
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
    and rsp, -16
    sub rsp, 32
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
    cmp qword [rel PreScanActive], 0
    jne PreScanFail
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
    mov rbx, rax
    shr rbx, 32
    mov eax, eax
    test rbx, rbx
    jz .PrintLine
    push rax
    lea rcx, [rel LineWord]
    mov edx, 5
    call PrintString
    pop rcx
    call PrintNumber
    mov rcx, rbx
    call PrintFileIn
    lea rcx, [rel Colon]
    mov edx, 2
    call PrintString
    jmp .Message
.CompileLine:
    call ErrorLine
    cmp qword [rel UseDepth], 0
    je .PrintLine
    push rax
    lea rcx, [rel LineWord]
    mov edx, 5
    call PrintString
    mov rcx, [rel UseStack + 7 * 8]
    mov rdx, [rel UseStack]
    call CountLines
    mov rcx, rax
    call PrintNumber
    lea rcx, [rel Colon]
    mov edx, 2
    call PrintString
    lea rcx, [rel InWord]
    mov edx, 3
    call PrintString
    mov rcx, [rel CurFile]
    call PrintFileName
    lea rcx, [rel LineSpace]
    mov edx, 6
    call PrintString
    pop rcx
    call PrintNumber
    lea rcx, [rel Colon]
    mov edx, 2
    call PrintString
    jmp .Message
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
    cmp qword [rel Running], 0
    je .NoTrace
    cmp qword [rel FileMode], 0
    je .NoTrace
    call PrintCallers
.NoTrace:
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
    cmp qword [rel InstanceDepth], 0
    jne .EofDone
    jmp Recover
.EofDone:
    inc qword [rel ErrorCount]
    jmp CheckDone
.Repl:
    call ResetCompiler
    mov qword [rel UseDepth], 0
    mov qword [rel CurFile], 0
    mov qword [rel InstanceDepth], 0
    jmp Repl
.Exit:
    mov ecx, 1
    and rsp, -16
    sub rsp, 32
    call ExitProcess
