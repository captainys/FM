#include "timer.h"
#include <conio.h>

void Wait10ms(void)
{
	unsigned short t0,accum=0;
	t0=inpw(IO_FREERUN_TIMER);
	while(accum<10000)
	{
		unsigned short t,diff;
		t=inpw(IO_FREERUN_TIMER);
		diff=t-t0;
		accum+=diff;
		t0=t;
	}
}

void WaitMicrosec(unsigned int microsec)
{
	unsigned short t0;
	unsigned int  accum=0;
	t0=inpw(IO_FREERUN_TIMER);
	while(accum<microsec)
	{
		unsigned short t,diff;
		t=inpw(IO_FREERUN_TIMER);
		diff=t-t0;
		accum+=diff;
		t0=t;
	}
}
