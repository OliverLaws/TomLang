%include "macros.inc"
extern CbRspPtr
extern FfiVmPtr
global InitIO
global PrintString
global PrintNumber
global PrintNewLine
global ReadLine
global InputBuf
global LoadFileArg
global CheckMode
extern TestMode
global SysAlloc
global SysNowNs
global SysSleepNs
global SysSleepNsT
global SysThreadId
global SysThreadCreate
global SysThreadExit
extern CreateThread
extern ExitThread
extern GetCurrentThreadId
extern ThreadMain
extern ThreadPark
extern ThreadUnpark
extern Threaded
extern CbEnter
extern CbExit
extern QueryPerformanceCounter
extern QueryPerformanceFrequency
extern CreateWaitableTimerExW
extern SetWaitableTimer
extern WaitForSingleObject
extern Sleep
global LoadFile
global ExeDir
global MainPathPtr
global SysLoadLib
global SysGetProc
global PrimFfiCall
extern FfiPrepare
extern FfiVmDepth
extern FfiVmStack
extern CbDepth
extern CbRspStack
extern CallbackArg
extern CallbackResult
global SysAllocExec
global CallbackEntry
global PrimCallbackDone
extern FfiArgs
extern FfiClass
extern FfiN
extern FfiFinish
extern LoadLibraryA
extern AddVectoredExceptionHandler
extern SetConsoleOutputCP
extern SetConsoleCP
extern GetConsoleMode
extern SetConsoleMode
extern GetProcessHeap
extern HeapAlloc
extern HeapFree
extern GetCurrentDirectoryA
extern MemGuard
extern MemFault
global SysMemAlloc
global SysMemFree
global SysCurrentDir
extern GetProcAddress
extern GetStdHandle
extern WriteFile
extern ReadFile
extern GetCommandLineA
extern CreateFileA
extern CloseHandle
extern ExitProcess
extern VirtualAlloc
extern GetFileSizeEx
extern GetModuleFileNameA

section .bss
ProcHeap resq 1
StdOut    resq 1
StdIn     resq 1
Written   resq 1
BytesRead resq 1
NumBuf    resb 24
InputBuf  resb 4096
PathBuf   resb 1024
FileBuf   resb 16777216
CheckMode resq 1
QpcFreq resq 1
WaitTimer resq 1
WaitTimerTried resq 1
MainPathPtr resq 1
FileSize resq 1

section .data
NewlineChar  db 10
ErrOpen      db "can't open file", 10
ErrOpenLen   equ $ - ErrOpen
ErrBig       db "that file is too big (16 MB at most)", 10
ErrBigLen    equ $ - ErrBig
ErrPath      db "that file path is too long", 10
ErrPathLen   equ $ - ErrPath

section .text
InitIO:
    push rbp
    mov rbp, rsp
    and rsp, -16
    sub rsp, 64
    mov rcx, -11
    call GetStdHandle
    mov [rel StdOut], rax
    mov rcx, -10
    call GetStdHandle
    mov [rel StdIn], rax
    mov ecx, 65001
    call SetConsoleOutputCP
    mov ecx, 65001
    call SetConsoleCP
    mov rcx, [rel StdOut]
    lea rdx, [rsp + 48]
    mov dword [rdx], 0
    call GetConsoleMode
    test eax, eax
    jz .NoVT
    mov edx, [rsp + 48]
    or edx, 4
    mov rcx, [rel StdOut]
    call SetConsoleMode
.NoVT:
    mov ecx, 1
    lea rdx, [rel FaultHandler]
    call AddVectoredExceptionHandler
    call GetProcessHeap
    mov [rel ProcHeap], rax
    mov rsp, rbp
    pop rbp
    ret

FaultHandler:
    mov rax, [rcx]
    cmp dword [rax], 0xC0000005
    jne .Search
    cmp byte [rel MemGuard], 0
    je .Search
    mov rax, [rcx + 8]
    lea rdx, [rel MemFault]
    mov [rax + 0xF8], rdx
    mov eax, -1
    ret
.Search:
    xor eax, eax
    ret

SysMemAlloc:
    push rbp
    mov rbp, rsp
    and rsp, -16
    sub rsp, 64
    mov r8, rcx
    mov rcx, [rel ProcHeap]
    mov edx, 8
    call HeapAlloc
    mov rsp, rbp
    pop rbp
    ret

