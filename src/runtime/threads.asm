%include "macros.inc"

global InitThreads
global ThreadPark
global ThreadUnpark
global ThreadSleep
global GilYield
global PrimLoopBack
global PrimSpawnThread
global PrimThreadEnd
global ThreadMain
global ThreadMarkRoots
global CbEnter
global CbExit
global InMainThread
global ParkIfThreaded
global UnparkIf
global TryStackPtr
global FfiVmPtr
global CbRspPtr
global Threaded
global ThreadCount
global GilOwner
global GilDrop
global MainCtx
extern SysAlloc
extern SysNowNs
extern SysSleepNsT
extern SysThreadCreate
extern SysThreadExit
extern SysThreadId
extern MarkRange
extern Abort
extern PrimCallValue
extern PrimDrop
extern TryStack
extern TryDepth
extern FfiVmStack
extern FfiVmDepth
extern CbRspStack
extern CbDepth
extern LastError
extern StackBase
extern ReplRsp
extern CurDataBase
extern CurRetBase
extern DataLimit
extern ReturnLimit
extern FfiArgs
extern FfiN

%define CTid        0
%define CState      8
%define CRsp        16
%define CNativeTop  24
%define CR15        32
%define CRbp        40
%define CDataBase   48
%define CRetBase    56
%define CDataLimit  64
%define CRetLimit   72
%define CTryDepth   80
%define CTryPtr     88
%define CFfiVmDepth 96
%define CCbDepth    104
%define CLastError  112
%define CFn         120
%define CFfiVmPtr   128
%define CCbRspPtr   136
%define CNext       144
%define CTimer      152
%define CFfiN       160
%define CSwitch     168
%define CReplRsp    176
%define CFfiSave    184
%define CHeader     512
%define CFfiVm      512
%define CCbRsp      6656
%define CTry        8704
%define CData       28672
%define CtxCells    65536
%define CRet        (CData + CtxCells * 8)
%define CtxSize     (CRet + CtxCells * 8)
%define MaxThreads  256
%define Parked      1
%define Idle        3

section .data
ErrThreadMemory db "not enough memory for another thread"
ErrThreadMemoryLen equ $ - ErrThreadMemory
ErrThreadMany db "too many threads (256 at once)"
ErrThreadManyLen equ $ - ErrThreadMany
align 8
BootThread:
    dq PrimCallValue, 0, PrimDrop, PrimThreadEnd

section .bss
alignb 16
MainCtx     resb CHeader
CtxTab      resq MaxThreads * 2
CtxFree     resq 1
GilOwner    resq 1
GilWaiters  resq 1
GilSwitches resq 1
GilDrop     resq 1
Threaded    resq 1
ThreadCount resq 1
TryStackPtr resq 1
FfiVmPtr    resq 1
CbRspPtr    resq 1

section .text
InitThreads:
    lea rax, [rel TryStack]
    mov [rel TryStackPtr], rax
    lea rax, [rel FfiVmStack]
    mov [rel FfiVmPtr], rax
    lea rax, [rel CbRspStack]
    mov [rel CbRspPtr], rax
    lea rax, [rel MainCtx]
    mov [rel GilOwner], rax
    call SysThreadId
    lea rcx, [rel CtxTab]
    mov [rcx], rax
    lea rax, [rel MainCtx]
    mov [rcx + 8], rax
    ret

InMainThread:
    lea rax, [rel MainCtx]
    cmp rax, [rel GilOwner]
    ret

SaveGlobals:
    mov rcx, [rel CurDataBase]
    mov [rax + CDataBase], rcx
    mov rcx, [rel CurRetBase]
    mov [rax + CRetBase], rcx
    mov rcx, [rel DataLimit]
    mov [rax + CDataLimit], rcx
    mov rcx, [rel ReturnLimit]
    mov [rax + CRetLimit], rcx
    mov rcx, [rel TryDepth]
    mov [rax + CTryDepth], rcx
    mov rcx, [rel TryStackPtr]
    mov [rax + CTryPtr], rcx
    mov rcx, [rel FfiVmDepth]
    mov [rax + CFfiVmDepth], rcx
    mov rcx, [rel CbDepth]
    mov [rax + CCbDepth], rcx
    mov rcx, [rel LastError]
    mov [rax + CLastError], rcx
    mov rcx, [rel FfiVmPtr]
    mov [rax + CFfiVmPtr], rcx
    mov rcx, [rel CbRspPtr]
    mov [rax + CCbRspPtr], rcx
    mov rcx, [rel StackBase]
    mov [rax + CNativeTop], rcx
    mov rcx, [rel ReplRsp]
    mov [rax + CReplRsp], rcx
    ret

