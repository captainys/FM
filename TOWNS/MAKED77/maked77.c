#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <conio.h>
#include <time.h>
#include "FMCFRB.H"


extern void XModemSend(unsigned int dataLength,const unsigned char data[],int baud); // baud  2:38400bps  4:19200bps
extern unsigned int TO_PHYSICAL(unsigned char *addr);
extern void MASKIRQ(void);
extern void UNMASKIRQ(void);
extern unsigned int GETFDCSTA(void); // MX BIOS reads IO 200H twice in a row.  Reason unknown.
extern unsigned int GETDRVSTA(void); // MX BIOS reads IO 208H three times in a row.  Reason unknown.


#define BUFFER_LENGTH 4096
unsigned char bufferSource[BUFFER_LENGTH]; // There should be 4KB continuous page within this array.
unsigned char *DMABuffer=NULL;
unsigned int DMABufferPhysicalAddr=0;


unsigned int drvSel=1;    // Drive 0
unsigned int seekStep=1;  // 2 for 2D disk.
unsigned int controlByte=0; // To be written to I/O 0208h
unsigned int speedByte=0;
unsigned int currentCylinder=0;

#define IO_FDC_STATUS			0x200
#define FDCSTA_BUSY				0x01
#define FDCSTA_INDEX			0x02

#define IOERR_CRC 8
#define IOERR_RECORD_NOT_FOUND 0x10
#define IOERR_DELETED_DATA     0x20
#define IOERR_LOST_DATA			0x04

#define IO_FDC_COMMAND			0x200
#define FDCCMD_RESTORE			0x08
#define FDCCMD_SEEK				0x18
#define FDCCMD_READADDR			0xC0
#define FDCCMD_READSECTOR		0x80

#define IO_FDC_CYLINDER			0x202
#define IO_FDC_SECTOR			0x204
#define IO_FDC_DATA				0x206

#define IO_FDC_DRIVE_STATUS		0x0208
#define DRIVE_STA_FREADY		0x02

#define IO_FDC_DRIVE_CONTROL	0x0208
#define IO_FDC_DRIVE_SELECT		0x020C

#define IO_1US_WAIT				0x06C

#define IO_DMA_INITIALIZE		0x0A0
#define IO_DMA_CHANNEL			0x0A1
#define IO_DMA_COUNT_LOW		0x0A2
#define IO_DMA_COUNT_HIGH		0x0A3
#define IO_DMA_ADDR_LOW			0x0A4
#define IO_DMA_ADDR_MID_LOW		0x0A5
#define IO_DMA_ADDR_MID_HIGH	0x0A6
#define IO_DMA_ADDR_HIGH		0x0A7
#define IO_DMA_DEVICE_CTRL_LOW	0x0A8
#define IO_DMA_DEVICE_CTRL_HIGH	0x0A9
#define IO_DMA_MODE_CONTROL		0x0AA
#define IO_DMA_STATUS			0x0AB
#define IO_DMA_REQUEST			0x0AE
#define IO_DMA_MASK				0x0AF

struct IDMARK
{
	unsigned char chrn[8]; // CHRN CRC STA
};

int IOErrToColor(unsigned int ioErr)
{
	if(IOERR_RECORD_NOT_FOUND&ioErr)
	{
		return 3; // Pink
	}
	if((IOERR_CRC|IOERR_DELETED_DATA)==(ioErr&(IOERR_CRC|IOERR_DELETED_DATA)))
	{
		return 6; // Yellow (DDM+CRC)
	}
	if(IOERR_CRC&ioErr)
	{
		return 2; // Red (CRC)
	}
	if(IOERR_DELETED_DATA&ioErr)
	{
		return 1; // Blue (DDM)
	}
	if(IOERR_LOST_DATA&ioErr)
	{
		return 5; // Cyan
	}
	if(0!=ioErr)
	{
		return 4; // Unknown Error
	}
	return 7;
}

void AllocDataBuffer(void)
{
	// I need a physical address of a 4KB window.
	// There should be such a window in an 8KB array, 

	for(int offset=0; offset<BUFFER_LENGTH; ++offset)
	{
		DMABufferPhysicalAddr=TO_PHYSICAL(bufferSource+offset);
		if(0==(0x3ff&DMABufferPhysicalAddr))
		{
			DMABuffer=bufferSource+offset;
			break;
		}
	}

	DMABuffer[0]='Y';
	DMABuffer[1]='S';
	printf("Read Buffer Physical Address=%08x\n",DMABufferPhysicalAddr);
}

