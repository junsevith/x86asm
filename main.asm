SECTION .data
    ten     dd      10.0
    numb    dd      0.0
    res     dd      0.0
    prec    dd      5
    tenpow dd      10000.0

SECTION .bss
    buffer  resb    16
    buffer2  resb    16


SECTION .text
global  main
 
main:    
    mov ebp, esp; for correct debugging
    call read_float
    mov [numb],eax
    

calculate:              ; wywołujemy wszystkie funkcje dla wejścia
    finit
    push DWORD [numb]
    call display_float
    
    fld DWORD [numb]
    fsin
    fstp DWORD [res]
    push DWORD [res]
    call display_float

    fld DWORD [numb]
    fcos
    fstp DWORD [res]
    push DWORD [res]
    call display_float
    
    fld DWORD [numb]
    fsqrt
    fstp DWORD [res]
    push DWORD [res]
    call display_float
    
    
    ; Computes e^x via the formula 2^(x * log2(e))
    fldl2e                  ; st(0) = log2(e)        <-- load log2(e)
    fmul DWORD [numb]       ; st(0) = x * log2(e)
    fld1                    ; st(0) = 1              <-- load 1
                            ; st(1) = x * log2(e)
    fld     st1             ; st(0) = x * log2(e)    <-- make copy of intermediate result
                            ; st(1) = 1
                            ; st(2) = x * log2(e)
    fprem                   ; st(0) = partial remainder((x * log2(e)) / 1)  <-- call this "rem"
                            ; st(1) = 1
                            ; st(2) = x * log2(e)
    f2xm1                   ; st(0) = 2^(rem) - 1
                            ; st(1) = 1
                            ; st(2) = x * log2(e)
    faddp   st1, st0        ; st(0) = 2^(rem) - 1 + 1 = 2^(rem)
                            ; st(1) = x * log2(e)
    fscale                  ; st(0) = 2^(rem) * 2^(trunc(x * log2(e)))
                            ; st(1) = x * log2(e)
    fstp    st1
    fstp DWORD [res]
    push DWORD [res]
    call display_float

    call exit
    
;Function display float --------------------------
display_float:
    push ebp
    mov ebp, esp

    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi

    xor eax, eax
    finit
    fld DWORD [ebp+8]
    fmul DWORD [tenpow]
    push 0
    fist DWORD [esp]
    
    ; Convert number to string
    mov eax, [esp]  ; eax = argument 1
    mov ebx, [prec]
    mov ecx, 10
    lea edi, [buffer2 + 15]
    mov byte [edi], 0x0A   ; newline character
    xor esi, esi

    cmp eax, 0
    jge freconvert
    neg eax
    mov esi,1

freconvert:
    dec edi         ; dekrementuje edi (przechodzi do poprzedniego znaku)
    cmp ebx,0
    dec ebx
    je set_dot
    
    xor edx, edx    ; zeruje edx
    div ecx         ; dzieli eax przez ecx i zapisuje wynik do eax, resztę do edx

    add dl, '0'     ; dodaje wartość int '0' do edx
    jmp fadd_char
    
set_dot:
    mov dl, 46

fadd_char:
    mov [edi], dl   ; zapisuje edx do edi
    test eax, eax   ; sprawdza czy eax jest zerem
    jnz freconvert
    
    cmp ebx, -1
    jg freconvert
    
    cmp esi, 0
    je syscall
    mov dl, 45
    dec edi
    xor esi,esi
    jmp fadd_char
    
syscall:
    ; Write to console
    mov eax, 4    ; write syscall
    mov ebx, 1    ; stdout
    lea ecx, [edi]  ; ecx = pointer to string
    lea edx, [buffer2 + 16]  ; 16 = 15 znaków + 1 newline character
    sub edx, ecx    ; oblicza długość stringa
    int 0x80        ; call kernel


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
    
    
; Function read float --------------------------------
read_float:
    push ebp
    mov ebp, esp

    mov eax, 3          ; syscall czytania
    mov ebx, 0          ; stdin
    lea ecx, [buffer]   ; tu zapisujemy adres bufora
    mov edx, 16         ; maksymalna długość czytanego stringa
    int 0x80            ; wywołanie syscalla

    ; Convert string to number
    xor eax, eax        ; zeruje eax
    xor ebx, ebx
    xor ecx, ecx
    lea esi, [buffer]   ; zapisujemy adres buffer do esi