LoadGlobals:
    mov rcx, [rax + CDataBase]
    mov [rel CurDataBase], rcx
    mov rcx, [rax + CRetBase]
    mov [rel CurRetBase], rcx
    mov rcx, [rax + CDataLimit]
    mov [rel DataLimit], rcx
    mov rcx, [rax + CRetLimit]
    mov [rel ReturnLimit], rcx
    mov rcx, [rax + CTryDepth]
    mov [rel TryDepth], rcx
    mov rcx, [rax + CTryPtr]
    mov [rel TryStackPtr], rcx
    mov rcx, [rax + CFfiVmDepth]
    mov [rel FfiVmDepth], rcx
    mov rcx, [rax + CCbDepth]
    mov [rel CbDepth], rcx
    mov rcx, [rax + CLastError]
    mov [rel LastError], rcx
    mov rcx, [rax + CFfiVmPtr]
    mov [rel FfiVmPtr], rcx
    mov rcx, [rax + CCbRspPtr]
    mov [rel CbRspPtr], rcx
    mov rcx, [rax + CNativeTop]
    mov [rel StackBase], rcx
    mov rcx, [rax + CReplRsp]
    mov [rel ReplRsp], rcx
    ret

ThreadPark:
    mov rax, [rel GilOwner]
    lea rcx, [rsp + 8]
    mov [rax + CRsp], rcx
    mov [rax + CR15], r15
    mov [rax + CRbp], rbp
    call SaveGlobals
    mov rcx, [rel FfiN]
    cmp rcx, 24
    jbe .FfiFits
    mov ecx, 24
.FfiFits:
    mov [rax + CFfiN], rcx
    lea r8, [rel FfiArgs]
    xor edx, edx
.Ffi:
    cmp rdx, rcx
    jae .FfiDone
    mov r9, [r8 + rdx * 8]
    mov [rax + CFfiSave + rdx * 8], r9
    inc rdx
    jmp .Ffi
.FfiDone:
    mov rcx, [rel GilSwitches]
    mov [rax + CSwitch], rcx
    mov qword [rax + CState], Parked
    mov qword [rel GilOwner], 0
    ret

ThreadUnpark:
    push rbx
    mov rbx, rcx
    call GilAcquire
    mov qword [rbx + CState], 0
    mov rax, [rbx + CSwitch]
    inc rax
    cmp rax, [rel GilSwitches]
    je .Same
    mov rax, rbx
    call LoadGlobals
.Same:
    pop rbx
    ret

ParkIfThreaded:
    xor eax, eax
    cmp qword [rel Threaded], 0
    je .No
    jmp ThreadPark
.No:
    ret

UnparkIf:
    test rcx, rcx
    jz .No
    jmp ThreadUnpark
.No:
    ret

GilAcquire:
    xor eax, eax
    lock cmpxchg [rel GilOwner], rcx
    jz .Got
    push rbx
    push r12
    push r13
    push r14
    mov rbx, rcx
    lock inc qword [rel GilWaiters]
    call SysNowNs
    mov r12, rax
    mov r13, 20000
.Try:
    mov r14d, 200
.Spin:
    xor eax, eax
    lock cmpxchg [rel GilOwner], rbx
    jz .GotSlow
    pause
    dec r14d
    jnz .Spin
    call SysNowNs
    sub rax, r12
    cmp rax, 5000000
    jb .Sleep
    mov qword [rel GilDrop], 1
.Sleep:
    mov rcx, r13
    lea rdx, [rbx + CTimer]
    call SysSleepNsT
    shl r13, 1
    cmp r13, 1000000
    jbe .Try
    mov r13, 1000000
    jmp .Try
.GotSlow:
    lock dec qword [rel GilWaiters]
    pop r14
    pop r13
    pop r12
    pop rbx
.Got:
    inc qword [rel GilSwitches]
    ret

GilYield:
    mov qword [rel GilDrop], 0
    cmp qword [rel GilWaiters], 0
    je .Out
    push rbx
    push r12
    call ThreadPark
    mov rbx, rax
    mov r12d, 200
.Wait:
    mov rax, [rbx + CSwitch]
    cmp rax, [rel GilSwitches]
    jne .Back
    cmp qword [rel GilWaiters], 0
    je .Back
    mov ecx, 50000
    lea rdx, [rbx + CTimer]
    call SysSleepNsT
    dec r12d
    jnz .Wait
.Back:
    mov rcx, rbx
    call ThreadUnpark
    pop r12
    pop rbx
.Out:
    ret

ThreadSleep:
    cmp qword [rel Threaded], 0
    jne .Parked
    lea rdx, [rel MainCtx + CTimer]
    jmp SysSleepNsT
