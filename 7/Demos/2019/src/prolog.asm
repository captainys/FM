					EXPORT			DEMO2019_PROLOG_SEQUENCE



DEMO2019_PROLOG_STACK_RESERVE_SIZE		EQU		35


DEMO2019_PROLOG_SEQUENCE

					;	[0,S]	+0	2-byte 	Line data pointer
					;	[2,S]	+2	2-byte	Model Data pointer
					;	[4,S]	+4	2-byte 	Center x
					;	[6,S]	+6	2-byte 	Center y
					;	[8,S]	+8	1-byte	Heading angle
					;	[9,S]	+9	1-byte	Pitch angle
					;	[10,S]	+10	1-byte 	Bank angle
					;	[11,S]	+11	1-byte 	Scaling

					;	[12,S]	+0	2-byte 	Line data pointer
					;	[14,S]	+2	2-byte	Model Data pointer
					;	[16,S]	+4	2-byte 	Center x
					;	[18,S]	+6	2-byte 	Center y
					;	[20,S]	+8	1-byte	Heading angle
					;	[21,S]	+9	1-byte	Pitch angle
					;	[22,S]	+10	1-byte 	Bank angle
					;	[23,S]	+11	1-byte 	Scaling

					;	[24,S]		1-byte	Parameter t
					;	[25,S]		1-byte	Which model? (0-3)
					;	[26,S]		1-byte	sin(t)
					;	[27,S]		1-byte	Frame count
					;	[28,S]		2-byte	Current data pointer
					;	[30,S]		1-byte  Per-Scene Progress Counter
					;	[31,S]		2-byte  Whole Prolog Progress Counter
					;	[33,S]		2-byte	Message Pointer


					LEAS	-DEMO2019_PROLOG_STACK_RESERVE_SIZE,S

					LEAY	,S
					LDB		#DEMO2019_PROLOG_STACK_RESERVE_SIZE
DEMO2019_PROLOG_RESET_LOOP
					CLR		,Y+
					DECB
					BNE		DEMO2019_PROLOG_RESET_LOOP


					LEAY	,S
					LBSR	LOCAL_TIMER_RESET



					; (1) Spin the ducky, move to the left.

					LEAX	DUCKY_WIREFRAME_DATA,PCR
					STX		2,S
					LDX		#160
					STX		4,S
					LDX		#100
					STX		6,S
					LDX		#$0000	; Heading, Pitch
					STX		8,S
					LDX		#$0010	; Bank, Scaling
					STX		10,S

					CLR		30,S
					CLR		31,S
					CLR		32,S
					LEAX	DEMO2019_PROLOG_TEXT,PCR
					STX		33,S



DEMO2019_SPIN_DUCKY_LOOP
					LDX		31,S
					LEAX	1,X
					STX		31,S

 					LEAX	PROJECTION_AREA,PCR
					STX		28,S	; Current line-data pointer

					LEAY	,S		; Model data, coordinates, orientation
					LDB		#1		; One model
					LBSR	PROJECT_ORTHOGONAL_MULTI

					LBSR	HALT_SUBCPU
					LBSR	MMR_ENABLE_ACCESS_SUBCPU_RAM


					LDY		#LINEDATA_BUF
					LDA		27,S
					ANDA	#1
					LBSR	SUBCPU_PUSH_BEGIN_FRAME_CMD


					;    X   Projected-data pointer
					;    U   Model information pointer
					;    Y   Destination pointer
					;    B   Model count
					LEAX	PROJECTION_AREA,PCR
					LEAU	,S
					LDB		#1
					LBSR	PROJECT_ORTHOGONAL_PUSH_TO_SUBCPU_SPACE


					LBSR	DEMO2019_PROLOG_ADD_TEXT


					LDA		27,S
					ANDA	#1
					LBSR	SUBCPU_PUSH_END_FRAME_CMD
					INC		27,S


					LDA		#LINE_CMD_2D_END_OF_CMDSET
					STA		,Y+


					LBSR	MMR_DISABLE
					LBSR	RELEASE_SUBCPU

					LDA		11,S
					BMI		DEMO2019_SPIN_DUCKY_SCALED_UP
					ADDA	#$10
					STA		11,S
					BRA		DEMO2019_SPIN_DUCKY_LOOP

