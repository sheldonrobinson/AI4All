# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(llamacpp VERSION 1.0.0 LANGUAGES CXX)
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

find_package(Threads REQUIRED)
find_package(OpenMP REQUIRED)

add_library(llamacpp SHARED "llamacpp.cpp")

# add_dependencies(llamacpp infoware_prj-build ggml_prj-build llama_cpp_prj-build)

target_include_directories(llamacpp PRIVATE
	$<BUILD_INTERFACE:${LLAMA_CPP_SOURCE_DIR}/src>)

set_target_properties(llamacpp PROPERTIES
  BUILD_WITH_INSTALL_RPATH TRUE
  LINKER_LANGUAGE CXX
  PUBLIC_HEADER llamacpp.h
  OUTPUT_NAME "llamacpp"
  POSITION_INDEPENDENT_CODE ON
)

if(MSVC)
	set_property(TARGET llamacpp PROPERTY
		MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
endif()

target_compile_definitions(llamacpp PUBLIC DART_SHARED_LIB)

if(ANDROID)
    target_link_libraries(llamacpp PRIVATE log cpuinfo infoware llama common ggml-cpu ggml ggml-base llguidance Threads::Threads)
else()
    target_link_libraries(llamacpp PRIVATE cpuinfo infoware llama common ggml-cpu ggml ggml-base llguidance Threads::Threads)
endif()

if (ANDROID)
  # Support Android 15 16k page size.
  target_link_options(llamacpp PRIVATE "-Wl,-z,max-page-size=16384")
endif()