void Color(int col)
{
	VDB_ATR atr;
	VDB_rddefatr(&atr);
	atr.color=col;
	VDB_setdefatr(&atr);
}

void Wait50ms(void)
{
	// Safe to use clock() for real-time in DOS.
	auto clk0=clock();
	while(clk0<=clock() && clock()<=clk0+CLOCKS_PER_SEC/20)
	{
	}
}

void WaitIndexHole(void)
{
	clock_t clk0=clock();
	unsigned int statusByte=0;
	while(0==(statusByte&FDCSTA_INDEX))
	{
		statusByte=_inp(IO_FDC_STATUS);
		if(clk0+CLOCKS_PER_SEC<clock())
		{
			break;
		}
	}
}

void SelectDrive(void)
{
	_outp(IO_FDC_DRIVE_SELECT,speedByte);
	_outp(IO_1US_WAIT,0);
	_outp(IO_1US_WAIT,0);
	_outp(IO_FDC_DRIVE_SELECT,speedByte|drvSel);
	_outp(IO_1US_WAIT,0);
	_outp(IO_1US_WAIT,0);
}

int CheckDriveReady(void)
{
	SelectDrive();
	_outp(IO_FDC_DRIVE_CONTROL,controlByte);
	for(int i=0; i<10; ++i)
	{
		Wait50ms();
		unsigned int readyByte=GETDRVSTA();
		unsigned int readyBit=(readyByte&DRIVE_STA_FREADY);
		if(0!=readyBit)
		{
			return 1;
		}
		else 
		{
			printf("Status %02xH\n",readyByte);
		}
	}
	return 0;
}

unsigned int WaitFDCReady(void)
{
	unsigned int sta=FDCSTA_BUSY;
	while(0!=(sta&FDCSTA_BUSY))
	{
		sta=GETFDCSTA(); // MX BIOS does  IN AL,DX  twice in a row.  Reason unknown.  I just follow it.
	}
	return sta;
}

void SetUpDMA(unsigned int dataLength)
{
	unsigned char *dataLengthPtr=(unsigned char *)&dataLength;

	_outp(IO_DMA_MODE_CONTROL,0x44); // IO to Mem

	_outp(IO_DMA_COUNT_LOW,dataLengthPtr[0]);
	_outp(IO_DMA_COUNT_HIGH,dataLengthPtr[1]);

	unsigned char *DMABufferPhysicalAddrPtr=(unsigned char *)&DMABufferPhysicalAddr;
	_outp(IO_DMA_ADDR_LOW,DMABufferPhysicalAddrPtr[0]);
	_outp(IO_DMA_ADDR_MID_LOW,DMABufferPhysicalAddrPtr[1]);
	_outp(IO_DMA_ADDR_MID_HIGH,DMABufferPhysicalAddrPtr[2]);
	_outp(IO_DMA_ADDR_HIGH,DMABufferPhysicalAddrPtr[3]);
}

void Restore(void)
{
	WaitFDCReady();
	SelectDrive();
	WaitFDCReady();
	_outp(IO_FDC_DRIVE_CONTROL,controlByte);
	WaitFDCReady();
	_outp(IO_FDC_COMMAND,FDCCMD_RESTORE);
	Wait50ms();
	WaitFDCReady();

	currentCylinder=0;
}

void Seek(unsigned int C)
{
	WaitFDCReady();
	SelectDrive();
	WaitFDCReady();
	_outp(IO_FDC_CYLINDER,currentCylinder);
	_outp(IO_FDC_DATA,C*seekStep);
	WaitFDCReady();
	_outp(IO_FDC_COMMAND,FDCCMD_SEEK);
	Wait50ms();
	unsigned char err=WaitFDCReady();

	if(0x10&err)
	{
		Color(2);
		printf("\n!!!! Seek Error !!!!\n");
		Color(7);
	}

	currentCylinder=C*seekStep;
}



