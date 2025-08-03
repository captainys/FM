;  Left-hand coordinate.  Z-plus is forward.

;	Input     (6 bytes in stack)
;				[7,S]	8bit	Pitch
;				[6,S]	8bit	Heading
;				[4,S]	16bit	Pointer to the model
;				[2,S]	16bit	Pointer to the command output
;	Output
;				B				Number of visible lines
;				[[2,S]]...		1-byte # visible lines
;								CXYXYCXYXY....  All 1 byte
;
;   Local Variables
;				[-3,Y]			3 bytes Temporary x,y,z
;				[-4,Y]			Number of visible lines
;
;				[COORD_AREA]		XYXYXYXY....  All 1 byte  -> Orthogonal projection doesn't care Z

PROJECT_ORTHOGONAL
				LEAY	,S
				LEAS	-4,S		; Temporary x,y,z,  Number of lines to draw

				LDU		4,Y
				LDB		,U+
				LBEQ	PROJECT_ORTHOGONAL_NO_VISIBLE_LINE

				LEAX	COORD_AREA,PCR
PROJECT_ORTHOGONAL_ROTATE_LOOP
				PSHS	B

				LDD		,U++		; x,y
				STD		-3,Y
				LDA		,U+			; z
				STA		-1,Y

				PSHS	X,Y,U
				LEAU	-3,Y
				LEAY	6,Y
				LBSR	PROJECT_ORTHOGONAL_ROTATE_HEADING_PITCH
				PULS	X,Y,U

				LDD		-3,Y		; x,y
				NEGB
				STD		,X++

				PULS	B
				DECB
				BNE		PROJECT_ORTHOGONAL_ROTATE_LOOP


				; Vertices are [COORD_AREA+vtIdx*2]


				LDX		2,Y

				CLR		,X+			; Tentative
				CLR		-4,Y

				LDB		,U+			; # of lines in the model

PROJECT_ORTHOGONAL_ADD_LINE_LOOP
				PSHS	B

				LDD		3,U
				STD		-3,Y
				LDA		5,U
				STA		-1,Y

				PSHS	X,Y,U
				LEAU	-3,Y
				LEAY	6,Y
				BSR		PROJECT_ORTHOGONAL_ROTATE_HEADING_PITCH_ZONLY
				PULS	X,Y,U

				TSTB	; nz'
				BLE		PROJECT_ORTHOGONAL_ADD_LINE_VISIBLE

				LDD		6,U
				STD		-3,Y
				LDA		8,U
				STA		-1,Y

				PSHS	X,Y,U
				LEAU	-3,Y
				LEAY	6,Y
				BSR		PROJECT_ORTHOGONAL_ROTATE_HEADING_PITCH_ZONLY
				PULS	X,Y,U

				TSTB	; nz'
				BGT		PROJECT_ORTHOGONAL_ADD_LINE_NOT_VISIBLE



PROJECT_ORTHOGONAL_ADD_LINE_VISIBLE
				PSHS	Y
				LDA		,U
				STA		,X+

				LEAY	COORD_AREA,PCR
				LDB		1,U
				CLRA
				LSLB
				ROLA
				LDD		D,Y
				NEGB			; Invert Y
				STD		,X++

				LDB		2,U
				CLRA
				LSLB
				ROLA
				LDD		D,Y
				NEGB			; Invert Y
				STD		,X++

				PULS	Y

				INC		-4,Y


PROJECT_ORTHOGONAL_ADD_LINE_NOT_VISIBLE
				LEAU	9,U

				PULS	B
				DECB
				BNE		PROJECT_ORTHOGONAL_ADD_LINE_LOOP


				LDU		2,Y
				LDB		-4,Y
				STB		,U
				BEQ		PROJECT_ORTHOGONAL_NO_VISIBLE_LINE

				LEAS	4,S

				RTS

PROJECT_ORTHOGONAL_NO_VISIBLE_LINE
				LEAS	4,S
				LDB		#0
				RTS


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Input
;				[,Y]	8bit	Heading
;				[1,Y]	8bit	Pitch

;				[,U]	8bit	nx
;				[1,U]	8bit	ny
;				[2,U]	8bit	nz

