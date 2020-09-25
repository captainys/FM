#include <stdio.h>
#include <string.h>
#include <stdlib.h>



int main(int ac,char *av[])
{
	/* RUN386 LAYOUT.EXP output.bin output-size-in-KB input1.bin file-offset input2.bin file-offset ....
	     or
	   RUN386 LAYOUT.EXP output.bin OVERWRITE input1.bin file-offset input2.bin file-offset ....
	*/

	int i;
	unsigned int outputSize;
	unsigned char *outputBuf;
	FILE *ofp;

	char cap[64];
	strncpy(cap,av[2],63);
	cap[63]=0;
	for(i=0; 0!=cap[i]; ++i)
	{
		if('a'<=cap[i] && cap[i]<='z')
		{
			cap[i]=cap[i]+'A'-'a';
		}
	}
	if(0==strcmp(cap,"OVERWRITE"))
	{
		FILE *ifp;
		printf("Overwrite Mode\n");
		ifp=fopen(av[1],"rb");
		if(NULL==ifp)
		{
			fprintf(stderr,"Cannot open input file.\n");
			return 1;
		}

		fseek(ifp,0,SEEK_END);
		outputSize=ftell(ifp);
		fseek(ifp,0,SEEK_SET);

		outputBuf=malloc(outputSize);
		fread(outputBuf,1,outputSize,ifp);

		fclose(ifp);
	}
	else
	{
		outputSize=atoi(av[2])*1024;
		outputBuf=malloc(outputSize);
		for(i=0; i<outputSize; ++i)
		{
			outputBuf[i]=0;
		}
	}

	for(i=3; i+1<ac; i+=2)
	{
		unsigned int fileOffset=atoi(av[i+1]);
		FILE *ifp=fopen(av[i],"rb");
		if(NULL==ifp)
		{
			fprintf(stderr,"Cannot open %s\n",av[i]);
			return 1;
		}
		fread(outputBuf+fileOffset,1,outputSize-fileOffset,ifp);
		fclose(ifp);
	}

	ofp=fopen(av[1],"wb");
	if(NULL==ofp)
	{
		fprintf(stderr,"Cannot write %s\n",av[1]);
		return 1;
	}
	fwrite(outputBuf,1,outputSize,ofp);
	fclose(ofp);

	return 0;
}
