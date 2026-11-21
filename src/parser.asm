%include "macros.inc"

global Advance
global ParseExpr
global ResetCompiler
global OpenBlocks
global DropFn
global MakingConst
global InFn
extern Warn
global StmtExpr
global TokPtr
global TokLen
global ErrTokPtr
global ErrTokLen
global ErrPos
global PrevTokPtr
global SayWord
global SetWord
global KeepWord
global IfWord
global OtherwiseWord
global EndWord
global RepeatWord
global StopWord
global SkipWord
global DoWord
global ReturnWord
global ByeWord
global HintElse
global HintElif
global HintThen
global HintFor
global HintWhile
global HintFunction
global HintLocal
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
extern CopyString
extern MakeText
extern InitStack
extern Abort
extern FileMode
extern PrimLit
extern PrimAdd
extern PrimSub
extern PrimMul
extern PrimDiv
extern PrimFloorDiv
extern PrimMod
extern PrimPow
extern PrimAnd
extern PrimOr
extern PrimDrop
extern PrimSwap
extern PrimFetch
extern PrimStore
extern PrimPrint
extern PrimExit
extern PrimCall
extern PrimEnter
extern PrimReturn
extern PrimNoReturn
extern PrimLocalGet
extern PrimLocalSet
extern PrimBranch
extern PrimBranch0
extern PrimBye
extern PrimLess
extern PrimGreater
extern PrimEq
extern PrimNotEq
extern PrimLessEq
extern PrimGreaterEq
extern PrimSayText
extern PrimSayBool
extern PrimBoolToText
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
extern TypeKind
extern ListOf
extern MapOf
extern ElemOf
extern InternRecord
extern FindField
extern FieldCount
extern NewEnum
extern FuncOf
extern PrimCallValue
extern PrimTry
extern PrimTryEnd
extern PrimLastError
extern NextToken
extern DictHere
extern PrimLessEq
extern TypeTable
global KindWord
global CheckWord
global IsWord
global TryWord
global LaterWord
extern CreateVar
extern ParseDecimalText
extern PrimDup
extern PrimDup2
extern PrimToDec
extern PrimToDecUnder
extern PrimDAdd
extern PrimDSub
extern PrimDMul
extern PrimDDiv
extern PrimDLess
extern PrimDGreater
extern PrimDLessEq
extern PrimDGreaterEq
extern PrimDEq
extern PrimDNotEq
extern PrimDecToText
extern PrimDecToNum
extern PrimRound
extern PrimTextToDec
extern PrimShow
extern PrimFormat
extern PrimMakeMap
extern PrimMapGet
extern PrimMapSet
extern PrimMapHas
extern PrimMapKeys
extern PrimMakeRecord
extern PrimGetField
extern PrimSetField
extern PrimListHas
extern PrimListHasText
extern PrimTextHas
extern PrimRange
extern PrimTextAt
extern PrimCode
extern PrimChar
extern PrimBitAnd
extern PrimBitOr
extern PrimBitXor
extern PrimShiftLeft
extern PrimShiftRight

%define TagIf   1
%define TagLoop 2
%define TagFn   3
%define TagDummy 4
%define TagCheck 5
%define TagTry   6

%define TNone 0
%define TNum  1
%define TText 2
%define TBool 3
%define TDec  4

%define KList 5
%define KMap  6
%define KRec  7
%define KEnum 8
%define KFunc 9

%define MaxLocals 64
%define SigCells  67
%define SigDef    152
%define SigFlags  280
%define SigName   288

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
    mov rax, [rel PrevTokPtr]
    mov [rel ErrPos], rax
    lea rcx, [rel %1]
    mov edx, %1Len
    jmp Abort
%endmacro

%macro FailTok 1
    mov rax, [rel TokPtr]
    mov [rel ErrTokPtr], rax
    mov [rel ErrPos], rax
    mov rax, [rel TokLen]
    mov [rel ErrTokLen], rax
    lea rcx, [rel %1]
    mov edx, %1Len
    jmp Abort
%endmacro

%macro Msg 2
%1 db %2
%1Len equ $ - %1
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

%macro NumOp 4
%1:
    push qword [rel ExprType]
    call Advance
    call %2
    pop rax
    cmp rax, TNum
    jne TypeError
    NeedType TNum
    CompilePrim %3
    SetType %4
%endmacro

%macro ArithOp 4
%1:
    push qword [rel ExprType]
    call Advance
    call %2
    pop rax
    call NumericPair
    lea rcx, [rel %3]
    cmp rax, TDec
    jne %%Emit
    lea rcx, [rel %4]
%%Emit:
    mov [rel ExprType], rax
    call Compile
%endmacro

section .data
Msg ErrExpect,     "expected a value here"
Msg ErrParen,      "missing ( or )"
Msg ErrBracket,    "missing [ or ]"
Msg ErrComma,      "missing ,"
Msg ErrName,       "unknown name"
Msg ErrType,       "type mismatch"
Msg ErrTypeName,   "unknown type (use number, text, bool or list)"
Msg ErrMember,     "unknown .something (lists and text have .length, lists have .add)"
Msg ErrSet,        "set needs a name and = (set score = 0)"
Msg ErrSetName,    "can't use that word as a variable name"
Msg ErrDoubleEq,   "use = to set a value (== is for comparing)"
Msg ErrNeedSet,    "to make a new variable, use set (set x = 5)"
Msg ErrConst,      "can't change a keep value"
Msg ErrKeepExists, "keep makes a new value, but this name already exists"
Msg ErrString,     "text is missing its closing quote or }"
Msg ErrBrace,      "lists use [ ] (records with { } aren't built yet)"
Msg ErrTimes,      "repeat needs times, while, until, forever or each"
Msg ErrEach,       "repeat each needs: repeat each name in list"
Msg ErrEnd,        "end without a block to close"
Msg ErrOther,      "otherwise without an if"
Msg ErrLoop,       "stop and skip only work inside a repeat (blocks close with end)"
Msg ErrDo,         "do needs a name and has to be outside other blocks"
Msg ErrReturn,     "return only works inside a do function"
Msg ErrArgs,       "wrong number of arguments"
Msg ErrArgTwice,   "this argument is given twice:"
Msg ErrNoParam,    "this function has no parameter called"
Msg ErrMissingArg, "missing an argument for"
Msg ErrRestLast,   "the ... parameter has to be the last one"
Msg ErrRestDefault, "the ... parameter can't have a default"
Msg ErrArgType,    "argument has the wrong type"
Msg ErrTooMany,    "too many variables in one function (max 64, params max 16)"
Msg ErrCond,       "this needs true or false (a comparison like x > 0)"
Msg ErrColon,      "TomLang ifs and repeats don't need a colon"
Msg ErrLogic,      "each side of and/or needs true or false, like x == 1 or x == 2"
Msg ErrSayList,    "can't say a whole list yet (say each item with repeat each)"
Msg ErrElse,       "TomLang uses otherwise instead of else"
Msg ErrElif,       "TomLang uses otherwise if"
Msg ErrThen,       "TomLang ifs don't need then"
Msg ErrFor,        "TomLang uses repeat each x in list, or repeat N times"
Msg ErrWhile,      "TomLang uses repeat while ..."
Msg ErrFunction,   "TomLang functions start with do (do name() ... end)"
Msg ErrNothing,    "there's nothing to say here"
Msg ErrOrHint,     "TomLang uses or instead of ||"
Msg ErrAndHint,    "TomLang uses and instead of &&"
Msg ErrNoField,    "that record has no field called"
Msg WarnExists,    "already exists; to change it, leave out set:"
Msg ErrChoice,     "a one-line choice needs otherwise, like a if x > 1 otherwise b"
Msg ErrTupleMany,  "too many values (9 at most)"
Msg ErrNotTuple,   "this doesn't give back several values to split up"
Msg ErrTupleCount, "the number of names doesn't match the number of values"
DigitNames db "123456789"
Msg ErrNoKindValue, "that kind has no value called"
Msg ErrKindEq,     "a kind needs = and its values, like kind Move = Rock, Paper, Scissors"
Msg ErrKindWhere,  "kind has to be outside functions and blocks"
Msg ErrKindName,   "this can't be used as a name:"
Msg ErrKindTaken,  "this name is already used:"
Msg ErrIs,         "is only goes inside a check block (check x / is 1 / ... / end)"
Msg ErrIsAfter,    "otherwise has to be the last part of a check"
Msg ErrArrow,      "a short function needs =>, like x => x * 2"
Msg ErrNotFunc,    "this needs a function"
Msg ErrBadFunc,    "this function takes the wrong kind of values here"
Msg ErrCapture,    "short functions can't use the variables of the function they are in yet (globals and their own inputs are fine):"
Msg ErrLaterWhere, "later only goes inside a do function"
Msg ErrLaterWhat,  "later needs one simple line after it, like: later say ready"
Msg ErrBadSpec,    "unknown format, try something like {x:commas} or {x:2 places}"
Msg ErrMapColon,   "map items need a : between key and value"
Msg ErrBraceClose, "missing }"
Msg ErrRecordColon, "record fields need a : after the name"
Msg ErrRecordName, "record fields need a name, like { name: value }"
Msg ErrNotExist,   "doesn't exist yet, make it first with set:"
Msg ErrCompoundNew, "set makes a new variable here, so it has no value to change yet (inside a function, change an outside variable without set: score += 1)"
Msg ErrLocal,      "TomLang makes variables with set (set x = 5)"

align 8
TempTop dq TempFields
EnumTop dq EnumNames
align 8
times SigCells dq 0
BrokenBody dq PrimEnter, 0, PrimLit, 0, PrimReturn

section .bss
LaterCount resq 1
LaterPos resq 16
HintCount resq 1
HintPtr   resq 1
HintOne   resq 1
CurHintCount resq 1
CurHintPtr resq 1
ItemList resq 1
ItemIndex resq 1
OuterFrame resq 1
EnumNames resq 2 * 4096
SpecStart resq 1
SpecEnd   resq 1
TokPtr       resq 1
TokLen       resq 1
ErrTokPtr    resq 1
ErrTokLen    resq 1
ErrPos       resq 1
PrevTokPtr   resq 1
ExprType     resq 1
LastVarRef   resq 1
OpenBlocks   resq 1
InFn         resq 1
FnSig        resq 1
FnFrameSlot  resq 1
MakingConst  resq 1
LocalCount   resq 1
VoidCall     resq 1
StmtStart    resq 1
StmtHere     resq 1
PathRef      resq 1
PathType     resq 1
PathDepth    resq 1
PathKey      resq 1
PathGet      resq 1
PathSet      resq 1
PathElem     resq 1
PathOffset   resq 1
PathIsField  resq 1
PathOp       resq 1
TempFields   resq 3 * 1024
LocalPtr     resq MaxLocals
LocalLen     resq MaxLocals
LocalType    resq MaxLocals
LocalConst   resq MaxLocals

section .text
Advance:
    mov rax, [rel TokPtr]
    mov [rel PrevTokPtr], rax
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
    IfTok "decimal", .Dec
    IfTok "text", .Text
    IfTok "bool", .Bool
    IfTok "list", .List
    IfTok "map", .Map
    IfTok "{", .Record
    IfTok "do", .Func
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call FindWord
    test rax, rax
    jz .BadName
    cmp rdx, 6
    jne .BadName
    ret
.BadName:
    Fail ErrTypeName
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
.List:
    call OfType
    mov rcx, rax
    jmp ListOf
.Map:
    call OfType
    mov rcx, rax
    jmp MapOf
.Func:
    sub rsp, 136
    mov qword [rsp + 128], 0
    call Advance
    Expect "(", ErrParen
    call Advance
    IfTok ")", .FuncParams
.FuncLoop:
    call ParseTypeName
    mov rcx, [rsp + 128]
    cmp rcx, 16
    jae .FuncMany
    mov [rsp + rcx * 8], rax
    inc qword [rsp + 128]
    call Advance
    IfTok ",", .FuncNext
    Expect ")", ErrParen
    jmp .FuncParams
.FuncNext:
    call Advance
    jmp .FuncLoop
.FuncParams:
    push qword [rel TokPtr]
    push qword [rel TokLen]
    call Advance
    IfTok ":", .FuncRet
    mov rcx, [rel TokPtr]
    call Unread
    pop qword [rel TokLen]
    pop qword [rel TokPtr]
    xor ecx, ecx
    jmp .FuncMake
.FuncRet:
    add rsp, 16
    call Advance
    call ParseTypeName
    mov rcx, rax
.FuncMake:
    mov rdx, [rsp + 128]
    mov r8, rsp
    call FuncOf
    add rsp, 136
    ret
.FuncMany:
    Fail ErrTooMany
.Record:
    push qword [rel TempTop]
    push 0
.RecordLoop:
    call Advance
    IfTok "}", .RecordDone
    call IsNameStart
    test eax, eax
    jz .RecordBad
    mov rax, [rsp]
    lea rax, [rax + rax * 2]
    mov rcx, [rsp + 8]
    lea r8, [rcx + rax * 8]
    mov rax, [rel TokPtr]
    mov [r8], rax
    mov rax, [rel TokLen]
    mov [r8 + 8], rax
    inc qword [rsp]
    mov rax, [rsp]
    lea rax, [rax + rax * 2]
    shl rax, 3
    add rax, [rsp + 8]
    mov [rel TempTop], rax
    push r8
    call Advance
    Expect ":", ErrTypeName
    call Advance
    call ParseTypeName
    pop r8
    mov [r8 + 16], rax
    call Advance
    IfTok ",", .RecordLoop
    Expect "}", ErrTypeName
.RecordDone:
    pop rcx
    pop rdx
    mov [rel TempTop], rdx
    jmp InternRecord
.RecordBad:
    Fail ErrTypeName

OfType:
    call GetInput
    push rax
    push qword [rel TokPtr]
    push qword [rel TokLen]
    call Advance
    IfTok "of", .Of
    pop qword [rel TokLen]
    pop qword [rel TokPtr]
    pop rcx
    call Unread
    xor eax, eax
    ret
.Of:
    add rsp, 24
    call Advance
    jmp ParseTypeName

Compatible:
    test rdx, rdx
    jz .No
    test rax, rax
    jz .TakeExpr
    cmp rax, rdx
    je .Same
    push rax
    push rdx
    mov rcx, rax
    call TypeKind
    mov r10, rax
    mov rcx, [rsp]
    call TypeKind
    mov r11, rax
    pop rdx
    pop rax
    cmp r10, r11
    jne .No
    cmp r10, KList
    je .Container
    cmp r10, KMap
    jne .No
.Container:
    push rax
    push rdx
    mov rcx, rax
    call ElemOf
    test rax, rax
    pop rdx
    pop rax
    jz .TakeExpr
    push rax
    push rdx
    mov rcx, rdx
    call ElemOf
    test rax, rax
    pop rdx
    pop rax
    jz .Same
.No:
    xor eax, eax
    ret
