; Hello World Program - asmtutor.com
; Compile with: nasm -f elf helloworld.asm
; Link with (64 bit systems require elf_i386 option): ld -m elf_i386 helloworld.o -o helloworld
; Run with: ./helloworld
 
SECTION .data
msg     db      'Hello World!', 0Ah
len     equ     $ - msg    ; '$' means 'here', so this is the length of the string msg
 
SECTION .text
global  main
 
main:
 
    mov     edx, len    ; arg3 - length of string
    mov     ecx, msg    ; arg2 - pointer to string
    mov     ebx, 1      ; arg1 - where to write, 1 = stdout
    mov     eax, 4      ; invoke SYS_WRITE (kernel opcode 4)
    int     80h         ; call kernel
 
    mov     ebx, 0      ; return 0 status on exit - 'No Errors'
    mov     eax, 1      ; invoke SYS_EXIT (kernel opcode 1)
    int     80h