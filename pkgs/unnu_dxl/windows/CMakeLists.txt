# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "unnu_dxl")
project(${PROJECT_NAME} LANGUAGES CXX C)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT DEFINED CMAKE_INSTALL_PREFIX)
 	set(CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_BINARY_DIR}" CACHE PATH "Needed to avoid cmake_install.cmake build issues." FORCE) 
endif()

set(CMAKE_BUILD_RPATH_USE_ORIGIN TRUE)
set(UNNU_DOCPARSER_LITE_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../src)

if (MSVC)
  add_compile_options($<$<CONFIG:Debug>:/bigobj>)
else ()
  add_compile_options($<$<CONFIG:Debug>:-Wa,-mbig-obj>)
endif ()

if (UNIX AND NOT WIN32 AND NOT APPLE)
	if (CMAKE_SIZEOF_VOID_P MATCHES "8")
		set (LIB_POSTFIX "64" CACHE STRING "suffix for 32/64 dir placement")
		mark_as_advanced (LIB_POSTFIX)
	endif ()
endif ()

if (NOT DEFINED LIB_POSTFIX)
  set (LIB_POSTFIX "")
endif()

if(MSVC)
	add_compile_definitions(_CRT_SECURE_NO_WARNINGS NOMINMAX)
	add_compile_options(/EHsc)
	set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
	set(CMAKE_INSTALL_UCRT_LIBRARIES ON)
	set(CMAKE_INSTALL_OPENMP_LIBRARIES ON)
	file(REAL_PATH ${CMAKE_BINARY_DIR}/runner/$<CONFIG> FLUTTER_APP_DIR)
	set(CMAKE_INSTALL_SYSTEM_RUNTIME_DESTINATION ${FLUTTER_APP_DIR})
endif()

include(FetchContent)
include(ExternalProject)
include(InstallRequiredSystemLibraries)

find_package(OpenMP REQUIRED)

######################## libarchive
FetchContent_Declare(
  libarchive
  GIT_REPOSITORY https://github.com/sheldonrobinson/libarchive.git
  GIT_TAG        origin/unnu_aux
  GIT_SHALLOW    TRUE
  
  EXCLUDE_FROM_ALL
			 
  OVERRIDE_FIND_PACKAGE
)

######################## libxml2
FetchContent_Declare(
  libxml2
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/libxml2.git
  GIT_TAG        		 origin/master
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL

  OVERRIDE_FIND_PACKAGE
)

####################### file_windows
FetchContent_Declare(
  file-windows
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/file-windows.git
  GIT_TAG        		 origin/master
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL

)

######################## pcre2posix
FetchContent_Declare(
  pcre2posix
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/pcre2.git
  GIT_TAG        		 origin/master
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL

  OVERRIDE_FIND_PACKAGE			 
)

######################## boost
FetchContent_Declare(
  boost
  GIT_REPOSITORY 		 https://github.com/boostorg/boost.git
  GIT_TAG        		 boost-1.88.0
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL
			 
  OVERRIDE_FIND_PACKAGE
)

####################### xpdf
# https://dl.xpdfreader.com/xpdf-4.05.tar.gz URL_HASH SHA256=92707ed5acb6584fbd73f34091fda91365654ded1f31ba72f0970022cf2a5cea
FetchContent_Declare(
  xpdf
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/xpdf.git
  GIT_TAG        		 origin/main
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL
			 
  OVERRIDE_FIND_PACKAGE
			 
)

####################### FreeType
FetchContent_Declare(
  freetype
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/freetype.git
  GIT_TAG        		 origin/build
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL

  OVERRIDE_FIND_PACKAGE
)

####################### libpng
FetchContent_Declare(
  png
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/libpng.git
  GIT_TAG        		 origin/libpng16
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL

  OVERRIDE_FIND_PACKAGE
)

######################## libxlsxwriter
FetchContent_Declare(
  libxlsxwriter
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/libxlsxwriter.git
  GIT_TAG        		 origin/main
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL
  
  CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=ON
			 -DUSE_SYSTEM_MINIZIP:BOOL=ON
			 -DUSE_STANDARD_TMPFILE:BOOL=OFF
			 -DUSE_OPENSSL_MD5:BOOL=OFF
			 -DUSE_DTOA_LIBRARY:BOOL=ON
			 -DUSE_MEM_FILE:BOOL=OFF
			 -DBUILD_TESTS:BOOL=OFF
			 -DBUILD_EXAMPLES:BOOL=OFF
			 -DBUILD_FUZZERS:BOOL=OFF
)


####################### zlib
FetchContent_Declare(
  zlib
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/zlib.git
  GIT_TAG        		 origin/develop
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL
			 
  OVERRIDE_FIND_PACKAGE

)

######################## bzip2
FetchContent_Declare(
  bzip2
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/bzip2.git
  GIT_TAG        		 origin/master
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL
			 
  OVERRIDE_FIND_PACKAGE
			 
)

set(BZIP2_ENABLE_LIB_ONLY ON CACHE BOOL "Build libbz2 only.  This is a short hand for -DENABLE_APP=0 -DENABLE_EXAMPLES=0" FORCE)
set(BZIP2_ENABLE_STATIC_LIB ON CACHE BOOL "Build libbz2 in static mode also" FORCE)
set(BZIP2_ENABLE_SHARED_LIB OFF CACHE BOOL "Build libbz2 as a shared library" FORCE)
set(BZIP2_ENABLE_INSTALL OFF CACHE BOOL "Install applications and library" FORCE)
set(ENABLE_APP OFF CACHE BOOL "Build applications (bzip2, and bzip2recover)" FORCE)
set(ENABLE_WERROR OFF CACHE BOOL "Turn on compile time warnings" FORCE)
set(ENABLE_DOCS OFF CACHE BOOL "Generate documentation" FORCE)
set(ENABLE_EXAMPLES OFF CACHE BOOL "Build examples" FORCE)
set(USE_OLD_SONAME OFF CACHE BOOL "Use libbz2.so.1.0 for compatibility with old Makefiles" FORCE)

FetchContent_MakeAvailable(bzip2)

file(REAL_PATH ${bzip2_SOURCE_DIR} BZIP2_INCLUDE_DIR)
file(REAL_PATH ${bzip2_SOURCE_DIR} BZIP2_SOURCE_DIR)
file(REAL_PATH ${bzip2_BINARY_DIR} BZIP2_BINARY_DIR)

set(BZIP2_LIBRARY ${BZIP2_BINARY_DIR}/$<CONFIG>/bz2_static.lib CACHE FILEPATH "bzip2 library" FORCE)
set(BZIP2_LIBRARIES ${BZIP2_BINARY_DIR}/$<CONFIG>/bz2_static.lib CACHE STRING "bzip2 libraries" FORCE)

if(NOT TARGET BZip2::BZip2)
	add_library(BZip2::BZip2 INTERFACE IMPORTED)
    set_target_properties(BZip2::BZip2 PROPERTIES
                          INTERFACE_LINK_LIBRARIES 
							  bz2_static
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						  )
endif()

####################### zlib cont

