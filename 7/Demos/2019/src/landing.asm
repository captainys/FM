
LANDING_STACK_SIZE		EQU		34

LANDING
						;	[33,S]	+11	1-byte 	Scaling
						;	[32,S]	+10	1-byte 	Bank angle
						;	[31,S]	+9	1-byte	Pitch angle
						;	[30,S]	+8	1-byte	Heading angle
						;	[28,S]	+6	2-byte 	Center y
						;	[26,S]	+4	2-byte 	Center x
						;	[24,S]	+2	2-byte	Model Data pointer
						;	[22,S]	+0	2-byte 	Line data pointer

						;	[2,S]		End-of-Segment flag.
						;	[1,S]		Frame Counter
						;	[,S]		Sequence Counter

						LDB		#LANDING_STACK_SIZE
LANDING_CLEAR_LOOP
						CLR		,-S
						DECB
						BNE		LANDING_CLEAR_LOOP


						LBSR	LANDING_RENDER_BACKGROUND

						BSR		LANDING_INIT

LANDING_LOOP_SEQUENCE_0
						LBSR	LANDING_TRANSFORM
						LBSR	LANDING_RENDER
						INC		1,S

						BSR		LANDING_MOVE_SEQUENCE0
						BCC		LANDING_LOOP_SEQUENCE_0


LANDING_LOOP_SEQUENCE_1
						LBSR	LANDING_MOVE_SEQUENCE1
						LBSR	LANDING_TRANSFORM
						LBSR	LANDING_RENDER

						LDA		2,S
						BNE		LANDING_EXIT

						INC		1,S
						BNE		LANDING_LOOP_SEQUENCE_1


LANDING_EXIT
						LEAS	LANDING_STACK_SIZE,S
						RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LANDING_INIT
						LDA		#1
						STA		2+33,S	; Scaling
						LDA		#$80
						STA		2+30,S	; Heading
						LDA		#120
						STA		2+31,S	; Pitch

						LDX		#280
						STX		2+26,S	; CX
						LDX		#48
						STX		2+28,S	; CY

						LEAX	DUCKY_WIREFRAME_DATA,PCR
						STX		2+24,S	; Model data pointer

						RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LANDING_MOVE_SEQUENCE0
						LDA		2+30,S		; Heading
						ADDA	#7
						STA		2+30,S
						LDA		2+31,S		; Pitch
						ADDA	#5
						STA		2+31,S
						LDA		2+32,S		; Bank
						ADDA	#11
						STA		2+32,S

						LDD		2+26,S		; CX
						SUBD	#1
						STD		2+26,S

						LDA		2+1,S
						ANDA	#1
						BNE		LANDING_MOVE_SEQUENCE0_SKIPY

						LDD		2+28,S		; CY
						SUBD	#1
						STD		2+28,S
LANDING_MOVE_SEQUENCE0_SKIPY

						LDA		2+1,S
						ANDA	#3
						BNE		LANDING_MOVE_SEQUENCE0_SCALING

						INC		2+33,S		; Scaling
LANDING_MOVE_SEQUENCE0_SCALING

						LDD		2+28,S		; CY
						CMPD	#-32
						BLE		LANDING_MOVE_SEQUENCE0_TERMINAL

						CLRA
						RTS

LANDING_MOVE_SEQUENCE0_TERMINAL
						LDD		#0
						STD		2+28,S		; CY
						COMA
						RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LANDING_MOVE_SEQUENCE1
						LDA		#100
						STA		2+33,S	; Scaling

						LDD		#136
						STD		2+26,S	; CX

						CLR		2+32,S	; Bank
						LDA		#-8
						STA		2+31,S	; Pitch
						LDA		#$B0
						STA		2+30,S	; Heading

						LDD		2+28,S	; CY
						CMPD	#152
						BEQ		LANDING_MOVE_SEQUENCE1_END_OF_SEGMENT
						BCC		LANDING_MOVE_SEQUENCE1_TERMINAL

						ADDD	#32
						STD		2+28,S

						CLRA
						RTS

LANDING_MOVE_SEQUENCE1_END_OF_SEGMENT
						COM		2+2,S

LANDING_MOVE_SEQUENCE1_TERMINAL
						LDD		#152
						STD		2+28,S

						COMA
						RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LANDING_TRANSFORM
						RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LANDING_RENDER
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


LANDING_RENDER_BACKGROUND
						LBSR	HALT_SUBCPU
						LBSR	MMR_ENABLE_ACCESS_SUBCPU_RAM


						LDY		#LINEDATA_BUF

						LDA		#LINE_CMD_SELECT_BANK1
						STA		,Y+

						LDA		#LINE_CMD_CLS
						STA		,Y+

						LDA		#LINE_CMD_SET_OFFSET
						STA		,Y+
						LDD		#$0
						STD		,Y++

						LDA		#LINE_CMD_SET_TRANS
						STA		,Y+
						LDD		#$00FF		; Rotation, Scaling
						STD		,Y++
						LDD		#160		; CX
						STD		,Y++
						LDD		#100		; CX
						STD		,Y++

						LDA		#LINE_CMD_2D_TRANS_CLIP
						STA		,Y+
						LEAX	CMU_2D_DATA,PCR
						LDB		,X+
						STB		,Y+
LANDING_RENDER_BACKGROUND_TRANSFER_FIRST_HALF
						LDA		,X+		; C
						ANDA	#7
						STA		,Y+
						LDU		,X++	; XY
						STU		,Y++
						LDU		,X++	; XY
						STU		,Y++
						DECB
						BNE		LANDING_RENDER_BACKGROUND_TRANSFER_FIRST_HALF

						LDA		#LINE_CMD_2D_END_OF_CMDSET
						STA		,Y+


						; Quick Release and Halt may result in pre-mature halt.
						; Make sure Sub CPU is done with the job.
						; If not, release and wait.
LANDING_RENDER_BACKGROUND_SUBCPU_JOB_WAIT
						LBSR	MMR_DISABLE
						LBSR	RELEASE_SUBCPU
						LBSR	HALT_SUBCPU
						LBSR	MMR_ENABLE_ACCESS_SUBCPU_RAM
						LDA		LINEDATA_BUF
						BNE		LANDING_RENDER_BACKGROUND_SUBCPU_JOB_WAIT


						LDY		#LINEDATA_BUF

						LDA		#LINE_CMD_SELECT_BANK1
						STA		,Y+

						LDA		#LINE_CMD_SET_OFFSET
						STA		,Y+
						LDD		#$2000
						STD		,Y++


						LDA		#LINE_CMD_2D_TRANS_CLIP
						STA		,Y+
						LEAX	CMU_2D_DATA,PCR
						LDB		,X+
						STB		,Y+
LANDING_RENDER_BACKGROUND_TRANSFER_SECOND_HALF
						LDA		,X+		; C
						LSRA
						LSRA
						LSRA
						LSRA
						ANDA	#7
						STA		,Y+
						LDU		,X++	; XY
						STU		,Y++
						LDU		,X++	; XY
						STU		,Y++
						DECB
						BNE		LANDING_RENDER_BACKGROUND_TRANSFER_SECOND_HALF


						LDA		#LINE_CMD_SELECT_BANK0
						STA		,Y+

						LDA		#LINE_CMD_2D_END_OF_CMDSET
						STA		,Y+

						LBSR	MMR_DISABLE
						LBSR	RELEASE_SUBCPU

						RTS

