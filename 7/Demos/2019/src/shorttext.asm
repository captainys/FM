; Print short string and clear screen with YAMAUCHI command only.

IO_MAIN_SUBCPU_HALT		EQU		$FD05

MAIN_SHARED_RAM			EQU		$FC80
SUB_SHARED_RAM			EQU		$D380


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Input
;		X		Text info
;		[,X]	Number of chars
;		[1,X]	VRAM Addr
;		[2,X:]	Text
PRINT_SHORT_TEXT_BY_POINTER
						LDA		,X+
						LDU		,X++
						; Fall down to PRINT_SHORT_TEXT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Input
;		A Number of chars
;		X Pointer to the text (Up to 32 chars)
;		U VRAM Address

PRINT_SHORT_TEXT
						STU		VRAMADDR,PCR

						BSR		HALT_SUBCPU

						LDU		#TEXTADDR_MAIN
PRINT_SHORT_TEXT_TFR_TEXT_LOOP
						LDB		,X+
						STB		,U+
						DECA
						BNE		PRINT_SHORT_TEXT_TFR_TEXT_LOOP

PRINT_SHORT_TEXT_CLEAR_LOOP
						CMPU	#TEXTADDR_MAIN_END
						BEQ		PRINT_SHORT_TEXT_TFR_END
						CLR		,U+
						BRA		PRINT_SHORT_TEXT_CLEAR_LOOP

PRINT_SHORT_TEXT_TFR_END
						LDA		#SUBCPU_PROC_END-SUBCPU_CMD
						LDX		#MAIN_SHARED_RAM
						LEAU	SUBCPU_CMD,PCR
						BSR		TFR_COMMAND

						BSR		RELEASE_SUBCPU

						RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CLEAR_SCREEN
						BSR		HALT_SUBCPU
						LDA		#SUBCPU_CLS_PROC_END-SUBCPU_CLS_CMD
						LDX		#MAIN_SHARED_RAM
						LEAU	SUBCPU_CLS_CMD,PCR
						BSR		TFR_COMMAND
						BSR		RELEASE_SUBCPU
						RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

HALT_SUBCPU
						LDB		IO_MAIN_SUBCPU_HALT
						BMI		HALT_SUBCPU
						LDB		#$80
						STB		IO_MAIN_SUBCPU_HALT
						RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TFR_COMMAND
						LDB		,U+
						STB		,X+
						DECA
						BNE		TFR_COMMAND
						RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RELEASE_SUBCPU
						CLR		IO_MAIN_SUBCPU_HALT
						LDB		IO_MAIN_SUBCPU_HALT
						BPL		RELEASE_SUBCPU
						RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
IO_SUB_VRAM_ACCESS		EQU		$D409
SUBSYS_FONT_ROM			EQU		$D800

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TEXTADDR_MAIN			EQU		$FCE0
TEXTADDR_MAIN_END		EQU		$FD00
TEXTADDR_SUB			EQU		$D3E0
TEXTADDR_SUB_END		EQU		$D400

SUBCPU_CMD				FCB		0,0
						FCB		$3F
VRAMADDR				FCB		"YAMAUCHI"
						FCB		$93
						FDB		SUB_SHARED_RAM+SUBCPU_PROC-SUBCPU_CMD
						FCB		$90

SUBCPU_PROC
						BITA	IO_SUB_VRAM_ACCESS

						LDY		VRAMADDR,PCR
SUBCPU_VRAM_LOOP
						LDU		#TEXTADDR_SUB
SUBCPU_TEXT_LOOP
						LDB		,U+

						LDX		#SUBSYS_FONT_ROM
						ABX
						ABX
						ABX
						ABX
						ABX
						ABX
						ABX
						ABX
						LDB		#8
SUBCPU_TEXT_TFR_LOOP
						LDA		,X+
						STA		,Y
						LEAY	80,Y
						DECB
						BNE		SUBCPU_TEXT_TFR_LOOP

						LEAY	-80*8+1,Y

						CMPU	#TEXTADDR_SUB_END
						BNE		SUBCPU_TEXT_LOOP

						LEAY	$4000-(TEXTADDR_SUB_END-TEXTADDR_SUB),Y
						CMPY	#$C000
						BCS		SUBCPU_VRAM_LOOP

						STA		IO_SUB_VRAM_ACCESS
						RTS
SUBCPU_PROC_END



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SUBCPU_CLS_CMD			FCB		0,0
						FCB		$3F
						FCB		"YAMAUCHI"
						FCB		$93
						FDB		SUB_SHARED_RAM+SUBCPU_CLS_PROC-SUBCPU_CLS_CMD
						FCB		$90
SUBCPU_CLS_PROC
						LDA		IO_SUB_VRAM_ACCESS

						LDX		#0
SUBCPU_CLS_LOOP			CLR		,X+
						CMPX	#$C000
						BNE		SUBCPU_CLS_LOOP

						STA		IO_SUB_VRAM_ACCESS
						RTS
SUBCPU_CLS_PROC_END
