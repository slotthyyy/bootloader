bits 16
org 0x7c00

jmp start
%include "stdio.h"

stack equ 0x7c00
start:
    mov ax,cs
    mov es,ax
    mov ds,ax
    mov ss,ax
    mov sp,stack

    printf "Hello, World!"

    hlt
 .loop:
    nop
    jmp .loop

times (510 - ($ - $$)) db 0x00

dw 0xAA55