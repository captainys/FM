						.386p
						ASSUME	CS:CODE,DS:DATA

						PUBLIC	ALLOC_4KB_PAGE
						PUBLIC	TO_PHYSICAL
						PUBLIC	_CLI
						PUBLIC	_STI
						PUBLIC	GETFDCSTA
						PUBLIC	GETDRVSTA

						PUBLIC	GET_LAST_FDC_STATUS
						PUBLIC	CLEAR_IRQ_FLAG
						PUBLIC	GET_IRQ_FLAG

						PUBLIC	FDC_EXEC_COMMAND


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IO_FDC_STATUS			EQU		200h
FDCSTA_BUSY				EQU		01h
FDCSTA_INDEX			EQU		02h

IOERR_CRC				EQU		8
IOERR_RECORD_NOT_FOUND	EQU		10h
IOERR_DELETED_DATA		EQU		20h
IOERR_LOST_DATA			EQU		04h

IO_PIC0_IRR				EQU		00h
IO_PIC0_OCW3			EQU		00h
IRR_FDC					EQU		40h

IO_FDC_COMMAND			EQU		200h
FDCCMD_RESTORE			EQU		008h
FDCCMD_SEEK				EQU		018h
FDCCMD_READADDR			EQU		0C0h
FDCCMD_READSECTOR		EQU		080h
FDCCMD_FORCEINTERRUPT	EQU		0D0h

IO_FDC_CYLINDER			EQU		202h
IO_FDC_SECTOR			EQU		204h
IO_FDC_DATA				EQU		206h

IO_FDC_DRIVE_STATUS		EQU		0208h
DRIVE_STA_FREADY		EQU		02h

IO_FDC_DRIVE_CONTROL	EQU		0208h
IO_FDC_DRIVE_SELECT		EQU		020Ch

IO_1US_WAIT				EQU		06Ch

IO_DMA_INITIALIZE		EQU		0A0h
IO_DMA_CHANNEL			EQU		0A1h
IO_DMA_COUNT_LOW		EQU		0A2h
IO_DMA_COUNT_HIGH		EQU		0A3h
IO_DMA_ADDR_LOW			EQU		0A4h
IO_DMA_ADDR_MID_LOW		EQU		0A5h
IO_DMA_ADDR_MID_HIGH	EQU		0A6h
IO_DMA_ADDR_HIGH		EQU		0A7h
IO_DMA_DEVICE_CTRL_LOW	EQU		0A8h
IO_DMA_DEVICE_CTRL_HIGH	EQU		0A9h
IO_DMA_MODE_CONTROL		EQU		0AAh
IO_DMA_STATUS			EQU		0ABh
IO_DMA_REQUEST			EQU		0AEh
IO_DMA_MASK				EQU		0AFh

TSUGARU_DEBUG_BREAK		MACRO
						PUSH	EAX
						PUSH	EDX
						MOV		DX,2386H
						MOV		AL,2
						OUT		DX,AL
						POP		EDX
						POP		EAX
						RET
						ENDM

SET_PIC_POLLING_MODE	MACRO
						MOV		DX,IO_PIC0_OCW3
						MOV		AL,0Eh
						OUT		DX,AL		; Set POLLING mode, REG0 is IRR
						OUT		DX,AL		; Set POLLING mode, REG0 is IRR
						ENDM

CLEAR_PIC_POLLING_MODE	MACRO
						MOV		DX,IO_PIC0_OCW3
						MOV		AL,0Ah
						OUT		DX,AL		; Clear POLLING mode.
						OUT		DX,AL		; Clear POLLING mode.
						ENDM


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CODE					SEGMENT

; Input: None
; Output: Physical Address Mapped to the end of DS
ALLOC_4KB_PAGE			PROC

						PUSH	ES
						PUSH	EBX
						PUSH	ECX

						MOV		EBX,1
						MOV		AH,48H
						INT		21H


						MOVZX	EBX,AX
						MOV		AX,2508h			; Get Segment Linear Base
						INT		21H

						MOV		EBX,ECX
						MOV		AX,2509h			; Linear Address to Physical Address
						INT		21H

						PUSH	DS
						POP		ES
						MOV		EBX,ECX
						MOV		ECX,1
						MOV		AX,250Ah
						INT		21H

						; Will be called once.  Just forget about wasting one LDT.

						POP		ECX
						POP		EBX
						POP		ES
						RET

ALLOC_4KB_PAGE			ENDP



; Input: Pointer
; Output: Physical Address
TO_PHYSICAL				PROC
; [EBP]		Prev EBP
; [EBP+4]	Return EIP
; [EBP+8]	Address

						PUSH	EBP
						MOV		EBP,ESP
						PUSH	EBX
						PUSH	ECX
						PUSH	EDX
						PUSH	ESI
						PUSH	EDI

						MOV		BX,DS
						MOV		AX,2508h			; Get Segment Linear Base
						INT		21H

						ADD		ECX,[EBP+8]
						MOV		EBX,ECX
						MOV		AX,2509h			; Linear Address to Physical Address
						INT		21H

						MOV		EAX,ECX

						POP		EDI
						POP		ESI
						POP		EDX
						POP		ECX
						POP		EBX
						POP		EBP
						RET
TO_PHYSICAL				ENDP


_CLI					PROC
						CLI
						RET
_CLI					ENDP


_STI					PROC
						STI
						RET
_STI					ENDP


GETFDCSTA				PROC
						PUSH	EDX
						PUSHF
						CLI
						MOV		DX,0200h
						IN		AL,DX		; MX BIOS does it.  Reason unknown.
						IN		AL,DX
						MOVZX	EAX,AL
						POPF
						POP		EDX
						RET
GETFDCSTA				ENDP


