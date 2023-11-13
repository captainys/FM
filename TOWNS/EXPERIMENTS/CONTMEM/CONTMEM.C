#include <stdio.h>


#define PAGE_SIZE 0x1000

#define DATABUF_SIZE (68*1024)
unsigned char _databuf[DATABUF_SIZE];

#define NUM_PHYSADDR (DATABUF_SIZE/4096)
unsigned int numPhysAddr=0;
unsigned int physAddr[NUM_PHYSADDR];



unsigned int ToPhysicalAddr(void *ptr);
unsigned char *MapToEndOfDS(unsigned int physAddr);



struct bufferInfo
{
	unsigned char *ptr;
	unsigned int physAddr;
	unsigned int length;
};

struct bufferInfo MakeDataBuffer(void)
{
	struct bufferInfo info;
	info.ptr=NULL;
	info.length=0;

	// Convert pointer to physical address.
	// Limit until PAGE_SIZE before the end of the array to make sure it gets continuous 4KB if low 11bits are all zero.
	int i,j;
	for(i=0; i<DATABUF_SIZE-PAGE_SIZE; ++i)
	{
		unsigned int phys=ToPhysicalAddr(_databuf+i);
		if(0==(phys&(PAGE_SIZE-1)) && numPhysAddr<NUM_PHYSADDR)
		{
			physAddr[numPhysAddr]=phys;
		}
	}

	// Sort page-top physical addresses.
	for(i=0; i<numPhysAddr; ++i)
	{
		for(j=i+1; j<numPhysAddr; ++j)
		{
			if(physAddr[i]>physAddr[j])
			{
				unsigned int swp=physAddr[i];
				physAddr[i]=physAddr[j];
				physAddr[j]=swp;
			}
		}
	}

	// Find maximum continuous physical addresses.
	unsigned int maxExtend=0,baseIndex=0;
	for(i=1; i<numPhysAddr; ++i)
	{
		for(j=i+1; j<numPhysAddr; ++j)
		{
			if(physAddr[j]!=physAddr[i]+PAGE_SIZE)
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

	// Map to the end of DS
	unsigned char *prevMapped=NULL;
	for(i=0; i<maxExtend; ++i)
	{
		unsigned char *mapped=MapToEndOfDS(physAddr[baseIndex+i]);
		if(0==i)
		{
			info.ptr=mapped;
			info.physAddr=physAddr[baseIndex+i];
		}
		else
		{
			if(PAGE_SIZE!=(mapped-prevMapped))
			{
				printf("Contradiction!\n");
				exit(1);
			}
		}
		prevMapped=mapped;
	}

	info.length=maxExtend*PAGE_SIZE;

	// Verify
	unsigned int prevPhys;
	for(int i=0; i<info.length; ++i)
	{
		unsigned int phys=ToPhysicalAddr(info.ptr+i);
		if(0<i && 1!=phys-prevPhys)
		{
			printf("Buffer Address Verification Failure!\n");
			exit(1);
		}
		prevPhys=phys;
	}

	return info;
}



int main(void)
{
	unsigned char *data=MakeDataBuffer();
}
