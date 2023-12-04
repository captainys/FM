#include <stdio.h>
#include <wav.h>
#include <snd.h>
#include <dos.h>
#include <conio.h>


#define TSUGARU_DEBUGBREAK				outp(0x2386,2);

char snd_work[SndWorkSize];

int main(void)
{
	int cap;


	SND_init(snd_work);

	WAV_init();

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


	WAV_end();
	SND_end();

	return 0;
}
