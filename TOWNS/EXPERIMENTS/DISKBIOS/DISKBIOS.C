#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <conio.h>

#include <egb.h>
#include <mos.h>
#include <snd.h>
#include <fmcfrb.h>

#define TsugaruDebugBreak _outp(0x2386,2);

unsigned char readBuf[65536];

int main(void)
{
	unsigned int devId;

	for(devId=0; devId<0xFF; ++devId)
	{
		int kind=devId&0xF0;
		if(0x20!=kind && 0xB0!=kind && 0xC0!=kind) // FD, SCSI, CD
		{
			int sector=0;
			int blocknum; // Probably BX returned by Disk BIOS.
			int err=DKB_read2(devId,sector,1,(char *)readBuf,&blocknum);
			printf("%02x %d\n",devId,err);
		}
	}
	return 0;
}
