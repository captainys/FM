; Input
;		Y	Buffer address
;		A	Color
;		
;		Add a CIRCLE (16 corners)  Radius is fixed to 127.
;		Command is fixed to LINE_CMD_2D_TRANS_CLIP

; Output
;		Y	Next buffer address

HIGH_LEV_GRAPH_CIRCLE16
						LDB		#LINE_CMD_2D_TRANS_CLIP
						STB		,Y+

						LDB		#16
						STB		,Y+		; # LINES

						STD		,--S
						LEAX	HIGH_LEV_CIRCLE16_TABLE,PCR
HIGH_LEV_GRAPH_CIRCLE16_LOOP
						LDA		,S
						STA		,Y+		; Color
						LDD		,X++
						STD		,Y++
						LDD		,X
						STD		,Y++
						DEC		1,S
						BNE		HIGH_LEV_GRAPH_CIRCLE16_LOOP

						PULS	A,B,PC

;;;;;;;;

HIGH_LEV_GRAPH_CIRCLE8
						LDB		#LINE_CMD_2D_TRANS_CLIP
						STB		,Y+

						LDB		#8
						STB		,Y+		; # LINES

						STD		,--S
						LEAX	HIGH_LEV_CIRCLE16_TABLE,PCR
HIGH_LEV_GRAPH_CIRCLE8_LOOP
						LDA		,S
						STA		,Y+		; Color
						LDD		,X
						STD		,Y++
						LEAX	4,X	; Skip 1 coord
						LDD		,X
						STD		,Y++
						DEC		1,S
						BNE		HIGH_LEV_GRAPH_CIRCLE8_LOOP

						PULS	A,B,PC


;;;;;;;;

HIGH_LEV_CIRCLE16_TABLE
						FCB		$7F,$00
						FCB		$75,$30
						FCB		$59,$59
						FCB		$30,$75
						FCB		$00,$7F
						FCB		$D0,$75
						FCB		$A7,$59
						FCB		$8B,$30
						FCB		$81,$00
						FCB		$8B,$D0
						FCB		$A7,$A7
						FCB		$D0,$8B
						FCB		$00,$81
						FCB		$30,$8B
						FCB		$59,$A7
						FCB		$75,$D0
						FCB		$7F,$00
