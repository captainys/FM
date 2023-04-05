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
	unsigned int seg,offset;
	int length=256;
	unsigned int ctr=0;

	if(ac<3)
	{
		printf("Usage:\n");
		printf("REALDUMP SEG OFFSET <length>\n");
		return 1;
	}

	seg=xtoui(av[1]);
	offset=xtoui(av[2]);
	if(4<=ac)
	{
		length=atoi(av[3]);
	}

	printf("          +0 +1 +2 +3 +4 +5 +6 +7 +8 +9 +A +B +C +D +E +F\n");
	while(0<length)
	{
		unsigned char data=Peek(seg,offset);
		if(0==ctr%16)
		{
			printf("%04x:%04x",seg,offset);
		}
		printf(" %02x",data);
		if(0==(ctr+1)%16 || 1==length)
		{
			printf("\n");
		}

		++ctr;
		++offset;
		--length;
	}

	return 0;
}
