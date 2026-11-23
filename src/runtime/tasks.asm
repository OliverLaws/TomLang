%include "macros.inc"
extern TryStackPtr
extern InitThreads
extern InMainThread
extern ThreadSleep
extern PrimThreadEnd
extern ThreadCount

global InitTasks
global PrimWait
global PrimSpawn
global PrimTaskEnd
global PrimTasksFinish
global TaskMarkRoots
global DataLimit
global ReturnLimit
global CurDataBase
global CurRetBase
extern SysAlloc
extern SysNowNs
extern SysSleepNs
extern DataStack
extern DataStackEnd
extern ReturnStack
extern ReturnStackEnd
extern TryStack
extern TryDepth
extern FfiVmDepth
extern CbDepth
extern MarkRange
extern Abort
extern PrimCallValue
extern PrimDrop
extern PrimBranch
extern MemCopy

%define TNext      0
%define TIp        8
%define TR15       16
%define TRbp       24
%define TR13       32
%define TWake      40
%define TInterval  48
%define TFn        56
%define TCond      64
%define TPrev      72
%define TDataBase  80
%define TDataLimit 88
%define TRetBase   96
%define TRetLimit  104
%define TTryDepth  112
%define TTrySave   120
%define TSize      4096
%define StackCells 65536
%define Forever    0x7FFFFFFFFFFFFFFF

section .bss
TaskMain    resb 128
TaskCur     resq 1
TaskCount   resq 1
TaskFree    resq 1
DataLimit   resq 1
ReturnLimit resq 1
CurDataBase resq 1
CurRetBase  resq 1
PickFrom    resq 1

section .data
ErrWaitCallback db "can't wait inside a function a DLL called"
ErrWaitCallbackLen equ $ - ErrWaitCallback
ErrTaskMemory db "not enough memory for another task"
ErrTaskMemoryLen equ $ - ErrTaskMemory
ErrSpawnThread db "task, every, after and when only work on the main thread, not inside a thread"
ErrSpawnThreadLen equ $ - ErrSpawnThread
align 8
BootTask:
    dq PrimTaskFn, PrimCallValue, 0, PrimDrop, PrimTaskEnd
BootAfter:
    dq PrimTaskWait, PrimTaskFn, PrimCallValue, 0, PrimDrop, PrimTaskEnd
BootEvery:
    dq PrimTaskWait, PrimTaskFn, PrimCallValue, 0, PrimDrop, PrimBranch, BootEvery
BootWhen:
    dq PrimTaskCond, PrimCallValue, 0, PrimTaskEdge, BootWhenPoll
    dq PrimTaskFn, PrimCallValue, 0, PrimDrop
BootWhenPoll:
    dq PrimTaskPoll, PrimBranch, BootWhen
BootTable:
    dq BootTask, BootAfter, BootEvery, BootWhen

section .text
InitTasks:
    lea rax, [rel TaskMain]
    mov [rel TaskCur], rax
    mov [rax + TNext], rax
    lea rcx, [rel DataStack]
    mov [rax + TDataBase], rcx
    mov [rel CurDataBase], rcx
    lea rcx, [rel DataStackEnd - 512]
    mov [rax + TDataLimit], rcx
    mov [rel DataLimit], rcx
    lea rcx, [rel ReturnStack]
    mov [rax + TRetBase], rcx
    mov [rel CurRetBase], rcx
    lea rcx, [rel ReturnStackEnd - 64]
    mov [rax + TRetLimit], rcx
    mov [rel ReturnLimit], rcx
    jmp InitThreads

SecondsToNs:
    movq xmm0, rax
    mov rax, 1000000000
    cvtsi2sd xmm1, rax
    mulsd xmm0, xmm1
    xorpd xmm1, xmm1
    ucomisd xmm0, xmm1
    jbe .Zero
    mov rax, 0x43D0000000000000
    movq xmm1, rax
    ucomisd xmm0, xmm1
    jae .Huge
    cvttsd2si rax, xmm0
    ret
.Zero:
    xor eax, eax
    ret
.Huge:
    mov rax, Forever / 2
    ret

PrimWait:
    cmp qword [rel FfiVmDepth], 0
    jne WaitInCallback
    cmp qword [rel CbDepth], 0
    jne WaitInCallback
    call InMainThread
    jne .InThread
    DPop rax
    call SecondsToNs
    push rax
    call SysNowNs
    pop rcx
    add rax, rcx
    mov rdx, [rel TaskCur]
    mov [rdx + TWake], rax
    jmp SwitchOut

