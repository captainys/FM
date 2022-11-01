						ASSUME	CS:CODE,DS:DATA

						PUBLIC	ALLOC_4KB_PAGE
						PUBLIC	TO_PHYSICAL
						PUBLIC	MASKIRQ
						PUBLIC	UNMASKIRQ
						PUBLIC	GETFDCSTA
						PUBLIC	GETDRVSTA

						PUBLIC	TAKEOVER_INT46
						PUBLIC	RESTORE_INT46
						PUBLIC	GET_LAST_FDC_STATUS
						PUBLIC	CLEAR_IRQ_FLAG
						PUBLIC	GET_IRQ_FLAG


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


MASKIRQ					PROC
						CLI
						RET
MASKIRQ					ENDP


UNMASKIRQ				PROC
						STI
						RET
UNMASKIRQ				ENDP


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
;   Pointer to eip
;   Pointer to segment selector
;   Pointer to real-mode handler
; Return
;   Segment and eip of the previous IRQ Handler
TAKEOVER_INT46			PROC
						PUSH	EBP
						MOV		EBP,ESP
						PUSH	ECX
						PUSH	EDX
						PUSH	EDI
						PUSH	DS
						PUSH	ES

						MOV		CL,46H	; INT 46H FDC
						MOV		AX,2502H	; Get Protected-mode INT vector
						INT		21H

						MOV		EDI,[EBP+8]
						MOV		[EDI],EBX
						MOV		EDI,[EBP+12]
						MOV		[EDI],ES

						MOV		CL,46H	; INT 46H FDC
						MOV		AX,2503h	; Get Real-mode INT vector
						INT		21H

						MOV		EDI,[EBP+16]
						MOV		[EDI],EBX


						MOV		CL,46H
						PUSH	CS
						POP		DS
						MOV		EDX,OFFSET HANDLE_INT46
						MOV		AX,2506H	; Native Mode Handle, even when INT happened in real mode.
						INT		21H

						POP		ES
						POP		DS
						POP		EDI
						POP		EDX
						POP		ECX
						POP		EBP
						RET
TAKEOVER_INT46			ENDP

; Input
;   eip
;   SEG
;   Real-Mode Handler
RESTORE_INT46			PROC
						PUSH	EBP
						MOV		EBP,ESP
						PUSH	ECX
						PUSH	EDX
						PUSH	EDI
						PUSH	DS

						MOV		EDX,[EBP+8]
						MOV		DS,[EBP+12]
						MOV		CL,46H
						MOV		AX,2504H
						INT		21H

						MOV		EBX,[EBP+16]
						MOV		CL,46H
						MOV		AX,2505h
						INT		21H

						POP		DS
						POP		EDI
						POP		EDX
						POP		ECX
						POP		EBP
						RET
RESTORE_INT46			ENDP



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
