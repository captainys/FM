#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include "DISKIMG.H"
#include "DEF.H"



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
	}
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

int ProcessD77(struct CommandParameterInfo *cpi)
{
	int err;
	int trackPos;
	D77READER *reader=D77Reader_Create();

	err=D77Reader_Begin(reader,cpi->imageFileName);
	if(ERROR_NONE!=err)
	{
		D77Reader_Destroy(reader);
		return err;
	}

	for(trackPos=0; trackPos<reader->prop.numTracks; ++trackPos)
	{
		int i;
		TRACK trk;
		D77Reader_ReadTrack(&trk,reader,trackPos);

		printf("C%02d H%02d\n",trk.C,trk.H);

		for(i=0; i<trk.numAddrMarks; ++i)
		{
			printf("%02x%02x%02x%02x ",trk.addrMarks[i].CHRN[0],trk.addrMarks[i].CHRN[1],trk.addrMarks[i].CHRN[2],trk.addrMarks[i].CHRN[3]);
		}

		printf("\n");

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

	err=ProcessD77(&cpi);
	if(ERROR_NONE!=err)
	{
		PrintError(err);
		return 1;
	}

	return 0;
}
