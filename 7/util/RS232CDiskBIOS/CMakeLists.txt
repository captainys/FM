set(TARGET_NAME RS232CDiskBios)

add_executable(${TARGET_NAME} main.cpp disk_bios_hook_client.cpp disk_bios_hook_client.h disk_bios_hook_clientCOM1.cpp disk_bios_hook_clientCOM1.h ../rs232cLoader/strloader.h ../rs232cLoader/strloader.cpp)
target_link_libraries(${TARGET_NAME} fm7lib d77lib comportlib)

foreach(TARGET ${TARGET_NAME})
	set_target_properties(${TARGET} PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/exe")
	set_target_properties(${TARGET} PROPERTIES RUNTIME_OUTPUT_DIRECTORY_DEBUG "${CMAKE_BINARY_DIR}/exe")
	set_target_properties(${TARGET} PROPERTIES RUNTIME_OUTPUT_DIRECTORY_RELEASE "${CMAKE_BINARY_DIR}/exe")
	target_include_directories(${TARGET} PRIVATE ../rs232cLoader)
endforeach(TARGET)
