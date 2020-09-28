						ASSUME	CS:DATA_CODE,DS:DATA_CODE


						.386p


DATA_CODE				SEGMENT	USE16

						INCLUDE		IODEF.ASM
						INCLUDE		DEF.ASM

MAIN					PROC
						DB		"IPL4"

						CLI
						PUSH	CS
						POP		DS

						; This IPL is for SCSI CD drive.
						; If TOWNS SYSROM calls this place, BL must be 1 (SCSI), and BH must be SCSI ID.
						AND		BH,7
						MOV		BYTE PTR [YSSCSICD_SCSI_ID],BH


						CALL	INITGRAPHICS
						CALL	VRAMMODE
						CALL	CLS

						MOV		AX,0101H
						CALL	LOCATE
						MOV		SI,OFFSET MSG_DIRECT_SCSI_CD_BOOT
						CALL	PRINT_TALL
						CALL	DRAW_AOMORI


						;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						; Search FBIOS
						MOV		AX,0040H
						MOV		FS,AX

						MOV		EDX,8	; I think starting sector 10 is good enough, but just in case start from 8
FIND_FBIOS_SECTOR_LOOP:
						PUSH	EAX
						PUSH	ECX
						PUSH	EDX

						MOV		SI,OFFSET SCSI_CMD
						MOV		EDI,0400H
						MOV		[SI+4],DH
						MOV		[SI+5],DL
						ROR		EDX,16
						MOV		[SI+2],DH
						MOV		[SI+3],DL
						ROR		EDX,16
						MOV		CL,[YSSCSICD_SCSI_ID]
						CALL	SCSI_COMMAND

						POP		EDX
						POP		ECX
						POP		EAX

						CMP		DWORD PTR FS:[0],4F494246H ; "FBIO"
   						JNE		@f
						CMP		BYTE PTR FS:[4],53H ; 'S'
						JE		FIND_FBIOS_SECTOR_FOUND
@@:
						ADD		EDX,1
						CMP		EDX,80	; Search up to this sector.
						JNE		FIND_FBIOS_SECTOR_LOOP

						; FBIOS not found.
						MOV		AX,0102H
						CALL	LOCATE
						MOV		SI,OFFSET MSG_FBIOS_NOT_FOUND
						CALL	PRINT_TALL
@@:
						JMP		@b

FIND_FBIOS_SECTOR_FOUND:



						;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						; Read FBIOS (IO.SYS)
						; EDX is the LBA for FBIOS.
						; Actually, SCSI_CMD is pointing FBIOS already.
						MOV		SI,OFFSET SCSI_CMD
						MOV		BYTE PTR [SI+8],64
						MOV		EDI,0400H
						MOV		CL,[YSSCSICD_SCSI_ID]
						CALL	SCSI_COMMAND
						JAE		LOADED_IO_SYS

						MOV		AX,0102H
						CALL	LOCATE
						MOV		SI,OFFSET MSG_IOSYS_READ_FAILURE
						CALL	PRINT_TALL
@@:
						JMP		@b
LOADED_IO_SYS:


						;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						; Find JMP xxxx:xxxx
						MOV		AX,0050H
						MOV		FS,AX
						MOV		AX,FS:[0]
						MOV		FS,AX		; FS:0000 is IO.SYS Entry

						MOV		SI,0
FIND_JUMP_INSTRUCTION_LOOP:
						MOV		AL,FS:[SI]
						CALL	E8_OR_BE
						JNE		FIND_JUMP_INSTRUCTION_NEXT

						MOV		CX,10
						PUSH	SI
@@:
						ADD		SI,3
						MOV		AL,FS:[SI]
						CALL	E8_OR_BE
						JNE		@f
						LOOP	@b

						ADD		SI,3
						MOV		AL,FS:[SI]
						CMP		AL,0EAH		; JMPF
						JNE		@f

						; Found it!
						ADD		SP,2
						JMP		FIND_JUMP_INSTRUCTION_FOUND
@@:
						POP		SI

FIND_JUMP_INSTRUCTION_NEXT:
						INC		SI
						CMP		SI,0FF00H	; Must not be that late in the segment
						JNE		FIND_JUMP_INSTRUCTION_LOOP

						; NOT FOUND
						MOV		AX,0102H
						CALL	LOCATE
						MOV		SI,OFFSET MSG_JUMP_INST_NOT_FOUND
						CALL	PRINT_TALL
@@:
						JMP		@b

