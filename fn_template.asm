fn:
    push ebp
    mov ebp, esp

    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi

fn_fin:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax

    mov esp, ebp
    pop ebp
    ret