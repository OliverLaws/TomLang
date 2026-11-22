%include "macros.inc"

global RegisterNatives
global MemGuard
global MemFault
extern SysMemAlloc
extern SysMemFree
global PrimFfiCallPtr
extern PrimFfiCall
global FfiPrepare
global CallbackArg
global CallbackResult
global ThunkCache
global ThunkCount
extern SysAllocExec
extern CallbackEntry
extern PrimCallbackDone
extern PrimCallValue
global FfiArgs
global FfiClass
global FfiN
global StructToC
global StructFromC
global FfiFinish
extern Compile
extern CreateEntry
extern Here
extern DictHere
extern Latest
extern Alloc
extern PermAlloc
extern MakeTextFrom
extern PrimExit
extern PrimLit
extern Abort

%define TNone 0
%define TNum  1
%define TText 2
%define TBool 3
%define TDec  4
%define SigCells 67

%macro NativeFn 4
    dq %2, %3, %4, %%Name, %%End - %%Name
[section .strs]
%%Name: db %1
%%End:
__SECT__
%endmacro

%macro Param 2-3 0
    dq %1, %%Name, %%End - %%Name, %3
[section .strs]
%%Name: db %2
%%End:
__SECT__
%endmacro

section .bss
FfiArgs resq 20
FfiClass resq 20
FfiN resq 1
FfiHidden resq 1
FfiPack resq 2
ThunkCache resq 3 * 256
ThunkCount resq 1
MemList resq 1
MemCount resq 1
MemCap resq 1
ThunkMem resq 1
ThunkTop resq 1

section .data
ErrThunks db "too many different functions given to DLLs (256 at most)"
ErrThunksLen equ $ - ErrThunks
ErrMemSize    db "memory needs a size from 1 to 1000000000"
ErrMemSizeLen equ $ - ErrMemSize
ErrBadAddr db "can't read or write memory at that address"
ErrBadAddrLen equ $ - ErrBadAddr
ErrFreeMem db "freeMemory needs an address that came from memory()"
ErrFreeMemLen equ $ - ErrFreeMem
MemGuard db 0

align 8
NativeTable:
    NativeFn "memory", PrimMemory, TNum, 1
    Param TNum, "size"
    NativeFn "freeMemory", PrimFreeMemory, TNone, 1
    Param TNum, "address"
    NativeFn "readByte", PrimReadByte, TNum, 1
    Param TNum, "address"
    NativeFn "writeByte", PrimWriteByte, TNone, 2
    Param TNum, "address"
    Param TNum, "value"
    NativeFn "read16", PrimRead16, TNum, 1
    Param TNum, "address"
    NativeFn "write16", PrimWrite16, TNone, 2
    Param TNum, "address"
    Param TNum, "value"
    NativeFn "read32", PrimRead32, TNum, 1
    Param TNum, "address"
    NativeFn "write32", PrimWrite32, TNone, 2
    Param TNum, "address"
    Param TNum, "value"
    NativeFn "read64", PrimRead64, TNum, 1
    Param TNum, "address"
    NativeFn "write64", PrimWrite64, TNone, 2
    Param TNum, "address"
    Param TNum, "value"
    NativeFn "readFloat", PrimReadFloat, TDec, 1
    Param TNum, "address"
    NativeFn "writeFloat", PrimWriteFloat, TNone, 2
    Param TNum, "address"
    Param TDec, "value"
    NativeFn "readDecimal", PrimReadDouble, TDec, 1
    Param TNum, "address"
    NativeFn "writeDecimal", PrimWriteDouble, TNone, 2
    Param TNum, "address"
    Param TDec, "value"
    NativeFn "readText", PrimReadText, TText, 2
    Param TNum, "address"
    Param TNum, "length", MinusOneThunk
    NativeFn "writeText", PrimWriteText, TNone, 2
    Param TNum, "address"
    Param TText, "value"
    NativeFn "copyBytes", PrimCopyBytes, TNone, 3
    Param TNum, "from"
    Param TNum, "to"
    Param TNum, "count"
    NativeFn "byteLength", PrimByteLength, TNum, 1
    Param TText, "source"
    dq 0

MinusOneThunk:
    dq PrimLit, -1, PrimExit

