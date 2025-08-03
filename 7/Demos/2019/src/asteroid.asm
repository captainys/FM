

					; 12 bytes per 3D obj
					;	[11]	+11	1-byte 	Scaling
					;	[10]	+10	1-byte 	Bank angle
					;	[ 9]	+9	1-byte	Pitch angle
					;	[ 8]	+8	1-byte	Heading angle
					;	[ 6]	+6	2-byte 	Center y
					;	[ 4]	+4	2-byte 	Center x
					;	[ 2]	+2	2-byte	Model Data pointer
					;	[ 0]	+0	2-byte 	Line data pointer


					; [8,S]		12 x 4  Object info

					; [7,S]		1-byte Ducky Z
					; [6,S]		1-byte Asteroid 2 Z
					; [5,S]		1-byte Asteroid 1 Z
					; [4,S]		1-byte Asteroid 0 Z

					; [3,S]		1-byte General Purpose
					; [2,S]		1-byte # of objects
					; [1,S]		1-byte Sub counter
					; [,S]		1-byte Counter


FLYING_THROUGH_ASTEROID_STACK_USE		EQU		56
FLYING_THROUGH_ASTEROID_OBJ_POS_OFFSET	EQU		8
FLYING_THROUGH_ASTEROID_STEPZ			EQU		4
FLYING_THROUGH_ASTEROID_MINZ			EQU		1

FLYING_THROUGH_ASTEROID
					LDB		#FLYING_THROUGH_ASTEROID_STACK_USE

FLYING_THROUGH_ASTEROID_CLEAR_LOOP
					CLR		,-S
					DECB
					BNE		FLYING_THROUGH_ASTEROID_CLEAR_LOOP

					CLR		,S

					LEAU	FLYING_THROUGH_ASTEROID_OBJ_POS_OFFSET,S

					LEAX	ASTEROID_DATA,PCR
					STX		2,U
					LDD		#80	; X
					STD		4,U
					LDD		#60	; Y
					STD		6,U
					LDA		#100 ; Scaling
					STA		11,U

					LEAU	12,U

					LEAX	ASTEROID_DATA,PCR
					STX		2,U
					LDD		#220	; X
					STD		4,U
					LDD		#120	; Y
					STD		6,U
					LDA		#100    ; Scaling
					STA		11,U

					LEAU	12,U

					LEAX	ASTEROID_DATA,PCR
					STX		2,U
					LDD		#140	; X
					STD		4,U
					LDD		#180	; Y
					STD		6,U
					LDA		#100    ; Scaling
					STA		11,U

					LEAU	12,U

					LEAX	DUCKY_WIREFRAME_DATA,PCR
					STX		2,U
					LDD		#160	; X
					STD		4,U
					LDD		#100	; Y
					STD		6,U
					LDA		#100    ; Scaling
					STA		11,U

					LDB		#4
					STB		2,S

					LDB		#FLYING_THROUGH_ASTEROID_MINZ+FLYING_THROUGH_ASTEROID_STEPZ*15
					STB		4,S
					LDB		#FLYING_THROUGH_ASTEROID_MINZ+FLYING_THROUGH_ASTEROID_STEPZ*10
					STB		5,S
					LDB		#FLYING_THROUGH_ASTEROID_MINZ+FLYING_THROUGH_ASTEROID_STEPZ*5
					STB		6,S
					LDB		#3
					STB		7,S


FLYING_THROUGH_ASTEROID_LOOP


					; Tentative >>
					LEAU	FLYING_THROUGH_ASTEROID_OBJ_POS_OFFSET,S
					INC		10,U
					LEAU	12,U
					INC		10,U
					LEAU	12,U
					INC		10,U
					LEAU	12,U
					INC		10,U
					; Tentative <<


					LBSR	FLYING_THROUGH_ASTEROID_UPDATE_XY
					BSR		FLYING_THROUGH_ASTEROID_UPDATE_ZOOM
					BSR		FLYING_THROUGH_ASTEROID_RENDER

					; Move Asteroids (not Ducky) closer
					LDA		4,S
					LBSR	FLYING_THROUGH_ASTEROID_MOVE_ASTEROID_Z
					STA		4,S

					LDA		5,S
					LBSR	FLYING_THROUGH_ASTEROID_MOVE_ASTEROID_Z
					STA		5,S

					LDA		6,S
					LBSR	FLYING_THROUGH_ASTEROID_MOVE_ASTEROID_Z
					STA		6,S


					; Random rotations
					LEAU	8,S
					LDD		8,U
					ADDA	#8
					SUBB	#5
					STD		8,U

					LEAU	12,U
					LDD		8,U
					ADDA	#3
					SUBB	#7
					STD		8,U

					LEAU	12,U
					LDD		8,U
					SUBA	#4
					ADDB	#9
					STD		8,U

					LEAU	12,U
					LDD		8,U
					SUBA	#10
					ADDB	#14
					STD		8,U

					LBSR	TIMER_GET_COUNTER_LOW
					CMPD	#$D100	; BGM Timing
					BGE		ASTEROID_EXIT

					DEC		,S
					BNE		FLYING_THROUGH_ASTEROID_LOOP

