// For Open Watcom C
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dos.h>
#include <conio.h>
#include <signal.h>

// Output Data Data Format (.TD1)
// Begin Disk
// 00 00 wp mt 00 00 00 00 00 00 00 00 00 00 00 00 (16 bytes)
// (32 bytes name, 0 padded
//    wp  0 write enabled  1 write protected
//    mt  media type
// Begin Track
// 01 00 cc hh 00 00 00 00 00 00 00 00 00 00 00 00 (16 bytes)
// ID Mark
// 02 00 cc hh rr nn <CRC> 00 00 00 00 00 00 00 00
// 02 00 cc hh rr nn <CRC> 00 00 00 00 00 00 00 00
// 02 00 cc hh rr nn <CRC> 00 00 00 00 00 00 00 00
//     :
// Data
// 03 00 cc hh rr nn st 00 00 00 <time><Real Size>
// (Bytes padded to 16*N bytes)
// Track Read
// 04 00 00 00 00 00 00 00 00 00 00 00 <Real Size>
// (Bytes padded to 16*N bytes)

// Next Track


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

#define IO_PIC0_IRR				0x00
#define IO_PIC0_OCW3			0x00
#define IRR_FDC					0x40

#define IO_FDC_COMMAND			0x200
#define FDCCMD_RESTORE			0x08
#define FDCCMD_SEEK				0x18
#define FDCCMD_READADDR			0xC0
#define FDCCMD_READSECTOR		0x80
#define FDCCMD_FORCEINTERRUPT	0xD0

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

#define IO_FUNCTION_ID			0x24

#define TSUGARU_DEBUGBREAK				outp(0x2386,2);

enum
{
	MODE_2D,       // 320K
	MODE_2DD,      // 640/720K
	MODE_2HD_1232K,// 1232K
	MODE_2HD_1440K,// 1440K
};

#define CTL_CLKSEL 0x20
#define CTL_MOTOR  0x10
#define CTL_SIDE   0x04
#define CTL_MFM    0x02
#define CTL_IRQEN  0x01

#define SPD_MODE_B 0x80
#define SPD_360RPM 0x40
#define SPD_INUSE  0x10

#define FDC_INT	0x46

volatile unsigned char INT46_DID_COME_IN=0;

void interrupt (*Default_INT46H_Handler)(void);

void interrupt Handle_INT46H(void)
{
	INT46_DID_COME_IN=1;
}

void CtrlC(int err)
{
	_dos_setvect(FDC_INT,Default_INT46H_Handler);
	printf("Intercepted Ctrl+C\n");
	exit(1);
}


// Watcom C inline assembly
void STI();
#pragma aux STI="sti";

void CLI();
#pragma aux CLI="cli";

////////////////////////////////////////////////////////////
// Console

struct VDB_ATR
{
	unsigned char chr;
	unsigned char disp;
	unsigned short color;
};
void VDB_rddefatr(struct VDB_ATR *atr);
#pragma aux VDB_rddefatr=\
"push ax" \
"mov ah,12h\n" \
"int 91h\n" \
"pop ax" \
parm[di]\

void VDB_setdefatr(struct VDB_ATR *atr);
#pragma aux VDB_setdefatr=\
"push ax" \
"mov ah,11h\n" \
"int 91h\n" \
"pop ax" \
parm[di]\

void Color(unsigned int c)
{
	struct VDB_ATR atr;
	VDB_rddefatr(&atr);
	atr.color=c;
	VDB_setdefatr(&atr);
}

////////////////////////////////////////////////////////////
// Disk
void SetDriveMode(unsigned int drive,unsigned int mode)
{
	drvSel=(1<<(drive&3));
	switch(mode)
	{
	case MODE_2D:
		controlByte=CTL_CLKSEL|CTL_MOTOR|CTL_IRQEN;
		speedByte=SPD_INUSE;
		seekStep=2;
		break;
	case MODE_2DD:
		controlByte=CTL_CLKSEL|CTL_MOTOR|CTL_IRQEN;
		speedByte=SPD_INUSE;
		seekStep=1;
		break;
	case MODE_2HD_1232K:
		controlByte=CTL_MOTOR|CTL_IRQEN;
		speedByte=SPD_360RPM|SPD_INUSE;
		seekStep=1;
		break;
	case MODE_2HD_1440K:
		controlByte=CTL_MOTOR|CTL_IRQEN;
		speedByte=SPD_MODE_B|SPD_360RPM|SPD_INUSE;
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
	case MODE_2HD_1440K:
		return 80;
	}
	return 0;
}

void SelectDrive(void)
{
	outp(IO_FDC_DRIVE_SELECT,speedByte);
	outp(IO_1US_WAIT,0);
	outp(IO_1US_WAIT,0);
	outp(IO_FDC_DRIVE_SELECT,speedByte|drvSel);
	outp(IO_1US_WAIT,0);
	outp(IO_1US_WAIT,0);

	outp(IO_FDC_DRIVE_CONTROL,controlByte);
}

