%include "macros.inc"

global Advance
global ParseExpr
global ResetCompiler
global OpenBlocks
global StmtExpr
global SayWord
global SetWord
global IfWord
global OtherwiseWord
global EndWord
global RepeatWord
global StopWord
global SkipWord
global DoWord
global ReturnWord
extern NextToken
extern Unread
extern GetInput
extern SetInput
extern ParseNumber
extern FindWord
extern Compile
extern Here
extern Latest
extern FnEntry
extern BeginDef
extern EndDef
extern CreateVar
extern AllocSlot
extern MakeText
extern InitStack
extern Abort
extern PrimLit
extern PrimAdd
extern PrimSub
extern PrimMul
extern PrimDiv
extern PrimMod
extern PrimAnd
extern PrimOr
extern PrimDrop
extern PrimSwap
extern PrimFetch
extern PrimStore
extern PrimPrint
extern PrimCall
extern PrimExit
extern PrimBranch
extern PrimBranch0
extern PrimToR
extern PrimFromR
extern PrimLess
extern PrimGreater
extern PrimEq
extern PrimNotEq
extern PrimLessEq
extern PrimGreaterEq
extern PrimSayText
extern PrimConcat
extern PrimToText
extern PrimToNumber
extern PrimTextEq
extern PrimAsk
extern PrimRandom
extern PrimMakeList
extern PrimIndex
extern PrimSetIndex
extern PrimListAdd
extern PrimLength

%define TagIf   1
%define TagLoop 2
%define TagFn   3

%define TNone 0
%define TNum  1
%define TText 2
%define TList 16

%macro IfTok 2
[section .data]
%%Str: db %1
%%End:
__SECT__
    lea rcx, [rel %%Str]
    mov edx, %%End - %%Str
    call IsTok
    test eax, eax
    jnz %2
%endmacro

%macro Expect 2
    IfTok %1, %%Ok
    Fail %2
%%Ok:
%endmacro

%macro Fail 1
    lea rcx, [rel %1]
    mov edx, %1Len
    jmp Abort
%endmacro

%macro CompileNum 1
    CompilePrim PrimLit
    mov rcx, %1
    call Compile
%endmacro

%macro SetType 1
    mov qword [rel ExprType], %1
%endmacro

%macro NeedType 1
    cmp qword [rel ExprType], %1
    jne TypeError
%endmacro

%macro NumOp 3
%1:
    push qword [rel ExprType]
    call Advance
    call %2
    pop rax
    cmp rax, TNum
    jne TypeError
    NeedType TNum
    CompilePrim %3
    SetType TNum
%endmacro

section .data
ErrExpect     db "expected a value", 10
ErrExpectLen  equ $ - ErrExpect
ErrParen      db "missing ( or )", 10
ErrParenLen   equ $ - ErrParen
ErrBracket    db "missing [ or ]", 10
ErrBracketLen equ $ - ErrBracket
ErrComma      db "missing ,", 10
ErrCommaLen   equ $ - ErrComma
ErrName       db "unknown name", 10
ErrNameLen    equ $ - ErrName
ErrType       db "type mismatch", 10
ErrTypeLen    equ $ - ErrType
ErrTypeName   db "unknown type", 10
ErrTypeNameLen equ $ - ErrTypeName
ErrMember     db "unknown .something", 10
ErrMemberLen  equ $ - ErrMember
ErrSet        db "set needs a name and =", 10
ErrSetLen     equ $ - ErrSet
ErrString     db "text is missing its closing quote or }", 10
ErrStringLen  equ $ - ErrString
ErrTimes      db "repeat needs times, while, until, forever or each", 10
ErrTimesLen   equ $ - ErrTimes
ErrEach       db "repeat each needs: repeat each name in list", 10
ErrEachLen    equ $ - ErrEach
ErrEnd        db "end without a block", 10
ErrEndLen     equ $ - ErrEnd
ErrOther      db "otherwise without if", 10
ErrOtherLen   equ $ - ErrOther
ErrLoop       db "stop/skip outside a loop", 10
ErrLoopLen    equ $ - ErrLoop
ErrDo         db "do needs a name, outside other blocks", 10
ErrDoLen      equ $ - ErrDo
ErrReturn     db "return outside a function", 10
ErrReturnLen  equ $ - ErrReturn
              dq 0
