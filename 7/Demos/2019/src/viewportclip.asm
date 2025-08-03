;	Input/Output
;		[,Y]		X
;		[2,Y}		Y
;		[4,Y]		X
;		[6,Y]		Y
;	Viewport size (0,0)-(320,200) fix
;	Visible     -> C=0
;	Not visible -> C=1

VIEWPORT_CLIP_XMIN		EQU		0
VIEWPORT_CLIP_XMAX		EQU		319
VIEWPORT_CLIP_YMIN		EQU		0
VIEWPORT_CLIP_YMAX		EQU		199

VIEWPORT_CLIP			BSR		VIEWPORT_CLIP_X
						BCS		VIEWPORT_CLIP_EXIT
						BSR		VIEWPORT_CLIP_Y
VIEWPORT_CLIP_EXIT		RTS



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



VIEWPORT_CLIP_X
						LDD		,Y
						CMPD	4,Y
						BLE		VIEWPORT_CLIP_NO_XSWAP
						LBSR	VIEWPORT_CLIP_SWAP
VIEWPORT_CLIP_NO_XSWAP

						LDD		4,Y
						CMPD	#VIEWPORT_CLIP_XMIN
						BLT		VIEWPORT_CLIP_END_INVISIBLE

						LDD		,Y
						CMPD	#VIEWPORT_CLIP_XMAX
						BGT		VIEWPORT_CLIP_END_INVISIBLE



						; X=0
						CMPD	#VIEWPORT_CLIP_XMIN
						BGE		VIEWPORT_CLIP_NOT_XMIN

						; Y'=(Xmin-X0)*(Y1-Y0)/(X1-X0)+Y0
						LDD		#VIEWPORT_CLIP_XMIN
						SUBD	,Y
						STD		,--S

						LDD		6,Y
						SUBD	2,Y
						STD		,--S

						LDD		4,Y
						SUBD	,Y
						STD		,--S

						PSHS	Y
						LEAY	2,S
						LBSR	VIEWPORT_CLIP_MULDIV
						PULS	Y
						LEAS	6,S

						BCS		VIEWPORT_CLIP_END_INVISIBLE

						ADDD	2,Y
						STD		2,Y
						LDD		#VIEWPORT_CLIP_XMIN
						STD		,Y
VIEWPORT_CLIP_NOT_XMIN


						LDD		4,Y
						CMPD	#VIEWPORT_CLIP_XMAX
						BLE		VIEWPORT_CLIP_NOT_XMAX

						; Y'=(Xmax-X1)*(Y1-Y0)/(X1-X0)+Y1
						LDD		#VIEWPORT_CLIP_XMAX
						SUBD	4,Y
						STD		,--S

						LDD		6,Y
						SUBD	2,Y
						STD		,--S

						LDD		4,Y
						SUBD	,Y
						STD		,--S

						PSHS	Y
						LEAY	2,S
						LBSR	VIEWPORT_CLIP_MULDIV
						PULS	Y
						LEAS	6,S

						BCS		VIEWPORT_CLIP_END_INVISIBLE

						ADDD	6,Y
						STD		6,Y
						LDD		#VIEWPORT_CLIP_XMAX
						STD		4,Y
VIEWPORT_CLIP_NOT_XMAX


VIEWPORT_CLIP_END_VISIBLE
						CLRA
						RTS

VIEWPORT_CLIP_END_INVISIBLE
						COMA
						RTS



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



VIEWPORT_CLIP_Y
						LDD		2,Y
						CMPD	6,Y
						BLE		VIEWPORT_CLIP_NO_YSWAP
						BSR		VIEWPORT_CLIP_SWAP
