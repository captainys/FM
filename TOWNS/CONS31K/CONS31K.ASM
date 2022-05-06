						.386p

						ASSUME	CS:CODE,DS:CODE
CODE					SEGMENT	USE16

						ORG		0100H

MAIN					PROC

						MOV		AX,CS
						MOV		SS,AX	; This should mask IRQ for the next instruction.
						MOV		SP,OFFSET STK_END

						MOV		DS,AX
						MOV		SI,OFFSET CRTC_REG_00_01

						; Input DS:SI Register/Sifter table.
						CALL	CRTC_SETREG

						MOV		AH,4CH
						INT		21H

MAIN					ENDP

						INCLUDE	CRTCCONS.ASM
						INCLUDE	CRTC.ASM

						DB		64 dup(0)
STK_END:

CODE					ENDS
						END		MAIN
