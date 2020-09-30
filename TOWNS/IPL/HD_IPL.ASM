						ASSUME	CS:CODE,DS:CODE


						.386p



DEFAULT_LOADER_LBA		EQU		33



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

LOADER_LBA					DD		DEFAULT_LOADER_LBA
YSSCSICD_LBA				DD		(DEFAULT_LOADER_LBA+128)
BOOTMENU_DEFAULT_SELECTION	DB	3


REALMAIN:
						CMP		BL,1	; Need to be from SCSI
						JE		@f
						RETF
@@:
						CLI
						PUSH		CS
						POP			DS
						PUSH		BX

						CALL		INITGRAPHICS
						CALL		VRAMMODE
						CALL		CLS

						MOV			AX,0101H
						CALL		LOCATE
						MOV			SI,OFFSET MESSAGE
						CALL		PRINT_TALL

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

						JB		@f

						MOV		AX,BOOTLOADER_SEGMENT
						MOV		FS,AX

						MOV		AL,CS:[BOOTMENU_DEFAULT_SELECTION]
						MOV		BYTE PTR FS:[LOADER_MENU_DEFAULT_SELECTION_OFFSET],AL

						MOV		WORD PTR FS:[LOADER_CONTROL_FLAGS_OFFSET],CONTROL_FLAG_BOOT_MENU
						MOV		EDX,CS:[YSSCSICD_LBA]
						MOV		DWORD PTR FS:[LOADER_LBA_BEGIN_OFFSET],EDX
						MOV		BYTE PTR FS:[LOADER_SECTOR_COUNT_OFFSET],96	; 96 sectors

						POP		BX

						DB		9AH		; CALLF 8000:0000
						DW		0000H
						DW		BOOTLOADER_SEGMENT

						; Not really happen, but if the loader fails, return to the system ROM.
						RETF

@@:
						PUSH	CS
						POP		DS
						MOV		AX,0101H
						CALL	LOCATE
						MOV		SI,OFFSET MESSAGE
						CALL	PRINT_TALL
@@:
						JMP		@b


MAIN					ENDP

						INCLUDE		DRAWFONT.ASM
						INCLUDE		MEMBANK.ASM

MESSAGE					DB	"SCSI-HD BOOT",0
ERROR_MESSAGE			DB	"SECTOR READ ERROR!",0

CODE					ENDS



						END		MAIN
