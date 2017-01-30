# README

This file explains the changes have been done from the first version of this
operating system kernel.

##	1. The "cumbersome" version
	
This is the explanation of how to build the very first version which place all 
the source files in one directory, it is cumbersome, but it works. It is still here to 
give insight of how actually the code works, rather than reading all the "twisty" 
makefile, it's better to read this file to know how exactly this thing works.

The following guide explains how to build a working "ancient kernel" 
from the sources in one directory.

### Step 0: The assumptions in the following steps

a. You have to put all the needed sources back into one directory, then invoke all 
the "command" mentioned here from within that directory if you wish to do this.

b. Every binary/executable tool mentioned here is built from their respective 
source and are named the same as their source file, except for the extension, i.e. 
in the binary/executable tool no file extension used at all, while in the source I'm
using ``` *.c``` extension. 

c. You already knows the PCI vendor ID and Device ID of the card you are using. They are
needed since if you are using a different card than mine, YOU HAVE TO CHANGE THOSE IDs
in the source code to match your card. It is in the first stage kernel loader, i.e. 
loader1.asm, which is located in the loader directory. If you failed to do so, there's 
a big chance that the resulting binary ROM file routine will not be executed at all 
during the booting process, which means our kernel is not executed at all.

d. You have the compiler and assembler needed. Nasm and GCC are required to build the
sources that I provided.

### Step 1: Build the tools needed
 	
The sources needed to build all of the tools are provided in the utility directory.
If you are using gcc, then just invoke it as follows (for each file):
gcc [source_filename] -o [target_filename]

#### Explanation of the tools
------------------------

a. _mergebin_, this tools is used to combine 2 binary file (actually anyfile) into a 
   single file. It's sensitive to position of the input parameters, i.e. the input filenames, the second input filename will be appended to the first input filename and the third 
input filename
	is the target binary file that we're building.

b. _zeroextend_, this tool is used to append zero(s) (0h) into a file until the file matches the 
	size we're targeting (in bytes), which is the input parameter. For example to "zeroextend" 
	a file into 1024 byte invoke: ```zeroextend [input_filename] 1024```

c. _patch2pnprom_, this tool is used to patch the 8-bit checksum of a "pseudo PCI ROM" file into a
	valid PCI pnprom. Frankly, it calculates the checksums and patches the needed header 
	format as needed.


### Step 2: Build the kernel loader

The source files are in the loader directory. Here's the explanation:

a. loader1.asm ; this file contains the PCI PnP rom header of the rom to be built, and some loader 
				routines.Its function is to load the operating system code from ROM to RAM during 
				the int 19h, which invokes the BEV that we set in this ROM source code. Its size 
				is 512 bytes, after assembled.

b. loader2.asm ; this file contains the assembly code to switch the machine from real to protected 
		mode and also contains a jump into the C-compiled kernel code.Its size is 512bytes,
		after assembled.

#### Step 2a: assemble loader1.asm and loader2.asm 
Invoke the following command to carry-out this step:
	
```nasm -fbin [filename] -o [target filename] ```

in the command line. 

#### Step 2b: combine the resulting binary from Step 2a.
To merge the file I use mergebin utility. Invoke : 
	
``` mergebin loader1.bin loader2.bin loader.bin ```

in the command line to obtain it. Becareful not to swap the filename position 
since mergebin will put the first filename argument in the beginning of the 
resulting file, and so forth.


### Step 3: Build the C kernel code

Compile and link the C sources for the kernel which are located in the kernel directory.
To do so, invoke the following command:

```gcc -c video.c -o video.o```

```gcc -c ports.c -o ports.o```

```ld -o kernel.bin -Ttext 0x7E00 -e main -N --oformat binary main.o video.o ports.o```

Note: The last line means, link the files with main() function as entry point, with plain binary 
format and the code will begin at 0x7E00 when executed, since the first 512 bytes from 0x7C00 is 
used by loader2.bin, and with no page alignment (one page is 4Kbyte).

We're not done yet !!!. 

Then use zeroextend utility to extend the file into multiple of 512 bytes 
(since we're building a ROM file here d00d) as follows:

	zeroextend kernel.bin 1024

Note: I'm using 1024 bytes as the "extended" file size for the C kernel binary here.


### Step 4: Merge the kernel loader and the C kernel

	Merge the C compiled code (kernel.bin) and the assembly code (loader.bin). Invoke 
the following command:

	mergebin loader.bin kernel.bin boot.bin

Note: Again, take care of the position of the parameters! mergebin is sensitive to it.


### Step 5: Patch the needed checksums

Invoke the following command:

	patch2pnprom boot.bin

to patch all the wrong checksums in the binary so that boot.bin will become a valid ROM file. 
This file is the "ready to burn ROM file", use rtflash or another flashing tool to burn it into 
your LAN/NIC card (or another PCI expansion card) flash rom chip.



##	2. Updated 10 February 2004, using Makefile support.

With the makefile support, you only need to invoke:	

```make ```

in this directory to make the OS and invoke : 

```make clean```

to clean up all the files generated.

Note:
-----
You have to provide the following program in an executable path within your "shell":

a. nasm 

b. gcc

I used Linux (with bash shell) as my development environment, and it works just fine.
I've tried using MinGW32 and MSys, the makefile works just fine but I don't know why 
gcc unable to output the "pure binary" file of the kernel (kernel.bin) correctly, 
any suggestion ??? 
please mail me: darmawan.salihun(at)gmail.com


#################################################################################################
#																								#
#		Successfully modded PCI CARDs															#
#																								#
#################################################################################################

The following cards have been successfully "implanted" with the resulting binary from this
source code with little modification(s):

1. Realtek 8139A NIC (VendorID = 10EC, DeviceID = 8139), with Atmel AT29C512 flashrom (64KByte). 
The binary flashed using flash program provided by Realtek website (rtflash.exe). First, set the 
flashrom window size with rset8139.exe (also from realtek website), just read Realtek's README 
file.

2. Adaptec AHA-2940U SCSI controller card (VendorID = 9004, DeviceID = 8178), with soldered 
PLCC SST29C512 flashrom (64KByte). The binary flashed using innoficial flash program (flash4.exe).
The result is awesome and a bit weird, no matter how I changed the BIOS setup, the PCI 
initialization routine always get called (I think this is due to the controller's chip 
Subclass Code and Interface Code, which is a SCSI controller/boot device). The hacked BIOS
make it behave as if it's a real PCI NIC except for the peculiarity mentioned above, my system 
boot from the card (through it's BEV routine) if I select boot from LAN in the BIOS setup of 
my mainboard. Also note that the flash program for this card ONLY ACCEPT BINARY FILE OF LENGTH 
64KB, if you fail to do so, the flash program will not flash the binary at all :(.

