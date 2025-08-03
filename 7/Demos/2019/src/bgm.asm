						EXPORT		BGM_PTR_HIGH
						EXPORT		CLOCK_COUNTER_HIGH
						EXPORT		TIMER_IRQ_HANDLER
						EXPORT		PLAYBACK_BGM_PSGLASTCMD



CLOCK_COUNTER_HIGH		FDB		0
CLOCK_COUNTER_LOW		FDB		0
CLOCK_COUNTER_LOCAL		FDB		0
TIMER_IRQ_HANDLER_SAVE	FDB		0



PSGLASTCMD 				EQU		$FF ;
PSGSTEPDIVIDER			EQU		$FE ;
PSGNOCHANGE				EQU		$FD ;	// Followed by one-byte counter (2ms)
PSGBEGINLOOP_INFINITE	EQU		$FC ;
PSGBEGINLOOP_FINITE		EQU		$FB ;
PSGENDLOOP				EQU		$FA ;
PSGLONGNOCHANGE			EQU		$F9 ; // Followed by two-byte counter (2ms)

OPN3CHPLAY				EQU		$EA ;   // Followed by upper-byte and lower-byte tone.  Stop-Note-Play
OPN2CHPLAY				EQU		$E9 ;   // Followed by upper-byte and lower-byte tone.  Stop-Note-Play
OPN1CHPLAY				EQU		$E8 ;   // Followed by upper-byte and lower-byte tone.  Stop-Note-Play

OPN3CHTONE				EQU		$E6 ;	// Followed by upper-byte and lower-byte tone.  Set tone only.
OPN2CHTONE				EQU		$E5 ;	// Followed by upper-byte and lower-byte tone.  Set tone only.
OPN1CHTONE				EQU		$E4 ;	// Followed by upper-byte and lower-byte tone.  Set tone only.

OPN3CHMUTE				EQU		$E2 ; // No parameter
OPN2CHMUTE				EQU		$E1 ; // No parameter
OPN1CHMUTE				EQU		$E0 ; // No parameter



BGM_PTR_HIGH			FCB		0
BGM_PTR					FDB		0
BGM_REPEAT_PTR			FDB		0
BGM_WAIT_COUNTER		FDB		0

BGM_CURRENT_OPN_NOTE	FDB		0,0,0
BGM_CURRENT_PSG_NOTE	FDB		0,0,0

BGM_MMR_RESET_FUNCTION	FDB		0

BGM_SAVE_FD93			FCB		0
BGM_SAVE_FD8C			FDB		0

BGM_END_OF_DATA			FCB		0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



START_BGM				PSHS	CC
						ORCC	#$50
						LDX		$FFF8
						STX		TIMER_IRQ_HANDLER_SAVE,PCR
						LEAX	TIMER_IRQ_HANDLER,PCR
						STX		$FFF8

						CLR		BGM_END_OF_DATA,PCR

						LDA		#$4
						STA		IO_IRQ_MASK

						LDX		#0
						STX		CLOCK_COUNTER_HIGH,PCR
						STX		CLOCK_COUNTER_LOW,PCR
						STX		CLOCK_COUNTER_LOCAL,PCR

						STX		BGM_WAIT_COUNTER,PCR
						LDX		#BGMDATA_TOP
						STX		BGM_PTR,PCR
						STX		BGM_REPEAT_PTR,PCR

						LDA		#BGM_MMR_TOP
						STA		BGM_PTR_HIGH,PCR

						LDA		#$2D
						LBSR	OPN_LATCH_REGISTER
						LDA		#$2E
						LBSR	OPN_LATCH_REGISTER

						LDD		#$2714
						LBSR	OPN_WRITE_REGISTER

						LDA		#$24
						LDB		#$FF
						LBSR	OPN_WRITE_REGISTER
						LDA		#$25
						LDB		#1
						LBSR	OPN_WRITE_REGISTER

						LDD		#$2715
						LBSR	OPN_WRITE_REGISTER

						PULS	CC,PC



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



END_BGM					PSHS	CC
						ORCC	#$50
						LDX		TIMER_IRQ_HANDLER_SAVE,PCR
						STX		$FFF8

						CLR		IO_IRQ_MASK

						LDD		#$2714
						LBSR	OPN_WRITE_REGISTER

						PULS	CC,PC


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



LOCAL_TIMER_RESET		PSHS	CC
						ORCC	#$50
						LDX		#0
						STX		CLOCK_COUNTER_LOCAL,PCR
						PULS	CC,PC



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



TIMER_IRQ_HANDLER
						LDA		IO_IRQ_SOURCE
						ANDA	#$04
						BNE		TIMER_IRQ_HANDLER_NOT_TIMER

						LDD		CLOCK_COUNTER_LOW,PCR
						ADDD	#1
						STD		CLOCK_COUNTER_LOW,PCR

						LDD		CLOCK_COUNTER_HIGH,PCR
						ADCB	#0
						ADCA	#0
						STD		CLOCK_COUNTER_HIGH,PCR

						LDD		CLOCK_COUNTER_LOCAL,PCR
						ADDD	#1
						STD		CLOCK_COUNTER_LOCAL,PCR

TIMER_IRQ_HANDLER_NOT_TIMER
						LBSR	OPN_GET_STATE

						LSRA
						BCC		TIMER_IRQ_HANDLER_EXIT
						BSR		PLAYBACK_BGM

TIMER_IRQ_HANDLER_EXIT
						RTI


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
						; Output
						;	D	Clock counter low 16 bits
TIMER_GET_COUNTER_LOW
						PSHS	CC
						ORCC	#$50
						LDD		CLOCK_COUNTER_LOW,PCR
						PULS	CC,PC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

						; Output
						;	X	Clock counter high 16 bits
						;	D	Clock counter low 16 bits
TIMER_GET_COUNTER
						PSHS	CC
						ORCC	#$50
						LDX		CLOCK_COUNTER_HIGH,PCR
						LDD		CLOCK_COUNTER_LOW,PCR
						PULS	CC,PC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


BGM_MMR_SAVE			LDA		$FD93
						STA		BGM_SAVE_FD93,PCR
						LDD		$FD8C
						STD		BGM_SAVE_FD8C,PCR
						RTS


BGM_MMR_ENABLE			LDA		BGM_PTR_HIGH,PCR
						STA		$FD8C
						INCA
						ANDA	#$0F
						STA		$FD8D

						LDA		#$80
						STA		$FD93

						RTS


BGM_MMR_RESTORE			LDA		BGM_SAVE_FD93,PCR
						STA		$FD93
						LDD		BGM_SAVE_FD8C,PCR
						STD		$FD8C
						RTS


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



PLAYBACK_BGM			BSR		BGM_MMR_SAVE
						LDX		BGM_WAIT_COUNTER,PCR
						LBNE	PLAYBACK_BGM_WAIT

						LDU		BGM_PTR,PCR
						BSR		BGM_MMR_ENABLE

PLAYBACK_BGM_LOOP		LDA		,U
						LDB		,U+
						SUBB	#$D0
						BCC		PLAYBACK_BGM_MACRO_COMMAND
						LDB		,U+
						LBSR	OPN_WRITE_REGISTER
						BRA		PLAYBACK_BGM_LOOP


PLAYBACK_BGM_MACRO_COMMAND
						ANDA	#3

						PSHS	A
						LEAX	PLAYBACK_BGM_JUMP_TABLE,PCR
						LSLB
						LDD		B,X
						LEAX	PLAYBACK_BGM_JUMP_BASE,PCR
						CLRA
						LEAX	D,X
						PULS	A

						JMP		,X
PLAYBACK_BGM_JUMP_BASE

OPN_CHMUTE				TFR		A,B
						LDA		#OPN_REG_SLOT_ON_OFF
						LBSR	OPN_WRITE_REGISTER
						BRA		PLAYBACK_BGM_LOOP

PLAYBACK_BGM_OPN_ALLMUTE
						LDD		#$2800
						LBSR	OPN_WRITE_REGISTER
						LDD		#$2801
						LBSR	OPN_WRITE_REGISTER
						LDD		#$2802
						LBSR	OPN_WRITE_REGISTER
						BRA		PLAYBACK_BGM_LOOP

OPN_CHUNMUTE			TFR		A,B
						ORB		#$f0
						LDA		#OPN_REG_SLOT_ON_OFF
						LBSR	OPN_WRITE_REGISTER
						BRA		PLAYBACK_BGM_LOOP

PLAYBACK_BGM_OPN_ALLUNMUTE
						LDD		#$28F0
						LBSR	OPN_WRITE_REGISTER
						LDD		#$28F1
						LBSR	OPN_WRITE_REGISTER
						LDD		#$28F2
						LBSR	OPN_WRITE_REGISTER
						BRA		PLAYBACK_BGM_LOOP

OPN_CHTONE				PSHS	A
						ADDA	#OPN_REG_FNUMBER_HIGH
						LDB		,U+
						LBSR	OPN_WRITE_REGISTER
						PULS	A
						ADDA	#OPN_REG_FNUMBER_LOW
						LDB		,U+
						LBSR	OPN_WRITE_REGISTER
						BRA		PLAYBACK_BGM_LOOP

PLAYBACK_BGM_PSGENDLOOP					; Not supported yet
PLAYBACK_BGM_PSGBEGINLOOP_FINITE		; Not supported yet
PLAYBACK_BGM_PSGBEGINLOOP_INFINITE		; Not supported yet
PLAYBACK_BGM_NOP		BRA		PLAYBACK_BGM_LOOP


OPN_CHPLAY				PSHS	A
						LDB		,S
						LDA		#OPN_REG_SLOT_ON_OFF
						LBSR	OPN_WRITE_REGISTER

						LDA		,S
						ADDA	#OPN_REG_FNUMBER_HIGH
						LDB		,U+
						LBSR	OPN_WRITE_REGISTER
						LDA		,S
						ADDA	#OPN_REG_FNUMBER_LOW
						LDB		,U+
						LBSR	OPN_WRITE_REGISTER

						PULS	B
						ORB		#$F0
						LDA		#OPN_REG_SLOT_ON_OFF
						LBSR	OPN_WRITE_REGISTER

						LBRA	PLAYBACK_BGM_LOOP


PLAYBACK_BGM_PSGEVENNOCHANGE
						LDB		,U+
						CLRA
						LSLB
						ROLA
						STD		BGM_WAIT_COUNTER,PCR
						BRA		PLAYBACK_BGM_LOOP_EXIT

PLAYBACK_BGM_PSGODDNOCHANGE
						LDB		,U+
						CLRA
						LSLB
						ROLA
						ADDD	#1
						STD		BGM_WAIT_COUNTER,PCR
						BRA		PLAYBACK_BGM_LOOP_EXIT

PLAYBACK_BGM_PSGLONGNOCHANGE
						LDD		,U++
						STD		BGM_WAIT_COUNTER,PCR
						BRA		PLAYBACK_BGM_LOOP_EXIT

PLAYBACK_BGM_PSGLASTCMD
						LEAU	-1,U

						LDD		#$2800
						LBSR	OPN_WRITE_REGISTER
						LDD		#$2801
						LBSR	OPN_WRITE_REGISTER
						LDD		#$2802
						LBSR	OPN_WRITE_REGISTER

						LDD		#$0800
						LBSR	OPN_WRITE_REGISTER
						LDD		#$0900
						LBSR	OPN_WRITE_REGISTER
						LDD		#$0A00
						LBSR	OPN_WRITE_REGISTER

						LDD		#2048
						STD		BGM_WAIT_COUNTER,PCR

						LDA		#$FF
						STA		BGM_END_OF_DATA,PCR

						BRA		PLAYBACK_BGM_LOOP_EXIT


PLAYBACK_BGM_PSG_TONE
						LSLA
						PSHS	A

						LDB		,U+
						BSR		OPN_WRITE_REGISTER

						PULS	A
						INCA
						LDB		,U+
						BSR		OPN_WRITE_REGISTER

						LBRA	PLAYBACK_BGM_LOOP



PLAYBACK_BGM_PSGNOCHANGE
						LDB		,U+
						CLRA
						STD		BGM_WAIT_COUNTER,PCR
PLAYBACK_BGM_PSGSTEPDIVIDER
						; Let fall down to PLAYBACK_BGM_LOOP_EXIT


PLAYBACK_BGM_LOOP_EXIT	LBSR	BGM_MMR_RESTORE

						CMPU	#BGMDATA_TOP+$1000
						BCS		PLAYBACK_BGM_UPDATE_POINTER
						LEAU	-$1000,U
						INC		BGM_PTR_HIGH,PCR

PLAYBACK_BGM_UPDATE_POINTER
						STU		BGM_PTR,PCR

PLAYBACK_BGM_WAIT		LDX		BGM_WAIT_COUNTER,PCR
						CMPX	#1022
						BCS		PLAYBACK_BGM_WAIT_SET_TIMER
						LDX		#1022
PLAYBACK_BGM_WAIT_SET_TIMER
						PSHS	X

						LDD		BGM_WAIT_COUNTER,PCR
						SUBD	,S
						STD		BGM_WAIT_COUNTER,PCR

						LDD		#$2714
						BSR		OPN_WRITE_REGISTER

						LDD		#1023
						SUBD	,S
						STB		1,S	; Don't need to save A

						LSRA
						RORB
						LSRA
						RORB
						LDA		#$24
						BSR		OPN_WRITE_REGISTER

						LDA		#$25
						LDB		1,S
						ANDB	#3
						BSR		OPN_WRITE_REGISTER

						LDD		#$2715
						BSR		OPN_WRITE_REGISTER

						PULS	X,PC



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



