#ifndef RASPPITRANSMIT_IS_INCLUDED
#define RASPPITRANSMIT_IS_INCLUDED
/* { */

void InitTransmitter(void);
void CloseTransmitter(void);
bool Transmit30Bit(const char bits[30]);
void Transmit30BitAutoRetry(const char bit[30],int nRetry);
void WaitAfterTransmissionFailure(void);

/* } */
#endif
