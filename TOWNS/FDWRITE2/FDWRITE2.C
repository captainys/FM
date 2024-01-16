#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <dos.h>
#include <signal.h>
#include "DISKIMG.H"
#include "DEF.H"
#include "DMABUF.H"
#include "FDC.H"
#include "PIC.H"
#include "TIMER.H"
#include "UTIL.H"
#include "CONSOLE.H"


#define VERSION 20240115


static struct bufferInfo DMABuf;
static _Handler default_INT46H_Handler;
static struct PICMask default_PICMask;



void PrintHelp(void)
{
	printf("Usage:\n");
	printf("  RUN386 -nocrt FDWRITE2 A: IMAGE.D77/RDD\n");
}

void PrintError(int err)
{
	switch(err)
	{
	case ERROR_NONE:
		fprintf(stderr,"No Error\n");
		break;
	case ERROR_OPEN_FILE:
		fprintf(stderr,"Error: Cannot open file.\n");
		break;
	case ERROR_TOO_SHORT:
		fprintf(stderr,"Error: Too short image file.\n");
		break;
	case ERROR_TOO_MANY_TRACKS:
		fprintf(stderr,"Error: Too many tracks.\n");
		break;
	case ERROR_DRIVE_LETTER:
		fprintf(stderr,"Error: Unsupported drive letter.\n");
		break;
	case ERROR_TOO_FEW_PARAMETERS:
		fprintf(stderr,"Error: Too few command arguments.\n");
		break;
	case ERROR_NOT_OPEN:
		fprintf(stderr,"Error: File not open.\n");
		break;
	case ERROR_TRACK_OUT_OF_RANGE:
		fprintf(stderr,"Error: Track number out of range.\n");
		break;
	case ERROR_OUT_OF_MEMORY:
		fprintf(stderr,"Error: Out of memory.\n");
		break;
	case ERROR_BROKEN_DATA:
		fprintf(stderr,"Error: Broken data.\n");
		break;
	case ERROR_1D_1DD_NOT_SUPPORTED:
		fprintf(stderr,"Error: 1D/1DD not supported.\n");
		break;
	case ERROR_2D_NOT_SUPPORTED:
		fprintf(stderr,"Error: 2D not supported.\n");
		break;
	case ERROR_2HD_1440KB_NOT_SUPPORTED:
		fprintf(stderr,"Error: 144KB not supported.\n");
		break;
	case ERROR_DISK_IMAGE_IS_ON_FD:
		fprintf(stderr,"Error: Disk Image cannot be on a floppy-disk.\n");
		break;
	case ERROR_DRIVE_NOT_READY:
		fprintf(stderr,"Error: Drive not ready.\n");
		break;
	}
}

void CleanUp(void)
{
	int i;
	struct FDC_IOConfig cfg;

	_setpvect(INT_FDC,default_INT46H_Handler);
	FDC_Command(FDCCMD_RESTORE_HEAD_UNLOAD);
	
	cfg=FDC_GetIOConfig(0,MODE_2HD_1232K);
	FDC_SetMFM(&cfg,1);
	cfg.controlByte&=~CTL_MOTOR;
	cfg.speedByte&=~SPD_INUSE;
	FDC_SelectDrive(cfg);
	FDC_WriteDriveControl(cfg,0);

	PIC_SetMask(default_PICMask);
	
	Color(7);
	PrintSysCharWord("        ",1,7);
	PrintSysCharWord("        ",9,7);
	PrintSysCharWord("        ",17,7);
	PrintSysCharWord("        ",25,7);
	for(i=0; i<8; ++i)
	{
		unsigned char r=(i&2 ? 255 : 0);
		unsigned char g=(i&4 ? 255 : 0);
		unsigned char b=(i&1 ? 255 : 0);
		Palette(i,r,g,b);
	}
}

void CtrlC(int err)
{
	// Color(7);
	CleanUp();
	printf("Intercepted Ctrl+C\n");
	exit(1);
}

struct CommandParameterInfo
{
	char target_drive;
	char imageFileName[_MAX_PATH];
};

int RecognizeCommandParameterInfo(struct CommandParameterInfo *cpi,int ac,char *av[])
{
	if(ac<3)
	{
		return ERROR_TOO_FEW_PARAMETERS;
	}

	for(int i=1; i<ac; ++i)
	{
		if(0==strcmp(av[i],"-HELP") || 0==strcmp(av[i],"-H") || 0==strcmp(av[i],"-help") || 0==strcmp(av[i],"-h") || 0==strcmp(av[i],"-?"))
		{
			PrintHelp();
			return ERROR_PRINTED_HELP;
		}
	}

	if(':'!=av[1][1])
	{
		return ERROR_DRIVE_LETTER;
	}

	cpi->target_drive=toupper(av[1][0]);
	if('A'!=cpi->target_drive && 'B'!=cpi->target_drive)
	{
		fprintf(stderr,"Drive letter needs to be A or B.\n");
		return ERROR_DRIVE_LETTER;
	}

	strncpy(cpi->imageFileName,av[2],_MAX_PATH-1);
	cpi->imageFileName[_MAX_PATH-1]=0;

	return ERROR_NONE;
}

