#ifndef DMABUF_IS_INCLUDED
#define DMABUF_IS_INCLUDED

#define PAGE_SIZE 0x1000

struct PhysToLinear
{
	unsigned int physAddr;
	unsigned char *data;
};

struct bufferInfo
{
	unsigned int physAddr;
	unsigned int numberOfPages;
	struct PhysToLinear *pages;
};

extern struct bufferInfo MakeDataBuffer(void);
extern void WriteToDMABuf(const struct bufferInfo *buf,unsigned long len,const unsigned char data[]);
extern void ReadFromDMABuf(unsigned char data[],const struct bufferInfo *buf,unsigned long len);

#endif
