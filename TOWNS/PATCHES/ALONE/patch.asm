						.386p
						ASSUME	CS:CODE
; Start:
;   060H bytes: Not yet confirmed to work.
; By not using EBP:
;   05FH bytes: Not yet confirmed to work.
; By using DL to remember low 4-bit in BCD2BIN_LOOP
;   05DH bytes: Not yet confirmed to work.
; By not setting ES on INT 21H AX=2511H
;   056H bytes: Not yet confirmed to work.
; By not setting HIWORD or EAX on INT 21H AX=2511H
;   055H bytes: Not yet confirmed to work.
; By INT 93H, AX=52C0H when ECX happens to be zero
;   052H bytes: Not yet confirmed to work.

CODE					SEGMENT

						ORG		0000E562H

CDDAPLAY				PROC

						; Assumption: DS:ESI`  6 bytes BCD Start time and End time
						;             Non-zero CALLBUFS

						; All segment registers are preserved.
						; D(irection) flag is preserved.
						; All registers except EBP destroyed.

						PUSH	EBP
						MOV		EBP,ESP
						PUSH	EBX
						PUSH	ESI

						PUSH	ES		; SS:ESP {ES}
						PUSH	DS

						MOVZX	EBX,Word Ptr [EBP+8]
						LEA		EBX,[EBX+EBX*2]
						MOV		ESI,DS:[00016A2CH]
						LEA		ESI,[EBX+ESI+9]
						MOV		AX,DS:[00016A28H]
						MOV		DS,AX


						; DOS-Extender Get Real-Mode Link Information
						MOV		AX,250DH
						INT		21H
						; EAX     CS:IP in real mode.  Don't need.
						; EBX     Real-mode address of the call data buffer
						; ES:EDX  Protected Mode adress of call data buffer


						PUSHF			; SS:ESP {ES,EFLAGS}
						MOV		ECX,6
						MOV		EDI,EDX		; EDX is done.
						CLD
BCD2BIN_LOOP:			LODSB

						; BCD to BIN >>
						MOV		DL,AL
						AND		DL,0FH
						SHR		AL,4
						MOV		AH,10
						MUL		AH
						ADD		AL,DL
						; BCD to BIN <<

						STOSB
						LOOP	BCD2BIN_LOOP
						POPF			; SS:ESP {ES}

						; ECX=0 on exit.

						; CD-ROM BIOS CDDASTOP
						MOV		AX,52C0H
						; XOR		ECX,ECX    ECX is already 0.
						INT		93H
						; Return AH,CX.  Don't care.
						; If error, CX may be destroyed, but if error at this time,
						; it doesn't matter for the subsequent CDDAPLAY command.


						; Once start and end times are transferred,
						; it's ok to forget where it is coming from.

						; Also EDI won't matter because what matters is the REAL MODE address at this point.


						MOV		EDI,EBX		; DI=Real Mode Offset

						SHR		EBX,16		; BX=Real Mode Segment

						PUSH	SS			; SS:ESP {ES,DS,SS}
						POP		DS			; DS=SS   SS:ESP {ES,DS}
						SUB		ESP,12H
						MOV		EDX,ESP

						MOV		 WORD PTR DS:[EDX],0093H		; INT Number
						MOV		DWORD PTR DS:[EDX+2],EBX		; DS (DWORD PTR EBX is shorter than WORD PTR BX)
						; MOV		 WORD PTR DS:[EDX+4],0		; ES  Don't care.
						; MOV		 WORD PTR DS:[EDX+6],0		; FS  Don't care.
						; MOV		 WORD PTR DS:[EDX+8],0		; GS  Don't care.
						MOV		 WORD PTR DS:[EDX+0AH],50C0H	; AX CDDAPlay
						; MOV		 WORD PTR DS:[EDX+0CH],0	; HIWORD of EAX  Don't care
						; MOV	DWORD PTR DS:[EDX+0EH],0  		; EDX  Don't care.
						INC		ECX			; ECX=1

						MOV		AX,2511H
						INT		21H

						ADD		ESP,12H


EXIT:
						POP		DS			; SS:ESP {ES}
						POP		ES			; SS:ESP {}

						POP		ESI
						POP		EBX
						LEAVE
						RET


CDDAPLAY				ENDP
CODE					ENDS
						END

