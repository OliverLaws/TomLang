%include "macros.inc"

global Advance
global ParseExpr
global ResetCompiler
global ExprDepth
global UnwindLambdas
global TypeDepth
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
global FailWord
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
extern NamePrefixPtr
extern NamePrefixLen
extern BeginDef
extern EndDef
extern CreateVar
extern AllocSlot
extern Alloc
extern PermAlloc
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
extern PrimLinkGet
extern PrimLinkSet
extern PrimPushFrame
extern PrimFail
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
extern PrimTextCompare
extern PrimAsk
extern PrimRandom
extern PrimMakeList
extern PrimIndex
extern PrimSetIndex
extern PrimListAdd
extern PrimTextSlice
extern PrimListSlice
extern PrimListInsert
extern PrimListRemove
extern PrimListPop
extern PrimListCopy
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
extern PrimMakeClosure
extern PrimTry
extern PrimTryEnd
extern PrimLastError
extern DictHere
extern CurFile
extern TryForward
extern PrimMissingFn
extern EnterInstanceSpace
extern LeaveInstanceSpace
extern TypeTable
global KindWord
global DllWord
global InstanceDepth
global PreScanActive
global PreScanFail
global EmitGlobalInits
global NestDepth
global NestHeaderDone
global NestAbort
global PreDeclare
extern VarTypeOf
extern SaveMain
extern RestoreMain
extern SetMainFile
extern SourceStart
extern SourceEnd
extern SavedHere
extern RecordLine
extern SysLoadLib
extern SysGetProc
extern PrimFfiCall
extern CreateEntry
global CheckWord
global IsWord
global TryWord
global LaterWord
extern ParseDecimalText
extern PrimDup
extern PrimDup2
extern PrimToDec
extern PrimToDecUnder
extern PrimDAdd
extern PrimDSub
extern PrimDMul
extern PrimDDiv
extern PrimDFloorDiv
extern PrimDMod
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
%define KVar  10

%define MaxLocals 64
%define LFrame 2416
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

%include "parser/messages.inc"

MaxForward equ 1024
NestRegion equ 9
ForwardRegion equ 8

section .bss
ParserState:
AllowTypeVars resq 1
GenericFound resq 1
InstanceMode resq 1
InstanceBindings resq 26
DoStart resq 1
PendingNode resq 1
FfiLib resq 1
FfiProc resq 1
FfiSavedHere resq 1
FfiEntry resq 1
FfiSig resq 1
FfiKinds resq 1
FfiArgc resq 1
FfiRet resq 1
FfiName resb 256
FfiKindArr resq 16
StructNamePtr resq 1
StructNameLen resq 1
StructCount resq 1
StructOffset resq 1
StructAlign resq 1
StructSize resq 1
StructType resq 1
StructFields resb 64 * 32
ExprDepth resq 1
TypeDepth resq 1
ReplacePtr resq 1
ReplaceLen resq 1
CurReplacePtr resq 1
CurReplaceLen resq 1
ReplaceType resq 1
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
LocalInit    resq MaxLocals
FnInitCell   resq 1
NestListCount resq 1
NestList resq 64
EachIdxPtr resq 1
EachIdxLen resq 1
EachMapVar resq 1
EachMapType resq 1
ParserStateEnd:
GenericCount resq 1
InitVarCount resq 1
InitVars resq 4096
NestDepth resq 1
NestInInstance resq 1
NestPending resq 1
NestHeaderDone resq 1
NestLinkOff resq 1
NestEntry resq 1
NestVars resq 4
alignb 16
NestSave resb (ParserStateEnd - ParserState)
MultiCount resq 1
MultiLast resq 1
MultiPtr resq 10
MultiLen resq 10
MultiBuf resb 256
ForwardMode resq 1
PreScanActive resq 1
PreScanRsp resq 1
ForwardCount resq 1
ForwardTable resq 3 * MaxForward
PreScanVars resq 8
alignb 16
PreScanSave resb (ParserStateEnd - ParserState)
GenericTable resq 2 * 256
InstanceDepth resq 1
SubstFail resq 1
DotBuf resb 256
alignb 16
InstanceSaves resb 8 * ((ParserStateEnd - ParserState) + 256)

section .text

%include "parser/helpers.inc"
%include "parser/expressions.inc"
%include "parser/calls.inc"
%include "parser/primary.inc"
%include "parser/text.inc"
%include "parser/assign.inc"
%include "parser/blocks.inc"
%include "parser/tuples.inc"
%include "parser/kinds.inc"
%include "parser/checks.inc"
%include "parser/functions.inc"
%include "parser/ffi.inc"
%include "parser/generics.inc"
