						ASSUME	CS:CODE,DS:CODE


						.386p



DEFAULT_LOADER_LBA		EQU		33
FIRST_PARTITION_LBA		EQU		3



CODE					SEGMENT	USE16

						INCLUDE		IODEF.ASM
						INCLUDE		DEF.ASM

; From SYSROM
; BL:Device Type   1:SCSI  2:FD  8:CD
; BH:Unit Number

MAIN					PROC

						DB		"IPL4"

						; ****ing MASM kindly inserts NOP after JMP and messes up the offsets.  Good job, Microsoft.
						DB		0EBH,(REALMAIN-@f)  ; JMP		REALMAIN
@@:
						DB		"FM TOWNS RESCUE BOOT LOADER BY CAPTAINYS"	; 40 chars
						DB		54 dup (0)									; 40+54=0x5E (Why 0x5E?  I don't know Fujitsu's IPL leaves this many bytes.)

LOADER_LBA				DD		DEFAULT_LOADER_LBA-FIRST_PARTITION_LBA
YSSCSICD_LBA			DD		(DEFAULT_LOADER_LBA+128-FIRST_PARTITION_LBA)


REALMAIN:
						CMP		BL,1	; Need to be from SCSI
						JE		@f
						RETF
@@:
						CLI
						CLD
						PUSH		CS
						POP			DS
						PUSH		BX

						CALL		INITGRAPHICS
						CALL		VRAMMODE
						CALL		CLS

						MOV			DI,01H+01H*(80*16)
						MOV			SI,OFFSET MESSAGE
						CALL		PRINT_TALL


						; Find which partition it is booting from and
						; add displacement to LOADER_LBA and YSSCSICD_LBA
						ADD		AX,0100H	; Partition Table is written in B100:0000
						MOV		FS,AX
						MOV		SI,0020H
@@:
						; Master Boot Sector or REIPL.COM marks the starting-partition with 0FFH.
						; Valid boot partition must start with FF 01
						MOV		EAX,FS:[SI+2]	; Tentative
						CMP		WORD PTR FS:[SI],01FFH
						JE		@f
						ADD		SI,030H
						CMP		SI,0200H
						JL		@b

						; If not found, this is not read from MBS or REIPL.COM.  This probably is the MBS.
						; In which case, the displacement should be 3 sectors (first partition)
						MOV		EAX,FIRST_PARTITION_LBA
@@:
						ADD		DWORD PTR DS:[LOADER_LBA],EAX
						ADD		DWORD PTR DS:[YSSCSICD_LBA],EAX


						POP			BX
						PUSH		BX

						MOV		AX,BOOTLOADER_SEGMENT
						MOV		DS,AX


						MOV		AH,05H	; Read Sector

						MOV		AL,BH	; Device ID
						AND		AL, 07H
						OR		AL,0B0H

						MOV		CX,WORD PTR CS:[LOADER_LBA+2]
						MOV		DX,WORD PTR CS:[LOADER_LBA]
						XOR		CH,CH	; Just in case

						MOV		BX,32	; 32 sectors
						XOR		DI,DI	; OFFSET 0

						; How can I write CALL 		FAR PTR 0FFFBH:0014H
						DB		9AH		; CALLF FFFB:0014
						DW		 0014H
						DW		0FFFBH

						JB		ERROR_END

						MOV		AX,BOOTLOADER_SEGMENT
						MOV		FS,AX

						MOV		WORD PTR FS:[LOADER_CONTROL_FLAGS_OFFSET],CONTROL_FLAG_BOOT_MENU
						MOV		EDX,CS:[LOADER_LBA]
						MOV		DWORD PTR FS:[LOADER_SELF_LBA_OFFSET],EDX
						MOV		EDX,CS:[YSSCSICD_LBA]
						MOV		DWORD PTR FS:[LOADER_YSSCSICD_LBA_OFFSET],EDX
						MOV		BYTE PTR FS:[LOADER_SECTOR_COUNT_OFFSET],96	; 96 sectors

						POP		BX

						DB		9AH		; CALLF 8000:0000
						DW		0000H
						DW		BOOTLOADER_SEGMENT

						; Not really happen, but if the loader fails, return to the system ROM.
						RETF

ERROR_END:
						PUSH	CS
						POP		DS
						MOV		DI,01H+01H*(80*16)
						MOV		SI,OFFSET ERROR_MESSAGE
						CALL	PRINT_TALL
@@:
						JMP		@b


MAIN					ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


INITGRAPHICS			PROC

						MOV		DX,IO_FMR_GVRAMDISPMODE
						MOV		AL,27H  ; Show all planes, write to Page 0 (Page 0 is upper half of VRAM Layer 0)
						OUT		DX,AL

						MOV		DX,IO_FMR_GVRAMMASK
						MOV		AL,0FH  ; Write to all planes
						OUT		DX,AL

						RET

INITGRAPHICS			ENDP



CLS						PROC
						PUSH	ES
						PUSH	DI
						PUSH	AX
						PUSH	CX

						AND		AL,0FH
						MOV		DX,IO_FMR_GVRAMMASK
						OUT		DX,AL

						MOV		AX,0C000H
						MOV		ES,AX
						MOV		DI,0
						MOV		CX,80*400/2
						MOV		AX,0
						REP STOSW

						POP		CX
						POP		AX
						POP		DI
						POP		ES
						RET
CLS						ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; DI:  VRAM ADDRESS
; AH:  ASCII Code
; C0000H must be in FM-R VRAM mode.
; BX preserved
; DS preserved
DRAWFONT_TALL			PROC
						PUSH	DS

						MOV		DX,0C000H
						MOV		DS,DX

						MOV		DX,IO_KVRAM_OR_ANKFONT
						MOV		AL,1
						OUT		DX,AL

						; ANK Font ROM CA000H-
						MOV		AL,8
						MUL		AH
						ADD		AX,0A000H

						MOV		CX,8
						MOV		SI,AX
@@:
						MOV		DH,DS:[SI]
						MOV		[DI],DH
						MOV		[DI+50H],DH
						INC		SI
						ADD		DI,0A0H
						LOOP	@b

						MOV		DX,IO_KVRAM_OR_ANKFONT
						XOR		AL,AL
						OUT		DX,AL

						POP		DS
						RET
DRAWFONT_TALL			ENDP



; Input
;   DS:SI     String
;   DI        VRAM Address
PRINT_TALL				PROC
						PUSH	ES
						PUSH	SI
						PUSH	DI
						PUSH	AX
						PUSH	DX
						PUSH	CX

						MOV		AX,0C000H
						MOV		ES,AX
						MOV		BX,SI
@@:
						MOV		SI,BX
						LODSB
						CMP		AL,0
						JE		@f
						MOV		AH,AL
						CALL	DRAWFONT_TALL
						ADD		DI,1-80*16
						ADD		BX,1
						JMP		@b
@@:
						POP		CX
						POP		DX
						POP		AX
						POP		DI
						POP		SI
						POP		ES
						RET
PRINT_TALL				ENDP

						INCLUDE		MEMBANK.ASM

MESSAGE					DB	"SCSI-HD BOOT",0
ERROR_MESSAGE			DB	"SOMETHING WENT WRONG.",0

CODE					ENDS



						END		MAIN