struct CRCErrorLog
{
	struct CRCErrorLog *next;
	struct IDMARK sector;
};
struct CRCErrorLog *crcErrLog=NULL,*crcErrLogTail=NULL;

#define BUFFERSIZE 3200*1024
#define NUM_SECTOR_BUF 160

#define BIOSERR_FLAG_DDM   4
#define BIOSERR_FLAG_CRC   0x10

static int sortSectors=1;

struct D77Header
{
	char diskName[17];             // +0
	char reserveBytes[9];          // +0x11
	unsigned char writeProtected;  // +0x1A
	unsigned char mediaType;       // +0x1B
	unsigned int diskSize;         // +0x1C
	// Must be 0x20 bytes.
};

struct D77SectorHeader
{
	unsigned char C,H,R,N;
	unsigned short numSectorPerTrack;
	unsigned char densityFlag;     // 0:Double Density   0x40 Single Density
	unsigned char DDM;             // 0:Not DDM          0x10:DDM
	unsigned char CRCError;        // 0:No Error         0xB0:CRC Error
	unsigned char reserved[5];
	unsigned short actualSectorLength;
};

void InitializeD77Header(struct D77Header *hdr)
{
	unsigned char *ptr=(unsigned char *)hdr;
	for(int i=0; i<sizeof(struct D77Header); ++i)
	{
		ptr[i]=0;
	}
}

void InitializeD77SectorHeader(struct D77SectorHeader *hdr)
{
	hdr->C=0;
	hdr->H=0;
	hdr->R=0;
	hdr->N=0;
	hdr->numSectorPerTrack=0;
	hdr->densityFlag=0;
	hdr->DDM=0;
	hdr->CRCError=0;
	for(int i=0; i<5; ++i)
	{
		hdr->reserved[i]=0;
	}
	hdr->actualSectorLength=0;
}

enum
{
	MODE_2D,       // 320K
	MODE_2DD,      // 640/720K
	MODE_2HD_1232K,// 1232K
};

#define CTL_CLKSEL 0x20
#define CTL_MOTOR  0x10
#define CTL_SIDE   0x04
#define CTL_MFM    0x02
#define CTL_FM     0x00
#define CTL_IRQEN  0x01

#define SPD_360RPM 0x40
#define SPD_INUSE  0x10

void SetDriveMode(unsigned int drive,unsigned int mode)
{
	drvSel=(1<<(drive&3));
	switch(mode)
	{
	case MODE_2D:
		controlByte=CTL_CLKSEL|CTL_MOTOR;
		speedByte=SPD_INUSE;
		seekStep=2;
		break;
	case MODE_2DD:
		controlByte=CTL_CLKSEL|CTL_MOTOR;
		speedByte=SPD_INUSE;
		seekStep=1;
		break;
	case MODE_2HD_1232K:
		controlByte=CTL_MOTOR;
		speedByte=SPD_360RPM|SPD_INUSE;
		seekStep=1;
		break;
	}
}

int NumberOfCylinders(unsigned int mode)
{
	switch(mode)
	{
	case MODE_2D:
		return 40;
	case MODE_2DD:
		return 80;
	case MODE_2HD_1232K:
		return 77;
	}
	return 0;
}


struct CommandParameterInfo
{
	unsigned char listOnly;
	unsigned int drive;  // 0:A  1:B
	unsigned int mode;
	unsigned int baudRate;
	unsigned int startTrk,endTrk;
	unsigned int firstRetryCount;
	unsigned int secondRetryCount;
	char outFName[512];
};

void UnmaskDMA(void)
{
	unsigned int DMAMask=_inp(IO_DMA_MASK);
	DMAMask&=0x0E; // Unmask chnanel 0
	_outp(IO_DMA_MASK,DMAMask);
}

void MaskDMA(void)
{
	unsigned int DMAMask=_inp(IO_DMA_MASK)&0x0F;
	DMAMask|=1; // Mask chnanel 0
	_outp(IO_DMA_MASK,DMAMask);
}