BrokenBody    dq PrimLit, 0, PrimExit

section .bss
TokPtr       resq 1
TokLen       resq 1
ExprType     resq 1
LastVarSlot  resq 1
OpenBlocks   resq 1
InFn         resq 1
FnParamCount resq 1
FnParams     resq 16

section .text
Advance:
    call NextToken
    mov [rel TokPtr], rax
    mov [rel TokLen], rdx
    ret

Pushback:
    cmp qword [rel TokLen], 0
    je .Done
    mov rcx, [rel TokPtr]
    call Unread
.Done:
    ret

IsTok:
    cmp rdx, [rel TokLen]
    jne .No
    mov r8, [rel TokPtr]
    xor r9d, r9d
.Loop:
    cmp r9, rdx
    je .Yes
    mov al, [rcx + r9]
    cmp al, [r8 + r9]
    jne .No
    inc r9
    jmp .Loop
.Yes:
    mov eax, 1
    ret
.No:
    xor eax, eax
    ret

TypeError:
    Fail ErrType

EmitJump:
    call Compile
    mov r10, [rel Here]
    xor ecx, ecx
    call Compile
    mov rax, r10
    ret

PatchChain:
    test rcx, rcx
    jz .Done
    mov r9, [rcx]
    mov [rcx], rdx
    mov rcx, r9
    jmp PatchChain
.Done:
    ret

ParseTypeName:
    IfTok "number", .Num
    IfTok "bool", .Num
    IfTok "text", .Text
    IfTok "list", .List
    Fail ErrTypeName
.Num:
    mov eax, TNum
    ret
.Text:
    mov eax, TText
    ret
.List:
    mov eax, TList
    ret

ResetCompiler:
    mov rax, [rel FnEntry]
    test rax, rax
    jz .NoFn
    lea rcx, [rel BrokenBody]
    mov [rax + 8], rcx
    mov qword [rel FnEntry], 0
.NoFn:
    mov qword [rel InFn], 0
    mov qword [rel OpenBlocks], 0
    call InitStack
    ret

ParseExpr:
ParseOr:
    call ParseAnd
.Loop:
    IfTok "or", .Or
    ret
NumOp .Or, ParseAnd, PrimOr
    jmp .Loop

ParseAnd:
    call ParseNot
.Loop:
    IfTok "and", .And
    ret
NumOp .And, ParseNot, PrimAnd
    jmp .Loop

ParseNot:
    IfTok "not", .Not
    jmp ParseCompare
.Not:
    call Advance
    call ParseNot
    NeedType TNum
    CompileNum 0
    CompilePrim PrimEq
    ret

ParseCompare:
    call ParseSum
    IfTok "==", .Eq
    IfTok "!=", .Ne
    IfTok "<=", .Le
    IfTok ">=", .Ge
    IfTok "<", .Lt
    IfTok ">", .Gt
    ret
.Eq:
    call .Both
    cmp rax, TText
    je .EqText
    CompilePrim PrimEq
    SetType TNum
    ret
.EqText:
    CompilePrim PrimTextEq
    SetType TNum
    ret
.Ne:
    call .Both
    cmp rax, TText
    je .NeText
    CompilePrim PrimNotEq
    SetType TNum
    ret
.NeText:
    CompilePrim PrimTextEq
    CompileNum 0
    CompilePrim PrimEq
    SetType TNum
    ret
.Both:
    push qword [rel ExprType]
    call Advance
    call ParseSum
    pop rax
    cmp rax, [rel ExprType]
    jne TypeError
    cmp rax, TNum
    je .BothOk
    cmp rax, TText
    jne TypeError
.BothOk:
    ret
NumOp .Le, ParseSum, PrimLessEq
    ret
NumOp .Ge, ParseSum, PrimGreaterEq
    ret
NumOp .Lt, ParseSum, PrimLess
    ret
NumOp .Gt, ParseSum, PrimGreater
    ret

ParseSum:
    call ParseProduct
.Loop:
    IfTok "+", .Add
    IfTok "-", .Sub
    ret
