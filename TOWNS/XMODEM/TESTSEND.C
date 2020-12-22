#include <stdio.h>

extern void RS232C_STI(void);
extern void RS232C_CLI(void);
extern void RS232C_INIT(int baudRate); // 2:38400bps  4:19200bps
extern int RS232C_GETC(void); // Return value<0 means no data.
extern void RS232C_PUTC(int byteData);

int main(void)
{
	const char *str="Hello from TESTSEND";
	RS232C_CLI();
	RS232C_INIT(2);
	for(int i=0; 0!=str[i]; ++i)
	{
		RS232C_PUTC(str[i]);
	}
	RS232C_STI();
	return 0;
}
