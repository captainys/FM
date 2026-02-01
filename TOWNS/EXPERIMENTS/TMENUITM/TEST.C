// Based on EXL121R.TXT
#include <stdio.h>
#include <item.h>



int main(int ac,char *av[])
{
	char *ItmPath;
	int err;
	int EtyNum;
	int CRC; 
	char NameStr[80]; 

	if(2<=ac)
	{
		ItmPath=av[1];
	}
	else
	{
		ItmPath="\\TMENU.ITM";
	}

	err=ITM_GetHeadData(ItmPath,&EtyNum,&CRC,NameStr); 
	if(0!=err)
	{
		// printf("Error %d\n",err);
		return err;
	}

	// printf("Item Ct:%d  CRC:%08xH  Name:%s\n",EtyNum,CRC,NameStr);

	return 0;
}