.Add:
    push qword [rel ExprType]
    call Advance
    call ParseProduct
    pop rax
    mov rdx, [rel ExprType]
    cmp rax, TText
    je .Text
    cmp rdx, TText
    je .Text
    cmp rax, TNum
    jne TypeError
    cmp rdx, TNum
    jne TypeError
    CompilePrim PrimAdd
    SetType TNum
    jmp .Loop
.Text:
    cmp rdx, TNum
    jne .RightText
    push rax
    CompilePrim PrimToText
    pop rax
    jmp .Left
.RightText:
    cmp rdx, TText
    jne TypeError
.Left:
    cmp rax, TNum
    jne .LeftText
    CompilePrim PrimSwap
    CompilePrim PrimToText
    CompilePrim PrimSwap
    jmp .Join
.LeftText:
    cmp rax, TText
    jne TypeError
.Join:
    CompilePrim PrimConcat
    SetType TText
    jmp .Loop
NumOp .Sub, ParseProduct, PrimSub
    jmp .Loop

ParseProduct:
    call ParseAtom
.Loop:
    IfTok "*", .Mul
    IfTok "/", .Div
    IfTok "%", .Mod
    ret
NumOp .Mul, ParseAtom, PrimMul
    jmp .Loop
NumOp .Div, ParseAtom, PrimDiv
    jmp .Loop
NumOp .Mod, ParseAtom, PrimMod
    jmp .Loop

ParseAtom:
    mov qword [rel LastVarSlot], 0
    call ParsePrimary
.Post:
    IfTok "[", .Index
    IfTok ".", .Member
    ret
.Index:
    mov rax, [rel ExprType]
    cmp rax, TList
    jb TypeError
    push rax
    call Advance
    call ParseExpr
    NeedType TNum
    Expect "]", ErrBracket
    call Advance
    CompilePrim PrimIndex
    pop rax
    sub rax, TList
    mov [rel ExprType], rax
    mov qword [rel LastVarSlot], 0
    jmp .Post
.Member:
    call Advance
    IfTok "length", .Length
    IfTok "add", .Add
    Fail ErrMember
.Length:
    mov rax, [rel ExprType]
    cmp rax, TText
    je .LengthOk
    cmp rax, TList
    jb TypeError
.LengthOk:
    CompilePrim PrimLength
    SetType TNum
    mov qword [rel LastVarSlot], 0
    call Advance
    jmp .Post
.Add:
    mov rax, [rel ExprType]
    cmp rax, TList
    jb TypeError
    push rax
    push qword [rel LastVarSlot]
    call Advance
    Expect "(", ErrParen
    call Advance
    call ParseExpr
    Expect ")", ErrParen
    call Advance
    pop rcx
    pop rax
    mov rdx, [rel ExprType]
    test rdx, rdx
    jz TypeError
    sub rax, TList
    test rax, rax
    jz .AddUnknown
    cmp rax, rdx
    jne TypeError
    jmp .AddEmit
.AddUnknown:
    test rcx, rcx
    jz .AddEmit
    lea r8, [rdx + TList]
    mov [rcx - 8], r8
.AddEmit:
    CompilePrim PrimListAdd
    SetType TNone
    ret

ParsePrimary:
    cmp qword [rel TokLen], 0
    je .Missing
    IfTok "(", .Paren
    IfTok "[", .List
    IfTok "-", .Neg
    IfTok "true", .True
    IfTok "false", .False
    IfTok "ask", .Ask
    IfTok "random", .Random
    IfTok "number", .ToNumber
    IfTok "text", .ToText
    mov rax, [rel TokPtr]
    cmp byte [rax], '"'
    je .String
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call ParseNumber
    test rdx, rdx
    jz .Name
    mov rbx, rax
    CompileNum rbx
    SetType TNum
    jmp Advance
.True:
    CompileNum 1
    SetType TNum
    jmp Advance
.False:
    CompileNum 0
    SetType TNum
    jmp Advance
.Name:
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call FindWord
    test rax, rax
    jz .Unknown
    cmp rdx, 4
    je .Func
    cmp rdx, 3
    jne .Missing
    mov rbx, rax
    CompileNum rbx
    CompilePrim PrimFetch
    mov rax, [rbx - 8]
    mov [rel ExprType], rax
    mov [rel LastVarSlot], rbx
    jmp Advance