int ReadAddress(struct IDMARK *idMark)
{
	SetUpDMA(6);
	WaitFDCReady();

	MASKIRQ();
	UnmaskDMA(); // Memo to myself:  DMA needs to be unmasked before writing FDC command, or it will freeze.
	_outp(IO_FDC_COMMAND,FDCCMD_READADDR);
	unsigned int sta=WaitFDCReady();
	MaskDMA();
	UNMASKIRQ();

	idMark->chrn[0]=DMABuffer[0]; // C
	idMark->chrn[1]=DMABuffer[1]; // H
	idMark->chrn[2]=DMABuffer[2]; // R
	idMark->chrn[3]=DMABuffer[3]; // N
	idMark->chrn[4]=DMABuffer[4]; // CRC
	idMark->chrn[5]=DMABuffer[5]; // CRC
	idMark->chrn[6]=sta;
	idMark->chrn[7]=0;

	return sta;
}

/*! Returns the BIOS error code.
*/
int ReadSector(struct D77SectorHeader *sectorHdr,unsigned char dataBuf[],unsigned int C,unsigned int H,unsigned int R,unsigned int N)
{
	SelectDrive();

	InitializeD77SectorHeader(sectorHdr);

	sectorHdr->C=C;
	sectorHdr->H=H;
	sectorHdr->R=R;
	sectorHdr->N=N;

	sectorHdr->numSectorPerTrack=0; // Tentative.  Should be updated later.

	sectorHdr->densityFlag=0;     // 0:Double Density   0x40 Single Density
	sectorHdr->actualSectorLength=(128<<(N&3));

	_outp(IO_FDC_CYLINDER,C);
	_outp(IO_FDC_SECTOR,R);

	SetUpDMA(128<<(N&3));
	for(int i=0; i<(128<<(N&3)); ++i)
	{
		DMABuffer[i]=0xF7;
	}
	WaitFDCReady();

	MASKIRQ();
	UnmaskDMA();
	_outp(IO_FDC_COMMAND,FDCCMD_READSECTOR);
	unsigned int sta=WaitFDCReady();
	MaskDMA();
	UNMASKIRQ();

	if(sta&IOERR_CRC)
	{
		sectorHdr->CRCError=0xB0;
	}
	if(sta&IOERR_RECORD_NOT_FOUND)
	{
		sectorHdr->CRCError=0xF0;
	}
	if(sta&IOERR_DELETED_DATA)
	{
		sectorHdr->DDM=0x10;
	}

	for(i=0; i<(128<<N); ++i)
	{
		dataBuf[i]=DMABuffer[i];
	}

	return sta;
}

void FormatSectorStatus(char str[4],struct D77SectorHeader *sectorHdr)
{
	str[0]=0;
	if(0x10==sectorHdr->DDM)
	{
		strcat(str,"D");
	}
	if(0xB0==sectorHdr->CRCError)
	{
		strcat(str,"C");
	}
	while(strlen(str)<3)
	{
		strcat(str," ");
	}
}

