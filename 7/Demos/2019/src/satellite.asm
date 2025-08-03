

SATELLITE_STACK_SIZE		EQU		34
SATELLITE_ORBIT_CX			EQU		160
SATELLITE_ORBIT_CY			EQU		200
SATELLITE_ORBIT_ARM_LENGTH	EQU		80
SATELLITE_EARTH_RADIUS		EQU		100


SATELLITE
						;	[33,S]	+11	1-byte 	Scaling
						;	[32,S]	+10	1-byte 	Bank angle
						;	[31,S]	+9	1-byte	Pitch angle
						;	[30,S]	+8	1-byte	Heading angle
						;	[28,S]	+6	2-byte 	Center y
						;	[26,S]	+4	2-byte 	Center x
						;	[24,S]	+2	2-byte	Model Data pointer
						;	[22,S]	+0	2-byte 	Line data pointer
						;	[21,S]	1 byte
						; 	[20,S]	1 byte 	Hubble Panel2 Rotation
						; 	[18,S]	2 bytes	Hubble Panel2 Y
						; 	[16,S]	2 bytes Hubble Panel2 X
						; 	[15,S]	1 byte
						; 	[14,S]	1 byte 	Hubble Panel1 Rotation
						; 	[12,S]	2 bytes	Hubble Panel1 Y
						; 	[10,S]	2 bytes Hubble Panel1 X
						; 	[9,S]		1 byte
						; 	[8,S]		1 byte	Hubble Fuselage Rotation
						; 	[6,S]		2 bytes	Hubble Fuselage Y
						; 	[4,S]		2 bytes Hubble Fuselage X
						; 	[3,S]		1 byte	Angle Ducky
						; 	[2,S]		1 byte	Angle Hubble
						; 	[1,S]		1 byte	Frame counter
						; 	[,S]		1 byte	Sequence Counter

						LBSR	SHOWCASE_HUBBLE

						LDB		#SATELLITE_STACK_SIZE
SATELLITE_ZERO_LOOP		CLR		,-S
						DECB
						BNE		SATELLITE_ZERO_LOOP



						LEAU	22,S
						LEAX	DUCKY_WIREFRAME_DATA,PCR
						STX		2,U
						LDX		#260
						STX		4,U
						LDX		#40
						STX		6,U
						LDX		#$0000	; Heading, Pitch
						STX		8,U
						LDX		#$0020	; Bank, Scaling
						STX		10,U


						LDA		#0
						STA		3,S		; Angle Ducky
						LDA		#$80
						STA		2,S		; Angle Hubble


SATELLITE_OUTSIDE_LOOP

SATELLITE_INSIDE_LOOP
						BSR		SATELLITE_MOVE
						LBSR	SATELLITE_RENDER


						INC		1,S
						LDA		1,S
						CMPA	#140
						BNE		SATELLITE_INSIDE_LOOP



						LEAS	SATELLITE_STACK_SIZE,S
						RTS


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


SATELLITE_MOVE
						INC		2+3,S	; Angle Ducky

						INC		2+32,S	; Ducky bank
						INC		2+32,S	; Ducky bank
						DEC		2+31,S	; Ducky pitch
						DEC		2+31,S	; Ducky pitch
						INC		2+30,S	; Ducky heading	
						INC		2+30,S	; Ducky heading	

						; Calculate positions of the ducky
						LDA		#SATELLITE_ORBIT_ARM_LENGTH
						LDB		2+3,S	; Angle Ducky
						LBSR	SIN8
						NEGA
						TFR		A,B
						SEX
						LSLB
						ROLA
						ADDD	#SATELLITE_ORBIT_CY
						STD		2+28,S

						LDA		#SATELLITE_ORBIT_ARM_LENGTH
						LDB		2+3,S
						LBSR	COS8
						TFR		A,B
						SEX
						LSLB
						ROLA
						ADDD	#SATELLITE_ORBIT_CX
						STD		2+26,S


						LDA		2+0,S
						BEQ		SATELLITE_MOVE_SEQUENCE0
						DECA
						BEQ		SATELLITE_MOVE_SEQUENCE1
						RTS


SATELLITE_MOVE_SEQUENCE0
						DEC		2+2,S

						LDA		2+3,S	; Angle Ducky
						CMPA	2+2,S	; Angle Hubble
						BCS		SATELLITE_MOVE_SEQUENCE0_NO_CATCH_UP
						INC		2+0,S

SATELLITE_MOVE_SEQUENCE0_NO_CATCH_UP

						; Calculate positions of Hubble parts
						LDA		#SATELLITE_ORBIT_ARM_LENGTH
						LDB		2+2,S	; Angle Hubble
						LBSR	SIN8
						NEGA
						TFR		A,B
						SEX
						LSLB
						ROLA
						ADDD	#SATELLITE_ORBIT_CY
						STD		2+6,S
						STD		2+12,S
						STD		2+18,S

						LDA		#SATELLITE_ORBIT_ARM_LENGTH
						LDB		2+2,S
						LBSR	COS8
						TFR		A,B
						SEX
						LSLB
						ROLA
						ADDD	#SATELLITE_ORBIT_CX
						STD		2+4,S
						STD		2+10,S
						STD		2+16,S

						LDA		#32
						STA		2+8,S
						STA		2+14,S
						STA		2+20,S

						RTS


SATELLITE_MOVE_SEQUENCE1
						LDD		2+4,S
						ADDD	#1
						STD		2+4,S
						LDD		2+6,S
						ADDD	#1
						STD		2+6,S
						LDA		2+8,S
						ADDA	#8
						STA		2+8,S

						LDD		2+10,S
						SUBD	#1
						STD		2+10,S
						LDD		2+12,S
						ADDD	#1
						STD		2+12,S
						LDA		2+14,S
						ADDA	#8
						STA		2+14,S

						LDD		2+16,S
						SUBD	#1
						STD		2+16,S
						LDD		2+18,S
						SUBD	#1
						STD		2+18,S
						LDA		2+20,S
						ADDA	#8
						STA		2+20,S

						RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


SATELLITE_RENDER
	 					LEAX	PROJECTION_AREA,PCR
						LEAY	2+22,S	; Model data, coordinates, orientation
						LDB		#1		; One model
						LBSR	PROJECT_ORTHOGONAL_MULTI



						LBSR	HALT_SUBCPU
						LBSR	MMR_ENABLE_ACCESS_SUBCPU_RAM


						LDY		#LINEDATA_BUF
						LDA		2+1,S		; Frame Counter
						ANDA	#1
						LBSR	SUBCPU_PUSH_BEGIN_FRAME_CMD



						LEAU	2+4,S
						LEAX	HUBBLE_FUSELAGE_2D_DATA,PCR
						BSR		SATELLITE_RENDER_2D

						LEAU	6,U
						LEAX	HUBBLE_PANEL_1_2D_DATA,PCR
						BSR		SATELLITE_RENDER_2D

						LEAU	6,U
						LEAX	HUBBLE_PANEL_2_2D_DATA,PCR
						BSR		SATELLITE_RENDER_2D


						; Earth
						LDB		#LINE_CMD_SET_TRANS
						STB		,Y+
						LDD		#$0080
						STD		,Y++
						LDD		#SATELLITE_ORBIT_CX
						STD		,Y++
						LDD		#SATELLITE_ORBIT_CY
						STD		,Y++

						LDA		#LINE_CMD_2D_TRANS_CLIP
						STA		,Y+

						LEAX	EARTH_2D,PCR
						LDB		,X+
						STB		,Y+
SATELLITE_RENDER_EARTH_LOOP
						LDA		,X+
						STA		,Y+
						LDU		,X++
						STU		,Y++
						LDU		,X++
						STU		,Y++
						DECB
						BNE		SATELLITE_RENDER_EARTH_LOOP



						;    X   Projected-data pointer
						;    U   Model information pointer
						;    Y   Destination pointer
						;    B   Model count
						LEAX	PROJECTION_AREA,PCR
						LEAU	2+22,S
						LDB		#1
						LBSR	PROJECT_ORTHOGONAL_PUSH_TO_SUBCPU_SPACE


						LDA		2+1,S
						ANDA	#1
						LBSR	SUBCPU_PUSH_END_FRAME_CMD

						LDA		#LINE_CMD_2D_END_OF_CMDSET
						STA		,Y+

						LBSR	MMR_DISABLE
						LBSR	RELEASE_SUBCPU

						RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SATELLITE_RENDER_2D
						PSHS	X

						LDA		#LINE_CMD_SET_TRANS
						STA		,Y+
						LDA		4,U
						STA		,Y+		; Rotation
						LDA		#32
						STA		,Y+			; Scaling
						LDX		,U
						STX		,Y++
						LDX		2,U
						STX		,Y++

						PULS	X

						LDA		#LINE_CMD_2D_TRANS_CLIP
						STA		,Y+

						PSHS	U
						LDB		,X+
						STB		,Y+
SATELLITE_RENDER_2D_LOOP
						LDA		,X+
						STA		,Y+
						LDU		,X++
						STU		,Y++
						LDU		,X++
						STU		,Y++
						DECB
						BNE		SATELLITE_RENDER_2D_LOOP

						PULS	U,PC
