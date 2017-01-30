;-------------------------------------------------------------------;
;The base code created in 2:34 am May 4th  2003
;Successfully patched in 9:35 am July 28th  2003
;by Darmawan MS a.k.a Pinczakko.
;
;This is my first operating system prototype :). One thing still
;obscured, the BEV mechanism mentioned in Plug & Play BIOS spec 1.0A
;don't explain about how the code executed :(. But based on my
;experiment it seems to be executed from ROM. So everything we do
;prior to loading the OS code from the expansion ROM into the RAM
;can't do anything dealing with memory write operation. I think
;BEV works as follows :
;1. During POST, the main bios recognize the LAN card as boot device.
;2. If we set up the main bios to boot from LAN as default, after POST succeded,
;   int 19h (bootstrap) will point into the PnP option rom BEV of the LAN
;   and passes execution into the code there, so we're executing code
;   in the ROM pointed to by the BEV. Unless we're loading part of this
;   code into RAM and execute from there, there's no writeable area in our code
;
;While the PCI function of the LAN card function as ordinary PCI card does
;so, the PCI init function has no direct connection with the BEV related stuff.
;
;	<--------- HACK IT DOWN D00D ----------->
;
;--------------------------------------------------------------------;
[BITS 16] 	;Real mode by default (prefix 66 or 67 to 32 bits instructions)

[ORG 0x00]
;-------------------------------------------;
; 	Option rom header
;-------------------------------------------;
	db	0x55		;;Rom signature byte 1
	db	0xAA		;;Rom signature byte 2
ROMsize	db	ROM_Size	;;1024 bytes
	jmp	INIT		;;jump to initialization

	Times 	0x18-($-$$) db 0	;;zero fill in between
	dw	PCI_DATA_STRUC	;;Pointer to PCI HDR structure (at 18h)

	Times 	0x1A-($-$$) db 0	;;zero fill in between
	dw	PnP_Header	;;PnP Expansion Header Pointer (at 1Ah)

;----------------------------
; PCI data structure
;----------------------------
PCI_DATA_STRUC:
	db	'PCIR'		;PCI Header Sign
	dw	0x9004		;Vendor ID
	dw	0x8178		;Device ID
	dw	0x00		;VPD
	dw	0x18		;PCI data struc length (byte)
	db	0x00		;PCI Data struct Rev
	db	0x02		;Base class code, 02h == Network Controller
	db	0x00		;Sub class code = 00h and interface = 00h -->Ethernet Controller
	db	0x00		;Interface code, see PCI Rev2.2 Spec Appendix D
	dw	ROM_Size	;Image length in mul of 512 byte, little endian format
	dw	0x00		;rev level
	db	0x00		;Code type = x86
	db	0x80		;last image indicator
	dw	0x00		;reserved

;-----------------------------
; PnP ROM Bios Header
;-----------------------------
PnP_Header:
	db	'$PnP'			;PnP Rom header sign
	db	0x01			;Structure Revision
	db	0x02			;Header structure Length in mul of 16 bytes
	dw	0x00			;Offset to next header (00 if none)
	db	0x00			;reserved
	db	0x7A			;8 Bit checksum (for this header, -->
					; --> check again after compile and repair if needed)
	dd	0x00			;PnP Device ID --> 0h in Realtek RPL ROM
	dw	Manufacturer_str	;pointer to manufacturer string
	dw	Product_str		;pointer to product string
	db	0x02,0x00,0x00		;Device Type code 3 byte
	db	0x14			;Device Indicator, 14h from RPL ROM-->See Page 18 of
					;PnP BIOS spec., Lo nibble (4) means IPL device

	dw	0x00			;Boot Connection Vector, 00h = disabled
	dw	0x00			;Disconnect Vector, 00h = disabled
	dw	Start_OS 		;Bootstrap Entry Vector (BEV)
	dw	0x00			;reserved
	dw	0x00			;Static resource Information vector (0000h if unused)

;----------------------------------------------------------
; Identifier strings
;----------------------------------------------------------
Manufacturer_str  db	'Pinczakko Corporation',00h

Product_str	db	'Realtek Hacked ROM',00h

;--------------------------------------------------------------------
;PCI Option ROM initialization Code (init function)
;--------------------------------------------------------------------
INIT:

	lea 	si,[msg]		;fetch the string addr
	call	dis_string	;display the message

	mov	bx,ROMsize	;clean up memory used (set image size to 0)
	xor	ax,ax		;produce 0000h
	mov 	[bx],ax		;3rd byte of this bios image file (image size)

	or	ax,0x20		;inform system BIOS that an IPL device attached
				;see PnP spec 1.0A p21 for info's

	retf			;return far to system BIOS

msg	db	10,13,'PCI expansion rom initialization called...','$'

;--------------------------------------------------------------
; 	-- Procedure to display string to stdout --
;Procedure definition:displaying character done through
;int 10h,service 0Eh
;--------------------------------------------------------------
dis_string:
		cld
.more_dis:				;display OS message
		lodsb
		cmp 	al,'$'
		je	.no_more_dis
		mov	ah,0xE
		mov	bx,0x7
		int	10h
		jmp 	.more_dis
.no_more_dis:
		retn

;--------------------------------------------------------------------
; Operating system entry point/BEV implementation (BootStrap)
;--------------------------------------------------------------------
Start_OS:

	mov	ax,cs
	mov	es,ax		;make all segment reg to -->
	mov	ds,ax		;point to the right segment

	lea 	si,[msg_PnP]	;fetch the string addr
	call	dis_string	;display the message

	mov	ah, 0x00
	int	0x16		;wait for key to be hit
;----------------------------------------------------------------------------------
;--- Load The Operating System Code beginning at OS_Load_Seg :OS_Load_Offset h ----
;----------------------------------------------------------------------------------
	cli			;disable interrupt during loading

	mov	ax,OS_Load_Seg		;point to OS segment
	mov	es,ax
	mov	ax,OS_Load_Offset	;point to OS offset
	mov	di,ax

	lea	si,[OS_Code]	;equal to lea si,OS_Code in masm
	cld

	xor	ecx,ecx
	mov	ecx,OS_Code_Size16

load_os:
	lodsw
	stosw
	loop	load_os

;-------- Loading completed -------------------------------------

	mov	ax,cs		;restore es segment register
	mov	es,ax
	xor	di,di

	jmp	OS_Load_Seg:OS_Load_Offset

msg_PnP	db	10,13,'PnP BEV Routine Invoked!',10,13,'$'

;------------------- WARNING !!! ----------------------------------;
;-- The linear address here must match the second file (OS code) --;
OS_Load_Seg 		equ	0x7C0
OS_Load_Offset 		equ	0x0000

ROM_Size		equ	0x04	;ROM size in multiple of 512 bytes
OS_Code_Size		equ	((ROM_Size - 1)*512)
OS_Code_Size16		equ	( OS_Code_Size / 2 )


	Times	(ROM_Size*512 - OS_Code_Size) - ($-$$) db 0	;extend to 512 bytes, zero fill in between
OS_Code:
