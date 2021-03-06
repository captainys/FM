IO_CMOS_D_DRIVE					EQU		31E8H
IO_CMOS_P_DRIVE					EQU		3218H
IO_CMOS_SINGLE_DRIVE_MODE		EQU		328CH
IO_CMOS_DRIVE_COUNTER_CHECKSUM	EQU		33CEH

MAX_NUM_DRIVE_ASSIGNMENTS		EQU		'Q'-'D'

CMOSMENU_RETUR_TO_MAINMENU		EQU		0
CMOSMENU_ITEMNUM_HELP			EQU		1
CMOSMENU_SINGLE_DRIVE_MODE		EQU		2
CMOSMENU_ITEMNUM_DRIVE_D		EQU		3

BOOTDEVICETYPE_FLOPPYDRIVE		EQU		0
BOOTDEVICETYPE_ROMDRIVE			EQU		5
BOOTDEVICETYPE_HARDDRIVE		EQU		2
BOOTDEVICETYPE_UNASSIGNED		EQU		0FFH


CMOSMENU				PROC
						CALL	READ_CMOS_DRIVE_ASSIGNMENTS
						CALL	UPDATE_ASSIGNMENT_MENU

						MOV		BYTE PTR CS:[CMOSMENU_SELECTION],0
						MOV		BYTE PTR CS:[CMOSMENU_VALUECHANGED],0

CMOSMENU_MAINLOOP:
						CALL	MENU_WAIT_PAD_RELEASE

						CALL	CLEAR_FIVE_BELOW

						MOV		AX,INSTRUCTION_LOCATION
						CALL	LOCATE
						MOV		SI,OFFSET CMOSMENU_INSTRUCTION1
						CALL	PRINT_TALL

						MOV		AX,INSTRUCTION_LOCATION+1
						CALL	LOCATE
						MOV		SI,OFFSET CMOSMENU_INSTRUCTION2
						CALL	PRINT_TALL

						CALL	COUNT_CMOSMENU_CHOICES
						MOVZX	CX,BL
						MOV		SI,OFFSET CMOSMENU_ITEMS
						CALL	DRAWMENU

						MOV		AX,DISPLACED_DEMOSPLASh_MESSAGE_LOCATION
						CALL	DEMOSPLASH_MESSAGE_MOVABLE

						MOV		AX,DISPLACED_DEMOSPLASh_MESSAGE_LOCATION
						ADD		AL,5
						CALL	HIROSAKI_MESSAGE_MOVABLE

						MOV		AL,CS:[DRIVE_COUNTER_CHECKSUM]
						CALL	ITOX8
						XCHG	AL,AH
						MOV		WORD PTR CS:[CMOSMENU_MISC],AX
						MOV		AX,4E18H
						CALL	LOCATE
						MOV		SI,OFFSET CMOSMENU_MISC
						CALL	PRINT_TALL

						CALL	COUNT_CMOSMENU_CHOICES
						MOVZX	CX,BL
						MOV		AL,CS:[CMOSMENU_SELECTION]
						CALL	DRAWARROW

@@:
						CALL	READ_PADA
						CMP		AL,3FH
						JE		@b

						CALL	COUNT_CMOSMENU_CHOICES
						MOV		AH,CS:[CMOSMENU_SELECTION]
						MOV		CH,BL
						CALL	MOVE_ARROW_BY_PAD
						MOV		CS:[CMOSMENU_SELECTION],AH

						CALL	CMOSMENU_SKIP_UNCHANGEABLE_DRIVES

						CALL	PAD_TO_LEFT_RIGHT
						JE		@f
						CALL	CMOSMENU_LEFT_RIGHT

@@:
						AND		AL,30H
						CMP		AL,30H
						JE		CMOSMENU_MAINLOOP

						MOV		AH,CS:[CMOSMENU_SELECTION]

						CMP		AH,CMOSMENU_ITEMNUM_HELP
						JNE		@f
						CALL	CMOSMENU_HELP
						JMP		CMOSMENU_MAINLOOP

