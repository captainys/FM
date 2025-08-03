HALT_SUBCPU					LDA		$FD05
							BMI		HALT_SUBCPU

							LDA		#$80
							STA		$FD05

HALT_SUBCPU_WAIT			LDA		$FD05
							BPL		HALT_SUBCPU_WAIT
							RTS



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


RELEASE_SUBCPU				CLR		$FD05
							RTS


; Original code was waiting for the sub-cpu to be busy again.
; What if no command is given?  Sub-cpu will stay ready.
; If IRQ is thrown after CLR $FD05, sub-cpu probably lower busy flag by LDA $FD05.
; Then the sub-cpu will never be busy again. RELEASE_SUBCPU_WAIT may wait infinity.
;RELEASE_SUBCPU				CLR		$FD05
;RELEASE_SUBCPU_WAIT			LDA		$FD05
;							BPL		RELEASE_SUBCPU_WAIT
;							RTS



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



CALL_SUBCPU_C000			BSR		HALT_SUBCPU

							LEAX	SUBCPU_CALL_C000_CMD,PCR
							LDU		#$FC82
							LDB		#SUBCPU_CALL_C000_CMD_END-SUBCPU_CALL_C000_CMD

CALL_SUBCPU_C000_TFR_LOOP	LDA		,X+
							STA		,U+
							DECB
							BNE		CALL_SUBCPU_C000_TFR_LOOP

							BSR		RELEASE_SUBCPU

							RTS


SUBCPU_CALL_C000_CMD		FCB		$3F
							FCB		"YAMAUCHI"
							FCB		$93
							FDB		$C000
							FCB		$90
SUBCPU_CALL_C000_CMD_END



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



