



DEMO2019_SPIN_SQUARE	CLRB
						CLR		,-S				; Size


DEMO2019_SPIN_SQUARE_LOOP
						PSHS	B
						LEAU	COORD_AREA,PCR
						CLR		,-S

						BITB	#1
						BEQ		DEMO2019_SPIN_SQUARE_INSIDE_LOOP
						INC		2,S

DEMO2019_SPIN_SQUARE_INSIDE_LOOP
						LDA		2,S
						LDB		1,S
						ADDB	,S
						LBSR	COS8
						TFR		A,B

						SEX
						LSLB
						ASRA

						ADDD	#160
						STD		,U++	; X

						LDA		2,S
						LDB		1,S
						ADDB	,S
						LBSR	SIN8
						TFR		A,B

						SEX
						LSLB
						ASRA

						ADDD	#100
						STD		,U++	; Y

						LDA		,S
						ADDA	#64
						STA		,S
						BNE		DEMO2019_SPIN_SQUARE_INSIDE_LOOP

						PULS	A


						LDD		COORD_AREA,PCR
						STD		,U
						LDD		COORD_AREA+2,PCR
						STD		2,U


						LBSR	HALT_SUBCPU
						LBSR	MMR_ENABLE_ACCESS_SUBCPU_RAM


						LEAX	COORD_AREA,PCR
						LDY		#LINEDATA_BUF



						; LDA		,S
						; ANDA	#1
						; ADDA	#LINE_CMD_SELECT_BANK0
						; STA		,Y+


						
						LDA		,S
						ANDA	#1
						LSLA
						LSLA
						LSLA
						LSLA
						LSLA


						LDB		#LINE_CMD_HALF_CLS
						STB		,Y+
						CLRB
						STD		,Y++

						LDB		#LINE_CMD_SET_OFFSET
						STB		,Y+
						CLRB
						STD		,Y++


						LDA		#LINE_CMD_2D_CLIPPING
						STA		,Y+
						LDA		#4		; 4 lines
						STA		,Y+


						LDB		#4
DEMO2019_SPIN_SQUARE_TRANSFER_LOOP
						PSHS	B

						ADDB	#3
						STB		,Y+				;C

						LDD		,X++			;X
						STD		,Y++
						LDD		,X++			;Y
						STD		,Y++

						LDD		,X				;X
						STD		,Y++
						LDD		2,X				;Y
						STD		,Y++

						PULS	B
						DECB
						BNE		DEMO2019_SPIN_SQUARE_TRANSFER_LOOP


						LDA		#LINE_CMD_2D_END_OF_CMDSET
						STA		,Y+


						LBSR	MMR_DISABLE
						LBSR	RELEASE_SUBCPU


						PULS	B
						DECB
						LBNE	DEMO2019_SPIN_SQUARE_LOOP


						PULS	B,PC

