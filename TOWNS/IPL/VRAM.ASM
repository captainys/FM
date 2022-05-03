; Use one in RDHIGH.ASM
; GDT_BACKUP				DW		0
;						DD		0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VRAMGDT_INFO			DW		VRAMGDT_END-VRAMGDT_BEGIN-1
VRAMGDT_ADDR			DD		0	; Sounds like a linear address

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VRAMADDR_HIGH			EQU		80H
VRAMADDR_MIDHIGH		EQU		00H
VRAMADDR_MIDLOW			EQU		00H
VRAMADDR_LOW			EQU		00H

VRAM_BYTES_PER_LINE		DD		512

VRAMGDT_BEGIN			DD		0,0			; Table 0.  Not used?
						; It must make a flat 32-bit descriptor.
						; https://wiki.osdev.org/Unreal_Mode
						DB		0FFH,0FFH	; Segment Limit (0-15)
VRAMGDT_BASE_LOW		DB		VRAMADDR_LOW			; Base Address 0-7
VRAMGDT_BASE_MIDLOW		DB		VRAMADDR_MIDLOW			; Base Address 8-15
VRAMGDT_BASE_MIDHIGH	DB		VRAMADDR_MIDHIGH		; Base Address 16-23
						DB		10010010B	; P=1, DPL=00, S=1, TYPE=0010
						DB		11000111B	; G=1, DB=1, (Unused)=0, A=0, LIMIT 16-19=0011
VRAMGDT_BASE_HIGH		DB		VRAMADDR_HIGH			; Base Address 24-31
VRAMGDT_END				DB		0	; Dummy

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LOCATE31K				PROC

						PUSH	EAX
						PUSH	ECX

						MOVZX	DI,AH
						MOVZX	EDI,DI
						SHL		EDI,2

						MOV		ECX,DWORD PTR CS:[VRAM_BYTES_PER_LINE]
						SHL		ECX,4

						XOR		AH,AH
						MOVZX	EAX,AX
						MUL		ECX

						ADD		EDI,EAX

						POP		ECX
						POP		EAX
						RET

						
LOCATE31K				ENDP


; INPUT
;   AX LOCATION
;   SI 0FFH-TERMINATED SEQUENCE OF C-STRINGS
DRAW_TEXT31K			PROC

						PUSH	AX
						PUSH	SI
						PUSH	EDI
						CALL	LOCATE31K
						CALL	WRSTRING_WHITE_HIGH
						POP		EDI
						POP		SI
						POP		AX

@@:
						CMP		BYTE PTR DS:[SI],0
						JE		SHORT @f
						INC		SI
						JMP		@b

@@:
						INC		SI
						INC		AL

						CMP		BYTE PTR [SI],0FFH
						JNE		DRAW_TEXT31K

						RET
DRAW_TEXT31K			ENDP


; Input
;   EDI Physical Address (Low 24-bits)
; Output
;   GDT Prepared
;   DS=CS
;   EBX Destroyed
;   EDI Zero
WRHIGH_SETUP_GDT		PROC
						; Don't destroy ECX
						MOV		EBX,EDI

						MOV		WORD PTR [VRAMGDT_BASE_LOW],BX
						SHR		EBX,16
						MOV		BYTE PTR [VRAMGDT_BASE_MIDHIGH],BL

						MOV		BX,CS
						MOVZX	EBX,BX
						SHL		EBX,4
						ADD		EBX,OFFSET VRAMGDT_BEGIN
						MOV		DWORD PTR [VRAMGDT_ADDR],EBX

						XOR		EDI,EDI

						SGDT	FWORD PTR [GDT_BACKUP]
						LGDT	FWORD PTR [VRAMGDT_INFO]

						RET
WRHIGH_SETUP_GDT		ENDP



; Input
;   DS:SI	C-String
;   EDI		VRAM OFFSET
WRSTRING_WHITE_HIGH		PROC
						PUSH	DX
						MOV		DH,0FH;
						CALL	WRSTRING_HIGH
						POP		DX
						RET
WRSTRING_WHITE_HIGH		ENDP

; Input
;   DS:SI	C-String
;   DH		Color
;   EDI		VRAM OFFSET
WRSTRING_HIGH			PROC
						PUSH	FS
						PUSH	ES
						PUSH	DS
						PUSHAD
						PUSHF

						PUSH	DX

						PUSH	DS
						POP		FS
						MOV		BP,SI	; Save pointer to string in FS:BP

						PUSH	CS
						POP		DS

						CALL	WRHIGH_SETUP_GDT

						MOV		DX,IO_KVRAM_OR_ANKFONT
						MOV		AL,1
						OUT		DX,AL


						POP		DX	; Recover DH

						CLI

						MOV		AX,0C000H
						MOV		DS,AX
						; ANK Font ROM CA000H-

						MOV		EAX,CR0
						PUSH	EAX
						OR		AL,1
						MOV		CR0,EAX


						; https://wiki.osdev.org/Unreal_Mode suggest one jump "to tell 386/486 not to crash".
						JMP		SHORT @f
@@:


						; Quote from https://www.felixcloutier.com/x86/lgdt:lidt
						; They are the only instructions that directly load a linear address 
						; (that is, not a segment-relative address) and a limit in protected mode.
						MOV		BX,8	; Descriptor 1
						MOV		ES,BX

WRFONTHIGH_OUTMOST_LOOP:
						MOV		AH,FS:[BP]
						INC		BP
						AND		AH,AH
						JE		WRFONTHIGH_LOOP_OUT

						MOV		AL,8
						MUL		AH
						ADD		AX,0A000H
						MOV		SI,AX
						; Font DS:AX

						MOV		DL,8
