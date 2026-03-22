#include <stdio.h>
#include <string.h>

#define __CLI _inline(0xFA)
#define __STI _inline(0xFB)

extern void RS232C_INIT(int port,int baudRate); // 2:38400bps  4:19200bps
extern int RS232C_GETC(int port,int waitInUS); // Return value<0 means no data.
extern void RS232C_PUTC(int port,int byteData,int waitInUS);

int main(int ac,char *av[])
{
	if(1==ac)
	{
		printf("Usage:\n");
		printf("  Run386 XMSEND filename\n");
		printf("Options:\n");
		printf("  -19200bps   Slow down to 19200bps (default 38400bps)\n");
		printf("  -COM0 -COM1 -COM2 -COM3 -COM4  Select COM port.\n");
		printf("Start this program and then start XMODEM Transfer in the host.\n");
	}

	const char *str="Hello from TESTSEND";

	int i;
	int baud=2,port=0,waitInUS=0;
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



	__CLI;
	RS232C_INIT(port,baud);
	for(i=0; 0!=str[i]; ++i)
	{
		RS232C_PUTC(port,str[i],waitInUS);
	}
	__STI;
	return 0;
}
