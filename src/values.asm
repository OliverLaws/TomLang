%include "macros.inc"

global PrimToDec
global PrimToDecUnder
global PrimDAdd
global PrimDSub
global PrimDMul
global PrimDDiv
global PrimDLess
global PrimDGreater
global PrimDLessEq
global PrimDGreaterEq
global PrimDEq
global PrimDNotEq
global PrimDecToText
global PrimDecToNum
global PrimRound
global PrimTextToDec
global PrimShow
global PrimFormat
global MakeTextFrom
global ParseDecimalText
extern Alloc
extern TypeTable
extern PrintString
extern PrintNewLine
extern Abort

%define KNum  1
%define KText 2
%define KBool 3
%define KDec  4
%define KList 5
%define KMap  6
%define KRec  7
%define KEnum 8
%define KFunc 9

section .data
align 8
Pow10:
    dq 1, 10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000
    dq 1000000000, 10000000000, 100000000000, 1000000000000
    dq 10000000000000, 100000000000000, 1000000000000000
    dq 10000000000000000, 100000000000000000, 1000000000000000000
align 16
SignMask     dq 0x7FFFFFFFFFFFFFFF, 0x7FFFFFFFFFFFFFFF
Half         dq 0.5
ErrDivZero   db "can't divide by 0"
ErrDivZeroLen equ $ - ErrDivZero
StrTrue      db "true"
StrFalse     db "false"

section .bss
DecBuf    resb 64
DecLen    resq 1
DecNeg    resq 1
ShowBuf   resb 65536
ShowLen   resq 1
FmtBuf    resb 4096
UIntBuf   resb 32

section .text
MakeTextFrom:
    push rbx
    push rsi
    push rdi
    mov rsi, rcx
    mov rdi, rdx
    lea rcx, [rdx + 8]
    call Alloc
    mov rbx, rax
    mov [rbx], rdi
    xor ecx, ecx
.Copy:
    cmp rcx, rdi
    jae .Done
    mov al, [rsi + rcx]
    mov [rbx + 8 + rcx], al
    inc rcx
    jmp .Copy
.Done:
    mov rax, rbx
    pop rdi
    pop rsi
    pop rbx
    ret

WriteUInt:
    lea r10, [rel UIntBuf + 32]
    mov r11, r10
.Loop:
    xor edx, edx
    mov rcx, 10
    div rcx
    add dl, '0'
    dec r10
    mov [r10], dl
    test rax, rax
    jnz .Loop
.Copy:
    cmp r10, r11
    jae .Done
    mov al, [r10]
    mov [rdi], al
    inc rdi
    inc r10
    jmp .Copy
.Done:
    ret

FormatDec:
    push rbx
    push rdi
    push r12
    push r13
    xor r13d, r13d
    movq rax, xmm0
    test rax, rax
    jns .Positive
    mov r13d, 1
    andpd xmm0, [rel SignMask]
.Positive:
    mov r12, rcx
    mov rbx, rcx
    test rbx, rbx
    jns .HavePrecision
    mov ebx, 10
.HavePrecision:
    cmp rbx, 15
    jbe .PrecisionOk
    mov ebx, 15
.PrecisionOk:
    lea rax, [rel Pow10]
    mov r9, [rax + rbx * 8]
    cvttsd2si r8, xmm0
    cvtsi2sd xmm1, r8
    subsd xmm0, xmm1
    cvtsi2sd xmm2, r9
    mulsd xmm0, xmm2
    cvtsd2si rcx, xmm0
    cmp rcx, r9
    jb .NoCarry
    sub rcx, r9
    inc r8
.NoCarry:
    test r8, r8
    jnz .SignKept
    test rcx, rcx
    jnz .SignKept
    xor r13d, r13d
.SignKept:
    push rcx
    lea rdi, [rel DecBuf]
    mov rax, r8
    call WriteUInt
    pop rcx
    test rbx, rbx
    jz .Finish
    mov byte [rdi], '.'
    inc rdi
    mov r8, rdi
    add rdi, rbx
    mov r10, rdi
    mov rax, rcx
