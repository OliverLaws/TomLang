%include "macros.inc"

global PackInit
global LoadFile
global PackWrite
global PackRecordMain
global ToolPath
global Packed
global BuildMode
extern SysLoadFile
extern SysExePath
extern SysWriteWhole
extern SysAlloc
extern ExeDir
extern MainPathPtr
extern FilePath
extern PrintString
extern PrintNewLine

%define MaxPack 256

section .data
PackMagic db "TOMPACK1"
BuiltMsg db "built "
BuiltMsgLen equ $ - BuiltMsg
WriteFailMsg db "can't write "
WriteFailMsgLen equ $ - WriteFailMsg
ExeText db ".exe"
ToolDir db "lib/tools/"
ToolDirLen equ $ - ToolDir
ToolUpDir db "../lib/tools/"
ToolUpDirLen equ $ - ToolUpDir

section .bss
Packed      resq 1
BuildMode   resq 1
PackCount   resq 1
PackTab     resq MaxPack * 4
PackBaseLen resq 1
PackBase    resb 1024
PackBaseNorm resb 2048
PackKey     resb 2048
PackExePath resb 1024
MainVirtual resb 2048
OutPath     resb 2048
RecCount    resq 1
RecTab      resq MaxPack * 4
NormA       resb 2048
NormB       resb 2048

section .text

PackInit:
    push rbx
    push rsi
    push rdi
    push r12
    lea rcx, [rel PackExePath]
    mov edx, 1000
    call SysExePath
    test rax, rax
    jz .No
    lea rcx, [rel PackExePath]
    mov byte [rcx + rax], 0
    call SysLoadFile
    cmp rdx, 32
    jb .No
    mov rbx, rax
    mov r12, rdx
    mov rax, [rbx + r12 - 8]
    cmp rax, [rel PackMagic]
    jne .No
    mov rsi, [rbx + r12 - 16]
    lea rax, [r12 - 24]
    cmp rsi, rax
    ja .No
    add rsi, rbx
    mov rcx, [rsi]
    cmp rcx, MaxPack
    ja .No
    test rcx, rcx
    jz .No
    mov [rel PackCount], rcx
    add rsi, 8
    lea rdi, [rel PackTab]
.Entry:
    mov rax, [rsi]
    lea rdx, [rsi + 8]
    mov [rdi], rdx
    mov [rdi + 8], rax
    lea rsi, [rdx + rax]
    mov rax, [rsi]
    lea rdx, [rsi + 8]
    mov [rdi + 16], rdx
    mov [rdi + 24], rax
    lea rsi, [rdx + rax]
    add rdi, 32
    dec rcx
    jnz .Entry
    mov qword [rel Packed], 1
    lea rcx, [rel PackBase]
    mov edx, 1000
    call ExeDir
    mov [rel PackBaseLen], rax
    lea rcx, [rel PackBase]
    mov byte [rcx + rax], 0
    push rax
    push rax
    lea rcx, [rel PackBase]
    lea r8, [rel PackBaseNorm]
    call NormCopy
    pop rax
    pop rax
    lea rdi, [rel MainVirtual]
    lea rsi, [rel PackBase]
    mov rcx, rax
    rep movsb
    lea rax, [rel PackTab]
    mov rsi, [rax]
    mov rcx, [rax + 8]
    rep movsb
    mov byte [rdi], 0
    lea rax, [rel MainVirtual]
    mov [rel MainPathPtr], rax
    lea rax, [rel PackTab]
    mov rdx, [rax + 24]
    mov rax, [rax + 16]
    jmp .Out
.No:
    xor eax, eax
    xor edx, edx
.Out:
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

NormCopy:
    xor eax, eax
.Loop:
    mov dl, [rcx + rax]
    test dl, dl
    jz .Done
    cmp dl, 92
    jne .Put
    mov dl, '/'
.Put:
    mov [r8 + rax], dl
    inc rax
    cmp rax, 2040
    jb .Loop
.Done:
    mov byte [r8 + rax], 0
    ret

StripUp:
.Loop:
    cmp byte [rcx], '.'
    jne .Done
    cmp byte [rcx + 1], '.'
    jne .Done
    cmp byte [rcx + 2], '/'
    jne .Done
    add rcx, 3
    jmp .Loop
.Done:
    ret

PackLookup:
    push rbx
    push rsi
    push rdi
    lea r8, [rel PackKey]
    call NormCopy
    lea rsi, [rel PackKey]
    lea rdi, [rel PackBaseNorm]
    call PrefixOf
    test rax, rax
    jz .Miss
    mov rcx, rax
    call StripUp
    mov rsi, rcx
    xor edx, edx
