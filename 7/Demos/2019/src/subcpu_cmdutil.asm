


;  Input
;    Y Sub-CPU command pointr
;    A Bit0: Buffer 0 or 1
;
;  Output
;    Y Pointer to the next command
;    A,B destroyed.
SUBCPU_PUSH_BEGIN_FRAME_CMD
					ANDA	#1
					LSLA
					LSLA
					LSLA
					LSLA
					LSLA

					LDB		#LINE_CMD_SET_OFFSET	; VRAM offset for HW LINE
					STB		,Y+
					CLRB
					STD		,Y++

					RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;  Input
;    Y Sub-CPU command pointr
;    A Bit0: Buffer 0 or 1 (whichever finished drawing)
;
;  Output
;    Y Pointer to the next command
;    A,B destroyed.
SUBCPU_PUSH_END_FRAME_CMD
					LDB		#LINE_CMD_HALF_CLS
					STB		,Y+
					EORA	#1
					LSLA
					LSLA
					LSLA
					LSLA
					LSLA
					CLRB
					STD		,Y++

					RTS



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SUBCPU_ALL_CLS_AND_FLUSH
					LBSR	HALT_SUBCPU
					LBSR	MMR_ENABLE_ACCESS_SUBCPU_RAM


					LDY		#LINEDATA_BUF

					LDA		#LINE_CMD_SELECT_BANK1
					STA		,Y+

					LDA		#LINE_CMD_CLS
					STA		,Y+

					LDA		#LINE_CMD_SELECT_BANK0
					STA		,Y+

					LDA		#LINE_CMD_CLS
					STA		,Y+

					LDA		#LINE_CMD_2D_END_OF_CMDSET
					STA		,Y+

					LBSR	MMR_DISABLE
					LBSR	RELEASE_SUBCPU

					RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SUBCPU_BANK0_CLS_AND_FLUSH
					LBSR	HALT_SUBCPU
					LBSR	MMR_ENABLE_ACCESS_SUBCPU_RAM


					LDY		#LINEDATA_BUF

					LDA		#LINE_CMD_SELECT_BANK0
					STA		,Y+

					LDA		#LINE_CMD_CLS
					STA		,Y+

					LDA		#LINE_CMD_2D_END_OF_CMDSET
					STA		,Y+

					LBSR	MMR_DISABLE
					LBSR	RELEASE_SUBCPU

					RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SUBCPU_BANK1_CLS_AND_FLUSH
					LBSR	HALT_SUBCPU
					LBSR	MMR_ENABLE_ACCESS_SUBCPU_RAM


					LDY		#LINEDATA_BUF

					LDA		#LINE_CMD_SELECT_BANK1
					STA		,Y+

					LDA		#LINE_CMD_CLS
					STA		,Y+

					LDA		#LINE_CMD_SELECT_BANK0
					STA		,Y+

					LDA		#LINE_CMD_2D_END_OF_CMDSET
					STA		,Y+

					LBSR	MMR_DISABLE
					LBSR	RELEASE_SUBCPU

					RTS
