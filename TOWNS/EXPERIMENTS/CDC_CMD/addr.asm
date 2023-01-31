						.386p
						ASSUME	CS:CODE

						PUBLIC	TOPHYSICAL

CODE					SEGMENT

; extern unsigned int TOPHYSICAL(void *ptr);

TOPHYSICAL				PROC
; [EBP+8]  Offset to DS
; [EBP+4]  EIP
; [EBP]    Last EBP

						PUSH	EBP
						MOV		EBP,ESP
						PUSH	EBX
						PUSH	ECX


						MOV		BX,DS
						MOV		AX,2508H
						INT		21H

						; ECX=Linear Base Address of DS

						MOV		EBX,[EBP+8]
						ADD		EBX,ECX
						MOV		AX,2509H
						INT		21H

						; ECX=Physical Address

						MOV		EAX,ECX

						POP		ECX
						POP		EBX
						POP		EBP
						RET

TOPHYSICAL				ENDP


CODE					ENDS
						END

