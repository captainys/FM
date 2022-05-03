; Needs to patch
; B200:000000F3 BF1201                    MOV     DI,0112H
; B200:000000F6 2EFF1D                    CALLF   WORD PTR CS:[DI]
;
;                                         CALLF   8000:HDIPLINTERCEPT
;                                         NOP


HDIPL_FROM_PATTERN		DB		0BFh,012h,001h,02Eh,0FFh,01Dh
HDIPL_TO_PATTERN		DB		9AH		; CALLF FFFB:0014
						DW		OFFSET HDIPLINTERCEPT
						DW		08000H
						DB		90H		; NOP



;B000:000000B6 52                        PUSH    DX
;B000:000000B7 33D2                      XOR     DX,DX
;B000:000000B9 52                        PUSH    DX
;B000:000000BA CB                        RETF
GENERALIPL_FROM_PATTERN	DB		052h,033h,0D2h,052h,0CBh
GENERALIPL_TO_PATTERN	DB		0EAH		; JMPF
						DW		OFFSET GENERALIPL_INTERCEPT
						DW		08000H



SETUP_INTERCEPT_AND_GO	PROC
						PUSH	DS
						PUSH	ES
						PUSHA

						MOV		SI,0B000h
						MOV		DS,SI
						XOR		SI,SI	; B000:0000 is the HD IPL location
						MOV		DX,2048/16 ; Length 2048 bytes maximum, divide by 16 to make it pages
						MOV		CX,6	; Pattern Length=6

						PUSH	CS
						POP		ES
						MOV		DI,OFFSET HDIPL_FROM_PATTERN	; ES:DI=Source Pattern
						MOV		BX,OFFSET HDIPL_TO_PATTERN   ; ES:BX=Write Pattern
						CALL	APPLY_PATCH


						MOV		SI,0B000h
						MOV		DS,SI
						XOR		SI,SI	; B000:0000 is the HD IPL location
						MOV		DX,2048/16 ; Length 2048 bytes maximum divide by 16 to make it pages
						MOV		CX,5	; Pattern Length=5

						PUSH	CS
						POP		ES
						MOV		DI,OFFSET GENERALIPL_FROM_PATTERN	; ES:DI=Source Pattern
						MOV		BX,OFFSET GENERALIPL_TO_PATTERN   ; ES:BX=Write Pattern
						CALL	APPLY_PATCH

						POPA
						POP		ES
						POP		DS

						; This calls HD IPL.
						DB		9AH		; CALLF B000:0004
						DW		 0004H
						DW		0B000H

						RET


SETUP_INTERCEPT_AND_GO	ENDP



HDIPLINTERCEPT:
						; This is called after HD IPL reads partition IPL to B000:0000
						; Called as CALLF 8000:HDIPLINTERCEPT
						CALL	SETUP_INTERCEPT_AND_GO
						RETF


GENERALIPL_INTERCEPT:
						; This is called after IO.SYS is loaded and no return.
						PUSHA

						CALL	CRTC640X400_640X400
						CALL	CLS_HIGH

						CALL	PATCH_V21L20
						CMP		BYTE PTR CS:[SCSI_ID_CDROM],0FFH
						JE		SHORT GENERALIPL_INTERCEPT_SKIP_YSSCSICD
						PUSH	DS
						PUSH	CS
						POP		DS
						CALL	INJECT_YSSCSICD_INSTALL_CALLBACK
						POP		DS

GENERALIPL_INTERCEPT_SKIP_YSSCSICD:
						POPA
						PUSH    DX		; DX is IO.SYS entry segment
						XOR		DX,DX
						PUSH	DX		; IO.SYS Entry offset is always 0000h
						RETF
