


INTRO_FM77AV
						BSR		FM77AV_4096COLORS
						LBSR	INTRO_FM77AV_MESSAGE
						RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Input   A times wait
INTRO_FM77AV_WAIT
						PSHS	A,B,X

						LDB		$FD04
						BITB	#2
						BEQ		INTRO_FM77AV_WAIT_EXIT

						LDX		#$4000
INTRO_FM77AV_WAIT_OUTER_LOOP
INTRO_FM77AV_WAIT_INNER_LOOP
						LEAX	-1,X
						BNE		INTRO_FM77AV_WAIT_INNER_LOOP
						DECA
						BNE		INTRO_FM77AV_WAIT_INNER_LOOP

INTRO_FM77AV_WAIT_EXIT
						PULS	A,B,X,PC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



FM77AV_4096COLORS
						LBSR	HALT_SUBCPU


						LDA		#3
						STA		IO_MMR_SEGMENT

						BSR		FM77AV_4096COLOR_INIT_MMR


						LDA		#$1C			; Physical Address $1C000
						STA		IO_MMR_TOP+$0C	; Sub system $C000-$CFFF mapped to Main system $C000-CFFF

						LDA		#$1D			; Physical Address $1D000
						STA		IO_MMR_TOP+$0D	; Sub system $D000-$DFFF mapped to Main system $D000-DFFF

						; Enable MMR
						LDA		#$80
						STA		IO_MMR_CONTROL

						CLR		LINEDATA_BUF			; Make sure Sub-CPU routine will do nothing after unhalting.

						CLR		IO_SUB_HWDRW_COMMAND	; Disable Hardware Drawing

						BSR		FM77AV_4096COLORS_MAIN

						LDA		#$80
						STA		IO_SUB_HWDRW_COMMAND	; Enable Hardware Drawing

						BSR		FM77AV_4096COLOR_INIT_MMR
						CLR		IO_MMR_CONTROL

						LBSR	RELEASE_SUBCPU

						RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FM77AV_4096COLOR_INIT_MMR
						LDA		#$30
						LDX		#IO_MMR_TOP
FM77AV_4096COLORS_MMR_INIT_LOOP
						STA		,X+
						INCA
						CMPA	#$40
						BNE		FM77AV_4096COLORS_MMR_INIT_LOOP
						RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FM77AV_4096COLOR_STACK_SIZE		EQU		12

FM77AV_4096COLORS_MAIN
						; [10,S]	2 byte		Bit-flip counter
						; [8,S]		2 byte
						; [7,S]		1 byte
						; [6,S]		1 byte		Current bit ($00 or $FF)
						; [4,S]		2 bytes		Bit flip cycle
						; [3,S]		1 byte		VRAM Physical Address Higher 8 bits ($10, $12, $14, $16, $18, $1A)
						; [2,S]		1 byte		VRAM Bank
						; [1,S]		1 byte		Frame Counter
						; [,S]		1 byte

						LEAS	-FM77AV_4096COLOR_STACK_SIZE,S
						CLR		,S
						CLR		1,S



						; for(Bank=0, FlipCycle=1; Bank<2; Bank=Bank+1)
						CLR		2,S

						LDD		#2048			; Bit-Flip Cycle
						STD		4,S
FM77AV_4096COLORS_MAIN_BANK_LOOP


						LDA		2,S
						BNE		FM77AV_4096COLORS_BANK1
						LDA		#$04
						FCB		$8C		; CMPX #$8660