set(ZLIB_BUILD_TESTING "none" CACHE STRING "Enable Zlib Examples as tests" FORCE)
set(ZLIB_BUILD_SHARED OFF CACHE BOOL "Enable building zlib shared library" FORCE)
set(ZLIB_BUILD_STATIC ON CACHE BOOL "Enable building zlib static library" FORCE)
set(ZLIB_BUILD_MINIZIP ON CACHE BOOL "Enable building libminizip contrib library" FORCE)
set(ZLIB_INSTALL OFF CACHE BOOL "Enable installation of zlib" FORCE)
set(ZLIB_BUILD_EXAMPLES OFF CACHE BOOL "Enable Zlib Examples" FORCE)

####################### minizip
set(MINIZIP_BUILD_SHARED OFF CACHE BOOL "Enable building minizip shared library" FORCE)
set(MINIZIP_BUILD_STATIC ON CACHE BOOL "Enable building minizip static library" FORCE)
set(MINIZIP_BUILD_TESTING OFF CACHE BOOL "Enable testing of minizip" FORCE)
set(MINIZIP_ENABLE_BZIP2 ON CACHE BOOL "Build minizip withj bzip2 support" FORCE)
set(MINIZIP_INSTALL OFF CACHE BOOL "Enable installation of minizip" FORCE)

FetchContent_MakeAvailable(zlib bzip2)

file(REAL_PATH ${zlib_SOURCE_DIR} ZLIB_INCLUDE_DIR)
file(REAL_PATH ${zlib_SOURCE_DIR} ZLIB_SOURCE_DIR)
file(REAL_PATH ${zlib_BINARY_DIR} ZLIB_BINARY_DIR)

set(ZLIB_LIBRARY ${ZLIB_BINARY_DIR}/$<CONFIG>/zs$<$<CONFIG:Debug>:d>.lib CACHE FILEPATH "zlib library" FORCE)

set(MINIZIP_LIBRARY ${ZLIB_BINARY_DIR}/$<CONFIG>/minizips$<$<CONFIG:Debug>:d>.lib CACHE FILEPATH "minizip library" FORCE)

if(NOT TARGET ZLIB::ZLIB)
	add_library(ZLIB::ZLIB INTERFACE IMPORTED)
    set_target_properties(ZLIB::ZLIB PROPERTIES
                          INTERFACE_LINK_LIBRARIES
							zlibstatic
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
							)
	target_include_directories(ZLIB::ZLIB INTERFACE 
						$<BUILD_INTERFACE:${ZLIB_INCLUDE_DIR}>
						$<BUILD_INTERFACE:${ZLIB_BINARY_DIR}>
						)
	target_link_libraries(ZLIB::ZLIB INTERFACE $<BUILD_INTERFACE:${ZLIB_LIBRARY}>)
endif()

if(NOT TARGET unofficial::minizip::minizip)
	add_library(unofficial::minizip::minizip INTERFACE IMPORTED)
    set_target_properties(unofficial::minizip::minizip PROPERTIES
                          INTERFACE_LINK_LIBRARIES
							libminizipstatic zlibstatic bz2_static
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						 )
endif()

add_dependencies(zlibstatic bz2_static)

add_dependencies(libminizipstatic zlibstatic bz2_static)

######################## libxlsxwriter cont
set(XLW_INSTALL OFF CACHE INTERNAL "Install applications and library" FORCE)

FetchContent_MakeAvailable(libxlsxwriter zlib)

target_include_directories(xlsxwriter PRIVATE ${ZLIB_INCLUDE_DIR}/contrib/minzip ${ZLIB_BINARY_DIR} ${ZLIB_INCLUDE_DIR} ${BZIP2_INCLUDE_DIR} ${BZIP2_BINARY_DIR})
add_dependencies(xlsxwriter libminizipstatic  zlibstatic bz2_static)

file(REAL_PATH ${libxlsxwriter_SOURCE_DIR} XLSXWRITER_INCLUDE_DIR)
file(REAL_PATH ${libxlsxwriter_SOURCE_DIR} XLSXWRITER_SOURCE_DIR)
file(REAL_PATH ${libxlsxwriter_BINARY_DIR} XLSXWRITER_BINARY_DIR)

####################### libpng cont
set(PNG_SHARED OFF CACHE BOOL "Build libpng as a shared library" FORCE)
set(PNG_STATIC  ON CACHE BOOL "Build libpng as a static library" FORCE)
set(PNG_TESTS OFF CACHE BOOL "Build the libpng tests" FORCE)
set(PNG_TOOLS OFF CACHE BOOL "Build the libpng tools" FORCE)
set(PNG_HARDWARE_OPTIMIZATIONS  ON CACHE BOOL "Enable hardware optimizations" FORCE)
set(PNG_INSTALL OFF CACHE BOOL "Install applications and library" FORCE)

FetchContent_MakeAvailable(png zlib)

target_include_directories(png_static PRIVATE ${ZLIB_BINARY_DIR})
add_dependencies(png_static zlibstatic)

file(REAL_PATH ${png_SOURCE_DIR} PNG_INCLUDE_DIR)
file(REAL_PATH ${png_SOURCE_DIR} PNG_SOURCE_DIR)
file(REAL_PATH ${png_BINARY_DIR} PNG_BINARY_DIR)

set(PNG_LIBRARY ${PNG_BINARY_DIR}/$<CONFIG>/libpng16_static$<$<CONFIG:Debug>:d>.lib CACHE FILEPATH "libpng library" FORCE)

set(PNG_INCLUDE_DIRS ${PNG_INCLUDE_DIR} ${PNG_BINARY_DIR})

set(PNG_LIBRARIES ${PNG_LIBRARY})

if(NOT TARGET PNG)
	add_library(PNG INTERFACE IMPORTED)
    set_target_properties(PNG PROPERTIES
                          INTERFACE_LINK_LIBRARIES
						    png_static
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						 )
endif()

####################### harbuzz
FetchContent_Declare(
  harfbuzz
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/harfbuzz.git
  GIT_TAG        		 origin/main
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL
  
  OVERRIDE_FIND_PACKAGE
)

set(HB_HAVE_CAIRO OFF CACHE BOOL "Enable cairo interop helpers" FORCE)
set(HB_HAVE_FREETYPE OFF CACHE BOOL "Enable freetype interop helpers" FORCE)
set(HB_HAVE_GRAPHITE2 OFF CACHE BOOL "Enable Graphite2 complementary shaper" FORCE)
set(HB_HAVE_GLIB OFF CACHE BOOL "Enable glib unicode functions" FORCE)
set(HB_HAVE_ICU OFF CACHE BOOL "Enable icu unicode functions" FORCE)
set(HB_BUILD_SUBSET  ON CACHE BOOL "Build harfbuzz-subset" FORCE)
set(HB_HAVE_GOBJECT OFF CACHE BOOL "Enable GObject Bindings" FORCE)
set(HB_HAVE_INTROSPECTIONHB_HAVE_INTROSPECTION OFF CACHE BOOL "Enable building introspection (.gir/.typelib) files" FORCE)
set(HB_INSTALL OFF CACHE BOOL "Install applications and library" FORCE)

FetchContent_MakeAvailable(harfbuzz)

file(REAL_PATH ${harfbuzz_SOURCE_DIR}/src HarfBuzz_INCLUDE_DIR)
file(REAL_PATH ${harfbuzz_SOURCE_DIR} HarfBuzz_SOURCE_DIR)
file(REAL_PATH ${harfbuzz_BINARY_DIR} HarfBuzz_BINARY_DIR)