.TakeExpr:
    mov rax, rdx
    ret
.Same:
    ret

KindOfType:
    mov rcx, rax
    jmp TypeKind

ToTextRaw:
    cmp rax, TText
    je .Done
    cmp rax, TNum
    je .Num
    cmp rax, TBool
    je .Bool
    cmp rax, TDec
    je .Dec
    test rax, rax
    jz TypeError
    push rax
    CompilePrim PrimShow
    pop rcx
    jmp Compile
.Bool:
    CompilePrim PrimBoolToText
    ret
.Dec:
    CompilePrim PrimDecToText
    ret
.Num:
    CompilePrim PrimToText
.Done:
    ret

EmitSay:
    mov rax, [rel ExprType]
    cmp rax, TText
    je .Text
    cmp rax, TBool
    je .Bool
    cmp rax, TNum
    je .Num
    test rax, rax
    jz .Nothing
    call ToTextRaw
.Text:
    CompilePrim PrimSayText
    ret
.Num:
    CompilePrim PrimPrint
    ret
.Bool:
    CompilePrim PrimSayBool
    ret
.Nothing:
    Fail ErrNothing

IsNameStart:
    mov rax, [rel TokPtr]
    mov cl, [rax]
    cmp cl, '_'
    je .Yes
    or cl, 0x20
    cmp cl, 'a'
    jb .No
    cmp cl, 'z'
    ja .No
.Yes:
    mov eax, 1
    ret
.No:
    xor eax, eax
    ret

IsReserved:
    IfTok "true", .Yes
    IfTok "false", .Yes
    IfTok "ask", .Yes
    IfTok "random", .Yes
    IfTok "number", .Yes
    IfTok "text", .Yes
    IfTok "and", .Yes
    IfTok "or", .Yes
    IfTok "not", .Yes
    IfTok "times", .Yes
    IfTok "in", .Yes
    IfTok "decimal", .Yes
    IfTok "round", .Yes
    IfTok "charCode", .Yes
    IfTok "charFrom", .Yes
    IfTok "xor", .Yes
    IfTok "of", .Yes
    IfTok "error", .Yes
    xor eax, eax
    ret
.Yes:
    mov eax, 1
    ret

DropFn:
    mov rax, [rel FnEntry]
    test rax, rax
    jz .NoFn
    lea rcx, [rel BrokenBody]
    mov [rax + 8], rcx
    mov qword [rel FnEntry], 0
.NoFn:
    mov qword [rel InFn], 0
    mov qword [rel LocalCount], 0
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
    mov qword [rel LocalCount], 0
    mov qword [rel MakingConst], 0
    call InitStack
    ret

FindLocal:
    xor eax, eax
    cmp qword [rel InFn], 0
    je .Done
    mov r8, [rel LocalCount]
.Loop:
    test r8, r8
    jz .None
    dec r8
    lea r9, [rel LocalLen]
    cmp rdx, [r9 + r8 * 8]
    jne .Loop
    lea r9, [rel LocalPtr]
    mov r9, [r9 + r8 * 8]
    xor r10d, r10d
.Compare:
    cmp r10, rdx
    je .Found
    mov al, [rcx + r10]
    cmp al, [r9 + r10]
    jne .Loop
    inc r10
    jmp .Compare
.Found:
    lea rax, [r8 * 8 + 2]
    ret
.None:
    xor eax, eax
.Done:
    ret

AddLocal:
    mov rax, [rel LocalCount]
    cmp rax, MaxLocals
    jae .TooMany
    push rdx
    xor eax, eax
    test rdx, rdx
    jz .Store
    call CopyString
.Store:
    pop rdx
    mov r8, [rel LocalCount]
    lea r9, [rel LocalPtr]
    mov [r9 + r8 * 8], rax
    lea r9, [rel LocalLen]
    mov [r9 + r8 * 8], rdx
    lea r9, [rel LocalType]
    mov qword [r9 + r8 * 8], 0
    lea r9, [rel LocalConst]
    mov qword [r9 + r8 * 8], 0
    inc qword [rel LocalCount]
    lea rax, [r8 * 8 + 2]
    ret
.TooMany:
    Fail ErrTooMany

LookupVar:
    push rcx
    push rdx
    call FindLocal
    test rax, rax
    jz .Global
    add rsp, 16
    mov rcx, rax
    shr rcx, 3
    lea r8, [rel LocalConst]
    mov rdx, [r8 + rcx * 8]
    ret
.Global:
    pop rdx
    pop rcx
    call FindWord
    test rax, rax
    jz .None
    cmp rdx, 3
    je .Var
    cmp rdx, 5
    je .Const
.None:
    xor eax, eax
    xor edx, edx
    ret
.Var:
    xor edx, edx
    ret
.Const:
    mov edx, 1
    ret

NewVar:
    cmp qword [rel InFn], 0
    jne AddLocal
    jmp CreateVar

NewHidden:
    cmp qword [rel InFn], 0
    je AllocSlot
    xor ecx, ecx
    xor edx, edx
    jmp AddLocal

MarkConst:
    test rax, 2
    jnz .Local
    mov r8, [rel Latest]
    mov byte [r8 + 16], 5
    ret
.Local:
    mov r8, rax
    shr r8, 3
    lea r9, [rel LocalConst]
    mov qword [r9 + r8 * 8], 1
    ret

TypeOf:
    test rcx, 2
    jnz .Local
    mov rax, [rcx - 8]
    ret
.Local:
    shr rcx, 3
    lea rax, [rel LocalType]
    mov rax, [rax + rcx * 8]
    ret

SetTypeOf:
    test rcx, 2
    jnz .Local
    mov [rcx - 8], rdx
    ret
.Local:
    shr rcx, 3
    lea rax, [rel LocalType]
    mov [rax + rcx * 8], rdx
    ret

EmitLoad:
    push rcx
    test rcx, 2
    jnz .Local
    CompilePrim PrimLit
    pop rcx
    call Compile
    CompilePrim PrimFetch
    ret
.Local:
    CompilePrim PrimLocalGet
    pop rcx
    and rcx, -8
    jmp Compile

EmitStore:
    push rcx
    test rcx, 2
    jnz .Local
    CompilePrim PrimLit
    pop rcx
    call Compile
    CompilePrim PrimStore
    ret
.Local:
    CompilePrim PrimLocalSet
    pop rcx
    and rcx, -8
    jmp Compile

NeedCondition:
    IfTok ":", .Colon
    IfTok "then", .Then
    cmp qword [rel ExprType], TBool
    jne .NotBool
    ret
.Colon:
    Fail ErrColon
.Then:
    Fail ErrThen
.NotBool:
    Fail ErrCond

CheckLogic:
    cmp rax, TBool
    jne .Bad
    cmp qword [rel ExprType], TBool
    jne .Bad
    ret
.Bad:
    Fail ErrLogic

NumericPair:
    mov rdx, [rel ExprType]
    cmp rax, TNum
    jne .Check
    cmp rdx, TNum
    jne .Check
    mov eax, TNum
    ret
.Check:
    cmp rax, TNum
    je .LeftOk
    cmp rax, TDec
    jne TypeError
.LeftOk:
    cmp rdx, TNum
    je .RightOk
    cmp rdx, TDec
    jne TypeError
.RightOk:
    cmp rdx, TNum
    jne .RightDec
    push rax
    CompilePrim PrimToDec
    pop rax
.RightDec:
    cmp rax, TNum
    jne .Done
    CompilePrim PrimToDecUnder
.Done:
    mov eax, TDec
    ret

SameLine:
    mov rax, [rel TokPtr]
    mov rcx, rax
.Back:
    dec rcx
    movzx edx, byte [rcx]
    cmp edx, ' '
    je .Back
    cmp edx, 9
    je .Back
    cmp edx, 10
    je .No
    cmp edx, 13
    je .No
    mov eax, 1
    ret
.No:
    xor eax, eax
    ret

ParseExpr:
    push qword [rel TokPtr]
    push qword [rel Here]
    call ParseOr
    IfTok "if", .Maybe
.Done:
    add rsp, 16
    ret
.Maybe:
    call SameLine
    test eax, eax
    jz .Done
    pop rax
    mov [rel Here], rax
    call Advance
    call ParseOr
    call NeedCondition
    lea rcx, [rel PrimBranch0]
    call EmitJump
    push rax
    Expect "otherwise", ErrChoice
    push qword [rel TokPtr]
    mov rcx, [rsp + 16]
    call Unread
    call Advance
    call ParseOr
    push qword [rel ExprType]
    lea rcx, [rel PrimBranch]
    call EmitJump
    mov rcx, [rsp + 16]
    mov [rsp + 16], rax
    mov rdx, [rel Here]
    mov [rcx], rdx
    mov rcx, [rsp + 8]
    call Unread
    call Advance
    call Advance
    call ParseExpr
    pop rax
    mov rdx, [rel ExprType]
    cmp rax, rdx
    jne .Mismatch
.Join:
    pop rcx
    pop rcx
    mov rdx, [rel Here]
    mov [rcx], rdx
    add rsp, 8
    ret
.Mismatch:
    call Compatible
    test rax, rax
    jz TypeError
    mov [rel ExprType], rax
    jmp .Join

ParseOr:
    call ParseAnd
.Loop:
    IfTok "or", .Or
    IfTok "||", .Hint
    ret
.Or:
    mov rax, [rel ExprType]
    cmp rax, TBool
    je .Logic
    cmp rax, TText
    je .Fallback
    call KindOfType
    cmp rax, KList
    je .Fallback
    cmp rax, KMap
    je .Fallback
.Logic:
    push qword [rel ExprType]
    call Advance
    call ParseAnd
    pop rax
    call CheckLogic
    CompilePrim PrimOr
    SetType TBool
    jmp .Loop
.Fallback:
    push qword [rel ExprType]
    CompilePrim PrimDup
    CompilePrim PrimLength
    lea rcx, [rel PrimBranch0]
    call EmitJump
    push rax
    lea rcx, [rel PrimBranch]
    call EmitJump
    pop rcx
    push rax
    mov rdx, [rel Here]
    mov [rcx], rdx
    CompilePrim PrimDrop
    call Advance
    call ParseAnd
    pop rcx
    mov rdx, [rel Here]
    mov [rcx], rdx
    pop rax
    cmp rax, [rel ExprType]
    jne TypeError
    jmp .Loop
.Hint:
    Fail ErrOrHint

ParseAnd:
    call ParseNot
.Loop:
    IfTok "and", .And
    IfTok "&&", .Hint
    ret
.And:
    push qword [rel ExprType]
    call Advance
    call ParseNot
    pop rax
    call CheckLogic
    CompilePrim PrimAnd
    SetType TBool
    jmp .Loop
.Hint:
    Fail ErrAndHint

ParseNot:
    IfTok "not", .Not
    jmp ParseCompare
.Not:
    call Advance
    call ParseNot
    mov eax, TBool
    call CheckLogic
    CompileNum 0
    CompilePrim PrimEq
    SetType TBool
    ret

ParseCompare:
    call ParseRange
    IfTok "==", .Eq
    IfTok "!=", .Ne
    IfTok "<=", .Le
    IfTok ">=", .Ge
    IfTok "<", .Lt
    IfTok ">", .Gt
    IfTok "in", .In
    IfTok "not", .MaybeNotIn
    ret
.Eq:
    call .Equal
    cmp rax, 2
    je .EqText
    cmp rax, 3
    je .EqDec
    CompilePrim PrimEq
    SetType TBool
    ret
.EqText:
    CompilePrim PrimTextEq
    SetType TBool
    ret
.EqDec:
    CompilePrim PrimDEq
    SetType TBool
    ret
.Ne:
    call .Equal
    cmp rax, 2
    je .NeText
    cmp rax, 3
    je .NeDec
    CompilePrim PrimNotEq
    SetType TBool
    ret
.NeText:
    CompilePrim PrimTextEq
    CompileNum 0
    CompilePrim PrimEq
    SetType TBool
    ret
.NeDec:
    CompilePrim PrimDNotEq
    SetType TBool
    ret
.Equal:
    push qword [rel ExprType]
    call Advance
    call ParseRange
    pop rax
    mov rdx, [rel ExprType]
    cmp rax, rdx
    jne .Mixed
    cmp rax, TText
    je .IsText
    cmp rax, TNum
    je .IsInt
    cmp rax, TBool
    je .IsInt
    cmp rax, TDec
    je .IsDec
    push rax
    call KindOfType
    cmp rax, KEnum
    pop rax
    je .IsInt
    jmp TypeError
.Mixed:
    call NumericPair
.IsDec:
    mov eax, 3
    ret
.IsText:
    mov eax, 2
    ret
.IsInt:
    mov eax, 1
    ret
.Le:
    lea rbx, [rel PrimLessEq]
    lea rsi, [rel PrimDLessEq]
    jmp .Order
.Ge:
    lea rbx, [rel PrimGreaterEq]
    lea rsi, [rel PrimDGreaterEq]
    jmp .Order
.Lt:
    lea rbx, [rel PrimLess]
    lea rsi, [rel PrimDLess]
    jmp .Order
.Gt:
    lea rbx, [rel PrimGreater]
    lea rsi, [rel PrimDGreater]
.Order:
    push rbx
    push rsi
    push qword [rel ExprType]
    call Advance
    call ParseRange
    pop rax
    call NumericPair
    pop rsi
    pop rbx
    mov rcx, rbx
    cmp rax, TDec
    jne .OrderEmit
    mov rcx, rsi
.OrderEmit:
    call Compile
    SetType TBool
    ret
.MaybeNotIn:
    call GetInput
    push rax
    push qword [rel TokPtr]
    push qword [rel TokLen]
    call Advance
    IfTok "in", .NotIn
    pop qword [rel TokLen]
    pop qword [rel TokPtr]
    pop rcx
    jmp Unread
.NotIn:
    add rsp, 24
    call .Membership
    CompileNum 0
    CompilePrim PrimEq
    SetType TBool
    ret
.In:
    call .Membership
    SetType TBool
    ret
.Membership:
    push qword [rel ExprType]
    call Advance
    call ParseRange
    pop rbx
    mov rax, [rel ExprType]
    cmp rax, TText
    je .InText
    mov rcx, rax
    call TypeKind
    cmp rax, KList
    je .InList
    cmp rax, KMap
    je .InMap
    jmp TypeError
.InText:
    cmp rbx, TText
    jne TypeError
    CompilePrim PrimTextHas
    ret
.InMap:
    cmp rbx, TText
    jne TypeError
    CompilePrim PrimMapHas
    ret
.InList:
    mov rcx, [rel ExprType]
    call ElemOf
    test rax, rax
    jz .InListAny
    cmp rax, rbx
    jne TypeError
.InListAny:
    cmp rbx, TText
    je .InListText
    CompilePrim PrimListHas
    ret
.InListText:
    CompilePrim PrimListHasText
    ret

ParseRange:
    call ParseBits
    IfTok "..", .Range
    ret
