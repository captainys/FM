#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include <conio.h>

#include <egb.h>
#include <mos.h>
#include <snd.h>
#include <fmcfrb.h>

#include "icmimage.h"

#define TsugaruDebugBreak _outp(0x2386,2);

#define CMOS_BACKUP_ADDR 0xDFFC
unsigned char *C0000000H=NULL;

extern void SETUP_PAGE_TABLE(unsigned char *pageBuf);
extern unsigned char *MALLOC_PHYS_ADDR(unsigned int physAddr);
extern void TRANSFER_TO_ICM(unsigned int size,const unsigned char from[],unsigned char to[]); // size needs to be 4*N
extern void CLEAR_ICM(unsigned int size,unsigned char cmosptr[]);

static char EGB_work[EgbWorkSize],mos[MosWorkSize],snd[16384];

unsigned char Aomori[]=
{
0x63,0x22,0x67,0x20,0x00,0x00,0x00,0x00,0x94,0xb6,0x94,0xa0,0x00,0x00,0x00,0x00,
0x94,0xaa,0x94,0xa0,0x00,0x00,0x00,0x00,0xf4,0xa2,0x97,0x20,0x08,0x00,0x00,0x00,
0x94,0xa2,0x94,0xa0,0x0c,0x00,0x00,0x00,0x93,0x22,0x64,0xa0,0x0e,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x0f,0xe0,0x00,0x00,0x13,0x38,0xc8,0x80,0x1f,0xf0,0x00,0x00,
0x14,0xa5,0x2c,0x80,0x3f,0xf8,0x01,0x00,0x14,0xa5,0x2a,0x80,0x3f,0xfc,0x03,0x00,
0x17,0xb9,0xea,0x80,0x7f,0xff,0x0f,0x00,0x94,0xa1,0x29,0x80,0x7f,0xff,0xfe,0x00,
0x64,0xa1,0x28,0x80,0x7f,0xff,0xfe,0x00,0x00,0x00,0x00,0x00,0x7f,0xff,0xfe,0x00,
0x00,0x00,0x00,0x00,0xff,0xff,0xfe,0x00,0x00,0x00,0x40,0x00,0xff,0xf9,0xfc,0x00,
0x00,0x00,0x70,0x80,0xff,0xf8,0xfc,0x00,0x00,0x00,0x71,0xe1,0xff,0xf0,0xfc,0x00,
0x00,0x00,0x7f,0xf1,0xff,0xc0,0x7c,0x00,0x00,0x00,0xff,0xf1,0xf0,0x00,0x7c,0x00,
0x00,0x03,0xff,0xf1,0xc0,0x00,0x7c,0x00,0x00,0x03,0xff,0xf0,0x00,0x00,0xfc,0x00,
0x00,0x00,0xff,0xf0,0x00,0x00,0xfc,0x00,0x00,0x00,0xff,0xf0,0x00,0x00,0xfc,0x00,
0x00,0x00,0xff,0xf0,0x00,0x01,0xf8,0x00,0x00,0x00,0xff,0xf0,0x18,0x01,0xf8,0x00,
0x00,0x00,0xff,0xf0,0x1e,0x01,0xf8,0x00,0x00,0x00,0xff,0xf0,0x3e,0x01,0xf8,0x00,
0x00,0x00,0xff,0xf8,0x3f,0x03,0xf8,0x00,0x00,0x01,0xff,0xf8,0x1f,0xc3,0xf8,0x00,
0x00,0x01,0xff,0xf8,0x3f,0xe7,0xfc,0x00,0x00,0x01,0xff,0xfc,0x3f,0xff,0xfc,0x00,
0x00,0x01,0xff,0xff,0xff,0xff,0xfc,0x00,0x00,0x03,0xff,0xff,0xff,0xff,0xfc,0x00,
0x00,0x07,0xff,0xff,0xff,0xff,0xfc,0x00,0x01,0x1f,0xff,0xff,0xff,0xff,0xfc,0x00,
0x07,0xff,0xff,0xff,0xff,0xff,0xfc,0x00,0x07,0xff,0xff,0xff,0xff,0xff,0xfe,0x00,
0x0f,0xff,0xff,0xff,0xff,0xff,0xfe,0x00,0x1f,0xff,0xff,0xff,0xff,0xff,0xfe,0x00,
0x3f,0xff,0xff,0xff,0xff,0xff,0xfe,0x00,0x7f,0xff,0xff,0xff,0xff,0xff,0xff,0x00,
0xff,0xff,0xff,0xff,0xff,0xff,0xff,0x00,0x5f,0xff,0xff,0xff,0xff,0xff,0xff,0x80,
0x1f,0xff,0xff,0xff,0xff,0xff,0xff,0x80,0x1f,0xff,0xff,0xff,0xff,0xff,0xff,0xf8,
0x1f,0xff,0xff,0xff,0xff,0xff,0xff,0xfc,0x1f,0xff,0xff,0xff,0xff,0xff,0xff,0xfe,
0x1e,0x7f,0xcf,0xff,0xbf,0xff,0xff,0xfe,0x1e,0x00,0x81,0xff,0x3f,0xff,0xff,0xfc,
0x00,0x00,0x00,0xf0,0x01,0xff,0xff,0xf0,0x00,0x00,0x00,0x00,0x01,0xff,0xff,0xf0,
0x00,0x00,0x00,0x00,0x01,0xff,0xdd,0xe0,0x00,0x00,0x00,0x00,0x03,0xff,0x90,0x00,
0x00,0x00,0x00,0x00,0x03,0xfe,0x00,0x00,0x00,0x00,0x00,0x00,0x03,0xfc,0x00,0x00,
0x00,0x00,0x00,0x00,0x03,0xf0,0x00,0x00,0x00,0x00,0x00,0x00,0x03,0xe0,0x00,0x00,
0x00,0x00,0x00,0x00,0x03,0xc0,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
};

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

