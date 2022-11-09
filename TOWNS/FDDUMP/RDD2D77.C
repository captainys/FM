/* LICENSE>>
Copyright 2022 Soji Yamakawa (CaptainYS, http://www.ysflight.com)

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

<< LICENSE */



#include <stdio.h>
#include <stdint.h>
#include <string.h>


#define TSUGARU_DEBUGBREAK				outp(0x2386,2);


struct D77Header
{
	char diskName[17];             // +0
	char reserveBytes[9];          // +0x11
	unsigned char writeProtected;  // +0x1A
	unsigned char mediaType;       // +0x1B
	uint32_t diskSize;         // +0x1C
	// Must be 0x20 bytes.
};

struct D77SectorHeader
{
	uint8_t C,H,R,N;
	uint16_t numSectorPerTrack;
	uint8_t densityFlag;     // 0:Double Density   0x40 Single Density
	uint8_t DDM;             // 0:Not DDM          0x10:DDM
	uint8_t CRCError;        // 0:No Error         0xB0:CRC Error
	uint8_t reserved[5];
	uint16_t actualSectorLength;
};

void InitializeD77Header(struct D77Header *hdr)
{
	int i;
	unsigned char *ptr=(unsigned char *)hdr;
	for(i=0; i<sizeof(struct D77Header); ++i)
	{
		ptr[i]=0;
	}
}

void InitializeD77SectorHeader(struct D77SectorHeader *hdr)
{
	int i;
	hdr->C=0;
	hdr->H=0;
	hdr->R=0;
	hdr->N=0;
	hdr->numSectorPerTrack=0;
	hdr->densityFlag=0;
	hdr->DDM=0;
	hdr->CRCError=0;
	for(i=0; i<5; ++i)
	{
		hdr->reserved[i]=0;
	}
	hdr->actualSectorLength=0;
}



unsigned int CheckRDDFileSignature(FILE *ifp)
{
	char sig[16];
	if(16!=fread(sig,1,16,ifp))
	{
		return 1;
	}
	return strncmp(sig,"REALDISKDUMP",12);
}

unsigned int ReadDiskHeader(struct D77Header *hdr,FILE *ifp)
{
	unsigned char dat[48];
	if(48!=fread(dat,1,48,ifp) || 0!=dat[0])
	{
		return 1;
	}

	hdr->mediaType=dat[2];
	hdr->writeProtected=(dat[3]&1);

	return 0;
}

#define DMA_BUFFER (24*1024)
static uint8_t DMABuf[DMA_BUFFER];

unsigned int ConvertTrack(uint32_t trackTable[],FILE *ofp,FILE *extFp,FILE *ifp,unsigned int C,unsigned int H)
{
	unsigned int track=C*2+H;
	static uint8_t id[16];
	int nSec=0;
	static uint8_t data[1024];
	static struct D77SectorHeader hdr;
	size_t d77Ptr=ftell(ofp);
	size_t rddPtr=ftell(ifp);

	// D77 format is weird because each sector needs to remember number of sectors per track.
	while(16==fread(id,1,16,ifp))
	{
		if(id[0]==3)
		{
			uint16_t len=id[15];
			len<<=8;
			len|=id[14];
			len+=15;
			len&=0xFFF0;

			fread(data,1,len,ifp);

			++nSec;
		}
		else if(2==id[0])
		{
		}
		else if(id[0]==4)
		{
			uint16_t len=id[15];
			len<<=8;
			len|=id[14];
			len+=15;
			len&=0xFFF0;

			fread(DMABuf,1,len,ifp);
		}
		else if(id[0]==5)
		{
			fseek(ifp,rddPtr,SEEK_SET);
			break;
		}
		else
		{
			printf("Unknown tab %d\n",id[0]);
			return 1;
		}
	}

	printf("%d\n",nSec);

	while(16==fread(id,1,16,ifp))
	{
		if(id[0]==3)
		{
			uint16_t len=id[15];
			uint32_t microsec=id[13];

			len<<=8;
			len|=id[14];
			len+=15;
			len&=0xFFF0;

			microsec<<=8;
			microsec|=id[12];
			microsec<<=8;
			microsec|=id[11];

			InitializeD77SectorHeader(&hdr);

			hdr.C=id[1];
			hdr.H=id[2];
			hdr.R=id[3];
			hdr.N=id[4];
			hdr.numSectorPerTrack=nSec;
			hdr.densityFlag=(id[6]&1 ? 0x40 : 0);
			hdr.DDM=(id[5]&0x20 ? 0x10 : 0);
			if(id[5]&0x10)
			{
				hdr.CRCError=0xF0;
			}
			else if(id[5]&0x08)
			{
				hdr.CRCError=0xB0;
			}
			hdr.actualSectorLength=len;

			fread(data,1,len,ifp);

			fwrite(&hdr,1,sizeof(hdr),ofp);
			fwrite(data,1,len,ofp);

			if(NULL!=extFp && 0<len)
			{
				uint32_t nanosecPerByte=microsec*1000;
				nanosecPerByte/=len;
				fprintf(extFp,"S %d %d %d NSBYTE %lu\n",C,H,id[3],nanosecPerByte);
			}
		}
		else if(id[0]==4)
		{
			uint16_t len=id[15];
			len<<=8;
			len|=id[14];
			len+=15;
			len&=0xFFF0;

			fread(DMABuf,1,len,ifp);
		}
		else if(5==id[0])
		{
			break;
		}
	}

	if(0<nSec)
	{
		trackTable[C*2+H]=d77Ptr;
	}

	return 0;
}