.Range:
    NeedType TNum
    call Advance
    call ParseBits
    NeedType TNum
    CompilePrim PrimRange
    mov ecx, TNum
    call ListOf
    mov [rel ExprType], rax
    ret

ParseBits:
    call ParseShift
.Loop:
    IfTok "&", .And
    IfTok "|", .Or
    IfTok "xor", .Xor
    ret
NumOp .And, ParseShift, PrimBitAnd, TNum
    jmp .Loop
NumOp .Or, ParseShift, PrimBitOr, TNum
    jmp .Loop
NumOp .Xor, ParseShift, PrimBitXor, TNum
    jmp .Loop

ParseShift:
    call ParseSum
.Loop:
    IfTok "<<", .Left
    IfTok ">>", .Right
    ret
NumOp .Left, ParseSum, PrimShiftLeft, TNum
    jmp .Loop
NumOp .Right, ParseSum, PrimShiftRight, TNum
    jmp .Loop

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
    call NumericPair
    lea rcx, [rel PrimAdd]
    cmp rax, TDec
    jne .AddEmit
    lea rcx, [rel PrimDAdd]
.AddEmit:
    mov [rel ExprType], rax
    call Compile
    jmp .Loop
.Text:
    push rax
    mov rax, rdx
    call ToTextRaw
    pop rax
    cmp rax, TText
    je .Join
    push rax
    CompilePrim PrimSwap
    pop rax
    call ToTextRaw
    CompilePrim PrimSwap
.Join:
    CompilePrim PrimConcat
    SetType TText
    jmp .Loop
ArithOp .Sub, ParseProduct, PrimSub, PrimDSub
    jmp .Loop

ParseProduct:
    call ParsePower
.Loop:
    IfTok "*", .Mul
    IfTok "//", .FloorDiv
    IfTok "/", .Div
    IfTok "%", .Mod
    ret
ArithOp .Mul, ParsePower, PrimMul, PrimDMul
    jmp .Loop
NumOp .FloorDiv, ParsePower, PrimFloorDiv, TNum
    jmp .Loop
NumOp .Mod, ParsePower, PrimMod, TNum
    jmp .Loop
.Div:
    push qword [rel ExprType]
    call Advance
    call ParsePower
    pop rax
    call NumericPair
    cmp rax, TDec
    je .DivEmit
    CompilePrim PrimToDec
    CompilePrim PrimToDecUnder
.DivEmit:
    CompilePrim PrimDDiv
    SetType TDec
    jmp .Loop

ParsePower:
    call ParseAtom
    IfTok "^", .Pow
    ret
NumOp .Pow, ParsePower, PrimPow, TNum
    ret

ParseAtom:
    mov qword [rel LastVarRef], 0
    call ParsePrimary
.Post:
    IfTok "[", .Index
    IfTok ".", .Member
    IfTok "(", .MaybeCall
    ret
.MaybeCall:
    mov rax, [rel ExprType]
    call KindOfType
    cmp rax, KFunc
    je .CallValue
    ret
.CallValue:
    call SameLine
    test eax, eax
    jz .NotCall
    mov rcx, [rel ExprType]
    shl rcx, 5
    lea rax, [rel TypeTable]
    add rax, rcx
    push qword [rax + 8]
    push qword [rax + 16]
    push qword [rax + 24]
    push 0
    call Advance
    IfTok ")", .CallArgsDone
.CallArg:
    mov rax, [rsp]
    cmp rax, [rsp + 16]
    jae .CallCount
    mov rcx, [rsp + 8]
    mov rax, [rcx + rax * 8]
    call SetHint
    call ParseExpr
    mov rax, [rsp]
    mov rcx, [rsp + 8]
    mov rax, [rcx + rax * 8]
    call CheckArg
    inc qword [rsp]
    IfTok ",", .CallComma
    Expect ")", ErrParen
.CallArgsDone:
    mov rax, [rsp]
    cmp rax, [rsp + 16]
    jne .CallCount
    call Advance
    CompilePrim PrimCallValue
    mov rcx, [rsp]
    call Compile
    add rsp, 24
    pop rax
    mov qword [rel VoidCall], 0
    test rax, rax
    jnz .CallType
    mov qword [rel VoidCall], 1
    mov eax, TNum
.CallType:
    mov [rel ExprType], rax
    mov qword [rel LastVarRef], 0
    jmp .Post
.CallComma:
    call Advance
    jmp .CallArg
.CallCount:
    Fail ErrArgs
.NotCall:
    ret
.Index:
    mov rax, [rel ExprType]
    cmp rax, TText
    je .TextIndex
    call KindOfType
    cmp rax, KList
    je .ListIndex
    cmp rax, KMap
    je .MapIndex
    jmp TypeError
.TextIndex:
    call Advance
    call ParseExpr
    NeedType TNum
    Expect "]", ErrBracket
    call Advance
    CompilePrim PrimTextAt
    SetType TText
    jmp .IndexDone
.ListIndex:
    push qword [rel ExprType]
    call Advance
    call ParseExpr
    NeedType TNum
    Expect "]", ErrBracket
    call Advance
    CompilePrim PrimIndex
    jmp .ElemType
.MapIndex:
    push qword [rel ExprType]
    call Advance
    call ParseExpr
    NeedType TText
    Expect "]", ErrBracket
    call Advance
    CompilePrim PrimMapGet
.ElemType:
    pop rcx
    call ElemOf
    mov [rel ExprType], rax
.IndexDone:
    mov qword [rel LastVarRef], 0
    jmp .Post
.Member:
    call Advance
    mov rax, [rel ExprType]
    call KindOfType
    cmp rax, KRec
    je .Field
    IfTok "length", .Length
    IfTok "add", .Add
    IfTok "keys", .Keys
    IfTok "filter", .Filter
    IfTok "map", .Map
    Fail ErrMember
.Filter:
    mov ecx, 1
    jmp ListLoop
.Map:
    mov ecx, 2
    jmp ListLoop
.Field:
    mov rcx, [rel ExprType]
    mov rdx, [rel TokPtr]
    mov r8, [rel TokLen]
    call FindField
    cmp rax, -1
    je .NoField
    push rdx
    push rax
    CompilePrim PrimGetField
    pop rcx
    shl rcx, 3
    call Compile
    pop rax
    mov [rel ExprType], rax
    mov qword [rel LastVarRef], 0
    call Advance
    jmp .Post
.NoField:
    FailTok ErrNoField
.Length:
    mov rax, [rel ExprType]
    cmp rax, TText
    je .LengthOk
    call KindOfType
    cmp rax, KList
    je .LengthOk
    cmp rax, KMap
    jne TypeError
.LengthOk:
    CompilePrim PrimLength
    SetType TNum
    mov qword [rel LastVarRef], 0
    call Advance
    jmp .Post
.Keys:
    mov rax, [rel ExprType]
    call KindOfType
    cmp rax, KMap
    jne TypeError
    CompilePrim PrimMapKeys
    mov ecx, TText
    call ListOf
    mov [rel ExprType], rax
    mov qword [rel LastVarRef], 0
    call Advance
    jmp .Post
.Add:
    mov rax, [rel ExprType]
    call KindOfType
    cmp rax, KList
    jne TypeError
    push qword [rel ExprType]
    push qword [rel LastVarRef]
    call Advance
    Expect "(", ErrParen
    call Advance
    call ParseExpr
    Expect ")", ErrParen
    call Advance
    pop rbx
    pop rcx
    call ElemOf
    mov rdx, [rel ExprType]
    test rdx, rdx
    jz TypeError
    test rax, rax
    jz .AddUnknown
    cmp rax, rdx
    jne TypeError
    jmp .AddEmit
.AddUnknown:
    test rbx, rbx
    jz .AddEmit
    mov rcx, rdx
    call ListOf
    mov rdx, rax
    mov rcx, rbx
    call SetTypeOf
.AddEmit:
    CompilePrim PrimListAdd
    SetType TNone
    ret

PeekColon:
    mov rcx, [rel TokPtr]
    add rcx, [rel TokLen]
.Skip:
    movzx eax, byte [rcx]
    cmp eax, ' '
    je .Next
    cmp eax, 9
    je .Next
    cmp eax, ':'
    jne .No
    mov eax, 1
    ret
.Next:
    inc rcx
    jmp .Skip
.No:
    xor eax, eax
    ret

FindParam:
    push rbx
    push rsi
    mov r10, [rcx - 16]
    xor eax, eax
.Loop:
    cmp rax, r10
    jae .None
    mov r11, rax
    shl r11, 4
    neg r11
    cmp r8, [rcx - SigName - 8 + r11]
    jne .Next
    mov rsi, [rcx - SigName + r11]
    xor r9d, r9d
.Compare:
    cmp r9, r8
    je .Found
    mov bl, [rsi + r9]
    cmp bl, [rdx + r9]
    jne .Next
    inc r9
    jmp .Compare
.Next:
    inc rax
    jmp .Loop
.None:
    mov rax, -1
.Found:
    pop rsi
    pop rbx
    ret

ParamTypeOf:
    shl rax, 3
    neg rax
    mov rax, [rdx - 24 + rax]
    ret

CheckArg:
    test rax, rax
    jz .Ok
    mov rdx, [rel ExprType]
    cmp rax, rdx
    je .Ok
    cmp rax, TDec
    jne .Compat
    cmp rdx, TNum
    jne .Bad
    CompilePrim PrimToDec
.Ok:
    ret
.Compat:
    push rax
    call Compatible
    pop rcx
    cmp rax, rcx
    je .Ok
.Bad:
    Fail ErrArgType

FuncTypeOfSig:
    sub rsp, 136
    mov rdx, [rcx - 16]
    xor eax, eax
.Copy:
    cmp rax, rdx
    jae .Done
    mov r8, rax
    shl r8, 3
    neg r8
    mov r8, [rcx - 24 + r8]
    mov [rsp + rax * 8], r8
    inc rax
    jmp .Copy
.Done:
    mov rcx, [rcx - 8]
    mov r8, rsp
    call FuncOf
    add rsp, 136
    ret

SetHint:
    mov qword [rel HintCount], 0
    test rax, rax
    jz .Done
    push rax
    mov rcx, rax
    call TypeKind
    pop rcx
    cmp rax, KFunc
    jne .Done
    shl rcx, 5
    lea rax, [rel TypeTable]
    mov rdx, [rax + rcx + 16]
    mov [rel HintCount], rdx
    mov rdx, [rax + rcx + 24]
    mov [rel HintPtr], rdx
.Done:
    ret

PeekArrow:
    mov rcx, [rel TokPtr]
    add rcx, [rel TokLen]
.Skip:
    movzx eax, byte [rcx]
    cmp eax, ' '
    je .Next
    cmp eax, 9
    je .Next
    cmp eax, '='
    jne .No
    cmp byte [rcx + 1], '>'
    jne .No
    mov eax, 1
    ret
.Next:
    inc rcx
    jmp .Skip
.No:
    xor eax, eax
    ret

ParenArrow:
    call GetInput
    mov rcx, [rel TokPtr]
    inc rcx
    mov r8d, 1
.Scan:
    cmp rcx, rdx
    jae .No
    movzx eax, byte [rcx]
    inc rcx
    cmp eax, '('
    je .Open
    cmp eax, ')'
    je .Close
    cmp eax, '"'
    je .No
    cmp eax, 10
    je .No
    jmp .Scan
.Open:
    inc r8
    jmp .Scan
.Close:
    dec r8
    jnz .Scan
.Skip:
    cmp rcx, rdx
    jae .No
    movzx eax, byte [rcx]
    cmp eax, ' '
    je .SkipNext
    cmp eax, 9
    je .SkipNext
    cmp eax, '='
    jne .No
    cmp byte [rcx + 1], '>'
    jne .No
    mov eax, 1
    ret
.SkipNext:
    inc rcx
    jmp .Skip
.No:
    xor eax, eax
    ret

OuterLocal:
    mov r8, [rel OuterFrame]
    test r8, r8
    jz .No
    cmp qword [r8 + 2056], 0
    je .No
    mov r9, [r8 + 2048]
    mov rdx, [rel TokLen]
    mov r11, [rel TokPtr]
.Loop:
    test r9, r9
    jz .No
    dec r9
    cmp rdx, [r8 + 512 + r9 * 8]
    jne .Loop
    mov r10, [r8 + r9 * 8]
    xor ecx, ecx
.Cmp:
    cmp rcx, rdx
    je .Yes
    mov al, [r10 + rcx]
    cmp al, [r11 + rcx]
    jne .Loop
    inc rcx
    jmp .Cmp
.Yes:
    mov eax, 1
    ret
.No:
    xor eax, eax
    ret

ParseLambda:
    push rsi
    push rdi
    push rbx
    sub rsp, 2048 + 96
    lea rsi, [rel LocalPtr]
    lea rdi, [rsp]
    mov ecx, MaxLocals
    rep movsq
    lea rsi, [rel LocalLen]
    mov ecx, MaxLocals
    rep movsq
    lea rsi, [rel LocalType]
    mov ecx, MaxLocals
    rep movsq
    lea rsi, [rel LocalConst]
    mov ecx, MaxLocals
    rep movsq
    mov rax, [rel LocalCount]
    mov [rsp + 2048], rax
    mov rax, [rel InFn]
    mov [rsp + 2056], rax
    mov rax, [rel FnSig]
    mov [rsp + 2064], rax
    mov rax, [rel FnFrameSlot]
    mov [rsp + 2072], rax
    mov rax, [rel CurHintCount]
    mov [rsp + 2080], rax
    mov rax, [rel CurHintPtr]
    mov [rsp + 2088], rax
    mov qword [rel HintCount], 0
    mov qword [rel CurHintCount], 0
    mov rax, [rel OuterFrame]
    mov [rsp + 2096], rax
    mov [rel OuterFrame], rsp
    cmp qword [rel InFn], 0
    jne .Inline
    mov rax, [rel Here]
    mov [rsp + 2040 + 96], rax
    mov qword [rsp + 2032 + 96], 0
    mov rax, [rel DictHere]
    mov [rel Here], rax
    jmp .Placed
.Inline:
    lea rcx, [rel PrimBranch]
    call EmitJump
    mov [rsp + 2032 + 96], rax
.Placed:
    mov ebx, SigCells
.Sig:
    xor ecx, ecx
    call Compile
    dec ebx
    jnz .Sig
    mov rax, [rel Here]
    mov [rel FnSig], rax
    mov qword [rel InFn], 1
    mov qword [rel LocalCount], 0
    mov qword [rel LaterCount], 0
    CompilePrim PrimEnter
    mov rax, [rel Here]
    mov [rel FnFrameSlot], rax
    xor ecx, ecx
    call Compile
    IfTok "(", .Many
    call .Param
    call Advance
    jmp .Arrow
.Many:
    call Advance
    IfTok ")", .ManyDone
.ManyLoop:
    call .Param
    call Advance
    IfTok ":", .Typed
    jmp .ManyNext