.Func:
    push rax
    call Advance
    Expect "(", ErrParen
    call Advance
    IfTok ")", .ArgsDone
.ArgLoop:
    call ParseExpr
    IfTok ",", .Comma
    Expect ")", ErrParen
    jmp .ArgsDone
.Comma:
    call Advance
    jmp .ArgLoop
.ArgsDone:
    call Advance
    CompilePrim PrimCall
    pop rcx
    push rcx
    call Compile
    pop rcx
    mov rax, [rcx - 8]
    test rax, rax
    jnz .FuncType
    mov eax, TNum
.FuncType:
    mov [rel ExprType], rax
    ret
.Paren:
    call Advance
    call ParseExpr
    Expect ")", ErrParen
    jmp Advance
.List:
    call Advance
    IfTok "]", .EmptyList
    push 0
    push 0
.ListLoop:
    call ParseExpr
    mov rax, [rel ExprType]
    test rax, rax
    jz TypeError
    mov rdx, [rsp]
    test rdx, rdx
    jz .FirstElem
    cmp rax, rdx
    jne TypeError
    jmp .ElemOk
.FirstElem:
    mov [rsp], rax
.ElemOk:
    inc qword [rsp + 8]
    IfTok ",", .ListComma
    Expect "]", ErrBracket
    call Advance
    pop rbx
    pop rsi
    CompileNum rsi
    CompilePrim PrimMakeList
    lea rax, [rbx + TList]
    mov [rel ExprType], rax
    ret
.ListComma:
    call Advance
    jmp .ListLoop
.EmptyList:
    CompileNum 0
    CompilePrim PrimMakeList
    SetType TList
    jmp Advance
.Neg:
    call Advance
    CompileNum 0
    call ParseAtom
    NeedType TNum
    CompilePrim PrimSub
    ret
.Ask:
    call Advance
    cmp qword [rel TokLen], 0
    je .AskNoPrompt
    mov rax, [rel TokPtr]
    cmp byte [rax], '"'
    je .AskPrompt
    IfTok "(", .AskPrompt
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call FindWord
    test rax, rax
    jz .AskNoPrompt
    cmp rdx, 3
    je .AskPrompt
    cmp rdx, 4
    je .AskPrompt
.AskNoPrompt:
    CompileNum 0
    jmp .AskCompile
.AskPrompt:
    call ParseSum
    cmp qword [rel ExprType], TText
    je .AskCompile
    NeedType TNum
    CompilePrim PrimToText
.AskCompile:
    CompilePrim PrimAsk
    SetType TText
    ret
.Random:
    call Advance
    Expect "(", ErrParen
    call Advance
    call ParseExpr
    NeedType TNum
    Expect ",", ErrComma
    call Advance
    call ParseExpr
    NeedType TNum
    Expect ")", ErrParen
    CompilePrim PrimRandom
    SetType TNum
    jmp Advance
.ToNumber:
    call Advance
    Expect "(", ErrParen
    call Advance
    call ParseExpr
    Expect ")", ErrParen
    cmp qword [rel ExprType], TNum
    je .ToNumberDone
    NeedType TText
    CompilePrim PrimToNumber
.ToNumberDone:
    SetType TNum
    jmp Advance
.ToText:
    call Advance
    Expect "(", ErrParen
    call Advance
    call ParseExpr
    Expect ")", ErrParen
    cmp qword [rel ExprType], TText
    je .ToTextDone
    NeedType TNum
    CompilePrim PrimToText
.ToTextDone:
    SetType TText
    jmp Advance
.String:
    mov rdx, [rel TokLen]
    cmp rdx, 2
    jb .BadString
    cmp byte [rax + rdx - 1], '"'
    jne .BadString
    lea rcx, [rax + 1]
    sub rdx, 2
    call CompileText
    jmp Advance
.BadString:
    Fail ErrString
.Missing:
    Fail ErrExpect
.Unknown:
    Fail ErrName

EmitTextLiteral:
    call MakeText
    push rax
    CompilePrim PrimLit
    pop rcx
    jmp Compile

