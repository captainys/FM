;/* ////////////////////////////////////////////////////////////
;
;File Name: HOOKBIOS.ASM
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


IRQ_NUMBER				EQU		77H

INT77_TOWNS				DD		0
MSG_PING				DB		"YSPING",0DH,0AH,0

INSTALL_IRQ				PROC
						PUSH	ES

						MOV		AH,35H
						MOV		AL,IRQ_NUMBER
						; AH=35H    Get IRQ vector
						; AL=xxH    for INT xxH
						INT		21H

						MOV		WORD PTR CS:[INT77_TOWNS],BX
						MOV		WORD PTR CS:[INT77_TOWNS+2],ES

						PUSH	CS
						POP		ES
						MOV		DX,OFFSET INT77H_HOOKPROC

						MOV		AH,25H
						MOV		AL,IRQ_NUMBER
						; AH=25H    Set IRQ vector
						; AL=xxH    for INT xxH
						INT		21H

						POP		ES
						RET
INSTALL_IRQ				ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INT77H_HOOKPROC			PROC

						PUSH	ES
						PUSH	DS
						PUSHA

						PUSH	AX
						MOV		AH,CS:[YSPING_FLAGS]
						TEST	AH,YSPING_FLAGS_CONSOLE
						POP		AX
						JE		@f

						PUSH	DI
						LEA		DI,[MSG_PING]
						CALL	PRINT_CSTR
						POP		DI

						CALL	PRINT_REGISTER
						CALL	PRINT_CRLF
@@:


						PUSH	AX
						MOV		AH,CS:[YSPING_FLAGS]
						TEST	AH,YSPING_FLAGS_RS232C
						POP		AX
						JE		@f

						CALL	RS232C_INIT

						PUSH	DI
						LEA		DI,[MSG_PING]
						CALL	RS232C_CSTR
						POP		DI

						CALL	RS232C_REGISTER
						CALL	RS232C_CRLF

						CALL	BUSY_WAIT_65536
						CALL	RS232C_WAIT_TX_READY
@@:


						POPA
						POP		DS
						POP		ES

						IRET

INT77H_HOOKPROC			ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BUSY_WAIT_65536			PROC
						PUSH	CX
						MOV		CX,65535

BUSY_WAIT_65536_LOOP:	LOOP	BUSY_WAIT_65536_LOOP

						POP		CX
						RET
BUSY_WAIT_65536			ENDP
