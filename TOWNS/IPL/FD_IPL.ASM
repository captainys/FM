						ASSUME	CS:CODE,DS:CODE


						.386p



CODE					SEGMENT	USE16

						INCLUDE		IODEF.ASM
						INCLUDE		DEF.ASM

; From SYSROM
; BL:Device Type   1:HD  2:FD  8:CD
; BH:Unit Number

MAIN					PROC

						DB			"IPL4"

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

						MOV			AL,BH	; Unit number
						OR			AL,20H	; Floppy Disk
						MOV			CS:[DEVICEID],AL

						MOV			WORD PTR CS:[TRACK_SIDE],1
						MOV			WORD PTR CS:[BUFFADDR],0

						MOV			AX,BOOTLOADER_SEGMENT
						MOV			DS,AX
@@:
						MOV			AH,05H	 ; Read Sector
						MOV			AL,CS:[DEVICEID]
						MOV			CX,CS:[TRACK_SIDE]
						XOR			DH,DH
						SHR			CX,1
						RCL			DH,1
						MOV			DL,1
						MOV			BX,8
						MOV			DI,CS:[BUFFADDR]

						; How can I write CALL 		FAR PTR 0FFFBH:0014H
						DB			9AH		; CALLF FFFB:0014
						DW			 0014H
						DW			0FFFBH

						JB			READ_ERROR

						INC			WORD PTR CS:[TRACK_SIDE]
						ADD			WORD PTR CS:[BUFFADDR],8192
						JNC			@b

@@:
						POP			BX		; Keep Incoming AX

						DB			9AH		; CALLF 8000:0000
						DW			0000H
						DW			BOOTLOADER_SEGMENT


READ_ERROR:
						MOV			AX,0102H
						CALL		LOCATE
						MOV			SI,OFFSET ERROR_MESSAGE
						CALL		PRINT_TALL
@@:	
						JMP			@b


MAIN					ENDP

						INCLUDE		DRAWFONT.ASM
						INCLUDE		MEMBANK.ASM

MESSAGE					DB	"FD BOOT",0
ERROR_MESSAGE			DB	"SECTOR READ ERROR!",0

DEVICEID				DB	0
TRACK_SIDE				DW	0
BUFFADDR				DW	0

CODE					ENDS



						END		MAIN
