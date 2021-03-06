#ifndef XMODEM_H_IS_INCLUDED
#define XMODEM_H_IS_INCLUDED

#define XMODEM_RECVSTA_INIT				0
#define XMODEM_RECVSTA_WAITSOH			1
#define XMODEM_RECVSTA_WAITIDX1			2
#define XMODEM_RECVSTA_WAITIDX2			3
#define XMODEM_RECVSTA_DATA				4
#define XMODEM_RECVSTA_CRC				5
#define XMODEM_RECVSTA_CRC2				6
#define XMODEM_RECVSTA_EOT				7


#define XMODEM_SENDSTA_WAIT_NAK_OR_C	0
#define XMODEM_SENDSTA_WAIT_ACK			1
#define XMODEM_SENDSTA_NEXT_PACKET		2
#define XMODEM_SENDSTA_SENT_EOT			3


#define XMODEM_SOH						0x01
#define XMODEM_EOT						0x04
#define XMODEM_ACK						0x06
#define XMODEM_NAK						0x15
#define XMODEM_ETB						0x17
#define XMODEM_CAN						0x18
#define XMODEM_C						0x43

#define XMODEM_PACKET_SIZE				128

#define XMODEM_MODE_CRC                 0
#define XMODEM_MODE_CHECKSUM            1
#define XMODEM_MODE_UNKNOWN             -1

#endif
