#include <stdio.h>
#include <stdlib.h>



const unsigned char patchFrom[]=
{
0x3e,0x8a,0x46,0x03,
0x2c,0x50,
0x8b,0xd8,
0x55,
0x8b,0x2e,0xe7,0x7e,
0x3e,0x89,0x5e,0x00,
0x83,0x06,0xe7,0x7e,0x02,
0x5d,
0x55,
0x8b,0x2e,0xe7,0x7e,
0x3e,0x89,0x7e,0x00,
0x83,0x06,0xe7,0x7e,0x02,
0x5d,
0xbe,0x45,0x7e,
0x3e,0x8a,0x46,0x07
};

const unsigned char patchTo[]=
{
0xCD,0x93,
0xC7,0x06,0xE5,0x7E,0x00,0x00,
0x80,0xFC,0x80,
0x3E,0x88,0x66,0x03,
0x75,0x04,
0x3E,0x89,0x4E,0x06,
0xE9,0x7B,0xFF
};

int ApplyPatch(
    int nByte,unsigned char byteData[],
    int nPatchFrom,const unsigned char patchFrom[],
    int nPatchTo,const unsigned char patchTo[])
{
	int nOccurrence=0;
	for(int i=0; i<nByte; ++i)
	{
		int found=1;
		for(int j=0; j<nPatchFrom && i+j<nByte; ++j)
		{
			if(byteData[i+j]!=patchFrom[j])
			{
				found=0;
				break;
			}
		}
		if(0!=found)
		{
			printf("Apply Patch at %08x\n",i);
			for(int j=0; j<nPatchTo; ++j)
			{
				byteData[i+j]=patchTo[j];
			}
			++nOccurrence;
		}
	}
	return nOccurrence;
}


int main(int ac,char *av[])
{
	if(3!=ac)
	{
		fprintf(stderr,"Usage: Patch source-file-name destination-file-name\n");
		return 1;
	}


	int nByte=0,nByteRead=0,nByteWritten=0;
	unsigned char *byteData=NULL;
	FILE *fp;

	fp=fopen(av[1],"rb");
	if(NULL==fp)
	{
		fprintf(stderr,"Cannot Open Input File!\n");
		return 1;
	}

	fseek(fp,0,SEEK_END);
	nByte=ftell(fp);
	fseek(fp,0,SEEK_SET);

	byteData=(unsigned char *)malloc(nByte);
	if(NULL==byteData)
	{
		fprintf(stderr,"Not Enough Memory Space!\n");
		return 1;
	}
	nByteRead=fread(byteData,1,nByte,fp);
	fclose(fp);

	if(nByteRead!=nByte)
	{
		fprintf(stderr,"File Read Error!\n");
		return 1;
	}


	if(0==ApplyPatch(nByte,byteData,sizeof(patchFrom),patchFrom,sizeof(patchTo),patchTo))
	{
		fprintf(stderr,"Source Pattern Not Found!\n");
		return 1;
	}


	fp=fopen(av[2],"wb");;
	if(NULL==fp)
	{
		fprintf(stderr,"Cannot Open Input File!\n");
		return 1;
	}

	nByteWritten=fwrite(byteData,1,nByte,fp);
	if(nByteWritten!=nByte)
	{
		fprintf(stderr,"File Write Error!\n");
		return 1;
	}
	fclose(fp);

	printf("Patched!\n");
	return 0;
}
