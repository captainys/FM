INITGRAPHICS			PROC

						MOV		DX,IO_FMR_GVRAMDISPMODE
						MOV		AL,27H  ; Show all planes, write to Page 0 (Page 0 is upper half of VRAM Layer 0)
						OUT		DX,AL

						MOV		DX,IO_FMR_GVRAMMASK
						MOV		AL,0FH  ; Write to all planes
						OUT		DX,AL

						RET

INITGRAPHICS			ENDP



CLS						PROC
						PUSH	ES
						PUSH	DI
						PUSH	AX
						PUSH	CX

						MOV		AX,0C000H
						MOV		ES,AX
						MOV		DI,0
						MOV		CX,80*400/2
						MOV		AX,0
						REP STOSW

						POP		CX
						POP		AX
						POP		DI
						POP		ES
						RET
CLS						ENDP



CLEAR_FIVE_BELOW		PROC
						PUSH	ES
						PUSH	DI
						PUSH	AX
						PUSH	CX

						MOV		AX,0C000H
						MOV		ES,AX
						MOV		DI,80*5*16
						MOV		CX,80*20*16/2
						MOV		AX,0
						REP STOSW

						POP		CX
						POP		AX
						POP		DI
						POP		ES
						RET
CLEAR_FIVE_BELOW		ENDP



; Input
;   AL Color (0-15)
; DX will be destroyed.
COLOR					PROC
						AND		AL,0FH
						MOV		DX,IO_FMR_GVRAMMASK
						OUT		DX,AL
						RET
COLOR					ENDP


; Input
; AH      X
; AL      Y
; Output
; DI      VRAM Address
LOCATE					PROC
						PUSH	AX
						PUSH	CX

						MOVZX	DI,AH

						MOV		CX,80*16
						XOR		AH,AH
						MUL		CX

						ADD		DI,AX

						POP		CX
						POP		AX
						RET
LOCATE					ENDP



; DI:  VRAM ADDRESS
; AH:  ASCII Code
; C0000H must be in FM-R VRAM mode.
DRAWFONT				PROC
						PUSH	DS
						SUB		SP,8

						MOV		DX,0C000H
						MOV		DS,DX

						MOV		DX,IO_KVRAM_OR_ANKFONT
						MOV		AL,1
						OUT		DX,AL

						; ANK Font ROM CA000H-
						MOV		AL,8
						MUL		AH
						ADD		AX,0A000H

						MOV		CX,8
						MOV		SI,AX
@@:
						MOV		DH,DS:[SI]
						MOV		[DI],DH
						INC		SI
						ADD		DI,50H
						LOOP	@b

						ADD		SP,8
						POP		DS
						RET
DRAWFONT				ENDP



; DI:  VRAM ADDRESS
; AH:  ASCII Code
; C0000H must be in FM-R VRAM mode.
; BX preserved
; DS preserved
DRAWFONT_TALL			PROC
						PUSH	DS
						SUB		SP,8

						MOV		DX,0C000H
						MOV		DS,DX

						MOV		DX,IO_KVRAM_OR_ANKFONT
						MOV		AL,1
						OUT		DX,AL

						; ANK Font ROM CA000H-
						MOV		AL,8
						MUL		AH
						ADD		AX,0A000H

						MOV		CX,8
						MOV		SI,AX
@@:
						MOV		DH,DS:[SI]
						MOV		[DI],DH
						MOV		[DI+50H],DH
						INC		SI
						ADD		DI,0A0H
						LOOP	@b

						ADD		SP,8
						POP		DS
						RET
DRAWFONT_TALL			ENDP



; Input
;   DS:SI     String
;   DI        VRAM Address
PRINT_TALL				PROC
						PUSH	ES
						PUSH	AX

						MOV		AX,0C000H
						MOV		ES,AX
						MOV		BX,SI
@@:
						MOV		SI,BX
						LODSB
						CMP		AL,0
						JE		@f
						MOV		AH,AL
						CALL	DRAWFONT_TALL
						ADD		DI,1-80*16
						ADD		BX,1
						JMP		@b
@@:

						POP		AX
						POP		ES
						RET
PRINT_TALL				ENDP



; Input
;   DI   First address of the line
;        DI will be destroyed
ERASE_LINE_TALL			PROC

						PUSH	ES
						PUSH	AX
						PUSH	CX

						MOV		AX,0C000H
						MOV		ES,AX

						XOR		AX,AX
						MOV		CX,80*16/2
						REP STOSW

						POP		CX
						POP		AX
						POP		ES
						RET

ERASE_LINE_TALL			ENDP