CompileText:
    push rbx
    push rsi
    push rdi
    push r12
    mov rsi, rcx
    lea rdi, [rcx + rdx]
    xor r12d, r12d
.Segment:
    mov rbx, rsi
.Find:
    cmp rsi, rdi
    jae .Tail
    cmp byte [rsi], '{'
    je .Brace
    inc rsi
    jmp .Find
.Brace:
    mov rcx, rbx
    mov rdx, rsi
    sub rdx, rbx
    test rdx, rdx
    jz .NoLiteral
    call EmitTextLiteral
    call .Join
.NoLiteral:
    inc rsi
    mov rbx, rsi
.FindClose:
    cmp rsi, rdi
    jae .Bad
    cmp byte [rsi], '}'
    je .Close
    inc rsi
    jmp .FindClose
.Close:
    call GetInput
    push rax
    push rdx
    push qword [rel TokPtr]
    push qword [rel TokLen]
    mov rcx, rbx
    mov rdx, rsi
    sub rdx, rbx
    call SetInput
    call Advance
    call ParseExpr
    cmp qword [rel TokLen], 0
    jne .Bad
    cmp qword [rel ExprType], TText
    je .Typed
    NeedType TNum
    CompilePrim PrimToText
.Typed:
    pop qword [rel TokLen]
    pop qword [rel TokPtr]
    pop rdx
    pop rcx
    sub rdx, rcx
    call SetInput
    call .Join
    inc rsi
    jmp .Segment
.Tail:
    mov rcx, rbx
    mov rdx, rsi
    sub rdx, rbx
    test rdx, rdx
    jnz .TailLiteral
    test r12, r12
    jnz .Finish
.TailLiteral:
    call EmitTextLiteral
    call .Join
.Finish:
    SetType TText
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret
.Join:
    test r12, r12
    jz .First
    CompilePrim PrimConcat
.First:
    mov r12d, 1
    ret
.Bad:
    Fail ErrString

StmtExpr:
    mov [rel TokPtr], r12
    mov [rel TokLen], r13
    call ParseExpr
    cmp qword [rel ExprType], TNone
    je .NoDrop
    CompilePrim PrimDrop
.NoDrop:
    jmp Pushback

SayWord:
    call Advance
    call ParseExpr
    cmp qword [rel ExprType], TText
    je .Text
    NeedType TNum
    CompilePrim PrimPrint
    jmp Pushback
.Text:
    CompilePrim PrimSayText
    jmp Pushback

SetWord:
    call Advance
    cmp qword [rel TokLen], 0
    je .Bad
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call FindWord
    test rax, rax
    jz .New
    cmp rdx, 3
    jne .Bad
    jmp .Have
.New:
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call CreateVar
.Have:
    push rax
    call Advance
    IfTok "[", .IndexSet
    IfTok ":", .Type
    jmp .Op
.Type:
    call Advance
    call ParseTypeName
    mov rcx, [rsp]
    mov rdx, [rcx - 8]
    test rdx, rdx
    jz .Declare
    cmp rdx, rax
    jne TypeError
.Declare:
    mov [rcx - 8], rax
    call Advance
.Op:
    IfTok "=", .Assign
    IfTok "+=", .AddAssign
    IfTok "-=", .SubAssign
    IfTok "*=", .MulAssign
    IfTok "/=", .DivAssign
.Bad:
    Fail ErrSet
.Assign:
    call Advance
    call ParseExpr
    mov rcx, [rsp]
    mov rdx, [rcx - 8]
    mov rax, [rel ExprType]
    test rax, rax
    jz TypeError
    test rdx, rdx
    jz .TakeType
    cmp rdx, rax
    je .Store
    cmp rdx, TList
    jne TypeError
    cmp rax, TList
    jb TypeError
.TakeType:
    mov [rcx - 8], rax
    jmp .Store
.AddAssign:
    mov rcx, [rsp]
    cmp qword [rcx - 8], TText
    je .Append
    lea rax, [rel PrimAdd]
    jmp .Compound
.SubAssign:
    lea rax, [rel PrimSub]
    jmp .Compound
.MulAssign:
    lea rax, [rel PrimMul]
    jmp .Compound
.DivAssign:
    lea rax, [rel PrimDiv]
