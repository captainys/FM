#include <time.h>
#include <string>
#include <iostream>

#include <fcntl.h>
#include <unistd.h>
#include <sys/poll.h>
#include <linux/input.h>

#include "fm77avkeymap.h"
#include "fm77avkey.h"

#include "RaspPITransmit.h"



class Device
{
public:
    int fd=-1;
    std::string name;
    int version;

    ~Device();
    bool Open(std::string fName);
    void Close(void);
};

Device::~Device()
{
    Close();
}

bool Device::Open(std::string devPath)
{
    Close();

    fd=open(devPath.c_str(),O_RDONLY);
    if(fd<0)
    {
        return false;
    }

    if(0!=ioctl(fd,EVIOCGVERSION,&version))
    {
        Close();
        return false;
    }

    char nm[256];
    ioctl(fd,EVIOCGNAME(sizeof(nm)));
    name=nm;

    return true;
}

void Device::Close(void)
{
    if(0<=fd)
    {
        close(fd);
        fd=-1;
    }
}




int RealMain(std::string devPath)
{
	FM77AVKeyMap keymap;

    Device dev;
    std::cout << "Opening:" << devPath << std::endl;
    if(true!=dev.Open(devPath))
    {
        std::cout << "Failed to open device or get device info." << std::endl;
        return 1;
    }

    std::cout << "Name:" << dev.name << " Ver:" << dev.version << std::endl;

    auto cTime=time(nullptr);
    for(;;)
    {
        struct input_event evt[64];

        struct pollfd pfd;
        pfd.fd=dev.fd;
        pfd.events=POLLIN;
        pfd.revents=0;
        if(1<=poll(&pfd,1,1))
        {
            std::cout << "Event detected!" << std::endl;
            auto n=read(dev.fd,evt,sizeof(evt));
            n/=sizeof(evt[0]);
            for(int i=0; i<n; ++i)
            {
                if(evt[i].type==EV_KEY)
                {
                    if(1==evt[i].value)
                    {
                        std::cout << "Key Press" << std::endl;
                        auto found=keymap.map.find(evt[i].code);
                        if(keymap.map.end()!=found)
                        {
							std::string ptn=FM77AVGetKeyPress30BitPattern(found->second);
							Transmit30Bit(ptn.c_str());
							WaitAfterTransmissionFailure();
						}
                    }
                    else if(2==evt[i].value)
                    {
                        std::cout << "Key Repeat" << std::endl;
                        auto found=keymap.map.find(evt[i].code);
                        if(keymap.map.end()!=found)
                        {
							std::string ptn=FM77AVGetKeyPress30BitPattern(found->second);
							Transmit30Bit(ptn.c_str());
							WaitAfterTransmissionFailure();
						}
                    }
                    else if(0==evt[i].value)
                    {
                        std::cout << "Key Release" << std::endl;
                        auto found=keymap.map.find(evt[i].code);
                        if(keymap.map.end()!=found)
                        {
							std::string ptn=FM77AVGetKeyRelease30BitPattern(found->second);
							Transmit30Bit(ptn.c_str());
							WaitAfterTransmissionFailure();
						}
                    }
                }
            }
        }


        if(time(nullptr)!=cTime)
        {
            cTime=time(nullptr);
            std::cout << "." << std::endl;
        }
    }

    return 0;
}

int main(int ac,char *av[])
{
	InitTransmitter();
    return RealMain(av[1]);
}