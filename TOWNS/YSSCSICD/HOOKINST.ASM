INT93_REAL_IDT_OFFSET	EQU		(93H*4)

; AL SCSI ID
INSTALL_HOOK_DIRECT		PROC
						PUSHF
						PUSH	DS
						PUSH	EAX

						CLI		; Just in case.  INT 93H is not supposed to happen while redirecting.

						MOV		CS:[YSSCSICD_SCSI_ID],AL

						XOR		AX,AX
						MOV		DS,AX
						MOV		EAX,DS:[INT93_REAL_IDT_OFFSET]	; INT Vector for INT 93H
						MOV		DWORD PTR CS:[INT93_TOWNS],EAX

						MOV		AX,CS
						ROL		EAX,16
						MOV		AX,OFFSET INT93H_HOOKPROC
						MOV		DWORD PTR DS:[INT93_REAL_IDT_OFFSET],EAX

						POP		EAX
						POP		DS
						POPF
						RETF
INSTALL_HOOK_DIRECT		ENDP



INSTALL_HOOK			PROC
						PUSH	ES

						MOV		AX,3593H
						; AH=35H    Get IRQ vector
						; AL=93H    for INT 93H
						INT		21H

						MOV		WORD PTR CS:[INT93_TOWNS],BX
						MOV		WORD PTR CS:[INT93_TOWNS+2],ES

						PUSH	CS
						POP		ES
						MOV		DX,OFFSET INT93H_HOOKPROC

						MOV		AX,2593H
						; AH=25H    Set IRQ vector
						; AL=93H    for INT 93H
						INT		21H


						POP		ES
						RET
INSTALL_HOOK			ENDP
