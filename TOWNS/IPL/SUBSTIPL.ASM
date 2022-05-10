; Not to forget how it works:
;   Towns II's system ROM reads first 4 sectors from a SCSI device on boot.
;   That gives 8KB for a CD.  If I am able to pack YSSCSICD installer in
;   this 8KB, the CD can boot by itself.
;   Also by keeping internal-CD boot code in the first 2KB, the CD is
;   still bootable from the internal CD as well.
						ASSUME	CS:DATA_CODE,DS:DATA_CODE


						.386p

						PAGE	99,160



DATA_CODE				SEGMENT	USE16

IOSYS_SEARCH_BEGIN		EQU		8	; I think starting sector 10 is good enough, but just in case start from 8
IOSYS_SEARCH_END		EQU		80	; Search up to this sector-1.


						INCLUDE		IODEF.ASM
						INCLUDE		DEF.ASM

MAIN					PROC
						DB		"IPL4"

						CLI
						CLD
						PUSH	CS
						POP		DS

						PUSH	BX
						CALL	INITGRAPHICS
						CALL	VRAMMODE
						CALL	CLS
						CALL	CRTC640X480_640X480MOD
						CALL	DRAW_AOMORI
						CALL	DEMOSPLASH_MESSAGE
						POP		BX

						CMP		BL,1
						JE		SCSICDBOOT

						CMP		BL,8	; From Internal CD?  Lucky you for having a live internal CD drive!
						JE		INTERNALCDBOOT

						RETF			; Let's cycle to the next boot device.

INTERNALCDBOOT:
						; For patched image, I still need to install YSSCSICD.SYS.
						; Let's find IO.SYS from the internal CD, and then jump to LOADED_IOSYS.
						TEXTLOCATION	01H,01H
						MOV		SI,OFFSET MSG_INTERNAL_CD_BOOT
						CALL	PRINT_TALL

						MOV		DX,IOSYS_SEARCH_BEGIN

INTERNAL_FIND_FBIOS_LOOP:
						PUSH	DS
						PUSH	DX

						MOV		AX,0040H
						MOV		DS,AX
						MOV		FS,AX		; For later comparison
						XOR		DI,DI

						MOV		AX,05C0H	; Read Sector, Device=C0H
						XOR		CX,CX		; CH must be 0, CL=High-byte of LBA
						MOV		BX,1
						; How can I write CALL 		FAR PTR 0FFFBH:0014H
						DB		9AH		; CALLF FFFB:0014
						DW		 0014H
						DW		0FFFBH

						POP		DX
						POP		DS

						JB		@f

						CMP		DWORD PTR FS:[0],4F494246H ; "FBIO"
						JNE		@f
						CMP		BYTE PTR FS:[4],53H ; 'S'
						JE		INTERNAL_FIND_FBIOS_SECTOR_FOUND
@@:

						INC		DX
						CMP		DX,IOSYS_SEARCH_END
						JNE		INTERNAL_FIND_FBIOS_LOOP

						JMP		FBIOS_NOT_FOUND



INTERNAL_FIND_FBIOS_SECTOR_FOUND:
						PUSH	DS

						MOV		AX,0040H
						MOV		DS,AX
						XOR		DI,DI

						MOV		AX,05C0H	; Read Sector, Device=C0H
						XOR		CX,CX		; CH must be 0, CL=High-byte of LBA
						MOV		BX,64
						; How can I write CALL 		FAR PTR 0FFFBH:0014H
						DB			9AH		; CALLF FFFB:0014
						DW			 0014H
						DW			0FFFBH

						POP		DS

						JB		IOSYS_LOAD_FAILURE

JUMP_TO_IOSYS:
						CALL	PATCH_V21L20

						MOV		AX,0050H
						MOV		FS,AX
						MOV		AX,FS:[0]
						MOV		CS:[IOSYS_ENTRY_CS],AX		; FS:0000 is IO.SYS Entry

						MOV		AX,0FFFFH	; Full RAM below 1MB
						MOV		BX,0008H	; Pretend or really Booting from CD-ROM Drive
						MOV		CX,0280H
						MOV		DI,0
						MOV		DX,0
						JMP		DWORD PTR CS:[IOSYS_ENTRY_IP]



						;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						; Find IO.SYS from the SCSI drive.