.Frac:
    cmp r10, r8
    jbe .FracDone
    xor edx, edx
    mov rcx, 10
    div rcx
    add dl, '0'
    dec r10
    mov [r10], dl
    jmp .Frac
.FracDone:
    test r12, r12
    jns .Finish
.Strip:
    lea rax, [r8 + 1]
    cmp rdi, rax
    jbe .Finish
    cmp byte [rdi - 1], '0'
    jne .Finish
    dec rdi
    jmp .Strip
.Finish:
    lea rax, [rel DecBuf]
    sub rdi, rax
    mov [rel DecLen], rdi
    mov [rel DecNeg], r13
    pop r13
    pop r12
    pop rdi
    pop rbx
    ret

ParseDecimalText:
    xor eax, eax
    xor r8d, r8d
    xor r9d, r9d
    xor r10d, r10d
    xor r11d, r11d
    test rdx, rdx
    jz .Build
    cmp byte [rcx], '-'
    jne .Loop
    mov r11d, 1
    inc rcx
    dec rdx
.Loop:
    test rdx, rdx
    jz .Build
    movzx r8d, byte [rcx]
    cmp r8b, '.'
    jne .Digit
    mov r10d, 1
    jmp .Next
.Digit:
    sub r8d, '0'
    cmp r8d, 9
    ja .Build
    cmp r9, 17
    jae .Next
    imul rax, rax, 10
    add rax, r8
    test r10, r10
    jz .Next
    inc r9
.Next:
    inc rcx
    dec rdx
    jmp .Loop
.Build:
    cvtsi2sd xmm0, rax
    lea rcx, [rel Pow10]
    cvtsi2sd xmm1, qword [rcx + r9 * 8]
    divsd xmm0, xmm1
    test r11, r11
    jz .Done
    xorpd xmm1, xmm1
    subsd xmm1, xmm0
    movapd xmm0, xmm1
.Done:
    movq rax, xmm0
    ret

PrimToDec:
    DPop rax
    cvtsi2sd xmm0, rax
    movq rax, xmm0
    DPush rax
    NEXT

PrimToDecUnder:
    mov rax, [r15 - 16]
    cvtsi2sd xmm0, rax
    movq [r15 - 16], xmm0
    NEXT

%macro DecOp 2
%1:
    DPop rax
    movq xmm1, rax
    DPop rax
    movq xmm0, rax
    %2 xmm0, xmm1
    movq rax, xmm0
    DPush rax
    NEXT
%endmacro

DecOp PrimDAdd, addsd
DecOp PrimDSub, subsd
DecOp PrimDMul, mulsd

PrimDDiv:
    DPop rax
    movq xmm1, rax
    xorpd xmm2, xmm2
    ucomisd xmm1, xmm2
    je .Zero
    DPop rax
    movq xmm0, rax
    divsd xmm0, xmm1
    movq rax, xmm0
    DPush rax
    NEXT
.Zero:
    lea rcx, [rel ErrDivZero]
    mov edx, ErrDivZeroLen
    jmp Abort

%macro DecCmp 2
%1:
    DPop rax
    movq xmm1, rax
    DPop rax
    movq xmm0, rax
    ucomisd xmm0, xmm1
    %2 cl
    movzx rcx, cl
    DPush rcx
    NEXT
%endmacro

DecCmp PrimDLess, setb
DecCmp PrimDGreater, seta
DecCmp PrimDLessEq, setbe
DecCmp PrimDGreaterEq, setae
DecCmp PrimDEq, sete
DecCmp PrimDNotEq, setne

PrimDecToNum:
    DPop rax
    movq xmm0, rax
    cvttsd2si rax, xmm0
    DPush rax
    NEXT

