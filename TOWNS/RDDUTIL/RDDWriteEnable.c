#include <stdio.h>
#include <stdlib.h>



int main(int ac,char *av[])
{
	FILE *fp=NULL;
	unsigned char *buf=NULL;

	if(2!=ac)
	{
		printf("Usage: RDDWriteProtect RDDFile\n");
		return 1;
	}

	fp=fopen(av[1],"rb");
	if(NULL==fp)
	{
		printf("Cannot open %s for read\n",av[1]);
		return 1;
	}

	fseek(fp,0,SEEK_END);
	size_t sz=ftell(fp);
	fseek(fp,0,SEEK_SET);

	buf=(unsigned char *)malloc(sz);
	if(sz!=fread(buf,1,sz,fp))
	{
		printf("Read error.\n");
		return 1;
	}

	fclose(fp);



	if(0!=memcmp(buf,"REALDISKDUMP",12))
	{
		printf("Not a RDD disk image.\n");
		return 1;
	}



	if(0x00==buf[0x10])
	{
		if(0==(buf[0x13]&1))
		{
			printf("Already write enabled.\n");
			return 0;
		}
		else
		{
			buf[0x13]&=0xFE;
		}
	}



	fp=fopen(av[1],"wb");
	if(NULL==fp)
	{
		printf("Cannot open %s for write\n",av[1]);
		return 1;
	}
	if(sz!=fwrite(buf,1,sz,fp))
	{
		printf("Write error.\n");
		return 1;
	}
	fclose(fp);



	return 0;
}
