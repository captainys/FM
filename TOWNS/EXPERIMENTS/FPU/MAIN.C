#include <stdio.h>

#define INT_DATA_LEN 256
#define FLOAT_DATA_LEN 256
#define DOUBLE_DATA_LEN 256
#define TWORD_DATA_LEN 256

int int_data[INT_DATA_LEN];
float float_data[FLOAT_DATA_LEN];
double double_data[DOUBLE_DATA_LEN];
unsigned char tword_data[TWORD_DATA_LEN*10];

extern RUN387(int *int_data,float *float_data,double *double_data,unsigned char *eighty_bit_data);

int main(void)
{
	RUN387(int_data,float_data,double_data,tword_data);

	for(int i=0; i<10; ++i)
	{
		printf("%f %lf\n",float_data[i],double_data[i]);
	}

	return 0;
}
