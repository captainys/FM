						ASSUME	CS:CODE

						PUBLIC	RS232C_INIT
						PUBLIC	RS232C_GETC
						PUBLIC	RS232C_PUTC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; size COMPORT_INFO must be 16.
COMPORT_INFO			STRUC

TIMER_CTRL				DW		?
TIMER_CTRL_IO			DW		?
TIMER_COUNT_IO			DW		?

DATA_IO					DW		?
STATUS_COMMAND_IO		DW		?
STATUS2_IO				DW		?
INT_REASON_IO			DW		?
INT_CTRL_IO				DW		?

COMPORT_INFO			ENDS



CODE					SEGMENT


COM0					COMPORT_INFO <0076H,0056H,0052H,0A00H,0A02H,0A04H,0A06H,0A08H>
COM1					COMPORT_INFO <0036H,0CA6H,0CA0H,0C80H,0C82H,0C84H,0C86H,0C08H>
COM2					COMPORT_INFO <0076H,0CA6H,0CA2H,0C90H,0C92H,0C94H,0C96H,0C08H>
COM3					COMPORT_INFO <0036H,0CE6H,0CE0H,0CC0H,0CC2H,0CC4H,0CC6H,0CC8H>
COM4					COMPORT_INFO <0076H,0CE6H,0CE0H,0CD0H,0CD2H,0CD4H,0CD6H,0CD8H>


; Initializes RS232C and masks IRQ.
; Input
;   Second Param=4   19200bps
;                2   38400bps
;                1   76800bps (Probably Fail)
;   First Param      COM Port
; Return
;   EFLAGS before masking IRQ.
RS232C_INIT			PROC
						PUSH	EDX
						PUSH	ESI

						; [ESP]ESI  [ESP+4]EDX  [ESP+8]EIP   [ESP+12]COM POrt  [ESP+16]Speed
						MOV		EAX,[ESP+12]	; COM Port
						SHL		EAX,4
						LEA		ESI,[COM0+EAX]

						XOR		AL,AL
						MOV		DX,[ESI].INT_CTRL_IO	; 0A08H
						OUT		DX,AL		; Mask all RS232C IRQs

						; Timer #4 must be set to Async 1/16 for 19200bps
						; Timer #4 mode must be 2 "Rate Generator"
						; RS232C BIOS is using mode 3 "Rectangular Rate Generator"
						MOV		DX,[ESI].TIMER_CTRL_IO	; 0056H
						MOV		AL,BYTE PTR [ESI].TIMER_CTRL		; 076H  ; Valule based on BIOS disassembly
						OUT		DX,AL

						; RS232C BIOS Disassembly showed it writes two bytes in 0052H in a sequence.
						MOV 	DX,[ESI].TIMER_COUNT_IO	; 0052H
						MOV		EAX,[ESP+16]
						OUT		DX,AL
						MOV		AL,00H
						OUT		DX,AL

						MOV		DX,[ESI].STATUS_COMMAND_IO	; 0A02H

						XOR		AL,AL
						OUT		DX,AL
						CALL	RS232C_DELAY

						XOR		AL,AL
						OUT		DX,AL
						CALL	RS232C_DELAY

						XOR		AL,AL
						OUT		DX,AL
						CALL	RS232C_DELAY

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
						MOV		AL,0B7H
						OUT		DX,AL
						CALL	RS232C_DELAY


						MOV		DX,[ESI].INT_CTRL_IO	; 0A08H
						MOV		AL,020H  ; DTR=1, Internal Clock for Rx and Tx
						OUT		DX,AL

						; Make sure it is ready to transmit
						CALL	RS232C_WAIT_TX_READY

						POP		ESI
						POP		EDX
						RET
RS232C_INIT			ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Input: ESI=COM Port Info
RS232C_WAIT_TX_READY	PROC
						MOV		DX,[ESI].STATUS_COMMAND_IO ; 0A02H
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

;   Second Param     Wait in microsec between TxRDY and writing to data I/O.
;   First Param      COM Port
RS232C_PUTC			PROC
						PUSH	EDX
						PUSH	ESI

						; [ESP]ESI  [ESP+4]EDX  [ESP+8]EIP  [ESP+12]COM Port  [ESP+16] Data  [ESP+20]Wait in us
						MOV		EAX,[ESP+12]	; COM Port
						SHL		EAX,4
						LEA		ESI,[COM0+EAX]

						CALL	RS232C_WAIT_TX_READY

						XCHG	ECX,[ESP+20]
						JECXZ	RS232C_PUTC_NO_WAIT
RS232C_PUTC_WAIT_LOOP:	OUT		6CH,AL
						LOOP	RS232C_PUTC_WAIT_LOOP
RS232C_PUTC_NO_WAIT:
						XCHG	ECX,[ESP+20]

						MOV		EAX,[ESP+16]
						MOV		DX,[ESI].DATA_IO	; 0A00H
						OUT		DX,AL

						POP		ESI
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
						PUSH	ESI

						;[ESP]ESI  [ESP+4]EDX  [ESP+8]EIP  [ESP+12]COM Port  [ESP+16]Wait in microsec
						MOV		EAX,[ESP+12]	; COM Port
						SHL		EAX,4
						LEA		ESI,[COM0+EAX]

						MOV		DX,[ESI].STATUS_COMMAND_IO ; 0A02H
						IN		AL,DX
						TEST	AL,02H
						JNE		RS232C_GETC_DATA_READY

						POP		ESI
						POP		EDX
						OR		EAX,80000000H
						RET

RS232C_GETC_DATA_READY:
						XCHG	ECX,[ESP+16]
						JECXZ	RS232C_GETC_NO_WAIT
RS232C_GETC_WAIT_LOOP:	OUT		6CH,AL
						LOOP	RS232C_GETC_WAIT_LOOP
RS232C_GETC_NO_WAIT:
						XCHG	ECX,[ESP+16]


						MOV		DX,[ESI].DATA_IO	; 0A00H
						IN		AL,DX
						POP		ESI
						POP		EDX
						MOVZX	EAX,AL
						RET
RS232C_GETC				ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CODE					ENDS
						END
