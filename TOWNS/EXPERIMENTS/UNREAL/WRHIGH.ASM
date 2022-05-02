						ASSUME		CS:CODE_DATA,DS:CODE_DATA,SS:STACK

						.186
CODE_DATA				SEGMENT


MAIN					PROC

						CALL	PRINT_AL
						CALL	PRINT_CRLF


						PUSH	CS
						POP		DS

						MOV		DX,0010H	; Destination 00100000H
						MOV		AX,0000H
						MOV		CX,64		; 64x4=256 bytes
						LEA		SI,[TEST_DATA1]
						CALL	WRITE_HIGH


						MOV		DX,0010H	; Destination 00100123H
						MOV		AX,0123H	; Test: Off 4-byte boundary
						MOV		CX,64		; 64x4=256 bytes
						LEA		SI,[TEST_DATA2]
						CALL	WRITE_HIGH


						MOV		DX,0015H	; Destination 00150237H
						MOV		AX,0237H	; Test: Off 4-byte boundary
						MOV		CX,64		; 64x4=256 bytes
						LEA		SI,[TEST_DATA3]
						CALL	WRITE_HIGH



						LEA		SI,[GDT_BACKUP]
						MOV		AL,CS:[SI]
						CALL	PRINT_AL
						MOV		AL,CS:[SI+1]
						CALL	PRINT_AL
						MOV		AL,CS:[SI+2]
						CALL	PRINT_AL
						MOV		AL,CS:[SI+3]
						CALL	PRINT_AL
						MOV		AL,CS:[SI+4]
						CALL	PRINT_AL
						MOV		AL,CS:[SI+5]
						CALL	PRINT_AL


						; EXIT
						MOV		AX,4C00H
						INT		21H

MAIN					ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PRINT_AL				PROC
						PUSH	CX
						PUSH	AX

						CALL	ITOA8
						XCHG	AL,AH
						CALL	PUTC
						XCHG	AL,AH
						CALL	PUTC

						POP		AX
						POP		CX
						RET
PRINT_AL				ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PRINT_CRLF				PROC
						PUSH	AX
						MOV		AL,0DH
						CALL	PUTC
						MOV		AL,0AH
						CALL	PUTC
						POP		AX
						RET
PRINT_CRLF				ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PUTC					PROC

						PUSH	AX
						PUSH	DX

						MOV		DL,AL
						MOV		AH,06H
						INT		21H

						POP		DX
						POP		AX

						RET

PUTC					ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Input
;	AL		Number
; Output
;	AH		Higher digit ASCII code
;	AL		Lower digit ASCII code
ITOA8					PROC

						MOV		AH,AL
						AND		AL,0FH
						SHR		AH,1
						SHR		AH,1
						SHR		AH,1
						SHR		AH,1

						ADD		AL,'0'
						CMP		AL,'9'
						JLE		@f
						ADD		AL,'A'-'0'-10
@@:
						ADD		AH,'0'
						CMP		AH,'9'
						JLE		@f
						ADD		AH,'A'-'0'-10
@@:
						RET

ITOA8					ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


TEST_DATA1				DB		"UNREAL MODE! HELLO HIGH MEMORY! YSFLIGHT.COM",0DH,0AH
						DB		"12345",0DH,0AH
						DB		"12345",0DH,0AH
						DB		"12345",0DH,0AH,0

TEST_DATA2				DB		"UNREAL MODE! HELLO HIGH MEMORY! YSFLIGHT.COM",0DH,0AH
						DB		"abcde",0DH,0AH
						DB		"abcde",0DH,0AH
						DB		"abcde",0DH,0AH,0

TEST_DATA3				DB		"UNREAL MODE! HELLO HIGH MEMORY! YSFLIGHT.COM",0DH,0AH
						DB		"ABCDE",0DH,0AH
						DB		"ABCDE",0DH,0AH
						DB		"ABCDE",0DH,0AH,0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


CODE_DATA				ENDS


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


						.386p
CODE_DATA				SEGMENT

; Input
;   DX:AX    Physical Address  DX=High_16_bit  AX=Low_16_bit
;   DS:SI    Source
;   CX       Transfer size/4

WRITE_HIGH				PROC

; https://wiki.osdev.org/Unreal_Mode

						PUSH	ES
						PUSH	DS
						PUSH	EDI
						PUSH	ESI
						PUSH	EDX
						PUSH	ECX
						PUSH	EBX
						PUSH	EAX
						PUSHF


						MOV		CS:[GDT_BASE_LOW+1],AH
						MOV		CS:[GDT_BASE_LOW+2],DL
						MOV		CS:[GDT_BASE_HIGH],DH
						MOV		AH,AL
						AND		AH,0F0H					; Align with 16-byte boundary.
						MOV		CS:[GDT_BASE_LOW],AH	; I don't know if segment boundary needs to be 4-byte alignment.
						AND		AX,000FH				; Let AL carry the low 4 bits.
						MOV		DI,AX
						; Now Destination is 0008:DI


						MOV		AX,CS
						MOV		DS,AX


						MOV		DX,CS
						SHR		DX,12
						MOV		AX,CS
						SHL		AX,4
						ADD		AX,OFFSET GDT_BEGIN
						ADC		DX,0
						MOV		WORD PTR CS:[GDT_ADDR  ],AX
						MOV		WORD PTR CS:[GDT_ADDR+2],DX


						CLI

						SGDT	FWORD PTR CS:[GDT_BACKUP]
						LGDT	FWORD PTR CS:[GDT_INFO]

						MOV		EAX,CR0
						PUSH	EAX
						OR		AL,1
						MOV		CR0,EAX



						; https://wiki.osdev.org/Unreal_Mode suggest one jump "to tell 386/486 not to crash".
						JMP		@f
@@:

						AND		ESI,0000FFFFH
						AND		EDI,0000FFFFH
						AND		ECX,0000FFFFH


						; Quote from https://www.felixcloutier.com/x86/lgdt:lidt
						; They are the only instructions that directly load a linear address 
						; (that is, not a segment-relative address) and a limit in protected mode.
						MOV		AX,8	; Descriptor 1
						MOV		ES,AX
						REP		MOVSD


						POP		EAX
						MOV		CR0,EAX

						LGDT	FWORD PTR CS:[GDT_BACKUP]

						POPF
						POP		EAX
						POP		EBX
						POP		ECX
						POP		EDX
						POP		ESI
						POP		EDI
						POP		DS
						POP		ES
						RET

WRITE_HIGH				ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GDT_BACKUP				DW		0
						DD		0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GDT_INFO				DW		GDT_END-GDT_BEGIN-1
GDT_ADDR				DD		0	; Sounds like a linear address

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GDT_BEGIN				DD		0,0			; Table 0.  Not used?
						; It must make a flat 32-bit descriptor.
						; https://wiki.osdev.org/Unreal_Mode
						DB		0FFH,0FFH	; Segment Limit (0-15)
GDT_BASE_LOW			DB		0,0,010H		; Base Address 0-23
						DB		10010010B	; P=1, DPL=00, S=1, TYPE=0010
						DB		11000111B	; G=1, DB=1, (Unused)=0, A=0, LIMIT 16-19=0011
GDT_BASE_HIGH			DB		0			; Base Address 24-31
GDT_END					DB		0	; Dummy

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


CODE_DATA				ENDS


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


STACK		SEGMENT	STACK

		DB	1024 DUP(0)

STACK		ENDS


						END		MAIN
