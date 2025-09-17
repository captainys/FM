						.386p
						ASSUME	CS:CODE,DS:CODE


CODE					SEGMENT		USE16

MAIN					PROC

						MOV			AL,1	; 0:Open Lid  1:Close Lid
						JMP			REALMAIN

MAIN					ENDP

CODE					ENDS

						INCLUDE SCSIOPCL.ASM

						END		MAIN
