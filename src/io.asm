global InitIO
global PrintString
global PrintNumber
global PrintNewLine
global ReadLine
global InputBuf
extern ReadFile
extern GetStdHandle
extern WriteFile

section .bss
StdOut  resq 1
Written resq 1
NumBuf  resb 24
StdIn   resq 1
InputBuf resb 256
BytesRead resq 1 

section .data
NewlineChar db 10

section .text
InitIO:
    sub rsp, 40
    mov rcx, -11
    call GetStdHandle
    mov [rel StdOut], rax
    mov rcx, - 10
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
    mov qword [rsp + 32], 0 
    call ReadFile 
    mov rax, [rel BytesRead]
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