SCSICDBOOT:
						PUSh	BX
						MOV		BX,8000H
						CALL	TRANSFER_SELF
						POP		BX

						DB		0EAH ; JMPF
						DW		OFFSET SCSICDBOOT_CONTINUE
						DW		8000H

SCSICDBOOT_CONTINUE:
						PUSH	CS
						POP		DS

						; This IPL is for SCSI CD drive.
						; If TOWNS SYSROM calls this place, BL must be 1 (SCSI), and BH must be SCSI ID.
						AND		BH,7
						MOV		BYTE PTR [YSSCSICD_SCSI_ID],BH

						TEXTLOCATION	01H,01H
						MOV		SI,OFFSET MSG_DIRECT_SCSI_CD_BOOT
						CALL	PRINT_TALL


						;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						; Search FBIOS
						MOV		AX,0040H
						MOV		FS,AX

						MOV		EDX,IOSYS_SEARCH_BEGIN
SCSI_FIND_FBIOS_SECTOR_LOOP:
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
						JE		SCSI_FIND_FBIOS_SECTOR_FOUND
@@:
						ADD		EDX,1
						CMP		EDX,IOSYS_SEARCH_END
						JNE		SCSI_FIND_FBIOS_SECTOR_LOOP

						; FBIOS not found.
FBIOS_NOT_FOUND:
						TEXTLOCATION	01H,02H
						MOV		SI,OFFSET MSG_FBIOS_NOT_FOUND
						CALL	PRINT_TALL
@@:
						JMP		@b

SCSI_FIND_FBIOS_SECTOR_FOUND:



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
						JAE		LOADED_IOSYS

IOSYS_LOAD_FAILURE:
						TEXTLOCATION	01H,02H
						MOV		SI,OFFSET MSG_IOSYS_READ_FAILURE
						CALL	PRINT_TALL
@@:
						JMP		@b



LOADED_IOSYS:



						;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						; Find First INT 21H AH=48H
						CALL	FIND_JUMP_INSTRUCTION
						JAE		FOUND_FIRST_INT21H

						; NOT FOUND
						TEXTLOCATION	01H,02H
						MOV		SI,OFFSET MSG_JUMP_INST_NOT_FOUND
						CALL	PRINT_TALL
@@:
						JMP		@b

FOUND_FIRST_INT21H:
						; DS:SI is first INT 21H AH=48H

						ADD 	SI,7	; Point to INT 21H

						MOV		BYTE PTR FS:[SI],9AH ; CALLF
						MOV		WORD PTR FS:[SI+1],OFFSET IOSYS_INTERCEPT
						MOV		FS:[SI+3],CS


						MOV		AX,0050H
						MOV		FS,AX
						MOV		AX,FS:[0]
						MOV		CS:[IOSYS_ENTRY_CS],AX		; FS:0000 is IO.SYS Entry

						JMP		JUMP_TO_IOSYS
MAIN					ENDP



						;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						; IO.SYS Intercept
; Intercept IO.SYS jump to MSDOS.SYS
IOSYS_INTERCEPT			PROC
						; Do what's replaced by CALLF 8000:IOSYS_INTERCEPT >>
						INT     21H
						ADD     AX,0010H
						; Do what's replaced by CALLF 8000:IOSYS_INTERCEPT <<

						PUSHF
						PUSH	DS
						PUSH	ES
						PUSHA

						PUSH	CS
						POP		DS

						CLD

						TEXTLOCATION	28H,00H
						MOV		SI,OFFSET IOSYS_INTERCEPTED_MSG
						CALL	PRINT_TALL

						CALL	DEMOSPLASH_MESSAGE

						CALL	DRAW_AOMORI

						; Turned out MSDOS.SYS is copied to the conventional memory, but not installed yet.
						; It is possible to patch at this time, but not doing it any more.

						; At this time, it is safe to use MALLOC
						MOV		BX,((OFFSET SCSI_DATA_BUF)+SCSI_DATA_BUF_LENGTH+0FH)
						SHR		BX,4	; Why MASM doesn't allow divide a constant by 16?  Can't it do the math?
						MOV		AH,48H
						INT		21H
						JNC		MALLOCED_SPACE_FOR_YSSCSICD

						TEXTLOCATION	28H,01H
						MOV		SI,OFFSET CANNOT_MALLOC
						CALL	PRINT_TALL
						JMP		SHORT IOSYS_INTERCEPT_EXIT