FILE *OpenD77ExtFp(const char d77File[])
{
	char d77ExtFile[256];
	int lastDot=0,i;

	strncpy(d77ExtFile,d77File,255);
	for(i=0; 0!=d77ExtFile[i]; ++i)
	{
		if('.'==d77ExtFile[i])
		{
			lastDot=i;
		}
	}

	if(0<lastDot && lastDot+6<250)
	{
		d77ExtFile[lastDot+1]='d';
		d77ExtFile[lastDot+2]='7';
		d77ExtFile[lastDot+3]='x';
	}

	printf("%s\n",d77ExtFile);

	return fopen(d77ExtFile,"w");
}

unsigned int RDD2D77(const char rddFile[],const char d77File[])
{
	int i,err=0;
	static struct D77Header hdr;
	static uint32_t trackTable[164];
	uint8_t id[16];
	FILE *ifp=NULL,*ofp=NULL,*extFp=NULL;

	InitializeD77Header(&hdr);
	for(i=0; i<164; ++i)
	{
		trackTable[i]=0;
	}

	ifp=fopen(rddFile,"rb");
	if(NULL==ifp)
	{
		printf("Cannot open .RDD file.\n");
		goto ERREND;
	}

	if(0!=CheckRDDFileSignature(ifp))
	{
		printf("Not a RDD file.\n");
		goto ERREND;
	}

	if(0!=ReadDiskHeader(&hdr,ifp))
	{
		printf("Disk Header Not Found.\n");
		goto ERREND;
	}

	ofp=fopen(d77File,"wb");
	if(NULL==ofp)
	{
		printf("Cannot open output file.\n");
		goto ERREND;
	}

	extFp=OpenD77ExtFp(d77File);

	fwrite(&hdr,1,sizeof(hdr),ofp);
	fwrite(trackTable,sizeof(uint32_t),164,ofp);
	while(16==fread(id,1,16,ifp))
	{
		if(1==id[0])
		{
			if(0!=ConvertTrack(trackTable,ofp,extFp,ifp,id[1],id[2]))
			{
				printf("Error during processing C=%d H=%d\n",id[1],id[2]);
				goto ERREND;
			}
		}
	}

	hdr.diskSize=ftell(ofp);
	fseek(ofp,0,SEEK_SET);

	fwrite(&hdr,1,sizeof(hdr),ofp);
	fwrite(trackTable,sizeof(uint32_t),164,ofp);

EXIT:
	if(NULL!=ifp)
	{
		fclose(ifp);
	}
	if(NULL!=ofp)
	{
		fclose(ofp);
	}
	if(NULL!=extFp)
	{
		fclose(extFp);
	}
	return err;
ERREND:
	err=1;
	goto EXIT;
}


int main(int ac,char *av[])
{
	if(ac<3)
	{
		printf("RDD2D77 by CaptainYS\n");
		printf("Usage: RDD2D77 rddfile.RDD d77file.D77\n");
		return 0;
	}

	return RDD2D77(av[1],av[2]);
}
