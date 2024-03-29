;/* ////////////////////////////////////////////////////////////
;
;File Name: PRINT.ASM
;Copyright (c) 2019 Soji Yamakawa.  All rights reserved.
;http://www.ysflight.com
;
;Redistribution and use in source and binary forms, with or without modification, 
;are permitted provided that the following conditions are met:
;
;1. Redistributions of source code must retain the above copyright notice, 
;   this list of conditions and the following disclaimer.
;
;2. Redistributions in binary form must reproduce the above copyright notice, 
;   this list of conditions and the following disclaimer in the documentation 
;   and/or other materials provided with the distribution.
;
;THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
;AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
;THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
;PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS 
;BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
;CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE 
;GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
;HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
;LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
;OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;
;//////////////////////////////////////////////////////////// */


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MSG_REG_AX				DB		"AX=",0
MSG_REG_BX				DB		" BX=",0
MSG_REG_CX				DB		" CX=",0
MSG_REG_DX				DB		" DX=",0
MSG_REG_SI				DB		" SI=",0
MSG_REG_DI				DB		" DI=",0
MSG_REG_CS				DB		" CS=",0
MSG_REG_DS				DB		" DS=",0
MSG_REG_ES				DB		" ES=",0,0


PRINT_REGISTER			PROC

						PUSHA

						PUSH	ES
						PUSH	DS
						PUSH	CS
						PUSH	DI
						PUSH	SI
						PUSH	DX
						PUSH	CX
						PUSH	BX
						PUSH	AX

						MOV		DI,OFFSET MSG_REG_AX

PRINT_REGISTER_OUTER_LOOP:
						POP		AX
						PUSH	DI
						CALL	PRINT_CSTR
						CALL	PRINT_AX
						POP		DI

PRINT_REGISTER_INNER_LOOP:
						INC		DI
						CMP		BYTE PTR CS:[DI],0
						JNE		PRINT_REGISTER_INNER_LOOP
						INC		DI

						CMP		BYTE PTR CS:[DI],0
						JNE		PRINT_REGISTER_OUTER_LOOP

						MOV		AL,'$'
						CALL	PUTC

						POPA

						RET

PRINT_REGISTER			ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PRINT_AL				PROC
						PUSH	CX
						PUSH	AX

						CALL	ITOA8
						XCHG	AL,AH
						CALL	PUTC
						XCHG	AL,AH
						CALL	PUTC

						POP		AX
						POP		CX
						RET
PRINT_AL				ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PRINT_AX				PROC
						XCHG	AL,AH
						CALL	PRINT_AL
						XCHG	AL,AH
						CALL	PRINT_AL
						RET
PRINT_AX				ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PRINT_AH_CX				PROC

						; CD-ROM BIOS Error Code
						PUSH	CX
						PUSH	AX
						PUSH	BP

						MOV		BP,SP
						MOV		AL,BYTE PTR [BP+3]
						CALL	PRINT_AL

						MOV		AL,' '
						CALL	PUTC

						MOV		AL,BYTE PTR [BP+5]
						CALL	PRINT_AL
						MOV		AL,BYTE PTR [BP+4]
						CALL	PRINT_AL

						MOV		AL,' '
						CALL	PUTC

						POP		BP
						POP		AX
						POP		CX

						RET

PRINT_AH_CX				ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PRINT_CRLF				PROC
						PUSH	AX
						MOV		AL,0DH
						CALL	PUTC
						MOV		AL,0AH
						CALL	PUTC
						POP		AX
						RET
PRINT_CRLF				ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PRINT_CSTR				PROC
						PUSH	DX
						PUSH	CX
						PUSH	AX
@@:
						MOV		DL,CS:[DI]
						CMP		DL,0
						JE		PRINT_CSTR_EXIT
						MOV		AH,06H
						INT		21H
						INC		DI
						JMP		@b

PRINT_CSTR_EXIT:
						POP		AX
						POP		CX
						POP		DX
						RET

PRINT_CSTR				ENDP

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

; Input
;	AL		Number
; Output
;	AH		Higher digit ASCII code
;	AL		Lower digit ASCII code
ITOA8					PROC

						MOV		AH,AL
						AND		AL,0FH
						SHR		AH,1
						SHR		AH,1
						SHR		AH,1
						SHR		AH,1

						ADD		AL,'0'
						CMP		AL,'9'
						JLE		@f
						ADD		AL,'A'-'0'-10
@@:
						ADD		AH,'0'
						CMP		AH,'9'
						JLE		@f
						ADD		AH,'A'-'0'-10
@@:
						RET

ITOA8					ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