DEMO2019_SPIN_DUCKY_SCALED_UP
					LDA		8,S
					SUBA	#3
					STA		8,S
					CMPA	#$48
					BCC		DEMO2019_SPIN_DUCKY_LOOP



					; Ostrich breaks in

					LEAX	OSTRICH_DATA,PCR
					STX		14,S
					LDX		#0
					STX		16,S	;X
					LDX		#100
					STX		18,S	;Y
					LDX		#$4000	; Heading, Pitch
					STX		20,S
					LDX		#$0080	; Bank, Scaling
					STX		22,S

					CLR		30,S

DEMO2019_PROLOG_OSTRICH_ENTRY_LOOP
					LDX		31,S
					LEAX	1,X
					STX		31,S

 					LEAX	PROJECTION_AREA,PCR
					STX		28,S	; Current line-data pointer

					LEAY	,S		; Model data, coordinates, orientation
					LDB		#2		; Two models
					LBSR	PROJECT_ORTHOGONAL_MULTI

					LBSR	HALT_SUBCPU
					LBSR	MMR_ENABLE_ACCESS_SUBCPU_RAM


					LDY		#LINEDATA_BUF
					LDA		27,S
					ANDA	#1
					LBSR	SUBCPU_PUSH_BEGIN_FRAME_CMD


					;    X   Projected-data pointer
					;    U   Model information pointer
					;    Y   Destination pointer
					;    B   Model count
					LEAX	PROJECTION_AREA,PCR
					LEAU	,S
					LDB		#2
					LBSR	PROJECT_ORTHOGONAL_PUSH_TO_SUBCPU_SPACE

					LDD		31,S
					CMPD	DEMO2019_PROLOG_TEXT_DUCKY_SPEAKS,PCR
					BCS		DEMO2019_PROLOG_NO_BALLOON
					LDA		#DUCKY_BALLOON_END-DUCKY_BALLOON
					LEAX	DUCKY_BALLOON,PCR
DEMO2019_PROLOG_BALLOON_LOOP
					LDB		,X+
					STB		,Y+
					DECA
					BNE		DEMO2019_PROLOG_BALLOON_LOOP

DEMO2019_PROLOG_NO_BALLOON

					LBSR	DEMO2019_PROLOG_ADD_TEXT


					LDA		27,S
					ANDA	#1
					LBSR	SUBCPU_PUSH_END_FRAME_CMD
					INC		27,S

					LDA		#LINE_CMD_2D_END_OF_CMDSET
					STA		,Y+


					LBSR	MMR_DISABLE
					LBSR	RELEASE_SUBCPU


					LDA		30,S
					DECA
					BEQ		DEMO2019_PROLOG_OSTRICH_ENTRY_1
					DECA
					BEQ		DEMO2019_PROLOG_OSTRICH_ENTRY_2

DEMO2019_PROLOG_OSTRICH_ENTRY_0
					LDA		20,S
					ADDA	#$14
					STA		20,S

					LDD		16,S
					ADDD	#16		; 10 steps
					STD		16,S
					CMPD	#160
					BCS		DEMO2019_PROLOG_OSTRICH_ENTRY_NEXT
					INC		30,S
					BRA		DEMO2019_PROLOG_OSTRICH_ENTRY_NEXT

