#include <chrono>
#include <thread>
#include <stdio.h>

#include "pigpio.h"



const int LED_OUT_PIN=18;

bool InitTransmitter(void)
{
	if(0<=gpioInitialise())
   {
      gpioSetMode(LED_OUT_PIN,PI_OUTPUT);
      return true;
   }
   return false;
}

bool Transmit30Bit(const char bits[30])
{
   // const char bits[]="101010110110101010101001010101";
   {
      auto T0=std::chrono::high_resolution_clock::now();
      while(T0==std::chrono::high_resolution_clock::now());
   }

   const int W0=100,W1=125,W2=175;

   unsigned int pulse[30]=
   {
      W0,W1,W2,W0,W1,W2,W0,W1,W2,W0,W1,W2,W0,W1,W2,
      W0,W1,W2,W0,W1,W2,W0,W1,W2,W0,W1,W2,W0,W1,W2,
   };
   unsigned int PWMWaveCount[30];
   std::chrono::time_point <std::chrono::high_resolution_clock> timeStamp[31];

   for(int i=0; i<30; ++i)
   {
      PWMWaveCount[i]=pulse[i]*1000/13158;
   }

   auto *pulsePtr=pulse;
   auto t0=std::chrono::high_resolution_clock::now();
   auto t1=t0;
   timeStamp[0]=t0;
   for(int i=0; i<30; ++i)
   {
      unsigned onOffTime[]={13158-400,13158+400};

      auto pulseWidth=*(pulsePtr++);
      auto bit=bits[i];
      t0=t1;
      t1=t1+std::chrono::microseconds(pulseWidth);
      if('1'==bit)
      {
         gpioWrite(LED_OUT_PIN,1);
         unsigned int onOff=1;
         unsigned int nFlip=0;
         auto tf=t0+std::chrono::nanoseconds(onOffTime[onOff]);
         while(std::chrono::high_resolution_clock::now()<t1)
         {
            if(tf<=std::chrono::high_resolution_clock::now())
            {
               onOff=1-onOff;
               gpioWrite(LED_OUT_PIN,onOff);
               tf=tf+std::chrono::nanoseconds(onOffTime[onOff]);
               ++nFlip;
            }
         }
         // Number of flips must be pulseWidth/13158
         if(nFlip<PWMWaveCount[i]-2)
         {
            printf("Error: PWMWave %d should be %d\n",nFlip,PWMWaveCount[i]);
            gpioWrite(LED_OUT_PIN,0);
            return false;
         }
      }
      else
      {
         gpioWrite(LED_OUT_PIN,0);
         while(std::chrono::high_resolution_clock::now()<t1)
         {
         }
      }
      timeStamp[i+1]=std::chrono::high_resolution_clock::now();
   }
   gpioWrite(LED_OUT_PIN,0);

   // Was it successful?  It is f**king UNIX that has been stubbornly refusing to admit there was a thing called real time.
   for(int i=0; i<30; ++i)
   {
      auto dt=(int)std::chrono::duration_cast<std::chrono::microseconds>(timeStamp[i+1]-timeStamp[i]).count();
      int err=(pulse[i]-dt);
      printf("Needed %d  Observed %d  Err %d\n",(int)pulse[i],(int)dt,(int)err);
      if(err<-5 || 5<err)
      {
         printf("Too much error!\n");
         return false;
      }
   }

   return true;
}

void Transmit30BitAutoRetry(const char bit[30],int nRetry)
{
	for(int i=0; i<nRetry; ++i)
	{
		if(true==Transmit30Bit(bit))
		{
			break;
		}
	}
}

void WaitAfterTransmissionFailure(void)
{
   std::this_thread::sleep_for(std::chrono::milliseconds(20));
}
