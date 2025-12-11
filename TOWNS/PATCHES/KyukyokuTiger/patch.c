#include <stdio.h>
#include <stdlib.h>



// EXP file size in the directory.  
// 574156 ->574412
unsigned char fileSize_from[]=
{
	0xcc,0xc2,0x08,0x00,0x00,0x08,0xc2,0xcc
};
unsigned char fileSize_to[]=
{
	0xcc,0xc3,0x08,0x00,0x00,0x08,0xc3,0xcc
};


// EXP Headers of KTIGER.EXP
unsigned char expSize_from[]=
{
	0x4D,0x50,0xCC,0x00,0x62,0x04,0x00,0x00,0x20,0x00
};
unsigned char expSize_to[]=
{
	0x4D,0x50,0xCC,0x01,0x62,0x04,0x00,0x00,0x20,0x00
};


unsigned char uncompressor_size_from[]=
{
	0xBE,0xCB,0xC0,0x08,0x00,               // MOV     ESI,0008C0CBH   -> 0008C1CB
	0xB9,0xC2,0x00,0x00,0x00                // MOV     ECX,000000C2H   -> 000001C2
};

unsigned char uncompressor_size_to[]=
{
	0xBE,0xCB,0xC1,0x08,0x00,               // MOV     ESI,0008C0CBH   -> 0008C1CB
	0xB9,0xC2,0x01,0x00,0x00                // MOV     ECX,000000C2H   -> 000001C2
};


// Force CD BIOS
unsigned char forceCDBIOS_pattern[]=
{
	0x68,0x9C,0xA9,0x14,0x00,  // PUSH    DWORD PTR 0014A99CH
	0xC3                       // RET
};

unsigned char forceCDBIOS_patch[]=
{
	0xe8,0x00,0x00,0x00,0x00,0x5e,0x83,0xc6,
	0x11,0xbf,0x32,0x0a,0x15,0x00,0xb9,0x9a,
	0x00,0x00,0x00,0xf3,0xa4,0xc3,0x53,0x0a,
	0x15,0x00,0x53,0x0a,0x15,0x00,0x53,0x0a,
	0x15,0x00,0x53,0x0a,0x15,0x00,0x53,0x0a,
	0x15,0x00,0x4a,0x0a,0x15,0x00,0xb4,0x55,
	0xb0,0xc0,0x31,0xc9,0xcd,0x93,0xc3,0x06,
	0xa2,0x74,0x1a,0x00,0x00,0x83,0xec,0x14,
	0x0f,0xb6,0xc8,0x8d,0x04,0x49,0x8d,0xb4,
	0x00,0xf0,0x19,0x00,0x00,0x66,0xbb,0x01,
	0x00,0x66,0xb8,0xc0,0x25,0xcd,0x21,0x72,
	0x52,0x66,0xc7,0x04,0x24,0x93,0x00,0x66,
	0x89,0x44,0x24,0x02,0x66,0xc7,0x44,0x24,
	0x0a,0xc0,0x50,0xb1,0x60,0x8e,0xc1,0x0f,
	0xb7,0xf8,0xc1,0xe7,0x04,0xc1,0xe9,0x04,
	0xac,0x88,0xc3,0xc0,0xe8,0x04,0xb4,0x0a,
	0xf6,0xe4,0x80,0xe3,0x0f,0x00,0xd8,0xaa,
	0xe2,0xee,0x66,0xb8,0xc0,0x52,0xcd,0x93,
	0x31,0xff,0x89,0xe2,0x66,0xb9,0x01,0x00,
	0x66,0xb8,0x11,0x25,0xcd,0x21,0x66,0x8b,
	0x4c,0x24,0x02,0x50,0x66,0xb8,0xc1,0x25,
	0xcd,0x21,0x58,0x83,0xc4,0x14,0x07,0xc3
};



int ApplyPatch(
    int nByte,unsigned char byteData[],
    int nPatchFrom,const unsigned char patchFrom[],
    int nPatchTo,const unsigned char patchTo[])
{
	int nOccurrence=0;
	for(int i=0; i+nPatchFrom<=nByte; ++i)
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

int ApplyPatchExternal(
    size_t nByte,unsigned char byteData[],
    size_t nPatchSig,const unsigned char patchSig[],
    size_t offset_from_signature,
    size_t patchSize,const unsigned char patchData[])
{
	size_t foundOffset=~0;
	for(size_t i=0; i+nPatchSig<nByte; ++i)
	{
		if(0==memcmp(byteData+i,patchSig,nPatchSig))
		{
			foundOffset=i;
			break;
		}
	}

	if(~0==foundOffset)
	{
		return 0;
	}

	unsigned char *loadPoint=byteData+foundOffset+offset_from_signature;

	if(nByte<foundOffset+offset_from_signature+patchSize)
	{
		fprintf(stderr,"Patch does not fit.\n");
		return 0;
	}

	memcpy(loadPoint,patchData,patchSize);

	printf("Applied to offset %llu\n",foundOffset+offset_from_signature);

	return 1;
}

int main(int ac,char *av[])
{
	if(2!=ac)
	{
		fprintf(stderr,"Usage: Patch source-file.bin/mdf/iso\n");
		fprintf(stderr,"  This program applies patches to Kyukyoku Tiger for FM TOWNS\n");
		fprintf(stderr,"  BIN/MDF/ISO Image, and makes it force to use CD-ROM BIOS to play BGM.\n");
		fprintf(stderr,"  With this it can run from YSSCSICD.SYS or Rescue IPL with BGM.\n");
		return 1;
	}

	int nByte=0,nByteRead=0,nByteWritten=0;
	unsigned char *byteData=NULL;
	FILE *fp;

	fp=fopen(av[1],"r+b");
	if(NULL==fp)
	{
		fprintf(stderr,"Cannot Open Input File!\n");
		return 1;
	}

	unsigned int LBA=0;
	unsigned char buf[2352];
	while(2352==fread(buf,1,2352,fp))
	{
		auto applied=ApplyPatch(2352,buf,sizeof(expSize_from),expSize_from,sizeof(expSize_to),expSize_to)+
                     ApplyPatch(2352,buf,sizeof(fileSize_from),fileSize_from,sizeof(fileSize_to),fileSize_to)+
                     ApplyPatch(2352,buf,sizeof(uncompressor_size_from),uncompressor_size_from,sizeof(uncompressor_size_to),uncompressor_size_to)+

					ApplyPatchExternal(
					    2352,buf,
					    sizeof(forceCDBIOS_pattern),forceCDBIOS_pattern,
					    sizeof(forceCDBIOS_pattern)-1,
					    sizeof(forceCDBIOS_patch),forceCDBIOS_patch)+

                     0;

		if(0!=applied)
		{
			printf("Applied Patch to LBA=%d\n",LBA);

			auto pos=ftell(fp);
			fseek(fp,pos-2352,SEEK_SET);
			fwrite(buf,1,2352,fp);
			fseek(fp,pos,SEEK_SET); // fwrite apparently only updates the write pointer, or mess up the read pointer.
		}
		++LBA;
	}

	fclose(fp);

	printf("Patched!\n");
	return 0;
}
