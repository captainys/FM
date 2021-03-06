#include <stdio.h>
#include <stdlib.h>



const unsigned char patch1From[]=
{
0x66,0xBA,0xC0,0x04,0xB0,0x82,0xEE,0x66,0xBA,0xC2,0x04,0xB0,0x84,0xEE,0x66,0xBA,
0xC4,0x04,0x2B,0xC0,0xEE,0xEE,0xEE,0xEE,0xEE,0xEE,0xEE,0xEE
};

const unsigned char patch1To[]=
{
0x57,0x51,0x66,0xB8,0xC0,0x52,0x66,0xB9,0x00,0x00,0xCD,0x93,0x59,0x5F,0x33,0xC0,
0x90,0x90,0x90,0x90,0x90,0x90,0x90,0x90,0x90,0x90,0x90,0x90
};


const unsigned char patch2From[]=
{
0xB8,0xAC,0xD7,0x0D,0x00,0xFF,0x40,0x70,0x83,0x78,0x70,0x0A,0x7E,0x21,0x66,0xBA,
0xC2,0x04,0xEC,0x0F,0xB6,0xC0,0xA3,0x18,0xD8,0x0D,0x00,0xEC,0xEC,0xEC,0x66,0xBA,
0xC0,0x04,0xB0,0x82,0xEE,0xC7,0x05,0x1C,0xD8,0x0D,0x00,0x00,0x00,0x00,0x00
};
const unsigned char patch2To[]=
{
0x66,0x60,0xA1,0x10,0xD8,0x0D,0x00,0x3D,0x00,0x00,0x00,0x00,0x0F,0x84,0x31,0x00,
0x00,0x00,0x3D,0x01,0x00,0x00,0x00,0x0F,0x84,0x53,0x00,0x00,0x00,0x3D,0x02,0x00,
0x00,0x00,0x0F,0x84,0x48,0x00,0x00,0x00,0x3D,0x04,0x00,0x00,0x00,0x0F,0x84,0x1F,
0x00,0x00,0x00,0x3D,0x05,0x00,0x00,0x00,0x0F,0x84,0x23,0x00,0x00,0x00,0xE9,0x5F,
0x00,0x00,0x00,0x66,0xB8,0xC0,0x52,0x66,0xB9,0x00,0x00,0xCD,0x93,0xE9,0x50,0x00,
0x00,0x00,0x66,0xB8,0xC0,0x56,0x66,0xB9,0x00,0x00,0xCD,0x93,0xE9,0x41,0x00,0x00,
0x00,0x66,0xB8,0xC0,0x03,0x66,0xB9,0x00,0x00,0xCD,0x93,0xE9,0x32,0x00,0x00,0x00,
0x52,0x51,0x53,0x50,0x66,0xB8,0xC0,0x55,0x66,0xB9,0x00,0x00,0xCD,0x93,0x66,0x8B,
0x1D,0x24,0xD8,0x0D,0x00,0x66,0x8B,0x0D,0x26,0xD8,0x0D,0x00,0x66,0x8B,0x15,0x28,
0xD8,0x0D,0x00,0x66,0xB8,0xC0,0x72,0xCD,0x93,0x58,0x5B,0x59,0x5A,0xE9,0x00,0x00,
0x00,0x00,0x66,0x61,0xC7,0x05,0x10,0xD8,0x0D,0x00,0xFF,0xFF,0xFF,0xFF,0xC3,0x66,
0x53,0x8A,0xD8,0x80,0xE3,0x0F,0xC0,0xE8,0x04,0xB4,0x0A,0xF6,0xE4,0x02,0xC3,0x66,
0x5B,0xC3
};


const unsigned char patch3From[]=
{
0xE8,0x93,0x22,0x00,0x00,0x66,0xBA,0xC0,0x04,0xB0,0x82,0xEE,0x66,0xBA,0xC2,0x04,
0xB0,0x86,0xEE,0x66,0xBA,0xC4,0x04,0x2B,0xC0,0xEE,0xEE,0xEE,0xEE
};
const unsigned char patch3To[]=
{
0x51,0x66,0xB8,0xC0,0x55,0x66,0xB9,0x00,0x00,0xCD,0x93,0xC7,0x05,0x18,0xD8,0x0D,
0x00,0x00,0x00,0x00,0x00,0xC7,0x05,0x14,0xD8,0x0D,0x00,0x03,0x00,0x00,0x00,0x59,
0xC3,
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


	if(0==ApplyPatch(nByte,byteData,sizeof(patch1From),patch1From,sizeof(patch1To),patch1To))
	{
		fprintf(stderr,"Source Pattern 1 Not Found!\n");
		return 1;
	}
	if(0==ApplyPatch(nByte,byteData,sizeof(patch2From),patch2From,sizeof(patch2To),patch2To))
	{
		fprintf(stderr,"Source Pattern 2 Not Found!\n");
		return 1;
	}
	if(0==ApplyPatch(nByte,byteData,sizeof(patch3From),patch3From,sizeof(patch3To),patch3To))
	{
		fprintf(stderr,"Source Pattern 3 Not Found!\n");
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
