# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.24)

project(unnu_dxp VERSION 0.0.1 LANGUAGES CXX C)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

cmake_policy(SET CMP0079 NEW)

if(NOT DEFINED CMAKE_INSTALL_PREFIX)
	set(CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_BINARY_DIR}" CACHE PATH "Needed to avoid cmake_install.cmake build issues." FORCE) 
	if(NOT DEFINED CMAKE_INSTALL_BINDIR)
		set(CMAKE_INSTALL_BINDIR ${CMAKE_BINARY_DIR}/runner/$<CONFIG>)
	endif()
endif()


add_library(unnu_dxp SHARED unnu_dxp.cpp)
set_target_properties(unnu_dxp PROPERTIES
  PUBLIC_HEADER unnu_dxp.h
  OUTPUT_NAME "unnu_dxp"
  POSITION_INDEPENDENT_CODE True
  CXX_STANDARD 20
)

if(MSVC)
#    target_compile_definitions(unnu_dxl PRIVATE MSVC_BUILD BOOST_USE_WINDOWS_H)
    target_compile_options(unnu_dxp PUBLIC /Zc:__cplusplus /Zc:preprocessor)
endif()

target_compile_definitions(unnu_dxp PUBLIC DART_SHARED_LIB)

find_package(Threads REQUIRED)

target_link_libraries(unnu_dxp PRIVATE 
							liblzma 
							boost_filesystem
							boost_algorithm
							boost_date_time
							docwire
							Threads::Threads)

if (ANDROID)
  # Support Android 15 16k page size
  target_link_options(unnu_dxp PRIVATE "-Wl,-z,max-page-size=16384")
endif()
