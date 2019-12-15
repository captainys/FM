; https://stackoverflow.com/questions/52859172/how-to-read-command-line-arguments-in-assembly-language
; DS:[DX] points to the command line ending with 0DH?

						.186

						ORG		0
						ASSUME	CS:CODE_DATA,DS:CODE_DATA


CODE_DATA				SEGMENT


MAIN					PROC


						MOV		AX,CS
						MOV		DS,AX


						MOV		DX,OFFSET FILENAME
						MOV		AH,3CH
						XOR		CX,CX ; Normal file
						INT		21H
						JNC		@f
						JMP		EXIT
@@:


						; Open File
						MOV		DX,OFFSET FILENAME
						MOV		AH,3DH
						MOV		AL,1	; Write mode
						INT		21H
						JNC		@f
						JMP		EXIT
@@:
						MOV		CS:[FP],AX
						CALL	DUMP_LOW_1MB

						MOV		AH,3EH
						MOV		BX,CS:[FP]
						INT		21H


						; EXIT
EXIT:
						MOV		AX,4C00H
						INT		21H

MAIN					ENDP


FILENAME				DB	"TESTFILE.BIN",0
FP						DW	0




;   BX  File Handle
DUMP_LOW_1MB			PROC
						MOV		BX,CS:[FP]
						MOV		DX,0000H
						CALL	WRITE_FILE_64K
						MOV		DX,1000H
						CALL	WRITE_FILE_64K
						MOV		DX,2000H
						CALL	WRITE_FILE_64K
						MOV		DX,3000H
						CALL	WRITE_FILE_64K
						MOV		DX,4000H
						CALL	WRITE_FILE_64K
						MOV		DX,5000H
						CALL	WRITE_FILE_64K
						MOV		DX,6000H
						CALL	WRITE_FILE_64K
						MOV		DX,7000H
						CALL	WRITE_FILE_64K
						MOV		DX,8000H
						CALL	WRITE_FILE_64K
						MOV		DX,9000H
						CALL	WRITE_FILE_64K
						MOV		DX,0A000H
						CALL	WRITE_FILE_64K
						MOV		DX,0B000H
						CALL	WRITE_FILE_64K
						MOV		DX,0F000H		; C0000-CFFFF are VRAM and Memory Mapped I/O.  Fill with F0000H-FFFFFH
						CALL	WRITE_FILE_64K
						MOV		DX,0D000H
						CALL	WRITE_FILE_64K
						MOV		DX,0E000H
						CALL	WRITE_FILE_64K
						MOV		DX,0F000H
						CALL	WRITE_FILE_64K

						RET

DUMP_LOW_1MB			ENDP


; Input
;   DX  Data Segment for 64K
;   BX  File Handle
WRITE_FILE_64K			PROC
						PUSHA

						MOV		DS,DX

						MOV		DX,0
						MOV		CX,4000H
						MOV		AH,40H
						INT		21H

						MOV		DX,4000H
						MOV		CX,4000H
						MOV		AH,40H
						INT		21H

						MOV		DX,8000H
						MOV		CX,4000H
						MOV		AH,40H
						INT		21H

						MOV		DX,0C000H
						MOV		CX,4000H
						MOV		AH,40H
						INT		21H

						POPA
						RET
WRITE_FILE_64K			ENDP


CODE_DATA				ENDS


STACK		SEGMENT	STACK

		DB	1024 DUP(0)

STACK		ENDS



						END		MAIN
