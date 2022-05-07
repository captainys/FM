#include <stdio.h>
#include <cdrfrb.h>

unsigned char buf[2340];


int main(int ac,char *av[])
{
	printf("DMCD.EXP (Dump CD Sectors) by CaptainYS\n");
	printf("http://www.ysflight.com\n");
	if(ac<4)
	{
		printf("Usage:\n");
		printf("  RUN386 -nocrt DMCD.EXP output-file startSector sectorCount\n");
		return 1;
	}

	int sectorLen=2340;
	if(0!=cdr_sdrvmd(0,2340))
	{
		printf("Cannot set sector size to 2340.\n");
		printf("Dump 2048 bytes only.\n");
		cdr_sdrvmd(0,2048);
		sectorLen=2048;
	}


	FILE *fp=fopen(av[1],"wb");
	if(NULL==fp)
	{
		printf("Cannot open output file.\n");
		return 0;
	}


	int startSector=atoi(av[2]);
	int sectorCount=atoi(av[3]);
	printf("Output: %s\n",av[1]);
	printf("Start:  %d\n",startSector);
	printf("Count:  %d\n",sectorCount);
	for(int i=0; i<sectorCount; ++i)
	{
		if(0!=cdr_read(0,startSector+i,(char *)buf,1)) // deviceno, lsector, buffer, count
		{
			printf("Read Error at Sector %d\n",startSector+i);
		}
		printf("  Sector %d\n",startSector+i);
		fwrite(buf,1,sectorLen,fp);
	}
	fclose(fp);

	cdr_sdrvmd(0,2048);
	return 0;
}
