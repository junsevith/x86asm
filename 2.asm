SECTION .data
    num     db      0

SECTION .bss
    buffer  resb    16

SECTION .text
global  main
 
main:
    call read_int
    add eax, eax
    add eax, eax
    push eax
    call write_int
    call exit


read_int:
    push ebp
    mov ebp, esp

    mov eax, 3          ; syscall czytania
    mov ebx, 0          ; stdin
    lea ecx, [buffer]   ; tu zapisujemy adres bufora
    mov edx, 16         ; maksymalna długość czytanego stringa
    int 0x80            ; wywołanie syscalla

    ; Convert string to number
    xor eax, eax        ; zeruje eax
    lea esi, [buffer]   ; zapisujemy adres buffer do esi

convert_loop:
    movzx edx, byte [esi]   ; powiększa wartość esi zerami i zapisuje go do edx
    cmp dl, 0x0A            ; sprawdza czy edx zawiera newline character (koniec stringa)
    je convert_done                 ; jeśli tak to kończy
    imul eax, 10            ; jeśli nie to mnoży eax * 10
    sub edx, '0'            ; odejmuje od edx wartość liczbową znaku '0' aby uzyskać wartość liczbową znaku
    add eax, edx            ; dodaje edx do eax
    inc esi                 ; inkrementuje esi (przechodzi do kolejnego znaku)
    jmp convert_loop

convert_done:
    mov esp, ebp
    pop ebp
    ret

write_int:
    push ebp
    mov ebp, esp

; Convert number to string
    mov eax, [ebp + 8]  ; eax = argument 1
    lea edi, [buffer + 15]
    mov byte [edi], 0x0A   ; newline character

reconvert:
    dec edi         ; dekrementuje edi (przechodzi do poprzedniego znaku)
    xor edx, edx    ; zeruje edx
    mov ecx, 10     ; zapisuje 10 do ecx
    div ecx         ; dzieli eax przez ecx i zapisuje wynik do eax, resztę do edx
    add dl, '0'     ; dodaje '0' do edx
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

    mov esp, ebp
    pop ebp
    ret

exit:
    mov     ebx, 0      ; return 0 status on exit - 'No Errors'
    mov     eax, 1      ; invoke SYS_EXIT (kernel opcode 1)
    int     80h