unsigned int ReadTrack(
   int devNo,int track,int side,struct CommandParameterInfo *cpi,unsigned char d77Image[],struct D77Header *hdr,unsigned int trackTable[],unsigned char *nextTrackData)
{
	int FMorMFM=CTL_MFM;

	Color(4);
	printf("C:%-2d H:%d ",track,side);
	Color(7);

	Seek(track);
	WaitIndexHole(); // Need to be immediately after seek.

	_outp(IO_DMA_INITIALIZE,3);  // 16bit, Reset
	_outp(IO_DMA_CHANNEL,0);
	_outp(IO_DMA_DEVICE_CTRL_LOW,0x20); // Enable DMA

	SelectDrive();

	int i;
	int nTrackSector=0;
	struct IDMARK idMark[NUM_SECTOR_BUF];
	// 1 second=5 revolutions for 2D/2DD, 6 revolutions for 2HD

	int mfmTry;
	for(mfmTry=0; mfmTry<2; ++mfmTry)
	{
		_outp(IO_FDC_DRIVE_CONTROL,controlByte|(0!=side ? CTL_SIDE : 0)|FMorMFM);

		time_t t0=time(NULL);
		for(i=0; i<NUM_SECTOR_BUF && time(NULL)<t0+3; ++i)
		{
			if(0==ReadAddress(&idMark[nTrackSector]))
			{
				++nTrackSector;
			}
		}
		if(0<nTrackSector)
		{
			break;
		}
		else
		{
			// Unformat?  Or mayby FM codec.  (C0 H0 of FM OASYS disks are formatted in FM)
			// Will take loooong time until switch, but be patient.
			FMorMFM=CTL_FM;
		}
	}

	// Remove Duplicates >>
	for(i=nTrackSector-1; 0<i; --i)
	{
		int j;
		for(j=i-1; 0<=j; --j)
		{
			if(idMark[i].chrn[0]==idMark[j].chrn[0] &&
			   idMark[i].chrn[1]==idMark[j].chrn[1] &&
			   idMark[i].chrn[2]==idMark[j].chrn[2] &&
			   idMark[i].chrn[3]==idMark[j].chrn[3])
			{
				idMark[i]=idMark[nTrackSector-1];
				--nTrackSector;
				break;
			}
		}
	}
	// Remove Duplicates <<


	// Sort sectors >>
	if(sortSectors)
	{
		for(int i=0; i<nTrackSector; ++i)
		{
			for(int j=i+1; j<nTrackSector; ++j)
			{
				if(idMark[i].chrn[2]>idMark[j].chrn[2])
				{
					struct IDMARK tmp=idMark[i];
					idMark[i]=idMark[j];
					idMark[j]=tmp;
				}
			}
		}
	}
	// Sort sectors <<


	trackTable[track*2+side]=(nextTrackData-d77Image);


	unsigned char *trackDataPtr=nextTrackData;
	int nActual=0;
	for(i=0; i<nTrackSector; ++i)
	{
		int retry,ioErr=0;
		// Strategy:  First retry up to firstRetryCount and if no error, take it.
		//            If finally it has a CRC error, always read secondRetryCount times.  Maybe a sign of KOROKORO-protect.
		for(retry=0; retry<cpi->firstRetryCount; ++retry)
		{
			struct D77SectorHeader *sectorHdr=(struct D77SectorHeader *)trackDataPtr;
			unsigned char *dataBuf=(unsigned char *)(sectorHdr+1);
			ioErr=ReadSector(sectorHdr,dataBuf,idMark[i].chrn[0],idMark[i].chrn[1],idMark[i].chrn[2],idMark[i].chrn[3]);

			if(FMorMFM==CTL_FM)
			{
				sectorHdr->densityFlag=0x40;
			}

			if(0==(ioErr&IOERR_CRC)) // No retry if no CRC error.
			{
				Color(IOErrToColor(ioErr));
				printf("%02x%02x%02x%02x ",idMark[i].chrn[0],idMark[i].chrn[1],idMark[i].chrn[2],idMark[i].chrn[3]);
				if(5==((nActual+1)%6))
				{
					printf("\n");
				}

				trackDataPtr+=sizeof(struct D77SectorHeader)+sectorHdr->actualSectorLength;
				++nActual;
				break;
			}
		}

		if(0!=(ioErr&IOERR_CRC))  // If finally I couldn't read without CRC error.
		{
			struct CRCErrorLog *newLog=(struct CRCErrorLog *)malloc(sizeof(struct CRCErrorLog));
			if(NULL!=newLog)
			{
				newLog->next=NULL;
				newLog->sector=idMark[i];
				if(NULL==crcErrLog)
				{
					crcErrLog=newLog;
					crcErrLogTail=newLog;
				}
				else
				{
					crcErrLogTail->next=newLog;
					crcErrLogTail=newLog;
				}
			}

			for(retry=0; retry<cpi->secondRetryCount; ++retry)
			{
				struct D77SectorHeader *sectorHdr=(struct D77SectorHeader *)trackDataPtr;
				unsigned char *dataBuf=(unsigned char *)(sectorHdr+1);
				ioErr=ReadSector(sectorHdr,dataBuf,idMark[i].chrn[0],idMark[i].chrn[1],idMark[i].chrn[2],idMark[i].chrn[3]);

				Color(IOErrToColor(ioErr));
				printf("%02x%02x%02x%02x ",idMark[i].chrn[0],idMark[i].chrn[1],idMark[i].chrn[2],idMark[i].chrn[3]);

				if(5==((nActual+1)%6))
				{
					printf("\n");
				}

				trackDataPtr+=sizeof(struct D77SectorHeader)+sectorHdr->actualSectorLength;
				++nActual;
			}
		}
	}
	if(0!=(nActual+1)%6)
	{
		printf("\n");
	}

	unsigned char *updatePtr=nextTrackData;
	for(i=0; i<nActual; ++i)
	{
		struct D77SectorHeader *sectorHdr=(struct D77SectorHeader *)updatePtr;
		sectorHdr->numSectorPerTrack=nActual;
		updatePtr+=sizeof(struct D77SectorHeader)+sectorHdr->actualSectorLength;
	}

	if(updatePtr!=trackDataPtr)
	{
		Color(2);
		fprintf(stderr,"Something Went Wrong in ReadTrack\n");
		fprintf(stderr,"  trackDataPtr:%08x\n",trackDataPtr);
		fprintf(stderr,"  updatePtr   :%08x\n",updatePtr);
	}

	Color(7);

	_outp(IO_FDC_DRIVE_CONTROL,controlByte|(0!=side ? CTL_SIDE : 0)|CTL_MFM);

	return trackDataPtr-nextTrackData;
}

