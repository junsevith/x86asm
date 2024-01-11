all: run

run: build
	./out

build: main.o
	gcc main.o -g -o out -m32 -no-pie

main.o: main.asm
	nasm -f elf -g -F stabs main.asm

clean:
	rm -rf *o program