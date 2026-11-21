global InitStack
global DataStack
global DataStackEnd
global ReturnStack
global ReturnStackEnd

section .bss
StackGuard     resq 4
DataStack      resq 65536
DataStackEnd   resq 4
ReturnStack    resq 65536
ReturnStackEnd resq 4

section .text
InitStack:
    lea r15, [rel DataStack]
    ret
