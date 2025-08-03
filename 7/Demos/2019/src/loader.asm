
						;	[,X]	2 bytes	Pointer to the file name
						;	[2,X]	2 bytes	Address Offset
						;	[4,X]	1 byte	Reserved.  Keep zero.
						;	[5,X]	1 byte	Drive 0 or 1
						;	[6,X]	
						;	[8,X]	
						;	[10,X]	
						; Output
						;	[,X]	
						;	[2,X]	
						;	[4,X]	
						;	[5,X]	
						;	[6,X]	2 bytes	Size in bytes
						;	[8,X]	2 bytes	Top address of the loaded binary
						;	[10,X]	2 bytes	Exec address
						; 	A		F-BASIC Error Code

SECTOR_DATA_BUFFER		EQU		$400
FAT_BUFFER				EQU		$500

IO_MAIN_320_640_SELECT	EQU		$FD12

REPEAT
						ORCC	#$50

						CLR		IO_MAIN_320_640_SELECT

						LDS		#$0400

						LBSR	CLEAR_SCREEN

						LEAX	MESSAGEL,PCR
						LBSR	PRINT_SHORT_TEXT_BY_POINTER

						LEAX	MESSAGE0,PCR
						LEAU	FILENAME0,PCR
						LDA		#3
LOAD_LOOP
						PSHS	U,X,A
						LBSR	PRINT_SHORT_TEXT_BY_POINTER
						LDU		3,S
						STA		$FD0F
						BSR		LOADM__R
						PULS	A,X,U
						LEAX	6,X
						LEAU	8,U
						DECA
						BNE		LOAD_LOOP

						BRA		REPEAT

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LOADM__R
						LEAX	LOADER_FILENAME_PTR,PCR
						STU		,X
						LDU		#SECTOR_DATA_BUFFER
						LDY		#FAT_BUFFER
						LBSR	FSYS_FILE_LOADM
						TSTA
						BEQ		LOADM_EXEC

						LEAX	MESSAGEERR,PCR
						LBSR	PRINT_SHORT_TEXT_BY_POINTER
LOADM_INFINITE			BRA		LOADM_INFINITE

LOADM_EXEC				LDX		LOADER_EXEC_ADDR,PCR
						JMP		,X	; Let RTS from there.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LOADER_FILENAME_PTR		FDB		0
LOADER_ADDR_OFFSET		FDB		0
						FCB		0
LOADER_DRIVE			FCB		0
LOADER_BYTE_COUNT		FDB		0
LOADER_TOP_ADDR			FDB		0
LOADER_EXEC_ADDR		FDB		0

FILENAME0				FCB		"DM2019-0"	; 8-bytes each
FILENAME1				FCB		"DM2019-1"
FILENAME4				FCB		"DM2019M "

MESSAGEL				FCB		29
						FDB		5+32*80
						FCB		"YS-DOS V1.0 by CaptainYS 2019"

MESSAGE0				FCB		3			; 6-bytes each
						FDB		5+40*80
						FCB		"1/3"
MESSAGE1				FCB		3
						FDB		5+40*80
						FCB		"2/3"
MESSAGE2				FCB		3
						FDB		5+40*80
						FCB		"3/3"

MESSAGEERR				FCB		11
						FDB		5+128*80
						FCB		"LOAD ERROR!"
