; stdio.h
; Change these two lines to switch to 16 bit version
bits 16
%define sz  2	; bits/8
; ---

%if sz = 4
 %define _printf    _printf32
 %define regax      eax
%else
 %define _printf    _printf16
 %define regax      ax
%endif

; printf :: String -> Bool
%macro printf 1
 %if sz = 4
  section .text
 %endif

    mov regax,%%buffer
    push regax
    call _printf

 %if sz = 4
  section .data
 %else
  jmp %%end
 %endif
    %%buffer:
        db %1
        dw nl
        db 0x00
    %%end:
 %if sz = 4
  section .text
 %endif
%endmacro

; printf :: String -> Word16 -> Bool
%macro printf 2
 %if sz = 4
  section .text
 %endif

    mov regax,%2
    push regax
    mov regax,%%buffer
    push regax
    call _printf

 %if sz = 4
  section .data
 %else
  jmp %%end
 %endif
    %%buffer:
        db %1
        dw nl
        db 0x00
    %%end:
 %if sz = 4
  section .text
 %endif
%endmacro

; printf :: String -> Word16 -> Word16 -> Bool
%macro printf 3
 %if sz = 4
  section .text
 %endif

    mov regax,%3
    push regax
    mov regax,%2
    push regax
    mov regax,%%buffer
    push regax
    call _printf

 %if sz = 4
  section .data
 %else
  jmp %%end
 %endif
    %%buffer:
        db %1
        dw nl
        db 0x00
    %%end:
 %if sz = 4
  section .text
 %endif
%endmacro

; printf :: String -> Word16 -> Word16 -> Word16 -> Bool
%macro printf 4
 %if sz = 4
  section .text
 %endif

    mov regax,%4
    push regax
    mov regax,%3
    push regax
    mov regax,%2
    push regax
    mov regax,%%buffer
    push regax
    call _printf

 %if sz = 4
  section .data
 %else
  jmp %%end
 %endif
    %%buffer:
        db %1
        dw nl
        db 0x00
    %%end:
 %if sz = 4
  section .text
 %endif
%endmacro

; printf :: String -> Word16 -> Word16 -> Word16 -> Word16 -> Bool
%macro printf 5
 %if sz = 4
  section .text
 %endif

    mov regax,%5
    push regax
    mov regax,%4
    push regax
    mov regax,%3
    push regax
    mov regax,%2
    push regax
    mov regax,%%buffer
    push regax
    call _printf

 %if sz = 4
  section .data
 %else
  jmp %%end
 %endif
    %%buffer:
        db %1
        dw nl
        db 0x00
    %%end:
 %if sz = 4
  section .text
 %endif
%endmacro

%if sz = 4
    %include "stdio32.asm"
%else
    %include "stdio16.asm"
%endif
