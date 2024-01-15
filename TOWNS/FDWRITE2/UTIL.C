#include <stdio.h>
#include <ctype.h>
#include "UTIL.H"
#include "DEF.H"

unsigned long DWordToUnsignedInt(const unsigned char data[])
{
	return *(unsigned long *)data;
}

unsigned short WordToUnsignedShort(const unsigned char data[])
{
	return *(unsigned short *)data;
}

void ExtractExtension(char ext[5],const char fileName[])
{
	int i;
	int lastDot=0;
	for(i=0; 0!=fileName[i]; ++i)
	{
		if('.'==fileName[i])
		{
			lastDot=i;
		}
	}

	ext[0]=0;
	ext[1]=0;
	ext[2]=0;
	ext[3]=0;
	ext[4]=0;
	for(i=0; i<4 && 0!=fileName[lastDot+i]; ++i)
	{
		ext[i]=fileName[lstDot+i];
	}
}

size_t GetFileSize(const char fileName[])
{
	size_t s=0;
	FILE *fp=fopen(fileName,"rb");
	if(NULL!=fp)
	{
		fseek(fp,0,SEEK_END);
		s=ftell(fp);
		fclose(fp);
	}
	return s;
}

unsigned int IdentifyFileType(const char fileName[])
{
	int i;
	char ext[5];
	ExtractExtension(ext,fileName);

	for(i=0; 0!=ext[i]; ++i)
	{
		ext[i]=toupper(ext[i]);
	}

	if(0==strcmp(ext[i],".D77"))
	{
		return FILETYPE_D77;
	}
	else if(0==strcmp(ext[i],".RDD"))
	{
		char id[16];
		FILE *fp=fopen(fileName,"rb");
		if(NULL!=fp && 16==fread(id,1,16,fp) && 0==strcmp(id,"REALDISKDUMP"))
		{
			return FILETYPE_RDD;
		}
	}
	else
	{
		size_t s=GetFileSize(fileName);
		if(1232*1024==s || 1440*1024==s || 640*1024==s || 720*1024==s)
		{
			return FILETYPE_BIN;
		}
	}

	return FILETYPE_NONE;
}
