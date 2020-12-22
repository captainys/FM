						ASSUME	CS:CODE

						PUBLIC	RS232C_STI
						PUBLIC	RS232C_CLI
						PUBLIC	RS232C_INIT
						PUBLIC	RS232C_GETC
						PUBLIC	RS232C_PUTC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CODE					SEGMENT

; Initializes RS232C and masks IRQ.
; Input
;   First Param=4   19200bps
;               2   38400bps
;               1   76800bps (Probably Fail)
; Return
;   EFLAGS before masking IRQ.
RS232C_INIT			PROC
						PUSH	EAX
						PUSH	EDX

						; [ESP]EDX  [ESP+4]EAX  [ESP+8]EFLAGS  [ESP+12]EIP  [ESP+16]1st Param
						MOV		EAX,[ESP+16]

						PUSH	EAX

						XOR		AL,AL
						MOV		DX,0A08H
						OUT		DX,AL		; Mask all RS232C IRQs

						; Timer #4 must be set to Async 1/16 for 19200bps
						; Timer #4 mode must be 2 "Rate Generator"
						; RS232C BIOS is using mode 3 "Rectangular Rate Generator"
						MOV		DX,0056H
						MOV		AL,076H  ; Valule based on BIOS disassembly
						OUT		DX,AL

						POP		EAX
						; RS232C BIOS Disassembly showed it writes two bytes in 0052H in a sequence.
						MOV 	DX,0052H
						OUT		DX,AL
						MOV		AL,00H
						OUT		DX,AL

						MOV		DX,0A02H
						XOR		AL,AL

						MOV		DX,0A02H
						XOR		AL,AL
						OUT		DX,AL
						CALL	RS232C_DELAY

						MOV		DX,0A02H
						XOR		AL,AL
						OUT		DX,AL
						CALL	RS232C_DELAY

						MOV		DX,0A02H
						XOR		AL,AL
						OUT		DX,AL
						CALL	RS232C_DELAY

						MOV		DX,0A02H
						MOV		AL,040H		; Internal reset
						OUT		DX,AL
						CALL	RS232C_DELAY


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
						CALL	RS232C_DELAY


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
						CALL	RS232C_DELAY


						MOV		DX,0A08H
						MOV		AL,020H  ; DTR=1, Internal Clock for Rx and Tx
						OUT		DX,AL

						; Make sure it is ready to transmit
						CALL	RS232C_WAIT_TX_READY

						POP		EDX
						POP		EAX
						RET
RS232C_INIT			ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RS232C_CLI				PROC
						CLI
						RET
RS232C_CLI				ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RS232C_STI				PROC
						CLI
						RET
RS232C_STI				ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RS232C_WAIT_TX_READY	PROC
						MOV		DX,0A02H
						IN		AL,DX
						AND		AL,03H		; Just exit if RxD.
						JE		RS232C_WAIT_TX_READY
						RET
RS232C_WAIT_TX_READY	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RS232C_DELAY			PROC
						PUSH	ECX
						MOV		ECX,256
RS232C_DELAY_LOOP:
						OUT		6CH,AL
						LOOP	RS232C_DELAY_LOOP
						POP		ECX
						RET
RS232C_DELAY			ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RS232C_PUTC			PROC
						PUSH	EDX

						CALL	RS232C_WAIT_TX_READY
						MOV		EAX,[ESP+8]
						MOV		DX,0A00H
						OUT		DX,AL

						POP		EDX
						RET
RS232C_PUTC			ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Output
;   AL            Byte data if CF=0, Undefined if CF=1
;   EAX Positive  One byte was read from the RS232C.
;   EAX Negative  Nothing to read
RS232C_GETC				PROC
						PUSH	EDX

						MOV		DX,0A02H
						IN		AL,DX
						TEST	AL,02H
						JNE		RS232C_GETC_DATA_READY

						POP		EDX
						OR		EAX,80000000H
						RET

RS232C_GETC_DATA_READY:
						MOV		DX,0A00H
						IN		AL,DX
						POP		EDX
						AND		EAX,000000FFH
						RET
RS232C_GETC				ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CODE					ENDS
						END
