/*
38KHz 50% duty cycle Infra-Red Signal Emitter
Copyright 2019 CaptainYS (http://www.ysflight.com)  All rights reserved.

Redistribution and use in source and binary forms, with or without modification, 
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, 
   this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, 
   this list of conditions and the following disclaimer in the documentation 
   and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, 
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS 
BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE 
GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


// 2023/11/25
// This program starts into the terminal mode, in which the host computer can connect to the serial port with a terminal program such as TeraTerm at 115200bps.
// Whatever you type into the terminal will be sent to FM77AV.
//
// When you start FM77AV Keyboard Emulator program, the program will send CMD_RESET five times, which makes this program exit the terminal mode.
// then my FM77AV Keyboard Emulator will have full control.
//
// To use my IR Emitter Shield as a general-purpose IR emitter, do send CMD_RESET (0x00) five times to make sure this program exits the terminal mode.
bool terminalMode=true;
int terminalExitCount=0;  // 3 reset commands to exit terminal mode.
void TerminalMode(unsigned char recv);


#define SERIAL_BPS 115200
// Confirmed to work up to 440000bps.
// Stopped working at 460000bps.
// Not tested between 440000 and 460000bps.


#define RECVBUF_SIZE 384
int nRecvBuf=0;
unsigned char recvBuf[RECVBUF_SIZE];
unsigned int cycle[RECVBUF_SIZE/2];
bool transmitMode=false;
unsigned long lastDataReceivedTime=0;
unsigned char processingCmd=0;


unsigned char pulseWidthTable[30];
const unsigned char pulseWidthSource[3]={100,125,175};


#define CMD_RESET 0
#define CMD_IRMAN_COMPATIBLE_MODE 'R'
#define CMD_VERSION 'V'
#define CMD_SELFTEST 't'
#define CMD_SAMPLERMODE 'S'
#define CMD_ENABLE_BYTECOUNT 0x24
#define CMD_ENABLE_TRANSMISSION_NOTIFY 0x25
#define CMD_ENABLE_HANDSHAKE 0x26
#define CMD_TRANSMIT_MICROSEC 0x80
#define CMD_TRANSMIT_30BIT_100US 0x81

#define CMD_TERMINAL_MODE 'T'

#define NOTIFY_READY 'C'
#define NOTIFY_FAIL 'F'

// 50% duty cycle: On and off within 1/38000 sec.  Must togle every 1/76000 sec.
#define TIMER_THRESHOLD_38K_WITH_1xPRESCALE ((F_CPU/38000)/2)
// Experiment with FM77AV40 IR LED receiver:  19000Hz No response 34000-36000 drops key.  38000 perfect.  40000 drops keys.

#define PWM_TIMER_THRESHOLD TIMER_THRESHOLD_38K_WITH_1xPRESCALE

// Succeeded Xfinity remote

#define PIN_OC1A 9
#define PIN_OC1B 10
#define PIN_OC2A 11
#define PIN_OC2B 3

#define PIN_POWER 13
#define PIN_STATUS 8

// For FM77AV Wired Connection
#define PIN_KSDATA   12
#define PIN_KDETECT  4


// PIN9=PB1 (PortB bit 1)
#define SetPin9High  PORTB|=_BV(1);
#define SetPin9Low   PORTB&=~_BV(1);
// PIN10=PB2 (PortB bit 2)
#define SetPin10High PORTB|=_BV(2);
#define SetPin10Low  PORTB&=~_BV(2);
// PIN11=PB3 (PortB bit 3)
#define SetPin11High PORTB|=_BV(3);
#define SetPin11Low  PORTB&=~_BV(3);
// PIN3=PD3 (PortD bit 3)
#define SetPin3High  PORTD|=_BV(3);
#define SetPin3Low   PORTD&=~_BV(3);

// PIN12=PB4 PortB bit 4
#define SetPin12High PORTB|=_BV(4);
#define SetPin12Low PORTB&=~_BV(4);
// PIN13=PB5 PortB bit 5
#define SetPin13High PORTB|=_BV(5);
#define SetPin13Low PORTB&=~_BV(5);
// PIN8=PB0 Port B bit 0
#define SetPin8High PORTB|=_BV(0);
#define SetPin8Low PORTB&=~_BV(0);

#define SetPin9and10Low PORTB&=~(_BV(1)|_BV(2));


#define SET_CTC_MODE {TCCR1B=bit(CS10)|bit(WGM12);}
// TCCR1B  WGM10=0,WGM11=0,WGM12=1 means CTC mode
//         CS10=1,CS11=0,CS12=0 means 1x pre-scale (no scaling).
//         CS10=0,CS11=0,CS12=0 means timer stop.

#define SET_OC1A_OC1B_TOGGLE {TCCR1A=bit(COM1A0)|bit(COM1B0);}
// ATmega 328 datasheet pp.134
// TCCR1A  COM1A0=1, COM1B0=1 means toggle OC1A and OC1B on compare match

#define SET_OC1A_OC1B_LOW {TCCR1A=(bit(COM1A1)|bit(COM1B1));TCCR1C=(bit(FOC1A)|bit(FOC1B));TCCR1C=0;}
// TCCR1A=(bit(COM1A1)|bit(COM1B1));  // Clear OC1A low on compare match
// TCCR1C=(bit(FOC1A)|bit(FOC1B));    // Force match
// TCCR1C=0;                          // Do I need to clear?


// Failed Attmept:
// For each HIGH pulse, force OC1A to be HIGH, and then start timer.  This approach didn't work.
// Probable reason is that it makes the first duty cycle slightly shorter.
// This method FM77AV40 misses one in every 80 to 100 key strokes.



void setup() {
  for(int i=0; i<30; ++i)
  {
    pulseWidthTable[i]=pulseWidthSource[i%3];
  }
  
  Serial.begin(SERIAL_BPS);

  pinMode(PIN_POWER,OUTPUT);
  pinMode(PIN_STATUS,OUTPUT);

  pinMode(PIN_OC1A,OUTPUT);
  pinMode(PIN_OC1B,OUTPUT);
  pinMode(PIN_OC2A,OUTPUT);
  pinMode(PIN_OC2B,OUTPUT);

  pinMode(PIN_KSDATA,OUTPUT);
  pinMode(PIN_KDETECT,OUTPUT);
  digitalWrite(PIN_KDETECT,0);

  // Reset timers 1 and 2
  TCCR1A=0;
  TCCR1B=0;
  TCCR2A=0;
  TCCR2B=0;
  TCNT1=0;
  TCNT2=0;

  // Timer 1 (8-bit) for 38K PWM IR LED output
  // ATmega 328 datasheet pp.134
  OCR1A=PWM_TIMER_THRESHOLD;
  OCR1B=0;

  SET_OC1A_OC1B_LOW;

  // Timer 2 for measuring 1us tick.
  TCCR2A=0;
  TCCR2B=bit(CS21);
  // CS20=0,CS21=1,CS22=0 means 8x pre-scaling.  0.5us per tick.  ATmega328 datasheet pp.162
  OCR2A=0;
  OCR2B=0;

  SetPin12High;
  SetPin13Low;
  SetPin8Low;
  SetPin9and10Low;
}

void SendCycleHWPWM(unsigned int cycle[])
{
  noInterrupts();

  TCNT1=0;
  SET_CTC_MODE;
  SET_OC1A_OC1B_LOW;
  // Now pins 9 and 10 are under control of Timer 1, OC1A, OC1B both low.
  // Pin9=OC1A
  // Pin10=OC1B

  for(int i=0; cycle[i]!=0xffff; i+=2)
  {
    TCNT2=0;

    TCNT1=PWM_TIMER_THRESHOLD-8;
    // Timer 1 pre-scalar is 1x.
    // Need to start toggling within 8 cycles.  0.5us error.
    SET_OC1A_OC1B_TOGGLE;
    SetPin12Low;

    auto w=cycle[i]<<1;
    while(TCNT2<w)
    {
      if(240<=TCNT2)
      {
        TCNT2=0;
        w-=240;
      }
    }

    TCNT2=0;
    SET_OC1A_OC1B_LOW;
    SetPin12High;
    w=cycle[i+1]<<1;
    while(TCNT2<w)
    {
      if(240<=TCNT2)
      {
        TCNT2=0;
        w-=240;
      }
    }
  }

  SET_OC1A_OC1B_LOW;
  SetPin9and10Low;
  SetPin12High;

  interrupts();
}

void MakeCycle(unsigned int cycle[],int nSample,unsigned char sample[])
{
  unsigned char k=0;
  switch(processingCmd)
  {
  case CMD_TRANSMIT_MICROSEC:
    {
      for(int i=0; i+1<nSample && (sample[i]!=0xff || sample[i+1]!=0xff); i+=2)
      {
        cycle[k]=(sample[i]<<8);
        cycle[k]+=sample[i+1];
        ++k;
      }
    }
    break;
  case CMD_TRANSMIT_30BIT_100US:
    {
      unsigned char samplePtr=0,sampleBit=1;
      cycle[k]=0;
      for(unsigned char i=0; i<30; ++i)
      {
        bool currentBit=((~k)&1);
        bool nextBit=(sample[samplePtr]&sampleBit);
        if(currentBit!=nextBit)
        {
          ++k;
          cycle[k]=0;
        }
        cycle[k]+=pulseWidthTable[i];

        if(128==sampleBit)
        {
          ++samplePtr;
          sampleBit=1;
        }
        else
        {
          sampleBit<<=1;
        }
      }
      ++k;
    }
    break;
  }
  cycle[k]=0;
  k+=(k&1); // Force it to be even.
  cycle[k  ]=0xffff;
  cycle[k+1]=0xffff;
}

void Transmit()
{
  SetPin8High;
  MakeCycle(cycle,nRecvBuf,recvBuf);
  SendCycleHWPWM(cycle);

  while(0==Serial.availableForWrite());
  Serial.write(NOTIFY_READY);

  transmitMode=false;

  SetPin8Low;
}

void loop() {
  bool received=false;
  while(0<Serial.available())
  {
    auto recvByte=Serial.read();
    if(true==terminalMode)
    {
      if(CMD_RESET==recvByte)
      {
        ++terminalExitCount;
        if(3<=terminalExitCount)
        {
          terminalMode=false;
        }
      }
      else
      {
        terminalExitCount=0;
        TerminalMode(recvByte);
      }
    }
    else if(true!=transmitMode)
    {
      processingCmd=recvByte;
      if(CMD_TRANSMIT_MICROSEC==recvByte ||
         CMD_TRANSMIT_30BIT_100US==recvByte)
      {
        transmitMode=true;
        nRecvBuf=0;
      }
      else if(CMD_IRMAN_COMPATIBLE_MODE==recvByte)
      {
        Serial.println("OK");
      }
      else if(CMD_VERSION==recvByte)
      {
        Serial.println("A277");
      }
      else if(CMD_SAMPLERMODE==recvByte)
      {
        Serial.println("S77");
      }
      else if(CMD_TERMINAL_MODE==recvByte)
      {
        Serial.println("Enter Terminal Mode.\n");
        terminalMode=true;
      }
    }
    else
    {
      recvBuf[nRecvBuf++]=recvByte;
      if(CMD_TRANSMIT_30BIT_100US==processingCmd && 4<=nRecvBuf)
      {
        Transmit();
      }
      else if(RECVBUF_SIZE<=nRecvBuf)
      {
        Transmit();
      }
      else if(2<=nRecvBuf && 0xff==recvBuf[nRecvBuf-1] && 0xff==recvBuf[nRecvBuf-2])
      {
        Transmit();
      }
    }
    received=true;
  }

  unsigned long t=millis();
  if(true==received)
  {
    lastDataReceivedTime=t;
  }
  else
  {
    // Second mode of failure.
    // In transmit mode, the FIFO buffer is overwhelmed and starts losing bytes.
    // The terminator 0xffff won't be caught, however, 0x03 included in the
    // pulse-width data put it into the transmitMode again, and never recover.
    // To get out of this mode, the user needs to release the key for 100ms.
    // If no byte is received for 100ms, the program goes back to command mode.
    if(true==transmitMode)
    {
      if(t<lastDataReceivedTime ||   // Timer overflow
         100<t-lastDataReceivedTime) // 100ms no transmittion from host
      {
        transmitMode=false;
        Serial.write(NOTIFY_FAIL);
        Serial.write(NOTIFY_READY);
      }
    }
  }
}

////////////////////////////////////////////////////////////////
// FM77AV Terminal Mode

enum
{
  AVKEY_NULL,

  AVKEY_BREAK,
  AVKEY_PF1,
  AVKEY_PF2,
  AVKEY_PF3,
  AVKEY_PF4,
  AVKEY_PF5,
  AVKEY_PF6,
  AVKEY_PF7,
  AVKEY_PF8,
  AVKEY_PF9,
  AVKEY_PF10,
  AVKEY_EL,
  AVKEY_CLS,
  AVKEY_DUP,
  AVKEY_HOME,
  AVKEY_INS,
  AVKEY_DEL,
  AVKEY_LEFT,
  AVKEY_RIGHT,
  AVKEY_UP,
  AVKEY_DOWN,

  AVKEY_ESC,
  AVKEY_0,
  AVKEY_1,
  AVKEY_2,
  AVKEY_3,
  AVKEY_4,
  AVKEY_5,
  AVKEY_6,
  AVKEY_7,
  AVKEY_8,
  AVKEY_9,
  AVKEY_MINUS,
  AVKEY_HAT,
  AVKEY_YEN,
  AVKEY_BACKSPACE,

  AVKEY_TAB,
  AVKEY_Q,
  AVKEY_W,
  AVKEY_E,
  AVKEY_R,
  AVKEY_T,
  AVKEY_Y,
  AVKEY_U,
  AVKEY_I,
  AVKEY_O,
  AVKEY_P,
  AVKEY_AT,
  AVKEY_LEFT_SQUARE_BRACKET,
  AVKEY_RETURN,

  AVKEY_CTRL,
  AVKEY_A,
  AVKEY_S,
  AVKEY_D,
  AVKEY_F,
  AVKEY_G,
  AVKEY_H,
  AVKEY_J,
  AVKEY_K,
  AVKEY_L,
  AVKEY_SEMICOLON,
  AVKEY_COLON,
  AVKEY_RIGHT_SQUARE_BRACKET,

  AVKEY_LEFT_SHIFT,
  AVKEY_Z,
  AVKEY_X,
  AVKEY_C,
  AVKEY_V,
  AVKEY_B,
  AVKEY_N,
  AVKEY_M,
  AVKEY_COMMA,
  AVKEY_DOT,
  AVKEY_SLASH,
  AVKEY_DOUBLE_QUOTE,
  AVKEY_RIGHT_SHIFT,

  AVKEY_CAPS,
  AVKEY_GRAPH,
  AVKEY_LEFT_SPACE,
  AVKEY_MID_SPACE,
  AVKEY_RIGHT_SPACE,
  AVKEY_KANA,

  AVKEY_NUM_STAR,
  AVKEY_NUM_SLASH,
  AVKEY_NUM_PLUS,
  AVKEY_NUM_MINUS,
  AVKEY_NUM_EQUAL,
  AVKEY_NUM_COMMA,
  AVKEY_NUM_RETURN,
  AVKEY_NUM_DOT,
  AVKEY_NUM_0,
  AVKEY_NUM_1,
  AVKEY_NUM_2,
  AVKEY_NUM_3,
  AVKEY_NUM_4,
  AVKEY_NUM_5,
  AVKEY_NUM_6,
  AVKEY_NUM_7,
  AVKEY_NUM_8,
  AVKEY_NUM_9,

AVKEY_NUM_KEYCODE
};

enum
{
  SHIFT_BIT=0x80000000L,
  CTRL_BIT= 0x40000000L,
  GRAPH_BIT=0x20000000L,
  KANA_BIT= 0x10000000L,
};

struct FM77AVKeyCombination
{
  unsigned short keyCode;
  bool shift;
  bool ctrl;
  bool graph;
  bool kana;
};

static const uint32_t bitPattern[AVKEY_NUM_KEYCODE] PROGMEM= // Supposed to be 101 elem = 404 bytes.
{
0b000000000000000000000000000000, // 
0b101010101010101001001010110101, // AVKEY_BREAK
0b101010101010101001001010101001, // AVKEY_PF1
0b101010101010101001001001010101, // AVKEY_PF2
0b101010101010101001001001001001, // AVKEY_PF3
0b101010101001010110110110110101, // AVKEY_PF4
0b101010101001010110110110101001, // AVKEY_PF5
0b101010101001010110110101010101, // AVKEY_PF6
0b101010101001010110110101001001, // AVKEY_PF7
0b101010101001010110101010110101, // AVKEY_PF8
0b101010101001010110101010101001, // AVKEY_PF9
0b101010101001010110101001010101, // AVKEY_PF10
0b101010101010110101010110101001, // AVKEY_EL
0b101010101010110101010101010101, // AVKEY_CLS
0b101010101010110101001010110101, // AVKEY_DUP
0b101010101010110101001001010101, // AVKEY_HOME
0b101010101010110101010110110101, // AVKEY_INS
0b101010101010110101010101001001, // AVKEY_DEL
0b101010101010110101001001001001, // AVKEY_LEFT
0b101010101010101010110110101001, // AVKEY_RIGHT
0b101010101010110101001010101001, // AVKEY_UP
0b101010101010101010110110110101, // AVKEY_DOWN
0b101010110110110110110110101001, // AVKEY_ESC
0b101010110110110101010101001001, // AVKEY_0
0b101010110110110110110101010101, // AVKEY_1
0b101010110110110110110101001001, // AVKEY_2
0b101010110110110110101010110101, // AVKEY_3
0b101010110110110110101010101001, // AVKEY_4
0b101010110110110110101001010101, // AVKEY_5
0b101010110110110110101001001001, // AVKEY_6
0b101010110110110101010110110101, // AVKEY_7
0b101010110110110101010110101001, // AVKEY_8
0b101010110110110101010101010101, // AVKEY_9
0b101010110110110101001010110101, // AVKEY_MINUS
0b101010110110110101001010101001, // AVKEY_HAT
0b101010110110110101001001010101, // AVKEY_YEN
0b101010110110110101001001001001, // AVKEY_BACKSPACE
0b101010110110101010110110110101, // AVKEY_TAB
0b101010110110101010110110101001, // AVKEY_Q
0b101010110110101010110101010101, // AVKEY_W
0b101010110110101010110101001001, // AVKEY_E
0b101010110110101010101010110101, // AVKEY_R
0b101010110110101010101010101001, // AVKEY_T
0b101010110110101010101001010101, // AVKEY_Y
0b101010110110101010101001001001, // AVKEY_U
0b101010110110101001010110110101, // AVKEY_I
0b101010110110101001010110101001, // AVKEY_O
0b101010110110101001010101010101, // AVKEY_P
0b101010110110101001010101001001, // AVKEY_AT
0b101010110110101001001010110101, // AVKEY_LEFT_SQUARE_BRACKET
0b101010110110101001001010101001, // AVKEY_RETURN
0b101010101010101010110101010101, // AVKEY_CTRL
0b101010110110101001001001010101, // AVKEY_A
0b101010110110101001001001001001, // AVKEY_S
0b101010110101010110110110110101, // AVKEY_D
0b101010110101010110110110101001, // AVKEY_F
0b101010110101010110110101010101, // AVKEY_G
0b101010110101010110110101001001, // AVKEY_H
0b101010110101010110101010110101, // AVKEY_J
0b101010110101010110101010101001, // AVKEY_K
0b101010110101010110101001010101, // AVKEY_L
0b101010110101010110101001001001, // AVKEY_SEMICOLON
0b101010110101010101010110110101, // AVKEY_COLON
0b101010110101010101010110101001, // AVKEY_RIGHT_SQUARE_BRACKET
0b101010101010101010110101001001, // AVKEY_LEFT_SHIFT
0b101010110101010101010101010101, // AVKEY_Z
0b101010110101010101010101001001, // AVKEY_X
0b101010110101010101001010110101, // AVKEY_C
0b101010110101010101001010101001, // AVKEY_V
0b101010110101010101001001010101, // AVKEY_B
0b101010110101010101001001001001, // AVKEY_N
0b101010110101001010110110110101, // AVKEY_M
0b101010110101001010110110101001, // AVKEY_COMMA
0b101010110101001010110101010101, // AVKEY_DOT
0b101010110101001010110101001001, // AVKEY_SLASH
0b101010110101001010101010110101, // AVKEY_DOUBLE_QUOTE
0b101010101010101010101010110101, // AVKEY_RIGHT_SHIFT
0b101010101010101010101010101001, // AVKEY_CAPS
0b101010101010101010101001010101, // AVKEY_GRAPH
0b101010101010101010101001001001, // AVKEY_LEFT_SPACE
0b101010101010101001010110110101, // AVKEY_MID_SPACE
0b101010110101001010101010101001, // AVKEY_RIGHT_SPACE
0b101010101010101001010101010101, // AVKEY_KANA
0b101010110101001010101001010101, // AVKEY_NUM_STAR
0b101010110101001010101001001001, // AVKEY_NUM_SLASH
0b101010110101001001010110110101, // AVKEY_NUM_PLUS
0b101010110101001001010110101001, // AVKEY_NUM_MINUS
0b101010110101001001001010101001, // AVKEY_NUM_EQUAL
0b101010101010110110110110101001, // AVKEY_NUM_COMMA
0b101010101010110110101010101001, // AVKEY_NUM_RETURN
0b101010101010110110101001001001, // AVKEY_NUM_DOT
0b101010101010110110101001010101, // AVKEY_NUM_0
0b101010101010110110110101010101, // AVKEY_NUM_1
0b101010101010110110110101001001, // AVKEY_NUM_2
0b101010101010110110101010110101, // AVKEY_NUM_3
0b101010110101001001001001010101, // AVKEY_NUM_4
0b101010110101001001001001001001, // AVKEY_NUM_5
0b101010101010110110110110110101, // AVKEY_NUM_6
0b101010110101001001010101010101, // AVKEY_NUM_7
0b101010110101001001010101001001, // AVKEY_NUM_8
0b101010110101001001001010110101, // AVKEY_NUM_9
};
static const uint32_t keyTranslationMap[256] PROGMEM =  // Supposed to be 1024 bytes.
{
0x00000000,
0x00000000,
0x00000000,
0x00000001,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000024,
0x00000025,
0x00000032,
0x00000000,
0x00000000,
0x00000032,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000050,
0x80000018,
0x0000004b,
0x8000001a,
0x8000001b,
0x8000001c,
0x8000001d,
0x8000001e,
0x8000001f,
0x80000020,
0x00000053,
0x00000055,
0x00000058,
0x00000056,
0x0000005a,
0x00000054,
0x0000005b,
0x0000005c,
0x0000005d,
0x0000005e,
0x0000005f,
0x00000060,
0x00000061,
0x00000062,
0x00000063,
0x00000064,
0x0000003e,
0x0000003d,
0x80000048,
0x00000057,
0x80000049,
0x8000004a,
0x00000030,
0x80000034,
0x80000045,
0x80000043,
0x80000036,
0x80000028,
0x80000037,
0x80000038,
0x80000039,
0x8000002d,
0x8000003a,
0x8000003b,
0x8000003c,
0x80000047,
0x80000046,
0x8000002e,
0x8000002f,
0x80000026,
0x80000029,
0x80000035,
0x8000002a,
0x8000002c,
0x80000044,
0x80000027,
0x80000042,
0x8000002b,
0x80000041,
0x00000031,
0x00000023,
0x0000003f,
0x00000022,
0x8000004b,
0x80000030,
0x00000034,
0x00000045,
0x00000043,
0x00000036,
0x00000028,
0x00000037,
0x00000038,
0x00000039,
0x0000002d,
0x0000003a,
0x0000003b,
0x0000003c,
0x00000047,
0x00000046,
0x0000002e,
0x0000002f,
0x00000026,
0x00000029,
0x00000035,
0x0000002a,
0x0000002c,
0x00000044,
0x00000027,
0x00000042,
0x0000002b,
0x00000041,
0x80000031,
0x80000023,
0x8000003f,
0x80000022,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
0x00000000,
};

struct FM77AVKeyCombination FM77AVGetKeyComb(unsigned char c)
{
  struct FM77AVKeyCombination comb;
  uint32_t code=pgm_read_dword(&keyTranslationMap[c]);
  comb.keyCode=(code&0xFFFF);
  comb.shift=(0!=(code&SHIFT_BIT));
  comb.ctrl=(0!=(code&CTRL_BIT));
  comb.graph=(0!=(code&GRAPH_BIT));
  comb.kana=(0!=(code&KANA_BIT));
  return comb;
}

unsigned int FM77AVGet1stByteIn30bitEncoding(uint32_t code)
{
  //0b101010110101001001001010110101
  //      ^^^^^^^^
  /* original
  unsigned int sum=0;
  unsigned int bitShift=0x80;
  for(int i=4; i<12; ++i)
  {
    if('1'==code30[i])
    {
      sum+=bitShift;
    }
    bitShift>>=1;
  return sum;
  } */
  return (code>>18)&0xFF;  
}

