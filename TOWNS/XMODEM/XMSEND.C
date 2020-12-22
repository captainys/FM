#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>

#include "XMODEM.H"

extern void RS232C_STI(void);
extern void RS232C_CLI(void);
extern void RS232C_INIT(int baudRate); // 2:38400bps  4:19200bps
extern int RS232C_GETC(void); // Return value<0 means no data.
extern void RS232C_PUTC(int byteData);

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

void XModemSend(const char fName[],int baud)
{
	FILE *fp=fopen(fName,"rb");
	if(NULL==fp)
	{
		printf("Cannot open input file.\n");
		exit(1);
	}

	printf("Now start XMODEM transfer on the receiver.\n");
	WaitMS(500);

	RS232C_CLI();
	RS232C_INIT(baud);


	int c,checkSumOrCrc;
	while((c=RS232C_GETC())<0)
	{
	}
	switch(c)
	{
	case XMODEM_NAK:
		printf("XMODEM Checksum\n");
		checkSumOrCrc=XMODEM_MODE_CHECKSUM;
		break;
	case XMODEM_C:
		printf("XMODEM CRC\n");
		checkSumOrCrc=XMODEM_MODE_CRC;
		break;
	default:
		RS232C_STI();
		printf("Unknown mode.\n");
		exit(1);
		break;
	}
	RS232C_STI();
	WaitMS(100);
	RS232C_CLI();


	unsigned int totalSent=0,count=1,nBuffUsed=0;
	nBuffFilled=0;
	for(;;)
	{
		unsigned int dataCount,checkCalc;

		if(nBuffFilled<=nBuffUsed)
		{
			printf("Sent %d\n",totalSent);
			RS232C_STI();
			nBuffFilled=fread(buffer,1,BUFFER_SIZE,fp);
			RS232C_CLI();
			for(int i=nBuffFilled; i<BUFFER_SIZE; ++i)
			{
				buffer[i]=0;
			}
			nBuffUsed=0;
		}

		if(nBuffFilled<BUFFER_SIZE && nBuffFilled<=nBuffUsed)
		{
			RS232C_PUTC(XMODEM_EOT); // End of Transmission
			break;
		}


		RS232C_PUTC(XMODEM_SOH);
		RS232C_PUTC(count);
		RS232C_PUTC(~count);


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
				RS232C_PUTC(c);

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

			RS232C_PUTC(checkCalc>>8);
			RS232C_PUTC(checkCalc&0xFF);
		}
		else // Check Sum
		{
			for(dataCount=0; dataCount<XMODEM_PACKET_SIZE; ++dataCount)
			{
				int c=buffer[nBuffUsed++];
				RS232C_PUTC(c);
				checkCalc+=c;
			}
			RS232C_PUTC(checkCalc);
		}

		while((c=RS232C_GETC())<0)
		{
		}

		if(XMODEM_NAK==c)
		{
			nBuffUsed-=XMODEM_PACKET_SIZE;
		}
		else if(XMODEM_ACK==c)
		{
			totalSent+=XMODEM_PACKET_SIZE;
			++count;
		}
	}

	RS232C_STI();

	printf("Sent %d\n",totalSent);

	fclose(fp);
}

int main(int ac,char *av[])
{
	printf("XMSEND (XMODEM Send) Utility by CaptainYS\n");
	printf("http://www.ysflight.com\n");

	if(1==ac)
	{
		printf("Usage:\n");
		printf("  Run386 XMSEND filename\n");
		printf("Options:\n");
		printf("  -19200bps   Slow down to 19200bps (default 38400bps)\n");
		printf("Start this program and then start XMODEM Transfer in the host.\n");
		return 1;
	}

	int i;
	char fName[512];
	int baud=2;
	fName[0]=0;
	for(i=1; i<ac; ++i)
	{
		if(0==strcmp("-19200bps",av[i]) || 0==strcmp("-19200BPS",av[i]))
		{
			baud=4;
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
	if(0==fName[0])
	{
		printf("File name not specified.\n");
		return 1;
	}
	printf("Upload %s\n",fName);

	XModemSend(fName,baud);

	return 0;
}


