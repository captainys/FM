#ifndef CONSOLE_H_IS_INCLUDED
#define CONSOLE_H_IS_INCLUDED


#define COLOR_DEBUG 1

#define COLOR_ERR_CRC_AND_DDM 3
#define COLOR_ERR_CRC 2
#define COLOR_ERR_DDM 4
#define COLOR_ERR_RECORD_NOT_FOUND 5
#define COLOR_ERR_MISC 6
#define COLOR_NO_ERROR 7


void Palette(unsigned char code,unsigned char r,unsigned char g,unsigned char b);
void Color(unsigned int c);
void PrintSysCharWord(char str[],unsigned int X,unsigned int color);
void PrintDebugLine(void);

#endif
