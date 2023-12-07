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
GDT_BASE_LOW			DW		0			; Base Address 0-15
GDT_BASE_MIDHIGH		DB		010H		; Base Address 16-23
						DB		10010010B	; P=1, DPL=00, S=1, TYPE=0010
						DB		11000111B	; G=1, DB=1, (Unused)=0, A=0, LIMIT 16-19=0011
GDT_BASE_HIGH			DB		0			; Base Address 24-31
GDT_END					DB		0	; Dummy

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Need .386p

; Input
;   ESI      Source Physical Address
;   ES:DI    Destination
;   CX       Transfer size
;	DF       0
READ_HIGHB				PROC
						PUSH	DS
						PUSH	DI
						PUSH	CX
						PUSH	EDX	; Why was it missing until 12/6/2023????
						PUSH	SI

						XCHG	EDX,ESI
						MOV		AL,1	; Get DS
						CALL	GET_UNREALMODE_SEG
						XCHG	EDX,ESI

						XOR		SI,SI
						REP		MOVSB

						POP		SI
						POP		EDX
						POP		CX
						POP		DI
						POP		DS
						RET
READ_HIGHB				ENDP



; Input
;	AL     Which segment selector:
;			bit0:DS
;			bit1:ES
;			bit2:FS
;			bit3:GS
;   EDX    Physical Address
GET_UNREALMODE_SEG		PROC

; https://wiki.osdev.org/Unreal_Mode

						PUSH	GS
						PUSH	FS
						PUSH	ES
						PUSH	DS
						PUSH	EDI
						PUSH	ESI
						PUSH	EDX
						PUSH	ECX
						PUSH	EBX
						PUSH	EAX
						PUSHF


						MOV		CS:[GDT_BASE_LOW],DX
						SHR		EDX,16
						MOV		CS:[GDT_BASE_MIDHIGH],DL
						MOV		CS:[GDT_BASE_HIGH],DH

						MOV		AX,CS
						MOV		DS,AX


						MOV		DX,CS
						MOVZX	EDX,DX
						SHL		EDX,4
						ADD		EDX,OFFSET GDT_BEGIN
						MOV		CS:[GDT_ADDR],EDX


						CLI

						SGDT	FWORD PTR CS:[GDT_BACKUP]
						LGDT	FWORD PTR CS:[GDT_INFO]

						MOV		EAX,CR0
						OR		AL,1
						MOV		CR0,EAX



						; https://wiki.osdev.org/Unreal_Mode suggest one jump "to tell 386/486 not to crash".
						JMP		@f
@@:
						; Quote from https://www.felixcloutier.com/x86/lgdt:lidt
						; They are the only instructions that directly load a linear address 
						; (that is, not a segment-relative address) and a limit in protected mode.
						MOV		DX,8	; Descriptor 1
						MOV		DS,DX
						MOV		ES,DX
						MOV		FS,DX
						MOV		GS,DX

						AND		AL,0FEH
						MOV		CR0,EAX

						JMP		@f
@@:

						LGDT	FWORD PTR CS:[GDT_BACKUP]

						POPF
						POP		EAX
						POP		EBX
						POP		ECX
						POP		EDX
						POP		ESI
						POP		EDI

						TEST	AL,1	; Return DS?
						JNE		GET_UNREAL_RETURN_DS
						POP		DS
						JMP		SHORT GET_UNREAL_NOT_RETURN_DS
GET_UNREAL_RETURN_DS:
						ADD		SP,2
GET_UNREAL_NOT_RETURN_DS:

						TEST	AL,2	; Return ES?
						JNE		GET_UNREAL_RETURN_ES
						POP		ES
						JMP		SHORT GET_UNREAL_NOT_RETURN_ES
GET_UNREAL_RETURN_ES:
						ADD		SP,2
GET_UNREAL_NOT_RETURN_ES:

						TEST	AL,4	; Return FS?
						JNE		GET_UNREAL_RETURN_FS
						POP		FS
						JMP		SHORT GET_UNREAL_NOT_RETURN_FS
GET_UNREAL_RETURN_FS:
						ADD		SP,2
GET_UNREAL_NOT_RETURN_FS:

						TEST	AL,8	; Return GS?
						JNE		GET_UNREAL_RETURN_GS
						POP		GS
						JMP		SHORT GET_UNREAL_NOT_RETURN_GS
GET_UNREAL_RETURN_GS:
						ADD		SP,2
GET_UNREAL_NOT_RETURN_GS:

						RET

GET_UNREALMODE_SEG		ENDP
