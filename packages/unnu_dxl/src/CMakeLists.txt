# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.24)

project(unnu_dxl VERSION 0.0.1 LANGUAGES CXX C)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

cmake_policy(SET CMP0079 NEW)

if(NOT DEFINED CMAKE_INSTALL_PREFIX)
	set(CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_BINARY_DIR}" CACHE PATH "Needed to avoid cmake_install.cmake build issues." FORCE) 
	if(NOT DEFINED CMAKE_INSTALL_BINDIR)
		set(CMAKE_INSTALL_BINDIR ${CMAKE_BINARY_DIR}/runner/$<CONFIG>)
	endif()
endif()

set(BUILD_SHARED_LIBS ON)
####################### zlib
set(ZLIB_BUILD_TESTING OFF CACHE BOOL "Enable Zlib Examples as tests" FORCE)
set(ZLIB_BUILD_SHARED OFF CACHE BOOL "Enable building zlib shared library" FORCE)
set(ZLIB_BUILD_STATIC ON CACHE BOOL "Enable building zlib static library" FORCE)
set(ZLIB_BUILD_MINIZIP OFF CACHE BOOL "Enable building libminizip contrib library" FORCE)
set(ZLIB_INSTALL OFF CACHE BOOL "Enable installation of zlib" FORCE)
set(ZLIB_BUILD_EXAMPLES OFF CACHE BOOL "Enable Zlib Examples" FORCE)
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/zlib" "${CMAKE_CURRENT_BINARY_DIR}/zlib")

####################### minizip
set(MINIZIP_BUILD_SHARED OFF CACHE BOOL "Enable building minizip shared library" FORCE)
set(MINIZIP_BUILD_STATIC ON CACHE BOOL "Enable building minizip static library" FORCE)
set(MINIZIP_BUILD_TESTING OFF CACHE BOOL "Enable testing of minizip" FORCE)
set(MINIZIP_ENABLE_BZIP2 OFF CACHE BOOL "Build minizip withj bzip2 support" FORCE)
set(MINIZIP_INSTALL OFF CACHE BOOL "Enable installation of minizip" FORCE)

if(WIN32)
set(IOWIN32_SRC zlib/contrib/minizip/iowin32.c)
endif()

set(minizip_srcs 
     zlib/contrib/minizip/ioapi.c 
	 ${IOWIN32_SRC} 
	 zlib/contrib/minizip/mztools.c
	 zlib/contrib/minizip/unzip.c
	 zlib/contrib/minizip/zip.c)

add_library(minizip_objs OBJECT ${minizip_srcs})
set_target_properties(minizip_objs  PROPERTIES POSITION_INDEPENDENT_CODE True)
target_include_directories(minizip_objs PRIVATE $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/zlib>)

######################## xz
set(XZ_NLS OFF CACHE BOOL "Native Language Support (translated messages and man pages)" FORCE)
set(XZ_MICROLZMA_ENCODER OFF CACHE BOOL "MicroLZMA encoder (needed by specific applications only)" FORCE)
set(XZ_MICROLZMA_DECODER OFF CACHE BOOL "MicroLZMA decoder (needed by specific applications only)" FORCE)
set(XZ_LZIP_DECODER ON CACHE BOOL "Support lzip decoder" FORCE)
set(XZ_TOOL_XZDEC OFF CACHE BOOL "Build and install the xzdec command line tool" FORCE)
set(XZ_TOOL_LZMADEC OFF CACHE BOOL "Build and install the lzmadec command line tool" FORCE)
set(XZ_TOOL_LZMAINFO OFF CACHE BOOL "Build and install the lzmainfo command line tool" FORCE)
set(XZ_TOOL_XZ OFF CACHE BOOL "Build and install the xz command line tool" FORCE)
set(XZ_DOC OFF CACHE BOOL "Install basic documentation, examples, and license files" FORCE)
   
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/xz" "${CMAKE_CURRENT_BINARY_DIR}/xz" EXCLUDE_FROM_ALL)
######################## bzip2
set(ENABLE_LIB_ONLY ON CACHE BOOL "Build in library, excl. app and examples" FORCE)
set(ENABLE_STATIC_LIB ON CACHE BOOL "Build in static library" FORCE)
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/bz2" "${CMAKE_CURRENT_BINARY_DIR}/bz2" EXCLUDE_FROM_ALL)

######################## libarchive
# set(BUILD_SHARED_LIBS OFF CACHE BOOL "Build shared libraries" FORCE)

