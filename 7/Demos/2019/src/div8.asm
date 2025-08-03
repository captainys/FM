;	UDIV8_8
;		Input		A	Numerator
;					B	Denominator
;		Output		X	A/B   ($FFFF if division by zero)
;					A   Destroyed
;
;
UDIV8_8					PSHS	B

						LDB		#1
						TST		,S
						BMI		UDIV8_8_UPSHIFT_DONE
						BEQ		UDIV8_8_DIVISION_BY_ZERO


UDIV8_8_UPSHIFT_LOOP	LSLB
						LSL		,S
						BPL		UDIV8_8_UPSHIFT_LOOP
UDIV8_8_UPSHIFT_DONE


						LDX		#0
UDIV8_8_LOOP			CMPA	,S
						BCS		UDIV8_8_NEXT

						ABX
						SUBA	,S

UDIV8_8_NEXT			LSR		,S
						LSRB
						BCC		UDIV8_8_LOOP

						PULS	B,PC


UDIV8_8_DIVISION_BY_ZERO
						LDX		#$FFFF
						PULS	B,PC
