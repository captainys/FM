						ASSUME	CS:CODE,DS:CODE

						PUBLIC	RS232C_INIT
						PUBLIC	RS232C_END
						PUBLIC	RS232C_GETC
						PUBLIC	RS232C_PUTC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; size COMPORT_INFO must be 16.
COMPORT_INFO			STRUC

INT_LEVEL				DB		?
TIMER_CTRL				DB		?
TIMER_CTRL_IO			DW		?
TIMER_COUNT_IO			DW		?

DATA_IO					DW		?
STATUS_COMMAND_IO		DW		?
STATUS2_IO				DW		?
INT_REASON_IO			DW		?
INT_CTRL_IO				DW		?

COMPORT_INFO			ENDS



						; Internal reset
I8251_RESET_COMMAND		EQU		40H

						; 04EH
						; S2 S1 Ep PN L2 L1 B2 B1
						;  0  1  0  0  1  1  1  0
						; S2=0, S1=1 -> 1 stop bit
						; PN=0       -> No parity
						; L2=1, L1=1 -> 8 bit
						; B2=1, B1=0 -> 1/16 scalar
I8251_MODE_BYTE			EQU		4EH

						; 037H
						; OFF	Sync Char search (Supposed to be valid only in the synchronous mode), 
						; OFF	Internal Reset,
						; ON	RTS request
						; ON	Clear Error Flags
						; OFF	Break
						; ON	RXE Receive Enable
						; ON	DTR Treminal Ready
						; ON	TXE Transmission Enable
I8251_COMMAND_BYTE		EQU		37H


						; b5  FE
						; b4  OE
						; b3  PE
I8251_STATUS_ERROR_BITS	EQU		38H


CODE					SEGMENT


COM0					COMPORT_INFO <2,76H,0056H,0052H,0A00H,0A02H,0A04H,0A06H,0A08H>
COM1					COMPORT_INFO <3,36H,0CA6H,0CA0H,0C80H,0C82H,0C84H,0C86H,0C88H>
COM2					COMPORT_INFO <3,76H,0CA6H,0CA2H,0C90H,0C92H,0C94H,0C96H,0C98H>
COM3					COMPORT_INFO <3,36H,0CE6H,0CE0H,0CC0H,0CC2H,0CC4H,0CC6H,0CC8H>
COM4					COMPORT_INFO <3,76H,0CE6H,0CE0H,0CD0H,0CD2H,0CD4H,0CD6H,0CD8H>

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PREV_INT_VECTOR				DD		0
							DW		0
PREV_REALMODE_INT_VECTOR	DD		0
PREV_PIC_INTMASK			DB		0


OPEN_COM_INFO			DD		0

RECV_BUF_LEN			EQU		2048

RECV_BUF_USED			DW		0
RECV_BUF_READ_PTR		DW		0
RECV_BUF_WRITE_PTR		DW		0
RECV_BUF				DB		RECV_BUF_LEN dup (0)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RS232C_INT_HANDLER		PROC	FAR
						PUSHAD
						PUSH	DS
						PUSH	ES

						MOV		AX,0014H
						MOV		DS,AX
						MOV		ES,AX

						MOV		ESI,[OPEN_COM_INFO]
						MOV		DX,[ESI].INT_REASON_IO
						IN		AL,DX
						AND		AL,1
						JE		ONBOARD_RS232C_INT_EXIT	; Is it a mistake?  Suprious INT?

						MOV		DX,[ESI].STATUS_COMMAND_IO
						IN		AL,DX
						AND		AL,2
						JE		ONBOARD_RS232C_INT_EXIT	; Supposed to be RxRDY.  WTF?

						MOV		DX,[ESI].DATA_IO
						IN		AL,DX

						MOV		BX,[RECV_BUF_USED]
						CMP		BX,RECV_BUF_LEN
						JAE		ONBOARD_RS232C_OUT_OF_BUF

						INC		BX
						MOV		[RECV_BUF_USED],BX

						MOVZX	EBX,WORD PTR [RECV_BUF_WRITE_PTR]
						MOV		[RECV_BUF+EBX],AL

						INC		BX
						AND		BX,(RECV_BUF_LEN-1)
						MOV		[RECV_BUF_WRITE_PTR],BX

ONBOARD_RS232C_OUT_OF_BUF:
						MOV		DX,[ESI].STATUS_COMMAND_IO
						IN		AL,DX
						AND		AL,I8251_STATUS_ERROR_BITS
						JE		ONBOARD_RS232C_INT_EXIT

						MOV		AL,I8251_COMMAND_BYTE	; Including Error Reset bit.
						OUT		DX,AL

ONBOARD_RS232C_INT_EXIT:
						MOV		AL,[ESI].INT_LEVEL
						OR		AL,060H		; Specific EOI.
						OUT		00H,AL

						POP		ES
						POP		DS
						POPAD
						IRETD
RS232C_INT_HANDLER		ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Input ESI=COM Port Info
SETUP_INT				PROC
						PUSHFD
						PUSH	ES
						CLI

						MOV		CL,[ESI].INT_LEVEL
						ADD		CL,40H
						MOV		AX,2502h	; Get Protected-Mode INT Vector
						INT		21H

						MOV		[PREV_INT_VECTOR],EBX
						MOV		WORD PTR [PREV_INT_VECTOR+4],ES

						; CL is supposed to be still INT number.
						MOV		AX,2503h	; Get Real-Mode INT Vector
						INT		21H
						MOV		[PREV_REALMODE_INT_VECTOR],EBX

						PUSH	DS

						; CL is supposed to be still INT number.
						MOV		EDX,OFFSET RS232C_INT_HANDLER
						PUSH	CS
						POP		DS
						MOV		AX,2506h		; Set INT to always gain control in protected mode
						INT		21H

						POP		DS

						IN		AL,0002H
						MOV		[PREV_PIC_INTMASK],AL

						MOV		CL,[ESI].INT_LEVEL
						MOV		AL,1
						SHL		AL,CL
						NOT		AL
						AND		AL,[PREV_PIC_INTMASK]
						OUT		0002H,AL

						POP		ES
						POPFD
						RET

