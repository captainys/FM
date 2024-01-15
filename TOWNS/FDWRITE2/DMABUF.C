////////////////////////////////////////////////////////////////////////
// DMA Buffer

#include <string.h>
#include "DMABUF.H"
#include "DEF.H"

#define DATABUF_SIZE (32*1024)
static unsigned char _databuf[DATABUF_SIZE];

#define NUM_PHYSADDR ((DATABUF_SIZE+PAGE_SIZE-1)/PAGE_SIZE)
static unsigned int numPhysAddr=0;
static struct PhysToLinear physToLinear[NUM_PHYSADDR];

unsigned int ToPhysicalAddr(void *ptr);

/*
This function finds physical addresses of the pages within _databuf, sort them, and find sequence of pages that
are continuous in the physical memory space.  The pages are added to the end of the data segment, and the pointer
is returned.

The length is up to 128KB, but most likely shorter.  The return value contains pointer to the physically-continuous
memory space, physical address, and the length.

*/
struct bufferInfo MakeDataBuffer(void)
{
	int i,j,step=1;
	for(i=0; i<DATABUF_SIZE; ++i)
	{
		_databuf[i]=0x77;
	}

	struct bufferInfo info;
	info.physAddr=0;
	info.numberOfPages=0;
	info.pages=0;

	printf("Looking for physically-continuous memory space....\n");

	// Convert pointer to physical address.
	// Limit until PAGE_SIZE before the end of the array to make sure it gets continuous 4KB if low 11bits are all zero.
	for(i=0; i<DATABUF_SIZE-PAGE_SIZE; i+=step)
	{
		unsigned int phys=ToPhysicalAddr(_databuf+i);
		if(0==(phys&(PAGE_SIZE-1)) && numPhysAddr<NUM_PHYSADDR)
		{
			step=PAGE_SIZE;
			printf("%08x ",phys);
			physToLinear[numPhysAddr].physAddr=phys;
			physToLinear[numPhysAddr].data=_databuf+i;
			numPhysAddr++;
			if(0==(numPhysAddr&7))
			{
				printf("\n");
			}
		}
	}
	printf("\n");

	// Sort page-top physical addresses.
	for(i=0; i<numPhysAddr; ++i)
	{
		for(j=i+1; j<numPhysAddr; ++j)
		{
			if(physToLinear[i].physAddr>physToLinear[j].physAddr)
			{
				struct PhysToLinear swp=physToLinear[i];
				physToLinear[i]=physToLinear[j];
				physToLinear[j]=swp;
			}
		}
	}
	printf("Sorted\n");
	for(i=0; i<numPhysAddr; ++i)
	{
		printf("%08x ",physToLinear[i].physAddr);
		if(7==(i&7))
		{
			printf("\n");
		}
	}
	printf("\n");

	// Find maximum continuous physical addresses.
	unsigned int maxExtend=0,baseIndex=0;
	for(i=0; i<numPhysAddr; ++i)
	{
		for(j=i+1; j<numPhysAddr; ++j)
		{
			if(physToLinear[j].physAddr!=physToLinear[j-1].physAddr+PAGE_SIZE)
			{
				break;
			}
		}

		if(maxExtend<j-i)
		{
			baseIndex=i;
			maxExtend=j-i;
		}
	}

	info.physAddr=physToLinear[baseIndex].physAddr;
	info.numberOfPages=maxExtend;
	info.pages=physToLinear+baseIndex;

	printf("Longest continuous physical memory space starts at:\n");
	printf("  Physical Address: %08xH\n",physToLinear[baseIndex].physAddr);
	printf("  Length:           %dKB\n",(PAGE_SIZE/1024)*maxExtend);

	return info;
}

extern void WriteToDMABuf(const struct bufferInfo *buf,unsigned long len,const unsigned char data[])
{
	unsigned int page=0,ptr=0;
	while(page<buf->numberOfPages && ptr<len)
	{
		unsigned int copyLen=SMALLER(len-ptr,PAGE_SIZE);
		memcpy(buf->pages[page].data,data+ptr,copyLen);
		++page;
		ptr+=PAGE_SIZE;
	}
}

extern void ReadFromDMABuf(unsigned char data[],const struct bufferInfo *buf,unsigned long len)
{
	unsigned int page=0,ptr=0;
	while(page<buf->numberOfPages && ptr<len)
	{
		unsigned int copyLen=SMALLER(len-ptr,PAGE_SIZE);
		memcpy(data+ptr,buf->pages[page].data,copyLen);
		++page;
		ptr+=PAGE_SIZE;
	}
}
