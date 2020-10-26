cmake_minimum_required(VERSION 3.5)

project(rtl_airband)

set(CMAKE_CXX_STANDARD 20)

set(APPLICATION_NAME "RTL Airband")

set(APPLICATION_VERSION_MAJOR "0")
set(APPLICATION_VERSION_MINOR "0")
set(APPLICATION_VERSION_PATCH "0")
set(APPLICATION_VERSION "${APPLICATION_VERSION_MAJOR}.${APPLICATION_VERSION_MINOR}.${APPLICATION_VERSION_PATCH}")

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

find_package(PkgConfig REQUIRED)

set(RTL_AIRBAND_PLATFORM_VALUES
        rpiv1
        rpiv2
        armv7-generic
        armv8-generic
        x86
        x86-freebsd)
set(RTL_AIRBAND_PLATFORM "x86" CACHE STRING "Select platform")
set_property(CACHE RTL_AIRBAND_PLATFORM
        PROPERTY STRINGS ${RTL_AIRBAND_PLATFORM_VALUES})

if (NOT RTL_AIRBAND_PLATFORM IN_LIST RTL_AIRBAND_PLATFORM_VALUES)
    message(FATAL_ERROR "RTL_AIRBAND_PLATFORM with value \"${RTL_AIRBAND_PLATFORM}\" is not valid. Must be one of ${RTL_AIRBAND_PLATFORM_VALUES}")
endif ()

set(RTL_AIRBAND_NFM FALSE CACHE BOOL "Include support for Narrow FM demodulation")
set(RTL_AIRBAND_PULSE FALSE CACHE BOOL "Include support for streaming to PulseAudio server")
set(RTL_AIRBAND_RTLSDR TRUE CACHE BOOL "Enable RTL-SDR support (via librtlsdr)")
set(RTL_AIRBAND_MIRISDR FALSE CACHE BOOL "Enable Mirics DVB-T chipset support (via libmirisdr)")
set(RTL_AIRBAND_SOAPYSDR FALSE CACHE BOOL "Enable SoapySDR support")

find_package(Threads REQUIRED)
find_package(Lame REQUIRED)

pkg_check_modules(VorbisEnc REQUIRED IMPORTED_TARGET vorbisenc)
pkg_check_modules(Shout REQUIRED IMPORTED_TARGET shout)
pkg_check_modules(Config++ REQUIRED IMPORTED_TARGET libconfig++)

set(SOURCES
        rtl_airband.cpp rtl_airband.h
        input-common.cpp input-common.h
        input-helpers.cpp input-helpers.h
        output.cpp
        config.cpp
        util.cpp
        mixer.cpp)

set(LIBRARIES
        Threads::Threads
        rt
        m
        dl
        Lame::Lame
        PkgConfig::VorbisEnc
        PkgConfig::Shout
        PkgConfig::Config++)

if (RTL_AIRBAND_PLATFORM STREQUAL "rpiv1")
    include_directories(/opt/vc/include)
    include_directories(/opt/vc/include/interface/vcos/pthreads)
    include_directories(/opt/vc/include/interface/vmcs_host/linux)
    set(RTL_AIRBAND_CFLAGS "-mcpu=arm1176jzf-s -mtune=arm1176jzf-s -march=armv6zk -mfpu=vfp -ffast-math")
    add_compile_definitions(USE_BCM_VC)
    list(APPEND SOURCES rtl_airband_vfp.s)
elseif (RTL_AIRBAND_PLATFORM STREQUAL "rpiv2")
    include_directories(/opt/vc/include)
    include_directories(/opt/vc/include/interface/vcos/pthreads)
    include_directories(/opt/vc/include/interface/vmcs_host/linux)
    set(RTL_AIRBAND_CFLAGS "-march=armv7-a -mfpu=neon-vfpv4 -mfloat-abi=hard -ffast-math")
    add_compile_definitions(USE_BCM_VC)
    list(APPEND SOURCES rtl_airband_neon.s)
elseif (RTL_AIRBAND_PLATFORM STREQUAL "armv7-generic")
    set(RTL_AIRBAND_CFLAGS "-march=armv7-a -mfpu=neon-vfpv4 -mfloat-abi=hard -ffast-math")
    find_package(FFTW REQUIRED COMPONENTS FLOAT_LIB)
    list(APPEND LIBRARIES FFTW::Float)
