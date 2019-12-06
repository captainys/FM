;/* ////////////////////////////////////////////////////////////
;
;File Name: RS232C.ASM
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


RS232C_INIT				PROC
						PUSH	AX
						PUSH	DX

						; Timer #4 must be set to Async 1/16 for 19200bps
						; Timer #4 mode must be 2 "Rate Generator"
						; RS232C BIOS is using mode 3 "Rectangular Rate Generator"
						MOV		DX,0056H
						MOV		AL,076H  ; Valule based on BIOS disassembly
						OUT		DX,AL

						; RS232C BIOS Disassembly showed it writes two bytes in 0052H in a sequence.
						MOV 	DX,0052H
						MOV		AL,04H
						OUT		DX,AL
						MOV		AL,00H
						OUT		DX,AL

						MOV		DX,0A02H
						XOR		AL,AL

						MOV		DX,0A02H
						XOR		AL,AL
						OUT		DX,AL
						CALL	RS232C_UNIT_DELAY

						MOV		DX,0A02H
						XOR		AL,AL
						OUT		DX,AL
						CALL	RS232C_UNIT_DELAY

						MOV		DX,0A02H
						XOR		AL,AL
						OUT		DX,AL
						CALL	RS232C_UNIT_DELAY

						MOV		DX,0A02H
						MOV		AL,040H		; Internal reset
						OUT		DX,AL
						CALL	RS232C_UNIT_DELAY


						; 04EH
						; S2 S1 Ep PN L2 L1 B2 B1
						;  0  1  0  0  1  1  1  0
						; S2=0, S1=1 -> 1 stop bit
						; PN=0       -> No parity
						; L2=1, L1=1 -> 8 bit
						; B2=1, B1=0 -> 1/16 scalar
						MOV		DX,0A02H
						MOV		AL,4EH
						OUT		DX,AL
						CALL	RS232C_UNIT_DELAY


						; 0B7H
						; ON	Sync Char search (?), 
						; OFF	Internal Reset,
						; ON	RTS request
						; ON	Clear Error Flags
						; OFF	Break
						; ON	RXE Receive Enable
						; ON	DTR Treminal Ready
						; ON	TXE Transmission Enable
						MOV		DX,0A02H
						MOV		AL,0B7H
						OUT		DX,AL
						CALL	RS232C_UNIT_DELAY


						MOV		DX,0A08H
						MOV		AL,020H  ; DTR=1, Internal Clock for Rx and Tx
						OUT		DX,AL


						; Make sure it is ready to transmit
						CALL	RS232C_WAIT_TX_READY

						POP		DX
						POP		AX
						RET
RS232C_INIT				ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RS232C_WAIT_TX_READY	PROC

						PUSH	AX
						PUSH	DX
@@:
						MOV		DX,0A02H
						IN		AL,DX
						AND		AL,03H		; Just exit if RxD.
						JE		@b

						POP		DX
						POP		AX
						RET

RS232C_WAIT_TX_READY	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RS232C_UNIT_DELAY		PROC
						PUSH	CX
						MOV		CX,256
@@:
						DEC		CX
						JNE		@b

						POP		CX
						RET
RS232C_UNIT_DELAY		ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RS232C_PUTC				PROC
						PUSH	DX

						CALL	RS232C_WAIT_TX_READY
						MOV		DX,0A00H
						OUT		DX,AL

						POP		DX
						RET
RS232C_PUTC				ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RS232C_REGISTER			PROC

						PUSHA
						PUSH	DI

						LEA		DI,[MSG_REG_AX]
						CALL	RS232C_CSTR
						CALL	RS232C_AX

						MOV		AX,BX
						LEA		DI,[MSG_REG_BX]
						CALL	RS232C_CSTR
						CALL	RS232C_AX

						MOV		AX,CX
						LEA		DI,[MSG_REG_CX]
						CALL	RS232C_CSTR
						CALL	RS232C_AX

						MOV		AX,DX
						LEA		DI,[MSG_REG_DX]
						CALL	RS232C_CSTR
						CALL	RS232C_AX

						MOV		AX,SI
						LEA		DI,[MSG_REG_SI]
						CALL	RS232C_CSTR
						CALL	RS232C_AX

						POP		DI

						MOV		AX,DI
						LEA		DI,[MSG_REG_DI]
						CALL	RS232C_CSTR
						CALL	RS232C_AX

						MOV		AX,CS
						LEA		DI,[MSG_REG_CS]
						CALL	RS232C_CSTR
						CALL	RS232C_AX

						MOV		AX,DS
						LEA		DI,[MSG_REG_DS]
						CALL	RS232C_CSTR
						CALL	RS232C_AX

						MOV		AX,ES
						LEA		DI,[MSG_REG_ES]
						CALL	RS232C_CSTR
						CALL	RS232C_AX

						MOV		AL,'$'
						CALL	RS232C_PUTC

						POPA

						RET

RS232C_REGISTER			ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RS232C_AL				PROC
						PUSH	CX
						PUSH	AX

						CALL	ITOA8
						XCHG	AL,AH
						CALL	RS232C_PUTC
						XCHG	AL,AH
						CALL	RS232C_PUTC

						POP		AX
						POP		CX
						RET
RS232C_AL				ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RS232C_AX				PROC
						XCHG	AL,AH
						CALL	RS232C_AL
						XCHG	AL,AH
						CALL	RS232C_AL
						RET
RS232C_AX				ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RS232C_AX_CH			PROC

						; FM TOWNS BIOS disassembly strongly suggests that CH is the error code.
						; The meaning of CH is still unknown, but 0 means no error.
						PUSH	CX
						PUSH	AX
						PUSH	BP

						MOV		BP,SP
						MOV		AL,BYTE PTR [BP+1]
						CALL	RS232C_AL
						MOV		AL,BYTE PTR [BP+0]
						CALL	RS232C_AL

						MOV		AL,' '
						CALL	RS232C_PUTC
						MOV		AL,BYTE PTR [BP+3]
						CALL	RS232C_AL

						MOV		AL,' '
						CALL	RS232C_PUTC

						POP		BP
						POP		AX
						POP		CX

						RET

RS232C_AX_CH			ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RS232C_AH_CX			PROC

						; CD-ROM BIOS Error Code
						PUSH	CX
						PUSH	AX
						PUSH	BP

						MOV		BP,SP
						MOV		AL,BYTE PTR [BP+3]
						CALL	RS232C_AL

						MOV		AL,' '
						CALL	RS232C_PUTC

						MOV		AL,BYTE PTR [BP+5]
						CALL	RS232C_AL
						MOV		AL,BYTE PTR [BP+4]
						CALL	RS232C_AL

						MOV		AL,' '
						CALL	RS232C_PUTC

						POP		BP
						POP		AX
						POP		CX

						RET

RS232C_AH_CX			ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RS232C_CRLF				PROC
						PUSH	AX
						MOV		AL,0DH
						CALL	RS232C_PUTC
						MOV		AL,0AH
						CALL	RS232C_PUTC
						POP		AX
						RET
RS232C_CRLF				ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RS232C_CSTR				PROC
						PUSH	DX
						PUSH	CX
						PUSH	AX

@@:
						MOV		AL,DS:[DI]
						CMP		AL,0
						JE		RS232C_CSTR_EXIT
						CALL	RS232C_PUTC
						LEA		DI,[DI+1]
						JMP		@b

RS232C_CSTR_EXIT:
						POP		AX
						POP		CX
						POP		DX
						RET

RS232C_CSTR				ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