set(ENABLE_MBEDTLS OFF CACHE BOOL "Enable use of mbed TLS" FORCE)
set(ENABLE_NETTLE OFF CACHE BOOL "Enable use of Nettle" FORCE)
set(ENABLE_OPENSSL OFF CACHE BOOL "Enable use of OpenSSL" FORCE)
set(ENABLE_TEST OFF CACHE BOOL "Enable unit and regression tests" FORCE)

set(ENABLE_TAR ON CACHE BOOL "Enable tar building" FORCE)
set(ENABLE_TAR_SHARED OFF CACHE BOOL "Enable dynamic build of tar" FORCE)
set(ENABLE_CPIO ON CACHE BOOL "Enable cpio building" FORCE)
set(ENABLE_CPIO_SHARED OFF CACHE BOOL "Enable dynamic build of cpio" FORCE)
set(ENABLE_CAT ON CACHE BOOL "Enable cat building" FORCE)
set(ENABLE_CAT_SHARED OFF CACHE BOOL "Enable dynamic build of cat" FORCE)
add_compile_definitions(LIBARCHIVE_STATIC)
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/libarchive" "${CMAKE_CURRENT_BINARY_DIR}/libarchive" EXCLUDE_FROM_ALL)
######################## DuckX
set(duckx_srcs 
     DuckX/src/duckx.cpp
	 DuckX/thirdparty/pugixml/pugixml.cpp
	 DuckX/thirdparty/zip/zip.c)

add_library(duckx_objs OBJECT ${duckx_srcs})
set_target_properties(duckx_objs  PROPERTIES POSITION_INDEPENDENT_CODE True)
target_include_directories(duckx_objs PRIVATE 
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/DuckX/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/DuckX/thirdparty/pugixml>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/DuckX/thirdparty/zip>)