PROJECT_ORTHOGONAL_ROTATE_HEADING_PITCH
				; Pitch = Rotation in (Z,Y) plane
				; Equivalent to reverse rotation in (Y,Z) plane

				LDB		1,Y			; Pitch
				NEGB
				TFR		D,X
				LDD		1,U			; (A,B)=(y,z)
				LBSR	ROT8
				STD		1,U			; Write y,z

				LDX		-1,Y		; Heading (Force lower-8bit to be an angle)
				LDA		,U			; A=x
				LDB		2,U			; B=z
				LBSR	ROT8
				STA		,U
				STB		2,U
				RTS


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Input
;				[,Y]	8bit	Heading
;				[1,Y]	8bit	Pitch
; Input/Output
;				[,U]	8bit	nx
;				[1,U]	8bit	destroyed
;				[2,U]	8bit	nz
;				B				nz'
;				CC				Depends on B
PROJECT_ORTHOGONAL_ROTATE_HEADING_PITCH_ZONLY
				; Pitch = Rotation in (Z,Y) plane
				; Equivalent to reverse rotation in (Y,Z) plane

				LDB		1,Y			; Pitch
				NEGB
				TFR		D,X
				LDD		1,U			; (A,B)=(y,z)
				LBSR	ROT8_YONLY
				STD		1,U			; Write y,z

				LDX		-1,Y		; Heading (Force lower-8bit to be an angle)
				LDA		,U			; A=x
				LDB		2,U			; B=z
				LBSR	ROT8_YONLY
				STB		2,U
				RTS


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



					;	Repeat B times >>
					;	[0,Y]	+2	2-byte	Unused
					;	[2,Y]	+0	2-byte 	I Pointer to model data
					;	[4,Y]	+4	2-byte 	I Center x
					;	[6,Y]	+6	2-byte 	I Center y
					;	[8,Y]	+8	1-byte	I Heading angle
					;	[9,Y]	+9	1-byte	I Pitch angle
					;	[10,Y]	+10	1-byte 	I Bank angle
					;	[11,S]	+11	1-byte 	I Scaling
					;	Repeat B times <<

					;	X					Line-Data (PROJECTION_AREA+offset)


PROJECT_ORTHOGONAL_MULTI

					PSHS	B

					LDD		#0
					STD		,Y		; Tentative

PROJECT_ORTHOGONAL_MULTI_LOOP
					PSHS	X,Y
					LEAS	-8,S

					STX		,Y

					LDD		2,Y
					STD		2,S

					LDD		8,Y
					STD		4,S

					STX		,S

					LBSR	PROJECT_ORTHOGONAL

					LEAS	8,S

					PULS	X,Y

					LDA		#5		; 5-bytes per line
					MUL
					ADDD	#1

					LEAX	D,X

					LEAY	12,Y
					DEC		,S
					BNE		PROJECT_ORTHOGONAL_MULTI_LOOP

					PULS	B,PC



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;  Input
;    X   Projected-data pointer
;    U   Model information pointer
;    Y   Destination pointer
;    B   Model count
PROJECT_ORTHOGONAL_PUSH_TO_SUBCPU_SPACE

					PSHS	B
PROJECT_ORTHOGONAL_PUSH_TO_SUBCPU_SPACE_LOOP
					LDB		,X
					BEQ		PROJECT_ORTHOGONAL_PUSH_TO_SUBCPU_SPACE_LOOP_NEXT

					LDB		#LINE_CMD_SET_TRANS
					STB		,Y+
					LDD		10,U		; A=Rotation  B=Scaling
					STD		,Y++
					LDD		4,U			; DX
					STD		,Y++
					LDD		6,U			; DY
					STD		,Y++


					LDA		#LINE_CMD_2D_TRANS_CLIP
					STA		,Y+

					PSHS	U

					LDB		,X+
					STB		,Y+
PROJECT_ORTHOGONAL_PUSH_TO_SUBCPU_SPACE_TFR_LOOP
					LDA		,X+		; Color
					STA		,Y+
					LDU		,X++	; XY
					STU		,Y++
					LDU		,X++	; XY
					STU		,Y++
					DECB
					BNE		PROJECT_ORTHOGONAL_PUSH_TO_SUBCPU_SPACE_TFR_LOOP

					PULS	U


PROJECT_ORTHOGONAL_PUSH_TO_SUBCPU_SPACE_LOOP_NEXT
					LEAU	12,U

					DEC		,S
					BNE		PROJECT_ORTHOGONAL_PUSH_TO_SUBCPU_SPACE_LOOP

					PULS	B,PC
