

VRAMMODE				PROC
						PUSH	DX
						PUSH	AX
						MOV		DX,IO_FMR_VRAM_OR_MAINRAM
						MOV		AL,0
						OUT		DX,AL
						POP		AX
						POP		DX
						RET
VRAMMODE				ENDP


RAMMODE					PROC
						PUSH	DX
						PUSH	AX
						MOV		DX,IO_FMR_VRAM_OR_MAINRAM
						MOV		AL,80H
						OUT		DX,AL
						POP		AX
						POP		DX
						RET
RAMMODE					ENDP