section .text
RegisterNatives:
    push rbx
    push rsi
    push rdi
    push r12
    lea rbx, [rel NativeTable]
    mov r12, [rel Here]
.Next:
    cmp qword [rbx], 0
    je .Done
    mov rax, [rel DictHere]
    mov [rel Here], rax
    mov rcx, [rbx + 24]
    mov rdx, [rbx + 32]
    call CreateEntry
    mov rdi, [rel Latest]
    mov byte [rdi + 16], 4
    mov esi, SigCells
.Sig:
    xor ecx, ecx
    call Compile
    dec esi
    jnz .Sig
    mov rsi, [rel Here]
    mov [rdi + 8], rsi
    mov rax, [rbx + 8]
    mov [rsi - 8], rax
    mov rcx, [rbx + 16]
    mov [rsi - 16], rcx
    lea rdi, [rbx + 40]
    xor edx, edx
.Params:
    cmp rdx, rcx
    jae .ParamsDone
    mov r8, rdx
    shl r8, 3
    neg r8
    mov rax, [rdi]
    mov [rsi - 24 + r8], rax
    shl r8, 1
    mov rax, [rdi + 8]
    mov [rsi - 288 + r8], rax
    mov rax, [rdi + 16]
    mov [rsi - 296 + r8], rax
    sar r8, 1
    mov rax, [rdi + 24]
    mov [rsi - 152 + r8], rax
    add rdi, 32
    inc rdx
    jmp .Params
.ParamsDone:
    mov rcx, [rbx]
    call Compile
    cmp qword [rbx + 8], TNone
    jne .HasResult
    lea rcx, [rel PrimLit]
    call Compile
    xor ecx, ecx
    call Compile
.HasResult:
    lea rcx, [rel PrimExit]
    call Compile
    mov rax, [rel Here]
    mov [rel DictHere], rax
    mov rbx, rdi
    jmp .Next
.Done:
    mov [rel Here], r12
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

MemTrack:
    push rbx
    mov rbx, rcx
    mov rax, [rel MemCount]
    cmp rax, [rel MemCap]
    jb .Room
    mov rcx, [rel MemCap]
    shl rcx, 1
    jnz .Grow
    mov ecx, 256
.Grow:
    push rcx
    push rcx
    shl rcx, 3
    call PermAlloc
    pop rcx
    pop rcx
    mov rdx, [rel MemList]
    xor r8d, r8d
.Copy:
    cmp r8, [rel MemCount]
    jae .Copied
    mov r9, [rdx + r8 * 8]
    mov [rax + r8 * 8], r9
    inc r8
    jmp .Copy
.Copied:
    mov [rel MemList], rax
    mov [rel MemCap], rcx
.Room:
    mov rax, [rel MemCount]
    mov rdx, [rel MemList]
    mov [rdx + rax * 8], rbx
    inc qword [rel MemCount]
    pop rbx
    ret

MemUntrack:
    xor eax, eax
    mov rdx, [rel MemList]
    xor r8d, r8d
.Find:
    cmp r8, [rel MemCount]
    jae .No
    cmp [rdx + r8 * 8], rcx
    je .Found
    inc r8
    jmp .Find
.Found:
    dec qword [rel MemCount]
    mov r9, [rel MemCount]
    mov r9, [rdx + r9 * 8]
    mov [rdx + r8 * 8], r9
    mov eax, 1
.No:
    ret

MemFault:
    mov byte [rel MemGuard], 0
    lea rcx, [rel ErrBadAddr]
    mov edx, ErrBadAddrLen
    jmp Abort

PrimFreeMemory:
    DPop rcx
    test rcx, rcx
    jz .Done
    push rcx
    push rcx
    call MemUntrack
    pop rcx
    pop rcx
    test eax, eax
    jz .Bad
    call SysMemFree
    test rax, rax
    jz .Bad
.Done:
    NEXT
.Bad:
    lea rcx, [rel ErrFreeMem]
    mov edx, ErrFreeMemLen
    jmp Abort

PrimFfiCallPtr:
    mov rcx, [r14 + 8]
    lea rax, [rcx * 8 + 8]
    mov rdx, r15
    sub rdx, rax
    mov rax, [rdx]
    cmp rax, 65536
    jb .BadAddr
    mov [r14], rax