void MakeFormatData(unsigned char formatData[],size_t max_len,size_t formatLen,TRACK *track)
{
	unsigned int len;
	int crunchLevel;
	for(crunchLevel=0; crunchLevel<3; ++crunchLevel)
	{
		Track_MakeFormatData(&len,formatData,max_len,track,crunchLevel);
		if(len<=formatLen)
		{
			break;
		}
		printf("Overbyte (%d/%d).  Crunch %d\n",len,formatLen,crunchLevel);
	}

	if(3==crunchLevel) // Could not fit all sectors
	{
		// If 1024-byte sector x8 and smaller sectors, try shrinking smaller sectors.
		int i;
		int num1024byte=0,numSmall=0;
		for(i=0; i<track->numAddrMarks; ++i)
		{
			if(3==track->addrMarks[i].CHRN[3])
			{
				++num1024byte;
			}
			else
			{
				++numSmall;
			}
		}
		if(8==num1024byte)
		{
			for(i=0; i<track->numAddrMarks; ++i)
			{
				if(3!=track->addrMarks[i].CHRN[3])
				{
					track->addrMarks[i].CHRN[3]=0; // Make it a 128-byte sector.
				}
			}
			for(i=0; i<track->numSectors; ++i)
			{
				if(3!=track->sectors[i].CHRN[3])
				{
					track->sectors[i].CHRN[3]=0; // Make it a 128-byte sector.
				}
			}

			for(crunchLevel=0; crunchLevel<3; ++crunchLevel)
			{
				Track_MakeFormatData(&len,formatData,max_len,track,crunchLevel);
				if(len<=formatLen)
				{
					printf("Fits (%d/%d)\n",len,formatLen);
					break;
				}
				printf("Still Overbyte (%d/%d).  Crunch %d\n",len,formatLen,crunchLevel);
			}
		}
	}

}

void WriteSectors(struct FDC_IOConfig fdcConfig,struct bufferInfo DMABuf,TRACK *track)
{
	int sec;
	for(sec=0; sec<track->numSectors; ++sec)
	{
		if(0==(track->sectors[sec].flags&FLAG_RECORD_NOT_FOUND))
		{
			FDC_WriteSector(fdcConfig,DMABuf,
					track->sectors[sec].CHRN[0],
					track->sectors[sec].CHRN[1],
					track->sectors[sec].CHRN[2],
					track->sectors[sec].CHRN[3],
					track->sectors[sec].numBytes,
					track->sectors[sec].data,
					0!=(track->sectors[sec].flags&FLAG_DELETED_DATA),
					0!=(track->sectors[sec].flags&FLAG_CRC_ERROR));
		}
	}
}

int WriteBackD77(struct CommandParameterInfo *cpi)
{
	int err;
	int trackPos;
	struct FDC_IOConfig fdcConfig;
	static unsigned char formatData[FORMAT_LEN_MAX];

	D77READER *reader=D77Reader_Create();

	err=D77Reader_Begin(reader,cpi->imageFileName);
	if(ERROR_NONE!=err)
	{
		D77Reader_Destroy(reader);
		return err;
	}

	err=VerifyDiskWritable(&reader->prop);
	if(ERROR_NONE!=err)
	{
		D77Reader_Destroy(reader);
		return err;
	}

	unsigned int mode=MODE_2HD_1232K,formatLen=FORMAT_LEN_2HD_1232KB;
	switch(reader->prop.mediaType)
	{
	case D77_MEDIATYPE_2HD:
		mode=MODE_2HD_1232K;
		formatLen=FORMAT_LEN_2HD_1232KB;
		printf("2HD Disk\n");
		break;
	case D77_MEDIATYPE_2D:
		mode=MODE_2D;
		formatLen=FORMAT_LEN_2DD;
		printf("2D Disk\n");
		break;
	case D77_MEDIATYPE_2DD:
		mode=MODE_2DD;
		formatLen=FORMAT_LEN_2DD;
		printf("2DD Disk\n");
		break;
	}

	fdcConfig=FDC_GetIOConfig(cpi->target_drive-'A',mode);

	if(0==FDC_CheckDriveReady(fdcConfig))
	{
		Color(2);
		printf("Drive Not Ready.\n");
		Color(7);
		return ERROR_DRIVE_NOT_READY;
	}

	FDC_Restore(fdcConfig);
	for(trackPos=0; trackPos<reader->prop.numTracks; ++trackPos)
	{
		unsigned long bytesWritten;
		TRACK trk;
		D77Reader_ReadTrack(&trk,reader,trackPos);

		if(D77_MEDIATYPE_2HD==reader->prop.mediaType)
		{
			unsigned int kb=IdentifyDiskSizeInKB(&reader->prop,&trk);
			if(1440==kb)
			{
				mode=MODE_2HD_1440K;
				formatLen=FORMAT_LEN_2HD_1440KB;
				if(0==FDC_Support1440KB())
				{
					err=ERROR_2HD_1440KB_NOT_SUPPORTED;
					break;
				}
			}
			else
			{
				mode=MODE_2HD_1232K;
				formatLen=FORMAT_LEN_2HD_1232KB;
			}
		}
		fdcConfig=FDC_GetIOConfig(cpi->target_drive-'A',mode);
		FDC_SetSide(&fdcConfig,trk.H);
		FDC_SetMFM(&fdcConfig,(trk.density==DENSITY_MFM));

		Track_Print(&trk);

		MakeFormatData(formatData,FORMAT_LEN_MAX,formatLen,&trk);

		FDC_Seek(fdcConfig,trk.C);
		FDC_WriteTrack(&bytesWritten,fdcConfig,DMABuf,formatLen,formatData);

		WriteSectors(fdcConfig,DMABuf,&trk);

		Track_Destroy(&trk);
	}

	D77Reader_Destroy(reader);

	return ERROR_NONE;
}

