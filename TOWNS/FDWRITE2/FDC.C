#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include <dos.h>
#include "DEF.H"
#include "FDC.H"
#include "PIC.H"
#include "TIMER.H"
#include "CONSOLE.H"
#include "DMABUF.H"

extern unsigned int GetDMACount(void);
extern Tsugaru_Debug(const char str[]);

volatile unsigned char INT46_DID_COME_IN=0;
volatile unsigned char lastFDCStatus=0;
volatile unsigned int lastDMACount=0;

unsigned char lastFDCCommand=0;


static int currentCylinder=0;


#pragma Calling_convention(_INTERRUPT|_CALLING_CONVENTION);
_Handler Handle_INT46H(void)
{
	Palette(COLOR_DEBUG,255,0,0);

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

	lastDMACount=GetDMACount();
	lastFDCStatus=inp(IO_FDC_STATUS);
	if(FDCCMD_RESTORE!=lastFDCCommand && FDCCMD_SEEK!=lastFDCCommand)
	{
		// Looks like if I force-interrupt for seek commands, FDC stops before the head actually moved.
		outp(IO_FDC_COMMAND,FDCCMD_FORCEINTERRUPT);

		__CLI; // Is it necessary?
		outp(IO_DMA_MASK,inp(IO_DMA_MASK)|1);
	}
	else
	{
		while(inp(IO_FDC_STATUS)&1)
		{
		}
	}

	Palette(COLOR_DEBUG,0,255,0);

	inp(IO_FDC_STATUS); // Dummy read so that Force Interrupt won't cause indefinite IRQ.
	inp(IO_DMA_STATUS); // BIOS Dummy reads

	Palette(COLOR_DEBUG,255,255,255);

	// EOI
	_outp(0x0000,0x66); // Specific EOI + INT 6(46H).

	// DOS-Extender intercepts INT 46H in its own handler, then redirect to this handler by CALLF.
	// Must return by RETF.
	// _Far is the keyword in High-C.

	return 0;
}
#pragma Calling_convention();


////////////////////////////////////////////////////////////
// Disk
void FDC_TakeOverINT46H(void)
{
	_setpvect(INT_FDC,Handle_INT46H);
}

struct FDC_IOConfig FDC_GetIOConfig(unsigned int drive,unsigned int mode)
{
	struct FDC_IOConfig cfg;
	cfg.drvSel=(1<<(drive&3));
	switch(mode)
	{
	case MODE_2D:
		cfg.controlByte=CTL_CLKSEL|CTL_MOTOR;
		cfg.speedByte=SPD_INUSE;
		cfg.seekStep=2;
		break;
	case MODE_2DD:
		cfg.controlByte=CTL_CLKSEL|CTL_MOTOR;
		cfg.speedByte=SPD_INUSE;
		cfg.seekStep=1;
		break;
	case MODE_2HD_1232K:
		cfg.controlByte=CTL_MOTOR;
		cfg.speedByte=SPD_360RPM|SPD_INUSE;
		cfg.seekStep=1;
		break;
	case MODE_2HD_1440K:
		cfg.controlByte=CTL_MOTOR;
		cfg.speedByte=SPD_MODE_B|SPD_360RPM|SPD_INUSE;
		cfg.seekStep=1;
		break;
	}
	return cfg;
}

void FDC_SetSide(struct FDC_IOConfig *cfgPtr,int H)
{
	if(0==H)
	{
		cfgPtr->controlByte&=~CTL_SIDE;
	}
	else
	{
		cfgPtr->controlByte|=CTL_SIDE;
	}
}

int FDC_Support1440KB(void)
{
	unsigned char byteData=_inp(IO_FDC_DRIVE_STATUS);
	byteData>>=2;
	byteData&=7;
	return 3==byteData;
}

int FDC_GetNumberOfCylinders(unsigned int mode)
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

void FDC_SelectDrive(struct FDC_IOConfig cfg)
{
	outp(IO_FDC_DRIVE_SELECT,cfg.speedByte);
	outp(IO_1US_WAIT,0);
	outp(IO_1US_WAIT,0);
	outp(IO_FDC_DRIVE_SELECT,cfg.speedByte|cfg.drvSel);
	outp(IO_1US_WAIT,0);
	outp(IO_1US_WAIT,0);
}

void FDC_WriteDriveControl(struct FDC_IOConfig cfg,unsigned char IRQEN)
{
	outp(IO_FDC_DRIVE_CONTROL,cfg.controlByte|IRQEN);
}

