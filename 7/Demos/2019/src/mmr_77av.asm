

MMR_INIT				CLR		IO_MMR_CONTROL

						BSR		MMR_CLEAR_ALL

						CLR		IO_MMR_SEGMENT	; Segment 0 for direct sub-system access.
						LDA		#$1C	        ; Sub-System            $C000-$CFFF
						STA		IO_MMR_TOP+$0C  ; Mapped to Main-System $C000-$CFFF
						LDA		#$1D			; Sub-System            $D000-$DFFF
						STA		IO_MMR_TOP+$0D	; Mapped to Main-System $D000-$DFFF

						LDA		#1
						STA		IO_MMR_SEGMENT	; Segment 1 for BGMDATA	[$4000:]   ; Not used any more.
						LDA		#4
						LDX		#IO_MMR_TOP+$04
MMR_INIT_BGMDATA_LOOP
						STA		,X+
						INCA
						CMPA	#$0F
						BNE		MMR_INIT_BGMDATA_LOOP

						CLR		IO_MMR_SEGMENT	; Segment 0 for direct sub-system access.

						RTS



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



MMR_CLEAR_ALL			LDA		#$00

MMR_CLEAR_ALL_OUTER_LOOP
						STA		IO_MMR_SEGMENT

						LDX		#IO_MMR_TOP
						LDB		#$30
MMR_CLEAR_ALL_INNER_LOOP
						STB		,X+
						INCB
						CMPB	#$40
						BNE		MMR_CLEAR_ALL_INNER_LOOP

						INCA
						CMPA	#8
						BNE		MMR_CLEAR_ALL_OUTER_LOOP

						RTS



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



MMR_ENABLE_ACCESS_SUBCPU_RAM
						CLR		IO_MMR_SEGMENT
						LDA		#$80
						STA		IO_MMR_CONTROL
						RTS



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



MMR_ENABLE_ACCESS_BGMDATA
						LDA		#1
						STA		IO_MMR_SEGMENT
						LDA		#$80
						STA		IO_MMR_CONTROL
						RTS



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



MMR_DISABLE				CLR		IO_MMR_CONTROL
						RTS



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Input			A	First 4KB Block
;					Y	Data pointer
;					X	Data size

MMR_TRANSFER_TO_EXPANDED_RAM
						PSHS	A,X,Y

						; FM77AV may have only 4 segment selectors.  #7 may be interpreted as #3, but 
						; either way (#3 or #7) the last possible segment will be used for this transfer.
						; (Segment selector just selects a set of MMR registers for quick MMR switching)
						LDA		#7
						STA		IO_MMR_SEGMENT

						LDA		#$30
						LDX		#IO_MMR_TOP
MMR_SETUP_SEG7_LOOP		STA		,X+
						INCA
						CMPA	#$40
						BNE		MMR_SETUP_SEG7_LOOP

						LDA		#$80
						STA		IO_MMR_CONTROL

						PULS	A,X,Y


TRANSFER_OUTER_LOOP		STA		IO_MMR_TOP+$0E		; Map to $E000-$EFFF
						LDU		#$E000

TRANSFER_INNER_LOOP		LDB		,Y+
						STB		,U+
						LEAX	-1,X
						BEQ		TRANSFER_OUTER_LOOP_DONE

						CMPU	#$F000
						BNE		TRANSFER_INNER_LOOP

						INCA
						BRA		TRANSFER_OUTER_LOOP


TRANSFER_OUTER_LOOP_DONE
						CLR		IO_MMR_CONTROL
						CLR		IO_MMR_SEGMENT
						RTS