convert_loop:
    movzx edx, byte [esi]   ; powiększa wartość esi zerami i zapisuje go do edx
    cmp dl, 0x0A            ; sprawdza czy edx zawiera newline character (koniec stringa)
    je convert_done                 ; jeśli tak to kończy
    
    cmp dl, 46
    je fraction
    cmp dl, 44
    je fraction
    
    cmp dl, 45
    je minus
    
    imul eax, 10            ; jeśli nie to mnoży eax * 10
    sub edx, '0'            ; odejmuje od edx wartość liczbową znaku '0' aby uzyskać wartość liczbową znaku
    add eax, edx            ; dodaje edx do eax
    inc esi                 ; inkrementuje esi (przechodzi do kolejnego znaku)
    jmp convert_loop

fraction:
    mov ebx, esi    ; zapisujemy miejsce przecinka
    inc esi
    jmp convert_loop
    
minus:
    mov ecx, 1
    inc esi
    jmp convert_loop

convert_done:
    cmp ebx, 0
    je wr_fin

prepare_float:
     sub ebx, esi
     neg ebx
     dec ebx
     jmp wr_fin
     
negate:
    neg eax
    xor ecx,ecx

wr_fin:
     cmp ecx, 1
     je negate
     push eax
     finit
     fild DWORD [esp]    ; ładujemy wejście pomijając przecinek

    
pow_ten:                ; dzielimy wejście przez 10^pozycja przecinka
    cmp ebx, 0
    jle finfin
    dec ebx
    fdiv DWORD [ten]
    jmp pow_ten

finfin:    
    fst DWORD [esp]
    mov eax, [esp]

    mov esp, ebp
    pop ebp
    ret


; function write --------------------------------
write_int_bin:
    push ecx
    mov ecx, 2             ; ustalamy bazę przez którą będziemy dzielić
    jmp write_int

write_int_dec:
    push ecx
    mov ecx, 10             ; ustalamy bazę przez którą będziemy dzielić

write_int:
    push ebp
    mov ebp, esp

    push eax
    push ebx
    push edx
    push esi
    push edi

; Convert number to string
    mov eax, [ebp + 12]  ; eax = argument 1
    lea edi, [buffer + 15]
    mov byte [edi], 0x0A   ; newline character

reconvert:
    dec edi         ; dekrementuje edi (przechodzi do poprzedniego znaku)
    xor edx, edx    ; zeruje edx
    div ecx         ; dzieli eax przez ecx i zapisuje wynik do eax, resztę do edx

    cmp dl, 10      ; sprawdza czy edx jest większe od 10 (dl to ostatni bajt edx)
    jge above_ten

    add dl, '0'     ; dodaje wartość int '0' do edx
    jmp add_char

above_ten:
    add dl, 'A' - 10    ; dodaje 'A' - 10 do edx tak aby 10 mapowało na A itd.

add_char:
    mov [edi], dl   ; zapisuje edx do edi
    test eax, eax   ; sprawdza czy eax jest zerem
    jnz reconvert

    ; Write to console
    mov eax, 4    ; write syscall
    mov ebx, 1    ; stdout
    lea ecx, [edi]  ; ecx = pointer to string
    lea edx, [buffer + 16]  ; 16 = 15 znaków + 1 newline character
    sub edx, ecx    ; oblicza długość stringa
    int 0x80        ; call kernel

    pop edi
    pop esi
    pop edx
    pop ebx
    pop eax

    mov esp, ebp
    pop ebp
    pop ecx
    ret

exit:
    mov     ebx, 0      ; return 0 status on exit - 'No Errors'
    mov     eax, 1      ; invoke SYS_EXIT (kernel opcode 1)
    int     80h