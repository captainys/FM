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

////////////////////////////////////////////////////////////////////////////////////////


// Ft.Dix BGM Fix
// Amiga version plays BGM every time Rocket Ranger returns to the base, Ft. Dix, where FM TOWNS version plays this music
// only the first time.  This patch fixes the problem.
//From:
//000C:0000402B E954FFFFFF                JMP     00003F84 { Chapter1_Loop(Prob):} 
//To:
//              E939FFFFFF                JMP     00003F69
unsigned char FtDixBGM_from[]=
{
0xC6,0x05,0x01,0x0D,0x0E,0x00,0x01,0x80,0x3D,0x01,0x0D,0x0E,0x00,0x01,0x0F,0x84,0x2E,0x48,0x02,0x00,0xE9,0x54,0xFF,0xFF,0xFF
};

unsigned char FtDixBGM_to[]=
{
0xC6,0x05,0x01,0x0D,0x0E,0x00,0x01,0x80,0x3D,0x01,0x0D,0x0E,0x00,0x01,0x0F,0x84,0x2E,0x48,0x02,0x00,0xE9,0x39,0xFF,0xFF,0xFF
};



////////////////////////////////////////////////////////////////////////////////////////

// Last Boss Background.
// Amiga version has concentric circles as a background and makes a visual effect like you are travelling in the time machine,
// where FM TOWNS version is just black background.
// In fact, FM TOWNS version has a bitmap data for the concentric circles.  Although it does not do animation, I can at least
// bring it back.

// First, do not draw the bottom half of the screen at the beginning of the last-boss battle.
// It should be done during the frame-buffer rendering.
// 000C:300D6 needs to be NOPped.
// 000C:000300D1 E8B143FDFF                CALL    00004487 { Drawing Upper Half of the Spiral.()}
// 000C:000300D6 E806000000                CALL    000300E1 { (Prob)Drawing Lower Half of the Spiral by symmetry()}
// 000C:000300DB E834000000                CALL    00030114
// 000C:000300E0 C3                        RET
unsigned char lastBossBackground_1_from[]=
{
	0xE8,0xB1,0x43,0xFD,0xFF,0xE8,0x06,0x00,0x00,0x00,0xE8,0x34,0x00,0x00,0x00,0xC3
};
unsigned char lastBossBackground_1_to[]=
{
	0xE8,0xB1,0x43,0xFD,0xFF,0x90,0x90,0x90,0x90,0x90,0xE8,0x34,0x00,0x00,0x00,0xC3
};

// Then make "copy upper-half to lower-half" function to take ESI as the source VRAM address.  The address was hard coded.
// From:
//	000C:000300EB BE20000000                MOV     ESI,00000020H
//	000C:000300F0 BF201C0300                MOV     EDI,00031C20H
// To:
//                                          LEA EDI,[ESI+31C00H], NOP NOP NOP NOP
unsigned char lastBossBackground_2_from[]=
{
0x66,0xB8,0x0C,0x01,0x8E,0xD8,0x8E,0xC0,0xBE,0x20,0x00,0x00,0x00,0xBF,0x20,0x1C,0x03,0x00,0xB9,0x64,0x00,0x00,0x00
};
unsigned char lastBossBackground_2_to[]=
{
0x66,0xB8,0x0C,0x01,0x8E,0xD8,0x8E,0xC0,0x8D,0xBE,0x00,0x1C,0x03,0x00,0x90,0x90,0x90,0x90,0xB9,0x64,0x00,0x00,0x00
};

// Instead of clearing the frame buffer, draw the concentric circles.
// Clear Frame Buffer()
// 000C:00030147 BF20000000                MOV     EDI,00000020H
// 000C:0003014C A048790300                MOV     AL,[00037948H]
// 000C:00030151 2401                      AND     AL,01H
// 000C:00030153 0F8405000000              JE      0003015E
// 000C:00030159 BF00820400                MOV     EDI,00048200H
// 000C:0003015E 06                        PUSH    ES                   -> PUSH	EDI
// 000C:0003015F 66B80C01                  MOV     AX,010CH                CALL	000300B6H
// 000C:00030163 8EC0                      MOV     ES,AX                   POP		ESI
// 000C:00030165 B9C8000000                MOV     ECX,000000C8H           CALL	000300E1H
// 000C:0003016A 51                        PUSH    ECX                     RET
// 000C:0003016B B950000000                MOV     ECX,00000050H           
unsigned char lastBossBackground_3_from[]=
{
0x24,0x01,0x0F,0x84,0x05,0x00,0x00,0x00,0xBF,0x00,0x82,0x04,0x00,0x06,0x66,0xB8,0x0C,0x01,0x8E,0xC0,0xB9,0xC8,0x00,0x00,0x00,0x51
};
unsigned char lastBossBackground_3_to[]=
{
0x24,0x01,0x0F,0x84,0x05,0x00,0x00,0x00,0xBF,0x00,0x82,0x04,0x00,0x57,0xE8,0x52,0xFF,0xFF,0xFF,0x5E,0xE8,0x77,0xFF,0xFF,0xFF,0xC3
};

