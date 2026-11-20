global InitStack
global DataStack
global ReturnStack

section .bss
StackGuard  resq 4
DataStack   resq 1024
ReturnStack resq 1024

section .text
InitStack:
    lea r15, [rel DataStack]
    ret