PrimRound:
    DPop rax
    movq xmm0, rax
    movapd xmm1, xmm0
    andpd xmm1, [rel SignMask]
    addsd xmm1, [rel Half]
    cvttsd2si rax, xmm1
    movq rcx, xmm0
    test rcx, rcx
    jns .Push
    neg rax
.Push:
    DPush rax
    NEXT

PrimTextToDec:
    DPop rax
    lea rcx, [rax + 8]
    mov rdx, [rax]
    call ParseDecimalText
    DPush rax
    NEXT

DecToTextObject:
    movq xmm0, rax
    mov rcx, -1
    call FormatDec
    cmp qword [rel DecNeg], 0
    je .Plain
    lea rcx, [rel FmtBuf]
    mov byte [rcx], '-'
    lea rdx, [rel DecBuf]
    mov r8, [rel DecLen]
    xor r9d, r9d
.Copy:
    cmp r9, r8
    jae .Make
    mov al, [rdx + r9]
    mov [rcx + r9 + 1], al
    inc r9
    jmp .Copy
.Make:
    lea rdx, [r8 + 1]
    jmp MakeTextFrom
.Plain:
    lea rcx, [rel DecBuf]
    mov rdx, [rel DecLen]
    jmp MakeTextFrom

PrimDecToText:
    DPop rax
    call DecToTextObject
    DPush rax
    NEXT

ShowAppend:
    push rdi
    mov rdi, [rel ShowLen]
    lea r8, [rel ShowBuf]
    xor r9d, r9d
.Loop:
    cmp r9, rdx
    jae .Done
    cmp rdi, 65000
    jae .Done
    mov al, [rcx + r9]
    mov [r8 + rdi], al
    inc rdi
    inc r9
    jmp .Loop
.Done:
    mov [rel ShowLen], rdi
    pop rdi
    ret

%macro ShowLit 1
[section .data]
%%Str: db %1
%%End:
__SECT__
    lea rcx, [rel %%Str]
    mov edx, %%End - %%Str
    call ShowAppend
%endmacro

ShowValue:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    mov rbx, rax
    mov rsi, rcx
    mov r13, rdx
    mov rax, rsi
    shl rax, 5
    lea rdi, [rel TypeTable]
    add rdi, rax
    mov rax, [rdi]
    cmp rax, KNum
    je .Num
    cmp rax, KText
    je .Text
    cmp rax, KBool
    je .Bool
    cmp rax, KDec
    je .Dec
    cmp rax, KList
    je .List
    cmp rax, KMap
    je .Map
    cmp rax, KRec
    je .Rec
    cmp rax, KEnum
    je .Enum
    cmp rax, KFunc
    je .Func
    ShowLit "?"
    jmp .Done
.Num:
    push rdi
    lea rdi, [rel FmtBuf]
    mov rax, rbx
    test rax, rax
    jns .NumPositive
    mov byte [rdi], '-'
    inc rdi
    neg rax
.NumPositive:
    call WriteUInt
    lea rcx, [rel FmtBuf]
    mov rdx, rdi
    sub rdx, rcx
    pop rdi
    call ShowAppend
    jmp .Done
.Func:
    ShowLit "<function>"
    jmp .Done
.Enum:
    mov rax, rbx
    dec rax
    cmp rax, [rdi + 16]
    jae .BadEnum
    shl rax, 4
    add rax, [rdi + 24]
    mov rcx, [rax]
    mov rdx, [rax + 8]
    call ShowAppend
    jmp .Done
.BadEnum:
    ShowLit "?"
    jmp .Done
.Text:
    test r13, r13
    jz .RawText
    ShowLit '"'
.RawText:
    lea rcx, [rbx + 8]
    mov rdx, [rbx]
    call ShowAppend
    test r13, r13
    jz .Done
    ShowLit '"'
    jmp .Done
.Bool:
    lea rcx, [rel StrTrue]
    mov edx, 4
    test rbx, rbx
    jnz .BoolOut
    lea rcx, [rel StrFalse]
    mov edx, 5
.BoolOut:
    call ShowAppend
    jmp .Done