// Boss rendering routine is using three different bit blit functions.  Two of them ignore transparent pixels.
// Those need to be replaced the one that takes transparency into account.
//000C:0002FF5C 66A3DC780300              MOV     [000378DCH],AX
//000C:0002FF62 8A4328                    MOV     AL,[EBX+28H]
//000C:0002FF65 B400                      MOV     AH,00H
//000C:0002FF67 66A359790300              MOV     [00037959H],AX
//000C:0002FF6D E81545FDFF                CALL    00004487     ->   JMP 2FEFB
//000C:0002FF72 C3                        RET
unsigned char lastBossBackground_4_from[]=
{
0x66,0xA3,0xDC,0x78,0x03,0x00,0x8A,0x43,0x28,0xB4,0x00,0x66,0xA3,0x59,0x79,0x03,0x00,0xE8,0x15,0x45,0xFD,0xFF,0xC3
};
unsigned char lastBossBackground_4_to[]=
{
0x66,0xA3,0xDC,0x78,0x03,0x00,0x8A,0x43,0x28,0xB4,0x00,0x66,0xA3,0x59,0x79,0x03,0x00,0xe9,0x89,0xff,0xff,0xff,0xC3
};

//000C:0002FCE2 66A1F6ED0200              MOV     AX,[0002EDF6H]
//000C:0002FCE8 6605A200                  ADD     AX,00A2H
//000C:0002FCEC 66A3DA780300              MOV     [000378DAH],AX
//000C:0002FCF2 66A1FAED0200              MOV     AX,[0002EDFAH]
//000C:0002FCF8 66056700                  ADD     AX,0067H
//000C:0002FCFC 66A3DC780300              MOV     [000378DCH],AX
//000C:0002FD02 66C705597903000C00        MOV     WORD PTR [00037959H],000CH
//000C:0002FD0B E87747FDFF                CALL    00004487         ->     JMP 4512
//000C:0002FD10 C3                        RET
unsigned char lastBossBackground_5_from[]=
{
0x66,0xA1,0xF6,0xED,0x02,0x00,0x66,0x05,0xA2,0x00,0x66,0xA3,0xDA,0x78,0x03,0x00,
0x66,0xA1,0xFA,0xED,0x02,0x00,0x66,0x05,0x67,0x00,0x66,0xA3,0xDC,0x78,0x03,0x00,
0x66,0xC7,0x05,0x59,0x79,0x03,0x00,0x0C,0x00,0xE8,0x77,0x47,0xFD,0xFF,0xC3
};
unsigned char lastBossBackground_5_to[]=
{
0x66,0xA1,0xF6,0xED,0x02,0x00,0x66,0x05,0xA2,0x00,0x66,0xA3,0xDA,0x78,0x03,0x00,
0x66,0xA1,0xFA,0xED,0x02,0x00,0x66,0x05,0x67,0x00,0x66,0xA3,0xDC,0x78,0x03,0x00,
0x66,0xC7,0x05,0x59,0x79,0x03,0x00,0x0C,0x00,0xE9,0x02,0x48,0xFD,0xFF,0xC3
};



// Interrogation scene bug fix.
// If you make wrong choices, Colonel Leermeister will torture you, and Jane and the Doctor will be taken to somewhere unknown.
// You eventually escapes from the prisoner camp, and somehow get your rocket pack back....
// But, FM TOWNS version skips all this storyline message due to a bug.
// You are suddenly taken to the scene in which you can either select next destination or send an SOS message.
// At 000C:00019AE0, it sets EAX=the message number, but the programmer forgot calling the fundtion that shows the storyline message.
// I can fix this bug by utilizing some bytes that are no longer used after above patches.
//	000C:00019AE0 B836000000                MOV     EAX,00000036H ->   E886660100 CALL 3016BH
//	000C:00019AE5 8A0DA9090E00              MOV     CL,[000E09A9H]
//	000C:00019AEB E8BDBEFFFF                CALL    000159AD
//	000C:00019AF0 A2A9090E00                MOV     [000E09A9H],AL
//	000C:00019AF5 C605030D0E000B            MOV     BYTE PTR [000E0D03H],0BH   行き先選択/SOS。
//	000C:00019AFC C3                        RET
unsigned char interrogation_scene_bugfix_1_from[]=
{
0xB8,0x36,0x00,0x00,0x00,0x8A,0x0D,0xA9,0x09,0x0E,0x00,0xE8,0xBD,0xBE,0xFF,0xFF,0xA2,0xA9,0x09,0x0E,0x00,0xC6,0x05,0x03,0x0D,0x0E,0x00,0x0B,0xC3
};
unsigned char interrogation_scene_bugfix_1_to[]=
{
0xE8,0x86,0x66,0x01,0x00,0x8A,0x0D,0xA9,0x09,0x0E,0x00,0xE8,0xBD,0xBE,0xFF,0xFF,0xA2,0xA9,0x09,0x0E,0x00,0xC6,0x05,0x03,0x0D,0x0E,0x00,0x0B,0xC3
};