@@:
						CMP		AH,CMOSMENU_RETUR_TO_MAINMENU
						JNE		CMOSMENU_MAINLOOP

						CMP		BYTE PTR CS:[CMOSMENU_VALUECHANGED],0
						JE		@f

						CALL	CMOSMENU_CONFIRM
						CMP		AH,2	; BACK TO DRIVE-LETTER ASSIGNMENT
						JE		CMOSMENU_MAINLOOP
						CMP		AH,1	; DISCARD CHANGES
						JE		@f

						CALL	WRITE_CMOS_DRIVE_ASSIGNMENTS

@@:
						RET


CMOSMENU				ENDP



CMOSMENU_SKIP_UNCHANGEABLE_DRIVES	PROC

						CALL	COUNT_NUM_ASSIGNED_DRIVES
						CMP		BL,2
						JG		@f
						RET
@@:
						MOV		AH,CS:[CMOSMENU_SELECTION]
						SUB		AH,CMOSMENU_ITEMNUM_DRIVE_D
						JNE		@f

						MOV		AH,BL
						SUB		AH,1
						ADD		AH,CMOSMENU_ITEMNUM_DRIVE_D
						MOV		CS:[CMOSMENU_SELECTION],AH
						RET

@@:
						SUB		BL,2
						CMP		AH,BL
						JNE		@f

						MOV		AH,CMOSMENU_ITEMNUM_DRIVE_D
						DEC		AH
						MOV		CS:[CMOSMENU_SELECTION],AH

@@:
						RET

CMOSMENU_SKIP_UNCHANGEABLE_DRIVES	ENDP



; INPUT
;   BX LEFT OR RIGHT  -1,0,OR 1
;	AX PRESERVED
CMOSMENU_LEFT_RIGHT		PROC
						PUSH	AX

						MOV		AL,CS:[CMOSMENU_SELECTION]
						CMP		AL,CMOSMENU_SINGLE_DRIVE_MODE
						JNE		@f

						; TOGGLE SINGLE-DRIVE MODE
						MOV		AL,CS:[SINGLE_DRIVE_MODE]
						CALL	TOGGLE_1_0
						MOV		DI,OFFSET SINGLE_DRIVE_MODE
						CALL	CMOSMENU_STORE_VALUE

						CALL	UPDATE_ASSIGNMENT_MENU
						JMP		CMOSMENU_LEFT_RIGHT_RETURN

@@:
						CMP		AL,CMOSMENU_ITEMNUM_DRIVE_D
						JB		CMOSMENU_LEFT_RIGHT_RETURN

						SUB		AL,CMOSMENU_ITEMNUM_DRIVE_D
						MOVZX	DI,AL
						SHL		DI,1
						ADD		DI,OFFSET DRIVE_ASSIGNMENTS
						CMP		BYTE PTR [DI],BOOTDEVICETYPE_HARDDRIVE
						JE		@f

						CMP		BX,0	; FLIP TO SCSI ID 0 ONLY WHEN PLUS
						JLE		CMOSMENU_LEFT_RIGHT_RETURN

						MOV		AL,BOOTDEVICETYPE_HARDDRIVE
						CALL	CMOSMENU_STORE_VALUE

						XOR		AL,AL
						CALL	CMOSMENU_SET_NEXT_PARTITION_NUMBER
						ADD		DI,1
						CALL	CMOSMENU_STORE_VALUE

						CALL	UPDATE_ASSIGNMENT_MENU

						JMP		CMOSMENU_LEFT_RIGHT_RETURN


@@:
						; DI POINTS TO THE 2-BYTE OF THE HARD DRIVE ASSIGNMENT
						; [DI] IS CHECKED TO BE BOOTDEVICETYPE_HARDDRIVE

						CMP		BYTE PTR [DI+2],BOOTDEVICETYPE_UNASSIGNED
						JNE		CMOSMENU_LEFT_RIGHT_RETURN	; ONLY THE LAST DRIVE CAN BE EDITED

						MOVZX	CX,BYTE PTR [DI+1]
						SHR		CL,4
						AND		CL,0FH	; CL IS SCSI ID

						ADD		CX,BX
						JNS		@f

						; SCSI ID BECOME NEGATIVE
						; UNASSIGN DRIVE
						MOV		AL,0FFH
						CALL	CMOSMENU_STORE_VALUE
						MOV		AL,0FFH
						ADD		DI,1
						CALL	CMOSMENU_STORE_VALUE
						CALL	UPDATE_ASSIGNMENT_MENU

						JMP		CMOSMENU_LEFT_RIGHT_RETURN


