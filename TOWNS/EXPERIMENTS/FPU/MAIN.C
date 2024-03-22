#include <stdio.h>
#include <string.h>
#include <math.h>

#define INT_DATA_LEN 256
#define FLOAT_DATA_LEN 256
#define DOUBLE_DATA_LEN 256
#define TBYTE_DATA_LEN 256

int int_data[INT_DATA_LEN];
float float_data[FLOAT_DATA_LEN];
double double_data[DOUBLE_DATA_LEN];
unsigned char tbyte_data[TBYTE_DATA_LEN*10];

extern RUN387(int *int_data,float *float_data,double *double_data,unsigned char *eighty_bit_data);
extern TBYTE_TO_QWORD(double *qword_ptr,const unsigned char *tbyte_ptr);

// Sample taken from real FM TOWNS II MX (80486DX) on 2024/03/21
const double sample[146]={
0.000000,0.693147,0.301030,3.141593,3.321928,1.000000,0.414214,65536.000000,
2.000000,4.000000,10.000000,10.000000,110.000000,12345678.000000,-100.000000,100.000000,
1.000000,0.866025,0.500000,-0.000000,-0.500000,-0.866025,-1.000000,-0.866025,
-0.500000,0.000000,0.500000,0.866025,0.100000,0.500000,0.250000,0.500000,
0.500000,0.500000,0.500000,25.600000,32.000000,30.272727,777.000000,777.000000,
777.000000,777.000000,256.000000,-6553.600000,-6553.600000,-6553.600000,-6553.600000,-6553.600000,
-6553.600000,-6553.600000,0.000000,0.785398,1.570796,2.356194,3.141593,-2.356194,
-1.570796,-0.785398,0.141593,0.141593,-1.732051,-1.000000,0.000000,1.000000,
1.732051,2.000000,-2.000000,2.000000,-2.000000,1.000000,-2.000000,2.000000,
-3.000000,2.000000,-1.000000,3.000000,-2.000000,1.000000,-1.000000,2.000000,
-2.000000,4096.000000,256.000000,0.000000,0.500000,0.866025,1.000000,0.866025,
0.500000,-0.000000,-0.500000,-0.866025,-1.000000,-0.866025,-0.500000,1.000000,
0.000000,0.866025,0.500000,0.500000,0.866025,-0.000000,1.000000,-0.500000,
0.866025,-0.866025,0.500000,-1.000000,-0.000000,-0.866025,-0.500000,-0.500000,
-0.866025,0.000000,-1.000000,0.500000,-0.866025,0.866025,-0.500000,0.000000,
0.200000,0.400000,0.600000,0.800000,1.000000,1.200000,1.400000,1.600000,
1.800000,2.000000,9.750000,4.500000,100.000000,50.000000,100000.000000,-1233.900000,
-1233.900000,-9.750000,-4.500000,-100.000000,-50.000000,-100000.000000,1233.900000,1233.900000,
800000.000000,13750.352375,
};

int main(int ac,char *av[])
{
	int err=0;

	int i;
	const int nOutput=146;

	memset(int_data,0,sizeof(int_data));
	memset(float_data,0,sizeof(float_data));
	memset(double_data,0,sizeof(double_data));
	memset(tbyte_data,0,sizeof(tbyte_data));

	RUN387(int_data,float_data,double_data,tbyte_data);

	printf("\n");

	for(i=0; i<nOutput; ++i)
	{
		double conv;
		TBYTE_TO_QWORD(&conv,tbyte_data+i*10);
		printf("%f %lf %lf\n",float_data[i],double_data[i],conv);
	}

	for(i=0; i<14; ++i)
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

	if(2<=ac && 0==strcmp("-capture",av[1]))
	{
		printf("const double sample[%d]={\n",nOutput);
		for(int i=0; i<nOutput; ++i)
		{
			printf("%lf,",double_data[i]);
			if(7==i%8 || i+1==nOutput)
			{
				printf("\n");
			}
		}
		printf("}\n");
	}
	else
	{
		printf("Checking against samples from real hardware...\n");
		for(int i=0; i<nOutput; ++i)
		{
			double conv;
			double diff1=fabs(float_data[i]-double_data[i]);
			double diff2=fabs(double_data[i]-sample[i]);
			double diff3;

			TBYTE_TO_QWORD(&conv,tbyte_data+i*10);
			diff3=fabs(conv-sample[i]);

			if(0.001<=diff1)
			{
				printf("FLOAT and DOUBLE differ by too much. %d %f %lf\n",i,float_data[i],double_data[i]);
				err=1;
			}
			if(0.00001<=diff2)
			{
				printf("DOUBLE Result differ from real hardware too much. %d %lf %lf\n",i,sample[i],double_data[i]);
				err=1;
			}
			if(0.00001<=diff3)
			{
				printf("TBYTE Result differ from real hardware too much. %d %lf %lf\n",i,sample[i],double_data[i]);
				err=1;
			}
		}
		printf("Tested %d samples.\n",nOutput);
		printf("Error=%d\n",err);
	}
	return err;
}