GETDRVSTA				PROC
						PUSH	EDX
						PUSHF
						CLI
						MOV		DX,0208h
						IN		AL,DX		; MX BIOS does it.  Reason unknown.
						IN		AL,DX
						IN		AL,DX
						MOVZX	EAX,AL
						POPF
						POP		EDX
						RET
GETDRVSTA				ENDP



; Input
;   First Param		FDC Command
FDC_EXEC_COMMAND		PROC
; [ESP]		EFLAGS
; [ESP+4]	EDX
; [ESP+8]	EIP
; [ESP+12]	FDC COMMAND
						PUSH	EDX
						PUSHFD
						CLI

						SET_PIC_POLLING_MODE

						CALL	FDC_WAIT_READY

						MOV		DX,IO_FDC_COMMAND
						MOV		AL,[ESP+12]
						OUT		DX,AL

						CALL	FDC_WAIT_IRQ

						MOV		DX,IO_FDC_STATUS
						IN		AL,DX
						MOVZX	EAX,AL

						PUSH	EAX

						MOV		DX,IO_FDC_COMMAND
						MOV		AL,FDCCMD_FORCEINTERRUPT
						OUT		DX,AL

						CALL	FDC_WAIT_READY

						CLEAR_PIC_POLLING_MODE

						POP		EAX

						POPFD
						POP		EDX
						RET
FDC_EXEC_COMMAND		ENDP



; Return
;   AL  FDC Status when BUSY flag is off
;	DX  IO_FDC_STATUS
FDC_WAIT_READY			PROC
						MOV		DX,IO_FDC_STATUS

FDC_WAIT_READY_LOOP:	IN		AL,DX
						AND		AL,1
						JNE		FDC_WAIT_READY_LOOP

						RET
FDC_WAIT_READY			ENDP



; Input
;   PIC must be set to the polling mode.
; Return
;   AL  IRR
;	DX  IO_PIC0_IRR
FDC_WAIT_IRQ			PROC

						MOV		DX,IO_PIC0_IRR
						IN		AL,DX
						AND		AL,IRR_FDC
						JE		FDC_WAIT_IRQ

						RET
FDC_WAIT_IRQ			ENDP



GET_LAST_FDC_STATUS		PROC
						MOV		EAX,DS:[LAST_FDC_STATUS]
						RET
GET_LAST_FDC_STATUS		ENDP




; This is what Disk BIOS does in the INT handler.
;03A4:00000D9B 68FD0C                    PUSH    WORD PTR 0CFDH
;03A4:00000D9E 1F                        POP     DS
;03A4:00000D9F A05704                    MOV     AL,[0457H]      Probably the current drive
;03A4:00000DA2 E8A0F7                    CALL    00000545
;	03A4:00000545 B402                      MOV     AH,02H
;	03A4:00000547 F6E4                      MUL     AH
;	03A4:00000549 05D204                    ADD     AX,04D2H
;	03A4:0000054C 8BF8                      MOV     DI,AX
;	03A4:0000054E 8B35                      MOV     SI,[DI]      SI is a structure for the current drive.
;	03A4:00000550 C3                        RET
;03A4:00000DA5 E895FE                    CALL    00000C3D
;	03A4:00000C3D E8A6FF                    CALL    00000BE6
;		03A4:00000BE6 BA0002                    MOV     DX,0200H
;		03A4:00000BE9 EC                        IN      AL,DX
;		03A4:00000BEA C3                        RET
;	03A4:00000C40 32E4                      XOR     AH,AH
;	03A4:00000C42 A35304                    MOV     [0453H],AX
;	03A4:00000C45 C606870400                MOV     BYTE PTR [0487H],00H
;	03A4:00000C4A BA0002                    MOV     DX,0200H
;	03A4:00000C4D B0D0                      MOV     AL,D0H
;	03A4:00000C4F EE                        OUT     DX,AL
;	03A4:00000C50 9C                        PUSHF
;	03A4:00000C51 FA                        CLI
;	03A4:00000C52 E89100                    CALL    00000CE6
;		03A4:00000CE6 E4AF                      IN      AL,AFH (DMAC_MASK)
;		03A4:00000CE8 0C01                      OR      AL,01H
;		03A4:00000CEA E6AF                      OUT     AFH,AL (DMAC_MASK)
;		03A4:00000CEC C3                        RET
;	03A4:00000C55 9D                        POPF
;	03A4:00000C56 C3                        RET
;03A4:00000DA8 CB                        RETF
HANDLE_INT46			PROC
						PUSH	EAX
						PUSH	EDX
						PUSH	DS
						PUSHF

						MOV		AX,0014H
						MOV		DS,AX

						MOV		DX,0200H ; FDC Status
						IN		AL,DX
						MOVZX	EAX,AL
						MOV		[LAST_FDC_STATUS],EAX

						MOV		AL,0D0H
						OUT		DX,AL

						CLI
						IN		AL,0AFH	; DMAC_MASK
						OR		AL,1	; Mask Floppy Disk Channel (Channel 0)
						OUT		0AFH,AL	; DMAC_MASK

						POPF
						POP		DS
						POP		EDX
						POP		EAX
						IRET
HANDLE_INT46			ENDP



CLEAR_IRQ_FLAG			PROC
						XOR		EAX,EAX
						MOV		[IRQ_DID_COME_IN],EAX
						RET
CLEAR_IRQ_FLAG			ENDP



GET_IRQ_FLAG			PROC
						MOV		EAX,[IRQ_DID_COME_IN]
						RET
GET_IRQ_FLAG			ENDP



CODE					ENDS


DATA					SEGMENT
IRQ_DID_COME_IN			DD		0
LAST_FDC_STATUS			DD		0
DATA					ENDS

						END
