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

						OUT		IO_WAIT_1MICROSEC,AL	; Hope this make it better.  TBIOS does wait for 1us after writing PAD OUT.

						MOV		DX,IO_PADA_IN
						IN		AL,DX
						AND		AL,3FH
						CMP		AL,3FH
						JE		READ_PADA_ANTI_CHATTER_DONE

						; If, any button is pressed, wait for 10ms and then read again to prevent chattering.
						MOV		DX,10000
READ_PADA_ANTI_CHATTER:	OUT		IO_WAIT_1MICROSEC,AL
						DEC		DX
						JNE		READ_PADA_ANTI_CHATTER

						MOV		DX,IO_PADA_IN
						IN		AL,DX

READ_PADA_ANTI_CHATTER_DONE:
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

LAST_KEY_READ			DB		0





HID_WAIT_VSYNC_CLEAR		PROC
							PUSH	DX
							PUSH	AX

							MOV		DX,IO_VSYNC
HID_WAIT_VSYNC_CLEAR_LOOP:	IN		AL,DX
							AND		AL,1
							JNE		HID_WAIT_VSYNC_CLEAR_LOOP

							POP		AX
							POP		DX
							RET
HID_WAIT_VSYNC_CLEAR		ENDP





HID_WAIT_VSYNC_SET			PROC
							PUSH	DX
							PUSH	AX

							MOV		DX,IO_VSYNC
HID_WAIT_VSYNC_SET_LOOP:	IN		AL,DX
							AND		AL,1
							JE		HID_WAIT_VSYNC_SET_LOOP

							POP		AX
							POP		DX
							RET
HID_WAIT_VSYNC_SET			ENDP





HID_WAIT_CX_VSYNC_CYCLES	PROC
							CALL	HID_WAIT_VSYNC_CLEAR
HID_WAIT_VSYNC_CYCLES_LOOP:	CALL	HID_WAIT_VSYNC_SET
							CALL	HID_WAIT_VSYNC_CLEAR
							LOOP	HID_WAIT_VSYNC_CYCLES_LOOP
							RET
HID_WAIT_CX_VSYNC_CYCLES	ENDP
