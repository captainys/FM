						.386p
						ASSUME	CS:CODE

						PUBLIC	GetDMACount
						PUBLIC	GetCS
						PUBLIC	GetINT46Handler
						PUBLIC	SetINT46Handler
						PUBLIC	SetUpDMAIn
						PUBLIC	SetUpDMAOut
						PUBLIC	Tsugaru_Debug

CODE					SEGMENT



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




;void SetUpDMAIn(unsigned int physAddr,unsigned int count);
;[ESP]		EFLAGS
;[ESP+4]	EIP
;[ESP+8]	physAddr
;[ESP+12]	count
SetUpDMAIn				PROC


; A1  Channel
; A2  Count
; AA  Mode/Control

						PUSHFD
						CLI
						XOR  	AL,AL
						OUT  	0A1H,AL	; CHANNEL

						MOV		EAX,[ESP+8]
						OUT		0A4H,AX
						SHR		EAX,16
						OUT		0A6H,AL
						MOV		AL,AH
						OUT		0A7H,AL

						IN		AL,0AFH
						AND		AL,0FEH
						OUT		0AFH,AL

						MOV		AX,[ESP+12]
						OUT		0A2H,AX

						MOV		AL,44H
						OUT		0AAH,AL
						POPFD

						RET

SetUpDMAIn				ENDP



;void SetUpDMAOut(unsigned int physAddr,unsigned int count);
;[ESP]		EFLAGS
;[ESP+4]	EIP
;[ESP+8]	physAddr
;[ESP+12]	count
SetUpDMAOut				PROC


; A1  Channel
; A2  Count
; AA  Mode/Control

						PUSHFD
						CLI
						XOR  	AX,AX
						OUT  	0A1H,AL	; CHANNEL

						MOV		AX,0020H
						OUT		0A8H,AX

						MOV		AL,48H
						OUT		0AAH,AL

						IN		AL,0AFH
						OR		AL,01H   ; Mask FDC DMACh
						OUT		0AFH,AL

						MOV		EAX,[ESP+8]
						OUT		0A4H,AX
						SHR		EAX,16
						OUT		0A6H,AL
						MOV		AL,AH
						OUT		0A7H,AL

						MOV		AX,[ESP+12]
						OUT		0A2H,AX

						IN		AL,0AFH
						AND		AL,0FEH
						OUT		0AFH,AL   ; Enable FDC DMACh

						POPFD

						RET

SetUpDMAOut				ENDP



Tsugaru_Debug			PROC
						PUSH	EBP
						MOV		EBP,ESP
						PUSH	EDX
						PUSH	EBX

						MOV		DX,2F12H	; TOWNSIO_VNDRV_ENABLE
						MOV		AL,1
						OUT		DX,AL		; Enable VNDRV


						MOV		EBX,[EBP+8]
						MOV		DX,2F18H	; TOWNSIO_VNDRV_AUXCOMMAND
						MOV		AL,09H		; TOWNS_VNDRV_AUXCMD_PRINTCSTR
						OUT		DX,AL

						POP		EBX
						POP		EDX
						POP		EBP
						RET
Tsugaru_Debug			ENDP


CODE					ENDS
						END
