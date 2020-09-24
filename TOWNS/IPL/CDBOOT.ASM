;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



BOOT_FROM_SCSI_CD		PROC
						CALL	LISTSCSI
						CALL	FIND_LAST_SCSI_CD
						CMP		AL,0FFH
						JE		@f

						MOV		CL,AL
						PUSH	CX
						CALL	FIND_FBIOS_SECTOR
						POP		CX
						JB		@f

						; CL=SCSI ID
						; EAX=Sector where FBIOS is written
						MOV		EDX,EAX
						MOV		BX,64
						MOV		EDI,0400H
						CALL	SCSI_READ_SECTOR
						JB		@f

						MOV		AX,0050H
						MOV		FS,AX
						MOV		AX,FS:[0]
						MOV		FS,AX
						CALL	FIND_JUMP_INSTRUCTION
						JB		@f

						PUSH	FS
						PUSH	SI

						MOV		BP,SP
						MOV		AL,[BP+2]  ; Low Byte FS
						CALL	ITOX8
						XCHG	AL,AH
						MOV		WORD PTR [BOOT_SCSICD_FOUND_MSG+16],AX

						MOV		AL,[BP+3]  ; High Byte FS
						CALL	ITOX8
						XCHG	AL,AH
						MOV		WORD PTR [BOOT_SCSICD_FOUND_MSG+14],AX

						MOV		AL,[BP]  ; Low Byte SI
						CALL	ITOX8
						XCHG	AL,AH
						MOV		WORD PTR [BOOT_SCSICD_FOUND_MSG+21],AX

						MOV		AL,[BP+1]  ; High Byte SI
						CALL	ITOX8
						XCHG	AL,AH
						MOV		WORD PTR [BOOT_SCSICD_FOUND_MSG+19],AX

						MOV		AX,0106H
						CALL	LOCATE
						MOV		SI,OFFSET BOOT_SCSICD_FOUND_MSG
						CALL	PRINT_TALL

						POP		SI
						POP		FS

						MOV		AX,FS:[SI+1]
						MOV		CS:[IOSYS_RESUME_IP],AX
						MOV		AX,FS:[SI+3]
						MOV		CS:[IOSYS_RESUME_CS],AX

						MOV		WORD PTR FS:[SI+1],OFFSET IOSYS_INTERCEPT
						MOV		FS:[SI+3],CS

						MOV		CS:[IOSYS_ENTRY_CS],FS

						; MOV		BX,0002H
						MOV		AX,0F7FFH	; This will make IO.SYS think B0000H to BFFFFH block is inaccessible.
						MOV		DI,0
						MOV		DX,0
						MOV		CX,0280H  ; Pretend CD-ROM Drive
						DB		0EAH   ; JMPF
IOSYS_ENTRY_IP			DW		0000H ; Fixed
IOSYS_ENTRY_CS			DW		0000H


@@:
						
						RET
BOOT_FROM_SCSI_CD		ENDP

BOOT_SCSICD_ERROR_MSG	DB		"BOOT SEQUENCE FAILED",0
BOOT_SCSICD_FOUND_MSG	DB		"JMPF FOUND AT xxxx:xxxx",0


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; Input
;    DS=CS
LISTSCSI				PROC

						MOV			CL,0
@@:
						PUSH		CX

						POP			AX
						PUSH		AX
						CALL		ITOX8
						XCHG		AH,AL
						MOV			WORD PTR [LISTSCSI_STR+5],AX

						POP			CX
						PUSH		CX
						CALL		IDENTIFY_SCSI_DEVICE

						MOV			AL,CL
						CALL		ITOX8
						XCHG		AH,AL
						MOV			WORD PTR [LISTSCSI_STR+14],AX

						POP			AX
						PUSH		AX
						MOV			AH,1
						ADD			AL,10
						CALL		LOCATE
						MOV			SI,OFFSET LISTSCSI_STR
						CALL		PRINT_TALL

						POP			CX
						INC			CL
						CMP			CL,7
						JB			@b

						RET

LISTSCSI				ENDP

LISTSCSI_STR			DB			"SCSI:  H TYPE:  H",0



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; Input
;   DS=CS
; Output
;   AL  Last SCSI CD ID (0FFH means no CD)
FIND_LAST_SCSI_CD		PROC
						MOV		CL,6
						MOV		AL,0FFH
FIND_LAST_SCSI_CD_LOOP:
						PUSH	CX

						PUSH	AX
						CALL	IDENTIFY_SCSI_DEVICE
						POP		AX
						JB		@f

						CMP		CL,4
						JB		@f
						CMP		CL,5
						JA		@f
						POP		AX	; Get CX value to AX
						PUSH	AX
@@:
						POP		CX
						AND		CL,CL
						JE		@f
						DEC		CL
						JMP		FIND_LAST_SCSI_CD_LOOP
