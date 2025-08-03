


DEMO2019_SPIN_ORTHO
; >> Testing orthogonal projection
					LEAS	-16,S
					LEAY	,S

					LDD		#0
					STD		14,Y
					LDD		#0
					STD		2,Y
					LDD		#0
					STD		,Y


					CLRB
					CLRA
DEMO2019_SPIN_ORTHO_LOOP
					PSHS	A,B,Y

					LDD		,Y
					ADDA	#4
					ADDB	#3
					STD		,Y

					PSHS	A,B

					LEAX	DUCKY_WIREFRAME_DATA,PCR
					PSHS	X
					LEAX	PROJECTION_AREA,PCR
					PSHS	X
;					[7,S]	8bit	Pitch
;					[6,S]	8bit	Heading
;					[4,S]	16bit	Pointer to the model
;					[2,S]	16bit	Pointer to the command output
					LBSR	PROJECT_ORTHOGONAL

					LEAS	6,S


					LBSR	HALT_SUBCPU
					LBSR	MMR_ENABLE_ACCESS_SUBCPU_RAM


					LDY		#LINEDATA_BUF

					LDB		#LINE_CMD_HALF_CLS
					STB		,Y+
					LDA		1,S
					ANDA	#1
					LSLA
					LSLA
					LSLA
					LSLA
					LSLA
					CLRB
					STD		,Y++

					LDB		#LINE_CMD_SET_OFFSET	; VRAM offset for HW LINE
					STB		,Y+
					CLRB
					STD		,Y++


					LDB		#LINE_CMD_SET_TRANS
					STB		,Y+
					LDD		#$0032		; A=Rotation  B=Scaling
					STD		,Y++
					LDD		#$00A0		; DX
					STD		,Y++
					LDD		#$0064		; DY
					STD		,Y++


					LDA		#LINE_CMD_2D_TRANS_CLIP
					STA		,Y+

					LEAX	PROJECTION_AREA,PCR
					LDB		,X+
					STB		,Y+
DEMO2019_SPIN_ORTHO_TFR_LOOP
					LDA		,X+
					STA		,Y+
					LDU		,X++
					STU		,Y++
					LDU		,X++
					STU		,Y++
					DECB
					BNE		DEMO2019_SPIN_ORTHO_TFR_LOOP

					LDA		#LINE_CMD_2D_END_OF_CMDSET
					STA		,Y+


					LBSR	MMR_DISABLE
					LBSR	RELEASE_SUBCPU

					PULS	A,B,Y
					DECB
					BNE		DEMO2019_SPIN_ORTHO_LOOP



					LEAS	16,S
					RTS
