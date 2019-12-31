						ASSUME		CS:CODE

						.386p

CODE					SEGMENT

CDDA_STOP_AND_RESTORE	PROC

;000C:0001062B 66BAC004                 MOV	DX,04C0
;000C:0001062F B082                     MOV	AL,82         ; MPU Reset|MPU IRQ Enable
;000C:00010631 EE                       OUT	DX,AL
;000C:00010632 66BAC204                 MOV	DX,04C2
;000C:00010636 B084                     MOV	AL,84          ;CMD_TYPE|CDDASTOP
;000C:00010638 EE                       OUT	DX,AL
;000C:00010639 66BAC404                 MOV	DX,04C4        ;Parameter Register
;000C:0001063D 2BC0                     SUB	EAX,EAX
;000C:0001063F EE                       OUT	DX,AL
;000C:00010640 EE                       OUT	DX,AL
;000C:00010641 EE                       OUT	DX,AL
;000C:00010642 EE                       OUT	DX,AL
;000C:00010643 EE                       OUT	DX,AL
;000C:00010644 EE                       OUT	DX,AL
;000C:00010645 EE                       OUT	DX,AL
;000C:00010646 EE                       OUT	DX,AL

						ORG		0001062BH
						PUSH	EDI
						PUSH	ECX
						MOV		AX,52C0H
						MOV		CX,0000H
						INT		93H
						POP		ECX
						POP		EDI
						XOR		EAX,EAX
						NOP
						NOP
						NOP
						NOP
						NOP
						NOP
						NOP
						NOP
						NOP
						NOP
						NOP
						NOP
						NOP
						NOP
						NOP
						NOP


CDDA_STOP_AND_RESTORE	ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CDDA_COMMAND			PROC
						ORG		00010690H
						
;[000DD810]==FFFFFFFF  NOP
;[000DD810]==0  STOP
;[000DD810]==1  Play EAX=000DD7AC, [EAX+78]~  (DD824~) Start and end times
;[000DD810]==2  Play EAX=000DD7AC, [EAX+78]~  (DD824~) Start and end times
;[000DD810]==3  ? (Command 86H CDDAxxx)
;[000DD810]==4  Resume
;[000DD810]==5  Restore

						PUSHA
						MOV		EAX,DWORD PTR DS:[000DD810H]
						CMP		EAX,0
						JE		CDDA_STOP
						CMP		EAX,1
						JE		CDDA_PLAY
						CMP		EAX,2
						JE		CDDA_PLAY
						CMP		EAX,4
						JE		CDDA_RESUME
						CMP		EAX,5
						JE		CDDA_RESTORE
						JMP		CDDA_COMMAND_EXIT


CDDA_STOP:
						MOV		AX,52C0H	; Should I Pause (55C0H) instead?
						MOV		CX,0
						INT		93H
						JMP		CDDA_COMMAND_EXIT
CDDA_RESUME:
						MOV		AX,56C0H
						MOV		CX,0
						INT		93H
						JMP		CDDA_COMMAND_EXIT
CDDA_RESTORE:
						MOV		AX,03C0H
						MOV		CX,0
						INT		93H
						JMP		CDDA_COMMAND_EXIT

CDDA_PLAY:
						; Requires YSCDPLAY.SYS
						PUSH	EDX
						PUSH	ECX
						PUSH	EBX
						PUSH	EAX

						MOV		AX,55C0H	; Should I Pause (55C0H) instead?
						MOV		CX,0
						INT		93H

						MOV		BX,WORD PTR DS:[000DD7ACH+78H]
						MOV		CX,WORD PTR DS:[000DD7ACH+7AH]
						MOV		DX,WORD PTR DS:[000DD7ACH+7CH]
						MOV		AX,72C0H ; Play BCD
						INT		93H		 ; Service from YSCDPLAY.SYS

						POP		EAX
						POP		EBX
						POP		ECX
						POP		EDX

						JMP		CDDA_COMMAND_EXIT


;						PUSH	ES
;
;						MOV		AX,250DH		; DOS Extender Get Real-Mode Link Information
;						INT		21H
;
;
;						; Save current contents of the shared buffer
;						MOV		EAX,ES:[EDX]
;						PUSH	EAX
;						MOV		EAX,ES:[EDX+4]
;						PUSH	EAX
;						PUSH	EDX
;						PUSH	ES
;
;
;						MOV		CL,6
;						MOV		EDI,000DD7ACH+78H
;CDDA_PLAY_COPY_LOOP:
;						MOV		AL,[EDI]
;						CALL	BCD2BIN
;						MOV		ES:[EDX],AL
;						INC		EDX
;						INC		EDI
;						DEC		CL
;						JNE		CDDA_PLAY_COPY_LOOP
;
;						SUB		ESP,12H
;						;Offset Size Description (Table 01361) 
;						;00h WORD interrupt number 
;						;02h WORD real-mode DS value 
;						;04h WORD real-mode ES value 
;						;06h WORD real-mode FS value 
;						;08h WORD real-mode GS value 
;						;0Ah DWORD real-mode EAX value 
;						;0Eh DWORD real-mode EDX value 
;						MOV		WORD PTR [ESP],93H
;
;						MOV		DI,BX
;						MOV		CX,0001H
;						ROR		EBX,16
;						MOV		[ESP+2],BX
;						MOV		[ESP+4],BX
;						MOV		[ESP+6],BX
;						MOV		[ESP+8],BX
;						MOV		DWORD PTR [ESP+0AH],50C0H	; Play CDDA, Device=C0H
;						MOV		DWORD PTR [ESP+0EH],0
;						LEA		EDX,[ESP]
;						MOV		AX,2511H
;						PUSH	DS
;						PUSH	SS
;						POP		DS
;						INT		21H
;						POP		DS
;
;						ADD		ESP,12H
;
;
;						POP		ES
;						POP		EDX
;						POP		EAX
;						MOV		ES:[EDX+4],EAX
;						POP		EAX
;						MOV		ES:[EDX],EAX
;
;
;						POP		ES
;						JMP		CDDA_COMMAND_EXIT

CDDA_COMMAND_EXIT:
						POPA
						MOV		DWORD PTR DS:[000DD810H],-1
						RET


BCD2BIN:				PUSH	BX

						MOV		BL,AL
						AND		BL,0FH

						SHR		AL,4
						MOV		AH,10
						MUL		AH

						ADD		AL,BL

						POP		BX
						RET


CDDA_COMMAND			ENDP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CDDAxxx_AND_PAUSE		PROC

						ORG		00010AA0H

						PUSH	ECX

						MOV		AX,55C0H
						MOV		CX,0
						INT		93H

						MOV		DWORD PTR DS:[000DD818H],0
						MOV		DWORD PTR DS:[000DD814H],3

						POP		ECX

						RET

CDDAxxx_AND_PAUSE		ENDP

CODE					ENDS

						END
