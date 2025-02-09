# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.24)

project(unnu_ragl VERSION 0.0.1 LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_C_STANDARD_REQUIRED ON)
cmake_policy(SET CMP0079 NEW)

if(NOT DEFINED CMAKE_INSTALL_PREFIX)
	set(CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_BINARY_DIR}" CACHE PATH "Needed to avoid cmake_install.cmake build issues." FORCE) 
	if(NOT DEFINED CMAKE_INSTALL_BINDIR)
		set(CMAKE_INSTALL_BINDIR ${CMAKE_BINARY_DIR}/runner/$<CONFIG>)
	endif()
endif()

########################## CTranslate2
if(CMAKE_GENERATOR_PLATFORM MATCHES "^arm64")
    set(ENABLE_CPU_DISPATCH  OFF CACHE BOOL "Compile CPU kernels for multiple ISA and dispatch at runtime" FORCE)
else()
    set(ENABLE_CPU_DISPATCH  ON CACHE BOOL "Compile CPU kernels for multiple ISA and dispatch at runtime" FORCE)
endif()
set(WITH_MKL OFF CACHE BOOL "Compile with Intel MKL backend" FORCE)
set(OPENMP_RUNTIME "COMP" CACHE STRING "OpenMP runtime (INTEL, COMP, NONE)" FORCE)
set(WITH_OPENBLAS ON CACHE BOOL "Compile with OpenBLAS backend" FORCE)
set(BUILD_SHARED_LIBS OFF)
# set(CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_SOURCE_DIR}/dist")

##########################$
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
	include_directories("${CMAKE_BINARY_DIR}" "${CMAKE_BINARY_DIR}/generated")
	add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/OpenBLAS" "${CMAKE_CURRENT_BINARY_DIR}/blas" EXCLUDE_FROM_ALL)
	link_directories(${CMAKE_CURRENT_BINARY_DIR}/blas/lib/$<CONFIG>)
	set(OPENBLAS_INCLUDE_DIR "${CMAKE_CURRENT_BINARY_DIR}/generated")
	set(OPENBLAS_LIBRARY openblas)
endif()

###################### armadillo
set(HEADER_ONLY ON CACHE BOOL "Do not generate the wrapper library" FORCE)
set(OPENBLAS_PROVIDES_LAPACK ON CACHE BOOL "Assume that OpenBLAS provides LAPACK functions" FORCE)
set(STATIC_LIB ON CACHE BOOL "Generate static library instead of shared library" FORCE)
set(BUILD_SMOKE_TEST OFF CACHE BOOL "Build the smoke test" FORCE)
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/armadillo" "${CMAKE_CURRENT_BINARY_DIR}/arma" EXCLUDE_FROM_ALL)

######################### cpuinfo
set(CPUINFO_LOG_LEVEL "fatal" CACHE STRING "Minimum logging level (info with lower severity will be ignored)" FORCE)
# set(CPUINFO_LOG_TO_STDIO OFF CACHE BOOL "Log errors, warnings, and information to stdout/stderr" FORCE)
set(CPUINFO_LIBRARY_TYPE "static" CACHE STRING "Type of cpuinfo library (shared, static, or default) to build" FORCE)
set(CPUINFO_BUILD_TOOLS OFF CACHE BOOL "Build command-line tools" FORCE)
set(CPUINFO_BUILD_UNIT_TESTS OFF CACHE BOOL "Build cpuinfo unit tests" FORCE)
set(CPUINFO_BUILD_MOCK_TESTS OFF CACHE BOOL "Build cpuinfo mock tests" FORCE)
set(CPUINFO_BUILD_BENCHMARKS OFF CACHE BOOL "Build cpuinfo micro-benchmarks" FORCE)
set(CPUINFO_BUILD_PKG_CONFIG OFF CACHE BOOL "Build pkg-config manifest" FORCE)
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/cpuinfo" "${CMAKE_CURRENT_BINARY_DIR}/cpuinfo" EXCLUDE_FROM_ALL)

