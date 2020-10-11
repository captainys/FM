TOWNSIO_MACHINEID_HIGH	EQU		0031H
TOWNSIO_WAIT_1US		EQU		006CH



; Input
;   CX   Number of microseconds to kill
;        Actual wait time is very inprecise.
;        Waits longer than CXus.
; Output
;   CX   Zero
WAIT_CX_US				PROC
						PUSH	AX

						IN		AL,TOWNSIO_MACHINEID_HIGH
						CMP		AL,1
						JE		WAIT_CX_US_MODEL2_OR_2F
						CMP		AL,2
						JE		WAIT_CX_US_MODEL2_OR_2F
@@:
						OUT		TOWNSIO_WAIT_1US,AL
						LOOP	@b
						JMP		WAIT_CX_US_RETURN

WAIT_CX_US_MODEL2_OR_2F:
						; Model2, 2F known to be 80386 16MHz
						; Need to waste 16 machine cycles to kill 1us.
						; LOOP takes 11 machine cycles.
						; 5 more machine cycles per loop.
@@:
						SUB		AX,AX	; 2 machine cycles
						NOP				; 3 machine cycles
						LOOP	@b

WAIT_CX_US_RETURN:
						POP		AX
						RET
WAIT_CX_US				ENDP
