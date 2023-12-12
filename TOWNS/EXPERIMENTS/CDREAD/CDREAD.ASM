; LICENSE>>
;Copyright 2023 Soji Yamakawa (CaptainYS, http://www.ysflight.com)
;
;Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
;
;1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
;
;2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
;
;3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
;
;THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;
; LICENSE<<


; build and run:
;   386asm CDREAD.ASM
;   386link CDREAD.OBJ -stack 8192
;   run386 -nocrt CDREAD.EXP

							.386p

IO_CDC_MASTER_CONTROL		EQU		04C0H
IO_CDC_MASTER_STATUS		EQU		04C0H

IO_CDC_COMMAND				EQU		04C2H
IO_CDC_STATUS				EQU		04C2H

IO_CDC_PARAM				EQU		04C4H
IO_CDC_TRANSFER_CONTROL		EQU		04C6H


IO_DMA_INITIALIZE			EQU		0A0H
IO_DMA_CHANNEL				EQU		0A1H
IO_DMA_COUNT_LOW			EQU		0A2H
IO_DMA_COUNT_HIGH			EQU		0A3H
IO_DMA_ADDR_LOW				EQU		0A4H
IO_DMA_ADDR_MID_LOW			EQU		0A5H
IO_DMA_ADDR_MID_HIGH		EQU		0A6H
IO_DMA_ADDR_HIGH			EQU		0A7H
IO_DMA_DEVICE_CTRL_LOW		EQU		0A8H
IO_DMA_DEVICE_CTRL_HIGH		EQU		0A9H
IO_DMA_MODE_CONTROL			EQU		0AAH
IO_DMA_STATUS				EQU		0ABH
IO_DMA_REQUEST				EQU		0AEH
IO_DMA_MASK					EQU		0AFH

IO_TIMER_1US_WAIT			EQU		06CH ; Since Towns 20F


CDCCMD_MODE1READ			EQU		62H		; MODE1READ(02H)+IRQ(40H)+STATUS_REQ(20H)


TSUGARU_DEBUG_BREAK			MACRO
							PUSH	AX
							PUSH	DX
							MOV		AL,02H   ; TOWNS_VMIF_CMD_PAUSE
							MOV		DX,2386H ; TOWNSIO_VM_HOST_IF_CMD_STATUS
							OUT		DX,AL
							POP		DX
							POP		AX
							ENDM



							ASSUME	CS:CODE,DS:DATA,SS:STACK
CODE						SEGMENT


MAIN						PROC

							PUSHFD
							CLI

							CALL	DEBUG_PALETTE_PURPLE

							CALL	GET_DMA_BUFFER_POINTER
							MOV		[DMABUF_PTR],EDX
							MOV		[DMABUF_PHYS],ECX

							CALL	CDC_CLEAR_STATUS_QUEUE

							CALL	CDC_DMA_RESET

							CALL	CDC_CLEAR_IRQ_AND_DEI


							CALL	CDC_UNDOCUMENTED_COMMAND_A0


							CALL	CDC_WAIT_READY
							JB		ERROREND
							CALL	CDC_PUSH_PARAMS


							CALL	CDC_WAIT_READY
							JB		ERROREND
							CALL	CDC_SHOOT_MODE1READ


WAIT_CDC_BUSY:
							; MOV		DX,IO_CDC_MASTER_STATUS
							; IN		AL,DX
							; TEST	AL,1
							; JNE		WAIT_CDC_BUSY

							CALL	DEBUG_PALETTE_YELLOW

							; TSUGARU_DEBUG_BREAK

READ_LOOP:
							CALL	DEBUG_PALETTE_RED

							MOV		DX,IO_CDC_MASTER_STATUS
							IN		AL,DX

							TEST	AL,80H
							JNE		READ_LOOP_SIRQ
							TEST	AL,40H
							JNE		READ_LOOP_NOSIRQ_BUT_DEI

							CALL	DEBUG_PALETTE_YELLOW

							JMP		READ_LOOP



READ_LOOP_SIRQ:
							CALL	DEBUG_PALETTE_CYAN

							; TBIOS waits up to 500000us until Status is ready to read after SIRQ is set.
							; If not take it as a time out.
							MOV		ECX,50000

READ_LOOP_WAIT_STATUS:
							OUT		IO_TIMER_1US_WAIT,AL
							DEC		ECX
							JE		ERROREND_STATUS_TIMEOUT

							IN		AL,DX
							TEST	AL,2	; SRQ=1 means status needs to be checked.  In the emulator, it is instantaneous.
							JE		READ_LOOP_WAIT_STATUS

							CALL	CDC_READ_STATUS
							MOV		[CDSTATUS],EAX

							CALL	CDC_CLEAR_IRQ
							MOV		EAX,[CDSTATUS]

							CMP		AL,0	; Command Accepted
							JE		READ_LOOP
							CMP		AL,21H	; Error
							JE		ERROREND_IO
							CMP		AL,22H	; Data Ready
							JE		DATA_READY
							CMP		AL,06H	; Read Done
							JE		BREAK_READ_LOOP
							JMP		ERROREND_UNKNOWN

DATA_READY:
							CALL	DEBUG_PALETTE_BLUE
							MOV		EDI,[DMABUF_PHYS]
							CALL	CDC_DMA_SET
							JMP		READ_LOOP



READ_LOOP_NOSIRQ_BUT_DEI:
							CALL	DEBUG_PALETTE_RED

							CALL	CDC_DMA_STOP
							CALL	CDC_CLEAR_DEI

							PUSH	DS
							POP		ES
							MOV		ESI,[DMABUF_PTR]
							MOV		EDI,[DATA_STORE_PTR]
							CLD
							MOV		ECX,800H
							REP		MOVSB
							MOV		[DATA_STORE_PTR],EDI

							JMP		READ_LOOP





BREAK_READ_LOOP:
							MOV		AL,3	; Channel 3 SCSI
							OUT		IO_DMA_CHANNEL,AL

							IN		AX,IO_DMA_COUNT_LOW
							MOV		[LAST_DMA_COUNT],AX

							CALL	DEBUG_PALETTE_WHITE

							MOV		AL,0C0H	; CDC IRQ Clear (80H), DMAE IRQ Clear (40H)
							MOV		DX,IO_CDC_MASTER_CONTROL
							OUT		DX,AL

							MOV		EDI,OFFSET MSG_READ_DONE
							CALL	PRINT_CSTR
							CALL	PRINT_CRLF

							MOV		EDI,OFFSET MSG_LAST_DMA_COUNT
							CALL	PRINT_CSTR
							MOVZX	EAX,WORD PTR [LAST_DMA_COUNT]
							CALL	PRINT_EAX
							CALL	PRINT_CRLF

							; TSUGARU_DEBUG_BREAK

							MOV		AH,3CH
							XOR		ECX,ECX
							MOV		EDX,OFFSET FILENAME
							INT		21H

							PUSH	AX

							MOV		BX,AX
							MOV		AH,40H
							MOV		EDX,OFFSET DATABUF
							MOV		ECX,16384
							INT		21H

							POP		BX

							MOV		AH,3EH
							INT		21H


ERROREND:
							CALL	DEBUG_PALETTE_WHITE

							POPFD
							MOV		AH,4CH
							INT		21H




ERROREND_PREMATURE:
							MOV		EAX,[CDSTATUS]
							CALL	PRINT_EAX
							MOV		EDI,OFFSET MSG_PREMATURE
							CALL	PRINT_CSTR
							CALL	CDC_RESET
							JMP		ERROREND

ERROREND_UNKNOWN:
							TSUGARU_DEBUG_BREAK
							CALL	PRINT_EAX
							CALL	PRINT_CRLF
							MOV		EDI,OFFSET MSG_UNKNOWN_ERROR
							CALL	PRINT_CSTR
							CALL	PRINT_CRLF
							CALL	CDC_RESET
							JMP		ERROREND

ERROREND_IO:
							CALL	PRINT_EAX
							CALL	PRINT_CRLF
							MOV		EDI,OFFSET MSG_IO_ERROR
							CALL	PRINT_CSTR
							CALL	PRINT_CRLF
							CALL	CDC_RESET
							JMP		ERROREND

ERROREND_STATUS_TIMEOUT:
							MOV		EDI,OFFSET MSG_STATUS_TIMEOUT
							CALL	PRINT_CSTR
							CALL	PRINT_CRLF
							CALL	CDC_RESET
							JMP		ERROREND


MAIN						ENDP



;;;;;;;;



; 4KB page must be included somewhere inside DMABUF_RUNWAY.
; Output:
;   EDX=Offset to DS
;   ECX=Physical Address
; This function is not supposed to fail.
GET_DMA_BUFFER_POINTER		PROC
							PUSH	EBP

							MOV		AX,2508H ; Get Segment Linear Base
							MOV		BX,DS
							INT		21H		; ECX=Linear Base Address

							MOV		EBP,ECX
							MOV		EDX,OFFSET DMABUF_RUNWAY

FIND_DMA_BUFFER_POINTER_LOOP:
							MOV		AX,2509H	; Linear address to Physical address
							LEA		EBX,[EBP+EDX]
							INT		21H

							MOV		EAX,ECX
							AND		EAX,0FFFH
							JE		FIND_DMA_BUFFER_POINTER_FOUND

							INC		EDX
							JMP		FIND_DMA_BUFFER_POINTER_LOOP

FIND_DMA_BUFFER_POINTER_FOUND:
							POP		EBP
							RET

GET_DMA_BUFFER_POINTER		ENDP



;;;;;;;;



CDC_RESET					PROC
							MOV		AL,4	; SUB MPU Reset
							MOV		DX,IO_CDC_MASTER_CONTROL
							OUT		DX,AL
							RET
CDC_RESET					ENDP



;;;;;;;;



CDC_CLEAR_IRQ				PROC
							MOV		DX,IO_CDC_MASTER_CONTROL
							MOV		AL,082H
							OUT		DX,AL
							RET
CDC_CLEAR_IRQ				ENDP



;;;;;;;;



CDC_CLEAR_DEI				PROC
							MOV		DX,IO_CDC_MASTER_CONTROL
							MOV		AL,042H
							OUT		DX,AL
							RET
CDC_CLEAR_DEI				ENDP



;;;;;;;;



CDC_CLEAR_IRQ_AND_DEI		PROC
							MOV		DX,IO_CDC_MASTER_CONTROL
							MOV		AL,0C2H
							OUT		DX,AL
							RET
CDC_CLEAR_IRQ_AND_DEI		ENDP



;;;;;;;;



CDC_CLEAR_STATUS_QUEUE		PROC

							MOV		DX,IO_CDC_MASTER_STATUS
							IN		AL,DX
							TEST 	AL,2 ; SRQ
							JE		CDC_CLEAR_STATUS_QUEUE_EXIT
							CALL	CDC_READ_STATUS
							JMP		CDC_CLEAR_STATUS_QUEUE

CDC_CLEAR_STATUS_QUEUE_EXIT:
							RET

CDC_CLEAR_STATUS_QUEUE		ENDP



;;;;;;;;



CDC_WAIT_READY				PROC

							MOV		DX,IO_CDC_MASTER_STATUS
							MOV		EBX,8000000 ; 8 Meg
CDD_WAIT_READY_LOOP:
							DEC		EBX
							JE		CDC_WAIT_READY_TIMEOUT

							IN		AL,DX
							SHR		AL,1
							JNC		CDD_WAIT_READY_LOOP

							CLC
							RET

CDC_WAIT_READY_TIMEOUT:
							STC
							RET

CDC_WAIT_READY				ENDP



;;;;;;;;



CDC_DMA_RESET				PROC
							;MOV		AL,3	; Reset DMA Controller
							;OUT		IO_DMA_INITIALIZE,AL

							MOV		AX,20H	; DMA enable
							OUT		IO_DMA_DEVICE_CTRL_LOW,AX

							IN		AL,IO_DMA_MASK
							OR		AL,8
							OUT		IO_DMA_MASK,AL

							MOV		AL,3	; Channel 3 SCSI
							OUT		IO_DMA_CHANNEL,AL

							; Unless this mode is set, CPU will freeze when DTS flag is set.
							; Presumably CPU and DMA fights for memory bus.
							MOV		AL,44H		; Single-Mode (Free Bus every byte or word), IO to MEM (AUTOI 10H is off)
							OUT		IO_DMA_MODE_CONTROL,AL

							RET
CDC_DMA_RESET				ENDP



;;;;;;;;



; EDI=Physical Address
CDC_DMA_SET					PROC

							; Mask DMA
							IN		AL,IO_DMA_MASK
							OR		AL,08H
							OUT		IO_DMA_MASK,AL

							CALL	DEBUG_PALETTE_RED

							MOV		DX,IO_CDC_MASTER_CONTROL
							MOV		AL,42H ; Clear DEI, Enable SIRQ
							OUT		DX,AL

							MOV		AL,3	; Channel 3 SCSI
							OUT		IO_DMA_CHANNEL,AL

							MOV		EAX,EDI
							OUT		IO_DMA_ADDR_LOW,AX
							SHR		EAX,16
							OUT		IO_DMA_ADDR_MID_HIGH,AL
							MOV		AL,AH
							OUT		IO_DMA_ADDR_HIGH,AL

							MOV		AX,07FFH
							OUT		IO_DMA_COUNT_LOW,AX

							; Unmask DMA
							IN		AL,IO_DMA_MASK
							AND		AL,0F7H
							OUT		IO_DMA_MASK,AL

							MOV		DX,IO_CDC_TRANSFER_CONTROL
							MOV		AL,10H	; DTS (DMA Transfer Mode)

							CALL	DEBUG_PALETTE_PURPLE
							OUT		DX,AL ; Stopping Here.
							CALL	DEBUG_PALETTE_RED

							RET

CDC_DMA_SET					ENDP



;;;;;;;;



CDC_DMA_STOP				PROC
							IN		AL,IO_DMA_MASK
							OR		AL,08H
							OUT		IO_DMA_MASK,AL

							MOV		DX,IO_CDC_MASTER_CONTROL
							MOV		AL,42H	; Clear DEI, Enable SIRQ
							OUT		DX,AL

							; TBIOS is not doing it.  Probably unnecessary.
							; MOV		DX,IO_CDC_TRANSFER_CONTROL
							; XOR		AL,AL
							; OUT		DX,AL

							RET
CDC_DMA_STOP				ENDP



;;;;;;;;



CDC_DMA_WAIT_DMAE			PROC

							IN		AL,IO_DMA_STATUS
							AND		AL,8	; DMAE bit for CDC (DMA Ch 3) Non-zero means Terminal Count or DMA End
							JNE		SHORT CDC_DMA_WAIT_DMAE
							RET

CDC_DMA_WAIT_DMAE			ENDP



;;;;;;;;



CDC_DMA_CLEAR				PROC

							IN		AL,IO_DMA_MASK
							AND		AL,0FH
							OR		AL,02H
							OUT		IO_DMA_MASK,AL
							RET

CDC_DMA_CLEAR				ENDP



;;;;;;;;



CDC_READ_STATUS				PROC
							MOV		DX,IO_CDC_STATUS

							IN		AL,DX
							ROR		EAX,8
							IN		AL,DX
							ROR		EAX,8
							IN		AL,DX
							ROR		EAX,8
							IN		AL,DX
							ROR		EAX,8

							RET

CDC_READ_STATUS				ENDP



;;;;;;;;



CDC_PUSH_PARAMS				PROC

							MOV		DX,IO_CDC_PARAM
							MOV		ESI,OFFSET CDPARAM

							LODSB
							OUT		DX,AL
							OUT		IO_TIMER_1US_WAIT,AL
							LODSB
							OUT		DX,AL
							OUT		IO_TIMER_1US_WAIT,AL
							LODSB
							OUT		DX,AL
							OUT		IO_TIMER_1US_WAIT,AL
							LODSB
							OUT		DX,AL
							OUT		IO_TIMER_1US_WAIT,AL
							LODSB
							OUT		DX,AL
							OUT		IO_TIMER_1US_WAIT,AL
							LODSB
							OUT		DX,AL
							OUT		IO_TIMER_1US_WAIT,AL
							LODSB
							OUT		DX,AL
							OUT		IO_TIMER_1US_WAIT,AL
							LODSB
							OUT		DX,AL
							OUT		IO_TIMER_1US_WAIT,AL
							RET

CDC_PUSH_PARAMS				ENDP



;;;;;;;;



CDC_SHOOT_MODE1READ			PROC
							MOV		DX,IO_CDC_COMMAND
							MOV		AL,CDCCMD_MODE1READ
							OUT		DX,AL
							RET
CDC_SHOOT_MODE1READ			ENDP



;;;;;;;;



; TBIOS uses this command before reading sectors.
; Effect is undocumented and unknown.
CDC_UNDOCUMENTED_COMMAND_A0	PROC
							CALL	CDC_WAIT_READY

							MOV		DX,IO_CDC_PARAM
							MOV		AL,8
							OUT		DX,AL
							MOV		AL,1
							OUT		DX,AL
							XOR		AL,AL
							OUT		DX,AL
							OUT		DX,AL
							OUT		DX,AL
							OUT		DX,AL
							OUT		DX,AL
							OUT		DX,AL

							MOV		DX,IO_CDC_COMMAND
							MOV		AL,0A0H
							OUT		DX,AL

							CALL	DEBUG_PALETTE_GREEN

CDC_A0_WAIT_LOOP:
							MOV		DX,IO_CDC_MASTER_STATUS
							IN		AL,DX
							TEST	AL,2
							JE		CDC_A0_WAIT_LOOP

							CALL	DEBUG_PALETTE_CYAN

							MOV		DX,IO_CDC_STATUS
							IN		AL,DX
							IN		AL,DX
							IN		AL,DX
							IN		AL,DX

							RET

CDC_UNDOCUMENTED_COMMAND_A0	ENDP



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PRINT_AL				PROC
						PUSH	CX
						PUSH	AX

						CALL	ITOA8
						XCHG	AL,AH
						CALL	PUTC
						XCHG	AL,AH
						CALL	PUTC

						POP		AX
						POP		CX
						RET
PRINT_AL				ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PRINT_EAX				PROC

						ROL		EAX,8
						CALL	PRINT_AL
						ROL		EAX,8
						CALL	PRINT_AL
						ROL		EAX,8
						CALL	PRINT_AL
						ROL		EAX,8
						CALL	PRINT_AL
						RET

PRINT_EAX				ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PRINT_CRLF				PROC
						PUSH	AX
						MOV		AL,0DH
						CALL	PUTC
						MOV		AL,0AH
						CALL	PUTC
						POP		AX
						RET
PRINT_CRLF				ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PRINT_CSTR				PROC
						PUSH	DX
						PUSH	CX
						PUSH	AX
PRINT_CSTR_LOOP:
						MOV		DL,[EDI]
						CMP		DL,0
						JE		PRINT_CSTR_EXIT
						MOV		AH,06H
						INT		21H
						INC		EDI
						JMP		PRINT_CSTR_LOOP

PRINT_CSTR_EXIT:
						POP		AX
						POP		CX
						POP		DX
						RET

PRINT_CSTR				ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PUTC					PROC

						PUSH	AX
						PUSH	DX

						MOV		DL,AL
						MOV		AH,06H
						INT		21H

						POP		DX
						POP		AX

						RET

PUTC					ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Input
;	AL		Number
; Output
;	AH		Higher digit ASCII code
;	AL		Lower digit ASCII code
ITOA8					PROC

						MOV		AH,AL
						AND		AL,0FH
						SHR		AH,1
						SHR		AH,1
						SHR		AH,1
						SHR		AH,1

						ADD		AL,'0'
						CMP		AL,'9'
						JLE		ITOA8_LOWER_DONE
						ADD		AL,'A'-'0'-10
ITOA8_LOWER_DONE:
						ADD		AH,'0'
						CMP		AH,'9'
						JLE		ITOA8_DONE
						ADD		AH,'A'-'0'-10
ITOA8_DONE:
						RET

ITOA8					ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



DEBUG_PALETTE_BLUE		PROC
						PUSH	EAX
						MOV		EAX,000000F0H
						CALL	SET_PALETTE_BOTH_PAGES
						POP		EAX
						RET
DEBUG_PALETTE_BLUE		ENDP



DEBUG_PALETTE_RED		PROC
						PUSH	EAX
						MOV		EAX,0000F000H
						CALL	SET_PALETTE_BOTH_PAGES
						POP		EAX
						RET
DEBUG_PALETTE_RED		ENDP



DEBUG_PALETTE_PURPLE	PROC
						PUSH	EAX
						MOV		EAX,0000F0F0H
						CALL	SET_PALETTE_BOTH_PAGES
						POP		EAX
						RET
DEBUG_PALETTE_PURPLE	ENDP



DEBUG_PALETTE_GREEN		PROC
						PUSH	EAX
						MOV		EAX,00F00000H
						CALL	SET_PALETTE_BOTH_PAGES
						POP		EAX
						RET
DEBUG_PALETTE_GREEN		ENDP



DEBUG_PALETTE_CYAN		PROC
						PUSH	EAX
						MOV		EAX,00F000F0H
						CALL	SET_PALETTE_BOTH_PAGES
						POP		EAX
						RET
DEBUG_PALETTE_CYAN		ENDP



DEBUG_PALETTE_YELLOW	PROC
						PUSH	EAX
						MOV		EAX,00F0F000H
						CALL	SET_PALETTE_BOTH_PAGES
						POP		EAX
						RET
DEBUG_PALETTE_YELLOW	ENDP



DEBUG_PALETTE_WHITE		PROC
						PUSH	EAX
						MOV		EAX,00F0F0F0H
						CALL	SET_PALETTE_BOTH_PAGES
						POP		EAX
						RET
DEBUG_PALETTE_WHITE		ENDP



SET_PALETTE_BOTH_PAGES	PROC
						PUSH	EDX

						PUSH	EAX
						MOV		DX,0448H
						MOV		AL,1
						OUT		DX,AL

						MOV		DX,044AH
						MOV		AL,20H
						OUT		DX,AL
						POP		EAX

						PUSH	EAX
						CALL	SET_ALL_PALETTE
						POP		EAX

						PUSH	EAX
						MOV		DX,044AH
						MOV		AL,00H
						OUT		DX,AL
						POP		EAX

						PUSH	EAX
						CALL	SET_ALL_PALETTE
						POP		EAX

						POP		EDX
						RET
SET_PALETTE_BOTH_PAGES	ENDP



SET_ALL_PALETTE			PROC
						PUSH	EDX
						PUSH	EBX
						MOV		EBX,1
SET_ALL_PALETTE_LOOP:
						MOV		DX,0FD90H
						XCHG	EAX,EBX
						OUT		DX,AL
						XCHG	EAX,EBX

						MOV		DX,0FD92H
						OUT		DX,AL
						ROR		EAX,8

						MOV		DX,0FD94H
						OUT		DX,AL
						ROR		EAX,8

						MOV		DX,0FD96H
						OUT		DX,AL
						ROR		EAX,16

						INC		EBX
						CMP		EBX,15
						JLE		SET_ALL_PALETTE_LOOP

						POP		EBX
						POP		EDX
						RET
SET_ALL_PALETTE			ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



CODE						ENDS


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


DATA						SEGMENT

DMABUF_RUNWAY				DB		8192 dup (0CDh)
DMABUF_PTR					DD		0
DMABUF_PHYS					DD		0

CDPARAM						DB		0,2,0,  0,2,7, 0,0 ; From 00:02.00 to 00:02.07  First 8 sectors
CDSTATUS					DD		99999999h

DATABUF						DB		16384 dup (077h) ; buffer for 8 sectors times 2KB
DATA_STORE_PTR				DD		OFFSET DATABUF
LAST_DMA_COUNT				DW		0

MSG_PREMATURE				DB		'Premature Termination',0
MSG_IO_ERROR				DB		'IO Error',0
MSG_UNKNOWN_ERROR			DB		'Unknown Error',0
MSG_READ_DONE				DB		'Read Done',0
MSG_STATUS_TIMEOUT			DB		'Status Time Out',0
MSG_LAST_DMA_COUNT			DB		'Last DMA Count:',0

FILENAME					DB		'CDREAD.BIN',0

DATA						ENDS


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


STACK						SEGMENT
							DB		1024 dup(0)
STACK						ENDS

							END		MAIN
