;/* ////////////////////////////////////////////////////////////
;
;File Name: UT_CDPLY.ASM
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

; Unit test for CD-ROM BIOS CD PLAY command

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


						MOV		AH,054H
						MOV		AL,0C0H
						LEA		DI,[TOC_BUFFER]
						XOR		CX,CX
						INT		93H

						CALL	PRINT_AH_CX

						CMP		AH,0
						JE		@f
						JMP		EXIT
@@:

						CALL	PRINT_CRLF
						MOV		CL,BYTE PTR [TOC_BUFFER+2]
						SUB		CL,BYTE PTR [TOC_BUFFER+1]
						ADD		CL,2
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


						LEA		DI,[MSG_TOC_DONE]
						CALL	PRINT_CSTR


						MOV		CL,BYTE PTR [TOC_BUFFER+2]
						SUB		CL,BYTE PTR [TOC_BUFFER+1]
						INC		CL
						LEA		DI,[TOC_BUFFER+6]

FIND_AUDIO_LOOP:
						MOV		AL,[DI]
						CALL	PRINT_AL
						CALL	PRINT_CRLF

						MOV		AL,[DI]
						TEST	AL,80H
						JE		FOUND_AUDIO

						LEA		DI,[DI+3]
						DEC		CL
						CMP		CL,0FFH
						JNE		FIND_AUDIO_LOOP

						LEA		DI,[MSG_NOT_FOUND]
						CALL	PRINT_CSTR
						JMP		EXIT


FOUND_AUDIO:
						MOV		AL,CL
						CALL	PRINT_AL

						PUSH	DI
						LEA		DI,[MSG_FOUND]
						CALL	PRINT_CSTR
						POP		DI

						MOV		AX,WORD PTR [DI]
						MOV		WORD PTR [PLAYCMD_BUFFER],AX
						MOV		AL,BYTE PTR [DI+2]
						MOV		BYTE PTR [PLAYCMD_BUFFER+2],AL

						MOV		DL,BYTE PTR [TOC_BUFFER+3]
						MOV		AH,BYTE PTR [TOC_BUFFER+4]
						MOV		AL,BYTE PTR [TOC_BUFFER+5]

						SUB		AH,2
						JNC		@f
						ADD		AH,60
						DEC		DL
@@:
						MOV		BYTE PTR [PLAYCMD_BUFFER+3],DL
						MOV		WORD PTR [PLAYCMD_BUFFER+4],AX


						MOV		AL,[PLAYCMD_BUFFER]
						CALL	PRINT_AL
						MOV		AL,[PLAYCMD_BUFFER+1]
						CALL	PRINT_AL
						MOV		AL,[PLAYCMD_BUFFER+2]
						CALL	PRINT_AL
						MOV		AL,[PLAYCMD_BUFFER+3]
						CALL	PRINT_AL
						MOV		AL,[PLAYCMD_BUFFER+4]
						CALL	PRINT_AL
						MOV		AL,[PLAYCMD_BUFFER+5]
						CALL	PRINT_AL
						CALL	PRINT_CRLF

						MOV		AH,50H
						MOV		AL,0C0H
						MOV		CH,0
						MOV		CL,1
						LEA		DI,[PLAYCMD_BUFFER]
						INT		93H

						CALL	PRINT_AH_CX


EXIT:
						POPA
						POP		DS
						POP		ES

						; Termination
						MOV	AH,4CH
						MOV	AL,00H
						INT	21H


MAIN					ENDP



						INCLUDE	PRINT.ASM

PLAYCMD_BUFFER			DB		6 dup(0)

MSG_AH					DB		"AH=",0
MSG_CX					DB		"  CX=",0
MSG_TOC_DONE			DB		"TOC",0dH,0aH,0
MSG_NOT_FOUND			DB		"Audio Track Not Found",0dH,0aH,0
MSG_FOUND				DB		"Found audio Track",0dH,0aH,0
TOC_BUFFER				DD		512 dup(0)



DATA_CODE				ENDS

STACK					SEGMENT	STACK

						DB	1024 DUP(0)

STACK					ENDS

						END		MAIN


