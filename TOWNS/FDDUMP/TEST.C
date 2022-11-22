// For Open Watcom C
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <dos.h>
#include <conio.h>
#include <signal.h>


#define TSUGARU_DEBUGBREAK				outp(0x2386,2);


void Restore(int dev);
#pragma aux Restore=\
"mov ah,03h"\
"mov al,bl"\
"int 93h" \
parm [ bx ]

void Seek(int dev,int trk);
#pragma aux Seek=\
"mov ah,04h"\
"mov al,bl"\
"int 93h"\
parm [ bx ] [ cx ]



int main(void)
{
	Restore(0x20);
	Restore(0x21);
	TSUGARU_DEBUGBREAK
	Seek(0x21,10);
	TSUGARU_DEBUGBREAK
	Seek(0x20,20);
	TSUGARU_DEBUGBREAK
	Seek(0x21,5);
	TSUGARU_DEBUGBREAK
	return 0;
}