int CheckDiskMediaType(unsigned int driveStatus,unsigned int mediaType)
{
	printf("Media Status:%02x\n",driveStatus);

	printf("BIOS Detected:\n");
	switch(driveStatus&0x30)
	{
	case 0x10:
		printf("2D or 2DD disk\n");
		break;
	case 0x00:
		printf("2HD disk\n");
		break;
	default:
		printf("Unsupported disk type.\n");
		return -1;
	}

	if(0==(driveStatus&0x80))
	{
		printf("MFM (double density) mode.\n");
	}
	else
	{
		printf("FM (single density) mode.\n");
	}

	if((driveStatus&0x30)==0 && mediaType!=MODE_2HD_1232K)
	{
		return -1;
	}
	if((driveStatus&0x30)==0x10 && (mediaType!=MODE_2D && mediaType!=MODE_2DD))
	{
		return -1;
	}
	return 0;
}

int ReadDisk(struct CommandParameterInfo *cpi,unsigned char d77Image[])
{
	int i;
	unsigned int devNo;

	struct D77Header *d77HeaderPtr=(struct D77Header *)d77Image;
	unsigned int *trackTable=(unsigned int *)(d77Image+0x20);

	InitializeD77Header(d77HeaderPtr);

	for(i=0; i<164; ++i)
	{
		trackTable[i]=0;
	}

	unsigned char *trackData=(unsigned char *)(trackTable+164);


	SetDriveMode(cpi->drive,cpi->mode);
	if(0==CheckDriveReady())
	{
		fprintf(stderr,"Drive Not Ready.\n");
		return -1;
	}

	Restore();


	cpi->drive&=0x0F;
	devNo=0x20|cpi->drive;

	unsigned int driveStatus;
	int biosError;
	if(0!=(biosError=DKB_rdstatus(devNo,&driveStatus)))
	{
		fprintf(stderr,"Cannot get the drive status.\n");
		fprintf(stderr,"  Bios Error Code 0x%02x\n",biosError);
		return -1;
	}



	int track;
	for(track=cpi->startTrk; track<=cpi->endTrk; ++track)
	{
		Seek(track);
		trackData+=ReadTrack(devNo,track,0,cpi,d77Image,d77HeaderPtr,trackTable,trackData);
		trackData+=ReadTrack(devNo,track,1,cpi,d77Image,d77HeaderPtr,trackTable,trackData);
	}
	d77HeaderPtr->diskSize=(trackData-d77Image);


	if(NULL!=crcErrLog)
	{
		printf("CRC Error Summary\n");
		int nCRCError=0,nCRCErrorNotF5F6F7=0;;
		struct CRCErrorLog *ptr;
		for(ptr=crcErrLog; NULL!=ptr; ptr=ptr->next)
		{
			printf("CRC Err at Track:%d  Side:%d  Sector:%d\n",ptr->sector.chrn[0],ptr->sector.chrn[1],ptr->sector.chrn[2]);
			if(0xF5!=ptr->sector.chrn[2] && 0xF6!=ptr->sector.chrn[2] && 0xF7!=ptr->sector.chrn[2])
			{
				++nCRCErrorNotF5F6F7;
			}
			++nCRCError;
		}
		printf("%d CRC Errors.\n",nCRCError);
		printf("%d CRC Errors in not F5,F6,F7 sectors.\n",nCRCErrorNotF5F6F7);
	}
	else
	{
		printf("No CRC Error.\n");
	}


	printf("D77 Image Size=%d bytes\n",d77HeaderPtr->diskSize);


	return d77HeaderPtr->diskSize;
}

