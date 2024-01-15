#include <conio.h>
#include "PIC.H"

const struct PICMask PIC_ENABLE_FDC_ONLY={{0xBF,0xFF}};

struct PICMask PIC_GetMask(void)
{
	struct PICMask mask;
	mask.m[0]=_inp(0x0002);
	mask.m[1]=_inp(0x0012);
	return mask;
}

void PIC_SetMask(struct PICMask mask)
{
	_outp(0x0002,mask.m[0]);
	_outp(0x0012,mask.m[1]);
}
