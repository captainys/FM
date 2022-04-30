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
	EGB_color(EGB_work,0,15);
	EGB_sjisString(EGB_work,&param);
}

void DrawRect(int x0,int y0,int x1,int y1,int color)
{
	EGB_color(EGB_work,0,color);
	short param[4]={x0,y0,x1,y1};
	EGB_rectangle(EGB_work,param);
}

void Logo(void)
{
	MOS_disp(0);
	PrintString(0,16,"IC Memory Card 救済IPL書き込みユーティリティ");
	PrintString(0,32,"by 山川機長 (http://www.ysflight.com)");
	PrintString(0,48,"IC Memory Card Rescue IPL Writer");
	PrintString(0,64,"by CaptainYS (http://www.ysflight.com)");
	PrintString(0,80,"Version ****");

	PrintString(0,128,"メモリカードを書き込み可能な状態にして、「書き込み」を選んでください。");
	PrintString(0,144,"キーボード,マウス,パッドで操作できます。");
	PrintString(0,160,"Make Memory Card writable and select \"Write\"");
	PrintString(0,176,"Use keyboard, mouse, or pad to make selection.");
	MOS_disp(1);
}

#define MENUX0 80
#define MENUX1 560
#define MENU0_Y0 (224-16-16)
#define MENU0_Y1 (224+16)
#define MENU1_Y0 (320-16-16)
#define MENU1_Y1 (320+16)

void PrintMenu(int menuSel)
{
	MOS_disp(0);

	DrawRect(MENUX0,MENU0_Y0,MENUX1,MENU0_Y1,(0==menuSel ? 15 : 0));
	PrintString(100,224,"書き込み Write");

	DrawRect(MENUX0,MENU1_Y0,MENUX1,MENU1_Y1,(1==menuSel ? 15 : 0));
	PrintString(100,320,"やっぱり書かない Cancel Write");

	MOS_disp(1);
}

int RunMenu(void)
{
	Logo();

	unsigned int prevPad=0;
	int prevMenuSel=-1,menuSel=0;
	for(;;)
	{
		if(prevMenuSel!=menuSel)
		{
			PrintMenu(menuSel);
			prevMenuSel=menuSel;
		}

		int gamePad;
		SND_joy_in_2(0,&gamePad);
		if(0xF0!=(gamePad&0xF0))
		{
			break;
		}
		if(3==(prevPad&3) && 3!=(gamePad&3))
		{
			menuSel=1-menuSel;
		}
		prevPad=gamePad;

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
			if(0x4D==keyAddr || // Up
			   0x50==keyAddr) // Down
			{
				menuSel=1-menuSel;
			}
		}

		int button,mx,my;
		MOS_rdpos(&button,&mx,&my);
		if(0!=(button&1))
		{
			break;
		}
		if(MENUX0<=mx && mx<=MENUX1)
		{
			if(MENU0_Y0<=my && my<=MENU0_Y1)
			{
				menuSel=0;
			}
			if(MENU1_Y0<=my && my<=MENU1_Y1)
			{
				menuSel=1;
			}
		}
	}
	return menuSel;
}

void WaitForKeyMouseOrPadButton(void)
{
	unsigned int prevPad=0,prevButton=3;
	for(;;)
 	{
		int gamePad;
		SND_joy_in_2(0,&gamePad);
		if(0xF0!=(gamePad&0xF0) && 0xF0==(prevPad&0xF0))
		{
			break;
		}
		prevPad=gamePad;

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
		if(0!=(button&1) && 0==(prevButton&1))
		{
			break;
		}
		prevButton=button;
	}
}

void CancelledWrite(void)
{
	MOS_disp(0);
	EGB_writePage(EGB_work,1);
	EGB_clearScreen(EGB_work);

	EGB_writePage(EGB_work,0);
	EGB_clearScreen(EGB_work);

	Logo();
	MOS_disp(1);

	PrintString(100,240,"書き込みをキャンセルしました。");
	PrintString(100,256,"リターンキー、パッドボタン、またはマウスボタンで");
	PrintString(100,272,"Towns MENUに戻ります。");

	PrintString(100,304,"Write Cancelled.");
	PrintString(100,320,"Return Key, Pad Button, or Mouse Button to return");
	PrintString(100,336,"to Towns MENU.");

	WaitForKeyMouseOrPadButton();
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

	for(;;)
	{
		if(0==RunMenu())
		{
			// if(write succeeds) break
			// otherwise, show error message and back to menu
		}
		else
		{
			CancelledWrite();
			break;
		}
	}

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
