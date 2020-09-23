
; Input
;    DS=CS
LISTSCSI				PROC

						MOV			CL,0
@@:
						PUSH		CX
						MOV			AH,1
						MOV			AL,CL
						ADD			AL,10
						CALL		LOCATE
						MOV			SI,OFFSET LISTSCSI_STR
						CALL		PRINT_TALL

						POP			AX
						PUSH		AX
						CALL		ITOX8
						XCHG		AH,AL
						MOV			WORD PTR [STR_16],AX
						MOV			[STR_16+2],0

						POP			AX
						PUSH		AX
						MOV			AH,6
						ADD			AL,10
						CALL		LOCATE
						MOV			SI,OFFSET STR_16
						CALL		PRINT_TALL

						POP			CX
						PUSH		CX
						CALL		IDENTIFY_SCSI_DEVICE

						MOV			AL,CL
						CALL		ITOX8
						XCHG		AH,AL
						MOV			WORD PTR [STR_16],AX

						POP			AX
						PUSH		AX
						MOV			AH,15
						ADD			AL,10
						CALL		LOCATE
						MOV			SI,OFFSET STR_16
						CALL		PRINT_TALL

						POP			CX
						INC			CL
						CMP			CL,7
						JB			@b

						RET

LISTSCSI				ENDP

LISTSCSI_STR			DB			"SCSI:    TYPE:",0


