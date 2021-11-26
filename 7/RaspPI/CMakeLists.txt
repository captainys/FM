add_library(RaspPITransmit RaspPITransmit.cpp RaspPITransmit.h)
target_include_directories(RaspPITransmit PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(RaspPITransmit pigpio pthread rt)
