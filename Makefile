ASMFLAGS := -f bin -i include/

.PHONY: all clean run

all: loader.img

loader.img: loader.asm
	nasm $(ASMFLAGS) -o $@ $<

kernel.img:
	dd if=/dev/zero of=$@ bs=1 count=512 status=none

clean:
	rm -f *.img

run: loader.img kernel.img
	qemu-system-i386 -nographic \
		-drive file=loader.img,format=raw,if=ide \
		-drive file=kernel.img,format=raw,if=ide \
		-m 16M