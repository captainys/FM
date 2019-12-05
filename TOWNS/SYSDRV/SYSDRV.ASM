						.186

						ORG		0
						ASSUME	CS:CODE_DATA,DS:CODE_DATA

; Usage:
;   SYSDRV.EXE
;     Makes Q drive (CD-ROM Drive) as the system drive.
;   SYSDRV.EXE /D:E
;     Makes E drive as the system drive.
;
; It must be used before CONTROL.EXE.
; CONTROL.EXE does have /D option to specify the system drive, but earlier programs may need a system drive.
; This program can be used for that purpose.

CODE_DATA				SEGMENT


MAIN					PROC

						MOV		AX,DS
						MOV		ES,AX
						MOV		DI,081H

						MOV		AX,CODE_DATA
						MOV		DS,AX



CMD_ARG_LOOP:
						MOV		AL,ES:[DI]
						CMP		AL,0
						JE		CMD_ARG_EXIT
						CMP		AL,0DH
						JE		CMD_ARG_EXIT
						CMP		AL,0AH

						CMP		AL,'/'
						JNE		CMD_ARG_NEXT

						CMP		BYTE PTR ES:[DI+1],'D'
						JE		@f
						CMP		BYTE PTR ES:[DI+1],'d'
						JNE		CMD_ARG_NEXT
@@:

						CMP		BYTE PTR ES:[DI+2],':'
						JNE		CMD_ARG_NEXT

						MOV		AL,ES:[DI+3]
						MOV		CS:[SYSDRV_LETTER],AL

CMD_ARG_NEXT:
						LEA		DI,[DI+1]
						JMP		CMD_ARG_LOOP

CMD_ARG_EXIT:


						; Small letter?
						MOV		AL,CS:[SYSDRV_LETTER]
						CMP		AL,'a'
						JB		@f
						CMP		AL,'z'
						JA		@f
						; Need capitalize
						ADD		AL,'A'-'a'
						MOV		CS:[SYSDRV_LETTER],AL
@@:


						CMP		BYTE PTR CS:[SYSDRV_LETTER],'A'
						JB		ILLEGAL_DRIVE_LETTER
						CMP		BYTE PTR CS:[SYSDRV_LETTER],'Z'
						JA		ILLEGAL_DRIVE_LETTER


						LEA		DI,[MESSAGE]
						CALL	PRINT_CSTR

						MOV		BL,CS:[SYSDRV_LETTER]
						SUB		BL,'A'
						AND		BL,1FH
						SHL		BL,2

						MOV		DX,3C32H
						IN		AL,DX

						AND		AL,083H
						OR		AL,BL

						OUT		DX,AL


						; Change DOS default drive.
						MOV		DL,CS:[SYSDRV_LETTER]
						SUB		DL,'A'
						MOV		AH,0EH
						INT		21H


						JMP		@f

ILLEGAL_DRIVE_LETTER:
						LEA		DI,[MESSAGE_ERROR]
						CALL	PRINT_CSTR

@@:
						; EXIT
						MOV		AX,4C00H
						INT		21H

MAIN					ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PRINT_CSTR				PROC
						PUSH	DX
						PUSH	CX
						PUSH	AX
@@:
						MOV		DL,DS:[DI]
						CMP		DL,0
						JE		PRINT_CSTR_EXIT
						MOV		AH,06H
						INT		21H
						LEA		DI,[DI+1]
						JMP		@b

PRINT_CSTR_EXIT:
						POP		AX
						POP		CX
						POP		DX
						RET

PRINT_CSTR				ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MESSAGE					DB		"SET SYSTEM DRIVE TO ["
SYSDRV_LETTER			DB		'Q'
						DB		']',0DH,0AH,0

MESSAGE_ERROR			DB		"UNACCEPTABLE DRIVE LETTER"

CODE_DATA				ENDS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

STACK		SEGMENT	STACK

		DB	1024 DUP(0)

STACK		ENDS



						END		MAIN