.Dec:
    movq xmm0, rbx
    mov rcx, -1
    call FormatDec
    cmp qword [rel DecNeg], 0
    je .DecDigits
    ShowLit "-"
.DecDigits:
    lea rcx, [rel DecBuf]
    mov rdx, [rel DecLen]
    call ShowAppend
    jmp .Done
.List:
    ShowLit "["
    mov rsi, [rdi + 8]
    xor r12d, r12d
.ListLoop:
    cmp r12, [rbx]
    jae .ListEnd
    test r12, r12
    jz .ListItem
    ShowLit ", "
.ListItem:
    mov rax, [rbx + 16]
    mov rax, [rax + r12 * 8]
    mov rcx, rsi
    mov edx, 1
    call ShowValue
    inc r12
    jmp .ListLoop
.ListEnd:
    ShowLit "]"
    jmp .Done
.Map:
    ShowLit "{"
    mov rsi, [rdi + 8]
    xor r12d, r12d
.MapLoop:
    cmp r12, [rbx]
    jae .MapEnd
    test r12, r12
    jz .MapItem
    ShowLit ", "
.MapItem:
    mov rax, [rbx + 16]
    mov rax, [rax + r12 * 8]
    mov ecx, KText
    mov edx, 1
    call ShowValue
    ShowLit ": "
    mov rax, [rbx + 24]
    mov rax, [rax + r12 * 8]
    mov rcx, rsi
    mov edx, 1
    call ShowValue
    inc r12
    jmp .MapLoop
.MapEnd:
    ShowLit "}"
    jmp .Done
.Rec:
    ShowLit "{"
    xor r12d, r12d
.RecLoop:
    cmp r12, [rdi + 16]
    jae .RecEnd
    test r12, r12
    jz .RecItem
    ShowLit ", "
.RecItem:
    lea rax, [r12 + r12 * 2]
    mov rsi, [rdi + 24]
    lea rsi, [rsi + rax * 8]
    mov rcx, [rsi]
    mov rdx, [rsi + 8]
    call ShowAppend
    ShowLit ": "
    mov rax, [rbx + r12 * 8]
    mov rcx, [rsi + 16]
    mov edx, 1
    call ShowValue
    inc r12
    jmp .RecLoop
.RecEnd:
    ShowLit "}"
.Done:
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret

PrimShow:
    mov rcx, [r14]
    add r14, 8
    DPop rax
    mov qword [rel ShowLen], 0
    xor edx, edx
    call ShowValue
    lea rcx, [rel ShowBuf]
    mov rdx, [rel ShowLen]
    call MakeTextFrom
    DPush rax
    NEXT

FmtPut:
    cmp r12, 4000
    jae .Done
    lea rdx, [rel FmtBuf]
    mov [rdx + r12], al
    inc r12
.Done:
    ret

PrimFormat:
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    mov rbx, [r14]
    mov rsi, [r14 + 8]
    add r14, 16
    DPop rax
    xor r12d, r12d
    xor r13d, r13d
    mov rcx, rsi
    shl rcx, 5
    lea rdx, [rel TypeTable]
    mov rcx, [rdx + rcx]
    cmp rcx, KNum
    je .Number
    cmp rcx, KDec
    je .Decimal
    mov qword [rel ShowLen], 0
    mov rcx, rsi
    xor edx, edx
    call ShowValue
    lea rdi, [rel ShowBuf]
    mov r8, [rel ShowLen]
    xor r13d, r13d
    mov r10d, 1
    jmp .Pad
.Number:
    mov rcx, rbx
    shr rcx, 16
    and ecx, 0xFF
    cmp ecx, 0xFF
    je .Integer
    cvtsi2sd xmm0, rax
    jmp .Fixed
.Decimal:
    movq xmm0, rax
    mov rcx, rbx
    shr rcx, 16
    and ecx, 0xFF
    cmp ecx, 0xFF
    jne .Fixed
    mov rcx, -1
