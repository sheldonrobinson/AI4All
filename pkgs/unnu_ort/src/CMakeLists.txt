# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(unnu_ort VERSION 0.0.1 LANGUAGES CXX C)

add_library(unnu_ort SHARED
  "unnu_ort.cxx"
)

set_target_properties(unnu_ort PROPERTIES
  PUBLIC_HEADER unnu_ort.h
  OUTPUT_NAME "unnu_ort"
  CXX_STANDARD 17
)

find_package(Threads REQUIRED)

target_include_directories(unnu_ort PRIVATE
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/ort/include>
)

set(UNNU_ORT_DEPS onnxruntime tokenizers_cpp)

target_compile_definitions(unnu_ort PUBLIC DART_SHARED_LIB)

if(ANDROID)
target_link_libraries(unnu_ort PRIVATE ${UNNU_ORT_DEPS} log Threads::Threads)
else()
target_link_libraries(unnu_ort PRIVATE ${UNNU_ORT_DEPS} Threads::Threads)
endif()

if (ANDROID)
  # Support Android 15 16k page size
  target_link_options(unnu_ort PRIVATE "-Wl,-z,max-page-size=16384")
endif()
