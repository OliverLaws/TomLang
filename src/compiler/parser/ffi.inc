FfiTypeName:
    IfTok "number", .Num
    IfTok "int", .Int
    IfTok "uint", .UInt
    IfTok "decimal", .Dec
    IfTok "float", .Float
    IfTok "bool", .Bool
    IfTok "text", .Text
    IfTok "do", .Callback
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call FindWord
    test rax, rax
    jz .Bad
    cmp rdx, 8
    jne .Bad
    mov rdx, rax
    mov r8, rax
    mov rax, [rax + 32]
    ret
.Callback:
    jmp FfiCallbackType
.Bad:
    Fail ErrFfiType
.Num:
    xor r10d, r10d
    mov eax, TNum
    xor edx, edx
    mov r8d, 1
    ret
.Int:
    xor r10d, r10d
    mov eax, TNum
    xor edx, edx
    mov r8d, 5
    ret
.UInt:
    xor r10d, r10d
    mov eax, TNum
    xor edx, edx
    mov r8d, 6
    ret
.Dec:
    mov eax, TDec
    mov edx, 1
    mov r8d, 2
    ret
.Float:
    xor r10d, r10d
    mov eax, TDec
    mov edx, 3
    mov r8d, 7
    ret
.Bool:
    xor r10d, r10d
    mov eax, TBool
    xor edx, edx
    mov r8d, 3
    ret
.Text:
    mov eax, TText
    mov edx, 2
    mov r8d, 4
    ret

ZeroName:
    cmp rdx, 250
    ja .Long
    lea rdi, [rel FfiName]
    mov rsi, rcx
    mov rcx, rdx
    rep movsb
    mov byte [rdi], 0
    lea rax, [rel FfiName]
    ret
.Long:
    Fail ErrFfiLoad

DllAlias:
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    lea r8, [rcx + rdx]
    xor r9d, r9d
.Scan:
    movzx eax, byte [r8]
    cmp eax, 10
    je .None
    cmp eax, 13
    je .None
    test eax, eax
    jz .None
    cmp eax, '('
    jne .NotOpen
    inc r9
.NotOpen:
    cmp eax, ')'
    jne .NotClose
    dec r9
.NotClose:
    test r9, r9
    jnz .Next
    cmp eax, ' '
    jne .Next
    cmp word [r8 + 1], 'as'
    jne .Next
    cmp byte [r8 + 3], ' '
    jne .Next
    lea r10, [r8 + 4]
.Spaces:
    cmp byte [r10], ' '
    jne .Quote
    inc r10
    jmp .Spaces
.Quote:
    cmp byte [r10], 34
    jne .Next
    inc r10
    mov r11, r10
.Find:
    movzx eax, byte [r11]
    cmp eax, 34
    je .Found
    cmp eax, 10
    je .None
    test eax, eax
    jz .None
    inc r11
    jmp .Find
.Found:
    mov rcx, r10
    mov rdx, r11
    sub rdx, r10
    test rdx, rdx
    jz .None
    ret
.Next:
    inc r8
    jmp .Scan
.None:
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    ret

DllWord:
    cmp qword [rel InFn], 0
    jne .Where
    cmp qword [rel OpenBlocks], 0
    jne .Where
    call Advance
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    cmp rdx, 3
    jb .BadName
    cmp byte [rcx], 34
    jne .BadName
    inc rcx
    sub rdx, 2
    call ZeroName
    mov rcx, rax
    call SysLoadLib
    test rax, rax
    jz .NoLib
    mov [rel FfiLib], rax
.Line:
    call Advance
    cmp qword [rel TokLen], 0
    je .MissingEnd
    IfTok "end", .Done
    IfTok "struct", .Struct
    Expect "do", ErrFfiDo
    call Advance
    call IsNameStart
    test eax, eax
    jz .BadFn
    call DllAlias
    call ZeroName
    mov rdx, rax
    mov rcx, [rel FfiLib]
    call SysGetProc
    test rax, rax
    jz .NoProc
    mov [rel FfiProc], rax
    mov rax, [rel Here]
    mov [rel FfiSavedHere], rax
    mov rax, [rel DictHere]
    mov [rel Here], rax
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call CreateEntry
    mov rax, [rel Latest]
    mov [rel FfiEntry], rax
    mov byte [rax + 16], 4
    mov ebx, SigCells