SysMemFree:
    push rbp
    mov rbp, rsp
    and rsp, -16
    sub rsp, 64
    mov r8, rcx
    mov rcx, [rel ProcHeap]
    xor edx, edx
    call HeapFree
    mov rsp, rbp
    pop rbp
    ret

SysCurrentDir:
    push rbp
    mov rbp, rsp
    and rsp, -16
    sub rsp, 64
    xchg rcx, rdx
    call GetCurrentDirectoryA
    mov rsp, rbp
    pop rbp
    ret

PrintString:
    push rbp
    mov rbp, rsp
    and rsp, -16
    sub rsp, 64
    mov r8, rdx
    mov rdx, rcx
    mov rcx, [rel StdOut]
    lea r9, [rel Written]
    mov qword [rsp+32], 0
    call WriteFile
    mov rsp, rbp
    pop rbp
    ret

PrintNumber:
    push rbp
    mov rbp, rsp
    and rsp, -16
    sub rsp, 64
    mov rax, rcx
    mov r11, rcx
    test rax, rax
    jns .Positive
    neg rax
.Positive:
    lea r9, [rel NumBuf + 24]
    mov r10, r9
    mov r8, 10
.Loop:
    xor edx, edx
    div r8
    add dl, '0'
    dec r9
    mov [r9], dl
    test rax, rax
    jnz .Loop
    test r11, r11
    jns .Print
    dec r9
    mov byte [r9], '-'
.Print:
    mov rcx, r9
    mov rdx, r10
    sub rdx, r9
    call PrintString
    mov rsp, rbp
    pop rbp
    ret

PrintNewLine:
    push rbp
    mov rbp, rsp
    and rsp, -16
    sub rsp, 64
    lea rcx, [rel NewlineChar]
    mov rdx, 1
    call PrintString
    mov rsp, rbp
    pop rbp
    ret

ReadLine:
    push rbp
    mov rbp, rsp
    and rsp, -16
    sub rsp, 64
    mov rcx, [rel StdIn]
    lea rdx, [rel InputBuf]
    mov r8, 4096
    lea r9, [rel BytesRead]
    mov qword [rsp+32], 0
    call ReadFile
    test eax, eax
    jz .Eof
    mov rax, [rel BytesRead]
    test rax, rax
    jz .Eof
.Trim:
    test rax, rax
    jz .Done
    lea rcx, [rel InputBuf]
    mov dl, [rcx + rax - 1]
    cmp dl, 10
    je .Cut
    cmp dl, 13
    jne .Done
.Cut:
    dec rax
    jmp .Trim
.Done:
    mov rsp, rbp
    pop rbp
    ret
.Eof:
    xor ecx, ecx
    call ExitProcess

LoadFileArg:
    push rbp
    mov rbp, rsp
    and rsp, -16
    sub rsp, 64
    call GetCommandLineA
    mov rcx, rax
    cmp byte [rcx], '"'
    jne .SkipName
    inc rcx
.SkipQuoted:
    mov al, [rcx]
    test al, al
    jz .None
    inc rcx
    cmp al, '"'
    jne .SkipQuoted
    jmp .SkipSpaces
.SkipName:
    mov al, [rcx]
    test al, al
    jz .None
    cmp al, ' '
    je .SkipSpaces
    inc rcx
    jmp .SkipName
.SkipSpaces:
    cmp byte [rcx], ' '
    jne .GotArg
    inc rcx
    jmp .SkipSpaces
.GotArg:
    cmp byte [rcx], 0
    je .None
    cmp byte [rcx], '-'
    jne .NotFlag
    cmp byte [rcx + 1], '-'
    jne .NotFlag
    cmp byte [rcx + 2], 't'
    je .TestFlag
    cmp byte [rcx + 2], 'c'
    jne .NotFlag
    mov qword [rel CheckMode], 1
    jmp .SkipFlag
.TestFlag:
    mov qword [rel TestMode], 1
.SkipFlag:
    mov al, [rcx]
    test al, al
    jz .None
    cmp al, ' '
    je .SkipSpaces
    inc rcx
    jmp .SkipFlag
.NotFlag:
    cmp dword [rcx], 'test'
    jne .NotTestWord
    cmp byte [rcx + 4], ' '
    jne .NotTestWord
    mov qword [rel TestMode], 1
    add rcx, 4
    jmp .SkipSpaces
.NotTestWord:
    lea rdx, [rel PathBuf]
    mov r8b, ' '
    cmp byte [rcx], '"'
    jne .Copy
    mov r8b, '"'
    inc rcx
