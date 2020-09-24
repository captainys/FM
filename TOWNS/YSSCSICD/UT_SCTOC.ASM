;/* ////////////////////////////////////////////////////////////
;
;File Name: UT_SCTOC.ASM
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

						.386p

						ORG		0
						ASSUME	CS:DATA_CODE,DS:DATA_CODE,SS:STACK


DATA_CODE				SEGMENT	USE16

MAIN					PROC

						PUSH	ES
						PUSH	DS
						PUSHA

						PUSH	CS
						POP		DS
						PUSH	CS
						POP		ES


						CALL	SCAN_SCSI_CDROM
						TEST	AL,0F8H
						JE		@f
						JMP		EXIT

@@:
						MOV		[YSSCSICD_SCSI_ID],AL

						LEA		DI,[TOC_BUFFER]

						PUSH	ES
						PUSH	DS
						PUSH	DI
						PUSH	SI
						PUSH	BP
						PUSH	DX
						PUSH	CX
						PUSH	BX
						PUSH	AX
						CLC
						PUSHF
						MOV		BP,SP

						CALL	CDROM_BIOS_054H_GET_DISC_INFO_TOC
						OR		AH,CH
						JE		@f
						JMP		EXIT
@@:

						POPF
						POP		AX
						POP		BX
						POP		CX
						POP		DX
						POP		BP
						POP		SI
						POP		DI
						POP		DS
						POP		ES

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

						CMP		AH,0
						JNE		EXIT


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
						INCLUDE	RS232C.ASM
						INCLUDE	HOOKBIOS.ASM
						INCLUDE	REDRFUNC.ASM
						INCLUDE SCSIUTIL.ASM
						INCLUDE YS_EXT.ASM
						INCLUDE	FMR_SCSI.ASM
						INCLUDE	DATABUF.ASM


MSG_AH					DB		"AH=",0
MSG_CX					DB		"  CX=",0
TOC_BUFFER				DD		512 dup(0)


DATA_CODE				ENDS

						INCLUDE WRHIGH.ASM

STACK					SEGMENT	STACK

						DB	1024 DUP(0)

STACK					ENDS

						END		MAIN


