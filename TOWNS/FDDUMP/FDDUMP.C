#include <stdio.h>
#include <dos.h>

#define FDC_INT	0x46

volatile unsigned char INT46_DID_COME_IN=0;

void interrupt (*Default_INT46H_Handler)(void);

void interrupt Handle_INT46H(void)
{
	INT46_DID_COME_IN=1;
}

int main(int ac,char *av[])
{
	Default_INT46H_Handler=_dos_getvect(FDC_INT);
	_dos_setvect(FDC_INT,Handle_INT46H);
	return 0;
}