MALLOCED_SPACE_FOR_YSSCSICD:
						; AX is the segment.
						; IO.SYS assumes that the PSP owner of the memory control block allocated
						; during the initialization is this segment.
						DEC		AX
						MOV		ES,AX
						INC		AX
						MOV		ES:[0001h],AX
						; Unless doing it, IO.SYS will go into infinite loop for searching last MCB.

						MOV		CS:[YSSCSICD_INSTALL_CS],AX
						MOV		BX,AX
						CALL	TRANSFER_SELF

						MOV		AL,CS:[YSSCSICD_SCSI_ID]

						CALL	DWORD PTR CS:[YSSCSICD_INSTALL_IP]

						PUSH	CS
						POP		DS
						TEXTLOCATION	28H,01H
						MOV		SI,OFFSET INSTALLED_HOOK_MSG
						CALL	PRINT_TALL

IOSYS_INTERCEPT_EXIT:
						POPA
						POP		ES
						POP		DS
						POPF

						RETF
IOSYS_INTERCEPT			ENDP


YSSCSICD_INSTALL_IP		DW		OFFSET INSTALL_HOOK_DIRECT
YSSCSICD_INSTALL_CS		DW		0

IOSYS_ENTRY_IP			DW		0
IOSYS_ENTRY_CS			DW		0


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


						INCLUDE	..\SCSILIB\SCSIIO.ASM
						INCLUDE	..\YSSCSICD\PRINT.ASM
						INCLUDE	..\YSSCSICD\RS232C.ASM
						INCLUDE	..\YSSCSICD\FMR_TIMR.ASM
						INCLUDE	..\YSSCSICD\HOOKINST.ASM
						INCLUDE	..\YSSCSICD\HOOKBIOS.ASM
						INCLUDE	..\YSSCSICD\YS_EXT.ASM
						INCLUDE	..\YSSCSICD\REDRFUNC.ASM
						INCLUDE	..\YSSCSICD\SCSIUTIL.ASM
						INCLUDE	..\YSSCSICD\FMR_SCSI.ASM



SCSI_DATA_BUF_LENGTH 	EQU 	2340

YSSCSICD_SCSI_ID		DB		0FFH	; 0FFH:No SCSI CD,   0 to 7:SCSI CD Found

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



; This area will be destroyed upon installing YSSCSICD.SYS

; Pattern
; 8BD8                      MOV     BX,AX
; 83C310                    ADD     BX,10H
; B448                      MOV     AH,48H
; CD21                      INT     21H (DOS)         -> CALLF 8000:INJECT_YSSCSICD
; 051000                    ADD     AX,0010H          ->
; 2EA3????                  MOV     CS:[????],AX
; 8EC0                      MOV     ES,AX
; 33FF                      XOR     DI,DI

; +0 +1 +2 +3 +4 +5 +6 +7 +8 +9 +A +B +C +D +E +F
; 8B D8 83 C3 10 B4 48 CD 21 05 10 00 2E A3 ?? ??
; 8E C0 33 FF

INT_21_AH_48_LEN	EQU	14
INT_21_AH_48_PTN	DB	08BH,0D8H,083H,0C3H,010H,0B4H,048H,0CDH,021H,005H,010H,000H,02EH,0A3H

IOSYS_INTERCEPTED_MSG	DB		"INTERCEPTED IO.SYS.",0
INSTALLED_HOOK_MSG		DB		"INSTALLED INT 93H HOOK.",0
CANNOT_MALLOC			DB		"MALLOC FAILED, CANNOT INSTALL YSSCSICD",0

