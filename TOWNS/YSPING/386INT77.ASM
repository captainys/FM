						.386p

						ASSUME	CS:CODE

CODE					SEGMENT

MAIN					PROC
						INT 77H

						; Termination
						MOV		AH,4CH
						MOV		AL,00H
						INT		21H

MAIN					ENDP

CODE					ENDS
						END		MAIN


