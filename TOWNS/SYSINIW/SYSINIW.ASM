						.186

						ORG		0
						ASSUME	CS:CODE_DATA,DS:CODE_DATA


CODE_DATA				SEGMENT


MAIN					PROC

						MOV		AL,'R'
						MOV		DX,3A34H
						OUT		DX,AL

						MOV		AL,'A'
						MOV		DX,3A36H
						OUT		DX,AL

						; EXIT
						MOV		AX,4C00H
						INT		21H

MAIN					ENDP



PUTC					PROC

						PUSH	AX
						PUSH	DX

						MOV		DL,AL
						MOV		AH,06H
						INT		21H

						POP		DX
						POP		AX

						RET

PUTC					ENDP



CODE_DATA				ENDS


STACK		SEGMENT	STACK

		DB	1024 DUP(0)

STACK		ENDS



						END		MAIN
