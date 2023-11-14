						.386p
						ASSUME	CS:CODE

						PUBLIC	_CLI
						PUBLIC	_STI
						PUBLIC	GetDMACount
						PUBLIC	GetCS
						PUBLIC	GetINT46Handler
						PUBLIC	SetINT46Handler
						PUBLIC	SetUpDMA

CODE					SEGMENT



_CLI					PROC
						CLI
						RET
_CLI					ENDP



_STI					PROC
						STI
						RET
_STI					ENDP




GetDMACount				PROC
						IN		AX,0A2H
						MOVZX	EAX,AX
						RET
GetDMACount				ENDP




; GetINT46Handler(unsigned int *selector,unsigned int *EIP)
; [EBP]		Prev EBP
; [EBP+4]	EIP
; [EBP+8]	*selector
; [EBP+12]	*EIP
GetINT46Handler			PROC
						PUSH	EBP
						MOV		EBP,ESP
						PUSH	EBX
						PUSH	ECX
						PUSH	ES

						MOV		CL,46H
						MOV		AX,2502H
						INT		21H

						MOV		ECX,[EBP+8]
						MOV		[ECX],ES
						MOV		ECX,[EBP+12]
						MOV		[ECX],EBX

						POP		ES
						POP		ECX
						POP		EBX
						POP		EBP
						RET
GetINT46Handler			ENDP




GetCS					PROC
						MOV		AX,CS
						MOVZX	EAX,AX
						RET
GetCS					ENDP



; SetINT46Handler(unsigned int CS,void (*func)())
; [EBP]		Prev EBP
; [EBP+4]	EIP
; [EBP+8]	HandlerCS
; [EBP+12]	HandlerEIP
SetINT46Handler			PROC
						PUSH	EBP
						MOV		EBP,ESP
						PUSH	EDX
						PUSH	ECX
						PUSH	DS

						MOV		CL,46H
						MOV		EDX,[EBP+8]
						MOV		DS,DX
						MOV		EDX,[EBP+12]
						MOV		AX,2504H
						INT		21H

						POP		DS
						POP		ECX
						POP		EDX
						POP		EBP
						RET
SetINT46Handler			ENDP




;void SetUpDMA(unsigned int physAddr,unsigned int count);
;[ESP]		EIP
;[ESP+4]	physAddr
;[ESP+8]	count
SetUpDMA				PROC


; A1  Channel
; A2  Count
; AA  Mode/Control

						PUSHF
						CLI
						XOR  	AL,AL
						OUT  	0A1H,AL	; CHANNEL

						MOV		EAX,[EBP+4]
						OUT		0A4H,AX
						SHR		EAX,16
						OUT		0A6H,AL
						MOV		AL,AH
						OUT		0A7H,AL

						IN		AL,0AFH
						AND		AL,0FEH
						OUT		0AFH,AL

						MOV		AX,[EBP+8]
						OUT		0A2H,AX

						MOV		AL,44H
						OUT		0AAH,AL
						POPF

						RET

SetUpDMA				ENDP


CODE					ENDS
						END