.Parked:
    push rbx
    push rcx
    call ThreadPark
    mov rbx, rax
    pop rcx
    lea rdx, [rbx + CTimer]
    call SysSleepNsT
    mov rcx, rbx
    call ThreadUnpark
    pop rbx
    ret

PrimLoopBack:
    cmp qword [rel GilDrop], 0
    jne .Yield
    mov r14, [r14]
    NEXT
.Yield:
    call GilYield
    mov r14, [r14]
    NEXT

NewCtx:
    mov rax, [rel CtxFree]
    test rax, rax
    jz NewCtxFresh
    mov rcx, [rax + CNext]
    mov [rel CtxFree], rcx
    jmp NewCtxInit

NewCtxFresh:
    mov rcx, CtxSize
    call SysAlloc
    test rax, rax
    jz NewCtxNone
    mov qword [rax + CTimer], 0
NewCtxInit:
    lea rcx, [rax + CData]
    mov [rax + CDataBase], rcx
    mov [rax + CR15], rcx
    add rcx, CtxCells * 8 - 512
    mov [rax + CDataLimit], rcx
    lea rcx, [rax + CRet]
    mov [rax + CRetBase], rcx
    mov [rax + CRbp], rcx
    add rcx, CtxCells * 8 - 64
    mov [rax + CRetLimit], rcx
    lea rcx, [rax + CTry]
    mov [rax + CTryPtr], rcx
    lea rcx, [rax + CFfiVm]
    mov [rax + CFfiVmPtr], rcx
    lea rcx, [rax + CCbRsp]
    mov [rax + CCbRspPtr], rcx
    xor ecx, ecx
    mov [rax + CTryDepth], rcx
    mov [rax + CFfiVmDepth], rcx
    mov [rax + CCbDepth], rcx
    mov [rax + CLastError], rcx
    mov [rax + CFn], rcx
    mov [rax + CFfiN], rcx
    mov [rax + CState], rcx
    mov [rax + CRsp], rcx
    mov [rax + CNativeTop], rcx
NewCtxNone:
    ret

ClaimSlot:
    lea r8, [rel CtxTab]
    xor r9d, r9d
.Find:
    cmp r9, MaxThreads
    jae .Full
    mov r10, r9
    shl r10, 4
    xor eax, eax
    mov r11, -1
    lock cmpxchg [r8 + r10], r11
    jz .Got
    inc r9
    jmp .Find
.Got:
    mov [r8 + r10 + 8], rcx
    mov [r8 + r10], rdx
    mov eax, 1
    ret
.Full:
    xor eax, eax
    ret

FindCtx:
    lea r8, [rel CtxTab]
    xor r9d, r9d
.Find:
    cmp r9, MaxThreads
    jae .None
    mov r10, r9
    shl r10, 4
    cmp [r8 + r10], rcx
    je .Got
    inc r9
    jmp .Find
.Got:
    mov rax, [r8 + r10 + 8]
    ret
.None:
    xor eax, eax
    ret

DropSlot:
    lea r8, [rel CtxTab]
    xor r9d, r9d
.Find:
    cmp r9, MaxThreads
    jae .Done
    mov r10, r9
    shl r10, 4
    cmp [r8 + r10 + 8], rcx
    jne .Next
    cmp qword [r8 + r10], -1
    je .Next
    mov qword [r8 + r10], 0
    ret
.Next:
    inc r9
    jmp .Find
.Done:
    ret

PrimSpawnThread:
    push rbx
    call NewCtx
    test rax, rax
    jz .NoMemory
    mov rbx, rax
    DPop rax
    mov [rbx + CFn], rax
    mov rcx, rbx
    mov rdx, -2
    call ClaimSlot
    test eax, eax
    jz .Many
    mov qword [rel Threaded], 1
    inc qword [rel ThreadCount]
    mov rcx, rbx
    call SysThreadCreate
    test rax, rax
    jz .NoMemory
    pop rbx
    NEXT
.NoMemory:
    lea rcx, [rel ErrThreadMemory]
    mov edx, ErrThreadMemoryLen
    jmp Abort
.Many:
    lea rcx, [rel ErrThreadMany]
    mov edx, ErrThreadManyLen
    jmp Abort

ThreadMain:
    and rsp, -16
    mov rbx, rcx
    mov [rbx + CNativeTop], rsp
    mov [rbx + CRsp], rsp
    call SysThreadId
    lea r8, [rel CtxTab]
    xor r9d, r9d
.Find:
    mov r10, r9
    shl r10, 4
    cmp [r8 + r10 + 8], rbx
    jne .Next
    cmp qword [r8 + r10], -2
    je .Set
.Next:
    inc r9
    cmp r9, MaxThreads
    jb .Find
    jmp .Run
.Set:
    mov [r8 + r10], rax