// For unknown reason Disk BIOS reads status three times in a row.
unsigned char FDC_ReadDriveStatusIO(void)
{
	_inp(IO_FDC_DRIVE_STATUS);
	_inp(IO_FDC_DRIVE_STATUS);
	return _inp(IO_FDC_DRIVE_STATUS);
}

int FDC_CheckDriveReady(struct FDC_IOConfig cfg)
{
	__CLI;

	unsigned int  accumTime=0;
	unsigned short t0,t,diff;
	unsigned char driveStatus;
	FDC_SelectDrive(cfg);
	FDC_WriteDriveControl(cfg,0);

	WaitMicrosec(DRIVE_MOTOR_WAIT_TIME);

	t0=inpw(IO_FREERUN_TIMER);
	while(accumTime<DRIVE_MOTOR_WAIT_TIME)
	{
		driveStatus=FDC_ReadDriveStatusIO();
		if(0!=(driveStatus&DRIVE_STA_FREADY))
		{
			return 1;
		}

		t=inpw(IO_FREERUN_TIMER);
		diff=t-t0;
		t0=t;
		accumTime+=diff;
	}

	__STI;

	printf("Status %02xH\n",driveStatus);
	printf("FDC Status %02x\n",inp(IO_FDC_STATUS));
	return 0;
}

