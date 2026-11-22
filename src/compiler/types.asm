global TypeTable
global TypeKind
global ListOf
global MapOf
global UnionOf2
global UnionWithout
global UnionHas
global MapKeyed
global KeyOf
global ElemOf
global InternRecord
global NewRecordType
global NewPlaceholder
global FieldCount
global FieldInfo
global FindField
global NewEnum
global FuncOf
global VarTypeOf
extern CopyString
extern AllocSlot
extern Abort

%define KList 5
%define TText 2
%define KMap  6
%define KRec  7
%define KEnum 8
%define KFunc 9
%define KVar  10
%define KUnion 11
%define KNil 12
%define TNil 5
%define MaxTypes 4096

section .data
align 8
TypeTable:
    dq 0, 0, 0, 0
    dq 1, 0, 0, 0
    dq 2, 0, 0, 0
    dq 3, 0, 0, 0
    dq 4, 0, 0, 0
    dq KNil, 0, 0, 0
TypeTableRest:
    times (MaxTypes - 6) * 4 dq 0
TypeCount dq 6
FuncTop dq FuncPool

section .bss
FuncPool resq 16384
UnionBuf resq 32
UnionN resq 1
VarIds resq 27

section .data
ErrTypes db "too many different types in one program"
ErrTypesLen equ $ - ErrTypes

section .text
TypesFull:
    lea rcx, [rel ErrTypes]
    mov edx, ErrTypesLen
    jmp Abort

%macro TypeRoom 0
    cmp qword [rel TypeCount], MaxTypes - 1
    jae TypesFull
%endmacro
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
    TypeRoom
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
    TypeRoom
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
    lea rax, [rdi + rdx * 8]
    lea rbx, [rel FuncPool + 16384 * 8 - 256]
    cmp rax, rbx
    jae TypesFull
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

UnionIntern:
    TypeRoom
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
    cmp qword [r9 + r11], KUnion
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
    lea rax, [rdi + rdx * 8]
    lea rbx, [rel FuncPool + 16384 * 8 - 256]
    cmp rax, rbx
    jae TypesFull
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
    mov qword [r9 + rax], KUnion
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

UnionAdd:
    push rcx
    mov rax, rcx
    shl rax, 5
    lea r8, [rel TypeTable]
    cmp qword [r8 + rax], KUnion
    jne .One
    mov r9, [r8 + rax + 16]
    mov r10, [r8 + rax + 24]
    xor r11d, r11d
.Each:
    cmp r11, r9
    jae .Done
    mov rcx, [r10 + r11 * 8]
    push r9
    push r10
    push r11
    call UnionAdd
    pop r11
    pop r10
    pop r9
    inc r11
    jmp .Each
.One:
    mov rcx, [rsp]
    mov rdx, [rel UnionN]
    xor r9d, r9d
.Scan:
    cmp r9, rdx
    jae .Insert
    lea r10, [rel UnionBuf]
    mov rax, [r10 + r9 * 8]
    cmp rax, rcx
    je .Done
    ja .Insert
    inc r9
    jmp .Scan
.Insert:
    cmp rdx, 30
    jae .Done
    lea r10, [rel UnionBuf]
    mov r11, rdx
.Shift:
    cmp r11, r9
    jbe .Put
    mov rax, [r10 + r11 * 8 - 8]
    mov [r10 + r11 * 8], rax
    dec r11
    jmp .Shift
.Put:
    mov [r10 + r9 * 8], rcx
    inc qword [rel UnionN]
.Done:
    pop rcx
    ret

UnionOf2:
    push rdx
    mov qword [rel UnionN], 0
    call UnionAdd
    pop rcx
    call UnionAdd
    cmp qword [rel UnionN], 1
    jne .Many
    mov rax, [rel UnionBuf]
    ret
.Many:
    xor ecx, ecx
    mov rdx, [rel UnionN]
    lea r8, [rel UnionBuf]
    jmp UnionIntern

UnionWithout:
    push rbx
    push r12
    mov rbx, rcx
    mov r12, rdx
    mov qword [rel UnionN], 0
    mov rax, rbx
    shl rax, 5
    lea r8, [rel TypeTable]
    cmp qword [r8 + rax], KUnion
    jne .Same
    mov r9, [r8 + rax + 16]
    mov r10, [r8 + rax + 24]
    xor r11d, r11d
.Each:
    cmp r11, r9
    jae .Built
    mov rcx, [r10 + r11 * 8]
    cmp rcx, r12
    je .Skip
    push r9
    push r10
    push r11
    call UnionAdd
    pop r11
    pop r10
    pop r9
.Skip:
    inc r11
    jmp .Each
.Built:
    cmp qword [rel UnionN], 1
    jne .Many
    mov rax, [rel UnionBuf]
    jmp .Out
.Many:
    xor ecx, ecx
    mov rdx, [rel UnionN]
    lea r8, [rel UnionBuf]
    call UnionIntern
    jmp .Out
.Same:
    mov rax, rbx
.Out:
    pop r12
    pop rbx
    ret

UnionHas:
    cmp rcx, rdx
    je .Yes
    mov rax, rcx
    shl rax, 5
    lea r8, [rel TypeTable]
    cmp qword [r8 + rax], KUnion
    jne .No
    mov r9, [r8 + rax + 16]
    mov r10, [r8 + rax + 24]
    xor r11d, r11d
.Each:
    cmp r11, r9
    jae .No
    cmp [r10 + r11 * 8], rdx
    je .Yes
    inc r11
    jmp .Each
.Yes:
    mov eax, 1
    ret
.No:
    xor eax, eax
    ret


VarTypeOf:
    lea rdx, [rel VarIds]
    mov rax, [rdx + rcx * 8]
    test rax, rax
    jnz .Done
    TypeRoom
    lea r9, [rel TypeTable]
    mov rax, [rel TypeCount]
    mov r10, rax
    shl r10, 5
    mov qword [r9 + r10], KVar
    mov [r9 + r10 + 8], rcx
    mov qword [r9 + r10 + 16], 0
    mov qword [r9 + r10 + 24], 0
    inc qword [rel TypeCount]
    mov [rdx + rcx * 8], rax
.Done:
    ret

ListOf:
    TypeRoom
    mov r8d, KList
    xor r11d, r11d
    jmp Intern1

MapOf:
    TypeRoom
    mov r8d, KMap
    xor r11d, r11d
    jmp Intern1

MapKeyed:
    TypeRoom
    mov r8d, KMap
    xor r11d, r11d
    cmp rdx, TText
    je Intern1
    mov r11, rdx

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
    cmp [r9 + rax + 16], r11
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
    mov [r9 + rax + 16], r11
    inc qword [rel TypeCount]
    mov rax, r10
    ret

KeyOf:
    shl rcx, 5
    lea rax, [rel TypeTable]
    mov rax, [rax + rcx + 16]
    test rax, rax
    jnz .Done
    mov eax, TText
.Done:
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
    TypeRoom
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
    cmp qword [rsi + 8], 0
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

NewRecordType:
    TypeRoom
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    mov r12, rcx
    mov r13, rdx
    jmp InternRecord.New

NewPlaceholder:
    TypeRoom
    mov rax, [rel TypeCount]
    mov rcx, rax
    shl rcx, 5
    lea rdx, [rel TypeTable]
    mov qword [rdx + rcx], 14
    mov qword [rdx + rcx + 8], 0
    mov qword [rdx + rcx + 16], 0
    mov qword [rdx + rcx + 24], 0
    inc qword [rel TypeCount]
    ret