.Len:
    cmp byte [rsi + rdx], 0
    je .Search
    inc rdx
    jmp .Len
.Search:
    lea rbx, [rel PackTab]
    mov r9, [rel PackCount]
.Next:
    test r9, r9
    jz .Miss
    cmp [rbx + 8], rdx
    jne .Skip
    mov rdi, [rbx]
    xor eax, eax
.Cmp:
    cmp rax, rdx
    jae .Hit
    mov cl, [rsi + rax]
    cmp cl, [rdi + rax]
    jne .Skip
    inc rax
    jmp .Cmp
.Skip:
    add rbx, 32
    dec r9
    jmp .Next
.Hit:
    mov rax, [rbx + 16]
    mov rdx, [rbx + 24]
    pop rdi
    pop rsi
    pop rbx
    ret
.Miss:
    xor eax, eax
    xor edx, edx
    pop rdi
    pop rsi
    pop rbx
    ret

LoadFile:
    cmp qword [rel Packed], 0
    je .Disk
    push rcx
    push rcx
    call PackLookup
    pop rcx
    pop rcx
    test rdx, rdx
    jnz .Done
.Disk:
    cmp qword [rel BuildMode], 0
    jne .Record
    jmp SysLoadFile
.Record:
    push rcx
    push rcx
    call SysLoadFile
    pop rcx
    pop rcx
    test rdx, rdx
    jz .Done
    push rax
    push rdx
    mov r8, rax
    mov r9, rdx
    call PackRecord
    pop rdx
    pop rax
.Done:
    ret

PackRecord:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    mov r12, rcx
    mov r13, r8
    mov r14, r9
    cmp qword [rel RecCount], MaxPack
    jae .Out
    mov rcx, r12
    lea r8, [rel NormA]
    call NormCopy
    lea rcx, [rel PackBase]
    mov edx, 1000
    call ExeDir
    lea rcx, [rel PackBase]
    mov byte [rcx + rax], 0
    lea rcx, [rel PackBase]
    lea r8, [rel NormB]
    call NormCopy
    lea rsi, [rel NormA]
    lea rdi, [rel NormB]
    call PrefixOf
    test rax, rax
    jz .TryMain
    mov rcx, rax
    call StripUp
    jmp .Key
.TryMain:
    lea rax, [rel FilePath]
    mov rcx, [rax]
    mov rdx, [rax + 8]
    test rcx, rcx
    jz .Out
.Back:
    test rdx, rdx
    jz .NoDir
    cmp byte [rcx + rdx - 1], '/'
    je .HaveDir
    cmp byte [rcx + rdx - 1], 92
    je .HaveDir
    dec rdx
    jmp .Back
.NoDir:
    lea rcx, [rel NormA]
    jmp .Key
.HaveDir:
    lea rdi, [rel NormB]
    xor eax, eax
.CopyDir:
    cmp rax, rdx
    jae .DirDone
    mov r8b, [rcx + rax]
    cmp r8b, 92
    jne .PutDir
    mov r8b, '/'
.PutDir:
    mov [rdi + rax], r8b
    inc rax
    jmp .CopyDir
.DirDone:
    mov byte [rdi + rax], 0
    lea rsi, [rel NormA]
    call PrefixOf
    test rax, rax
    jz .Out
    mov rcx, rax
.Key:
    push rcx
    push rcx
    xor ebx, ebx
.KeyLen:
    cmp byte [rcx + rbx], 0
    je .Store
    inc rbx
    jmp .KeyLen
.Store:
    lea rcx, [rbx + r14 + 16]
    call SysAlloc
    pop rsi
    pop rsi
    test rax, rax
    jz .Out
    mov rdi, rax
    mov rcx, rbx
    rep movsb
    mov rsi, r13
    mov rcx, r14
    rep movsb
    mov rcx, [rel RecCount]
    shl rcx, 5
    lea rdx, [rel RecTab]
    add rdx, rcx
    mov [rdx], rax
    mov [rdx + 8], rbx
    add rax, rbx
    mov [rdx + 16], rax
    mov [rdx + 24], r14
    inc qword [rel RecCount]
.Out:
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

PackRecordMain:
    push rsi
    push rdi
    mov r8, rcx
    mov r9, rdx
    mov rsi, [rel MainPathPtr]
    xor eax, eax
    xor edx, edx
