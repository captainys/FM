; DS:SI					Target Location
; DX					Target Length
; CX					Pattern Length
; ES:DI					Source Pattern
; ES:BX					Write Pattern
APPLY_PATCH				PROC

APPLY_PATCH_LOOP:
						PUSH	CX
						PUSH	SI
						PUSH	DI
						REPE	CMPSB
						POP		DI
						POP		SI
						POP		CX
						JE		APPLY_PATCH_FOUND

						INC		SI
						DEC		DX
						JNE		APPLY_PATCH_LOOP
						RET

APPLY_PATCH_FOUND:
						PUSH	DS
						PUSH	ES
						POP		DS
						POP		ES

						MOV		DI,SI  ; DS:SI becomes destination ES:DI
						MOV		SI,BX  ; ES:BX becomes source DS:SI

						REP		MOVSB
						RET

APPLY_PATCH				ENDP