void InitializeCommandParameterInfo(struct CommandParameterInfo *cpi)
{
	cpi->listOnly=0;
	cpi->drive=0;
	cpi->mode=MODE_2HD_1232K;
	cpi->baudRate=0;
	cpi->outFName[0]=0;
	cpi->firstRetryCount=8;
	cpi->secondRetryCount=3;
}

int RecognizeCommandParameter(struct CommandParameterInfo *cpi,struct D77Header *hdr,int ac,char *av[])
{
	if(ac<3)
	{
		return -1;
	}

	// ac is supposed to be minimum 3.
	cpi->drive=av[1][0];
	if('A'<=cpi->drive && cpi->drive<='Z')
	{
		cpi->drive-='A';
	}
	else if('a'<=cpi->drive && cpi->drive<='z')
	{
		cpi->drive-='a';
	}
	if(4<=cpi->drive || ':'!=av[1][1])
	{
		fprintf(stderr,"Error!  Invalid drive.\n");
		return -1;
	}

	if(0==strcmp(av[2],"2D") || 0==strcmp(av[2],"2d") ||
	   0==strcmp(av[2],"320KB") || 0==strcmp(av[2],"320kb"))
	{
		cpi->mode=MODE_2D;
		cpi->startTrk=0;
		cpi->endTrk=39;
		hdr->mediaType=0;
	}
	else if(0==strcmp(av[2],"2DD") || 0==strcmp(av[2],"2dd") ||
	        0==strcmp(av[2],"640KB") || 0==strcmp(av[2],"640kb") ||
	        0==strcmp(av[2],"720KB") || 0==strcmp(av[2],"720kb"))
	{
		cpi->mode=MODE_2DD;
		cpi->startTrk=0;
		cpi->endTrk=79;
		hdr->mediaType=0x10;
	}
	else if(0==strcmp(av[2],"2HD") || 0==strcmp(av[2],"2hd") ||
	        0==strcmp(av[2],"1232KB") || 0==strcmp(av[2],"1232kb"))
	{
		cpi->mode=MODE_2HD_1232K;
		cpi->startTrk=0;
		cpi->endTrk=76;
		hdr->mediaType=0x20;
	}
	else
	{
		fprintf(stderr,"Unknown media type %s\n",av[2]);
		return -1;
	}

	for(int i=3; i<ac; ++i)
	{
		if(0==strcmp(av[i],"-STARTTRK") || 0==strcmp(av[i],"-starttrk"))
		{
			if(i+1<ac)
			{
				cpi->startTrk=atoi(av[i+1]);
				++i;
			}
			else
			{
				fprintf(stderr,"Too few arguments for %s\n",av[i]);
				return -1;
			}
		}
		else if(0==strcmp(av[i],"-ENDTRK") || 0==strcmp(av[i],"-endtrk"))
		{
			if(i+1<ac)
			{
				cpi->endTrk=atoi(av[i+1]);
				++i;
			}
			else
			{
				fprintf(stderr,"Too few arguments for %s\n",av[i]);
				return -1;
			}
		}
		else if(0==strcmp(av[i],"-LISTONLY") || 0==strcmp(av[i],"-listonly"))
		{
			cpi->listOnly=1;
			printf("List-Only Mode.\n");
		}
		else if(0==strcmp(av[i],"-OUT") || 0==strcmp(av[i],"-out"))
		{
			if(i+1<ac)
			{
				strcpy(cpi->outFName,av[i+1]);
				++i;
			}
			else
			{
				fprintf(stderr,"Too few arguments for %s\n",av[i]);
				return -1;
			}
		}
		else if(0==strcmp(av[i],"-19200BPS") || 0==strcmp(av[i],"-19200bps"))
		{
			cpi->baudRate=19200;
		}
		else if(0==strcmp(av[i],"-38400BPS") || 0==strcmp(av[i],"-38400bps"))
		{
			cpi->baudRate=38400;
		}
		else if(0==strcmp(av[i],"-NAME") || 0==strcmp(av[i],"-name"))
		{
			if(i+1<ac)
			{
				strncpy(hdr->diskName,av[i+1],17);
				++i;
			}
			else
			{
				fprintf(stderr,"Too few arguments for %s\n",av[i]);
				return -1;
			}
		}
		else if(0==strcmp(av[i],"-WRITEPROTECT") || 0==strcmp(av[i],"-writeprotect"))
		{
			hdr->writeProtected=1;
		}
		else if(0==strcmp(av[i],"-dontsort") || 0==strcmp(av[i],"-DONTSORT"))
		{
			sortSectors=0;
		}
		else
		{
			fprintf(stderr,"Unknown option %s\n",av[i]);
			return -1;
		}
	}

	return 0;
}