.Copy:
    mov al, [rcx]
    test al, al
    jz .CopyDone
    cmp al, r8b
    je .CopyDone
    lea r9, [rel PathBuf + 1020]
    cmp rdx, r9
    jae .TooLong
    mov [rdx], al
    inc rcx
    inc rdx
    jmp .Copy
.CopyDone:
    mov byte [rdx], 0
    lea rcx, [rel PathBuf]
    mov [rel MainPathPtr], rcx
    mov edx, 0x80000000
    mov r8d, 1
    xor r9d, r9d
    mov qword [rsp+32], 3
    mov qword [rsp+40], 0x80
    mov qword [rsp+48], 0
    call CreateFileA
    cmp rax, -1
    je .Fail
    mov [rsp+56], rax
    mov rcx, rax
    lea rdx, [rel FileBuf]
    mov r8d, 16777216
    lea r9, [rel BytesRead]
    mov qword [rsp+32], 0
    call ReadFile
    mov rcx, [rsp+56]
    call CloseHandle
    cmp qword [rel BytesRead], 16777216
    jae .TooBig
    lea rax, [rel FileBuf]
    mov rdx, [rel BytesRead]
    mov rsp, rbp
    pop rbp
    ret
.None:
    xor eax, eax
    xor edx, edx
    mov rsp, rbp
    pop rbp
    ret
.TooBig:
    lea rcx, [rel ErrBig]
    mov rdx, ErrBigLen
    jmp .Say
.TooLong:
    lea rcx, [rel ErrPath]
    mov rdx, ErrPathLen
    jmp .Say
.Fail:
    lea rcx, [rel ErrOpen]
    mov rdx, ErrOpenLen
.Say:
    call PrintString
    mov ecx, 1
    call ExitProcess

SysNowNs:
    push rbp
    mov rbp, rsp
    and rsp, -16
    sub rsp, 48
    cmp qword [rel QpcFreq], 0
    jne .HaveFreq
    lea rcx, [rel QpcFreq]
    call QueryPerformanceFrequency
.HaveFreq:
    lea rcx, [rsp + 32]
    call QueryPerformanceCounter
    mov rax, [rsp + 32]
    mov rcx, 1000000000
    mul rcx
    div qword [rel QpcFreq]
    mov rsp, rbp
    pop rbp
    ret

SysSleepNs:
    lea rdx, [rel WaitTimer]
SysSleepNsT:
    push rbp
    mov rbp, rsp
    push rbx
    and rsp, -16
    sub rsp, 64
    mov rbx, rdx
    mov [rsp + 56], rcx
    cmp qword [rbx], 0
    jne .HaveTimer
    cmp qword [rel WaitTimerTried], 0
    jne .Fallback
    xor ecx, ecx
    xor edx, edx
    mov r8d, 2
    mov r9d, 0x1F0003
    call CreateWaitableTimerExW
    mov [rbx], rax
    test rax, rax
    jnz .HaveTimer
    mov qword [rel WaitTimerTried], 1
    jmp .Fallback
.HaveTimer:
    mov rax, [rsp + 56]
    xor edx, edx
    mov rcx, 100
    div rcx
    neg rax
    mov [rsp + 48], rax
    mov rcx, [rbx]
    lea rdx, [rsp + 48]
    xor r8d, r8d
    xor r9d, r9d
    mov qword [rsp + 32], 0
    mov qword [rsp + 40], 0
    call SetWaitableTimer
    test eax, eax
    jz .Fallback
    mov rcx, [rbx]
    mov edx, -1
    call WaitForSingleObject
    jmp .Done
.Fallback:
    mov rax, [rsp + 56]
    xor edx, edx
    mov rcx, 1000000
    div rcx
    mov rcx, rax
    call Sleep
.Done:
    mov rbx, [rbp - 8]
    mov rsp, rbp
    pop rbp
    ret

SysThreadId:
    push rbp
    mov rbp, rsp
    and rsp, -16
    sub rsp, 32
    call GetCurrentThreadId
    mov eax, eax
    mov rsp, rbp
    pop rbp
    ret

SysThreadCreate:
    push rbp
    mov rbp, rsp
    and rsp, -16
    sub rsp, 64
    mov r9, rcx
    xor ecx, ecx
    mov edx, 1048576
    lea r8, [rel ThreadStub]
    mov qword [rsp + 32], 0
    mov qword [rsp + 40], 0
    call CreateThread
    test rax, rax
    jz .Out
    mov rcx, rax
    call CloseHandle
    mov eax, 1
