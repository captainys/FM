						ASSUME	CS:CODE,DS:CODE


						.386p



; Some SCSI CD drives are real slow to spin up.
; TOWNS System ROM may fail to boot in the first attempt due to time out.
; But, should succeed after it goes around other boot devices and come back to 
; this drive.



CODE					SEGMENT	USE16

						INCLUDE		IODEF.ASM
						INCLUDE		DEF.ASM

; From SYSROM
; BL:Device Type   1:SCSI  2:FD  8:CD
; BH:Unit Number

MAIN					PROC

						DB		"IPL4"
						JMP		REALMAIN

LOADER_LBA				DD		4		; Beginning Sector 4  ( +8192 bytes into ISO)
YSSCSICD_LBA			DD		32		; Beginning Sector 32 (+65536 bytes into ISO)

REALMAIN:
						CMP		BL,1	; If in the internal CD-ROM drive, don't do anything.
						JE		@f
						RETF

@@:
						CLI
						PUSH	CS
						POP		DS
						PUSH	BX

						CALL	INITGRAPHICS
						CALL	VRAMMODE
						CALL	CLS

						MOV		AX,0101H
						CALL	LOCATE
						MOV		SI,OFFSET MESSAGE
						CALL	PRINT_TALL

						POP		BX
						PUSH	BX

						MOV		AL,BH	; Unit number
						OR		AL,0B0H	; SCSI Device
						MOV		CS:[DEVICEID],AL

						; If it comes here, SYSROM already read the first sector of the SCSI CD.
						; CD initialization must be done by here.
						; Also, CD drive is supposed to be ready.

						MOV		CL,BH
						AND		CL,7
						MOV		SI,OFFSET SCSI_READ_SECTOR_CMD

						MOV		EDX,LOADER_LBA
						MOV		[SI+4],DH
						MOV		[SI+5],DL
						ROR		EDX,16
						MOV		[SI+2],DH
						MOV		[SI+3],DL

						MOV		WORD PTR [SI+7],2000H	; 32 sectors, but in Big-Endian

						MOV		EDI,80000H

						CALL	SCSI_COMMAND
						JB		@f

						MOV		AX,BOOTLOADER_SEGMENT
						MOV		FS,AX
						MOV		WORD PTR FS:[LOADER_CONTROL_FLAGS_OFFSET],CONTROL_FLAG_PROMPT_CD
						MOV		EDX,[YSSCSICD_LBA]
						MOV		DWORD PTR FS:[LOADER_LBA_BEGIN_OFFSET],EDX
						MOV		BYTE PTR FS:[LOADER_SECTOR_COUNT_OFFSET],24	; 24 sectors

						POP		BX

						DB		9AH		; CALLF 8000:0000
						DW		0000H
						DW		BOOTLOADER_SEGMENT

@@:
						MOV		AX,0102H
						CALL	LOCATE
						MOV		SI,OFFSET ERROR_MESSAGE
						CALL	PRINT_TALL
						JMP		@b


MAIN					ENDP

						INCLUDE		../SCSILIB/SCSIIO.ASM
						INCLUDE		DRAWFONT.ASM
						INCLUDE		MEMBANK.ASM

MESSAGE					DB	"SCSI-CD BOOT",0
ERROR_MESSAGE			DB	"SECTOR READ ERROR!",0

SCSI_READ_SECTOR_CMD	DB	28H,0,0,0,0,0,0
						DB	0,32  ; 32 sectors in big-endian
						DB	0
						
DEVICEID				DB	0
TRACK_SIDE				DW	0
SECTOR					DB	0
BUFFADDR				DW	0

CODE					ENDS



						END		MAIN
