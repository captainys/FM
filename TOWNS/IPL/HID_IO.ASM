; FM TOWNS Techincal Data Book pp.238
; "To make it compatible with MSX game pads, COM out must be zero."
; "To read A and B buttons, TRIG out must be one."
; The value written to I/O 04D6H must be 0FH instead of 3FH.
PAD_OUT_CONST			EQU		0FH


WAIT_BUTTON_RELEASE		PROC

						PUSH	AX
						PUSH	DX

@@:
						MOV		AL,PAD_OUT_CONST
						MOV		DX,IO_PAD_OUT
						OUT		DX,AL

						MOV		DX,IO_PADA_IN
						IN		AL,DX
						AND		AL,30H
						CMP		AL,30H
						JNE		@b

						MOV		DX,IO_PADB_IN
						IN		AL,DX
						AND		AL,30H
						CMP		AL,30H
						JNE		@b

						POP		DX
						POP		AX
						RET

WAIT_BUTTON_RELEASE		ENDP



WAIT_BUTTON_PRESS		PROC

						PUSH	AX
						PUSH	DX

@@:
						MOV		AL,PAD_OUT_CONST
						MOV		DX,IO_PAD_OUT
						OUT		DX,AL

						MOV		DX,IO_PADA_IN
						IN		AL,DX
						AND		AL,30H
						CMP		AL,30H
						JNE		@f

						MOV		DX,IO_PADB_IN
						IN		AL,DX
						AND		AL,30H
						CMP		AL,30H
						JE		@b

@@:
						POP		DX
						POP		AX
						RET
WAIT_BUTTON_PRESS		ENDP



WAIT_PADA_RELEASE		PROC

						PUSH	AX
						PUSH	DX

@@:
						MOV		AL,PAD_OUT_CONST
						MOV		DX,IO_PAD_OUT
						OUT		DX,AL

						MOV		DX,IO_PADA_IN
						IN		AL,DX
						AND		AL,3FH
						CMP		AL,3FH
						JNE		@b


						; Clear key buffer as well.
@@:
						MOV		DX,IO_KEYBOARD_STATE
						IN		AL,DX
						AND		AL,1
						JE		@f

						MOV		DX,IO_KEYBOARD_DATA
						IN		AL,DX
						JMP		@b


@@:
						POP		DX
						POP		AX
						RET

WAIT_PADA_RELEASE		ENDP



READ_PADA				PROC

						PUSH	DX

						MOV		AL,PAD_OUT_CONST
						MOV		DX,IO_PAD_OUT
						OUT		DX,AL

						MOV		DX,IO_PADA_IN
						IN		AL,DX
						AND		AL,3FH


						PUSH	AX
						MOV		DX,IO_KEYBOARD_STATE
						IN		AL,DX
						AND		AL,1
						JE		SHORT READ_PADA_KEY_INPUT_DONE

						MOV		DX,IO_KEYBOARD_DATA
						IN		AL,DX

						MOV		AH,CS:[LAST_KEY_READ]
						MOV		CS:[LAST_KEY_READ],AL
						AND		AH,90H
						CMP		AH,80H
						JNE		SHORT READ_PADA_KEY_INPUT_DONE

						MOV		DL,0FFH-04H
						CMP		AL,4FH	; Left
						JE		SHORT READ_PADA_THERE_WAS_KEY_INPUT

						MOV		DL,0FFH-08H
						CMP		AL,51H	; Right
						JE		SHORT READ_PADA_THERE_WAS_KEY_INPUT

						MOV		DL,0FFH-01H
						CMP		AL,4DH	; Up
						JE		SHORT READ_PADA_THERE_WAS_KEY_INPUT

						MOV		DL,0FFH-02H
						CMP		AL,50H	; Down
						JE		SHORT READ_PADA_THERE_WAS_KEY_INPUT

						MOV		DL,0FFH-10H
						CMP		AL,35H	; Space
						JE		SHORT READ_PADA_THERE_WAS_KEY_INPUT

						MOV		DL,0FFH-10H
						CMP		AL,73H	; Execute
						JE		SHORT READ_PADA_THERE_WAS_KEY_INPUT

						MOV		DL,0FFH-10H
						CMP		AL,1DH	; Return
						JE		SHORT READ_PADA_THERE_WAS_KEY_INPUT

READ_PADA_KEY_INPUT_DONE:
						POP		AX
						POP		DX
						RET

; DL is AND-pattern
READ_PADA_THERE_WAS_KEY_INPUT:
						POP		AX
						AND		AL,DL
						POP		DX
						RET


READ_PADA				ENDP


LAST_KEY_READ			DB		0

