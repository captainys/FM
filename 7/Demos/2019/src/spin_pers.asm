; Temporary variables
;				[,S]	16bit	Pointer to the command output
;				[2,S]	16bit	Pointer to the model
;				[4,S]	8bit	Heading
;				[5,S]	8bit	Pitch
;				[6,S]	16bit	DX
;				[8,S]	16bit	DY
;				[10,S]	16bit	DZ
;
;				[12,S]	8bit	counter

DEMO2019_SPIN_PERS
						LEAS	-24,S

						LEAX	PROJECTION_AREA,PCR
						STX		,S

						; LEAX	DUCKY_WIREFRAME_DATA,PCR
						LEAX	CUBE_WIREFRAME_DATA,PCR
						STX		2,S

						LDX		#$2020
						STX		4,S
						LDX		#0
						STX		6,S
						STX		8,S
						LDX		#1024
						STX		10,S


						LDB		#255
						STB		12,S
DEMO2019_SPIN_PERS_LOOP
						LBSR	TRANSFORM_3D_RESTRICTED
						TSTB
						BEQ		DEMO2019_SPIN_PERS_NEXT


						LBSR	HALT_SUBCPU
						LBSR	MMR_ENABLE_ACCESS_SUBCPU_RAM


						LDY		#LINEDATA_BUF

						LDB		#LINE_CMD_HALF_CLS
						STB		,Y+
						LDA		12,S
						ANDA	#1
						LSLA
						LSLA
						LSLA
						LSLA
						LSLA
						CLRB
						STD		,Y++

						LDB		#LINE_CMD_SET_OFFSET	; VRAM offset for HW LINE
						STB		,Y+
						CLRB
						STD		,Y++


						LDA		#LINE_CMD_3D_CLIPPING
						STA		,Y+

						LEAX	PROJECTION_AREA,PCR
						LDB		,X+
						STB		,Y+
DEMO2019_SPIN_PERS_TFR_LOOP
						LDA		,X+		; color
						STA		,Y+
						LDU		,X++	; x
						STU		,Y++
						LDU		,X++	; y
						STU		,Y++
						LDU		,X++	; z
						STU		,Y++
						LDU		,X++	; x
						STU		,Y++
						LDU		,X++	; y
						STU		,Y++
						LDU		,X++	; z
						STU		,Y++

						DECB
						BNE		DEMO2019_SPIN_PERS_TFR_LOOP

						LBSR	PRINTTEST_ADD_COMMAND

						LDA		#LINE_CMD_2D_END_OF_CMDSET
						STA		,Y+

						LBSR	MMR_DISABLE
						LBSR	RELEASE_SUBCPU



DEMO2019_SPIN_PERS_NEXT
						LDD		10,S
						SUBD	#16
						CMPD	#64
						BGT		DEMO2019_SPIN_PERS_Z_FAR_ENOUGH
						LDD		#1024

DEMO2019_SPIN_PERS_Z_FAR_ENOUGH
						STD		10,S

						DEC		12,S
						BNE		DEMO2019_SPIN_PERS_LOOP


						LEAS	24,S
						RTS
