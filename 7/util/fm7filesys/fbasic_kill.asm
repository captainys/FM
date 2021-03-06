						; Input
						;	Y		FAT Buffer (152 bytes)
						;	U		Sector Read Buffer (256 bytes)
						;	X		Pointer to the file name
						;			File name shorter than 8 bytes must be padded with trailing ' 's.
						;	B		Drive
						; Output
						;	A		F-BASIC error code.

FSYS_FILE_KILL_STACK_SIZE		EQU		4
FSYS_FILE_KILL_DRIVE			EQU		FSYS_FILE_KILL_STACK_SIZE
FSYS_FILE_KILL_FILENAMEPTR		EQU		FSYS_FILE_KILL_STACK_SIZE+1
FSYS_FILE_KILL_FAT_BUFFER		EQU		FSYS_FILE_KILL_STACK_SIZE+3
FSYS_FILE_KILL_SECTOR_BUFFER	EQU		FSYS_FILE_KILL_STACK_SIZE+5



FSYS_FILE_KILL
						PSHS	U,Y,X,B

						;	[FSYS_FILE_KILL_STACK_SIZE+5,S]	U	Sector Read/Write Buffer
						;	[FSYS_FILE_KILL_STACK_SIZE+3,S]	Y	FAT Buffer
						;	[FSYS_FILE_KILL_STACK_SIZE+1,S]	X	File Name
						;	[FSYS_FILE_KILL_STACK_SIZE,S]	B	Drive

						;	[3,S]	1 byte	First cluster
						;	[2,S]	1 byte	Directory Offset from Sector Top
						;	[1,S]	1 byte	Directory Side
						;	[,S]	1 byte	Directory Sector
						LEAS	-FSYS_FILE_KILL_STACK_SIZE,S

						LBSR	FSYS_FAT_LOAD
						LBCS	FSYS_FILE_KILL_DISKBIOSERROR

						LDX		FSYS_FILE_KILL_FILENAMEPTR,S
						LDA		FSYS_FILE_KILL_DRIVE,S
						LEAY	,S
						LDU		FSYS_FILE_KILL_SECTOR_BUFFER,S
						LBSR	FSYS_DIR_FIND_FILE_ENTRY
						LBCS	FSYS_FILE_KILL_DEVICE_IO_ERROR_OR_FILE_NOT_FOUND

						LDB		2,S		; Offset to the directory entry
						CLRA
						CLR		D,U
						ADDD	#$0E
						LDB		D,U		; Offset $0E=First Cluster
						STB		3,S


						LDA		1,S								; Side
						LDB		FSYS_FILE_KILL_DRIVE,S			; Drive
						TFR		D,X
						LDA		#FSYS_DIR_TRACK					; Track is always 1
						LDB		,S
						LDU		FSYS_FILE_KILL_SECTOR_BUFFER,S	; Original U (Sector Read Buffer)
						LBSR	FSYS_BIOS_WRITESECTOR
						BCS		FSYS_FILE_KILL_DISKBIOSERROR

						LDB		3,S
						LDA		#$FF
FSYS_FILE_KILL_CLEAR_FAT
						LDX		FSYS_FILE_KILL_FAT_BUFFER,S	; Original Y (FAT Buffer)
						ABX
						LDB		,X
						STA		,X
						CMPB	#$C0
						BCS		FSYS_FILE_KILL_CLEAR_FAT


						LDY		FSYS_FILE_KILL_FAT_BUFFER,S
						LDU		FSYS_FILE_KILL_SECTOR_BUFFER,S
						LDB		FSYS_FILE_KILL_DRIVE,S
						LBSR	FSYS_FAT_SAVE
						BCS		FSYS_FILE_KILL_DISKBIOSERROR

FSYS_FILE_KILL_EXIT
						LEAS	FSYS_FILE_KILL_STACK_SIZE,S
						PULS	B,X,Y,U,PC
FSYS_FILE_KILL_DEVICE_IO_ERROR_OR_FILE_NOT_FOUND
						TSTA
						BEQ		FSYS_FILE_KILL_FILE_NOT_FOUND
FSYS_FILE_KILL_DEVICE_IO_ERROR
						LDA		#FBASIC_ERROR_DEVICE_IO_ERROR
						FCB		$8C		; Make it COMPX #$86xx
FSYS_FILE_KILL_FILE_NOT_FOUND
						LDA		#FBASIC_ERROR_FILE_NOT_FOUND
						BRA		FSYS_FILE_KILL_EXIT
FSYS_FILE_KILL_BAD_FILE_MODE
						LDA		#FBASIC_ERROR_BAD_FILE_MODE
						BRA		FSYS_FILE_KILL_EXIT
FSYS_FILE_KILL_WRITE_PROTECTED
						LDA		#FBASIC_ERROR_DISK_WRITE_PROTECTED
						BRA		FSYS_FILE_KILL_EXIT
FSYS_FILE_KILL_DISKBIOSERROR
						LBSR	FSYS_FILE_BIOSERROR_TO_FBASICERROR
						BRA		FSYS_FILE_KILL_EXIT
