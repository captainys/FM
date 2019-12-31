						ASSUME		CS:DATA_CODE,DS:DATA_CODE


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


						.386p
DATA_CODE				SEGMENT

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

						MOV		EAX,CR0
						PUSH	EAX
						OR		AL,1
						MOV		CR0,EAX


						SGDT	FWORD PTR CS:[GDT_BACKUP]


						LGDT	FWORD PTR CS:[GDT_INFO]

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


						LGDT	FWORD PTR CS:[GDT_BACKUP]

						POP		EAX
						MOV		CR0,EAX

						JMP		@f
@@:

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


DATA_CODE				ENDS


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

