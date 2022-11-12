/* LICENSE>>
Copyright 2022 Soji Yamakawa (CaptainYS, http://www.ysflight.com)

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

<< LICENSE */


// For Open Watcom C
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <dos.h>
#include <conio.h>
#include <signal.h>
#include <malloc.h>

// RDD Output Data Data Format (.RDD  Real Disk Dump)
// Signature (First 16 bytes)
// 'R' 'E' 'A' 'L' 'D' 'I' 'S' 'K' 'D' 'U' 'M' 'P' 0 0 0 0 
// Begin Disk
// 00 vr mt fl 00 00 00 00 00 00 00 00 00 00 00 00 (16 bytes)
//    +1  vr  Version 
//    +2  mt  media type
//    +3  fl  flags
//            bit0  1:Write Protected  0:Write Enabled
// (32 bytes name, 0 padded
// Begin Track
// 01 cc hh 00 00 00 00 00 00 00 00 00 00 00 00 00 (16 bytes)
//    +1  cc  Cylinder
//    +2  hh  Head
// ID Mark
// 02 cc hh rr nn <CRC> st 00 00 00 00 00 00 00 00
// 02 cc hh rr nn <CRC> st 00 00 00 00 00 00 00 00
// 02 cc hh rr nn <CRC> st 00 00 00 00 00 00 00 00
//     :
//    +1  cc  Cylinder
//    +2  hh  Head
//    +3  rr  Sector Number
//    +4  nn  Length=128<<(n&3)
//    +5  CRC  CRC of the address mark (not for the data)
//    +6  CRC  CRC of the address mark (not for the data)
//    +7  st  MB8877 status
// Data
// 03 cc hh rr nn st fl 00 00 00 00 <time  > <Length>
//    +1  cc  Cylinder
//    +2  hh  Head
//    +3  rr  Sector Number
//    +4  nn  Length=128<<(n&3)
//    +5  st  MB8877 status
//    +6  fl  bit0=density flag(0:MFM 1:FM)
//            bit1=resample flag(1 means Resample for unstable bytes)
//            bit2=Probably Leaf-In-The-Forest Protect
//    +B  (3 bytes) Microseconds for reading the sector.
//    +E  (2 bytes) Length.  Currently always match (128<<(nn&3)).
// (Bytes padded to 16*N bytes)
// Track Read
// 04 cc hh st 00 00 00 00 00 00 00 00 00 <nBytes>
//    +1  cc  Cylinder
//    +2  hh  Head
//    +3  st  MB8877 status
//    +E  (2 bytes) Number of bytes returned from Track Read.
// (Bytes padded to 16*N bytes)
// End of Track
// 05 00 00 00 00 00 00 00 00 00 00 00 00 00 00
// End of File
// 06 00 00 00 00 00 00 00 00 00 00 00 00 00 00

// Next Track


unsigned int drvSel=1;    // Drive 0
unsigned int seekStep=1;  // 2 for 2D disk.
unsigned int controlByte=0; // To be written to I/O 0208h
unsigned int speedByte=0;
unsigned int currentCylinder=0;
unsigned int lastFDCCommand=0;

unsigned char far *trackBuf=NULL;
#define DMABUF_SIZE (20*1024)
unsigned char DMABuf[DMABUF_SIZE]="DMABUFFER";
#define SECTORCOPyBUF_SIZE 1024
unsigned char sectorDataCopy[SECTORCOPyBUF_SIZE];


#define COLOR_DEBUG 1

#define COLOR_ERR_CRC_AND_DDM 3
#define COLOR_ERR_CRC 2
#define COLOR_ERR_DDM 4
#define COLOR_ERR_RECORD_NOT_FOUND 5
#define COLOR_ERR_MISC 6
#define COLOR_NO_ERROR 7


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
#define ERRORLOG_TYPE_LOSTDATA_READADDR	4
#define ERRORLOG_TYPE_READ_TRACK 5
struct ErrorLog
{
	struct ErrorLog far *next;
	unsigned char errType;
	struct IDMARK idMark;
};
struct ErrorLog far *errLog=NULL,far *errLogTail=NULL;

void LogError(unsigned int code,struct IDMARK *idMark)
{
	struct ErrorLog far *newLog=(struct ErrorLog far *)_fmalloc(sizeof(struct ErrorLog));
	if(NULL!=newLog)
	{
		newLog->next=NULL;
		newLog->errType=code;
		newLog->idMark=*idMark;
		if(NULL==errLog)
		{
			errLog=newLog;
			errLogTail=newLog;
		}
		else
		{
			errLogTail->next=newLog;
			errLogTail=newLog;
		}
	}
}

void LogErrorCH(unsigned int code,uint8_t C,uint8_t H)
{
	struct ErrorLog far *newLog=(struct ErrorLog far *)_fmalloc(sizeof(struct ErrorLog));
	if(NULL!=newLog)
	{
		newLog->next=NULL;
		newLog->errType=code;
		newLog->idMark.chrn[0]=C;
		newLog->idMark.chrn[1]=H;
		newLog->idMark.chrn[2]=0;
		newLog->idMark.chrn[3]=0;
		if(NULL==errLog)
		{
			errLog=newLog;
			errLogTail=newLog;
		}
		else
		{
			errLogTail->next=newLog;
			errLogTail=newLog;
		}
	}
}



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
#define FDCCMD_READTRACK		0xE0
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

#define DRIVE_MOTOR_WAIT_TIME	2000000
#define READADDR_TIMEOUT		1000000
#define READADDR_TRACK_TIMEOUT  3000000
#define READTRACK_TIMEOUT		3000000
#define READSECTOR_TIMEOUT		3000000
#define AFTER_SCSI_WAIT          100000	// 100ms

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
volatile unsigned int lastDMACount=0;



void Palette(unsigned char code,unsigned char r,unsigned char g,unsigned char b)
{
	outp(0xFD90,code);
	outp(0xFD92,b&0xF0);
	outp(0xFD94,r&0xF0);
	outp(0xFD96,g&0xF0);
}

