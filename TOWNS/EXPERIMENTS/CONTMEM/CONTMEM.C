#include <stdio.h>


#define PAGE_SIZE 0x1000

#define DATABUF_SIZE (128*1024)
unsigned char _databuf[DATABUF_SIZE];

#define NUM_PHYSADDR ((DATABUF_SIZE+PAGE_SIZE-1)/PAGE_SIZE)
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

/*
This function finds physical addresses of the pages within _databuf, sort them, and find sequence of pages that
are continuous in the physical memory space.  The pages are added to the end of the data segment, and the pointer
is returned.

The length is up to 128KB, but most likely shorter.  The return value contains pointer to the physically-continuous
memory space, physical address, and the length.

*/
struct bufferInfo MakeDataBuffer(void)
{
	for(int i=0; i<DATABUF_SIZE; ++i)
	{
		_databuf[i]=0x77;
	}

	struct bufferInfo info;
	info.ptr=NULL;
	info.length=0;

	printf("Looking for physically-continuous memory space....\n");

	// Convert pointer to physical address.
	// Limit until PAGE_SIZE before the end of the array to make sure it gets continuous 4KB if low 11bits are all zero.
	int i,j;
	for(i=0; i<DATABUF_SIZE-PAGE_SIZE; ++i)
	{
		unsigned int phys=ToPhysicalAddr(_databuf+i);
		if(0==(phys&(PAGE_SIZE-1)) && numPhysAddr<NUM_PHYSADDR)
		{
			printf("%08x ",phys);
			physAddr[numPhysAddr++]=phys;
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
			if(physAddr[i]>physAddr[j])
			{
				unsigned int swp=physAddr[i];
				physAddr[i]=physAddr[j];
				physAddr[j]=swp;
			}
		}
	}
	printf("Sorted\n");
	for(i=0; i<numPhysAddr; ++i)
	{
		printf("%08x ",physAddr[i]);
		if(0==(i&7))
		{
			printf("\n");
		}
	}
	printf("\n");

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
	printf("Longest continuous physical memory space starts at:\n");
	printf("  Physical Address: %08xH\n",physAddr[baseIndex]);
	printf("  Length:           %dKB\n",(PAGE_SIZE/4)*maxExtend);

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

	printf("Verify really continuous.\n");
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

		info.ptr[i]=0xFF;
		if(0xFF!=info.ptr[i])
		{
			printf("Write error to the mapped address.\n");
			exit(1);
		}
		info.ptr[i]=0x00;
		if(0x00!=info.ptr[i])
		{
			printf("Write error to the mapped address.\n");
			exit(1);
		}
	}

	for(i=0; i<DATABUF_SIZE; ++i)
	{
		_databuf[i]=0xFF;
	}
	for(int i=0; i<info.length; ++i)
	{
		if(0xFF!=info.ptr[i])
		{
			printf("Mapping error.\n");
			exit(1);
		}
	}
	for(i=0; i<DATABUF_SIZE; ++i)
	{
		_databuf[i]=0x00;
	}
	for(int i=0; i<info.length; ++i)
	{
		if(0x00!=info.ptr[i])
		{
			printf("Mapping error.\n");
			exit(1);
		}
	}



	printf("Verified.\n");
	return info;
}



int main(void)
{
	unsigned char *data=MakeDataBuffer();
}
