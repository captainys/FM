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



; Return:
;   AL  Pad state (b7 Select, b6 Run)
;   AH  Key Scan Code
; Guarantee to preserve DX.  BOOTMENU assumes so.
READ_PADA				PROC

						PUSH	DX

						MOV		AL,PAD_OUT_CONST
						MOV		DX,IO_PAD_OUT
						OUT		DX,AL

						MOV		DX,IO_PADA_IN
						IN		AL,DX
						OR		AL,0C0H
						XOR		AH,AH

						TEST	AL,03H
						JNE		READ_PADA_SELECTBTN_UP
						AND		AL,7FH
						OR		AL,3

READ_PADA_SELECTBTN_UP:
						TEST	AL,0CH
						JNE		READ_PADA_RUNBTN_UP
						AND		AL,0BFH
						OR		AL,0CH
READ_PADA_RUNBTN_UP:

						PUSH	AX
						MOV		DX,IO_KEYBOARD_STATE
						IN		AL,DX
						AND		AL,1
						JE		SHORT READ_PADA_KEY_INPUT_DONE

						MOV		DX,IO_KEYBOARD_DATA
						IN		AL,DX
						MOV		DH,AL

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
						MOV		DL,0FFh
; DL is AND-pattern
READ_PADA_THERE_WAS_KEY_INPUT:
						POP		AX
						AND		AL,DL
						MOV		AH,DH
						POP		DX
						RET

READ_PADA				ENDP


; Read PADA
;   If there is an input, wait until release, and then return.
READ_PADA_WAIT_RELEASE	PROC
						PUSH	DX

						CALL	READ_PADA
						CMP		AL,0FFH
						JE		READ_PADA_WAIT_RELEASE_NO_PAD_INPUT

						MOV		DX,AX	; Preserve AH (Key stroke)

READ_PADA_WAITREL_WAIT:
						CALL	READ_PADA

						MOV		AH,AL
						AND		AH,0C0H
						CMP		AH,0C0H
						JE		READ_PADA_WAITREL_NEXT

						MOV		DL,AL	; If RUN/SELECT is pressed, update DL.  (F**k chattering!)

READ_PADA_WAITREL_NEXT:
						CMP		AL,0FFH
						JNE		READ_PADA_WAITREL_WAIT

						MOV		AX,DX

READ_PADA_WAIT_RELEASE_NO_PAD_INPUT:
						POP		DX
						RET

READ_PADA_WAIT_RELEASE	ENDP


LAST_KEY_READ			DB		0

