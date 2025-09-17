
; Test program to see the behavior of TEST UNIT READY and REQUEST SENSE commands
; while a SCSI CD drive is spinning up.
;
; Test on the actual FM TOWNS 2MX showed that when the CD drive is spinning up,
; TEST UNIT READY returns CHECK CONDITION status, but the subsequent REQUEST SENSE
; command returns nothing.  Probably I should only use TEST UNIT READY to wait for
; the CD drive to spin up.



SCSI_SENSEKEY_NO_SENSE		EQU		0
SCSI_SENSEKEY_RECOVERED		EQU		1
SCSI_SENSEKEY_NOT_READY		EQU		2
SCSI_SENSEKEY_MEDIUM_ERROR	EQU		3
SCSI_SENSEKEY_HARD_ERROR	EQU		4
SCSI_SENSEKEY_ILLEGAL_REQ	EQU		5
SCSI_SENSEKEY_MEDIA_CHANGED	EQU		6
SCSI_SENSEKEY_DATA_PROTEDT	EQU		7





CODE					SEGMENT		USE16


REALMAIN				PROC

						; Input   AL 0:Open Lid  1:Close Lid
						AND		AL,AL
						JE		REALMAIN_OPENLID

						; Close Lid
						MOV		BYTE PTR CS:[SCSICMD_START_STOP+4],3	; LoEj=1, Start=1 Close lid and start
						MOV		DI,OFFSET TITLE_LOGO_CLOSE

						JMP		REALMAIN_OPEN_CLOSE_SET


REALMAIN_OPENLID:
						; Open Lid

						MOV		BYTE PTR CS:[SCSICMD_START_STOP+4],2	; LoEj=1, Start=0 Open lid and stop
						MOV		DI,OFFSET TITLE_LOGO_OPEN


REALMAIN_OPEN_CLOSE_SET:
						MOV		DX,0EFEFH  ; Use BRKON IOW EFEF for breaking
						OUT		DX,AL

						PUSH	CS
						POP		DS
						PUSH	CS
						POP		ES
						CALL	PRINT_CSTR


						MOV		AH,62H	; GET PSP
						INT		21H

						PUSH	DS

						MOV		DS,BX
						MOV		SI,81H
						CALL	SKIP_SPACE_TAB
						CALL	XTOI
						MOV		ES:[SCSIID],AL	; SCSI ID

						CALL	PRINT_REGISTER
						CALL	PRINT_CRLF

						POP		DS



						XCHG	AX,DX
						CALL	PRINT_AX
						XCHG	AX,DX
						CALL	PRINT_AX
						CALL	PRINT_CRLF


@@:
						MOV		CL,CS:[SCSIID]

						MOV		EDI,0
						MOV		DI,CS
						SHL		DI,4
						ADD		EDI,OFFSET DATABUF

						MOV		SI,OFFSET SCSICMD_START_STOP

						CALL	SCSI_COMMAND

						JAE		UNIT_IS_READY

						CMP		AH,2	; CHECK STATUS
						JNE		UNKNOWN_ERROR


						MOV		CL,CS:[SCSIID]

						MOV		EDI,0
						MOV		DI,CS
						SHL		DI,4
						ADD		EDI,OFFSET DATABUF

						MOV		SI,OFFSET SCSICMD_REQUEST_SENSE

						CALL	SCSI_COMMAND

						CMP		AH,0
						JNE		SENSE_FAILED

						; ILLEGAL REQUEST, NO SENSE, or NOT READY
HAVE_SENSE:
						MOV		AH,CS:[DATABUF]
						MOV		AL,CS:[DATABUF+2]
						CALL	PRINT_AX
						MOV		AL,CS:[SCSI_PHASE_FLAG]
						CALL	PRINT_AL
						CALL	PRINT_CRLF

						MOV		AL,CS:[DATABUF+2]
						AND		AL,0FH
						CMP		AL,SCSI_SENSEKEY_NOT_READY
						JE		@b

						JMP		UNKNOWN_ERROR



UNIT_IS_READY:
						MOV		DI,OFFSET MSG_UNIT_IS_READY
						CALL	PRINT_CSTR
						CALL	PRINT_CRLF
						JMP		EXIT_PROGRAM

UNKNOWN_ERROR:
						MOV		DI,OFFSET MSG_UNKNOWN_ERROR
						CALL	PRINT_CSTR
						CALL	PRINT_CRLF
						JMP		EXIT_PROGRAM

SENSE_FAILED:
						MOV		DI,OFFSET MSG_SENSE_FAILED
						CALL	PRINT_CSTR
						CALL	PRINT_CRLF
						JMP		EXIT_PROGRAM


EXIT_PROGRAM:
						MOV		AH,4CH
						INT		21H

REALMAIN				ENDP



MAKEPRINTABLE			PROC
						CMP		AL,32
						JB		@f
						CMP		AL,126
						JA		@f
						RET
@@:
						MOV		AL,'.'
						RET
MAKEPRINTABLE			ENDP




SKIP_SPACE_TAB			PROC
						CLD
@@:						LODSB
						CMP		AL,' '
						JE		@b
						CMP		AL,9
						JE		@b
						SUB		SI,1
						RET
SKIP_SPACE_TAB			ENDP



; DS:SI  In   Pointer to the hexadecimal
; DX:AX  Out  32-bit value
; SI          Points to the char after the word
; BX          Destroyed
XTOI					PROC
						XOR		DX,DX
						XOR		BX,BX

@@:						LODSB
						CALL	XCTOI
						JB		@f

						SHLD	DX,BX,4
						SHL		BX,4
						OR		BL,AL
						JMP		@b
@@:
						MOV		AX,BX
						RET
XTOI					ENDP



; AL In   ASCII code
; AL Out  0 to F
; CF Out  1 if not a hexadecimal
XCTOI					PROC
						CMP		AL,'0'
						JB		@f
						CMP		AL,'9'
						JA		@f
						SUB		AL,'0'
						CLC
						RET
@@:
						CMP		AL,'A'
						JB		@f
						CMP		AL,'F'
						JA		@f
						SUB		AL,'A'-10
						CLC
						RET
@@:
						CMP		AL,'a'
						JB		@f
						CMP		AL,'f'
						JA		@f
						SUB		AL,'a'-10
						CLC
						RET
@@:
						STC
						RET

XCTOI					ENDP



						INCLUDE	../../YSSCSICD/PRINT.ASM
						INCLUDE	../../SCSILIB/SCSIIO.ASM
CODE					ENDS



CODE					SEGMENT	USE16
TITLE_LOGO_OPEN			DB		"SCSIOPEN by CaptainYS http://www.ysflight.com",0DH,0AH,0
TITLE_LOGO_CLOSE		DB		"SCSICLOS by CaptainYS http://www.ysflight.com",0DH,0AH,0

SCSIID					DB		0

SCSICMD_START_STOP		DB		1Bh		; +0 Cmd
						DB		1		; +1 Immed
						DB		0,0		; +2,+3 Reserved
						DB		0		; +4 LoEj|Start
						DB		0		; +5 Control

SCSICMD_REQUEST_SENSE	DB		3,0,0,0,18,0

MSG_UNIT_IS_READY		DB		"Unit is ready.",0
MSG_UNKNOWN_ERROR		DB		"Unknown Error.",0
MSG_SENSE_FAILED		DB		"Sense failed.",0

; 2048 should be good enough for CD-ROM sectors
DATABUF					DB		4096 dup(0)

CODE					ENDS



STACK					SEGMENT	STACK USE16

						DB	1024 DUP(0)

STACK					ENDS