.Typed:
    call Advance
    call ParseTypeName
    mov rbx, [rel LocalCount]
    dec rbx
    call .SetParam
    call Advance
.ManyNext:
    IfTok ",", .ManyComma
    Expect ")", ErrParen
.ManyDone:
    call Advance
    jmp .Arrow
.ManyComma:
    call Advance
    jmp .ManyLoop
.Arrow:
    Expect "=>", ErrArrow
    mov rax, [rel LocalCount]
    mov r8, [rel FnSig]
    mov [r8 - 16], rax
    mov rbx, rax
.Prologue:
    test rbx, rbx
    jz .Body
    dec rbx
    CompilePrim PrimLocalSet
    mov rcx, rbx
    shl rcx, 3
    call Compile
    jmp .Prologue
.Body:
    call Advance
    call ParseExpr
    mov rax, [rel ExprType]
    test rax, rax
    jz TypeError
    mov r8, [rel FnSig]
    mov [r8 - 8], rax
    CompilePrim PrimReturn
    mov rax, [rel FnFrameSlot]
    mov rcx, [rel LocalCount]
    mov [rax], rcx
    mov rax, [rsp + 2032 + 96]
    test rax, rax
    jz .FromDict
    mov rdx, [rel Here]
    mov [rax], rdx
    jmp .Restore
.FromDict:
    mov rax, [rel Here]
    mov [rel DictHere], rax
    mov rax, [rsp + 2040 + 96]
    mov [rel Here], rax
.Restore:
    mov rbx, [rel FnSig]
    lea rsi, [rsp]
    lea rdi, [rel LocalPtr]
    mov ecx, MaxLocals
    rep movsq
    lea rdi, [rel LocalLen]
    mov ecx, MaxLocals
    rep movsq
    lea rdi, [rel LocalType]
    mov ecx, MaxLocals
    rep movsq
    lea rdi, [rel LocalConst]
    mov ecx, MaxLocals
    rep movsq
    mov rax, [rsp + 2048]
    mov [rel LocalCount], rax
    mov rax, [rsp + 2056]
    mov [rel InFn], rax
    mov rax, [rsp + 2064]
    mov [rel FnSig], rax
    mov rax, [rsp + 2072]
    mov [rel FnFrameSlot], rax
    mov rax, [rsp + 2096]
    mov [rel OuterFrame], rax
    add rsp, 2048 + 96
    push rbx
    CompilePrim PrimLit
    mov rcx, [rsp]
    call Compile
    pop rcx
    call FuncTypeOfSig
    mov [rel ExprType], rax
    pop rbx
    pop rdi
    pop rsi
    ret
.Param:
    call IsNameStart
    test eax, eax
    jz .BadParam
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call AddLocal
    mov rbx, [rel LocalCount]
    dec rbx
    cmp rbx, 16
    jae .TooMany
    mov eax, TNum
    cmp rbx, [rsp + 8 + 2080]
    jae .SetParam
    mov rax, [rsp + 8 + 2088]
    mov rax, [rax + rbx * 8]
    test rax, rax
    jnz .SetParam
    mov eax, TNum
.SetParam:
    lea r8, [rel LocalType]
    mov [r8 + rbx * 8], rax
    mov r8, [rel FnSig]
    mov r9, rbx
    shl r9, 3
    neg r9
    mov [r8 - 24 + r9], rax
    ret
.BadParam:
    Fail ErrParen
.TooMany:
    Fail ErrTooMany

ListLoop:
    sub rsp, 64
    mov [rsp + 56], rcx
    mov rax, [rel ExprType]
    mov [rsp + 48], rax
    call KindOfType
    cmp rax, KList
    jne TypeError
    mov rcx, [rsp + 48]
    call ElemOf
    test rax, rax
    jz TypeError
    mov [rsp + 40], rax
    mov [rel HintOne], rax
    call NewHidden
    mov [rsp], rax
    mov rcx, rax
    call EmitStore
    call Advance
    Expect "(", ErrParen
    call Advance
    mov qword [rel HintCount], 1
    lea rax, [rel HintOne]
    mov [rel HintPtr], rax
    call ParseExpr
    mov rax, [rel ExprType]
    call KindOfType
    cmp rax, KFunc
    jne .NotFunc
    mov rcx, [rel ExprType]
    shl rcx, 5
    lea rax, [rel TypeTable]
    add rax, rcx
    cmp qword [rax + 16], 1
    jne .BadFunc
    mov rdx, [rax + 24]
    mov rdx, [rdx]
    cmp rdx, [rsp + 40]
    jne .BadFunc
    mov rdx, [rax + 8]
    mov [rsp + 32], rdx
    test rdx, rdx
    jz .BadFunc
    cmp qword [rsp + 56], 1
    jne .FuncOk
    cmp rdx, TBool
    jne .BadFunc
.FuncOk:
    Expect ")", ErrParen
    call NewHidden
    mov [rsp + 8], rax
    mov rcx, rax
    call EmitStore
    CompileNum 0
    CompilePrim PrimMakeList
    call NewHidden
    mov [rsp + 16], rax
    mov rcx, rax
    call EmitStore
    CompileNum 1
    call NewHidden
    mov [rsp + 24], rax
    mov rcx, rax
    call EmitStore
    mov rax, [rsp]
    mov [rel ItemList], rax
    mov rax, [rsp + 24]
    mov [rel ItemIndex], rax
    mov rbx, [rel Here]
    mov rcx, [rsp + 24]
    call EmitLoad
    mov rcx, [rsp]
    call EmitLoad
    CompilePrim PrimLength
    CompilePrim PrimLessEq
    lea rcx, [rel PrimBranch0]
    call EmitJump
    push rax
    push rbx
    cmp qword [rsp + 16 + 56], 1
    jne .MapBody
    mov rcx, [rsp + 16 + 8]
    call EmitLoad
    call .Item
    CompilePrim PrimCallValue
    mov ecx, 1
    call Compile
    lea rcx, [rel PrimBranch0]
    call EmitJump
    push rax
    mov rcx, [rsp + 24 + 16]
    call EmitLoad
    call .Item
    CompilePrim PrimListAdd
    pop rcx
    mov rdx, [rel Here]
    mov [rcx], rdx
    jmp .Step
.MapBody:
    mov rcx, [rsp + 16 + 16]
    call EmitLoad
    mov rcx, [rsp + 16 + 8]
    call EmitLoad
    call .Item
    CompilePrim PrimCallValue
    mov ecx, 1
    call Compile
    CompilePrim PrimListAdd
.Step:
    mov rcx, [rsp + 16 + 24]
    call EmitLoad
    CompileNum 1
    CompilePrim PrimAdd
    mov rcx, [rsp + 16 + 24]
    call EmitStore
    CompilePrim PrimBranch
    pop rcx
    call Compile
    pop rcx
    mov rdx, [rel Here]
    mov [rcx], rdx
    mov rcx, [rsp + 16]
    call EmitLoad
    call Advance
    cmp qword [rsp + 56], 1
    jne .MapType
    mov rax, [rsp + 48]
    jmp .Typed
.MapType:
    mov rcx, [rsp + 32]
    call ListOf
.Typed:
    mov [rel ExprType], rax
    mov qword [rel LastVarRef], 0
    add rsp, 64
    jmp ParseAtom.Post
.Item:
    mov rcx, [rel ItemList]
    call EmitLoad
    mov rcx, [rel ItemIndex]
    call EmitLoad
    CompilePrim PrimIndex
    ret
.NotFunc:
    Fail ErrNotFunc
.BadFunc:
    Fail ErrBadFunc

ParseArg:
    call Advance
    Expect "(", ErrParen
    call Advance
    call ParseExpr
    Expect ")", ErrParen
    ret

ParsePrimary:
    mov rax, [rel HintCount]
    mov [rel CurHintCount], rax
    mov rax, [rel HintPtr]
    mov [rel CurHintPtr], rax
    mov qword [rel HintCount], 0
    cmp qword [rel TokLen], 0
    je .Missing
    IfTok "(", .Paren
    IfTok "[", .List
    IfTok "{", .Brace
    IfTok "-", .Neg
    IfTok "true", .True
    IfTok "false", .False
    IfTok "error", .LastError
    IfTok "ask", .Ask
    IfTok "random", .Random
    IfTok "number", .ToNumber
    IfTok "decimal", .ToDecimal
    IfTok "round", .Round
    IfTok "text", .ToText
    IfTok "charCode", .Code
    IfTok "charFrom", .Char
    mov rax, [rel TokPtr]
    cmp byte [rax], '"'
    je .String
    mov cl, [rax]
    cmp cl, '0'
    jb .NotNumber
    cmp cl, '9'
    ja .NotNumber
    mov rcx, rax
    mov rdx, [rel TokLen]
    xor r8d, r8d
.FindDot:
    cmp r8, rdx
    jae .Integer
    cmp byte [rcx + r8], '.'
    je .Decimal
    inc r8
    jmp .FindDot
.Decimal:
    call ParseDecimalText
    mov rbx, rax
    CompileNum rbx
    SetType TDec
    jmp Advance
.Integer:
    call ParseNumber
    test rdx, rdx
    jz .Missing
    mov rbx, rax
    CompileNum rbx
    SetType TNum
    jmp Advance
.NotNumber:
    jmp .Name
.LastError:
    CompilePrim PrimLastError
    SetType TText
    jmp Advance
.True:
    CompileNum 1
    SetType TBool
    jmp Advance
.False:
    CompileNum 0
    SetType TBool
    jmp Advance
.Name:
    call PeekArrow
    test eax, eax
    jnz ParseLambda
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call LookupVar
    test rax, rax
    jnz .Var
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call FindWord
    test rax, rax
    jz .Unknown
    cmp rdx, 4
    je .Func
    cmp rdx, 6
    je .Kind
    jmp .Missing
.Kind:
    push rax
    call Advance
    IfTok ".", .KindValue
    mov rcx, [rsp]
    call FieldCount
    push rax
    xor ebx, ebx
.KindAll:
    cmp rbx, [rsp]
    jae .KindAllDone
    inc rbx
    CompileNum rbx
    jmp .KindAll
.KindAllDone:
    pop rbx
    CompileNum rbx
    CompilePrim PrimMakeList
    pop rcx
    call ListOf
    mov [rel ExprType], rax
    ret
.KindValue:
    call Advance
    mov rcx, [rsp]
    call FindKindName
    test rax, rax
    jz .NoKindValue
    push rax
    CompilePrim PrimLit
    pop rcx
    call Compile
    pop rax
    mov [rel ExprType], rax
    jmp Advance
.NoKindValue:
    FailTok ErrNoKindValue
.Var:
    mov rbx, rax
    mov rcx, rbx
    call EmitLoad
    mov rcx, rbx
    call TypeOf
    mov [rel ExprType], rax
    mov [rel LastVarRef], rbx
    jmp Advance
.Func:
    push rax
    call Advance
    IfTok "(", .FuncCall
    CompilePrim PrimLit
    mov rcx, [rsp]
    call Compile
    pop rcx
    call FuncTypeOfSig
    mov [rel ExprType], rax
    ret
.FuncCall:
    pop rax
    sub rsp, 704
    mov [rsp + 640], rax
    mov qword [rsp + 648], 0
    mov qword [rsp + 656], 0
    xor ecx, ecx
.ClearPos:
    mov qword [rsp + rcx * 8], 0
    inc ecx
    cmp ecx, 16
    jb .ClearPos
    call Advance
    mov rax, [rel Here]
    mov [rsp + 664], rax
    IfTok ")", .P1Done
.P1Loop:
    call IsNameStart
    test eax, eax
    jz .Positional
    call PeekColon
    test eax, eax
    jz .Positional
    mov rcx, [rsp + 640]
    mov rdx, [rel TokPtr]
    mov r8, [rel TokLen]
    call FindParam
    cmp rax, -1
    je .NoParam
    cmp qword [rsp + rax * 8], 0
    jne .Twice
    push rax
    call Advance
    call Advance
    pop rax
    mov rcx, [rel TokPtr]
    mov [rsp + rax * 8], rcx
    mov rdx, [rsp + 640]
    call ParamTypeOf
    call SetHint
    jmp .P1Parse
.Positional:
    mov rax, [rsp + 648]
    mov rdx, [rsp + 640]
    mov rcx, [rdx - 16]
    test qword [rdx - SigFlags], 1
    jz .Plain
    dec rcx
    cmp rax, rcx
    jb .Plain
    mov rax, [rsp + 656]
    cmp rax, 64
    jae .ArgCount
    mov rcx, [rel TokPtr]
    mov [rsp + 128 + rax * 8], rcx
    inc qword [rsp + 656]
    mov rax, [rsp + 648]
    mov rdx, [rsp + 640]
    call ParamTypeOf
    mov rcx, rax
    call ElemOf
    call SetHint
    jmp .P1Parse
.Plain:
    cmp rax, rcx
    jae .ArgCount
    cmp qword [rsp + rax * 8], 0
    jne .Twice
    mov rcx, [rel TokPtr]
    mov [rsp + rax * 8], rcx
    inc qword [rsp + 648]
    mov rdx, [rsp + 640]
    call ParamTypeOf
    call SetHint
.P1Parse:
    call ParseExpr
    IfTok ",", .P1Comma
    Expect ")", ErrParen
.P1Done:
    mov rax, [rel TokPtr]
    mov [rsp + 672], rax
    mov rax, [rsp + 664]
    mov [rel Here], rax
    mov qword [rsp + 680], 0
.P2Loop:
    mov rax, [rsp + 680]
    mov rdx, [rsp + 640]
    cmp rax, [rdx - 16]
    jae .P2Done
    mov rcx, [rsp + rax * 8]
    test rcx, rcx
    jnz .P2Given
    mov rcx, [rdx - 16]
    dec rcx
    cmp rax, rcx
    jne .P2Default
    test qword [rdx - SigFlags], 1
    jnz .P2Rest
.P2Default:
    mov r8, rax
    shl r8, 3
    neg r8
    mov rcx, [rdx - SigDef + r8]
    test rcx, rcx
    jz .MissingArg
    push rcx
    CompilePrim PrimCall
    pop rcx
    call Compile
    jmp .P2Next
.P2Given:
    push rcx
    call ParamTypeOf
    call SetHint
    pop rcx
    call Unread
    call Advance
    call ParseExpr
    mov rax, [rsp + 680]
    mov rdx, [rsp + 640]
    call ParamTypeOf
    call CheckArg
    jmp .P2Next
.P2Rest:
    mov qword [rsp + 688], 0
.RestLoop:
    mov rax, [rsp + 688]
    cmp rax, [rsp + 656]
    jae .RestDone
    mov rax, [rsp + 680]
    mov rdx, [rsp + 640]
    call ParamTypeOf
    mov rcx, rax
    call ElemOf
    call SetHint
    mov rax, [rsp + 688]
    mov rcx, [rsp + 128 + rax * 8]
    call Unread
    call Advance
    call ParseExpr
    mov rax, [rsp + 680]
    mov rdx, [rsp + 640]
    call ParamTypeOf
    mov rcx, rax
    call ElemOf
    call CheckArg
    inc qword [rsp + 688]
    jmp .RestLoop
.RestDone:
    CompileNum [rsp + 656]
    CompilePrim PrimMakeList
.P2Next:
    inc qword [rsp + 680]
    jmp .P2Loop
.P2Done:
    mov rcx, [rsp + 672]
    call Unread
    call Advance
    call Advance
    CompilePrim PrimCall
    mov rcx, [rsp + 640]
    call Compile
    mov rcx, [rsp + 640]
    add rsp, 704
    mov rax, [rcx - 8]
    mov qword [rel VoidCall], 0
    test rax, rax
    jnz .FuncType
    mov qword [rel VoidCall], 1
    mov eax, TNum
.FuncType:
    mov [rel ExprType], rax
    ret
.P1Comma:
    call Advance
    jmp .P1Loop
.ArgCount:
    Fail ErrArgs
.Twice:
    FailTok ErrArgTwice
.NoParam:
    FailTok ErrNoParam
.MissingArg:
    mov rcx, rax
    shl rcx, 4
    neg rcx
    mov r8, [rdx - SigName + rcx]
    mov r9, [rdx - SigName - 8 + rcx]
    mov rax, [rsp + 672]
    mov [rel ErrPos], rax
    mov [rel ErrTokPtr], r8
    mov [rel ErrTokLen], r9
    lea rcx, [rel ErrMissingArg]
    mov edx, ErrMissingArgLen
    jmp Abort
.Paren:
    call ParenArrow
    test eax, eax
    jnz ParseLambda
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
.ListFinish:
    call Advance
    pop rbx
    pop rsi
    CompileNum rsi
    CompilePrim PrimMakeList
    mov rcx, rbx
    call ListOf
    mov [rel ExprType], rax
    ret
.ListComma:
    call Advance
    IfTok "]", .ListFinish
    jmp .ListLoop
.EmptyList:
    CompileNum 0
    CompilePrim PrimMakeList
    xor ecx, ecx
    call ListOf
    mov [rel ExprType], rax
    jmp Advance
.Brace:
    call Advance
    IfTok "}", .EmptyMap
    mov rax, [rel TokPtr]
    cmp byte [rax], '"'
    je .MapLiteral
    jmp RecordLiteral
.EmptyMap:
    CompileNum 0
    CompilePrim PrimMakeMap
    xor ecx, ecx
    call MapOf
    mov [rel ExprType], rax
    jmp Advance
.MapLiteral:
    push 0
    push 0
.MapLoop:
    call ParseExpr
    NeedType TText
    Expect ":", ErrMapColon
    call Advance
    call ParseExpr
    mov rax, [rel ExprType]
    test rax, rax
    jz TypeError
    mov rdx, [rsp]
    test rdx, rdx
    jz .MapFirst
    cmp rax, rdx
    jne TypeError
    jmp .MapOk
.MapFirst:
    mov [rsp], rax
.MapOk:
    inc qword [rsp + 8]
    IfTok ",", .MapComma
    Expect "}", ErrBraceClose
.MapFinish:
    call Advance
    pop rbx
    pop rsi
    CompileNum rsi
    CompilePrim PrimMakeMap
    mov rcx, rbx
    call MapOf
    mov [rel ExprType], rax
    ret
.MapComma:
    call Advance
    IfTok "}", .MapFinish
    jmp .MapLoop
.Neg:
    call Advance
    CompileNum 0
    call ParsePower
    mov rax, [rel ExprType]
    cmp rax, TDec
    je .NegDec
    NeedType TNum
    CompilePrim PrimSub
    ret
.NegDec:
    CompilePrim PrimDSub
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
    call LookupVar
    test rax, rax
    jnz .AskPrompt
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call FindWord
    test rax, rax
    jz .AskNoPrompt
    cmp rdx, 4
    je .AskPrompt
.AskNoPrompt:
    CompileNum 0
    jmp .AskCompile
.AskPrompt:
    call ParseSum
    mov rax, [rel ExprType]
    call ToTextRaw
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
    call ParseArg
    mov rax, [rel ExprType]
    cmp rax, TNum
    je .ToNumberDone
    cmp rax, TDec
    je .ToNumberDec
    NeedType TText
    CompilePrim PrimToNumber
    jmp .ToNumberDone
.ToNumberDec:
    CompilePrim PrimDecToNum
.ToNumberDone:
    SetType TNum
    jmp Advance
.ToDecimal:
    call ParseArg
    mov rax, [rel ExprType]
    cmp rax, TDec
    je .ToDecimalDone
    cmp rax, TNum
    je .ToDecimalNum
    NeedType TText
    CompilePrim PrimTextToDec
    jmp .ToDecimalDone
.ToDecimalNum:
    CompilePrim PrimToDec
.ToDecimalDone:
    SetType TDec
    jmp Advance
.Round:
    call ParseArg
    cmp qword [rel ExprType], TNum
    je .RoundDone
    NeedType TDec
    CompilePrim PrimRound
.RoundDone:
    SetType TNum
    jmp Advance
.ToText:
    call ParseArg
    mov rax, [rel ExprType]
    call ToTextRaw
    SetType TText
    jmp Advance
.Code:
    call ParseArg
    NeedType TText
    CompilePrim PrimCode
    SetType TNum
    jmp Advance
.Char:
    call ParseArg
    NeedType TNum
    CompilePrim PrimChar
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
    call OuterLocal
    test eax, eax
    jnz .Captured
    push qword [rel TokPtr]
    push qword [rel TokLen]
    call Advance
    IfTok "=", .WantSet
    IfTok "+=", .WantSet
    IfTok "-=", .WantSet
    IfTok ",", .WantSet
    pop qword [rel TokLen]
    pop qword [rel TokPtr]
    FailTok ErrName
.WantSet:
    pop qword [rel TokLen]
    pop qword [rel TokPtr]
    FailTok ErrNotExist
.Captured:
    FailTok ErrCapture

RecordLiteral:
    push qword [rel TempTop]
    push 0
.Loop:
    call IsNameStart
    test eax, eax
    jz .Bad
    mov rax, [rsp]
    lea rax, [rax + rax * 2]
    mov rcx, [rsp + 8]
    lea r8, [rcx + rax * 8]
    mov rax, [rel TokPtr]
    mov [r8], rax
    mov rax, [rel TokLen]
    mov [r8 + 8], rax
    push r8
    inc qword [rsp + 8]
    mov rax, [rsp + 8]
    lea rax, [rax + rax * 2]
    shl rax, 3
    add rax, [rsp + 16]
    mov [rel TempTop], rax
    call Advance
    Expect ":", ErrRecordColon
    call Advance
    call ParseExpr
    pop r8
    mov rax, [rel ExprType]
    test rax, rax
    jz TypeError
    mov [r8 + 16], rax
    IfTok ",", .Comma
    Expect "}", ErrBraceClose
.Finish:
    call Advance
    mov rcx, [rsp]
    mov rdx, [rsp + 8]
    call InternRecord
    mov rbx, rax
    CompilePrim PrimMakeRecord
    mov rcx, [rsp]
    call Compile
    xor esi, esi
.Slots:
    cmp rsi, [rsp]
    jae .Done
    lea rax, [rsi + rsi * 2]
    mov rdi, [rsp + 8]
    lea rdi, [rdi + rax * 8]
    mov rcx, rbx
    mov rdx, [rdi]
    mov r8, [rdi + 8]
    call FindField
    mov rcx, rax
    call Compile
    inc rsi
    jmp .Slots
.Done:
    mov [rel ExprType], rbx
    pop rax
    pop rax
    mov [rel TempTop], rax
    ret
.Comma:
    call Advance
    IfTok "}", .Finish
    jmp .Loop
.Bad:
    Fail ErrRecordName

EmitTextLiteral:
    call MakeText
    push rax
    CompilePrim PrimLit
    pop rcx
    jmp Compile

FindSpecColon:
    xor r9d, r9d
    xor r10d, r10d
    mov rax, rcx
.Loop:
    cmp rax, rdx
    jae .None
    mov r8b, [rax]
    cmp r8b, '"'
    jne .NotQuote
    xor r10d, 1
    jmp .Next
.NotQuote:
    test r10d, r10d
    jnz .Next
    cmp r8b, '('
    je .Open
    cmp r8b, '['
    je .Open
    cmp r8b, '{'
    je .Open
    cmp r8b, ')'
    je .Close
    cmp r8b, ']'
    je .Close
    cmp r8b, '}'
    je .Close
    cmp r8b, ':'
    jne .Next
    test r9, r9
    jz .Found
    jmp .Next
.Open:
    inc r9
    jmp .Next
.Close:
    dec r9
.Next:
    inc rax
    jmp .Loop
.None:
    mov rax, rdx
.Found:
    ret

%macro WordIs 2
[section .data]
%%Str: db %1
%%End:
__SECT__
    cmp r11, %%End - %%Str
    jne %%No
    push rcx
    push rdx
    push r8
    lea rcx, [rel %%Str]
    mov rdx, r10
    mov r8, r11
    call SameWord
    pop r8
    pop rdx
    pop rcx
    test r9d, r9d
    jnz %2
%%No:
%endmacro

SameWord:
    test r8, r8
    jz .Yes
    movzx r9d, byte [rdx]
    or r9d, 32
    cmp r9b, [rcx]
    jne .No
    inc rcx
    inc rdx
    dec r8
    jmp SameWord
.Yes:
    mov r9d, 1
    ret
.No:
    xor r9d, r9d
    ret

SpecError:
    mov rax, [rel SpecStart]
    mov [rel ErrPos], rax
    mov [rel ErrTokPtr], rax
    mov rax, [rel SpecEnd]
    sub rax, [rel SpecStart]
    mov [rel ErrTokLen], rax
    lea rcx, [rel ErrBadSpec]
    mov edx, ErrBadSpecLen
    jmp Abort

ParseSpec:
.TrimStart:
    cmp rcx, rdx
    jae .Trimmed
    cmp byte [rcx], ' '
    jne .TrimEnd
    inc rcx
    jmp .TrimStart
.TrimEnd:
    cmp byte [rdx - 1], ' '
    jne .Trimmed
    dec rdx
    jmp .TrimEnd
.Trimmed:
    mov [rel SpecStart], rcx
    mov [rel SpecEnd], rdx
    mov r8, rcx
.Scan:
    cmp r8, rdx
    jae ShortSpec
    movzx eax, byte [r8]
    or eax, 32
    cmp eax, 'a'
    jb .Next
    cmp eax, 'z'
    ja .Next
    lea r9, [r8 + 1]
    cmp r9, rdx
    jne WordSpec
    cmp r8, rcx
    je WordSpec
.Next:
    inc r8
    jmp .Scan

WordSpec:
    mov eax, 0xFF << 16
.Part:
    cmp rcx, rdx
    jae .Done
    movzx r9d, byte [rcx]
    cmp r9d, ' '
    je .Skip
    cmp r9d, ','
    je .Skip
    sub r9d, '0'
    cmp r9d, 9
    jbe .Count
    call .ReadWord
    WordIs "commas", .Commas
    WordIs "comma", .Commas
    WordIs "sign", .Sign
    WordIs "and", .Part
    WordIs "left", .Left
    WordIs "right", .Right
    jmp SpecError
.Skip:
    inc rcx
    jmp .Part
.Commas:
    or eax, 1 << 28
    jmp .Part
.Sign:
    or eax, 1 << 26
    jmp .Part
.Left:
    or eax, 1 << 24
    jmp .Width
.Right:
    or eax, 2 << 24
.Width:
    call .ReadNumber
    and eax, ~0xFFFF
    or eax, r8d
    jmp .Part
.Count:
    call .ReadNumber
    call .ReadWord
    WordIs "places", .Places
    WordIs "place", .Places
    WordIs "decimals", .Places
    WordIs "digits", .Digits
    WordIs "digit", .Digits
    WordIs "wide", .Wide
    jmp SpecError
.Places:
    cmp r8d, 15
    jbe .PlacesOk
    mov r8d, 15
.PlacesOk:
    and eax, ~(0xFF << 16)
    shl r8d, 16
    or eax, r8d
    jmp .Part
.Digits:
    or eax, 1 << 27
.Wide:
    and eax, ~0xFFFF
    or eax, r8d
    jmp .Part
.Done:
    ret

.ReadWord:
.WordSpaces:
    cmp rcx, rdx
    jae .WordStart
    cmp byte [rcx], ' '
    jne .WordStart
    inc rcx
    jmp .WordSpaces
.WordStart:
    mov r10, rcx
.WordLoop:
    cmp rcx, rdx
    jae .WordEnd
    movzx r9d, byte [rcx]
    or r9d, 32
    cmp r9d, 'a'
    jb .WordEnd
    cmp r9d, 'z'
    ja .WordEnd
    inc rcx
    jmp .WordLoop
.WordEnd:
    mov r11, rcx
    sub r11, r10
    ret

.ReadNumber:
.NumSpaces:
    cmp rcx, rdx
    jae .NumStart
    cmp byte [rcx], ' '
    jne .NumStart
    inc rcx
    jmp .NumSpaces
.NumStart:
    xor r8d, r8d
    mov r9, rcx
.NumLoop:
    cmp rcx, rdx
    jae .NumEnd
    movzx r10d, byte [rcx]
    sub r10d, '0'
    cmp r10d, 9
    ja .NumEnd
    imul r8d, r8d, 10
    add r8d, r10d
    inc rcx
    jmp .NumLoop
.NumEnd:
    cmp rcx, r9
    je SpecError
    and r8d, 0xFFFF
    ret

ShortSpec:
    mov eax, 0xFF << 16
    cmp rcx, rdx
    jae .Done
    cmp byte [rcx], '<'
    jne .NotLeft
    or eax, 1 << 24
    inc rcx
    jmp .Sign
.NotLeft:
    cmp byte [rcx], '>'
    jne .Sign
    or eax, 2 << 24
    inc rcx
.Sign:
    cmp rcx, rdx
    jae .Done
    cmp byte [rcx], '+'
    jne .Zero
    or eax, 1 << 26
    inc rcx
.Zero:
    cmp rcx, rdx
    jae .Done
    cmp byte [rcx], '0'
    jne .Width
    or eax, 1 << 27
    inc rcx
.Width:
    xor r8d, r8d
.WidthLoop:
    cmp rcx, rdx
    jae .WidthDone
    movzx r9d, byte [rcx]
    sub r9d, '0'
    cmp r9d, 9
    ja .WidthDone
    imul r8d, r8d, 10
    add r8d, r9d
    inc rcx
    jmp .WidthLoop
.WidthDone:
    and r8d, 0xFFFF
    or eax, r8d
    cmp rcx, rdx
    jae .Done
    cmp byte [rcx], ','
    jne .Precision
    or eax, 1 << 28
    inc rcx