.Out:
    mov rsp, rbp
    pop rbp
    ret

ThreadStub:
    jmp ThreadMain

SysThreadExit:
    and rsp, -16
    sub rsp, 32
    xor ecx, ecx
    call ExitThread

SysAlloc:
    push rbp
    mov rbp, rsp
    and rsp, -16
    sub rsp, 64
    mov rdx, rcx
    xor ecx, ecx
    mov r8d, 0x3000
    mov r9d, 4
    call VirtualAlloc
    mov rsp, rbp
    pop rbp
    ret

LoadFile:
    push rbx
    push rsi
    push rbp
    mov rbp, rsp
    and rsp, -16
    sub rsp, 64
    mov edx, 0x80000000
    mov r8d, 1
    xor r9d, r9d
    mov qword [rsp+32], 3
    mov qword [rsp+40], 0x80
    mov qword [rsp+48], 0
    call CreateFileA
    cmp rax, -1
    je .Fail
    mov rbx, rax
    mov rcx, rbx
    lea rdx, [rel FileSize]
    call GetFileSizeEx
    test eax, eax
    jz .Close
    cmp qword [rel FileSize], 16777216
    jae .Close
    mov rdx, [rel FileSize]
    add rdx, 16
    xor ecx, ecx
    mov r8d, 0x3000
    mov r9d, 4
    call VirtualAlloc
    test rax, rax
    jz .Close
    mov rsi, rax
    mov rcx, rbx
    mov rdx, rsi
    mov r8, [rel FileSize]
    lea r9, [rel BytesRead]
    mov qword [rsp+32], 0
    call ReadFile
    mov rcx, rbx
    call CloseHandle
    mov rax, rsi
    mov rdx, [rel BytesRead]
    mov rsp, rbp
    pop rbp
    pop rsi
    pop rbx
    ret
.Close:
    mov rcx, rbx
    call CloseHandle
.Fail:
    xor eax, eax
    xor edx, edx
    mov rsp, rbp
    pop rbp
    pop rsi
    pop rbx
    ret

ExeDir:
    push rbx
    push rbp
    mov rbp, rsp
    and rsp, -16
    sub rsp, 32
    mov rbx, rcx
    mov r8, rdx
    mov rdx, rcx
    xor ecx, ecx
    call GetModuleFileNameA
.Back:
    test rax, rax
    jz .Done
    mov cl, [rbx + rax - 1]
    cmp cl, 92
    je .Done
    cmp cl, '/'
    je .Done
    dec rax
    jmp .Back
.Done:
    mov rsp, rbp
    pop rbp
    pop rbx
    ret

SysLoadLib:
    push rbp
    mov rbp, rsp
    and rsp, -16
    sub rsp, 64
    call LoadLibraryA
    mov rsp, rbp
    pop rbp
    ret

SysGetProc:
    push rbp
    mov rbp, rsp
    and rsp, -16
    sub rsp, 64
    call GetProcAddress
    mov rsp, rbp
    pop rbp
    ret

PrimFfiCall:
    add r14, 32
    mov rax, [rel FfiVmDepth]
    cmp rax, 256
    jae .NoVm
    imul rax, rax, 24
    mov rcx, [rel FfiVmPtr]
    mov [rcx + rax], r15
    mov [rcx + rax + 8], rbp
    mov [rcx + rax + 16], r13
.NoVm:
    inc qword [rel FfiVmDepth]
    call FfiPrepare
    mov r12, rax
    mov rbx, rsp
    mov rax, [rel FfiN]
    cmp rax, 4
    jae .Enough
    mov eax, 4
.Enough:
    inc rax
    and rax, -2
    shl rax, 3
    and rsp, -16
    sub rsp, rax
    lea r9, [rel FfiArgs]
    xor ecx, ecx
.Store:
    cmp rcx, [rel FfiN]
    jae .Load
    mov rdx, [r9 + rcx * 8]
    mov [rsp + rcx * 8], rdx
    inc rcx
    jmp .Store
.Load:
    xor esi, esi
    cmp qword [rel Threaded], 0
    je .Go
    call ThreadPark
    mov rsi, rax
