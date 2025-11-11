						ORG		$4000

PORT					FCB		0			; at $4000
RETURN					FCB		0			; at $4001

ENTRY_INIT				BRA		JSInit		; at $4002
ENTRY_READ				LDA		PORT,PCR	; at $4004
						BSR		JSRead
						STA		RETURN,PCR
						RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IO_FM_CMD				EQU		$FD15
IO_FM_DATA				EQU		$FD16

FM_CMD_LATCH			EQU		3
FM_CMD_WRITE			EQU		2
FM_CMD_READ				EQU		9


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

JSInit					LDD		#$0F7F	; Reg 15 <- $7F
						BSR		FMWrite
						LDD		#$07BF	; Reg 7 <- $BF
						BRA		FMWrite
						RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

						; A 0->JS0  1->JS1
JSRead					LDB		#$2F
						ANDA	#1
						BEQ		JSRead0
						LDB		#$5F
JSRead0					LDA		#$0F	; Reg 15 < $2F or $5F
						BSR		FMWrite

						LDA		#14
						BSR		FMLatchRegister
						LDA		#9
						STA		IO_FM_CMD
						LDA		IO_FM_DATA
						BRA		FMClearCommand

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

						; A Register
						; B Data
FMWrite					BSR		FMLatchRegister
						STB		IO_FM_DATA
						LDA		#FM_CMD_WRITE
						BRA		FMWriteCommand

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

						; A Register
FMLatchRegister			STA		IO_FM_DATA
						LDA		#FM_CMD_LATCH

FMWriteCommand			STA		IO_FM_CMD
FMClearCommand			CLR		IO_FM_CMD
						RTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
