# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.24)

# Project-level configuration.
set(PROJECT_NAME "unnu_ragl")
project(${PROJECT_NAME} LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT DEFINED ${CMAKE_INSTALL_PREFIX})
	set(CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_BINARY_DIR}" CACHE PATH "Needed to avoid cmake_install.cmake build issues." FORCE) 
	if(NOT DEFINED ${CMAKE_INSTALL_BINDIR})
		set(CMAKE_INSTALL_BINDIR ${CMAKE_BINARY_DIR}/runner/$<CONFIG>)
	endif()
endif()

set(CMAKE_BUILD_RPATH_USE_ORIGIN TRUE)
set(UNNU_RAG_LITE_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../src)


set(BUILD_SHARED_LIBS OFF)
####################### tokenizers
# set(MSGPACK_CXX17 ON CACHE BOOL "Using c++17 compiler" FORCE)
# set(MSGPACK_USE_BOOST OFF CACHE BOOL "Use Boost libraried" FORCE)
# set(SPM_ENABLE_SHARED OFF CACHE BOOL "Builds shared libaries in addition to static libraries." FORCE)
# set(SPM_ENABLE_MSVC_MT_BUILD ON CACHE BOOL "Use /MT flag in MSVC build" FORCE)
# add_subdirectory("${UNNU_RAG_LITE_SRC_DIR}/tokenizers" "${CMAKE_CURRENT_BINARY_DIR}/tokenizers")



# Invoke the build for native code shared with the other target platforms.
# This can be changed to accommodate different builds.
add_subdirectory("${UNNU_RAG_LITE_SRC_DIR}" "${CMAKE_CURRENT_BINARY_DIR}/shared")

# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(unnu_ragl_bundled_libraries
  # Defined in ../src/CMakeLists.txt.
  # This can be changed to accommodate different builds.
  $<TARGET_FILE:unnu_ragl>
  $<TARGET_FILE:ctranslate2>
  $<TARGET_FILE:duckdb>
  PARENT_SCOPE
)