// 000C:0003016B B950000000                MOV     ECX,00000050H           -> MOV EAX,36H
// 000C:00030170 B800000000                MOV     EAX,00000000H           -> CALL 000098F3H
// 000C:00030175 F3AB                      REP STOSD                       -> CALL 0001B4F8H
// 000C:00030177 81C7C0020000              ADD     EDI,000002C0H           -> RET
// 000C:0003017D 59                        POP     ECX                     
unsigned char interrogation_scene_bugfix_2_from[]=
{
0xB9,0x50,0x00,0x00,0x00,0xB8,0x00,0x00,0x00,0x00,0xF3,0xAB,0x81,0xC7,0xC0,0x02,0x00,0x00,0x59
};
unsigned char interrogation_scene_bugfix_2_to[]=
{
0xB8,0x36,0x00,0x00,0x00,0xE8,0x7E,0x97,0xFD,0xFF,0xE8,0x7E,0xB3,0xFE,0xFF,0xC3,0x90,0x90,0x90
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

#define numPatterns 10

int main(int ac,char *av[])
{
	if(2!=ac)
	{
		fprintf(stderr,"Usage: Patch source-file.bin/mdf/iso\n");
		fprintf(stderr,"  This program applies patches to Rocket Ranger for FM TOWNS\n");
		fprintf(stderr,"  ISO Image, and...\n");
		fprintf(stderr,"  (1) Corrects Opening Demo BGM bug that crashes in the FAST mode.\n");
		fprintf(stderr,"  (2) Plays Ft.Dix theme BGM every time Rocket Ranger comes back to base.\n");
		fprintf(stderr,"  (3) Draws background picture during the last-boss battle.\n");
		fprintf(stderr,"  (4) In the Interrogation scene, the programmer apparently forgot to call\n");
		fprintf(stderr,"      a function to show storyline message.  If you make wrong choices,\n");
		fprintf(stderr,"      you are taken to the 'Select Destination / Send SOS signal' screen\n");
		fprintf(stderr,"      with no explanation.  This patch will fix this issue.\n");
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

	unsigned int applyCount[numPatterns]={0};

	unsigned int LBA=0;
	unsigned char buf[2352];
	while(2352==fread(buf,1,2352,fp))
	{
		int applied[numPatterns]=
		{
			ApplyPatch(2352,buf,sizeof(CALLE660_from),CALLE660_from,sizeof(CALLEADE_to),CALLEADE_to),
			ApplyPatch(2352,buf,sizeof(BGMFileReader_from),BGMFileReader_from,sizeof(BGMFileReader_to),BGMFileReader_to),
			ApplyPatch(2352,buf,sizeof(FtDixBGM_from),FtDixBGM_from,sizeof(FtDixBGM_to),FtDixBGM_to),
			ApplyPatch(2352,buf,sizeof(lastBossBackground_1_from),lastBossBackground_1_from,sizeof(lastBossBackground_1_to),lastBossBackground_1_to),
			ApplyPatch(2352,buf,sizeof(lastBossBackground_2_from),lastBossBackground_2_from,sizeof(lastBossBackground_2_to),lastBossBackground_2_to),
			ApplyPatch(2352,buf,sizeof(lastBossBackground_3_from),lastBossBackground_3_from,sizeof(lastBossBackground_3_to),lastBossBackground_3_to),
			ApplyPatch(2352,buf,sizeof(lastBossBackground_4_from),lastBossBackground_4_from,sizeof(lastBossBackground_4_to),lastBossBackground_4_to),
			ApplyPatch(2352,buf,sizeof(lastBossBackground_5_from),lastBossBackground_5_from,sizeof(lastBossBackground_5_to),lastBossBackground_5_to),
			ApplyPatch(2352,buf,sizeof(interrogation_scene_bugfix_1_from),interrogation_scene_bugfix_1_from,sizeof(interrogation_scene_bugfix_1_to),interrogation_scene_bugfix_1_to),
			ApplyPatch(2352,buf,sizeof(interrogation_scene_bugfix_2_from),interrogation_scene_bugfix_2_from,sizeof(interrogation_scene_bugfix_2_to),interrogation_scene_bugfix_2_to),
			// ApplyPatch(2352,buf,sizeof(xxxx_from),xxxx_from,sizeof(xxxx_to),xxxx_to),
		};

		for(int i=0; i<numPatterns; ++i)
		{
			applyCount[i]+=applied[i];
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

	for(int i=0; i<numPatterns; ++i)
	{
		if(0==applyCount[i])
		{
			printf("Pattern %d is not applied.  The patched disc may not work.\n",i);
		}
		if(1<applyCount[i])
		{
			printf("Pattern %d is applied more than once (%d times).  The patched disc may not work.\n",i,applyCount[i]);
		}
	}

	printf("Patched!\n");
	return 0;
}
