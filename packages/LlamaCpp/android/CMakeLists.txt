cmake_minimum_required(VERSION 3.22)

# Project-level configuration.
set(PROJECT_NAME "llamacpp")
project(${PROJECT_NAME} LANGUAGES CXX C)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_POLICY_VERSION_MINIMUM 3.5 PARENT_SCOPE)

if(NOT DEFINED CMAKE_INSTALL_PREFIX)
	set(CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_BINARY_DIR}" CACHE PATH "Needed to avoid cmake_install.cmake build issues." FORCE)
endif()

find_package(Vulkan REQUIRED COMPONENTS glslc)
find_package(OpenMP REQUIRED)

set(CMAKE_BUILD_RPATH_USE_ORIGIN TRUE)
set(LLAMACPP_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../src)

if (UNIX AND NOT WIN32 AND NOT APPLE)
	if (CMAKE_SIZEOF_VOID_P MATCHES "8")
		set (LIB_POSTFIX "64" CACHE STRING "suffix for 32/64 dir placement")
		mark_as_advanced (LIB_POSTFIX)
	endif ()
endif ()

if (NOT DEFINED LIB_POSTFIX)
  set (LIB_POSTFIX "")
endif ()

# Set CMake flags
add_compile_options(-DBUILD_COMMIT=unknown -DBUILD_COMPILER=unknown -DBUILD_TARGET=Android -fvisibility=default -mbranch-protection=standard)
add_link_options("LINKER:--hash-style=gnu,--build-id=none")
set(BUILD_SHARED_LIBS ON)
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
	message("Adding DEBUG compile option")
	add_compile_options(-DDEBUG -D_DEBUG)
endif()

################## cpuinfo settings ###############################
set(CPUINFO_LOG_LEVEL "none" CACHE STRING "Minimum logging level (info with lower severity will be ignored)" FORCE)
set(CPUINFO_LOG_TO_STDIO OFF CACHE BOOL "Log errors, warnings, and information to stdout/stderr" FORCE)
set(CPUINFO_LIBRARY_TYPE "static" CACHE STRING "Type of cpuinfo library (shared, static, or default) to build" FORCE)
set(CPUINFO_BUILD_TOOLS OFF CACHE BOOL "Build command-line tools" FORCE)
set(CPUINFO_BUILD_UNIT_TESTS OFF CACHE BOOL "Build cpuinfo unit tests" FORCE)
set(CPUINFO_BUILD_MOCK_TESTS OFF CACHE BOOL "Build cpuinfo mock tests" FORCE)
set(CPUINFO_BUILD_BENCHMARKS OFF CACHE BOOL "Build cpuinfo micro-benchmarks" FORCE)
set(CPUINFO_BUILD_PKG_CONFIG OFF CACHE BOOL "Build pkg-config manifest" FORCE)

add_subdirectory("${LLAMACPP_SRC_DIR}/cpuinfo" "${CMAKE_CURRENT_BINARY_DIR}/cpuinfo" EXCLUDE_FROM_ALL)
include_directories("${LLAMACPP_SRC_DIR}/cpuinfo/include")

set_target_properties(cpuinfo PROPERTIES
  BUILD_WITH_INSTALL_RPATH TRUE
  PUBLIC_HEADER cpuinfo.h
  OUTPUT_NAME "cpuinfo"
  POSITION_INDEPENDENT_CODE True
)

#################### Vulkan
set(VULKAN_HEADERS_ENABLE_TESTS OFF CACHE BOOL "Test Vulkan-Headers" FORCE)
set(VULKAN_HEADERS_ENABLE_INSTALL OFF CACHE BOOL "Install Vulkan-Headers" FORCE)
# add_subdirectory("${LLAMACPP_SRC_DIR}/Vulkan-Headers" "${CMAKE_CURRENT_BINARY_DIR}/vkheaders" EXCLUDE_FROM_ALL)
include_directories("${LLAMACPP_SRC_DIR}/Vulkan-Headers/include")

##########################  kleidiai
set(KLEIDIAI_BUILD_TESTS       OFF CACHE BOOL "Build unit tests."             FORCE)
set(KLEIDIAI_BUILD_BENCHMARK   OFF CACHE BOOL "Build the benchmark tool."     FORCE)
set(KLEIDIAI_ENABLE_CLANG_TIDY OFF CACHE BOOL "Build with Clang-Tidy checks." FORCE)

# Set the linker flags for shared libraries
set(LLAMA_BUILD_COMMON ON CACHE BOOL "llama: build common utils library" FORCE)
set(LLAMA_CURL         OFF CACHE BOOL "llama: use libcurl to download model from an URL" FORCE)
set(LLAMA_LLGUIDANCE   OFF CACHE BOOL "llama-common: include LLGuidance library for structured output in common utils" FORCE)
# set(GGML_CPU_ARM_ARCH  "armv8-a" CACHE STRING "ggml: CPU architecture for ARM" FORCE)
set(GGML_AVX    OFF CACHE BOOL "ggml: enable AVX" FORCE)
set(GGML_AVX2   OFF CACHE BOOL "ggml: enable AVX2" FORCE)
set(GGML_FMA    OFF CACHE BOOL "ggml: enable FMA" FORCE)
set(GGML_F16C   OFF CACHE BOOL "ggml: enable F16C" FORCE)
set(GGML_NATIVE        OFF CACHE BOOL "ggml: optimize the build for the current system" FORCE)
set(GGML_CPU ON CACHE BOOL "ggml: enable CPU backend" FORCE)
set(GGML_CPU_REPACK    ON CACHE BOOL "ggml: use runtime weight conversion of Q4_0 to Q4_X_X" FORCE)
set(GGML_CPU_KLEIDIAI  ON CACHE BOOL "ggml: use KleidiAI optimized kernels if applicable" FORCE)
set(GGML_OPENMP        ON CACHE BOOL "ggml: use OpenMP" FORCE)
set(GGML_OPENCL        OFF CACHE BOOL "ggml: use OpenCL" FORCE)
set(GGML_VULKAN        ON CACHE BOOL "llama: enable vulkan" FORCE)
set(GGML_BLAS          OFF CACHE BOOL "ggml: use BLAS" FORCE)
set(GGML_LLAMAFILE     OFF CACHE BOOL "ggml: use LLAMAFILE" FORCE)
set(GGML_KOMPUTE       OFF CACHE BOOL "ggml: use Kompute" FORCE)
set(GGML_CUDA          OFF CACHE BOOL "ggml: use CUDA" FORCE)

add_subdirectory("${LLAMACPP_SRC_DIR}/lcpp" "${CMAKE_CURRENT_BINARY_DIR}/llama" EXCLUDE_FROM_ALL)

# add_dependencies(ggml-vulkan Vulkan::Headers)

add_subdirectory("${LLAMACPP_SRC_DIR}" "${CMAKE_BINARY_DIR}/shared")

set(llamacpp_bundled_libraries
  $<TARGET_FILE:llamacpp>
  $<TARGET_FILE:llama>
  $<TARGET_FILE:ggml-vulkan>
  $<TARGET_FILE:ggml-cpu>
  $<TARGET_FILE:ggml-base>
  $<TARGET_FILE:ggml>
#  PARENT_SCOPE
)