.Precision:
    cmp rcx, rdx
    jae .Done
    cmp byte [rcx], '.'
    jne .Letter
    inc rcx
    xor r8d, r8d
.PrecisionLoop:
    cmp rcx, rdx
    jae .PrecisionDone
    movzx r9d, byte [rcx]
    sub r9d, '0'
    cmp r9d, 9
    ja .PrecisionDone
    imul r8d, r8d, 10
    add r8d, r9d
    inc rcx
    jmp .PrecisionLoop
.PrecisionDone:
    cmp r8d, 15
    jbe .PrecisionOk
    mov r8d, 15
.PrecisionOk:
    and eax, ~(0xFF << 16)
    shl r8d, 16
    or eax, r8d
.Letter:
    cmp rcx, rdx
    jae .Done
    movzx r9d, byte [rcx]
    or r9d, 32
    cmp r9d, 'f'
    je .SkipLetter
    cmp r9d, 'd'
    je .SkipLetter
    cmp r9d, 's'
    jne .Done
.SkipLetter:
    inc rcx
.Done:
    cmp rcx, rdx
    jne SpecError
    ret

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
    cmp byte [rsi], 92
    je .Escape
    cmp byte [rsi], '{'
    je .Brace
    inc rsi
    jmp .Find
.Escape:
    add rsi, 2
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
    xor ecx, ecx
.FindClose:
    cmp rsi, rdi
    jae .Bad
    mov al, [rsi]
    cmp al, '"'
    je .InnerString
    cmp al, '{'
    jne .NotOpen
    inc ecx
    jmp .CloseNext
.NotOpen:
    cmp al, '}'
    jne .CloseNext
    test ecx, ecx
    jz .Close
    dec ecx
.CloseNext:
    inc rsi
    jmp .FindClose
.InnerString:
    inc rsi
.InnerLoop:
    cmp rsi, rdi
    jae .Bad
    mov al, [rsi]
    inc rsi
    cmp al, 92
    jne .InnerNotEscape
    inc rsi
    jmp .InnerLoop
.InnerNotEscape:
    cmp al, '"'
    jne .InnerLoop
    jmp .FindClose
.Close:
    mov rcx, rbx
    mov rdx, rsi
    call FindSpecColon
    push rax
    cmp rax, rsi
    je .NoSpec
    lea rcx, [rax + 1]
    mov rdx, rsi
    call ParseSpec
    jmp .HaveSpec
.NoSpec:
    mov rax, -1
.HaveSpec:
    push rax
    push rbx
    push rsi
    push rdi
    push r12
    call GetInput
    push rax
    push rdx
    push qword [rel TokPtr]
    push qword [rel TokLen]
    mov rcx, rbx
    mov rdx, [rsp + 72]
    sub rdx, rbx
    call SetInput
    call Advance
    call ParseExpr
    cmp qword [rel TokLen], 0
    jne .Bad
    mov rax, [rsp + 64]
    cmp rax, -1
    je .Plain
    CompilePrim PrimFormat
    mov rcx, [rsp + 64]
    call Compile
    mov rcx, [rel ExprType]
    call Compile
    jmp .Typed
.Plain:
    mov rax, [rel ExprType]
    call ToTextRaw
.Typed:
    pop qword [rel TokLen]
    pop qword [rel TokPtr]
    pop rdx
    pop rcx
    sub rdx, rcx
    call SetInput
    pop r12
    pop rdi
    pop rsi
    pop rbx
    add rsp, 16
    call .Join
    inc rsi
    jmp .Segment
.Tail:
    cmp rsi, rdi
    jbe .TailOk
    mov rsi, rdi
.TailOk:
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
    push rcx
    mov [rel StmtStart], r12
    mov rax, [rel Here]
    mov [rel StmtHere], rax
    mov [rel PrevTokPtr], r12
    mov [rel TokPtr], r12
    mov [rel TokLen], r13
    mov qword [rel VoidCall], 0
    call ParseExpr
    IfTok ",", .Multi
    IfTok "=", .Assign
    IfTok "+=", .Assign
    IfTok "-=", .Assign
    IfTok "*=", .Assign
    IfTok "/=", .Assign
    pop rcx
    cmp qword [rel ExprType], TNone
    je .Done
    test rcx, rcx
    jz .Drop
    cmp qword [rel FileMode], 0
    jne .Drop
    cmp qword [rel VoidCall], 0
    jne .Drop
    call EmitSay
    jmp .Done
.Drop:
    CompilePrim PrimDrop
.Done:
    jmp Pushback
.Assign:
    pop rcx
    mov rax, [rel StmtHere]
    mov [rel Here], rax
    mov rcx, [rel StmtStart]
    call Unread
    jmp AssignStmt
.Multi:
    pop rcx
    mov rax, [rel StmtHere]
    mov [rel Here], rax
    mov rcx, [rel StmtStart]
    call Unread
    call Advance
    xor ecx, ecx
    jmp MultiAssign

SayWord:
    call Advance
    call ParseExpr
    call EmitSay
    jmp Pushback

ByeWord:
    CompilePrim PrimBye
    ret

AssignStmt:
    call Advance
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call LookupVar
    test rax, rax
    jz .Unknown
    test rdx, rdx
    jnz .Const
    push rax
    call Advance
    jmp AssignTail
.Unknown:
    FailTok ErrNotExist
.Const:
    Fail ErrConst

ResolveLoopVar:
    cmp qword [rel InFn], 0
    jne .Local
    push rcx
    push rdx
    call LookupVar
    pop r8
    pop r9
    test rax, rax
    jz .NewGlobal
    test rdx, rdx
    jnz .Const
    ret
.NewGlobal:
    mov rcx, r9
    mov rdx, r8
    jmp CreateVar
.Local:
    push rcx
    push rdx
    call FindLocal
    pop rdx
    pop rcx
    test rax, rax
    jz AddLocal
    mov r8, rax
    shr r8, 3
    lea r9, [rel LocalConst]
    cmp qword [r9 + r8 * 8], 0
    jne .Const
    ret
.Const:
    Fail ErrConst

KeepWord:
    mov qword [rel MakingConst], 1

SetWord:
    call Advance
    cmp qword [rel TokLen], 0
    je .Bad
    call IsNameStart
    test eax, eax
    jz .BadName
    push qword [rel TokPtr]
    push qword [rel TokLen]
    call Advance
    IfTok ",", .Multi
    IfTok "[", .Existing
    IfTok ".", .Existing
    mov rcx, [rsp + 8]
    mov rdx, [rsp]
    cmp qword [rel InFn], 0
    jne .InFunction
    call LookupVar
    jmp .Resolved
.InFunction:
    call FindLocal
    xor edx, edx
    test rax, rax
    jz .Resolved
    mov r8, rax
    shr r8, 3
    lea r9, [rel LocalConst]
    mov rdx, [r9 + r8 * 8]
.Resolved:
    test rax, rax
    jz .Create
    cmp qword [rel MakingConst], 0
    jne .Exists
    test rdx, rdx
    jnz .Const
    lea rcx, [rel WarnExists]
    mov edx, WarnExistsLen
    mov r8, [rsp + 8]
    mov r9, [rsp]
    call Warn
    jmp .Have
.Create:
    push qword [rel TokPtr]
    push qword [rel TokLen]
    mov rax, [rsp + 24]
    mov [rel TokPtr], rax
    mov rax, [rsp + 16]
    mov [rel TokLen], rax
    call IsReserved
    test eax, eax
    jnz .BadName
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call FindWord
    test rax, rax
    jz .NameOk
    cmp rdx, 3
    je .NameOk
    cmp rdx, 5
    jne .BadName
.NameOk:
    pop qword [rel TokLen]
    pop qword [rel TokPtr]
    mov rcx, [rsp + 8]
    mov rdx, [rsp]
    call NewVar
    cmp qword [rel MakingConst], 0
    je .Have
    call MarkConst
.Have:
    add rsp, 16
    mov qword [rel MakingConst], 0
    push rax
    jmp AssignTail
.Existing:
    mov rcx, [rsp + 8]
    mov rdx, [rsp]
    call LookupVar
    test rax, rax
    jz .Missing
    test rdx, rdx
    jnz .Const
    add rsp, 16
    push rax
    jmp AssignTail
.Missing:
    mov rax, [rsp + 8]
    mov [rel TokPtr], rax
    mov rax, [rsp]
    mov [rel TokLen], rax
    FailTok ErrNotExist
.Multi:
    cmp qword [rel MakingConst], 0
    jne .Bad
    pop rax
    pop rcx
    call Unread
    call Advance
    mov ecx, 1
    jmp MultiAssign
.Bad:
    Fail ErrSet
.BadName:
    FailTok ErrSetName
.Const:
    Fail ErrConst
.Exists:
    Fail ErrKeepExists

AssignTail:
    IfTok "[", .Path
    IfTok ".", .Path
    IfTok ":", .Type
    jmp .Op
.Type:
    call Advance
    call ParseTypeName
    push rax
    mov rcx, [rsp + 8]
    call TypeOf
    pop rdx
    test rax, rax
    jz .Declare
    cmp rax, rdx
    jne TypeError
.Declare:
    mov rcx, [rsp]
    call SetTypeOf
    call Advance
.Op:
    IfTok "=", .Assign
    IfTok "+=", .AddAssign
    IfTok "-=", .SubAssign
    IfTok "*=", .MulAssign
    IfTok "/=", .DivAssign
    IfTok "==", .DoubleEq
    Fail ErrSet
.DoubleEq:
    Fail ErrDoubleEq
.Assign:
    call Advance
    call ParseExpr
    mov rcx, [rsp]
    call TypeOf
    mov rdx, [rel ExprType]
    cmp rax, TDec
    jne .AssignCheck
    cmp rdx, TNum
    jne .AssignCheck
    CompilePrim PrimToDec
    jmp .Store
.AssignCheck:
    push rax
    call Compatible
    pop rcx
    test rax, rax
    jz TypeError
    cmp rax, rcx
    je .Store
    mov rdx, rax
    mov rcx, [rsp]
    call SetTypeOf
    jmp .Store
.AddAssign:
    mov rcx, [rsp]
    call TypeOf
    test rax, rax
    jz .NewCompound
    cmp rax, TText
    je .Append
    lea rbx, [rel PrimAdd]
    lea rsi, [rel PrimDAdd]
    jmp .Compound
.SubAssign:
    lea rbx, [rel PrimSub]
    lea rsi, [rel PrimDSub]
    jmp .Compound
.MulAssign:
    lea rbx, [rel PrimMul]
    lea rsi, [rel PrimDMul]
    jmp .Compound
.DivAssign:
    xor ebx, ebx
    lea rsi, [rel PrimDDiv]
.Compound:
    push rsi
    push rbx
    mov rcx, [rsp + 16]
    call TypeOf
    test rax, rax
    jz .NewCompound
    mov rcx, [rsp + 16]
    call EmitLoad
    mov rcx, [rsp + 16]
    call TypeOf
    push rax
    call Advance
    call ParseExpr
    pop rax
    call NumericPair
    pop rbx
    pop rsi
    test rbx, rbx
    jnz .Pick
    cmp rax, TDec
    je .Pick
    CompilePrim PrimToDec
    CompilePrim PrimToDecUnder
    mov eax, TDec
.Pick:
    mov rcx, rbx
    cmp rax, TDec
    jne .Emit
    mov rcx, rsi
.Emit:
    push rax
    call Compile
    mov rcx, [rsp + 8]
    call TypeOf
    pop rdx
    cmp rax, rdx
    jne TypeError
    jmp .Store
.NewCompound:
    Fail ErrCompoundNew
.Append:
    mov rcx, [rsp]
    call EmitLoad
    call Advance
    call ParseExpr
    mov rax, [rel ExprType]
    call ToTextRaw
    CompilePrim PrimConcat
.Store:
    pop rcx
    call EmitStore
    jmp Pushback
.Path:
    mov rcx, [rsp]
    call EmitLoad
    mov rcx, [rsp]
    call TypeOf
    mov [rel PathType], rax
    mov rax, [rsp]
    mov [rel PathRef], rax
    mov qword [rel PathDepth], 0
.Step:
    IfTok "[", .PathIndex
    IfTok ".", .PathField
    Fail ErrSet
.PathIndex:
    mov qword [rel PathIsField], 0
    mov rax, [rel PathType]
    call KindOfType
    cmp rax, KList
    je .PathList
    cmp rax, KMap
    je .PathMap
    jmp TypeError
.PathList:
    mov qword [rel PathKey], TNum
    lea rax, [rel PrimIndex]
    mov [rel PathGet], rax
    lea rax, [rel PrimSetIndex]
    mov [rel PathSet], rax
    jmp .PathKeyParse
.PathMap:
    mov qword [rel PathKey], TText
    lea rax, [rel PrimMapGet]
    mov [rel PathGet], rax
    lea rax, [rel PrimMapSet]
    mov [rel PathSet], rax
.PathKeyParse:
    call Advance
    call ParseExpr
    mov rax, [rel PathKey]
    cmp [rel ExprType], rax
    jne TypeError
    Expect "]", ErrBracket
    call Advance
    mov rcx, [rel PathType]
    call ElemOf
    mov [rel PathElem], rax
    call PathFinalOp
    test eax, eax
    jnz .PathFinal
    mov rcx, [rel PathGet]
    call Compile
    mov rax, [rel PathElem]
    mov [rel PathType], rax
    inc qword [rel PathDepth]
    jmp .Step
.PathField:
    mov rax, [rel PathType]
    call KindOfType
    cmp rax, KRec
    jne TypeError
    call Advance
    mov rcx, [rel PathType]
    mov rdx, [rel TokPtr]
    mov r8, [rel TokLen]
    call FindField
    cmp rax, -1
    je .NoField
    mov [rel PathElem], rdx
    shl rax, 3
    mov [rel PathOffset], rax
    lea rax, [rel PrimGetField]
    mov [rel PathGet], rax
    lea rax, [rel PrimSetField]
    mov [rel PathSet], rax
    mov qword [rel PathIsField], 1
    call Advance
    call PathFinalOp
    test eax, eax
    jnz .PathFinal
    CompilePrim PrimGetField
    mov rcx, [rel PathOffset]
    call Compile
    mov rax, [rel PathElem]
    mov [rel PathType], rax
    inc qword [rel PathDepth]
    jmp .Step
.NoField:
    FailTok ErrNoField
.PathFinal:
    cmp qword [rel PathOp], 1
    jne .PathCompound
    call Advance
    call ParseExpr
    mov rax, [rel PathElem]
    mov rdx, [rel ExprType]
    test rdx, rdx
    jz TypeError
    test rax, rax
    jz .PathUnknown
    cmp rax, rdx
    je .PathEmit
    cmp rax, TDec
    jne .PathCompat
    cmp rdx, TNum
    jne TypeError
    CompilePrim PrimToDec
    jmp .PathEmit
