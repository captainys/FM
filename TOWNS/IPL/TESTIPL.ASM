						ASSUME	CS:CODE,DS:CODE


						.386p
CODE					SEGMENT	USE16

						INCLUDE		IODEF.ASM

MAIN					PROC

						DB			"IPL4"

						CLI
						PUSH		CS
						POP			DS

						CALL		INITGRAPHICS
						CALL		VRAMMODE
						CALL		CLS

						MOV			BX,0
						MOV			AX,0505H
@@:
						PUSH		BX
						PUSH		AX
						XCHG		BX,AX
						CALL		COLOR
						XCHG		BX,AX
						CALL		LOCATE
						MOV			SI,OFFSET MESSAGE
						CALL		PRINT_TALL

						POP			AX
						POP			BX
						INC			AL
						INC			BX
						CMP			BX,16
						JNE			@b

@@:
						JMP			@b

MAIN					ENDP

						INCLUDE		DRAWFONT.ASM
						INCLUDE		MEMBANK.ASM

MESSAGE					DB	"TEST IPL",0

						DB	1024 dup (0) ; Padding


CODE					ENDS

						END		MAIN
