#include <stdio.h>
#include <stdlib.h>

int main(int ac,char *av[])
{
	if(ac<3)
	{
		printf("BIN2ASM input.bin output.asm\n");
		return 1;
	}

	FILE *fp=fopen(av[1],"rb");
	fseek(fp,0,SEEK_END);

	size_t fSize=ftell(fp);
	fseek(fp,0,SEEK_SET);

	unsigned char *dat=malloc(fSize);
	fread(dat,1,fSize,fp);

	fclose(fp);

	printf("File Size=%d\n",fSize);

	fp=fopen(av[2],"w");
	for(int i=0; i<fSize; ++i)
	{
		if(0==(i&15))
		{
			fprintf(fp,"\t\t\t\tDB\t");
		}

		fprintf(fp,"0%02xh",dat[i]);

		if(15==(i&15) || i+1==fSize)
		{
			fprintf(fp,"\n");
		}
		else
		{
			fprintf(fp,",");
		}
	}
	fclose(fp);

	printf("%s\n",av[2]);

	return 0;
}