.PathCompat:
    push rax
    call Compatible
    pop rcx
    cmp rax, rcx
    jne TypeError
    jmp .PathEmit
.PathUnknown:
    cmp qword [rel PathDepth], 0
    jne TypeError
    push rdx
    mov rax, [rel PathType]
    call KindOfType
    pop rcx
    cmp rax, KList
    je .PathNewList
    call MapOf
    jmp .PathSetType
.PathNewList:
    call ListOf
.PathSetType:
    mov rdx, rax
    mov rcx, [rel PathRef]
    call SetTypeOf
.PathEmit:
    mov rcx, [rel PathSet]
    call Compile
    cmp qword [rel PathIsField], 0
    je .PathDone
    mov rcx, [rel PathOffset]
    call Compile
.PathDone:
    pop rax
    jmp Pushback
.PathCompound:
    cmp qword [rel PathIsField], 0
    jne .CompoundField
    CompilePrim PrimDup2
    mov rcx, [rel PathGet]
    call Compile
    jmp .CompoundGot
.CompoundField:
    CompilePrim PrimDup
    CompilePrim PrimGetField
    mov rcx, [rel PathOffset]
    call Compile
.CompoundGot:
    mov rax, [rel PathElem]
    cmp rax, TText
    jne .CompoundNumber
    cmp qword [rel PathOp], 2
    jne TypeError
    call Advance
    call ParseExpr
    mov rax, [rel ExprType]
    call ToTextRaw
    CompilePrim PrimConcat
    jmp .PathEmit
.CompoundNumber:
    push rax
    call Advance
    call ParseExpr
    mov rax, [rsp]
    call NumericPair
    pop rcx
    cmp rax, rcx
    jne TypeError
    lea rcx, [rel PrimAdd]
    lea rdx, [rel PrimDAdd]
    cmp qword [rel PathOp], 2
    je .CompoundPick
    lea rcx, [rel PrimSub]
    lea rdx, [rel PrimDSub]
.CompoundPick:
    cmp rax, TDec
    jne .CompoundEmit
    mov rcx, rdx
.CompoundEmit:
    call Compile
    jmp .PathEmit

PathFinalOp:
    IfTok "=", .Set
    IfTok "+=", .Add
    IfTok "-=", .Sub
    xor eax, eax
    ret
.Set:
    mov qword [rel PathOp], 1
    mov eax, 1
    ret
.Add:
    mov qword [rel PathOp], 2
    mov eax, 1
    ret
.Sub:
    mov qword [rel PathOp], 3
    mov eax, 1
    ret

IfWord:
    call Advance
    call ParseExpr
    call NeedCondition
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
    je .IfOk
    cmp qword [r15 - 8], TagCheck
    je .CheckOtherwise
    cmp qword [r15 - 8], TagTry
    je .TryOtherwise
    cmp qword [r15 - 8], TagDummy
    jne .Bad
.IfOk:
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
    IfTok ":", .Colon
    jmp Pushback
.ElseIf:
    call Advance
    call ParseExpr
    call NeedCondition
    lea rcx, [rel PrimBranch0]
    call EmitJump
    mov [r15 - 32], rax
    jmp Pushback
.TryOtherwise:
    cmp qword [r15 - 32], 0
    jne .Bad
    CompilePrim PrimTryEnd
    lea rcx, [rel PrimBranch]
    call EmitJump
    mov [r15 - 32], rax
    mov rcx, [r15 - 40]
    mov rdx, [rel Here]
    mov [rcx], rdx
    ret
.CheckOtherwise:
    mov rax, [r15 - 32]
    test rax, rax
    jz .Bad
    lea rcx, [rel PrimBranch]
    call EmitJump
    mov rdx, [r15 - 40]
    mov [rax], rdx
    mov [r15 - 40], rax
    mov rcx, [r15 - 32]
    mov rdx, [rel Here]
    mov [rcx], rdx
    mov qword [r15 - 32], 0
    ret
.Colon:
    Fail ErrColon
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
    cmp rax, TagCheck
    je .Check
    cmp rax, TagTry
    je .Try
    cmp rax, TagDummy
    jne .Fn
    cmp qword [r15 - 16], 0
    je .Pop
    call DropFn
    jmp .Pop
.Try:
    mov rcx, [r15 - 32]
    test rcx, rcx
    jnz .TryHandled
    CompilePrim PrimTryEnd
    mov rcx, [r15 - 40]
    mov rdx, [rel Here]
    mov [rcx], rdx
    jmp .Pop
.TryHandled:
    mov rdx, [rel Here]
    mov [rcx], rdx
    jmp .Pop
.Check:
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
    lea rax, [rel PrimSub]
    test rbx, 1
    jz .Count
    lea rax, [rel PrimAdd]
    and rbx, -2
.Count:
    push rax
    mov rcx, rbx
    call EmitLoad
    CompileNum 1
    pop rcx
    call Compile
    mov rcx, rbx
    call EmitStore
.NoCounter:
    CompilePrim PrimBranch
    mov rcx, [r15 - 40]
    call Compile
    mov rcx, [r15 - 32]
    mov rdx, [rel Here]
    call PatchChain
    jmp .Pop
.Fn:
    call EmitLaters
    mov qword [rel LaterCount], 0
    mov r8, [rel FnSig]
    mov rax, [r8 - 8]
    cmp rax, TDec
    ja .NoReturn
    cmp rax, TText
    je .NoReturn
    CompileNum 0
    CompilePrim PrimReturn
    jmp .FnFinish
.NoReturn:
    CompilePrim PrimNoReturn
.FnFinish:
    mov rax, [rel FnFrameSlot]
    mov rcx, [rel LocalCount]
    mov [rax], rcx
    call EndDef
    mov qword [rel InFn], 0
    mov qword [rel LocalCount], 0
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
    call NewHidden
    push rax
    call ParseExpr
    NeedType TNum
    IfTok "times", .Times
    Fail ErrTimes
.Times:
    pop rbx
    mov rcx, rbx
    call EmitStore
    mov rax, [rel Here]
    push rax
    mov rcx, rbx
    call EmitLoad
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
    call NeedCondition
    jmp .Cond
.Until:
    call Advance
    mov rax, [rel Here]
    push rax
    call ParseExpr
    call NeedCondition
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
    call IsNameStart
    test eax, eax
    jz .BadEach
    push qword [rel TokPtr]
    push qword [rel TokLen]
    call Advance
    Expect "in", ErrEach
    call Advance
    call ParseBits
    IfTok "..", .EachRange
    mov rax, [rel ExprType]
    call KindOfType
    cmp rax, KList
    je .EachList
    cmp rax, KMap
    jne TypeError
    CompilePrim PrimMapKeys
    mov ecx, TText
    call ListOf
    mov [rel ExprType], rax
.EachList:
    mov rcx, [rel ExprType]
    call ElemOf
    push rax
    call NewHidden
    push rax
    mov rcx, rax
    call EmitStore
    call NewHidden
    push rax
    CompileNum 0
    mov rcx, [rsp]
    call EmitStore
    mov rcx, [rsp + 32]
    mov rdx, [rsp + 24]
    call ResolveLoopVar
    push rax
    mov rcx, rax
    call TypeOf
    mov rdx, [rsp + 24]
    test rax, rax
    jz .EachSetType
    test rdx, rdx
    jz .EachTyped
    cmp rax, rdx
    jne TypeError
    jmp .EachTyped
.EachSetType:
    mov rcx, [rsp]
    call SetTypeOf
.EachTyped:
    mov rax, [rel Here]
    push rax
    mov rcx, [rsp + 16]
    call EmitLoad
    mov rcx, [rsp + 24]
    call EmitLoad
    CompilePrim PrimLength
    CompilePrim PrimLess
    lea rcx, [rel PrimBranch0]
    call EmitJump
    push rax
    mov rcx, [rsp + 32]
    call EmitLoad
    mov rcx, [rsp + 24]
    call EmitLoad
    CompileNum 1
    CompilePrim PrimAdd
    CompilePrim PrimIndex
    mov rcx, [rsp + 16]
    call EmitStore
    pop rax
    pop rdx
    pop rcx
    pop rbx
    add rsp, 32
    or rbx, 1
    DPush rdx
    DPush rax
    DPush rbx
    DPush 0
    DPush TagLoop
    inc qword [rel OpenBlocks]
    jmp Pushback
.EachRange:
    NeedType TNum
    call Advance
    call ParseBits
    NeedType TNum
    call NewHidden
    push rax
    mov rcx, rax
    call EmitStore
    mov rcx, [rsp + 16]
    mov rdx, [rsp + 8]
    call ResolveLoopVar
    push rax
    mov rcx, rax
    call TypeOf
    test rax, rax
    jz .RangeSetType
    cmp rax, TNum
    jne TypeError
    jmp .RangeTyped
.RangeSetType:
    mov rcx, [rsp]
    mov edx, TNum
    call SetTypeOf
.RangeTyped:
    mov rcx, [rsp]
    call EmitStore
    mov rax, [rel Here]
    push rax
    mov rcx, [rsp + 8]
    call EmitLoad
    mov rcx, [rsp + 16]
    call EmitLoad
    CompilePrim PrimLessEq
    lea rcx, [rel PrimBranch0]
    call EmitJump
    pop rdx
    pop rbx
    add rsp, 24
    or rbx, 1
    DPush rdx
    DPush rax
    DPush rbx
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

EndTries:
    mov r8, [rel OpenBlocks]
    mov r9, r15
    xor r10d, r10d
.Loop:
    test r8, r8
    jz .Emit
    mov rax, [r9 - 8]
    cmp rax, rcx
    je .Emit
    cmp rax, TagFn
    je .Emit
    cmp rax, TagTry
    jne .Next
    cmp qword [r9 - 32], 0
    jne .Next
    inc r10
.Next:
    sub r9, 40
    dec r8
    jmp .Loop
.Emit:
    test r10, r10
    jz .Done
    push r10
    CompilePrim PrimTryEnd
    pop r10
    dec r10
    jmp .Emit
.Done:
    ret

StopWord:
    mov ecx, TagLoop
    call EndTries
    call FindLoopFrame
    mov r11, rax
    lea rcx, [rel PrimBranch]
    call EmitJump
    mov rdx, [r11 + 8]
    mov [rax], rdx
    mov [r11 + 8], rax
    ret

SkipWord:
    mov ecx, TagLoop
    call EndTries
    call FindLoopFrame
    mov r11, rax
    lea rcx, [rel PrimBranch]
    call EmitJump
    mov rdx, [r11 + 24]
    mov [rax], rdx
    mov [r11 + 24], rax
    ret

ParseTuple:
    push qword [rel TempTop]
    push 0
.Add:
    mov rax, [rel ExprType]
    test rax, rax
    jz TypeError
    mov rcx, [rsp]
    cmp rcx, 9
    jae .TooMany
    lea rdx, [rcx + rcx * 2]
    mov r8, [rsp + 8]
    lea r8, [r8 + rdx * 8]
    lea r9, [rel DigitNames]
    add r9, rcx
    mov [r8], r9
    mov qword [r8 + 8], 1
    mov [r8 + 16], rax
    inc qword [rsp]
    add r8, 24
    mov [rel TempTop], r8
    IfTok ",", .Next
    mov rcx, [rsp]
    mov rdx, [rsp + 8]
    call InternRecord
    mov rbx, rax
    push rbx
    CompilePrim PrimMakeRecord
    mov rcx, [rsp + 8]
    call Compile
    xor esi, esi
.Slots:
    cmp rsi, [rsp + 8]
    jae .Done
    lea rdx, [rel DigitNames]
    add rdx, rsi
    mov rcx, [rsp]
    mov r8d, 1
    call FindField
    mov rcx, rax
    call Compile
    inc rsi
    jmp .Slots
.Done:
    pop rbx
    mov [rel ExprType], rbx
    pop rax
    pop rax
    mov [rel TempTop], rax
    ret
.Next:
    call Advance
    call ParseExpr
    jmp .Add
.TooMany:
    Fail ErrTupleMany

MultiAssign:
    sub rsp, 160
    mov [rsp + 152], rcx
    mov qword [rsp + 144], 0
.Name:
    call IsNameStart
    test eax, eax
    jz .BadName
    mov rax, [rsp + 144]
    cmp rax, 9
    jae .TooMany
    shl rax, 4
    mov rcx, [rel TokPtr]
    mov [rsp + rax], rcx
    mov rcx, [rel TokLen]
    mov [rsp + rax + 8], rcx
    inc qword [rsp + 144]
    call Advance
    IfTok ",", .More
    Expect "=", ErrSet
    call Advance
    call ParseExpr
    IfTok ",", .Tuple
    jmp .Check
.More:
    call Advance
    jmp .Name
.Tuple:
    call ParseTuple
.Check:
    mov rax, [rel ExprType]
    call KindOfType
    cmp rax, KRec
    jne .NotTuple
    mov rcx, [rel ExprType]
    call FieldCount
    cmp rax, [rsp + 144]
    jne .Count
    mov qword [rsp + 136], 0
.Store:
    mov rax, [rsp + 136]
    cmp rax, [rsp + 144]
    jae .Finish
    lea rdx, [rel DigitNames]
    add rdx, rax
    mov rcx, [rel ExprType]
    mov r8d, 1
    push qword [rel ExprType]
    call FindField
    cmp rax, -1
    je .NotTupleP
    push rdx
    push rax
    CompilePrim PrimDup
    CompilePrim PrimGetField
    pop rcx
    shl rcx, 3
    call Compile
    mov rax, [rsp + 16 + 136]
    shl rax, 4
    mov rcx, [rsp + 16 + rax]
    mov rdx, [rsp + 16 + rax + 8]
    cmp qword [rsp + 16 + 152], 0
    je .Change
    push rcx
    push rdx
    cmp qword [rel InFn], 0
    jne .FindLocal
    call LookupVar
    jmp .Found
.FindLocal:
    call FindLocal
    xor edx, edx
    test rax, rax
    jz .Found
    mov r8, rax
    shr r8, 3
    lea r9, [rel LocalConst]
    mov rdx, [r9 + r8 * 8]
.Found:
    test rax, rax
    jz .Create
    test rdx, rdx
    jnz .Const
    lea rcx, [rel WarnExists]
    mov edx, WarnExistsLen
    mov r8, [rsp + 8]
    mov r9, [rsp]
    call Warn
    add rsp, 16
    jmp .Typed
.Create:
    pop rdx
    pop rcx
    call NewVar
    jmp .Typed
.Change:
    push rcx
    push rdx
    call LookupVar
    pop r9
    pop r8
    test rax, rax
    jz .Missing
    test rdx, rdx
    jnz .ConstChange
.Typed:
    push rax
    mov rcx, rax
    call TypeOf
    mov rdx, [rsp + 8]
    test rax, rax
    jz .SetType
    cmp rax, rdx
    je .Emit
    call Compatible
    test rax, rax
    jz TypeError
    jmp .Emit