.Go:
    mov r10, [r14 - 32]
    mov rcx, [rsp]
    mov rdx, [rsp + 8]
    mov r8, [rsp + 16]
    mov r9, [rsp + 24]
    movq xmm0, rcx
    movq xmm1, rdx
    movq xmm2, r8
    movq xmm3, r9
    call r10
    mov rsp, rbx
    test rsi, rsi
    jz .Back
    push rax
    sub rsp, 8
    movq [rsp], xmm0
    mov rcx, rsi
    call ThreadUnpark
    movq xmm0, [rsp]
    add rsp, 8
    pop rax
.Back:
    dec qword [rel FfiVmDepth]
    jmp FfiFinish

SysAllocExec:
    push rbp
    mov rbp, rsp
    and rsp, -16
    sub rsp, 64
    mov rdx, rcx
    xor ecx, ecx
    mov r8d, 0x3000
    mov r9d, 0x40
    call VirtualAlloc
    mov rsp, rbp
    pop rbp
    ret

CallbackEntry:
    mov r11, rsp
    push rbx
    push rbp
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    sub rsp, 248
    movdqu [rsp], xmm6
    movdqu [rsp + 16], xmm7
    movdqu [rsp + 32], xmm8
    movdqu [rsp + 48], xmm9
    movdqu [rsp + 64], xmm10
    movdqu [rsp + 80], xmm11
    movdqu [rsp + 96], xmm12
    movdqu [rsp + 112], xmm13
    movdqu [rsp + 128], xmm14
    movdqu [rsp + 144], xmm15
    mov [rsp + 160], rcx
    mov [rsp + 168], rdx
    mov [rsp + 176], r8
    mov [rsp + 184], r9
    movq [rsp + 192], xmm0
    movq [rsp + 200], xmm1
    movq [rsp + 208], xmm2
    movq [rsp + 216], xmm3
    mov [rsp + 224], r11
    mov [rsp + 232], rax
    mov r12, rax
    call CbEnter
    mov [rsp + 240], rax
    cmp rax, -1
    je .NoVm
    mov rax, [rel FfiVmDepth]
    test rax, rax
    jz .NoVm
    dec rax
    imul rax, rax, 24
    mov rcx, [rel FfiVmPtr]
    mov r15, [rcx + rax]
    mov rbp, [rcx + rax + 8]
    mov r13, [rcx + rax + 16]
    mov rax, [r12]
    DPush rax
    mov rbx, [r12 + 8]
    xor esi, esi
.Arg:
    cmp rsi, [rbx + 8]
    jae .Run
    mov rcx, [rbx + 24 + rsi * 8]
    cmp rsi, 4
    jae .StackArg
    cmp rcx, 2
    je .Xmm
    cmp rcx, 7
    je .Xmm
    mov rax, [rsp + 160 + rsi * 8]
    jmp .Conv
.Xmm:
    mov rax, [rsp + 192 + rsi * 8]
    jmp .Conv
.StackArg:
    mov rax, [rsp + 224]
    mov rax, [rax + 40 + rsi * 8 - 32]
.Conv:
    call CallbackArg
    DPush rax
    inc rsi
    jmp .Arg
.Run:
    mov rax, [rel CbDepth]
    cmp rax, 256
    jae .NoVm
    mov rcx, [rel CbRspPtr]
    mov [rcx + rax * 8], rsp
    inc qword [rel CbDepth]
    lea r14, [r12 + 16]
    NEXT
.NoVm:
    xor eax, eax
    jmp CallbackReturn

PrimCallbackDone:
    dec qword [rel CbDepth]
    mov rax, [rel CbDepth]
    mov rcx, [rel CbRspPtr]
    mov rsp, [rcx + rax * 8]
    mov r12, [rsp + 232]
    mov rbx, [r12 + 8]
    mov rcx, [rbx + 16]
    xor eax, eax
    test rcx, rcx
    jz CallbackReturn
    DPop rax
    call CallbackResult
CallbackReturn:
    mov rcx, [rsp + 240]
    call CbExit
    movdqu xmm6, [rsp]
    movdqu xmm7, [rsp + 16]
    movdqu xmm8, [rsp + 32]
    movdqu xmm9, [rsp + 48]
    movdqu xmm10, [rsp + 64]
    movdqu xmm11, [rsp + 80]
    movdqu xmm12, [rsp + 96]
    movdqu xmm13, [rsp + 112]
    movdqu xmm14, [rsp + 128]
    movdqu xmm15, [rsp + 144]
    add rsp, 248
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbp
    pop rbx
    ret