######################### pthreadpool
set(PTHREADPOOL_LIBRARY_TYPE "static" CACHE STRING "Type of library (shared, static, or default) to build" FORCE)
set(PTHREADPOOL_ALLOW_DEPRECATED_API OFF CACHE BOOL "Enable deprecated API functions" FORCE)
set(PTHREADPOOL_BUILD_TESTS OFF CACHE BOOL "Build pthreadpool unit tests" FORCE)
set(PTHREADPOOL_BUILD_BENCHMARKS OFF CACHE BOOL "Build pthreadpool micro-benchmarks" FORCE)
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/cpuinfo/include")
add_compile_definitions(PTHREADPOOL_USE_CPUINFO=1)
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/pthreadpool" "${CMAKE_CURRENT_BINARY_DIR}/pthreadpool" EXCLUDE_FROM_ALL)

set(BUILD_SHARED_LIBS OFF)
####################### sentencepiece
set(SPM_ENABLE_SHARED OFF CACHE BOOL "Builds shared libaries in addition to static libraries." FORCE)
set(SPM_ENABLE_MSVC_MT_BUILD OFF CACHE BOOL "Use /MT flag in MSVC build" FORCE)
set(SPM_ENABLE_TCMALLOC OFF CACHE BOOL "Enable TCMalloc if available." FORCE)
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/sentencepiece" "${CMAKE_CURRENT_BINARY_DIR}/sentencepiece" EXCLUDE_FROM_ALL)

set(BUILD_SHARED_LIBS ON)
########################## CTranslate2
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/CTranslate2" "${CMAKE_CURRENT_BINARY_DIR}/ct2" EXCLUDE_FROM_ALL)

######################### duckdb
if(CMAKE_GENERATOR_PLATFORM MATCHES "^arm64")
    set(DUCKDB_EXPLICIT_PLATFORM "windows_arm64" CACHE STRING "Set the platform for duckdb" FORCE) 
else()
    set(DUCKDB_EXPLICIT_PLATFORM "windows_amd64" CACHE STRING "Set the platform for duckdb" FORCE)
endif()
set(BUILD_MAIN_DUCKDB_LIBRARY ON CACHE BOOL "Build the main duckdb library and executable." FORCE)
set(BUILD_CLI OFF CACHE BOOL "Compile the clients" FORCE)
set(GENERATE_EXTENSION_ENTRIES ON CACHE BOOL "Build for generating extension_entries.hpp" FORCE)
set(BUILD_UNITTESTS OFF CACHE BOOL "Build the C++ Unit Tests." FORCE)
set(EXTENSION_STATIC_BUILD ON CACHE BOOL "Extension build linking statically with DuckDB. Required for building linux loadable extensions." FORCE)
set(ENABLE_EXTENSION_AUTOLOADING 1 CACHE BOOL "Enable extension auto-loading by default." FORCE)
set(ENABLE_EXTENSION_AUTOINSTALL 1 CACHE BOOL "Enable extension auto-installing by default." FORCE)
set(BUILD_SHELL OFF CACHE BOOL "Build the DuckDB Shell and SQLite API Wrappers" FORCE)

include_directories("${CMAKE_CURRENT_SOURCE_DIR}/duckdb/include" "${CMAKE_CURRENT_BINARY_DIR}/duckdb/codegen/include")
set(INSTALL_INCLUDE_DIR ${CMAKE_CURRENT_BINARY_DIR}/duckdb/codegen/include)
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/duckdb" "${CMAKE_CURRENT_BINARY_DIR}/duckdb" EXCLUDE_FROM_ALL)


set(DUCKDB_EXT_LIBRARIES 
			core_functions_extension 
			fts_extension 
			icu_extension 
			json_extension 
			parquet_extension 
			sqlite_scanner_extension
			vss_extension)
			
set(DUCKDB_3RDPARTY_LIBRARIES
			duckdb_fastpforlib
			duckdb_fmt
			duckdb_fsst
			duckdb_hyperloglog
			duckdb_pg_query
			duckdb_mbedtls
			duckdb_miniz
			duckdb_re2
			duckdb_skiplistlib
			duckdb_utf8proc
			duckdb_yyjson
			duckdb_zstd)

add_library(unnu_ragl SHARED
  "unnu_ragl.cpp"
)