ASTEROID_EXIT


					LEAS	FLYING_THROUGH_ASTEROID_STACK_USE,S
					RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FLYING_THROUGH_ASTEROID_UPDATE_ZOOM
					LEAX	DIVTABLE,PCR
					LEAY	2+4,S
					LEAU	2+FLYING_THROUGH_ASTEROID_OBJ_POS_OFFSET,S

					LDA		#4
					PSHS	A

					CLRA

FLYING_THROUGH_ASTEROID_UPDATE_ZOOM_LOOP
					LDB		,Y+
					LDB		D,X
					STB		11,U

					LEAU	12,U
					DEC		,S
					BNE		FLYING_THROUGH_ASTEROID_UPDATE_ZOOM_LOOP

					PULS	A,PC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FLYING_THROUGH_ASTEROID_RENDER
 					LEAX	PROJECTION_AREA,PCR
					LEAY	2+FLYING_THROUGH_ASTEROID_OBJ_POS_OFFSET,S		; Model data, coordinates, orientation
					LDB		2+2,S		; Object count
					LBSR	PROJECT_ORTHOGONAL_MULTI

					LBSR	HALT_SUBCPU
					LBSR	MMR_ENABLE_ACCESS_SUBCPU_RAM


					LDY		#LINEDATA_BUF
					LDA		2,S
					ANDA	#1
					LBSR	SUBCPU_PUSH_BEGIN_FRAME_CMD


					;    X   Projected-data pointer
					;    U   Model information pointer
					;    Y   Destination pointer
					;    B   Model count
					LEAX	PROJECTION_AREA,PCR
					LEAU	2+FLYING_THROUGH_ASTEROID_OBJ_POS_OFFSET,S
					LDB		2+2,S
					LBSR	PROJECT_ORTHOGONAL_PUSH_TO_SUBCPU_SPACE



					LDA		2,S
					ANDA	#1
					LBSR	SUBCPU_PUSH_END_FRAME_CMD


					LDA		#LINE_CMD_2D_END_OF_CMDSET
					STA		,Y+


					LBSR	MMR_DISABLE
					LBSR	RELEASE_SUBCPU

					RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FLYING_THROUGH_ASTEROID_UPDATE_XY
					; Update XY based on the distance.
					LEAU	2+FLYING_THROUGH_ASTEROID_OBJ_POS_OFFSET,S

					LDX		#-127
					LDY		#70
					LDB		2+4,S
					LBSR	PROJECT_PERSPECTIVE_ONE_COORD
					LEAX	-30,X ; Shift center (Not to hide the ducky)
					STX		4,U
					LEAY	-15,Y ; Shift center (Not to hide the ducky)
					STY		6,U

					LEAU	12,U

					LDX		#127
					LDY		#-10
					LDB		2+5,S
					LBSR	PROJECT_PERSPECTIVE_ONE_COORD
					LEAX	30,X ; Shift center (Not to hide the ducky)
					STX		4,U
					STY		6,U

					LEAU	12,U

					LDX		#-30
					LDY		#-127
					LDB		2+6,S
					LBSR	PROJECT_PERSPECTIVE_ONE_COORD
					STX		4,U
					LEAY	30,Y  ; Shift center (Not to hide the ducky)
					STY		6,U

					RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FLYING_THROUGH_ASTEROID_MOVE_ASTEROID_Z
					SUBA	#FLYING_THROUGH_ASTEROID_STEPZ
					CMPA	#FLYING_THROUGH_ASTEROID_MINZ
					BPL		FLYING_THROUGH_ASTEROID_MOVE_ASTEROID_Z_RTS
					LDA		#FLYING_THROUGH_ASTEROID_MINZ+15*FLYING_THROUGH_ASTEROID_STEPZ

FLYING_THROUGH_ASTEROID_MOVE_ASTEROID_Z_RTS
					RTS
