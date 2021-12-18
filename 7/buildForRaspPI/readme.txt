<<< Prerequisite >>>
  clang
  OpenGL libraries
  PIGPIO library
  CMake version 3.2 or newer

(Type the following commands to install prerequisites)

sudo apt-get install clang
sudo apt-get install freeglut3-dev
sudo apt-get install cmake

cd ~
mkdir pigpio
cd pigpio
wget https://github.com/joan2937/pigpio/archive/master.zip
unzip master.zip
cd pigpio-master
make
sudo make install



<<< Compile >>>
(Type the following commands to build FM77AV Keyboard Emulator for Raspberry PI)

cd ~
git clone https://github.com/captainys/FM.git
cd FM/7/buildForRaspPI
mdir build
cd build
cmake ..
cmake --build . --config Release



<<< Run >>>
sudo ~/FM/7/buildForRaspPI/build/FM77AVKeyboard/FM77AVKeyboard