@@:
						CMP		CX,6
						JA		CMOSMENU_LEFT_RIGHT_RETURN	; ONLY UP TO 6

						MOV		AL,CL
						SHL		AL,4

						CALL	CMOSMENU_SET_NEXT_PARTITION_NUMBER
						ADD		DI,1
						CALL	CMOSMENU_STORE_VALUE

						CALL	UPDATE_ASSIGNMENT_MENU


CMOSMENU_LEFT_RIGHT_RETURN:
						POP		AX
						RET
CMOSMENU_LEFT_RIGHT		ENDP



CMOSMENU_DELETE_LAST_DRIVE	PROC
						MOV		DI,OFFSET DRIVE_ASSIGNMENTS
						CMP		BYTE PTR [DI],0FFH
						JNE		@f
						RET

@@:
						CMP		BYTE PTR [DI+2],0FFH
						JE		@f
						ADD		DI,2
						JMP		@b

@@:
						MOV		AL,0FFH
						CALL	CMOSMENU_STORE_VALUE
						ADD		DI,1
						MOV		AL,0FFH
						CALL	CMOSMENU_STORE_VALUE
						CALL	UPDATE_ASSIGNMENT_MENU
						RET
CMOSMENU_DELETE_LAST_DRIVE	ENDP



CMOSMENU_HELP			PROC
						CALL	MENU_WAIT_PAD_RELEASE

						CALL	CLEAR_FIVE_BELOW

						MOV		AX,0105H
						MOV		SI,OFFSET CMOSMENU_HELP_TEXT
						CALL	DRAW_TEXT

@@:
						CALL	READ_PADA
						CMP		AL,3FH
						JE		@b


						RET
CMOSMENU_HELP			ENDP


; INPUT
;   AL HIGH 4-BIT    SCSI ID
; OUTPUT
;   AL LOW 4-BIT    PARTITION NUMBER
;   AH NOT PRESERVED
CMOSMENU_SET_NEXT_PARTITION_NUMBER	PROC
						PUSH	SI
						PUSH	CX
						PUSH	BX

						MOV		AH,AL
						AND		AH,0F0H		; AH=SCSI ID
						XOR		AL,AL

						MOV		SI,OFFSET DRIVE_ASSIGNMENTS
						MOV		CX,MAX_NUM_DRIVE_ASSIGNMENTS

CMOSMENU_SET_NEXT_PARTITION_OUTER_LOOP:
						MOV		BH,[SI]

						CMP		BH,BOOTDEVICETYPE_UNASSIGNED
						JE		CMOSMENU_SET_NEXT_PARTITION_BREAK
						CMP		BH,BOOTDEVICETYPE_HARDDRIVE
						JNE		CMOSMENU_SET_NEXT_PARTITION_CONTINUE

						MOV		BH,[SI+1]

						AND		BH,0F0H		; BH=SCSI ID
						CMP		AH,BH
						JNE		CMOSMENU_SET_NEXT_PARTITION_CONTINUE

						MOV		BH,[SI+1]
						AND		BH,0FH		; BH=PARTITION NUMBER
						INC		BH
						CMP		AL,BH
						JGE		CMOSMENU_SET_NEXT_PARTITION_CONTINUE

						MOV		AL,BH

CMOSMENU_SET_NEXT_PARTITION_CONTINUE:
						ADD		SI,2
						LOOP	CMOSMENU_SET_NEXT_PARTITION_OUTER_LOOP

CMOSMENU_SET_NEXT_PARTITION_BREAK:
						AND		AL,0FH
						OR		AL,AH

						POP		BX
						POP		CX
						POP		SI
						RET
CMOSMENU_SET_NEXT_PARTITION_NUMBER	ENDP