.Shift:
    test rcx, rcx
    jz .Shifted
    mov r8, [rdx + 8]
    mov [rdx], r8
    add rdx, 8
    dec rcx
    jmp .Shift
.Shifted:
    sub r15, 8
    jmp PrimFfiCall
.BadAddr:
    lea rcx, [rel ErrBadAddr]
    mov edx, ErrBadAddrLen
    jmp Abort

PrimMemory:
    DPop rcx
    cmp rcx, 1
    jl .Bad
    cmp rcx, 1000000000
    jg .Bad
    call SysMemAlloc
    test rax, rax
    jz .Bad
    push rax
    push rax
    mov rcx, rax
    call MemTrack
    pop rax
    pop rax
    DPush rax
    NEXT
.Bad:
    lea rcx, [rel ErrMemSize]
    mov edx, ErrMemSizeLen
    jmp Abort

PrimReadByte:
    mov byte [rel MemGuard], 1
    DPop rax
    movzx eax, byte [rax]
    DPush rax
    mov byte [rel MemGuard], 0
    NEXT

PrimWriteByte:
    mov byte [rel MemGuard], 1
    DPop rdx
    DPop rax
    mov [rax], dl
    mov byte [rel MemGuard], 0
    NEXT

PrimRead16:
    mov byte [rel MemGuard], 1
    DPop rax
    movzx eax, word [rax]
    DPush rax
    mov byte [rel MemGuard], 0
    NEXT

PrimWrite16:
    mov byte [rel MemGuard], 1
    DPop rdx
    DPop rax
    mov [rax], dx
    mov byte [rel MemGuard], 0
    NEXT

PrimRead32:
    mov byte [rel MemGuard], 1
    DPop rax
    mov eax, [rax]
    DPush rax
    mov byte [rel MemGuard], 0
    NEXT

PrimWrite32:
    mov byte [rel MemGuard], 1
    DPop rdx
    DPop rax
    mov [rax], edx
    mov byte [rel MemGuard], 0
    NEXT

PrimRead64:
    mov byte [rel MemGuard], 1
    DPop rax
    mov rax, [rax]
    DPush rax
    mov byte [rel MemGuard], 0
    NEXT

PrimWrite64:
    mov byte [rel MemGuard], 1
    DPop rdx
    DPop rax
    mov [rax], rdx
    mov byte [rel MemGuard], 0
    NEXT

PrimReadFloat:
    mov byte [rel MemGuard], 1
    DPop rax
    cvtss2sd xmm0, [rax]
    movq rax, xmm0
    DPush rax
    mov byte [rel MemGuard], 0
    NEXT

PrimWriteFloat:
    mov byte [rel MemGuard], 1
    DPop rdx
    DPop rax
    movq xmm0, rdx
    cvtsd2ss xmm0, xmm0
    movd [rax], xmm0
    mov byte [rel MemGuard], 0
    NEXT

PrimReadDouble:
    mov byte [rel MemGuard], 1
    DPop rax
    mov rax, [rax]
    DPush rax
    mov byte [rel MemGuard], 0
    NEXT

PrimWriteDouble:
    mov byte [rel MemGuard], 1
    DPop rdx
    DPop rax
    mov [rax], rdx
    mov byte [rel MemGuard], 0
    NEXT

PrimReadText:
    mov byte [rel MemGuard], 1
    DPop rdx
    DPop rcx
    test rdx, rdx
    jns .Have
    xor edx, edx
.Len:
    cmp byte [rcx + rdx], 0
    je .Have
    inc rdx
    jmp .Len
.Have:
    call MakeTextFrom
    DPush rax
    mov byte [rel MemGuard], 0
    NEXT

PrimWriteText:
    mov byte [rel MemGuard], 1
    DPop rsi
    DPop rdi
    mov rcx, [rsi]
    add rsi, 8
    rep movsb
    mov byte [rdi], 0
    mov byte [rel MemGuard], 0
    NEXT

PrimByteLength:
    mov rax, [r15 - 8]
    mov rax, [rax]
    mov [r15 - 8], rax
    NEXT

