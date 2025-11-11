					ORG		$2000

ENTRY				LDX		#$8000	; Copy from main:$4000
					LDU		#$C000	; Copy to sub:$C000
					LDD		#$800
					BSR		TO_SUB_CPU

					LDX		#$C000	; Copy from sub:$C000
					LDU		#$4000  ; Copy to main:$4000
					LDD		#$800
					BSR		FROM_SUB_CPU

					LDX		#$4000
					LDU		#$8000
					LDY		#$800
VERIFY				LDD		,X++
					CMPD	,U++
					BNE		VERIFY_ERROR
					LEAY	-2,Y
					BNE		VERIFY

					LDA		#4
					STA		$FD3F

					RTS

VERIFY_ERROR		LDA		#2
					STA		$FD3F
					RTS


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MAX_ONE_TIME_TFR	EQU		$6D

; Input D bytes left
;       Y Points to SUBCPU_TFR_SRC
; This function does:
;   D=min(MAX_ONE_TIME_TFR,D)
;   [SUBCPU_TFR_LEN]=D
TAKE_MIN_TFR_LEN
					; Transfer Length=min(bytes_left,MAX_ONE_TIME_TFR)
					CMPD	#MAX_ONE_TIME_TFR
					BLE		TAKE_MIN_TFR_LEN_RTS
					LDD		#MAX_ONE_TIME_TFR
TAKE_MIN_TFR_LEN_RTS
					STD		(SUBCPU_TFR_LEN-SUBCPU_TFR_SRC),Y
					RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; X From (in main RAM)
; U To (in sub RAM)
; D Length
TO_SUB_CPU
					LEAY	SUBCPU_TFR_SRC,PCR

					STU		(SUBCPU_TFR_DST-SUBCPU_TFR_SRC),Y	; U is free now.
					LDU		#$D393 ; main $FC93
					STU		(SUBCPU_TFR_SRC-SUBCPU_TFR_SRC),Y

TO_SUB_CPU_OUTER_LOOP
					PSHS	A,B

					; Transfer Length=min(bytes_left,$MAX_ONE_TIME_TFR)
					BSR		TAKE_MIN_TFR_LEN	; This updates D and [SUBCPU_TFR_LEN]

					BSR		HALT_SUBCPU
					BSR		SET_YAMAUCHI_COMMAND
					LDU		#$FC93
					; B is one-time transfer length. (From TAKE_MIN_TFR_LEN)
					; X is source.
					; U is destination.
					BSR		TFR_X_TO_U_FOR_B	; X,U incremented, A destroyed, B=0

					CLR		$FD05

					; X is incremented already.
					LDD		(SUBCPU_TFR_LEN-SUBCPU_TFR_SRC),Y
					ADDD	(SUBCPU_TFR_DST-SUBCPU_TFR_SRC),Y
					STD		(SUBCPU_TFR_DST-SUBCPU_TFR_SRC),Y
					; Destination address incremented.

					PULS	A,B

					; D is remeaining byte-count again.
					SUBD	(SUBCPU_TFR_LEN-SUBCPU_TFR_SRC),Y
					BGT		TO_SUB_CPU_OUTER_LOOP

					RTS


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; U To (in main RAM)
; X From (in sub RAM)
; D Length
FROM_SUB_CPU
					LEAY	SUBCPU_TFR_SRC,PCR

					STX		(SUBCPU_TFR_SRC-SUBCPU_TFR_SRC),Y	; X is free now.
					LDX		#$D393 ; main $FC93
					STX		(SUBCPU_TFR_DST-SUBCPU_TFR_SRC),Y

					PSHS	A,B
					BSR		HALT_SUBCPU	; Destroys A
					PULS	A,B

FROM_SUB_CPU_OUTER_LOOP
					PSHS	A,B

					; Transfer Length=min(bytes_left,$MAX_ONE_TIME_TFR)
					BSR		TAKE_MIN_TFR_LEN	; This updates D and [SUBCPU_TFR_LEN]

					BSR		SET_YAMAUCHI_COMMAND
					CLR		$FD05

					BSR		HALT_SUBCPU	; B register is preserved.

					LDX		#$FC93
					; B is one-time transfer length. (From TAKE_MIN_TFR_LEN)
					; X is source.
					; U is destination.
					BSR		TFR_X_TO_U_FOR_B	; X,U incremented, A destroyed, B=0

					; U is incremented already.
					LDD		(SUBCPU_TFR_LEN-SUBCPU_TFR_SRC),Y
					ADDD	(SUBCPU_TFR_SRC-SUBCPU_TFR_SRC),Y
					STD		(SUBCPU_TFR_SRC-SUBCPU_TFR_SRC),Y
					; Destination address incremented.

					PULS	A,B

					; D is remeaining byte-count again.
					SUBD	(SUBCPU_TFR_LEN-SUBCPU_TFR_SRC),Y
					BGT		FROM_SUB_CPU_OUTER_LOOP

					; Sub-CPU is HALT when come out of the loop.
					LDA		#$80
					STA		$FC80
					CLR		$FD05

					RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TFR_X_TO_U_FOR_B
					LDA		,X+
					STA		,U+
					DECB
					BNE		TFR_X_TO_U_FOR_B
					RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SET_YAMAUCHI_COMMAND
					PSHS	A,B,X,U
					LDU		#$FC80
					LEAX	SUBCPU_TFR_CMD,PCR
					LDB		#$13
					BSR		TFR_X_TO_U_FOR_B
					PULS	A,B,X,U,PC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Don't change B.  Above code assumes B does not change in this.
HALT_SUBCPU			LDA		$FD05
					BMI		HALT_SUBCPU
					LDA		#$80
					STA		$FD05
HALT_CHECK			LDA		$FD05
					BPL		HALT_CHECK
					RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

					; $FC80 +0  +1  +2 +3  +4  +5  +6  +7  +8  +9  +A  +B 
SUBCPU_TFR_CMD		FCB		$00,$00,$3F,'Y','A','M','A','U','C','H','I',$91
					;       +C  +D 
SUBCPU_TFR_SRC		FCB		$D3,$93
					;       +E  +F
SUBCPU_TFR_DST		FCB		$C0,$00
					;       +10 +11 +12
SUBCPU_TFR_LEN		FCB		$00,$6D,$90
