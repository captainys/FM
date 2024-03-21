#include <stdio.h>
#include <string.h>

#define INT_DATA_LEN 256
#define FLOAT_DATA_LEN 256
#define DOUBLE_DATA_LEN 256
#define TBYTE_DATA_LEN 256

int int_data[INT_DATA_LEN];
float float_data[FLOAT_DATA_LEN];
double double_data[DOUBLE_DATA_LEN];
unsigned char tbyte_data[TBYTE_DATA_LEN*10];

extern RUN387(int *int_data,float *float_data,double *double_data,unsigned char *eighty_bit_data);

int main(void)
{
	int i;

	memset(int_data,0,sizeof(int_data));
	memset(float_data,0,sizeof(float_data));
	memset(double_data,0,sizeof(double_data));
	memset(tbyte_data,0,sizeof(tbyte_data));

	RUN387(int_data,float_data,double_data,tbyte_data);

	printf("\n");

	for(i=0; i<33; ++i)
	{
		printf("%f %lf\n",float_data[i],double_data[i]);
	}

	for(i=0; i<8; ++i)
	{
		printf("%08x",int_data[i]);
		if(7==i%8)
		{
			printf("\n");
		}
		else
		{
			printf(" ");
		}
	}

	printf("\n");

	return 0;
}
