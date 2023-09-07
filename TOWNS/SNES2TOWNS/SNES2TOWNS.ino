/* LICENSE>>
Copyright 2023 Soji Yamakawa (CaptainYS, http://www.ysflight.com)

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

<< LICENSE */


#define AS_TOWNS2BTN 14  // If A0 is high, present self as 2-Button Towns Game Pad
#define AS_TOWNS6BTN 15  // If A1 is high, present self as 6-Button Towns Game Pad
#define STATUS_LED 16
#define CLOCK 17  // A0 for CLOCK
#define LATCH 18  // A1 for LATCH
#define DATA 19   // A2 for DATA

// Order SNES game pad sends.
#define _B 0
#define _Y 1
#define _SELECT 2
#define _START 3
#define _UP 4
#define _DOWN 5
#define _LEFT 6
#define _RIGHT 7
#define _A 8
#define _X 9
#define _L 10
#define _R 11

//                   CPSF     TOWNS 6BTN    TOWNS 2BTN
#define OUT_P1A 13  // UP          UP            UP
#define OUT_P1B 12  // R           X             UP
#define OUT_P2A 11  // DOWN        DOWN          DOWN
#define OUT_P2B 10  // Y           Y             DOWN
#define OUT_P3A  9  // LEFT        LEFT          LEFT
#define OUT_P3B  8  // X           L             LEFT
#define OUT_P4A  7  // RIGHT       RIGHT         RIGHT
#define OUT_P4B  6  // SEL         R             RIGHT
#define OUT_P6A  5  // A           A             A
#define OUT_P6B  4  // L           A             A
#define OUT_P7A  3  // B           B             B
#define OUT_P7B  2  // START       B             B

#define OUT_BEGIN OUT_P7B   // Pin 2
#define OUT_END OUT_P1A  // to Pin 13
#define NUM_OUTPUTS (OUT_END-OUT_BEGIN+1)
#define SNES_NUM_PULSES 16

void setup() {
  pinMode(LATCH, OUTPUT);
  pinMode(CLOCK, OUTPUT);
  pinMode(DATA, INPUT);

  pinMode(STATUS_LED,OUTPUT);
  digitalWrite(STATUS_LED,HIGH);

  digitalWrite(CLOCK, LOW);
  digitalWrite(LATCH, LOW);

  for(int i=OUT_BEGIN; i<=OUT_END; ++i) {
    pinMode(i, OUTPUT);
    digitalWrite(i, LOW);
  }

  pinMode(AS_TOWNS2BTN, INPUT);
  pinMode(AS_TOWNS6BTN, INPUT);
}

enum
{
  MODE_AS_CPSF,
  MODE_AS_TOWNS6BUTTON,
  MODE_AS_TOWNSPAD,
};

void DoTownsThings(unsigned int readbuf[])
{
  if(LOW==readbuf[_SELECT])
  {
    readbuf[_UP]=LOW;
    readbuf[_DOWN]=LOW;
  }
  if(LOW==readbuf[_START])
  {
    readbuf[_LEFT]=LOW;
    readbuf[_RIGHT]=LOW;
  }
}

