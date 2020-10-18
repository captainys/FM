; From SYSROM
; BL:Device Type   1:HD  2:FD  8:CD
; BH:Unit Number

MAIN					PROC

						DB			"IPL4"

						; ****ing MASM kindly inserts NOP after JMP and messes up the offsets.  Good job, Microsoft.
						DB		0EBH,(REALMAIN-@f)  ; JMP		REALMAIN
@@:

						DB			55H dup (0)

REALMAIN:
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

						POP			BX
						PUSH		BX

						MOV			AL,BH	; Unit number
						OR			AL,20H	; Floppy Disk
						MOV			CS:[DEVICEID],AL

						; FD Restore (AL=Device ID) >>
						MOV			AH,03H
						XOR			CH,CH
						; How can I write CALL 		FAR PTR 0FFFBH:0014H
						DB			9AH		; CALLF FFFB:0014
						DW			0014H,0FFFBH
						; FD Restore (AL=Device ID) <<


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
						DW			0014H,0FFFBH

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
						PUSH		CS
						POP			DS
						MOV			DI,01H+02H*(80*16)
						MOV			SI,OFFSET ERROR_MESSAGE
						CALL		PRINT_TALL
@@:	
						JMP			@b


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