int WriteBackRDD(struct CommandParameterInfo *cpi)
{
	int err;
	unsigned char FDCStatus;
	struct FDC_IOConfig fdcConfig;
	static unsigned char formatData[FORMAT_LEN_MAX];

	RDDREADER *reader=RDDReader_Create();

	err=RDDReader_Begin(reader,cpi->imageFileName);
	if(ERROR_NONE!=err)
	{
		RDDReader_Destroy(reader);
		return err;
	}

	err=VerifyDiskWritable(&reader->prop);
	if(ERROR_NONE!=err)
	{
		RDDReader_Destroy(reader);
		return err;
	}

	unsigned int mode=MODE_2HD_1232K,formatLen=FORMAT_LEN_2HD_1232KB;
	switch(reader->prop.mediaType)
	{
	case D77_MEDIATYPE_2HD:
		mode=MODE_2HD_1232K;
		formatLen=FORMAT_LEN_2HD_1232KB;
		printf("2HD Disk\n");
		break;
	case D77_MEDIATYPE_2D:
		mode=MODE_2D;
		formatLen=FORMAT_LEN_2DD;
		printf("2D Disk\n");
		break;
	case D77_MEDIATYPE_2DD:
		mode=MODE_2DD;
		formatLen=FORMAT_LEN_2DD;
		printf("2DD Disk\n");
		break;
	}

	fdcConfig=FDC_GetIOConfig(cpi->target_drive-'A',mode);

	if(0==FDC_CheckDriveReady(fdcConfig))
	{
		Color(2);
		printf("Drive Not Ready.\n");
		Color(7);
		return ERROR_DRIVE_NOT_READY;
	}

	FDC_Restore(fdcConfig);

	while(1)
	{
		unsigned long bytesWritten;
		TRACK trk;
		err=RDDReader_ReadTrack(&trk,reader);
		if(ERROR_NONE!=err)
		{
			break;
		}

		if(D77_MEDIATYPE_2HD==reader->prop.mediaType)
		{
			unsigned int kb=IdentifyDiskSizeInKB(&reader->prop,&trk);
			if(1440==kb)
			{
				mode=MODE_2HD_1440K;
				formatLen=FORMAT_LEN_2HD_1440KB;
				if(0==FDC_Support1440KB())
				{
					err=ERROR_2HD_1440KB_NOT_SUPPORTED;
					break;
				}
			}
			else
			{
				mode=MODE_2HD_1232K;
				formatLen=FORMAT_LEN_2HD_1232KB;
			}
		}
		fdcConfig=FDC_GetIOConfig(cpi->target_drive-'A',mode);
		FDC_SetSide(&fdcConfig,trk.H);
		FDC_SetMFM(&fdcConfig,(trk.density==DENSITY_MFM));

		Track_Print(&trk);

		MakeFormatData(formatData,FORMAT_LEN_MAX,formatLen,&trk);

		FDCStatus=FDC_Seek(fdcConfig,trk.C);

		// printf("Seek Returned %02x\n",FDCStatus);

		FDCStatus=FDC_WriteTrack(&bytesWritten,fdcConfig,DMABuf,formatLen,formatData);

		// printf("Format Returned %02x  %d bytes written.\n",FDCStatus,bytesWritten);

		WriteSectors(fdcConfig,DMABuf,&trk);

		Track_Destroy(&trk);
	}

	RDDReader_Destroy(reader);

	return ERROR_NONE;
}

