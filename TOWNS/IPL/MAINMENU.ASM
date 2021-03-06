MENUITEM_LENGTH			EQU		80

NUM_MAINMENU_OPTIONS	EQU		5

MAINMENU_ITEMNUM_BOOTMENU		EQU		1
MAINMENU_ITEMNUM_CMOSMENU		EQU		0
MAINMENU_ITEMNUM_RESETCMOS		EQU		2
MAINMENU_ITEMNUM_RS232CMENU		EQU		3
MAINMENU_ITEMNUM_IPLDEBUGMENU	EQU		4

MAINMENU				PROC

						CALL	BOOTMENU	; Go to BOOT MENU first

MAINMENU_OUTER_LOOP:
						CALL	MENU_WAIT_PAD_RELEASE

						CALL	CLEAR_FIVE_BELOW

						MOV		SI,OFFSET MAINMENU_ITEM_BUFFER
						MOV		CX,NUM_MAINMENU_OPTIONS
						CALL	DRAWMENU

						MOV		AX,DISPLACED_DEMOSPLASh_MESSAGE_LOCATION
						CALL	DEMOSPLASH_MESSAGE_MOVABLE

						MOV		AX,DISPLACED_DEMOSPLASh_MESSAGE_LOCATION
						ADD		AL,5
						CALL	HIROSAKI_MESSAGE_MOVABLE

						MOV		CL,NUM_MAINMENU_OPTIONS
						MOV		AL,CS:[MAINMENU_SELECTION]
						CALL	DRAWARROW

@@:
						CALL	READ_PADA
						CMP		AL,3FH
						JE		@b

						MOV		AH,CS:[MAINMENU_SELECTION]
						MOV		CH,NUM_MAINMENU_OPTIONS
						CALL	MOVE_ARROW_BY_PAD
						MOV		CS:[MAINMENU_SELECTION],AH

						AND		AL,30H
						CMP		AL,30H
						JE		MAINMENU_OUTER_LOOP

						;	AH is still Selection
						CMP		AH,MAINMENU_ITEMNUM_CMOSMENU
						JNE		@f
						CALL	CMOSMENU
						JMP		MAINMENU_OUTER_LOOP

@@:
						CMP		AH,MAINMENU_ITEMNUM_BOOTMENU
						JNE		@f
						CALL	BOOTMENU
						JMP		MAINMENU_OUTER_LOOP

@@:
						CMP		AH,MAINMENU_ITEMNUM_RESETCMOS
						JNE		@f
						CALL	CMOSRESET_CONFIRM
						JMP		MAINMENU_OUTER_LOOP

@@:
						CMP		AH,MAINMENU_ITEMNUM_RS232CMENU
						JNE		@f
						CALL	RS232CMENU
						JMP		MAINMENU_OUTER_LOOP

@@:
						CMP		AH,MAINMENU_ITEMNUM_IPLDEBUGMENU
						JNE		@f
						CALL	IPLDEBUG
						JMP		MAINMENU_OUTER_LOOP

@@:
						JMP		MAINMENU_OUTER_LOOP

MAINMENU				ENDP



MAINMENU_SELECTION		DB		0
	                           ; 01234567890123456789012345678901234567890123456789012345678901234567890123456789
MAINMENU_ITEM_BUFFER	DB		"DRIVE LETTER ASSIGNMENTS                                                       ",0
						DB		"BOOT MENU                                                                      ",0
						DB		"RESET CMOS RAM                                                                 ",0
						DB		"SERIAL (RS232C) MENU                                                           ",0
						DB		"IPL DEBUG (DUMP B0000 to B00FF)                                                ",0


; Input
;   AL Pad
;   AH Current Selection
;   CH Number of Choices
; Output
;   AH New Selection
MOVE_ARROW_BY_PAD		PROC
						TEST	AL,2
						JE		MOVE_ARROW_BY_PAD_DOWN
						TEST	AL,1
						JE		MOVE_ARROW_BY_PAD_UP
						RET

MOVE_ARROW_BY_PAD_DOWN:
						INC		AH
						CMP		AH,CH
						JL		@f
						XOR		AH,AH
						RET

MOVE_ARROW_BY_PAD_UP:
						SUB		AH,1
						JAE		@f
						MOV		AH,CH
						DEC		AH
@@:
						RET

MOVE_ARROW_BY_PAD		ENDP




; INPUT
;   AL PAD
; OUTPUT
;   BX  -1 LEFT
;        0 NEUTRAL
;        1 RIGHT
;   ZF=0 IF LEFT OR RIGHT,  ZF=1 IF NEUTRAL
PAD_TO_LEFT_RIGHT		PROC
						XOR		BX,BX

						TEST	AL,08H
						JNE		@f
						MOV		BX,1
						AND		BX,BX
						RET
@@:
						TEST	AL,04H
						JNE		@f
						MOV		BX,-1
						AND		BX,BX
						RET
@@:
						TEST	AL,10H
						JNE		@f
						MOV		BX,1
						AND		BX,BX
						RET
@@:
						TEST	AL,20H
						JNE		@f
						MOV		BX,-1

@@:
						AND		BX,BX
						RET
PAD_TO_LEFT_RIGHT		ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


MENU_WAIT_PAD_PRESS		PROC
						MOV		AX,INSTRUCTION_LOCATION
						CALL	LOCATE
						MOV		SI,OFFSET MENU_ASKPRESS_MESSAGE
						CALL	PRINT_TALL

						CALL	WAIT_BUTTON_PRESS

						MOV		AX,INSTRUCTION_LOCATION
						CALL	LOCATE
						CALL	ERASE_LINE_TALL

						RET
MENU_WAIT_PAD_PRESS		ENDP

MENU_ASKPRESS_MESSAGE	DB		"PRESS PAD0 BUTTON",0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; INPUT/OUTPUT
;	AL
TOGGLE_1_0				PROC
						AND		AL,1
						XOR		AL,1
						RET

TOGGLE_1_0				ENDP



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; Input
;   DS:SI    Triple confirmation message
; Output
;   AH       0  Confirmed
;            1  Cancelled
MENU_TRIPLE_CONFIRM		PROC


						MOV		BX,3
						MOV		AH,1	; CANCEL
TRIPLE_CONFIRM_LOOP:
						PUSH	BX
						PUSH	SI
						PUSH	AX

						CALL	MENU_WAIT_PAD_RELEASE
						CALL	CLEAR_FIVE_BELOW

						POP		AX
						POP		SI
						PUSH	SI
						PUSH	AX

						MOV		CX,2		; 2 MENU ITEMS
						CALL	DRAWMENU

						POP		AX
						PUSH	AX

						MOV		CX,2		; 2 MENU ITEMS
						MOV		AL,AH		; AL=CURRENT SELECTION
						CALL	DRAWARROW

						POP		AX
						POP		SI

@@:
						CALL	READ_PADA
						CMP		AL,3FH
						JE		@b

						MOV		CH,2
						CALL	MOVE_ARROW_BY_PAD

						POP		BX

						AND		AL,30H
						CMP		AL,30H
						JE		TRIPLE_CONFIRM_LOOP

						CMP		AH,1
						JNE		@f
						RET

@@:
						ADD		SI,MENUITEM_LENGTH*2
						DEC		BX
						JE		@f
						MOV		AH,1	; CANCEL
						JMP		TRIPLE_CONFIRM_LOOP

@@:
						RET

MENU_TRIPLE_CONFIRM		ENDP