MSG_INTERNAL_CD_BOOT	DB		"BOOT FROM INTERNAL CD",0
MSG_DIRECT_SCSI_CD_BOOT	DB		"DIRECT SCSI CD BOOT",0
MSG_FBIOS_NOT_FOUND		DB		"IO.SYS NOT FOUND",0
MSG_IOSYS_READ_FAILURE	DB		"FAILED TO LOAD IO.SYS",0
MSG_JUMP_INST_NOT_FOUND	DB		"JUMP INSTRUCTION NOT FOUND",0

MSG_DEMOSPLASH_1		DB		"PLEASE JOIN US AT DEMOSPLASH 2022",0
MSG_DEMOSPLASH_2		DB		"AND 2023, 2024, ...",0
MSG_DEMOSPLASH_3		DB		"http://demosplash.org",0

						INCLUDE		../RESOURCE/AOMORI.ASM
						INCLUDE		DRAWFONT.ASM
						INCLUDE		GRAPHICS.ASM
						INCLUDE		MEMBANK.ASM
						INCLUDE		PATCH.ASM
						INCLUDE		CRTC.ASM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



DEMOSPLASH_MESSAGE		PROC
						TEXTLOCATION	28H,0AH
						MOV		SI,OFFSET MSG_DEMOSPLASH_1
						CALL	PRINT_TALL

						TEXTLOCATION	28H,0BH
						MOV		SI,OFFSET MSG_DEMOSPLASH_2
						CALL	PRINT_TALL

						TEXTLOCATION	28H,0CH
						MOV		SI,OFFSET MSG_DEMOSPLASH_3
						CALL	PRINT_TALL

						RET
DEMOSPLASH_MESSAGE		ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Input
;   FS    IO.SYS Start Segment
; Output
;   DS:SI Offset to the JMPF xxxx:0000
;   CF    Set if not found
FIND_JUMP_INSTRUCTION	PROC
						PUSH	DS
						PUSH	ES

						PUSH	FS
						POP		DS	; DS:SI  IO.SYS
						PUSH	CS
						POP		ES	; ES:DI  Pattern

						CLD

FIND_JUMP_INSTRUCTION_OUTER_LOOP:
						MOV		SI,0

FIND_JUMP_INSTRUCTION_INNER_LOOP:
						MOV		CX,INT_21_AH_48_LEN
						MOV		DI,OFFSET INT_21_AH_48_PTN
						PUSH	SI
						REPE	CMPSB
						POP		SI
						JNE		SHORT FIND_JUMP_INSTRUCTION_INNER_NEXT

						CMP		DWORD PTR [SI+010h],0FF33C08Eh
						JE		SHORT FIND_JUMP_INSTRUCTION_FOUND

FIND_JUMP_INSTRUCTION_INNER_NEXT:
						INC		SI
						CMP		SI,16
						JNE		FIND_JUMP_INSTRUCTION_INNER_LOOP

						MOV		SI,DS
						INC		SI
						MOV		DS,SI
						CMP		SI,04000h
						JB		FIND_JUMP_INSTRUCTION_OUTER_LOOP

						STC	; Not found
						JMP		SHORT FIND_JUMP_INSTRUCTION_EXIT

FIND_JUMP_INSTRUCTION_FOUND:
						CLC
						PUSH	DS
						POP		FS

FIND_JUMP_INSTRUCTION_EXIT:
						POP		ES
						POP		DS
						RET

FIND_JUMP_INSTRUCTION	ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


TRANSFER_SELF			PROC
						PUSH	ES
						PUSH	DS
						PUSH	SI
						PUSH	DI
						PUSh	CX

						PUSH	CS
						POP		DS
						MOV		ES,BX
						XOR		SI,SI
						XOR		DI,DI
						MOV		CX,OFFSET END_OF_THE_WORLD
						REP		MOVSB

						POP		CX
						POP		DI
						POP		SI
						POP		DS
						POP		ES
						RET
TRANSFER_SELF			ENDP


; <<

END_OF_THE_WORLD:

DATA_CODE				ENDS

						END		MAIN
