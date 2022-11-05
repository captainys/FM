// For Open Watcom C
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
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

unsigned char far *trackBuf=NULL;
#define DMABUF_SIZE (20*1024)
unsigned char DMABuf[DMABUF_SIZE]="DMABUFFER";


struct IDMARK
{
	unsigned char chrn[8]; // CHRN CRC STA
};
#define IDBUF_SIZE 160
struct IDMARK idMark[IDBUF_SIZE];

#define ERRORLOG_TYPE_NONE	0
#define ERRORLOG_TYPE_CRC	1
#define ERRORLOG_TYPE_RECORD_NOT_FOUND	2
#define ERRORLOG_TYPE_LOSTDATA	3
struct ErrorLog
{
	struct ErrorLog *next;
	unsigned char errType;
	unsigned char CHRN[4];
};
struct ErrorLog far *errLog=NULL,*errLogTail=NULL;

#define IO_FDC_STATUS			0x200
#define FDCSTA_BUSY				0x01
#define FDCSTA_INDEX			0x02

#define IOERR_CRC 8
#define IOERR_RECORD_NOT_FOUND 0x10
#define IOERR_DELETED_DATA     0x20
#define IOERR_LOST_DATA			0x04

#define IO_PIC0_IRR				0x00
#define IO_PIC0_ISR				0x00
#define IO_PIC0_OCW2			0x00	// bit 3 & 4 zero
#define IO_PIC0_OCW3			0x00	// bit 3=1, bit4=0
#define IRR_FDC					0x40

#define IO_FDC_COMMAND			0x200
#define FDCCMD_RESTORE_HEAD_UNLOAD  0x00
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

#define IO_FREERUN_TIMER		0x26

#define TSUGARU_DEBUGBREAK				outp(0x2386,2);

#define READADDR_TIMEOUT		1000000
#define READADDR_TRACK_TIMEOUT  3000000

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
volatile unsigned char lastFDCStatus=0;

void interrupt (*Default_INT46H_Handler)(void);


void Palette(unsigned char code,unsigned char r,unsigned char g,unsigned char b)
{
	outp(0xFD90,code);
	outp(0xFD92,b&0xF0);
	outp(0xFD94,r&0xF0);
	outp(0xFD96,g&0xF0);
}


// Watcom C inline assembly
void STI();
#pragma aux STI="sti";

void CLI();
#pragma aux CLI="cli";

void interrupt Handle_INT46H(void)
{
	Palette(7,255,0,0);

	INT46_DID_COME_IN=1;

//03A4:00000D9B 68FD0C                    PUSH    WORD PTR 0CFDH
//03A4:00000D9E 1F                        POP     DS
//03A4:00000D9F A05704                    MOV     AL,[0457H]  Drive?
//03A4:00000DA2 E8A0F7                    CALL    00000545
//	03A4:00000545 B402                      MOV     AH,02H
//	03A4:00000547 F6E4                      MUL     AH
//	03A4:00000549 05D204                    ADD     AX,04D2H
//	03A4:0000054C 8BF8                      MOV     DI,AX
//	03A4:0000054E 8B35                      MOV     SI,[DI]
//	03A4:00000550 C3                        RET
//03A4:00000DA5 E895FE                    CALL    00000C3D
//	03A4:00000C3D E8A6FF                    CALL    00000BE6
//		03A4:00000BE6 BA0002                    MOV     DX,0200H
//		03A4:00000BE9 EC                        IN      AL,DX
//		03A4:00000BEA C3                        RET
//	03A4:00000C40 32E4                      XOR     AH,AH
//	03A4:00000C42 A35304                    MOV     [0453H],AX
//	03A4:00000C45 C606870400                MOV     BYTE PTR [0487H],00H
//	03A4:00000C4A BA0002                    MOV     DX,0200H
//	03A4:00000C4D B0D0                      MOV     AL,D0H
//	03A4:00000C4F EE                        OUT     DX,AL
//	03A4:00000C50 9C                        PUSHF
//	03A4:00000C51 FA                        CLI    Is it necessary?
//	03A4:00000C52 E89100                    CALL    00000CE6
//		03A4:00000CE6 E4AF                      IN      AL,AFH (DMAC_MASK)
//		03A4:00000CE8 0C01                      OR      AL,01H
//		03A4:00000CEA E6AF                      OUT     AFH,AL (DMAC_MASK)
//		03A4:00000CEC C3                        RET
//	03A4:00000C55 9D                        POPF
//	03A4:00000C56 C3                        RET
//03A4:00000DA8 CB                        RETF

	lastFDCStatus=inp(IO_FDC_STATUS);
	outp(IO_FDC_COMMAND,FDCCMD_FORCEINTERRUPT);

	CLI(); // Is it necessary?
	outp(IO_DMA_MASK,inp(IO_DMA_MASK)|1);

	inp(IO_FDC_STATUS); // Dummy read so that Force Interrupt won't cause indefinite IRQ.
	inp(IO_DMA_STATUS); // BIOS Dummy reads

	outp(IO_PIC0_OCW2,0x66); // Specific End Of Interrupt, Level=6

	Palette(7,255,255,255);
}

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