######################## libxlsxwriter
file(GLOB_RECURSE libxlsxwriter_srcs 
		libxlsxwriter/src/*.c 
		libxlsxwriter/third_party/dtoa/*.c
		libxlsxwriter/third_party/md5/*.c
		libxlsxwriter/third_party/tmpfileplus/*.c)

add_library(libxlsxwriter_objs OBJECT ${libxlsxwriter_srcs})

target_compile_definitions(libxlsxwriter_objs PRIVATE USE_MEM_FILE)

target_include_directories(libxlsxwriter_objs PRIVATE
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/libxlsxwriter/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/libxlsxwriter/xlsxwriter/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/third_party/dtoa/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/third_party/md5/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/third_party/tmpfileplus/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/zlib>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/zlib/contrib>)

set_target_properties(libxlsxwriter_objs  PROPERTIES POSITION_INDEPENDENT_CODE True)

####################### xpdf
set(MULTITHREADED ON CACHE BOOL "include support for multithreading" FORCE)
set(SPLASH_CMYK OFF CACHE BOOL "include support for CMYK rasterization" FORCE)
set(NO_FONTCONFIG ON CACHE BOOL "disable support for libfontconfig" FORCE)
set(NO_TEXT_SELECT ON CACHE BOOL "do not allow text selection" FORCE)
set(XPDFWIDGET_PRINTING OFF CACHE BOOL "include printing support in XpdfWidget" FORCE)

# add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/xpdf" "${CMAKE_CURRENT_BINARY_DIR}/xpdf")

set(A4_PAPER OFF CACHE BOOL "use A4 (instead of Letter) paper size by default for PostScript output" FORCE)
set(NO_TEXT_SELECT ON CACHE BOOL "do not allow text selection" FORCE)
set(OPI_SUPPORT OFF CACHE BOOL "include support for OPI comments" FORCE)
set(MULTITHREADED ON CACHE BOOL "include support for multithreading" FORCE)
set(USE_EXCEPTIONS ON CACHE BOOL "use C++ exceptions" FORCE)
set(USE_FIXEDPOINT OFF CACHE BOOL "use fixed point (instead of floating point) arithmetic" FORCE)
set(SPLASH_CMYK OFF CACHE BOOL "include support for CMYK rasterization" FORCE)
set(NO_FONTCONFIG ON CACHE BOOL "disable support for libfontconfig" FORCE)
#--- check for various library functions
check_function_exists(mkstemp HAVE_MKSTEMP)
check_function_exists(mkstemps HAVE_MKSTEMPS)
check_function_exists(popen HAVE_POPEN)
#--- set up 64-bit file seeks
check_function_exists(fseeko HAVE_FSEEKO)
check_function_exists(fseek64 HAVE_FSEEK64)
check_function_exists(_fseeki64 HAVE_FSEEKI64)
set(HAVE_PAPER_H FALSE)
set(PAPER_LIBRARY "")
set(HAVE_FONTCONFIG FALSE)
set(FONTCONFIG_LIBRARY "")

#--- create aconf.h
configure_file(xpdf/aconf.h.in xpdf/aconf.h)

file(GLOB_RECURSE xpdf_srcs 
		  xpdf/goo/*.cc 
		  xpdf/fofi/*.cc
		  xpdf/splash/Splash.cc
		  xpdf/splash/SplashBitmap.cc
		  xpdf/splash/SplashClip.cc
		  xpdf/splash/SplashFTFont.cc
		  xpdf/splash/SplashFTFontEngine.cc
		  xpdf/splash/SplashFTFontFile.cc
		  xpdf/splash/SplashFont.cc
		  xpdf/splash/SplashFontEngine.cc
		  xpdf/splash/SplashFontFile.cc
		  xpdf/splash/SplashFontFileID.cc
		  xpdf/splash/SplashPath.cc
		  xpdf/splash/SplashPattern.cc
		  xpdf/splash/SplashScreen.cc
		  xpdf/splash/SplashState.cc
		  xpdf/splash/SplashXPath.cc
		  xpdf/splash/SplashXPathScanner.cc
		  xpdf/xpdf/AcroForm.cc
		  xpdf/xpdf/Annot.cc
		  xpdf/xpdf/Array.cc
		  xpdf/xpdf/BuiltinFont.cc
		  xpdf/xpdf/BuiltinFontTables.cc
		  xpdf/xpdf/Catalog.cc
		  xpdf/xpdf/CharCodeToUnicode.cc
		  xpdf/xpdf/CMap.cc
		  xpdf/xpdf/Decrypt.cc
		  xpdf/xpdf/Dict.cc
		  xpdf/xpdf/DisplayState.cc
		  xpdf/xpdf/Error.cc
		  xpdf/xpdf/FontEncodingTables.cc
		  xpdf/xpdf/Function.cc
		  xpdf/xpdf/Gfx.cc
		  xpdf/xpdf/GfxFont.cc
		  xpdf/xpdf/GfxState.cc
		  xpdf/xpdf/GlobalParams.cc
		  xpdf/xpdf/JArithmeticDecoder.cc
		  xpdf/xpdf/JBIG2Stream.cc
		  xpdf/xpdf/JPXStream.cc
		  xpdf/xpdf/Lexer.cc
		  xpdf/xpdf/Link.cc
		  xpdf/xpdf/NameToCharCode.cc
		  xpdf/xpdf/Object.cc
		  xpdf/xpdf/OptionalContent.cc
		  xpdf/xpdf/Outline.cc
		  xpdf/xpdf/OutputDev.cc
		  xpdf/xpdf/Page.cc
		  xpdf/xpdf/Parser.cc
		  xpdf/xpdf/PDF417Barcode.cc
		  xpdf/xpdf/PDFCore.cc
		  xpdf/xpdf/PDFDoc.cc
		  xpdf/xpdf/PDFDocEncoding.cc
		  xpdf/xpdf/PSTokenizer.cc
		  xpdf/xpdf/SecurityHandler.cc
		  xpdf/xpdf/ShadingImage.cc
		  xpdf/xpdf/SplashOutputDev.cc
		  xpdf/xpdf/Stream.cc
		  xpdf/xpdf/TextString.cc
		  xpdf/xpdf/TextOutputDev.cc
		  xpdf/xpdf/TileCache.cc
		  xpdf/xpdf/TileCompositor.cc
		  xpdf/xpdf/TileMap.cc
		  xpdf/xpdf/UnicodeMap.cc
		  xpdf/xpdf/UnicodeRemapping.cc
		  xpdf/xpdf/UnicodeTypeTable.cc
		  xpdf/xpdf/UTF8.cc
		  xpdf/xpdf/XFAScanner.cc
		  xpdf/xpdf/XRef.cc
		  xpdf/xpdf/Zoox.cc
		)

add_library(xpdf_objs OBJECT ${xpdf_srcs})
		
target_include_directories(xpdf_objs PRIVATE
	${CMAKE_CURRENT_BINARY_DIR}/xpdf
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/xpdf>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/xpdf/goo>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/xpdf/fofi>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/xpdf/splash>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/xpdf/xpdf>
	)
set_target_properties(xpdf_objs  PROPERTIES POSITION_INDEPENDENT_CODE True)

###################### libtre
file(GLOB_RECURSE libtre_srcs tre/lib/*.c)

add_library(libtre_objs OBJECT ${libtre_srcs})
if(MSVC)
set(TRE_PLATFORM_INCDIR $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/tre/win32>)
endif()
target_include_directories(libtre_objs PRIVATE
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/tre/lib>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/tre/local_includes>
	)
set_target_properties(libtre_objs PROPERTIES POSITION_INDEPENDENT_CODE True)
target_compile_definitions(libtre_objs PRIVATE HAVE_CONFIG_H USE_LOCAL_TRE_H)

########################## libmagic

set(libmagic_srcs 				  
                  file/src/apprentice.c
				  file/src/apptype.c
				  file/src/ascmagic.c
				  file/src/asctime_r.c
				  file/src/asprintf.c
				  file/src/buffer.c
				  file/src/cdf.c
				  file/src/cdf_time.c
				  file/src/compress.c
				  file/src/ctime_r.c
				  file/src/der.c
				  file/src/dprintf.c
				  file/src/encoding.c
				  file/src/fmtcheck.c
				  file/src/fsmagic.c
				  file/src/funcs.c
				  file/src/getline.c
				  file/src/getopt_long.c
				  file/src/gmtime_r.c
				  file/src/is_csv.c
				  file/src/is_json.c
				  file/src/is_simh.c
				  file/src/is_tar.c
				  file/src/localtime_r.c
				  file/src/magic.c
				  file/src/pread.c
				  file/src/print.c
				  file/src/readcdf.c
				  file/src/readelf.c
				  file/src/seccomp.c
				  file/src/softmagic.c
				  file/src/strcasestr.c
				  file/src/strlcat.c
				  file/src/strlcpy.c
				  file/src/vasprintf.c
				  )

add_library(libmagic_objs OBJECT ${libmagic_srcs})
if(MSVC)
set(DIRENT_INCLUDE_DIR $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/dirent/include>)
endif()
target_include_directories(libmagic_objs PRIVATE
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/file/src>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/tre/include>
	${DIRENT_INCLUDE_DIR}
	)
set_target_properties(libmagic_objs  PROPERTIES POSITION_INDEPENDENT_CODE True)
target_compile_definitions(libmagic_objs PRIVATE HAVE_INTTYPES_H HAVE_STDINT_H BUILD_AS_WINDOWS_STATIC_LIBARAY)
if(MSVC)
	set(WINDOWS_EXTRA_LIBS shlwapi) 
endif()
target_link_libraries(libmagic_objs PRIVATE $<TARGET_OBJECTS:libtre_objs> ${WINDOWS_EXTRA_LIBS})

#################### boost filesystem
file(GLOB_RECURSE boost_fs_srcs 
				  boost_container/src/*.cpp
				  boost_container/src/alloc_lib.c
				  boost_fs/src/*.cpp 
				  )
add_library(boost_fs_objs OBJECT ${boost_fs_srcs})

target_compile_features(boost_fs_objs PUBLIC cxx_std_20)
target_include_directories(boost_fs_objs PRIVATE
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_algorithm/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_align/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_assert/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_bind/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_callable_traits/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_concept_check/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_config/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_container/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_container_hash/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_core/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_date_time/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_describe/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_detail/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_dll/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_endian/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_fs/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_function/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_intrusive/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_io/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_iterator/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_json/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_lexical_cast/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_move/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_mp11/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_mpl/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_numeric_conversion/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_preprocessor/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_predef/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_range/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_scope/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_smart_ptr/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_static_assert/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_system/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_throw_exception/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_tokenizer/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_type_traits/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_utility/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_variant2/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_winapi/include>
	)

target_compile_definitions(boost_fs_objs PRIVATE
			BOOST_ALL_NO_LIB
			BOOST_JSON_NO_LIB
			BOOST_CONTAINER_NO_LIB
			BOOST_FILESYSTEM_VERSION=4
			BOOST_FILESYSTEM_STATIC_LINK=1
			BOOST_FILESYSTEM_SOURCE
			BOOST_FILESYSTEM_NO_DEPRECATED
			BOOST_FILESYSTEM_NO_LIB
#			BOOST_FILESYSTEM_DISABLE_COPY_FILE_RANGE
#			BOOST_FILESYSTEM_DISABLE_SENDFILE
#			BOOST_FILESYSTEM_DISABLE_STATX
			BOOST_FILESYSTEM_DISABLE_BCRYPT
#			BOOST_FILESYSTEM_DISABLE_GETRANDOM
#			BOOST_FILESYSTEM_DISABLE_ARC4RANDOM
			BOOST_FILESYSTEM_DISABLE_EMSCRIPTEN_WASI
			)
##################### docwire-lite
file(GLOB_RECURSE docwire_lite_srcs
				  boost_json/src/src.cpp
				  docwire_lite/src/*.cpp 
				  )

add_library(docwire_lite_objs OBJECT ${docwire_lite_srcs})

include(GenerateExportHeader)
generate_export_header(docwire_lite_objs 
		EXPORT_MACRO_NAME DOCWIRE_CORE_EXPORT 
		EXPORT_FILE_NAME core_export.h)
		
target_compile_features(docwire_lite_objs PUBLIC cxx_std_20)

target_link_libraries(docwire_lite_objs PUBLIC archive_static $<TARGET_OBJECTS:libmagic_objs>)

target_include_directories(docwire_lite_objs PRIVATE
	${CMAKE_CURRENT_BINARY_DIR}
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/docwire_lite/src>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_algorithm/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_align/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_assert/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_bind/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_callable_traits/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_concept_check/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_config/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boostcontainer/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_container_hash/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_core/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_date_time/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_describe/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_detail/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_dll/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_endian/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_fs/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_fs/src>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_function/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_intrusive/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_io/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_iterator/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_json/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_lexical_cast/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_move/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_mp11/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_mpl/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_numeric_conversion/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_preprocessor/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_predef/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_range/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_scope/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_smart_ptr/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_static_assert/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_system/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_throw_exception/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_tokenizer/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_type_traits/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_utility/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_variant2/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/boost_winapi/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/magic_enum/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/libarchive/libarchive>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/zlib>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/zlib/contrib/minizip>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/libxlsxwriter/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/file/src>
	${CMAKE_CURRENT_BINARY_DIR}/xpdf
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/xpdf/goo>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/xpdf>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/xpdf/xpdf>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/DuckX/include>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/DuckX/thirdparty/pugixml>
	$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/tre/include>
	)

target_compile_definitions(docwire_lite_objs PRIVATE
			DOCWIRE_ENABLE_SHORT_MACRO_NAMES
			docwire_lite_objs_EXPORTS
			BOOST_ALL_NO_LIB
			BOOST_JSON_NO_LIB
			BOOST_CONTAINER_NO_LIB
			BOOST_FILESYSTEM_NO_LIB
			)	

if(MSVC)
#    target_compile_definitions(docwire_lite_objs PRIVATE MSVC_BUILD BOOST_USE_WINDOWS_H)
    target_compile_options(docwire_lite_objs PUBLIC /Zc:__cplusplus /Zc:preprocessor)	
endif()

add_library(unnu_dxl SHARED unnu_dxl.cpp)
set_target_properties(unnu_dxl PROPERTIES
  PUBLIC_HEADER unnu_dxl.h
  OUTPUT_NAME "unnu_dxl"
  POSITION_INDEPENDENT_CODE True
  CXX_STANDARD 20
)

target_include_directories(unnu_dxl PRIVATE 
		${CMAKE_CURRENT_BINARY_DIR}
		$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/docwire_lite/src>)

if(MSVC)
#    target_compile_definitions(unnu_dxl PRIVATE MSVC_BUILD BOOST_USE_WINDOWS_H)
    target_compile_options(unnu_dxl PUBLIC /Zc:__cplusplus /Zc:preprocessor)
endif()

find_package(Threads REQUIRED)

target_link_libraries(unnu_dxl PRIVATE 
							liblzma 
							zlibstatic
							$<TARGET_OBJECTS:minizip_objs>
							bz2_static
							archive_static
							$<TARGET_OBJECTS:libtre_objs>
							$<TARGET_OBJECTS:libmagic_objs>							
							$<TARGET_OBJECTS:duckx_objs> 
							$<TARGET_OBJECTS:xpdf_objs>
							$<TARGET_OBJECTS:boost_fs_objs>
							$<TARGET_OBJECTS:docwire_lite_objs>
							${WINDOWS_EXTRA_LIBS}
							Threads::Threads)

if (ANDROID)
  # Support Android 15 16k page size
  target_link_options(unnu_dxl PRIVATE "-Wl,-z,max-page-size=16384")
endif()
