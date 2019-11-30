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




INT93_TOWNS				DD		0

INSTALL_HOOK			PROC
						PUSH	ES

						MOV		AX,3593H
						; AH=35H    Get IRQ vector
						; AL=93H    for INT 93H
						INT		21H

						MOV		WORD PTR [INT93_TOWNS],BX
						MOV		WORD PTR [INT93_TOWNS+2],ES

						PUSH	CS
						POP		ES
						MOV		DX,OFFSET INT93H_HOOKPROC

						MOV		AX,2593H
						; AH=25H    Set IRQ vector
						; AL=93H    for INT 93H
						INT		21H


						POP		ES
						RET
INSTALL_HOOK			ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INT93H_HOOKPROC			PROC
						CMP		AL,0C0H
						JE		INT93H_IS_CDROM_CALL

						JMP		CS:[INT93_TOWNS]

INT93H_IS_CDROM_CALL:
						TEST	BYTE PTR CS:[YSSCSICD_FLAGS],YSSCSICD_FLAGS_DEBUG_RS232C
						JE		@f
						CALL	RS232C_INIT
@@:


						PUSH	ES
						PUSH	DS

						PUSH	DS
						POP		ES

						PUSH	CS
						POP		DS

						TEST	BYTE PTR CS:[YSSCSICD_FLAGS],YSSCSICD_FLAGS_DEBUG_CONSOLE
						JE		@f
						PUSHA
						CALL	PRINT_REGISTER
						CALL	PRINT_CRLF
						POPA
@@:

						TEST	BYTE PTR CS:[YSSCSICD_FLAGS],YSSCSICD_FLAGS_DEBUG_RS232C
						JE		@f
						PUSHA
						CALL	RS232C_REGISTER
						CALL	RS232C_CRLF
						POPA
@@:

						MOV		BYTE PTR CS:[DEBUG_REDIR_SUBSTEP],':'

						POP		DS
						POP		ES



						TEST	BYTE PTR CS:[YSSCSICD_SCSI_ID],0F8H
						JE		@f	; Jump if redirect.
						JMP		CS:[INT93_TOWNS]
@@:
						CALL	REDIRECT_CDROM_BIOSCALL


						TEST	BYTE PTR CS:[YSSCSICD_FLAGS],YSSCSICD_FLAGS_DEBUG_RS232C
						JE		@f
						PUSHA
						PUSH	AX
						MOV		AL,'R'
						CALL	RS232C_PUTC
						MOV		AL,CS:[DEBUG_REDIR_SUBSTEP]
						CALL	RS232C_PUTC
						POP		AX
						CALL	RS232C_AH_CX
						CALL	RS232C_CRLF
						CALL	BUSY_WAIT_65536
						CALL	RS232C_WAIT_TX_READY
						POPA
@@:

						IRET

INT93H_HOOKPROC			ENDP


BUSY_WAIT_65536			PROC
						PUSH	CX
						MOV		CX,65535

BUSY_WAIT_65536_LOOP:	LOOP	BUSY_WAIT_65536_LOOP

						POP		CX
						RET
BUSY_WAIT_65536			ENDP