PrimCopyBytes:
    mov byte [rel MemGuard], 1
    DPop rcx
    DPop rdi
    DPop rsi
    test rcx, rcx
    jle .Done
    rep movsb
.Done:
    mov byte [rel MemGuard], 0
    NEXT

StructToC:
    push rbx
    push r12
    push r13
    mov r12, rsi
    mov r13, rdi
    mov rbx, rdx
    xor ecx, ecx
.Field:
    cmp rcx, [rbx + 24]
    jae .Done
    mov rax, rcx
    shl rax, 5
    lea r8, [rbx + 40 + rax]
    mov r9, [r8 + 16]
    mov rax, [r12 + r9 * 8]
    mov r10, [r8 + 8]
    add r10, r13
    mov r11, [r8]
    cmp r11, 1
    je .Byte
    cmp r11, 8
    je .Bool
    cmp r11, 2
    je .Short
    cmp r11, 3
    je .Int
    cmp r11, 4
    je .Int
    cmp r11, 6
    je .Float
    cmp r11, 9
    je .Nested
    mov [r10], rax
    jmp .Next
.Byte:
    mov [r10], al
    jmp .Next
.Bool:
    test rax, rax
    setnz byte [r10]
    jmp .Next
.Short:
    mov [r10], ax
    jmp .Next
.Int:
    mov [r10], eax
    jmp .Next
.Float:
    movq xmm0, rax
    cvtsd2ss xmm0, xmm0
    movd [r10], xmm0
    jmp .Next
.Nested:
    push rcx
    mov rsi, rax
    mov rdi, r10
    mov rdx, [r8 + 24]
    call StructToC
    pop rcx
.Next:
    inc rcx
    jmp .Field
.Done:
    pop r13
    pop r12
    pop rbx
    ret

StructFromC:
    push rbx
    push r12
    push r13
    mov r12, rsi
    mov rbx, rdx
    mov rcx, [rbx + 24]
    shl rcx, 3
    push rcx
    call Alloc
    pop rcx
    mov r13, rax
    xor ecx, ecx
.Field:
    cmp rcx, [rbx + 24]
    jae .Done
    mov rax, rcx
    shl rax, 5
    lea r8, [rbx + 40 + rax]
    mov r10, [r8 + 8]
    add r10, r12
    mov r11, [r8]
    cmp r11, 1
    je .Byte
    cmp r11, 8
    je .Bool
    cmp r11, 2
    je .Short
    cmp r11, 3
    je .Int
    cmp r11, 4
    je .UInt
    cmp r11, 6
    je .Float
    cmp r11, 9
    je .Nested
    mov rax, [r10]
    jmp .Store
.Byte:
    movzx eax, byte [r10]
    jmp .Store
.Bool:
    movzx eax, byte [r10]
    test eax, eax
    setnz al
    jmp .Store
.Short:
    movsx rax, word [r10]
    jmp .Store
.Int:
    movsxd rax, dword [r10]
    jmp .Store
.UInt:
    mov eax, [r10]
    jmp .Store
.Float:
    cvtss2sd xmm0, [r10]
    movq rax, xmm0
    jmp .Store
.Nested:
    push rcx
    push r8
    mov rsi, r10
    mov rdx, [r8 + 24]
    call StructFromC
    pop r8
    pop rcx
.Store:
    mov r9, [r8 + 16]
    mov [r13 + r9 * 8], rax
    inc rcx
    jmp .Field
.Done:
    mov rax, r13
    pop r13
    pop r12
    pop rbx
    ret

SmallStruct:
    mov rax, [rdx + 8]
    cmp rax, 1
    je .Yes
    cmp rax, 2
    je .Yes
    cmp rax, 4
    je .Yes
    cmp rax, 8
    je .Yes
    xor eax, eax
    ret
.Yes:
    mov eax, 1
    ret

FfiPrepare:
    push rbx
    push r12
    push r13
    push rsi
    push rdi
    mov r11, [r14 - 24]
    mov rax, r11
    shl rax, 3
    mov r12, r15
    sub r12, rax
    mov r13, [r14 - 16]
    xor ebx, ebx
    mov qword [rel FfiHidden], 0
    mov rdx, [r14 - 8]
    cmp rdx, 4096
    jb .Args
    call SmallStruct
    test eax, eax
    jnz .Args
    mov rdx, [r14 - 8]
    mov rcx, [rdx + 8]
    push r11
    call Alloc
    pop r11
    mov [rel FfiHidden], rax
    lea rcx, [rel FfiArgs]
    mov [rcx], rax
    lea rcx, [rel FfiClass]
    mov qword [rcx], 0
    inc rbx