unsigned char IOErrToColor(uint8_t ioErr)
{
	if(0!=(ioErr&IOERR_CRC) && 0!=(ioErr&IOERR_DELETED_DATA))
	{
		return COLOR_ERR_CRC_AND_DDM;
	}
	if(0!=(ioErr&IOERR_CRC))
	{
		return COLOR_ERR_CRC;
	}
	if(0!=(ioErr&IOERR_DELETED_DATA))
	{
		return COLOR_ERR_DDM;
	}
	if(0!=(ioErr&IOERR_RECORD_NOT_FOUND))
	{
		return COLOR_ERR_RECORD_NOT_FOUND;
	}
	if(0!=ioErr)
	{
		return COLOR_ERR_MISC;
	}
	return COLOR_NO_ERROR;
}

// Watcom C inline assembly
void STI();
#pragma aux STI="sti";

void CLI();
#pragma aux CLI="cli";

unsigned int GetDMACount();
#pragma aux GetDMACount="in ax,0A2H" value [ AX ];

void far Handle_INT46H(void)
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

		CLI(); // Is it necessary?
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
}



////////////////////////////////////////////////////////////
// Interrupt

struct INT_DATA_BLOCK
{
	unsigned char zero[2];
	void far (*func)(void);
};

uint16_t default_INT46H_HandlerPtr[2];
uint8_t default_INT_EnableBits[4]={0,0,0,0};

// Note: INT number is from PIC point of view.  46H from CPU point of view is 06H from PIC point of view.
void INT46_SaveHandler(uint16_t *ptr);
#pragma aux INT46_SaveHandler=\
"push ds"\
"push es"\
"push ds"\
"push si"\
"mov dl,06h"\
"mov ah,01h"\
"int 0aeh"\
"pop si"\
"pop es"\
"mov es:[si],di"\
"mov es:[si+2],ds"\
"pop es"\
"pop ds"\
parm [ SI ] modify [ DI DX ]

void INT46_RestoreHandler(uint16_t *ptr);
#pragma aux INT46_RestoreHandler=\
"push ds"\
"push di"\
"push dx"\
"mov dl,06h"\
"lds di,ds:[di]"\
"xor ah,ah"\
"int 0aeh"\
"pop dx"\
"pop di"\
"pop ds"\
parm [ DI ]

void INT46_RegisterHandler(struct INT_DATA_BLOCK *ptr);
#pragma aux INT46_RegisterHandler=\
"mov dl,06h"\
"xor ah,ah"\
"int 0aeh"\
parm [ DI ]

void INT46_TakeOver(void)
{
	static struct INT_DATA_BLOCK datablock;
	datablock.zero[0]=0;
	datablock.zero[1]=0;
	datablock.func=Handle_INT46H;
	INT46_RegisterHandler(&datablock);
}


void INT_SetEnableBits(uint8_t *ptr);
#pragma aux INT_SetEnableBits=\
"mov ah,2"\
"int 0aeh"\
parm [ DI ]


void INT_GetEnableBits(uint8_t *ptr);
#pragma aux INT_GetEnableBits=\
"mov ah,3"\
"int 0aeh"\
parm [ DI ]



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
"mov ah,12h" \
"int 91h" \
"pop ax" \
parm[di]\

void VDB_setdefatr(struct VDB_ATR *atr);
#pragma aux VDB_setdefatr=\
"push ax" \
"mov ah,11h" \
"int 91h" \
"pop ax" \
parm[di]\

unsigned int VDB_rdposcus(void);
#pragma aux VDB_rdposcus=\
"mov ah,0Eh"\
"int 91h"\
value [dx]

void VDB_setposcus(int dx);
#pragma aux VDB_setposcus=\
"mov ah,0Dh"\
"int 91h"\
parm [ dx ]


void VDB_wtsysline(int AL,int CX,unsigned int DX,void *DI);
#pragma aux VDB_wtsysline=\
"mov [DI+2],DS"\
"mov [DI+6],DS"\
"mov ah,1Fh"\
"int 91h"\
parm [ AX ] [ CX ] [ DX ] [ DI ]

unsigned int sysCharBufPtr[4];
struct VDB_ATR sysChrAttr[8];


void Color(unsigned int c)
{
	struct VDB_ATR atr;
	VDB_rddefatr(&atr);
	atr.color=c;
	VDB_setdefatr(&atr);
}

void PrintSysCharWord(char str[],unsigned int X,unsigned int color)
{
	int L;
	for(L=0; L<8 && 0!=str[L]; ++L)
	{
		VDB_rddefatr(&sysChrAttr[L]);
		sysChrAttr[L].color=color;
	}
	sysCharBufPtr[0]=(unsigned int)str;
	sysCharBufPtr[2]=(unsigned int)sysChrAttr;
	VDB_wtsysline(1,L,X,sysCharBufPtr);
}

void PrintDebugLine(void)
{
	PrintSysCharWord("[ACT]",1,COLOR_DEBUG);
}

void CleanUp(void);

