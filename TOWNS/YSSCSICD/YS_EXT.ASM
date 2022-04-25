;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; YS Extension INT 93H AX=71C0H
YS_EXT_PLAY_CDDA		PROC

						CALL	YS_EXT_REMEMBER_TIME

						PUSH	CS
						POP		DS
						MOV		AX,50C0H
						MOV		CX,0001H
						MOV		DI,OFFSET YS_EXT_PLAY_TIME_BUFFER

						JMP		INT93H_HOOKPROC	; Jump back with AX=50C0H

YS_EXT_PLAY_CDDA		ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; YS Extension INT 93H AX=72C0H
YS_EXT_PLAY_CDDA_BCD	PROC

						CALL	YS_EXT_REMEMBER_TIME
						CALL	YS_EXT_CONVERT_TIME_BCD2BIN

						PUSH	CS
						POP		DS
						MOV		AX,50C0H
						MOV		CX,0001H
						MOV		DI,OFFSET YS_EXT_PLAY_TIME_BUFFER

						JMP		INT93H_HOOKPROC	; Jump back with AX=50C0H

YS_EXT_PLAY_CDDA_BCD	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

YS_EXT_REMEMBER_TIME	PROC

						MOV		WORD PTR CS:[YS_EXT_PLAY_TIME_BUFFER],BX
						MOV		WORD PTR CS:[YS_EXT_PLAY_TIME_BUFFER+2],CX
						MOV		WORD PTR CS:[YS_EXT_PLAY_TIME_BUFFER+4],DX
						RET

YS_EXT_REMEMBER_TIME	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

YS_EXT_CONVERT_TIME_BCD2BIN	PROC

						PUSH	CX

						MOV		DI,OFFSET YS_EXT_PLAY_TIME_BUFFER
						MOV		CL,6
@@:
						MOV		AL,CS:[DI]
						MOV		CH,AL

						SHR		AL,4
						MOV		AH,10
						MUL		AH

						AND		CH,0FH
						ADD		AL,CH

						MOV		CS:[DI],AL
						INC		DI

						XOR		CH,CH
						LOOP	@b

						POP		CX
						RET

YS_EXT_CONVERT_TIME_BCD2BIN	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

YS_EXT_PLAY_TIME_BUFFER	DB		6 dup (0)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Input AL in BCD
; Output AL in Binary
;        AH destroyed
BCD2BIN					PROC

						PUSH	BX

						MOV		BL,AL
						AND		BL,0FH

						SHR		AL,4
						MOV		AH,10
						MUL		AH

						ADD		AL,BL

						POP		BX
						RET

BCD2BIN					ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
