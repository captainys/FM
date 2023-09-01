#define AS_CPSF 14    // If A0 is high, present self to TOWNS as CPSF
#define AS_FJ6BTN 15  // If A1 is high, present self to TOWNS as Fujitsu 6-Button Pad

#define CLOCK 17  // A0 for CLOCK
#define LATCH 18  // A1 for LATCH
#define DATA 19   // A2 for DATA

#define OUT_BEGIN 2    // Pin 2
#define NUM_OUTPUT 12  // to Pin 13

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

void setup() {
  pinMode(LATCH, OUTPUT);
  pinMode(CLOCK, OUTPUT);
  pinMode(DATA, INPUT);

  digitalWrite(CLOCK, LOW);
  digitalWrite(LATCH, LOW);

  for (int i = 0; i < NUM_OUTPUT; ++i) {
    pinMode(OUT_BEGIN + i, OUTPUT);
    digitalWrite(OUT_BEGIN + i, LOW);
  }

  pinMode(AS_CPSF, INPUT);
  pinMode(AS_FJ6BTN, INPUT);
}

void ConvertAsTOWNS6ButtonPad(unsigned int readbuf[])
{
  if(LOW==readbuf[_START])
  {
    readbuf[_LEFT]=LOW;
    readbuf[_RIGHT]=LOW;
  }
  if(LOW==readbuf[_SELECT])
  {
    readbuf[_UP]=LOW;
    readbuf[_DOWN]=LOW;
  }

  // TOWNS 6 Button Pad button label  A,B,C,X,Y,Z
  // SNES/CPSF Button label           A,B,X,Y,L,R

  unsigned int CBtn=readbuf[_X];
  unsigned int XBtn=readbuf[_Y];
  unsigned int YBtn=readbuf[_L];
  unsigned int ZBtn=readbuf[_R];

  readbuf[_L]=readbuf[_A];
  readbuf[_START]=readbuf[_B];

  readbuf[_R]=ZBtn;  // <-> UP
  readbuf[_Y]=YBtn;  // <-> DOWN
  readbuf[_X]=XBtn;  // <-> LEFT
  readbuf[_SELECT]=CBtn; // <-> RIGHT
}

void ConvertAsTOWNSPad(unsigned int readbuf[])
{
  if(LOW==readbuf[_START])
  {
    readbuf[_LEFT]=LOW;
    readbuf[_RIGHT]=LOW;
  }
  if(LOW==readbuf[_SELECT])
  {
    readbuf[_UP]=LOW;
    readbuf[_DOWN]=LOW;
  }

  readbuf[_R]=readbuf[_UP];
  readbuf[_L]=readbuf[_A];
  readbuf[_Y]=readbuf[_DOWN];
  readbuf[_START]=readbuf[_B];
  readbuf[_X]=readbuf[_LEFT];
  readbuf[_SELECT]=readbuf[_RIGHT];
}

enum
{
  MODE_AS_CPSF,
  MODE_AS_TOWNS6BUTTON,
  MODE_AS_TOWNSPAD,
};

void loop() {
  unsigned int readbuf[NUM_OUTPUT];
  unsigned int mode=MODE_AS_CPSF;

  digitalWrite(CLOCK, HIGH);
  digitalWrite(LATCH, HIGH);
  delayMicroseconds(12);
  digitalWrite(LATCH, LOW);
  for (int i = 0; i<NUM_OUTPUT; ++i) {
    delayMicroseconds(6);
    readbuf[i]=digitalRead(DATA);
    digitalWrite(CLOCK, LOW);
    delayMicroseconds(6);
    digitalWrite(CLOCK, HIGH);
  }

  switch(mode)
  {
  case MODE_AS_CPSF:
    break;
  case MODE_AS_TOWNS6BUTTON:
    ConvertAsTOWNS6ButtonPad(readbuf);
    break;
  case MODE_AS_TOWNSPAD:
    ConvertAsTOWNSPad(readbuf);
    break;
  }

  for(int i=0; i<NUM_OUTPUT; ++i)
  {
    digitalWrite(OUT_BEGIN + i, readbuf[i]);
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