; INPUT
;   DS:DI  DESTINATION
;   AL     VALUE TO WRITE
CMOSMENU_STORE_VALUE	PROC
						XCHG	AL,BYTE PTR [DI]
						SUB		AL,BYTE PTR [DI]	; AL=OLDVALUE-NEWVALUE
						ADD		BYTE PTR CS:[DRIVE_COUNTER_CHECKSUM],AL

						; VALUE=OLDVALUE+(NEWVALUE-OLDVALUE)
						; SUM=OLDSUM+(NEWVALUE-OLDVALUE)+(NEWCOUNTERCHECKSUM-OLDCOUNTERCHECKSUM)
						; (NEWVALUE-OLDVALUE)+(NEWCOUNTERCHECKSUM-OLDCOUNTERCHECKSUM)=0
						; NEWCOUNTERCHECKSUM=OLDCOUNTERCHECKSUM+(OLDVALUE-NEWVALUE)

						OR		BYTE PTR CS:[CMOSMENU_VALUECHANGED],0FFH

						RET
CMOSMENU_STORE_VALUE	ENDP



READ_CMOS_DRIVE_ASSIGNMENTS	PROC
						PUSH	ES

						PUSH	CS
						POP		ES
						MOV		DX,IO_CMOS_D_DRIVE
						MOV		DI,OFFSET DRIVE_ASSIGNMENTS
@@:
						INSB
						ADD		DX,2
						INSB
						ADD		DX,2
						CMP		DX,IO_CMOS_P_DRIVE
						JBE		@b

						MOV		DX,IO_CMOS_SINGLE_DRIVE_MODE
						IN		AL,DX
						MOV		CS:[SINGLE_DRIVE_MODE],AL

						MOV		DX,IO_CMOS_DRIVE_COUNTER_CHECKSUM
						IN		AL,DX
						MOV		CS:[DRIVE_COUNTER_CHECKSUM],AL

						POP		ES
						RET
READ_CMOS_DRIVE_ASSIGNMENTS	ENDP



WRITE_CMOS_DRIVE_ASSIGNMENTS	PROC
						PUSH	ES

						PUSH	CS
						POP		ES
						MOV		DX,IO_CMOS_D_DRIVE
						MOV		SI,OFFSET DRIVE_ASSIGNMENTS
@@:
						OUTSB
						ADD		DX,2
						OUTSB
						ADD		DX,2
						CMP		DX,IO_CMOS_P_DRIVE
						JBE		@b

						MOV		AL,CS:[SINGLE_DRIVE_MODE]
						MOV		DX,IO_CMOS_SINGLE_DRIVE_MODE
						OUT		DX,AL

						MOV		AL,CS:[DRIVE_COUNTER_CHECKSUM]
						MOV		DX,IO_CMOS_DRIVE_COUNTER_CHECKSUM
						OUT		DX,AL

						POP		ES
						RET
WRITE_CMOS_DRIVE_ASSIGNMENTS	ENDP



; Output
;   BL  Number of CMOS Menu Choices
COUNT_CMOSMENU_CHOICES	PROC
						CALL	COUNT_NUM_ASSIGNED_DRIVES

						CMP		BL,MAX_NUM_DRIVE_ASSIGNMENTS
						JGE		@F
						INC		BL

@@:
						ADD		BL,CMOSMENU_ITEMNUM_DRIVE_D
						RET
COUNT_CMOSMENU_CHOICES	ENDP



; Output
;   BL	Number of drives assigned (D drive and later)
COUNT_NUM_ASSIGNED_DRIVES	PROC
						PUSH	SI

						MOV		BL,0
						MOV		SI,OFFSET DRIVE_ASSIGNMENTS
@@:
						CMP		BYTE PTR CS:[SI],0FFH
						JE		@f
						ADD		SI,2
						INC		BL
						JMP		@b
@@:
						POP		SI
						RET
COUNT_NUM_ASSIGNED_DRIVES	ENDP



UPDATE_ASSIGNMENT_MENU		PROC
						PUSH	ES

						PUSH	CS
						POP		ES

						MOV		SI,OFFSET CMOSMENU_OFF

						MOV		DI,OFFSET CMOSMENU_ITEMS+CMOSMENU_SINGLE_DRIVE_MODE*MENUITEM_LENGTH+18
						CMP		BYTE PTR CS:[SINGLE_DRIVE_MODE],0
						JE		@f
						MOV		SI,OFFSET CMOSMENU_ON