.Sig:
    xor ecx, ecx
    call Compile
    dec ebx
    jnz .Sig
    mov rax, [rel Here]
    mov [rel FfiSig], rax
    mov rcx, [rel FfiEntry]
    mov [rcx + 8], rax
    mov qword [rel FfiArgc], 0
    call Advance
    Expect "(", ErrParen
    call Advance
    IfTok ")", .ParamsDone
.Param:
    call IsNameStart
    test eax, eax
    jz .BadFn
    mov rbx, [rel FfiArgc]
    cmp rbx, 16
    jae .TooMany
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    push rdx
    call CopyString
    pop rdx
    mov r8, [rel FfiSig]
    mov r9, rbx
    shl r9, 4
    neg r9
    mov [r8 - SigName + r9], rax
    mov [r8 - SigName - 8 + r9], rdx
    call Advance
    IfTok ":", .ParamType
    mov eax, TNum
    xor edx, edx
    jmp .ParamSet
.ParamType:
    call Advance
    call FfiTypeName
    push rax
    push rdx
    call Advance
    pop rdx
    pop rax
.ParamSet:
    mov r8, [rel FfiSig]
    mov r9, rbx
    shl r9, 3
    neg r9
    mov [r8 - 24 + r9], rax
    lea rcx, [rel FfiKindArr]
    mov [rcx + rbx * 8], rdx
    inc qword [rel FfiArgc]
    IfTok ",", .Comma
    Expect ")", ErrParen
.ParamsDone:
    mov r8, [rel FfiSig]
    mov rax, [rel FfiArgc]
    mov [r8 - 16], rax
    mov qword [r8 - 8], 0
    mov qword [rel FfiRet], 0
    call Advance
    IfTok ":", .Ret
    jmp .Emit
.Ret:
    call Advance
    call FfiTypeName
    mov r9, [rel FfiSig]
    mov [r9 - 8], rax
    mov [rel FfiRet], r8
    call Advance
.Emit:
    IfTok "as", .Alias
    jmp .EmitCall
.Alias:
    call Advance
    call Advance
.EmitCall:
    CompilePrim PrimFfiCall
    mov rcx, [rel FfiProc]
    call Compile
    mov rcx, [rel FfiArgc]
    call Compile
    mov rcx, [rel FfiArgc]
    shl rcx, 3
    add rcx, 8
    call PermAlloc
    mov rbx, rax
    xor ecx, ecx
.CopyKinds:
    cmp rcx, [rel FfiArgc]
    jae .KindsDone
    lea rdx, [rel FfiKindArr]
    mov rdx, [rdx + rcx * 8]
    mov [rbx + rcx * 8], rdx
    inc rcx
    jmp .CopyKinds
.KindsDone:
    mov rcx, rbx
    call Compile
    mov rcx, [rel FfiRet]
    call Compile
    CompilePrim PrimExit
    mov rax, [rel Here]
    mov [rel DictHere], rax
    mov rax, [rel FfiSavedHere]
    mov [rel Here], rax
    mov rcx, [rel TokPtr]
    call Unread
    jmp .Line
.Comma:
    call Advance
    jmp .Param
.Struct:
    call StructDecl
    mov rcx, [rel TokPtr]
    call Unread
    jmp .Line
.Done:
    ret
.Where:
    Fail ErrFfiWhere
.BadName:
    Fail ErrFfiName
.NoLib:
    FailTok ErrFfiLoad
.NoProc:
    FailTok ErrFfiProc
.BadFn:
    FailTok ErrFfiDo
.TooMany:
    Fail ErrTooMany
.MissingEnd:
    Fail ErrFfiEnd

StructDecl:
    call Advance
    call IsNameStart
    test eax, eax
    jz .BadName
    mov rax, [rel TokPtr]
    mov [rel StructNamePtr], rax
    mov rax, [rel TokLen]
    mov [rel StructNameLen], rax
    call Advance
    Expect "=", ErrStructEq
    mov qword [rel StructCount], 0
    mov qword [rel StructOffset], 0
    mov qword [rel StructAlign], 1
