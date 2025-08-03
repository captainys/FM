


DEMO2019_INTRO
					LEAX	CUBE_WIREFRAME_DATA,PCR
					STX		DEMO2019_INTRO_SEQUENCE_MODEL1_PTR,PCR
					STX		DEMO2019_INTRO_SEQUENCE_MODEL2_PTR,PCR
					STX		DEMO2019_INTRO_SEQUENCE_MODEL3_PTR,PCR
					STX		DEMO2019_INTRO_SEQUENCE_MODEL4_PTR,PCR
					BSR		DEMO2019_INTRO_SEQUENCE
					RTS

DEMO2019_FOUR_DUCKY
					LEAX	DUCKY_WIREFRAME_DATA,PCR
					STX		DEMO2019_INTRO_SEQUENCE_MODEL1_PTR,PCR
					STX		DEMO2019_INTRO_SEQUENCE_MODEL2_PTR,PCR
					STX		DEMO2019_INTRO_SEQUENCE_MODEL3_PTR,PCR
					STX		DEMO2019_INTRO_SEQUENCE_MODEL4_PTR,PCR
					BSR		DEMO2019_INTRO_SEQUENCE
					RTS

DEMO2019_INTRO_SEQUENCE_MODEL1_PTR		FDB		CUBE_WIREFRAME_DATA
DEMO2019_INTRO_SEQUENCE_MODEL2_PTR		FDB		CUBE_WIREFRAME_DATA
DEMO2019_INTRO_SEQUENCE_MODEL3_PTR		FDB		CUBE_WIREFRAME_DATA
DEMO2019_INTRO_SEQUENCE_MODEL4_PTR		FDB		CUBE_WIREFRAME_DATA

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


DEMO2019_INTRO_SEQUENCE_STACK_RESERVE_SIZE		EQU		54


DEMO2019_INTRO_SEQUENCE
					LBSR	LOCAL_TIMER_RESET


					;	Repeat four times >>
					;	[0,S]	+0	2-byte 	Line data pointer
					;	[2,S]	+2	2-byte	Model Data pointer
					;	[4,S]	+4	2-byte 	Center x
					;	[6,S]	+6	2-byte 	Center y
					;	[8,S]	+8	1-byte	Heading angle
					;	[9,S]	+9	1-byte	Pitch angle
					;	[10,S]	+10	1-byte 	Bank angle
					;	[11,S]	+11	1-byte 	Scaling
					;	Repeat four times <<
					;	[48,S]		1-byte	Parameter t
					;	[49,S]		1-byte	Which model? (0-3)
					;	[50,S]		1-byte	sin(t)
					;	[51,S]		1-byte	Frame count
					;	[52,S]		2-byte	Unused

					LEAS	-DEMO2019_INTRO_SEQUENCE_STACK_RESERVE_SIZE,S


					LEAY	,S
					LDB		#DEMO2019_INTRO_SEQUENCE_STACK_RESERVE_SIZE
DEMO2019_INTRO_CLEAR
					CLR		,Y+
					DECB
					BNE		DEMO2019_INTRO_CLEAR

					LEAY	,S
					LDX		#65
					CLRB

DEMO2019_INTRO_INIT_COORD
					LEAU	DEMO2019_INTRO_SEQUENCE_MODEL1_PTR,PCR
					LDU		B,U
					STU		2,Y		; Model-data pointer

					STX		4,Y		; X
					LDU		#100
					STU		6,Y		; Y
					LDU		#$0032	; Rotation, Scaling
					STU		10,Y
					LEAY	12,Y
					LEAX	65,X

					ADDB	#2
					CMPB	#8
					BCS		DEMO2019_INTRO_INIT_COORD


DEMO2019_INTRO_OUTSIDE_LOOP
					INC		51,S


					LEAY	,S
					LDD		8,Y		; Heding, Pitch
					ADDA	#7
					SUBB	#7
					STD		8,Y
					INC		10,Y	; Bank

					LEAY	12,Y
					LDD		8,Y		; Heding, Pitch
					SUBB	#7
					STD		8,Y
					DEC		10,Y	; Bank

					LEAY	12,Y
					LDD		8,Y		; Heding, Pitch
					SUBA	#7
					STD		8,Y
					LDA		10,Y
					ADDA	#15
					STA		10,Y	; Bank

					LEAY	12,Y
					LDD		8,Y		; Heding, Pitch
					ADDA	#15
					ADDB	#3
					STD		8,Y
					LDA		10,Y
					SUBA	#15
					STA		10,Y	; Bank



					LDD		CLOCK_COUNTER_LOCAL,PCR
					LSRA
					RORB
					STB		48,S

					LSLB
					LDA		#255
					LBSR	SIN8
					STA		50,S


					LEAX	PROJECTION_AREA,PCR
					LEAY	,S
					LDB		#4
					LBSR	PROJECT_ORTHOGONAL_MULTI


					LBSR	HALT_SUBCPU
					LBSR	MMR_ENABLE_ACCESS_SUBCPU_RAM


					LDY		#LINEDATA_BUF
					LDA		51,S
					LBSR	SUBCPU_PUSH_BEGIN_FRAME_CMD


					LEAX	PROJECTION_AREA,PCR
					LEAU	,S
					LDB		#4
					LBSR	PROJECT_ORTHOGONAL_PUSH_TO_SUBCPU_SPACE


					LDA		#LINE_CMD_2D_END_OF_CMDSET
					STA		,Y+


					LBSR	MMR_DISABLE
					LBSR	RELEASE_SUBCPU


					LDD		CLOCK_COUNTER_LOCAL,PCR
					CMPD	#$1000
					LBCS	DEMO2019_INTRO_OUTSIDE_LOOP


					LEAS	DEMO2019_INTRO_SEQUENCE_STACK_RESERVE_SIZE,S
					RTS


;					[7,S]	8bit	Pitch
;					[6,S]	8bit	Heading
;					[4,S]	16bit	Pointer to the model
;					[2,S]	16bit	Pointer to the command output

INTRO_SETUP_VERTICAL_OR_HORIZONTAL
					BCC		INTRO_SETUP_HORIZONTAL

INTRO_SETUP_VERTICAL
					BSR		INTRO_SETUP_VERTICAL_OR_HORIZONTAL_MATH

					STD		4,Y
					LDD		#0
					STD		6,Y

					LDB		,Y
					LSLB
					STB		6,S
					CLR		7,S

					RTS

INTRO_SETUP_HORIZONTAL
					BSR		INTRO_SETUP_VERTICAL_OR_HORIZONTAL_MATH

					STD		6,Y
					LDD		#0
					STD		4,Y

					RTS

INTRO_SETUP_VERTICAL_OR_HORIZONTAL_MATH
					LDA		#127
					LDB		,Y
					LSLB

					LBSR	SIN8

					TFR		A,B
					SEX

					RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



