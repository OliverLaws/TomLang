%include "macros.inc"

global InitHeap
global Alloc
global AllocAtomic
global AllocLike
global PrimNoPtrs
extern U8Text
extern LetterCache
global PermAlloc
global Collect
global StackBase
global GcStress
global GcCount
extern SysAlloc
extern Abort
extern DataStack
extern CurDataBase
extern CurRetBase
extern TaskMarkRoots
extern ThreadMarkRoots
global MarkRange
extern ReturnStack
extern DataSpace
extern DataHere
extern LastError
extern ThunkCache
extern FfiArgs

%define Free 2
%define Mark 1
%define NoPtrs 4
%define HeapSize (1 << 30)
%define PermSize (64 << 20)
%define MarkMax (1 << 20)

section .data
ErrMemory    db "out of memory (the program is keeping more than 1 GB of data)"
ErrMemoryLen equ $ - ErrMemory
Threshold    dq 32 << 20

section .bss
HeapStart   resq 1
HeapTop     resq 1
HeapLimit   resq 1
Bitmap      resq 1
PermHere    resq 1
PermEnd     resq 1
MarkStack   resq 1
MarkTop     resq 1
MarkOver    resq 1
AllocBytes  resq 1
LiveBytes   resq 1
StackBase   resq 1
GcStress    resq 1
AtomicReq   resq 1
GcCount     resq 1
InGc        resq 1
FreeSmall   resq 64
FreeLarge   resq 1
PermSpace   resb 16777216

section .text
InitHeap:
    sub rsp, 40
    mov rcx, HeapSize
    call SysAlloc
    test rax, rax
    jz .Fail
    mov [rel HeapStart], rax
    mov [rel HeapTop], rax
    mov rcx, HeapSize
    add rax, rcx
    mov [rel HeapLimit], rax
    mov rcx, HeapSize / 128
    call SysAlloc
    test rax, rax
    jz .Fail
    mov [rel Bitmap], rax
    mov rcx, MarkMax * 8
    call SysAlloc
    test rax, rax
    jz .Fail
    mov [rel MarkStack], rax
    mov rcx, PermSize
    call SysAlloc
    test rax, rax
    jz .StaticPerm
    mov [rel PermHere], rax
    mov rcx, PermSize
    add rax, rcx
    mov [rel PermEnd], rax
    add rsp, 40
    ret
.StaticPerm:
    lea rax, [rel PermSpace]
    mov [rel PermHere], rax
    add rax, 16777216
    mov [rel PermEnd], rax
    add rsp, 40
    ret
.Fail:
    add rsp, 40
    jmp OutOfMemory

OutOfMemory:
    lea rcx, [rel ErrMemory]
    mov edx, ErrMemoryLen
    jmp Abort

PermAlloc:
    mov rax, [rel PermHere]
    add rcx, 15
    jc OutOfMemory
    and rcx, -16
    mov r8, [rel PermEnd]
    sub r8, rax
    cmp rcx, r8
    ja OutOfMemory
    lea r8, [rax + rcx]
    mov [rel PermHere], r8
    ret

PrimNoPtrs:
    mov rax, [r15 - 8]
    test rax, rax
    jz .Done
    mov rax, [rax + 16]
    test rax, rax
    jz .Done
    mov rsi, rax
    call FindBlock
    test rax, rax
    jz .Done
    lea rcx, [rax + 8]
    cmp rcx, rsi
    jne .Done
    or qword [rax], NoPtrs
.Done:
    NEXT

SetBit:
    sub r8, [rel HeapStart]
    shr r8, 4
    mov r9, [rel Bitmap]
    bts [r9], r8
    ret

ClearBit:
    sub r8, [rel HeapStart]
    shr r8, 4
    mov r9, [rel Bitmap]
    btr [r9], r8
    ret

AllocLike:
    test rdx, rdx
    jz Alloc
    test qword [rdx - 8], NoPtrs
    jz Alloc
AllocAtomic:
    mov qword [rel AtomicReq], 1
    jmp AllocAny

Alloc:
    mov qword [rel AtomicReq], 0
AllocAny:
    push rdx
    push rsi
    push rdi
    push r9
    push r10
    push r11
    add rcx, 8 + 15
    jc OutOfMemory
    and rcx, -16
    mov rax, HeapSize
    cmp rcx, rax
    jae OutOfMemory
    add [rel AllocBytes], rcx
    cmp qword [rel GcStress], 0
    jne .Collect
    mov rax, [rel AllocBytes]
    cmp rax, [rel Threshold]
    jb .Try