void loop() {
  unsigned int readbuf[NUM_OUTPUTS];
  unsigned int mode=MODE_AS_CPSF;
  if(HIGH==digitalRead(AS_TOWNS2BTN))
  {
    mode=MODE_AS_TOWNSPAD;
  }
  else if(HIGH==digitalRead(AS_TOWNS6BTN))
  {
    mode=MODE_AS_TOWNS6BUTTON;
  }

  digitalWrite(CLOCK, HIGH);
  digitalWrite(LATCH, HIGH);
  delayMicroseconds(12);
  digitalWrite(LATCH, LOW);
  // Experiment indicates 16 clock pulses are necessary for SNES Controller.
  // CAPCOM Power Stick Fighter works fine if I stop at 12 clock pulses, but
  // SNES Controller occasionally fails to latch if I do not cycle clock pulse 16 times after latch.
  // Update: SNES Controller apparently does not allow re-latching until all 16 clock pulses comes.
  //         Therefore, if I stop reading at 12 clock pulses, next time the latch pulse is ignored,
  //         and I only reads left-over four bits, which are not assigned to any buttons.
  //         This behavior is not observed in CAPCOM Power Stick Fighter.
  for (int i = 0; i<SNES_NUM_PULSES; ++i) {
    delayMicroseconds(6);
    if(i<NUM_OUTPUTS)
    {
      readbuf[i]=digitalRead(DATA);
    }
    digitalWrite(CLOCK, LOW);
    delayMicroseconds(6);
    digitalWrite(CLOCK, HIGH);
  }

  digitalWrite(STATUS_LED,readbuf[_START]);

  switch(mode)
  {
  case MODE_AS_CPSF:
    digitalWrite(OUT_P1A,readbuf[_UP]);
    digitalWrite(OUT_P1B,readbuf[_R]);
    digitalWrite(OUT_P2A,readbuf[_DOWN]);
    digitalWrite(OUT_P2B,readbuf[_Y]);
    digitalWrite(OUT_P3A,readbuf[_LEFT]);
    digitalWrite(OUT_P3B,readbuf[_X]);
    digitalWrite(OUT_P4A,readbuf[_RIGHT]);
    digitalWrite(OUT_P4B,readbuf[_SELECT]);
    digitalWrite(OUT_P6A,readbuf[_A]);
    digitalWrite(OUT_P6B,readbuf[_L]);
    digitalWrite(OUT_P7A,readbuf[_B]);
    digitalWrite(OUT_P7B,readbuf[_START]);
    break;
  case MODE_AS_TOWNS6BUTTON:
    DoTownsThings(readbuf);
    digitalWrite(OUT_P1A,readbuf[_UP]);
    digitalWrite(OUT_P1B,readbuf[_X]);
    digitalWrite(OUT_P2A,readbuf[_DOWN]);
    digitalWrite(OUT_P2B,readbuf[_Y]);
    digitalWrite(OUT_P3A,readbuf[_LEFT]);
    digitalWrite(OUT_P3B,readbuf[_L]);
    digitalWrite(OUT_P4A,readbuf[_RIGHT]);
    digitalWrite(OUT_P4B,readbuf[_R]);
    digitalWrite(OUT_P6A,readbuf[_A]);
    digitalWrite(OUT_P6B,readbuf[_A]);
    digitalWrite(OUT_P7A,readbuf[_B]);
    digitalWrite(OUT_P7B,readbuf[_B]);
    break;
  case MODE_AS_TOWNSPAD:
    DoTownsThings(readbuf);
    digitalWrite(OUT_P1A,readbuf[_UP]);
    digitalWrite(OUT_P1B,readbuf[_UP]);
    digitalWrite(OUT_P2A,readbuf[_DOWN]);
    digitalWrite(OUT_P2B,readbuf[_DOWN]);
    digitalWrite(OUT_P3A,readbuf[_LEFT]);
    digitalWrite(OUT_P3B,readbuf[_LEFT]);
    digitalWrite(OUT_P4A,readbuf[_RIGHT]);
    digitalWrite(OUT_P4B,readbuf[_RIGHT]);
    digitalWrite(OUT_P6A,readbuf[_A]);
    digitalWrite(OUT_P6B,readbuf[_A]);
    digitalWrite(OUT_P7A,readbuf[_B]);
    digitalWrite(OUT_P7B,readbuf[_B]);
    break;
  }

 /* static int k=OUT_BEGIN;
  for(int i=0; i<NUM_OUTPUT; ++i)
  {
    digitalWrite(OUT_BEGIN+i,HIGH);
  }
  digitalWrite(k,LOW);
  ++k;
  if(OUT_BEGIN+NUM_OUTPUT<k)
  {
    k=OUT_BEGIN;
  }
  delay(100); */
}
