# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

# Project-level configuration.
set(PROJECT_NAME "unnu_cognitive_environment")
project(${PROJECT_NAME} LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/dist" CACHE STRING "Needed by cpuinfo and duckdb" FORCE) 
set(UNNU_COG_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../src)

########################## CTranslate2
if(CMAKE_GENERATOR_PLATFORM MATCHES "^arm64")
    set(ENABLE_CPU_DISPATCH  OFF CACHE BOOL "Compile CPU kernels for multiple ISA and dispatch at runtime" FORCE)
else()
    set(ENABLE_CPU_DISPATCH  ON CACHE BOOL "Compile CPU kernels for multiple ISA and dispatch at runtime" FORCE)
endif()
set(WITH_MKL OFF CACHE BOOL "Compile with Intel MKL backend" FORCE)
set(OPENMP_RUNTIME "COMP" CACHE STRING "OpenMP runtime (INTEL, COMP, NONE)" FORCE)
set(WITH_OPENBLAS ON CACHE BOOL "Compile with OpenBLAS backend" FORCE)

if(WITH_OPENBLAS)
	set(BUILD_SHARED_LIBS OFF)
	set(BUILD_STATIC_LIBS ON)
	######################## OpenBLAS
	set(BUILD_WITHOUT_LAPACK OFF CACHE BOOL "Do not build LAPACK and LAPACKE (Only BLAS or CBLAS)" FORCE)
	set(BUILD_TESTING OFF CACHE BOOL "Build LAPACK testsuite when building LAPACK" FORCE)
	# set(BUILD_STATIC_LIBS ON CACHE BOOL "Build static library" FORCE)
	set(USE_OPENMP ON CACHE BOOL "Use compiler OpenMP" FORCE)
	set(NOFORTRAN ON CACHE BOOL "Not using Fortran Compiler" FORCE)
	# set(BUILD_SHARED_LIBS OFF CACHE BOOL "Build shared libraries" FORCE)
	set(C_LAPACK ON CACHE BOOL "Build LAPACK from C sources instead of the original Fortran" FORCE)
	message(ERROR " CMAKE_BINARY_DIR(blas):=${CMAKE_BINARY_DIR}")
	message(ERROR " CMAKE_CURRENT_BINARY_DIR(blas):=${CMAKE_CURRENT_BINARY_DIR}")
	include_directories("${CMAKE_BINARY_DIR}/generated")
	add_subdirectory("${UNNU_COG_SRC_DIR}/OpenBLAS" "${CMAKE_CURRENT_BINARY_DIR}/blas")
	link_directories(${CMAKE_CURRENT_BINARY_DIR}/blas/lib/$<CONFIG>)
	set(OPENBLAS_INCLUDE_DIR "${CMAKE_CURRENT_BINARY_DIR}/generated")
	set(OPENBLAS_LIBRARY openblas)
endif()

set(BUILD_SHARED_LIBS OFF)
####################### sentencepiece
message(ERROR " CMAKE_BINARY_DIR(sp):=${CMAKE_BINARY_DIR}")
message(ERROR " CMAKE_CURRENT_BINARY_DIR(sp):=${CMAKE_CURRENT_BINARY_DIR}")
set(SPM_ENABLE_SHARED OFF CACHE BOOL "Builds shared libaries in addition to static libraries." FORCE)
include_directories("${UNNU_COG_SRC_DIR}/sentencepiece/src" "${CMAKE_CURRENT_BINARY_DIR}/sentencepiece")
add_subdirectory("${UNNU_COG_SRC_DIR}/sentencepiece" "${CMAKE_CURRENT_BINARY_DIR}/sentencepiece")
link_directories(${CMAKE_CURRENT_BINARY_DIR}/sentencepiece/src/$<CONFIG>)

set(BUILD_SHARED_LIBS OFF)
######################### cpuinfo
set(CPUINFO_LOG_LEVEL "fatal" CACHE STRING "Minimum logging level (info with lower severity will be ignored)" FORCE)
# set(CPUINFO_LOG_TO_STDIO OFF CACHE BOOL "Log errors, warnings, and information to stdout/stderr" FORCE)
set(CPUINFO_LIBRARY_TYPE "static" CACHE STRING "Type of cpuinfo library (shared, static, or default) to build" FORCE)
set(CPUINFO_BUILD_TOOLS OFF CACHE BOOL "Build command-line tools" FORCE)
set(CPUINFO_BUILD_UNIT_TESTS OFF CACHE BOOL "Build cpuinfo unit tests" FORCE)
set(CPUINFO_BUILD_MOCK_TESTS OFF CACHE BOOL "Build cpuinfo mock tests" FORCE)
set(CPUINFO_BUILD_BENCHMARKS OFF CACHE BOOL "Build cpuinfo micro-benchmarks" FORCE)
set(CPUINFO_BUILD_PKG_CONFIG OFF CACHE BOOL "Build pkg-config manifest" FORCE)

include_directories("${UNNU_COG_SRC_DIR}/cpuinfo/include")
add_subdirectory("${UNNU_COG_SRC_DIR}/cpuinfo" "${CMAKE_CURRENT_BINARY_DIR}/cpuinfo")
link_directories(${CMAKE_CURRENT_BINARY_DIR}/cpuinfo/$<CONFIG>)

set(BUILD_SHARED_LIBS ON)
########################## CTranslate2
include_directories("${UNNU_COG_SRC_DIR}/CTranslate2/include")
add_subdirectory("${UNNU_COG_SRC_DIR}/CTranslate2" "${CMAKE_CURRENT_BINARY_DIR}/ct2")
link_directories(${CMAKE_CURRENT_BINARY_DIR}/ct2/$<CONFIG>)

# Invoke the build for native code shared with the other target platforms.
# This can be changed to accommodate different builds.
add_subdirectory("${UNNU_COG_SRC_DIR}" "${CMAKE_CURRENT_BINARY_DIR}/shared")


# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(unnu_cognitive_environment_bundled_libraries
  # Defined in ../src/CMakeLists.txt.
  # This can be changed to accommodate different builds.
  $<TARGET_FILE:unnu_cognitive_environment>
  $<TARGET_FILE:ctranslate2>
  PARENT_SCOPE
)
