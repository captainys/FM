						ASSUME	CS:CODE

						.186
CODE					SEGMENT

PATCH					PROC

						ORG		0281H
L10281H:	

						ORG		02EEH
L102EEH:
                        INT		93H
						MOV		WORD PTR DS:[7EE5H],0
						CMP		AH,80H
						MOV		DS:[BP+3],AH
						JNE		NOT_HARD_ERR
						MOV		DS:[BP+6],CX
NOT_HARD_ERR:
						JMP		L10281H

PATCH					ENDP

CODE					ENDS

						END
