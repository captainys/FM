#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>

#include <egb.h>
#include <mos.h>
#include <snd.h>
#include <fmcfrb.h>

#include "icmimage.h"

static char EGB_work[EgbWorkSize],mos[MosWorkSize],snd[16384];

void PrintString(int x,int y,const char str[])
{
	struct param
	{
		short x,y,len;
		char str[256];
	} param;

	param.x=x;
	param.y=y;
	param.len=strlen(str);
	strcpy(param.str,str);
	EGB_sjisString(EGB_work,&param);
}

void Logo(void)
{
	MOS_disp(0);
	PrintString(0,16,"IC Memory Card 救済IPL書き込みユーティリティ");
	PrintString(0,32,"by 山川機長 (http://www.ysflight.com)");
	PrintString(0,48,"IC Memory Card Rescue IPL Writer");
	PrintString(0,64,"by CaptainYS (http://www.ysflight.com)");
	PrintString(0,80,"Version ****");

	PrintString(0,128,"メモリカードを書き込み可能な状態にして、「書き込み」を選んで");
	PrintString(0,144,"ください。");
	PrintString(0,160,"Make Memory Card writable and select \"Write\"");
	MOS_disp(1);
}

void PrintMenu(int menuSel)
{
}

int RunMenu(void)
{
	Logo();

	int prevMenuSel=-1,menuSel=0;
	for(;;)
	{
		if(prevMenuSel!=menuSel)
		{
			// Draw Screen
			prevMenuSel=menuSel;
		}

		int gamePad;
		SND_joy_in_2(0,&gamePad);
		if(0xF0!=gamePad&0xF0)
		{
			break;
		}

		unsigned int encode;
		unsigned int inkey=KYB_read(1,&encode); // 1 means non-blocking.
		if(0xFF00!=(inkey&0xFF00))
		{
			unsigned int keyAddr=inkey&0xFF;
			if(0x35==keyAddr || // Space
			   0x1D==keyAddr || // Return
			   0x73==keyAddr) // Execute
			{
				break;
			}
		}

		int button,mx,my;
		MOS_rdpos(&button,&mx,&my);
		if(0!=(button&1))
		{
			break;
		}
	}
	return menuSel;
}

int main(int ac,char *av[])
{
	EGB_init(EGB_work,EgbWorkSize);
	EGB_resolution(EGB_work,0,3);	// 640x480 16 colors
	EGB_resolution(EGB_work,1,10);	// 320x240 32K colors

	EGB_writePage(EGB_work,1);
	EGB_displayStart(EGB_work,0,0,0);
	EGB_displayStart(EGB_work,2,2,2);
	EGB_displayStart(EGB_work,3,320,240);
	EGB_clearScreen(EGB_work);

	EGB_writePage(EGB_work,0);
	EGB_displayStart(EGB_work,0,0,0);
	EGB_displayStart(EGB_work,2,1,1);
	EGB_displayStart(EGB_work,3,640,480);
	EGB_clearScreen(EGB_work);

	EGB_displayPage(EGB_work,0,3);


	SND_init(snd);

	MOS_start(mos,MosWorkSize);
	MOS_disp(1);

	KYB_init();
	unsigned int modeSave=KYB_rdcode();
	KYB_setcode(0x4000); // Scan Mode/8bit Code/No Mask

	RunMenu();

	MOS_end();
	SND_end();
	KYB_setcode(modeSave); // Scan Mode/8bit Code/No Mask

	// Set to DOS mode.
	EGB_init(EGB_work,EgbWorkSize);
	EGB_resolution(EGB_work,0,1);	// 640x400 16 colors
	EGB_resolution(EGB_work,1,1);	// 640x400 16 colors

	EGB_writePage(EGB_work,1);
	EGB_displayStart(EGB_work,0,0,0);
	EGB_displayStart(EGB_work,2,1,1);
	EGB_displayStart(EGB_work,3,640,400);
	EGB_clearScreen(EGB_work);

	EGB_writePage(EGB_work,0);
	EGB_displayStart(EGB_work,0,0,0);
	EGB_displayStart(EGB_work,2,1,1);
	EGB_displayStart(EGB_work,3,640,400);
	EGB_clearScreen(EGB_work);

	return 0;
}