.Collect:
    cmp qword [rel InGc], 0
    jne .Try
    push rcx
    mov qword [rel U8Text], 0
    call Collect
    mov qword [rel U8Text], 0
    pop rcx
.Try:
    cmp rcx, 1024
    ja .Large
    mov rdx, rcx
    shr rdx, 4
    dec rdx
    lea rsi, [rel FreeSmall]
    mov rax, [rsi + rdx * 8]
    test rax, rax
    jz .Large
    mov rdi, [rax + 8]
    mov [rsi + rdx * 8], rdi
    jmp .Got
.Large:
    lea rsi, [rel FreeLarge]
.Walk:
    mov rax, [rsi]
    test rax, rax
    jz .Bump
    mov rdx, [rax]
    and rdx, -16
    cmp rdx, rcx
    jae .Fit
    lea rsi, [rax + 8]
    jmp .Walk
.Fit:
    mov rdi, [rax + 8]
    mov [rsi], rdi
    mov rdi, rdx
    sub rdi, rcx
    cmp rdi, 32
    jb .Whole
    lea r8, [rax + rcx]
    mov r10, rdi
    or r10, Free
    mov [r8], r10
    push rax
    push rcx
    mov r11, r8
    call SetBit
    mov r8, r11
    pop rcx
    pop rax
    push rax
    push rcx
    mov rcx, r8
    mov rdx, rdi
    call AddFree
    pop rcx
    pop rax
    jmp .Got
.Whole:
    mov rcx, rdx
    jmp .Got
.Bump:
    mov rax, [rel HeapTop]
    mov rdx, [rel HeapLimit]
    sub rdx, rax
    cmp rcx, rdx
    jbe .BumpOk
    cmp qword [rel InGc], 0
    jne OutOfMemory
    cmp qword [rel AllocBytes], 0
    je OutOfMemory
    push rcx
    call Collect
    pop rcx
    mov qword [rel AllocBytes], 0
    jmp .Try
.BumpOk:
    lea rdx, [rax + rcx]
    mov [rel HeapTop], rdx
    mov r8, rax
    sub r8, [rel HeapStart]
    shr r8, 4
    mov r9, [rel Bitmap]
    bts [r9], r8
.Got:
    cmp qword [rel AtomicReq], 0
    jne .NoZero
    mov [rax], rcx
    lea rdi, [rax + 8]
    sub rcx, 8
    cmp rcx, 56
    ja .BigZero
    xor edx, edx
.SmallZero:
    mov qword [rdi + rdx], 0
    add rdx, 8
    cmp rdx, rcx
    jb .SmallZero
    mov rax, rdi
    jmp .Out
.BigZero:
    push rdi
    shr rcx, 3
    xor eax, eax
    rep stosq
    pop rax
    jmp .Out
.NoZero:
    or rcx, NoPtrs
    mov [rax], rcx
    add rax, 8
.Out:
    pop r11
    pop r10
    pop r9
    pop rdi
    pop rsi
    pop rdx
    ret

AddFree:
    cmp rdx, 1024
    ja .Large
    shr rdx, 4
    dec rdx
    lea r8, [rel FreeSmall]
    mov r9, [r8 + rdx * 8]
    mov [rcx + 8], r9
    mov [r8 + rdx * 8], rcx
    ret
.Large:
    mov r9, [rel FreeLarge]
    mov [rcx + 8], r9
    mov [rel FreeLarge], rcx
    ret

FindBlock:
    cmp rax, [rel HeapStart]
    jb .No
    cmp rax, [rel HeapTop]
    jae .No
    mov r8, rax
    sub r8, [rel HeapStart]
    shr r8, 4
    mov r9, r8
    shr r9, 6
    mov ecx, r8d
    and ecx, 63
    mov r10, [rel Bitmap]
    mov r11, [r10 + r9 * 8]
    mov edx, 2
    shl rdx, cl
    dec rdx
    and r11, rdx
.Search:
    test r11, r11
    jnz .Found
    test r9, r9
    jz .No
    dec r9
    mov r11, [r10 + r9 * 8]
    jmp .Search
.Found:
    bsr rdx, r11
    shl r9, 6
    add r9, rdx
    shl r9, 4
    add r9, [rel HeapStart]
    mov rdx, [r9]
    test rdx, Free
    jnz .No
    and rdx, -16
    add rdx, r9
    cmp rax, rdx
    jae .No
    mov rax, r9
    ret
.No:
    xor eax, eax
    ret