.Compound:
    mov rcx, [rsp]
    cmp qword [rcx - 8], TNum
    jne TypeError
    push rax
    mov rbx, [rsp + 8]
    CompileNum rbx
    CompilePrim PrimFetch
    call Advance
    call ParseExpr
    NeedType TNum
    pop rcx
    call Compile
    jmp .Store
.Append:
    mov rbx, rcx
    CompileNum rbx
    CompilePrim PrimFetch
    call Advance
    call ParseExpr
    cmp qword [rel ExprType], TText
    je .AppendText
    NeedType TNum
    CompilePrim PrimToText
.AppendText:
    CompilePrim PrimConcat
.Store:
    pop rbx
    CompileNum rbx
    CompilePrim PrimStore
    jmp Pushback
.IndexSet:
    mov rbx, [rsp]
    cmp qword [rbx - 8], TList
    jb TypeError
    CompileNum rbx
    CompilePrim PrimFetch
    call Advance
    call ParseExpr
    NeedType TNum
    Expect "]", ErrBracket
    call Advance
    Expect "=", ErrSet
    call Advance
    call ParseExpr
    mov rcx, [rsp]
    mov rax, [rcx - 8]
    sub rax, TList
    mov rdx, [rel ExprType]
    test rdx, rdx
    jz TypeError
    test rax, rax
    jz .IndexUnknown
    cmp rax, rdx
    jne TypeError
    jmp .IndexEmit
.IndexUnknown:
    lea r8, [rdx + TList]
    mov [rcx - 8], r8
.IndexEmit:
    CompilePrim PrimSetIndex
    pop rax
    jmp Pushback

IfWord:
    call Advance
    call ParseExpr
    NeedType TNum
    lea rcx, [rel PrimBranch0]
    call EmitJump
    DPush 0
    DPush rax
    DPush 0
    DPush 0
    DPush TagIf
    inc qword [rel OpenBlocks]
    jmp Pushback

OtherwiseWord:
    cmp qword [rel OpenBlocks], 0
    je .Bad
    cmp qword [r15 - 8], TagIf
    jne .Bad
    lea rcx, [rel PrimBranch]
    call EmitJump
    lea r8, [r15 - 40]
    mov rdx, [r8]
    mov [rax], rdx
    mov [r8], rax
    mov rcx, [r8 + 8]
    test rcx, rcx
    jz .NoPending
    mov rdx, [rel Here]
    mov [rcx], rdx
    mov qword [r8 + 8], 0
.NoPending:
    call Advance
    IfTok "if", .ElseIf
    jmp Pushback
.ElseIf:
    call Advance
    call ParseExpr
    NeedType TNum
    lea rcx, [rel PrimBranch0]
    call EmitJump
    mov [r15 - 32], rax
    jmp Pushback
.Bad:
    Fail ErrOther

EndWord:
    cmp qword [rel OpenBlocks], 0
    je .Bad
    mov rax, [r15 - 8]
    cmp rax, TagIf
    je .If
    cmp rax, TagLoop
    je .Loop
    jmp .Fn
.If:
    mov rcx, [r15 - 32]
    test rcx, rcx
    jz .NoPending
    mov rdx, [rel Here]
    mov [rcx], rdx
.NoPending:
    mov rcx, [r15 - 40]
    mov rdx, [rel Here]
    call PatchChain
    jmp .Pop
.Loop:
    mov rcx, [r15 - 16]
    mov rdx, [rel Here]
    call PatchChain
    mov rbx, [r15 - 24]
    test rbx, rbx
    jz .NoCounter
    test rbx, 1
    jnz .CountUp
    CompileNum rbx
    CompilePrim PrimFetch
    CompileNum 1
    CompilePrim PrimSub
    CompileNum rbx
    CompilePrim PrimStore
    jmp .NoCounter
.CountUp:
    and rbx, -2
    CompileNum rbx
    CompilePrim PrimFetch
    CompileNum 1
    CompilePrim PrimAdd
    CompileNum rbx
    CompilePrim PrimStore
.NoCounter:
    CompilePrim PrimBranch
    mov rcx, [r15 - 40]
    call Compile
    mov rcx, [r15 - 32]
    mov rdx, [rel Here]
    call PatchChain
    jmp .Pop
