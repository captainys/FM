


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



; DOS6 IPL   Commented out for the time being because I haven't figured how to patch DOS6 from IPL.

;	; Need to patch
;	; B000:000000DB 2EFF1E1201                CALLF   WORD PTR CS:[0112H]
;	;
;	;                                         CALLF   8000:HDIPLINTERCEPT
;	HDIPL_FROM_PATTERN2		DB		02Eh,0FFh,01Eh,012h,001h
;	HDIPL_TO_PATTERN2		DB		9AH		; CALLF XXXX:YYYY
;							DW		OFFSET HDIPLINTERCEPT
;							DW		08000H
;	
;	
;	
;	; B000:000000B1 26FF360000                PUSH    WORD PTR ES:[0000H]
;	; B000:000000B6 51                        PUSH    CX
;	; B000:000000B7 8B0E7600                  MOV     CX,[0076H]
;	; B000:000000BB CB                        RETF
;	GENERALIPL_FROM_PATTERN2	DB		026h,0FFh,036h,000h,000h
;								DB		051h
;								DB		08Bh,00Eh,076h,000h
;								DB		0CBh
;	
;	GENERALIPL_TO_PATTERN2		DB		08Bh,00Eh,076h,000h	; MOV CX,[0076H]
;								DB		0EAH		; JMPF
;								DW		OFFSET DOS6IPL_INTERCEPT
;								DW		8000h
;								DB		90h,90h	; NOP NOP



SETUP_INTERCEPT_AND_GO	PROC
						PUSH	DS
						PUSH	ES
						PUSHA


						; HD IPL Pattern 1
						MOV		SI,0B000h
						MOV		DS,SI
						PUSH	CS
						POP		ES

						XOR		SI,SI	; B000:0000 is the HD IPL location
						MOV		DX,2048/16 ; Length 2048 bytes maximum, divide by 16 to make it pages
						MOV		CX,6	; Pattern Length=6

						MOV		DI,OFFSET HDIPL_FROM_PATTERN	; ES:DI=Source Pattern
						MOV		BX,OFFSET HDIPL_TO_PATTERN   ; ES:BX=Write Pattern
						CALL	APPLY_PATCH


						; Commented out for the time being because I haven't figured how to patch DOS6 from IPL.
						;	; HD IPL Pattern 2 (DOS6+Towns OS)
						;	MOV		SI,0B000h
						;	MOV		DS,SI
						;	PUSH	CS
						;	POP		ES

						;	XOR		SI,SI	; B000:0000 is the HD IPL location
						;	MOV		DX,2048/16 ; Length 2048 bytes maximum, divide by 16 to make it pages
						;	MOV		CX,5	; Pattern Length=5

						;	MOV		DI,OFFSET HDIPL_FROM_PATTERN2	; ES:DI=Source Pattern
						;	MOV		BX,OFFSET HDIPL_TO_PATTERN2   ; ES:BX=Write Pattern
						;	CALL	APPLY_PATCH


						; Other IPLs
						MOV		SI,0B000h
						MOV		DS,SI
						PUSH	CS
						POP		ES

						XOR		SI,SI	; B000:0000 is the HD IPL location
						MOV		DX,2048/16 ; Length 2048 bytes maximum divide by 16 to make it pages
						MOV		CX,5	; Pattern Length=5

						MOV		DI,OFFSET GENERALIPL_FROM_PATTERN	; ES:DI=Source Pattern
						MOV		BX,OFFSET GENERALIPL_TO_PATTERN   ; ES:BX=Write Pattern
						CALL	APPLY_PATCH


						; Commented out for the time being because I haven't figured how to patch DOS6 from IPL.
						;	; IPL by (DOS6+Towns OS)
						;	MOV		SI,0B000h
						;	MOV		DS,SI
						;	PUSH	CS
						;	POP		ES

						;	XOR		SI,SI	; B000:0000 is the HD IPL location
						;	MOV		DX,2048/16 ; Length 2048 bytes maximum divide by 16 to make it pages
						;	MOV		CX,11	; Pattern Length=11

						;	MOV		DI,OFFSET GENERALIPL_FROM_PATTERN2	; ES:DI=Source Pattern
						;	MOV		BX,OFFSET GENERALIPL_TO_PATTERN2   ; ES:BX=Write Pattern
						;	CALL	APPLY_PATCH



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
						CALL	DO_386SX_THINGS
						CALL	SETUP_INTERCEPT_AND_GO
						RETF

; Patched DOS6 IPL does:
;					 	MOV     DX,0050H
;					 	MOV     ES,DX
;					 	MOV     CX,[0076H]
;					 	JMPF    8000:DOS6IPL_INTERCEPT
DOS6IPL_INTERCEPT:
						MOV		DX,ES:[0]

; DX must be the segment where FBIOS entry is at offset zero.
GENERALIPL_INTERCEPT:
						; This is called after IO.SYS is loaded and no return.
						PUSHA

						CALL	RESTORE_CMOS_IF_AUTOCMOS_IS_SET

						CALL	DO_386SX_THINGS

						CALL	PATCH_V21L20
						CMP		BYTE PTR CS:[SCSI_ID_CDROM],0FFH
						JE		SHORT GENERALIPL_INTERCEPT_SKIP_YSSCSICD
						TEST	CS:[CONTROL_FLAGS],CONTROL_FLAG_DONT_INSTALL_YSSCSICD
						JNE		SHORT GENERALIPL_INTERCEPT_SKIP_YSSCSICD

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
