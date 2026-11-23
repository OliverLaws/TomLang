%include "macros.inc"
%define FuseMask 4095

global CodeBuf
global InstEnd
global Here
global Compile
global CompileOp
global FuseBranch
global LastOpAt
extern FuseTable
extern BranchTable
extern StoreTable
extern PrimLocalGet
extern PrimLit
extern PrimGetG
global DictHere
global EnterInstanceSpace
global LeaveInstanceSpace
global FnEntry
global SavedHere
global DataSpace
global DataHere
global NamePrefixPtr
global NamePrefixLen
global ApplyPrefix
global CreateEntry
global BeginDef
global EndDef
global CreateVar
global AllocSlot
global CopyString
global MakeText
extern Latest
extern NextToken
extern Abort

InstRegion equ 1048576

section .bss
FuseHashTab resq 4096
FuseReady resb 8
CombBuf   resb 512
CodeBuf   resq 1048576
CodeEnd   resq 64
DictSpace resq 1048576
DictEnd   resq 64
InstSpace resb InstRegion * 20
InstEnd   resq 64
InstSaveHere resq 20
InstSaveEnd  resq 20
DataSpace resq 2097152
DataEnd   resq 64
Here      resq 1
SavedHere resq 1
FnEntry   resq 1
LastOpAt  resq 1
PrevOpAt  resq 1
FusedAt   resq 1

section .data
DictHere dq DictSpace
DataHere dq DataSpace
CodeEndPtr   dq CodeEnd
DictStartPtr dq DictSpace
DictEndPtr   dq DictEnd
InstHereTab:
%assign i 0
%rep 20
    dq InstSpace + i * InstRegion
%assign i i + 1
%endrep
DataEndPtr   dq DataEnd
NamePrefixPtr dq 0
NamePrefixLen dq 0

ErrTooBig     db "this program is too big (too much code or text)"
ErrTooBigLen  equ $ - ErrTooBig
ErrLongName   db "that name is too long (200 letters at most)"
ErrLongNameLen equ $ - ErrLongName

section .text
ApplyPrefix:
    mov r8, [rel NamePrefixLen]
    test r8, r8
    jz .Done
    test rdx, rdx
    jz .Done
    lea r9, [r8 + rdx]
    cmp r9, 250
    ja LongName
    push rsi
    push rdi
    push rdx
    push rcx
    lea rdi, [rel CombBuf]
    mov rsi, [rel NamePrefixPtr]
    mov rcx, r8
    rep movsb
    pop rsi
    pop rcx
    push rcx
    rep movsb
    pop rdx
    lea rcx, [rel CombBuf]
    add rdx, [rel NamePrefixLen]
    pop rdi
    pop rsi
.Done:
    ret

TooBig:
    lea rcx, [rel ErrTooBig]
    mov edx, ErrTooBigLen
    jmp Abort

LongName:
    lea rcx, [rel ErrLongName]
    mov edx, ErrLongNameLen
    jmp Abort

%macro DataRoom 1
    cmp %1, [rel DataEndPtr]
    jae TooBig
%endmacro

EnterInstanceSpace:
    lea r8, [rel InstSaveHere]
    mov rax, [rel DictHere]
    mov [r8 + rcx * 8], rax
    lea r8, [rel InstSaveEnd]
    mov rax, [rel DictEndPtr]
    mov [r8 + rcx * 8], rax
    lea rdx, [rel InstHereTab]
    mov rax, [rdx + rcx * 8]
    mov [rel DictHere], rax
    lea rdx, [rel InstSpace]
    imul rax, rcx, InstRegion
    lea rax, [rdx + rax + InstRegion - 512]
    mov [rel DictEndPtr], rax
    ret

LeaveInstanceSpace:
    lea rdx, [rel InstHereTab]
    mov rax, [rel DictHere]
    mov [rdx + rcx * 8], rax
    lea r8, [rel InstSaveHere]
    mov rax, [r8 + rcx * 8]
    mov [rel DictHere], rax
    lea r8, [rel InstSaveEnd]
    mov rax, [r8 + rcx * 8]
    mov [rel DictEndPtr], rax
    ret

IsProducer:
    lea r10, [rel PrimLocalGet]
    cmp rdx, r10
    je .Yes
    lea r10, [rel PrimLit]
    cmp rdx, r10
    je .Yes
    lea r10, [rel PrimGetG]
    cmp rdx, r10
    je .Yes
    xor r10d, r10d
    ret
.Yes:
    mov r10d, 1
    ret

FuseKey:
    mov rax, rdx
    imul rax, rax, 0x5BD1E995
    mov r10, r11
    imul r10, r10, 0x2545F491
    add rax, r10
    mov r10, rcx
    imul r10, r10, 0x27D4EB2F
    add rax, r10
    shr rax, 17
    ret