set(HarfBuzz_LIBRARY ${HarfBuzz_BINARY_DIR}/$<CONFIG>/harfbuzz.lib CACHE FILEPATH "harfbuzz library" FORCE)
set(HarfBuzz_INCLUDE_DIRS "${HarfBuzz_BINARY_DIR}/src" CACHE STRING "harfbuzz include directories" FORCE)
set(HarfBuzz_LIBRARIES "${HarfBuzz_BINARY_DIR}/$<CONFIG>/harfbuzz-subset.lib" CACHE STRING "harfbuzz modules" FORCE)

####################### FreeType cont

set(FT_DISABLE_ZLIB OFF CACHE BOOL "Disable use of system zlib and use internal zlib library instead." FORCE)
set(FT_DISABLE_BZIP2 OFF CACHE BOOL "Disable support of bzip2 compressed fonts." FORCE)
set(FT_DISABLE_PNG OFF CACHE BOOL "Disable support of PNG compressed OpenType embedded bitmaps." FORCE)
set(FT_DISABLE_HARFBUZZ  ON CACHE BOOL "Disable HarfBuzz (used for improving auto-hinting of OpenType fonts)." FORCE)
set(FT_DISABLE_BROTLI  ON CACHE BOOL "Disable support of compressed WOFF2 fonts." FORCE)
set(FT_ENABLE_ERROR_STRINGS OFF CACHE BOOL "Enable support for meaningful error descriptions." FORCE)
set(FT_INSTALL OFF CACHE BOOL "Install applications and library" FORCE)

FetchContent_MakeAvailable(freetype png zlib bzip2 harfbuzz)

target_include_directories(freetype PRIVATE ${PNG_SOURCE_DIR} ${PNG_BINARY_DIR} ${HarfBuzz_BINARY_DIR}/src ${BZIP2_SOURCE_DIR} ${BZIP2_BINARY_DIR} ${ZLIB_SOURCE_DIR} ${ZLIB_BINARY_DIR})
add_dependencies(freetype png_static harfbuzz zlibstatic bz2_static)

file(REAL_PATH ${freetype_SOURCE_DIR}/include FREETYPE_INCLUDE_DIR)
file(REAL_PATH ${freetype_SOURCE_DIR} FREETYPE_SOURCE_DIR)
file(REAL_PATH ${freetype_BINARY_DIR} FREETYPE_BINARY_DIR)

set(FREETYPE_LIBRARY ${FREETYPE_BINARY_DIR}/$<CONFIG>/freetype.lib CACHE FILEPATH "freetype library" FORCE)

####################### xpdf cont
set(A4_PAPER OFF CACHE BOOL "use A4 (instead of Letter) paper size by default for PostScript output" FORCE)
set(NO_TEXT_SELECT ON CACHE BOOL "do not allow text selection" FORCE)
set(OPI_SUPPORT OFF CACHE BOOL "include support for OPI comments" FORCE)
set(MULTITHREADED ON CACHE BOOL "include support for multithreading" FORCE)
set(USE_EXCEPTIONS ON CACHE BOOL "use C++ exceptions" FORCE)
set(USE_FIXEDPOINT OFF CACHE BOOL "use fixed point (instead of floating point) arithmetic" FORCE)
set(SPLASH_CMYK OFF CACHE BOOL "include support for CMYK rasterization" FORCE)
set(NO_FONTCONFIG ON CACHE BOOL "disable support for libfontconfig" FORCE)

set(XPDFWIDGET_PRINTING OFF CACHE BOOL "include printing support in XpdfWidget" FORCE)
set(PNG_INCLUDE_DIRS ${CMAKE_CURRENT_BINARY_DIR}/include CACHE PATH "libpng include dir" FORCE)
set(XPDF_INSTALL OFF CACHE BOOL "Install applications and library" FORCE)
set(CMAKE_DISABLE_FIND_PACKAGE_Qt4  ON CACHE BOOL "Prevent lookup of Qt4" FORCE)
set(CMAKE_DISABLE_FIND_PACKAGE_Qt5Widgets  ON CACHE BOOL "Prevent lookup of Qt5" FORCE)
set(ENABLE_LIBXPDF  ON CACHE BOOL "Setup to build libxpdf" FORCE)

set(PNG_INCLUDE_DIRS ${PNG_BINARY_DIR})

FetchContent_MakeAvailable(zlib png file-windows freetype xpdf)

file(REAL_PATH ${xpdf_SOURCE_DIR}/xpdf XPDF_INCLUDE_DIR)
file(REAL_PATH ${xpdf_SOURCE_DIR} XPDF_SOURCE_DIR)
file(REAL_PATH ${xpdf_BINARY_DIR} XPDF_BINARY_DIR)

target_include_directories(xpdf_objs
	INTERFACE 
		$<BUILD_INTERFACE:${FREETYPE_BINARY_DIR}/include>
		$<BUILD_INTERFACE:${FREETYPE_SOURCE_DIR}/include>
		$<BUILD_INTERFACE:${XPDF_SOURCE_DIR}/fofi>
		$<BUILD_INTERFACE:${XPDF_SOURCE_DIR}/goo>
		$<BUILD_INTERFACE:${XPDF_SOURCE_DIR}/splash>
		$<BUILD_INTERFACE:${LIBMAGIC_INCLUDE_DIR}>
		$<BUILD_INTERFACE:${PNG_INCLUDE_DIR}>
		$<BUILD_INTERFACE:${PNG_BINARY_DIR}>
		$<BUILD_INTERFACE:${ZLIB_INCLUDE_DIR}>
		$<BUILD_INTERFACE:${ZLIB_BINARY_DIR}>
	)
add_dependencies(xpdf_objs libmagic freetype png_static zlibstatic)

set_property(TARGET goo_objs PROPERTY
  POSITION_INDEPENDENT_CODE True)