void FM77AVPut1stByteIn30bitEncoding(uint32_t &code,uint32_t byteData)
{
  /* original code when code was a string.
  unsigned int bitShift=0x80;
  for(int i=4; i<12; ++i)
  {
    if(0!=(byteData&bitShift))
    {
      code30[i]='1';
    }
    else
    {
      code30[i]='0';
    }
    bitShift>>=1;
  }
   * 
   */
  code &=0b111100000000111111111111111111;
  code|=(byteData<<18);
}

uint32_t FM77AVGetKeyPress30BitPattern(int fm77avkey)
{
  if(AVKEY_NULL<fm77avkey && fm77avkey<AVKEY_NUM_KEYCODE)
  {
    return pgm_read_dword(&bitPattern[fm77avkey]);
  }
  return 0;
}

uint32_t FM77AVGetKeyRelease30BitPattern(int fm77avkey)
{
  uint32_t code=FM77AVGetKeyPress30BitPattern(fm77avkey);
  if(0!=code)
  {
    /* Thanks to Mr. Kobayashi from Classic PC & Retro Game Club JAPAN
       for calculation of the key-release code.
    */

    auto firstByte=FM77AVGet1stByteIn30bitEncoding(code);
    firstByte-=0x60;
    firstByte&=255;
    FM77AVPut1stByteIn30bitEncoding(code,firstByte);
    return code;
  }
  return 0;
}

