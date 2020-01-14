#include <stdio.h>
#include <stdlib.h>


const char patchCDDAPlayFrom[]=
{
//000C:0000E562 55                       PUSH	EBP
//000C:0000E563 8BEC                     MOV	EBP,ESP
//000C:0000E565 53                       PUSH	EBX
//000C:0000E566 56                       PUSH	ESI
//000C:0000E567 66BAE304                 MOV	DX,04E3
//000C:0000E56B B004                     MOV	AL,04
//000C:0000E56D E8C6FBFFFF               CALL	0000E138       (Wait&OUT DX,AL)x5times
//000C:0000E572 66BAE204                 MOV	DX,04E2
//000C:0000E576 B01F                     MOV	AL,1F
//000C:0000E578 E8BBFBFFFF               CALL	0000E138       (Wait&OUT DX,AL)x5times
//000C:0000E57D 66BAE304                 MOV	DX,04E3
//000C:0000E581 B005                     MOV	AL,05
//000C:0000E583 E8B0FBFFFF               CALL	0000E138       (Wait&OUT DX,AL)x5times
//000C:0000E588 66BAE204                 MOV	DX,04E2
//000C:0000E58C B01F                     MOV	AL,1F
//000C:0000E58E E8A5FBFFFF               CALL	0000E138       (Wait&OUT DX,AL)x5times
0x55,
0x8B,0xEC,
0x53,
0x56,
0x66,0xBA,0xE3,0x04,
0xB0,0x04,
0xE8,0xC6,0xFB,0xFF,0xFF,
0x66,0xBA,0xE2,0x04,
0xB0,0x1F,
0xE8,0xBB,0xFB,0xFF,0xFF,
0x66,0xBA,0xE3,0x04,
0xB0,0x05,
0xE8,0xB0,0xFB,0xFF,0xFF,
0x66,0xBA,0xE2,0x04,
0xB0,0x1F,
0xE8,0xA5,0xFB,0xFF,0xFF
};

const char patchCDDAPlayTo[]=
{
0x55,0x8B,0xEC,0x53,0x56,0x06,0x1E,0x0F,0xB7,0x5D,0x08,0x8D,0x1C,0x5B,0x8B,0x35,
0x2C,0x6A,0x01,0x00,0x8D,0x74,0x33,0x09,0x66,0xA1,0x28,0x6A,0x01,0x00,0x8E,0xD8,
0x66,0xB8,0x0D,0x25,0xCD,0x21,0x66,0x9C,0xB9,0x06,0x00,0x00,0x00,0x8B,0xFA,0xFC,
0xAC,0x8A,0xD0,0x80,0xE2,0x0F,0xC0,0xE8,0x04,0xB4,0x0A,0xF6,0xE4,0x02,0xC2,0xAA,
0xE2,0xEE,0x66,0x9D,0x66,0xB8,0xC0,0x52,0xCD,0x93,0x8B,0xFB,0xC1,0xEB,0x10,0x16,
0x1F,0x83,0xEC,0x12,0x8B,0xD4,0x66,0xC7,0x02,0x93,0x00,0x89,0x5A,0x02,0x66,0xC7,
0x42,0x0A,0xC0,0x50,0x41,0x66,0xB8,0x11,0x25,0xCD,0x21,0x83,0xC4,0x12,0x1F,0x07,
0x5E,0x5B,0xC9,0xC3
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


	if(0==ApplyPatch(nByte,byteData,sizeof(patchCDDAPlayFrom),patchCDDAPlayFrom,sizeof(patchCDDAPlayTo),patchCDDAPlayTo))
	{
		fprintf(stderr,"Source Pattern CDDAPlay Not Found!\n");
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
