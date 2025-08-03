				EXPORT	RENDER_HORIZON

			; Input
			;	Y		Pointer where Sub-CPU commands need to be stored.
			;	A		View Pitch
			;	B		View Bank
			;	X		View Z (0-127)
			;	U		View Y (0-127)

			; Output
			;	Y		Pointer where next Sub-CPU commands need to be stored.



RENDER_HORIZON
			LEAS	-2,S
			PSHS	U,X,B,A

			;	[7,S]	Line Z
			;	[6,S]	Line Counter

			;	[5,S]	VY Low
			;	[4,S]	VY High
			;	[3,S]	VZ Low
			;	[2,S]	VZ High
			;	[1,S]	Bank
			;	[,S]	Pitch

			LDA		#LINE_CMD_SET_TRANS
			STA		,Y+
			LDA		1,S
			NEGA
			STA		,Y+		; Bank
			LDA		#255
			STA		,Y+		; Scaling 128=2X

			LDA		,S
			BSR		HORIZON_GET_CENTER
			STX		,Y++
			SEX
			STD		,Y++


; LINE_CMD_SET_TRANS			EQU		11	; Followed by 1-byte Rotation, 1-byte unsigned Scaling (x128), 2-byte X, and 2-byte Y

			LDA		#LINE_CMD_2D_TRANS_CLIP_16
			STA		,Y+

			LDA		#8
			STA		,Y+
			STA		6,S

			LDA		3,S
			NEGA
			ANDA	#31
			STA		7,S

			LEAU	DIVTABLE,PCR

RENDER_HORIZON_LOOP
			LDA		6,S
			DECA
			ANDA	#3
			ADDA	#4
			STA		,Y+		; Color


			LDB		7,S
			CLRA
			LDB		D,U
			LDA		5,S
			MUL
			TFR		A,B
			LDA		#$FF
			NEGB

			LDX		#-192
			STX		,Y++
			STD		,Y++

			LDX		#192
			STX		,Y++
			STD		,Y++

			LDA		7,S
			SUBA	#4
			ANDA	#31
			STA		7,S

			DEC		6,S
			BNE		RENDER_HORIZON_LOOP


			PULS	A,B,X,U
			LEAS	2,S
			RTS


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


			; Input		
			;	A		Pitch
			;	B		Bank
			; Output
			;	X		cx
			;	B		cy
HORIZON_GET_CENTER
			NEGA
			NEGB
			PSHS	B,A

			; Calculate center
			LDA		#127	; Ad-hoc: 90deg=127pixels
			LDB		,S
			LBSR	SIN8
			STA		,S

			;	[,S]=127*sin(p)
			LDB		1,S
			LBSR	COS8

			LDB		1,S
			ADDA	#100
			STA		1,S

			LDA		,S
			LBSR	SIN8
			TFR		A,B
			SEX
			ADDD	#160
			TFR		D,X

			PULS	A,B,PC
