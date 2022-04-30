#include <stdio.h>
#include <stdlib.h>

int main(int ac,char *av[])
{
	if(ac<4)
	{
		printf("BIN2C input.bin filename-base variable-name\n");
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



	char hName[256];
	sprintf(hName,"%s.h",av[2]);
	fp=fopen(hName,"w");
	fprintf(fp,"#define %s_size %d\n",av[3],fSize);
	fprintf(fp,"extern unsigned char %s[%s_size];\n",av[3],av[3]);
	fclose(fp);

	printf("%s\n",hName);

	char cName[256];
	sprintf(cName,"%s.c",av[2]);
	fp=fopen(cName,"w");
	fprintf(fp,"unsigned char %s[]={\n",av[3]);
	for(int i=0; i<fSize; ++i)
	{
		if(0==(i&15))
		{
			fprintf(fp,"\t");
		}

		fprintf(fp,"0x%02x",dat[i]);
		if(i+1!=fSize)
		{
			fprintf(fp,",");
		}

		if(15==(i&15) || i+1==fSize)
		{
			fprintf(fp,"\n");
		}
	}
	fprintf(fp,"};\n");
	fclose(fp);

	printf("%s\n",cName);

	return 0;
}
