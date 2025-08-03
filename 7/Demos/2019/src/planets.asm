						EXPORT		FLYBY_PLANET_MAIN



FLYBY_PLANET_STACK_SIZE		EQU		42

FLYBY_PLANET_SEQUENCE_NONE		EQU		0
FLYBY_PLANET_SEQUENCE_PLUTO		EQU		1
FLYBY_PLANET_SEQUENCE_NEPTUNE	EQU		2
FLYBY_PLANET_SEQUENCE_URANUS	EQU		3
FLYBY_PLANET_SEQUENCE_SATURN	EQU		4
FLYBY_PLANET_SEQUENCE_JUPITER	EQU		5
FLYBY_PLANET_SEQUENCE_MARS		EQU		6


						;	[41,S]		1 byte		Additional Object Scaling
						;	[40,S]		1 byte		Additional Object Rotation
						;	[38,S]		2 byte		Additional Object CY
						;	[36,S]		2 bytes		Additional Object CX
						;	[34,S]		2 bytes		Additional Object Pattern Pointer

						;	[33,S]	+11	1-byte 	Scaling
						;	[32,S]	+10	1-byte 	Bank angle
						;	[31,S]	+9	1-byte	Pitch angle
						;	[30,S]	+8	1-byte	Heading angle
						;	[28,S]	+6	2-byte 	Center y
						;	[26,S]	+4	2-byte 	Center x
						;	[24,S]	+2	2-byte	Model Data pointer
						;	[22,S]	+0	2-byte 	Line data pointer

						;	[20,S]		2 bytes
						;	[19,S]		1 byte		Sequence-specific state
						;	[18,S]		1 byte		Sequence-specific state
						;	[17,S]		1 byte		Other Object Scaling
						;	[16,S]		1 byte		Other Object Rotation
						;	[14,S]		2 byte		Other Object CY
						;	[12,S]		2 bytes		Other Object CX
						;	[10,S]		2 bytes		Other Object Pattern Pointer
						;	[9,S]		1 byte		Planet Scaling
						;	[8,S]		1 byte		Planet Rotation
						;	[6,S]		2 bytes		Planet CY
						;	[4,S]		2 bytes 	Planet CX
						;	[2,S]		2 bytes		Planet Pattern Pointer
						;	[1,S]		1 byte		Frame counter
						;	[,S]		1 byte		Sequence counter (Planet type)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FLYBY_PLUTO_TO_JUPITER
						LEAS	-FLYBY_PLANET_STACK_SIZE,S

						LBSR	SHOWCASE_VOYAGER

						LBSR	PLANET_BACKGROUND_1
						BSR		PLANET_INIT
						LBSR	FLYBY_PLANET_INIT_ENTRY
						LBSR	FLYBY_PLANET_MAIN

						LBSR	SHOWCASE_NEWHORIZONS

						LBSR	PLANET_BACKGROUND_2
						BSR		PLANET_INIT
						LBSR	FLYBY_PLANET_INIT_PLUTO
						LBSR	FLYBY_PLANET_MAIN

						;BSR		PLANET_INIT
						;LBSR	FLYBY_PLANET_INIT_NEPTUNE
						;LBSR	FLYBY_PLANET_MAIN

						LBSR	PLANET_BACKGROUND_SATURN
						BSR		PLANET_INIT
						LBSR	FLYBY_PLANET_INIT_SATURN
						LBSR	FLYBY_PLANET_MAIN

						LEAS	FLYBY_PLANET_STACK_SIZE,S
						RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FLYBY_MARS
						LEAS	-FLYBY_PLANET_STACK_SIZE,S

						LBSR	SHOWCASE_ROVER

						LBSR	PLANET_BACKGROUND_MARS
						LBSR	PLANET_INIT_STATIC
						LBSR	PLANET_MARS_BOUNCE_INIT
						LBSR	PLANET_SWINGBY_MAIN

						LBSR	PLANET_INIT_STATIC
						LBSR	PLANET_JUPITER_SWINGBY_INIT
						LBSR	PLANET_SWINGBY_MAIN

						LBSR	PLANET_BACKGROUND_MARS2
						BSR		PLANET_INIT
						BSR		PLANET_MARS_INIT
						LBSR	FLYBY_PLANET_MAIN

						LEAS	FLYBY_PLANET_STACK_SIZE,S
						RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PLANET_INIT
						LEAU	2,S
						LDB		#FLYBY_PLANET_STACK_SIZE

