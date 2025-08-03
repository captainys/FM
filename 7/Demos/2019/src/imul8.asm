					EXPORT	MUL_SGN16_USGN8


; Input				A	Signed 8-bit
;					B	Unsigned 8-bit
; Output			D	A*B Signed

SGN_USGN_MUL8		STA		,-S
					BPL		SGN_USGN_MUL8_SIGNCHECKED
					NEGA
SGN_USGN_MUL8_SIGNCHECKED

					MUL

					TST		,S+
					BPL		SGN_USGN_MUL8_END

					COMA
					COMB
					ADDD	#1

SGN_USGN_MUL8_END	RTS


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Input				X	Signed 16-bit
;					A	Unsigned 8-bit
;
; Output			A	Highest 8-bit of X*A
;					B	Mid 8-bit of X*A
;					Higher 8-bit of X	Lowest 8-bit of X*A (Lower 8-bit of X is zero)

MUL_SGN16_USGN8
					LEAS	-5,S
					PSHS	X,A
					; [7,S]		Sign
					; [6,S]		#0
					; [5,S]		Lowest 8-bit
					; [4,S]		Mid 8-bit
					; [3,S]		Highest 8-bit
					; [2,S]		X low
					; [1,S]		X high
					; [,S]		A

					CLR		6,S

					LDD		1,S
					STA		7,S	; Save sign
					BPL		MUL_SGN16_USGN8_SIGN_SET

					COMA
					COMB
					ADDD	#1
					STD		1,S
MUL_SGN16_USGN8_SIGN_SET

					; A=xh, B=xl
					; (xh*256+xl)*a=a*xh*256+a*xl
					LDA		,S		; a
					; LDB		3,S		; xl <- Can skip this because B=xl when sign is set.
					MUL
					STD		4,S

					LDA		,S		; a
					LDB		1,S		; xh
					MUL

					ADDB	4,S
					ADCA	#0
					STD		3,S	

					TST		7,S
					BPL		MUL_SGN16_USGN8_SIGN_RECOVERED

					COM		3,S

					LDD		4,S
					COMA
					COMB
					ADDD	#1
					STD		4,S

					LDA		3,S
					ADCA	#0
					STA		3,S

MUL_SGN16_USGN8_SIGN_RECOVERED

					LDX		5,S
					LDD		3,S

					LEAS	8,S
					RTS


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Input				X	Signed 16-bit
;					A	Unsigned 8-bit
;
; Output			A	Highest 8-bit of (X*A)/128
;					B	Mid 8-bit of (X*A)/128
;					Higher 8-bit of X	Lowest 8-bit of X*A (Lower 8-bit of X is zero)
MUL_SGN16_USGN8_7LSR
					BSR		MUL_SGN16_USGN8

					LSLB
					RORA

					CMPX	#0
					BPL		MUL_SGN16_USGN8_7LSR_EXIT
					ORB		#1

MUL_SGN16_USGN8_7LSR_EXIT
					RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Input		A		Signed value
;				B		Signed value
;	Output		D=A*B	Signed
;



IMUL8				CLR		,-S
					TSTA
					BPL		IMUL8_A_TESTED
					INC		,S
					NEGA

IMUL8_A_TESTED		TSTB
					BPL		IMUL8_B_TESTED
					INC		,S
					NEGB

IMUL8_B_TESTED		MUL

					LSR		,S+
					BCC		IMUL8_EXIT

					COMA
					COMB
					ADDD	#1

IMUL8_EXIT			RTS
