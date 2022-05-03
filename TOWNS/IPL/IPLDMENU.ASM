; Question:
;   So, does SYSROM tweaks some bytes in the IPL sector after reading it to B000:0000 block?
IPLDEBUG_BUF			DB		0,0,0

IPLDEBUG				PROC

						CALL	CLS_5BELOW_HIGH
						CALL	MENU_WAIT_PAD_RELEASE

						MOV		AX,0B000H
						MOV		FS,AX
						MOV		AX,0507H
						MOV		SI,0000H

@@:
						PUSH	AX
						PUSH	SI
						CALL	LOCATE31K

						MOV		AL,FS:[SI]
						CALL	ITOX8

						MOV		SI,OFFSET IPLDEBUG_BUF
						XCHG	AL,AH
						MOV		CS:[SI],AX
						CALL	WRSTRING_WHITE_HIGH

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
