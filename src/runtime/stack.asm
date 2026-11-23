global InitStack
extern InitTasks
global DataStack
global DataStackEnd
global ReturnStack
global ReturnStackEnd

section .bss
StackGuard     resq 4
DataStack      resq 1048576
DataStackEnd   resq 4
ReturnStack    resq 1048576
ReturnStackEnd resq 4

section .text
InitStack:
    lea r15, [rel DataStack]
    jmp InitTasks
