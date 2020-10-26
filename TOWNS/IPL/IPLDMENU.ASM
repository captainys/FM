; Question:
;   So, does SYSROM tweaks some bytes in the IPL sector after reading it to B000:0000 block?
IPLDEBUG				PROC

						CALL	CLEAR_FIVE_BELOW
						CALL	MENU_WAIT_PAD_RELEASE

						MOV		AX,0B000H
						MOV		FS,AX
						MOV		AX,0507H
						MOV		SI,0000H

@@:
						PUSH	AX
						PUSH	SI
						CALL	LOCATE

						MOV		AL,FS:[SI]
						CALL	ITOX8

						PUSH	AX
						PUSH	DI
						CALL	DRAWFONT_TALL
						POP		DI
						ADD		DI,1
						POP		AX
						XCHG	AH,AL
						CALL	DRAWFONT_TALL

						POP		SI
						POP		AX

						ADD		AH,3
						ADD		SI,1
						TEST	SI,000FH
						JNE		@b

						INC		AL
						MOV		AH,5
						CMP		SI,0100H
						JB		@b

						CALL	MENU_WAIT_PAD_PRESS

						RET

IPLDEBUG				ENDP