PLANAET_CLEAR_LOOP		CLR		,U+
						DECB
						BNE		PLANAET_CLEAR_LOOP

						; Planet CY,Zoom
						LDX		#140
						STX		2+6,S
						LDA		#60
						STA		2+9,S


						LEAU	2+22,S
						LEAX	DUCKY_WIREFRAME_DATA,PCR
						STX		2,U
						LDX		#320
						STX		4,U
						LDX		#40
						STX		6,U
						LDX		#$0000	; Heading, Pitch
						STX		8,U
						LDX		#$0028	; Bank, Scaling
						STX		10,U

						LEAU	2,S

						RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PLANET_MARS_INIT
						LDA		#FLYBY_PLANET_SEQUENCE_MARS
						STA		2+0,S

						LDX		#80
						STX		2+28,S	; Override Ducky CY

						LDA		#110
						STA		2+9,S	; Override Planet Zoom

						LEAX	MARS_2D_DATA,PCR
						STX		2+2,S

						LEAX	ROVER_2D_DATA,PCR
						STX		2+10,S

						LDX		#80
						STX		2+14,S	; Rover CY

						LDA		#40
						STA		2+17,S	; Rover Scaling

						RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FLYBY_PLANET_INIT_ENTRY
						LDA		#FLYBY_PLANET_SEQUENCE_NONE
						STA		2+0,S

						LEAX	VOYAGER_2D_DATA,PCR
						STX		2+10,S

						LDX		#100
						STX		2+28,S	; Override Ducky CY

						LDX		#100
						STX		2+14,S	; VOYAGER CY

						LDA		#100
						STA		2+17,S	; VOYAGER Scaling

						RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FLYBY_PLANET_INIT_SATURN
						LDA		#FLYBY_PLANET_SEQUENCE_SATURN
						STA		2+0,S

						LEAX	SATURN_2D_DATA,PCR
						STX		2+2,S

						LDX		#28
						STX		2+28,S	; Override Ducky CY

						LDA		#220
						STA		2+9,S	; Override Planet Zoom

						LDX		#100
						STX		2+6,S

						RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FLYBY_PLANET_INIT_PLUTO
						LDA		#FLYBY_PLANET_SEQUENCE_PLUTO
						STA		2+0,S

						LEAX	PLUTO_2D_DATA,PCR
						STX		2+2,S

						LDA		#100
						STA		2+9,S	; Override Planet Zoom


						LEAX	NEWHORIZON_2D_1_DATA,PCR
						STX		2+10,S
						LEAX	NEWHORIZON_2D_2_DATA,PCR
						STX		2+34,S

						LDX		2+28,S
						STX		2+14,S	; New Horizons CY
						STX		2+38,S	; New Horizons CY

						LDA		#60
						STA		2+17,S	; New Horizons Scaling
						STA		2+41,S	; New Horizons Scaling

						RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FLYBY_PLANET_INIT_NEPTUNE
						LDA		#FLYBY_PLANET_SEQUENCE_NEPTUNE
						STA		2+0,S

						LEAX	NEPTUNE_2D_DATA,PCR
						STX		2+2,S

						LDA		#150
						STA		2+9,S	; Override Planet Zoom

						RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FLYBY_PLANET_MAIN
						; Render
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


						LEAU	2+2,S
						LBSR	FLYBY_PLANET_RENDER_2D

						LEAU	2+10,S
						LBSR	FLYBY_PLANET_RENDER_2D

						LEAU	2+34,S
						LBSR	FLYBY_PLANET_RENDER_2D


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



						; Move
						LDD		2+26,S	; Ducky X
						SUBD	#4
						STD		2+26,S

						LDD		2+4,S
						ADDD	#4
						STD		2+4,S
						CMPD	#380
						LBGE	FLYBY_PLANET_MAIN_EXIT

						LDD		2+30,S
						INCA			; Heading
						ADDB	#10		; Pitch
						STD		2+30,S
						LDA		2+32,S
						ADDA	#16		; Bank
						STA		2+32,S

						LDA		2+0,S
						BEQ		FLYBY_PLANET_MOVE_ENTRY
						DECA
						LBEQ	FLYBY_PLANET_MOVE_PLUTO
						DECA
						LBEQ	FLYBY_PLANET_MOVE_NEPTUNE
						DECA
						LBEQ	FLYBY_PLANET_MOVE_URANUS
						DECA
						LBEQ	FLYBY_PLANET_MOVE_SATURN
						DECA
						LBEQ	FLYBY_PLANET_MOVE_JUPITER
						DECA
						LBEQ	FLYBY_PLANET_MOVE_MARS
						LBRA	FLYBY_PLANET_MOVED

