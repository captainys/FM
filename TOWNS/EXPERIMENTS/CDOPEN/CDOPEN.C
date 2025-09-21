#include <conio.h>
#include <stdio.h>

#define IO_CDC_MASTER_CONTROL	0x04C0
#define IO_CDC_MASTER_STATUS	0x04C0
#define IO_CDC_COMMAND			0x04C2
#define IO_CDC_STATUS			0x04C2
#define IO_CDC_PARAM			0x04C4
#define IO_CDC_TFR_CONTROL		0x04C6

#define IO_FREERUN_TIMER		0x26

#define CMDFLAG_STATUS_REQUEST  0x20
#define CMDFLAG_IRQ             0x40

#define __CLI _inline(0xFA)
#define __STI _inline(0xFB)

#define MAX_NUM_RESPONSES 128

size_t nResp=0;
unsigned char data[MAX_NUM_RESPONSES][4];

int main(int ac,char *av[])
{
	if(ac<2)
	{
		printf("Usage: run386 cdopen o/c/l/u\n");
		printf("  o Open\n");
		printf("  c Close\n");
		printf("  l Lock\n");
		printf("  u Unlock\n");
		printf("  8 Send unknown command A1|02 08 00 00 00 00 00 00\n");
		return 1;
	}

	// Wait CDC Ready
	while(0==(_inp(IO_CDC_MASTER_STATUS)&1))
	{
	}

	// Push params
	switch(av[1][0])
	{
	case 'o':
	case 'O':
		_outp(IO_CDC_PARAM,2);
		_outp(IO_CDC_PARAM,2);
		break;
	case 'c':
	case 'C':
		_outp(IO_CDC_PARAM,2);
		_outp(IO_CDC_PARAM,4);
		break;
	case 'l':
	case 'L':
		_outp(IO_CDC_PARAM,2);
		_outp(IO_CDC_PARAM,1);
		break;
	case 'u':
	case 'U':
		_outp(IO_CDC_PARAM,2);
		_outp(IO_CDC_PARAM,0);
		break;
	case '8':
		_outp(IO_CDC_PARAM,2);
		_outp(IO_CDC_PARAM,8);
		break;
	default:
		printf("The option must be o, c, l, u, or 8\n");
		return 1;
	}
	_outp(IO_CDC_PARAM,0);
	_outp(IO_CDC_PARAM,0);
	_outp(IO_CDC_PARAM,0);
	_outp(IO_CDC_PARAM,0);
	_outp(IO_CDC_PARAM,0);
	_outp(IO_CDC_PARAM,0);

	// Wait CDC Ready
	while(0==(_inp(IO_CDC_MASTER_STATUS)&1))
	{
	}

	_outp(IO_CDC_COMMAND,0x81|CMDFLAG_STATUS_REQUEST);

	__CLI;

	unsigned int t0,accum=0;
	t0=inpw(IO_FREERUN_TIMER);
	while(accum<5000000) // Sample for 5000000us
	{
		unsigned short t,diff;
		t=inpw(IO_FREERUN_TIMER);
		diff=t-t0;
		accum+=diff;
		t0=t;

		if(0!=(_inp(IO_CDC_MASTER_STATUS)&2))
		{
			if(nResp<MAX_NUM_RESPONSES)
			{
				data[nResp][0]=_inp(IO_CDC_STATUS);
				data[nResp][1]=_inp(IO_CDC_STATUS);
				data[nResp][2]=_inp(IO_CDC_STATUS);
				data[nResp][3]=_inp(IO_CDC_STATUS);
				++nResp;
			}
			else
			{
				_inp(IO_CDC_STATUS);
				_inp(IO_CDC_STATUS);
				_inp(IO_CDC_STATUS);
				_inp(IO_CDC_STATUS);
			}
		}
	}

	__STI;

	for(int i=0; i<nResp; ++i)
	{
		printf("%02x %02x %02x %02x\n",data[i][0],data[i][1],data[i][2],data[i][3]);
	}

	return 0;
}
