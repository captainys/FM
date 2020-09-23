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

@@:
						RET
BOOT_FROM_SCSI_CD		ENDP



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