.Fn:
    CompileNum 0
    call EmitEpilogue
    call EndDef
    mov qword [rel InFn], 0
.Pop:
    sub r15, 40
    dec qword [rel OpenBlocks]
    ret
.Bad:
    Fail ErrEnd

RepeatWord:
    call Advance
    IfTok "forever", .Forever
    IfTok "while", .While
    IfTok "until", .Until
    IfTok "each", .Each
    call AllocSlot
    push rax
    call ParseExpr
    NeedType TNum
    IfTok "times", .Times
    Fail ErrTimes
.Times:
    pop rbx
    CompileNum rbx
    CompilePrim PrimStore
    mov rax, [rel Here]
    push rax
    CompileNum rbx
    CompilePrim PrimFetch
    CompileNum 0
    CompilePrim PrimGreater
    lea rcx, [rel PrimBranch0]
    call EmitJump
    pop rdx
    DPush rdx
    DPush rax
    DPush rbx
    DPush 0
    DPush TagLoop
    inc qword [rel OpenBlocks]
    ret
.Forever:
    mov rax, [rel Here]
    DPush rax
    DPush 0
    DPush 0
    DPush 0
    DPush TagLoop
    inc qword [rel OpenBlocks]
    ret
.While:
    call Advance
    mov rax, [rel Here]
    push rax
    call ParseExpr
    NeedType TNum
    jmp .Cond
.Until:
    call Advance
    mov rax, [rel Here]
    push rax
    call ParseExpr
    NeedType TNum
    CompileNum 0
    CompilePrim PrimEq
.Cond:
    lea rcx, [rel PrimBranch0]
    call EmitJump
    pop rdx
    DPush rdx
    DPush rax
    DPush 0
    DPush 0
    DPush TagLoop
    inc qword [rel OpenBlocks]
    jmp Pushback
.Each:
    call Advance
    cmp qword [rel TokLen], 0
    je .BadEach
    push qword [rel TokPtr]
    push qword [rel TokLen]
    call Advance
    Expect "in", ErrEach
    call Advance
    call ParseExpr
    mov rax, [rel ExprType]
    cmp rax, TList
    jb TypeError
    push rax
    call AllocSlot
    mov rbx, rax
    CompileNum rbx
    CompilePrim PrimStore
    call AllocSlot
    mov rsi, rax
    CompileNum 0
    CompileNum rsi
    CompilePrim PrimStore
    mov rcx, [rsp + 16]
    mov rdx, [rsp + 8]
    call FindWord
    test rax, rax
    jz .EachNew
    cmp rdx, 3
    je .EachHave
.EachNew:
    mov rcx, [rsp + 16]
    mov rdx, [rsp + 8]
    call CreateVar
.EachHave:
    mov rdi, rax
    pop rax
    add rsp, 16
    sub rax, TList
    mov rdx, [rdi - 8]
    test rdx, rdx
    jz .EachType
    test rax, rax
    jz .EachTyped
    cmp rdx, rax
    jne TypeError
.EachType:
    mov [rdi - 8], rax
.EachTyped:
    mov r12, [rel Here]
    CompileNum rsi
    CompilePrim PrimFetch
    CompileNum rbx
    CompilePrim PrimFetch
    CompilePrim PrimLength
    CompilePrim PrimLess
    lea rcx, [rel PrimBranch0]
    call EmitJump
    push rax
    CompileNum rbx
    CompilePrim PrimFetch
    CompileNum rsi
    CompilePrim PrimFetch
    CompileNum 1
    CompilePrim PrimAdd
    CompilePrim PrimIndex
    CompileNum rdi
    CompilePrim PrimStore
    pop rax
    lea rdx, [rsi + 1]
    DPush r12
    DPush rax
    DPush rdx
    DPush 0
    DPush TagLoop
    inc qword [rel OpenBlocks]
    jmp Pushback
.BadEach:
    Fail ErrEach

FindLoopFrame:
    mov rcx, [rel OpenBlocks]
    mov rax, r15
.Loop:
    test rcx, rcx
    jz .None
    cmp qword [rax - 8], TagLoop
    je .Found
    cmp qword [rax - 8], TagFn
    je .None
    sub rax, 40
    dec rcx
    jmp .Loop
