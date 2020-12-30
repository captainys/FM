#include "FMCFRB.H"



struct D77Header
{
	char diskName[17];             // +0
	char reserveBytes[9];          // +0x11
	unsigned char writeProtected;  // +0x1A
	unsigned char mediaType;       // +0x1B
	unsigned int diskSize;         // +0x1C
	// Must be 0x20 bytes.
};

void InitializeD77Header(struct D77Header *hdr)
{
	unsigned char *ptr=(unsigned char *)hdr;
	for(int i=0; i<sizeof(struct D77Header); ++i)
	{
		ptr[i]=0;
	}
}

enum
{
	MODE_2D,       // 320K
	MODE_2DD,      // 640/720K
	MODE_2HD_1232K,// 1232K
};

#define MODE1_MFM_MODE          0x00
#define MODE1_FM_MODE           0x80
#define MODE1_2HD               0x00
#define MODE1_2DD               0x10
#define MODE1_2D                0x20
#define MODE1_128_BYTE_PER_SEC  0x00
#define MODE1_256_BYTE_PER_SEC  0x01
#define MODE1_512_BYTE_PER_SEC  0x02
#define MODE1_1024_BYTE_PER_SEC 0x03

void SetDriveMode(unsigned int drive,unsigned int mode)
{
	drive&=0x0F;
	drive|=0x20;

	switch(mode)
	{
	case MODE_2D:
		DKB_setmode(drive,MODE1_MFM_MODE|MODE1_2D|MODE1_256_BYTE_PER_SEC,0x2F);
		break;
	case MODE_2DD:
		DKB_setmode(drive,MODE1_MFM_MODE|MODE1_2DD|MODE1_512_BYTE_PER_SEC,0x28);
		break;
	case MODE_2HD_1232K:
		DKB_setmode(drive,MODE1_MFM_MODE|MODE1_2HD|MODE1_1024_BYTE_PER_SEC,0x28);
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
};

int Run(struct CommandParameterInfo *cpi,unsigned char d77Image[])
{
	unsigned int devNo;

	cpi->drive&=0x0F;
	devNo=0x20|cpi->drive;
	SetDriveMode(cpi->drive,MODE_2HD_1232K);

	DKB_restore(devNo);
}

void InitializeCommandParameterInfo(struct CommandParameterInfo *cpi)
{
	cpi->listOnly=0;
	cpi->drive=0;
	cpi->mode=MODE_2HD_1232K;
	cpi->baudRate=38400;
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
	else if('a'<=cpi->drive && cpi->drive<='a')
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
		hdr->mediaType=0;
	}
	else if(0==strcmp(av[2],"2DD") || 0==strcmp(av[2],"2dd") ||
	        0==strcmp(av[2],"640KB") || 0==strcmp(av[2],"640kb") ||
	        0==strcmp(av[2],"720KB") || 0==strcmp(av[2],"720kb"))
	{
		cpi->mode=MODE_2DD;
		hdr->mediaType=0x10;
	}
	else if(0==strcmp(av[2],"2HD") || 0==strcmp(av[2],"2hd") ||
	        0==strcmp(av[2],"1232KB") || 0==strcmp(av[2],"1232kb"))
	{
		cpi->mode=MODE_2HD_1232K;
		hdr->mediaType=0x20;
	}

	for(int i=3; i<ac; ++i)
	{
		if(0==strcmp(av[i],"-STARTTRK") || 0==strcmp(av[i],"-starttrk"))
		{
			if(i+1<ac)
			{
				cpi->startTrk=atoi(av[i+1]);
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
			}
			else
			{
				fprintf(stderr,"Too few arguments for %s\n",av[i]);
				return -1;
			}
		}
		else if(0==strcmp(av[i],"-WRITEPROTECT") || 0==strcmp(av[i],"-writeprotect"))
		{
			if(i+1<ac)
			{
				hdr->writeProtected=1;
			}
			else
			{
				fprintf(stderr,"Too few arguments for %s\n",av[i]);
				return -1;
			}
		}
	}

	return 0;
}

int main(int ac,char *av[])
{
	unsigned char *d77Image=(unsigned char *)malloc(1600*1024);
	if(NULL==d77Image)
	{
		printf("Out of memory.\n");
		printf("Cannot allocate memory for making D77 image.\n");
		return 0;
	}
	struct D77Header *hdr=(struct D77Header *)d77Image;


	struct CommandParameterInfo cpi;
	if(ac<3 || 0!=RecognizeCommandParameter(&cpi,hdr,ac,av))
	{
		printf("Make D77 file and send to RS232C\n");
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
		printf("  Options:
		printf("    -starttrk trackNum  Start track (Between 0 and 76 if 2HD)\n");
		printf("    -endtrk   trackNum  End track (Between 0 and 76 if 2HD)\n");
		printf("    -listonly           List track info only.  No RS232C transmission\n");
		printf("    -19200bps           Slow down to 19200bps (default 38400bps)\n");
		printf("    -38400bps           Transmit at 38400bps (default)\n");
		printf("    -name diskName      Specify disk name up to 16 chars.\n");
		printf("    -writeprotect       Write protect the disk image.\n");
	}

	return Run(&cpi,d77Image);
}
