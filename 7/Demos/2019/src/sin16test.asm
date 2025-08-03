SIN16_ROT16_TEST_STACK_SIZE		EQU	16

						EXPORT	SIN16_ROT16_TEST


SIN16_ROT16_TEST		
						LDB		#SIN16_ROT16_TEST_STACK_SIZE
SIN16_ROT16_TEST_CLEAR_LOCAL
						CLR		,-S
						DECB
						BNE		SIN16_ROT16_TEST_CLEAR_LOCAL


						LBSR	HALT_SUBCPU
						LBSR	MMR_ENABLE_ACCESS_SUBCPU_RAM

						LDY		#LINEDATA_BUF

						LDA		#LINE_CMD_SELECT_BANK1
						STA		,Y+
						LDA		#LINE_CMD_CLS
						STA		,Y+
						LDA		#LINE_CMD_SELECT_BANK0
						STA		,Y+
						LDA		#LINE_CMD_CLS
						STA		,Y+
						LDA		#LINE_CMD_2D_END_OF_CMDSET
						STA		,Y+


						LBSR	MMR_DISABLE
						LBSR	RELEASE_SUBCPU


						;	[15,S]	Color
						;	[14,S]	Color
						;	[13,S]	Color
						;	[11,S]	16-bit Radius
						;	[10,S]	8-bit Angle
						;	[8,S]	dy
						;	[6,S]	dx
						;	[4,S]	16-bit cy
						;	[2,S]	16-bit cx
						;	[1,S]	Angle0
						;	[,S]	Outer-loop counter


						LDX		#40
						STX		11,S

SIN16_ROT16_TEST_OUTER_LOOP
						CLR		,S
						INC		1,S

SIN16_ROT16_TEST_INNER_LOOP
						LDB		,S
						CLRA
						LEAX	SIN16_ROT16_TEST_CENTER_TABLE,PCR
						LEAX	D,X
						LDD		,X++
						STD		2,S
						LDD		,X++
						STD		4,S


						LDD		11,S
						STD		6,S
						LDD		#0
						STD		8,S

						LDA		#2
						STA		13,S
						LDA		#7
						STA		14,S
						LDA		#1
						STA		15,S



	 					LEAU	PROJECTION_AREA,PCR

						LDD		11,S
						STD		6,S
						LDD		#0
						STD		8,S

						LDA		#$40
						STA		10,S
						LDX		6,S
						LDY		8,S
						LDB		1,S		; Angle0
						LBSR	ROT16

SIN16_ROT16_ROUND_LOOP
						LDB		#8
						LBSR	ROT16
						STX		,U++
						STY		,U++

						DEC		10,S
						BNE		SIN16_ROT16_ROUND_LOOP



						LBSR	HALT_SUBCPU
						LBSR	MMR_ENABLE_ACCESS_SUBCPU_RAM

						LDU		#LINEDATA_BUF
						LEAX	PROJECTION_AREA,PCR
						LDA		#LINE_CMD_2D_CLIPPING		; Draw 2D lines with clipping. (#lines, CXYXYCXYXY....  C:8bit X:16bit  Y:16bit)
						STA		,U+

						LDA		#32
						STA		,U+		; # Lines
						STA		10,S

SIN16_ROT16_TEST_TRANSFER_LOOP
						LDA		15,S	; Color
						STA		,U+

						LDY		13,S	; Rotate Red White and Blue
						STY		14,S
						STA		13,S

						LDD		2,S		; Center XY
						STD		,U++
						LDD		4,S
						STD		,U++

						LDD		,X++
						ADDD	2,S
						STD		,U++
						LDD		,X++
						ADDD	4,S
						STD		,U++

						DEC		10,S
						BNE		SIN16_ROT16_TEST_TRANSFER_LOOP

						LDA		#LINE_CMD_2D_END_OF_CMDSET
						STA		,U+

						LBSR	MMR_DISABLE
						LBSR	RELEASE_SUBCPU



						LDA		,S
						ADDA	#4
						STA		,S
						CMPA	#20
						LBNE	SIN16_ROT16_TEST_INNER_LOOP

						LDD		11,S
						ADDD	#10
						STD		11,S
						CMPD	#320
						LBLE	SIN16_ROT16_TEST_OUTER_LOOP


						LEAS	SIN16_ROT16_TEST_STACK_SIZE,S


						RTS



SIN16_ROT16_TEST_CENTER_TABLE	FDB	160,100,  0,0,  320,200,  0,200,  320,0
