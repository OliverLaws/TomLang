%include "macros.inc"

global CodeBuf
global Here
global Compile
global DictHere
global SavedHere
global CreateEntry
global CompIf
global CompElse
global CompThen
global CompBegin
global CompUntil
global CompAgain
global CompVariable
extern Latest
extern NextToken
extern PrimLit
extern PrimExit
extern PrimBranch
extern PrimBranch0

section .bss
CodeBuf   resq 4096
DictSpace resq 16384
Here      resq 1
SavedHere resq 1

section .data
DictHere dq DictSpace

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

CompIf:
    lea rcx, [rel PrimBranch0]
    call Compile
    mov rax, [rel Here]
    DPush rax
    xor ecx, ecx
    call Compile
    ret

CompElse:
    lea rcx, [rel PrimBranch]
    call Compile
    mov r8, [rel Here]
    xor ecx, ecx
    call Compile
    DPop rax
    mov rdx, [rel Here]
    mov [rax], rdx
    DPush r8
    ret

CompThen:
    DPop rax
    mov rdx, [rel Here]
    mov [rax], rdx
    ret

CompBegin:
    mov rax, [rel Here]
    DPush rax
    ret

CompUntil:
    lea rcx, [rel PrimBranch0]
    call Compile
    DPop rcx
    call Compile
    ret

CompAgain:
    lea rcx, [rel PrimBranch]
    call Compile
    DPop rcx
    call Compile
    ret

CompVariable:
    mov rax, [rel Here]
    mov [rel SavedHere], rax
    mov rax, [rel DictHere]
    mov [rel Here], rax
    call NextToken
    mov rcx, rax
    call CreateEntry
    lea rcx, [rel PrimLit]
    call Compile
    mov rcx, [rel Here]
    add rcx, 16
    call Compile
    lea rcx, [rel PrimExit]
    call Compile
    xor ecx, ecx
    call Compile
    mov rax, [rel Here]
    mov [rel DictHere], rax
    mov rax, [rel SavedHere]
    mov [rel Here], rax
    ret