int main(int ac,char *av[])
{
	AllocDataBuffer();


	unsigned char *d77Image=(unsigned char *)malloc(BUFFERSIZE);
	if(NULL==d77Image)
	{
		printf("Out of memory.\n");
		printf("Cannot allocate memory for making D77 image.\n");
		printf("The program requires minimum 4MB RAM.\n");
		return 0;
	}
	struct D77Header *hdr=(struct D77Header *)d77Image;


	struct CommandParameterInfo cpi;
	InitializeCommandParameterInfo(&cpi);
	if(ac<3 || 0!=RecognizeCommandParameter(&cpi,hdr,ac,av))
	{
		printf("Make D77 file and send to RS232C via XMODEM\n");
		printf("  by CaptainYS\n");
		printf("Usage:\n");
		printf("  RUN386 MAKED77 A: 1232KB [options]\n");
		printf("    A:      Drive\n");
		printf("    1232KB  Disk Type\n");
		printf("  Disk Type can be one of:\n");
		printf("    2D,320KB         2D Disk (from FM-7)\n");
		printf("    2DD,640KB,720KB  2DD Disk\n");
		printf("    2HD,1232KB       2HD 1232K Disk\n");
		printf("    (1440KB not supported at this time.\n");
		printf("  Options:\n");
		printf("    -starttrk trackNum  Start track (Between 0 and 76 if 2HD)\n");
		printf("    -endtrk   trackNum  End track (Between 0 and 76 if 2HD)\n");
		printf("    -listonly           List track info only.  No RS232C transmission\n");
		printf("    -out filename.d77   Save image to .d77 file.\n");
		printf("    -19200bps           Transmit the image at 19200bps\n");
		printf("    -38400bps           Transmit the image at 38400bps\n");
		printf("    -name diskName      Specify disk name up to 16 chars.\n");
		printf("    -writeprotect       Write protect the disk image.\n");
		printf("    -dontsort           Don't sort sectors (preserve interleave).\n");
		return 1;
	}

	if(0==cpi.listOnly && 0==cpi.baudRate && 0==cpi.outFName[0])
	{
		fprintf(stderr,"No output is specified.\n");
		fprintf(stderr,"Specify baud rate for XMODEM transfer or output file name.\n");
		return 1;
	}


	int d77Size=ReadDisk(&cpi,d77Image);


	if(d77Size<0)
	{
		fprintf(stderr,"Disk Read Error.\n");
		return 1;
	}
	if(0==cpi.listOnly)
	{
		if(0!=cpi.outFName[0])
		{
			FILE *fp=fopen(cpi.outFName,"wb");
			if(NULL!=fp)
			{
				fwrite(d77Image,1,d77Size,fp);
				fclose(fp);
				printf("Saved to %s\n",cpi.outFName);
			}
			else
			{
				fprintf(stderr,"Cannot open outputu file.\n");
			}
		}
		if(0!=cpi.baudRate)
		{
			// Force it to be 128xN.  XMODEM's limitation.
			d77Size=((d77Size+127)&~127);
			struct D77Header *d77HeaderPtr=(struct D77Header *)d77Image;
			d77HeaderPtr->diskSize=d77Size;

			int baud=(cpi.baudRate==38400 ? 2 : 4);
			XModemSend(d77Size,d77Image,baud);
		}
	}

	return 0;
}
