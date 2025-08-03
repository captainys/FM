

DEMO2019_2D_TRANS
						CLR		,-S
						CLR		,-S
						CLR		,-S
						LDX		#100
						PSHS	X
						LDX		#0
						PSHS	X

						; [6,S] Overall counter
						; [5,S] Scaling
						; [4,S] Rotation
						; [2,S]	ty
						; [,S]	tx



DEMO2019_2D_TRANS_OUTER_LOOP
						LBSR	HALT_SUBCPU
						LBSR	MMR_ENABLE_ACCESS_SUBCPU_RAM

						LDY		#LINEDATA_BUF

						LDA		6,S

						ANDA	#1
						LSLA
						LSLA
						LSLA
						LSLA
						LSLA


						LDB		#LINE_CMD_HALF_CLS
						STB		,Y+
						CLRB
						STD		,Y++

						LDB		#LINE_CMD_SET_OFFSET
						STB		,Y+
						CLRB
						STD		,Y++


						LDB		#LINE_CMD_SET_TRANS
						STB		,Y+

						LDD		4,S	; A=Rotation  B=Scaling
						ADDA	#8
						ADDB	#8
						STD		4,S
						STD		,Y++

						LDD		,S	; TransX
						ADDD	#1
						STD		,S
						STD		,Y++

						LDD		2,S
						STD		,Y++


						LDA		#LINE_CMD_2D_TRANS_CLIP
						STA		,Y+

						LDA		#4	; 4 lines
						STA		,Y+

						LDA		#4
						STA		,Y+
						LDD		#$2020	; ( 32, 32)
						STD		,Y++
						LDD		#$E020	; (-32, 32)
						STD		,Y++

						LDA		#6
						STA		,Y+
						LDD		#$E020	; (-32, 32)
						STD		,Y++
						LDD		#$E0E0	; (-32,-32)
						STD		,Y++

						LDA		#7
						STA		,Y+
						LDD		#$E0E0	; (-32,-32)
						STD		,Y++
						LDD		#$20E0	; ( 32,-32)
						STD		,Y++

						LDA		#5
						STA		,Y+
						LDD		#$20E0	; ( 32,-32)
						STD		,Y++
						LDD		#$2020	; ( 32, 32)
						STD		,Y++


						LDA		#LINE_CMD_2D_END_OF_CMDSET
						STA		,Y+


						LBSR	MMR_DISABLE
						LBSR	RELEASE_SUBCPU


						DEC		6,S
						LBNE		DEMO2019_2D_TRANS_OUTER_LOOP

						LEAS	7,S
						RTS
