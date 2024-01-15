#ifndef DISKIMG_H_IS_INCLUDED
#define DISKIMG_H_IS_INCLUDED

#include "DEF.H"

#define MAX_NUM_TRACKS         163



#define FLAG_CRC_ERROR         1
#define FLAG_DELETED_DATA      2
#define FLAG_RECORD_NOT_FOUND  4

#define MB8877_IOERR_CRC 8
#define MB8877_IOERR_RECORD_NOT_FOUND 0x10
#define MB8877_IOERR_DELETED_DATA     0x20
#define MB8877_IOERR_LOST_DATA			0x04


typedef struct AddrMark
{
	unsigned char CHRN[4],flags;
} ADDRMARK;

void AddrMark_Init(ADDRMARK *addr);

typedef struct Sector
{
	unsigned char CHRN[4],flags;
	unsigned int numBytes;
	unsigned char *data;
} SECTOR;

void Sector_Init(SECTOR *sector);
void Sector_Alloc(SECTOR *sector,unsigned int len);
void Sector_Destroy(SECTOR *sector);

typedef struct Track
{
	unsigned density;
	unsigned char C,H;
	unsigned int numAddrMarks;
	ADDRMARK *addrMarks;
	unsigned int numSectors;
	SECTOR *sectors;
} TRACK;

void Track_Init(TRACK *track);
int Track_Prepare(TRACK *track,int C,int H,int numAddrMarks,int numSectors);
void Track_Destroy(TRACK *track);
/*! crunchGapLevel
    0
	unsigned int len_preGap=32;
	unsigned int len_sync=12;
	unsigned int len_gap2=0x16;
	unsigned int len_gap3=0x36;
	1
	unsigned int len_preGap=24;
	unsigned int len_sync=10;
	unsigned int len_gap2=0x10;
	unsigned int len_gap3=0x30;
	2
	unsigned int len_preGap=20;
	unsigned int len_sync=9;
	unsigned int len_gap2=0x0C;
	unsigned int len_gap3=0x26;

	returns error code.
*/
int Track_MakeFormatData(unsigned int *len,unsigned char data[],unsigned long maxLen,const TRACK *track,unsigned char crunchGapLevel);

void Track_Print(TRACK *track);

#define FORMAT_LEN_2DD          6198
#define FORMAT_LEN_2HD_1232KB  10416
#define FORMAT_LEN_2HD_1440KB  12934
#define FORMAT_LEN_MAX         16384

typedef struct DiskProp
{
	unsigned char writeProtected;
	unsigned char mediaType;
	unsigned int numTracks;
} DISKPROP;

typedef struct Disk
{
	DISKPROP prop;
	TRACK tracks[MAX_NUM_TRACKS];
} DISK;

int VerifyDiskWritable(const DISKPROP *prop);

/*! Returns 0, 320, 640, 1232 or 1440.
    Does not distinguish 640KB and 720KB.
    Returns 0 if the media type is 1D or 1DD or unknown.
*/
int IdentifyDiskSizeInKB(const DISKPROP *prop,const TRACK *track);

#define D77_HEADER_LENGTH 0x20

#define D77_MEDIATYPE_2D       0
#define D77_MEDIATYPE_2DD   0x10
#define D77_MEDIATYPE_2HD   0x20
#define D77_MEDIATYPE_1D    0x30
#define D77_MEDIATYPE_1DD   0x40

#define D77_DENSITY_FM      0x40
#define D77_DENSITY_MFM        0

#define D77_DATAMARK_NORMAL     0
#define D77_DATAMARK_DELETED 0x10

#define D77_SECTOR_STATUS_CRC              0xB0
#define D77_SECTOR_STATUS_RECORD_NOT_FOUND 0xF0

#define D77_HEADER_OFFSET_WRITEPROT 0x1a
#define D77_HEADER_OFFSET_MEDIATYPE 0x1b
#define D77_HEADER_OFFSET_DISKSIZE  0x1c

typedef struct D77Reader
{
	FILE *fp;
	DISKPROP prop;
	unsigned long diskSize;
	unsigned char header_basic[D77_HEADER_LENGTH];
	unsigned long trackPtr[MAX_NUM_TRACKS];
} D77READER;

D77READER *D77Reader_Create(void);
int D77Reader_Begin(D77READER *reader,const char fn[]);
int D77Reader_ReadTrack(TRACK *track,D77READER *reader,unsigned int trackPos);
void D77Reader_DestroyTrack(TRACK *track);
int D77Reader_End(D77READER *reader);
void D77Reader_Destroy(D77READER *);


#define RDDCMD_BEGIN_DISK     0x00
#define RDDCMD_BEGIN_TRACK    0x01
#define RDDCMD_IDMARK         0x02
#define RDDCMD_DATA           0x03
#define RDDCMD_TRACK_READ     0x04
#define RDDCMD_END_TRACK      0x05
#define RDDCMD_END_DISK       0x06
#define RDDCMD_RESERVED07H    0x07
#define RDDCMD_RESERVED08H    0x08
#define RDDCMD_RESERVED09H    0x09
#define RDDCMD_RESERVED0AH    0x0A
#define RDDCMD_RESERVED0BH    0x0B
#define RDDCMD_RESERVED0CH    0x0C
#define RDDCMD_RESERVED0DH    0x0D
#define RDDCMD_RESERVED0EH    0x0E
#define RDDCMD_RESERVED0FH    0x0F
#define RDDCMD_UNSTABLE_BYTES 0x10

#define RDD_PADDED_SIZE(n) (((n)+15)&0xFFFFFFF0)

typedef struct RDDReader
{
	FILE *fp;
	DISKPROP prop;
	unsigned char RDDVer;
	char diskName[34];
	unsigned char captureDevice;
} RDDREADER;

RDDREADER *RDDReader_Create(void);
int RDDReader_Begin(RDDREADER *reader,const char fn[]);
int RDDReader_ReadTrack(TRACK *track,RDDREADER *reader);
void RDDReader_DestroyTrack(TRACK *track);
int RDDReader_End(RDDREADER *reader);
void RDDReader_Destroy(RDDREADER *);

#endif