target_link_directories(unnu_ragl PRIVATE 
			${CMAKE_CURRENT_BINARY_DIR}/duckdb/src/$<CONFIG>
			${CMAKE_CURRENT_BINARY_DIR}/duckdb/extension/core_functions/$<CONFIG>
			${CMAKE_CURRENT_BINARY_DIR}/duckdb/extension/icu/$<CONFIG>
			${CMAKE_CURRENT_BINARY_DIR}/duckdb/extension/parquet/$<CONFIG>
			${CMAKE_CURRENT_BINARY_DIR}/duckdb/extension/json/$<CONFIG>
			${CMAKE_CURRENT_BINARY_DIR}/duckdb/extension/fts/$<CONFIG>
			${CMAKE_CURRENT_BINARY_DIR}/duckdb/extension/vss/$<CONFIG>
			${CMAKE_CURRENT_BINARY_DIR}/duckdb/extension/sqlite/$<CONFIG>
			${CMAKE_CURRENT_BINARY_DIR}/duckdb/third_party/fastpforlib/$<CONFIG>
			${CMAKE_CURRENT_BINARY_DIR}/duckdb/third_party/fmt/$<CONFIG>
			${CMAKE_CURRENT_BINARY_DIR}/duckdb/third_party/fsst/$<CONFIG>
			${CMAKE_CURRENT_BINARY_DIR}/duckdb/third_party/hyperloglog/$<CONFIG>
			${CMAKE_CURRENT_BINARY_DIR}/duckdb/third_party/libpg_query/$<CONFIG>
			${CMAKE_CURRENT_BINARY_DIR}/duckdb/third_party/mbedtls/$<CONFIG>
			${CMAKE_CURRENT_BINARY_DIR}/duckdb/third_party/miniz/$<CONFIG>
			${CMAKE_CURRENT_BINARY_DIR}/duckdb/third_party/re2/$<CONFIG>
			${CMAKE_CURRENT_BINARY_DIR}/duckdb/third_party/skiplist/$<CONFIG>
			${CMAKE_CURRENT_BINARY_DIR}/duckdb/third_party/utf8proc/$<CONFIG>
			${CMAKE_CURRENT_BINARY_DIR}/duckdb/third_party/yyjson/$<CONFIG>
			${CMAKE_CURRENT_BINARY_DIR}/duckdb/third_party/zstd/$<CONFIG>
			${CMAKE_CURRENT_BINARY_DIR}/ct2/$<CONFIG>
			${CMAKE_CURRENT_BINARY_DIR}/pthreadpool/$<CONFIG>
			${CMAKE_CURRENT_BINARY_DIR}/sentencepiece/src/$<CONFIG>
			${CMAKE_CURRENT_BINARY_DIR}/cpuinfo/$<CONFIG>
			${CMAKE_CURRENT_BINARY_DIR}/blas/lib/$<CONFIG>
			)

target_include_directories(unnu_ragl PRIVATE 
		$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/pthreadpool/include>
		$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/CTranslate2/include>
		$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/sentencepiece/src>
		$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/cpuinfo/include>
		$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/duckdb/include>
		${CMAKE_CURRENT_BINARY_DIR}/duckdb/codegen/include
		$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/uuid4/include>
		$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/armadillo/include>
		${CMAKE_BINARY_DIR}/generated
		)

set_target_properties(unnu_ragl PROPERTIES
  PUBLIC_HEADER unnu_ragl.h
  OUTPUT_NAME "unnu_ragl"
)

target_compile_definitions(unnu_ragl PUBLIC DART_SHARED_LIB)

set(UNNU_RAG_LITE_DEPS
        openblas
        cpuinfo
        duckdb
        duckdb_static
        ${DUCKDB_EXT_LIBRARIES}
        ${DUCKDB_3RDPARTY_LIBRARIES}
		sentencepiece
		pthreadpool
        ctranslate2)

find_package(Threads REQUIRED)

if(ANDROID)
    target_link_libraries(unnu_ragl PRIVATE log ${UNNU_RAG_LITE_DEPS} Threads::Threads)
else()
    target_link_libraries(unnu_ragl PRIVATE ${UNNU_RAG_LITE_DEPS} Threads::Threads)
endif()

if (ANDROID)
  # Support Android 15 16k page size
  target_link_options(unnu_ragl PRIVATE "-Wl,-z,max-page-size=16384")
endif()