.Args:
    xor ecx, ecx
.Loop:
    cmp rcx, r11
    jae .Done
    mov rdx, [r13 + rcx * 8]
    mov rax, [r12 + rcx * 8]
    xor r9d, r9d
    cmp rdx, 4096
    jae .Desc
    cmp rdx, 1
    je .Double
    cmp rdx, 2
    je .Text
    cmp rdx, 3
    je .Float
    jmp .Put
.Double:
    mov r9d, 1
    jmp .Put
.Float:
    movq xmm0, rax
    cvtsd2ss xmm0, xmm0
    movd eax, xmm0
    mov r9d, 1
    jmp .Put
.Text:
    push rcx
    push r11
    mov rsi, rax
    mov rcx, [rsi]
    inc rcx
    push rsi
    call Alloc
    pop rsi
    mov rdi, rax
    mov rcx, [rsi]
    add rsi, 8
    mov rdx, rdi
    rep movsb
    mov byte [rdi], 0
    mov rax, rdx
    pop r11
    pop rcx
    xor r9d, r9d
    jmp .Put
.Desc:
    cmp qword [rdx], 2
    je .Callback
    push rcx
    push r11
    push rdx
    push rax
    call SmallStruct
    test eax, eax
    jz .Big
    mov qword [rel FfiPack], 0
    pop rsi
    pop rdx
    lea rdi, [rel FfiPack]
    call StructToC
    mov rax, [rel FfiPack]
    pop r11
    pop rcx
    xor r9d, r9d
    jmp .Put
.Big:
    mov rdx, [rsp + 8]
    mov rcx, [rdx + 8]
    call Alloc
    mov rdi, rax
    pop rsi
    pop rdx
    push rdi
    call StructToC
    pop rax
    pop r11
    pop rcx
    xor r9d, r9d
    jmp .Put
.Callback:
    push rcx
    push r11
    mov rcx, rax
    call MakeThunk
    pop r11
    pop rcx
    xor r9d, r9d
.Put:
    mov [r12 + rcx * 8], rax
    lea rdx, [rel FfiArgs]
    mov [rdx + rbx * 8], rax
    lea rdx, [rel FfiClass]
    mov [rdx + rbx * 8], r9
    inc rbx
    inc rcx
    jmp .Loop
.Done:
    mov [rel FfiN], rbx
    mov rax, [rel FfiHidden]
    pop rdi
    pop rsi
    pop r13
    pop r12
    pop rbx
    ret

FfiFinish:
    mov rcx, [r14 - 24]
    shl rcx, 3
    sub r15, rcx
    mov rcx, [r14 - 8]
    cmp rcx, 4096
    jae .Struct
    cmp rcx, 1
    je .Int
    cmp rcx, 2
    je .Dbl
    cmp rcx, 3
    je .Bool
    cmp rcx, 4
    je .Text
    cmp rcx, 5
    je .Int32
    cmp rcx, 6
    je .UInt32
    cmp rcx, 7
    je .Float
    test rcx, rcx
    jnz .Unknown
    mov qword [r15], 0
    add r15, 8
.Unknown:
    NEXT
.Struct:
    mov rdx, rcx
    mov rsi, r12
    test rsi, rsi
    jnz .FromBuf
    mov [rel FfiPack], rax
    lea rsi, [rel FfiPack]
.FromBuf:
    call StructFromC
    DPush rax
    NEXT
.Int:
    DPush rax
    NEXT
.Dbl:
    movq rax, xmm0
    DPush rax
    NEXT
.Bool:
    test eax, eax
    setnz al
    movzx eax, al
    DPush rax
    NEXT
.Int32:
    movsxd rax, eax
    DPush rax
    NEXT
.UInt32:
    mov eax, eax
    DPush rax
    NEXT
