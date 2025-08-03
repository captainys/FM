						EXPORT	SOLAR_SYSTEM


SOLAR_SYSTEM_STACK_SIZE	EQU	54


SOLAR_SYSTEM

		;	[33,S]	+11	1-byte 	Scaling
		;	[32,S]	+10	1-byte 	Bank angle
		;	[31,S]	+9	1-byte	Pitch angle
		;	[30,S]	+8	1-byte	Heading angle
		;	[28,S]	+6	2-byte 	Center y
		;	[26,S]	+4	2-byte 	Center x
		;	[24,S]	+2	2-byte	Model Data pointer
		;	[22,S]	+0	2-byte 	Line data pointer

		;	[21,S]		
		;	[19,S]		2-byte arm length
		;	[18,S]		General counter
		;	[17,S]		General counter
		;	[16,S]		1-byte Zoom		32=1X
		;	[14,S]		2-byte Sun location Y
		;	[12,S]		2-byte Sun location X
		;	[11,S]		Angle Pluto
		;	[10,S]		Angle Neptune
		;	[9,S]		Angle Uranus
		;	[8,S]		Angle Saturn
		;	[7,S]		Angle Jupiter
		;	[6,S]		Angle Mars
		;	[5,S]		Angle Earth
		;	[4,S]		Angle Venus
		;	[3,S]		Angle Mercury
		;	[2,S]		Zero (Sun angle=0)
		;	[1,S]		Frame counter
		;	[,S]		Sequence counter


						LDU		#28+100*40	; VRAM addr ($0000-$2000)
						LEAX	BMP_GALAXY_45DEG_96X96,PCR
						LBSR	DRAW_BITMAP_64_PAGE1

						LDU		#2+8*40	; VRAM addr ($0000-$2000)
						LEAX	BMP_STAR_BLUE_8X8,PCR
						LBSR	DRAW_BITMAP_64_PAGE1

						LDU		#0+16*40	; VRAM addr ($0000-$2000)
						LEAX	BMP_STAR_BLUE_8X8,PCR
						LBSR	DRAW_BITMAP_64_PAGE1

						LDU		#3+20*40	; VRAM addr ($0000-$2000)
						LEAX	BMP_STAR_BLUE_8X8,PCR
						LBSR	DRAW_BITMAP_64_PAGE1

						LDU		#1+24*40	; VRAM addr ($0000-$2000)
						LEAX	BMP_STAR_BLUE_8X8,PCR
						LBSR	DRAW_BITMAP_64_PAGE1



						LDB		#SOLAR_SYSTEM_STACK_SIZE
SOLAR_SYSTEM_INIT_LOOP
						CLR		,-S
						DECB
						BNE		SOLAR_SYSTEM_INIT_LOOP

						LEAU	22,S
						LEAX	DUCKY_WIREFRAME_DATA,PCR
						STX		2,U
						LDX		#260
						STX		4,U
						LDX		#40
						STX		6,U
						LDX		#$0000	; Heading, Pitch
						STX		8,U
						LDX		#$00FF	; Bank, Scaling
						STX		10,U
						

						LEAX	HIGH_LEV_GRAPH_CIRCLE8,PCR
						LEAU	SOLAR_SYSTEM_RENDER_FUNCTION,PCR
						STX		,U++
						STX		,U++
						STX		,U++
						STX		,U++
						STX		,U++
						STX		,U++
						STX		,U++
						STX		,U++
						STX		,U++
						STX		,U++

						LEAX	HIGH_LEV_GRAPH_CIRCLE16,PCR
						STX		SOLAR_SYSTEM_RENDER_FUNCTION,PCR		; Sun

						LEAX	SOLAR_SYSTEM_EARTH,PCR
						STX		SOLAR_SYSTEM_RENDER_FUNCTION+6,PCR		; Earth

						LEAX	SOLAR_SYSTEM_JUPITER,PCR
						STX		SOLAR_SYSTEM_RENDER_FUNCTION+10,PCR		; Earth

						LEAX	SOLAR_SYSTEM_SATURN,PCR
						STX		SOLAR_SYSTEM_RENDER_FUNCTION+12,PCR		; Earth

						LDX		#160		; Sun X
						STX		12,S
						LDX		#100		; Sun Y
						STX		14,S

						LDA		#1		; Initial Solar-System size
						STA		16,S


SOLAR_SYSTEM_OUTER_LOOP


SOLAR_SYSTEM_INNER_LOOP
						BSR		SOLAR_SYSTEM_RENDER



						CLR		17,S
						LEAU	3,S

SOLAR_SYSTEM_ORBIT_LOOP
						LDB		,U
						ADDB	#9
						SUBB	17,S
						STB		,U+

						INC		17,S
						LDB		17,S
						CMPB	#9
						BNE		SOLAR_SYSTEM_ORBIT_LOOP




						LDD		30,S
						ADDA	#8
						SUBB	#9
						STD		30,S
						LDA		32,S
						ADDA	#3
						STA		32,S

						LDA		33,S
						CMPA	#4
						BCS		SOLAR_SYSTEM_INNER_LOOP_DUCKY_MOVED
						DEC		33,S