SETUP_INT				ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


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
						MOV		[OPEN_COM_INFO],ESI

						CALL	SETUP_INT

						MOV		AL,2		; Take only RxRDY INT.
						MOV		DX,[ESI].INT_CTRL_IO	; 0A08H
						OUT		DX,AL		; Mask all RS232C IRQs

						; Timer #4 must be set to Async 1/16 for 19200bps
						; Timer #4 mode must be 2 "Rate Generator"
						; RS232C BIOS is using mode 3 "Rectangular Rate Generator"
						MOV		DX,[ESI].TIMER_CTRL_IO	; 0056H
						MOV		AL,[ESI].TIMER_CTRL		; 076H  ; Valule based on BIOS disassembly
						OUT		DX,AL

						; RS232C BIOS Disassembly showed it writes two bytes in 0052H in a sequence.
						MOV 	DX,[ESI].TIMER_COUNT_IO	; 0052H
						MOV		EAX,[ESP+16]
						OUT		DX,AL
						MOV		AL,AH
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


						MOV		AL,I8251_RESET_COMMAND
						OUT		DX,AL
						CALL	RS232C_DELAY


						MOV		AL,I8251_MODE_BYTE
						OUT		DX,AL
						CALL	RS232C_DELAY


						MOV		AL,I8251_COMMAND_BYTE
						OUT		DX,AL
						CALL	RS232C_DELAY


						MOV		DX,[ESI].INT_CTRL_IO	; 0A08H
						MOV		AL,022H  ; DTR=1, Internal Clock for Rx and Tx, Enable RxRDY INT
						OUT		DX,AL

						; Make sure it is ready to transmit
						CALL	RS232C_WAIT_TX_READY

						POP		ESI
						POP		EDX
						RET
RS232C_INIT			ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RS232C_END			PROC
					PUSHFD
					CLI

					MOV		ESI,[OPEN_COM_INFO]
					MOV		CL,[ESI].INT_LEVEL
					ADD		CL,40H

					PUSH	DS
					LDS		EDX,FWORD PTR [PREV_INT_VECTOR+4]
					MOV		AX,2504h	; Set Protected-Mode INT Vector
					INT		21H
					POP		DS

					MOV		EBX,[PREV_REALMODE_INT_VECTOR]
					MOV		AX,2505h	; Set Real-Mode INT Vector
					INT		21H

					MOV		AL,[PREV_PIC_INTMASK]
					OUT		0002H,AL

					POPFD
					RET
RS232C_END			ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Input: ESI=COM Port Info
RS232C_WAIT_TX_READY	PROC
						MOV		DX,[ESI].STATUS_COMMAND_IO ; 0A02H
						IN		AL,DX
						AND		AL,05H
						CMP		AL,5	; TxE and TxRDY
						JNE		RS232C_WAIT_TX_READY
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

WAIT_BY_EDX_TIMES_MICROSEC	PROC
						XCHG	EDX,ECX
						JECXZ	WAIT_BY_EDX_NO_WAIT
WAIT_BY_EDX_LOOP:
						OUT		6CH,AL
						LOOP	WAIT_BY_EDX_LOOP
WAIT_BY_EDX_NO_WAIT:
						XCHG	ECX,EDX
						RET
WAIT_BY_EDX_TIMES_MICROSEC	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Input:
;  ESI COM Port Info
;  EAX Data from i8251
; Output:
;  EAX b30 set if error was cleared.
CLEAR_ERROR				PROC
						PUSH	EAX
						MOV		DX,[ESI].STATUS_COMMAND_IO
						IN		AL,DX
						AND		AL,I8251_STATUS_ERROR_BITS
						JE		NO_ERROR_TO_CLEAR

						MOV		AL,I8251_COMMAND_BYTE
						OUT		DX,AL

CLEARED_ERROR:			POP		EAX
						OR		EAX,40000000H
						RET

NO_ERROR_TO_CLEAR:		POP		EAX
						RET

CLEAR_ERROR				ENDP

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

						MOV		EDX,[ESP+20]
						CALL	WAIT_BY_EDX_TIMES_MICROSEC

						MOV		EAX,[ESP+16]
						MOV		DX,[ESI].DATA_IO	; 0A00H
						OUT		DX,AL

						MOV		EDX,[ESP+20]
						CALL	WAIT_BY_EDX_TIMES_MICROSEC

						POP		ESI
						POP		EDX
						RET
RS232C_PUTC			ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Output
;   EAX Positive  One byte was read from the RS232C.
;   EAX Negative  Nothing to read
;       b30       Cleared error
RS232C_GETC				PROC
						PUSH	EDX
						PUSH	ESI

						;[ESP]ESI  [ESP+4]EDX  [ESP+8]EIP  [ESP+12]COM Port  [ESP+16]Wait in microsec

						MOV		EAX,80000000H
						CMP		WORD PTR [RECV_BUF_USED],0
						JE		RS232C_GOTC

						MOVZX	ESI,WORD PTR [RECV_BUF_READ_PTR]
						MOVZX	EAX,BYTE PTR [RECV_BUF+ESI]

						INC		SI
						AND		SI,(RECV_BUF_LEN-1)
						MOV		[RECV_BUF_READ_PTR],SI

						DEC		WORD PTR [RECV_BUF_USED]

RS232C_GOTC:
						POP		ESI
						POP		EDX
						RET
RS232C_GETC				ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CODE					ENDS
						END
