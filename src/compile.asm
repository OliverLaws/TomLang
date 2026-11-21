%include "macros.inc"

global CodeBuf
global Here
global Compile
global DictHere
global FnEntry
global CreateEntry
global BeginDef
global EndDef
global CreateVar
global AllocSlot
global CopyString
global MakeText
extern Latest
extern NextToken

section .bss
CodeBuf   resq 65536
DictSpace resq 65536
DataSpace resq 65536
Here      resq 1
SavedHere resq 1
FnEntry   resq 1

section .data
DictHere dq DictSpace
DataHere dq DataSpace

section .text
Compile:
    mov rax, [rel Here]
    mov [rax], rcx
    add rax, 8
    mov [rel Here], rax
    ret

CreateEntry:
    mov r8, [rel Here]
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
    lea rax, [r8 + 18 + rdx]
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
    mov r8, [rel DataHere]
    add r8, 7
    and r8, -8
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
    mov qword [rax], 0
    lea r8, [rax + 8]
    mov [rel DataHere], r8
    ret

CopyString:
    mov rax, [rel DataHere]
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