.Found:
    sub rax, 40
    ret
.None:
    Fail ErrLoop

StopWord:
    call FindLoopFrame
    mov r11, rax
    lea rcx, [rel PrimBranch]
    call EmitJump
    mov rdx, [r11 + 8]
    mov [rax], rdx
    mov [r11 + 8], rax
    ret

SkipWord:
    call FindLoopFrame
    mov r11, rax
    lea rcx, [rel PrimBranch]
    call EmitJump
    mov rdx, [r11 + 24]
    mov [rax], rdx
    mov [r11 + 24], rax
    ret

EmitEpilogue:
    xor ebx, ebx
.Loop:
    cmp rbx, [rel FnParamCount]
    jae .Done
    CompilePrim PrimFromR
    lea rax, [rel FnParams]
    mov rsi, [rax + rbx * 8]
    CompileNum rsi
    CompilePrim PrimStore
    inc rbx
    jmp .Loop
.Done:
    CompilePrim PrimExit
    ret

ReturnWord:
    cmp qword [rel InFn], 0
    je .Bad
    call Advance
    call ParseExpr
    mov rax, [rel ExprType]
    test rax, rax
    jz TypeError
    mov rcx, [rel FnEntry]
    mov rcx, [rcx + 8]
    mov rdx, [rcx - 8]
    test rdx, rdx
    jz .SetReturn
    cmp rdx, rax
    jne TypeError
    jmp .Emit
.SetReturn:
    mov [rcx - 8], rax
.Emit:
    call EmitEpilogue
    jmp Pushback
.Bad:
    Fail ErrReturn

DoWord:
    cmp qword [rel InFn], 0
    jne .Bad
    cmp qword [rel OpenBlocks], 0
    jne .Bad
    call Advance
    cmp qword [rel TokLen], 0
    je .Bad
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call BeginDef
    xor ecx, ecx
    call Compile
    mov rax, [rel Latest]
    mov byte [rax + 16], 4
    mov rcx, [rel Here]
    mov [rax + 8], rcx
    mov qword [rel InFn], 1
    mov qword [rel FnParamCount], 0
    call Advance
    Expect "(", ErrParen
    call Advance
    IfTok ")", .ParamsDone
.ParamLoop:
    cmp qword [rel TokLen], 0
    je .BadParen
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call FindWord
    test rax, rax
    jz .NewParam
    cmp rdx, 3
    je .HaveParam
.NewParam:
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call CreateVar
.HaveParam:
    mov rcx, [rel FnParamCount]
    lea rdx, [rel FnParams]
    mov [rdx + rcx * 8], rax
    inc qword [rel FnParamCount]
    push rax
    call Advance
    IfTok ":", .ParamType
    mov eax, TNum
    jmp .SetParamType
.ParamType:
    call Advance
    call ParseTypeName
    push rax
    call Advance
    pop rax
.SetParamType:
    pop rcx
    mov rdx, [rcx - 8]
    test rdx, rdx
    jz .StoreParamType
    cmp rdx, rax
    jne TypeError
.StoreParamType:
    mov [rcx - 8], rax
    IfTok ",", .NextParam
    IfTok ")", .ParamsDone
.BadParen:
    Fail ErrParen
.NextParam:
    call Advance
    jmp .ParamLoop
.ParamsDone:
    call Advance
    IfTok ":", .ReturnType
    call Pushback
    jmp .Prologue
.ReturnType:
    call Advance
    call ParseTypeName
    mov rcx, [rel FnEntry]
    mov rcx, [rcx + 8]
    mov [rcx - 8], rax
.Prologue:
    mov rbx, [rel FnParamCount]
.PLoop:
    test rbx, rbx
    jz .PDone
    dec rbx
    lea rax, [rel FnParams]
    mov rsi, [rax + rbx * 8]
    CompileNum rsi
    CompilePrim PrimFetch
    CompilePrim PrimToR
    CompileNum rsi
    CompilePrim PrimStore
    jmp .PLoop
.PDone:
    DPush 0
    DPush 0
    DPush 0
    DPush 0
    DPush TagFn
    inc qword [rel OpenBlocks]
    ret
.Bad:
    Fail ErrDo
