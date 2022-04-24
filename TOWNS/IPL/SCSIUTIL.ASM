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
						MOV		BYTE PTR [SI+1],0  ; Looks like Logical Unit ID needs to be zero.

						MOV		EDI,DS
						MOVZX	EDI,DI
						SHL		EDI,4
						ADD		EDI,OFFSET SCSI_DATABUF

						CALL	SCSI_COMMAND

						MOV		CL,[SCSI_DATABUF]
						JAE		SHORT @f
						MOV		CL,0FFH
@@:
						POP		DS
						RET
IDENTIFY_SCSI_DEVICE	ENDP

SCSI_INQURY_CMD			DB		12H,0,0,0,8,0



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
						MOV		BYTE PTR [SI+1],0 ; Looks like Logical Unit ID needs to be zero.

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



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; Input
;   CL SCSI ID
; Output
;   AH      0 Unit is ready
;           Non Zero (Most likely 2) Unit is not ready
SCSI_TEST_UNIT_READY	PROC
						PUSH	DS

						PUSH	CS
						POP		DS
						AND		CL,7
						MOV		SI,OFFSET SCSI_TEST_UNIT_READY_CMD
						MOV		EDI,0
						MOV		DI,CS
						SHL		EDI,4
						ADD		EDI,OFFSET SCSI_DATABUF
						; TEST_UNIT_READY is not supposed to return data.
						; But, just in case.
						CALL	SCSI_COMMAND

						POP		DS
						RET

SCSI_TEST_UNIT_READY	ENDP

SCSI_TEST_UNIT_READY_CMD	DB		0,0,0,0,0,0



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; Input
;   CL SCSI ID
SCSI_SENSE				PROC
						PUSH	DS

						PUSH	CS
						POP		DS
						AND		CL,7
						MOV		SI,OFFSET SCSI_SENSE_CMD
						MOV		EDI,0
						MOV		DI,CS
						SHL		EDI,4
						ADD		EDI,OFFSET SCSI_DATABUF
						CALL	SCSI_COMMAND
						POP		DS
						RET

SCSI_SENSE				ENDP


SCSI_SENSE_CMD			DB	03H,0,0,0,18,0



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
