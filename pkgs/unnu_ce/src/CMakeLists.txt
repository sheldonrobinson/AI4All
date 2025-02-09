# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.26)

project(unnu_ce VERSION 0.0.1 LANGUAGES CXX C)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_C_STANDARD_REQUIRED ON)

if(NOT DEFINED CMAKE_INSTALL_PREFIX)
	set(CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_BINARY_DIR}" CACHE PATH "Needed to avoid cmake_install.cmake build issues." FORCE) 
	# set(CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_BINARY_DIR}" PARENT_SCOPE)
	if(NOT DEFINED CMAKE_INSTALL_BINDIR)
		set(CMAKE_INSTALL_BINDIR ${CMAKE_BINARY_DIR}/runner/$<CONFIG>)
		# set(CMAKE_INSTALL_BINDIR ${CMAKE_BINARY_DIR}/bin/$<CONFIG> PARENT_SCOPE)
	endif()
endif()

add_library(unnu_ce SHARED
  "unnu_ce.cxx"
)

set_target_properties(unnu_ce PROPERTIES
  PUBLIC_HEADER unnu_ce.h
  OUTPUT_NAME "unnu_ce"
  CXX_STANDARD 17
)

find_package(Threads REQUIRED)

target_compile_definitions(unnu_ce PUBLIC DART_SHARED_LIB)

# set(UNNU_LIB_DEPS libuv::libuv soar_lib TclSoarLib SQLite3 ort ort-genai nlohmann::json minimal_uuid4)

set(UNNU_LIB_DEPS libuv::libuv soar_lib TclSoarLib SQLite3 ort ort-genai slmengine nlohmann::json minimal_uuid4)

if(ANDROID)
target_link_libraries(unnu_ce PRIVATE ${UNNU_LIB_DEPS} log Threads::Threads)
else()
target_link_libraries(unnu_ce PRIVATE ${UNNU_LIB_DEPS} Threads::Threads)
endif()

if (ANDROID)
  # Support Android 15 16k page size
  target_link_options(unnu_ce PRIVATE "-Wl,-z,max-page-size=16384")
endif()