DEMO2019_PROLOG_OSTRICH_ENTRY_1
					LDA		20,S
					SUBA	#10
					STA		20,S

					LDD		16,S
					SUBD	#8
					STD		16,S

					LDA		9,S
					ADDA	#25
					STA		9,S

					LDD		4,S
					ADDD	#8
					STD		4,S
					CMPD	#240
					BCS		DEMO2019_PROLOG_OSTRICH_ENTRY_NEXT
					INC		30,S
					BRA		DEMO2019_PROLOG_OSTRICH_ENTRY_NEXT

DEMO2019_PROLOG_OSTRICH_ENTRY_2

DEMO2019_PROLOG_OSTRICH_ENTRY_NEXT
					LDD		31,S
					CMPD	#340
					LBNE	DEMO2019_PROLOG_OSTRICH_ENTRY_LOOP



					;;;;;;;;;;;;;;;;;;;;;;;;;;;;

					; Clear Text
					LBSR	SUBCPU_BANK1_CLS_AND_FLUSH

					;;;;;;;;;;;;;;;;;;;;;;;;;;;;



					LDB		#2
					STB		30,S

DEMO2019_PROLOG_DUCKY_FALL_LOOP
 					LEAX	PROJECTION_AREA,PCR
					STX		28,S	; Current line-data pointer

					LEAY	,S		; Model data, coordinates, orientation
					LDB		30,S	; One or Two models
					LBSR	PROJECT_ORTHOGONAL_MULTI

					LBSR	HALT_SUBCPU
					LBSR	MMR_ENABLE_ACCESS_SUBCPU_RAM


					LDY		#LINEDATA_BUF
					LDA		27,S
					ANDA	#1
					LBSR	SUBCPU_PUSH_BEGIN_FRAME_CMD


					;    X   Projected-data pointer
					;    U   Model information pointer
					;    Y   Destination pointer
					;    B   Model count
					LEAX	PROJECTION_AREA,PCR
					LEAU	,S
					LDB		30,S
					LBSR	PROJECT_ORTHOGONAL_PUSH_TO_SUBCPU_SPACE

					LBSR	DEMO2019_PROLOG_ADD_TEXT


					LDA		27,S
					ANDA	#1
					LBSR	SUBCPU_PUSH_END_FRAME_CMD
					INC		27,S
					LDA		#LINE_CMD_2D_END_OF_CMDSET
					STA		,Y+


					LBSR	MMR_DISABLE
					LBSR	RELEASE_SUBCPU



					LDA		10,S	; Bank
					SUBA	#$0C
					STA		10,S

					LDD		6,S		; Y
					ADDD	#4
					STD		6,S

					CMPD	#220
					BCS		DEMO2019_PROLOG_DUCKY_FALL_LOOP

					LDD		4,S
					CMPD	#160
					BEQ		DEMO2019_PROLOG_DUCKY_FALL_LOOP_EXIT

					LDU		#2+20*40	; VRAM addr ($0000-$2000)
					LEAX	BMP_GALAXY_96X96,PCR
					LBSR	DRAW_BITMAP_64_PAGE1

					LDU		#240/8+80*40	; VRAM addr ($0000-$2000)
					LEAX	BMP_STAR_BLUE_16X16,PCR
					LBSR	DRAW_BITMAP_64_PAGE1

					LDU		#280/8+120*40	; VRAM addr ($0000-$2000)
					LEAX	BMP_STAR_BLUE_16X16,PCR
					LBSR	DRAW_BITMAP_64_PAGE1


					LDA		#1
					STA		30,S
					LDD		#160
					STD		4,S
					LDD		#0
					STD		6,S
					LBRA	DEMO2019_PROLOG_DUCKY_FALL_LOOP


DEMO2019_PROLOG_DUCKY_FALL_LOOP_EXIT



					LEAS	DEMO2019_PROLOG_STACK_RESERVE_SIZE,S
					RTS



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


					;	[31,U]		2-byte  Whole Prolog Progress Counter
					;	[33,U]		2-byte	Message Pointer

					; Output
					;   [33,U]      2-byte  Next message pointer
					;   Y			Current Sub-CPU command ptr.
