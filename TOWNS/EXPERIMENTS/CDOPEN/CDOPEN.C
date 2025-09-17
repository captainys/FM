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

int main(void)
{
	// Wait CDC Ready
	while(0==(_inp(IO_CDC_MASTER_STATUS)&1))
	{
	}

	// Push params
	_outp(IO_CDC_PARAM,3);
	_outp(IO_CDC_PARAM,0);
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

	_outp(IO_CDC_COMMAND,0x1F|CMDFLAG_STATUS_REQUEST);

	__CLI;

	unsigned int t0,accum=0;
	t0=inpw(IO_FREERUN_TIMER);
	while(accum<1000000) // Sample for 1000000us
	{
		unsigned short t,diff;
		t=inpw(IO_FREERUN_TIMER);
		diff=t-t0;
		accum+=diff;
		t0=t;

		if(0!=(_inp(IO_CDC_MASTER_STATUS)&2) && nResp<MAX_NUM_RESPONSES)
		{
			data[nResp][0]=_inp(IO_CDC_STATUS);
			data[nResp][1]=_inp(IO_CDC_STATUS);
			data[nResp][2]=_inp(IO_CDC_STATUS);
			data[nResp][3]=_inp(IO_CDC_STATUS);
			++nResp;
		}
	}

	__STI;

	for(int i=0; i<nResp; ++i)
	{
		printf("%02x %02x %02x %02x\n",data[i][0],data[i][1],data[i][2],data[i][3]);
	}

	return 0;
}
