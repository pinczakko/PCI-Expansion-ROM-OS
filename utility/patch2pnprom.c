/*

This program created in May 5th 2003 by Darmawan MS a.k.a Pinczakko
-------------------------------------------------------------------

Currently only capable of transforming "hacked" *.com file (a flat
binary file which begins at 00h) into a functional PnP ROM file.
This program only search for, calculate and writes all checksum
bytes in a PnP ROM. A generic ROM file such as PCI Option ROM and
ISA Option ROM which do not conform PnP is not supported now :(.
Summing up, this means the ROM format currently supported are:
1. PCI PnP option ROM
2. ISA PnP option ROM

-->Note: This program reads the PnP ROM size from the file header 
	(offset 02h) and also DID NOT alter the ROM size. Hence,
	it's the responsibility  of the PnP ROM writer to write 
	a "right" PnP ROM source code and only let this program to 
	calculate and alter the checksums needed :)

	
Added March 4th 2004
---------------------
-->Note: this program currently not capable of patching the required
	checksum for multiple option rom in one binary rom file, for
	example: a binary PCI rom file which contains 2 consecutive 
 	PCI rom as mentioned in PCI 2.2 standard.This issue need to be
	refined later.

*/

#include <stdlib.h>
#include <stdio.h>

#define ITEM_COUNT		1
#define ROM_SIZE_INDEX		0x2
#define PnP_HDR_PTR		0x1A
#define PnP_CHKSUM_INDEX	0x9
#define PnP_HDR_SIZE_INDEX	0x5

typedef unsigned char UCHAR;
typedef unsigned int UINT;

static UCHAR calc_checksum(FILE* fp, UINT size);

int main(int argc, char* argv[])
{
	FILE*	fp;
	UCHAR	checksum_byte;
	UINT	ROMSize; /* size of ROM source code in multiple of 512 bytes */
	UCHAR	PnPHeaderPos;
	UCHAR	PnPChecksum = 0x00;
	UCHAR	PnPChecksumByte;
	UCHAR	PnPHdrCounter = 0x00;
	UCHAR	PnPHdrSize;


	if(argc != 2) /* not enough parameter */
	{
		printf("Usage: %s  [filename]\n",argv[0]);
		return -1;
	}

	/* argv[1] is pointer to the filename parameter from user */
	if( (fp = fopen( argv[1] , "rb+")) == NULL)
	{
		printf("Error opening file\nclosing program ...");
		return -1;
	}


	/* Save ROM source code file size which is located
	at index 0x2 from beginning of file (zero based index) */

	fseek(fp, ROM_SIZE_INDEX, SEEK_SET);
	ROMSize = fgetc(fp);
	
		
		/* Patch the PnP Header checksum */
		if(fseek(fp,PnP_HDR_PTR,SEEK_SET) != 0)
		{
			printf("Error seeking PnP Header");
			return -1;
		}
		
		PnPHeaderPos = fgetc(fp);/* save PnP header offset */
		
		if(fseek(fp,(PnPHeaderPos + PnP_HDR_SIZE_INDEX), SEEK_SET) != 0) 
		{
			printf("Error seeking PnP Header Checksum\n");
			return -1;
		}

		PnPHdrSize = fgetc(fp);/* save PnP header size*/

		/* reset current checksum to 0x00 so that
		the checksum won't be wrong if calculated */
	
		if(fseek(fp,(PnPHeaderPos + PnP_CHKSUM_INDEX),SEEK_SET) != 0) 
		{
			printf("Error seeking PnP Header Checksum\n");
			return -1;
		}

		if(fputc(0x00,fp) == EOF)
		{
			printf("Error resetting PnP Header checksum value\n");
			return -1;
		}

		/* calculate PnP Header Checksum */
		if(fseek(fp,PnPHeaderPos,SEEK_SET) != 0)
		{
			printf("Error seeking to calculate PnP Header checksum");
			return -1;
		}

			/*
			PnP BIOS Header size is calculated in every 16 bytes increment
			*/
			for(; PnPHdrCounter < (PnPHdrSize * 0x10) ; PnPHdrCounter++)
			{
				PnPChecksum = ( (PnPChecksum + fgetc(fp)) % 0x100);
			}

			PnPChecksumByte = 0x100 - PnPChecksum;

		/* write PnP Header Checksum */
		fseek(fp,(PnPHeaderPos + PnP_CHKSUM_INDEX), SEEK_SET);
		fputc(PnPChecksumByte ,fp);


	
	/* Overall file checksum handled from here on */
	
	/* reset current checksum on last byte */
	fseek(fp, -1, SEEK_END);
	fputc(0x00,fp);

	
	/* calculate checksum byte */
	if(calc_checksum(fp,ROMSize) == 0x00)
	{
		checksum_byte = 0x00; /* checksum already O.K */
	}

	else
	{
		checksum_byte = 0x100 - calc_checksum(fp,ROMSize);
	}


	/* Write Checksum byte */
		
		/* Put the file pointer at last byte */
		if(fseek(fp,-1,SEEK_END) != 0)
		{
			printf("Failed to seek through the file\nclosing program ...");
			return -1;
		}
		/* write the checksum to the end of the file */
		fputc(checksum_byte, fp);


	/* write to disk */
	fclose(fp); 

	printf("PnP ROM successfully created\n");

	return 0;


}



static UCHAR calc_checksum(FILE* fp, UINT size)
{
UINT  position = 0x00;/* Position of file pointer */
UCHAR checksum = 0x00;

	/* set file pointer to the beginning of file */
	if(!fseek(fp,0,SEEK_SET))
	{
		/*
		calculate 8 bit checksum 8
		file size = size * 512 byte = size * 0x200
		*/

		for(; position < (size * 0x200) ; position++)
		{
			checksum = ( (checksum + fgetc(fp)) % 0x100);
		}

		printf("calculated checksum = %#x \n",checksum);

	}

	else
	{
	printf("function calc_checksum:Failed to seek through the beginning of file\n");
	}


	return checksum;

}

