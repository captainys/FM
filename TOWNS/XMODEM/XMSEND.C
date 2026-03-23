#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>
#include <conio.h>

#include "XMODEM.H"
#include "DEBUG.H"

#define VERSION "20260323c"

// #define __CLI _inline(0xFA)
// #define __STI _inline(0xFB)
#define __CLI
#define __STI
#define __WAIT_1US _inline(0xE6,0x6C)

extern void RS232C_INIT(int COMPort,int baudRate); // 2:38400bps  4:19200bps
extern void RS232C_END(void);
extern int RS232C_GETC(int COMPort,int waitInUS); // Return value<0 means no data.
extern void RS232C_PUTC(int COMPort,int byteData,int waitInUS);
extern int PadABButton(void);

void WaitMS(unsigned int ms)
{
	auto t0=clock(); // It is real time clock in Towns.  clock() is not useless like in Unix.
	while(clock()-t0<CLOCKS_PER_SEC*ms/1000)
	{
	}
}

#define BUFFER_SIZE 8192
unsigned int nBuffFilled=0;
unsigned char buffer[BUFFER_SIZE];

void XModemSend(const char fName[],int port,int baud,int waitInUS)
{
	FILE *fp=fopen(fName,"rb");
	unsigned int sz=0;
	if(NULL==fp)
	{
		printf("Cannot open input file.\n");
		exit(1);
	}

	fseek(fp,0,SEEK_END);
	sz=ftell(fp);
	fseek(fp,0,SEEK_SET);

	printf("Now start XMODEM transfer on the receiver.\n");
	WaitMS(500);

	__CLI;
	RS232C_INIT(port,baud);

	Palette(7,0,0xFF,0);

	int c,checkSumOrCrc,retry;
	const int maxNumRetry=2;
	for(retry=0; retry<maxNumRetry; ++retry)
	{
		while((c=RS232C_GETC(port,waitInUS))<0)
		{
			if(0!=PadABButton())
			{
				printf("Abort.\n");
				goto ABORT;
			}
		}
		c&=0xFF;
		if(XMODEM_NAK==c)
		{
			printf("XMODEM Checksum\n");
			checkSumOrCrc=XMODEM_MODE_CHECKSUM;
			break;
		}
		else if(XMODEM_C==c)
		{
			printf("XMODEM CRC\n");
			checkSumOrCrc=XMODEM_MODE_CRC;
			break;
		}
		else
		{
			__STI;
			printf("Unknown mode.\n");
		}
	}
	if(maxNumRetry==retry)
	{
		goto ABORT;
	}

	__STI;
	WaitMS(100);
	__CLI;

	Palette(7,0,0xFF,0);

	unsigned int totalSent=0,count=1,nBuffUsed=0;
	nBuffFilled=0;
	for(;;)
	{
		Palette(7,0xFF,0,0);

		unsigned int dataCount,checkCalc;

		if(nBuffFilled<=nBuffUsed)
		{
			printf("Sent %10d/%10d\r",totalSent,sz);
			__STI;
			nBuffFilled=fread(buffer,1,BUFFER_SIZE,fp);
			__CLI;
			for(int i=nBuffFilled; i<BUFFER_SIZE; ++i)
			{
				buffer[i]=0;
			}
			nBuffUsed=0;
		}

		if(nBuffFilled<BUFFER_SIZE && nBuffFilled<=nBuffUsed)
		{
			RS232C_PUTC(port,XMODEM_EOT,waitInUS); // End of Transmission
			break;
		}

		Palette(7,0,0xFF,0);

		RS232C_PUTC(port,XMODEM_SOH,waitInUS);
		RS232C_PUTC(port,count,waitInUS);
		RS232C_PUTC(port,~count,waitInUS);

		Palette(7,0,0,0xFF);

		checkCalc=0;
		if(XMODEM_MODE_CRC==checkSumOrCrc)
		{
			// CRC calculation
			// XMODEM_CALC_CRC_OUTER_LOOP:
			// 						LODSB
			// 						; First shift, then xor: Take XOR of high-byte of DX and AL
			// 						XOR		DH,AL
			// 
			// 						MOV		AH,8
			// XMODEM_CALC_CRC_INNER_LOOP:
			// 						SHL		DX,1
			// 						JAE		@f		; Jump if no carry, means DX WAS zero or positive.
			// 
			// 						XOR		DX,1021H
			// @@:
			// 						DEC		AH
			// 						JNE		XMODEM_CALC_CRC_INNER_LOOP

			for(dataCount=0; dataCount<XMODEM_PACKET_SIZE; ++dataCount)
			{
				int i,c=buffer[nBuffUsed++];
				RS232C_PUTC(port,c,waitInUS);

				checkCalc^=(c<<8);
				for(i=0; i<8; ++i)
				{
					checkCalc<<=1;
					if(0!=(checkCalc&0x10000))
					{
						checkCalc^=0x11021;
					}
				}
			}

			RS232C_PUTC(port,checkCalc>>8,waitInUS);
			RS232C_PUTC(port,checkCalc&0xFF,waitInUS);
		}
		else // Check Sum
		{
			for(dataCount=0; dataCount<XMODEM_PACKET_SIZE; ++dataCount)
			{
				int c=buffer[nBuffUsed++];
				RS232C_PUTC(port,c,waitInUS);
				checkCalc+=c;
			}
			RS232C_PUTC(port,checkCalc,waitInUS);
		}

		Palette(7,0xFF,0,0xFF);

		while((c=RS232C_GETC(port,waitInUS))<0)
		{
			if(0!=PadABButton())
			{
				printf("\nAbort.\n");
				goto ABORT;
			}
		}

		c&=0xFF;

		if(XMODEM_NAK==c)
		{
			nBuffUsed-=XMODEM_PACKET_SIZE;
		}
		else if(XMODEM_ACK==c)
		{
			totalSent+=XMODEM_PACKET_SIZE;
			++count;
		}

		Palette(7,0,0xFF,0xFF);

		if(0!=PadABButton())
		{
			printf("\nAbort.\n");
			goto ABORT;
		}
	}

	__STI;

	printf("\nSent %d\n",totalSent);
	printf("Done\n");

	Palette(7,0xFF,0xFF,0xFF);

ABORT:
	fclose(fp);

	RS232C_END();
}

