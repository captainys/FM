; The original code by Haruhiko Okumura 4/6/1989 (https://web.archive.org/web/19990209183635/http://oak.oakland.edu/pub/simtelnet/msdos/arcutils/lz_comp2.zip)
; Ported to 6809 by CaptainYS 11/14/2024

; Usage:
;   Place compressed binary where it is not overlapping the decompressor.
;   Call DecodeLZSS with:
;     X Address of the compressed data
;     U Address where decompressed data should be placed
;     Y 4KB buffer used by the decompressor
;     D Length of the compressed data in bytes.

						ORG		$1800
TESTMAIN
						ORCC	#$50
						STA		$FD0F

						LDX		#$2000    ; Compressed data
						LDU		#$C000    ; Decompression buffer
						LDY		#$6000    ; 4KB Text buffer
						LDD		#7109     ; Length of the compressed data
						BSR		DecodeLZSS

						LDA		$FD0F

						RTS





LZSS_N		 		EQU		4096	; size of ring buffer
LZSS_BUFFER_MASK	EQU		(LZSS_N-1)
LZSS_BUFFER_MASK_HI	EQU		(LZSS_BUFFER_MASK>>8)
LZSS_BUFFER_MASK_LO	EQU		(LZSS_BUFFER_MASK&255)
LZSS_F		 		EQU		  18	; upper limit for match_length
LZSS_THRESHOLD		EQU		   2    ; encode string into position and length
						        ;   if match_length is greater than this
LZSS_NIL			EQU		LZSS_N  ; index for root of binary search trees




; Input
;   X					Compressed data
;	U					Decompression buffer
;   Y					4KB Text buffer
;	D					Length of the compressed data
; Output
;   D					Bytes extracted

DecodeLZSS
						PSHS	U	; (*1) Save Expand Pointer for expand-size calculation

						PSHS	X	; (*2) Save Source Pointer
						ADDD	,S
						STD		LZSS_SOURCE_END_PTR,PCR

						; void Decode(void)	/* Just the reverse of Encode(). */
						; {
						;	int  i, j, k, r, c;
						;	unsigned int  flags;


						;	for (i = 0; i < N - F; i++) text_buf[i] = ' ';
						LDD		#$2020	; ' ',' '
						LDX		#LZSS_N

						PSHS	Y	; (*3)
LZSS_INIT_TEXT_BUF		STD		,Y++
						LEAX	-2,X
						BNE		LZSS_INIT_TEXT_BUF
						PULS	Y	; (*3)

						;	r = N - F;  flags = 0;
						LDD		#LZSS_N-LZSS_F
						STD		LZSS_R,PCR
						CLRA
						CLRB
						STD		LZSS_FLAGS_COUNTER,PCR

						PULS	X	(*2) Recover Source Pointer

						; Again X is source, U is desination, Y is 4KB buffer.

						; 	for ( ; ; ) {
LZSS_OUTER_LOOP
						; This flag is to check if the byte should be used as is, or should look up in the sliding window.
						; In 16-bit or higher CPU, using high-byte is beneficial like in the sample code,
						; but in 6809, probably having a counter is easier.

						;		if (((flags >>= 1) & 256) == 0) {
						;			if ((c = getc(infile)) == EOF) break;
						;			flags = c | 0xff00;		/* uses higher byte cleverly */
						;		}							/* to count eight */
						LSR		LZSS_FLAGS_COUNTER,PCR
						BNE		LZSS_NO_FLAGS_REFRESH

						CMPX	LZSS_SOURCE_END_PTR,PCR
						LBCC	LZSS_END_OUTER_LOOP		; Jump if end of data

						LDA		#$FF					; flags|=0xFF00
						LDB		,X+
						STD		LZSS_FLAGS_COUNTER,PCR

LZSS_NO_FLAGS_REFRESH
						LSR		LZSS_FLAGS,PCR
						BCC		LZSS_FLAGS_B0_IS_CLEAR
;LZSS_FLAGS_B0_IS_SET
						;		if (flags & 1) {
						;			if ((c = getc(infile)) == EOF) break;
						;			putc(c, outfile);  text_buf[r++] = c;  r &= (N - 1);
						CMPX	LZSS_SOURCE_END_PTR,PCR
						LBCC	LZSS_END_OUTER_LOOP		; Jump if end of data

						LDA		,X+
						STA		,U

						LDD		LZSS_R,PCR

						PSHS	Y	; (*4)
						LEAY	D,Y

						ADDD	#1
						ANDA	#LZSS_BUFFER_MASK_HI
						; ANDB	#LZSS_BUFFER_MASK_LO	; Since LZSS_BUFFER_MASK_LO is 255, this line is unnecessary.
						STD		LZSS_R,PCR

						LDA		,U+
						STA		,Y

						PULS	Y	; (*4)

						BRA		LZSS_OUTER_LOOP_NEXT


LZSS_FLAGS_B0_IS_CLEAR
						;		} else {
						;			if ((i = getc(infile)) == EOF) break;
						;			if ((j = getc(infile)) == EOF) break;

						CMPX	LZSS_SOURCE_END_PTR,PCR
						BCC		LZSS_END_OUTER_LOOP		; Jump if end of data

						LDB		,X+
						STB		LZSS_I+1,PCR			; Low byte of i.

						CMPX	LZSS_SOURCE_END_PTR,PCR
						BCC		LZSS_END_OUTER_LOOP		; Jump if end of data

						LDB		,X+						; B is High-byte of i | byte count
						TFR		B,A

						;			i |= ((j & 0xf0) << 4);  j = (j & 0x0f) + THRESHOLD;

						; i|=((j&0xf0)<<4); -> Using high 4 bits of j as high byte of i.
						LSRA
						LSRA
						LSRA
						LSRA
						STA		LZSS_I,PCR	; High-Byte of i

						ANDB	#$0F
						ADDB	#LZSS_THRESHOLD+1	; This guarantees j to be non zero.
						STB		LZSS_J,PCR

						;			for (k = 0; k <= j; k++) {
						;				c = text_buf[(i + k) & (N - 1)];
						;				putc(c, outfile);  text_buf[r++] = c;  r &= (N - 1);
						;			}
						;		}

						; LDA		LZSS_I,PCR   A is already high-byte of i.
						LDB		LZSS_I+1,PCR

						; In the original implementation, k is just a counter.
						; j can be used as a counter.
						; i can be incremented every iteration.
LZSS_INNER_LOOP
						; At this line D is i.
						LDA		D,Y
						STA		,U

						PSHS	Y
						LDD		LZSS_R,PCR
						LEAY	D,Y

						ADDD	#1
						ANDA	#LZSS_BUFFER_MASK_HI
						; ANDB	#LZSS_BUFFER_MASK_LO	; It is FF.  Can be omitted.
						STD		LZSS_R,PCR

						LDA		,U+
						STA		,Y
						PULS	Y

						LDD		LZSS_I,PCR
						ADDD	#1
						ANDA	#LZSS_BUFFER_MASK_HI
						; ANDB	#LZSS_BUFFER_MASK_LO	; It is FF.  Can be omitted.
						STD		LZSS_I,PCR

						DEC		LZSS_J,PCR
						BNE		LZSS_INNER_LOOP


LZSS_OUTER_LOOP_NEXT
						LBRA	LZSS_OUTER_LOOP
						;	}
						; }


LZSS_END_OUTER_LOOP
						TFR		U,D
						SUBD	,S
						PULS	U,PC	; (*1) Expand Pointer was saved in S


LZSS_I					FDB		0
LZSS_J					FCB		0
LZSS_R					FDB		0
LZSS_FLAGS_COUNTER		FCB		0
LZSS_FLAGS				FCB		0	; LZSS_FLAGS must come after LZSS_FLAGS_COUNTER
LZSS_SOURCE_END_PTR		FDB		0

