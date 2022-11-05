#include <stdio.h>
#include <stdlib.h>
#include <dos.h>
#include <conio.h>
#include <signal.h>

// Output Data Data Format (.TD1)
// Begin Disk
// 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 (16 bytes)
// Begin Track
// 01 00 cc hh 00 00 00 00 00 00 00 00 00 00 00 00 (16 bytes)
// ID Mark
// 02 00 cc hh rr nn <CRC> 00 00 00 00 00 00 00 00
// 02 00 cc hh rr nn <CRC> 00 00 00 00 00 00 00 00
// 02 00 cc hh rr nn <CRC> 00 00 00 00 00 00 00 00
//     :
// Data
// 03 00 cc hh rr nn st 00 00 00 00 00 <Real Size>
// (Bytes padded to 16*N bytes)
// Track Read
// 04 00 00 00 00 00 00 00 00 00 00 00 <Real Size>
// (Bytes padded to 16*N bytes)

// Next Track


#define FDC_INT	0x46

volatile unsigned char INT46_DID_COME_IN=0;

void interrupt (*Default_INT46H_Handler)(void);

void interrupt Handle_INT46H(void)
{
	INT46_DID_COME_IN=1;
}

void CtrlC(int err)
{
	_dos_setvect(FDC_INT,Default_INT46H_Handler);
	printf("Intercepted Ctrl+C\n");
	exit(1);
}


struct CommandParameterInfo
{
};

void ReadDisk(struct CommandParameterInfo *cpi)
{
}

unsigned char FreeRunTimerAvailable(void)
{
}

int main(int ac,char *av[])
{
	Default_INT46H_Handler=_dos_getvect(FDC_INT);
	_dos_setvect(FDC_INT,Handle_INT46H);
	signal(SIGINT,CtrlC);



	return 0;
}