@@:
						CMP		AL,0FFH
						JE		@f
						PUSH	AX
						CALL	ITOX8
						MOV		[FIND_LAST_SCSI_CD_ID],AH
						MOV		[FIND_LAST_SCSI_CD_ID+1],AL
						MOV		AX,0104H
						CALL	LOCATE
						MOV		SI,OFFSET FIND_LAST_SCSI_CD_STR1
						CALL	PRINT_TALL
						POP		AX
						RET
@@:
						MOV		AX,0104H
						CALL	LOCATE
						MOV		SI,OFFSET FIND_LAST_SCSI_CD_STR2
						CALL	PRINT_TALL
						MOV		AL,0FFH
						RET

FIND_LAST_SCSI_CD		ENDP

FIND_LAST_SCSI_CD_STR1	DB	"CD DRIVE FOUND AT SCSI ID="
FIND_LAST_SCSI_CD_ID	DB	0,0,'H',0
FIND_LAST_SCSI_CD_STR2	DB	"SCSI CD DRIVE NOT FOUND",0



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; Input
;   CL  SCSI ID
; Output
;   EAX Sector starting with "FBIOS"
;   CF  Set if not found
FIND_FBIOS_SECTOR		PROC

						MOV		AX,0040H
						MOV		FS,AX

						MOV		EDX,10	; I think starting sector 10 is good enough
FIND_FBIOS_SECTOR_LOOP:
						PUSH	EAX
						PUSH	ECX
						PUSH	EDX

						MOV		EDI,0400H
						MOV		BX,1
						CALL	SCSI_READ_SECTOR

						POP		EDX
						POP		ECX
						POP		EAX

						CMP		DWORD PTR FS:[0],4F494246H ; "FBIO"
   						JNE		@f
						CMP		BYTE PTR FS:[4],53H ; 'S'
						JE		FIND_FBIOS_SECTOR_FOUND
@@:
						ADD		EDX,1
						CMP		EDX,40
						JNE		FIND_FBIOS_SECTOR_LOOP
						MOV		AX,0105H
						CALL	LOCATE
						MOV		SI,OFFSET FIND_FBIOS_SECTOR_NOT_FOUND_MESSAGE
						CALL	PRINT_TALL
						STC
						RET

FIND_FBIOS_SECTOR_FOUND:
						MOV		EAX,EDX
						PUSH	EAX
						CALL	ITOX8
						XCHG	AH,AL
						MOV		WORD PTR [FIND_FBIOS_SECTOR_FOUND_MESSAGE+30],AX
						MOV		AX,0105H
						CALL	LOCATE
						MOV		SI,OFFSET FIND_FBIOS_SECTOR_FOUND_MESSAGE
						CALL	PRINT_TALL
						POP		EAX
						CLC
						RET

FIND_FBIOS_SECTOR_FOUND_MESSAGE		DB	"IO.SYS(FBIOS) FOUND AT SECTOR   H",0 ; 30,31
FIND_FBIOS_SECTOR_NOT_FOUND_MESSAGE		DB	"IO.SYS(FBIOS) NOT FOUND",0

FIND_FBIOS_SECTOR		ENDP



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; Input
;   FS    IO.SYS Start Segment
; Output
;   SI    Offset to the JMPF xxxx:0000
;   CF    Set if not found
FIND_JUMP_INSTRUCTION	PROC
						MOV		SI,0

FIND_JUMP_INSTRUCTION_LOOP:
						MOV		AL,FS:[SI]
						CALL	E8_OR_BE
						JNE		FIND_JUMP_INSTRUCTION_NEXT

						MOV		CX,10
						PUSH	SI
@@:
						ADD		SI,3
						MOV		AL,FS:[SI]
						CALL	E8_OR_BE
						JNE		@f
						LOOP	@b

						ADD		SI,3
						MOV		AL,FS:[SI]
						CMP		AL,0EAH		; JMPF
						JNE		@f

						; Found it!
						ADD		SP,2
						JMP		FIND_JUMP_INSTRUCTION_FOUND

@@:
						POP		SI

FIND_JUMP_INSTRUCTION_NEXT:
						INC		SI
						CMP		SI,0FF00H	; Must not be that late in the segment
						JNE		FIND_JUMP_INSTRUCTION_LOOP
						STC
						RET

FIND_JUMP_INSTRUCTION_FOUND:
						CLC
						RET

; Return ZF=1 if AL==E8 or BE
E8_OR_BE:
						CMP		AL,0E8H	; CALL
						JE		@f
						CMP		AL,0BEH ; MOV SI,
@@:						RET


FIND_JUMP_INSTRUCTION	ENDP



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; Intercept IO.SYS jump to MSDOS.SYS
IOSYS_INTERCEPT			PROC

						PUSH	CS
						POP		DS

						; Turned out MSDOS.SYS is copied to the conventional memory, but not installed yet.

@@:
						JMP		@b

						DB		0EAH ; JMPF
IOSYS_RESUME_IP			DW		0
IOSYS_RESUME_CS			DW		0

IOSYS_INTERCEPT_MESSAGE	DB		"INTERCEPTED IO.SYS$",0



IOSYS_INTERCEPT			ENDP