void CtrlC(int err)
{
	Color(7);
	CleanUp();
	printf("Intercepted Ctrl+C\n");
	exit(1);
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

void WaitMicrosec(uint32_t microsec)
{
	uint16_t t0;
	uint32_t accum=0;
	t0=inpw(IO_FREERUN_TIMER);
	while(accum<microsec)
	{
		uint16_t t,diff;
		t=inpw(IO_FREERUN_TIMER);
		diff=t-t0;
		accum+=diff;
		t0=t;
	}
}

////////////////////////////////////////////////////////////


#define RDD_VERSION 0

#define RDD_SECTORFLAG_DENSITY_FM   1
#define RDD_SECTORFLAG_RESAMPLE     2
#define RDD_SECTORFLAG_LEAF_IN_THE_FOREST  4


// Begin Disk
// 00 vr mt fl 00 00 00 00 00 00 00 00 00 00 00 00 (16 bytes)
//    vr  Version 
//    mt  media type (Compatible with D77.  0:2D  0x10:2DD  0x20:2HD)
//    fl  flags
//        bit0  1:Write Protected  0:Write Enabled
void RDD_MakeDiskHeader(unsigned char data[48],uint8_t restoreState,uint8_t mediaType,const char label[])
{
	int i;
	for(i=0; i<48; ++i)
	{
		data[i]=0;
	}
	data[0]=0x00; // Begin Disk
	data[1]=RDD_VERSION; //
	data[2]=mediaType;
	data[3]|=((restoreState&0x40) ? 1 : 0);
	strncpy(data+16,label,32);
}

unsigned int RDD_WriteSignature(const char fName[])
{
	char signature[16];
	int i;
	FILE *ofp;

	for(i=0; i<16; ++i)
	{
		signature[i]=0;
	}
	strcpy(signature,"REALDISKDUMP");

	ofp=fopen(fName,"wb");
	fwrite(signature,1,16,ofp);
	fclose(ofp);

	WaitMicrosec(AFTER_SCSI_WAIT);

	return 0;
}

unsigned int RDD_WriteDiskHeader(const char fName[],uint8_t restoreState,uint8_t mediaType,const char label[])
{
	unsigned char data[48];
	FILE *ofp;

	RDD_MakeDiskHeader(data,restoreState,mediaType,label);

	ofp=fopen(fName,"ab");
	if(NULL==ofp)
	{
		Color(2);
		fprintf(stderr,"Cannot open output file.\n");
		Color(7);
		return 1;
	}
	fwrite(data,1,48,ofp);
	fclose(ofp);

	WaitMicrosec(AFTER_SCSI_WAIT);

	return 0;
}

// Begin Track
// 01 cc hh 00 00 00 00 00 00 00 00 00 00 00 00 00 (16 bytes)
unsigned int RDD_WriteTrackHeader(const char fName[],uint8_t C,uint8_t H)
{
	FILE *ofp;
	unsigned char data[16];
	int i;
	for(i=0; i<16; ++i)
	{
		data[i]=0;
	}
	data[0]=1;
	data[1]=C;
	data[2]=H;

	ofp=fopen(fName,"ab");
	if(NULL==ofp)
	{
		Color(2);
		fprintf(stderr,"Cannot open output file.\n");
		Color(7);
		return 1;
	}
	fwrite(data,1,16,ofp);
	fclose(ofp);

	WaitMicrosec(AFTER_SCSI_WAIT);

	return 0;
}

// ID Mark
// 02 cc hh rr nn <CRC> st 00 00 00 00 00 00 00 00
unsigned int RDD_WriteIDMark(const char fName[],unsigned int numIDMarks,struct IDMARK idMark[])
{
	FILE *ofp;
	unsigned char data[16];
	int i;
	for(i=0; i<16; ++i)
	{
		data[i]=0;
	}
	data[0]=2;

	ofp=fopen(fName,"ab");
	if(NULL==ofp)
	{
		Color(2);
		fprintf(stderr,"Cannot open output file.\n");
		Color(7);
		return 1;
	}

	for(i=0; i<numIDMarks; ++i)
	{
		data[1]=idMark[i].chrn[0]; // C
		data[1]=idMark[i].chrn[1]; // H
		data[2]=idMark[i].chrn[2]; // R
		data[3]=idMark[i].chrn[3]; // N
		data[4]=idMark[i].chrn[4]; // CRC
		data[6]=idMark[i].chrn[5]; // CRC
		data[7]=idMark[i].chrn[7]; // FDC Status
		fwrite(data,1,16,ofp);
	}
	fclose(ofp);

	WaitMicrosec(AFTER_SCSI_WAIT);

	return 0;
}

// Data
// 03 cc hh rr nn st fl 00 00 00 00 <time  > <Length>
//     st  MB8877 status
//     fl  bit0=density flag(0:MFM 1:FM)
//         bit1=resample flag(1 means Resample for unstable bytes)
unsigned int RDD_WriteSectorData(const char fName[],const uint8_t CHRN[4],uint8_t FDCSta,uint32_t readTime,uint8_t FMorMFM,uint8_t isResample)
{
	FILE *ofp;
	unsigned int actualSize=0; // MB8877 always reads 128<<N anyway.
	unsigned char *actualSizePtr,*readTimePtr;
	unsigned char data[16];
	int i;
	uint8_t flags=0;

	if(CTL_MFM!=FMorMFM) // If single-density
	{
		flags|=RDD_SECTORFLAG_DENSITY_FM;
	}
	if(0!=isResample)
	{
		flags|=RDD_SECTORFLAG_RESAMPLE;
	}

	for(i=0; i<16; ++i)
	{
		data[i]=0;
	}
	data[0]=3;
	data[1]=CHRN[0];
	data[2]=CHRN[1];
	data[3]=CHRN[2];
	data[4]=CHRN[3];
	data[5]=FDCSta;

	readTimePtr=(unsigned char *)&readTime;
	data[11]=readTimePtr[0];
	data[12]=readTimePtr[1];
	data[13]=readTimePtr[2];

	actualSize=(128<<(CHRN[3]&3));
	actualSizePtr=(unsigned char *)&actualSize;
	data[14]=actualSizePtr[0];
	data[15]=actualSizePtr[1];

	ofp=fopen(fName,"ab");
	if(NULL==ofp)
	{
		Color(2);
		fprintf(stderr,"Cannot open output file.\n");
		Color(7);
		return 1;
	}

	fwrite(data,1,16,ofp);
	fwrite(DMABuf,1,actualSize,ofp);

	fclose(ofp);

	WaitMicrosec(AFTER_SCSI_WAIT);

	return 0;
}

// Track Read
// 04 cc hh st 00 00 00 00 00 00 00 00 00 <nBytes>
unsigned int RDD_WriteTrack(const char outFName[],uint8_t C,uint8_t H,uint16_t readSize,uint8_t st)
{
	FILE *ofp;
	unsigned int writeSize=0;
	unsigned char *readSizePtr;
	unsigned char data[16];
	int i;
	for(i=0; i<16; ++i)
	{
		data[i]=0;
	}
	data[0]=4;
	data[1]=C;
	data[2]=H;
	data[3]=st;

	readSizePtr=(unsigned char *)&readSize;
	data[14]=readSizePtr[0];
	data[15]=readSizePtr[1];

	ofp=fopen(outFName,"ab");
	if(NULL==ofp)
	{
		Color(2);
		fprintf(stderr,"Cannot open output file.\n");
		Color(7);
		return 1;
	}

	writeSize=(readSize+15)&~0x000F;
	for(i=readSize; i<writeSize; ++i)
	{
		DMABuf[i]=0;
	}

	fwrite(data,1,16,ofp);
	fwrite(DMABuf,1,writeSize,ofp);

	fclose(ofp);

	WaitMicrosec(AFTER_SCSI_WAIT);

	return 0;
}

unsigned int RDD_WriteEndOfTrack(const char outFName[])
{
	FILE *ofp;
	uint8_t data[16]={5,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};

	ofp=fopen(outFName,"ab");
	if(NULL==ofp)
	{
		Color(2);
		fprintf(stderr,"Cannot open output file.\n");
		Color(7);
		return 1;
	}

	fwrite(data,1,16,ofp);

	fclose(ofp);

	WaitMicrosec(AFTER_SCSI_WAIT);
	WaitMicrosec(AFTER_SCSI_WAIT);
	WaitMicrosec(AFTER_SCSI_WAIT);

	return 0;
}

unsigned int RDD_WriteEndOfDisk(const char outFName[])
{
	FILE *ofp;
	uint8_t data[16]={6,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};

	ofp=fopen(outFName,"ab");
	if(NULL==ofp)
	{
		Color(2);
		fprintf(stderr,"Cannot open output file.\n");
		Color(7);
		return 1;
	}

	fwrite(data,1,16,ofp);

	fclose(ofp);

	WaitMicrosec(AFTER_SCSI_WAIT);

	return 0;
}

////////////////////////////////////////////////////////////
// Disk
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
	case MODE_2HD_1440K:
		controlByte=CTL_MOTOR;
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
}

