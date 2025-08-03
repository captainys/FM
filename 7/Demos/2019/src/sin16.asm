;		Input
;				X Coefficient
;				B Angle
;		Output
;				D c*sin (SIN16) or c*cos (COS16)


COS16					NEGB
						ADDB	#64
						; Fall down to SIN16

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SIN16					PSHS	X,B

						TSTB
						BPL		SIN16_ANGLE_TESTED
						NEGB
SIN16_ANGLE_TESTED

						LEAX	SINTABLE,PCR
						ABX		; Cannot avoid this.  If B=$80, LDA B,X will give LDA -128,X.
						LDA		,X
						LDX		1,S
						LBSR	MUL_SGN16_USGN8

						; D						Higher 16-bits
						; Higher 8-bit of X 	Lower 8-bits

						LSLB
						ROLA
						CMPX	#0
						BPL		SIN16_SHIFTED
						ORB		#1
SIN16_SHIFTED

						TST		,S+
						BPL		SIN16_EXIT
						COMA
						COMB
						ADDD	#1

SIN16_EXIT				PULS	X,PC



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; Input					X		x
;						Y		y
;						B		Angle
; Output				X		x'
;						Y		y'

ROT16
						PSHS	Y,X,B
						;	[3,S]		y
						;	[1,S]		x
						;	[,S]		Angle

						;	y'=s*x+c*y
						; A is x.
						TSTB
						BEQ		ROT16_ZERO
						LDX		3,S
						STX		,--S

						;	[5,S]		y
						;	[3,S]		x
						;	[2,S]		Angle
						;	[,S]		y

						BSR		COS16
						STD		5,S

						;	[5,S]		c*y
						;	[3,S]		x
						;	[2,S]		Angle
						;	[,S]		y

						LDX		3,S
						LDB		2,S
						BSR		SIN16
						ADDD	5,S
						STD		5,S

						;	[5,S]		y'
						;	[3,S]		x
						;	[2,S]		Angle
						;	[,S]		y

						;	x'=c*x-s*y
						LDX		,S
						LDB		2,S
						BSR		SIN16
						STD		,S

						;	[5,S]		y'
						;	[3,S]		x
						;	[2,S]		Angle
						;	[,S]		s*y

						LDX		3,S
						LDB		2,S
						BSR		COS16
						SUBD	,S++
						STD		1,S

						;	[3,S]		y'
						;	[1,S]		x'
						;	[,S]		Angle

ROT16_ZERO
						PULS	X,Y,B,PC


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


