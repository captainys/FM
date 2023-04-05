// DUMP REAL-MODE MEMORY
// For WATCOM C

#include <stdio.h>
#include <stdlib.h>

unsigned char Peek(unsigned short SEG,unsigned short OFFSET);
#pragma aux Peek=\
"PUSH DS" \
"MOV DS,AX" \
"MOV AL,DS:[SI]" \
"POP DS" \
parm [ AX ] [ SI ] value [ AL ];


unsigned int xtoui(const char *str)
{
	unsigned int value=0;
	if('0'==str[0] && 'x'==str[1])
	{
		str+=2;
	}

	while(0!=*str)
	{
		char c=*str;
		value<<=4;
		if('a'<=c && c<='f')
		{
			value+=(10+c-'a');
		}
		else if('A'<=c && c<='F')
		{
			value+=(10+c-'A');
		}
		else if('0'<=c && c<='9')
		{
			value+=(c-'0');
		}
		else
		{
			break;
		}
		++str;
	}

	return value;
}

int main(int ac,char *av[])
{
	int i;
	unsigned int seg;
	int nPtn=0;
	unsigned char ptn[256];

	if(ac<2)
	{
		printf("Usage:\n");
		printf("REALFIND byte array\n");
		return 1;
	}

	for(i=1; i<ac && nPtn<256; ++i)
	{
		ptn[nPtn++]=xtoui(av[i]);
	}

	for(seg=0; seg<0xFFFF; ++seg)
	{
		unsigned int off;
		for(off=0; off<0x10; ++off)
		{
			for(i=0; i<nPtn; ++i)
			{
				if(Peek(seg,off+i)!=ptn[i])
				{
					break;
				}
			}
			if(i==nPtn)
			{
				printf("Found at %04x:%04x\n",seg,off);
			}
		}
	}

	return 0;
}
