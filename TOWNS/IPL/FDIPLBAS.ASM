; From SYSROM
; BL:Device Type   1:HD  2:FD  8:CD
; BH:Unit Number

MAIN					PROC

						DB			"IPL4"

						CLI
						CLD
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


						MOV			WORD PTR CS:[TRACK_SIDE],BOOTLOADER_FD_BEGIN_TRACK*2+BOOTLOADER_FD_BEGIN_SIDE
						MOV			BYTE PTR CS:[SECTOR],BOOTLOADER_FD_BEGIN_SECTOR
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

						MOV			DL,CS:[SECTOR]

						MOV			BL,9
						SUB			BL,DL
						XOR			BH,BH

						MOV			DI,CS:[BUFFADDR]

						; How can I write CALL 		FAR PTR 0FFFBH:0014H
						DB			9AH		; CALLF FFFB:0014
						DW			 0014H
						DW			0FFFBH

						JB			READ_ERROR

						MOV			BL,9
						SUB			BL,CS:[SECTOR]
						XOR			BH,BH
						SHL			BX,10		; ReadSize=1024*SectorCount

						MOV			BYTE PTR CS:[SECTOR],1
						INC			WORD PTR CS:[TRACK_SIDE]
						ADD			WORD PTR CS:[BUFFADDR],BX
						JNC			@b

@@:
						MOV			BX,BOOTLOADER_SEGMENT
						MOV			FS,BX
						MOV			WORD PTR FS:[LOADER_CONTROL_FLAGS_OFFSET],LOADER_FLAGS_CUSTOM

						POP			BX		; RESTORING INCOING BX

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
