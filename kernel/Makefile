########################################################
# makefile for generating the 32-bit protected kernel 
# 
#######################################################

include ../var.mak

CC= gcc
ENTRYPOINT_CFLAGS= -ffreestanding -c
CFLAGS= -c
LD= ld
KERNEL_LDFLAGS= -Ttext 0x7E00 -e main -N --oformat binary
KERNEL_ROMSIZE=64512

all: main.o video.o ports.o
	$(LD) -o $(KERNEL_BIN) $(KERNEL_LDFLAGS) main.o video.o ports.o
	cp ../$(UTILS_DIR)/$(ZEROEXTEND) .
	./$(ZEROEXTEND) $(KERNEL_BIN) $(KERNEL_ROMSIZE)
	
video.o: video.c
	$(CC) $(CFLAGS) -o $@ $<

ports.o: ports.c
	$(CC) $(CFLAGS) -o $@ $<

main.o: main.c
	$(CC) $(ENTRYPOINT_CFLAGS) -o $@ $<

clean:
	rm -rf *.bin *.o $(ZEROEXTEND) *~
