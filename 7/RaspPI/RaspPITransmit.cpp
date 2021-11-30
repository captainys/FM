#include <vector>
#include <chrono>
#include <thread>
#include <stdio.h>

#include "pigpio.h"



const int LED_OUT_PIN=18;
const int LED_STATUS_PIN=23;

bool InitTransmitter(void)
{
   // gpioCfgClock needs to be *before* gpioInitialise.
   gpioCfgClock(1,PI_CLOCK_PCM,0);
   gpioCfgClock(1,PI_CLOCK_PWM,0);

	if(0<=gpioInitialise())
   {
      gpioSetMode(LED_OUT_PIN,PI_OUTPUT);
      gpioSetMode(LED_STATUS_PIN,PI_OUTPUT);
      gpioWrite(LED_STATUS_PIN,1);
      return true;
   }
   return false;
}



int MakeOnOffCycle(int onOffCycle[30],const char bits[30],const unsigned int pulseWidth[30])
{
   char prev='1';
   int nCycle=0;
   int curCycle=0;

   for(int i=0; i<30; ++i)
   {
      if(prev!=bits[i])
      {
         onOffCycle[nCycle++]=curCycle;
         curCycle=pulseWidth[i];
         prev=bits[i];
      }
      else
      {
         curCycle+=pulseWidth[i];
      }
   }

   onOffCycle[nCycle++]=curCycle;

   return nCycle;
}

std::vector <gpioPulse_t> MakeWaveForm(int nCycle,const int cycle[],int dataPin)
{
   std::vector <gpioPulse_t> pulse;
   unsigned int leftOver=0;
   unsigned int onOff=1;
   const unsigned int dutyMicrosec=13;

   for(int i=0; i<nCycle; ++i)
   {
      if(0!=onOff)
      {
         gpioPulse_t p;
         auto us=cycle[i]+leftOver; // leftOver is supposed to be zero.
         unsigned int pwm=1;
         while(dutyMicrosec<=us)
         {
            if(1==pwm)
            {
               p.gpioOn=(1<<dataPin);
               p.gpioOff=0;
               p.usDelay=dutyMicrosec;
            }
            else
            {
               p.gpioOn=0;
               p.gpioOff=(1<<dataPin);
               p.usDelay=dutyMicrosec;
            }
            pulse.push_back(p);
            pwm=1-pwm;
            us-=dutyMicrosec;
         }
         if(1==pwm)
         {
            p.gpioOn=(1<<dataPin);
            p.gpioOff=0;
            p.usDelay=us;
            pulse.push_back(p);
            leftOver=0;
         }
         else
         {
            leftOver=us;     
         }
      }
      else
      {
         gpioPulse_t p;
         p.gpioOn=0;
         p.gpioOff=(1<<dataPin);
         p.usDelay=cycle[i]+leftOver;
         pulse.push_back(p);
         leftOver=0;
      }
      onOff=1-onOff;
   }
   if(0<pulse.size() && 0==pulse.back().gpioOff)
   {
      gpioPulse_t p;
      p.gpioOn=0;
      p.gpioOff=(1<<dataPin);
      p.usDelay=10;
      pulse.push_back(p);
   }
   return pulse;
}

#ifndef SOFTWARE_PWM
bool Transmit30Bit(const char bits[30])
{
   const int W0=100,W1=125,W2=175;

   unsigned int pulse[30]=
   {
      W0,W1,W2,W0,W1,W2,W0,W1,W2,W0,W1,W2,W0,W1,W2,
      W0,W1,W2,W0,W1,W2,W0,W1,W2,W0,W1,W2,W0,W1,W2,
   };

   int onOffCycle[30];
   int nCycle=MakeOnOffCycle(onOffCycle,bits,pulse);

   auto waveForm=MakeWaveForm(nCycle,onOffCycle,LED_OUT_PIN);

   gpioWrite(LED_OUT_PIN,0);
   gpioWrite(LED_STATUS_PIN,0);

   gpioWaveClear();

   gpioWaveAddNew();
   gpioWaveAddGeneric(waveForm.size(),waveForm.data());

   auto waveId=gpioWaveCreate();
   if(0<=waveId)
   {
      gpioWaveTxSend(waveId,PI_WAVE_MODE_ONE_SHOT);
      while(gpioWaveTxBusy());
   }

   gpioWaveClear();


   gpioWrite(LED_OUT_PIN,0);
   gpioWrite(LED_STATUS_PIN,1);

   return true;
}
#else
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
      if(err<-5 || 5<err)
      {
         for(int j=0; j<30; ++j)
         {
            auto dt=(int)std::chrono::duration_cast<std::chrono::microseconds>(timeStamp[j+1]-timeStamp[j]).count();
            int err=(pulse[j]-dt);
            printf("Needed %d  Observed %d  Err %d\n",(int)pulse[j],(int)dt,(int)err);
         }
         printf("Too much error!\n");
         return false;
      }
   }

   return true;
}
#endif

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
