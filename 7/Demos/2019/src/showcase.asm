
SHOWCASE_VOYAGER_STACK_SIZE		EQU	12

SHOWCASE_VOYAGER
						LDB		#SHOWCASE_VOYAGER_STACK_SIZE
SHOWCASE_VOYAGER_INIT_LOOP
						CLR		,-S
						DECB
						BNE		SHOWCASE_VOYAGER_INIT_LOOP


						LEAU	,S

						LEAX	VOYAGER_3D_DATA,PCR ; DUCKY_WIREFRAME_DATA,PCR ; 
						STX		2,U
						LDX		#160	; CX
						STX		4,U
						LDX		#100	; CY
						STX		6,U
						LDA		#16		; Pitch
						STA		9,U
						LDA		#200	; Scaling
						STA		11,U

						LDD		#$4804	; A=# of steps, B=Heading Increment
						LEAX	SHOWCASE_VOYAGER_MESSAGE0,PCR
						LEAY	SHOWCASE_VOYAGER_MESSAGE1,PCR
						LBSR	SHOWCASE

						LEAS	SHOWCASE_VOYAGER_STACK_SIZE,S
						RTS

SHOWCASE_VOYAGER_MESSAGE0
						FCB		63
						FDB		11+160*40
						FCB		"VOYAGER SPACECRAFT"
						FCB		0

SHOWCASE_VOYAGER_MESSAGE1
						FCB		63
						FDB		12+168*40
						FCB		"LAUNCHED IN 1977"
						FCB		0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SHOWCASE_ROVER_STACK_SIZE		EQU	12

SHOWCASE_ROVER
						LDB		#SHOWCASE_ROVER_STACK_SIZE
SHOWCASE_ROVER_INIT_LOOP
						CLR		,-S
						DECB
						BNE		SHOWCASE_ROVER_INIT_LOOP


						LEAU	,S

						LEAX	ROVER_3D_DATA,PCR ; DUCKY_WIREFRAME_DATA,PCR ; 
						STX		2,U
						LDX		#160	; CX
						STX		4,U
						LDX		#100	; CY
						STX		6,U
						LDA		#16		; Pitch
						STA		9,U
						LDA		#160	; Scaling
						STA		11,U

						LDD		#$1D09	; A=# of steps, B=Heading Increment
						LEAX	SHOWCASE_ROVER_MESSAGE0,PCR
						LEAY	SHOWCASE_ROVER_MESSAGE1,PCR
						LBSR	SHOWCASE

						LEAS	SHOWCASE_ROVER_STACK_SIZE,S
						RTS

SHOWCASE_ROVER_MESSAGE0
						FCB		63
						FDB		9+160*40
						FCB		"MARS ROVER OPPORTUNITY"
						FCB		0

SHOWCASE_ROVER_MESSAGE1
						FCB		63
						FDB		12+168*40
						FCB		"LAUNCHED IN 2003"
						FCB		0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SHOWCASE_NEWHORIZONS_STACK_SIZE		EQU	12

SHOWCASE_NEWHORIZONS
						LDB		#SHOWCASE_NEWHORIZONS_STACK_SIZE
SHOWCASE_NEWHORIZONS_INIT_LOOP
						CLR		,-S
						DECB
						BNE		SHOWCASE_NEWHORIZONS_INIT_LOOP


						LEAU	,S

						LEAX	NEWHORIZONS_3D_DATA,PCR ; DUCKY_WIREFRAME_DATA,PCR ; 
						STX		2,U
						LDX		#160	; CX
						STX		4,U
						LDX		#100	; CY
						STX		6,U
						LDA		#16		; Pitch
						STA		9,U
						LDA		#160	; Scaling
						STA		11,U

						LDD		#$4804	; A=# of steps, B=Heading Increment
						LEAX	SHOWCASE_NEWHORIZONS_MESSAGE0,PCR
						LEAY	SHOWCASE_NEWHORIZONS_MESSAGE1,PCR
						LBSR	SHOWCASE

						LEAS	SHOWCASE_NEWHORIZONS_STACK_SIZE,S
						RTS

SHOWCASE_NEWHORIZONS_MESSAGE0
						FCB		63
						FDB		8+160*40
						FCB		"NEW HORIZONS SPACECRAFT"
						FCB		0

SHOWCASE_NEWHORIZONS_MESSAGE1
						FCB		63
						FDB		12+168*40
						FCB		"LAUNCHED IN 2006"
						FCB		0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SHOWCASE_HUBBLE_STACK_SIZE		EQU	12

SHOWCASE_HUBBLE
						LDB		#SHOWCASE_HUBBLE_STACK_SIZE
SHOWCASE_HUBBLE_INIT_LOOP
						CLR		,-S
						DECB
						BNE		SHOWCASE_HUBBLE_INIT_LOOP


						LEAU	,S

						LEAX	HUBBLE_3D_DATA,PCR ; DUCKY_WIREFRAME_DATA,PCR ; 
						STX		2,U
						LDX		#160	; CX
						STX		4,U
						LDX		#100	; CY
						STX		6,U
						LDA		#16		; Pitch
						STA		9,U
						LDA		#200	; Scaling
						STA		11,U

						LDD		#$4004	;  A=# of steps, B=Heading Increment
						LEAX	SHOWCASE_HUBBLE_MESSAGE0,PCR
						LEAY	SHOWCASE_HUBBLE_MESSAGE1,PCR
						BSR		SHOWCASE

						LEAS	SHOWCASE_HUBBLE_STACK_SIZE,S
						RTS

