# Bootloader

This is a small **16-bit x86 BIOS bootloader**. Its current behavior is:

1. The BIOS loads the first 512-byte sector into memory at `0x7C00`.
2. The bootloader initializes the segment registers and a stack.
3. It prints `Hello, World!` using BIOS video services.
4. It halts forever.
5. It does **not** load or execute a kernel yet.

## Project structure

- `loader.asm` - the boot-sector entry point.
- `include/stdio.h` - NASM macros for `printf`.
- `include/stdio16.asm` - 16-bit formatting and BIOS output routines.
- `Makefile` - build, clean, and QEMU run commands.
- `loader.ld` - an unused linker script retained for reference.

## Build process

Running `make` assembles `loader.asm` into a flat binary:

```sh
nasm -f bin -i include/ -o loader.img loader.asm
```

Important options:

- `-f bin` produces a raw binary rather than an object file or executable.
- `-i include/` lets NASM find files in `include/`.
- `-o loader.img` selects the output file.

The `kernel.img` target creates a 512-byte file full of zeroes:

```sh
dd if=/dev/zero of=kernel.img bs=1 count=512
```

The bootloader currently never reads `kernel.img`; it is only attached as a
second disk by QEMU.

`loader.ld` is currently unused. It is a linker script, but this project uses
NASM directly to generate a flat binary, so no linker runs.

## Why `loader.asm` is a boot sector

```asm
bits 16
org 0x7c00
```

`bits 16` tells NASM to generate 16-bit instructions. `org 0x7c00` tells the
assembler that the code will be loaded at physical address `0x7C00`.

The BIOS convention is to:

- Read the first sector of the boot disk.
- Place it at `0x7C00`.
- Start executing it there.

The boot sector must be exactly 512 bytes and end with the signature:

```asm
dw 0xAA55
```

Because x86 is little-endian, this produces the bytes `55 AA` at offsets 510
and 511, which is the signature the BIOS checks for.

This expression fills unused space with zeroes until byte 510:

```asm
times (510 - ($ - $$)) db 0x00
```

- `$` is the current assembly position.
- `$$` is the beginning of the current section.

## Initial CPU setup

Execution begins with:

```asm
jmp start
```

The jump skips over the included helper code and lands at `start`.

```asm
start:
    mov ax,cs
    mov es,ax
    mov ds,ax
    mov ss,ax
    mov sp,stack
```

Real-mode x86 uses segment registers:

- `CS` - code segment
- `DS` - data segment
- `ES` - extra segment
- `SS` - stack segment
- `SP` - stack pointer

The code copies `CS` into the other segment registers so code, data, and stack
all use the same segment.

```asm
stack equ 0x7c00
```

The stack starts at `0x7C00` and grows downward, allowing the bootloader to use
stack space below its loaded location. A production bootloader would usually
choose a safer stack address and preserve the BIOS boot-drive number from `DL`.

## How `printf` works

This line:

```asm
printf "Hello, World!"
```

invokes a NASM macro defined in `include/stdio.h`; it does not call a C
standard-library function.

Since `stdio.h` selects 16-bit mode:

```asm
bits 16
%define sz 2
```

it maps `printf` to `_printf16` and includes `stdio16.asm`.

The one-argument macro loads the address of an embedded, null-terminated
string, pushes it onto the stack, and calls `_printf16`. It then jumps over the
embedded string so the CPU does not interpret the string bytes as instructions.

The newline value is defined as:

```asm
nl equ 0x0a0d
```

Stored as a little-endian word, this produces carriage return followed by line
feed (`0x0D 0x0A`).

The formatter supports:

- `%c` - character
- `%s` - null-terminated string
- `%d` - decimal integer
- `%x` - hexadecimal integer
- `%%` - literal percent sign

For example:

```asm
printf "Value: %d", 42
printf "Address: %x", 0x7c00
printf "Text: %s", some_string
```

## Printing a character

The core output routine uses BIOS interrupt `0x10`:

```asm
mov ah,0x0e
int 0x10
```

Function `0x0E` is the BIOS teletype output function. The character is passed
in `AL`, and the BIOS displays it.

The formatter scans the string with `lodsb`. Normal characters are sent to
`putchar16`; format sequences are dispatched to the appropriate conversion
routine.

## Integer and hexadecimal output

`printint16` converts a 16-bit value to decimal by repeatedly dividing by 10.
The remainders are stored in reverse order in a shared buffer and then printed.

`printhex16` extracts four hexadecimal nibbles using masks and shifts. Values
from 0 to 9 become `0`-`9`; values from 10 to 15 become `a`-`f`.

The temporary buffer is:

```asm
buf times 64 db 0x00
```

## Program termination

After printing:

```asm
hlt
.loop:
    nop
    jmp .loop
```

`hlt` stops the CPU until an interrupt occurs. If one occurs, execution enters
the infinite loop. There is no operating system to return to, so the
bootloader must stop or continue running indefinitely.

## Running with QEMU

Use:

```sh
make run
```

The `run` target starts:

```sh
qemu-system-i386 -nographic \
    -drive file=loader.img,format=raw,if=ide \
    -drive file=kernel.img,format=raw,if=ide \
    -m 16M
```

This starts an emulated 32-bit x86 machine, attaches `loader.img` as the first
IDE disk, attaches `kernel.img` as the second IDE disk, and provides 16 MB of
RAM.

The bootloader prints through BIOS VGA video services. Since `-nographic`
removes the graphical display, the message may not appear in the terminal.
Running QEMU with a graphical display is more appropriate for this output.

## Current architecture

```text
BIOS
  |
  | loads sector 0 at 0x7C00
  v
loader.asm
  |
  | initializes segments and stack
  v
printf macro
  |
  v
_printf16
  |
  v
putchar16
  |
  v
BIOS int 0x10
  |
  v
screen output
```

This project is currently a boot-sector printing experiment, not yet a
complete bootloader. The next major step would be to use BIOS disk services
(`int 0x13`) to read sectors from `kernel.img` into memory and jump to the
loaded kernel.