VIEWPORT_CLIP_NO_YSWAP

						LDD		6,Y
						CMPD	#VIEWPORT_CLIP_YMIN
						BLT		VIEWPORT_CLIP_END_INVISIBLE

						LDD		2,Y
						CMPD	#VIEWPORT_CLIP_YMAX
						BGT		VIEWPORT_CLIP_END_INVISIBLE



						; Y=0
						CMPD	#VIEWPORT_CLIP_YMIN
						BGE		VIEWPORT_CLIP_NOT_YMIN

						; X'=(Ymin-Y0)*(X1-X0)/(Y1-Y0)+X0
						LDD		#VIEWPORT_CLIP_YMIN
						SUBD	2,Y
						STD		,--S

						LDD		4,Y
						SUBD	,Y
						STD		,--S

						LDD		6,Y
						SUBD	2,Y
						STD		,--S

						PSHS	Y
						LEAY	2,S
						BSR		VIEWPORT_CLIP_MULDIV
						PULS	Y
						LEAS	6,S

						BCS		VIEWPORT_CLIP_END_INVISIBLE

						ADDD	,Y
						STD		,Y
						LDD		#VIEWPORT_CLIP_YMIN
						STD		2,Y
VIEWPORT_CLIP_NOT_YMIN


						LDD		6,Y
						CMPD	#VIEWPORT_CLIP_YMAX
						BLE		VIEWPORT_CLIP_NOT_YMAX

						; X'=(Ymax-Y1)*(X1-X0)/(Y1-Y0)+X1
						LDD		#VIEWPORT_CLIP_YMAX
						SUBD	6,Y
						STD		,--S

						LDD		4,Y
						SUBD	,Y
						STD		,--S

						LDD		6,Y
						SUBD	2,Y
						STD		,--S

						PSHS	Y
						LEAY	2,S
						BSR		VIEWPORT_CLIP_MULDIV
						PULS	Y
						LEAS	6,S

						BCS		VIEWPORT_CLIP_END_INVISIBLE

						ADDD	4,Y
						STD		4,Y
						LDD		#VIEWPORT_CLIP_YMAX
						STD		6,Y
VIEWPORT_CLIP_NOT_YMAX


VIEWPORT_CLIP_Y_END_VISIBLE
						CLRA
						RTS



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



VIEWPORT_CLIP_SWAP		LDX		,Y
						LDU		4,Y
						STU		,Y
						STX		4,Y

						LDX		2,Y
						LDU		6,Y
						STU		2,Y
						STX		6,Y
						RTS



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;				[,Y]		(x1-x0)
;				[2,Y]		(y1-y0)
;				[4,Y]		(x-x0)
; 		Return [4,Y]*[2,Y]/[,Y]

VIEWPORT_CLIP_MULDIV
						CLR		,-S

						LDD		,Y
						BPL		VIEWPORT_CLIP_MULDIV_SIGNADJ1
						INC		,S
						COMA
						COMB
						ADDD	#1
						STD		,Y
VIEWPORT_CLIP_MULDIV_SIGNADJ1

						LDD		2,Y
						BPL		VIEWPORT_CLIP_MULDIV_SIGNADJ2
						INC		,S
						COMA
						COMB
						ADDD	#1
						STD		2,Y
VIEWPORT_CLIP_MULDIV_SIGNADJ2

						LDD		4,Y
						BPL		VIEWPORT_CLIP_MULDIV_SIGNADJ3
						INC		,S
						COMA
						COMB
						ADDD	#1
						STD		4,Y
VIEWPORT_CLIP_MULDIV_SIGNADJ3


						LEAY	2,Y
						LBSR	UMUL16
						LEAY	-2,Y


						LDD		4,Y
						LDX		,Y
						BEQ		VIEWPORT_CLIP_MULDIV_OVERFLOW_END
						LBSR	UDIV16


						LSR		,S+
						BCC		VIEWPORT_CLIP_MULDIV_END

						COMA
						COMB
						ADDD	#1

VIEWPORT_CLIP_MULDIV_END
						ANDCC	#$FE
						RTS

VIEWPORT_CLIP_MULDIV_OVERFLOW_END
						CLR		,S+
						ORCC	#1
						RTS



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

