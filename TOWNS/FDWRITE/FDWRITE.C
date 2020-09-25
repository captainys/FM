#include <stdio.h>
#include <stdlib.h>
#include <fmcfrb.h>



enum
{
	FORMAT_UNKNOWN,
	FORMAT_640KB,
	FORMAT_720KB,
	FORMAT_1232KB,
	FORMAT_1440KB
};


const char *FormatToString(unsigned int fmt)
{
	switch(fmt)
	{
	case FORMAT_640KB:
		return "640KB";
	case FORMAT_720KB:
		return "720KB";
	case FORMAT_1232KB:
		return "1232KB";
	case FORMAT_1440KB:
		return "1440KB";
	}
	return "UNKNOWN";
}



// Max 1440KB
#define MAX_IMG_SIZE (1024*1440)
unsigned int imgSize=0;
unsigned char *img;
unsigned char testBuf[1024];

int ReadImageFile(const char fName[])
{
	FILE *ifp=fopen(fName,"rb");
	if(NULL!=ifp)
	{
		imgSize=fread(img,1,MAX_IMG_SIZE,ifp);
		fclose(ifp);
		return 0;
	}
	return 1;
}

int IdentifyFormatFromImageSize(unsigned int imgSize)
{
	if(640*1024==imgSize)
	{
		return FORMAT_640KB;
	}
	else if(720*1024==imgSize)
	{
		return FORMAT_720KB;
	}
	else if(1232*1024==imgSize)
	{
		return FORMAT_1232KB;
	}
	else if(1440*1024==imgSize)
	{
		return FORMAT_1440KB;
	}
	return FORMAT_UNKNOWN;
}

int IdentifyDestinationMediaFormat(int drive) // 0:A drive  1:B drive
{
	unsigned int devNo=0x20|drive;
	int secnum;

	DKB_restore(devNo);

	//   1232KB format 1024 bytes per sector,  8 sectors per track, 77 tracks
	//   1440KB format  512 bytes per sector, 18 sectors per track, 80 tracks
	//    640KB format  512 bytes per sector,  8 sectors per track, 80 tracks
	//    720KB format  512 bytes per sector,  9 sectors per track, 80 tracks

	DKB_setmode(devNo,0x83,0x28); // Double density, 2HD, 1024 bytes/sector, 2 sides, 8 sectors/track
	if(0==DKB_read(devNo,0,0,1,1,(char *)testBuf,&secnum))
	{
		return FORMAT_1232KB;
	}

	DKB_setmode(devNo,0x92,0x28); // Double density, 2HD, 1024 bytes/sector, 2 sides, 8 sectors/track
	if(0==DKB_read(devNo,0,0,9,1,(char *)testBuf,&secnum))
	{
		return FORMAT_720KB;
	}
	if(0==DKB_read(devNo,0,0,8,1,(char *)testBuf,&secnum))
	{
		return FORMAT_640KB;
	}

	return FORMAT_UNKNOWN;
}

int WriteDisk(unsigned int drive,unsigned int numTracks,unsigned int secPerTrack,unsigned int sectorLength)
{
	int secnum;
	unsigned int devNo=0x20|drive;
	unsigned char *imagePtr=img;
	for(int trk=0; trk<numTracks; ++trk)
	{
		for(int side=0; side<2; ++side)
		{
			printf("Track %d Side %d\n",trk,side);
			int err=DKB_write(devNo,trk,side,1,secPerTrack,(char *)imagePtr,&secnum);
			if(0!=err)
			{
				printf("Write Error! (Ignore error and continue) %d %d %d\n",err,secnum,secPerTrack);
			}
			imagePtr+=secPerTrack*sectorLength;
			if(imgSize<=imagePtr-img)
			{
				return 0;
			}
		}
	}
	return 0;
}

int main(int ac,char *av[])
{
	unsigned int diskImgFormat,mediaFormat,drive;
	if(ac!=3)
	{
		printf("Usage: run386 -nocrt fdwrite.exp A: image.bin\n");
		return 1;
	}

	img=(unsigned char *)malloc(MAX_IMG_SIZE);
	if(NULL==img)
	{
		printf("Not enough memory.\n");
	}

	if(0!=ReadImageFile(av[2]))
	{
		printf("Error while reading disk image.\n");
		return 1;
	}

	if('A'<=av[1][0] && av[1][0]<='D')
	{
		drive=av[1][0]-'A';
	}
	else if('a'<=av[1][0] && av[1][0]<='d')
	{
		drive=av[1][0]-'a';
	}
	else
	{
		printf("Error in the drive letter.\n");
		return 1;
	}

	diskImgFormat=IdentifyFormatFromImageSize(imgSize);
	printf("Disk Image Format=%s\n",FormatToString(diskImgFormat));
	mediaFormat=IdentifyDestinationMediaFormat(drive);
	printf("Destination Media Format=%s\n",FormatToString(mediaFormat));

	if(diskImgFormat!=FORMAT_UNKNOWN && diskImgFormat!=mediaFormat)
	{
		printf("Disk Image format and Media Format are incompatible.\n");
		return 1;
	}
	if(FORMAT_1440KB==diskImgFormat || FORMAT_1440KB==mediaFormat)
	{
		printf("1440KB disk is not supported at this time.\n");
		return 1;
	}

	//   1232KB format 1024 bytes per sector,  8 sectors per track, 77 tracks
	//   1440KB format  512 bytes per sector, 18 sectors per track, 80 tracks
	//    640KB format  512 bytes per sector,  8 sectors per track, 80 tracks
	//    720KB format  512 bytes per sector,  9 sectors per track, 80 tracks

	unsigned int numTracks,secPerTrack,sectorLength;
	switch(mediaFormat)
	{
	case FORMAT_640KB:
		numTracks=80;
		secPerTrack=8;
		sectorLength=512;
		break;
	case FORMAT_720KB:
		numTracks=80;
		secPerTrack=9;
		sectorLength=512;
		break;
	case FORMAT_1232KB:
		numTracks=77;
		secPerTrack=8;
		sectorLength=1024;
		break;
	case FORMAT_1440KB:
		numTracks=80;
		secPerTrack=18;
		sectorLength=512;
		break;
	}

	if(0!=WriteDisk(drive,numTracks,secPerTrack,sectorLength))
	{
		printf("There were errors.\n");
		return 1;
	}
	printf("Completed.\n");
	return 0;
}
