#ifndef FDC_H_IS_INCLUDED
#define FDC_H_IS_INCLUDED

#include "DMABUF.H"

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
#define FDCCMD_WRITETRACK		0xF0
#define FDCCMD_READSECTOR		0x80
#define FDCCMD_WRITESECTOR		0xA0
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

#define DRIVE_MOTOR_WAIT_TIME	2000000
#define READADDR_TIMEOUT		1000000
#define READADDR_TRACK_TIMEOUT  3000000
#define READTRACK_TIMEOUT		3000000
#define WRITETRACK_TIMEOUT		3000000
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

#define INT_FDC 0x46

struct FDC_IOConfig
{
	unsigned char drvSel,controlByte,speedByte,seekStep;
};

void FDC_TakeOverINT46H(void);
struct FDC_IOConfig FDC_GetIOConfig(unsigned int drive,unsigned int mode);
int FDC_GetNumberOfCylinders(unsigned int mode);
void FDC_SelectDrive(struct FDC_IOConfig cfg);
void FDC_WriteDriveControl(struct FDC_IOConfig cfg,unsigned char IRQEN);
unsigned char FDC_ReadDriveStatusIO(void);
int FDC_CheckDriveReady(struct FDC_IOConfig cfg);
unsigned int  FDC_WaitReady(void);
void FDC_Command(unsigned char cmd);
void FDC_WaitIndexHole(void);
unsigned char FDC_Restore(struct FDC_IOConfig cfg);
unsigned char FDC_Seek(struct FDC_IOConfig cfg,unsigned char C);
unsigned char FDC_ReadAddress(struct FDC_IOConfig cfg,struct bufferInfo DMABuf,unsigned int  *accumTime);
unsigned char FDC_ReadSectorReal(struct FDC_IOConfig cfg,struct bufferInfo DMABuf,unsigned int  *accumTime,unsigned char C,unsigned char H,unsigned char R,unsigned char N);
unsigned char FDC_ReadSector(struct FDC_IOConfig cfg,struct bufferInfo DMABuf,unsigned int  *accumTime,unsigned char C,unsigned char H,unsigned char R,unsigned char N);
unsigned char FDC_ReadTrack(struct FDC_IOConfig cfg,struct bufferInfo DMABuf,unsigned short *readSize);
unsigned char FDC_WriteTrack(unsigned long *writeSize,struct FDC_IOConfig cfg,struct bufferInfo DMABuf,unsigned int len,unsigned char data[]);
unsigned char FDC_WriteSector(struct FDC_IOConfig cfg,struct bufferInfo DMABuf,
    unsigned char C,unsigned char H,unsigned char R,unsigned char N,
    unsigned int len,const unsigned char data[],
    unsigned char deletedData,unsigned char crcError);


#endif