struct FM77AVKeyEvent
{
  bool pressEvent; // If false, it is a release event.
  int keyCode;
};

uint32_t FM77AVMake30BitPattern(const struct FM77AVKeyEvent keyEvent)
{
  if(true==keyEvent.pressEvent)
  {
    return FM77AVGetKeyPress30BitPattern(keyEvent.keyCode);
  }
  else
  {
    return FM77AVGetKeyRelease30BitPattern(keyEvent.keyCode);
  }
}

void SendCode(uint32_t code)
{
  unsigned int k=0;
  unsigned char samplePtr=0;
  uint32_t bit=1;
  bit<<=29;
  cycle[k]=0;
  for(unsigned char i=0; i<30; ++i)
  {
    bool currentBit=((~k)&1);
    bool nextBit=(code&bit);
    if(currentBit!=nextBit)
    {
      ++k;
      cycle[k]=0;
    }
    cycle[k]+=pulseWidthTable[i];
    bit>>=1;
  }
  ++k;

  cycle[k]=0;
  k+=(k&1); // Force it to be even.
  cycle[k  ]=0xffff;
  cycle[k+1]=0xffff;

  SetPin8High;
  SendCycleHWPWM(cycle);
  SetPin8Low;
}

void KeyPress(uint32_t avkey)
{
  uint32_t code=FM77AVGetKeyPress30BitPattern(avkey);
  if(0!=code)
  {
    SendCode(code);  // Takes 4ms
    delayMicroseconds(8000);
  }
}
void KeyRelease(uint32_t avkey)
{
  uint32_t code=FM77AVGetKeyRelease30BitPattern(avkey);
  if(0!=code)
  {
    SendCode(code);  // Takes 4ms
    delayMicroseconds(8000);
  }
}
void TerminalMode(unsigned char recv)
{
  auto comb=FM77AVGetKeyComb(recv);
  if(AVKEY_NULL!=comb.keyCode)
  {
    if(comb.kana)
    {
      KeyPress(AVKEY_KANA);
    }
    if(comb.shift)
    {
      KeyPress(AVKEY_LEFT_SHIFT);
    }
    if(comb.ctrl)
    {
      KeyPress(AVKEY_CTRL);
    }
    if(comb.graph)
    {
      KeyPress(AVKEY_GRAPH);
    }

    KeyPress(comb.keyCode);
    KeyRelease(comb.keyCode);

    if(comb.graph)
    {
      KeyRelease(AVKEY_GRAPH);
    }
    if(comb.ctrl)
    {
      KeyRelease(AVKEY_CTRL);
    }
    if(comb.shift)
    {
      KeyRelease(AVKEY_LEFT_SHIFT);
    }
    if(comb.kana)
    {
      KeyRelease(AVKEY_KANA);
    }
    Serial.write(recv);
  }
  else
  {
    Serial.println((int)recv);
  }
}
