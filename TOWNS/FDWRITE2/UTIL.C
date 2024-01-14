#include "UTIL.H"



unsigned long DWordToUnsignedInt(const unsigned char data[])
{
	return *(unsigned long *)data;
}

unsigned short WordToUnsignedShort(const unsigned char data[])
{
	return *(unsigned short *)data;
}