void Help(void)
{
	printf("Usage:\n");
	printf("  Run386 XMSEND filename\n");
	printf("Options:\n");
	printf("  -19200bps\n");
	printf("     Slow down to 19200bps (default 38400bps)\n");
	printf("  -COM0 -COM1 -COM2 -COM3 -COM4\n");
	printf("     Select COM port.\n");
	printf("  -wait microsec\n");
	printf("     Wait specified micro seconds before sending a byte.\n");
	printf("  -1200bps,-4800bps,-9600bps,-19200bps,-38400bps\n");
	printf("     Specify baud rate.  Port 0 default is 38400bps, and other pots 19200bps.\n");
	printf("     FM TOWNS's On-board RS232C can transmit at 3400bps maximum.\n");
	printf("     Urban Corporation Fast RS232C board, Turbo 232CT, can go up to 115200bps.\n");
	printf("     If you want to take advantage of 115200bps,\n");
	printf("     (1) Connect cable to CH1 on the board.\n");
	printf("     (2) Set dip switch 1 and 8 OFF, 2 to 7 ON.\n");
	printf("     (3) Use -COM1 and -19200bps options.\n");
	printf("     TOWNS will think it is communicating at 19200bps, but it is boosted to\n");
	printf("     115200bps by Turbo 232CT.\n");
	printf("Start this program and then start XMODEM Transfer in the host.\n");
}

int main(int ac,char *av[])
{
	printf("XMSEND (XMODEM Send) Utility by CaptainYS\n");
	printf("Version " VERSION "\n");
	printf("http://www.ysflight.com\n");

	if(1==ac)
	{
		Help();
		return 1;
	}

	int i;
	char fName[512];
	int baud=0,port=0,byteWaitMicroSec=0;
	fName[0]=0;
	for(i=1; i<ac; ++i)
	{
		if(0==strcmp("-1200bps",av[i]) || 0==strcmp("-1200BPS",av[i]) ||
		   0==strcmp("-2400bps",av[i]) || 0==strcmp("-2400BPS",av[i]) ||
		   0==strcmp("-4800bps",av[i]) || 0==strcmp("-4800BPS",av[i]) ||
		   0==strcmp("-9600bps",av[i]) || 0==strcmp("-9600BPS",av[i]) ||
		   0==strcmp("-19200bps",av[i]) || 0==strcmp("-19200BPS",av[i]) ||
		   0==strcmp("-38400bps",av[i]) || 0==strcmp("-38400BPS",av[i]))
		{
			int bps=atoi(av[i]+1);
			baud=76800/bps;
		}
		else if(0==strncmp("-COM",av[i],4) || 0==strncmp("-com",av[i],4))
		{
			if('0'<=av[i][4] && av[i][4]<='4')
			{
				port=av[i][4]-'0';
			}
			else
			{
				printf("Port number needs to be between 0 and 4.\n");
				return 1;
			}
		}
		else if((0==strcmp("-WAIT",av[i]) || 0==strcmp("-wait",av[i])) && i+1<ac)
		{
			byteWaitMicroSec=atoi(av[i+1]);
			++i;
		}
		else
		{
			strcpy(fName,av[i]);
		}
	}
	if(0==baud)
	{
		if(0==port)
		{
			baud=2; // 38400bps
		}
		else
		{
			baud=4; // 19200bps
		}
	}
	switch(baud)
	{
	case 64:
	case 32:
	case 16:
	case 8:
	case 4:
	case 2:
		printf("%dbps\n",76800/baud);
		break;
	default:
		printf("Undefined baud rate.\n");
		return 1;
	}
	if(0!=byteWaitMicroSec)
	{
		printf("Wait %d us before sending each byte\n",byteWaitMicroSec);
	}
	if(0==fName[0])
	{
		Help();
		printf("File name not specified.\n");
		return 1;
	}
	printf("Upload %s\n",fName);

	_outp(0x0448,1); // Writing to VIDEO OUT Register 1
	_outp(0x044A,0x29);  // Palette for 16-color mode page 1, YS enabled, Layer1 has priority.

	printf("Press Game PAD0 A+B buttons to abort.\n");
	XModemSend(fName,port,baud,byteWaitMicroSec);

	Palette(7,0xFF,0xFF,0xFF);

	return 0;
}