@@:
						MOV		CX,5
						REP		MOVSB


						MOV		CX,MAX_NUM_DRIVE_ASSIGNMENTS
						MOV		DI,OFFSET CMOSMENU_ITEMS+CMOSMENU_ITEMNUM_DRIVE_D*MENUITEM_LENGTH
						MOV		SI,OFFSET DRIVE_ASSIGNMENTS

UPDATE_ASSIGNMENT_MENU_OUTER_LOOP:
						PUSH	CX
						PUSH	SI
						PUSH	DI

						ADD		DI,9
						MOV		CX,MENUITEM_LENGTH-9-1
						MOV		AL,' '
						REP		STOSB

						POP		DI
						PUSH	DI


						MOV		AL,[SI]
						CALL	ITOX8
						XCHG	AL,AH
						MOV		[DI+8],AX

						MOV		AL,[SI+1]
						CALL	ITOX8
						XCHG	AL,AH
						MOV		[DI+10],AX

						MOV		AX,[SI]
						CMP		AL,BOOTDEVICETYPE_UNASSIGNED
						JNE		@f

						ADD		DI,13
						MOV		SI,OFFSET CMOSMENU_UNASSIGNED
						MOV		CX,(OFFSET CMOSMENU_UNASSIGNED_END)-(OFFSET CMOSMENU_UNASSIGNED)
						REP		MOVSB
						JMP		UPDATE_ASSIGNMENT_MENU_NEXT
@@:
						CMP		AL,BOOTDEVICETYPE_FLOPPYDRIVE
						JNE		@F

						ADD		DI,13
						MOV		SI,OFFSET CMOSMENU_FLOPPYDRIVE
						MOV		CX,(OFFSET CMOSMENU_FLOPPYDRIVE_END)-(OFFSET CMOSMENU_FLOPPYDRIVE)
						REP		MOVSB
						JMP		UPDATE_ASSIGNMENT_MENU_NEXT
@@:
						CMP		AL,BOOTDEVICETYPE_HARDDRIVE
						JE		@F

						ADD		DI,13
						MOV		SI,OFFSET CMOSMENU_UNKNOWNDEVICE
						MOV		CX,(OFFSET CMOSMENU_UNKNOWNDEVICE_END)-(OFFSET CMOSMENU_UNKNOWNDEVICE)
						REP		MOVSB
						JMP		UPDATE_ASSIGNMENT_MENU_NEXT

@@:
						PUSH	DI
						ADD		DI,13
						MOV		SI,OFFSET CMOSMENU_SCSIHDD
						MOV		CX,(OFFSET CMOSMENU_SCSIHDD_END)-(OFFSET CMOSMENU_SCSIHDD)
						REP		MOVSB
						POP		DI

						; TRANSLATE AH (SCSIID|PARTITION)
						XCHG	AL,AH
						PUSH	AX
						AND		AL,0FH
						CALL	ITOX8
						XCHG	AL,AH
						MOV		[DI+32],AX

						POP		AX
						SHR		AL,4
						AND		AL,0FH
						CALL	ITOX8
						XCHG	AL,AH
						MOV		[DI+22],AX

UPDATE_ASSIGNMENT_MENU_NEXT:
						POP		DI
						POP		SI
						POP		CX
						ADD		DI,MENUITEM_LENGTH
						ADD		SI,2
						DEC		CX
						JNE		UPDATE_ASSIGNMENT_MENU_OUTER_LOOP

						POP		ES
						RET
UPDATE_ASSIGNMENT_MENU		ENDP



; OUTPUT
;   AH CHOICE
CMOSMENU_CONFIRM		PROC

						CALL	MENU_WAIT_PAD_RELEASE
						CALL	CLEAR_FIVE_BELOW

						MOV		CX,3
						MOV		SI,OFFSET CMOSMENU_CONFIRM_ITEMS
						CALL	DRAWMENU

						MOV		AH,2

CMOSMENU_CONFIRM_MAINLOOP:
						; AH=SELECTION
						PUSH	AX

						MOV		CX,3
						MOV		AL,AH
						CALL	DRAWARROW

						CALL	MENU_WAIT_PAD_RELEASE

						POP		AX

