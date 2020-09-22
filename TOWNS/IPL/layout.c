#include <stdio.h>
#include <stdlib.h>



int main(int ac,char *av[])
{
	/* RUN386 LAYOUT.EXP output.bin output-size-in-KB input1.bin file-offset input2.bin file-offset ....
	*/

	int i;
	unsigned int outputSize=atoi(av[2])*1024;
	unsigned char *outputBuf=malloc(outputSize);
	FILE *ofp;
	for(i=0; i<outputSize; ++i)
	{
		outputBuf[i]=0;
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
