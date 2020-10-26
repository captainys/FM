						ASSUME	CS:CODE,DS:CODE


						.386p



CODE					SEGMENT	USE16

						INCLUDE		IODEF.ASM
						INCLUDE		DEF.ASM


MAIN					PROC

						DB		"IPL4"

						JMP		REALMAIN

						DB		053H dup(0)  ; Purpose of this area is unknown.  But, Towns 2F crashes without this gap.


; From SYSROM
; BL:Device Type   1:SCSI  2:FD  8:CD
; BH:Unit Number

						; Need to:
						;   Copy self to B400:0000
REALMAIN:
						PUSH	AX
						PUSH	BX

						PUSH	CS
						POP		DS
						MOV		AX,0B400H
						MOV		ES,AX

						XOR		SI,SI
						XOR		DI,DI
						MOV		CX,512
						REP MOVSB

						DB		0EAH		; JMPF B400:READ_PARTITION_TABLE
						DW		OFFSET READ_PARTITION_TABLE,0B400H
READ_PARTITION_TABLE:
						CALL	INITGRAPHICS

						POP		BX
						PUSH	BX

						MOV		AX,0B100H
						MOV		DS,AX

						MOV		AH,05H	; Read Sector

						MOV		AL,BH	; Device ID
						AND		AL, 07H
						OR		AL,0B0H

						XOR		CX,CX	; CH needs to be 0
						MOV		DX,1	; LBA=1

						MOV		BX,1	; Read 1 sector
						XOR		DI,DI	; OFFSET 0

						DB		9AH		; CALLF FFFB:0014
						DW		0014H,0FFFBH

						JB		SHOW_ERROR_PARTITION_TABLE

						MOV		SI,0020H
						MOV		CX,10
@@:
						CMP		BYTE PTR DS:[SI],0FFH
						JE		@f
						ADD		SI,0030H
						LOOP	@b
						JMP		SHOW_ERROR_NO_BOOT_PARTITION
@@:
						MOV		CX,DS:[SI+4]	; LBA High
						MOV		DX,DS:[SI+2]	; LBA Low
						XOR		CH,CH	; CH needs to be zero

						MOV		AX,0B000H
						MOV		DS,AX

						MOV		AH,05H	; Read Sector

						POP		BX
						PUSH	BX

						MOV		AL,BH	; Device ID
						AND		AL, 07H
						OR		AL,0B0H

						MOV		BX,1	; Read 1 sector
						XOR		DI,DI	; OFFSET 0

						DB		9AH		; CALLF FFFB:0014
						DW		0014H,0FFFBH

						JB		SHOW_ERROR_PARTITION_TABLE

						CMP		DWORD PTR DS:[0],344C5049H	; "IPL4"
						JNE		SHOW_ERROR_NO_IPL

						POP		BX
						POP		AX

						DB		0EAH		; JMPF B000:0004
						DW		0004H,0B000H



SHOW_ERROR_PARTITION_TABLE:
						MOV		SI,OFFSET ERROR_PARTITION_TABLE
						JMP		PRINT_ERROR_AND_HALT

SHOW_ERROR_IPL_SECTOR:
						MOV		SI,OFFSET ERROR_IPL_SECTOR
						JMP		PRINT_ERROR_AND_HALT

SHOW_ERROR_NO_BOOT_PARTITION:
						MOV		SI,OFFSET ERROR_NO_BOOT_PARTITION
						JMP		PRINT_ERROR_AND_HALT

SHOW_ERROR_NO_IPL:
						MOV		SI,OFFSET ERROR_NO_IPL
						; JMP		PRINT_ERROR_AND_HALT

PRINT_ERROR_AND_HALT:
						PUSH	CS
						POP		DS
						MOV		DI,01H+01H*(80*16)
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

MESSAGE					DB	"SCSI-HD MBR",0
ERROR_PARTITION_TABLE	DB	"FAILED TO READ PARTITION TABLE",0
ERROR_IPL_SECTOR		DB	"FAILED TO READ IPL SECTOR",0
ERROR_NO_BOOT_PARTITION	DB	"NO BOOT PARTITION",0
ERROR_NO_IPL			DB	"NO IPL",0


CODE					ENDS



						END		MAIN
