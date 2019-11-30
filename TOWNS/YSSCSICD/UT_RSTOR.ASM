;/* ////////////////////////////////////////////////////////////
;
;File Name: UT_RSTOR.ASM
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

; Unit test for CD-ROM BIOS CD STOP command

						.186

						ORG		0
						ASSUME	CS:DATA_CODE,DS:DATA_CODE,SS:STACK


DATA_CODE				SEGMENT

MAIN					PROC

						PUSH	CS
						POP		DS
						PUSH	CS
						POP		ES

						MOV		AH,003H
						MOV		AL,0C0H
						XOR		CX,CX
						INT		93H

						PUSH	AX
						LEA		DI,[MSG_AH]
						CALL	PRINT_CSTR
						MOV		AL,AH
						CALL	PRINT_AL

						LEA		DI,[MSG_CX]
						CALL	PRINT_CSTR
						MOV		AX,CX
						CALL	PRINT_AX
						POP		AX

						; Termination
						MOV	AH,4CH
						MOV	AL,00H
						INT	21H


MAIN					ENDP


						INCLUDE	PRINT.ASM


MSG_AH					DB		"AH=",0
MSG_CX					DB		"  CX=",0

PLAYCMD_BUFFER			DB		6 dup(0)


DATA_CODE				ENDS

STACK					SEGMENT	STACK

						DB	1024 DUP(0)

STACK					ENDS

						END		MAIN


