					EXPORT	RS232C_OPEN
					EXPORT	RS232C_CLOSE


RS232C_IO			FDB		$FD06		; COM0:$FD06  COM1:$FD24


					; Initialization based on disassembly of D77IMG by Mr. Apollo

					; It chooses COM1 if present.
RS232C_OPEN
					PSHS	A,B,X,U

					CLR		$FD02			; Turn off RS232C IRQ
											; This actually turns off other IRQs, but there's no way of knowing which IRQs were enabled.

					LDA		#5
					STA		$FD0C			; AV20/40 DTR OFF  RS232C ON
					MUL						; Wait 11 cycles
					LDA		#$10
					STA		$FD0B			; AV20/40 Baud Rate  100=4x300=1200bps
					MUL						; Wait 11 cycles
					LDA		$FD0F			; FM-7 does not distinguish FD0B and FD0F


					LDU		#$FD06
					BSR		RESET_8251
					LDU		#$FD24
					BSR		RESET_8251

					; F-BASIC ROM resets error flag and check status byte.
					; If error flag is clear, the status byte will not be $FF.
					LDA		1,U
					CMPA	#$FF
					BNE		RS232C_COM1_PRESENT
					LDU		#$FD06

RS232C_COM1_PRESENT
					STU		RS232C_IO,PCR

					PULS	A,B,X,U,PC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RS232C_CLOSE		PSHS	A,B,X,U
					LDU		RS232C_IO,PCR
					BSR		RESET_8251
					PULS	A,B,X,U,PC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;	Input  U  RS232C I/O
RESET_8251			LEAX	RESET_8251_CMD,PCR
RESET_8251_LOOP		MUL
					LDA		,X+
					STA		1,U
					BPL		RESET_8251_LOOP
					RTS

RESET_8251_CMD		FCB		0,0,0
					FCB		$40				; Internal Reset

					FCB		$4E				; (Immediately after reset)
											; 1 stop-bit, Odd parity, Parity Disabled, 8-bit data, 1/16 baud-rate division (? what is it)
											; Presumably baud rate is 4x300x16=19200bps in AV20/AV40.
											; Baud Rate must be set by hardware dip switches (if I remember correctly) in earlier models.
											; Lowest two bits seem to decide Async or Sync mode.
											; Will be in Sync mode if the lowest two bits are both zero.
											; Wait 11 cycles

					FCB		$B7				; ON	Sync Char search (?), 
											; OFF	Internal Reset,
											; ON	RTS request
											; ON	Clear Error Flags
											; OFF	Break
											; ON	RXE Receive Enable
											; ON	DTR Treminal Ready
											; ON	TXE Transmission Enable


