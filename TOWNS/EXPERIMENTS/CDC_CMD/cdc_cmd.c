// Test CDC Command 03 RAWREAD
// This program reads the first sector of a CD-ROM in the internal CD DRive and save to cdread.bin in the current working directory.

#include <stdio.h>


extern unsigned int TOPHYSICAL(void *ptr);
extern unsigned int READCD(unsigned int physaddr);

static unsigned char buf[8192];

struct BufferAddr
{
	unsigned char *buf;
	unsigned int phys;
};

struct BufferAddr Get4KBContinuousBuffer(void)
{
	struct BufferAddr addr;
	addr.buf=NULL;
	addr.phys=0;
	for(unsigned int offset=0; offset<0x2000; ++offset)
	{
		auto phys=TOPHYSICAL(buf+offset);
		if(0==(phys&0xFFF))
		{
			addr.buf=buf+offset;
			addr.phys=phys;
			break;
		}
	}

	printf("Buffer DS:%08xH\n",addr.buf);
	printf("Physical:%08xH\n",addr.phys);

	return addr;
}

int main(void)
{
	struct BufferAddr buffer=Get4KBContinuousBuffer();

	for(int i=0; i<8192; ++i)
	{
		buf[i]=0xcc;
	}

	printf("Read CD\n");
	READCD(buffer.phys);
	printf("Returned.\n");

	{
		FILE *fp=fopen("cdread.bin","wb");
		if(NULL!=fp)
		{
			fwrite(buffer.buf,1,4096,fp);
			fclose(fp);
		}
	}

	return 0;
}