void CtrlC(int err)
{
	Color(7);
	_dos_setvect(FDC_INT,Default_INT46H_Handler);
	printf("Intercepted Ctrl+C\n");
	exit(1);
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

void Wait10ms(void)
{
	uint16_t t0,accum=0;
	t0=inpw(IO_FREERUN_TIMER);
	while(accum<10000)
	{
		uint16_t t,diff;
		t=inpw(IO_FREERUN_TIMER);
		diff=t-t0;
		accum+=diff;
		t0=t;
	}
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

uint32_t FDC_WaitReady(void)
{
	uint32_t accum=0;
	uint16_t t0,t,diff;
	t0=inpw(IO_FREERUN_TIMER);
	while(inp(IO_FDC_STATUS)&FDCSTA_BUSY)
	{
		t=inpw(IO_FREERUN_TIMER);
		diff=t-t0;
		accum+=diff;
		t0=t;
	}
	return accum;
}

void FDC_WaitIndexHole(void)
{
	unsigned int statusByte;

	CLI();

	outp(IO_FDC_COMMAND,FDCCMD_FORCEINTERRUPT);
	FDC_WaitReady();
	statusByte=0;
	while(0==(statusByte&FDCSTA_INDEX))
	{
		statusByte=inp(IO_FDC_STATUS); // This read will clear IRR.
	}

	STI();
}

// A1  Channel
// A2  Count
// AA  Mode/Control
void SetUpDMA(unsigned char *DMABuf,unsigned int count);
#pragma aux SetUpDMA=\
"pushf"\
"cli"\
"xor  al,al"\
"out  0A1h,al"\
"push dx"\
"mov  ax,cx"\
"mov  cx,ds"\
"xor  dx,dx"\
"shl  cx,1"\
"rcl  dx,1"\
"shl  cx,1"\
"rcl  dx,1"\
"shl  cx,1"\
"rcl  dx,1"\
"shl  cx,1"\
"rcl  dx,1"\
"add  ax,cx"\
"adc  dx,0"\
"out  0A4h,ax"\
"mov  al,dl"\
"out  0A6h,al"\
"mov  al,dh"\
"out  0A7h,al"\
"in   al,0afh"\
"and  al,0feh"\
"out  0afh,al"\
"pop  ax"\
"dec  ax"\
"out  0A2h,ax"\
"mov  al,44h"\
"out  0AAh,al"\
"popf"\
parm [ cx ] [ dx ] \
modify[ dx cx ]


unsigned char FDC_Restore(void)
{
	CLI();
	INT46_DID_COME_IN=0;

	FDC_WaitReady();
	STI();
	outp(IO_FDC_COMMAND,FDCCMD_RESTORE);
	while(0==INT46_DID_COME_IN)
	{
	}
	STI();

	currentCylinder=0;
	printf("RESTORE Returned %02x\n",lastFDCStatus);

	return (lastFDCStatus&~FDCSTA_BUSY);
}

unsigned char FDC_Seek(unsigned char C)
{
	Palette(7,0,0,255);

	FDC_WaitReady();
	outp(IO_FDC_CYLINDER,currentCylinder);
	outp(IO_FDC_DATA,C*seekStep);

	CLI();
	INT46_DID_COME_IN=0;

	Palette(7,0,255,0);

	FDC_WaitReady();

	Palette(7,255,0,0);

	STI();
	outp(IO_FDC_COMMAND,FDCCMD_SEEK);
	while(0==INT46_DID_COME_IN)
	{
		Palette(7,rand(),rand(),rand());
	}
	STI();

	Palette(7,255,255,255);

	if(0x10&lastFDCStatus)
	{
		Color(2);
		printf("\n!!!! Seek Error !!!!\n");
		Color(7);
	}

	return (lastFDCStatus&~FDCSTA_BUSY);
}

unsigned char FDC_ReadAddress(uint32_t *accumTime)
{
	uint16_t t0,t,diff;

	*accumTime=0;

	CLI();
	SelectDrive();

	SetUpDMA(DMABuf,6);

	CLI();
	INT46_DID_COME_IN=0;

	FDC_WaitReady();
	STI();

	outp(IO_FDC_COMMAND,FDCCMD_READADDR);
	t0=inpw(IO_FREERUN_TIMER);

	// Memo: Make sure to write 44H to I/O AAh.
	//       Otherwise, apparently CPU and DMA fights each other for control of RAM access, and lock up.
	while(0==INT46_DID_COME_IN && *accumTime<READADDR_TIMEOUT)
	{
		t=inpw(IO_FREERUN_TIMER);
		diff=t-t0;
		*accumTime+=diff;
		t0=t;
	}

	if(READADDR_TIMEOUT<=*accumTime)
	{
		return 0xFF;
	}

	return (lastFDCStatus&~FDCSTA_BUSY);
}

void CleanUp(void)
{
	_dos_setvect(FDC_INT,Default_INT46H_Handler);
	SelectDrive();
	outp(IO_FDC_COMMAND,FDCCMD_RESTORE_HEAD_UNLOAD);
	outp(IO_FDC_DRIVE_SELECT,speedByte&~SPD_INUSE);
	Color(7);
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

void ReadTrack(unsigned char C,unsigned char H,struct CommandParameterInfo *cpi)
{
	const int nInfoPerLine=8;
	unsigned char nInfo=0;
	int FMorMFM=CTL_MFM;
	int i;
	int nTrackSector=0;
	unsigned char lostDataReadAddr=0;
	unsigned char lostDataReadData=0;
	unsigned char mfmTry,nFail=0;

	STI();
	Color(4);
	printf("C%-2d H%d ",C,H);
	fflush(stdout);
	Color(7);

	Wait10ms();
	Wait10ms();
	Wait10ms();
	Wait10ms();

	SelectDrive();

	FDC_WaitIndexHole(); // Need to be immediately after seek.
	// 1 second=5 revolutions for 2D/2DD, 6 revolutions for 2HD

	for(mfmTry=0; mfmTry<2; ++mfmTry)
	{
		uint32_t accumTime=0;
		uint16_t nFail=0;

		controlByte&=(~CTL_MFM);
		controlByte|=FMorMFM;

		for(i=0; i<IDBUF_SIZE && accumTime<READADDR_TRACK_TIMEOUT; ++i)
		{
			uint32_t passedTime;
			unsigned int sta;
			sta=FDC_ReadAddress(&passedTime);
			accumTime+=passedTime;
			if(0==sta || IOERR_CRC==sta)
			{
				idMark[nTrackSector].chrn[0]=DMABuf[0];
				idMark[nTrackSector].chrn[1]=DMABuf[1];
				idMark[nTrackSector].chrn[2]=DMABuf[2];
				idMark[nTrackSector].chrn[3]=DMABuf[3];
				idMark[nTrackSector].chrn[4]=DMABuf[4];
				idMark[nTrackSector].chrn[5]=DMABuf[5];
				++nTrackSector;
			}
			if(IOERR_LOST_DATA&sta)
			{
				lostDataReadAddr=1;
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
			FMorMFM=0;
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
	if(cpi->sortSectors)
	{
		int i,j;
		for(i=0; i<nTrackSector; ++i)
		{
			for(j=i+1; j<nTrackSector; ++j)
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


	STI();
	for(i=0; i<nTrackSector; ++i)
	{
		if(0<i && 0==nInfo)
		{
			printf("       ");
		}

		printf("%02x%02x%02x%02x ",idMark[i].chrn[0],idMark[i].chrn[1],idMark[i].chrn[2],idMark[i].chrn[3]);
		++nInfo;

		if(nInfoPerLine==nInfo)
		{
			printf("\n");
			nInfo=0;
		}
	}
	if(0!=nInfo)
	{
		printf("\n");
	}


//	numSectorTrackLog[track*2+side]=nTrackSector;
//	trackTable[track*2+side]=(nextTrackData-d77Image);
/*
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

			if(FMorMFM!=CTL_MFM)
			{
				sectorHdr->densityFlag=0x40;
			}

			if(0!=(ioErr&IOERR_LOST_DATA)) // Don't add garbage if lost data
			{
				lostDataLog[track*2+side]|=2;
				Color(IOErrToColor(ioErr));
				printf("%02x%02x%02x%02x ",idMark[i].chrn[0],idMark[i].chrn[1],idMark[i].chrn[2],idMark[i].chrn[3]);
				if(0==((nActual+nInfo+1)%nInfoPerLine))
				{
					printf("\n");
				}
				++nInfo;
			}
			else if(0==(ioErr&IOERR_CRC)) // No retry if no CRC error.
			{
				Color(IOErrToColor(ioErr));
				printf("%02x%02x%02x%02x ",idMark[i].chrn[0],idMark[i].chrn[1],idMark[i].chrn[2],idMark[i].chrn[3]);
				if(0==((nActual+nInfo+1)%nInfoPerLine))
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

				if(0==((nActual+nInfo+1)%nInfoPerLine))
				{
					printf("\n");
				}

				if(0!=(ioErr&IOERR_LOST_DATA))
				{
					++nInfo;
				}
				else
				{
					trackDataPtr+=sizeof(struct D77SectorHeader)+sectorHdr->actualSectorLength;
					++nActual;
				}
			}
		}
	}
	if(0!=(nActual+nInfo)%nInfoPerLine)
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
*/

	Color(7);

	outp(IO_FDC_DRIVE_CONTROL,controlByte|(0!=H ? CTL_SIDE : 0)|CTL_MFM);
}

void ReadDisk(struct CommandParameterInfo *cpi)
{
	int C;
	for(C=cpi->startTrk; C<=cpi->endTrk; ++C)
	{
Palette(4,0,0,255);
		FDC_Seek(C);
Palette(4,255,0,0);
		ReadTrack(C,0,cpi);
Palette(4,255,255,255);
		ReadTrack(C,1,cpi);
Palette(4,0,255,0);
	}

	/* if(NULL!=errLog)
	{
		printf("Error Summary\n");
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

	{
		for(int track=cpi->startTrk; track<=cpi->endTrk; ++track)
		{
			for(int side=0; side<2; ++side)
			{
				unsigned char t=track*2+side;
				if(lostDataLog[t]&1)
				{
					printf("Lost Data (ReadAddr) at C:%d H:%d\n",track,side);
				}
				if(lostDataLog[t]&2)
				{
					printf("Lost Data (Data    ) at C:%d H:%d\n",track,side);
				}

				if(0==numSectorTrackLog[t])
				{
					printf("Unformat C:%d H:%d\n",track,side);
				}
			}
		}
	} */
}

unsigned char FreeRunTimerAvailable(void)
{
	unsigned char flags=inp(IO_FUNCTION_ID);
	return (0==(flags&0x10));
}

int main(int ac,char *av[])
{
	unsigned char RestoreState=0;
	struct CommandParameterInfo cpi;

	Color(4);
	printf("FDDUMP for FM TOWNS\n");
	Color(7);
	printf("  by CaptainYS\n");

	InitializeCommandParameterInfo(&cpi);
	if(ac<3 || 0!=RecognizeCommandParameter(&cpi,ac,av))
	{
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
		CleanUp();
		return 1;
	}

	RestoreState=FDC_Restore(); // Can check write-protect
	if(RestoreState&0x80)
	{
		Color(2);
		printf("Restore command failed (Not Ready).\n");
		Color(7);
		CleanUp();
		return 1;
	}
	if(RestoreState&0x10)
	{
		Color(2);
		printf("Restore command failed (Seek Error).\n");
		Color(7);
		CleanUp();
		return 1;
	}

	remove(cpi.outFName);
	ReadDisk(&cpi);

	CleanUp();

	return 0;
}
