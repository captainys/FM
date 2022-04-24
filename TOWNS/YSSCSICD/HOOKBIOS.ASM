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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INT93H_HOOKPROC			PROC
						CMP		AX,71C0H
						JE		YS_EXT_PLAY_CDDA

						CMP		AX,72C0H
						JE		YS_EXT_PLAY_CDDA_BCD

						CMP		AX,73C0H
						JE		SHORT INT93H_GET_SCSI_CD_ID

						CMP		AL,0C0H
						JE		SHORT INT93H_IS_CDROM_CALL

						JMP		CS:[INT93_TOWNS]

INT93H_GET_SCSI_CD_ID:
						MOV		AL,CS:[YSSCSICD_SCSI_ID]
						IRET


INT93H_IS_CDROM_CALL:
						TEST	BYTE PTR CS:[YSSCSICD_FLAGS],YSSCSICD_FLAGS_DEBUG_RS232C
						JE		SHORT @f
						CALL	RS232C_INIT
@@:


						PUSH	ES
						PUSH	DS


						TEST	BYTE PTR CS:[YSSCSICD_FLAGS],YSSCSICD_FLAGS_DEBUG_CONSOLE
						JE		SHORT @f
						PUSHA
						CALL	PRINT_REGISTER
						CALL	PRINT_CRLF
						POPA
@@:

						TEST	BYTE PTR CS:[YSSCSICD_FLAGS],YSSCSICD_FLAGS_DEBUG_RS232C
						JE		SHORT @f
						PUSHA
						CALL	RS232C_REGISTER
						CALL	RS232C_CRLF
						POPA
@@:

						MOV		BYTE PTR CS:[DEBUG_REDIR_SUBSTEP],':'

						POP		DS
						POP		ES



						TEST	BYTE PTR CS:[YSSCSICD_SCSI_ID],0F8H
						JE		SHORT @f	; Jump if redirect.
						JMP		CS:[INT93_TOWNS]
@@:
						MOV		BYTE PTR CS:[YSSCSICD_DEBUG_CMD_CACHE],AH
						CALL	REDIRECT_CDROM_BIOSCALL


						TEST	BYTE PTR CS:[YSSCSICD_FLAGS],YSSCSICD_FLAGS_DEBUG_RS232C
						JE		INT93H_NO_RS232C_POST
						PUSHA

						;;;;;;;;

						PUSH	AX
						PUSH	CX
						CMP		BYTE PTR CS:[YSSCSICD_DEBUG_CMD_CACHE],050H
						JNE		SHORT @f
						CALL	INT93_DEBUG_RS232C_PLAY_INFO
@@:
						CMP		BYTE PTR CS:[YSSCSICD_DEBUG_CMD_CACHE],054H
						JNE		SHORT @f
						CALL	INT93_DEBUG_RS232C_TOC
@@:
						POP		CX
						POP		AX

						;;;;;;;;

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
INT93H_NO_RS232C_POST:

						IRET

INT93H_HOOKPROC			ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INT93_DEBUG_RS232C_PLAY_INFO	PROC
						PUSH	DI
						PUSH	CX
						PUSH	AX
						MOV		CX,6
@@:
						MOV		AL,DS:[DI]
						CALL	RS232C_AL
						LEA		DI,[DI+1]
						LOOP	SHORT @b

						CALL	RS232C_CRLF
						POP		AX
						POP		CX
						POP		DI
						RET
INT93_DEBUG_RS232C_PLAY_INFO	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INT93_DEBUG_RS232C_TOC	PROC
						PUSH	DI
						PUSH	CX
						PUSH	AX

						CMP		AH,0
						JNE		INT93_DEBUG_RS232C_TOC_ERROR

						MOV		CL,DS:[DI+2]
						SUB		CL,DS:[DI+1]
						ADD		CL,4			; CL+1=Num of music  Two more 3-byte pairs for additional info.  Will print 3 extra bytes.
						XOR		CH,CH
@@:
						MOV		AL,DS:[DI]
						CALL	RS232C_AL
						MOV		AL,DS:[DI+1]
						CALL	RS232C_AL
						MOV		AL,DS:[DI+2]
						CALL	RS232C_AL
						CALL	RS232C_CRLF
						LEA		DI,[DI+3]
						LOOP	SHORT @b

INT93_DEBUG_RS232C_TOC_ERROR:
						POP		AX
						POP		CX
						POP		DI
						RET
INT93_DEBUG_RS232C_TOC	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BUSY_WAIT_65536			PROC
						PUSH	CX
						MOV		CX,65535

BUSY_WAIT_65536_LOOP:	LOOP	BUSY_WAIT_65536_LOOP

						POP		CX
						RET
BUSY_WAIT_65536			ENDP