SHOWCASE_HUBBLE_MESSAGE0
						FCB		63
						FDB		9+160*40
						FCB		"HUBBLE SPACE TELESCOPE"
						FCB		0

SHOWCASE_HUBBLE_MESSAGE1
						FCB		63
						FDB		12+168*40
						FCB		"LAUNCHED IN 1990"
						FCB		0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Input
;	A	Number of steps
;	B	Heading increment
;	U	Model-Info pointer
;	X	Message 1 pointer (or NULL)
;	Y	Message 2 pointer (or NULL)


					;	[11,U]	+11	1-byte 	Scaling
					;	[10,U]	+10	1-byte 	Bank angle
					;	[9,U]	+9	1-byte	Pitch angle
					;	[8,U]	+8	1-byte	Heading angle
					;	[6,U]	+6	2-byte 	Center y
					;	[4,U]	+4	2-byte 	Center x
					;	[2,U]	+2	2-byte	Model Data pointer
					;	[0,U]	+0	2-byte 	Line data pointer

					;	[3,X]	+3	n-byte	C string
					;	[1,X]	+1	2-byte	VRAM address
					;	[0,X]	+0			Color

SHOWCASE
						PSHS	U,Y,X,B,A
						LBSR	SUBCPU_BANK1_CLS_AND_FLUSH
						PULS	U,Y,X,B,A
						PSHS	U,Y,X,B,A

						CLR		,-S


					;	[7,S]	Model-Info pointer
					;	[5,S]	Message 2 pointer
					;	[3,S]	Message 1 pointer
					;	[2,S]	Heading Increment
					;	[1,S]	Frame counter (steps left)
					;	[,S]	Sequence counter

						BSR		SHOWCASE_MESSAGE
						LDX		5,S
						BSR		SHOWCASE_MESSAGE

SHOWCASE_LOOP
	 					LEAX	PROJECTION_AREA,PCR
						LDY		7,S		; Model-info pointer
						LDB		#1		; One model
						LBSR	PROJECT_ORTHOGONAL_MULTI


						LBSR	HALT_SUBCPU
						LBSR	MMR_ENABLE_ACCESS_SUBCPU_RAM


						LDY		#LINEDATA_BUF
						LDA		1,S
						ANDA	#1
						LBSR	SUBCPU_PUSH_BEGIN_FRAME_CMD


						LEAX	PROJECTION_AREA,PCR
						LDU		7,S		; Model-info pointer
						LDB		#1		; One model
						LBSR	PROJECT_ORTHOGONAL_PUSH_TO_SUBCPU_SPACE


						LDA		1,S
						ANDA	#1
						LBSR	SUBCPU_PUSH_END_FRAME_CMD

						LDA		#LINE_CMD_2D_END_OF_CMDSET
						STA		,Y+


						LBSR	MMR_DISABLE
						LBSR	RELEASE_SUBCPU





						LDU		7,S
						LDA		2,S
						ADDA	8,U
						STA		8,U

						DEC		1,S
						BNE		SHOWCASE_LOOP


						LBSR	SUBCPU_BANK1_CLS_AND_FLUSH

						LEAS	1,S

						PULS	A,B,X,Y,U,PC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


SHOWCASE_MESSAGE
						CMPX	#0
						BEQ		SHOWCASE_MESSAGE_EXIT

						LEAY	3,X
						CLRB

SHOWCASE_MESSAGE_STRLEN	TST		,Y+
						BEQ		SHOWCASE_MESSAGE_HAVE_NUM_LETTERS
						INCB
						BRA		SHOWCASE_MESSAGE_STRLEN
SHOWCASE_MESSAGE_HAVE_NUM_LETTERS

						; B: Num Letters


						LBSR	HALT_SUBCPU
						LBSR	MMR_ENABLE_ACCESS_SUBCPU_RAM


						LDY		#LINEDATA_BUF

						LDA		#LINE_CMD_SELECT_BANK1
						STA		,Y+

						LDA		#LINE_CMD_PRINT
						STA		,Y+
						LDA		,X+		; Color
						STA		,Y+

						STB		,Y+		; Number of letters

						LDD		,X++	; VRAM addr
						STD		,Y++

SHOWCASE_MESSAGE_STRCPY	LDA		,X+
						BEQ		SHOWCASE_MESSAGE_STRCPY_END
						STA		,Y+
						BRA		SHOWCASE_MESSAGE_STRCPY

SHOWCASE_MESSAGE_STRCPY_END
						LDA		#LINE_CMD_SELECT_BANK0
						STA		,Y+


						LDA		#LINE_CMD_2D_END_OF_CMDSET
						STA		,Y+


						LBSR	MMR_DISABLE
						LBSR	RELEASE_SUBCPU

SHOWCASE_MESSAGE_EXIT
						RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

