#include <stdio.h>
#include <vector>



int main(int ac,char *av[])
{
	if(3!=ac)
	{
		printf("Usage: REPAIRRDD.EXE input.RDD output.RDD\n");
		return 1;
	}

	FILE *fp=fopen(av[1],"rb");
	if(nullptr==fp)
	{
		printf("Error!  Cannot read RDD.\n");
		return 1;
	}

	fseek(fp,0,SEEK_END);
	auto size=ftell(fp);

	std::vector <unsigned char> data;
	data.resize(size);

	fseek(fp,0,SEEK_SET);
	fread(data.data(),1,size,fp);

	fclose(fp);


	if(data.size()<16 || 0!=strcmp((char *)data.data(),"REALDISKDUMP"))
	{
		printf("The input file does not have REALDISKDUMP signature.\n");
		return 1;
	}


	bool endOfFile=false;
	bool corrected=false;
	unsigned int ptr=16;
	int C=0,H=0;
	unsigned int trkIDMarkBegin=0,trkIDMarkEnd=0;;
	while(ptr<data.size())
	{
		switch(data[ptr])
		{
		default:
			printf("Undefined tag 0x%02x at offset 0x%08x\n",data[ptr],ptr);
			return 1;
		case 0:
			// Begin Disk
			ptr+=48;
			break;
		case 1:
			// Begin Track
			C=data[ptr+1];
			H=data[ptr+2];
			ptr+=16;
			trkIDMarkBegin=0;
			trkIDMarkEnd=0;
			break;
		case 2:
			// ID Mark
			if(0==trkIDMarkBegin)
			{
				trkIDMarkBegin=ptr;
			}
			trkIDMarkEnd=ptr+16;
			ptr+=16;
			break;
		case 3:
		case 4:
			// Data or Track Read
			{
				unsigned int len=data[ptr+0x0F];
				len<<=8;
				len|=data[ptr+0x0E];
				len=(len+15)&0xFFF0;
				ptr+=16+len;
			}
			break;
		case 5:
			if(trkIDMarkBegin<trkIDMarkEnd)
			{
				bool needCorrection=true;
				// It is unlikely that the first bytes of CRC are all zero.
				for(auto i=trkIDMarkBegin; i<trkIDMarkEnd; i+=16)
				{
					if(0!=data[i+5])
					{
						needCorrection=false;
						break;
					}
				}
				if(true==needCorrection)
				{
					for(auto i=trkIDMarkBegin; i<trkIDMarkEnd; i+=16)
					{
						data[i+5]=data[i+4];
						data[i+4]=data[i+3];
						data[i+3]=data[i+2];
						data[i+2]=data[i+1];
						data[i+1]=C;
					}
					corrected=true;
				}
			}
			trkIDMarkBegin=0;
			trkIDMarkEnd=0;
			ptr+=16;
			break;
		case 6:
			// End of File
			endOfFile=true;
			ptr=data.size();
			break;
		case 0x10:
			{
				unsigned int len=data[ptr+0x02];
				len<<=8;
				len|=data[ptr+0x01];
				len=(len+15)&0xFFF0;
				ptr+=16+len;
			}
			break;
		}
	}

	if(true!=endOfFile)
	{
		printf("Missing End of File tag.\n");
		return 1;
	}

	if(true!=corrected)
	{
		printf("The RDD did not seem to have an error from the FDDUMP bug.\n");
		return 1;
	}
	else
	{
		printf("The RDD seems to have an error, and has been corrected.\n");
		printf("However, C of CHRN in IDMarks are a guess.  If it is essential for\n");
		printf("copy protection, the game may not work.  Sorry!\n");

		fp=fopen(av[2],"wb");
		if(nullptr==fp)
		{
			printf("!!!!\n");
			printf("But could not open the output file.\n");
			printf("Corrected file was not written.\n");
			return 1;
		}
		fwrite(data.data(),1,data.size(),fp);
		fclose(fp);
		printf("Corrected RDD saved in %s\n",av[2]);
	}
	return 0;
}
