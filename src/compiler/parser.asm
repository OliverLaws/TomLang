%include "macros.inc"

global Advance
global ParseExpr
global ResetCompiler
global ExprDepth
global UnwindLambdas
global TypeDepth
global OpenBlocks
global BlockBase
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
extern DataSpace
extern DataHere
extern Alloc
extern PermAlloc
extern CopyString
extern MakeText
extern InitStack
extern Abort
extern FileMode
extern ReadMoreLine
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
extern PrimLoopBack
extern PrimNoPtrs
extern PrimAppendG
extern PrimAppendL
extern PrimFlatTop
extern PrimSpawnThread
extern PrimBranch0
extern PrimBye
extern PrimBox
extern PrimUnbox
extern PrimTagIs
extern PrimGetG
extern PrimSetG
extern PrimIncG
extern PrimIncL
extern PrimTextLength
extern PrimTextChars
extern PrimFfiCallPtr
extern PrimMakeMapInt
extern PrimMapGetInt
extern PrimMapSetInt
extern PrimMapHasInt
extern PrimEnterHeap
extern PrimReturnHeap
extern PrimFetchOff
extern PrimStoreOff
extern PrimReorder
extern PrimDPow
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
extern PrimDeepEq
extern PrimListSort
extern PrimAndJump
extern PrimWait
extern PrimTextSplit
extern PrimTextUpper
extern PrimTextLower
extern PrimTextTrim
extern PrimTextReplace
extern PrimTextStarts
extern PrimTextEnds
extern PrimListRemoveValue
extern PrimMapGetOr
extern PrimMapGetOrInt
extern PrimMapRemove
extern PrimMapRemoveInt
extern PrimSpawn
extern PrimTaskEnd
extern PrimEnterArgs
extern F_Lit_PrimAdd
extern F_Lit_PrimSub
extern F_GetG_Lit_PrimAdd
extern F_GetG_Lit_PrimSub
extern F_LocalGet_Lit_PrimAdd
extern F_LocalGet_Lit_PrimSub
extern FuseBranch
extern CompileOp
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
extern UnionOf2
extern UnionWithout
extern UnionHas
extern MapKeyed
extern KeyOf
extern ElemOf
extern InternRecord
extern FindField
extern FieldCount
extern FieldInfo
extern NewRecordType
extern NewPlaceholder
extern PrimMakeIface
extern PrimJoin
extern PrimIfaceCall
extern NewEnum
extern FuncOf
extern PrimCallValue
extern PrimMakeClosure
extern PrimTry
extern PrimTryEnd
extern PrimLastError
extern DictHere
extern CurFile
extern FilePath
extern SysCurrentDir
extern FileCount
extern TryForward
extern TryForwardVar
extern PrimMissingFn
extern EnterInstanceSpace
extern LeaveInstanceSpace
extern TypeTable
global KindWord
global RecordWord
global SettingWord
global SpawnWhenWord
global SpawnEveryWord
global SpawnAfterWord
global SpawnTaskWord
global SpawnThreadWord
global WaitWord
global InterfaceWord
global TypeWord
global DllWord
global InstanceDepth
global PreScanActive
global PreScanFail
global EmitGlobalInits
global NestDepth
global NestHeaderDone
global NestFloor
global NestAbort
global PreDeclare
global PreHandler
global NoteForwardVar
global LookupVar
global FullForward
global NoteStmt
extern SetWord
extern KeepWord
extern VarTypeOf
extern SaveMain
extern RestoreMain
extern SetMainFile
extern ForwardOps
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
%define TNil 5
%define KUnion 11
%define KNil 12
%define TBool 3
%define TDec  4

%define KList 5
%define KMap  6
%define KRec  7
%define KEnum 8
%define KFunc 9
%define KVar  10
%define KIface 13

%define MaxLocals 1024
%define LfCount (MaxLocals * 40 + 0)
%define LfInFn (MaxLocals * 40 + 8)
%define LfSig (MaxLocals * 40 + 16)
%define LfFrame (MaxLocals * 40 + 24)
%define LfHintCount (MaxLocals * 40 + 32)
%define LfHintPtr (MaxLocals * 40 + 40)
%define LfOuter (MaxLocals * 40 + 48)
%define LfBranch (MaxLocals * 40 + 56)
%define LfBody (MaxLocals * 40 + 64)
%define LfJump (MaxLocals * 40 + 72)
%define LfHere (MaxLocals * 40 + 80)
%define LfParams (MaxLocals * 40 + 88)
%define LfLink (MaxLocals * 40 + 96)
%define LfId (MaxLocals * 40 + 104)
%define LfHeap (MaxLocals * 40 + 112)
%define LfScopes (MaxLocals * 40 + 120)
%define LfInit (MaxLocals * 40 + 128)
%define LfParent (MaxLocals * 40 + 136)
%define LFrame (MaxLocals * 40 + 160)
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

