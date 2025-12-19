# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(unnu_aux VERSION 0.0.1 LANGUAGES CXX C)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

cmake_policy(SET CMP0079 NEW)

if(NOT DEFINED CMAKE_INSTALL_PREFIX)
	set(CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_BINARY_DIR}" CACHE PATH "Needed to avoid cmake_install.cmake build issues." FORCE) 
	if(NOT DEFINED CMAKE_INSTALL_BINDIR)
		set(CMAKE_INSTALL_BINDIR ${CMAKE_BINARY_DIR}/runner/$<CONFIG>)
	endif()
endif()

add_library(unnu_aux SHARED  "unnu_aux.cxx")
set_target_properties(unnu_aux PROPERTIES
  PUBLIC_HEADER unnu_aux.h
  OUTPUT_NAME "unnu_aux"
  POSITION_INDEPENDENT_CODE True
  CXX_STANDARD 17
)

if(MSVC)
	set_property(TARGET unnu_aux PROPERTY
		MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
endif()

target_compile_definitions(unnu_aux PUBLIC DART_SHARED_LIB)

find_package(Threads REQUIRED)

target_link_libraries(unnu_aux PRIVATE 
							libconfig++
							hashpp
							cpuinfo
							dlib
							yaml-cpp::yaml-cpp
							openblas_shared
							Threads::Threads)

if (ANDROID)
  # Support Android 15 16k page size
  target_link_options(unnu_aux PRIVATE "-Wl,-z,max-page-size=16384")
endif()
