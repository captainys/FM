						.386p
						ASSUME	CS:CODE

						PUBLIC	ToPhysicalAddr
						PUBLIC	MapToEndOfDS

CODE					SEGMENT


TSUGARU_DEBUG_BREAK			MACRO
							PUSH	AX
							PUSH	DX
							MOV		AL,02H   ; TOWNS_VMIF_CMD_PAUSE
							MOV		DX,2386H ; TOWNSIO_VM_HOST_IF_CMD_STATUS
							OUT		DX,AL
							POP		DX
							POP		AX
							ENDM


; unsigned int ToPhysicalAddr(void *ptr);
; [EBP]		Prev EBP
; [EBP+4]	EIP
; [EBP+8]	ptr
;
ToPhysicalAddr			PROC
						PUSH	EBP
						MOV		EBP,ESP
						PUSH	EBX
						PUSH	ECX
						PUSH	EDX

						MOV		BX,DS
						MOV		AX,2508H
						INT		21H
						; Output ECX=Linear Base Address

						ADD		ECX,[EBP+8]
						MOV		EBX,ECX
						MOV		AX,2509H
						INT		21H
						; Output ECX=Physical Address
						MOV		EAX,ECX

						POP		EDX
						POP		ECX
						POP		EBX
						POP		EBP

						RET

ToPhysicalAddr			ENDP



; unsigned char *MapToEndOfDS(unsigned int physAddr,unsigned int numPages);
; [EBP]		Prev EBP
; [EBP+4]	EIP
; [EBP+8]	physAddr
; [EBP+12]	numPages
MapToEndOfDS			PROC
						PUSH	EBP
						MOV		EBP,ESP
						PUSH	ES
						PUSH	EBX
						PUSH	ECX

						TSUGARU_DEBUG_BREAK

						PUSH	DS
						POP		ES
						MOV		EBX,[EBP+8]
						MOV		ECX,[EBP+12]
						MOV		AX,250AH
						INT		21H
						; Output EAX=offset to ES

						POP		ECX
						POP		EBX
						POP		ES
						POP		EBP
						RET
MapToEndOfDS			ENDP



CODE					ENDS
						END
