global TypeTable
global TypeKind
global ListOf
global MapOf
global ElemOf
global InternRecord
global FieldCount
global FieldInfo
global FindField
global NewEnum
global FuncOf
extern CopyString
extern AllocSlot

%define KList 5
%define KMap  6
%define KRec  7
%define KEnum 8
%define KFunc 9
%define MaxTypes 4096

section .data
align 8
TypeTable:
    dq 0, 0, 0, 0
    dq 1, 0, 0, 0
    dq 2, 0, 0, 0
    dq 3, 0, 0, 0
    dq 4, 0, 0, 0
TypeTableRest:
    times (MaxTypes - 5) * 4 dq 0
TypeCount dq 5
FuncTop dq FuncPool

section .bss
FuncPool resq 16384

section .text
TypeKind:
    shl rcx, 5
    lea rax, [rel TypeTable]
    mov rax, [rax + rcx]
    ret

ElemOf:
    shl rcx, 5
    lea rax, [rel TypeTable]
    mov rax, [rax + rcx + 8]
    ret

NewEnum:
    lea r9, [rel TypeTable]
    mov rax, [rel TypeCount]
    mov r10, rax
    shl r10, 5
    mov qword [r9 + r10], KEnum
    mov qword [r9 + r10 + 8], 0
    mov [r9 + r10 + 16], rcx
    mov [r9 + r10 + 24], rdx
    inc qword [rel TypeCount]
    ret

FuncOf:
    push rbx
    push rsi
    push rdi
    lea r9, [rel TypeTable]
    mov r10d, 5
.Find:
    cmp r10, [rel TypeCount]
    jae .New
    mov r11, r10
    shl r11, 5
    cmp qword [r9 + r11], KFunc
    jne .Next
    cmp [r9 + r11 + 8], rcx
    jne .Next
    cmp [r9 + r11 + 16], rdx
    jne .Next
    mov rsi, [r9 + r11 + 24]
    xor ebx, ebx
.Cmp:
    cmp rbx, rdx
    je .Found
    mov rax, [rsi + rbx * 8]
    cmp rax, [r8 + rbx * 8]
    jne .Next
    inc rbx
    jmp .Cmp
.Next:
    inc r10
    jmp .Find
.Found:
    mov rax, r10
    jmp .Done
.New:
    mov rdi, [rel FuncTop]
    xor ebx, ebx
.Copy:
    cmp rbx, rdx
    je .Copied
    mov rax, [r8 + rbx * 8]
    mov [rdi + rbx * 8], rax
    inc rbx
    jmp .Copy
.Copied:
    lea rax, [rdi + rdx * 8]
    mov [rel FuncTop], rax
    mov rax, r10
    shl rax, 5
    mov qword [r9 + rax], KFunc
    mov [r9 + rax + 8], rcx
    mov [r9 + rax + 16], rdx
    mov [r9 + rax + 24], rdi
    inc qword [rel TypeCount]
    mov rax, r10
.Done:
    pop rdi
    pop rsi
    pop rbx
    ret

ListOf:
    mov r8d, KList
    jmp Intern1

MapOf:
    mov r8d, KMap

Intern1:
    lea r9, [rel TypeTable]
    mov r10d, 5
.Find:
    cmp r10, [rel TypeCount]
    jae .New
    mov rax, r10
    shl rax, 5
    cmp [r9 + rax], r8
    jne .Next
    cmp [r9 + rax + 8], rcx
    jne .Next
    mov rax, r10
    ret
.Next:
    inc r10
    jmp .Find
.New:
    mov rax, r10
    shl rax, 5
    mov [r9 + rax], r8
    mov [r9 + rax + 8], rcx
    inc qword [rel TypeCount]
    mov rax, r10
    ret

FieldCount:
    shl rcx, 5
    lea rax, [rel TypeTable]
    mov rax, [rax + rcx + 16]
    ret

FieldInfo:
    shl rcx, 5
    lea rax, [rel TypeTable]
    mov rax, [rax + rcx + 24]
    lea rdx, [rdx + rdx * 2]
    lea rax, [rax + rdx * 8]
    ret

FindField:
    push rbx
    push rsi
    push rdi
    mov rbx, rdx
    mov rsi, r8
    shl rcx, 5
    lea rax, [rel TypeTable]
    mov r9, [rax + rcx + 16]
    mov r10, [rax + rcx + 24]
    xor r11d, r11d
.Loop:
    cmp r11, r9
    jae .None
    cmp rsi, [r10 + 8]
    jne .Next
    mov rdi, [r10]
    xor ecx, ecx
.Compare:
    cmp rcx, rsi
    je .Found
    mov al, [rbx + rcx]
    cmp al, [rdi + rcx]
    jne .Next
    inc rcx
    jmp .Compare
.Next:
    add r10, 24
    inc r11
    jmp .Loop
.Found:
    mov rax, r11
    mov rdx, [r10 + 16]
    pop rdi
    pop rsi
    pop rbx
    ret
.None:
    mov rax, -1
    pop rdi
    pop rsi
    pop rbx
    ret

InternRecord:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    mov r12, rcx
    mov r13, rdx
    mov rbx, 5
.Candidate:
    cmp rbx, [rel TypeCount]
    jae .New
    mov rax, rbx
    shl rax, 5
    lea rsi, [rel TypeTable]
    add rsi, rax
    cmp qword [rsi], KRec
    jne .NextCandidate
    cmp [rsi + 16], r12
    jne .NextCandidate
    xor edi, edi
.FieldLoop:
    cmp rdi, r12
    jae .Match
    lea rax, [rdi + rdi * 2]
    lea rax, [r13 + rax * 8]
    push rax
    mov rcx, rbx
    mov rdx, [rax]
    mov r8, [rax + 8]
    call FindField
    pop r9
    cmp rax, -1
    je .NextCandidate
    cmp rdx, [r9 + 16]
    jne .NextCandidate
    inc rdi
    jmp .FieldLoop
.Match:
    mov rax, rbx
    jmp .Done
.NextCandidate:
    inc rbx
    jmp .Candidate
.New:
    lea rdx, [r12 + r12 * 2]
    shl rdx, 3
    mov rcx, r13
    call CopyString
    mov rsi, rax
    xor edi, edi
.CopyNames:
    cmp rdi, r12
    jae .Store
    lea rax, [rdi + rdi * 2]
    lea r8, [rsi + rax * 8]
    push r8
    mov rcx, [r8]
    mov rdx, [r8 + 8]
    call CopyString
    pop r8
    mov [r8], rax
    inc rdi
    jmp .CopyNames
.Store:
    mov rax, [rel TypeCount]
    mov rcx, rax
    shl rcx, 5
    lea r8, [rel TypeTable]
    mov qword [r8 + rcx], KRec
    mov qword [r8 + rcx + 8], 0
    mov [r8 + rcx + 16], r12
    mov [r8 + rcx + 24], rsi
    inc qword [rel TypeCount]
.Done:
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret
