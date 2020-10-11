TOWNSIO_SERIAL_ROM		EQU		0032H


; Input/Output
;   DS:DI  32-byte Seiral-ROM Buffer
; Output
;   AX,CX will be destroyed
READ_SERIAL_ROM			PROC

						; Rewind Pointer
						MOV		AL,060H	; IDRESET=0,CLK=1,CS=1
						OUT		TOWNSIO_SERIAL_ROM,AL
						MOV		AL,0E0H	; IDRESET=1,CLK=1,CS=1
						OUT		TOWNSIO_SERIAL_ROM,AL
						MOV		AL,060H	; IDRESET=0,CLK=1,CS=1
						OUT		TOWNSIO_SERIAL_ROM,AL


						; In UNZ/Tsugaru format,
						; bit N of Serial ROM corresponds to
						;   bit (N&7) of buf[31-((N>>3)&31]
						ADD		DI,31
						MOV		CH,32
READ_SERIAL_ROM_OUTER_LOOP:
						MOV		CL,1
						MOV		BYTE PTR [DI],0

READ_SERIAL_ROM_INNER_LOOP:
						IN		AL,TOWNSIO_SERIAL_ROM
						AND		AL,1
						JE		@f

						OR		BYTE PTR [DI],CL

@@:
						MOV		AL,20H	; IDRESET=0,CLK=0,CS=1
						OUT		TOWNSIO_SERIAL_ROM,AL
						MOV		AL,60H	; IDRESET=0,CLK=1,CS=1
						OUT		TOWNSIO_SERIAL_ROM,AL

						SHL		CL,1
						JAE		READ_SERIAL_ROM_INNER_LOOP


						SUB		DI,1
						DEC		CH
						JNE		READ_SERIAL_ROM_OUTER_LOOP

						INC		DI

						RET
READ_SERIAL_ROM			ENDP