int WriteBackBIN(struct CommandParameterInfo *cpi)
{
	int err=0,trackPos=0;
	struct FDC_IOConfig fdcConfig;
	static unsigned char formatData[FORMAT_LEN_MAX];

	BINREADER *reader=BINReader_Create();

	err=BINReader_Begin(reader,cpi->imageFileName);
	if(ERROR_NONE!=err)
	{
		BINReader_Destroy(reader);
		return err;
	}

	err=VerifyDiskWritable(&reader->prop);
	if(ERROR_NONE!=err)
	{
		BINReader_Destroy(reader);
		return err;
	}

	unsigned int mode=MODE_2HD_1232K,formatLen=FORMAT_LEN_2HD_1232KB;
	switch(reader->fileSize)
	{
	case FILESIZE_2DD_640KB:
		mode=MODE_2DD;
		formatLen=FORMAT_LEN_2DD;
		break;
	case FILESIZE_2DD_720KB:
		mode=MODE_2DD;
		formatLen=FORMAT_LEN_2DD;
		break;
	case FILESIZE_2HD_1440KB:
		mode=MODE_2HD_1440K;
		formatLen=FORMAT_LEN_2HD_1440KB;
		if(0==FDC_Support1440KB())
		{
			return ERROR_2HD_1440KB_NOT_SUPPORTED;
		}
		break;
	case FILESIZE_2HD_1232KB:
		mode=MODE_2HD_1232K;
		formatLen=FORMAT_LEN_2HD_1232KB;
		break;
	}

	fdcConfig=FDC_GetIOConfig(cpi->target_drive-'A',mode);

	if(0==FDC_CheckDriveReady(fdcConfig))
	{
		Color(2);
		printf("Drive Not Ready.\n");
		Color(7);
		return ERROR_DRIVE_NOT_READY;
	}

	FDC_Restore(fdcConfig);
	for(trackPos=0; trackPos<reader->prop.numTracks; ++trackPos)
	{
		unsigned long bytesWritten;
		TRACK trk;
		err=BINReader_ReadTrack(&trk,reader);
		if(ERROR_NONE!=err)
		{
			break;
		}

		fdcConfig=FDC_GetIOConfig(cpi->target_drive-'A',mode);
		FDC_SetSide(&fdcConfig,trk.H);
		FDC_SetMFM(&fdcConfig,1);

		Track_Print(&trk);

		MakeFormatData(formatData,FORMAT_LEN_MAX,formatLen,&trk);

		FDC_Seek(fdcConfig,trk.C);
		FDC_WriteTrack(&bytesWritten,fdcConfig,DMABuf,formatLen,formatData);

		WriteSectors(fdcConfig,DMABuf,&trk);

		WriteSectors(fdcConfig,DMABuf,&trk);

		Track_Destroy(&trk);
	}

	BINReader_Destroy(reader);

	return ERROR_NONE;
}

int main(int ac,char *av[])
{
	printf("FDWRITE2.EXP - RDD/D77/BIN Floppy-Disk Write-Back Utility\n");
	printf("  Version %d\n",VERSION);
	printf("  by CaptainYS http://www.ysflight.com\n");

	int err=ERROR_NONE;

	struct CommandParameterInfo cpi;
	err=RecognizeCommandParameterInfo(&cpi,ac,av);
	if(ERROR_NONE!=err)
	{
		PrintError(err);
		return 1;
	}

	DMABuf=MakeDataBuffer();

	default_INT46H_Handler=_getpvect(INT_FDC);
	FDC_TakeOverINT46H();
	default_PICMask=PIC_GetMask();
	signal(SIGINT,CtrlC);


	{
		// Based on my memo in FDDUMP.C

		// I don't know what timer does bad for FDC, but at the beginning of Read Sector BIOS Call,
		// it was cancelling two timers.  So, I just disable timers and see.

		// Confirmed!  Unless I mask timer interrupt, FDC gets irresponsive, probably because Disk BIOS was using
		// timer for checking disk change, it did something to I/O, and messed up with FDC.

		struct PICMask picmask=PIC_GetMask();
		picmask.m[0]|=1;
		PIC_SetMask(picmask);
	}

	switch(IdentifyFileType(cpi.imageFileName))
	{
	case FILETYPE_D77:
		err=WriteBackD77(&cpi);
		break;
	case FILETYPE_RDD:
		err=WriteBackRDD(&cpi);
		break;
	case FILETYPE_BIN:
		err=WriteBackBIN(&cpi);
		break;
	default:
		err=ERROR_UNSUPPORTED_FILE_TYPE;
		goto ERREND;
	}

	CleanUp();

	if(ERROR_NONE!=err)
	{
		PrintError(err);
		return 1;
	}

	return 0;

ERREND:
	CleanUp();
	return 1;
}
