				; Input
				; X		x (Signed.  8-bit)
				; Y		y (Signed.  8-bit)
				; B		z (Unsigned. 8-bit)

				; Output
				; X		256*x/z
				; Y		256*x/z
				; A,B	destroyed

				; Magnification fixed at 256
				; Center fixed at (160,100)

PROJECT_PERSPECTIVE_ONE_COORD
				PSHS	Y,X,B,A

				;	[5,S]	Y Low
				;	[4,S]	Y High
				;	[3,S]	X Low
				;	[2,S]	X High
				;	[1,S]	Z

				LEAX	DIVTABLE,PCR
				CLRA
				LDB		D,X
				STB		,S
				;	[,S]	256*(1/Z)

				; B=256*(1/Z)
				LDA		3,S
				LBSR	SGN_USGN_MUL8
				TFR		A,B
				SEX
				ADDD	#160
				STD		2,S

				LDA		5,S
				LDB		,S
				LBSR	SGN_USGN_MUL8
				TFR		A,B
				NEGB
				SEX
				ADDD	#101
				STD		4,S

				PULS	A,B,X,Y,PC


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; This projection does not invert Y and does not translate for the screen center.


PROJECT_PERSPECTIVE_ONE_COORD_SCALING_ONLY
				PSHS	Y,X,B,A

				;	[5,S]	Y Low
				;	[4,S]	Y High
				;	[3,S]	X Low
				;	[2,S]	X High
				;	[1,S]	Z

				LEAX	DIVTABLE,PCR
				CLRA
				LDB		D,X
				STB		,S
				;	[,S]	256*(1/Z)

				; B=256*(1/Z)
				LDA		3,S
				LBSR	SGN_USGN_MUL8
				TFR		A,B
				SEX
				STD		2,S

				LDA		5,S
				LDB		,S
				LBSR	SGN_USGN_MUL8
				TFR		A,B
				SEX
				STD		4,S

				PULS	A,B,X,Y,PC