FLYBY_PLANET_MOVE_ENTRY
						LDD		2+12,S	; Fragment X
						ADDD	#4
						STD		2+12,S

						LDA		2+18,S
						BNE		FLYBY_PLANET_MOVE_ENTRY_AFTER_COLLISION

						LDD		2+12,S	; VOYAGER X
						CMPD	2+26,S	; Ducky X
						LBLE	FLYBY_PLANET_MOVED

						INC		2+18,S
						LEAX	VOYAGER_HALF_1_2D_DATA,PCR
						STX		2+10,S
						LEAX	VOYAGER_HALF_2_2D_DATA,PCR
						STX		2+34,S
						LDX		2+12,S
						STX		2+36,S
						LDX		2+14,S
						STX		2+38,S
						LDX		2+16,S
						STX		2+40,S

						LBRA	FLYBY_PLANET_MOVED

FLYBY_PLANET_MOVE_ENTRY_AFTER_COLLISION		; PLUTE works the same.
						LDD		2+14,S  ; Fragment Y
						ADDD	#4
						STD		2+14,S
						LDA		2+16,S
						ADDA	#16
						STA		2+16,S

						LDD		2+38,S  ; Fragment Y
						SUBD	#4
						STD		2+38,S  ; Fragment Y
						LDA		2+40,S
						ADDA	#16
						STA		2+40,S

						LBRA	FLYBY_PLANET_MOVED

FLYBY_PLANET_MOVE_PLUTO
						LDD		2+12,S	; Fragment X
						ADDD	#6
						STD		2+12,S
						LDD		2+36,S  ; Fragment X
						ADDD	#6
						STD		2+36,S

						LDA		2+18,S
						BNE		FLYBY_PLANET_MOVE_ENTRY_AFTER_COLLISION	; Common code as VOYAGER

						LDD		2+12,S	; VOYAGER X
						CMPD	2+26,S	; Ducky X
						LBLE	FLYBY_PLANET_MOVED

						INC		2+18,S
						LEAX	NEWHORIZON_2D_1_DATA,PCR
						STX		2+10,S
						LEAX	NEWHORIZON_2D_2_DATA,PCR
						STX		2+34,S

						BRA		FLYBY_PLANET_MOVED


FLYBY_PLANET_MOVE_NEPTUNE
						BRA		FLYBY_PLANET_MOVED

FLYBY_PLANET_MOVE_URANUS
						BRA		FLYBY_PLANET_MOVED

FLYBY_PLANET_MOVE_SATURN
						LDD		2+4,S	; Planet CX
						CMPD	2+26,S	; Ducky CX
						BLE		FLYBY_PLANET_MOVED

						; One idea: Break Saturn's ring
						LEAX	SATURN_BROKEN_2D_DATA,PCR
						STX		2+2,S	; Planet Pattern
						; Or, spin it?
						;LDA		2+8,S	; Planet Spin
						;ADDA	#16
						;STA		2+8,S

						BRA		FLYBY_PLANET_MOVED