elseif (RTL_AIRBAND_PLATFORM STREQUAL "armv8-generic")
    set(RTL_AIRBAND_CFLAGS "-march=armv8-a+crc -mtune=cortex-a53 -ffast-math")
    find_package(FFTW REQUIRED COMPONENTS FLOAT_LIB)
    list(APPEND LIBRARIES FFTW::Float)
elseif (RTL_AIRBAND_PLATFORM STREQUAL "x86")
    set(RTL_AIRBAND_CFLAGS "-march=native")
    find_package(FFTW REQUIRED COMPONENTS FLOAT_LIB)
    list(APPEND LIBRARIES FFTW::Float)
elseif (RTL_AIRBAND_PLATFORM STREQUAL "x86-freebsd")
    set(RTL_AIRBAND_CFLAGS "-march=native -I/usr/local/include")
    find_package(FFTW REQUIRED COMPONENTS FLOAT_LIB)
    list(APPEND LIBRARIES FFTW::Float c++)
else ()
    message(FATAL "Platform not supported")
endif ()

if (RTL_AIRBAND_NFM)
    add_compile_definitions(NFM)
endif ()

if (RTL_AIRBAND_PULSE)
    add_compile_definitions(PULSE)
    pkg_check_modules(PulseAudio REQUIRED IMPORTED_TARGET libpulse)
    list(APPEND LIBRARIES PkgConfig::PulseAudio)
    list(APPEND SOURCES pulse.cpp)
endif ()

if (RTL_AIRBAND_RTLSDR)
    add_compile_definitions(WITH_RTLSDR)
    pkg_check_modules(RTLSDR REQUIRED IMPORTED_TARGET librtlsdr)
    list(APPEND LIBRARIES PkgConfig::RTLSDR)
    list(APPEND SOURCES input-rtlsdr.cpp input-rtlsdr.h)
endif ()

if (RTL_AIRBAND_MIRISDR)
    add_compile_definitions(WITH_MIRISDR)
    pkg_check_modules(MiriSDR REQUIRED IMPORTED_TARGET libmirisdr)
    list(APPEND LIBRARIES PkgConfig::MiriSDR)
    list(APPEND SOURCES input-mirisdr.cpp input-mirisdr.h)
endif ()

if (RTL_AIRBAND_SOAPYSDR)
    add_compile_definitions(WITH_SOAPYSDR)
    pkg_check_modules(SoapySDR REQUIRED IMPORTED_TARGET SoapySDR)
    list(APPEND LIBRARIES PkgConfig::SoapySDR)
    list(APPEND SOURCES input-soapysdr.cpp input-soapysdr.h)
endif ()

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${RTL_AIRBAND_CFLAGS}")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${RTL_AIRBAND_CFLAGS}")

if (CMAKE_BUILD_TYPE STREQUAL "Debug" OR CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
    add_compile_definitions(DEBUG=1)
else ()
    add_compile_definitions(DEBUG=0)
endif ()

add_compile_definitions(SYSCONFDIR=".")

message(STATUS "    * Narrow FM demodulation:       ${RTL_AIRBAND_NFM}")
message(STATUS "    * PulseAudio server streaming:  ${RTL_AIRBAND_PULSE}")
message(STATUS "    * RTL-SDR support:              ${RTL_AIRBAND_RTLSDR}")
message(STATUS "    * Mirics DVB-T chipset support: ${RTL_AIRBAND_MIRISDR}")
message(STATUS "    * SoapySDR support:             ${RTL_AIRBAND_SOAPYSDR}")

message(STATUS "### Platform:   ${RTL_AIRBAND_PLATFORM}")
message(STATUS "### CFLAGS:     ${CMAKE_C_FLAGS}")
message(STATUS "### SOURCES:    ${SOURCES}")
message(STATUS "### LIBRARIES:  ${LIBRARIES}")

add_executable(rtl_airband ${SOURCES})
target_link_libraries(rtl_airband ${LIBRARIES})
target_compile_options(rtl_airband PRIVATE -O3 -Wall)
