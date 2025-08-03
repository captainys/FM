; Input
;	X	Pointer to bitmap [,X] wid in bytes, [1,X] height in pixels, [2,X:] bitmap
;	U	Pointer to VRAM address ($0 to $2000)

DRAW_BITMAP_STACK_SIZE	EQU		11

DRAW_BITMAP_VRAM_ADDRESS		EQU		DRAW_BITMAP_STACK_SIZE+2
DRAW_BITMAP_BITMAP_POINTER		EQU		DRAW_BITMAP_STACK_SIZE

DRAW_BITMAP_H_TIMES_40			EQU		9		; 2-bytes	Height times 40
DRAW_BITMAP_VRAMADDR_END		EQU		7		; 2-bytes	Last Address of VRAM
DRAW_BITMAP_HEIGHT				EQU		6		; 1-byte	Height in pixels
DRAW_BITMAP_WIDTH				EQU		5		; 1-byte	Width in bytes
DRAW_BITMAP_CURRENT_FD8B		EQU		4		; 1-byte	Current VRAM layer (written to $FD8B and $FD8C)
DRAW_BITMAP_SAVE_FD8C			EQU		2		; 2-bytes	Save MMR for $C000, $D000
DRAW_BITMAP_SAVE_FD8B			EQU		1		; 1-byte	Save MMR for $B000
DRAW_BITMAP_SAVE_FD93			EQU		0		; 1-byte	MMR control register

DRAW_BITMAP_64_PAGE1
						PSHS	U,X
						LEAS	-DRAW_BITMAP_STACK_SIZE,S

						LBSR	HALT_SUBCPU

						; Save MMR
						LDA		$FD93
						STA		DRAW_BITMAP_SAVE_FD93,S
						LDA		$FD8B
						STA		DRAW_BITMAP_SAVE_FD8B,S
						LDD		$FD8C
						STD		DRAW_BITMAP_SAVE_FD8C,S


						; Enable MMR (Sub $C000-$DFFF mapped to Main)
						LDD		#$1B1C
						STD		$FD8B
						LDA		#$1D
						STA		$FD8D
						LDA		#$80
						STA		$FD93

						; Do nothing after Unhalt
						CLR		LINEDATA_BUF

						; Select Bank 1
						LDA		#$64
						STA		IO_SUB_VRAM_BANKSELECT

						CLR		IO_SUB_HWDRW_COMMAND	; Disable Hardware Drawing
						; Prep
						LDD		,X++
						STD		DRAW_BITMAP_WIDTH,S
						LEAY	,X

						LDA		#40
						LDB		DRAW_BITMAP_HEIGHT,S
						MUL
						STD		DRAW_BITMAP_H_TIMES_40,S


						; for(unsigned char vramaddr=0x10; vramaddr<0x1C; vramaddr+=2)
						LDA		#$10
						STA		$FD8B
						INCA
						STA		$FD8C
DRAW_BITMAP_64_PAGE1_LAYER_LOOP


						; for(unsigned int y=0; y<height; ++y)
						LDU		DRAW_BITMAP_VRAM_ADDRESS,S
						LDD		DRAW_BITMAP_H_TIMES_40,S
						ADDD	#$B000
						LEAU	D,U
						STU		DRAW_BITMAP_VRAMADDR_END,S

						LDU		DRAW_BITMAP_VRAM_ADDRESS,S
						LEAU	$B000,U
DRAW_BITMAP_Y_LOOP

						; for(int i=0; i<width_in_byte; ++i)
						TFR		U,X
						LDA		DRAW_BITMAP_WIDTH,S
DRAW_BITMAP_X_LOOP
						LDB		,Y+
						STB		,X+
						DECA
						BNE		DRAW_BITMAP_X_LOOP



						LEAU	40,U
						CMPU	DRAW_BITMAP_VRAMADDR_END,S
						BCS		DRAW_BITMAP_Y_LOOP



						INC		$FD8B
						INC		$FD8B
						INC		$FD8C
						INC		$FD8C
						LDA		$FD8B
						CMPA	#$1C
						BCS		DRAW_BITMAP_64_PAGE1_LAYER_LOOP





						; Select Bank 0
						LDA		#$04
						STA		IO_SUB_VRAM_BANKSELECT

						LDA		#$80
						STA		IO_SUB_HWDRW_COMMAND	; Enable Hardware Drawing

						; Restore MMR
						LDA		DRAW_BITMAP_SAVE_FD8B,S
						STA		$FD8B
						LDD		DRAW_BITMAP_SAVE_FD8C,S
						STD		$FD8C
						LDA		DRAW_BITMAP_SAVE_FD93,S
						STA		$FD93

						LBSR	RELEASE_SUBCPU

						LEAS	DRAW_BITMAP_STACK_SIZE,S
						PULS	X,U,PC
