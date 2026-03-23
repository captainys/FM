#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>
#include <conio.h>

#include "XMODEM.H"
#include "DEBUG.H"

#define VERSION "20260322c"

// #define __CLI _inline(0xFA)
// #define __STI _inline(0xFB)
#define __CLI
#define __STI
#define __WAIT_1US _inline(0xE6,0x6C)

extern void RS232C_INIT(int COMPort,int baudRate); // 2:38400bps  4:19200bps
extern void RS232C_END(void);
extern int RS232C_GETC(int COMPort,int waitInUS); // Return value<0 means no data.
extern void RS232C_PUTC(int COMPort,int byteData,int waitInUS);

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

	Palette(7,0xFF,0,0);

	int c,checkSumOrCrc,retry;
	const int maxNumRetry=2;
	for(retry=0; retry<maxNumRetry; ++retry)
	{
		while((c=RS232C_GETC(port,waitInUS))<0)
		{
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
			printf("Sent %d/%d\n",totalSent,sz);
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
		}

		if(c&0x40000000)
		{
			printf("                     i8251 Err\r");
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
	}

	__STI;

	printf("Sent %d\n",totalSent);

	Palette(7,0xFF,0xFF,0xFF);

	fclose(fp);

ABORT:
	RS232C_END();
}

int main(int ac,char *av[])
{
	printf("XMSEND (XMODEM Send) Utility by CaptainYS\n");
	printf("Version " VERSION "\n");
	printf("http://www.ysflight.com\n");

	if(1==ac)
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
		printf("  -19200bps   Slow down to 19200bps (default 38400bps)\n");
		printf("Start this program and then start XMODEM Transfer in the host.\n");
		return 1;
	}

	int i;
	char fName[512];
	int baud=2,port=0,byteWaitMicroSec=0;
	fName[0]=0;
	for(i=1; i<ac; ++i)
	{
		if(0==strcmp("-19200bps",av[i]) || 0==strcmp("-19200BPS",av[i]))
		{
			baud=4;
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
	switch(baud)
	{
	case 4:
		printf("19200bps\n");
		break;
	case 2:
		printf("38400bps\n");
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
		printf("File name not specified.\n");
		return 1;
	}
	printf("Upload %s\n",fName);

	_outp(0x0448,1); // Writing to VIDEO OUT Register 1
	_outp(0x044A,0x29);  // Palette for 16-color mode page 1, YS enabled, Layer1 has priority.

	XModemSend(fName,port,baud,byteWaitMicroSec);

	Palette(7,0xFF,0xFF,0xFF);

	return 0;
}


