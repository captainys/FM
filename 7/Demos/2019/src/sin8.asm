;		Input
;				A Coefficient
;				B Angle
;		Output
;				A c*sin (SIN8) or c*cos (COS8)


COS8					NEGB
						ADDB	#64
						; Fall down to SIN8

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SIN8
						STA		,-S
						BPL		SIN8_A_TESTED
						NEGA
SIN8_A_TESTED

						TSTB
						BPL		SIN8_B_TESTED
						NEGB
						NEG		,S
SIN8_B_TESTED

						LEAX	SINTABLE,PCR
						ABX		; When B=#$80, B,X points to X-$80.  Need to use ABX.
						LDB		,X
						MUL

						LSLB
						ROLA

						TST		,S+
						BPL		SIN8_EXIT
						NEGA

SIN8_EXIT				RTS


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Input					A		x
;						B		y
;						X		Angle
; Output				A		x'
;						B		y'

ROT8
						PSHS	X,A,B
						;	3,S		Angle
						;	2,S		Temporary variable
						;	1,S		y, Temporary x'
						;	,S		x

						;	x'=c*x-s*y
						;	y'=s*x+c*y
						; A is x.
						LDB		3,S
						BEQ		ROT8_ZERO
						BSR		SIN8
						STA		2,S		; [2,S]=s*x

						LDA		1,S		; y
						LDB		3,S
						BSR		SIN8
						STA		,-S		; [,S]=s*y


						LDA		1+0,S	; x
						LDB		1+3,S
						BSR		COS8	; A=c*x
						SUBA	,S+		; A=c*x-s*y
						STA		,S

						LDA		1,S		; y
						LDB		3,S
						BSR		COS8
						ADDA	2,S		; B=[2,s]+c*y
						STA		1,S		; [2,S]=y'

ROT8_ZERO
						PULS	A,B,X,PC



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Input					A		x
;						B		y
;						X		Angle
; Output				A
;						B		y'
; It rotates (x,y) by X, but only returns y'.
ROT8_YONLY
						PSHS	X,A,B
						;	3,S		Angle
						;	2,S		Temporary variable
						;	1,S		y, Temporary x'
						;	,S		x

						;	y'=s*x+c*y
						; A is x.
						LDB		3,S
						BEQ		ROT8_ZERO
						BSR		SIN8
						STA		2,S		; [2,S]=s*x

						LDA		1,S		; y
						LDB		3,S
						BSR		COS8
						ADDA	2,S		; B=[2,s]+c*y
						STA		1,S		; [2,S]=y'

						PULS	A,B,X,PC


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


SINTABLE				FCB		$00,$03,$06,$09,$0c,$0f,$12,$15,$18,$1c,$1f,$22,$25,$28,$2b,$2e
						FCB		$30,$33,$36,$39,$3c,$3f,$41,$44,$47,$49,$4c,$4e,$51,$53,$55,$58
						FCB		$5a,$5c,$5e,$60,$62,$64,$66,$68,$6a,$6c,$6d,$6f,$70,$72,$73,$75
						FCB		$76,$77,$78,$79,$7a,$7b,$7c,$7c,$7d,$7e,$7e,$7f,$7f,$7f,$7f,$7f
						FCB		$80,$7f,$7f,$7f,$7f,$7f,$7e,$7e,$7d,$7c,$7c,$7b,$7a,$79,$78,$77
						FCB		$76,$75,$73,$72,$70,$6f,$6d,$6c,$6a,$68,$66,$64,$62,$60,$5e,$5c
						FCB		$5a,$58,$55,$53,$51,$4e,$4c,$49,$47,$44,$41,$3f,$3c,$39,$36,$33
						FCB		$30,$2e,$2b,$28,$25,$22,$1f,$1c,$18,$15,$12,$0f,$0c,$09,$06,$03
						FCB		$00


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


ROT8_RESTRICTED
						PSHS	X,A,B
						;	3,S		Angle
						;	2,S		Unused
						;	1,S		y
						;	,S		x

						;	y'=s*x+c*y
						; A is x.
						LDB		3,S
						ANDA	#3
						BEQ		ROT8_RESTRICTED_ZERO

						DECB
						BEQ		ROT8_RESTRICTED_90DEG

						DECB
						BEQ		ROT8_RESTRICTED_180DEG

						; 270 DEG
						LDA		1,S
						LDB		,S
						NEGB		; (y,-x)
						STD		,S
						BRA		ROT8_RESTRICTED_ZERO

ROT8_RESTRICTED_180DEG
						LDD		,S
						NEGA
						NEGB
						STD		,S
						BRA		ROT8_RESTRICTED_ZERO

ROT8_RESTRICTED_90DEG
						LDA		1,S
						LDB		,S
						NEGA		; (-y,x)
						STD		,S

ROT8_RESTRICTED_ZERO
						PULS	A,B,X,PC

