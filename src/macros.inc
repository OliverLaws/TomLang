%define LetterCacheQ 512
%macro DPush 1
    mov qword [r15], %1
    add r15, 8
%endmacro

%macro DPop 1
    sub r15, 8
    mov %1, qword [r15]
%endmacro

%macro RPush 1
    mov [rbp], %1
    add rbp, 8
%endmacro

%macro RPop 1
    sub rbp, 8
    mov %1, [rbp]
%endmacro

%macro NEXT 0
    mov rax, [r14]
    add r14, 8
    jmp rax
%endmacro

%macro CompilePrim 1
    lea rcx, [rel %1]
    call CompileOp
%endmacro

%xdefine LastEntry 0

%macro DefEntry 3
%%Entry:
    dq LastEntry
    dq %2
    db %3
    db %%End - %%Name
%%Name:
    db %1
%%End:
%xdefine LastEntry %%Entry
%endmacro

%macro DefWord 2
    DefEntry %1, %2, 0
%endmacro

%macro DefImm 2
    DefEntry %1, %2, 2
%endmacro