FLYBY_PLANET_MOVE_JUPITER
						BRA		FLYBY_PLANET_MOVED

FLYBY_PLANET_MOVE_MARS
						LDA		2+18,S
						BNE		FLYBY_PLANET_MOVE_MARS_AFTER_COLLISION

						LDD		2+4,S
						STD		2+12,S	; Rover X
						CMPD	2+26,S	; Ducky X
						BLE		FLYBY_PLANET_MOVED
						INC		2+18,S
						BRA		FLYBY_PLANET_MOVED
FLYBY_PLANET_MOVE_MARS_AFTER_COLLISION
						LDD		2+12,S	; Rover X
						SUBD	#4
						STD		2+12,S
						LDD		2+14,S	; Rover Y
						ADDD	#2
						STD		2+14,S
						LDD		2+28,S	; Ducky Y
						SUBD	#2
						STD		2+28,S
						LDA		2+16,S
						ADDA	#16
						STA		2+16,S
						BRA		FLYBY_PLANET_MOVED


FLYBY_PLANET_MOVED
						INC		2+1,S
						LBRA	FLYBY_PLANET_MAIN


FLYBY_PLANET_MAIN_EXIT
						RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FLYBY_PLANET_RENDER_2D
						LDX		,U
						BEQ		FLYBY_PLANET_RENDER_2D_EXIT

						LDB		#LINE_CMD_SET_TRANS
						STB		,Y+
						LDD		6,U		; Rotation, Scaling
						STD		,Y++
						LDD		2,U
						STD		,Y++
						LDD		4,U
						STD		,Y++


						LDA		#LINE_CMD_2D_TRANS_CLIP
						STA		,Y+

						LDB		,X+
						STB		,Y+
FLYBY_PLANET_RENDER_2D_TRANS_LOOP
						LDA		,X+
						STA		,Y+
						LDU		,X++
						STU		,Y++
						LDU		,X++
						STU		,Y++
						DECB
						BNE		FLYBY_PLANET_RENDER_2D_TRANS_LOOP

FLYBY_PLANET_RENDER_2D_EXIT
						RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PLANET_INIT_STATIC
						LEAU	2,S
						LDB		#FLYBY_PLANET_STACK_SIZE

PLANAET_STATIC_CLEAR_LOOP
						CLR		,U+
						DECB
						BNE		PLANAET_STATIC_CLEAR_LOOP

						; Planet CX,CY,Zoom
						LDX		#160
						STX		2+4,S
						LDX		#100
						STX		2+6,S
						LDA		#60
						STA		2+9,S

						LEAU	2,S

						RTS


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PLANET_MARS_BOUNCE_INIT
						LEAU	2+22,S
						LEAX	DUCKY_WIREFRAME_DATA,PCR
						STX		2,U
						LDX		#320
						STX		4,U
						LDX		#100
						STX		6,U
						LDX		#$0000	; Heading, Pitch
						STX		8,U
						LDX		#$0028	; Bank, Scaling
						STX		10,U


						LEAU	2,S
						LDA		#FLYBY_PLANET_SEQUENCE_MARS
						STA		2+0,S

						LDA		#110
						STA		2+9,S	; Override Planet Zoom

						LEAX	MARS_2D_DATA,PCR
						STX		2+2,S

						LEAX	ROVER_2D_DATA,PCR
						STX		2+10,S

						LDX		#160
						STX		2+12,S	; Rover CX

						LDX		#40
						STX		2+14,S	; Rover CY

						LDA		#40
						STA		2+17,S	; Rover Scaling

						RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PLANET_JUPITER_SWINGBY_INIT
						LEAU	2+22,S
						LEAX	DUCKY_WIREFRAME_DATA,PCR
						STX		2,U
						LDX		#0
						STX		4,U
						LDX		#180
						STX		6,U
						LDX		#$0000	; Heading, Pitch
						STX		8,U
						LDX		#$0028	; Bank, Scaling
						STX		10,U


						LEAU	2,S
						LDA		#FLYBY_PLANET_SEQUENCE_JUPITER
						STA		2+0,S

						LDA		#110
						STA		2+9,S	; Override Planet Zoom

						LEAX	JUPITER_2D_DATA,PCR
						STX		2+2,S

						RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PLANET_SWINGBY_MAIN
						; Render
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


						LEAU	2+2,S
						LBSR	FLYBY_PLANET_RENDER_2D

						LEAU	2+10,S
						LBSR	FLYBY_PLANET_RENDER_2D

						LEAU	2+34,S
						LBSR	FLYBY_PLANET_RENDER_2D


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



						; Move
						LDD		2+30,S
						INCA			; Heading
						ADDB	#10		; Pitch
						STD		2+30,S
						LDA		2+32,S
						ADDA	#16		; Bank
						STA		2+32,S

						LDA		2+0,S
						CMPA	#FLYBY_PLANET_SEQUENCE_MARS
						BEQ		FLYBY_PLANET_MOVE_MARS_BOUNCE
						CMPA	#FLYBY_PLANET_SEQUENCE_JUPITER
						LBEQ	FLYBY_PLANET_MOVE_JUPITER_SWINGBY
						LBRA	FLYBY_PLANET_SWINGBY_MOVED