@@:
						CALL	READ_PADA
						CMP		AL,3FH
						JE		@b

						MOV		CH,3
						CALL	MOVE_ARROW_BY_PAD
@@:
						AND		AL,30H
						CMP		AL,30H
						JE		CMOSMENU_CONFIRM_MAINLOOP

						PUSH	AX
						CALL	MENU_WAIT_PAD_RELEASE
						POP		AX

						; AH is still the selection

						RET
CMOSMENU_CONFIRM		ENDP



NUM_ASSIGNED_DRIVES		DB	0
SINGLE_DRIVE_MODE		DB	0
DRIVE_ASSIGNMENTS		DB	26 dup (0FFH)	; Drive D to P
						DB	0FFH,0FFH		; Stopper for preventing overflow in counting
DRIVE_COUNTER_CHECKSUM	DB	0

CMOSMENU_SELECTION		DB	0
CMOSMENU_VALUECHANGED	DB	0

                           ; 01234567890123456789012345678901234567890123456789012345678901234567890123456789
CMOSMENU_ITEMS			DB	"BACK TO MAIN MENU                                                              ",0
						DB	"HELP (PAD0 BUTTON TO SEE HELP)                                                 ",0
						DB	"SINGLE DRIVE MODE                                                              ",0
						DB	"DRIVE D                                                                        ",0
						DB	"DRIVE E                                                                        ",0
						DB	"DRIVE F                                                                        ",0
						DB	"DRIVE G                                                                        ",0
						DB	"DRIVE H                                                                        ",0
						DB	"DRIVE I                                                                        ",0
						DB	"DRIVE J                                                                        ",0
						DB	"DRIVE K                                                                        ",0
						DB	"DRIVE L                                                                        ",0
						DB	"DRIVE M                                                                        ",0
						DB	"DRIVE N                                                                        ",0
						DB	"DRIVE O                                                                        ",0
						DB	"DRIVE P                                                                        ",0
						;            0200 SCSI ID=   PART=

CMOSMENU_CONFIRM_ITEMS	DB	"SAVE CHANGES                                                                   ",0
						DB	"DISCARD CHANGES                                                                ",0
						DB	"BACK TO DRIVE-ASSIGNMENT MENU                                                  ",0

CMOSMENU_UNASSIGNED		DB	"*UNASSIGNED*"
CMOSMENU_UNASSIGNED_END:

CMOSMENU_UNKNOWNDEVICE	DB	"?UNKNOWN DEVICE?"
CMOSMENU_UNKNOWNDEVICE_END:

CMOSMENU_FLOPPYDRIVE	DB	"FLOPPY DISK DRIVE"
CMOSMENU_FLOPPYDRIVE_END:

CMOSMENU_SCSIHDD		DB	"SCSI ID=[  ] PART=[  ]"
CMOSMENU_SCSIHDD_END:

CMOSMENU_ON				DB "[ON ]"
CMOSMENU_OFF			DB "[OFF]"

CMOSMENU_MISC			DB	0,0,0

CMOSMENU_INSTRUCTION1	DB	"USE LEFT & RIGHT TO CHANGE ASSIGNMENT",0
CMOSMENU_INSTRUCTION2	DB	"ONLY LAST AND UNASSIGNED DRIVES CAN BE CHANGED",0

CMOSMENU_HELP_TEXT		DB	"- CMOS MENU HELP -",0
						DB	"USE GAMEPAD0 UP AND DOWN TO SELECT A DRIVE.",0
						DB	"USE LEFT AND RIGHT TO CHANGE ASSIGNEMENTS.",0
						DB	"DRIVE-LETTER ASSIGNMENT WILL CHANGE:",0
						DB	0
						DB	"UNASSIGNED <-> SCSI ID0 <-> ID1 <-> ID2 <-> ID3 <-> ID4 <-> ID5 <-> ID6 ",0
						DB	0
						DB	"YOU CAN CHANGE ONLY THE LAST DRIVE AND THE UNASSIGNED DRIVE THAT IS",0
						DB	"IMMEDIATELY AFTER THE LAST DRIVE.",0
						DB	0
						DB	"PRESS PAD BUTTON TO GO BACK.",0,0FFH,0FFH

