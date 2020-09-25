#include <stdio.h>
#include <stdlib.h>



int main(int ac,char *av[])
{
	int i;
	unsigned int startByte,length;
	unsigned char *dat;
	FILE *ifp,*ofp;

	if(5!=ac)
	{
		printf("Usage: RUN386 CUTOUT.EXP source.bin startByte length output.bin\n");
		return 1;
	}

	startByte=atoi(av[2]);
	length=atoi(av[3]);

	dat=(unsigned char *)malloc(length);
	for(i=0; i<length; ++i)
	{
		dat[i]=0;
	}

	ifp=fopen(av[1],"rb");
	if(NULL==ifp)
	{
		fprintf(stderr,"Cannot open input file.\n");
		return 1;
	}

	fseek(ifp,startByte,SEEK_SET);
	fread(dat,1,length,ifp);
	fclose(ifp);

	ofp=fopen(av[4],"wb");
	if(NULL==ofp)
	{
		fprintf(stderr,"Cannot open output file.\n");
		return 1;
	}
	fwrite(dat,1,length,ofp);
	fclose(ofp);
	return 0;
}
