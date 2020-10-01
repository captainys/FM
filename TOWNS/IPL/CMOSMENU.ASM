IO_CMOS_D_DRIVE					EQU		31E8H
IO_CMOS_P_DRIVE					EQU		3218H
IO_CMOS_SINGLE_DRIVE_MODE		EQU		328CH
IO_CMOS_DRIVE_COUNTER_CHECKSUM	EQU		33CEH

MAX_NUM_DRIVE_ASSIGNMENTS		EQU		'Q'-'D'

CMOSMENU_RETUR_TO_MAINMENU		EQU		0
CMOSMENU_ITEMNUM_DRIVE_D		EQU		2

BOOTDEVICETYPE_FLOPPYDRIVE		EQU		0
BOOTDEVICETYPE_ROMDRIVE			EQU		5
BOOTDEVICETYPE_HARDDRIVE		EQU		2
BOOTDEVICETYPE_UNASSIGNED		EQU		0FFH


CMOSMENU				PROC
						CALL	READ_CMOS_DRIVE_ASSIGNMENTS
						CALL	UPDATE_ASSIGNMENT_MENU

						MOV		BYTE PTR CS:[CMOSMENU_SELECTION],0

CMOSMENU_MAINLOOP:
						CALL	MENU_WAIT_PAD_RELEASE

						CALL	CLEAR_FIVE_BELOW

						CALL	COUNT_CMOSMENU_CHOICES
						MOVZX	CX,BL
						MOV		SI,OFFSET CMOSMENU_ITEMS
						CALL	DRAWMENU

						MOV		AX,DISPLACED_DEMOSPLASh_MESSAGE_LOCATION
						CALL	DEMOSPLASH_MESSAGE_MOVABLE

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

						AND		AL,30H
						CMP		AL,30H
						JE		CMOSMENU_MAINLOOP

						; AH is still the selection
						CMP		AH,CMOSMENU_RETUR_TO_MAINMENU
						JNE		@f
						RET


@@:
						JMP		CMOSMENU_MAINLOOP

CMOSMENU				ENDP



READ_CMOS_DRIVE_ASSIGNMENTS	PROC
						PUSH	ES

						PUSH	CS
						POP		ES
						MOV		DX,IO_CMOS_D_DRIVE
						MOV		DI,OFFSET DRIVE_ASSIGNMENTS
@@:
						IN		AL,DX
						STOSB
						ADD		DX,2
						IN		AL,DX
						STOSB
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
						MOV		CX,MAX_NUM_DRIVE_ASSIGNMENTS
						MOV		DI,OFFSET CMOSMENU_ITEMS+CMOSMENU_ITEMNUM_DRIVE_D*80
						MOV		SI,OFFSET DRIVE_ASSIGNMENTS

UPDATE_ASSIGNMENT_MENU_OUTER_LOOP:
						PUSH	CX
						PUSH	SI
						PUSH	DI

						ADD		DI,9
						MOV		CX,80-9-1
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
						MOV		[DI+29],AX

						POP		AX
						SHR		AL,4
						AND		AL,0FH
						CALL	ITOX8
						XCHG	AL,AH
						MOV		[DI+21],AX

UPDATE_ASSIGNMENT_MENU_NEXT:
						POP		DI
						POP		SI
						POP		CX
						ADD		DI,80
						ADD		SI,2
						DEC		CX
						JNE		UPDATE_ASSIGNMENT_MENU_OUTER_LOOP

						POP		ES
						RET
UPDATE_ASSIGNMENT_MENU		ENDP




NUM_ASSIGNED_DRIVES		DB	0
SINGLE_DRIVE_MODE		DB	0
DRIVE_ASSIGNMENTS		DB	26 dup (0FFH)	; Drive D to P
						DB	0FFH,0FFH		; Stopper for preventing overflow in counting
DRIVE_COUNTER_CHECKSUM	DB	0

CMOSMENU_SELECTION		DB	0

                           ; 01234567890123456789012345678901234567890123456789012345678901234567890123456789
CMOSMENU_ITEMS			DB	"BACK TO MAIN MENU                                                              ",0
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

CMOSMENU_UNASSIGNED		DB	"*UNASSIGNED*"
CMOSMENU_UNASSIGNED_END:

CMOSMENU_UNKNOWNDEVICE	DB	"?UNKNOWN DEVICE?"
CMOSMENU_UNKNOWNDEVICE_END:

CMOSMENU_FLOPPYDRIVE	DB	"FLOPPY DISK DRIVE"
CMOSMENU_FLOPPYDRIVE_END:

CMOSMENU_SCSIHDD		DB	"SCSI ID=   PART="
CMOSMENU_SCSIHDD_END:
