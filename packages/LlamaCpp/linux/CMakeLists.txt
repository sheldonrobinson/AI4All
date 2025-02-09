# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "llamacpp")
project(${PROJECT_NAME} LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_POLICY_VERSION_MINIMUM 3.5 PARENT_SCOPE)

if(NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_BINARY_DIR}" CACHE PATH "Needed to avoid cmake_install.cmake build issues." FORCE)
endif()


find_package(Vulkan REQUIRED COMPONENTS glslc)
find_package(OpenMP REQUIRED)
find_package(cpuinfo REQUIRED)

# set(CMAKE_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/dist" CACHE STRING "Needed by cpuinfo and duckdb" FORCE)
set(CMAKE_BUILD_RPATH_USE_ORIGIN TRUE)
set(LLAMACPP_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../src)

set(BUILD_SHARED_LIBS ON)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++17 -Wall -Wno-error -fPIC -msse2 -msse -mavx -mavx2 -mfma")

# Set the linker flags for shared libraries
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--build-id=none")

################## llama.cpp settings ###############################
# Set the linker flags for shared libraries
set(LLAMA_BUILD_COMMON ON CACHE BOOL "llama: build common utils library" FORCE)
set(LLAMA_CURL OFF CACHE BOOL "llama: use libcurl to download model from an URL" FORCE)
set(LLAMA_LLGUIDANCE ON CACHE BOOL "llama-common: include LLGuidance library for structured output in common utils" FORCE)
################## ggml settings ###############################
set(GGML_CCACHE ON CACHE BOOL "ggml: use ccache if available" FORCE)
set(GGML_NATIVE OFF CACHE BOOL "ggml: optimize the build for the current system" FORCE)
set(GGML_AVX    ON CACHE BOOL "ggml: enable AVX" FORCE)
set(GGML_AVX2   ON CACHE BOOL "ggml: enable AVX2" FORCE)
set(GGML_FMA   ON CACHE BOOL "ggml: enable FMA" FORCE)
set(GGML_F16C  ON CACHE BOOL "ggml: enable F16C" FORCE)
set(GGML_OPENCL OFF CACHE BOOL "ggml: use OpenCL" FORCE)
set(GGML_OPENMP ON CACHE BOOL "ggml: use OpenMP" FORCE)
set(GGML_VULKAN ON CACHE BOOL "llama: enable vulkan" FORCE)
set(GGML_BLAS OFF CACHE BOOL "ggml: use BLAS" FORCE)
set(GGML_LLAMAFILE OFF CACHE BOOL "ggml: use LLAMAFILE" FORCE)
set(GGML_KOMPUTE  OFF CACHE BOOL "ggml: use Kompute" FORCE)
set(GGML_CUDA  OFF CACHE BOOL "ggml: use CUDA" FORCE)

add_subdirectory("${LLAMACPP_SRC_DIR}/lcpp" "${CMAKE_CURRENT_BINARY_DIR}/llama" EXCLUDE_FROM_ALL)

add_subdirectory("${LLAMACPP_SRC_DIR}" "${CMAKE_BINARY_DIR}/shared")

set(llamacpp_bundled_libraries
    $<TARGET_FILE:llamacpp>
    $<TARGET_FILE:llama>
    $<TARGET_FILE:ggml-vulkan>
    $<TARGET_FILE:ggml-cpu>
    $<TARGET_FILE:ggml-base>
    $<TARGET_FILE:ggml>
    PARENT_SCOPE
)
