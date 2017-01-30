##########################################################################################
# This makefile builds the first stage and second stage bootloader, it also 
# merge them into a complete kernel loader
# Note: $(ASM) is a variant of nasm, be it nasmw(in windows) or nasm (in Linux)
##########################################################################################

include ../var.mak

ASM_FLAGS= -fbin

all: $(FIRST_STAGE_LOADER) $(SECOND_STAGE_LOADER)
	cp ../$(UTILS_DIR)/$(MERGEBIN) .
	./$(MERGEBIN) $(FIRST_STAGE_LOADER) $(SECOND_STAGE_LOADER) $(KERNEL_LOADER)

$(FIRST_STAGE_LOADER): loader1.asm
	$(ASM) $(ASM_FLAGS) $< -o $@

$(SECOND_STAGE_LOADER): loader2.asm
	$(ASM) $(ASM_FLAGS) $< -o $@

clean:
	rm -rf *.bin $(MERGEBIN) *~
