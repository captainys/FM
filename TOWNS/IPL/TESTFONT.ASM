						ASSUME	CS:CODE,DS:CODE,SS:STACK



						.386p
CODE					SEGMENT	USE16

						INCLUDE		IODEF.ASM

MAIN					PROC

						MOV		DX,CS
						MOV		DS,DX

						MOV		DX,IO_VMIF_CMD_STATUS
						MOV		AL,VMIF_CMD_PAUSE
						OUT		DX,AL

						CALL	VRAMMODE

						CALL	CLS

						MOV		DI,80*16
						MOV		AH,0
						MOV		AL,80

@@:
						PUSH	DI
						PUSH	AX
						CALL	DRAWFONT_TALL
						POP		AX
						POP		DI

						INC		DI
						INC		AH
						JE		@f

						DEC		AL
						JNE		@b

						MOV		AL,80
						ADD		DI,80*15
						JMP		@b

@@:

						MOV		AX,0510H
						CALL	LOCATE
						MOV		SI,OFFSET MESSAGE
						CALL	PRINT_TALL


						CALL	RAMMODE

						MOV		AH,4CH
						INT		21H

MAIN					ENDP

						INCLUDE		DRAWFONT.ASM
						INCLUDE		MEMBANK.ASM

MESSAGE					DB	"FONT-DRAWING TEST",0

CODE					ENDS





STACK					SEGMENT	STACK
						DB		1024 dup(0)
STACK					ENDS


						END		MAIN