unsigned int  FDC_WaitReady(void)
{
	unsigned int  accum=0;
	unsigned short t0,t,diff;
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

void FDC_Command(unsigned char cmd)
{
	lastFDCCommand=cmd;
	_outp(IO_FDC_COMMAND,cmd);
}

void FDC_WaitIndexHole(void)
{
	unsigned int statusByte;

	__CLI;

	FDC_Command(FDCCMD_FORCEINTERRUPT);
	FDC_WaitReady();
	statusByte=0;
	while(0==(statusByte&FDCSTA_INDEX))
	{
		statusByte=inp(IO_FDC_STATUS); // This read will clear IRR.
	}
}


extern void SetUpDMAIn(unsigned int physAddr,unsigned int count);
extern void SetUpDMAOut(unsigned int physAddr,unsigned int count);


unsigned char FDC_Restore(struct FDC_IOConfig cfg)
{
	__CLI;
	struct PICMask picmask=PIC_GetMask();
	PIC_SetMask(PIC_ENABLE_FDC_ONLY);

	FDC_SelectDrive(cfg);
	FDC_WriteDriveControl(cfg,0);

	INT46_DID_COME_IN=0;

	FDC_WaitReady();
	__STI;
	FDC_Command(FDCCMD_RESTORE);
	FDC_WriteDriveControl(cfg,CTL_IRQEN);
	while(0==INT46_DID_COME_IN)
	{
	}
	FDC_WriteDriveControl(cfg,0);

	__CLI;
	PIC_SetMask(picmask);
	__STI;

	currentCylinder=0;
	printf("RESTORE Returned %02x\n",lastFDCStatus);

	return (lastFDCStatus&~FDCSTA_BUSY);
}

unsigned char FDC_Seek(struct FDC_IOConfig cfg,unsigned char C)
{
//03A4:00000C0F Write IO8:[020C] 50(FDC_DRIVE_SELECT)
//03A4:00000C15 Write IO8:[020C] 51(FDC_DRIVE_SELECT)
//03A4:00000C0F Write IO8:[020C] 40(FDC_DRIVE_SELECT)
//03A4:00000C15 Write IO8:[020C] 41(FDC_DRIVE_SELECT)
//03A4:00000C5A Write IO8:[0202] 00(FDC_TRACK)
//03A4:00000C1D Write IO8:[020C] 40(FDC_DRIVE_SELECT)
//03A4:00000C1F Write IO8:[020C] 41(FDC_DRIVE_SELECT)
//03A4:00000C22 Write IO8:[020C] 40(FDC_DRIVE_SELECT)
//03A4:00000C1D Write IO8:[020C] 40(FDC_DRIVE_SELECT)
//03A4:00000C1F Write IO8:[020C] 42(FDC_DRIVE_SELECT)
//03A4:00000C22 Write IO8:[020C] 40(FDC_DRIVE_SELECT)
//03A4:00000C1D Write IO8:[020C] 40(FDC_DRIVE_SELECT)
//03A4:00000C1F Write IO8:[020C] 44(FDC_DRIVE_SELECT)
//03A4:00000C22 Write IO8:[020C] 40(FDC_DRIVE_SELECT)
//03A4:00000C1D Write IO8:[020C] 40(FDC_DRIVE_SELECT)
//03A4:00000C1F Write IO8:[020C] 48(FDC_DRIVE_SELECT)
//03A4:00000C22 Write IO8:[020C] 40(FDC_DRIVE_SELECT)
//03A4:00000C07 Write IO8:[0208] 12(FDC_DRIVE_STATUS_CONTROL)
//03A4:00000C0F Write IO8:[020C] 40(FDC_DRIVE_SELECT)
//03A4:00000C15 Write IO8:[020C] 41(FDC_DRIVE_SELECT)
//03A4:00000BEE Read IO8:[0208] 8E(FDC_DRIVE_STATUS_CONTROL)
//03A4:00000BEF Read IO8:[0208] 8E(FDC_DRIVE_STATUS_CONTROL)
//03A4:00000BF0 Read IO8:[0208] 8E(FDC_DRIVE_STATUS_CONTROL)
//03A4:00000C0F Write IO8:[020C] 50(FDC_DRIVE_SELECT)
//03A4:00000C15 Write IO8:[020C] 51(FDC_DRIVE_SELECT)
//03A4:00000BEE Read IO8:[0208] 8E(FDC_DRIVE_STATUS_CONTROL)
//03A4:00000BEF Read IO8:[0208] 8E(FDC_DRIVE_STATUS_CONTROL)
//03A4:00000BF0 Read IO8:[0208] 8E(FDC_DRIVE_STATUS_CONTROL)
//03A4:00000C5F Write IO8:[0206] 14(FDC_DATA)
//03A4:00000BE9 Read IO8:[0200] 20(FDC_STATUS_COMMAND)
//03A4:00000C07 Write IO8:[0208] 13(FDC_DRIVE_STATUS_CONTROL)
//03A4:00000C3B Write IO8:[0200] 18(FDC_STATUS_COMMAND)
//FDC Command Write 18 Seek
//03A4:00000BE9 Read IO8:[0200] 00(FDC_STATUS_COMMAND)
//03A4:00000C4F Write IO8:[0200] D0(FDC_STATUS_COMMAND)
//FDC Command Write D0 Force_Interrupt
//03A4:00000C07 Write IO8:[0208] 12(FDC_DRIVE_STATUS_CONTROL)

	FDC_WaitReady();
	__CLI;

	struct PICMask picmask=PIC_GetMask();
	PIC_SetMask(PIC_ENABLE_FDC_ONLY);

	FDC_SelectDrive(cfg);
	FDC_WriteDriveControl(cfg,0);
	outp(IO_FDC_CYLINDER,currentCylinder);
	outp(IO_FDC_DATA,C*cfg.seekStep);
	currentCylinder=C*cfg.seekStep;

	Palette(COLOR_DEBUG,0,255,0);

	INT46_DID_COME_IN=0;

	FDC_WaitReady();

	Palette(COLOR_DEBUG,0,0,255);

	__STI;
	FDC_WriteDriveControl(cfg,CTL_IRQEN);
	FDC_Command(FDCCMD_SEEK);
	while(0==INT46_DID_COME_IN)
	{
		Palette(COLOR_DEBUG,rand(),rand(),rand());
	}
	FDC_WriteDriveControl(cfg,0);

	__CLI;
	PIC_SetMask(picmask);
	__STI;

	Palette(COLOR_DEBUG,0,255,255);

	if(0x10&lastFDCStatus)
	{
		Color(2);
		printf("\n!!!! Seek Error !!!!\n");
		Color(7);
	}

	Palette(COLOR_DEBUG,255,255,255);

	return (lastFDCStatus&~FDCSTA_BUSY);
}

unsigned char FDC_ReadAddress(struct FDC_IOConfig cfg,struct bufferInfo DMABuf,unsigned int  *accumTime)
{
	unsigned short t0,t,diff;

	Palette(COLOR_DEBUG,255,0,0);

	*accumTime=0;

	__CLI;
	FDC_SelectDrive(cfg);
	FDC_WriteDriveControl(cfg,0);

	SetUpDMAIn(DMABuf.physAddr,6);

	Palette(COLOR_DEBUG,0,255,0);

	__CLI;
	INT46_DID_COME_IN=0;
	struct PICMask picmask=PIC_GetMask();
	PIC_SetMask(PIC_ENABLE_FDC_ONLY);

	FDC_WaitReady();
	__STI;

	Palette(COLOR_DEBUG,0,0,255);

	FDC_WriteDriveControl(cfg,CTL_IRQEN);
	FDC_Command(FDCCMD_READADDR);
	t0=inpw(IO_FREERUN_TIMER);

	Palette(COLOR_DEBUG,0,255,255);

	// Memo: Make sure to write 44H to I/O AAh.
	//       Otherwise, apparently CPU and DMA fights each other for control of RAM access, and lock up.
	while(0==INT46_DID_COME_IN && *accumTime<READADDR_TIMEOUT)
	{
		Palette(COLOR_DEBUG,rand(),rand(),rand());
		t=inpw(IO_FREERUN_TIMER);
		diff=t-t0;
		*accumTime+=diff;
		t0=t;
	}
	FDC_WriteDriveControl(cfg,0);

	Palette(COLOR_DEBUG,255,255,255);

	PIC_SetMask(picmask);

	if(READADDR_TIMEOUT<=*accumTime)
	{
		// It does happen in real hardware, and unless Force Interrupt, FDC will never be ready again.
		FDC_Command(FDCCMD_FORCEINTERRUPT);
		outp(IO_DMA_MASK,inp(IO_DMA_MASK)|1);
		return 0xFF;
	}

	return (lastFDCStatus&~FDCSTA_BUSY);
}

unsigned char FDC_ReadSectorReal(struct FDC_IOConfig cfg,struct bufferInfo DMABuf,unsigned int  *accumTime,unsigned char C,unsigned char H,unsigned char R,unsigned char N)
{
	unsigned short t0,t,diff,initDMACounter;

	Palette(COLOR_DEBUG,255,0,0);

	*accumTime=0;

	__CLI;
	struct PICMask picmask=PIC_GetMask();
	PIC_SetMask(PIC_ENABLE_FDC_ONLY);


	FDC_SelectDrive(cfg);
	FDC_WriteDriveControl(cfg,0);

	initDMACounter=128<<(N&3);
	SetUpDMAIn(DMABuf.physAddr,initDMACounter);
	// --initDMACounter;  Why was I decrementing it?
	__STI;

	Palette(COLOR_DEBUG,0,255,0);

	INT46_DID_COME_IN=0;

	outp(IO_FDC_CYLINDER,C);
	outp(IO_FDC_SECTOR,R);
	FDC_WaitReady();

	Palette(COLOR_DEBUG,0,0,255);

	FDC_WriteDriveControl(cfg,CTL_IRQEN);
	FDC_Command(FDCCMD_READSECTOR);
	t0=inpw(IO_FREERUN_TIMER);

	Palette(COLOR_DEBUG,0,255,255);

	// Memo: Make sure to write 44H to I/O AAh.
	//       Otherwise, apparently CPU and DMA fights each other for control of RAM access, and lock up.
	// First loop until the DMA counter starts moving.
	while(0==INT46_DID_COME_IN && *accumTime<READSECTOR_TIMEOUT)
	{
		Palette(COLOR_DEBUG,rand(),rand(),rand());
		t=inpw(IO_FREERUN_TIMER);
		diff=t-t0;
		*accumTime+=diff;
		if(inpw(IO_DMA_COUNT_LOW)!=initDMACounter)
		{
			*accumTime=0;
			break;
		}
		t0=t;
	}
	// Second loop for measuring how long it takes to read a sector.
	while(0==INT46_DID_COME_IN && *accumTime<READSECTOR_TIMEOUT)
	{
		Palette(COLOR_DEBUG,rand(),rand(),rand());
		t=inpw(IO_FREERUN_TIMER);
		diff=t-t0;
		*accumTime+=diff;
		t0=t;
	}
	FDC_WriteDriveControl(cfg,0);


	__CLI;
	PIC_SetMask(picmask);
	__STI;


	Palette(COLOR_DEBUG,255,255,255);

	if(READSECTOR_TIMEOUT<=*accumTime)
	{
		// It does happen in real hardware, and unless Force Interrupt, FDC will never be ready again.
		FDC_Command(FDCCMD_FORCEINTERRUPT);
		outp(IO_DMA_MASK,inp(IO_DMA_MASK)|1);
		return 0xFF;
	}

	return lastFDCStatus;
}

unsigned char FDC_ReadSector(struct FDC_IOConfig cfg,struct bufferInfo DMABuf,unsigned int  *accumTime,unsigned char C,unsigned char H,unsigned char R,unsigned char N)
{
	int i;
	unsigned char res;
	for(i=0; i<3; ++i)
	{
		res=FDC_ReadSectorReal(cfg,DMABuf,accumTime,C,H,R,N);
		if(0xFF!=res)
		{
			break;
		}
		// Time Out!  Try Again!
	}
	return res;
}

unsigned char FDC_ReadTrack(struct FDC_IOConfig cfg,struct bufferInfo DMABuf,unsigned short *readSize)
{
	__CLI;
	struct PICMask picmask=PIC_GetMask();
	PIC_SetMask(PIC_ENABLE_FDC_ONLY);
	__STI;

	unsigned int DMABufSize=DMABuf.numberOfPages*PAGE_SIZE;

	int retry=0;
	for(retry=0; retry<3; ++retry)
	{
		unsigned short t0,t,diff;
		unsigned int  accumTime=0;

		Palette(COLOR_DEBUG,255,0,0);

		__CLI;

		FDC_SelectDrive(cfg);
		FDC_WriteDriveControl(cfg,0);

		SetUpDMAIn(DMABuf.physAddr,DMABufSize);

		Palette(COLOR_DEBUG,0,255,0);

		__CLI;
		INT46_DID_COME_IN=0;

		FDC_WaitReady();
		__STI;

		Palette(COLOR_DEBUG,0,0,255);

		FDC_WriteDriveControl(cfg,CTL_IRQEN);
		FDC_Command(FDCCMD_READTRACK);
		t0=inpw(IO_FREERUN_TIMER);

		Palette(COLOR_DEBUG,0,255,255);

		// Memo: Make sure to write 44H to I/O AAh.
		//       Otherwise, apparently CPU and DMA fights each other for control of RAM access, and lock up.
		accumTime=0;
		while(0==INT46_DID_COME_IN && accumTime<READTRACK_TIMEOUT)
		{
			Palette(COLOR_DEBUG,rand(),rand(),rand());
			t=inpw(IO_FREERUN_TIMER);
			diff=t-t0;
			accumTime+=diff;
			t0=t;
		}
		FDC_WriteDriveControl(cfg,0);

		Palette(COLOR_DEBUG,255,255,255);

		if(READTRACK_TIMEOUT<=accumTime)
		{
			// It does happen in real hardware, and unless Force Interrupt, FDC will never be ready again.
			FDC_Command(FDCCMD_FORCEINTERRUPT);
			outp(IO_DMA_MASK,inp(IO_DMA_MASK)|1);
			WaitMicrosec(500000);
			lastFDCStatus=0xFF;
		}
		else
		{
			break;
		}
	}

	__CLI;
	PIC_SetMask(picmask);
	__STI;

	{
		unsigned short DMACount;
		DMACount=lastDMACount;
		++DMACount;
		*readSize=DMABufSize-DMACount;
	}

	return lastFDCStatus;
}

unsigned char FDC_WriteTrack(unsigned long *writeSize,struct FDC_IOConfig cfg,struct bufferInfo DMABuf,unsigned int len,unsigned char data[])
{
	if(NULL!=writeSize)
	{
		*writeSize=0;
	}

	__CLI;
	struct PICMask picmask=PIC_GetMask();
	PIC_SetMask(PIC_ENABLE_FDC_ONLY);
	__STI;

	WriteToDMABuf(DMABuf,len,data);

	unsigned int DMABufSize=DMABuf.numberOfPages*PAGE_SIZE;

	int retry=0;
	for(retry=0; retry<3; ++retry)
	{
		unsigned short t0,t,diff;
		unsigned int  accumTime=0;

		Palette(COLOR_DEBUG,255,0,0);

		__CLI;

		FDC_SelectDrive(cfg);
		FDC_WriteDriveControl(cfg,0);

		SetUpDMAOut(DMABuf.physAddr,DMABufSize);

		Palette(COLOR_DEBUG,0,255,0);

		__CLI;
		INT46_DID_COME_IN=0;

		FDC_WaitReady();
		__STI;

		Palette(COLOR_DEBUG,0,0,255);

		FDC_WriteDriveControl(cfg,CTL_IRQEN);
		FDC_Command(FDCCMD_WRITETRACK);
		t0=inpw(IO_FREERUN_TIMER);

		Palette(COLOR_DEBUG,0,255,255);

		// Memo: Make sure to write 44H to I/O AAh.
		//       Otherwise, apparently CPU and DMA fights each other for control of RAM access, and lock up.
		accumTime=0;
		while(0==INT46_DID_COME_IN && accumTime<WRITETRACK_TIMEOUT)
		{
			Palette(COLOR_DEBUG,rand(),rand(),rand());
			t=inpw(IO_FREERUN_TIMER);
			diff=t-t0;
			accumTime+=diff;
			t0=t;
		}
		FDC_WriteDriveControl(cfg,0);

		Palette(COLOR_DEBUG,255,255,255);

		if(WRITETRACK_TIMEOUT<=accumTime)
		{
			// It does happen in real hardware, and unless Force Interrupt, FDC will never be ready again.
			FDC_Command(FDCCMD_FORCEINTERRUPT);
			outp(IO_DMA_MASK,inp(IO_DMA_MASK)|1);
			WaitMicrosec(500000);
			lastFDCStatus=0xFF;
		}
		else
		{
			break;
		}
	}

	__CLI;
	PIC_SetMask(picmask);
	__STI;

	if(NULL!=writeSize)
	{
		unsigned short DMACount;
		DMACount=lastDMACount;
		++DMACount;
		*writeSize=DMABufSize-DMACount;
	}

	return lastFDCStatus;
}

unsigned char FDC_WriteSector(struct FDC_IOConfig cfg,struct bufferInfo DMABuf,
    unsigned char C,unsigned char H,unsigned char R,unsigned char N,
    unsigned int len,const unsigned char data[],
    unsigned char deletedData,unsigned char crcError)
{
	unsigned short t0,t,diff,initDMACounter;
	unsigned char cmd=FDCCMD_WRITESECTOR;
	unsigned int accumTime=0;
	if(deletedData)
	{
		cmd|=1;
	}

	WriteToDMABuf(DMABuf,len,data);

	Palette(COLOR_DEBUG,255,0,0);

	__CLI;
	struct PICMask picmask=PIC_GetMask();
	PIC_SetMask(PIC_ENABLE_FDC_ONLY);


	FDC_SelectDrive(cfg);
	FDC_WriteDriveControl(cfg,0);

	initDMACounter=128<<(N&3);
	SetUpDMAOut(DMABuf.physAddr,initDMACounter);
	__STI;

	Palette(COLOR_DEBUG,0,255,0);

	INT46_DID_COME_IN=0;

	outp(IO_FDC_CYLINDER,C);
	outp(IO_FDC_SECTOR,R);
	FDC_WaitReady();

	Palette(COLOR_DEBUG,0,0,255);

	FDC_WriteDriveControl(cfg,CTL_IRQEN);
	FDC_Command(cmd);
	t0=inpw(IO_FREERUN_TIMER);

	Palette(COLOR_DEBUG,0,255,255);

	// Memo: Make sure to write 44H to I/O AAh.
	//       Otherwise, apparently CPU and DMA fights each other for control of RAM access, and lock up.
	// First loop until the DMA counter starts moving.
	while(0==INT46_DID_COME_IN && accumTime<READSECTOR_TIMEOUT)
	{
		Palette(COLOR_DEBUG,rand(),rand(),rand());
		t=inpw(IO_FREERUN_TIMER);
		diff=t-t0;
		accumTime+=diff;
		if(inpw(IO_DMA_COUNT_LOW)!=initDMACounter)
		{
			accumTime=0;
			break;
		}
		t0=t;
	}
	// Second loop for measuring how long it takes to read a sector.
	while(0==INT46_DID_COME_IN && accumTime<READSECTOR_TIMEOUT)
	{
		Palette(COLOR_DEBUG,rand(),rand(),rand());
		t=inpw(IO_FREERUN_TIMER);
		diff=t-t0;
		accumTime+=diff;
		t0=t;

		if(crcError && 0==inpw(IO_DMA_COUNT_LOW))
		{
			FDC_Command(FDCCMD_FORCEINTERRUPT);
			outp(IO_DMA_MASK,inp(IO_DMA_MASK)|1);
		}
	}
	FDC_WriteDriveControl(cfg,0);


	__CLI;
	PIC_SetMask(picmask);
	__STI;


	Palette(COLOR_DEBUG,255,255,255);

	if(READSECTOR_TIMEOUT<=accumTime)
	{
		// It does happen in real hardware, and unless Force Interrupt, FDC will never be ready again.
		FDC_Command(FDCCMD_FORCEINTERRUPT);
		outp(IO_DMA_MASK,inp(IO_DMA_MASK)|1);
		return 0xFF;
	}

	return lastFDCStatus;
}
