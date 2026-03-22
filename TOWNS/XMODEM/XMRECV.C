#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>

#include "XMODEM.H"

#define VERSION "20260321c"

#define __CLI _inline(0xFA)
#define __STI _inline(0xFB)
#define __WAIT_1US _inline(0xE6,0x6C)

extern void RS232C_INIT(int COMPort,int baudRate); // 2:38400bps  4:19200bps
extern int RS232C_GETC(int COMPort,int waitInUS); // Return value<0 means no data.
extern void RS232C_PUTC(int COMPort,int byteData,int waitInUS);

void Wait10ms(void)
{
	auto t0=clock(); // It is real time clock in Towns.  clock() is not useless like in Unix.
	while(clock()-t0<CLOCKS_PER_SEC/100)
	{
	}
}

#define BUFFER_SIZE 4096
unsigned int nBuffFilled=0;
unsigned char buffer[BUFFER_SIZE];

void XModemReceive(const char fName[],int port,int baud,int waitInUS,int checkSumOrCrc)
{
	FILE *fp=fopen(fName,"wb");
	if(NULL==fp)
	{
		printf("Cannot open output file.\n");
		exit(1);
	}

	__CLI;
	RS232C_INIT(port,baud);

	switch(checkSumOrCrc)
	{
	case XMODEM_MODE_CHECKSUM:
		RS232C_PUTC(port,XMODEM_NAK,waitInUS);
		break;
	case XMODEM_MODE_CRC:
		RS232C_PUTC(port,XMODEM_C,waitInUS);
		break;
	}

	unsigned int totalReceived=0;
	nBuffFilled=0;
	for(;;)
	{
		int i;
		int index[2];
		unsigned int dataCount,checkRecv,checkCalc;

		// Wait for SOH or EOT
		for(;;)
		{
			int c=RS232C_GETC(port,waitInUS);
			if(c==XMODEM_SOH)
			{
				break;
			}
			else if(c==XMODEM_EOT)
			{
				RS232C_PUTC(port,XMODEM_ACK,waitInUS); // End of Transmission
				goto EOT;
			}
		}

		// Receive index1 and index2
		for(i=0; i<2; ++i)
		{
			int c;
			while((c=RS232C_GETC(port,waitInUS))<0)
			{
			}
			index[i]=c;
		}

		checkRecv=0;
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
				int i,c;
				while((c=RS232C_GETC(port,waitInUS))<0)
				{
				}
				buffer[nBuffFilled++]=(unsigned char)c;

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

			int c;
			while((c=RS232C_GETC(port,waitInUS))<0)
			{
			}
			checkRecv=(c<<8);
			while((c=RS232C_GETC(port,waitInUS))<0)
			{
			}
			checkRecv|=c;
		}
		else // Check Sum
		{
			for(dataCount=0; dataCount<XMODEM_PACKET_SIZE; ++dataCount)
			{
				int c;
				while((c=RS232C_GETC(port,waitInUS))<0)
				{
				}
				buffer[nBuffFilled++]=(unsigned char)c;
				checkCalc+=c;
			}

			int c;
			while((c=RS232C_GETC(port,waitInUS))<0)
			{
			}
			checkRecv=c;
			checkCalc&=0xFF;
		}

		if(checkRecv!=checkCalc)
		{
			printf("CRC or Checksum Error! %04x %04x\n",checkRecv,checkCalc);
			__STI;
			Wait10ms();
			__CLI;
			RS232C_PUTC(port,XMODEM_NAK,waitInUS);
			nBuffFilled-=XMODEM_PACKET_SIZE;
		}
		else
		{
			if(BUFFER_SIZE<=nBuffFilled)
			{
				totalReceived+=nBuffFilled;
				printf("%d\n",totalReceived);
				__STI;
				fwrite(buffer,1,nBuffFilled,fp);
				nBuffFilled=0;
				__CLI;
			}
			RS232C_PUTC(port,XMODEM_ACK,waitInUS);
		}
	}
EOT:

	clock_t clk0=clock(); // Might receive ETB
	while(clock()-clk0<CLOCKS_PER_SEC/2)
	{
		int c=RS232C_GETC(port,waitInUS);
		if(0<=c)
		{
		}
	}

	__STI;

	if(0<nBuffFilled)
	{
		totalReceived+=nBuffFilled;
		printf("%d\n",totalReceived);
		fwrite(buffer,1,nBuffFilled,fp);
		nBuffFilled=0;
	}

	fclose(fp);
}

int main(int ac,char *av[])
{
	printf("XMRECV (XMODEM Receive) Utility by CaptainYS\n");
	printf("Version " VERSION "\n");
	printf("http://www.ysflight.com\n");
	Wait10ms();  // Let Towns console emulator flush.

	if(1==ac)
	{
		printf("Usage:\n");
		printf("  Run386 XMRECV filename\n");
		printf("Options:\n");
		printf("  -19200bps\n");
		printf("     Slow down to 19200bps (default 38400bps)\n");
		printf("  -checksum\n");
		printf("     Use XMODEM Checksum (default XMODEM CRC)\n");
		printf("  -COM0 -COM1 -COM2 -COM3 -COM4\n");
		printf("     Select COM port.\n");
		printf("  -wait microsec\n");
		printf("     Wait specified micro seconds before sending a byte.\n");
		printf("Start XMODEM Transfer in the host, and then run this command.\n");
		return 1;
	}

	int i;
	char fName[512];
	int baud=2,port=0,byteWaitMicroSec=0;
	int mode=XMODEM_MODE_CRC;
	fName[0]=0;
	for(i=1; i<ac; ++i)
	{
		if(0==strcmp("-19200bps",av[i]) || 0==strcmp("-19200BPS",av[i]))
		{
			baud=4;
		}
		else if(0==strcmp("-checksum",av[i]) || 0==strcmp("-CHECKSUM",av[i]))
		{
			mode=XMODEM_MODE_CHECKSUM;
		}
		else if((0==strcmp("-WAIT",av[i]) || 0==strcmp("-wait",av[i])) && i+1<ac)
		{
			byteWaitMicroSec=atoi(av[i+1]);
			++i;
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
		else
		{
			strcpy(fName,av[i]);
		}
	}
	switch(mode)
	{
	case XMODEM_MODE_CRC:
		printf("XMODEM CRC\n");
		break;
	case XMODEM_MODE_CHECKSUM:
		printf("XMODEM CHECKSUM\n");
		break;
	default:
		printf("Undefined XMODEM mode.\n");
		return 1;
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
	printf("Download to %s\n",fName);

	XModemReceive(fName,port,baud,byteWaitMicroSec,mode);

	return 0;
}