if(MSVC)
	set_property(TARGET goo_objs PROPERTY
		MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
endif()

set_property(TARGET fofi_objs PROPERTY
  POSITION_INDEPENDENT_CODE True)
if(MSVC)
	set_property(TARGET fofi_objs PROPERTY
		MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
endif()

set_property(TARGET xpdf_objs PROPERTY
  POSITION_INDEPENDENT_CODE True)
if(MSVC)
	set_property(TARGET xpdf_objs PROPERTY
		MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
endif()


####################### dirent
FetchContent_Declare(
  dirent
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/dirent.git
  GIT_TAG        		 origin/master
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL

  OVERRIDE_FIND_PACKAGE
)

set(DIRENT_INSTALL OFF CACHE INTERNAL "Install applications and library" FORCE)

FetchContent_MakeAvailable(dirent)

file(REAL_PATH ${dirent_SOURCE_DIR}/include DIRENT_INCLUDE_DIR)
file(REAL_PATH ${dirent_SOURCE_DIR} DIRENT_SOURCE_DIR)

######################## pcre2posix cont
set(PCRE2_STATIC_PIC ON CACHE BOOL "Build the static library with the option position independent code enabled." FORCE)
set(PCRE2_SHOW_REPORT ON CACHE BOOL "Show the final configuration report" FORCE)
set(PCRE2_BUILD_PCRE2GREP OFF CACHE BOOL "Build pcre2grep" FORCE)
set(PCRE2_BUILD_TESTS OFF CACHE BOOL "Build the tests" FORCE)
set(PCRE2_SUPPORT_LIBEDIT OFF CACHE BOOL "Enable support for linking pcre2test with libedit." FORCE)
set(PCRE2_SUPPORT_LIBREADLINE OFF CACHE BOOL "Enable support for linking pcre2test with libreadline." FORCE)
set(PCRE2_BUILD_PCRE2_8 ON CACHE BOOL "Build 8 bit PCRE2 library" FORCE)
set(PCRE2_BUILD_PCRE2_16 OFF CACHE BOOL "Build 16 bit PCRE2 library" FORCE)
set(PCRE2_BUILD_PCRE2_32 OFF CACHE BOOL "Build 32 bit PCRE2 library" FORCE)
set(PCRE2_INSTALL OFF CACHE BOOL "Install applications and library" FORCE)

FetchContent_MakeAvailable(pcre2posix zlib bzip2)

target_include_directories(pcre2-posix-static PRIVATE ${BZIP2_BINARY_DIR} ${ZLIB_BINARY_DIR})
add_dependencies(pcre2-posix-static zlibstatic bz2_static)

file(REAL_PATH ${pcre2posix_SOURCE_DIR}/src PCRE2POSIX_INCLUDE_DIR)
file(REAL_PATH ${pcre2posix_SOURCE_DIR} PCRE2POSIX_SOURCE_DIR)
file(REAL_PATH ${pcre2posix_BINARY_DIR} PCRE2POSIX_BINARY_DIR)

set(PCRE2_LIBRARY ${PCRE2POSIX_BINARY_DIR}/$<CONFIG>/pcre2-posix-static$<$<CONFIG:Debug>:d>.lib CACHE FILEPATH "pcre2posix library" FORCE)

####################### file_windows cont
FetchContent_MakeAvailable(file-windows pcre2posix dirent)

target_include_directories(libmagic
							PRIVATE
								$<BUILD_INTERFACE:${PCRE2POSIX_INCLUDE_DIR}>
								$<BUILD_INTERFACE:${PCRE2POSIX_BINARY_DIR}>
								$<BUILD_INTERFACE:${DIRENT_INCLUDE_DIR}>
						  )

add_dependencies(libmagic pcre2-posix-static dirent)

file(REAL_PATH ${file-windows_BINARY_DIR}/libmagic-src/src LIBMAGIC_INCLUDE_DIR)
file(REAL_PATH ${file-windows_BINARY_DIR}/libmagic-src LIBMAGIC_SOURCE_DIR)
file(REAL_PATH ${file-windows_BINARY_DIR}/libmagic-build LIBMAGIC_BINARY_DIR)

set(LIGMAGIC_LIBRARY ${LIBMAGIC_BINARY_DIR}/$<CONFIG>/libmagic.lib CACHE FILEPATH "libmagic library" FORCE)

if(NOT TARGET unofficial::libmagic::libmagic)
	add_library(unofficial::libmagic::libmagic INTERFACE IMPORTED)
    set_target_properties(unofficial::libmagic::libmagic PROPERTIES
                          INTERFACE_LINK_LIBRARIES
						    libmagic pcre2-posix-static dirent
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
							)
endif()

######################## xz
FetchContent_Declare(
  liblzma
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/xz.git
  GIT_TAG        		 origin/master
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL
  
  OVERRIDE_FIND_PACKAGE
)

set(XZ_NLS OFF CACHE BOOL "Native Language Support (translated messages and man pages)" FORCE)
set(XZ_SMALL OFF CACHE BOOL "Reduce code size at expense of speed. This may be useful together with CMAKE_BUILD_TYPE=MinSizeRel." FORCE)
set(XZ_MICROLZMA_ENCODER ON CACHE BOOL "MicroLZMA encoder (needed by specific applications only)" FORCE)
set(XZ_MICROLZMA_DECODER ON CACHE BOOL "MicroLZMA decoder (needed by specific applications only)" FORCE)
set(XZ_LZIP_DECODER ON CACHE BOOL "Support lzip decoder" FORCE)
set(XZ_EXTERNAL_SHA256 OFF CACHE BOOL "Use SHA-256 code from the operating system if possible. See INSTALL for possible subtle problems." FORCE)
set(XZ_TOOL_XZDEC OFF CACHE BOOL "Build and install the xzdec command line tool" FORCE)
set(XZ_TOOL_LZMADEC OFF CACHE BOOL "Build and install the lzmadec command line tool" FORCE)
set(XZ_TOOL_LZMAINFO OFF CACHE BOOL "Build and install the lzmainfo command line tool" FORCE)
set(XZ_TOOL_XZ OFF CACHE BOOL "Build and install the xz command line tool" FORCE)
set(XZ_DOC OFF CACHE BOOL "Install basic documentation, examples, and license files" FORCE)
set(XZ_ENABLE_INSTALL OFF CACHE BOOL "Install applications and library" FORCE)
set(BUILD_TESTING OFF CACHE BOOL "Disable test applications and library" FORCE)


FetchContent_MakeAvailable(liblzma)

file(REAL_PATH ${liblzma_SOURCE_DIR}/src/liblzma/api LibLZMA_INCLUDE_DIR)
file(REAL_PATH ${liblzma_SOURCE_DIR} LibLZMA_SOURCE_DIR)
file(REAL_PATH ${liblzma_BINARY_DIR} LibLZMA_BINARY_DIR)

set(LibLZMA_LIBRARY ${LibLZMA_BINARY_DIR}/$<CONFIG>/lzma.lib CACHE FILEPATH "liblzma library" FORCE)

if(NOT TARGET LibLZMA::LibLZMA)
	add_library(LibLZMA::LibLZMA INTERFACE IMPORTED)
    set_target_properties(LibLZMA::LibLZMA PROPERTIES
                          INTERFACE_LINK_LIBRARIES
						    liblzma
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
							)
endif()

######################## lz4
FetchContent_Declare(
  lz4
  GIT_REPOSITORY 		 https://github.com/lz4/lz4.git
  GIT_TAG        		 v1.10.0
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  SOURCE_SUBDIR  build/cmake
  
  EXCLUDE_FROM_ALL
			 
  OVERRIDE_FIND_PACKAGE
)

set(LZ4_BUILD_CLI OFF CACHE BOOL "Build lz4 program" FORCE)
set(LZ4_BUILD_LEGACY_LZ4C OFF CACHE BOOL "Build lz4c program with legacy argument support" FORCE)
set(LZ4_POSITION_INDEPENDENT_LIB ON CACHE BOOL "Use position independent code for static library (if applicable)" FORCE)

FetchContent_MakeAvailable(lz4)

file(REAL_PATH ${lz4_SOURCE_DIR}/lib LZ4_INCLUDE_DIR)
file(REAL_PATH ${lz4_SOURCE_DIR} LZ4_SOURCE_DIR)
file(REAL_PATH ${lz4_BINARY_DIR} LZ4_BINARY_DIR)

set(LZ4_LIBRARY ${LZ4_BINARY_DIR}/$<CONFIG>/lz4.lib CACHE FILEPATH "lz4 library" FORCE)

######################## lzo
FetchContent_Declare(
  lzo2
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/lzo2.git
  GIT_TAG        		 origin/master
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL
			 
  OVERRIDE_FIND_PACKAGE
)

set(LZO_ENABLE_STATIC ON CACHE BOOL "Build static LZO library." FORCE)
set(LZO_ENABLE_SHARED OFF CACHE BOOL "Build static LZO library." FORCE)
set(LZO_INSTALL OFF CACHE BOOL "Build shared libraries" FORCE)

FetchContent_MakeAvailable(lzo2)

file(REAL_PATH ${lzo2_SOURCE_DIR}/include LZO2_INCLUDE_DIR)
file(REAL_PATH ${lzo2_SOURCE_DIR} LZO2_SOURCE_DIR)
file(REAL_PATH ${lzo2_BINARY_DIR} LZO2_BINARY_DIR)

set(LZO2_LIBRARY ${LZO2_BINARY_DIR}/$<CONFIG>/lzo2.lib CACHE FILEPATH "lzo2 library" FORCE)

######################## zstd
FetchContent_Declare(
  zstd
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/zstd.git
  GIT_TAG        		 origin/dev
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  SOURCE_SUBDIR build/cmake
  
  EXCLUDE_FROM_ALL

  OVERRIDE_FIND_PACKAGE
)

set(ZSTD_LEGACY_SUPPORT ON CACHE BOOL "Enable legacy format support" FORCE)
set(ZSTD_MULTITHREAD_SUPPORT ON CACHE BOOL "Enable multi-threading support" FORCE) # set to OFF for Android
set(ZSTD_BUILD_PROGRAMS OFF CACHE BOOL "Build command-line programs" FORCE)
set(ZSTD_BUILD_CONTRIB OFF CACHE BOOL "Build contrib utilities" FORCE)
set(ZSTD_PROGRAMS_LINK_SHARED OFF CACHE BOOL "Link programs against shared library" FORCE)
set(ZSTD_BUILD_TESTS OFF CACHE BOOL "Build test suite" FORCE)

set(ZSTD_BUILD_STATIC ON CACHE BOOL "BUILD STATIC LIBRARIES" FORCE)
set(ZSTD_BUILD_SHARED OFF CACHE BOOL "BUILD SHARED LIBRARIES" FORCE)
set(ZSTD_BUILD_COMPRESSION ON CACHE BOOL "BUILD COMPRESSION MODULE" FORCE)
set(ZSTD_BUILD_DECOMPRESSION ON CACHE BOOL "BUILD DECOMPRESSION MODULE" FORCE)
set(ZSTD_BUILD_DICTBUILDER ON CACHE BOOL "BUILD DICTBUILDER MODULE" FORCE)
set(ZSTD_BUILD_DEPRECATED OFF CACHE BOOL "BUILD DEPRECATED MODULE" FORCE)
set(ZSTD_INSTALL OFF CACHE BOOL "Install applicatuins and libraries" FORCE)

FetchContent_MakeAvailable(zstd)

file(REAL_PATH ${zstd_SOURCE_DIR}/lib ZSTD_INCLUDE_DIR)
file(REAL_PATH ${zstd_SOURCE_DIR} ZSTD_SOURCE_DIR)
file(REAL_PATH ${zstd_BINARY_DIR} ZSTD_BINARY_DIR)

set(ZSTD_LIBRARY ${ZSTD_BINARY_DIR}/lib/$<CONFIG>/zstd_static.lib CACHE FILEPATH "zstd library" FORCE)

if( NOT TARGET zstd::libzstd_static)
	add_library(zstd::libzstd_static INTERFACE IMPORTED)
    set_target_properties(zstd::libzstd_static PROPERTIES
                          INTERFACE_LINK_LIBRARIES 
						     libzstd_static
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
							)
endif()

######################## win-iconv
FetchContent_Declare(
  iconv
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/win-iconv.git
  GIT_TAG        		 origin/master
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL
			 
  OVERRIDE_FIND_PACKAGE

)

set(WIN_ICONV_BUILD_TEST OFF CACHE BOOL "build test executable" FORCE)
set(WIN_ICONV_BUILD_STATIC ON CACHE BOOL "build the static library" FORCE)
set(WIN_ICONV_BUILD_SHARED OFF CACHE BOOL "build the shared library" FORCE)
set(WIN_ICONV_BUILD_EXECUTABLE OFF CACHE BOOL "build the win_iconv executable" FORCE)
set(WIN_ICONV_INSTALL OFF CACHE BOOL "Install applications and library" FORCE)
set(DISABLE_LOCALE_CHARSET OFF CACHE BOOL "disable locale_charset()" FORCE)

FetchContent_MakeAvailable(iconv)

file(REAL_PATH ${iconv_SOURCE_DIR} Iconv_INCLUDE_DIR)
file(REAL_PATH ${iconv_SOURCE_DIR} Iconv_SOURCE_DIR)
file(REAL_PATH ${iconv_BINARY_DIR} Iconv_BINARY_DIR)

set(Iconv_LIBRARY ${Iconv_BINARY_DIR}/$<CONFIG>/libiconv.lib CACHE FILEPATH "iconv library" FORCE)

if(NOT TARGET Iconv::Iconv)
	add_library(Iconv::Iconv INTERFACE IMPORTED)
    set_target_properties(Iconv::Iconv PROPERTIES
                          INTERFACE_LINK_LIBRARIES
							iconv_static
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
							)
endif()

######################## boost cont
set(BOOST_FILESYSTEM_NO_DEPRECATED  ON CACHE BOOL "Disable deprecated functionality of Boost.Filesystem" FORCE)
set(BOOST_FILESYSTEM_DISABLE_SENDFILE  ON CACHE BOOL "Disable usage of sendfile API in Boost.Filesystem" FORCE)
set(BOOST_FILESYSTEM_DISABLE_COPY_FILE_RANGE OFF CACHE BOOL "Disable usage of copy_file_range API in Boost.Filesystem" FORCE)
set(BOOST_FILESYSTEM_DISABLE_STATX OFF CACHE BOOL "Disable usage of statx API in Boost.Filesystem" FORCE)
set(BOOST_FILESYSTEM_DISABLE_GETRANDOM OFF CACHE BOOL "Disable usage of getrandom API in Boost.Filesystem" FORCE)
set(BOOST_FILESYSTEM_DISABLE_ARC4RANDOM OFF CACHE BOOL "Disable usage of arc4random API in Boost.Filesystem" FORCE)
set(BOOST_FILESYSTEM_DISABLE_BCRYPT OFF CACHE BOOL "Disable usage of BCrypt API in Boost.Filesystem")
set(BOOST_FILESYSTEM_EMSCRIPTEN_USE_WASI OFF CACHE BOOL "Use WASI under emscripten in Boost.Filesystem")

set(BOOST_JSON_INSTALL OFF CACHE BOOL "Install boost::json files" FORCE)
set(BOOST_JSON_BUILD_TESTS OFF CACHE BOOL "Build boost::json tests" FORCE)
set(BOOST_JSON_BUILD_FUZZERS OFF CACHE BOOL "Build boost::json fuzzers" FORCE)
set(BOOST_JSON_BUILD_EXAMPLES OFF CACHE BOOL "Build boost::json examples" FORCE)
set(BOOST_JSON_BUILD_BENCHMARKS OFF CACHE BOOL "Build boost::json benchmarks" FORCE)

set(BOOST_IOSTREAMS_ENABLE_ZLIB  ON CACHE BOOL "Boost.Iostreams: Enable ZLIB support" FORCE)
set(BOOST_IOSTREAMS_ENABLE_BZIP2  ON CACHE BOOL "Boost.Iostreams: Enable BZip2 support" FORCE)
set(BOOST_IOSTREAMS_ENABLE_LZMA  ON CACHE BOOL "Boost.Iostreams: Enable LZMA support" FORCE)
set(BOOST_IOSTREAMS_ENABLE_ZSTD  ON CACHE BOOL "Boost.Iostreams: Enable Zstd support" FORCE)
set(BOOST_IOSTREAMS_ZSTD_TARGET "zstd::libzstd_static" CACHE STRING "Target name for Zstd (zstd::libzstd_shared, zstd::libzstd_static)" FORCE)

set(BOOST_ENABLE_MPI OFF CACHE BOOL "Build and enable installation of Boost.MPI and its dependents (requires MPI, CMake 3.10)" FORCE)
set(BOOST_ENABLE_PYTHON OFF CACHE BOOL "Build and enable installation of Boost.Python and its dependents (requires Python, CMake 3.14)" FORCE)
set(BUILD_TESTING OFF CACHE BOOL "Build the tests." FORCE)

set(BOOST_DLL_USE_STD_FS  ON CACHE BOOL "Use std::filesystem instead of Boost.Filesystem" FORCE)
set(BOOST_ALL_NO_LIB  ON CACHE BOOL "Build no system binaries." FORCE)

FetchContent_MakeAvailable(boost liblzma zstd zlib bzip2 iconv)

target_include_directories(boost_iostreams PRIVATE ${LibLZMA_INCLUDE_DIR} ${ZSTD_INCLUDE_DIR} ${BZIP2_SOURCE_DIR} ${BZIP2_BINARY_DIR} ${ZLIB_SOURCE_DIR} ${ZLIB_BINARY_DIR})
add_dependencies(boost_iostreams iconv_static zlibstatic bz2_static libzstd_static liblzma)

target_include_directories(boost_locale PRIVATE ${Iconv_INCLUDE_DIR})
add_dependencies(boost_locale iconv_static)

######################## libxml2 cont
set(LIBXML2_WITH_CATALOG ON CACHE BOOL "Add the Catalog support" FORCE)
set(LIBXML2_WITH_DEBUG OFF CACHE BOOL "Add the debugging module" FORCE)
set(LIBXML2_WITH_HTML ON CACHE BOOL "Add the HTML support" FORCE)
set(LIBXML2_WITH_HTTP OFF CACHE BOOL "Add the HTTP support" FORCE)
set(LIBXML2_WITH_ICONV ON CACHE BOOL "Add ICONV support" FORCE)
set(LIBXML2_WITH_ICU OFF CACHE BOOL "Add ICU support" FORCE)
set(LIBXML2_WITH_ISO8859X ON CACHE BOOL "Add ISO8859X support if no iconv" FORCE)
set(LIBXML2_WITH_LEGACY OFF CACHE BOOL "Add deprecated APIs for compatibility" FORCE)
set(LIBXML2_WITH_LZMA ON CACHE BOOL "Use liblzma" FORCE)
set(LIBXML2_WITH_DOCS OFF CACHE BOOL "Build documentation" FORCE)
set(LIBXML2_WITH_MODULES OFF CACHE BOOL "Add the dynamic modules support" FORCE)
set(LIBXML2_WITH_OUTPUT ON CACHE BOOL "Add the serialization support" FORCE)
set(LIBXML2_WITH_PATTERN ON CACHE BOOL "Add the xmlPattern selection interface" FORCE)
set(LIBXML2_WITH_PROGRAMS OFF CACHE BOOL "Build programs" FORCE)
set(LIBXML2_WITH_PUSH ON CACHE BOOL "Add the PUSH parser interfaces" FORCE)
set(LIBXML2_WITH_PYTHON OFF CACHE BOOL "Build Python bindings" FORCE)
set(LIBXML2_WITH_READLINE OFF CACHE BOOL "readline support for xmllint shell" FORCE)
set(LIBXML2_WITH_REGEXPS ON CACHE BOOL "Add Regular Expressions support" FORCE)
set(LIBXML2_WITH_SAX1 ON CACHE BOOL "Add the older SAX1 interface" FORCE)
set(LIBXML2_WITH_TESTS OFF CACHE BOOL "Build tests" FORCE)
set(LIBXML2_WITH_THREADS ON CACHE BOOL "Add multithread support" FORCE)
set(LIBXML2_WITH_TLS OFF CACHE BOOL "Enable thread-local storage" FORCE)
set(LIBXML2_WITH_VALID ON CACHE BOOL "Add the DTD validation support" FORCE)
set(LIBXML2_WITH_XINCLUDE ON CACHE BOOL "Add the XInclude support" FORCE)
set(LIBXML2_WITH_XPATH ON CACHE BOOL "Add the XPATH support" FORCE)
set(LIBXML2_INSTALL OFF CACHE BOOL "Install applications and library" FORCE)

FetchContent_MakeAvailable(libxml2 zlib liblzma iconv)

target_include_directories(LibXml2 PRIVATE ${ZLIB_BINARY_DIR} ${ZLIB_INCLUDE_DIR} ${LibLZMA_INCLUDE_DIR} ${Iconv_INCLUDE_DIR})
add_dependencies(LibXml2 iconv_static zlibstatic liblzma)

file(REAL_PATH ${libxml2_SOURCE_DIR}/include LibXml2_INCLUDE_DIR)
file(REAL_PATH ${libxml2_SOURCE_DIR} LibXml2_SOURCE_DIR)
file(REAL_PATH ${libxml2_BINARY_DIR} LibXml2_BINARY_DIR)

set(LibXml2_LIBRARY ${LibXml2_BINARY_DIR}/$<CONFIG>/libxml2s$<$<CONFIG:Debug>:d>.lib CACHE FILEPATH "libxml2 library" FORCE)

######################## libarchive cont
set(LIBARCHIVE_BUILD_SHARED_LIBS OFF CACHE BOOL "Build shared libraries" FORCE)
set(LIBARCHIVE_ENABLE_INSTALL OFF CACHE BOOL "Enable installing of libraries" FORCE)
set(ENABLE_MBEDTLS OFF CACHE BOOL "Enable use of mbed TLS" FORCE)
set(ENABLE_NETTLE OFF CACHE BOOL "Enable use of Nettle" FORCE)
set(ENABLE_OPENSSL OFF CACHE BOOL "Enable use of OpenSSL" FORCE)
set(ENABLE_LIBB2 OFF CACHE BOOL "Enable the use of the system LIBB2 library if found" FORCE)
set(ENABLE_LZ4  ON CACHE BOOL "Enable the use of the system LZ4 library if found" FORCE)
set(ENABLE_LZO  ON CACHE BOOL "Enable the use of the system LZO library if found" FORCE)
set(ENABLE_LZMA  ON CACHE BOOL "Enable the use of the system LZMA library if found" FORCE)
set(ENABLE_ZSTD  ON CACHE BOOL "Enable the use of the system zstd library if found" FORCE)
set(ENABLE_ZLIB  ON CACHE BOOL "Enable the use of the system ZLIB library if found" FORCE)
set(ENABLE_BZip2  ON CACHE BOOL "Enable the use of the system BZip2 library if found" FORCE)
set(ENABLE_LIBXML2  ON CACHE BOOL "Enable the use of the system libxml2 library if found" FORCE)
set(ENABLE_EXPAT OFF CACHE BOOL "Enable the use of the system EXPAT library if found" FORCE)
set(ENABLE_WIN32_XMLLITE OFF CACHE BOOL "Enable the use of the Windows XmlLite library if found" FORCE)
set(ENABLE_PCREPOSIX OFF CACHE BOOL "Enable the use of the system PCREPOSIX library if found" FORCE)
set(ENABLE_PCRE2POSIX  ON CACHE BOOL "Enable the use of the system PCRE2POSIX library if found" FORCE)
# set(ENABLE_LIBGCC OFF CACHE BOOL "Enable the use of the system LibGCC library if found" FORCE)
set(ENABLE_CNG OFF CACHE BOOL "Enable the use of CNG(Crypto Next Generation)" FORCE)
set(ENABLE_TAR OFF CACHE BOOL "Enable tar building" FORCE)
set(ENABLE_TAR_SHARED OFF CACHE BOOL "Enable dynamic build of tar" FORCE)
set(ENABLE_CPIO OFF CACHE BOOL "Enable cpio building" FORCE)
set(ENABLE_CPIO_SHARED OFF CACHE BOOL "Enable dynamic build of cpio" FORCE)
set(ENABLE_CAT OFF CACHE BOOL "Enable cat building" FORCE)
set(ENABLE_CAT_SHARED OFF CACHE BOOL "Enable dynamic build of cat" FORCE)
set(ENABLE_XATTR OFF CACHE BOOL "Enable extended attribute support" FORCE)
set(ENABLE_ACL OFF CACHE BOOL "Enable ACL support" FORCE)
set(ENABLE_ICONV  ON CACHE BOOL "Enable iconv support" FORCE)
set(ENABLE_TEST OFF CACHE BOOL "Enable unit and regression tests" FORCE)
set(ENABLE_COVERAGE OFF CACHE BOOL "Enable code coverage (GCC only, automatically sets ENABLE_TEST to ON)" FORCE)

set(ZLIB_LIBRARIES ${ZLIB_LIBRARY})
set(BZIP2_LIBRARIES ${BZIP2_LIBRARY})
set(LIBLZMA_LIBRARY ${LibLZMA_LIBRARY})
set(LIBLZMA_INCLUDE_DIR ${LibLZMA_INCLUDE_DIR})
set(LIBLZMA_LIBRARY ${LibLZMA_LIBRARY})
set(LIBLZMA_INCLUDE_DIRS ${LibLZMA_INCLUDE_DIR})
set(LIBLZMA_LIBRARIES ${LibLZMA_LIBRARY})
set(PCRE2_INCLUDE_DIR ${PCRE2POSIX_BINARY_DIR})
set(PCRE2POSIX_INCLUDE_DIR ${PCRE2POSIX_INCLUDE_DIR})
set(PCRE2POSIX_LIBRARIES ${PCRE2_LIBRARY})
set(LIBXML2_INCLUDE_DIR ${LibXml2_INCLUDE_DIR})
set(LIBXML2_LIBRARY ${LibXml2_LIBRARY})
set(LIBXML2_LIBRARIES ${LibXml2_LIBRARY})
set(ICONV_INCLUDE_DIR ${Iconv_INCLUDE_DIR})
set(LIBICONV_PATH ${Iconv_LIBRARY})

FetchContent_MakeAvailable(libarchive libxml2 liblzma zstd lzo2 lz4 iconv pcre2posix zlib bzip2)

target_include_directories(archive_static
	PRIVATE
		$<BUILD_INTERFACE:${LibXml2_INCLUDE_DIR}>
		$<BUILD_INTERFACE:${LibXml2_BINARY_DIR}>
		$<BUILD_INTERFACE:${Iconv_INCLUDE_DIR}>
		$<BUILD_INTERFACE:${PCRE2POSIX_INCLUDE_DIR}>
		$<BUILD_INTERFACE:${PCRE2POSIX_BINARY_DIR}>
		$<BUILD_INTERFACE:${ZSTD_INCLUDE_DIR}>
		$<BUILD_INTERFACE:${LZO2_INCLUDE_DIR}>
		$<BUILD_INTERFACE:${LZ4_INCLUDE_DIR}>
		$<BUILD_INTERFACE:${LibLZMA_INCLUDE_DIR}>
		$<BUILD_INTERFACE:${BZIP2_INCLUDE_DIR}>
		$<BUILD_INTERFACE:${BZIP2_BINARY_DIR}>
		$<BUILD_INTERFACE:${ZLIB_INCLUDE_DIR}>
		$<BUILD_INTERFACE:${ZLIB_BINARY_DIR}>
		)

add_dependencies(archive_static LibXml2 iconv_static pcre2-posix-static liblzma zlibstatic bz2_static libzstd_static lzo_static_lib lz4_static )

file(REAL_PATH ${libarchive_SOURCE_DIR}/libarchive LIBARCHIVE_INCLUDE_DIR)
file(REAL_PATH ${libarchive_SOURCE_DIR} LIBARCHIVE_SOURCE_DIR)
file(REAL_PATH ${libarchive_BINARY_DIR} LIBARCHIVE_BINARY_DIR)

set(LIBARCHIVE_LIBRARY ${LIBARCHIVE_BINARY_DIR}/libarchive/$<CONFIG>/archive.lib CACHE FILEPATH "libarchive library" FORCE)

if( NOT TARGET LibArchive::LibArchive)
	add_library(LibArchive::LibArchive INTERFACE IMPORTED)
    set_target_properties(LibArchive::LibArchive PROPERTIES
						  INTERFACE_LINK_LIBRARIES
						    archive_static LibXml2 iconv_static pcre2-posix-static iconv_static liblzma libzstd_static lzo_static_lib lz4_static
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						)
endif()

######################## magic_enum
FetchContent_Declare(
  magic_enum
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/magic_enum.git
  GIT_TAG        		 origin/master
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL
			 
  OVERRIDE_FIND_PACKAGE
)

set(MAGIC_ENUM_OPT_BUILD_EXAMPLES OFF CACHE BOOL "Build magic_enum examples" FORCE)
set(MAGIC_ENUM_OPT_BUILD_TESTS OFF CACHE BOOL "Build and perform magic_enum tests" FORCE)
set(MAGIC_ENUM_OPT_INSTALL OFF CACHE BOOL "Generate and install magic_enum target" FORCE)
set(MAGIC_ENUM_OPT_INSTALL_PACKAGE_XML OFF CACHE BOOL "Include package.xml when installing" FORCE)
set(MAGIC_ENUM_OPT_TEST_INSTALLED_VERSION OFF CACHE BOOL "When configuring tests, try use a local magic_enum." FORCE)
set(MAGIC_ENUM_OPT_TEST_INSTALLED_VERSION_PKGCONFIG OFF CACHE BOOL "When configuring tests, try use a local magic_enum via pkgconfig" FORCE)

FetchContent_MakeAvailable(magic_enum)

file(REAL_PATH ${magic_enum_SOURCE_DIR}/include MAGIC_ENUM_INCLUDE_DIR)
file(REAL_PATH ${magic_enum_SOURCE_DIR} MAGIC_ENUM_SOURCE_DIR)


if(NOT TARGET magic_enum::magic_enum)
	add_library(magic_enum::magic_enum INTERFACE IMPORTED)
    set_target_properties(magic_enum::magic_enum PROPERTIES
                          INTERFACE_LINK_LIBRARIES
						    magic_enum
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						 )
    target_include_directories(magic_enum::magic_enum 
								INTERFACE
									$<BUILD_INTERFACE:${MAGIC_ENUM_INCLUDE_DIR}>
							  )
endif()



######################## dlib
FetchContent_Declare(
  dlib
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/dlib.git
  GIT_TAG        		 origin/master
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL
			 
  OVERRIDE_FIND_PACKAGE
			 
)

set(DLIB_IN_PROJECT_BUILD  ON CACHE BOOL "DLIB_IN_PROJECT_BUILD==true means you are using dlib by invoking add_subdirectory(dlib) in the parent project" FORCE)
set(DLIB_ENABLE_ASSERTS OFF CACHE BOOL "Enable this if you want to turn on the DLIB_ASSERT macro" FORCE)
set(DLIB_ISO_CPP_ONLY OFF CACHE BOOL "Enable this if you don't want to compile any non-ISO C++ code (i.e. you don't use any of the API Wrappers)" FORCE)
set(DLIB_NO_GUI_SUPPORT  ON CACHE BOOL "Enable this if you don't want to compile any of the dlib GUI code" FORCE)
set(DLIB_ENABLE_STACK_TRACE OFF CACHE BOOL "Enable this if you want to turn on the DLIB_STACK_TRACE macros" FORCE)

set(DLIB_JPEG_SUPPORT OFF CACHE BOOL "Disable this if you don't want to link against libjpeg" FORCE)
set(DLIB_LINK_WITH_SQLITE3 OFF CACHE BOOL "Disable this if you don't want to link against sqlite3" FORCE)
set(DLIB_USE_BLAS OFF CACHE BOOL "Disable this if you don't want to use a BLAS library" FORCE)
set(DLIB_USE_LAPACK OFF CACHE BOOL "Disable this if you don't want to use a LAPACK library" FORCE)
set(DLIB_USE_CUDA OFF CACHE BOOL "Disable this if you don't want to use NVIDIA CUDA" FORCE)
set(DLIB_PNG_SUPPORT OFF CACHE BOOL "Disable this if you don't want to link against libpng" FORCE)
set(DLIB_GIF_SUPPORT OFF CACHE BOOL "Disable this if you don't want to link against libgif" FORCE)
set(DLIB_WEBP_SUPPORT OFF CACHE BOOL "Disable this if you don't want to link against libwebp" FORCE)
set(DLIB_JXL_SUPPORT OFF CACHE BOOL "Disable this if you don't want to link against libjxl" FORCE)
#option(DLIB_USE_FFTW ${DLIB_USE_FFTW_STR} OFF)
set(DLIB_USE_MKL_FFT OFF CACHE BOOL "Disable this is you don't want to use the MKL DFTI FFT implementation" FORCE)
set(DLIB_USE_MKL_SEQUENTIAL OFF CACHE BOOL "Enable this if you have MKL installed and want to use the sequential version instead of the multi-core version." FORCE)
set(DLIB_USE_MKL_WITH_TBB OFF CACHE BOOL "Enable this if you have MKL installed and want to use the tbb version instead of the openmp version." FORCE)
set(DLIB_USE_FFMPEG OFF CACHE BOOL "Disable this if you don't want to use the FFMPEG library" FORCE)
set(CUDA_PROPAGATE_HOST_FLAGS OFF CACHE BOOL "Propage C/CXX_FLAGS and friends to the host compiler via -Xcompile" FORCE)
set(DLIB_FORCE_MSVC_STATIC_RUNTIME OFF CACHE BOOL "use static runtime" FORCE)

set(USE_SSE2_INSTRUCTIONS  ON CACHE BOOL "Compile your program with SSE2 instructions" FORCE)
set(USE_SSE4_INSTRUCTIONS  ON CACHE BOOL "Compile your program with SSE4 instructions" FORCE)
set(USE_AVX_INSTRUCTIONS   ON CACHE BOOL "Compile your program with AVX instructions"  FORCE)

FetchContent_MakeAvailable(dlib)

file(REAL_PATH ${dlib_SOURCE_DIR}/dlib DLIB_INCLUDE_DIR)
file(REAL_PATH ${dlib_SOURCE_DIR} DLIB_SOURCE_DIR)
file(REAL_PATH ${dlib_BINARY_DIR} DLIB_BINARY_DIR)

####################### DuckX
FetchContent_Declare(
  duckx
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/DuckX.git
  GIT_TAG        		 origin/master
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL
)

set(DUCKX_INSTALL OFF CACHE INTERNAL "Install applications and library" FORCE)
set(DUCKX_BUILD_SHARED_LIBS OFF CACHE INTERNAL "Build shared libraries" FORCE)

FetchContent_MakeAvailable(duckx)

file(REAL_PATH ${duckx_SOURCE_DIR}/include DUCKX_INCLUDE_DIR)
file(REAL_PATH ${duckx_SOURCE_DIR} DUCKX_SOURCE_DIR)
file(REAL_PATH ${duckx_BINARY_DIR} DUCKX_BINARY_DIR)

set(DUCKX_LIBRARY ${DUCKX_BINARY_DIR}/$<CONFIG>/duckx.lib CACHE FILEPATH "duckx library" FORCE)

target_include_directories(duckx 
	INTERFACE 
	$<BUILD_INTERFACE:${DUCKX_SOURCE_DIR}/thirdparty/pugixml>
	$<BUILD_INTERFACE:${DUCKX_SOURCE_DIR}/thirdparty/zip>)
	


####################### csv-parser
FetchContent_Declare(
  csv_parser
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/csv-parser.git
  GIT_TAG        		 origin/master
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL
  
  CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE=ON
			 -DBUILD_PYTHON=OFF
			 -DCSV_BUILD_PROGRAMS=OFF
			 -DBUILD_SHARED_LIBS=OFF
)


FetchContent_MakeAvailable(csv_parser)


# Invoke the build for native code shared with the other target platforms.
# This can be changed to accommodate different builds.
add_subdirectory("${UNNU_DOCPARSER_LITE_SRC_DIR}" "${CMAKE_CURRENT_BINARY_DIR}/shared")

set_target_properties(unnu_dxl PROPERTIES
  BUILD_WITH_INSTALL_RPATH TRUE
)

# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(unnu_dxl_bundled_libraries
  # Defined in ../src/CMakeLists.txt.
  # This can be changed to accommodate different builds.
  $<TARGET_FILE:unnu_dxl>
  PARENT_SCOPE
)
