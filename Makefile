#################################################################
#this is the makefile that controls the build of my kernel
#which is executed from the PCI expansion/option ROM
#of a Realtek 8139A based ethernet card 
#First build of this makefile: Feb 03, 2004
##################################################################

include var.mak

all: 
	$(MAKE) -C $(UTILS_DIR) all
	$(MAKE) -C $(LOADER_DIR) all
	$(MAKE) -C $(KERNEL_DIR) all
	cp ./$(KERNEL_DIR)/$(KERNEL_BIN) .
	cp ./$(LOADER_DIR)/$(KERNEL_LOADER) .
	cp ./$(UTILS_DIR)/$(MERGEBIN) .
	cp ./$(UTILS_DIR)/$(PATCH2PNPROM) .
	./$(MERGEBIN) $(KERNEL_LOADER) $(KERNEL_BIN) $(ROM_BIN) 
	./$(PATCH2PNPROM) $(ROM_BIN)

clean:
	$(MAKE) -C $(UTILS_DIR) clean
	$(MAKE) -C $(LOADER_DIR) clean
	$(MAKE) -C $(KERNEL_DIR) clean
	rm -rf $(MERGEBIN) $(PATCH2PNPROM) *.bin *~