.SetType:
    mov rcx, [rsp]
    call SetTypeOf
.Emit:
    pop rcx
    call EmitStore
    add rsp, 8
    pop rax
    mov [rel ExprType], rax
    inc qword [rsp + 136]
    jmp .Store
.Finish:
    CompilePrim PrimDrop
    add rsp, 160
    jmp Pushback
.NotTupleP:
    add rsp, 8
.NotTuple:
    Fail ErrNotTuple
.Count:
    Fail ErrTupleCount
.TooMany:
    Fail ErrTupleMany
.BadName:
    FailTok ErrSetName
.Const:
.ConstChange:
    Fail ErrConst
.Missing:
    mov [rel ErrTokPtr], r8
    mov [rel ErrPos], r8
    mov [rel ErrTokLen], r9
    lea rcx, [rel ErrNotExist]
    mov edx, ErrNotExistLen
    jmp Abort

FindKindName:
    push rbx
    push rsi
    mov rbx, rcx
    call FieldCount
    mov r10, rax
    mov rcx, rbx
    shl rcx, 5
    lea rax, [rel TypeTable]
    mov r11, [rax + rcx + 24]
    mov rdx, [rel TokPtr]
    mov r8, [rel TokLen]
    xor eax, eax
.Loop:
    cmp rax, r10
    jae .None
    mov rsi, rax
    shl rsi, 4
    add rsi, r11
    cmp r8, [rsi + 8]
    jne .Next
    mov rsi, [rsi]
    xor r9d, r9d
.Cmp:
    cmp r9, r8
    je .Found
    mov cl, [rsi + r9]
    cmp cl, [rdx + r9]
    jne .Next
    inc r9
    jmp .Cmp
.Next:
    inc rax
    jmp .Loop
.Found:
    inc rax
    pop rsi
    pop rbx
    ret
.None:
    xor eax, eax
    pop rsi
    pop rbx
    ret

KindWord:
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
    xor ecx, ecx
    mov rdx, [rel EnumTop]
    call NewEnum
    push rax
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call CreateVar
    mov r8, [rel Latest]
    mov byte [r8 + 16], 6
    mov rcx, [rsp]
    mov [r8 + 8], rcx
    call Advance
    Expect "=", ErrKindEq
    xor ebx, ebx
.Value:
    call Advance
    call IsNameStart
    test eax, eax
    jz .BadValue
    call IsReserved
    test eax, eax
    jnz .BadValue
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call FindWord
    test rax, rax
    jnz .Taken
    lea rax, [rel EnumNames]
    mov rcx, [rel EnumTop]
    sub rcx, rax
    cmp rcx, 16 * 4090
    jae .TooMany
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    push rdx
    call CopyString
    pop rdx
    mov r8, [rel EnumTop]
    mov [r8], rax
    mov [r8 + 8], rdx
    add qword [rel EnumTop], 16
    inc rbx
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call CreateVar
    mov [rax], rbx
    mov rcx, rax
    mov rdx, [rsp]
    call SetTypeOf
    mov r8, [rel Latest]
    mov byte [r8 + 16], 5
    call Advance
    IfTok ",", .Value
    pop rcx
    shl rcx, 5
    lea rax, [rel TypeTable]
    mov [rax + rcx + 16], rbx
    jmp Pushback
.Where:
    Fail ErrKindWhere
.BadName:
    FailTok ErrKindName
.BadValue:
    FailTok ErrKindName
.Taken:
    FailTok ErrKindTaken
.TooMany:
    Fail ErrTupleMany

CheckWord:
    call Advance
    call ParseExpr
    mov rax, [rel ExprType]
    test rax, rax
    jz TypeError
    push rax
    call NewHidden
    push rax
    mov rcx, rax
    call EmitStore
    pop rbx
    pop rax
    DPush 0
    DPush 0
    DPush rbx
    DPush rax
    DPush TagCheck
    inc qword [rel OpenBlocks]
    jmp Pushback

IsWord:
    cmp qword [rel OpenBlocks], 0
    je .Bad
    cmp qword [r15 - 8], TagDummy
    je .Dummy
    cmp qword [r15 - 8], TagCheck
    jne .Bad
    mov rax, [r15 - 32]
    or rax, [r15 - 40]
    jz .First
    cmp qword [r15 - 32], 0
    je .AfterOtherwise
    lea rcx, [rel PrimBranch]
    call EmitJump
    mov rdx, [r15 - 40]
    mov [rax], rdx
    mov [r15 - 40], rax
    mov rcx, [r15 - 32]
    mov rdx, [rel Here]
    mov [rcx], rdx
.First:
    xor ebx, ebx
.Alt:
    push rbx
    mov rcx, [r15 - 24]
    call EmitLoad
    call Advance
    call ParseExpr
    mov rbx, [r15 - 16]
    mov rax, [rel ExprType]
    cmp rax, rbx
    je .Equal
    mov rcx, rax
    call TypeKind
    cmp rax, KList
    jne .Mixed
    mov rcx, [rel ExprType]
    call ElemOf
    cmp rax, rbx
    jne TypeError
    cmp rbx, TText
    je .HasText
    CompilePrim PrimListHas
    jmp .Joined
.HasText:
    CompilePrim PrimListHasText
    jmp .Joined
.Mixed:
    mov rax, rbx
    call NumericPair
    CompilePrim PrimDEq
    jmp .Joined
.Equal:
    cmp rbx, TText
    je .EqText
    cmp rbx, TDec
    je .EqDec
    CompilePrim PrimEq
    jmp .Joined
.EqText:
    CompilePrim PrimTextEq
    jmp .Joined
.EqDec:
    CompilePrim PrimDEq
.Joined:
    pop rbx
    test rbx, rbx
    jz .NoOr
    CompilePrim PrimOr
.NoOr:
    mov ebx, 1
    IfTok ",", .Alt
    lea rcx, [rel PrimBranch0]
    call EmitJump
    mov [r15 - 32], rax
    jmp Pushback
.Dummy:
    call Advance
    call ParseExpr
    IfTok ",", .Dummy
    jmp Pushback
.AfterOtherwise:
    Fail ErrIsAfter
.Bad:
    Fail ErrIs

TryWord:
    lea rcx, [rel PrimTry]
    call EmitJump
    DPush rax
    DPush 0
    DPush 0
    DPush 0
    DPush TagTry
    inc qword [rel OpenBlocks]
    ret

LaterWord:
    cmp qword [rel InFn], 0
    je .Bad
    mov rax, [rel LaterCount]
    cmp rax, 16
    jae .TooMany
    call GetInput
    mov rcx, [rel LaterCount]
    lea rdx, [rel LaterPos]
    mov [rdx + rcx * 8], rax
    inc qword [rel LaterCount]
    push qword [rel Here]
    call ParseOneStatement
    pop qword [rel Here]
    ret
.Bad:
    Fail ErrLaterWhere
.TooMany:
    Fail ErrTooMany

EmitLaters:
    mov rax, [rel LaterCount]
    test rax, rax
    jz .None
    push r12
    push r13
    call GetInput
    push rax
    push qword [rel TokPtr]
    push qword [rel TokLen]
    push qword [rel PrevTokPtr]
    mov rax, [rel LaterCount]
    push rax
.Loop:
    cmp qword [rsp], 0
    je .Done
    dec qword [rsp]
    mov rax, [rsp]
    lea rcx, [rel LaterPos]
    mov rcx, [rcx + rax * 8]
    call Unread
    call ParseOneStatement
    jmp .Loop
.Done:
    pop rax
    pop qword [rel PrevTokPtr]
    pop qword [rel TokLen]
    pop qword [rel TokPtr]
    pop rcx
    call Unread
    pop r13
    pop r12
.None:
    ret

ParseOneStatement:
    call NextToken
    test rdx, rdx
    jz .Bad
    mov r12, rax
    mov r13, rdx
    mov rcx, rax
    call FindWord
    test rax, rax
    jz .Expr
    cmp rdx, 2
    jne .Expr
    lea rcx, [rel SayWord]
    cmp rax, rcx
    je .Imm
    lea rcx, [rel SetWord]
    cmp rax, rcx
    je .Imm
    lea rcx, [rel ByeWord]
    cmp rax, rcx
    je .Imm
.Bad:
    Fail ErrLaterWhat
.Imm:
    mov [rel PrevTokPtr], r12
    mov [rel TokPtr], r12
    mov [rel TokLen], r13
    jmp rax
.Expr:
    xor ecx, ecx
    jmp StmtExpr

ReturnWord:
    cmp qword [rel InFn], 0
    je .Bad
    call Advance
    call ParseExpr
    IfTok ",", .Tuple
    jmp .Typed
.Tuple:
    call ParseTuple
.Typed:
    mov rax, [rel ExprType]
    test rax, rax
    jz TypeError
    mov r8, [rel FnSig]
    mov rdx, [r8 - 8]
    test rdx, rdx
    jz .SetReturn
    cmp rdx, rax
    je .Emit
    cmp rdx, TDec
    jne .ReturnCompat
    cmp rax, TNum
    jne TypeError
    CompilePrim PrimToDec
    jmp .Emit
.ReturnCompat:
    xchg rax, rdx
    push rax
    call Compatible
    pop rcx
    cmp rax, rcx
    jne TypeError
    jmp .Emit
.SetReturn:
    mov [r8 - 8], rax
.Emit:
    mov ecx, TagFn
    call EndTries
    call EmitLaters
    CompilePrim PrimReturn
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
    call IsNameStart
    test eax, eax
    jz .Bad
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call BeginDef
    mov rax, [rel Latest]
    mov byte [rax + 16], 4
    mov ebx, SigCells
.Sig:
    xor ecx, ecx
    call Compile
    dec ebx
    jnz .Sig
    mov rax, [rel Here]
    mov rcx, [rel Latest]
    mov [rcx + 8], rax
    mov [rel FnSig], rax
    mov qword [rel InFn], 1
    mov qword [rel LocalCount], 0
    CompilePrim PrimEnter
    mov rax, [rel Here]
    mov [rel FnFrameSlot], rax
    xor ecx, ecx
    call Compile
    call Advance
    Expect "(", ErrParen
    call Advance
    IfTok ")", .ParamsDone
.ParamLoop:
    cmp qword [rel TokLen], 0
    je .BadParen
    call IsNameStart
    test eax, eax
    jz .BadParen
    mov r8, [rel FnSig]
    test qword [r8 - SigFlags], 1
    jnz .RestNotLast
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call AddLocal
    mov rbx, [rel LocalCount]
    dec rbx
    cmp rbx, 16
    jae .TooMany
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    push rdx
    call CopyString
    pop rdx
    mov r8, [rel FnSig]
    mov r9, rbx
    shl r9, 4
    neg r9
    mov [r8 - SigName + r9], rax
    mov [r8 - SigName - 8 + r9], rdx
    call Advance
    IfTok "...", .Rest
    jmp .AfterRest
.Rest:
    mov r8, [rel FnSig]
    or qword [r8 - SigFlags], 1
    call Advance
.AfterRest:
    push rbx
    push 0
    IfTok ":", .ParamType
    jmp .MaybeDefault
.ParamType:
    call Advance
    call ParseTypeName
    mov [rsp], rax
    call Advance
.MaybeDefault:
    IfTok "=", .Default
    pop rax
    pop rbx
    test rax, rax
    jnz .SetParamType
    mov eax, TNum
    jmp .SetParamType
.Default:
    mov r8, [rel FnSig]
    test qword [r8 - SigFlags], 1
    jnz .RestDefault
    call Advance
    mov qword [rel InFn], 0
    lea rcx, [rel PrimBranch]
    call EmitJump
    push rax
    push qword [rel Here]
    call ParseExpr
    mov qword [rel InFn], 1
    mov rax, [rsp + 16]
    mov rdx, [rel ExprType]
    test rax, rax
    jz .DefaultTakes
    cmp rax, rdx
    je .DefaultTyped
    cmp rax, TDec
    jne .DefaultCompat
    cmp rdx, TNum
    jne TypeError
    CompilePrim PrimToDec
    jmp .DefaultTyped
.DefaultCompat:
    call Compatible
    cmp rax, [rsp + 16]
    jne TypeError
    jmp .DefaultTyped
.DefaultTakes:
    test rdx, rdx
    jz TypeError
    mov [rsp + 16], rdx
.DefaultTyped:
    CompilePrim PrimExit
    pop rcx
    pop rdx
    mov rax, [rel Here]
    mov [rdx], rax
    pop rax
    pop rbx
    mov r8, [rel FnSig]
    mov r9, rbx
    shl r9, 3
    neg r9
    mov [r8 - SigDef + r9], rcx
.SetParamType:
    mov r8, [rel FnSig]
    test qword [r8 - SigFlags], 1
    jz .NotRest
    mov rcx, rax
    call ListOf
.NotRest:
    push rax
    call KindOfType
    pop rcx
    cmp rax, KList
    jne .ParamTypeKeep
    push rcx
    call ElemOf
    pop rcx
    test rax, rax
    jnz .ParamTypeKeep
    mov ecx, TNum
    call ListOf
    mov rcx, rax
.ParamTypeKeep:
    mov rax, rcx
.ParamTypeOk:
    lea r8, [rel LocalType]
    mov [r8 + rbx * 8], rax
    mov r8, [rel FnSig]
    mov r9, rbx
    shl r9, 3
    sub r8, 24
    sub r8, r9
    mov [r8], rax
    IfTok ",", .NextParam
    IfTok ")", .ParamsDone
.BadParen:
    Fail ErrParen
.NextParam:
    call Advance
    jmp .ParamLoop
.ParamsDone:
    mov rax, [rel LocalCount]
    mov r8, [rel FnSig]
    mov [r8 - 16], rax
    call Advance
    IfTok ":", .ReturnType
    call Pushback
    jmp .Prologue
.ReturnType:
    call Advance
    call ParseTypeName
    mov r8, [rel FnSig]
    mov [r8 - 8], rax
.Prologue:
    mov rbx, [rel LocalCount]
.PLoop:
    test rbx, rbx
    jz .PDone
    dec rbx
    CompilePrim PrimLocalSet
    mov rcx, rbx
    shl rcx, 3
    call Compile
    jmp .PLoop
.PDone:
    DPush 0
    DPush 0
    DPush 0
    DPush 0
    DPush TagFn
    inc qword [rel OpenBlocks]
    ret
.TooMany:
    Fail ErrTooMany
.RestNotLast:
    Fail ErrRestLast
.RestDefault:
    Fail ErrRestDefault
.Bad:
    Fail ErrDo

HintElse:
    Fail ErrElse
HintElif:
    Fail ErrElif
HintThen:
    Fail ErrThen
HintFor:
    Fail ErrFor
HintWhile:
    Fail ErrWhile
HintFunction:
    Fail ErrFunction
HintLocal:
    Fail ErrLocal
