########################################################
# makefile for generating the utility program needed
########################################################

include ../var.mak

CC= gcc
CFLAGS= -02 -Wall -c
LD= gcc
LDFLAGS= 

all: $(ZEROEXTEND).o $(MERGEBIN).o $(PATCH2PNPROM).o
	$(LD) $(LDFLAGS) -o $(ZEROEXTEND) $(ZEROEXTEND).o
	$(LD) $(LDFLAGS) -o $(MERGEBIN)  $(MERGEBIN).o
	$(LD) $(LDFLAGS) -o $(PATCH2PNPROM) $(PATCH2PNPROM).o
		
$(ZEROEXTEND).o: $(ZEROEXTEND).c
	$(CC) $(CFLAGS) -o $@ $<

$(MERGEBIN).o: $(MERGEBIN).c
	$(CC) $(CFLAGS) -o $@ $<

$(PATCH2PNPROM).o: $(PATCH2PNPROM).c
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -rf *~ $(ZEROEXTEND) $(MERGEBIN) $(PATCH2PNPROM) *.o
