WAIT_BUTTON_RELEASE		PROC

						PUSH	AX
						PUSH	DX

@@:
						MOV		AL,3FH
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
						MOV		AL,3FH
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
						MOV		AL,3FH
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

						MOV		AL,3FH
						MOV		DX,IO_PAD_OUT
						OUT		DX,AL

						MOV		DX,IO_PADA_IN
						IN		AL,DX
						AND		AL,3FH


						PUSH	AX
						MOV		DX,IO_KEYBOARD_STATE
						IN		AL,DX
						AND		AL,1
						JE		READ_PADA_KEY_INPUT_DONE

						MOV		DX,IO_KEYBOARD_DATA
						IN		AL,DX

						MOV		AH,CS:[LAST_KEY_READ]
						MOV		CS:[LAST_KEY_READ],AL
						AND		AH,90H
						CMP		AH,80H
						JNE		READ_PADA_KEY_INPUT_DONE

						CMP		AL,4FH	; Left
						JNE		@f
						POP		AX
						AND		AL,0FFH-04H
						JMP		READ_PADA_THERE_WAS_KEY_INPUT
@@:
						CMP		AL,51H	; Right
						JNE		@f
						POP		AX
						AND		AL,0FFH-08H
						JMP		READ_PADA_THERE_WAS_KEY_INPUT
@@:
						CMP		AL,4DH	; Up
						JNE		@f
						POP		AX
						AND		AL,0FFH-01H
						JMP		READ_PADA_THERE_WAS_KEY_INPUT
@@:
						CMP		AL,50H	; Down
						JNE		@f
						POP		AX
						AND		AL,0FFH-02H
						JMP		READ_PADA_THERE_WAS_KEY_INPUT
@@:
						CMP		AL,35H	; Space
						JNE		@f
						POP		AX
						AND		AL,0FFH-10H
						JMP		READ_PADA_THERE_WAS_KEY_INPUT
@@:
						CMP		AL,73H	; Execute
						JNE		@f
						POP		AX
						AND		AL,0FFH-10H
						JMP		READ_PADA_THERE_WAS_KEY_INPUT
@@:
						CMP		AL,1DH	; Return
						JNE		@f
						POP		AX
						AND		AL,0FFH-10H
						JMP		READ_PADA_THERE_WAS_KEY_INPUT
@@:

READ_PADA_KEY_INPUT_DONE:
						POP		AX
READ_PADA_THERE_WAS_KEY_INPUT:


						POP		DX
						RET

READ_PADA				ENDP


LAST_KEY_READ			DB		0