.Run:
    mov rcx, rbx
    call GilAcquire
    mov [rbx + CReplRsp], rsp
    mov rax, rbx
    call LoadGlobals
    mov qword [rel FfiVmDepth], 0
    mov qword [rel CbDepth], 0
    mov qword [rel TryDepth], 0
    mov qword [rel LastError], 0
    mov r15, [rbx + CDataBase]
    mov rbp, [rbx + CRetBase]
    mov r13, rbp
    mov rax, [rbx + CFn]
    DPush rax
    lea r14, [rel BootThread]
    NEXT

PrimThreadEnd:
    mov rbx, [rel GilOwner]
    mov rcx, rbx
    call DropSlot
    mov qword [rbx + CFn], 0
    mov rax, [rel CtxFree]
    mov [rbx + CNext], rax
    mov [rel CtxFree], rbx
    dec qword [rel ThreadCount]
    mov qword [rel GilOwner], 0
    jmp SysThreadExit

CbEnter:
    push rbx
    call SysThreadId
    mov rcx, rax
    push rcx
    call FindCtx
    pop rdx
    test rax, rax
    jz .Foreign
    mov rbx, rax
    cmp rbx, [rel GilOwner]
    je .Held
    cmp qword [rbx + CState], Idle
    je .Enter
    mov rcx, rbx
    call ThreadUnpark
    mov eax, 1
    pop rbx
    ret
.Held:
    xor eax, eax
    pop rbx
    ret
.Foreign:
    push rdx
    call NewCtxFresh
    pop rdx
    test rax, rax
    jz .Refuse
    mov rbx, rax
    mov qword [rbx + CState], Idle
    mov rcx, rbx
    call ClaimSlot
    test eax, eax
    jz .Refuse
    mov qword [rel Threaded], 1
.Enter:
    lea rax, [rsp + 16]
    mov [rbx + CNativeTop], rax
    mov [rbx + CReplRsp], rax
    mov rcx, rbx
    call GilAcquire
    mov qword [rbx + CTryDepth], 0
    mov qword [rbx + CCbDepth], 0
    mov qword [rbx + CLastError], 0
    mov qword [rbx + CFfiVmDepth], 1
    mov rax, [rbx + CDataBase]
    mov [rbx + CR15], rax
    mov rcx, [rbx + CFfiVmPtr]
    mov [rcx], rax
    mov rax, [rbx + CRetBase]
    mov [rbx + CRbp], rax
    mov [rcx + 8], rax
    mov [rcx + 16], rax
    mov rax, rbx
    call LoadGlobals
    mov qword [rbx + CState], 0
    mov eax, 2
    pop rbx
    ret
.Refuse:
    mov eax, -1
    pop rbx
    ret

CbExit:
    cmp rcx, 1
    je .Repark
    cmp rcx, 2
    je .Leave
    ret
.Repark:
    push rax
    sub rsp, 16
    movq [rsp], xmm0
    call ThreadPark
    movq xmm0, [rsp]
    add rsp, 16
    pop rax
    ret
.Leave:
    mov rcx, [rel GilOwner]
    mov qword [rcx + CState], Idle
    mov rdx, [rcx + CDataBase]
    mov [rcx + CR15], rdx
    mov rdx, [rcx + CRetBase]
    mov [rcx + CRbp], rdx
    mov qword [rel GilOwner], 0
    ret

ThreadMarkRoots:
    push rbx
    push r12
    push rsi
    push rdi
    xor r12d, r12d
.Slot:
    cmp r12, MaxThreads
    jae .Done
    mov rax, r12
    shl rax, 4
    lea rcx, [rel CtxTab]
    mov rdx, [rcx + rax]
    test rdx, rdx
    jz .Next
    cmp rdx, -1
    je .Next
    mov rbx, [rcx + rax + 8]
    lea rsi, [rbx + CFn]
    lea rdi, [rbx + CFn + 8]
    call MarkRange
    cmp rbx, [rel GilOwner]
    je .Next
    cmp qword [rbx + CState], Parked
    jne .Next
    mov rsi, [rbx + CDataBase]
    mov rdi, [rbx + CR15]
    call MarkRange
    mov rsi, [rbx + CRetBase]
    mov rdi, [rbx + CRbp]
    call MarkRange
    mov rsi, [rbx + CRsp]
    mov rdi, [rbx + CNativeTop]
    call MarkRange
    lea rsi, [rbx + CLastError]
    lea rdi, [rbx + CLastError + 8]
    call MarkRange
    lea rsi, [rbx + CFfiSave]
    mov rdi, [rbx + CFfiN]
    lea rdi, [rsi + rdi * 8]
    call MarkRange
.Next:
    inc r12
    jmp .Slot
.Done:
    pop rdi
    pop rsi
    pop r12
    pop rbx
    ret
