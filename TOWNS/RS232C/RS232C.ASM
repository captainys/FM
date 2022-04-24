;/* ////////////////////////////////////////////////////////////
;
;File Name: RS232C.ASM
;Copyright (c) 2020 Soji Yamakawa.  All rights reserved.
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


; Input
;   AL=4   19200bps
;   AL=2   38400bps
;   AL=1   76800bps (Probably Fail)
RS232C2_INIT			PROC
						PUSH	AX
						PUSH	DX

						PUSH	AX

						XOR		AL,AL
						MOV		DX,0A08H
						OUT		DX,AL		; Mask all RS232C IRQs

						; Timer #4 must be set to Async 1/16 for 19200bps
						; Timer #4 mode must be 2 "Rate Generator"
						; RS232C BIOS is using mode 3 "Rectangular Rate Generator"
						MOV		DX,0056H
						MOV		AL,076H  ; Valule based on BIOS disassembly
						OUT		DX,AL

						POP		AX
						; RS232C BIOS Disassembly showed it writes two bytes in 0052H in a sequence.
						MOV 	DX,0052H
						OUT		DX,AL
						MOV		AL,00H
						OUT		DX,AL

						MOV		DX,0A02H
						XOR		AL,AL

						CALL	RS232C2_DELAY

						OUT		DX,AL
						CALL	RS232C2_DELAY

						OUT		DX,AL
						CALL	RS232C2_DELAY

						OUT		DX,AL
						CALL	RS232C2_DELAY

						MOV		AL,040H		; Internal reset
						OUT		DX,AL
						CALL	RS232C2_DELAY


						; 04EH
						; S2 S1 Ep PN L2 L1 B2 B1
						;  0  1  0  0  1  1  1  0
						; S2=0, S1=1 -> 1 stop bit
						; PN=0       -> No parity
						; L2=1, L1=1 -> 8 bit
						; B2=1, B1=0 -> 1/16 scalar
						MOV		AL,4EH
						OUT		DX,AL
						CALL	RS232C2_DELAY


						; 0B7H
						; ON	Sync Char search (?), 
						; OFF	Internal Reset,
						; ON	RTS request
						; ON	Clear Error Flags
						; OFF	Break
						; ON	RXE Receive Enable
						; ON	DTR Treminal Ready
						; ON	TXE Transmission Enable
						MOV		AL,0B7H
						OUT		DX,AL
						CALL	RS232C2_DELAY


						MOV		DL,08H	; DX=0A08H
						MOV		AL,020H	; DTR=1, Internal Clock for Rx and Tx
						OUT		DX,AL


						; Make sure it is ready to transmit
						CALL	RS232C2_WAIT_TX_READY

						POP		DX
						POP		AX
						RET
RS232C2_INIT			ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RS232C2_WAIT_TX_READY	PROC

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

RS232C2_WAIT_TX_READY	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Must not change DX and AL
RS232C2_DELAY			PROC
						PUSH	CX
						MOV		CX,256
@@:
						OUT		6CH,AL
						LOOP	@b
						POP		CX
						RET
RS232C2_DELAY			ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Input AL
RS232C2_PUTC			PROC
						PUSH	DX

						CALL	RS232C2_WAIT_TX_READY
						MOV		DX,0A00H
						OUT		DX,AL

						POP		DX
						RET
RS232C2_PUTC			ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Output
;   AL    Byte data if CF=0, Undefined if CF=1
;   CF=0  One byte was read from the RS232C.
;   CF=1  Nothing to read
RS232C2_GETC			PROC
						PUSH	DX
						MOV		DX,0A02H
						IN		AL,DX
						TEST	AL,02H
						JNE		@f
						POP		DX
						STC
						RET

@@:
						MOV		DX,0A00H
						IN		AL,DX
						POP		DX
						CLC
						RET
RS232C2_GETC				ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