FM77AV_4096COLORS_BANK1
						LDA		#$64
						STA		IO_SUB_VRAM_BANKSELECT


						; for(Layer=#$10; Layer<#$1C; Layer=Layer+2)
						LDA		#$10
						STA		3,S
FM77AV_4096COLORS_MAIN_LAYER_LOOP
						LDA		3,S
						STA		IO_MMR_TOP+$08
						INCA
						STA		IO_MMR_TOP+$09


						; for(U=$8000; U<$A000; U=U+1)
						LDU		#$8000		; U=Current Mapped VRAM Address

						LDX		4,S
						STX		10,S
						LDA		#0
						STA		6,S
FM77AV_4096COLORS_MAIN_ADDRESS_LOOP

						LDA		$FD04
						BITA	#2
						BEQ		FM77AV_4096COLOR_MAIN_EXIT



						LDX		10,S	; Bit-flip counter

						LDB		#$80
						STB		7,S
						ANDB	6,S
						STB		FM77AV_4096COLOR_MAIN_BYTE_OR+1,PCR
						CLRA
FM77AV_4096COLOR_MAIN_BYTE_LOOP
FM77AV_4096COLOR_MAIN_BYTE_OR
						ORA		#$FF		; #$FF will be replaced.

						LEAX	-1,X
						BNE		FM77AV_4096COLOR_MAIN_BYTE_NO_FLIP_YET

						COM		6,S
						LDB		7,S
						ANDB	6,S
						STB		FM77AV_4096COLOR_MAIN_BYTE_OR+1,PCR
						LDX		4,S
FM77AV_4096COLOR_MAIN_BYTE_NO_FLIP_YET

						LSR		FM77AV_4096COLOR_MAIN_BYTE_OR+1,PCR
						LSR		7,S
						BCC		FM77AV_4096COLOR_MAIN_BYTE_LOOP

						STX		10,S	; Save Bit-Flip counter



						STA		,U+

						INC		,S
						LDA		,S
						ANDA	#31
						BNE		FM77AV_4096COLOR_MAIN_USE_256_DOTS_ONLY

						; After every 256 dots.
						LDX		-32,U
						STX		,U++
						LDX		-32,U
						STX		,U++
						LDX		-32,U
						STX		,U++
						LDX		-32,U
						STX		,U++
						LEAY	-40,U
						LDA		#11
FM77AV_4096COLOR_MAIN_DUPLICATE_11_LINES_NEXT_LINE
						LDB		#20
FM77AV_4096COLOR_MAIN_DUPLICATE_11_LINES
						LDX		,Y++
						STX		,U++
						DECB
						BNE		FM77AV_4096COLOR_MAIN_DUPLICATE_11_LINES
						LEAY	-40,Y
						DECA
						BNE		FM77AV_4096COLOR_MAIN_DUPLICATE_11_LINES_NEXT_LINE

FM77AV_4096COLOR_MAIN_USE_256_DOTS_ONLY

p						CMPU	#$8000+192*40		; 192 lines times 40 bytes
						BLO		FM77AV_4096COLORS_MAIN_ADDRESS_LOOP


						; FlipCycle/=2
						LSR		4,S
						ROR		5,S

						; Next layer
						LDA		3,S
						ADDA	#2
						STA		3,S
						CMPA	#$1C
						LBLO	FM77AV_4096COLORS_MAIN_LAYER_LOOP


						INC		2,S
						LDA		2,S
						CMPA	#2
						LBLO	FM77AV_4096COLORS_MAIN_BANK_LOOP



						LBSR	WIREFRAME_SUBCPU_SELECT_BANK0


FM77AV_4096COLOR_MAIN_EXIT
						LEAS	FM77AV_4096COLOR_STACK_SIZE,S
						RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




INTRO_FM77AV_MESSAGE
						LEAU	INTRO_FM77AV_MESSAGE_DATA,PCR
						LDX		#2+10*40  ; (X,Y)=(16,40)

INTRO_FM77AV_MESSAGE_OUTER_LOOP
						LDA		,U
						BEQ		INTRO_FM77AV_MESSAGE_OUTER_LOOP_END

						PSHS	X
INTRO_FM77AV_MESSAGE_INNER_LOOP
						LBSR	HALT_SUBCPU
						LBSR	MMR_ENABLE_ACCESS_SUBCPU_RAM

						LDA		,U+

						LDY		#LINEDATA_BUF

						LDB		#LINE_CMD_SELECT_BANK1
						STB		,Y+
						BSR		INTRO_FM77AV_MESSAGE_ADD_PRINT_COMMAND

						LDB		#LINE_CMD_SELECT_BANK0
						STB		,Y+
						BSR		INTRO_FM77AV_MESSAGE_ADD_PRINT_COMMAND

						LDB		#LINE_CMD_2D_END_OF_CMDSET
						STB		,Y+

						LBSR	MMR_DISABLE
						LBSR	RELEASE_SUBCPU

						LDA		#1
						LBSR	INTRO_FM77AV_WAIT
 
						LEAX	1,X

						LDA		,U
						BNE		INTRO_FM77AV_MESSAGE_INNER_LOOP
						LEAU	1,U

						PULS	X
						LEAX	12*40,X	; 12 lines times 40 bytes

						BRA		INTRO_FM77AV_MESSAGE_OUTER_LOOP

INTRO_FM77AV_MESSAGE_OUTER_LOOP_END

						LDA		#5
						LBSR	INTRO_FM77AV_WAIT

						RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; X VRAM Addr
; A Char
INTRO_FM77AV_MESSAGE_ADD_PRINT_COMMAND
						LDB		#$81
						STB		IO_BEEP

						LDB		#LINE_CMD_PRINT
						STB		,Y+
						LDB		#63		; Color
						STB		,Y+

						LDB		#1
						STB		,Y+		; Number of letters

						STX		,Y++	; VRAM addr
						STA		,Y+

						CLR		IO_BEEP

						RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

INTRO_FM77AV_MESSAGE_DATA
						FCB		"'DUCKY IS BACK' for Fujitsu FM77AV",0
						FCB		"In 1985, FM77AV boasted",0
						FCB		"4096 simultaneous colors.",0
						FCB		"Less known was its",0
						FCB		"hardware-accelerated line drawing.",0
						FCB		"FM77AV inherited two 6809 CPUs",0
						FCB		"from FM-7.",0
						FCB		"The line-drawing hardware can draw",0
						FCB		"lines, while the Sub-CPU is scaling",0
						FCB		"and viewport-clipping, while",0
						FCB		"the Main-CPU is transforming",0
						FCB		"coordinates.",0
						FCB		"Enjoy watching two 6809s and",0
						FCB		"the line-drawing hardware",0
						FCB		"running in parallel!",0
						FCB		0