MarkValue:
    call FindBlock
    test rax, rax
    jz .Done
    test qword [rax], Mark
    jnz .Done
    or qword [rax], Mark
    mov rdx, [rel MarkTop]
    cmp rdx, MarkMax
    jae .Over
    mov r8, [rel MarkStack]
    mov [r8 + rdx * 8], rax
    inc qword [rel MarkTop]
.Done:
    ret
.Over:
    mov qword [rel MarkOver], 1
    ret

MarkRange:
    and rsi, -8
.Loop:
    cmp rsi, rdi
    jae .Done
    mov rax, [rsi]
    call MarkValue
    add rsi, 8
    jmp .Loop
.Done:
    ret

Drain:
.Loop:
    mov rax, [rel MarkTop]
    test rax, rax
    jz .Done
    dec rax
    mov [rel MarkTop], rax
    mov r8, [rel MarkStack]
    mov rbx, [r8 + rax * 8]
    mov rdi, [rbx]
    test rdi, NoPtrs
    jnz .Loop
    and rdi, -16
    add rdi, rbx
    lea rsi, [rbx + 8]
    call MarkRange
    jmp .Loop
.Done:
    cmp qword [rel MarkOver], 0
    je .Out
    mov qword [rel MarkOver], 0
    mov rbx, [rel HeapStart]
.Rescan:
    cmp rbx, [rel HeapTop]
    jae .Loop
    mov rdx, [rbx]
    mov rdi, rdx
    and rdi, -16
    test rdx, Mark
    jz .Skip
    test rdx, Free
    jnz .Skip
    test rdx, NoPtrs
    jnz .Skip
    push rbx
    push rdi
    add rdi, rbx
    lea rsi, [rbx + 8]
    call MarkRange
    pop rdi
    pop rbx
.Skip:
    add rbx, rdi
    jmp .Rescan
.Out:
    ret

Collect:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push rbp
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15
    mov qword [rel U8Text], 0
    lea rdi, [rel LetterCache]
    mov ecx, LetterCacheQ
    xor eax, eax
    rep stosq
    mov qword [rel InGc], 1
    inc qword [rel GcCount]
    mov qword [rel MarkTop], 0
    mov qword [rel MarkOver], 0
    mov rsi, [rel CurDataBase]
    mov rdi, r15
    call MarkRange
    mov rsi, [rel CurRetBase]
    mov rdi, rbp
    call MarkRange
    call TaskMarkRoots
    call ThreadMarkRoots
    lea rsi, [rel DataSpace]
    mov rdi, [rel DataHere]
    call MarkRange
    mov rsi, rsp
    mov rdi, [rel StackBase]
    call MarkRange
    lea rsi, [rel LastError]
    lea rdi, [rsi + 8]
    call MarkRange
    lea rsi, [rel ThunkCache]
    lea rdi, [rsi + 24 * 256]
    call MarkRange
    lea rsi, [rel FfiArgs]
    lea rdi, [rsi + 20 * 8]
    call MarkRange
    call Drain
    call Sweep
    mov rax, [rel LiveBytes]
    shl rax, 1
    mov rcx, 32 << 20
    cmp rax, rcx
    jae .Set
    mov rax, rcx
.Set:
    mov [rel Threshold], rax
    mov qword [rel AllocBytes], 0
    mov qword [rel InGc], 0
    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rbp
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

Sweep:
    xor eax, eax
    lea rdi, [rel FreeSmall]
    mov ecx, 65
    rep stosq
    mov qword [rel LiveBytes], 0
    mov rbx, [rel HeapStart]
    xor r12d, r12d
.Loop:
    cmp rbx, [rel HeapTop]
    jae .End
    mov rdx, [rbx]
    mov r13, rdx
    and r13, -16
    test rdx, Free
    jnz .Dead
    test rdx, Mark
    jz .Dead
    and qword [rbx], -2
    add [rel LiveBytes], r13
    test r12, r12
    jz .Next
    mov rcx, r12
    mov rdx, rbx
    sub rdx, r12
    mov r8, rdx
    or r8, Free
    mov [rcx], r8
    call AddFree
    xor r12d, r12d
    jmp .Next
.Dead:
    test r12, r12
    jnz .Merge
    mov r12, rbx
    jmp .Next
.Merge:
    mov r8, rbx
    call ClearBit
.Next:
    add rbx, r13
    jmp .Loop
.End:
    test r12, r12
    jz .Done
    mov r8, r12
    call ClearBit
    mov [rel HeapTop], r12
.Done:
    ret
