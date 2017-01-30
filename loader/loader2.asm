;--------------------------------------------
; Operating System Code
;--------------------------------------------
[BITS 16]
[ORG 0x7C00]

OS_Code:
	mov	ax,cs			;adjust all segment registers
	mov	ds,ax
	mov	es,ax

	mov	si,msg_OS_Ldd_ptr	;fetch the relative offset address
					;of msg_OS_Loaded
	call	disp_msg		;display the message (near call)
	mov	ah,0x00
	int 	0x16

	jmp	enable_A20

;---- OS Real Mode Procedure to display message ----;
disp_msg:
	cld
.disp:				;display message
	lodsb
	cmp 	al,'$'
	je	.no_disp
	mov	ah,0xE
	mov	bx,0x7
		int	0x10
	jmp 	.disp
.no_disp:
	ret

;------ Variable & Equates declaration ------------------------------------;
msg_OS_Loaded	db	10,13,'Operating System Loaded!','$'
msg_A20_Enabled db	10,13,'Gate A20 enabled !','$'

msg_OS_Ldd_ptr	equ  	(msg_OS_Loaded - OS_Code)
msg_A20_ptr	equ	(msg_A20_Enabled - OS_Code)

;---------------------------------------------------------------
; Enable Gate A20 so that we can access RAM post 1 MB
;---------------------------------------------------------------
enable_A20:
        cli

        call    a20wait
        mov     al,0xAD
        out     0x64,al

        call    a20wait
        mov     al,0xD0
        out     0x64,al

        call    a20wait2
        in      al,0x60
        push    eax

        call    a20wait
        mov     al,0xD1
        out     0x64,al

        call    a20wait
        pop     eax
        or      al,2
        out     0x60,al

        call    a20wait
        mov     al,0xAE
        out     0x64,al

        call    a20wait
	jmp 	Continue

a20wait:
.l0:    mov     ecx,65536
.l1:    in      al,0x64
        test    al,2
        jz      .l2
        loop    .l1
        jmp     .l0
.l2:    ret


a20wait2:
.l0:    mov     ecx,65536
.l1:    in      al,0x64
        test    al,1
        jnz     .l2
        loop    .l1
        jmp     .l0
.l2:    ret

Continue:
	sti				;enable interrupt
	mov	si,msg_A20_ptr
	call	disp_msg

	mov	ah,0x00
	int 	0x16
;---------------------------------------------------------------------;
;Switch to P-Mode and jump to kernel, we need BITS 32 here since the
; code will be executed in 32 bit P-Mode.
;---------------------------------------------------------------------;
	cli			;disable interrupt

	lgdt	[gdt_desc_addr]	;load GDT to GDTR (we load both limit and base address)

	mov	eax,cr0		;switch to P-Mode
	or	eax,0x1
	mov	cr0,eax		;haven't yet in P-Mode, we need a FAR Jump

	jmp SEG_CODE_SEL:dword  do_pm	;this force P-Mode to be reached (CS updated)
					;beware !!! this is the most buggy part,
					;read NASM manual for mixed size jump (jmp) instruction

[BITS 32]
do_pm:
	xor	esi,esi
	xor	edi,edi
	mov	ax,10h		;Save data segment identifier (see GDT)
	mov	ds,ax
	mov	ax,18h		;Save stack segment identifier
	mov	ss,ax
	mov	esp,0x90000


	;Print debugging message to video memory (display the message)
	mov byte [ds:dword 0xB8000],'P'
	mov byte [ds:dword 0xB8001],9Bh	;text attribute
	mov byte [ds:dword 0xB8002],'-'
	mov byte [ds:dword 0xB8003],9Bh	;text attribute
	mov byte [ds:dword 0xB8004],'M'
	mov byte [ds:dword 0xB8005],9Bh	;text attribute
	mov byte [ds:dword 0xB8006],'O'
	mov byte [ds:dword 0xB8007],9Bh
	mov byte [ds:dword 0xB8008],'D'
	mov byte [ds:dword 0xB8009],9Bh
	mov byte [ds:dword 0xB800A],'E'
	mov byte [ds:dword 0xB800B],9Bh

	jmp	SEG_CODE_SEL:0x7E00	;Jump to C Compiled code (in code segment after this code)

	Times ( (($-OS_Code)/4) + 1 )*4 - ($-OS_Code)  db 0

;-----------------------------------------------------;
;			GDT definition
;------------------------------------------------------
gdt_marker:		;dummy Segment Descriptor (GDT)
	dw	0
	dw	0
	db	0
	db	0
	db	0
	db	0

SEG_CODE_SEL 	equ	($-gdt_marker)
SegDesc1:			;kernel CS (08h) PL0, 08h is an identifier
	dw	0xffff		;seg_length0_15
	dw	0		;base_addr0_15
	db	0		;base_addr16_23
	db	0x9A		;flags
	db	0xcf		;access
	db	0		;base_addr24_31

SEG_DATA_SEL 	equ	($-gdt_marker)
SegDesc2:			;kernel DS (10h) PL0
	dw	0xffff	;seg_length0_15
	dw	0		;base_addr0_15
	db	0		;base_addr16_23
	db	0x92		;flags
	db	0xcf		;access
	db	0		;base_addr24_31

SEG_STACK_SEL 	equ	($-gdt_marker)
SegDesc3:			;kernel SS (18h) PL0
	dw	0xffff		;seg_length0_15
	dw	0		;base_addr0_15
	db	0		;base_addr16_23
	db	0x92		;flags
	db	0xcf		;access
	db	0		;base_addr24_31
gdt_end:

gdt_desc:	dw	gdt_end - gdt_marker - 1 ;GDT limit
		dd	gdt_marker		 ;physical addr of GDT

gdt_desc_addr 	equ   	(gdt_desc - OS_Code)

;---------------------------------------------------
; End of Operating system code
;---------------------------------------------------

	times 512 - ($-$$) db 0	;extend to 512 bytes, zero fill in between