SOLAR_SYSTEM_INNER_LOOP_DUCKY_MOVED


						LDA		1,S
						ANDA	#3
						BNE		SOLAR_SYSTEM_INNER_LOOP_SHIFTED
						LDD		12,S
						SUBD	#1
						STD		12,S
						INC		16,S
SOLAR_SYSTEM_INNER_LOOP_SHIFTED

						LDA		1,S
						ANDA	#7
						BNE		SOLAR_SYSTEM_INNER_LOOP_ZOOMED
						LDD		14,S
						ADDD	#1
						STD		14,S
SOLAR_SYSTEM_INNER_LOOP_ZOOMED

						INC		1,S
						BNE		SOLAR_SYSTEM_INNER_LOOP



	;					INC		,S
	;					LDA		,S
	;					CMPA	#10
	;					BNE		SOLAR_SYSTEM_OUTER_LOOP


						LEAS	SOLAR_SYSTEM_STACK_SIZE,S
						RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SOLAR_SYSTEM_RENDER
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




						CLR		2+17,S		; General Counter
SOLAR_SYSTEM_RENDER_LOOP
						LDA		#LINE_CMD_SET_TRANS
						STA		,Y+
						CLR		,Y+		; Rotation

						LDB		2+17,S		; General Counter
						LEAU	SOLAR_SYSTEM_STAR_RADIUS,PCR
						LDA		B,U
						LDB		2+16,S
						MUL
						LSRA
						RORB
						LSRA
						RORB
						LSRA
						RORB
						LSRA
						RORB
						LSRA
						RORB
						STB		,Y+			; Scaling

						TST		2+17,S		; General counter
						BNE		SOLAR_SYSTEM_RENDER_PLANET
						LDX		2+12,S
						STX		,Y++
						LDX		2+14,S
						STX		,Y++

						BRA		SOLAR_SYSTEM_RENDER_DRAW

SOLAR_SYSTEM_RENDER_PLANET
						LDA		2+17,S
						LDB		#11
						MUL		; B distance from sun
						LDA		2+16,S		; Overall Zoom
						MUL

						LSRA
						RORB
						LSRA
						RORB
						LSRA
						RORB
						LSRA
						RORB
						LSRA
						RORB
						STD		2+19,S		; Arm length

						LEAU	2+2,S
						LDA		2+17,S
						LDB		A,U
						LDX		2+19,S
						LBSR	COS16
						ADDD	2+12,S
						STD		,Y++

						LEAU	2+2,S
						LDA		2+17,S
						LDB		A,U
						LDX		2+19,S
						LBSR	SIN16
						ADDD	2+14,S
						STD		,Y++

SOLAR_SYSTEM_RENDER_DRAW
						LDA		2+17,S
						LEAU	SOLAR_SYSTEM_STAR_COLOR,PCR
						LDA		A,U

						LDB		2+17,S
						LSLB
						LEAU	SOLAR_SYSTEM_RENDER_FUNCTION,PCR
						JSR		[B,U]

						INC		2+17,S
						LDA		2+17,S
						CMPA	#10
						LBNE	SOLAR_SYSTEM_RENDER_LOOP



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


SOLAR_SYSTEM_STAR_RADIUS		FCB		10,4,4,4,4,8,12,6,6,3
SOLAR_SYSTEM_STAR_COLOR			FCB		6,7,7,1,2,6,6,7,5,3
SOLAR_SYSTEM_RENDER_FUNCTION	FDB		0,0,0,0,0,0,0,0,0,0


SOLAR_SYSTEM_EARTH
						PSHS	U

						LDB		#LINE_CMD_2D_TRANS_CLIP
						STB		,Y+

						LEAX	EARTH_2D,PCR
						LDA		,X+
						STA		,Y+
SOLAR_SYSTEM_EARTH_LOOP
						LDB		,X+
						STB		,Y+
						LDU		,X++
						STU		,Y++
						LDU		,X++
						STU		,Y++
						DECA
						BNE		SOLAR_SYSTEM_EARTH_LOOP

						PULS	U,PC


SOLAR_SYSTEM_JUPITER
						PSHS	U

						LDB		#LINE_CMD_2D_TRANS_CLIP
						STB		,Y+

						LEAX	JUPITER_2D_LOD_DATA,PCR
						LDA		,X+
						STA		,Y+
SOLAR_SYSTEM_JUPITER_LOOP
						LDB		,X+
						STB		,Y+
						LDU		,X++
						STU		,Y++
						LDU		,X++
						STU		,Y++
						DECA
						BNE		SOLAR_SYSTEM_JUPITER_LOOP

						PULS	U,PC

SOLAR_SYSTEM_SATURN
						PSHS	U

						LDB		#LINE_CMD_2D_TRANS_CLIP
						STB		,Y+

						LEAX	SATURN_2D_LOD_DATA,PCR
						LDA		,X+
						STA		,Y+
SOLAR_SYSTEM_SATURN_LOOP
						LDB		,X+
						STB		,Y+
						LDU		,X++
						STU		,Y++
						LDU		,X++
						STU		,Y++
						DECA
						BNE		SOLAR_SYSTEM_SATURN_LOOP

						PULS	U,PC