int CheckDriveReady(void)
{
	int i;
	const int nRepeat=500;
	SelectDrive();
	for(i=0; i<nRepeat; ++i)
	{
		unsigned int readyByte,readyBit;
		readyByte=inp(IO_FDC_DRIVE_STATUS);
		readyBit=(readyByte&DRIVE_STA_FREADY);
		if(0!=readyBit)
		{
			return 1;
		}
		else if(i+1==nRepeat)
		{
			printf("Status %02xH\n",readyByte);
		}
	}
	return 0;
}


////////////////////////////////////////////////////////////

struct CommandParameterInfo
{
	unsigned char listOnly;
	unsigned char drive;  // 0:A  1:B
	unsigned int mode;
	unsigned int baudRate;
	unsigned int startTrk,endTrk;
	unsigned char firstRetryCount;
	unsigned char secondRetryCount;
	unsigned char mediaType;
	unsigned char writeProtect;
	unsigned char sortSectors;
	char diskName[32];
	char outFName[512];
};

void InitializeCommandParameterInfo(struct CommandParameterInfo *cpi)
{
	int i;
	cpi->listOnly=0;
	cpi->drive=0;
	cpi->mode=MODE_2HD_1232K;
	cpi->baudRate=0;
	cpi->outFName[0]=0;
	cpi->firstRetryCount=8;
	cpi->secondRetryCount=12;
	cpi->writeProtect=0;
	cpi->mediaType=0;
	cpi->sortSectors=0;
	for(i=0; i<32; ++i)
	{
		cpi->diskName[i]=0;
	}
	cpi->outFName[0]=0;
}

int RecognizeCommandParameter(struct CommandParameterInfo *cpi,int ac,char *av[])
{
	int i;

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
		cpi->mediaType=0;
	}
	else if(0==strcmp(av[2],"2DD") || 0==strcmp(av[2],"2dd") ||
	        0==strcmp(av[2],"640KB") || 0==strcmp(av[2],"640kb") ||
	        0==strcmp(av[2],"720KB") || 0==strcmp(av[2],"720kb"))
	{
		cpi->mode=MODE_2DD;
		cpi->startTrk=0;
		cpi->endTrk=79;
		cpi->mediaType=0x10;
	}
	else if(0==strcmp(av[2],"2HD") || 0==strcmp(av[2],"2hd") ||
	        0==strcmp(av[2],"1232KB") || 0==strcmp(av[2],"1232kb"))
	{
		cpi->mode=MODE_2HD_1232K;
		cpi->startTrk=0;
		cpi->endTrk=76;
		cpi->mediaType=0x20;
	}
	else
	{
		fprintf(stderr,"Unknown media type %s\n",av[2]);
		return -1;
	}

	for(i=3; i<ac; ++i)
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
				strncpy(cpi->diskName,av[i+1],32);
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
			cpi->writeProtect=1;
		}
		else if(0==strcmp(av[i],"-dontsort") || 0==strcmp(av[i],"-DONTSORT"))
		{
			cpi->sortSectors=0;
		}
		else
		{
			fprintf(stderr,"Unknown option %s\n",av[i]);
			return -1;
		}
	}

	return 0;
}

void ReadDisk(struct CommandParameterInfo *cpi)
{
}

unsigned char FreeRunTimerAvailable(void)
{
	unsigned char flags=inp(IO_FUNCTION_ID);
	return (0==(flags&0x10));
}

int main(int ac,char *av[])
{
	struct CommandParameterInfo cpi;
	InitializeCommandParameterInfo(&cpi);
	if(ac<3 || 0!=RecognizeCommandParameter(&cpi,ac,av))
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
		//printf("    -19200bps           Transmit the image at 19200bps\n");
		//printf("    -38400bps           Transmit the image at 38400bps\n");
		printf("    -name diskName      Specify disk name up to 16 chars.\n");
		//printf("    -writeprotect       Write protect the disk image.\n");
		printf("    -dontsort           Don't sort sectors (preserve interleave).\n");
		return 1;
	}

	Default_INT46H_Handler=_dos_getvect(FDC_INT);
	_dos_setvect(FDC_INT,Handle_INT46H);
	signal(SIGINT,CtrlC);

	if(0==FreeRunTimerAvailable())
	{
		Color(2);
		printf("This program requires Free-Run timer.\n");
		printf("Needs to be FM TOWNS 2 UG or newer.\n");
		Color(7);
		return 1;
	}

	SetDriveMode(cpi.drive,cpi.mode);

	if(0==CheckDriveReady())
	{
		Color(2);
		printf("Drive Not Ready.\n");
		Color(7);
		return 1;
	}

	TSUGARU_DEBUGBREAK;

	Color(4);
	printf("Green\n");

	TSUGARU_DEBUGBREAK;

	Color(7);
	printf("White\n");


	return 0;
}
