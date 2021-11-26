cmake_minimum_required(VERSION 3.2)


# gpioTransmit library uses pigpio library.
# Exactly follow the instruction on:
#    https://abyz.me.uk/rpi/pigpio/download.html
# to install pigpio library.



# Cmake V3.12 add_compile_definitions
add_compile_options(-DYS_RASPBERRYPI)

set(YS_RASPBERRYPI 1)

include_directories(${CMAKE_CURRENT_SOURCE_DIR})
include_directories(../imported/include)

add_subdirectory("../FM77AVKeyboardRaspPI" "${CMAKE_BINARY_DIR}/FM77AVKeyboardRaspPI")

add_subdirectory("../FM77AVKeyboard" "${CMAKE_BINARY_DIR}/FM77AVKeyboard")
add_subdirectory("../util/lib/yscomport" "${CMAKE_BINARY_DIR}/yscomport")
add_subdirectory("../lib/irtoy" "${CMAKE_BINARY_DIR}/irtoy")
add_subdirectory("../lib/cheaplib" "${CMAKE_BINARY_DIR}/cheaplib")
add_subdirectory("../lib/cheapgui" "${CMAKE_BINARY_DIR}/cheapgui")
# add_subdirectory("../RomajiToKanaKey" "${CMAKE_BINARY_DIR}/RomajiToKanaKey")
add_subdirectory("../RaspPI" "${CMAKE_BINARY_DIR}/RaspPI")

add_subdirectory("../lib/ysgl/src" "${CMAKE_BINARY_DIR}/ysgl")
add_subdirectory("../lib/ysbitmapfont/src" "${CMAKE_BINARY_DIR}/ysbitmapfont")
add_subdirectory("../lib/fssimplewindow/src" "${CMAKE_BINARY_DIR}/fssimplewindow")
