#include <stdio.h>
#include <stdlib.h>
#include <wav.h>
#include <snd.h>
#include <dos.h>
#include <conio.h>


#define TSUGARU_DEBUGBREAK				outp(0x2386,2);

char snd_work[SndWorkSize];


struct binaryData
{
	size_t len;
	char *data;
};

struct binaryData ReadFile(const char fn[])
{
	FILE *fp=fopen(fn,"rb");
	struct binaryData data;
	data.len=0;
	data.data=NULL;

	if(NULL==fp)
	{
		return data;
	}

	fseek(fp,0,SEEK_END);
	data.len=ftell(fp);
	fseek(fp,0,SEEK_SET);

	data.data=(char *)malloc(data.len);

	if(NULL==data.data)
	{
		data.len=0;
		fclose(fp);
		return data;
	}

	fread(data.data,1,data.len,fp);
	fclose(fp);

	return data;
}

char WAVRingBuf[4096*3];  // As example says.

int main(void)
{
	int cap;

	struct binaryData data=ReadFile("NOTICE.WAV");
	if(NULL==data.data)
	{
		printf("Failed to read WAV data.\n");
		return 0;
	}


	SND_init(snd_work);

	WAV_init();

	struct WAVBufferControl
	{
		int sum;
		int apply_loc;
		int system_loc;
		struct
		{
			char *ptr;
			char reserve[8];
		} table[2];
	} bufCtrl;
	bufCtrl.sum=2;
	bufCtrl.apply_loc=0;
	WAV_makeTable(WAVRingBuf,(char *)&bufCtrl);


	WAV_getCapability(&cap,44100);

	if(0!=(cap&WAV_CAP_16PCM_EXIST))
	{
		printf("High-Res PCM exists.\n");
	}
	else
	{
		printf("High-Res PCM does not exist.\n");
	}

	TSUGARU_DEBUGBREAK

	int freq,bitno,nCh,pcmsz,pcmstart;
	WAV_getWaveInfo(data.data,data.len,&freq,&bitno,&nCh,&pcmsz,&pcmstart);
	printf("%d Hz\n",freq);
	printf("%d bits\n",bitno);
	printf("%d channels\n",nCh);
	printf("%d bytes long\n",pcmsz);
	printf("%d bytes of header\n",pcmstart);


	WAV_playPrepare(freq,bitno,nCh,data.data+pcmstart,(void (*)())NULL);
	WAV_play(pcmsz);
	for(;;)
	{
		int status;
		WAV_getStatus(&status);
		if(0!=(status&WAV_ST_PLAY_PLAYING))
		{
			break;
		}
	}
	for(;;)
	{
		int status;
		WAV_getStatus(&status);
		if(0==(status&WAV_ST_PLAY_PROCESS))
		{
			break;
		}
	}

	WAV_end();
	SND_end();

	return 0;
}
