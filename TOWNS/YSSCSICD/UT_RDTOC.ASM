;/* ////////////////////////////////////////////////////////////
;
;File Name: UT_RDTOC.ASM
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

; Unit test for CD-ROM BIOS Read TOC command

						.186

						ORG		0
						ASSUME	CS:DATA_CODE,DS:DATA_CODE,SS:STACK


DATA_CODE				SEGMENT

MAIN					PROC

						PUSH	ES
						PUSH	DS
						PUSHA

						PUSH	CS
						POP		DS
						PUSH	CS
						POP		ES


						LEA		DI,[TOC_BUFFER]
						MOV		CX,512
						MOV		AL,255
						REP		STOSB


						MOV		AH,054H
						MOV		AL,0C0H
						LEA		DI,[TOC_BUFFER]
						XOR		CX,CX
						CALL	PRINT_REGISTER
						CALL	PRINT_CRLF
						INT		93H
						CALL	PRINT_REGISTER
						CALL	PRINT_CRLF

						CMP		AH,0
						JNE		EXIT


						CALL	PRINT_CRLF
						MOV		CL,BYTE PTR [TOC_BUFFER+2]
						SUB		CL,BYTE PTR [TOC_BUFFER+1]
						ADD		CL,4  ; Must see FFFFFF in the end.
						LEA		DI,[TOC_BUFFER]
PRINT_LOOP:
						MOV		AL,[DI]
						CALL	PRINT_AL
						MOV		AL,[DI+1]
						CALL	PRINT_AL
						MOV		AL,[DI+2]
						CALL	PRINT_AL
						CALL	PRINT_CRLF

						LEA		DI,[DI+3]
						DEC		CL
						JNE		PRINT_LOOP


						POPA
						POP		DS
						POP		ES

EXIT:
						; Termination
						MOV	AH,4CH
						MOV	AL,00H
						INT	21H


MAIN					ENDP


						INCLUDE	PRINT.ASM


MSG_AH					DB		"AH=",0
MSG_CX					DB		"  CX=",0
TOC_BUFFER				DD		512 dup(0)


DATA_CODE				ENDS

STACK					SEGMENT	STACK

						DB	1024 DUP(0)

STACK					ENDS

						END		MAIN


