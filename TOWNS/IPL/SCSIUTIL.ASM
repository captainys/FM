; Input
;   CL   SCSI ID
; Output
;   CL   05 or 04 means CD
;        00 means HD
;   Carry  Set if error
IDENTIFY_SCSI_DEVICE	PROC
						PUSH	DS
						MOV		AX,CS
						MOV		DS,AX
						MOV		SI,OFFSET SCSI_INQURY_CMD

						AND		CL,7
						MOV		CH,CL
						SHL		CH,5
						MOV		[SI+1],CH

						MOV		EDI,DS
						AND		EDI,0FFFFH
						SHL		EDI,4
						ADD		EDI,OFFSET SCSI_DATABUF

						CALL	SCSI_COMMAND

						MOV		CL,[SCSI_DATABUF]
						JAE		@f
						MOV		CL,0FFH
@@:
						POP		DS
						RET
IDENTIFY_SCSI_DEVICE	ENDP

SCSI_INQURY_CMD			DB		12H,0,0,0,8,0

SCSI_DATABUF			DB		256 dup (0)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; Input
;   CL    SCSI ID
;   EDX   Starting Sector
;   BX    Number of Sectors
;   EDI   Data Buffer Physical Address
;   DS=CS
; Output
;   CF    Set if error
SCSI_READ_SECTOR		PROC
						MOV		SI,OFFSET SCSI_READ_SECTOR_CMD

						AND		CL,7
						SHL		CL,5
						MOV		[SI+1],CL
						SHR		CL,5

						MOV		[SI+4],DH
						MOV		[SI+5],DL
						ROR		EDX,16
						MOV		[SI+2],DH
						MOV		[SI+3],DL

						MOV		[SI+7],BH
						MOV		[SI+8],BL

						CALL	SCSI_COMMAND

						RET
SCSI_READ_SECTOR		ENDP

SCSI_READ_SECTOR_CMD	DB	28H,0,0,0,0,0,0,0,0,0
