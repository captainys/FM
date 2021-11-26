cmake_minimum_required(VERSION 3.0)
project(FM77AVKeyboardRaspPI)


# gpioTransmit library uses pigpio library.
# Exactly follow the instruction on:
#    https://abyz.me.uk/rpi/pigpio/download.html
# to install pigpio library.


# CMake does not have a way to identify Raspberry PI.
# Therefore, CMake script must be isolated from other cross-platform scripts.

add_executable(FM77AVKeyboardCUI
	fm77avkeymap.cpp
	fm77avkeymap.h
	main.cpp
	RaspPITransmit.cpp
	RaspPITransmit.h
	../FM77AVKeyboard/fm77avkey.cpp
	../FM77AVKeyboard/fm77avkey.h
)
target_include_directories(FM77AVKeyboardCUI PUBLIC ../FM77AVKeyboard)
target_link_libraries(FM77AVKeyboardCUI pigpio pthread rt)
