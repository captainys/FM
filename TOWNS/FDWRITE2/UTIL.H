#ifndef UTIL_H_IS_NOT_INCLUDED
#define UTIL_H_IS_NOT_INCLUDED

#include <stdio.h>

unsigned long DWordToUnsignedInt(const unsigned char data[]);
unsigned short WordToUnsignedShort(const unsigned char data[]);

/* Length of ext must be at least 5.
   '.' 'R' 'D' 'D' '\0'
*/
void ExtractExtension(char ext[5],const char fileName[]);

size_t GetFileSize(const char fileName[]);

unsigned int IdentifyFileType(const char fileName[]);


// In ASM.ASM
extern Tsugaru_Debug(const char str[]);


#endif
