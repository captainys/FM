#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>

#include "../XMODEM/XMODEM.H"

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

void XModemSend(unsigned int dataLength,const unsigned char data[],int baud)
{
	printf("Ready to transmit.\n");
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


	const int updateCycle=8192;
	unsigned int count=1,dataPtr=0,nextUpdate=updateCycle;
	for(;;)
	{
		unsigned int dataCount,checkCalc;

		if(nextUpdate<=dataPtr)
		{
			printf("Sent %d\n",dataPtr);
			RS232C_STI();
			clock_t clk=clock();
			while(clock()<clk+CLOCKS_PER_SEC/100);
			RS232C_CLI();

			nextUpdate+=updateCycle;
		}

		if(dataLength<=dataPtr)
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
				int i,c=(dataPtr<dataLength ? data[dataPtr] : 0);
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
				++dataPtr;
			}

			RS232C_PUTC(checkCalc>>8);
			RS232C_PUTC(checkCalc&0xFF);
		}
		else // Check Sum
		{
			for(dataCount=0; dataCount<XMODEM_PACKET_SIZE; ++dataCount)
			{
				int c=(dataPtr<dataLength ? data[dataPtr] : 0);
				RS232C_PUTC(c);
				checkCalc+=c;
				++dataPtr;
			}
			RS232C_PUTC(checkCalc);
		}

		while((c=RS232C_GETC())<0)
		{
		}

		if(XMODEM_NAK==c)
		{
			dataPtr-=XMODEM_PACKET_SIZE;
		}
		else if(XMODEM_ACK==c)
		{
			++count;
		}
	}

	RS232C_STI();

	printf("Sent %d\n",dataPtr);
}