%macro TryOp 2
[section .data]
%%Str: db %1
%%End:
__SECT__
    push rax
    mov rdx, [rel ExprType]
    lea rcx, [rel %%Str]
    mov r8d, %%End - %%Str
    call TryOverload
    test eax, eax
    pop rax
    jnz %2
%endmacro

%macro ArithOp 5
%1:
    push qword [rel ExprType]
    call Advance
    call %2
    pop rax
    TryOp %5, %%Over
    call NumericPair
    lea rcx, [rel %3]
    cmp rax, TDec
    jne %%Emit
    lea rcx, [rel %4]
%%Emit:
    mov [rel ExprType], rax
    call CompileOp
%%Over:
%endmacro

%include "parser/messages.inc"

MaxForward equ 8192
NestRegion equ 12
MaxNest equ 32
MaxScopes equ 64
ForwardRegion equ 8
MaxPre equ 16

section .bss
ParserState:
AllowTypeVars resq 1
GenericFound resq 1
InstanceMode resq 1
InstanceBindings resq 27
DoStart resq 1
PendingNode resq 1
FfiLib resq 1
FfiPtrMode resq 1
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
LaterPos resq 64
LaterBlock resq 64
HintCount resq 1
HintPtr   resq 1
HintFn    resq 1
NoBar resq 1
PendingType resq 1
PendingUsed resq 1
OrderOp resq 1
DefNamePtr resq 1
DefNameLen resq 1
RecvType  resq 1
RecvBare  resq 1
HintType  resq 1
CurHintType resq 1
CurHintFn resq 1
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
BlockBase    resq 1
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
NarrowCount resq 1
NarrowVar resq 32
NarrowType resq 32
NarrowLevel resq 32
NarrowCandVar resq 1
NarrowCandType resq 1
NarrowCandHere resq 1
OrSeen resq 1
NilCmpVar resq 1
EqType resq 1
CheckVars resq 64
NilCmpType resq 1
ScopeCount resq 1
ScopeTab resq 8 * MaxScopes
CurLinkOff resq 1
CurFnId resq 1
CurHeap resq 1
NestFloor resq 1
EachIdxLen resq 1
EachMapVar resq 1
EachMapType resq 1
EachMapFull resq 1
NegCandVar resq 1
NegCandType resq 1
NegCandHere resq 1
NegCandDepth resq 1
NegCount resq 1
NegVars resq 4
NegTypes resq 4
NegDepths resq 4
PendLevel resq 1
AndSeen resq 1
PrevExit resq 1
DeadAtEnd resq 1
PendNarVar resq 1
PendNarType resq 1
ParserStateEnd:
GenericCount resq 1
CompoundHere resq 1
ForwardVarCount resq 1
ForwardVars resq 256
LaterEmitting resq 1
InitVarCount resq 1
InitVars resq 4096
NestDepth resq 1
NestInInstance resq 1
FileZeroTab resb 256
LastFnValSig resq 1
LastFnValHere resq 1
VarSigCount resq 1
VarSigTab resq 3 * 1024
ImplicitScanned resq 1
ImplicitUsed resq 1
ImplicitNext resq 1
InParams resq 1
NestPending resq 1
FnIdCounter resq 1
NestEntryTab resq MaxNest
NestDoneTab resq MaxNest
NestInstTab resq MaxNest
NestVarTab resq 4 * MaxNest
alignb 16
NestSaves resb (ParserStateEnd - ParserState) * MaxNest
MultiCount resq 1
MultiLast resq 1
MultiPtr resq 10
MultiLen resq 10
MultiBuf resb 256
ForwardMode resq 1
PreHandler resq 1
FullEntry resq 1
NegSlots resq 64 * 8
FwdNameBuf resb 256
PreScanActive resq 1
PreScanRspTab resq MaxPre
ForwardCount resq 1
ForwardTable resq 3 * MaxForward
PreScanVarTab resq 8 * MaxPre
alignb 16
PreScanSaves resb (ParserStateEnd - ParserState) * MaxPre
GenericTable resq 2 * 256
InstanceDepth resq 1
SubstFail resq 1
DotBuf resb 256
alignb 16
InstanceSaves resb 32 * ((ParserStateEnd - ParserState) + 256)

section .text

%include "parser/helpers.inc"
%include "parser/expressions.inc"
%include "parser/calls.inc"
%include "parser/primary.inc"
%include "parser/text.inc"
%include "parser/assign.inc"
%include "parser/blocks.inc"
%include "parser/tasks.inc"
%include "parser/tuples.inc"
%include "parser/kinds.inc"
%include "parser/checks.inc"
%include "parser/functions.inc"
%include "parser/ffi.inc"
%include "parser/generics.inc"
%include "parser/scopes.inc"
%include "parser/methods.inc"