.Field:
    call Advance
    call IsNameStart
    test eax, eax
    jz .BadName
    mov rbx, [rel StructCount]
    cmp rbx, 32
    jae .Many
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    push rdx
    call CopyString
    pop rdx
    mov r8, rbx
    shl r8, 6
    lea r9, [rel StructFields]
    add r9, r8
    mov [r9], rax
    mov [r9 + 8], rdx
    push r9
    call Advance
    Expect ":", ErrStructEq
    call Advance
    call StructFieldType
    pop r9
    mov [r9 + 16], rax
    mov [r9 + 24], rdx
    mov [r9 + 32], r10
    mov [r9 + 48], r8
    mov rax, [rel StructOffset]
    lea rax, [rax + rcx - 1]
    mov r11, rcx
    neg r11
    and rax, r11
    mov [r9 + 40], rax
    add rax, r8
    mov [rel StructOffset], rax
    cmp rcx, [rel StructAlign]
    jbe .AlignOk
    mov [rel StructAlign], rcx
.AlignOk:
    inc qword [rel StructCount]
    call Advance
    IfTok ",", .Field
    mov rax, [rel StructOffset]
    mov rcx, [rel StructAlign]
    lea rax, [rax + rcx - 1]
    neg rcx
    and rax, rcx
    mov [rel StructSize], rax
    mov rax, [rel TempTop]
    push rax
    xor ebx, ebx
.Temp:
    cmp rbx, [rel StructCount]
    jae .Intern
    mov r8, rbx
    shl r8, 6
    lea r9, [rel StructFields]
    add r9, r8
    mov rax, [rel TempTop]
    mov rcx, [r9]
    mov [rax], rcx
    mov rcx, [r9 + 8]
    mov [rax + 8], rcx
    mov rcx, [r9 + 16]
    mov [rax + 16], rcx
    add qword [rel TempTop], 24
    call TempRoom
    inc rbx
    jmp .Temp
.Intern:
    mov rcx, [rel StructCount]
    mov rdx, [rsp]
    call InternRecord
    pop rcx
    mov [rel TempTop], rcx
    mov [rel StructType], rax
    mov rcx, [rel StructCount]
    shl rcx, 5
    add rcx, 40
    call PermAlloc
    mov rbx, rax
    mov qword [rbx], 1
    mov rax, [rel StructSize]
    mov [rbx + 8], rax
    mov rax, [rel StructAlign]
    mov [rbx + 16], rax
    mov rax, [rel StructCount]
    mov [rbx + 24], rax
    mov rax, [rel StructType]
    mov [rbx + 32], rax
    xor esi, esi
.Desc:
    cmp rsi, [rel StructCount]
    jae .Register
    mov r8, rsi
    shl r8, 6
    lea r9, [rel StructFields]
    add r9, r8
    mov rdi, rsi
    shl rdi, 5
    lea rdi, [rbx + 40 + rdi]
    mov rax, [r9 + 24]
    mov [rdi], rax
    mov rax, [r9 + 40]
    mov [rdi + 8], rax
    mov rax, [r9 + 32]
    mov [rdi + 24], rax
    push rdi
    push rsi
    mov rcx, [rel StructType]
    mov rdx, [r9]
    mov r8, [r9 + 8]
    call FindField
    pop rsi
    pop rdi
    mov [rdi + 16], rax
    inc rsi
    jmp .Desc
.Register:
    mov rax, [rel Here]
    mov [rel FfiSavedHere], rax
    mov rax, [rel DictHere]
    mov [rel Here], rax
    mov rcx, [rel StructNamePtr]
    mov rdx, [rel StructNameLen]
    call CreateEntry
    mov rax, [rel Latest]
    mov byte [rax + 16], 8
    mov [rax + 8], rbx
    mov rax, [rel Here]
    mov [rel DictHere], rax
    mov rax, [rel FfiSavedHere]
    mov [rel Here], rax
    ret
.BadName:
    FailTok ErrFfiDo
.Many:
    Fail ErrTooManyFields

