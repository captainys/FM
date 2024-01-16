#ifndef DEF_H_IS_INCLUDED
#define DEF_H_IS_INCLUDED

enum
{
	FILETYPE_NONE,
	FILETYPE_D77,
	FILETYPE_RDD,
	FILETYPE_BIN,
};

enum
{
	ERROR_NONE,
	ERROR_PRINTED_HELP,
	ERROR_OPEN_FILE,
	ERROR_NOT_OPEN,
	ERROR_TOO_SHORT,
	ERROR_TOO_MANY_TRACKS,
	ERROR_DRIVE_LETTER,
	ERROR_TOO_FEW_PARAMETERS,
	ERROR_TRACK_OUT_OF_RANGE,
	ERROR_OUT_OF_MEMORY,
	ERROR_BROKEN_DATA,
	ERROR_1D_1DD_NOT_SUPPORTED,
	ERROR_2D_NOT_SUPPORTED,
	ERROR_2HD_1440KB_NOT_SUPPORTED,
	ERROR_FORMAT_DATA_OVERFLOW,
	ERROR_UNSUPPORTED_FILE_TYPE,
	ERROR_DISK_IMAGE_IS_ON_FD,
	ERROR_DRIVE_NOT_READY,

	END_OF_FILE
};


#define DAMN_BIG_NUMBER 0x7fffffff

#ifndef _MAX_PATH
	#define _MAX_PATH 260
#endif

#define RDD_SIGNATURE "REALDISKDUMP"


//                                        		.386p 
//                                        		ASSUME CS:CODE 
//00000000                                CODE		SEGMENT 
//00000000  FA                            		CLI 
//00000001  FB                            		STI 
//00000002                                CODE		ENDS 
//                                        		END 
#define __CLI _inline(0xFA)
#define __STI _inline(0xFB)

#define SMALLER(a,b) ((a)<(b) ? (a) : (b))
#define GREATER(a,b) ((a)>(b) ? (a) : (b))

#endif
