# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "unnu_dxl")
project(${PROJECT_NAME} LANGUAGES CXX C)

if(NOT DEFINED CMAKE_INSTALL_PREFIX)
	set(CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_BINARY_DIR}" CACHE PATH "Needed to avoid cmake_install.cmake build issues." FORCE) 
	if(NOT DEFINED CMAKE_INSTALL_BINDIR)
		set(CMAKE_INSTALL_BINDIR ${CMAKE_BINARY_DIR}/runner/$<CONFIG>)
	endif()
endif()


set(CMAKE_BUILD_RPATH_USE_ORIGIN TRUE)
set(UNNU_DOCPARSER_LITE_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../src)

if (UNIX AND NOT WIN32 AND NOT APPLE)
	if (CMAKE_SIZEOF_VOID_P MATCHES "8")
		set (LIB_POSTFIX "64" CACHE STRING "suffix for 32/64 dir placement")
		mark_as_advanced (LIB_POSTFIX)
	endif ()
endif ()
if (MSVC)
	add_definitions (-D_CRT_SECURE_NO_WARNINGS)
endif()
if (NOT DEFINED LIB_POSTFIX)
  set (LIB_POSTFIX "")
endif ()

if(DEFINED CMAKE_BUILD_TYPE)
	string(TOLOWER ${CMAKE_BUILD_TYPE} build_type)
	if (build_type STREQUAL "debug" OR build_type STREQUAL "relwithdebinfo")
		if (MSVC)
		  add_compile_options(/bigobj)
		else ()
		  add_compile_options(-Wa,-mbig-obj)
		endif ()
	endif()
endif()

# Invoke the build for native code shared with the other target platforms.
# This can be changed to accommodate different builds.
add_subdirectory("${UNNU_DOCPARSER_LITE_SRC_DIR}" "${CMAKE_CURRENT_BINARY_DIR}/shared")

set_target_properties(unnu_dxl PROPERTIES
  BUILD_WITH_INSTALL_RPATH TRUE
)

# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(unnu_dxl_bundled_libraries
  # Defined in ../src/CMakeLists.txt.
  # This can be changed to accommodate different builds.
  $<TARGET_FILE:unnu_dxl>
  PARENT_SCOPE
)
