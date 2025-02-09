# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(llamacpp VERSION 1.0.0 LANGUAGES CXX C)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

find_package(Threads REQUIRED)
find_package(OpenMP REQUIRED)

add_library(llamacpp SHARED "llamacpp.cpp")

target_include_directories(llamacpp PRIVATE
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/lcpp/common>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/lcpp/src>)

set_target_properties(llamacpp PROPERTIES
  BUILD_WITH_INSTALL_RPATH TRUE
  PUBLIC_HEADER llamacpp.h
  OUTPUT_NAME "llamacpp"
  POSITION_INDEPENDENT_CODE True
)

target_compile_definitions(llamacpp PUBLIC DART_SHARED_LIB)

if(ANDROID)
target_link_libraries(llamacpp PRIVATE log cpuinfo ggml llama common Threads::Threads)
else()
target_link_libraries(llamacpp PRIVATE cpuinfo ggml llama common Threads::Threads)
endif()

if (ANDROID)
  # Support Android 15 16k page size.
  target_link_options(llamacpp PRIVATE "-Wl,-z,max-page-size=16384")
endif()
