

SET_4096COLOR_MODE		LDA		#$40
						STA		IO_SCREEN_MODE
						RTS



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



SET_DEFAULT_PALETTE		LDX		#4096

SET_DEFAULT_PALETTE_LOOP
						TFR		X,D

						SUBD	#1
						STD		IO_ANALOG_PALETTE_CODE

						STA		IO_ANALOG_PALETTE_BLUE
						TFR		B,A
						LSRA
						LSRA
						LSRA
						LSRA
						STA		IO_ANALOG_PALETTE_RED
						ANDB	#15
						STB		IO_ANALOG_PALETTE_GREEN

						LEAX	-1,X
						BNE		SET_DEFAULT_PALETTE_LOOP

						RTS



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



SET_PALETTE_8_8_64
						; GGgg RRrr BBbb
						LDX		#4096

SET_PALETTE_8_8_64_LOOP
						TFR		X,D

						SUBD	#1
						STD		IO_ANALOG_PALETTE_CODE

						BITA	#$0C
						BNE		SET_PALETTE_8_8_64_FOREGROUND
						BITB	#$CC
						BNE		SET_PALETTE_8_8_64_FOREGROUND

; Show Background
						ANDA	#3
						PSHS	A

						TFR		B,A
						LSRA
						LSRA
						LSRA
						LSRA
						ANDA	#3
						PSHS	A

						ANDB	#3
						PSHS	B


						LDB		,S
						LSLB
						LSLB
						ORB		,S
						STB		IO_ANALOG_PALETTE_BLUE

						LDB		1,S
						LSLB
						LSLB
						ORB		1,S
						STB		IO_ANALOG_PALETTE_RED

						LDB		2,S
						LSLB
						LSLB
						ORB		2,S
						STB		IO_ANALOG_PALETTE_GREEN



						BRA		SET_PALETTE_8_8_64_NEXT


SET_PALETTE_8_8_64_FOREGROUND
						LSRA
						LSRA
						PSHS	A
						LSRA
						ORA		,S
						ANDA	#1
						STA		,S

						TFR		B,A
						LSRA
						LSRA
						LSRA
						LSRA
						LSRA
						LSRA
						PSHS	A
						LSRA
						ORA		,S
						ANDA	#1
						STA		,S

						LSRB
						LSRB
						PSHS	B
						LSRB
						ORB		,S
						ANDB	#1
						STB		,S


						LDA		#$10
						SUBA	,S
						ANDA	#$0F
						STA		IO_ANALOG_PALETTE_BLUE

						LDA		#$10
						SUBA	1,S
						ANDA	#$0F
						STA		IO_ANALOG_PALETTE_RED

						LDA		#$10
						SUBA	2,S
						ANDA	#$0F
						STA		IO_ANALOG_PALETTE_GREEN


SET_PALETTE_8_8_64_NEXT
						LEAS	3,S

						LEAX	-1,X
						LBNE	SET_PALETTE_8_8_64_LOOP

						RTS


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



SET_64COLOR_TWO_LAYER
						LDX		#4096

SET_64COLOR_TWO_LAYER_LOOP
						TFR		X,D

						SUBD	#1
						STD		IO_ANALOG_PALETTE_CODE

						; Ignore lower 2-bits
						BITA	#12
						BNE		SET_64COLOR_TWO_LAYER_SET_BLUE
						LSLA
						LSLA
SET_64COLOR_TWO_LAYER_SET_BLUE
						ANDA	#12
						PSHS	A
						LSRA
						LSRA
						ADDA	,S+
						STA		IO_ANALOG_PALETTE_BLUE

						TFR		B,A
						LSRA
						LSRA
						LSRA
						LSRA

						BITA	#12
						BNE		SET_64COLOR_TWO_LAYER_SET_RED
						LSLA
						LSLA
SET_64COLOR_TWO_LAYER_SET_RED
						ANDA	#12
						PSHS	A
						LSRA
						LSRA
						ADDA	,S+
						STA		IO_ANALOG_PALETTE_RED

						BITB	#12
						BNE		SET_64COLOR_TWO_LAYER_SET_GREEN
						LSLB
						LSLB
SET_64COLOR_TWO_LAYER_SET_GREEN
						ANDB	#12
						PSHS	B
						LSRB
						LSRB
						ADDB	,S+
						STB		IO_ANALOG_PALETTE_GREEN

						LEAX	-1,X
						BNE		SET_64COLOR_TWO_LAYER_LOOP

						RTS



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



SET_BLACK_WHITE
						LDX		#1
						LDA		#15
SET_BLACK_WHITE_LOOP	STX		IO_ANALOG_PALETTE_CODE
						STA		IO_ANALOG_PALETTE_BLUE
						STA		IO_ANALOG_PALETTE_RED
						STA		IO_ANALOG_PALETTE_GREEN
						LEAX	1,X
						CMPX	#4096
						BNE		SET_BLACK_WHITE_LOOP

						LDX		#0
						STX		IO_ANALOG_PALETTE_CODE
						CLR		IO_ANALOG_PALETTE_BLUE
						CLR		IO_ANALOG_PALETTE_RED
						CLR		IO_ANALOG_PALETTE_GREEN

						RTS



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



SET_64COLOR_DOUBLE_BUFFER_EXPOSE_BANK0
						LDX		#4096

SET_64COLOR_DOUBLE_BUFFER_EXPOSE_BANK0_LOOP
						TFR		X,D

						SUBD	#1
						STD		IO_ANALOG_PALETTE_CODE

						; Ignore lower 2-bits
						ANDA	#12
						PSHS	A
						LSRA
						LSRA
						ADDA	,S+
						STA		IO_ANALOG_PALETTE_BLUE

						TFR		B,A
						LSRA
						LSRA
						LSRA
						LSRA
						ANDA	#12
						PSHS	A
						LSRA
						LSRA
						ADDA	,S+
						STA		IO_ANALOG_PALETTE_RED

						ANDB	#12
						PSHS	B
						LSRB
						LSRB
						ADDB	,S+
						STB		IO_ANALOG_PALETTE_GREEN

						LEAX	-1,X
						BNE		SET_64COLOR_DOUBLE_BUFFER_EXPOSE_BANK0_LOOP

						RTS



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



SET_64COLOR_DOUBLE_BUFFER_EXPOSE_BANK1
						LDX		#4096

SET_64COLOR_DOUBLE_BUFFER_EXPOSE_BANK1_LOOP
						TFR		X,D

						SUBD	#1
						STD		IO_ANALOG_PALETTE_CODE

						; Ignore lower 2-bits
						ANDA	#3
						PSHS	A
						LSLA
						LSLA
						ADDA	,S+
						STA		IO_ANALOG_PALETTE_BLUE

						TFR		B,A
						LSRA
						LSRA
						LSRA
						LSRA
						ANDA	#3
						PSHS	A
						LSLA
						LSLA
						ADDA	,S+
						STA		IO_ANALOG_PALETTE_RED

						ANDB	#3
						PSHS	B
						LSLB
						LSLB
						ADDB	,S+
						STB		IO_ANALOG_PALETTE_GREEN

						LEAX	-1,X
						BNE		SET_64COLOR_DOUBLE_BUFFER_EXPOSE_BANK1_LOOP

						RTS



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