FLYBY_PLANET_MOVE_MARS_BOUNCE
						LDA		2+18,S
						BNE		FLYBY_PLANET_MOVE_MARS_BOUNCE_AFTER_COLLISION

						LDD		2+26,S	; Ducky X
						SUBD	#4
						STD		2+26,S

						CMPD	#204
						LBCC	FLYBY_PLANET_SWINGBY_MOVED
						INC		2+18,S
						LDX		#32
						STX		2+14,S	; Rover CY
						LBRA	FLYBY_PLANET_SWINGBY_MOVED

FLYBY_PLANET_MOVE_MARS_BOUNCE_AFTER_COLLISION
						LDX		2+14,S	; Rover CY
						CMPX	#40
						BCC		FLYBY_PLANET_MOVE_MARS_BOUNCE_AFTER_COLLISION_RE_LAND
						LEAX	1,X
FLYBY_PLANET_MOVE_MARS_BOUNCE_AFTER_COLLISION_RE_LAND
						STX		2+14,S	; Rover CY

						LDB		2+5,S	; Planet X lower 8-bit (I know it is less than 255)
						LDA		2+1,S
						ANDA	#4
						BNE		FLYBY_PLANET_MOVE_MARS_BOUNCE_AFTER_COLLISION_MARS_QUAKE
						INCB
						FCB		#$86	; Make it LDA #?
FLYBY_PLANET_MOVE_MARS_BOUNCE_AFTER_COLLISION_MARS_QUAKE
						DECB
						STB		2+5,S


						LDD		2+26,S	; Ducky X
						ADDD	#4
						STD		2+26,S

						CMPD	#320
						BCC		FLYBY_PLANET_SWINGBY_EXIT

						LBRA	FLYBY_PLANET_SWINGBY_MOVED



FLYBY_PLANET_MOVE_JUPITER_SWINGBY
						LDA		2+18,S
						DECA
						BEQ		FLYBY_PLANET_MOVE_JUPITER_SWINGBY_TURNING
						DECA
						BEQ		FLYBY_PLANET_MOVE_JUPITER_SWINGBY_BACK_ON_COURSE

						LDD		2+26,S	; Ducky X
						ADDD	#4
						STD		2+26,S

						CMPD	#160
						BCS		FLYBY_PLANET_SWINGBY_MOVED
						INC		2+18,S
						LDA		#4
						STA		2+19,S
						BRA		FLYBY_PLANET_SWINGBY_MOVED

