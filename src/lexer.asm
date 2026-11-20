global SetInput
global NextToken
global ParseNumber

section .bss
InPtr resq 1
InEnd resq 1

section .text
SetInput:
    mov [rel InPtr], rcx
    add rcx, rdx
    mov [rel InEnd], rcx
    ret

IsWordChar:
    cmp cl, '0'
    jb .No
    cmp cl, '9'
    jbe .Yes
    cmp cl, 'A'
    jb .No
    cmp cl, 'Z'
    jbe .Yes
    cmp cl, '_'
    je .Yes
    cmp cl, 'a'
    jb .No
    cmp cl, 'z'
    jbe .Yes
.No:
    xor eax, eax
    ret
.Yes:
    mov eax, 1
    ret

NextToken:
    mov r8, [rel InPtr]
    mov r9, [rel InEnd]
.Skip:
    cmp r8, r9
    jae .End
    cmp byte [r8], ' '
    jne .Start
    inc r8
    jmp .Skip
.Start:
    mov r10, r8
    mov cl, [r8]
    inc r8
    call IsWordChar
    test eax, eax
    jz .Symbol
.Run:
    cmp r8, r9
    jae .Done
    mov cl, [r8]
    call IsWordChar
    test eax, eax
    jz .Done
    inc r8
    jmp .Run
.Symbol:
    cmp r8, r9
    jae .Done
    cmp byte [r8], '='
    jne .Done
    inc r8
.Done:
    mov [rel InPtr], r8
    mov rax, r10
    mov rdx, r8
    sub rdx, r10
    ret
.End:
    mov [rel InPtr], r8
    xor edx, edx
    ret

ParseNumber:
    xor eax, eax
    test rdx, rdx
    jz .Fail
.Loop:
    movzx r8d, byte [rcx]
    sub r8d, '0'
    cmp r8d, 9
    ja .Fail
    imul rax, rax, 10
    add rax, r8
    inc rcx
    dec rdx
    jnz .Loop
    mov edx, 1
    ret
.Fail:
    xor edx, edx
    ret