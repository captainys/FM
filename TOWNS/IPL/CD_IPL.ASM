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

						; ****ing MASM kindly inserts NOP after JMP and messes up the offsets.  Good job, Microsoft.
						DB		0EBH,(REALMAIN-@f)  ; JMP		REALMAIN
@@:
						DB		5EH dup (0)

LOADER_LBA				DD		4		; Beginning Sector 4  ( +8192 bytes into ISO)
YSSCSICD_LBA			DD		32		; Beginning Sector 32 (+65536 bytes into ISO)

REALMAIN:
						CMP		BL,1	; SCSI CD?
						JE		@f
						CMP		BL,8	; Internal CD?
						JE		@f
						RETF

@@:
						CLI
						CLD
						PUSH	CS
						POP		DS
						PUSH	BX

						CALL	INITGRAPHICS
						CALL	VRAMMODE
						CALL	CLS

						TEXTLOCATION	01H,01H
						MOV		SI,OFFSET MESSAGE
						CALL	PRINT_TALL

						POP		BX
						PUSH	BX

						CMP		BL,1
						JE		SCSICD



INTERNALCD:
						PUSH	DS
						MOV		AX,8000H
						MOV		DS,AX
						XOR		DI,DI

						MOV		AX,05C0H	; Read Sector, Device=0C0H
						XOR		CX,CX
						MOV		DX,WORD PTR CS:[LOADER_LBA]
						MOV		BX,32		; 32 Sectors

						; How can I write CALL 		FAR PTR 0FFFBH:0014H
						DB		9AH		; CALLF FFFB:0014
						DW		 0014H
						DW		0FFFBH

						POP		DS
						JB		CD_ERROR

						JMP		SECONDARY_LOADER_LOADED



SCSICD:
						MOV		AL,BH	; Unit number
						OR		AL,0B0H	; SCSI Device
						MOV		CS:[DEVICEID],AL

						; If it comes here, SYSROM already read the first sector of the SCSI CD.
						; CD initialization must be done by here.
						; Also, CD drive is supposed to be ready.

						MOV		CL,BH
						AND		CL,7
						MOV		SI,OFFSET SCSI_READ_SECTOR_CMD

						MOV		EDX,CS:[LOADER_LBA]
						MOV		[SI+4],DH
						MOV		[SI+5],DL
						ROR		EDX,16
						MOV		[SI+2],DH
						MOV		[SI+3],DL

						MOV		WORD PTR [SI+7],2000H	; 32 sectors, but in Big-Endian

						MOV		EDI,80000H

						CALL	SCSI_COMMAND
						JB		CD_ERROR



SECONDARY_LOADER_LOADED:
						MOV		AX,BOOTLOADER_SEGMENT
						MOV		FS,AX
						MOV		WORD PTR FS:[LOADER_CONTROL_FLAGS_OFFSET],CONTROL_FLAG_DONT_REMEMBER_BOOT_CHOICE+CONTROL_FLAG_DONT_SCAN_PARTITION+CONTROL_FLAG_BOOT_MENU+CONTROL_FLAG_PROMPT_CD_CHANGE

						MOV		EDX,[YSSCSICD_LBA]
						MOV		DWORD PTR FS:[LOADER_YSSCSICD_LBA_OFFSET],EDX
						MOV		BYTE PTR FS:[LOADER_SECTOR_COUNT_OFFSET],24	; 24 sectors

						POP		BX

						DB		9AH		; CALLF 8000:0000
						DW		0000H
						DW		BOOTLOADER_SEGMENT

CD_ERROR:
						TEXTLOCATION	01H,02H
						MOV		SI,OFFSET ERROR_MESSAGE
						CALL	PRINT_TALL
						JMP		@b


MAIN					ENDP

						INCLUDE		../SCSILIB/SCSIIO.ASM
						INCLUDE		DRAWFONT.ASM
						INCLUDE		MEMBANK.ASM

MESSAGE					DB	"CD BOOT",0
ERROR_MESSAGE			DB	"SECTOR READ ERROR!",0

SCSI_READ_SECTOR_CMD	DB	28H,0,0,0,0,0,0
						DB	0,32  ; 32 sectors in big-endian
						DB	0
						
DEVICEID				DB	0
TRACK_SIDE				DW	0
SECTOR					DB	0
BUFFADDR				DW	0


						; 80386SX SYSTEM ROM will read Sector 1 for the partition table.
						; Then checks magic number first six bytes.
						; Then finds a boot partition and reads first sector of the boot partition.
						; If "IPL4", reads sector written at [0020].  If it is not FBIOS, the SYSROM will boot into the CD IPL.  If not force ROM IO.SYS.

						ORG		0800H  ; Sector 1

						DB		95H,78H,8EH,6DH,92H,0CAH,03H,00H,00H,00H,0FEH,0FFH,01H,00H,00H,02H
						DB		0010H dup (0FFH)

						DB		0FFH	; Boot Partition
						DB		1
						DD		2		; Start Sector
						DD		10		; Number of sectors (fake)
						DB		6 dup(0)
						DB		"MS-DOS          "
						DB		"RESCUE          "


						ORG		1000H  ; Sector 2
						DB		"IPL4"


CODE					ENDS



						END		MAIN
