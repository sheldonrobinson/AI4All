# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(unnu_dxl VERSION 0.0.1 LANGUAGES CXX C)
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

##################### docwire-lite
file(GLOB_RECURSE dxl_srcs
				  docwire_lite/src/*.cpp 
				  )

add_library(dxl ${dxl_srcs} $<TARGET_OBJECTS:xpdf_objs> $<TARGET_OBJECTS:fofi_objs>  $<TARGET_OBJECTS:goo_objs>)
set_property(TARGET dxl PROPERTY
  POSITION_INDEPENDENT_CODE True)

if(MSVC)
	set_property(TARGET dxl PROPERTY
		MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
	target_compile_options(dxl PUBLIC /Zc:__cplusplus /Zc:preprocessor)	
	target_compile_definitions(dxl PRIVATE MSVC_BUILD BOOST_USE_WINDOWS_H)
endif()

include(GenerateExportHeader)
generate_export_header(dxl 
		EXPORT_MACRO_NAME DOCWIRE_CORE_EXPORT 
		EXPORT_FILE_NAME core_export.h)
		
target_compile_features(dxl PUBLIC cxx_std_20)

target_link_libraries(dxl	PUBLIC
							archive_static 
							zlibstatic 
							libminizipstatic
							png_static
							freetype
							xlsxwriter 
							duckx::duckx
							libmagic
							magic_enum
							dlib
							pcre2-posix-static
							boost_filesystem
							boost_algorithm
							boost_date_time
							boost_dll
							boost_json
							# libxpdf
						)

target_include_directories(dxl PRIVATE
	${CMAKE_CURRENT_BINARY_DIR}
	${XPDF_BINARY_DIR}
	${XPDF_INCLUDE_DIR}
	${XPDF_SOURCE_DIR}/fofi
	${XPDF_SOURCE_DIR}/goo
	${XPDF_SOURCE_DIR}/splash
	${DUCKX_INCLUDE_DIR}
	)

target_compile_definitions(dxl PRIVATE
			DOCWIRE_ENABLE_SHORT_MACRO_NAMES
			docwire_lite_EXPORTS
			BOOST_ALL_NO_LIB
			BOOST_JSON_NO_LIB
			BOOST_CONTAINER_NO_LIB
			BOOST_FILESYSTEM_NO_LIB
			LIBARCHIVE_STATIC
			)
			
if(CMAKE_SYSTEM_PROCESSOR STREQUAL "x64")
	target_compile_definitions(dxl PUBLIC
				BOOST_UUID_USE_SSE2
				BOOST_UUID_USE_SSE3
				BOOST_UUID_USE_SSE41
				BOOST_UUID_USE_AVX
				)
endif()

if(MSVC)
#    target_compile_definitions(docwire_lite_objs PRIVATE MSVC_BUILD BOOST_USE_WINDOWS_H)
    
endif()

add_library(unnu_dxl SHARED unnu_dxl.cpp)
set_target_properties(unnu_dxl PROPERTIES
  PUBLIC_HEADER unnu_dxl.h
  OUTPUT_NAME "unnu_dxl"
  POSITION_INDEPENDENT_CODE True
  CXX_STANDARD 20
)

if(MSVC)
	set_property(TARGET unnu_dxl PROPERTY
		MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
endif()

target_include_directories(unnu_dxl PRIVATE 
		${CMAKE_CURRENT_BINARY_DIR}
		$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/docwire_lite/src>)

if(MSVC)
	target_compile_options(unnu_dxl PUBLIC /Zc:__cplusplus /Zc:preprocessor)	
endif()

target_compile_definitions(unnu_dxl PUBLIC DART_SHARED_LIB)

find_package(Threads REQUIRED)

target_link_libraries(unnu_dxl PRIVATE 
							libminizipstatic
							boost_filesystem
							boost_algorithm
							boost_date_time
							dxl
							archive_static
							Threads::Threads)

if (ANDROID)
  # Support Android 15 16k page size
  target_link_options(unnu_dxl PRIVATE "-Wl,-z,max-page-size=16384")
endif()