FLYBY_PLANET_MOVE_JUPITER_SWINGBY_TURNING
						LDA		#80
						LDB		2+19,S
						LBSR	SIN8
						LDX		#160
						LEAX	A,X
						STX		2+26,S	; Duck X

						LDA		#80
						LDB		2+19,S
						LBSR	COS8
						LDX		#100
						LEAX	A,X
						STX		2+28,S	; Duck Y

						LDA		2+19,S
						ADDA	#4
						STA		2+19,S
						BPL		FLYBY_PLANET_SWINGBY_MOVED

						INC		2+18,S
						BRA		FLYBY_PLANET_SWINGBY_MOVED

FLYBY_PLANET_MOVE_JUPITER_SWINGBY_BACK_ON_COURSE
						LDD		2+26,S	; Ducky X
						SUBD	#4
						STD		2+26,S
						BMI		FLYBY_PLANET_SWINGBY_EXIT

						BRA	FLYBY_PLANET_SWINGBY_MOVED



FLYBY_PLANET_SWINGBY_MOVED
						INC		2+1,S
						LBRA	PLANET_SWINGBY_MAIN


FLYBY_PLANET_SWINGBY_EXIT
						RTS


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PLANET_BACKGROUND_1
						LEAY	PLANET_BACKGROUND_1_COORD,PCR
						BRA		PLANET_BACKGROUND

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PLANET_BACKGROUND_2
						LEAY	PLANET_BACKGROUND_2_COORD,PCR
						BRA		PLANET_BACKGROUND

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PLANET_BACKGROUND_MARS
						LEAY	PLANET_BACKGROUND_MARS_COORD,PCR
						BRA		PLANET_BACKGROUND

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PLANET_BACKGROUND_MARS2
						LEAY	PLANET_BACKGROUND_MARS2_COORD,PCR
						BRA		PLANET_BACKGROUND

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PLANET_BACKGROUND_SATURN
						LEAY	PLANET_BACKGROUND_SATURN_COORD,PCR
						BRA		PLANET_BACKGROUND

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PLANET_BACKGROUND
						PSHS	Y
						LBSR	SUBCPU_BANK1_CLS_AND_FLUSH
PLANET_BACKGROUND_LOOP
						LDY		,S
						LDU		,Y++
						BEQ		PLANET_BACKGROUND_LOOP_EXIT
						STY		,S
						LEAX	BMP_STAR_BLUE_8X8,PCR
						LBSR	DRAW_BITMAP_64_PAGE1
						BRA		PLANET_BACKGROUND_LOOP

PLANET_BACKGROUND_LOOP_EXIT
						PULS	Y,PC

PLANET_BACKGROUND_1_COORD
						FDB		 34/8+ 39*40
						FDB		154/8+ 61*40
						FDB		240/8+ 37*40
						FDB		 32/8+138*40
						FDB		104/8+127*40
						FDB		192/8+160*40
						FDB		280/8+117*40
						FDB		0

PLANET_BACKGROUND_2_COORD
						FDB		 40/8+ 81*40
						FDB		304/8+ 30*40
						FDB		120/8+ 92*40
						FDB		120/8+ 92*40
						FDB		204/8+ 69*40
						FDB		240/8+189*40
						FDB		0

PLANET_BACKGROUND_MARS_COORD
						FDB		 37/8+ 102*40
						FDB		 20/8+ 151*40
						FDB		 83/8+ 149*40
						FDB		238/8+  39*40
						FDB		292/8+  61*40
						FDB		229/8+ 151*40
						FDB		294/8+ 161*40
						FDB		0

PLANET_BACKGROUND_MARS2_COORD
						FDB		225/8+ 193*40
						FDB		 48/8+  50*40
						FDB		183/8+  29*40
						FDB		307/8+  61*40
						FDB		 13/8+ 192*40
						FDB		0

PLANET_BACKGROUND_SATURN_COORD
						FDB		 35/8+  42*40
						FDB		 69/8+ 166*40
						FDB		185/8+ 156*40
						FDB		270/8+ 180*40
						FDB		114/8+  45*40
						FDB		232/8+  25*40
						FDB		299/8+  49*40
						FDB		0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

