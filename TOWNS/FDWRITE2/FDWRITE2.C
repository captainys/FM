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



static struct bufferInfo DMABuf;
static unsigned char formatData[FORMAT_LEN_MAX];
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
	}
}

void CleanUp(void)
{
	int i;
	_setpvect(INT_FDC,default_INT46H_Handler);
//	FDC_Command(FDCCMD_RESTORE_HEAD_UNLOAD);
//	
//	controlByte&=~CTL_MOTOR;
//	speedByte&=~SPD_INUSE;
//	SelectDrive();
//	WriteDriveControl(0);
//	
	PIC_SetMask(default_PICMask);
//	
//	Color(7);
//	PrintSysCharWord("        ",1,7);
//	PrintSysCharWord("        ",9,7);
//	PrintSysCharWord("        ",17,7);
//	PrintSysCharWord("        ",25,7);
	for(i=0; i<8; ++i)
	{
//		unsigned char r=(i&2 ? 255 : 0);
//		unsigned char g=(i&4 ? 255 : 0);
//		unsigned char b=(i&1 ? 255 : 0);
//		Palette(i,r,g,b);
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
		break;
	case D77_MEDIATYPE_2D:
		mode=MODE_2D;
		formatLen=FORMAT_LEN_2DD;
		break;
	case D77_MEDIATYPE_2DD:
		mode=MODE_2DD;
		formatLen=FORMAT_LEN_2DD;
		break;
	}

	fdcConfig=FDC_GetIOConfig(cpi->target_drive-'A',mode);
	FDC_Restore(fdcConfig);
	for(trackPos=0; trackPos<reader->prop.numTracks; ++trackPos)
	{
		int i;
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
			}
			else
			{
				mode=MODE_2HD_1232K;
				formatLen=FORMAT_LEN_2HD_1232KB;
			}
		}
		fdcConfig=FDC_GetIOConfig(cpi->target_drive-'A',mode);
		FDC_SetSide(&fdcConfig,trk.H);

		printf("C%02d H%02d\n",trk.C,trk.H);
		for(i=0; i<trk.numAddrMarks; ++i)
		{
			printf("%02x%02x%02x%02x ",trk.addrMarks[i].CHRN[0],trk.addrMarks[i].CHRN[1],trk.addrMarks[i].CHRN[2],trk.addrMarks[i].CHRN[3]);
			if(7==i%8 || i+1==trk.numAddrMarks)
			{
				printf("\n");
			}
		}

		{
			int crunchLevel;
			for(crunchLevel=0; crunchLevel<3; ++crunchLevel)
			{
				unsigned int len;
				Track_MakeFormatData(&len,formatData,FORMAT_LEN_MAX,&trk,crunchLevel);
				if(len<=formatLen)
				{
					break;
				}
				printf("Crunch %d\n",crunchLevel);
			}
		}

		FDC_Seek(fdcConfig,trk.C);
		FDC_WriteTrack(&bytesWritten,fdcConfig,DMABuf,formatLen,formatData);

		{
			int sec;
			for(sec=0; sec<trk.numSectors; ++sec)
			{
				FDC_WriteSector(fdcConfig,DMABuf,
						trk.sectors[sec].CHRN[0],
						trk.sectors[sec].CHRN[1],
						trk.sectors[sec].CHRN[2],
						trk.sectors[sec].CHRN[3],
						trk.sectors[sec].numBytes,
						trk.sectors[sec].data,
						0!=(trk.sectors[sec].flags&FLAG_DELETED_DATA),
						0!=(trk.sectors[sec].flags&FLAG_CRC_ERROR));
			}
		}

		Track_Destroy(&trk);
	}

	D77Reader_Destroy(reader);

	return ERROR_NONE;
}

int main(int ac,char *av[])
{
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

	printf("Start\n");

	err=WriteBackD77(&cpi);
	if(ERROR_NONE!=err)
	{
		PrintError(err);
		return 1;
	}

	return 0;
}
