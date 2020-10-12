STR_16					DB	16 dup(0)



; Input
;	AL		Number
; Output
;	AH		Higher digit ASCII code
;	AL		Lower digit ASCII code
ITOX8					PROC

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

ITOX8					ENDP



; Input
;   EAX    Number
;   DS:DI  String Pointer (8 bytes)
ITOX32					PROC
						ROL		EAX,8
						PUSH	EAX
						CALL	ITOX8
						XCHG	AL,AH
						MOV		WORD PTR [DI],AX
						POP		EAX
						ROL		EAX,8
						CALL	ITOX8
						XCHG	AL,AH
						MOV		WORD PTR [DI+2],AX
						ROL		EAX,8
						CALL	ITOX8
						XCHG	AL,AH
						MOV		WORD PTR [DI+4],AX
						ROL		EAX,8
						CALL	ITOX8
						XCHG	AL,AH
						MOV		WORD PTR [DI+6],AX
						RET
ITOX32					ENDP
