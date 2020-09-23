; Input
;   CL   SCSI
; Output
;   CL   05 or 04 means CD
;        00 means HD
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
