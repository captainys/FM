; Input DS:SI Register/Sifter table.
CRTC_SETREG				PROC
						MOV		DH,04H

						MOV		BX,0
						MOV		CX,2
						CALL	SET_CRTCREG_LOOP

						MOV		BX,4
						MOV		CX,1CH
						CALL	SET_CRTCREG_LOOP

						MOV		AH,0
						MOV		CX,4
SET_CRTCSIFTER_LOOP:
						MOV		AL,AH
						MOV		DL,48H
						OUT		DX,AL
						INC		AH
						LODSB
						MOV		DL,4AH
						OUT		DX,AL
						LOOP	SET_CRTCSIFTER_LOOP

						RET

SET_CRTCREG_LOOP:
						MOV		AX,BX
						MOV		DL,40H
						OUT		DX,AL
						LODSW
						MOV		DL,42H
						OUT		DX,AX
						INC		BX
						LOOP	SET_CRTCREG_LOOP
						RET

CRTC_SETREG				ENDP


; AX reg
; BX value
CRTC_WRITEREG			PROC
						MOV		DX,440H
						OUT		DX,AX
						MOV		DL,42H
						MOV		AX,BX
						OUT		DX,AX
						RET
CRTC_WRITEREG			ENDP


