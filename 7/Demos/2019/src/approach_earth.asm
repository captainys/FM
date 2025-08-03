
APPROACH_EARTH_STACK_SIZE	EQU	26


APPROACH_EARTH
						LDB		#APPROACH_EARTH_STACK_SIZE
APPROACH_EARTH_INIT_LOOP
						CLR		,-S
						DECB
						BNE		APPROACH_EARTH_INIT_LOOP


						LEAU	14,S
						LEAX	DUCKY_WIREFRAME_DATA,PCR
						STX		2,U
						LDX		#240
						STX		4,U
						LDX		#80
						STX		6,U
						LDX		#$0000	; Heading, Pitch
						STX		8,U
						LDX		#$00FF	; Bank, Scaling
						STX		10,U


						CLR		5,S
						CLR		4,S
						LDX		#120	; Y
						STX		2,S
						LDX		#80		; X
						STX		,S

						;	[25,S]	+11	1-byte 	Scaling
						;	[24,S]	+10	1-byte 	Bank angle
						;	[23,S]	+9	1-byte	Pitch angle
						;	[22,S]	+8	1-byte	Heading angle
						;	[20,S]	+6	2-byte 	Center y
						;	[18,S]	+4	2-byte 	Center x
						;	[16,S]	+2	2-byte	Model Data pointer
						;	[14,S]	+0	2-byte 	Line data pointer

						; [13,S] 
						; [12,S] Overall counter

						; [11,S] 
						; [10,S] 
						; [8,S] 
						; [6,S] 

						; [5,S] earth Scaling
						; [4,S] earth Rotation
						; [2,S]	earth Y
						; [,S]	earth X



APPROACH_EARTH_OUTER_LOOP
						LDD		22,S
						ADDA	#7
						SUBB	#17
						STD		22,S
						LDA		24,S
						ADDA	#$10
						STA		24,S

						LDA		25,S
						BEQ		APPROACH_EARTH_DUCKY_SCALED_DOWN
						DEC		25,S
APPROACH_EARTH_DUCKY_SCALED_DOWN

						INC		5,S
						BNE		APPROACH_EARTH_EARTH_SCALED_UP
						DEC		5,S
APPROACH_EARTH_EARTH_SCALED_UP

						TFR		S,U
						BSR		APPROACH_EARTH_RENDER
						DEC		12,S
						LBNE	APPROACH_EARTH_OUTER_LOOP

						LEAS	APPROACH_EARTH_STACK_SIZE,S
						RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

APPROACH_EARTH_RENDER
	 					LEAX	PROJECTION_AREA,PCR
						LEAY	2+14,S	; Model data, coordinates, orientation
						LDB		#1		; One model
						LBSR	PROJECT_ORTHOGONAL_MULTI


						LBSR	HALT_SUBCPU
						LBSR	MMR_ENABLE_ACCESS_SUBCPU_RAM

						LEAU	2,S

						LDY		#LINEDATA_BUF

						LDA		12,U
						ANDA	#1
						LBSR	SUBCPU_PUSH_BEGIN_FRAME_CMD


						; Transformation of earth

						LDB		#LINE_CMD_SET_TRANS
						STB		,Y+

						LDD		4,U	; A=Rotation  B=Scaling
						STD		,Y++

						LDD		,U	; TransX
						STD		,Y++

						LDD		2,U ; TransY
						STD		,Y++


						; Draw earth

						LDA		#LINE_CMD_2D_TRANS_CLIP
						STA		,Y+


						LEAX	EARTH_2D,PCR
						LDB		,X+
						STB		,Y+
APPROACH_EARTH_TRANS_EARTH_LOOP
						LDA		,X+
						STA		,Y+
						LDU		,X++
						STU		,Y++
						LDU		,X++
						STU		,Y++
						DECB
						BNE		APPROACH_EARTH_TRANS_EARTH_LOOP



						;    X   Projected-data pointer
						;    U   Model information pointer
						;    Y   Destination pointer
						;    B   Model count
						LEAX	PROJECTION_AREA,PCR
						LEAU	2+14,S
						LDB		#1
						LBSR	PROJECT_ORTHOGONAL_PUSH_TO_SUBCPU_SPACE



						LEAU	2,S

						; Clear the other buffer
						LDA		12,U
						ANDA	#1
						LBSR	SUBCPU_PUSH_END_FRAME_CMD

						; End of Sub-SYS commands
						LDA		#LINE_CMD_2D_END_OF_CMDSET
						STA		,Y+


						LBSR	MMR_DISABLE
						LBSR	RELEASE_SUBCPU

						RTS
