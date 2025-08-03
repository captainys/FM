;				Input	D	Numerator
;						X	Denominator
;				Output	D	X/A


UDIV16_DENOM			EQU		0

UDIV16					STX		,--S
						BEQ		UDIV16_BY_ZERO
						; ,S		Denominator

						LDX		#1
						STX		UDIV16_SHIFT,PCR

						TST		UDIV16_DENOM,S
						BMI		UDIV16_UPSHIFT_DONE

UDIV16_UPSHIFT			LSL		UDIV16_SHIFT+1,PCR
						ROL		UDIV16_SHIFT  ,PCR
						LSL		UDIV16_DENOM+1,S
						ROL		UDIV16_DENOM  ,S
						BPL		UDIV16_UPSHIFT
UDIV16_UPSHIFT_DONE


						LDX		#0
UDIV16_DOWNSHIFT		CMPD	UDIV16_DENOM,S
						BCS		UDIV16_DOWNSHIFT_NO_ADDITION

UDIV16_LEAX				LEAX	$1234,X
UDIV16_SHIFT			EQU		UDIV16_LEAX+2
						SUBD	UDIV16_DENOM,S

UDIV16_DOWNSHIFT_NO_ADDITION
						LSR		UDIV16_DENOM  ,S
						ROR		UDIV16_DENOM+1,S
						LSR		UDIV16_SHIFT  ,PCR
						ROR		UDIV16_SHIFT+1,PCR
						BCC		UDIV16_DOWNSHIFT

						STX		,S
						PULS	A,B,PC

UDIV16_BY_ZERO			LDD		#$FFFF
						PULS	X,PC


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;				Input	D	Numerator (Signed)
;						X	Denominator (Unsigned)
;				Output	X	D/X

HDIV16					CLR		,-S

						TSTA
						BPL		HDIV16_NUR_SIGN_SET
						INC		,S
						COMA
						COMB
						ADDD	#1

HDIV16_NUR_SIGN_SET		BSR		UDIV16
						BRA		IDIV16_SIGN_ADJUST



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;				Input	D	Numerator
;						X	Denominator
;				Output	X	D/X


IDIV16					CLR		,-S

						TSTA
						BPL		IDIV16_NUMER_SIGN_SET
						INC		,S
						COMA
						COMB
						ADDD	#1
IDIV16_NUMER_SIGN_SET

						EXG		D,X

						TSTA
						BPL		IDIV16_DENOM_SIGN_SET
						INC		,S
						COMA
						COMB
						ADDD	#1
IDIV16_DENOM_SIGN_SET

						EXG		D,X

						BSR		UDIV16

IDIV16_SIGN_ADJUST		LSR		,S+
						BCC		IDIV16_EXIT

						COMA
						COMB
						ADDD	#1

IDIV16_EXIT				RTS