char VersionStr[256]="VERSION ****";

void Logo(void)
{
	MOS_disp(0);


	EGB_color(EGB_work,0,12);
	struct
	{
		unsigned char *ptr;
		unsigned short DS;
		unsigned short x0,y0,x1,y1;
	} bitmapParam;
	bitmapParam.ptr=Aomori;
	bitmapParam.DS=0x14;  // Was there a macro?
	bitmapParam.x0=576;
	bitmapParam.y0=0;
	bitmapParam.x1=639;
	bitmapParam.y1=63;
	EGB_putBlockColor(EGB_work,1,&bitmapParam);

	PrintString(0,16,"IC Memory Card 救済IPL書き込みユーティリティ");
	PrintString(0,32,"by 山川機長 (http://www.ysflight.com)");
	PrintString(0,48,"IC Memory Card Rescue IPL Writer");
	PrintString(0,64,"by CaptainYS (http://www.ysflight.com)");
	PrintString(0,80,VersionStr);

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
#define MENU1_Y0 (288-16-16)
#define MENU1_Y1 (288+16)
#define MENU2_Y0 (352-16-16)
#define MENU2_Y1 (352+16)

void PrintMenu(int menuSel)
{
	MOS_disp(0);

	DrawRect(MENUX0,MENU0_Y0,MENUX1,MENU0_Y1,(0==menuSel ? 15 : 0));
	PrintString(100,MENU0_Y0+32,"書き込み Write");

	DrawRect(MENUX0,MENU1_Y0,MENUX1,MENU1_Y1,(1==menuSel ? 15 : 0));
	PrintString(100,MENU1_Y0+32,"クリアして書き込み  Clear and then Write");

	DrawRect(MENUX0,MENU2_Y0,MENUX1,MENU2_Y1,(2==menuSel ? 15 : 0));
	PrintString(100,MENU2_Y0+32,"やっぱり書かない Cancel Write");

	MOS_disp(1);
}

int RunMenu(void)
{
	EGB_writePage(EGB_work,1);
	EGB_clearScreen(EGB_work);

	EGB_writePage(EGB_work,0);
	EGB_clearScreen(EGB_work);
	Logo();

	unsigned int prevPad=0,prevButton=3;
	int prevMX=0,prevMY=0;
	int prevMenuSel=-1,menuSel=0;
	for(;;)
	{
		if(prevMenuSel!=menuSel)
		{
			EGB_writePage(EGB_work,1);
			EGB_clearScreen(EGB_work);

			EGB_writePage(EGB_work,0);
			EGB_clearScreen(EGB_work);
			Logo();

			PrintMenu(menuSel);
			prevMenuSel=menuSel;
		}

		int gamePad;
		SND_joy_in_2(0,&gamePad);
		if(0xF0==(prevPad&0xF0) && 0xF0!=(gamePad&0xF0))
		{
			break;
		}
		if(3==(prevPad&3) && 3!=(gamePad&3))
		{
			if(0==(gamePad&1)) // Up
			{
				menuSel=(menuSel+2)%3;
			}
			else if(0==(gamePad&2)) // Down
			{
				menuSel=(menuSel+1)%3;
			}
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
			if(0x4D==keyAddr) // Up
			{
				menuSel=(menuSel+2)%3;
			}
			if(0x50==keyAddr) // Down
			{
				menuSel=(menuSel+1)%3;
			}
		}

		int button,mx,my;
		MOS_rdpos(&button,&mx,&my);
		if(0!=(button&1) && 0==(prevButton&1))
		{
			break;
		}
		int deltaX=mx-prevMX;
		int deltaY=my-prevMY;
		prevButton=button;
		if(deltaX<-8 || 8<deltaX || deltaY<-8 || 8<deltaY)
		{
			prevMX=mx;
			prevMY=my;
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
				if(MENU2_Y0<=my && my<=MENU2_Y1)
				{
					menuSel=2;
				}
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

void PrintResult(int BIOSErr)
{
	MOS_disp(0);
	EGB_writePage(EGB_work,1);
	EGB_clearScreen(EGB_work);

	EGB_writePage(EGB_work,0);
	EGB_clearScreen(EGB_work);

	if(0!=BIOSErr)
	{
		char str[256];
		sprintf(str,"BIOS Error Detail Code=0x%04x",BIOSErr);
		PrintString(100,192,str);
	}

	if(0!=(BIOSErr&1))
	{
		PrintString(100,240,"ICメモリカードがありません。");
		PrintString(100,256,"リターンキー、パッドボタン、またはマウスボタンで");
		PrintString(100,272,"メニューに戻ります。");

		PrintString(100,304,"IC Memory Card Not Ready.");
		PrintString(100,320,"Return Key, Pad Button, or Mouse Button to return");
		PrintString(100,336,"to MENU.");
	}
	else if(0!=(BIOSErr&2))
	{
		PrintString(100,240,"ICメモリカードが書き込み禁止になっています。");
		PrintString(100,256,"リターンキー、パッドボタン、またはマウスボタンで");
		PrintString(100,272,"メニューに戻ります。");

		PrintString(100,304,"IC Memory Card Write Protected.");
		PrintString(100,320,"Return Key, Pad Button, or Mouse Button to return");
		PrintString(100,336,"to MENU.");
	}
	else if(0==(BIOSErr&1))
	{
		PrintString(100,240,"書き込みに成功しました。");
		PrintString(100,256,"リターンキー、パッドボタン、またはマウスボタンで");
		PrintString(100,272,"プログラムを終了します。");

		PrintString(100,304,"Written to IC Memory Card successfully..");
		PrintString(100,320,"Return Key, Pad Button, or Mouse Button to exit.");
	}
	else
	{
		PrintString(100,240,"エラーが発生しました。");
		PrintString(100,256,"リターンキー、パッドボタン、またはマウスボタンで");
		PrintString(100,272,"メニューに戻ります。");

		PrintString(100,304,"IC Memory Card Write Error.");
		PrintString(100,320,"Return Key, Pad Button, or Mouse Button to return");
		PrintString(100,336,"to MENU.");
	}

	MOS_disp(1);

	WaitForKeyMouseOrPadButton();
}

void PrintVerificationError(void)
{
	MOS_disp(0);
	EGB_writePage(EGB_work,1);
	EGB_clearScreen(EGB_work);

	EGB_writePage(EGB_work,0);
	EGB_clearScreen(EGB_work);

	PrintString(100,240,"書き込み内容が一致しませんでした。");
	PrintString(100,256,"リターンキー、パッドボタン、またはマウスボタンで");
	PrintString(100,272,"メニューに戻ります。");

	PrintString(100,304,"Verification Failure.");
	PrintString(100,320,"Return Key, Pad Button, or Mouse Button to return");
	PrintString(100,336,"to MENU.");

	MOS_disp(1);

	WaitForKeyMouseOrPadButton();
}

// TICM.SYS uses device ID 0x50, in which case the sector size is 512 bytes.
#define ICM_SECTOR_SIZE 512
#define ICM_DEVICE_TYPE 0x50
// However, it is not available in Towns OS V2.1 L51.  WTF?

// If accessed from device ID 0x4A, it seems to work as 1024 bytes per sector?  -> Confirmed.  0x4A uses 1024 bytes per sector.
#define ICM_SECTOR_SIZE_4A 1024
#define ICM_DEVICE_TYPE_4A 0x4A

// OK.  From Towns OS V2.1 L51, neither 0x50 nor 0x4A works.  WTF.

#define ICM_SECTOR_SIZE_LARGER ((ICM_SECTOR_SIZE)<(ICM_SECTOR_SIZE_4A) ? (ICM_SECTOR_SIZE_4A) : (ICM_SECTOR_SIZE))

unsigned int ICM_PhysAddr(void)
{
	unsigned char AL=_inp(0x30);
	if(3==(AL&7))
	{
		return 0xD00000; // 386SX
	}
	else
	{
		return 0xC0000000;
	}
}

void ClearICMCMOSBackUp(void)
{
	CLEAR_ICM(65536-CMOS_BACKUP_ADDR,C0000000H+CMOS_BACKUP_ADDR);
}

int WriteICM(void)
{
	TRANSFER_TO_ICM(ICMIMAGE_size,ICMIMAGE,C0000000H);
/*
	// Disk BIOS fails to recognize the Memory Card if everything is 00h.
	// (Probably checking reg, but FRAM card does not have REG memory for saving cost.)
	int sector=0;
	unsigned char writeBuf[ICM_SECTOR_SIZE];
	for(unsigned int base=0; base<ICMIMAGE_size; base+=ICM_SECTOR_SIZE)
	{
		unsigned int i;
		for(i=0; i<ICM_SECTOR_SIZE && base+i<ICMIMAGE_size; ++i)
		{
			writeBuf[i]=ICMIMAGE[base+i];
		}
		for(i=i; i<ICM_SECTOR_SIZE; ++i)
		{
			writeBuf[i]=0x77;
		}

		int blocknum; // Probably BX returned by Disk BIOS.
		int err=DKB_write2(ICM_DEVICE_TYPE,sector,1,(char *)writeBuf,&blocknum);
		if(0!=err)
		{
			return err;
		}

		++sector;
	}
*/
	return 0;
}

int VerifyICM(unsigned int devId,unsigned int sectorSize)
{
	int sector=0;
	unsigned char readBuf[ICM_SECTOR_SIZE_LARGER];
	for(unsigned int base=0; base<ICMIMAGE_size; base+=sectorSize)
	{
		int blocknum; // Probably BX returned by Disk BIOS.
		int err=DKB_read2(devId,sector,1,(char *)readBuf,&blocknum);
		if(2==err)
		{
			/* Ideally I want to make sure the Disk BIOS can read the contents written to
			   the IC Memory Card.  However, Towns OS V2.1 L51 doesn't seem to accept the
			   BIOS disk read command with undocumented device IDs for IC Memory Card,
			   0x4A and 0x50.

			   All I can do is to directly compare memory bytes.
			*/
			goto DIRECT_COMPARISON;
		}

		if(0!=err)
		{
			return err;
		}

		unsigned int i;
		for(i=0; i<sectorSize && base+i<ICMIMAGE_size; ++i)
		{
			if(readBuf[i]!=ICMIMAGE[base+i])
			{
				return -1;
			}
		}

		++sector;
	}
	return 0;

DIRECT_COMPARISON:
	if(0==memcmp(C0000000H,ICMIMAGE,ICMIMAGE_size))
	{
		return 0;
	}
	return -1;
}

int main(int ac,char *av[])
{
	// _outp(0x2386,2); //Tsugaru debugger break.

	C0000000H=MALLOC_PHYS_ADDR(ICM_PhysAddr());

	// This method worked on Tsugaru, but didn't work on actual MX.
	// unsigned char *pageBuf=malloc(32768+4095); // Need space that puts 8 pages.  32768+4095 should be good enough.
	// SETUP_PAGE_TABLE(pageBuf);

	for(int base=0; base+17<ICMIMAGE_size; ++base)
	{
		char cap[32];
		for(int i=0; i<7; ++i)
		{
			cap[i]=ICMIMAGE[base+i];
			if('a'<=cap[i] && cap[i]<='z')
			{
				cap[i]=cap[i]+'A'-'a';
			}
		}
		if(0==strncmp(cap,"VERSION",7) && '0'<=ICMIMAGE[base+i+8] && ICMIMAGE[base+i+8]<='9')
		{
			strncpy(VersionStr,(char *)ICMIMAGE+base,31);
			cap[31]=0;
			break;
		}

	NEXTBASE:
		;
	}

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
	KYB_clic(1); // No beep.  (0->Yes beep)

	for(;;)
	{
		auto menuSel=RunMenu();
		if(0==menuSel || 1==menuSel)
		{
			if(1==menuSel)
			{
				ClearICMCMOSBackUp();
			}
			int err=WriteICM();
			if(0==err)
			{
				if(0==VerifyICM(ICM_DEVICE_TYPE,ICM_SECTOR_SIZE) &&
				   0==VerifyICM(ICM_DEVICE_TYPE_4A,ICM_SECTOR_SIZE_4A))
				{
					PrintResult(err);
					break;
				}
				PrintVerificationError();
			}
			else
			{
				PrintResult(err);
			}
		}
		else if(2==menuSel)
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