FindFuse:
    push r9
    cmp byte [rel FuseReady], 0
    jne .Ready
    call BuildFuse
.Ready:
    call FuseKey
    lea r9, [rel FuseHashTab]
.Probe:
    and eax, FuseMask
    mov r10, [r9 + rax * 8]
    test r10, r10
    jz .None
    cmp [r10], rdx
    jne .Next
    cmp [r10 + 8], r11
    jne .Next
    cmp [r10 + 16], rcx
    jne .Next
    mov rax, [r10 + 24]
    pop r9
    ret
.Next:
    inc eax
    jmp .Probe
.None:
    xor eax, eax
    pop r9
    ret

BuildFuse:
    push rbx
    push rcx
    push rdx
    push r11
    lea rbx, [rel FuseTable]
    lea r9, [rel FuseHashTab]
.Row:
    cmp qword [rbx], 0
    je .Done
    mov rdx, [rbx]
    mov r11, [rbx + 8]
    mov rcx, [rbx + 16]
    call FuseKey
.Probe:
    and eax, FuseMask
    cmp qword [r9 + rax * 8], 0
    je .Put
    inc eax
    jmp .Probe
.Put:
    mov [r9 + rax * 8], rbx
    add rbx, 32
    jmp .Row
.Done:
    mov byte [rel FuseReady], 1
    pop r11
    pop rdx
    pop rcx
    pop rbx
    ret

CompileOp:
    push rdx
    push r8
    push r9
    push r10
    push r11
    push rax
    mov r8, [rel LastOpAt]
    mov r9, [rel PrevOpAt]
    mov [rel PrevOpAt], r8
    mov rax, [rel Here]
    mov [rel LastOpAt], rax
    lea r10, [r8 + 8]
    cmp r10, rax
    jne .NotStore
    mov rdx, [r8]
    lea r10, [rel StoreTable]
.StoreScan:
    cmp qword [r10], 0
    je .NotStore
    cmp [r10], rdx
    jne .StoreNext
    cmp [r10 + 8], rcx
    jne .StoreNext
    mov rdx, [r10 + 16]
    mov [r8], rdx
    jmp .Plain
.StoreNext:
    add r10, 24
    jmp .StoreScan
.NotStore:
    lea r10, [r8 + 16]
    cmp r10, rax
    jne .Plain
    mov rdx, [r8]
    call IsProducer
    test r10, r10
    jz .Plain
    lea r10, [r9 + 16]
    cmp r10, r8
    jne .Single
    mov r11, rdx
    mov rdx, [r9]
    call IsProducer
    test r10, r10
    jz .SingleBack
    call FindFuse
    test rax, rax
    jz .SingleBack
    mov [r9], rax
    mov [rel FusedAt], r9
    jmp .Plain
.SingleBack:
    mov rdx, r11
.Single:
    xor r11d, r11d
    call FindFuse
    test rax, rax
    jz .Plain
    mov [r8], rax
    mov [rel FusedAt], r8
.Plain:
    pop rax
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    jmp Compile

FuseBranch:
    push rcx
    push rdx
    push r8
    push r9
    push r10
    push r11
    push rax
    mov r8, [rel LastOpAt]
    mov qword [rel LastOpAt], 0
    mov qword [rel PrevOpAt], 0
    mov rax, [rel Here]
    lea r9, [r8 + 8]
    cmp r9, rax
    jne .Done
    mov rdx, [r8]
    lea r10, [rel BranchTable]
.Scan:
    mov r9, [r10]
    test r9, r9
    jz .Done
    cmp r9, rdx
    je .Found
    add r10, 16
    jmp .Scan
.Found:
    mov rcx, [r10 + 8]
    mov [r8], rcx
    mov r9, [rel FusedAt]
    lea rax, [r9 + 16]
    cmp rax, r8
    je .Prod
    lea rax, [r9 + 32]
    cmp rax, r8
    jne .Done
.Prod:
    mov rax, [r9]
    lea r10, [rel FuseTable]
.FindOld:
    cmp qword [r10], 0
    je .Done
    cmp [r10 + 24], rax
    je .HaveOld
    add r10, 32
    jmp .FindOld
.HaveOld:
    cmp [r10 + 16], rdx
    jne .Done
    mov rdx, [r10]
    mov r11, [r10 + 8]
    lea rax, [r9 + 16]
    test r11, r11
    jz .Layout
    lea rax, [r9 + 32]
.Layout:
    cmp rax, r8
    jne .Done
    call FindFuse
    test rax, rax
    jz .Done
    mov [r9], rax
