global InitIO
global PrintString
global PrintNumber
global PrintNewLine
global ReadLine
global InputBuf
global LoadFileArg
global CheckMode
extern GetStdHandle
extern WriteFile
extern ReadFile
extern GetCommandLineA
extern CreateFileA
extern CloseHandle
extern ExitProcess

section .bss
StdOut    resq 1
StdIn     resq 1
Written   resq 1
BytesRead resq 1
NumBuf    resb 24
InputBuf  resb 256
PathBuf   resb 512
FileBuf   resb 1048576
CheckMode resq 1

section .data
NewlineChar  db 10
ErrOpen      db "can't open file", 10
ErrOpenLen   equ $ - ErrOpen

section .text
InitIO:
    sub rsp, 40
    mov rcx, -11
    call GetStdHandle
    mov [rel StdOut], rax
    mov rcx, -10
    call GetStdHandle
    mov [rel StdIn], rax
    add rsp, 40
    ret

PrintString:
    sub rsp, 40
    mov r8, rdx
    mov rdx, rcx
    mov rcx, [rel StdOut]
    lea r9, [rel Written]
    mov qword [rsp+32], 0
    call WriteFile
    add rsp, 40
    ret

PrintNumber:
    sub rsp, 40
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
    add rsp, 40
    ret

PrintNewLine:
    sub rsp, 40
    lea rcx, [rel NewlineChar]
    mov rdx, 1
    call PrintString
    add rsp, 40
    ret

ReadLine:
    sub rsp, 40
    mov rcx, [rel StdIn]
    lea rdx, [rel InputBuf]
    mov r8, 256
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
    add rsp, 40
    ret
.Eof:
    xor ecx, ecx
    call ExitProcess

LoadFileArg:
    sub rsp, 56
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
    cmp byte [rcx + 2], 'c'
    jne .NotFlag
    mov qword [rel CheckMode], 1
.SkipFlag:
    mov al, [rcx]
    test al, al
    jz .None
    cmp al, ' '
    je .SkipSpaces
    inc rcx
    jmp .SkipFlag
.NotFlag:
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
    mov [rdx], al
    inc rcx
    inc rdx
    jmp .Copy
.CopyDone:
    mov byte [rdx], 0
    lea rcx, [rel PathBuf]
    mov edx, 0x80000000
    mov r8d, 1
    xor r9d, r9d
    mov qword [rsp+32], 3
    mov qword [rsp+40], 0x80
    mov qword [rsp+48], 0
    call CreateFileA
    cmp rax, -1
    je .Fail
    mov [rsp+48], rax
    mov rcx, rax
    lea rdx, [rel FileBuf]
    mov r8d, 1048576
    lea r9, [rel BytesRead]
    mov qword [rsp+32], 0
    call ReadFile
    mov rcx, [rsp+48]
    call CloseHandle
    lea rax, [rel FileBuf]
    mov rdx, [rel BytesRead]
    add rsp, 56
    ret
.None:
    xor eax, eax
    xor edx, edx
    add rsp, 56
    ret
.Fail:
    lea rcx, [rel ErrOpen]
    mov rdx, ErrOpenLen
    call PrintString
    mov ecx, 1
    call ExitProcess