PrimWait.InThread:
    DPop rax
    call SecondsToNs
    mov rcx, rax
    test rcx, rcx
    jz .Now
    call ThreadSleep
.Now:
    NEXT

WaitInCallback:
    lea rcx, [rel ErrWaitCallback]
    mov edx, ErrWaitCallbackLen
    jmp Abort

PrimSpawn:
    call InMainThread
    jne SpawnInThread
    mov rax, [r14]
    add r14, 8
    push rax
    mov rbx, [rel TaskFree]
    test rbx, rbx
    jz .New
    mov rcx, [rbx + TNext]
    mov [rel TaskFree], rcx
    jmp .Have
.New:
    mov rcx, TSize + StackCells * 16
    call SysAlloc
    test rax, rax
    jz .NoMemory
    mov rbx, rax
    mov qword [rbx + TTrySave], 0
.Have:
    lea rax, [rbx + TSize]
    mov [rbx + TDataBase], rax
    mov [rbx + TR15], rax
    lea rcx, [rax + StackCells * 8 - 512]
    mov [rbx + TDataLimit], rcx
    lea rax, [rbx + TSize + StackCells * 8]
    mov [rbx + TRetBase], rax
    mov [rbx + TRbp], rax
    mov [rbx + TR13], rax
    lea rcx, [rax + StackCells * 8 - 64]
    mov [rbx + TRetLimit], rcx
    mov qword [rbx + TTryDepth], 0
    mov qword [rbx + TPrev], 1
    mov qword [rbx + TCond], 0
    mov qword [rbx + TInterval], 0
    pop rax
    lea rcx, [rel BootTable]
    mov rcx, [rcx + rax * 8]
    mov [rbx + TIp], rcx
    DPop rcx
    mov [rbx + TFn], rcx
    cmp rax, 3
    je .Cond
    test rax, rax
    jz .Linked
    DPop rax
    call SecondsToNs
    mov [rbx + TInterval], rax
    jmp .Linked
.Cond:
    DPop rcx
    mov [rbx + TCond], rcx
.Linked:
    call SysNowNs
    mov [rbx + TWake], rax
    mov rcx, [rel TaskCur]
    mov rax, rcx
.FindTail:
    cmp [rax + TNext], rcx
    je .Tail
    mov rax, [rax + TNext]
    jmp .FindTail
.Tail:
    mov [rbx + TNext], rcx
    mov [rax + TNext], rbx
    inc qword [rel TaskCount]
    NEXT
.NoMemory:
    lea rcx, [rel ErrTaskMemory]
    mov edx, ErrTaskMemoryLen
    jmp Abort

PrimTaskFn:
    mov rax, [rel TaskCur]
    mov rax, [rax + TFn]
    DPush rax
    NEXT

PrimTaskCond:
    mov rax, [rel TaskCur]
    mov rax, [rax + TCond]
    DPush rax
    NEXT

PrimTaskEdge:
    DPop rax
    mov rdx, [rel TaskCur]
    mov rcx, [rdx + TPrev]
    mov [rdx + TPrev], rax
    test rax, rax
    jz .Skip
    test rcx, rcx
    jnz .Skip
    add r14, 8
    NEXT
.Skip:
    mov r14, [r14]
    NEXT

PrimTaskWait:
    mov rdx, [rel TaskCur]
    mov rax, [rdx + TWake]
    add rax, [rdx + TInterval]
    push rax
    push rdx
    call SysNowNs
    pop rdx
    pop rcx
    cmp rcx, rax
    jge .Set
    mov rcx, rax
.Set:
    mov [rdx + TWake], rcx
    jmp SwitchOut

PrimTaskPoll:
    call SysNowNs
    add rax, 16000000
    mov rdx, [rel TaskCur]
    mov [rdx + TWake], rax
    jmp SwitchOut

PrimTasksFinish:
    cmp qword [rel TaskCount], 0
    jne .Wait
    cmp qword [rel ThreadCount], 0
    jne .Threads
    NEXT
.Threads:
    mov ecx, 2000000
    call ThreadSleep
    sub r14, 8
    NEXT
