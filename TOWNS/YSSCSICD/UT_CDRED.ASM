;/* ////////////////////////////////////////////////////////////
;
;File Name: UT_CDRED.ASM
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

; During DIR
;   AX=05C0 BX=0001 CX=0000 DX=0016 SI=2E3D DI=0006
;
; Read 1 sector from HSG=000016

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


						MOV		AH,05H	; By HSG
						MOV		AL,0C0H
						MOV		BX,2
						MOV		CX,0
						MOV		DX,000H
						LEA		DI,[READ_BUF1]
						INT		93H

						CALL	PRINT_AH_CX
						CALL	PRINT_CRLF

						MOV		DX,0
						MOV		AX,000H
						CALL	HSG2MSF
						MOV		CX,DX
						MOV		DX,AX

						PUSH	DX
						PUSH	CX
						MOV		AX,CX
						CALL	PRINT_AX
						MOV		AX,DX
						CALL	PRINT_AX
						CALL	PRINT_CRLF
						POP		CX
						POP		DX


						; CDISC2.SYS CDBIOS.ASM  CDReadMSF -> MSF bit is CMD[13=(BlkAdrs-7)] of DosCDRead ->
						; -> CDSD.SYS READ.ASM Read -> Referred to by SetParm (mov	al,es:[di.AdrMode])
						; It is just converting MSF2HSG

						MOV		AH,15H	; By MSF
						MOV		AL,0C0H
						MOV		BX,2
						LEA		DI,[READ_BUF2]
						INT		93H

						CALL	PRINT_AH_CX
						CALL	PRINT_CRLF


						XOR		CH,CH
						MOV		DX,512
						LEA		DI,[READ_BUF1]
PRINT_LOOP:
						MOV		CL,16

PRINT_INNER_LOOP:
						MOV		AL,[DI]
						LEA		DI,[DI+1]
						CALL	PRINT_AL
						MOV		AL,' '
						CALL	PUTC
						DEC		CL
						JNE		PRINT_INNER_LOOP

						CALL	PRINT_CRLF

						DEC		CH
						JNE		@f
						CALL	PRINT_CRLF
@@:

						DEC		DX
						JNE		PRINT_LOOP



						MOV		CX,4096
						LEA		SI,[READ_BUF1]
						LEA		DI,[READ_BUF2]
COMPARE_LOOP:
						MOV		AL,[SI]
						CMP		AL,[DI]
						JNE		MISMATCH
						LEA		SI,[SI+1]
						LEA		DI,[DI+1]
						DEC		CX			; Does LOOP instruction do the same?
						JNE		COMPARE_LOOP
						JMP		MATCH

MISMATCH:
						NEG		CX
						ADD		CX,4096
						MOV		AX,CX
						CALL	PRINT_AX
						CALL	PRINT_CRLF
						LEA		DI,[MSG_MISMATCH]
						CALL	PRINT_CSTR

MATCH:



						POPA
						POP		DS
						POP		ES

EXIT:
						; Termination
						MOV	AH,4CH
						MOV	AL,00H
						INT	21H


MAIN					ENDP


; HSG=60*MIN+75*SEC+FRM  ->  60 seconds/min,   75 frames/sec   -> 60*75 frames/min
; Input:
;	DX:AX	HSG
; Output:
;	DL		MIN
;	AH		SEC
;	AL		FRM
HSG2MSF					PROC
						PUSH	CX

						MOV		CX,60*75
						DIV		CX
						; AX minutes, DX sub-minute

						XOR		AH,AH
						PUSH	AX		; MIN in stack

						MOV		AX,DX
						XOR		DX,DX
						MOV		CX,75
						DIV		CX
						; AL seconds, DL frames

						MOV		AH,AL
						MOV		AL,DL

						POP		DX
						POP		CX
						RET
HSG2MSF					ENDP


						INCLUDE	PRINT.ASM


MSG_MISMATCH			DB		"MSF read and HSG read does not match!",0DH,0AH,0

READ_BUF1				DB		4096 dup(0)
READ_BUF2				DB		4096 dup(255)


DATA_CODE				ENDS

STACK					SEGMENT	STACK

						DB	1024 DUP(0)

STACK					ENDS

						END		MAIN


