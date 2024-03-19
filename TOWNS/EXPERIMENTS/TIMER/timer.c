// Linux seems to be polling I/O 60H.  Does it work in the real hardware?
// It is very weird because TM0OUT should be cleared in the timer interrupt.
// If so, unless IF=0 or TM0MSKed, polling does not work.
#include <conio.h>
#include <stdio.h>

extern void POLL_TIMER();

int main(void)
{
	for(int i=0; i<10; ++i)
	{
		POLL_TIMER();
		printf(".\n");
	}
	return 0;
}
