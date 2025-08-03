

IO_OPN_COMMAND			EQU		$FD15
IO_OPN_DATA				EQU		$FD16


OPN_WRITE_COMMAND		EQU		2
OPN_LATCH_COMMAND		EQU		3
OPN_STATUS_COMMAND		EQU		4


OPN_REG_SLOT_ON_OFF		EQU		$28
OPN_REG_FNUMBER_LOW		EQU		$A0
OPN_REG_FNUMBER_HIGH	EQU		$A4


; Input		A: OPN Register

OPN_LATCH_REGISTER		BSR		OPN_WAIT_READY

						STA		IO_OPN_DATA
						LDA		#OPN_LATCH_COMMAND
						STA		IO_OPN_COMMAND
						CLR		IO_OPN_COMMAND

						RTS



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Input		A: OPN Register
;			B: Value

OPN_WRITE_REGISTER		BSR		OPN_LATCH_REGISTER

						; F-BASIC 3.3 waits 6 cycles with NOP NOP NOP.
						TFR		A,A

						STB		IO_OPN_DATA
						LDB		#OPN_WRITE_COMMAND
						STB		IO_OPN_COMMAND
						CLR		IO_OPN_COMMAND

						RTS


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; F-BASIC waits up to 255 times.  Is this a good strategy?
OPN_WAIT_READY			PSHS	A,B

						CLRB
OPN_WAIT_READY_LOOP		DECB
						BEQ		OPN_WAIT_READY_LOOP_OUT

						LDA		#OPN_STATUS_COMMAND
						STA		IO_OPN_COMMAND
						LDA		IO_OPN_DATA
						CLR		IO_OPN_COMMAND
						TSTA
						BMI		OPN_WAIT_READY_LOOP

OPN_WAIT_READY_LOOP_OUT	PULS	A,B,PC


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Output: A status
;   Bit 0  Timer A Up
;   Bit 1  Timer B Up
;   Bit 7  Busy
OPN_GET_STATE			LDA		#OPN_STATUS_COMMAND
						STA		IO_OPN_COMMAND
						LDA		IO_OPN_DATA
						CLR		IO_OPN_COMMAND
						RTS