StructFieldType:
    IfTok "byte", .Byte
    IfTok "short", .Short
    IfTok "int", .Int
    IfTok "uint", .UInt
    IfTok "number", .Num
    IfTok "float", .Float
    IfTok "decimal", .Double
    IfTok "bool", .Bool
    mov rcx, [rel TokPtr]
    mov rdx, [rel TokLen]
    call FindWord
    test rax, rax
    jz .Bad
    cmp rdx, 8
    jne .Bad
    mov r10, rax
    mov r8, [r10 + 8]
    mov rcx, [r10 + 16]
    mov edx, 9
    mov rax, [r10 + 32]
    ret
.Byte:
    xor r10d, r10d
    mov eax, TNum
    mov edx, 1
    mov r8d, 1
    mov ecx, 1
    ret
.Short:
    xor r10d, r10d
    mov eax, TNum
    mov edx, 2
    mov r8d, 2
    mov ecx, 2
    ret
.Int:
    xor r10d, r10d
    mov eax, TNum
    mov edx, 3
    mov r8d, 4
    mov ecx, 4
    ret
.UInt:
    xor r10d, r10d
    mov eax, TNum
    mov edx, 4
    mov r8d, 4
    mov ecx, 4
    ret
.Num:
    xor r10d, r10d
    mov eax, TNum
    mov edx, 5
    mov r8d, 8
    mov ecx, 8
    ret
.Float:
    xor r10d, r10d
    mov eax, TDec
    mov edx, 6
    mov r8d, 4
    mov ecx, 4
    ret
.Double:
    xor r10d, r10d
    mov eax, TDec
    mov edx, 7
    mov r8d, 8
    mov ecx, 8
    ret
.Bool:
    xor r10d, r10d
    mov eax, TBool
    mov edx, 8
    mov r8d, 1
    mov ecx, 1
    ret
.Bad:
    Fail ErrStructType

FfiCallbackType:
    push rbx
    sub rsp, 288
    mov qword [rsp + 256], 0
    mov qword [rsp + 264], 0
    call Advance
    Expect "(", ErrParen
    call Advance
    IfTok ")", .Params
.Param:
    mov rbx, [rsp + 256]
    cmp rbx, 8
    jae .Many
    call FfiTypeName
    cmp rdx, 4096
    jae .Bad
    mov rbx, [rsp + 256]
    mov [rsp + rbx * 8], rax
    mov [rsp + 128 + rbx * 8], r8
    inc qword [rsp + 256]
    call Advance
    IfTok ",", .Comma
    Expect ")", ErrParen
.Params:
    push qword [rel TokPtr]
    push qword [rel TokLen]
    call Advance
    IfTok ":", .Ret
    mov rcx, [rel TokPtr]
    call Unread
    pop qword [rel TokLen]
    pop qword [rel TokPtr]
    jmp .Make
.Ret:
    add rsp, 16
    call Advance
    call FfiTypeName
    cmp rdx, 4096
    jae .Bad
    mov [rsp + 264], r8
    mov [rsp + 272], rax
.Make:
    mov rcx, [rsp + 256]
    shl rcx, 3
    add rcx, 24
    call PermAlloc
    mov rbx, rax
    mov qword [rbx], 2
    mov rcx, [rsp + 256]
    mov [rbx + 8], rcx
    mov rcx, [rsp + 264]
    mov [rbx + 16], rcx
    xor ecx, ecx
.Copy:
    cmp rcx, [rsp + 256]
    jae .Copied
    mov rax, [rsp + 128 + rcx * 8]
    mov [rbx + 24 + rcx * 8], rax
    inc rcx
    jmp .Copy
.Copied:
    xor ecx, ecx
    cmp qword [rsp + 264], 0
    je .NoRet
    mov rcx, [rsp + 272]
.NoRet:
    mov rdx, [rsp + 256]
    mov r8, rsp
    call FuncOf
    mov rdx, rbx
    mov r8d, 1
    add rsp, 288
    pop rbx
    ret
.Comma:
    call Advance
    jmp .Param
.Many:
    Fail ErrTooMany
.Bad:
    Fail ErrFfiType
