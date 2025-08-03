;	Unsigned multiplication 16 bit x 16 bit
;		Input
;			[,Y]		a
;			[2,Y]		b
;		Output
;			[,Y]		higher 16 bits of a*b
;			[2,Y]		lower 16 bits of a*b
;

;	(AH*256+AL)+(BH*256+BL)=65536*AH*BH+256*(AH*BL+AL*BH)+ALBL



UMUL16
			LDA			1,Y
			LDB			3,Y
			MUL
			PSHS		A,B			; Low 16 bits

			LDA			,Y
			LDB			2,Y
			MUL
			PSHS		A,B			; High 16 bits

			;	[,S]	Highest 8 bits
			;	[1,S]	Second high 8 bits
			;	[2,S]	Third high 8bits
			;	[3,S]	Fourth high 8bits

			LDA			1,Y
			LDB			2,Y
			MUL
			ADDD		1,S
			STD			1,S
			LDA			,S
			ADCA		#0
			STA			,S

			LDA			,Y
			LDB			3,Y
			MUL
			ADDD		1,S
			STD			1,S
			LDA			,S
			ADCA		#0
			STA			,S

			LDD			,S++
			STD			,Y
			LDD			,S++
			STD			2,Y

			RTS