WRFONTHIGH_OUTER_LOOP:
						LODSB
						XOR		EBX,EBX

						MOV		CX,8
WRFONTHIGH_INNER_LOOP:
						SHL		EBX,4
						SHR		AL,1
						JNC		SHORT WRFONTHIGH_INNER_LOOP_NEXT
						OR		BL,DH
WRFONTHIGH_INNER_LOOP_NEXT:
						LOOP	WRFONTHIGH_INNER_LOOP

						MOV		EAX,DWORD PTR CS:[VRAM_BYTES_PER_LINE]
						MOV		ES:[EDI],EBX
						ADD		EDI,EAX
						MOV		ES:[EDI],EBX
						ADD		EDI,EAX
						DEC		DL
						JNE		WRFONTHIGH_OUTER_LOOP

						SHL		EAX,4	; BytesPerLine*16
						SUB		EDI,EAX
						ADD		EDI,4
						JMP		WRFONTHIGH_OUTMOST_LOOP


WRFONTHIGH_LOOP_OUT:
						POP		EAX
						MOV		CR0,EAX

						JMP		SHORT @f
@@:

						MOV		DX,IO_KVRAM_OR_ANKFONT
						XOR		AL,AL
						OUT		DX,AL

RESETGDT_POP_AND_RET:
						LGDT	FWORD PTR CS:[GDT_BACKUP]

						POPF
						POPAD
						POP		DS
						POP		ES
						POP		FS
						RET

WRSTRING_HIGH			ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; EBX VRAM Offset
WRAOMORI_HIGH			PROC
						PUSH	FS
						PUSH	ES
						PUSH	DS
						PUSHAD
						PUSHF

						CALL	WRHIGH_SETUP_GDT

						CLI

						MOV		EAX,CR0
						PUSH	EAX
						OR		AL,1
						MOV		CR0,EAX


						; https://wiki.osdev.org/Unreal_Mode suggest one jump "to tell 386/486 not to crash".
						JMP		SHORT @f
@@:


						MOV		BX,8	; Descriptor 1
						MOV		ES,BX
						MOV		SI,OFFSET AOMORI_BMP

						MOV		EBX,DWORD PTR [VRAM_BYTES_PER_LINE]
						MOV		EDI,EBX
						SHL		EDI,6
						SUB		EDI,EBX

WRAOMORIHIGH_OUTMOST_LOOP:
						MOV		DL,8
WRAOMORIHIGH_OUTER_LOOP:
						LODSB
						XOR		EBX,EBX

						MOV		CX,8
WRAOMORIHIGH_INNER_LOOP:
						SHL		EBX,4
						SHR		AL,1
						JC		SHORT WRAOMORIHIGH_INNER_LOOP_NEXT
						OR		BL,0CH
WRAOMORIHIGH_INNER_LOOP_NEXT:
						LOOP	WRAOMORIHIGH_INNER_LOOP

						XCHG	EAX,EBX
						STOSD
						XCHG	EAX,EBX
						DEC		DL
						JNE		WRAOMORIHIGH_OUTER_LOOP

						MOV		EBX,DWORD PTR [VRAM_BYTES_PER_LINE]
						SUB		EDI,EBX
						SUB		EDI,32
						CMP		SI,OFFSET AOMORI_BMP_END
						JB		WRAOMORIHIGH_OUTMOST_LOOP


WRAOMORIHIGH_LOOP_OUT:
						POP		EAX
						MOV		CR0,EAX

						JMP		SHORT @f
@@:
						JMP		RESETGDT_POP_AND_RET

WRAOMORI_HIGH			ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CLS_HIGH				PROC
						XOR		EDI,EDI
						MOV		AL,8	; 10000H times 8 to clear both pages.
CLS_HIGH_LOOP:
						MOV		ECX,04000H
						CALL	CLS_HIGH_SUB
						ADD		EDI,010000H
						CMP		EDI,080000H
						JB		CLS_HIGH_LOOP

						RET
CLS_HIGH				ENDP



CLS_5BELOW_HIGH				PROC
						MOV		AX,0006H
						CALL	LOCATE31K

CLS_5BELOW_HIGH_LOOP:
						MOV		ECX,04000H
						CALL	CLS_HIGH_SUB
						ADD		EDI,010000H
						CMP		EDI,040000H
						JB		CLS_5BELOW_HIGH_LOOP

						RET
CLS_5BELOW_HIGH				ENDP



; Input
;  EDI=VRAM top
ERASE_LINE_HIGH				PROC
						PUSH	ECX
						MOV		ECX,CS:[VRAM_BYTES_PER_LINE]
						SHL		ECX,4
						CALL	CLS_HIGH_SUB
						POP		ECX
						RET
ERASE_LINE_HIGH				ENDP



CLS_HIGH_SUB			PROC
						PUSH	FS
						PUSH	ES
						PUSH	DS
						PUSHAD
						PUSHF

						CALL	WRHIGH_SETUP_GDT

						CLI

						; In this one, EBX is free.
						MOV		EBX,CR0
						OR		BL,1
						MOV		CR0,EBX

						JMP		SHORT @f
@@:

						MOV		DX,8	; Descriptor 1
						MOV		ES,DX

						XOR		EAX,EAX
						REP		STOSD

						AND		BL,0FEH
						MOV		CR0,EBX

						JMP		SHORT @f
@@:
						JMP		RESETGDT_POP_AND_RET

CLS_HIGH_SUB			ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
