# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(unnu_ragl VERSION 0.0.1 LANGUAGES CXX)
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

set(INSTALL_INCLUDE_DIR ${DUCKDB_BINARY_DIR}/codegen/include)


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

set_target_properties(unnu_ragl PROPERTIES
  PUBLIC_HEADER unnu_ragl.h
  OUTPUT_NAME "unnu_ragl"
)

target_compile_definitions(unnu_ragl PRIVATE
			BOOST_ALL_NO_LIB
			BOOST_JSON_NO_LIB
			BOOST_CONTAINER_NO_LIB
			BOOST_FILESYSTEM_NO_LIB
			LIBARCHIVE_STATIC
			)

if(MSVC)
	set_property(TARGET unnu_ragl PROPERTY
		MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
endif()

target_compile_definitions(unnu_ragl PUBLIC DART_SHARED_LIB)

target_include_directories(unnu_ragl PRIVATE $<BUILD_INTERFACE:${CTRANSLATE2_BINARY_DIR}>)

set(UNNU_RAG_LITE_DEPS
        boost_uuid
        openblas_shared
        cpuinfo
        duckdb_static
		tbb
		dnnl
		armadillo
		tokenizers_cpp
		sqlite3-shared
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
