;/* ////////////////////////////////////////////////////////////
;
;File Name: UT_SCSUB.ASM
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

; Unit test for CD-ROM BIOS Read Sub Channel command

; Second byte is supposed to be Play State
; PLAYING  11H
; PAUSED   12H
; However, I have a suspicion that it is 11H even when it is paused.

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
						CALL	SCSI_TEST_UNIT_READY
						CALL	PRINT_AX_CH
						CALL	IS_SCSI_ERROR
						CALL	PRINT_AH_CX


						CALL	PRINT_CRLF

						MOV		CH,2
						LEA		DI,[SCSI_DATA_BUF]
PRINT_OUTER_LOOP:

						MOV		CL,16

PRINT_INNER_LOOP:
						MOV		AL,[DI]
						CALL	PRINT_AL
						MOV		AL,' '
						CALL	PUTC

						LEA		DI,[DI+1]

						DEC		CL
						JNE		PRINT_INNER_LOOP

						CALL	PRINT_CRLF
						DEC		CH
						JNE		PRINT_OUTER_LOOP



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


DATA_CODE				ENDS

						INCLUDE WRHIGH.ASM

STACK					SEGMENT	STACK

						DB	1024 DUP(0)

STACK					ENDS

						END		MAIN


