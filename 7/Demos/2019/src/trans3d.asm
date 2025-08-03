;  Left-hand coordinate.  Z-plus is forward.

;	Input     (6 bytes in stack)
;				[12,S]	16bit	DZ
;				[10,S]	16bit	DY
;				[8,S]	16bit	DX
;				[7,S]	8bit	Pitch
;				[6,S]	8bit	Heading
;				[4,S]	16bit	Pointer to the model
;				[2,S]	16bit	Pointer to the command output
;				[,S]	16bit	PC
;	Output
;				B				Number of visible lines
;				[[2,S]]...		1-byte # visible lines
;								CXYZXYZCXZYXYZ....  C:1 byte   X,Y,Z:2 bytes each
;
;   Local Variables
;				[-6,Y]			3 or 6 bytes Temporary x,y,z
;				[-9,Y]			3 bytes Temporary nx,ny,nz
;				[-10,Y]			Unused
;				[-11,Y]			Number of visible lines
;				[-13,Y]			Pointer to the rotation function.
;				[COORD_AREA]		XYXYXYXY....  All 1 byte  -> Orthogonal projection doesn't care Z



TRANSFORM_3D
						LEAY	,S
						LEAS	-13,S

						LEAU	PROJECT_ORTHOGONAL_ROTATE_HEADING_PITCH,PCR
						STU		-13,Y

						; Also called from TRANSFORM_3D_RESTRICTED
TRANSFORM_3D_MAIN
						LDU		4,Y
						LDB		,U+
						LBEQ	TRANSFORM_3D_NO_VISIBLE_LINE

						LEAX	COORD_AREA,PCR
TRANSFORM_3D_VERTEX_LOOP
						PSHS	B

						LDD		,U++		; x,y
						STD		-3,Y
						LDA		,U+			; z
						STA		-1,Y

						PSHS	X,Y,U
						LDX		-13,Y
						LEAU	-3,Y
						LEAY	6,Y
						JSR		,X
						PULS	X,Y,U

						LDB		-3,Y
						SEX
						ADDD	8,Y
						STD		,X++

						LDB		-2,Y
						SEX
						ADDD	10,Y
						STD		,X++

						LDB		-1,Y
						SEX
						ADDD	12,Y
						STD		,X++

						STD		,X++		; Make it 8-byte per vtx

						PULS	B
						DECB
						BNE		TRANSFORM_3D_VERTEX_LOOP



						; Also called from TRANSFORM_3D_RESTRICTED
TRANSFORM_3D_ADD_LINE_TO_BUFFER
						; Vertices are [COORD_AREA+vtIdx*8]



						LDX		2,Y

						CLR		,X+			; Tentative
						CLR		-11,Y

						LDB		,U+			; # of lines in the model
						STB		,-S
TRANSFORM_3D_LINE_LOOP
						; Take one point of the line
						LDB		1,U			; vtIdx0
						CLRA
						LSLB
						ROLA
						LSLB
						ROLA
						LSLB
						ROLA
						PSHS	X
						LEAX	COORD_AREA,PCR
						LEAX	D,X
						LDD		,X++
						STD		-6,Y
						LDD		,X++
						STD		-4,Y
						LDD		,X++
						STD		-2,Y
						LEAX	-6,Y
						LBSR	TRANSFORM_3D_LINE_SCALE_TO_8BIT   		; x,y,z = [-5,Y],[-3,Y],[-1,Y]
						PULS	X

						LDA		-1,Y
						PSHS	A
						LDA		-3,Y
						PSHS	A
						LDA		-5,Y
						PSHS	A

						LDA		5,U	; Z
						PSHS	A
						LDA		4,U	; Y
						PSHS	A
						LDA		3,U	; X
						PSHS	A

						PSHS	X,Y,U
						LDX		-13,Y
						LEAU	6,S
						LEAY	6,Y
						JSR		,X
						PULS	X,Y,U

						LBSR	DOT8_3D
						CMPD	#0
						BGT		TRANSFORM_3D_NOM1_INVIS
						LEAS	6,S
						BRA		TRANSFORM_3D_LINE_IS_VISIBLE


TRANSFORM_3D_NOM1_INVIS
						LDD		6,U	; XY
						STD		,S
						LDA		8,U	; Z
						STA		2,S

						PSHS	X,Y,U
						LDX		-13,Y
						LEAU	6,S
						LEAY	6,Y
						JSR		,X
						PULS	X,Y,U

						LBSR	DOT8_3D
						LEAS	6,S
						CMPD	#0
						BGT		TRANSFORM_3D_NEXT_LINE