void WriteDriveControl(uint8_t IRQEN)
{
	outp(IO_FDC_DRIVE_CONTROL,controlByte|IRQEN);
}

// For unknown reason Disk BIOS reads status three times in a row.
uint8_t ReadDriveStatusIO(void);
#pragma aux ReadDriveStatusIO=\
"mov dx,0208h"\
"in al,dx"\
"in al,dx"\
"in al,dx"\
"movzx ax,al"\
value [ al ] modify [ dx ]

int CheckDriveReady(void)
{
	uint32_t accumTime=0;
	uint16_t t0,t,diff;
	uint8_t driveStatus;
	SelectDrive();
	WriteDriveControl(0);

	WaitMicrosec(DRIVE_MOTOR_WAIT_TIME);

	t0=inpw(IO_FREERUN_TIMER);
	while(accumTime<DRIVE_MOTOR_WAIT_TIME)
	{
		driveStatus=ReadDriveStatusIO();
		if(0!=(driveStatus&DRIVE_STA_FREADY))
		{
			return 1;
		}

		t=inpw(IO_FREERUN_TIMER);
		diff=t-t0;
		t0=t;
		accumTime+=diff;
	}
	printf("Status %02xH\n",driveStatus);
	printf("FDC Status %02x\n",inp(IO_FDC_STATUS));
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

void FDC_Command(unsigned char cmd)
{
	lastFDCCommand=cmd;
	outp(IO_FDC_COMMAND,cmd);
}

void FDC_WaitIndexHole(void)
{
	unsigned int statusByte;

	CLI();

	FDC_Command(FDCCMD_FORCEINTERRUPT);
	FDC_WaitReady();
	statusByte=0;
	while(0==(statusByte&FDCSTA_INDEX))
	{
		statusByte=inp(IO_FDC_STATUS); // This read will clear IRR.
	}
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
	SelectDrive();
	WriteDriveControl(0);

	INT46_DID_COME_IN=0;

	FDC_WaitReady();
	STI();
	FDC_Command(FDCCMD_RESTORE);
	WriteDriveControl(CTL_IRQEN);
	while(0==INT46_DID_COME_IN)
	{
	}
	WriteDriveControl(0);
	STI();

	currentCylinder=0;
	printf("RESTORE Returned %02x\n",lastFDCStatus);

	return (lastFDCStatus&~FDCSTA_BUSY);
}

unsigned char FDC_Seek(unsigned char C)
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
	CLI();

	SelectDrive();
	WriteDriveControl(0);
	outp(IO_FDC_CYLINDER,currentCylinder);
	outp(IO_FDC_DATA,C*seekStep);
	currentCylinder=C*seekStep;

	Palette(COLOR_DEBUG,0,255,0);

	INT46_DID_COME_IN=0;

	FDC_WaitReady();

	Palette(COLOR_DEBUG,0,0,255);

	STI();
	WriteDriveControl(CTL_IRQEN);
	FDC_Command(FDCCMD_SEEK);
	while(0==INT46_DID_COME_IN)
	{
		Palette(COLOR_DEBUG,rand(),rand(),rand());
	}
	WriteDriveControl(0);
	STI();

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

unsigned char FDC_ReadAddress(uint32_t *accumTime)
{
	uint16_t t0,t,diff;

	Palette(COLOR_DEBUG,255,0,0);

	*accumTime=0;

	CLI();
	SelectDrive();
	WriteDriveControl(0);

	SetUpDMA(DMABuf,6);

	Palette(COLOR_DEBUG,0,255,0);

	CLI();
	INT46_DID_COME_IN=0;

	FDC_WaitReady();
	STI();

	Palette(COLOR_DEBUG,0,0,255);

	WriteDriveControl(CTL_IRQEN);
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
	WriteDriveControl(0);

	Palette(COLOR_DEBUG,255,255,255);

	if(READADDR_TIMEOUT<=*accumTime)
	{
		// It does happen in real hardware, and unless Force Interrupt, FDC will never be ready again.
		FDC_Command(FDCCMD_FORCEINTERRUPT);
		outp(IO_DMA_MASK,inp(IO_DMA_MASK)|1);
		return 0xFF;
	}

	return (lastFDCStatus&~FDCSTA_BUSY);
}

unsigned char FDC_ReadSectorReal(uint32_t *accumTime,uint8_t C,uint8_t H,uint8_t R,uint8_t N)
{
	static uint8_t INT_EnableBits[4]; // Make sure it is in DS.
	uint8_t INT_EnableBitsBackUp[4];

	uint16_t t0,t,diff,initDMACounter;

	Palette(COLOR_DEBUG,255,0,0);

	*accumTime=0;


	INT_GetEnableBits(INT_EnableBits);
	INT_EnableBitsBackUp[0]=INT_EnableBits[0];
	INT_EnableBitsBackUp[1]=INT_EnableBits[1];
	INT_EnableBitsBackUp[2]=INT_EnableBits[2];
	INT_EnableBitsBackUp[3]=INT_EnableBits[3];
	INT_EnableBits[3]&=0xC0; // Mask everything except FDC and Secondary PIC.
	INT_EnableBits[2]=0;     // Mask everything except FDC and Secondary PIC.
	INT_SetEnableBits(INT_EnableBits);


	SelectDrive();
	WriteDriveControl(0);

	CLI();
	initDMACounter=128<<(N&3);
	SetUpDMA(DMABuf,initDMACounter);
	--initDMACounter;
	STI();

	Palette(COLOR_DEBUG,0,255,0);

	INT46_DID_COME_IN=0;

	outp(IO_FDC_CYLINDER,C);
	outp(IO_FDC_SECTOR,R);
	FDC_WaitReady();

	Palette(COLOR_DEBUG,0,0,255);

	WriteDriveControl(CTL_IRQEN);
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
	WriteDriveControl(0);


	INT_EnableBits[0]=INT_EnableBitsBackUp[0];
	INT_EnableBits[1]=INT_EnableBitsBackUp[1];
	INT_EnableBits[2]=INT_EnableBitsBackUp[2];
	INT_EnableBits[3]=INT_EnableBitsBackUp[3];
	INT_SetEnableBits(INT_EnableBits);


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

unsigned char FDC_ReadSector(uint32_t *accumTime,uint8_t C,uint8_t H,uint8_t R,uint8_t N)
{
	int i;
	uint8_t res;
	for(i=0; i<3; ++i)
	{
		res=FDC_ReadSectorReal(accumTime,C,H,R,N);
		if(0xFF!=res)
		{
			break;
		}
		// Time Out!  Try Again!
	}
	return res;
}

unsigned char FDC_ReadTrack(uint16_t *readSize)
{
	int retry=0;
	for(retry=0; retry<3; ++retry)
	{
		uint16_t t0,t,diff;
		uint32_t accumTime=0;

		Palette(COLOR_DEBUG,255,0,0);

		CLI();
		SelectDrive();
		WriteDriveControl(0);

		SetUpDMA(DMABuf,DMABUF_SIZE);

		Palette(COLOR_DEBUG,0,255,0);

		CLI();
		INT46_DID_COME_IN=0;

		FDC_WaitReady();
		STI();

		Palette(COLOR_DEBUG,0,0,255);

		WriteDriveControl(CTL_IRQEN);
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
		WriteDriveControl(0);

		Palette(COLOR_DEBUG,255,255,255);

		if(READTRACK_TIMEOUT<=accumTime)
		{
			int i;
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

	{
		uint16_t DMACount;
		DMACount=lastDMACount;
		++DMACount;
		*readSize=DMABUF_SIZE-DMACount;
	}

	return lastFDCStatus;
}

void CleanUp(void)
{
	int i;
	INT46_RestoreHandler(default_INT46H_HandlerPtr);
	FDC_Command(FDCCMD_RESTORE_HEAD_UNLOAD);

	controlByte&=~CTL_MOTOR;
	speedByte&=~SPD_INUSE;
	SelectDrive();
	WriteDriveControl(0);

	INT_SetEnableBits(default_INT_EnableBits);

	Color(7);
	PrintSysCharWord("        ",1,7);
	PrintSysCharWord("        ",9,7);
	PrintSysCharWord("        ",17,7);
	PrintSysCharWord("        ",25,7);
	for(i=0; i<8; ++i)
	{
		uint8_t r=(i&2 ? 255 : 0);
		uint8_t g=(i&4 ? 255 : 0);
		uint8_t b=(i&1 ? 255 : 0);
		Palette(i,r,g,b);
	}
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
	char logFName[512];
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
	cpi->logFName[0]=0;
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
		cpi->endTrk=40;
		cpi->mediaType=0;
	}
	else if(0==strcmp(av[2],"2DD") || 0==strcmp(av[2],"2dd") ||
	        0==strcmp(av[2],"640KB") || 0==strcmp(av[2],"640kb") ||
	        0==strcmp(av[2],"720KB") || 0==strcmp(av[2],"720kb"))
	{
		cpi->mode=MODE_2DD;
		cpi->startTrk=0;
		cpi->endTrk=80;
		cpi->mediaType=0x10;
	}
	else if(0==strcmp(av[2],"2HD") || 0==strcmp(av[2],"2hd") ||
	        0==strcmp(av[2],"1232KB") || 0==strcmp(av[2],"1232kb"))
	{
		cpi->mode=MODE_2HD_1232K;
		cpi->startTrk=0;
		cpi->endTrk=80;
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
		else if(0==strcmp(av[i],"-LOG") || 0==strcmp(av[i],"-log"))
		{
			if(i+1<ac)
			{
				strcpy(cpi->logFName,av[i+1]);
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
		else if(0==strcmp(av[i],"-sort") || 0==strcmp(av[i],"-SORT"))
		{
			cpi->sortSectors=1;
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


/*
Thexder Protected Track

82 bytes per dummy sector

1 byte = 16 pulse windows

82 bytes = 1312 pulse windows

500K pulses per sec

1312/500K=2.624 millisec
*/



unsigned int IsLeafInTheForest(int nIDMarks,const struct IDMARK idMark[],uint16_t readTrackSize)
{
	int i;
	int nSec=0;

	// Sign of Leaf-In-The-Forest protect (1) all same C,H,R
	for(i=1; i<nIDMarks; ++i)
	{
		if(idMark[i].chrn[0]!=idMark[0].chrn[0] ||
		   idMark[i].chrn[1]!=idMark[0].chrn[1] ||
		   idMark[i].chrn[2]!=idMark[0].chrn[2])
		{
			return 0;
		}
	}

	// Sign of Leaf-In-The-Forest protect (2) many ID marks.
	for(i=0; i+6<readTrackSize; ++i)
	{
		if(DMABuf[i  ]==0xA1 &&
		   DMABuf[i+1]==0xA1 &&
		   DMABuf[i+2]==0xFE &&
		   DMABuf[i+3]==idMark[0].chrn[0] &&
		   DMABuf[i+4]==idMark[0].chrn[1] &&
		   DMABuf[i+5]==idMark[0].chrn[2]) // ID Mark
		{
			++nSec;
		}
		if(DMABuf[i  ]==0xA1 &&
		   DMABuf[i+1]==0xA1 &&
		   (DMABuf[i+2]==0xFB || DMABuf[i+2]==0xF8)) // Data Mark
		{
		}
	}

	// Thexder and Fire Crystal had more than 60 sectors in total.
	// 40 should be a good threshold.
	if(40<=nSec)
	{
		return 1;
	}

	return 0;
}

#define nInfoPerLine 8

// Data
// 03 cc hh rr nn st fl 00 00 00 00 <time  > <Length>
//    +1  cc  Cylinder
//    +2  hh  Head
//    +3  rr  Sector Number
//    +4  nn  Length=128<<(n&3)
//    +5  st  MB8877 status
//    +6  fl  bit0=density flag(0:MFM 1:FM)
//            bit1=resample flag(1 means Resample for unstable bytes)
//    +B  (3 bytes) Microseconds for reading the sector.
//    +E  (2 bytes) Length.  Currently always match (128<<(nn&3)).
void FindHiddenLeaf(const char fName[],int nInfo,uint16_t readTrackSize,uint8_t mediaType)
{
	// Looks like FM TOWNS's FDC is reliable in Read Track command.
	uint8_t header[16]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
	uint16_t ptr;
	uint16_t addrMarkPtr=0,dataMarkPtr=0;
	uint16_t prevAddrMarkPtr,prevDataMarkPtr;
	uint8_t C,H,R,N;


	if(0<nInfo && 0==nInfo%nInfoPerLine)
	{
		printf("       ");
	}

	Color(4);
	printf("HIDNLEAF ");
	fflush(stdout);
	++nInfo;
	if(0==nInfo%nInfoPerLine)
	{
		printf("\n");
	}


	for(ptr=0; ptr+7<readTrackSize; ++ptr)
	{
		if(DMABuf[ptr  ]==0xA1 &&
		   DMABuf[ptr+1]==0xA1 &&
		   DMABuf[ptr+2]==0xFE)
		{
			prevAddrMarkPtr=addrMarkPtr;
			addrMarkPtr=ptr;
		}
		else if(DMABuf[ptr  ]==0xA1 &&
		        DMABuf[ptr+1]==0xA1 &&
		       (DMABuf[ptr+2]==0xFB || DMABuf[ptr+2]==0xF8))
		{
			uint16_t len=0;
			uint16_t dataPtr,microsec;

			prevDataMarkPtr=dataMarkPtr;
			dataMarkPtr=ptr;
			dataPtr=ptr+3;

			C=DMABuf[addrMarkPtr+3];
			H=DMABuf[addrMarkPtr+4];
			R=DMABuf[addrMarkPtr+5];
			N=DMABuf[addrMarkPtr+6];

			header[0]=3;
			header[1]=C;
			header[2]=H;
			header[3]=R;
			header[4]=N;
			header[5]=IOERR_CRC;
			if(0xF8==DMABuf[ptr+2])
			{
				header[5]|=IOERR_DELETED_DATA;
			}
			header[6]=RDD_SECTORFLAG_LEAF_IN_THE_FOREST;

			len=(128<<(N&3));
			header[14]=(len&0xFF);
			header[15]=(len>>8);

			if(0x20==mediaType) // 2HD 1000K pulses per sec
			{
				microsec=16*len; // (micro=1M)*len*(16 pulses per byte)/1000K.
			}
			else // 2D/2DD 500K pulses per sec
			{
				microsec=32*len; // (micro=1M)*len*(16 pulses per byte)/500K.
			}
			header[0x0B]=microsec&0xFF;
			header[0x0C]=(microsec>>8)&0xFF;

			{
				FILE *ofp=fopen(fName,"ab");
				if(NULL!=ofp)
				{
					fwrite(header,1,16,ofp);
					fwrite(DMABuf+dataPtr,1,len,ofp);
					fclose(ofp);

					if(0<nInfo && 0==nInfo%nInfoPerLine)
					{
						printf("       ");
					}

					Color(IOErrToColor(header[4]));
					printf("%02x%02x%02x%02x ",C,H,R,N);
					fflush(stdout);
					++nInfo;
					if(0==nInfo%nInfoPerLine)
					{
						printf("\n");
					}
				}
			}
		}
	}

	Color(7);

	if(0!=nInfo%nInfoPerLine)
	{
		printf("\n");
	}
}

void ReadTrack(unsigned char C,unsigned char H,struct CommandParameterInfo *cpi)
{
	unsigned char nInfo=0;
	int FMorMFM=CTL_MFM;
	int i;
	int nTrackSector=0;
	unsigned char lostDataReadAddr=0;
	unsigned char lostDataReadData=0;
	unsigned char mfmTry,nFail=0;
	uint16_t readTrackSize=0;
	uint8_t ioErr=0;

	STI();
	Color(4);
	printf("C%-2d H%d ",C,H);
	fflush(stdout);
	Color(7);

	RDD_WriteTrackHeader(cpi->outFName,C,H);

	if(0==H)
	{
		controlByte&=~CTL_SIDE;
	}
	else
	{
		controlByte|=CTL_SIDE;
	}
	SelectDrive();
	WriteDriveControl(0);

	FDC_WaitIndexHole(); // Need to be immediately after seek.
	// 1 second=5 revolutions for 2D/2DD, 6 revolutions for 2HD

	STI();
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
				idMark[nTrackSector].chrn[7]=sta;

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

	if(lostDataReadAddr)
	{
		LogErrorCH(ERRORLOG_TYPE_LOSTDATA_READADDR,C,H);
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


	// Read Track
	ioErr=FDC_ReadTrack(&readTrackSize);
	if(0xFF==ioErr)
	{
		LogErrorCH(ERRORLOG_TYPE_READ_TRACK,C,H);
	}


	STI();
	RDD_WriteIDMark(cpi->outFName,nTrackSector,idMark);
	if(0xFF!=ioErr)
	{
		RDD_WriteTrack(cpi->outFName,C,H,readTrackSize,ioErr);
		// If Hidden-Leaf protect, do differently.
		if(IsLeafInTheForest(nTrackSector,idMark,readTrackSize))
		{
			FindHiddenLeaf(cpi->outFName,nInfo,readTrackSize,cpi->mediaType);
			RDD_WriteEndOfTrack(cpi->outFName);
			return;
		}
	}


	WaitMicrosec(500000); // 500ms


	for(i=0; i<nTrackSector; ++i)
	{
		uint8_t retry,ioErr=0;
		lostDataReadData=0;

		for(retry=0; retry<cpi->firstRetryCount; ++retry)
		{
			uint32_t readTime;
			ioErr=FDC_ReadSector(&readTime,idMark[i].chrn[0],idMark[i].chrn[1],idMark[i].chrn[2],idMark[i].chrn[3]);

			if(0<nInfo && 0==nInfo%nInfoPerLine)
			{
				printf("       ");
			}

			if(0!=(ioErr&IOERR_LOST_DATA)) // Don't add garbage if lost data
			{
				lostDataReadData=1;
				Color(IOErrToColor(ioErr));
				printf("%02x%02x%02x%02x ",idMark[i].chrn[0],idMark[i].chrn[1],idMark[i].chrn[2],idMark[i].chrn[3]);
				fflush(stdout);
				++nInfo;

				if(0==nInfo%nInfoPerLine)
				{
					printf("\n");
				}
			}
			else if(0==(ioErr&IOERR_CRC)) // No retry if no CRC error.
			{
				lostDataReadData=0;
				Color(IOErrToColor(ioErr));
				printf("%02x%02x%02x%02x ",idMark[i].chrn[0],idMark[i].chrn[1],idMark[i].chrn[2],idMark[i].chrn[3]);
				fflush(stdout);
				++nInfo;

				STI();
				RDD_WriteSectorData(cpi->outFName,idMark[i].chrn,ioErr,readTime,FMorMFM,0);

				if(0==nInfo%nInfoPerLine)
				{
					printf("\n");
				}
				break;
			}
		}

		if(lostDataReadData)
		{
			LogError(ERRORLOG_TYPE_LOSTDATA,&idMark[i]);
		}

		if(0!=(ioErr&IOERR_CRC))  // If finally I couldn't read without CRC error.
		{
			int j,len;
			LogError(ERRORLOG_TYPE_CRC,&idMark[i]);

			len=(128<<(idMark[i].chrn[3]&3));
			for(retry=0; retry<cpi->secondRetryCount; ++retry)
			{
				uint32_t readTime;

				for(j=0; j<len; ++j)
				{
					sectorDataCopy[j]=DMABuf[j];
				}
				ioErr=FDC_ReadSector(&readTime,idMark[i].chrn[0],idMark[i].chrn[1],idMark[i].chrn[2],idMark[i].chrn[3]);

				if(0==(ioErr&IOERR_LOST_DATA)) // && different from previous)
				{
					unsigned int different=0;
					for(j=0; j<len; ++j)
					{
						if(sectorDataCopy[j]!=DMABuf[j])
						{
							different=1;
						}
						sectorDataCopy[j]=DMABuf[j]; // For next comparison.
					}

					if(0==retry || 0!=different)
					{
						if(0<nInfo && 0==nInfo%nInfoPerLine)
						{
							printf("       ");
						}

						Color(IOErrToColor(ioErr));
						printf("%02x%02x%02x%02x ",idMark[i].chrn[0],idMark[i].chrn[1],idMark[i].chrn[2],idMark[i].chrn[3]);
						fflush(stdout);
						++nInfo;
						STI();
						RDD_WriteSectorData(cpi->outFName,idMark[i].chrn,ioErr,readTime,FMorMFM,1);

						if(0==nInfo%nInfoPerLine)
						{
							printf("\n");
						}
					}
				}
			}
		}
	}
	if(0!=nInfo%nInfoPerLine)
	{
		printf("\n");
	}

	Color(7);

	outp(IO_FDC_DRIVE_CONTROL,controlByte|(0!=H ? CTL_SIDE : 0)|CTL_MFM);

	RDD_WriteEndOfTrack(cpi->outFName);
}

void WriteInfoLog(FILE *ofp,struct CommandParameterInfo *cpi)
{
	fprintf(ofp,"Output: %s\n",cpi->outFName);
	fprintf(ofp,"Drive:  %c\n",'A'+cpi->drive);

	switch(cpi->mode)
	{
	case MODE_2D:
		fprintf(ofp,"Media Type: 2D\n");
		break;
	case MODE_2DD:
		fprintf(ofp,"Media Type: 2DD\n");
		break;
	case MODE_2HD_1232K:
		fprintf(ofp,"Media Type: 2HD\n");
		break;
	}

	fprintf(ofp,"Start Track: %d\n",cpi->startTrk);
	fprintf(ofp,"End Track: %d\n",cpi->endTrk);
}

void WriteErrorLog(FILE *ofp,struct CommandParameterInfo *cpi)
{
	if(NULL!=errLog)
	{
		struct ErrorLog far *ptr;
		int nCRCError=0,nCRCErrorNotF5F6F7=0,nLostDataAddr=0,nLostDataData=0,nReadTrackErr=0;;
		fprintf(ofp,"Error Summary\n");

		for(ptr=errLog; NULL!=ptr; ptr=ptr->next)
		{
			if(ERRORLOG_TYPE_CRC==ptr->errType)
			{
				if(0==nCRCError)
				{
					fprintf(ofp,"CRC Error: ");
				}
				fprintf(ofp,"%02x%02x%02x ",ptr->idMark.chrn[0],ptr->idMark.chrn[1],ptr->idMark.chrn[2]);
				++nCRCError;
				if(0xF5!=ptr->idMark.chrn[2] && 0xF6!=ptr->idMark.chrn[2] && 0xF7!=ptr->idMark.chrn[2])
				{
					++nCRCErrorNotF5F6F7;
				}
			}
		}
		if(0<nCRCError)
		{
			fprintf(ofp,"\n");
		}

		for(ptr=errLog; NULL!=ptr; ptr=ptr->next)
		{
			if(ERRORLOG_TYPE_LOSTDATA_READADDR==ptr->errType)
			{
				if(0==nLostDataAddr)
				{
					fprintf(ofp,"Lost Data in Read ID Mark: ");
				}
				fprintf(ofp,"%02x%02x ",ptr->idMark.chrn[0],ptr->idMark.chrn[1]);
				++nLostDataAddr;
			}
		}
		if(0<nLostDataAddr)
		{
			fprintf(ofp,"\n");
		}

		for(ptr=errLog; NULL!=ptr; ptr=ptr->next)
		{
			if(ERRORLOG_TYPE_LOSTDATA==ptr->errType)
			{
				if(0==nLostDataAddr)
				{
					fprintf(ofp,"Lost Data in Read Sector: ");
				}
				fprintf(ofp,"%02x%02x ",ptr->idMark.chrn[0],ptr->idMark.chrn[1]);
				++nLostDataData;
			}
		}
		if(0<nLostDataData)
		{
			fprintf(ofp,"\n");
		}

		for(ptr=errLog; NULL!=ptr; ptr=ptr->next)
		{
			if(ERRORLOG_TYPE_READ_TRACK==ptr->errType)
			{
				if(0==nReadTrackErr)
				{
					fprintf(ofp,"Read Track Error: ");
				}
				fprintf(ofp,"%02x%02x ",ptr->idMark.chrn[0],ptr->idMark.chrn[1]);
				++nReadTrackErr;
			}
		}
		if(0<nReadTrackErr)
		{
			fprintf(ofp,"\n");
		}

		fprintf(ofp,"%d CRC Errors.\n",nCRCError);
		fprintf(ofp,"%d CRC Errors in not F5,F6,F7 sectors.\n",nCRCErrorNotF5F6F7);
		fprintf(ofp,"%d LostData Errors in Read ID Mark.\n",nLostDataAddr);
		fprintf(ofp,"%d LostData Errors in Read Sector.\n",nLostDataData);
		fprintf(ofp,"%d Read-Track Error.\n",nReadTrackErr);
	}
	else
	{
		fprintf(ofp,"No Error.\n");
	}
}

void ReadDisk(struct CommandParameterInfo *cpi)
{
	int C;

	if(0!=cpi->logFName[0])
	{
		FILE *ofp=fopen(cpi->logFName,"a");
		if(NULL!=ofp)
		{
			WriteInfoLog(ofp,cpi);
			fclose(ofp);
		}
	}

	for(C=cpi->startTrk; C<=cpi->endTrk; ++C)
	{
		PrintDebugLine();
		FDC_Seek(C);
		ReadTrack(C,0,cpi);
		ReadTrack(C,1,cpi);
	}

	WriteErrorLog(stdout,cpi);

	if(0!=cpi->logFName[0])
	{
		FILE *ofp=fopen(cpi->logFName,"a");
		if(NULL!=ofp)
		{
			WriteErrorLog(ofp,cpi);
			fclose(ofp);
		}
	}
}

////////////////////////////////////////////////////////////


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
		printf("  FDDUMP A: 1232KB [options]\n");
		printf("    A:      Drive\n");
		printf("    1232KB  Disk Type\n");
		printf("  Disk Type can be one of:\n");
		printf("    2D,320KB         2D Disk (from FM-7)\n");
		printf("    2DD,640KB,720KB  2DD Disk\n");
		printf("    2HD,1232KB       2HD 1232K Disk\n");
		printf("    (For 1440KB, use 2HD.)\n");
		printf("  Options:\n");
		printf("    -starttrk trackNum  Start track (Between 0 and 76 if 2HD)\n");
		printf("    -endtrk   trackNum  End track (Between 0 and 76 if 2HD)\n");
		//printf("    -listonly           List track info only.  No RS232C transmission\n");
		printf("    -out filename.rdd   Save image to .rdd (Real Disk Dump) file.\n");
		//printf("    -19200bps           Transmit the image at 19200bps\n");
		//printf("    -38400bps           Transmit the image at 38400bps\n");
		printf("    -name diskName      Specify disk name up to 16 chars.\n");
		//printf("    -writeprotect       Write protect the disk image.\n");
		printf("    -dontsort           Don't sort sectors (preserve interleave).\n");
		printf("    -sort               Sort sectors.\n");
		printf("    -log filename.txt   Write log file.\n");
		return 1;
	}

	INT_GetEnableBits(default_INT_EnableBits);

	if(0==FreeRunTimerAvailable())
	{
		Color(2);
		printf("This program requires Free-Run timer.\n");
		printf("Needs to be FM TOWNS 2 UG or newer.\n");
		Color(7);
		return 1;
	}

	{
		// I don't know what timer does bad for FDC, but at the beginning of Read Sector BIOS Call,
		// it was cancelling two timers.  So, I just disable timers and see.

		// Confirmed!  Unless I mask timer interrupt, FDC gets irresponsive, probably because Disk BIOS was using
		// timer for checking disk change, it did something to I/O, and messed up with FDC.

		static uint8_t INT_EnableBits[4];
		INT_GetEnableBits(INT_EnableBits);
		INT_EnableBits[3]&=0xFE; // Is it really [3] b0 for INT 0?  FM Towns Techncial Databook says so.
		INT_SetEnableBits(INT_EnableBits);
	}

	INT46_SaveHandler(default_INT46H_HandlerPtr);
	INT46_TakeOver();
	signal(SIGINT,CtrlC);

	SetDriveMode(cpi.drive,cpi.mode);

	// Looks like drive-ready should be checked after masking timer and/or taking over INT 46h,
	// or I keep getting FREADY=0 from I/O 0208h.
	if(0==CheckDriveReady())
	{
		Color(2);
		printf("Drive Not Ready.\n");
		Color(7);
		goto ERREND;
	}


	RestoreState=FDC_Restore(); // Can check write-protect
	if(RestoreState&0x80)
	{
		Color(2);
		printf("Restore command failed (Not Ready).\n");
		Color(7);
		goto ERREND;
	}
	if(RestoreState&0x10)
	{
		Color(2);
		printf("Restore command failed (Seek Error).\n");
		Color(7);
		goto ERREND;
	}

	if(0!=RDD_WriteSignature(cpi.outFName))
	{
		goto ERREND;
	}

	if(0!=RDD_WriteDiskHeader(cpi.outFName,RestoreState,cpi.mediaType,cpi.diskName))
	{
		goto ERREND;
	}

	ReadDisk(&cpi);

	RDD_WriteEndOfDisk(cpi.outFName);

	CleanUp();

	return 0;

ERREND:
	CleanUp();
	return 1;
}