DEMO2019_PROLOG_ADD_TEXT
					PSHS	A,B,X,U
					LEAU	8,S   ; 6 bytes + return address

					LDX		33,U
					LDD		,X
					CMPD	#$FFFF
					BEQ		DEMO2019_PROLOG_ADD_TEXT_EXIT

					LDD		31,U
					CMPD	,X++
					BCS		DEMO2019_PROLOG_ADD_TEXT_EXIT

					LDA		#LINE_CMD_SELECT_BANK1
					STA		,Y+

					LDA		#LINE_CMD_PRINT
					STA		,Y+
					LDA		#63		; Color
					STA		,Y+

					LEAU	,Y+		; Number of letters

					LDD		,X++	; VRAM addr
					STD		,Y++

					CLRB
DEMO2019_PROLOG_ADD_TEXT_LOOP
					LDA		,X+
					BEQ		DEMO2019_PROLOG_ADD_TEXT_LOOP_END
					STA		,Y+
					INCB
					BRA		DEMO2019_PROLOG_ADD_TEXT_LOOP

DEMO2019_PROLOG_ADD_TEXT_LOOP_END
					STB		,U

					LDA		#LINE_CMD_SELECT_BANK0
					STA		,Y+

					LEAU	8,S   ; 6 bytes + return address
					STX		33,U

DEMO2019_PROLOG_ADD_TEXT_EXIT
					PULS	A,B,X,U,PC

DEMO2019_PROLOG_TEXT
					FDB		35
					FDB		16/8+8*40
					FCB		"IN DEMOSPLASH 2018....",0

					FDB		70
					FDB		16/8+16*40
					FCB		"A DUCKY ",0

					FDB		105
					FDB		80/8+16*40
					FCB		"LOST TO AN OSTRICH",0

					FDB		140
					FDB		16/8+24*40
					FCB		"BY ONE VOTE",0


					FDB		140
					FDB		16/8+160*40
					FCB		"146 votes",0

					FDB		140
					FDB		16/8+168*40
					FCB		"Cycle-Counting",0

					FDB		140
					FDB		16/8+176*40
					FCB		"Megademo",0

					FDB		140
					FDB		16/8+184*40
					FCB		"(Apple IIe)",0


					FDB		140
					FDB		168/8+160*40
					FCB		"145 votes",0

					FDB		140
					FDB		168/8+168*40
					FCB		"The Golden Age of",0

					FDB		140
					FDB		168/8+176*40
					FCB		"Fujitsu Micro",0

					FDB		140
					FDB		168/8+184*40
					FCB		"(FM TOWNS)",0


DEMO2019_PROLOG_TEXT_DUCKY_SPEAKS
					FDB		180
					FDB		144/8+40*40
					FCB		"CAN I ORDER RECOUNT? ",0

					FDB		220
					FDB		144/8+40*40
					FCB		"NO HANGING CHADS?    ",0

					FDB		260
					FDB		144/8+40*40
					FCB		"NO RUSSIAN INFLUENCE?",0

					FDB		300
					FDB		144/8+40*40
					FCB		"QUAAAAAACK!!!!       ",0

					FDB		$FFFF


DUCKY_BALLOON
					FCB		#LINE_CMD_2D_NOCLIPPING
					FCB		12
					FCB		7
					FDB		248,64,257,51
					FCB		7
					FDB		257,51,313,51
					FCB		7
					FDB		313,51,317,47
					FCB		7
					FDB		317,47,317,38
					FCB		7
					FDB		317,38,313,34
					FCB		7
					FDB		313,34,142,34
					FCB		7
					FDB		142,34,138,38
					FCB		7
					FDB		138,38,138,47
					FCB		7
					FDB		138,47,142,51
					FCB		7
					FDB		142,51,250,51
					FCB		7
					FDB		250,51,248,64
					FCB		7
					FDB		248,64,248,64 
DUCKY_BALLOON_END