.Float:
    cvtss2sd xmm0, xmm0
    movq rax, xmm0
    DPush rax
    NEXT
.Text:
    mov rcx, rax
    xor edx, edx
    test rcx, rcx
    jz .Make
.Len:
    cmp byte [rcx + rdx], 0
    je .Make
    inc rdx
    jmp .Len
.Make:
    call MakeTextFrom
    DPush rax
    NEXT

MakeThunk:
    push rbx
    push rsi
    push rdi
    xor eax, eax
    lea rsi, [rel ThunkCache]
.Find:
    cmp rax, [rel ThunkCount]
    jae .New
    mov rdi, rax
    imul rdi, rdi, 24
    cmp [rsi + rdi], rcx
    jne .Next
    cmp [rsi + rdi + 8], rdx
    jne .Next
    mov rax, [rsi + rdi + 16]
    jmp .Out
.Next:
    inc rax
    jmp .Find
.New:
    cmp qword [rel ThunkCount], 256
    jae .Full
    push rcx
    push rdx
    cmp qword [rel ThunkMem], 0
    jne .HaveMem
    mov ecx, 65536
    call SysAllocExec
    test rax, rax
    jz .Full
    mov [rel ThunkMem], rax
    mov [rel ThunkTop], rax
.HaveMem:
    mov ecx, 48
    call PermAlloc
    mov rbx, rax
    pop rdx
    pop rcx
    mov [rbx], rcx
    mov [rbx + 8], rdx
    lea rax, [rel PrimCallValue]
    mov [rbx + 16], rax
    mov rax, [rdx + 8]
    mov [rbx + 24], rax
    lea rax, [rel PrimCallbackDone]
    mov [rbx + 32], rax
    mov rdi, [rel ThunkTop]
    mov word [rdi], 0xB848
    mov [rdi + 2], rbx
    mov word [rdi + 10], 0xBA49
    lea rax, [rel CallbackEntry]
    mov [rdi + 12], rax
    mov byte [rdi + 20], 0x41
    mov byte [rdi + 21], 0xFF
    mov byte [rdi + 22], 0xE2
    add qword [rel ThunkTop], 32
    lea rsi, [rel ThunkCache]
    mov rax, [rel ThunkCount]
    imul rax, rax, 24
    mov [rsi + rax], rcx
    mov [rsi + rax + 8], rdx
    mov [rsi + rax + 16], rdi
    inc qword [rel ThunkCount]
    mov rax, rdi
.Out:
    pop rdi
    pop rsi
    pop rbx
    ret
.Full:
    lea rcx, [rel ErrThunks]
    mov edx, ErrThunksLen
    jmp Abort

CallbackArg:
    cmp rcx, 2
    je .Done
    cmp rcx, 7
    je .Float
    cmp rcx, 5
    je .Int32
    cmp rcx, 6
    je .UInt32
    cmp rcx, 3
    je .Bool
    cmp rcx, 4
    je .Text
.Done:
    ret
.Float:
    movd xmm0, eax
    cvtss2sd xmm0, xmm0
    movq rax, xmm0
    ret
.Int32:
    movsxd rax, eax
    ret
.UInt32:
    mov eax, eax
    ret
.Bool:
    test eax, eax
    setnz al
    movzx eax, al
    ret
.Text:
    mov rcx, rax
    xor edx, edx
    test rcx, rcx
    jz .Make
.Len:
    cmp byte [rcx + rdx], 0
    je .Make
    inc rdx
    jmp .Len
.Make:
    jmp MakeTextFrom

CallbackResult:
    cmp rcx, 2
    je .Double
    cmp rcx, 7
    je .Float
    cmp rcx, 4
    je .Text
    ret
.Double:
    movq xmm0, rax
    ret
.Float:
    movq xmm0, rax
    cvtsd2ss xmm0, xmm0
    ret
.Text:
    push rsi
    push rdi
    mov rsi, rax
    mov rcx, [rsi]
    inc rcx
    push rsi
    call PermAlloc
    pop rsi
    mov rdi, rax
    mov rcx, [rsi]
    add rsi, 8
    mov rdx, rdi
    rep movsb
    mov byte [rdi], 0
    mov rax, rdx
    pop rdi
    pop rsi
    ret
