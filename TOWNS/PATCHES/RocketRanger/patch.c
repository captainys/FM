#include <stdio.h>
#include <stdlib.h>
#include <string.h>


// CALL E660 -> CALL EADE
unsigned char CALLE660_from[]=
{
0xE8,0xBF,0x00,0x00,0x00,0xBA,0xC6,0x01,0x00,0x00,0xE8,0x77,0xE5,0x00,0x00,0xE8,0xB0,0x00,0x00,0x00,0xE8,0xA4,0x18,0x00,0x00
};
unsigned char CALLEADE_to[]=
{
0xE8,0xBF,0x00,0x00,0x00,0xBA,0xC6,0x01,0x00,0x00,0xE8,0xF5,0xE9,0x00,0x00,0xE8,0xB0,0x00,0x00,0x00,0xE8,0xA4,0x18,0x00,0x00
};

// BGM file reader
// Original (Crash!):
//		000C:0000EAB6 B43D                      MOV     AH,3DH
//		000C:0000EAB8 B0C0                      MOV     AL,C0H
//		000C:0000EABA B900000000                MOV     ECX,00000000H  -> XOR ECX,ECX 3バイト節約
//		000C:0000EABF CD21                      INT     21H (DOS)
//		000C:0000EAC1 0F8305000000              JAE     0000EACC  この2行   JB SHORT EAF2  で済む。
//		000C:0000EAC7 E926000000                JMP     0000EAF2
//		000C:0000EACC 8BD8                      MOV     EBX,EAX
//		000C:0000EACE BA4AB10C00                MOV     EDX,000CB14AH
//		000C:0000EAD3 B900F00000                MOV     ECX,0000F000H
//		000C:0000EAD8 B43F                      MOV     AH,3FH
//		000C:0000EADA CD21                      INT     21H (DOS)
//		000C:0000EADC 66890DCAAE0C00            MOV     [000CAECAH],CX
//		000C:0000EAE3 669C                      PUSHF
//		000C:0000EAE5 B43E                      MOV     AH,3EH
//		000C:0000EAE7 CD21                      INT     21H (DOS)
//		000C:0000EAE9 669D                      POPF
//		000C:0000EAEB 0F8201000000              JB      0000EAF2
//		000C:0000EAF1 C3                        RET
//		000C:0000EAF2 BA2FB10C00                MOV     EDX,000CB12FH
//		000C:0000EAF7 B409                      MOV     AH,09H
//		000C:0000EAF9 CD21                      INT     21H (DOS)
//		000C:0000EAFB F9                        STC
//		000C:0000EAFC C3                        RET

// Fixed: (No crash):
// 					MOV     AH,3DH
// 					MOV     AL,0C0H
// 					XOR		ECX,ECX
// 					INT     21H (DOS)
// 					JB      SHORT FAIL
// 					MOV     EBX,EAX
// 					MOV     EDX,000CB14AH
// 					MOV     ECX,0000F000H
// 					MOV     AH,3FH
// 					INT     21H (DOS)
// 					MOV     [000CAECAH],CX
// 					PUSHF
// 					MOV     AH,3EH
// 					INT     21H (DOS)
// 					POPF
// FAIL:				RET
// 
// WAIT_FOR_BGM_END:
// 					CMP		BYTE PTR DS:[000DC14DH],0FFH
// 					JNE		WAIT_FOR_BGM_END
// 					JMP		0E660h



unsigned char BGMFileReader_from[]=
{
0xB4,0x3D,0xB0,0xC0,0xB9,0x00,0x00,0x00,0x00,0xCD,0x21,0x0F,0x83,0x05,0x00,0x00,0x00,0xE9,0x26,
0x00,0x00,0x00,0x8B,0xD8,0xBA,0x4A,0xB1,0x0C,0x00,0xB9,0x00,0xF0,0x00,0x00,0xB4,0x3F,0xCD,0x21,
0x66,0x89,0x0D,0xCA,0xAE,0x0C,0x00,0x66,0x9C,0xB4,0x3E,0xCD,0x21,0x66,0x9D,0x0F,0x82
};

unsigned char BGMFileReader_to[]=
{
0xB4,0x3D,0xB0,0xC0,0x31,0xC9,0xCD,0x21,0x72,0x1D,0x89,0xC3,0xBA,0x4A,0xB1,0x0C,0x00,0xB9,0x00,
0xF0,0x00,0x00,0xB4,0x3F,0xCD,0x21,0x66,0x89,0x0D,0xCA,0xAE,0x0C,0x00,0x9C,0xB4,0x3E,0xCD,0x21,
0x9D,0xC3,0x3E,0x80,0x3D,0x4D,0xC1,0x0D,0x00,0xFF,0x75,0xF6,0xE9,0x73,0xFB,0xFF,0xFF
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
		fprintf(stderr,"  This program applies patches to Rocket Ranger for FM TOWNS\n");
		fprintf(stderr,"  ISO Image, and correct Opening Demo BGM bug that crashes in\n");
		fprintf(stderr,"  the FAST mode.\n");
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
		int applied[2]=
		{
			ApplyPatch(2352,buf,sizeof(CALLE660_from),CALLE660_from,sizeof(CALLEADE_to),CALLEADE_to),
			ApplyPatch(2352,buf,sizeof(BGMFileReader_from),BGMFileReader_from,sizeof(BGMFileReader_to),BGMFileReader_to),
		};

		for(int i=0; i<sizeof(applied)/sizeof(int); ++i)
		{
			if(0!=applied[i])
			{
				printf("Applied Patch %d to LBA=%d\n",i,LBA);

				auto pos=ftell(fp);
				fseek(fp,pos-2352,SEEK_SET);
				fwrite(buf,1,2352,fp);
				fseek(fp,pos,SEEK_SET); // fwrite apparently only updates the write pointer, or mess up the read pointer.
			}
		}
		++LBA;
	}

	fclose(fp);

	printf("Patched!\n");
	return 0;
}