TRANSFORM_3D_LINE_IS_VISIBLE
						INC		-11,Y
						LDB		,U			; Color
						STB		,X+

						PSHS	Y

						LDB		1,U			; vtIdx0
						CLRA
						LSLB
						ROLA
						LSLB
						ROLA
						LSLB
						ROLA
						LEAY	COORD_AREA,PCR
						LEAY	D,Y
						LDD		,Y++
						STD		,X++
						LDD		,Y++
						STD		,X++
						LDD		,Y++
						STD		,X++

						LDB		2,U			; vtIdx1
						CLRA
						LSLB
						ROLA
						LSLB
						ROLA
						LSLB
						ROLA
						LEAY	COORD_AREA,PCR
						LEAY	D,Y
						LDD		,Y++
						STD		,X++
						LDD		,Y++
						STD		,X++
						LDD		,Y++
						STD		,X++

						PULS	Y


TRANSFORM_3D_NEXT_LINE
						LEAU	9,U
						DEC		,S
						LBNE	TRANSFORM_3D_LINE_LOOP
						TST		,S+


						LDB		-11,Y
						LDY		2,Y
						STB		,Y

						LEAS	13,S

						RTS


TRANSFORM_3D_NO_VISIBLE_LINE
						LEAS	13,S
						LDU		2,S
						CLR		,U
						RTS


; Word [,X]		X
; Word [2,X]	Y
; Word [3,X]	Z
TRANSFORM_3D_LINE_SCALE_TO_8BIT
						BRA		TRANSFORM_3D_LINE_SCALE_TO_8BIT_DOWNSHIFT_LOOP_IN

TRANSFORM_3D_LINE_SCALE_TO_8BIT_DOWNSHIFT_LOOP
						ASR		,X
						ROR		1,X
						ASR		2,X
						ROR		3,X
						ASR		4,X
						ROR		5,X

TRANSFORM_3D_LINE_SCALE_TO_8BIT_DOWNSHIFT_LOOP_IN
						LDD		,X
						CMPD	#127
						BGE		TRANSFORM_3D_LINE_SCALE_TO_8BIT_DOWNSHIFT_LOOP
						CMPD	#-127
						BLE		TRANSFORM_3D_LINE_SCALE_TO_8BIT_DOWNSHIFT_LOOP

						LDD		2,X
						CMPD	#127
						BGE		TRANSFORM_3D_LINE_SCALE_TO_8BIT_DOWNSHIFT_LOOP
						CMPD	#-127
						BLE		TRANSFORM_3D_LINE_SCALE_TO_8BIT_DOWNSHIFT_LOOP

						LDD		4,X
						CMPD	#127
						BGE		TRANSFORM_3D_LINE_SCALE_TO_8BIT_DOWNSHIFT_LOOP
						CMPD	#-127
						BLE		TRANSFORM_3D_LINE_SCALE_TO_8BIT_DOWNSHIFT_LOOP

						RTS



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Input     (6 bytes in stack)
;				[12,S]	16bit	DZ
;				[10,S]	16bit	DY
;				[8,S]	16bit	DX
;				[7,S]	8bit	Pitch: Only lowest 2 bits.  0, 1, 2, or 3
;				[6,S]	8bit	Heading: Only lowest 2 bits.  0, 1, 2, or 3
;				[4,S]	16bit	Pointer to the model
;				[2,S]	16bit	Pointer to the command output
;				[,S]	16bit	PC
;	Output
;				B				Number of visible lines
;				[[2,S]]...		1-byte # visible lines
;								CXYZXYZCXZYXYZ....  C:1 byte   X,Y,Z:2 bytes each
;
;   Local Variables
;				[-6,Y]			3 or 6 bytes Temporary x,y,z
;				[-9,Y]			3 bytes Temporary nx,ny,nz
;				[-10,Y]			Unused
;				[-11,Y]			Number of visible lines
;				[-13,Y]			Pointer to the transformation function
;
;				[COORD_AREA]		XYXYXYXY....  All 1 byte  -> Orthogonal projection doesn't care Z

TRANSFORM_3D_RESTRICTED
						LEAY	,S
						LEAS	-13,S

						LEAU	TRANSFORM_3D_ROTATE_HEADING_PITCH_RESTRICTED,PCR
						STU		-13,Y

						LBRA	TRANSFORM_3D_MAIN



TRANSFORM_3D_ROTATE_HEADING_PITCH_RESTRICTED
						LDB		1,Y			; Pitch
						LDA		2,U			; A=z
						LDB		1,U			; B=y
						LBSR	ROT8_RESTRICTED
						STA		2,U			; Write z
						STB		1,U			; Write y

						LDB		,Y			; Heading
						TFR		D,X
						LDA		,U			; A=x
						LDB		2,U			; B=z
						LBSR	ROT8_RESTRICTED
						STA		,U
						STB		2,U
						RTS
