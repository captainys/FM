;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;		Input	[,S]		PC
;				[2,S]		X
;				[3,S]		Y
;				[4,S]		Z
;				[5,S]		X
;				[6,S]		Y
;				[7,S]		Z


DOT8_3D
				LDA		2,S
				LDB		5,S
				LBSR	IMUL8
				STD		,--S

				LDA		5,S
				LDB		8,S
				LBSR	IMUL8
				ADDD	,S
				STD		,S

				LDA		6,S
				LDB		9,S
				LBSR	IMUL8
				ADDD	,S

				LEAS	2,S
				RTS

