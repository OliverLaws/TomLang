%include "macros.inc"

global CodeBuf
global Here
global Compile
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
CombBuf   resb 512
CodeBuf   resq 1048576
CodeEnd   resq 64
DictSpace resq 1048576
DictEnd   resq 64
InstSpace resb InstRegion * 8
InstEnd   resq 64
InstSaveHere resq 8
InstSaveEnd  resq 8
DataSpace resq 2097152
DataEnd   resq 64
Here      resq 1
SavedHere resq 1
FnEntry   resq 1

section .data
DictHere dq DictSpace
DataHere dq DataSpace
CodeEndPtr   dq CodeEnd
DictStartPtr dq DictSpace
DictEndPtr   dq DictEnd
InstHereTab:
%assign i 0
%rep 8
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
    mov [r8 + 8], rax
    lea r9, [rax + 8]
    mov [rel DataHere], r9
    ret

AllocSlot:
    mov rax, [rel DataHere]
    add rax, 7
    and rax, -8
    lea r8, [rax + 16]
    DataRoom r8
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
    jne .Put
    mov r8b, 9
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

