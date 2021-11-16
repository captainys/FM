#include <fcntl.h>
#include <termios.h>
#include <unistd.h>
#include <string.h>

#include "comport.h"



class YsCOMPort::PortHandle
{
public:
	int fd=0;
};




/* static */ std::vector <std::string> YsCOMPort::FindAvailablePortName(void)
{
	std::vector <std::string> available;
	return available;
}
bool YsCOMPort::Open(const std::string &port)
{
	Close();
	portPtr=new PortHandle;
	portPtr->fd=open(port.c_str(),O_RDWR|O_NOCTTY|O_SYNC);
	if(portPtr->fd<0)
	{
		delete portPtr;
		portPtr=nullptr;
		return false;
	}

	return ChangeBaudRate(desiredBaudRate);
}

bool YsCOMPort::ChangeBaudRate(int baudRate)
{
	int fSpeed=0; // f**kingSpeed.
	if(desiredBaudRate<2400)
	{
		fSpeed=B1200;
	}
	else if(desiredBaudRate<4800)
	{
		fSpeed=B2400;
	}
	else if(desiredBaudRate<9600)
	{
		fSpeed=B4800;
	}
	else if(desiredBaudRate<19200)
	{
		fSpeed=B9600;
	}
	else if(desiredBaudRate<38400)
	{
		fSpeed=B19200;
	}
	else if(desiredBaudRate<57600)
	{
		fSpeed=B38400;
	}
	else if(desiredBaudRate<115200)
	{
		fSpeed=B57600;
	}
	else
	{
		fSpeed=B115200;
	}

	// Stack overflow questions/6947413

	struct termios tty;
	memset(&tty,0,sizeof(tty));
	if(0==tcgetattr(portPtr->fd,&tty))
	{
		cfsetospeed(&tty,fSpeed);
		cfsetispeed(&tty,fSpeed);

		tty.c_cflag&=~(CSIZE|PARENB|PARODD|CSTOPB|CRTSCTS);
		tty.c_cflag|=(CS8|CLOCAL|CREAD);  // 8bit

		tty.c_iflag&=~(IXON|IXOFF|IXANY|IGNBRK|INLCR|ICRNL); // F**K ICRNL

		tty.c_lflag=0;

		tty.c_oflag=0;

		tty.c_cc[VMIN]=0; // Non blocking
		tty.c_cc[VTIME]=0; // Polling read
		if(0==tcsetattr(portPtr->fd,TCSANOW,&tty))
		{
			return true;
		}
		fprintf(stderr,"Failed to set tty attrib.\n");
		return false;
	}
	fprintf(stderr,"Failed to get tty attrib.\n");
	return false;
}

void YsCOMPort::Close(void)
{
	if(nullptr!=portPtr)
	{
		close(portPtr->fd);
		delete portPtr;
	}
	portPtr=nullptr;
}

bool YsCOMPort::Update(void)
{
	return true;
}

long long int YsCOMPort::Send(long long int nDat,const unsigned char dat[])
{
	if(nullptr!=portPtr)
	{
		auto len=write(portPtr->fd,dat,nDat);
		fsync(portPtr->fd);
		return len;
	}
	return 0;
}

void YsCOMPort::SendBreak(void)
{
}

void YsCOMPort::FlushWriteBuffer(void)
{
}

std::vector <unsigned char> YsCOMPort::Receive(void)
{
	std::vector <unsigned char> dat;
	if(nullptr!=portPtr)
	{
		unsigned char readBuf[256];
		for(;;)
		{
			auto nRead=read(portPtr->fd,readBuf,255);
			if(0==nRead)
			{
				break;
			}
			for(int i=0; i<nRead; ++i)
			{
				dat.push_back(readBuf[i]);
			}
		}
	}
	return dat;
}
