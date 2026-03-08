;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


CHECK_INTERNAL_CD_READY	PROC
						MOV		ECX,2000000
						MOV		DX,04C0H

WAIT_CDC_READY:
						IN		AL,DX
						AND		AL,1
						JNE		INTERNAL_CD_CONTROLLER_READY	; CDC is ready to accept a command

						OUT		06Ch,AL		; Wait 1us.  For earlier models, don't worry.  CPU is slow enough.

						DEC		ECX
						JNE		WAIT_CDC_READY

						; If CDC doesn't become ready in 2 seconds, probably the drive is removed.
						STC
						RET





INTERNAL_CD_CONTROLLER_READY:
						MOV		AX,0EC0h
						XOR		CX,CX

						; How can I write CALL 		FAR PTR 0FFFBH:0014H
						DB		9AH		; CALLF FFFB:0014
						DW		 0014H
						DW		0FFFBH

						JC		SHORT @f
						SUB		AH,1
						CMC
@@:
						RET
CHECK_INTERNAL_CD_READY	ENDP


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
