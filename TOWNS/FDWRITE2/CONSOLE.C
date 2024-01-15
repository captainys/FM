#include "CONSOLE.H"
#include <conio.h>
#include <fmcfrb.h>

void Palette(unsigned char code,unsigned char r,unsigned char g,unsigned char b)
{
	outp(0xFD90,code);
	outp(0xFD92,b&0xF0);
	outp(0xFD94,r&0xF0);
	outp(0xFD96,g&0xF0);
}

static VDB_ATR sysChrAttr[8];

void Color(unsigned int c)
{
	VDB_ATR atr;
	VDB_rddefatr(&atr);
	atr.color=c;
	VDB_setdefatr(&atr);
}

void PrintSysCharWord(char str[],unsigned int X,unsigned int color)
{
	int L;
	for(L=0; L<8 && 0!=str[L]; ++L)
	{
		VDB_rddefatr(&sysChrAttr[L]);
		sysChrAttr[L].color=color;
	}
	VDB_wtsysline(1,L,X,str,(char *)sysChrAttr);
}

void PrintDebugLine(void)
{
	PrintSysCharWord("[ACT]",1,COLOR_DEBUG);
}
