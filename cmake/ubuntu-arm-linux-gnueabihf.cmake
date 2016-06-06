# shamelessly copied over from oxide’s build system
# to enable ARM cross compilation

set(CMAKE_SYSTEM_NAME Linux CACHE INTERNAL "")

find_program(_DPKG_ARCH_EXECUTABLE dpkg-architecture)
if(_DPKG_ARCH_EXECUTABLE STREQUAL "DPKG_ARCHITECTURE_EXECUTABLE-NOTFOUND")
  message(FATAL_ERROR "dpkg-architecture not found")
endif()
execute_process(COMMAND ${_DPKG_ARCH_EXECUTABLE} -qDEB_BUILD_MULTIARCH
                RESULT_VARIABLE _RESULT
                OUTPUT_VARIABLE HOST_ARCHITECTURE
                OUTPUT_STRIP_TRAILING_WHITESPACE)
if(NOT _RESULT EQUAL 0)
  message(FATAL_ERROR "Failed to determine host architecture")
endif()

set(CMAKE_C_COMPILER arm-linux-gnueabihf-gcc CACHE INTERNAL "")
set(CMAKE_CXX_COMPILER arm-linux-gnueabihf-g++ CACHE INTERNAL "")
set(CMAKE_LIBRARY_ARCHITECTURE arm-linux-gnueabihf CACHE INTERNAL "")
set(ENV{PKG_CONFIG_PATH} /usr/lib/${CMAKE_LIBRARY_ARCHITECTURE}/pkgconfig CACHE INTERNAL "")
