; stdio16.asm
%define putchar     putchar16
%define printstr    printstr16
%define printhex    printhex16
%define printint    printint16

; _printf :: String -> [Word16] -> Bool
_printf16:
    .init:
        push bx
        push cx
        push si
        push di

        push bp
        mov bp,sp
        add bp,(4*sz)

        mov ax,[bp+(2*sz)]
        mov si,ax
        xor bx,bx
        xor cx,cx
        inc cx
        clc

    .loop:
        mov ax,0x00
        lodsb
        jc .special

        cmp al,'%'
        je .percent
        or al,al
        jz .end

        push ax
        call putchar
        clc
        jmp .loop

    .percent:
        stc
        jmp .loop

    .special:
        push ax
        mov ax,0x02
        add ax,cx
        mov bx,sz
        mul bl
        mov di,ax
        mov ax,[bp+di]
        pop bx
        push ax
        inc cx

        cmp bl,'%'
        je .percent2
        cmp bl,'d'
        je .int
        cmp bl,'x'
        je .hex
        cmp bl,'s'
        je .str
        cmp bl,'c'
        je .char
        pop ax
        jmp .spcend

    .percent2:
        pop ax
        push bx
        call putchar
        jmp .spcend

    .int:
        call printint
        jmp .spcend

    .hex:
        call printhex
        jmp .spcend

    .str:
        call printstr
        jmp .spcend

    .char:
        call putchar
    
    .spcend:
        clc
        jmp .loop

    .end:
        sub bp,(4*sz)
        mov sp,bp
        pop bp

        pop di
        pop si
        pop cx
        pop bx

        mov ax,0x01

        ret

; putchar :: Char -> Bool
putchar16:
    push bx
    push bp
    mov bp,sp
    add bp,(1*sz)

    mov ax,[bp+(2*sz)]
    xor bx,bx

    mov ah,0x0e
    int 0x10

    sub bp,(1*sz)
    mov sp,bp
    pop bp

    pop bx
    mov ax,0x01

    ret

; printstr :: String -> Bool
printstr16:
    push si
    push bp
    mov bp,sp
    add bp,(1*sz)

    mov ax,[bp+(2*sz)]
    mov si,ax

.loop:
    xor ax,ax
    mov byte al,[si]
    or al,al
    jz .done

    push ax
    call putchar
    inc si
    jmp .loop

.done:
    sub bp,(1*sz)
    mov sp,bp
    pop bp
    pop si
    mov ax,0x01

    ret

; printint :: Word16 -> Bool
printint16:
    push bx
    push cx
    push dx
    push di

    push bp
    mov bp,sp
    add bp,(4*sz)

    mov ax,buf
    mov di,ax
    mov ax,[bp+(2*sz)]
    mov cx,0x06
    add di,cx
    mov byte [di],0x00

    dec cx
    xor bx,bx
    xor dx,dx

.loop:
    dec di
    mov bx,0x0a
    div bx
    call .digit
    xor dx,dx
    loop .loop

    xor ax,ax
    mov cx,0x04

 .zeroloop:
    mov byte al,[di]
    cmp al,0x30
    jne .pr
    inc di
    loop .zeroloop

.pr:
    mov ax,di
    push ax
    call printstr

    sub bp,(4*sz)
    mov sp,bp
    pop bp

    pop di
    pop dx
    pop cx
    pop bx

    mov ax,0x01

    ret

.digit:
    push bp
    mov bp,sp

    add dl,0x30
    mov byte [di],dl

    mov sp,bp
    pop bp
    ret

; printhex :: Word16 -> Bool
printhex16:
    push bp
    mov bp,sp
    mov ax,[bp+(2*sz)]

 .dig01:
    and ax,0xf000
    shr ax,12
    call .digit

 .dig02:
    mov ax,[bp+(2*sz)]
    and ax,0x0f00
    shr ax,8
    call .digit

 .dig03:
    mov ax,[bp+(2*sz)]
    and ax,0x00f0
    shr ax,4
    call .digit

 .dig04:
    mov ax,[bp+(2*sz)]
    and ax,0x000f
    call .digit

 .end:
    mov sp,bp
    pop bp
    mov ax,0x01

    ret

 .digit:
    push bp
    mov bp,sp

    cmp al,0x09
    jg .hexdigit
    add al,0x30
    jmp .enddigit

  .hexdigit:
    add al,0x57

  .enddigit:
    push ax
    call putchar

    mov sp,bp
    pop bp

    ret

data:
    nl  equ 0x0a0d
    buf times 64 db 0x00