.Wait:
    mov rdx, [rel TaskCur]
    mov rax, Forever
    mov [rdx + TWake], rax
    jmp SwitchOut

SaveTry:
    mov rcx, [rel TryDepth]
    mov [rbx + TTryDepth], rcx
    test rcx, rcx
    jz .Done
    cmp qword [rbx + TTrySave], 0
    jne .Have
    mov rcx, 8 * 8 * 256
    call SysAlloc
    test rax, rax
    jz .Done
    mov [rbx + TTrySave], rax
    mov rcx, [rel TryDepth]
.Have:
    mov rcx, [rel TryStackPtr]
    mov rdx, [rbx + TTrySave]
    mov r8, [rel TryDepth]
    shl r8, 6
    call MemCopy
.Done:
    ret

RestoreTry:
    mov rcx, [rbx + TTryDepth]
    mov [rel TryDepth], rcx
    test rcx, rcx
    jz .Done
    mov rcx, [rbx + TTrySave]
    mov rdx, [rel TryStackPtr]
    mov r8, [rel TryDepth]
    shl r8, 6
    call MemCopy
.Done:
    ret

SwitchOut:
    mov rbx, [rel TaskCur]
    mov [rbx + TIp], r14
    mov [rbx + TR15], r15
    mov [rbx + TRbp], rbp
    mov [rbx + TR13], r13
    call SaveTry
    mov [rel PickFrom], rbx
    jmp Pick

SpawnInThread:
    lea rcx, [rel ErrSpawnThread]
    mov edx, ErrSpawnThreadLen
    jmp Abort

PrimTaskEnd:
    call InMainThread
    jne PrimThreadEnd
    mov rbx, [rel TaskCur]
    mov rax, rbx
.FindPrev:
    mov rcx, [rax + TNext]
    cmp rcx, rbx
    je .Found
    mov rax, rcx
    jmp .FindPrev
.Found:
    mov rcx, [rbx + TNext]
    mov [rax + TNext], rcx
    mov rcx, [rel TaskFree]
    mov [rbx + TNext], rcx
    mov [rel TaskFree], rbx
    mov qword [rbx + TFn], 0
    mov qword [rbx + TCond], 0
    dec qword [rel TaskCount]
    mov [rel PickFrom], rax
    mov [rel TaskCur], rax
    jmp Pick

Pick:
    call SysNowNs
    mov r12, rax
    mov rbx, [rel PickFrom]
    mov rsi, rbx
    mov rdi, Forever
.Scan:
    mov rbx, [rbx + TNext]
    mov rax, [rbx + TWake]
    cmp rax, r12
    jle Resume
    cmp rax, rdi
    jge .NotSooner
    mov rdi, rax
.NotSooner:
    cmp rbx, rsi
    jne .Scan
    mov rax, Forever
    cmp rdi, rax
    je .OnlyForever
    mov rcx, rdi
    sub rcx, r12
    call ThreadSleep
    jmp Pick
.OnlyForever:
    lea rbx, [rel TaskMain]

Resume:
    mov [rel TaskCur], rbx
    mov r14, [rbx + TIp]
    mov r15, [rbx + TR15]
    mov rbp, [rbx + TRbp]
    mov r13, [rbx + TR13]
    mov rax, [rbx + TDataBase]
    mov [rel CurDataBase], rax
    mov rax, [rbx + TDataLimit]
    mov [rel DataLimit], rax
    mov rax, [rbx + TRetBase]
    mov [rel CurRetBase], rax
    mov rax, [rbx + TRetLimit]
    mov [rel ReturnLimit], rax
    call RestoreTry
    NEXT

TaskMarkRoots:
    push rbx
    push r12
    mov r12, [rel TaskCur]
    mov rbx, r12
.Loop:
    mov rbx, [rbx + TNext]
    cmp rbx, r12
    je .Done
    mov rsi, [rbx + TDataBase]
    mov rdi, [rbx + TR15]
    call MarkRange
    mov rsi, [rbx + TRetBase]
    mov rdi, [rbx + TRbp]
    call MarkRange
    lea rsi, [rbx + TFn]
    lea rdi, [rbx + TCond + 8]
    call MarkRange
    jmp .Loop
.Done:
    lea rsi, [r12 + TFn]
    lea rdi, [r12 + TCond + 8]
    call MarkRange
    pop r12
    pop rbx
    ret