FIND_JUMP_INSTRUCTION_FOUND:



						;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						; Set up intercept and JMP to IO.SYS
						MOV		AX,FS:[SI+1]
						MOV		CS:[IOSYS_RESUME_IP],AX
						MOV		AX,FS:[SI+3]
						MOV		CS:[IOSYS_RESUME_CS],AX

						MOV		WORD PTR FS:[SI+1],OFFSET IOSYS_INTERCEPT
						MOV		FS:[SI+3],CS

						MOV		CS:[IOSYS_ENTRY_CS],FS

						MOV		AX,0F7FFH	; Make IO.SYS think B0000H to BFFFFH block is inaccessible
						MOV		BX,0008H	; Pretend Booting from CD-ROM Drive
						MOV		CX,0280H
						MOV		DI,0
						MOV		DX,0

						; Cannot use direct jump because at the time of MOV CS:[IOSYS_ENTRY_CS]
						; This location is already in cache.
						; I'm not sure about the logic of MASM indirect jump, but if I make it
						; DWORD PTR it woks just fine.  
						; FWORD PTR looks to fetch 48 bytes, and doesn't work.
						; WORD PTR makes it near jump.
						JMP		DWORD PTR CS:[IOSYS_ENTRY_IP]



						;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						; IO.SYS Intercept
IOSYS_INTERCEPT:
						PUSH	DS
						PUSH	ES
						PUSH	AX
						PUSH	BX
						PUSH	CX
						PUSH	DX
						PUSH	SI
						PUSH	DI
						PUSH	BP

						PUSH	CS
						POP		DS

						CALL	DRAW_AOMORI

						; Turned out MSDOS.SYS is copied to the conventional memory, but not installed yet.
						MOV		AL,CS:[YSSCSICD_SCSI_ID]
						PUSH	CS		; G** D**n it!  How can I CALLF DATA_CODE:INSTALL_HOOK_DIRECT?
						CALL	INSTALL_HOOK_DIRECT

						POP		BP
						POP		DI
						POP		SI
						POP		DX
						POP		CX
						POP		BX
						POP		AX
						POP		ES
						POP		DS

						JMP		DWORD PTR CS:[IOSYS_RESUME_IP]



@@:
						JMP		@b

MSG_DIRECT_SCSI_CD_BOOT	DB		"DIRECT SCSI CD BOOT",0
MSG_FBIOS_NOT_FOUND		DB		"IO.SYS NOT FOUND",0
MSG_IOSYS_READ_FAILURE	DB		"FAILED TO LOAD IO.SYS",0
MSG_JUMP_INST_NOT_FOUND	DB		"JUMP INSTRUCTION NOT FOUND",0

IOSYS_RESUME_IP			DW		0
IOSYS_RESUME_CS			DW		0

IOSYS_ENTRY_IP			DW		0
IOSYS_ENTRY_CS			DW		0


MAIN					ENDP

						INCLUDE	..\SCSILIB\SCSIIO.ASM

						INCLUDE		DRAWFONT.ASM
						INCLUDE		GRAPHICS.ASM
						INCLUDE		MEMBANK.ASM
						INCLUDE		../RESOURCE/AOMORI.ASM
						INCLUDE		TSUGARU.ASM

						INCLUDE	..\YSSCSICD\PRINT.ASM
						INCLUDE	..\YSSCSICD\RS232C.ASM
						INCLUDE ..\YSSCSICD\FMR_TIMR.ASM
						INCLUDE	..\YSSCSICD\HOOKBIOS.ASM
						INCLUDE ..\YSSCSICD\YS_EXT.ASM
						INCLUDE	..\YSSCSICD\REDRFUNC.ASM
						INCLUDE ..\YSSCSICD\SCSIUTIL.ASM
						INCLUDE	..\YSSCSICD\FMR_SCSI.ASM
DATA_CODE				ENDS

						INCLUDE	..\YSSCSICD\WRHIGH.ASM

DATA_CODE				SEGMENT




SECTOR_BUFFER_COUNT		EQU		12
MAX_SECTOR_SIZE			EQU		2340
SCSI_DATA_BUF_LENGTH 	EQU 	(128+SECTOR_BUFFER_COUNT*MAX_SECTOR_SIZE)

YSSCSICD_SCSI_ID		DB		0	; 0FFH:No SCSI CD  0 to 7:SCSI CD Found

YSSCSICD_FLAGS_DEBUG_CONSOLE	EQU		1
YSSCSICD_FLAGS_DEBUG_RS232C		EQU		2
YSSCSICD_FLAGS			DB		0
YSSCSICD_DEBUG_CMD_CACHE	DB		0

YSSCSICD_ELEVOL_LEFT	DB		0FFH
YSSCSICD_ELEVOL_RIGHT	DB		0FFH

DEBUG_REDIR_SUBSTEP		DB		' '

; THE FOLLOWING BLOCK MUST BE AT THE [VERY END] OF THE BINARY >>
SCSI_DATABUF_PTR		DB		4 dup(0)
SCSI_CMD				DB		28H,0,0,0,0,0,0,0,1,0	; Used as a READ10 command during boot.
						DB		0,0
SCSI_DATA_BUF			DB		0

; One-time use routine.
E8_OR_BE:
						CMP		AL,0E8H	; CALL
						JE		@f
						CMP		AL,0BEH ; MOV SI,
@@:						RET
; <<

; Memory protection will be through AX bits passed to IO.SYS.
; Entire memory all the way to B000:FFFF will be available.

DATA_CODE				ENDS

						END		MAIN