.Done:
    pop rax
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    ret

Compile:
    mov rax, [rel Here]
    cmp rax, [rel DictStartPtr]
    jae .Dict
    cmp rax, [rel CodeEndPtr]
    jae TooBig
    jmp .Ok
.Dict:
    cmp rax, [rel DictEndPtr]
    jae TooBig
.Ok:
    mov [rax], rcx
    add rax, 8
    mov [rel Here], rax
    ret

CreateEntry:
    cmp rdx, 200
    ja LongName
    call ApplyPrefix
    mov r8, [rel Here]
    lea r9, [r8 + rdx + 64]
    cmp r9, [rel DictEndPtr]
    jae TooBig
    mov rax, [rel Latest]
    mov [r8], rax
    mov [rel Latest], r8
    mov byte [r8 + 16], 1
    mov [r8 + 17], dl
    xor r9d, r9d
.Copy:
    cmp r9, rdx
    je .CopyDone
    mov al, [rcx + r9]
    mov [r8 + 18 + r9], al
    inc r9
    jmp .Copy
.CopyDone:
    lea rax, [r8 + 18 + rdx + 7]
    and rax, -8
    mov [r8 + 8], rax
    mov [rel Here], rax
    ret

BeginDef:
    mov rax, [rel Here]
    mov [rel SavedHere], rax
    mov rax, [rel DictHere]
    mov [rel Here], rax
    call CreateEntry
    mov rax, [rel Here]
    mov [rel DictHere], rax
    mov rax, [rel Latest]
    mov [rel FnEntry], rax
    ret

EndDef:
    mov rax, [rel Here]
    mov [rel DictHere], rax
    mov rax, [rel SavedHere]
    mov [rel Here], rax
    mov qword [rel FnEntry], 0
    ret

CreateVar:
    cmp rdx, 200
    ja LongName
    call ApplyPrefix
    mov r8, [rel DataHere]
    add r8, 7
    and r8, -8
    lea r9, [r8 + rdx + 64]
    DataRoom r9
    mov rax, [rel Latest]
    mov [r8], rax
    mov [rel Latest], r8
    mov byte [r8 + 16], 3
    mov [r8 + 17], dl
    xor r9d, r9d
.Copy:
    cmp r9, rdx
    je .CopyDone
    mov al, [rcx + r9]
    mov [r8 + 18 + r9], al
    inc r9
    jmp .Copy
.CopyDone:
    lea rax, [r8 + 18 + rdx + 7]
    and rax, -8
    mov qword [rax], 0
    add rax, 8
    mov qword [rax], 0
    add rax, 8
    mov qword [rax], 0
    mov [r8 + 8], rax
    lea r9, [rax + 8]
    mov [rel DataHere], r9
    ret

AllocSlot:
    mov rax, [rel DataHere]
    add rax, 7
    and rax, -8
    lea r8, [rax + 32]
    DataRoom r8
    mov qword [rax], 0
    mov qword [rax + 8], 0
    add rax, 16
    mov qword [rax], 0
    lea r8, [rax + 8]
    mov [rel DataHere], r8
    ret

CopyString:
    mov rax, [rel DataHere]
    lea r8, [rax + rdx + 16]
    DataRoom r8
    xor r9d, r9d
.Copy:
    cmp r9, rdx
    je .Done
    mov r8b, [rcx + r9]
    mov [rax + r9], r8b
    inc r9
    jmp .Copy
.Done:
    lea r8, [rax + rdx]
    mov [rel DataHere], r8
    ret

MakeText:
    mov rax, [rel DataHere]
    add rax, 7
    and rax, -8
    lea r8, [rax + rdx + 16]
    DataRoom r8
    push rbx
    xor r9d, r9d
    xor r10d, r10d
.Copy:
    cmp r9, rdx
    jae .Done
    mov r8b, [rcx + r9]
    inc r9
    cmp r8b, 92
    jne .Put
    cmp r9, rdx
    jae .Put
    mov r8b, [rcx + r9]
    inc r9
    cmp r8b, 'n'
    jne .NotN
    mov r8b, 10
    jmp .Put
.NotN:
    cmp r8b, 't'
    jne .NotT
    mov r8b, 9
    jmp .Put
.NotT:
    cmp r8b, 'r'
    jne .NotR
    mov r8b, 13
    jmp .Put
.NotR:
    cmp r8b, '0'
    jne .Put
    xor r8d, r8d
.Put:
    mov [rax + 8 + r10], r8b
    inc r10
    jmp .Copy
.Done:
    mov [rax], r10
    lea r8, [rax + 8 + r10]
    mov [rel DataHere], r8
    pop rbx
    ret

