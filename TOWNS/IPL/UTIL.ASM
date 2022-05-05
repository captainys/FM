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



;Input
;  ES:DI  0FFH terminated text
;Output
;   CX     Preserved
;   BX     Preserved
;   ES:DI  Points to 0FFH
SEEK_TEXT_ADD_POSITION	PROC

SEEK_TEXT_ADD_POSITION_LOOP:
						CMP		BYTE PTR ES:[DI],0FFH
						JE		SHORT SEEK_TEXT_ADD_POSITION_BREAK
						INC		DI
						JMP		SEEK_TEXT_ADD_POSITION_LOOP
SEEK_TEXT_ADD_POSITION_BREAK:
						; ES:[DI]=0FFH
						RET
SEEK_TEXT_ADD_POSITION	ENDP



;Input
;  ES:DI  0FFH terminated text
;  CX     Index
;Output
;  AL     Destroyed
;  ES:DI  Points to the menu item (If ES:[DI]==0FFH, overflow.)
SEEK_MENU_ITEM			PROC
						OR		CX,CX
						JE		SEEK_MENU_ITEM_BREAK
SEEK_MENU_ITEM_LOOP:
						MOV		AL,ES:[DI]
						CMP		AL,0FFH
						JE		SHORT SEEK_MENU_ITEM_BREAK

						INC		DI
						OR		AL,AL
						JNE		SEEK_MENU_ITEM_LOOP
						LOOP	SEEK_MENU_ITEM_LOOP

SEEK_MENU_ITEM_BREAK:
						RET
SEEK_MENU_ITEM			ENDP




; Input
;   BX     Preserved
;   CX     Preserved
;   ES:DI
ADD_CHECKBOX_TO_TEXT	PROC
						CALL	SEEK_TEXT_ADD_POSITION
						MOV		DWORD PTR ES:[DI],0FF5D205Bh
						MOV		BYTE PTR ES:[DI+4],0FFh
						ADD		DI,3
						RET
ADD_CHECKBOX_TO_TEXT	ENDP




; Input:
;   DS:SI  Pointer to C-String
;   ES:DI  Pointer to Text (Terminated by 0FFh)
; Output:
;   CX     Preserved
;   BX     Preserved
;   SI		Preserved
;   AL		Destroyed
;   ES:DI 	Points to 0FFFFH
ADD_STRING_TO_TEXT		PROC
						PUSH	SI

						CALL	SEEK_TEXT_ADD_POSITION

ADD_STRING_TO_TEXT_COPY:
						LODSB
						STOSB
						OR		AL,AL
						JNE		ADD_STRING_TO_TEXT_COPY

						MOV		WORD PTR ES:[DI],0FFFFh

						POP		SI
						RET

ADD_STRING_TO_TEXT		ENDP



; Input
;   CX    Count
;   DS:SI String Source
;   ES:DI Text terminated by 0FFH
; Output
;   Many things destroyed
;   ES:DI Points to 0FFFFh
ADD_CHECKBOX_TO_TEXT_INCREMENT	PROC
						MOV		BL,0
ADD_CHECKBOX_TO_TEXT_INCREMENT_LOOP:
						CALL	ADD_CHECKBOX_TO_TEXT
						CALL	ADD_STRING_TO_TEXT
						ADD		ES:[DI-2],BL
						INC		DL
						LOOP	ADD_CHECKBOX_TO_TEXT_INCREMENT_LOOP
						RET
ADD_CHECKBOX_TO_TEXT_INCREMENT	ENDP
