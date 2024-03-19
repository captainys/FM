// Linux seems to be polling I/O 60H.  Does it work in the real hardware?
// It is very weird because TM0OUT should be cleared in the timer interrupt.
// If so, unless IF=0 or TM0MSKed, polling does not work.
#include <conio.h>
#include <stdio.h>
#include <dos.h>

extern void POLL_TIMER();

int c=0;

#pragma Calling_convention(_INTERRUPT|_CALLING_CONVENTION);
_Handler Handle_INT40H(void)
{
	unsigned char AL=_inp(0x60);
	AL>>=2;
	AL&=7;
	AL|=0x80;
	_outp(0x60,AL);
	++c;

	// EOI
	_outp(0x0000,0x60|0x00); // Specific EOI + INT 0(40H).

	return 0;
}
#pragma Calling_convention();

int main(void)
{
	_Handler save40H=_getpvect (0x40);

	_setpvect(0x40,Handle_INT40H);

	for(int i=0; i<3; ++i)
	{
		POLL_TIMER();
		printf(".\n");
	}

	_setpvect(0x40,save40H);

	printf("%d times timer INT fired.\n",c);

	return 0;
}
