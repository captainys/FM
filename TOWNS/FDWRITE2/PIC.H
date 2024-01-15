#ifndef PIC_H_IS_INCLUDED
#define PIC_H_IS_INCLUDED

struct PICMask
{
	unsigned char m[2];
};

extern const struct PICMask PIC_ENABLE_FDC_ONLY;

struct PICMask PIC_GetMask(void);
void PIC_SetMask(struct PICMask mask);

#endif