.Scan:
    mov cl, [rsi + rax]
    test cl, cl
    jz .Got
    inc rax
    cmp cl, '/'
    je .Sep
    cmp cl, 92
    jne .Scan
.Sep:
    mov rdx, rax
    jmp .Scan
.Got:
    lea rcx, [rsi + rdx]
    pop rdi
    pop rsi
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    mov r13, r8
    mov r14, r9
    jmp PackRecord.Key

PrefixOf:
    xor eax, eax
.Loop:
    mov dl, [rdi + rax]
    test dl, dl
    jz .Yes
    cmp dl, [rsi + rax]
    jne .No
    inc rax
    jmp .Loop
.Yes:
    lea rax, [rsi + rax]
    ret
.No:
    xor eax, eax
    ret

PackWrite:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    mov rsi, [rel MainPathPtr]
    lea rdi, [rel OutPath]
    xor ecx, ecx
.CopyName:
    mov al, [rsi + rcx]
    test al, al
    jz .NameDone
    mov [rdi + rcx], al
    inc rcx
    cmp rcx, 2000
    jb .CopyName
.NameDone:
    cmp rcx, 4
    jb .AddExe
    cmp dword [rdi + rcx - 4], '.tom'
    jne .AddExe
    sub rcx, 4
.AddExe:
    mov eax, [rel ExeText]
    mov [rdi + rcx], eax
    mov byte [rdi + rcx + 4], 0
    lea rcx, [rel PackExePath]
    mov edx, 1000
    call SysExePath
    lea rcx, [rel PackExePath]
    mov byte [rcx + rax], 0
    call SysLoadFile
    test rdx, rdx
    jz .Fail
    mov rbx, rax
    mov r12, rdx
    cmp r12, 32
    jb .Plain
    mov rax, [rbx + r12 - 8]
    cmp rax, [rel PackMagic]
    jne .Plain
    mov r12, [rbx + r12 - 16]
.Plain:
    lea r13, [r12 + 24]
    mov rcx, [rel RecCount]
    lea rdx, [rel RecTab]
.Size:
    test rcx, rcx
    jz .Sized
    add r13, [rdx + 8]
    add r13, [rdx + 24]
    add r13, 16
    add rdx, 32
    dec rcx
    jmp .Size
.Sized:
    mov rcx, r13
    call SysAlloc
    test rax, rax
    jz .Fail
    mov r14, rax
    mov rdi, rax
    mov rsi, rbx
    mov rcx, r12
    rep movsb
    mov rax, [rel RecCount]
    stosq
    mov rbx, [rel RecCount]
    lea rdx, [rel RecTab]
.Write:
    test rbx, rbx
    jz .Trailer
    mov rax, [rdx + 8]
    stosq
    mov rsi, [rdx]
    mov rcx, [rdx + 8]
    rep movsb
    mov rax, [rdx + 24]
    stosq
    mov rsi, [rdx + 16]
    mov rcx, [rdx + 24]
    rep movsb
    add rdx, 32
    dec rbx
    jmp .Write
.Trailer:
    mov rax, r12
    stosq
    mov rax, [rel PackMagic]
    stosq
    lea rcx, [rel OutPath]
    mov rdx, r14
    mov r8, r13
    call SysWriteWhole
    test rax, rax
    jz .Fail
    lea rcx, [rel BuiltMsg]
    mov edx, BuiltMsgLen
    call PrintString
    call PrintOut
    call PrintNewLine
    xor eax, eax
    jmp .Done
.Fail:
    lea rcx, [rel WriteFailMsg]
    mov edx, WriteFailMsgLen
    call PrintString
    call PrintOut
    call PrintNewLine
    mov eax, 1
.Done:
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

PrintOut:
    lea rcx, [rel OutPath]
    xor edx, edx
.Len:
    cmp byte [rcx + rdx], 0
    je .Print
    inc rdx
    jmp .Len
.Print:
    jmp PrintString

ToolPath:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    mov r12, rcx
    mov r13, rdx
    mov rbx, r8
    mov rcx, r12
    mov edx, 1000
    call ExeDir
    lea rdi, [r12 + rax]
    lea rsi, [rel ToolDir]
    mov ecx, ToolDirLen
    test rbx, rbx
    jz .Copy
    lea rsi, [rel ToolUpDir]
    mov ecx, ToolUpDirLen
.Copy:
    rep movsb
    mov rsi, r13
    mov ecx, 3
    rep movsb
    mov dword [rdi], '.tom'
    mov byte [rdi + 4], 0
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret
