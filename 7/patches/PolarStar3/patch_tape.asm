; Put this patch ("LOADER" and "PATCH") before Polar Star III tape.

; "LOADER"
; 10 CLEAR,&H1000
; 20 LOADM"CAS0:"
; 30 LOADM"CAS0:"
; 40 EXEC &H1A00

; SAVEM"PATCH",&h1A00,&H1B7F,&H1A00


ORIGINAL_INKEY		EQU		$1B34


					ORG		$1A00


					LDD		#$1212	; NOP NOP
					STD		$6017
					STD		$6019
					LDA		#$39	; RTS
					STA		$6044
					ORCC	#$50
					LDS		#$FC80
					JSR		$6000	; This will load and come back.



					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					; Clear Screen (Init Sub-CPU)
					; Need to use Sub-CPU program space for joystick reader.
					; Therefore, the sub-CPU program needs to be placed in this loader from $C000
					; However, Polar Star III issues Sub-INIT command, which nukes $C000-
					; To prevent, init sub-CPU here, and NOP the part that is issuing sub-init in Polar Star III.
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

					LBSR		HALT_SUBCPU

					LEAX	SUBCPU_INIT,PCR
					LDU		#$FC80
					LDB		#(SUBCPU_INIT_END-SUBCPU_INIT)
SUBCMD_TFR			LDA		,X+
					STA		,U+
					DECB
					BNE		SUBCMD_TFR

					CLR		$FD05



					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					; Disable Clear Screen in the Polar Star III code.
					; emb 585A 12 12 12 12 12 12 12 12 12 12 12 12 12
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

					LDX		#$585A
					LDA		#$12
					LDB		#13
NOP_POLAR3_INITSUB	STA		,X+
					DECB
					BNE		NOP_POLAR3_INITSUB




					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					; Transfer $0467 bytes from main $5BF1 to sub $C000  (Last destination address is $C467)
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					LDU		#$5BF1
TFR_LOOP
					BSR		HALT_SUBCPU

					LEAX	SUBCPU_TFR_CMD,PCR
					LDY		#$FC80
					LDB		#$13
TFR_INNER_LOOP1		LDA		,X+
					STA		,Y+
					DECB
					BNE		TFR_INNER_LOOP1

					LDB		#$6D
TFR_INNER_LOOP2		LDA		,U+
					STA		,Y+
					DECB
					BNE		TFR_INNER_LOOP2

					CLR		$FD05

					LDD		SUBCPU_TFR_CMD+$0E,PCR
					ADDD	#$6D
					STD		SUBCPU_TFR_CMD+$0E,PCR
					CMPD	#$C467

					BCS		TFR_LOOP



					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					; Prevent Polar Star III code from re-transfer the sub-CPU code.
					; LBSR $1B7C -> NOP NOP NOP
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					LDD		#$1212
					STD		$417E
					STA		$4180




					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
					; Apply joystick patches.
					;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

					BSR		JSInit

					; For testing, just destroy 5C00-5DFF and if it is ok.
					LDX		#$5C00
					LEAU	REDIRECT_BEGIN,PCR
					LDB		#(REDIRECT_END-REDIRECT_BEGIN)
PATCH_LOOP			LDA		,U+
					STA		,X+
					DECB
					BNE		PATCH_LOOP


					; 0816 17131B     LBSR    $1B34   INKEY  ->  JSR $1C00
					LDA		#$BD	; JSR
					STA		$4816
					LDD		#$1C00
					STD		$4817

					; Looks like waiting for SPACE is in different routine than $1B34.

					; 05AF 171582     LBSR    $1B34   INKEY  ->  JSR $1C00+(REDIRECT_WAIT_SPACE-REDIRECT_BEGIN)
					LDA		#$BD	; JSR
					STA		$45AF
					LDD		#($1C00+REDIRECT_WAIT_SPACE-REDIRECT_BEGIN)
					STD		$45B0

					; 09FC B6FD04     LDA     $FD04  -> JSR $1C00+(REDIRECT_CHECK_BREAK_KEY-REDIRECT_BEGIN)
					LDA		#$BD	; JSR
					STA		$49FC
					LDD		#($1C00+REDIRECT_CHECK_BREAK_KEY-REDIRECT_BEGIN)
					STD		$49FD

					JMP		$E8E0

HALT_SUBCPU			LDA		$FD05
					BMI		HALT_SUBCPU
					LDA		#$80
					STA		$FD05
HALT_CHECK			LDA		$FD05
					BPL		HALT_CHECK
					RTS


SUBCPU_INIT			FCB		$00,$00,$01,$00,$50,$19,$00,$19,$00,$01,$00
SUBCPU_INIT_END
					;  $FC80 +0  +1  +2 +3  +4  +5  +6  +7  +8  +9  +A  +B  +C  +D  +E  +F  +10 +11 +12
SUBCPU_TFR_CMD		FCB		$00,$00,$3F,'Y','A','M','A','U','C','H','I',$91,$D3,$93,$C0,$00,$00,$6D,$90


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

IO_FM_CMD				EQU		$FD15
IO_FM_DATA				EQU		$FD16

FM_CMD_LATCH			EQU		3
FM_CMD_WRITE			EQU		2
FM_CMD_READ				EQU		9


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

JSInit					LDD		#$0F7F	; Reg 15 <- $7F
						LBSR	FMWrite
						LDD		#$07BF	; Reg 7 <- $BF
						LBRA	FMWrite
						RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

REDIRECT_BEGIN

REDIRECT_INKEY
					JSR		ORIGINAL_INKEY
					TSTA
					BNE		RTS_REDIRECT_INKEY_NO_PREVJS

					BSR		JS0Read
					TFR		A,B		; Back up in B

					EORA	PREVJS,PCR
					ANDA	#$0F
					TFR		B,A		; Restore from Back Up, CC is not supposed to be affected.
					BEQ		NO_CHANGE_IN_DIR

					LEAX	DIR_TABLE,PCR
					ANDB	#$0F	; A is JS0Read  B loses buttons.
					LDB		B,X		; A is JS0Read  B is key code
					EXG		A,B		; B is JS0Read  A is key code
					BRA		RTS_REDIRECT_INKEY


NO_CHANGE_IN_DIR
					; Want to check Prev bit5==1 (Release) and New bit5==0 (Pressed)
					; Same as Prev bit5==1 and !(New bit5)==1
					COMA
					ANDA	PREVJS,PCR
					BITA	#$20
					BEQ		NO_B_BUTTON_PRESS

					LDA		#'P'	; Return P for palette change.
					ORB		#$0F	; Virtually release direction button.
					BRA		RTS_REDIRECT_INKEY

NO_B_BUTTON_PRESS
NO_A_BUTTON_PRESS

RTS_REDIRECT_INKEY_RETURN_ZERO
					CLRA	; No key code to return.

RTS_REDIRECT_INKEY
					STB		PREVJS,PCR
RTS_REDIRECT_INKEY_NO_PREVJS
					RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

REDIRECT_WAIT_SPACE
					JSR		ORIGINAL_INKEY
					TSTA
					BNE		RTS_REDIRECT_INKEY_NO_PREVJS

					BSR		JS0Read
					TFR		A,B
					ANDA	#$30
					CMPA	#$30
					BEQ		RTS_REDIRECT_INKEY_RETURN_ZERO

					LDA		#' '
					BRA		RTS_REDIRECT_INKEY


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

REDIRECT_CHECK_BREAK_KEY
					LDA		$FD04
					BITA	#2
					BEQ		REDIRECT_DONE_BREAK_KEY

					BSR		JS0Read
					TFR		A,B
					LDA		#$FF
					ANDB	#$30
					CMPB	#$30
					BEQ		REDIRECT_DONE_BREAK_KEY

					CLRA

REDIRECT_DONE_BREAK_KEY
					RTS


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


					; Return A=0 if either BREAK or Trigger A is held down.
					;        A=0xFF otherwise.
REDIRECT_TRIGGER

DIR_TABLE			FCB		0	; bits 0000
					FCB		0	; bits 0001
					FCB		0	; bits 0010
					FCB		0	; bits 0011
					FCB		0	; bits 0100
					FCB		'3'	; bits 0101	; Right+Down
					FCB		'9'	; bits 0110	; Right+Up
					FCB		'6'	; bits 0111	; Right
					FCB		0	; bits 1000
					FCB		'1'	; bits 1001	; Left+Down
					FCB		'7'	; bits 1010 ; Left+Up
					FCB		'4'	; bits 1011	; Left
					FCB		0	; bits 1100
					FCB		'2'	; bits 1101	; Down
					FCB		'8'	; bits 1110	; Up
					FCB		'5'	; bits 1111

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

JS0Read					LDB		#$2F	; $2F for JS0,  $5F for JS1
						LDA		#$0F	; Reg 15 < $2F or $5F
						BSR		FMWrite

						LDA		#14
						BSR		FMLatchRegister
						LDA		#9
						STA		IO_FM_CMD
						LDA		IO_FM_DATA
						BRA		FMClearCommand

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

						; A Register
						; B Data
FMWrite					BSR		FMLatchRegister
						STB		IO_FM_DATA
						LDA		#FM_CMD_WRITE
						BRA		FMWriteCommand

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

						; A Register
FMLatchRegister			STA		IO_FM_DATA
						LDA		#FM_CMD_LATCH

FMWriteCommand			STA		IO_FM_CMD
FMClearCommand			CLR		IO_FM_CMD
						RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PREVJS					; Does not have to have an initial value.  Save one byte.

REDIRECT_END

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