.Fixed:
    call FormatDec
    mov r13, [rel DecNeg]
    lea rdi, [rel DecBuf]
    mov r8, [rel DecLen]
    xor r10d, r10d
    jmp .Commas
.Integer:
    test rax, rax
    jns .IntPositive
    mov r13d, 1
    neg rax
.IntPositive:
    push rdi
    lea rdi, [rel DecBuf]
    call WriteUInt
    lea r8, [rel DecBuf]
    sub rdi, r8
    mov r8, rdi
    pop rdi
    lea rdi, [rel DecBuf]
    xor r10d, r10d
.Commas:
    test rbx, 1 << 28
    jz .Pad
    xor r9d, r9d
.FindDot:
    cmp r9, r8
    jae .GotInt
    cmp byte [rdi + r9], '.'
    je .GotInt
    inc r9
    jmp .FindDot
.GotInt:
    lea r11, [rel ShowBuf]
    xor ecx, ecx
    xor edx, edx
.CommaLoop:
    cmp rdx, r9
    jae .CommaRest
    test rdx, rdx
    jz .CommaDigit
    mov rax, r9
    sub rax, rdx
    push rdx
    xor edx, edx
    push rcx
    mov rcx, 3
    div rcx
    pop rcx
    test rdx, rdx
    pop rdx
    jnz .CommaDigit
    mov byte [r11 + rcx], ','
    inc rcx
.CommaDigit:
    mov al, [rdi + rdx]
    mov [r11 + rcx], al
    inc rcx
    inc rdx
    jmp .CommaLoop
.CommaRest:
    cmp rdx, r8
    jae .CommaDone
    mov al, [rdi + rdx]
    mov [r11 + rcx], al
    inc rcx
    inc rdx
    jmp .CommaRest
.CommaDone:
    mov rdi, r11
    mov r8, rcx
.Pad:
    xor r9d, r9d
    test r10, r10
    jnz .NoSign
    test r13, r13
    jz .MaybePlus
    mov r9b, '-'
    jmp .NoSign
.MaybePlus:
    test rbx, 1 << 26
    jz .NoSign
    mov r9b, '+'
.NoSign:
    mov rcx, rbx
    and ecx, 0xFFFF
    mov rdx, r8
    test r9, r9
    jz .LenKnown
    inc rdx
.LenKnown:
    xor r11d, r11d
    cmp rcx, rdx
    jbe .NoFill
    mov r11, rcx
    sub r11, rdx
.NoFill:
    mov rax, rbx
    shr rax, 24
    and eax, 3
    test eax, eax
    jnz .AlignKnown
    mov eax, 2
    test r10, r10
    jz .AlignKnown
    mov eax, 1
.AlignKnown:
    test r10, r10
    jnz .SpaceFill
    test rbx, 1 << 27
    jz .SpaceFill
    test r9, r9
    jz .ZeroFill
    mov al, r9b
    call FmtPut
    xor r9d, r9d
.ZeroFill:
    test r11, r11
    jz .Body
    mov al, '0'
    call FmtPut
    dec r11
    jmp .ZeroFill
.SpaceFill:
    cmp eax, 2
    jne .Sign
.LeftSpaces:
    test r11, r11
    jz .Sign
    mov al, ' '
    call FmtPut
    dec r11
    jmp .LeftSpaces
.Sign:
    test r9, r9
    jz .Body
    mov al, r9b
    call FmtPut
.Body:
    xor ecx, ecx
.BodyLoop:
    cmp rcx, r8
    jae .Right
    mov al, [rdi + rcx]
    push rcx
    call FmtPut
    pop rcx
    inc rcx
    jmp .BodyLoop
.Right:
    test r11, r11
    jz .Make
    mov al, ' '
    call FmtPut
    dec r11
    jmp .Right
.Make:
    lea rcx, [rel FmtBuf]
    mov rdx, r12
    call MakeTextFrom
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    DPush rax
    NEXT
