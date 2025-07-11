# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "unnu_dxp")
project(${PROJECT_NAME} LANGUAGES CXX)


if(NOT DEFINED CMAKE_INSTALL_PREFIX)
	set(CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_BINARY_DIR}" CACHE PATH "Needed to avoid cmake_install.cmake build issues." FORCE) 
	if(NOT DEFINED CMAKE_INSTALL_BINDIR)
		set(CMAKE_INSTALL_BINDIR ${CMAKE_BINARY_DIR}/runner/$<CONFIG>)
	endif()
endif()


set(CMAKE_BUILD_RPATH_USE_ORIGIN TRUE)
set(UNNU_DOCPARSER_PRO_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../src)

if (UNIX AND NOT WIN32 AND NOT APPLE)
	if (CMAKE_SIZEOF_VOID_P MATCHES "8")
		set (LIB_POSTFIX "64" CACHE STRING "suffix for 32/64 dir placement")
		mark_as_advanced (LIB_POSTFIX)
	endif ()
endif ()
if (MSVC)
	add_definitions (-D_CRT_SECURE_NO_WARNINGS)
endif()
if (NOT DEFINED LIB_POSTFIX)
  set (LIB_POSTFIX "")
endif ()

if(DEFINED CMAKE_BUILD_TYPE)
	string(TOLOWER ${CMAKE_BUILD_TYPE} build_type)
	if (build_type STREQUAL "debug" OR build_type STREQUAL "relwithdebinfo")
		if (MSVC)
		  add_compile_options(/bigobj)
		else ()
		  add_compile_options(-Wa,-mbig-obj)
		endif ()
	endif()
endif()

include(FetchContent)
include(ExternalProject)

######################## bzip2
set(ENABLE_STATIC_LIB ON CACHE BOOL "Build libbz2 in static mode also" FORCE)
set(ENABLE_SHARED_LIB OFF CACHE BOOL "Build libbz2 as a shared library" FORCE)
set(USE_OLD_SONAME OFF CACHE BOOL "Use libbz2.so.1.0 for compatibility with old Makefiles" FORCE)

FetchContent_Declare(
  bzip2
  GIT_REPOSITORY https://github.com/libarchive/bzip2.git
  GIT_TAG        1ea1ac188ad4b9cb662e3f8314673c63df95a589
  GIT_SHALLOW    TRUE
  
  CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=ON
             -DENABLE_LIB_ONLY:BOOL=ON
             -DENABLE_DEBUG:BOOL=OFF
			 -DENABLE_APP:BOOL=OFF
			 -DENABLE_DOCS:BOOL=OFF
			 -DENABLE_EXAMPLES:BOOL=OFF
			 -DENABLE_WERROR:BOOL=OFF
			 -DUSE_OLD_SONAME:BOOL=${USE_OLD_SONAME}
			 -DENABLE_SHARED_LIB:BOOL=${ENABLE_SHARED_LIB}
			 -DENABLE_STATIC_LIB:BOOL=${ENABLE_STATIC_LIB}
			 
  OVERRIDE_FIND_PACKAGE
			 
)

FetchContent_MakeAvailable(bzip2)

file(REAL_PATH ${bzip2_SOURCE_DIR} BZIP2_INCLUDE_DIR)
file(REAL_PATH ${bzip2_SOURCE_DIR} BZIP2_SOURCE_DIR)
file(REAL_PATH ${bzip2_BINARY_DIR} BZIP2_BINARY_DIR)

set(BZIP2_LIBRARY ${BZIP2_BINARY_DIR}/$<CONFIG>/bz2_static.lib CACHE FILEPATH "bzip2 library" FORCE)

if(NOT TARGET BZip2::BZip2)
	add_library(BZip2::BZip2 INTERFACE IMPORTED)
    set_target_properties(BZip2::BZip2 PROPERTIES
                          INTERFACE_LINK_LIBRARIES 
							  bz2_static
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						  )
	target_include_directories(BZip2::BZip2 INTERFACE 
						$<BUILD_INTERFACE:${BZIP2_INCLUDE_DIR}>
						$<BUILD_INTERFACE:${BZIP2_BINARY_DIR}>
						)
	target_link_libraries(BZip2::BZip2 INTERFACE $<BUILD_INTERFACE:${BZIP2_LIBRARY}>)
endif()
# include_directories(${BZIP2_INCLUDE_DIR} ${BZIP2_BINARY_DIR})
# link_libraries(${BZIP2_LIBRARY})

####################### zlib
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

FetchContent_Declare(
  zlib
  GIT_REPOSITORY https://github.com/madler/zlib.git
  GIT_TAG        5a82f71ed1dfc0bec044d9702463dbdf84ea3b71
  GIT_SHALLOW    TRUE
  
  CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=ON
             -DCMAKE_PREFIX_INSTALL:BOOL=${CMAKE_CURRENT_BINARY_DIR}
             -DZLIB_BUILD_TESTING:STRING=${ZLIB_BUILD_TESTING}
			 -DZLIB_BUILD_SHARED:BOOL=${ZLIB_BUILD_SHARED} 
             -DZLIB_BUILD_STATIC:BOOL=${ZLIB_BUILD_STATIC}
			 -DZLIB_BUILD_MINIZIP:BOOL=${ZLIB_BUILD_MINIZIP}
			 -DZLIB_INSTALL:BOOL=${ZLIB_INSTALL}
			 -DZLIB_BUILD_EXAMPLES:BOOL=${ZLIB_BUILD_EXAMPLES}
			 -DMINIZIP_BUILD_SHARED:BOOL=${MINIZIP_BUILD_SHARED}
			 -DMINIZIP_BUILD_STATIC:BOOL=${MINIZIP_BUILD_STATIC}
			 -DMINIZIP_BUILD_TESTING:BOOL=${MINIZIP_BUILD_TESTING}
			 -DMINIZIP_ENABLE_BZIP2:BOOL=${MINIZIP_ENABLE_BZIP2}
			 -DMINIZIP_INSTALL:BOOL=${MINIZIP_INSTALL}
			 -DBZIP2_INCLUDE_DIR:PATH=${BZIP2_INCLUDE_DIR}
			 -DBZIP2_LIBRARY:FILEPATH=${BZIP2_LIBRARY}
			 
  OVERRIDE_FIND_PACKAGE

)

FetchContent_MakeAvailable(zlib bzip2)

file(REAL_PATH ${zlib_SOURCE_DIR} ZLIB_INCLUDE_DIR)
file(REAL_PATH ${zlib_SOURCE_DIR} ZLIB_SOURCE_DIR)
file(REAL_PATH ${zlib_BINARY_DIR} ZLIB_BINARY_DIR)

set(ZLIB_LIBRARY ${ZLIB_BINARY_DIR}/$<CONFIG>/zs$<$<CONFIG:Debug>:${CMAKE_DEBUG_POSTFIX}>.lib CACHE FILEPATH "zlib library" FORCE)

set(MINIZIP_LIBRARY ${ZLIB_BINARY_DIR}/$<CONFIG>/minizips$<$<CONFIG:Debug>:${CMAKE_DEBUG_POSTFIX}>.lib CACHE FILEPATH "minizip library" FORCE)

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

if(NOT TARGET unofficial-minizip)
	add_library(unofficial-minizip INTERFACE IMPORTED)
    set_target_properties(unofficial-minizip PROPERTIES
                          INTERFACE_LINK_LIBRARIES
							libminizipstatic zlibstatic bz2_static
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						 )
	target_include_directories(unofficial-minizip
								INTERFACE 
									$<BUILD_INTERFACE:${ZLIB_INCLUDE_DIR}/contrib/minzip>
									$<BUILD_INTERFACE:${ZLIB_INCLUDE_DIR}>
									$<BUILD_INTERFACE:${ZLIB_BINARY_DIR}>
									$<BUILD_INTERFACE:${BZIP2_INCLUDE_DIR}>
									$<BUILD_INTERFACE:${BZIP2_BINARY_DIR}>
							  )
	target_link_libraries(unofficial-minizip
							INTERFACE
								$<BUILD_INTERFACE:${BZIP2_LIBRARY}>
								$<BUILD_INTERFACE:${ZLIB_LIBRARY}>
								$<BUILD_INTERFACE:${MINIZIP_LIBRARY}>
						 )
endif()

if(NOT TARGET unofficial::minizip::minizip)
	add_library(unofficial::minizip::minizip INTERFACE IMPORTED)
    set_target_properties(unofficial::minizip::minizip PROPERTIES
                          INTERFACE_LINK_LIBRARIES
							libminizipstatic zlibstatic bz2_static
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						 )
	target_include_directories(unofficial::minizip::minizip 
								INTERFACE 
									$<BUILD_INTERFACE:${ZLIB_INCLUDE_DIR}/contrib/minzip>
									$<BUILD_INTERFACE:${ZLIB_INCLUDE_DIR}>
									$<BUILD_INTERFACE:${ZLIB_BINARY_DIR}>
									$<BUILD_INTERFACE:${BZIP2_INCLUDE_DIR}>
									$<BUILD_INTERFACE:${BZIP2_BINARY_DIR}>
							  )
	target_link_libraries(unofficial::minizip::minizip
							INTERFACE
								$<BUILD_INTERFACE:${BZIP2_LIBRARY}>
								$<BUILD_INTERFACE:${ZLIB_LIBRARY}>
								$<BUILD_INTERFACE:${MINIZIP_LIBRARY}>
						 )
endif()

add_dependencies(zlibstatic bz2_static)

# include_directories(${ZLIB_BINARY_DIR} ${ZLIB_INCLUDE_DIR})
# link_libraries(${ZLIB_LIBRARY})

target_include_directories(libminizipstatic PRIVATE $<BUILD_INTERFACE:${ZLIB_INCLUDE_DIR}> $<BUILD_INTERFACE:${ZLIB_BINARY_DIR}> $<BUILD_INTERFACE:${BZIP2_INCLUDE_DIR}> $<BUILD_INTERFACE:${BZIP2_BINARY_DIR}>)
target_link_libraries(libminizipstatic INTERFACE $<BUILD_INTERFACE:${BZIP2_LIBRARY}> $<BUILD_INTERFACE:${ZLIB_LIBRARY}>)
add_dependencies(libminizipstatic zlibstatic bz2_static)

######################## xz
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


FetchContent_Declare(
  liblzma
  GIT_REPOSITORY https://github.com/libarchive/xz.git
  GIT_TAG        v5.6.3
  GIT_SHALLOW    TRUE
  
  CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=ON
			 -DBUILD_SHARED_LIBS:BOOL=OFF
             -DXZ_NLS:BOOL=${XZ_NLS}
			 -DXZ_SMALL:BOOL=${XZ_SMALL}
			 -DXZ_EXTERNAL_SHA256:BOOL=${XZ_EXTERNAL_SHA256}
			 -DXZ_MICROLZMA_ENCODER:BOOL=${XZ_MICROLZMA_ENCODER} 
             -DXZ_MICROLZMA_DECODER:BOOL=${XZ_MICROLZMA_DECODER}
			 -DXZ_LZIP_DECODER:BOOL=${XZ_LZIP_DECODER}
			 -DXZ_TOOL_XZDEC:BOOL=${XZ_TOOL_XZDEC}
			 -DXZ_TOOL_LZMADEC:BOOL=${XZ_TOOL_LZMADEC}
			 -DXZ_TOOL_LZMAINFO:BOOL=${XZ_TOOL_LZMAINFO}
			 -DXZ_TOOL_XZ:BOOL=${XZ_TOOL_XZ}
			 -DXZ_DOC:BOOL=${XZ_DOC}
  
  OVERRIDE_FIND_PACKAGE
)

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
    target_include_directories(LibLZMA::LibLZMA INTERFACE $<BUILD_INTERFACE:${LibLZMA_INCLUDE_DIR}>)
	target_link_libraries(LibLZMA::LibLZMA INTERFACE $<BUILD_INTERFACE:${LibLZMA_LIBRARY}>)
endif()

set(LIBLZMA_INCLUDE_DIR ${LibLZMA_INCLUDE_DIR} CACHE PATH "liblzma include directory" FORCE)
set(LIBLZMA_LIBRARY ${LibLZMA_LIBRARY} CACHE FILEPATH "liblzma library" FORCE)

# include_directories(${LibLZMA_INCLUDE_DIR})
# link_libraries(${LibLZMA_LIBRARY})

######################## lz4
set(LZ4_BUILD_CLI OFF CACHE BOOL "Build lz4 program" FORCE)
set(LZ4_BUILD_LEGACY_LZ4C OFF CACHE BOOL "Build lz4c program with legacy argument support" FORCE)
set(LZ4_POSITION_INDEPENDENT_LIB ON CACHE BOOL "Use position independent code for static library (if applicable)" FORCE)

FetchContent_Declare(
  lz4
  GIT_REPOSITORY https://github.com/lz4/lz4.git
  GIT_TAG        v1.10.0
  GIT_SHALLOW    TRUE
  
  SOURCE_SUBDIR  build/cmake
  
  CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=ON
             -DLZ4_BUILD_CLI:BOOL=${LZ4_BUILD_CLI}
			 -DLZ4_BUILD_LEGACY_LZ4C:BOOL=${LZ4_BUILD_LEGACY_LZ4C}
			 -DLZ4_POSITION_INDEPENDENT_LIB:BOOL=${LZ4_POSITION_INDEPENDENT_LIB}
             -DBUILD_STATIC_LIBS:BOOL=ON
			 -DBUILD_SHARED_LIBS:BOOL=OFF
			 
  OVERRIDE_FIND_PACKAGE
)

FetchContent_MakeAvailable(lz4)

file(REAL_PATH ${lz4_SOURCE_DIR}/lib LZ4_INCLUDE_DIR)
file(REAL_PATH ${lz4_SOURCE_DIR} LZ4_SOURCE_DIR)
file(REAL_PATH ${lz4_BINARY_DIR} LZ4_BINARY_DIR)

set(LZ4_LIBRARY ${LZ4_BINARY_DIR}/$<CONFIG>/lz4.lib CACHE FILEPATH "lz4 library" FORCE)

######################## lzo
FetchContent_Declare(
  lzo2
  URL      https://www.oberhumer.com/opensource/lzo/download/lzo-2.10.tar.gz
  URL_HASH SHA256=c0f892943208266f9b6543b3ae308fab6284c5c90e627931446fb49b4221a072
 
  CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE=ON
             -DENABLE_STATIC=ON
			 -DENABLE_SHARED=OFF
			 
  OVERRIDE_FIND_PACKAGE
)

FetchContent_MakeAvailable(lzo2)

file(REAL_PATH ${lzo2_SOURCE_DIR}/include LZO2_INCLUDE_DIR)
file(REAL_PATH ${lzo2_SOURCE_DIR} LZO2_SOURCE_DIR)
file(REAL_PATH ${lzo2_BINARY_DIR} LZO2_BINARY_DIR)

set(LZO2_LIBRARY ${LZO2_BINARY_DIR}/$<CONFIG>/lzo2.lib CACHE FILEPATH "lzo2 library" FORCE)

######################## zstd
set(ZSTD_LEGACY_SUPPORT ON CACHE BOOL "Enable legacy format support" FORCE)
set(ZSTD_FRAMEWORK OFF CACHE BOOL "Build as Apple Framework" FORCE)
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

FetchContent_Declare(
  zstd
  GIT_REPOSITORY https://github.com/facebook/zstd.git
  GIT_TAG        v1.5.7
  GIT_SHALLOW    TRUE
  
  SOURCE_SUBDIR build/cmake
  
  CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=ON
             -DZSTD_LEGACY_SUPPORT:BOOL=${ZSTD_LEGACY_SUPPORT}
			 -DZSTD_FRAMEWORK:BOOL=${ZSTD_FRAMEWORK} 
             -DZSTD_MULTITHREAD_SUPPORT:BOOL=${ZSTD_MULTITHREAD_SUPPORT}
			 -DZSTD_BUILD_PROGRAMS:BOOL=${ZSTD_BUILD_PROGRAMS}
			 -DZSTD_BUILD_CONTRIB:BOOL=${ZSTD_BUILD_CONTRIB}
			 -DZSTD_PROGRAMS_LINK_SHARED:BOOL=${ZSTD_PROGRAMS_LINK_SHARED}
			 -DZSTD_BUILD_TESTS:BOOL=${ZSTD_BUILD_TESTS}
			 -DZSTD_BUILD_STATIC:BOOL=${ZSTD_BUILD_STATIC}
			 -DZSTD_BUILD_SHARED:BOOL=${ZSTD_BUILD_SHARED}
			 -DZSTD_BUILD_COMPRESSION:BOOL=${ZSTD_BUILD_COMPRESSION}
			 -DZSTD_BUILD_DECOMPRESSION:BOOL=${ZSTD_BUILD_DECOMPRESSION}
			 -DZSTD_BUILD_DICTBUILDER:BOOL=${ZSTD_BUILD_DICTBUILDER}
			 -DZSTD_BUILD_DEPRECATED:BOOL=${ZSTD_BUILD_DEPRECATED}

  OVERRIDE_FIND_PACKAGE
)

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
	target_include_directories(zstd::libzstd_static INTERFACE $<BUILD_INTERFACE:${ZSTD_INCLUDE_DIR}>)
	target_link_libraries(zstd::libzstd_static INTERFACE $<BUILD_INTERFACE:${ZSTD_LIBRARY}>)
endif()

######################## win-iconv
set(WIN_ICONV_BUILD_TEST OFF CACHE BOOL "build test executable" FORCE)
set(WIN_ICONV_BUILD_STATIC ON CACHE BOOL "build the static library" FORCE)
set(WIN_ICONV_BUILD_SHARED OFF CACHE BOOL "build the shared library" FORCE)
set(WIN_ICONV_BUILD_EXECUTABLE OFF CACHE BOOL "build the win_iconv executable" FORCE)

FetchContent_Declare(
  iconv
  GIT_REPOSITORY https://github.com/win-iconv/win-iconv.git
  GIT_TAG        82f00fbc1b1156530a0bbd003b93b3942743ed27
  GIT_SHALLOW    TRUE
  
  CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=ON
             -DWIN_ICONV_BUILD_TEST:BOOL=${WIN_ICONV_BUILD_TEST}
			 -DWIN_ICONV_BUILD_STATIC:BOOL=${WIN_ICONV_BUILD_STATIC} 
             -DWIN_ICONV_BUILD_SHARED:BOOL=${WIN_ICONV_BUILD_SHARED}
			 -DWIN_ICONV_BUILD_EXECUTABLE:BOOL=${WIN_ICONV_BUILD_EXECUTABLE}
			 -DDISABLE_LOCALE_CHARSET:BOOL=OFF
			 
  OVERRIDE_FIND_PACKAGE

)

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
	target_include_directories(Iconv::Iconv INTERFACE $<BUILD_INTERFACE:${Iconv_INCLUDE_DIR}>)
	target_link_libraries(Iconv::Iconv INTERFACE $<BUILD_INTERFACE:${Iconv_LIBRARY}>)
endif()

# include_directories(${Iconv_INCLUDE_DIR})
# link_libraries(${Iconv_LIBRARY})

######################## libxml2
set(LIBXML2_WITH_CATALOG ON CACHE BOOL "Add the Catalog support" FORCE)
set(LIBXML2_WITH_DEBUG OFF CACHE BOOL "Add the debugging module" FORCE)
set(LIBXML2_WITH_HTML ON CACHE BOOL "Add the HTML support" FORCE)
set(LIBXML2_WITH_HTTP OFF CACHE BOOL "Add the HTTP support" FORCE)
set(LIBXML2_WITH_ICONV ON CACHE BOOL "Add ICONV support" FORCE)
set(LIBXML2_WITH_ICU OFF CACHE BOOL "Add ICU support" FORCE)
set(LIBXML2_WITH_ISO8859X ON CACHE BOOL "Add ISO8859X support if no iconv" FORCE)
set(LIBXML2_WITH_LEGACY OFF CACHE BOOL "Add deprecated APIs for compatibility" FORCE)
set(LIBXML2_WITH_LZMA ON CACHE BOOL "Use liblzma" FORCE)
set(LIBXML2_WITH_MODULES ON CACHE BOOL "Add the dynamic modules support" FORCE)
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


set(CMAKE_INSTALL_FULL_LIBDIR ${CMAKE_BINARY_DIR}/lib CACHE PATH "CMAKE INSTALL FULL PATH" FORCE)


FetchContent_Declare(
  libxml2
  GIT_REPOSITORY https://github.com/sheldonrobinson/libxml2.git
  GIT_TAG        4c48944bd54294d30d0ca386ac0124f7824e4fd8 #v2.14.5
  GIT_SHALLOW    TRUE
 
  CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=ON
			 -DCMAKE_INSTALL_FULL_LIBDIR:PATH=${CMAKE_INSTALL_FULL_LIBDIR}
             -DBUILD_SHARED_LIBS:BOOL=OFF
             -DLIBXML2_WITH_CATALOG:BOOL=${LIBXML2_WITH_CATALOG}
			 -DLIBXML2_WITH_DEBUG:BOOL=${LIBXML2_WITH_DEBUG}
             -DLIBXML2_WITH_HTML:BOOL=${LIBXML2_WITH_HTML}
			 -DLIBXML2_WITH_HTTP:BOOL=${LIBXML2_WITH_HTTP}
			 -DLIBXML2_WITH_ICONV:BOOL=${LIBXML2_WITH_ICONV}
			 -DLIBXML2_WITH_ICU:BOOL=${LIBXML2_WITH_ICU}
			 -DLIBXML2_WITH_ISO8859X:BOOL=${LIBXML2_WITH_ISO8859X}
             -DLIBXML2_WITH_LEGACY:BOOL=${LIBXML2_WITH_LEGACY}
			 -DLIBXML2_WITH_LZMA:BOOL=${LIBXML2_WITH_LZMA}
             -DLIBXML2_WITH_MODULES:BOOL=${LIBXML2_WITH_MODULES}
			 -DLIBXML2_WITH_OUTPUT:BOOL=${LIBXML2_WITH_OUTPUT}
			 -DLIBXML2_WITH_PATTERN:BOOL=${LIBXML2_WITH_PATTERN}
             -DLIBXML2_WITH_PROGRAMS:BOOL=${LIBXML2_WITH_PROGRAMS}
			 -DLIBXML2_WITH_PUSH:BOOL=${LIBXML2_WITH_PUSH} 
             -DLIBXML2_WITH_PYTHON:BOOL=${LIBXML2_WITH_PYTHON}
			 -DLIBXML2_WITH_READLINE:BOOL=${LIBXML2_WITH_READLINE}
			 -DLIBXML2_WITH_REGEXPS:BOOL=${LIBXML2_WITH_REGEXPS}
             -DLIBXML2_WITH_SAX1:BOOL=${LIBXML2_WITH_SAX1}
			 -DLIBXML2_WITH_TESTS:BOOL=${LIBXML2_WITH_TESTS}
             -DLIBXML2_WITH_THREADS:BOOL=${LIBXML2_WITH_THREADS}
			 -DLIBXML2_WITH_TLS:BOOL=${LIBXML2_WITH_TLS}
			 -DLIBXML2_WITH_VALID:BOOL=${LIBXML2_WITH_VALID}
			 -DLIBXML2_WITH_XINCLUDE:BOOL=${LIBXML2_WITH_XINCLUDE}
			 -DLIBXML2_WITH_XPATH:BOOL=${LIBXML2_WITH_XPATH}
			 -DIconv_INCLUDE_DIR:PATH=${Iconv_INCLUDE_DIR}
			 -DIconv_LIBRARY:FILEPATH=${Iconv_LIBRARY}
			 -DLibLZMA_INCLUDE_DIR:PATH=${LibLZMA_INCLUDE_DIR}
			 -DLibLZMA_LIBRARY:FILEPATH=${LibLZMA_LIBRARY}
			 -DZLIB_INCLUDE_DIR:PATH=${ZLIB_INCLUDE_DIR}
			 -DZLIB_LIBRARY:FILEPATH=${ZLIB_LIBRARY}

  OVERRIDE_FIND_PACKAGE
)

FetchContent_MakeAvailable(libxml2 iconv zlib liblzma)

target_include_directories(LibXml2 PRIVATE ${ZLIB_BINARY_DIR} ${ZLIB_INCLUDE_DIR} ${LibLZMA_INCLUDE_DIR} ${Iconv_INCLUDE_DIR})
add_dependencies(LibXml2 iconv_static zlibstatic liblzma)

file(REAL_PATH ${libxml2_SOURCE_DIR}/include LibXml2_INCLUDE_DIR)
file(REAL_PATH ${libxml2_SOURCE_DIR} LibXml2_SOURCE_DIR)
file(REAL_PATH ${libxml2_BINARY_DIR} LibXml2_BINARY_DIR)

set(LibXml2_LIBRARY ${LibXml2_BINARY_DIR}/$<CONFIG>/libxml2s$<$<CONFIG:Debug>:${CMAKE_DEBUG_POSTFIX}>.lib CACHE FILEPATH "libxml2 library" FORCE)

######################## pcre2posix
set(PCRE2_STATIC_PIC ON CACHE BOOL "Build the static library with the option position independent code enabled." FORCE)
set(PCRE2_SHOW_REPORT ON CACHE BOOL "Show the final configuration report" FORCE)
set(PCRE2_BUILD_PCRE2GREP OFF CACHE BOOL "Build pcre2grep" FORCE)
set(PCRE2_BUILD_TESTS OFF CACHE BOOL "Build the tests" FORCE)
set(PCRE2_SUPPORT_LIBEDIT OFF CACHE BOOL "Enable support for linking pcre2test with libedit." FORCE)
set(PCRE2_SUPPORT_LIBREADLINE OFF CACHE BOOL "Enable support for linking pcre2test with libreadline." FORCE)
set(PCRE2_BUILD_PCRE2_8 ON CACHE BOOL "Build 8 bit PCRE2 library" FORCE)
set(PCRE2_BUILD_PCRE2_16 OFF CACHE BOOL "Build 16 bit PCRE2 library" FORCE)
set(PCRE2_BUILD_PCRE2_32 OFF CACHE BOOL "Build 32 bit PCRE2 library" FORCE)

FetchContent_Declare(
  pcre2posix
  GIT_REPOSITORY https://github.com/PCRE2Project/pcre2.git
  GIT_TAG        pcre2-10.45
  GIT_SHALLOW    TRUE

  
  CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE=ON
             -DBUILD_SHARED_LIBS=OFF
             -DBUILD_STATIC_LIBS=ON
             -DPCRE2_STATIC_PIC=${PCRE2_STATIC_PIC}
             -DPCRE2_SHOW_REPORT=${PCRE2_SHOW_REPORT}
			 -DPCRE2_BUILD_PCRE2_8=${PCRE2_BUILD_PCRE2_8}
			 -PCRE2_BUILD_PCRE2_16=${PCRE2_BUILD_PCRE2_16}
			 -DPCRE2_BUILD_PCRE2_32=${PCRE2_BUILD_PCRE2_32}
			 -DPCRE2_BUILD_PCRE2GREP=${PCRE2_BUILD_PCRE2GREP}
			 -DPCRE2_BUILD_TESTS=${PCRE2_BUILD_TESTS}
			 -DPCRE2_SUPPORT_LIBEDIT=${PCRE2_SUPPORT_LIBEDIT}
			 -DPCRE2_SUPPORT_LIBREADLINE=${PCRE2_SUPPORT_LIBREADLINE}		 
			 -DBZIP2_INCLUDE_DIR=${BZIP2_INCLUDE_DIR}
			 -DBZIP2_LIBRARY=${BZIP2_LIBRARY}	
			 -DZLIB_INCLUDE_DIR=${ZLIB_INCLUDE_DIR}
			 -DZLIB_LIBRARY=${ZLIB_LIBRARY}

  OVERRIDE_FIND_PACKAGE			 
)

FetchContent_MakeAvailable(pcre2posix zlib bzip2)

target_include_directories(pcre2-posix-static PRIVATE ${BZIP2_BINARY_DIR} ${ZLIB_BINARY_DIR})
add_dependencies(pcre2-posix-static zlibstatic bz2_static)

file(REAL_PATH ${pcre2posix_SOURCE_DIR}/src PCRE2POSIX_INCLUDE_DIR)
file(REAL_PATH ${pcre2posix_SOURCE_DIR} PCRE2POSIX_SOURCE_DIR)
file(REAL_PATH ${pcre2posix_BINARY_DIR} PCRE2POSIX_BINARY_DIR)

set(PCRE2_LIBRARY ${PCRE2POSIX_BINARY_DIR}/$<CONFIG>/pcre2-posix-static.lib CACHE FILEPATH "pcre2posix library" FORCE)


######################## libzip
# ExternalProject_Add(
  # libzip
  # GIT_REPOSITORY https://github.com/nih-at/libzip.git
  # GIT_TAG        v1.11.4
  # GIT_SHALLOW    TRUE
  
  # CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE=ON
             # -DENABLE_MBEDTLS=OFF
             # -DENABLE_OPENSSL=OFF
			 # -DENABLE_GNUTLS=OFF
			 # -DENABLE_COMMONCRYPTO=OFF
			 # -DENABLE_WINDOWS_CRYPTO=ON
			 # -DENABLE_LZMA=ON
			 # -DENABLE_ZSTD=ON
			 # -DENABLE_BZIP2=ON
			 # -DENABLE_FDOPEN=OFF
			 # -DBUILD_TOOLS=OFF
			 # -DBUILD_REGRESS=OFF
			 # -DBUILD_OSSFUZZ=OFF
			 # -DBUILD_EXAMPLES=OFF
			 # -DBUILD_DOC=OFF
			 # -DBUILD_SHARED_LIBS=OFF
	 
  # OVERRIDE_FIND_PACKAGE
# )

# file(REAL_PATH ${libzip_SOURCE_DIR}/src LIBZIP_INCLUDE_DIR)
# file(REAL_PATH ${libzip_SOURCE_DIR} LIBZIP_SOURCE_DIR)
# file(REAL_PATH ${libzip_BINARY_DIR} LIBZIP_BINARY_DIR)

# set(LIBZIP_LIBRARY ${LIBZIP_BINARY_DIR}/$<CONFIG>/zip.lib CACHE FILEPATH "zip library" FORCE)

######################## libarchive
set(ENABLE_TEST OFF CACHE BOOL "Enable testing." FORCE)

FetchContent_Declare(
  libarchive
  GIT_REPOSITORY https://github.com/libarchive/libarchive.git
  GIT_TAG        v3.8.1
  GIT_SHALLOW    TRUE
  
  CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE=ON
             -DBUILD_SHARED_LIBS=OFF
             -DENABLE_MBEDTLS=OFF
			 -DENABLE_NETTLE=OFF 
             -DENABLE_OPENSSL=OFF
			 -DENABLE_TEST=${ENABLE_TEST}
			 -DENABLE_LIBB2=OFF
			 -DENABLE_LZ4=ON
             -DENABLE_LZO=ON
			 -DENABLE_LZMA=ON
			 -DENABLE_ZSTD=ON
			 -DENABLE_ZLIB=ON
			 -DENABLE_BZip2=ON
             -DENABLE_LIBXML2=ON
			 -DENABLE_EXPAT=OFF
			 -DENABLE_WIN32_XMLLITE=OFF
			 -DENABLE_PCREPOSIX=OFF
			 -DENABLE_PCRE2POSIX=ON
			 -DENABLE_LIBGCC=OFF
			 -DENABLE_TAR=OFF
			 -DENABLE_TAR_SHARED=OFF
			 -DENABLE_CPIO=OFF
			 -DENABLE_CPIO_SHARED=OFF
			 -DENABLE_CAT=OFF
			 -DENABLE_CAT_SHARED=OFF
			 -DENABLE_XATTR=OFF
			 -DENABLE_ACL=OFF
			 -DENABLE_ICONV=ON
			 -DENABLE_COVERAGE=OFF
			 -DENABLE_INSTALL=OFF
			 -DZLIB_INCLUDE_DIR=${ZLIB_INCLUDE_DIR}
			 -DZLIB_LIBRARY=${ZLIB_LIBRARY}
			 -DZLIB_LIBRARIES=${ZLIB_LIBRARY}
			 -DBZIP2_INCLUDE_DIR=${BZIP2_INCLUDE_DIR}
			 -DBZIP2_LIBRARY=${BZIP2_LIBRARY}
			 -DBZIP2_LIBRARIES=${BZIP2_LIBRARY}
			 -DICONV_INCLUDE_DIR=${Iconv_INCLUDE_DIR}
			 -DLIBICONV_PATH=${Iconv_LIBRARY}
			 -DLIBLZMA_INCLUDE_DIR=${LibLZMA_INCLUDE_DIR}
			 -DLIBLZMA_LIBRARY=${LibLZMA_LIBRARY}
			 -DLIBLZMA_INCLUDE_DIRS=${LibLZMA_INCLUDE_DIR}
			 -DLIBLZMA_LIBRARIES=${LibLZMA_LIBRARY}
			 -DPCRE2POSIX_INCLUDE_DIR=${PCRE2POSIX_INCLUDE_DIR}
			 -DPCRE2_INCLUDE_DIR=${PCRE2POSIX_BINARY_DIR}
			 -DPCRE2_LIBRARY=${PCRE2_LIBRARY}
			 -DPCRE2POSIX_LIBRARIES=${PCRE2_LIBRARY}
			 -DPCRE2POSIX_LIBRARIES=${PCRE2_LIBRARY}
			 -DLIBXML2_LIBRARY=${LibXml2_LIBRARY}
			 -DLIBXML2_INCLUDE_DIR=${LibXml2_INCLUDE_DIR}
			 -DLIBXML2_LIBRARIES=${LibXml2_LIBRARY}
			 -DZSTD_INCLUDE_DIR=${ZSTD_INCLUDE_DIR}
			 -DZSTD_LIBRARY=${ZSTD_LIBRARY}
			 -DLZO2_INCLUDE_DIR=${LZO2_INCLUDE_DIR}
			 -DLZO2_LIBRARY=${LZO2_LIBRARY}
			 -DLZ4_INCLUDE_DIR=${LZ4_INCLUDE_DIR}
			 -DLZ4_LIBRARY=${LZ4_LIBRARY}

   OVERRIDE_FIND_PACKAGE
)

FetchContent_MakeAvailable(libarchive libxml2 iconv pcre2posix liblzma zlib bzip2 zstd lzo2 lz4 )

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
target_link_libraries(archive_static 
	${ZLIB_LIBRARY}
	${BZIP2_LIBRARY}
	${Iconv_LIBRARY}
	${LibLZMA_LIBRARY}
	${PCRE2_LIBRARY}
	${LibXml2_LIBRARY}
	${ZSTD_LIBRARY}
	${LZO2_LIBRARY}
	${LZ4_LIBRARY}
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
						     archive_static
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
							)
	target_include_directories(LibArchive::LibArchive 
						INTERFACE
							$<BUILD_INTERFACE:${LIBARCHIVE_INCLUDE_DIR}>
							$<BUILD_INTERFACE:${ZSTD_INCLUDE_DIR}>
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
						)
	target_link_libraries(LibArchive::LibArchive 
						INTERFACE
							$<BUILD_INTERFACE:${LIBARCHIVE_LIBRARY}>
							$<BUILD_INTERFACE:${ZSTD_LIBRARY}>
							$<BUILD_INTERFACE:${ZLIB_LIBRARY}>
							$<BUILD_INTERFACE:${BZIP2_LIBRARY}>
							$<BUILD_INTERFACE:${Iconv_LIBRARY}>
							$<BUILD_INTERFACE:${LibLZMA_LIBRARY}>
							$<BUILD_INTERFACE:${PCRE2_LIBRARY}>
							$<BUILD_INTERFACE:${LibXml2_LIBRARY}>
							$<BUILD_INTERFACE:${ZSTD_LIBRARY}>
							$<BUILD_INTERFACE:${LZO2_LIBRARY}>
							$<BUILD_INTERFACE:${LZ4_LIBRARY}>
						)
endif()


# include_directories(${LIBARCHIVE_INCLUDE_DIR})
# link_libraries(${LIBARCHIVE_LIBRARY})

####################### libpng
set(PNG_SHARED OFF CACHE BOOL "Build libpng as a shared library" FORCE)
set(PNG_STATIC ON CACHE BOOL "Build libpng as a static library" FORCE)
set(PNG_TESTS OFF CACHE BOOL "Build the libpng tests" FORCE)
set(PNG_TOOLS OFF CACHE BOOL "Build the libpng tools" FORCE)
set(PNG_HARDWARE_OPTIMIZATIONS ON CACHE BOOL "Enable hardware optimizations" FORCE)

FetchContent_Declare(
  png
  GIT_REPOSITORY https://github.com/pnggroup/libpng.git
  GIT_TAG        v1.6.50
  GIT_SHALLOW    TRUE
  
  CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE=ON
			 -DPNG_SHARED=${PNG_SHARED}
			 -DPNG_STATIC=${PNG_STATIC}
			 -DPNG_TESTS=${PNG_TESTS}
			 -DPNG_TOOLS=${PNG_TOOLS}
			 -DPNG_HARDWARE_OPTIMIZATIONS=${PNG_HARDWARE_OPTIMIZATIONS}
			 -DZLIB_INCLUDE_DIR=${ZLIB_INCLUDE_DIR}
			 -DZLIB_LIBRARY=${ZLIB_LIBRARY}
			 -DBUILD_SHARED_LIBS=OFF

   OVERRIDE_FIND_PACKAGE
)

FetchContent_MakeAvailable(png zlib)

target_include_directories(png_static PRIVATE ${ZLIB_BINARY_DIR})
add_dependencies(png_static zlibstatic)

file(REAL_PATH ${png_SOURCE_DIR} PNG_INCLUDE_DIR)
file(REAL_PATH ${png_SOURCE_DIR} PNG_SOURCE_DIR)
file(REAL_PATH ${png_BINARY_DIR} PNG_BINARY_DIR)

set(PNG_LIBRARY ${PNG_BINARY_DIR}/$<CONFIG>/libpng16_static.lib CACHE FILEPATH "libpng library" FORCE)

set(PNG_INCLUDE_DIRS ${PNG_INCLUDE_DIR} ${PNG_BINARY_DIR})

set(PNG_LIBRARIES ${PNG_LIBRARY})

if(NOT TARGET PNG)
	add_library(PNG INTERFACE IMPORTED)
    set_target_properties(PNG PROPERTIES
                          INTERFACE_LINK_LIBRARIES
						    png_static
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						 )
    target_include_directories(PNG
								INTERFACE
									$<BUILD_INTERFACE:${PNG_INCLUDE_DIR}>
									$<BUILD_INTERFACE:${PNG_BINARY_DIR}>
							  )
endif()

####################### harbuzz
set(HB_HAVE_CAIRO OFF CACHE BOOL "Enable cairo interop helpers" FORCE)
set(HB_HAVE_FREETYPE OFF CACHE BOOL "Enable freetype interop helpers" FORCE)
set(HB_HAVE_GRAPHITE2 OFF CACHE BOOL "Enable Graphite2 complementary shaper" FORCE)
set(HB_HAVE_GLIB OFF CACHE BOOL "Enable glib unicode functions" FORCE)
set(HB_HAVE_ICU OFF CACHE BOOL "Enable icu unicode functions" FORCE)
set(HB_BUILD_SUBSET ON CACHE BOOL "Build harfbuzz-subset" FORCE)
set(HB_HAVE_GOBJECT OFF CACHE BOOL "Enable GObject Bindings" FORCE)
set(HB_HAVE_INTROSPECTIONHB_HAVE_INTROSPECTION OFF CACHE BOOL "Enable building introspection (.gir/.typelib) files" FORCE)

FetchContent_Declare(
  harfbuzz
  GIT_REPOSITORY https://github.com/harfbuzz/harfbuzz.git
  GIT_TAG        11.2.1
  GIT_SHALLOW    TRUE
  
  CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE=ON
			 -DHB_HAVE_CAIRO=${HB_HAVE_CAIRO}
			 -DHB_HAVE_FREETYPE=${HB_HAVE_FREETYPE}
			 -DHB_HAVE_GRAPHITE2=${HB_HAVE_GRAPHITE2}
			 -DHB_HAVE_GLIB=${HB_HAVE_GLIB}
			 -DHB_HAVE_ICU=${HB_HAVE_ICU}
			 -DHB_BUILD_SUBSET=${HB_BUILD_SUBSET}
			 -DHB_HAVE_GOBJECT=${HB_HAVE_GOBJECT}
			 -DHB_HAVE_INTROSPECTION=${HB_HAVE_GOBJECT}		 
			 -DBUILD_SHARED_LIBS=OFF
  
  OVERRIDE_FIND_PACKAGE
)

FetchContent_MakeAvailable(harfbuzz)

file(REAL_PATH ${harfbuzz_SOURCE_DIR}/src HarfBuzz_INCLUDE_DIR)
file(REAL_PATH ${harfbuzz_SOURCE_DIR} HarfBuzz_SOURCE_DIR)
file(REAL_PATH ${harfbuzz_BINARY_DIR} HarfBuzz_BINARY_DIR)


set(HarfBuzz_LIBRARY ${HarfBuzz_BINARY_DIR}/$<CONFIG>/harfbuzz.lib CACHE FILEPATH "harfbuzz library" FORCE)
set(HarfBuzz_INCLUDE_DIRS "${HarfBuzz_BINARY_DIR}/src" CACHE STRING "harfbuzz include directories" FORCE)
set(HarfBuzz_LIBRARIES "${HarfBuzz_BINARY_DIR}/$<CONFIG>/harfbuzz-subset.lib" CACHE STRING "harfbuzz modules" FORCE)

####################### brotli
set(BROTLI_BUILD_TOOLS OFF CACHE BOOL "Build/install CLI tools" FORCE)

FetchContent_Declare(
  brotli
  GIT_REPOSITORY https://github.com/google/brotli.git
  GIT_TAG        a47d7475063eb223c87632eed806c0070e70da29
  GIT_SHALLOW    TRUE

  CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE=ON
			 -DBROTLI_BUILD_TOOLS=${BROTLI_BUILD_TOOLS}
			 -DBUILD_SHARED_LIBS=OFF
 
  OVERRIDE_FIND_PACKAGE
)

FetchContent_MakeAvailable(brotli)

file(REAL_PATH ${brotli_SOURCE_DIR}/c/include BrotliDec_INCLUDE_DIR)
file(REAL_PATH ${brotli_SOURCE_DIR} BrotliDec_SOURCE_DIR)
file(REAL_PATH ${brotli_BINARY_DIR} BrotliDec_BINARY_DIR)

set(BrotliDec_LIBRARY ${BrotliDec_BINARY_DIR}/$<CONFIG>/brotlidec.lib CACHE FILEPATH "brotlidec library" FORCE)

####################### FreeType
set(FT_DISABLE_ZLIB OFF CACHE BOOL "Disable use of system zlib and use internal zlib library instead." FORCE)
set(FT_DISABLE_BZIP2 OFF CACHE BOOL "Disable support of bzip2 compressed fonts." FORCE)
set(FT_DISABLE_PNG OFF CACHE BOOL "Disable support of PNG compressed OpenType embedded bitmaps." FORCE)
set(FT_DISABLE_HARFBUZZ ON CACHE BOOL "Disable HarfBuzz (used for improving auto-hinting of OpenType fonts)." FORCE)
set(FT_DISABLE_BROTLI OFF CACHE BOOL "Disable support of compressed WOFF2 fonts." FORCE)
set(FT_ENABLE_ERROR_STRINGS OFF CACHE BOOL "Enable support for meaningful error descriptions." FORCE)

FetchContent_Declare(
  freetype
  GIT_REPOSITORY https://github.com/freetype/freetype.git
  GIT_TAG        VER-2-13-3
  GIT_SHALLOW    TRUE

  CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE=ON
             -DCMAKE_PREFIX_INSTALL=${CMAKE_CURRENT_BINARY_DIR}
			 -DBUILD_SAMPLES=OFF 
			 -DBUILD_SHARED_LIBS=ON
			 -DZLIB_INCLUDE_DIR=${ZLIB_INCLUDE_DIR}
			 -DZLIB_LIBRARY=${ZLIB_LIBRARY}
			 -DBZIP2_INCLUDE_DIR=${BZIP2_INCLUDE_DIR}
			 -DBZIP2_LIBRARY=${BZIP2_LIBRARY}
			 -DBrotliDec_INCLUDE_DIR=${BrotliDec_INCLUDE_DIR}
			 -DBrotliDec_LIBRARY=${BrotliDec_LIBRARY}
			 -DHarfBuzz_INCLUDE_DIR=${HarfBuzz_INCLUDE_DIR}
			 -DHarfBuzz_LIBRARY=${HarfBuzz_LIBRARY}
			 -DPNG_INCLUDE_DIR=${PNG_INCLUDE_DIR}
			 -DPNG_LIBRARY=${PNG_LIBRARY}
             -DPNG_INCLUDE_DIRS=${PNG_INCLUDE_DIRS}
			 -DPNG_LIBRARIES=${PNG_LIBRARIES}

  OVERRIDE_FIND_PACKAGE
)

FetchContent_MakeAvailable(freetype harfbuzz png zlib bzip2 brotli)

target_include_directories(freetype PRIVATE ${PNG_SOURCE_DIR} ${PNG_BINARY_DIR} ${HarfBuzz_BINARY_DIR}/src ${BZIP2_SOURCE_DIR} ${BZIP2_BINARY_DIR} ${ZLIB_SOURCE_DIR} ${ZLIB_BINARY_DIR})
add_dependencies(freetype png_static harfbuzz zlibstatic bz2_static)

file(REAL_PATH ${freetype_SOURCE_DIR}/include FREETYPE_INCLUDE_DIR)
file(REAL_PATH ${freetype_SOURCE_DIR} FREETYPE_SOURCE_DIR)
file(REAL_PATH ${freetype_BINARY_DIR} FREETYPE_BINARY_DIR)

set(FREETYPE_LIBRARY ${FREETYPE_BINARY_DIR}/$<CONFIG>/freetype.lib CACHE FILEPATH "freetype library" FORCE)

######################## magic_enum
set(MAGIC_ENUM_OPT_BUILD_EXAMPLES OFF CACHE BOOL "Build magic_enum examples" ${IS_TOPLEVEL_PROJECT})
set(MAGIC_ENUM_OPT_BUILD_TESTS OFF CACHE BOOL "Build and perform magic_enum tests" ${IS_TOPLEVEL_PROJECT})
set(MAGIC_ENUM_OPT_INSTALL OFF CACHE BOOL "Generate and install magic_enum target" ${IS_TOPLEVEL_PROJECT})
set(MAGIC_ENUM_OPT_INSTALL_PACKAGE_XML OFF CACHE BOOL "Include package.xml when installing" ${MAGIC_ENUM_OPT_INSTALL})
set(MAGIC_ENUM_OPT_TEST_INSTALLED_VERSION OFF CACHE BOOL "When configuring tests, try use a local magic_enum." FORCE)
set(MAGIC_ENUM_OPT_TEST_INSTALLED_VERSION_PKGCONFIG OFF CACHE BOOL "When configuring tests, try use a local magic_enum via pkgconfig" FORCE)

FetchContent_Declare(
  magic_enum
  GIT_REPOSITORY https://github.com/Neargye/magic_enum.git
  GIT_TAG        691cc4b2a4bc08ef35528da2af47d434160409d9
  GIT_SHALLOW    TRUE
  
  CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE=ON
             -DMAGIC_ENUM_OPT_BUILD_EXAMPLES=OFF
			 -DMAGIC_ENUM_OPT_BUILD_TESTS=OFF 
             -DMAGIC_ENUM_OPT_INSTALL=OFF
			 -DMAGIC_ENUM_OPT_INSTALL_PACKAGE_XML=OFF
			 -DMAGIC_ENUM_OPT_TEST_INSTALLED_VERSION=OFF
			 -DMAGIC_ENUM_OPT_TEST_INSTALLED_VERSION_PKGCONFIG=OFF
			 -DBUILD_SHARED_LIBS=OFF
			 
  OVERRIDE_FIND_PACKAGE
)

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

####################### dirent
FetchContent_Declare(
  dirent
  GIT_REPOSITORY https://github.com/tronkko/dirent.git
  GIT_TAG        31db6474b5231c180bd4618c8c90e43af50c86d0
  GIT_SHALLOW    TRUE
  
  CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE=ON
			 -DDIRENT_EXAMPLES="OFF"
			 -DDIRENT_TESTS="OFF"
			 -DBUILD_SHARED_LIBS=OFF

  OVERRIDE_FIND_PACKAGE
)

FetchContent_MakeAvailable(dirent)

file(REAL_PATH ${dirent_SOURCE_DIR}/include DIRENT_INCLUDE_DIR)
file(REAL_PATH ${dirent_SOURCE_DIR} DIRENT_SOURCE_DIR)

####################### file_windows
FetchContent_Declare(
  file-windows
  GIT_REPOSITORY https://github.com/sheldonrobinson/file-windows.git
  GIT_TAG        ec1dd39ecb682529719075142dd0ab871c786d37
  GIT_SHALLOW    TRUE
  
  CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE=ON
			 -DBUILD_TESTS=OFF
			 -DBUILD_SHARED_LIBS=OFF
			 
  FIND_PACKAGE_ARGS NAMES unofficial-libmagic
)

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

if(NOT TARGET unofficial-libmagic)
	add_library(unofficial-libmagic INTERFACE IMPORTED)
    set_target_properties(unofficial-libmagic PROPERTIES
                          INTERFACE_LINK_LIBRARIES
						    libmagic pcre2-posix-static dirent
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
							)
    target_include_directories(unofficial-libmagic 
								INTERFACE 
									$<BUILD_INTERFACE:${LIBMAGIC_INCLUDE_DIR}>
									$<BUILD_INTERFACE:${PCRE2POSIX_INCLUDE_DIR}>
									$<BUILD_INTERFACE:${PCRE2POSIX_BINARY_DIR}>
									$<BUILD_INTERFACE:${DIRENT_INCLUDE_DIR}>
							  )
	target_link_libraries(unofficial-libmagic 
							INTERFACE
								$<BUILD_INTERFACE:${LIGMAGIC_LIBRARY}>
								$<BUILD_INTERFACE:${PCRE2_LIBRARY}>
						)
endif()


if(NOT TARGET unofficial::libmagic::libmagic)
	add_library(unofficial::libmagic::libmagic INTERFACE IMPORTED)
    set_target_properties(unofficial::libmagic::libmagic PROPERTIES
                          INTERFACE_LINK_LIBRARIES
						    libmagic pcre2-posix-static dirent
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
							)
    target_include_directories(unofficial::libmagic::libmagic 
								INTERFACE 
									$<BUILD_INTERFACE:${LIBMAGIC_INCLUDE_DIR}>
									$<BUILD_INTERFACE:${PCRE2POSIX_INCLUDE_DIR}>
									$<BUILD_INTERFACE:${PCRE2POSIX_BINARY_DIR}>
									$<BUILD_INTERFACE:${DIRENT_INCLUDE_DIR}>
							  )
	target_link_libraries(unofficial::libmagic::libmagic 
							INTERFACE
								$<BUILD_INTERFACE:${LIGMAGIC_LIBRARY}>
								$<BUILD_INTERFACE:${PCRE2_LIBRARY}>
						)
endif()

######################## boost
set(BOOST_FILESYSTEM_NO_DEPRECATED ON CACHE BOOL "Disable deprecated functionality of Boost.Filesystem" FORCE)
set(BOOST_FILESYSTEM_DISABLE_SENDFILE ON CACHE BOOL "Disable usage of sendfile API in Boost.Filesystem" FORCE)
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

set(BOOST_IOSTREAMS_ENABLE_ZLIB ON CACHE BOOL "Boost.Iostreams: Enable ZLIB support" FORCE)
set(BOOST_IOSTREAMS_ENABLE_BZIP2 ON CACHE BOOL "Boost.Iostreams: Enable BZip2 support" FORCE)
set(BOOST_IOSTREAMS_ENABLE_LZMA ON CACHE BOOL "Boost.Iostreams: Enable LZMA support" FORCE)
set(BOOST_IOSTREAMS_ENABLE_ZSTD ON CACHE BOOL "Boost.Iostreams: Enable Zstd support" FORCE)
set(BOOST_IOSTREAMS_ZSTD_TARGET "zstd::libzstd_static" CACHE STRING "Target name for Zstd (zstd::libzstd_shared, zstd::libzstd_static)" FORCE)

set(BOOST_DLL_USE_STD_FS ON CACHE BOOL "Use std::filesystem instead of Boost.Filesystem" FORCE)

FetchContent_Declare(
  boost
  GIT_REPOSITORY https://github.com/boostorg/boost.git
  GIT_TAG        boost-1.88.0
  GIT_SHALLOW    TRUE
  
  CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE=ON
             -DBOOST_ALL_NO_LIB=ON
			 -DBOOST_JSON_NO_LIB=ON 
             -DBOOST_CONTAINER_NO_LIB=ON
			 -DBOOST_FILESYSTEM_SOURCE=ON
			 -DBOOST_FILESYSTEM_NO_LIB=ON
			 -DBOOST_FILESYSTEM_VERSION=4
			 -DBOOST_FILESYSTEM_STATIC_LINK=1
			 -DBOOST_FILESYSTEM_NO_DEPRECATED=${BOOST_FILESYSTEM_NO_DEPRECATED}
			 -DBOOST_FILESYSTEM_DISABLE_SENDFILE=${BOOST_FILESYSTEM_DISABLE_SENDFILE}
			 -DBOOST_FILESYSTEM_DISABLE_COPY_FILE_RANGE=${BOOST_FILESYSTEM_DISABLE_COPY_FILE_RANGE}
			 -DBOOST_FILESYSTEM_DISABLE_STATX=${BOOST_FILESYSTEM_DISABLE_STATX}
			 -DBOOST_FILESYSTEM_DISABLE_GETRANDOM=${BOOST_FILESYSTEM_DISABLE_GETRANDOM}
			 -DBOOST_FILESYSTEM_DISABLE_ARC4RANDOM=${BOOST_FILESYSTEM_DISABLE_ARC4RANDOM}	 
			 -DBOOST_FILESYSTEM_DISABLE_BCRYPT=${BOOST_FILESYSTEM_DISABLE_BCRYPT}
			 -DBOOST_FILESYSTEM_DISABLE_EMSCRIPTEN_WASI=${BOOST_FILESYSTEM_EMSCRIPTEN_USE_WASI}
			 -DBOOST_IOSTREAMS_ENABLE_ZLIB=${BOOST_IOSTREAMS_ENABLE_ZLIB}
			 -DBOOST_IOSTREAMS_ENABLE_BZIP2=${BOOST_IOSTREAMS_ENABLE_BZIP2}
			 -DBOOST_IOSTREAMS_ENABLE_LZMA=${BOOST_IOSTREAMS_ENABLE_LZMA}
			 -DBOOST_IOSTREAMS_ENABLE_ZSTD=${BOOST_IOSTREAMS_ENABLE_ZSTD}
			 -DBOOST_IOSTREAMS_ZSTD_TARGET=${BOOST_IOSTREAMS_ZSTD_TARGET}
			 -DBOOST_JSON_INSTALL=${BOOST_JSON_INSTALL}
			 -DBOOST_JSON_BUILD_TESTS=${BOOST_JSON_BUILD_TESTS}
			 -DBOOST_JSON_BUILD_FUZZERS=${BOOST_JSON_BUILD_FUZZERS}
			 -DBOOST_JSON_BUILD_EXAMPLES=${BOOST_JSON_BUILD_EXAMPLES}
			 -DBOOST_JSON_BUILD_BENCHMARKS=${BOOST_JSON_BUILD_BENCHMARKS}
			 -DBOOST_DLL_USE_STD_FS=${BOOST_DLL_USE_STD_FS}
			 
  OVERRIDE_FIND_PACKAGE
)

FetchContent_MakeAvailable(boost iconv liblzma zstd zlib bzip2)


file(REAL_PATH ${boost_SOURCE_DIR} BOOST_SOURCE_DIR)
file(REAL_PATH ${boost_BINARY_DIR} BOOST_BINARY_DIR)

target_include_directories(boost_iostreams PRIVATE ${LibLZMA_INCLUDE_DIR} ${ZSTD_INCLUDE_DIR} ${BZIP2_SOURCE_DIR} ${BZIP2_BINARY_DIR} ${ZLIB_SOURCE_DIR} ${ZLIB_BINARY_DIR})
add_dependencies(boost_iostreams iconv_static zlibstatic bz2_static libzstd_static liblzma)

target_include_directories(boost_locale PRIVATE ${Iconv_INCLUDE_DIR})
add_dependencies(boost_locale iconv_static)

set(boost_algorithm_inc_dir ${BOOST_SOURCE_DIR}/libs/algorithm/include CACHE PATH "Boost Algorithm include directory" FORCE)

####################### xpdf
set(XPDFWIDGET_PRINTING OFF CACHE BOOL "include printing support in XpdfWidget" FORCE)
set(PNG_INCLUDE_DIRS ${CMAKE_CURRENT_BINARY_DIR}/include CACHE PATH "libpng include dir" FORCE)
FetchContent_Declare(
  xpdf-project
  URL      https://dl.xpdfreader.com/xpdf-4.05.tar.gz
  URL_HASH SHA256=92707ed5acb6584fbd73f34091fda91365654ded1f31ba72f0970022cf2a5cea
  
  CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE=ON
             -DCMAKE_DISABLE_FIND_PACKAGE_Qt4=1
			 -DCMAKE_DISABLE_FIND_PACKAGE_Qt5Widgets=1
             -DMULTITHREADED=ON
			 -DSPLASH_CMYK=OFF
			 -DNO_FONTCONFIG=ON
			 -DNO_TEXT_SELECT=ON
			 -DXPDFWIDGET_PRINTING=OFF
			 -DA4_PAPER=OFF
			 -DOPI_SUPPORT=OFF
			 -DUSE_EXCEPTIONS=ON
			 -DUSE_FIXEDPOINT=OFF
			 -DBUILD_SHARED_LIBS=OFF
			 -DZLIB_INCLUDE_DIR=${ZLIB_INCLUDE_DIR}
			 -DZLIB_LIBRARY=${ZLIB_LIBRARY}
             -DPNG_INCLUDE_DIR=${PNG_INCLUDE_DIR}
			 -DPNG_LIBRARY=${PNG_LIBRARY}
             -DPNG_INCLUDE_DIRS=${PNG_BINARY_DIR}
             -DFREETYPE_INCLUDE_DIR=${FREETYPE_INCLUDE_DIR}
             -DFREETYPE_LIBRARY=${FREETYPE_LIBRARY}
			 
  OVERRIDE_FIND_PACKAGE
			 
)

FetchContent_MakeAvailable(xpdf-project file-windows freetype png zlib)

file(REAL_PATH ${xpdf-project_SOURCE_DIR}/xpdf XPDF_INCLUDE_DIR)
file(REAL_PATH ${xpdf-project_SOURCE_DIR} XPDF_SOURCE_DIR)
file(REAL_PATH ${xpdf-project_BINARY_DIR} XPDF_BINARY_DIR)

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

if(NOT TARGET libxpdf)

	add_library(libxpdf STATIC $<TARGET_OBJECTS:xpdf_objs>)

	target_include_directories(libxpdf
		INTERFACE
			$<BUILD_INTERFACE:${XPDF_SOURCE_DIR}>
			$<BUILD_INTERFACE:${XPDF_SOURCE_DIR}/fofi>
			$<BUILD_INTERFACE:${XPDF_SOURCE_DIR}/goo>
			$<BUILD_INTERFACE:${XPDF_SOURCE_DIR}/splash>
	)

	target_link_libraries(libxpdf
			libmagic
			freetype
			zlibstatic
			png_static
	)
endif()

######################## libxlsxwriter
FetchContent_Declare(
  libxlsxwriter
  GIT_REPOSITORY https://github.com/jmcnamara/libxlsxwriter.git
  GIT_TAG        f6e8305d1b70610705e03c15f337ce317c46be8a
  GIT_SHALLOW    TRUE
  
  CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE=ON
			 -DUSE_SYSTEM_MINIZIP=ON
			 -DUSE_STANDARD_TMPFILE=OFF
			 -DUSE_OPENSSL_MD5=OFF
			 -DUSE_DTOA_LIBRARY=ON
			 -DUSE_MEM_FILE=OFF
			 -DBUILD_TESTS=OFF
			 -DBUILD_EXAMPLES=OFF
			 -DBUILD_FUZZERS=OFF
			 -DBUILD_SHARED_LIBS=OFF
			 -DZLIB_INCLUDE_DIR=${ZLIB_INCLUDE_DIR}
			 -DZLIB_LIBRARY=${ZLIB_LIBRARY}
)

FetchContent_MakeAvailable(libxlsxwriter zlib bzip2)

target_include_directories(xlsxwriter PRIVATE ${ZLIB_INCLUDE_DIR}/contrib/minzip ${ZLIB_INCLUDE_DIR} ${ZLIB_BINARY_DIR} ${BZIP2_INCLUDE_DIR} ${BZIP2_BINARY_DIR})
add_dependencies(xlsxwriter  libminizipstatic  zlibstatic bz2_static)

file(REAL_PATH ${libxlsxwriter_SOURCE_DIR} XLSXWRITER_INCLUDE_DIR)
file(REAL_PATH ${libxlsxwriter_SOURCE_DIR} XLSXWRITER_SOURCE_DIR)
file(REAL_PATH ${libxlsxwriter_BINARY_DIR} XLSXWRITER_BINARY_DIR)

####################### zip
# set(ZIP_STATIC_PIC ON CACHE BOOL "Build static zip with PIC" FORCE)
# set(ZIP_BUILD_DOCS OFF CACHE BOOL "Generate API documentation with Doxygen" FORCE)
# set(ZIP_BUILD_FUZZ OFF CACHE BOOL "Build fuzz targets" FORCE)

# FetchContent_Declare(
  # zip
  # GIT_REPOSITORY https://github.com/kuba--/zip.git
  # GIT_TAG        v0.3.5
  # GIT_SHALLOW    TRUE
  
  # CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE=ON
			 # -DCMAKE_ENABLE_SANITIZERS=OFF
			 # -DBUILD_TESTS=OFF
			 # -DBUILD_SHARED_LIBS=OFF
			 # -DZIP_STATIC_PIC=${ZIP_STATIC_PIC}
			 # -DZIP_BUILD_DOCS=${ZIP_BUILD_DOCS}
			 # -DZIP_BUILD_FUZZ=${ZIP_BUILD_FUZZ}
			 
#	OVERRIDE_FIND_PACKAGE
# )

# FetchContent_MakeAvailable(zip)


# file(REAL_PATH ${zip_SOURCE_DIR}/src ZIP_INCLUDE_DIR)
# file(REAL_PATH ${zip_SOURCE_DIR} ZIP_SOURCE_DIR)
# file(REAL_PATH ${zip_BINARY_DIR} ZIP_BINARY_DIR)

# set(ZIP_LIBRARY ${ZIP_BINARY_DIR}/$<CONFIG>/zip.lib CACHE FILEPATH "zip library" FORCE)

####################### pugixml
# set(PUGIXML_WCHAR_MODE OFF CACHE BOOL "Enable wchar_t mode" FORCE)
# set(PUGIXML_COMPACT OFF CACHE BOOL "Enable compact mode" FORCE)
# set(PUGIXML_INSTALL OFF CACHE BOOL "Enable installation rules" FORCE)
# set(PUGIXML_NO_XPATH OFF CACHE BOOL "Disable XPath" FORCE)
# set(PUGIXML_NO_STL OFF CACHE BOOL "Disable STL" FORCE)
# set(PUGIXML_NO_EXCEPTIONS OFF CACHE BOOL "Disable Exceptions" FORCE)
# set(PUGIXML_BUILD_TESTS  OFF CACHE BOOL "Build pugixml tests" FORCE)
# set(PUGIXML_BUILD_SHARED_AND_STATIC_LIBS OFF CACHE BOOL "Build both shared and static libraries" FORCE)

# FetchContent_Declare(
  # pugixml
  # GIT_REPOSITORY https://github.com/zeux/pugixml.git
  # GIT_TAG        v1.15
  # GIT_SHALLOW    TRUE
  
  # CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE=ON
			 # -DCMAKE_ENABLE_SANITIZERS=OFF
			 # -DBUILD_SHARED_LIBS=OFF
			 # -DPUGIXML_WCHAR_MODE=${PUGIXML_WCHAR_MODE}
			 # -DPUGIXML_COMPACT=${PUGIXML_COMPACT}
			 # -DPUGIXML_INSTALL=${PUGIXML_INSTALL}
			 # -DPUGIXML_NO_XPATH=${PUGIXML_NO_XPATH}
			 # -DPUGIXML_NO_STL=${PUGIXML_NO_STL}
			 # -DPUGIXML_NO_EXCEPTIONS=${PUGIXML_NO_EXCEPTIONS}
			 # -DPUGIXML_BUILD_TESTS=${PUGIXML_BUILD_TESTS}
			 # -DPUGIXML_BUILD_SHARED_AND_STATIC_LIBS=${PUGIXML_BUILD_SHARED_AND_STATIC_LIBS}
			 
#	OVERRIDE_FIND_PACKAGE
# )

# FetchContent_MakeAvailable(pugixml)


# file(REAL_PATH ${pugixml_SOURCE_DIR}/src ZIP_INCLUDE_DIR)
# file(REAL_PATH ${pugixml_SOURCE_DIR} ZIP_SOURCE_DIR)
# file(REAL_PATH ${pugixml_BINARY_DIR} ZIP_BINARY_DIR)

# set(ZIP_LIBRARY ${ZIP_BINARY_DIR}/$<CONFIG>/pugixml.lib CACHE FILEPATH "zip library" FORCE)

####################### DuckX
FetchContent_Declare(
  duckx
  GIT_REPOSITORY https://github.com/amiremohamadi/DuckX.git
  GIT_TAG        53f880f72ee745221cf2925ce0f2813fdf1553a2
  GIT_SHALLOW    TRUE
  
  CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE=ON
			 -DBUILD_SAMPLES=OFF 
			 -DBUILD_SHARED_LIBS=OFF
)

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
  GIT_REPOSITORY https://github.com/vincentlaucsb/csv-parser.git
  GIT_TAG        e425b157adb6e144e3472f2d144c6d7f2e5db81b
  GIT_SHALLOW    TRUE
  
  CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE=ON
			 -DBUILD_PYTHON=OFF
			 -DCSV_BUILD_PROGRAMS=OFF
			 -DBUILD_SHARED_LIBS=OFF
)

FetchContent_MakeAvailable(csv_parser)

####################### base64
set(BASE64_WERROR OFF CACHE BOOL "Treat warnings as error" FORCE)
set(BASE64_BUILD_TESTS OFF CACHE BOOL "add test projects" FORCE)
set(BASE64_WITH_OpenMP ON CACHE BOOL "use OpenMP" FORCE)
set(BASE64_REGENERATE_TABLES ON CACHE BOOL "regenerate the codec tables" FORCE)
set(BASE64_WITH_SSSE3 ON CACHE BOOL "add SSSE 3 codepath" FORCE)
set(BASE64_WITH_AVX ON CACHE BOOL "add AVX codepath" FORCE)
set(BASE64_WITH_AVX2 ON CACHE BOOL "add AVX 2 codepath" FORCE)
set(BASE64_WITH_AVX512 OFF CACHE BOOL "add AVX 512 codepath" FORCE)
set(BASE64_WITH_NEON32 OFF CACHE BOOL "add NEON32 codepath" FORCE)
set(BASE64_WITH_NEON64 OFF CACHE BOOL "add NEON64 codepath" FORCE)

FetchContent_Declare(
  base64
  GIT_REPOSITORY https://github.com/aklomp/base64.git
  GIT_TAG        9e8ed65048ff0f703fad3deb03bf66ac7f78a4d7
  GIT_SHALLOW    TRUE
  
  CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE=ON
			 -DBASE64_WERROR=${BASE64_WERROR}
			 -DBASE64_BUILD_TESTS=${BASE64_BUILD_TESTS}
			 -DBASE64_WITH_OpenMP=${BASE64_WITH_OpenMP}
			 -DBASE64_REGENERATE_TABLES=${BASE64_REGENERATE_TABLES}
			 -DBASE64_WITH_SSSE3=${BASE64_WITH_SSSE3}
			 -DBASE64_WITH_AVX=${BASE64_WITH_AVX}
			 -DBASE64_WITH_AVX2=${BASE64_WITH_AVX2}
			 -DBASE64_WITH_AVX512=${BASE64_WITH_AVX512}
			 -DBASE64_WITH_NEON32=${BASE64_WITH_NEON32}
			 -DBASE64_WITH_NEON64=${BASE64_WITH_NEON64}
			 -DBUILD_SHARED_LIBS=OFF

  # FIND_PACKAGE_ARGS NAMES base64
)

FetchContent_MakeAvailable(base64)

file(REAL_PATH ${base64_SOURCE_DIR}/include BASE64_INCLUDE_DIR)
file(REAL_PATH ${base64_SOURCE_DIR} BASE64_SOURCE_DIR)
file(REAL_PATH ${base64_BINARY_DIR} BASE64_BINARY_DIR)

set(BASE64_LIBRARY ${BASE64_BINARY_DIR}/$<CONFIG>/base64.lib CACHE FILEPATH "base64 library" FORCE)


# if(NOT TARGET base64)
	# add_library(base64 INTERFACE IMPORTED)
    # set_target_properties(base64 PROPERTIES
						  # INTERFACE_POSITION_INDEPENDENT_CODE ON
						  # )
	# target_include_directories(base64  INTERFACE 
						# $<BUILD_INTERFACE:${BASE64_INCLUDE_DIR}>
						# )
	# target_link_libraries(base64  INTERFACE $<BUILD_INTERFACE:${BASE64_LIBRARY}>)
# endif()

if(NOT TARGET base64)
	add_library(base64 INTERFACE IMPORTED)
    set_target_properties(aklomp::base64 PROPERTIES
                          INTERFACE_LINK_LIBRARIES 
							  aklomp::base64
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						  )
	target_include_directories(base64 INTERFACE 
						$<BUILD_INTERFACE:${BASE64_INCLUDE_DIR}>
						)
	target_link_libraries(base64  INTERFACE $<BUILD_INTERFACE:${BASE64_LIBRARY}>)
endif()

set(base64 ${BASE64_BINARY_DIR}/$<CONFIG>/base64.lib CACHE FILEPATH "base64 library" FORCE)
set(base64_inc_dir ${BASE64_INCLUDE_DIR} CACHE PATH "base64 library" FORCE)

####################### mailio
set(MAILIO_BUILD_DOCUMENTATION OFF CACHE BOOL "Turn on to build doxygen based documentation." FORCE)
set(MAILIO_BUILD_EXAMPLES OFF CACHE BOOL "Turn on to build examples." FORCE)
set(MAILIO_BUILD_TESTS OFF CACHE BOOL "Turn on to build the tests." FORCE)
set(MAILIO_DYN_LINK_TESTS OFF CACHE BOOL "Turn on to dynamically link the tests." FORCE)

FetchContent_Declare(
  mailio
  GIT_REPOSITORY https://github.com/karastojko/mailio.git
  GIT_TAG        0.25.2
  GIT_SHALLOW    TRUE
  
  CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE=ON
			 -DMAILIO_BUILD_DOCUMENTATION=${MAILIO_BUILD_DOCUMENTATION}
			 -DMAILIO_BUILD_EXAMPLES=${MAILIO_BUILD_EXAMPLES}
			 -DMAILIO_BUILD_TESTS=${MAILIO_BUILD_TESTS}
			 -DMAILIO_DYN_LINK_TESTS=${MAILIO_DYN_LINK_TESTS}
			 -DBUILD_SHARED_LIBS=OFF

  OVERRIDE_FIND_PACKAGE
)

FetchContent_MakeAvailable(mailio)

file(REAL_PATH ${mailio_SOURCE_DIR}/include MAILIO_INCLUDE_DIR)
file(REAL_PATH ${mailio_SOURCE_DIR} MAILIO_SOURCE_DIR)
file(REAL_PATH ${mailio_BINARY_DIR} MAILIO_BINARY_DIR)

set(MAILIO_LIBRARY ${MAILIO_BINARY_DIR}/$<CONFIG>/mailio.lib CACHE FILEPATH "mailio library" FORCE)

if(NOT TARGET mailio::mailio)
	add_library(mailio::mailio INTERFACE IMPORTED)
    set_target_properties(mailio::mailio PROPERTIES
                          INTERFACE_LINK_LIBRARIES 
							  mailio
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						  )
	target_include_directories(mailio::mailio  INTERFACE 
						$<BUILD_INTERFACE:${MAILIO_INCLUDE_DIR}>
						)
	target_link_libraries(mailio::mailio  INTERFACE $<BUILD_INTERFACE:${MAILIO_LIBRARY}>)
endif()

####################### charsetdetect
# upstream https://gitlab.freedesktop.org/uchardet/uchardet.git
FetchContent_Declare(
  charsetdetect
  GIT_REPOSITORY https://github.com/JetAr/libcharsetdetect.git 
  GIT_TAG        f2c7cbb5d7b73f46e7817cdf97c01a45962b4de0
  GIT_SHALLOW    TRUE
  
  CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE=ON
			 -DBUILD_BINARY=OFF
			 -DCHECK_SSE2=ON
			 -DBUILD_SHARED_LIBS=OFF
			 -DBUILD_STATIC=ON

  FIND_PACKAGE_ARGS NAMES charsetdetect
)

FetchContent_MakeAvailable(charsetdetect)

file(REAL_PATH ${charsetdetect_SOURCE_DIR} CHARSETDETECT_INCLUDE_DIR)
file(REAL_PATH ${charsetdetect_SOURCE_DIR} CHARSETDETECT_SOURCE_DIR)
file(REAL_PATH ${charsetdetect_BINARY_DIR} CHARSETDETECT_BINARY_DIR)

set(CHARSETDETECT_LIBRARY ${CHARSETDETECT_BINARY_DIR}/$<CONFIG>/charsetdetect.lib CACHE FILEPATH "charsetdetect library" FORCE)

if(NOT TARGET charsetdetect)
	add_library(charsetdetect INTERFACE IMPORTED)
    set_target_properties(charsetdetect PROPERTIES
                          INTERFACE_LINK_LIBRARIES 
							  charsetdetect
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						  )
	target_include_directories(charsetdetect  INTERFACE 
						$<BUILD_INTERFACE:${CHARSETDETECT_INCLUDE_DIR}>
						)
	target_link_libraries(charsetdetect  INTERFACE $<BUILD_INTERFACE:${CHARSETDETECT_LIBRARY}>)
endif()

set(charsetdetect ${CHARSETDETECT_LIBRARY} CACHE FILEPATH "charsetdetect library" FORCE)
set(charsetdetect_inc_dir ${CHARSETDETECT_INCLUDE_DIR} CACHE PATH "charsetdetect include directory" FORCE)

####################### libdeflate
set(LIBDEFLATE_BUILD_STATIC_LIB ON CACHE BOOL "Build the static library" FORCE)
set(LIBDEFLATE_BUILD_SHARED_LIB OFF CACHE BOOL "Build the shared library" FORCE)
set(LIBDEFLATE_COMPRESSION_SUPPORT ON CACHE BOOL "Support compression" FORCE)
set(LIBDEFLATE_DECOMPRESSION_SUPPORT ON CACHE BOOL "Support decompression" FORCE)
set(LIBDEFLATE_ZLIB_SUPPORT ON CACHE BOOL "Support the zlib format" FORCE)
set(LIBDEFLATE_GZIP_SUPPORT ON CACHE BOOL "Support the gzip format" FORCE)
set(LIBDEFLATE_FREESTANDING OFF CACHE BOOL "Build a freestanding library, i.e. a library that doesn't link to any libc functions like malloc(), free(), and memcpy().  Library users will need to provide a custom memory allocator." FORCE)
set(LIBDEFLATE_BUILD_GZIP OFF CACHE BOOL "Build the libdeflate-gzip program" FORCE)
set(LIBDEFLATE_BUILD_TESTS OFF CACHE BOOL "Build the test programs" FORCE)
set(LIBDEFLATE_USE_SHARED_LIB OFF CACHE BOOL "Link the libdeflate-gzip and test programs to the shared library instead of the static library" FORCE)

FetchContent_Declare(
  libdeflate
  GIT_REPOSITORY https://github.com/ebiggers/libdeflate.git
  GIT_TAG        v1.24
  GIT_SHALLOW    TRUE
  
  CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE=ON
			 -DLIBDEFLATE_BUILD_STATIC_LIB=${LIBDEFLATE_BUILD_STATIC_LIB}
			 -DLIBDEFLATE_BUILD_SHARED_LIB=${LIBDEFLATE_BUILD_SHARED_LIB}
			 -DLIBDEFLATE_COMPRESSION_SUPPORT=${LIBDEFLATE_COMPRESSION_SUPPORT}
			 -DLIBDEFLATE_DECOMPRESSION_SUPPORT=${LIBDEFLATE_DECOMPRESSION_SUPPORT}
			 -DLIBDEFLATE_ZLIB_SUPPORT=${LIBDEFLATE_ZLIB_SUPPORT}
			 -DLIBDEFLATE_GZIP_SUPPORT=${LIBDEFLATE_GZIP_SUPPORT}
			 -DLIBDEFLATE_FREESTANDING=${LIBDEFLATE_FREESTANDING}
			 -DLIBDEFLATE_BUILD_GZIP=${LIBDEFLATE_BUILD_GZIP}
			 -DLIBDEFLATE_BUILD_TESTS=${LIBDEFLATE_BUILD_TESTS}
			 -DLIBDEFLATE_USE_SHARED_LIB=${LIBDEFLATE_USE_SHARED_LIB}
			 -DBUILD_SHARED_LIBS=OFF

  OVERRIDE_FIND_PACKAGE
)

FetchContent_MakeAvailable(libdeflate)

file(REAL_PATH ${libdeflate_SOURCE_DIR}/lib LIBDEFLATE_INCLUDE_DIR)
file(REAL_PATH ${libdeflate_SOURCE_DIR} LIBDEFLATE_SOURCE_DIR)
file(REAL_PATH ${libdeflate_BINARY_DIR} LIBDEFLATE_BINARY_DIR)

set(LIBDEFLATE_LIBRARY ${LIBDEFLATE_BINARY_DIR}/$<CONFIG>/libdeflate_static.lib CACHE FILEPATH "libdeflate library" FORCE)

if(NOT TARGET libdeflate::libdeflate)
	add_library(libdeflate::libdeflate INTERFACE IMPORTED)
    set_target_properties(libdeflate::libdeflate PROPERTIES
                          INTERFACE_LINK_LIBRARIES 
							  libdeflate_static
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						  )
	target_include_directories(libdeflate::libdeflate  INTERFACE 
						$<BUILD_INTERFACE:${LIBDEFLATE_INCLUDE_DIR}>
						)
	target_link_libraries(libdeflate::libdeflate  INTERFACE $<BUILD_INTERFACE:${LIBDEFLATE_LIBRARY}>)
endif()

set(Deflate_INCLUDE_DIRS ${LIBDEFLATE_INCLUDE_DIR} CACHE PATH "deflate include directory" FORCE)
set(Deflate_LIBRARIES ${LIBDEFLATE_LIBRARY} CACHE FILEPATH "deflate include directory" FORCE)

####################### rapidfuzz
set(RAPIDFUZZ_BUILD_TESTING OFF CACHE BOOL "Build tests" FORCE)
set(RAPIDFUZZ_ENABLE_LINTERS OFF CACHE BOOL "Enable Linters for the test builds" FORCE)
set(RAPIDFUZZ_BUILD_BENCHMARKS OFF CACHE BOOL "Build benchmarks" FORCE)
set(RAPIDFUZZ_BUILD_FUZZERS ON CACHE BOOL "Build fuzzers" FORCE)

FetchContent_Declare(
  rapidfuzz
  GIT_REPOSITORY https://github.com/rapidfuzz/rapidfuzz-cpp.git
  GIT_TAG        v3.3.2
  GIT_SHALLOW    TRUE
  
  CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE=ON
			 -DRAPIDFUZZ_BUILD_TESTING=${RAPIDFUZZ_BUILD_TESTING}
			 -DRAPIDFUZZ_ENABLE_LINTERS=${RAPIDFUZZ_ENABLE_LINTERS}
			 -DRAPIDFUZZ_BUILD_BENCHMARKS=${RAPIDFUZZ_BUILD_BENCHMARKS}
			 -DRAPIDFUZZ_BUILD_FUZZERS=${RAPIDFUZZ_BUILD_FUZZERS}
			 -DBUILD_SHARED_LIBS=OFF

  OVERRIDE_FIND_PACKAGE
)

FetchContent_MakeAvailable(rapidfuzz)

file(REAL_PATH ${rapidfuzz_SOURCE_DIR} RAPIDFUZZ_INCLUDE_DIR)
file(REAL_PATH ${rapidfuzz_SOURCE_DIR} RAPIDFUZZ_SOURCE_DIR)
file(REAL_PATH ${rapidfuzz_BINARY_DIR} RAPIDFUZZ_BINARY_DIR)

set(RAPIDFUZZ_LIBRARY ${RAPIDFUZZ_BINARY_DIR}/$<CONFIG>/rapidfuzz.lib CACHE FILEPATH "rapidfuzz library" FORCE)

if(NOT TARGET rapidfuzz::rapidfuzz)
	add_library(rapidfuzz::rapidfuzz INTERFACE IMPORTED)
    set_target_properties(rapidfuzz::rapidfuzz PROPERTIES
                          INTERFACE_LINK_LIBRARIES 
							  rapidfuzz
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						  )
	target_include_directories(rapidfuzz::rapidfuzz  INTERFACE 
						$<BUILD_INTERFACE:${RAPIDFUZZ_INCLUDE_DIR}>
						)
	target_link_libraries(rapidfuzz::rapidfuzz  INTERFACE $<BUILD_INTERFACE:${RAPIDFUZZ_LIBRARY}>)
endif()


####################### gif
# Alternative https://github.com/gongjianbo/GifLib.git
FetchContent_Declare(
  giflib
  GIT_REPOSITORY https://github.com/bitbank2/giflib-turbo.git
  GIT_TAG        ca7058b0141c577810fa793458796c485945ed8a
  GIT_SHALLOW    TRUE
  
  CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE=ON
			 -DBUILD_SHARED_LIBS=OFF

   OVERRIDE_FIND_PACKAGE
)

FetchContent_MakeAvailable(giflib)

file(REAL_PATH ${giflib_SOURCE_DIR} GIFLIB_INCLUDE_DIR)
file(REAL_PATH ${giflib_SOURCE_DIR} GIFLIB_SOURCE_DIR)
file(REAL_PATH ${giflib_BINARY_DIR} GIFLIB_BINARY_DIR)

set(GIFLIB_LIBRARY ${GIFLIB_BINARY_DIR}/$<CONFIG>/gif.lib CACHE FILEPATH "giflib library" FORCE)

set(GIFLIB_INCLUDE_DIRS ${GIFLIB_INCLUDE_DIR})

set(GIFLIB_LIBRARIES ${GIFLIB_LIBRARY})

set(GIF_INCLUDE_DIR ${GIFLIB_INCLUDE_DIR})

set(GIF_LIBRARY ${GIFLIB_LIBRARY})


####################### libjpeg
FetchContent_Declare(
  libjpeg
  GIT_REPOSITORY https://github.com/csparker247/jpeg-cmake.git
  GIT_TAG        v1.3.0
  GIT_SHALLOW    TRUE

  
  CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=ON
             -DBUILD_STATIC_LIBS:BOOL=ON
			 -DBUILD_SHARED_LIBS:BOOL=OFF
			 -DBUILD_EXECUTABLE:BOOL=OFF
			 -DBUILD_TESTS:BOOL=OFF
             -DLINK_STATIC:BOOL=ON
			 -DWBUILD_ALT_UI:BOOL=OFF

   OVERRIDE_FIND_PACKAGE
)

FetchContent_MakeAvailable(libjpeg)

file(REAL_PATH ${libjpeg_SOURCE_DIR}/libjpeg LIBJPEG_INCLUDE_DIR)
file(REAL_PATH ${libjpeg_SOURCE_DIR} LIBJPEG_SOURCE_DIR)
file(REAL_PATH ${libjpeg_BINARY_DIR} LIBJPEG_BINARY_DIR)

set(LIBJPEG_INCLUDE_DIR ${LIBJPEG_INCLUDE_DIR} CACHE PATH "libjpeg include directory" FORCE)

set(LIBJPEG_LIBRARY ${LIBJPEG_BINARY_DIR}/$<CONFIG>/jpeg-static.lib CACHE FILEPATH "libjpeg library" FORCE)

set(LIBJPEG_TURBO_LIBRARY ${LIBJPEG_BINARY_DIR}/$<CONFIG>/turbojpeg-static.lib CACHE FILEPATH "libjpeg-turbo library" FORCE)

set(JPEG_LIBRARY ${LIBJPEG_LIBRARY} CACHE FILEPATH "libjpeg library" FORCE)

set(JPEG_INCLUDE_DIR ${LIBJPEG_INCLUDE_DIR})

set(JPEG_INCLUDE_DIRS ${LIBJPEG_INCLUDE_DIR} ${LIBJPEG_BINARY_DIR})

set(JPEG_LIBRARIES ${LIBJPEG_LIBRARY} ${LIBJPEG_TURBO_LIBRARY})

if(NOT TARGET jpeg-static)
	add_library(jpeg-static INTERFACE IMPORTED GLOBAL)
	set_target_properties(  jpeg-static
						   PROPERTIES IMPORTED_LOCATION
						   ${JPEG_LIBRARY}				   
						   )
	target_include_directories(jpeg-static INTERFACE 
							$<BUILD_INTERFACE:${LIBJPEG_INCLUDE_DIR}>
							$<BUILD_INTERFACE:${LIBJPEG_BINARY_DIR}>
						)
	target_link_libraries(jpeg-static  INTERFACE 
							$<BUILD_INTERFACE:${LIBJPEG_LIBRARY}>
						)
endif()


if(NOT TARGET JPEG::JPEG)
	add_library(JPEG::JPEG INTERFACE IMPORTED)
    set_target_properties(JPEG::JPEG PROPERTIES
                          INTERFACE_LINK_LIBRARIES 
							  jpeg_static
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						  )
	target_include_directories(JPEG::JPEG INTERFACE 
							$<BUILD_INTERFACE:${LIBJPEG_INCLUDE_DIR}>
							$<BUILD_INTERFACE:${LIBJPEG_BINARY_DIR}>
						)
	target_link_libraries(JPEG::JPEG  INTERFACE 
							$<BUILD_INTERFACE:${LIBJPEG_LIBRARY}>
							$<BUILD_INTERFACE:${LIBJPEG_TURBO_LIBRARY}>
						)
endif()


####################### libjpeg
# set(WITH_TURBOJPEG ON CACHE BOOL "Include the TurboJPEG API library and associated command-line tools/test programs" FORCE)

# ExternalProject_Add(
  # libjpeg-turbo-project
  # GIT_REPOSITORY https://github.com/libjpeg-turbo/libjpeg-turbo.git
  # GIT_TAG        3.1.1
  # GIT_SHALLOW    TRUE
  
  # PREFIX "${CMAKE_BINARY_DIR}/_deps/libjpeg-turbo"
  
  # SOURCE_DIR   "${CMAKE_BINARY_DIR}/_deps/libjpeg-turbo-src"
  # BINARY_DIR   "{CMAKE_BINARY_DIR}/_deps/libjpeg-turbo-build"
  # INSTALL_DIR  "${CMAKE_BINARY_DIR}/_deps/libjpeg-turbo"
  
  # BUILD_BYPRODUCTS "${CMAKE_BINARY_DIR}/_deps/libjpeg-turbo/lib/jpeg-static.lib"
  
  # CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE:BOOL=ON
             # -DENABLE_SHARED:BOOL=OFF
			 # -DENABLE_STATIC:BOOL=ON
			 # -DREQUIRE_SIMD:BOOL=OFF
			 # -DWITH_ARITH_DEC:BOOL=ON
             # -DWITH_ARITH_ENC:BOOL=ON
			 # -DWITH_JAVA:BOOL=OFF
			 # -DWITH_JPEG7:BOOL=OFF
			 # -DWITH_JPEG8:BOOL=OFF
			 # -DWITH_TURBOJPEG:BOOL=${WITH_TURBOJPEG}
             # -DWITH_TOOLS:BOOL=OFF
			 # -DWITH_TESTS:BOOL=OFF
			 # -DWITH_FUZZ:BOOL=OFF
			 # -DBUILD_SHARED_LIBS:BOOL=OFF

   # OVERRIDE_FIND_PACKAGE
# )

# FetchContent_MakeAvailable(libjpeg-turbo)

# ExternalProject_Get_Property(libjpeg-turbo-project SOURCE_DIR BINARY_DIR INSTALL_DIR)

# message("JPEG_SOURCE_DIR=${SOURCE_DIR}")
# message("JPEG_BINARY_DIR=${BINARY_DIR}")

# file(REAL_PATH ${INSTALL_DIR}/include LIBJPEG_INCLUDE_DIR)
# file(REAL_PATH ${SOURCE_DIR} LIBJPEG_SOURCE_DIR)
# file(REAL_PATH ${BINARY_DIR} LIBJPEG_BINARY_DIR)

# set(LIBJPEG_INCLUDE_DIR ${INSTALL_DIR}/include CACHE PATH "libjpeg include directory" FORCE)

# set(LIBJPEG_LIBRARY ${INSTALL_DIR}/lib/jpeg-static.lib CACHE FILEPATH "libjpeg library" FORCE)

# set(LIBJPEG_TURBO_LIBRARY ${INSTALL_DIR}/lib/turbojpeg-static.lib CACHE FILEPATH "libjpeg-turbo library" FORCE)

# set(JPEG_LIBRARY ${LIBJPEG_LIBRARY} CACHE FILEPATH "libjpeg library" FORCE)

# set(JPEG_INCLUDE_DIR ${LIBJPEG_INCLUDE_DIR})

# set(JPEG_INCLUDE_DIRS ${LIBJPEG_INCLUDE_DIR} ${BINARY_DIR})

# set(JPEG_LIBRARIES ${LIBJPEG_LIBRARY} ${LIBJPEG_TURBO_LIBRARY})

# if(NOT TARGET jpeg-static)
	# add_library(jpeg-static INTERFACE IMPORTED GLOBAL)
	# set_target_properties(# Specifies the target library.
						   # jpeg-static

						   # Specifies the parameter you want to define.
						   # PROPERTIES IMPORTED_LOCATION

						   # Provides the path to the library you want to import.
						   # ${JPEG_LIBRARY}				   
						   # )
	# target_include_directories(jpeg-static INTERFACE 
							# $<BUILD_INTERFACE:${LIBJPEG_INCLUDE_DIR}>
							# $<BUILD_INTERFACE:${BINARY_DIR}>
						# )
	# target_link_libraries(jpeg-static  INTERFACE 
							# $<BUILD_INTERFACE:${LIBJPEG_LIBRARY}>
						# )
# endif()

# if(NOT TARGET turbojpeg-static)
	# add_library(turbojpeg-static INTERFACE IMPORTED GLOBAL)
	# set_target_properties(# Specifies the target library.
						   # turbojpeg-static

						   # Specifies the parameter you want to define.
						   # PROPERTIES IMPORTED_LOCATION

						   # Provides the path to the library you want to import.
						   # ${LIBJPEG_TURBO_LIBRARY}				   
						   # )
	# target_include_directories(jpeg-static INTERFACE 
							# $<BUILD_INTERFACE:${LIBJPEG_INCLUDE_DIR}>
							# $<BUILD_INTERFACE:${BINARY_DIR}>
						# )
	# target_link_libraries(jpeg-static  INTERFACE 
							# $<BUILD_INTERFACE:${LIBJPEG_LIBRARY}>
							# $<BUILD_INTERFACE:${LIBJPEG_TURBO_LIBRARY}>
						# )
# endif()

# if(NOT TARGET JPEG::JPEG)
	# add_library(JPEG::JPEG INTERFACE IMPORTED)
    # set_target_properties(JPEG::JPEG PROPERTIES
                          # INTERFACE_LINK_LIBRARIES 
							  # jpeg-static
						  # INTERFACE_POSITION_INDEPENDENT_CODE ON
						  # )
	# target_include_directories(JPEG::JPEG INTERFACE 
							# $<BUILD_INTERFACE:${LIBJPEG_INCLUDE_DIR}>
							# $<BUILD_INTERFACE:${BINARY_DIR}>
						# )
	# target_link_libraries(JPEG::JPEG  INTERFACE 
							# $<BUILD_INTERFACE:${LIBJPEG_LIBRARY}>
							# $<BUILD_INTERFACE:${LIBJPEG_TURBO_LIBRARY}>
						# )
# endif()

####################### openjpeg
FetchContent_Declare(
  openjp2
  GIT_REPOSITORY https://github.com/uclouvain/openjpeg.git
  GIT_TAG        v2.5.3
  GIT_SHALLOW    TRUE
  
  CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DBUILD_DOC=OFF -DENABLE_STATIC=ON -DBUILD_LUTS_GENERATOR=OFF -DBUILD_CODEC=ON -DBUILD_JPIP=ON -DBUILD_JPIP_SERVER=OFF -DBUILD_VIEWER=OFF -DBUILD_JAVA=OFF -DBUILD_THIRDPARTY=OFF -DBUILD_TESTING=OFF -DBUILD_STATIC_LIBS=ON -DBUILD_SHARED_LIBS=OFF

  OVERRIDE_FIND_PACKAGE
)

FetchContent_MakeAvailable(openjp2)

file(REAL_PATH ${openjp2_SOURCE_DIR}/src/lib OPENJP2_INCLUDE_DIR)
file(REAL_PATH ${openjp2_SOURCE_DIR} OPENJP2_SOURCE_DIR)
file(REAL_PATH ${openjp2_BINARY_DIR} OPENJP2_BINARY_DIR)

set(OPENJP2_LIBRARY ${OPENJP2_BINARY_DIR}/$<CONFIG>/openjp2.lib CACHE FILEPATH "openjp2 library" FORCE)
set(OPENJPIP_LIBRARY ${OPENJP2_BINARY_DIR}/$<CONFIG>/openjpip.lib CACHE FILEPATH "openjp2 library" FORCE)

set(OPENJPEG_INCLUDE_DIRS ${OPENJP2_INCLUDE_DIR} ${OPENJP2_BINARY_DIR})

set(OPENJPEG_LIBRARIES ${OPENJP2_LIBRARY} ${OPENJPIP_LIBRARY})

set(OpenJPEG_DIR ${OPENJP2_SOURCE_DIR})

####################### libtiff
set(tiff-static ON CACHE BOOL "build TIFF static libraries" FORCE)
set(tiff-tools OFF CACHE BOOL "build TIFF tools" FORCE)
set(tiff-tests OFF CACHE BOOL "build TIFF tests" FORCE)
set(tiff-contrib ON CACHE BOOL "build TIFF contrib" FORCE)
set(tiff-docs OFF CACHE BOOL "build TIFF documentation" FORCE)
set(tiff-deprecated OFF CACHE BOOL "build TIFF deprecated features" FORCE)
set(tiff-install OFF CACHE BOOL "install TIFF targets" FORCE)


FetchContent_Declare(
  tiff
  GIT_REPOSITORY https://github.com/libsdl-org/libtiff.git
  GIT_TAG        v4.7.0
  GIT_SHALLOW    TRUE
  
  CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE=ON -Dtiff-static=${tiff-static} -Dtiff-tools=${tiff-tools} -Dtiff-tests=${tiff-tests} -Dtiff-contrib=${tiff-contrib} -Dtiff-docs=${tiff-docs} -Dtiff-deprecated=${tiff-deprecated} -Dtiff-install=${tiff-install} -DBUILD_SHARED_LIBS=OFF

  OVERRIDE_FIND_PACKAGE
)

FetchContent_MakeAvailable(tiff zlib liblzma zstd libjpeg)

add_dependencies(tiff jpeg-static zlibstatic libzstd_static liblzma)

file(REAL_PATH ${tiff_SOURCE_DIR}/libtiff TIFF_INCLUDE_DIR)
file(REAL_PATH ${tiff_SOURCE_DIR} TIFF_SOURCE_DIR)
file(REAL_PATH ${tiff_BINARY_DIR} TIFF_BINARY_DIR)

set(TIFF_LIBRARY ${TIFF_BINARY_DIR}/$<CONFIG>/tiff.lib CACHE FILEPATH "libtiff library" FORCE)

set(TIFF_INCLUDE_DIRS ${TIFF_INCLUDE_DIR} ${TIFF_BINARY_DIR})

set(TIFF_LIBRARIES ${TIFF_LIBRARY})

if(NOT TARGET TIFF::tiff)
	add_library(TIFF::tiff INTERFACE IMPORTED)
    set_target_properties(TIFF::tiff PROPERTIES
                          INTERFACE_LINK_LIBRARIES
						    png_static
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						 )
    target_include_directories(TIFF::tiff
								INTERFACE
									$<BUILD_INTERFACE:${TIFF_INCLUDE_DIR}>
									$<BUILD_INTERFACE:${TIFF_BINARY_DIR}>
							  )
endif()

####################### webp
set(WEBP_LINK_STATIC ON CACHE BOOL "Link using static libraries. If OFF, use dynamic libraries." FORCE)
set(WEBP_ENABLE_SIMD ON CACHE BOOL "Enable any SIMD optimization." FORCE)
set(WEBP_BUILD_ANIM_UTILS OFF CACHE BOOL "Build animation utilities." FORCE)
set(WEBP_BUILD_CWEBP OFF CACHE BOOL "Build the cwebp command line tool." FORCE)
set(WEBP_BUILD_DWEBP OFF CACHE BOOL "Build the dwebp command line tool." FORCE)
set(WEBP_BUILD_GIF2WEBP OFF CACHE BOOL "Build the gif2webp conversion tool." FORCE)
set(WEBP_BUILD_IMG2WEBP OFF CACHE BOOL "Build the img2webp animation tool." FORCE)
set(WEBP_BUILD_VWEBP OFF CACHE BOOL "Build the vwebp viewer tool." FORCE)
set(WEBP_BUILD_WEBPINFO OFF CACHE BOOL "Build the webpinfo command line tool." FORCE)
set(WEBP_BUILD_LIBWEBPMUX ON CACHE BOOL "Build the libwebpmux library." FORCE)
set(WEBP_BUILD_WEBPMUX OFF CACHE BOOL "Build the webpmux command line tool." FORCE)
set(WEBP_BUILD_EXTRAS OFF CACHE BOOL "Build extras." FORCE)
set(WEBP_BUILD_WEBP_JS OFF CACHE BOOL "Emscripten build of webp.js." FORCE)
set(WEBP_BUILD_FUZZTEST OFF CACHE BOOL "Build the fuzztest tests." FORCE)
set(WEBP_USE_THREAD ON CACHE BOOL "Enable threading support" FORCE)
set(WEBP_NEAR_LOSSLESS ON CACHE BOOL "Enable near-lossless encoding" FORCE)
set(WEBP_ENABLE_SWAP_16BIT_CSP OFF CACHE BOOL "Enable byte swap for 16 bit colorspaces." FORCE)
set(WEBP_ENABLE_FBOUNDS_SAFETY OFF CACHE BOOL "Enable -fbounds-safety for the part of the codebase which supports it. This expects an experimental toolchain." FORCE)
set(WEBP_ENABLE_WUNUSED_RESULT OFF CACHE BOOL "Add [[nodiscard]] to some functions. CMake must be at least 3.21 to force C23" FORCE)

FetchContent_Declare(
  webp
  GIT_REPOSITORY https://github.com/webmproject/libwebp.git
  GIT_TAG        v1.6.0
  GIT_SHALLOW    TRUE
  
  CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE=ON
			 -DWEBP_LINK_STATIC=${WEBP_LINK_STATIC}
			 -DWEBP_ENABLE_SIMD=${WEBP_ENABLE_SIMD}
			 -DWEBP_BUILD_ANIM_UTILS=${WEBP_BUILD_ANIM_UTILS}
			 -DWEBP_BUILD_CWEBP=${WEBP_BUILD_CWEBP}
			 -DWEBP_BUILD_DWEBP=${WEBP_BUILD_DWEBP}
			 -DWEBP_BUILD_GIF2WEBP=${WEBP_BUILD_GIF2WEBP}
			 -DWEBP_BUILD_IMG2WEBP=${WEBP_BUILD_IMG2WEBP}
			 -DWEBP_BUILD_VWEBP=${WEBP_BUILD_VWEBP}
			 -DWEBP_BUILD_WEBPINFO=${WEBP_BUILD_WEBPINFO}
			 -DWEBP_BUILD_LIBWEBPMUX=${WEBP_BUILD_LIBWEBPMUX}
			 -DWEBP_BUILD_WEBPMUX=${WEBP_BUILD_WEBPMUX}
			 -DWEBP_BUILD_EXTRAS=${WEBP_BUILD_EXTRAS}
			 -DWEBP_BUILD_WEBP_JS=${WEBP_BUILD_WEBP_JS}
			 -DWEBP_BUILD_FUZZTEST=${WEBP_BUILD_FUZZTEST}
			 -DWEBP_USE_THREAD=${WEBP_USE_THREAD}
			 -DWEBP_NEAR_LOSSLESS=${WEBP_NEAR_LOSSLESS}
			 -DWEBP_ENABLE_SWAP_16BIT_CSP=${WEBP_ENABLE_SWAP_16BIT_CSP}
			 -DWEBP_ENABLE_FBOUNDS_SAFETY=${WEBP_ENABLE_FBOUNDS_SAFETY}
			 -DWEBP_ENABLE_WUNUSED_RESULT=${WEBP_ENABLE_WUNUSED_RESULT}
			 -DBUILD_SHARED_LIBS=OFF

   OVERRIDE_FIND_PACKAGE
)

FetchContent_MakeAvailable(webp)

file(REAL_PATH ${webp_SOURCE_DIR}/src WEBP_INCLUDE_DIR)
file(REAL_PATH ${webp_SOURCE_DIR} WEBP_SOURCE_DIR)
file(REAL_PATH ${webp_BINARY_DIR} WEBP_BINARY_DIR)

set(WebP_LIBRARY ${WEBP_BINARY_DIR}/$<CONFIG>/webp.lib CACHE FILEPATH "webp library" FORCE)

set(WebP_INCLUDE_DIRS ${WEBP_INCLUDE_DIR} ${WEBP_BINARY_DIR})

set(WebP_LIBRARIES ${WebP_LIBRARY} ${WEBP_BINARY_DIR}/$<CONFIG>/webpdemux.lib ${WEBP_BINARY_DIR}/$<CONFIG>/webpmux.lib ${WEBP_BINARY_DIR}/$<CONFIG>/sharpyuv.lib)

if(NOT TARGET WebP::webp)
	add_library(WebP::webp INTERFACE IMPORTED)
    set_target_properties(WebP::webp PROPERTIES
                          INTERFACE_LINK_LIBRARIES
						    webp
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						 )
    target_include_directories(WebP::webp
								INTERFACE
									$<BUILD_INTERFACE:${WEBP_INCLUDE_DIR}>
									$<BUILD_INTERFACE:${WEBP_BINARY_DIR}>
							  )
    target_link_libraries(WebP::webp  INTERFACE 
							$<BUILD_INTERFACE:${WebP_LIBRARY}>
							$<BUILD_INTERFACE:${WEBP_BINARY_DIR}/$<CONFIG>/webpdemux.lib>
							$<BUILD_INTERFACE:${WEBP_BINARY_DIR}/$<CONFIG>/webpmux.lib>
							$<BUILD_INTERFACE:${WEBP_BINARY_DIR}/$<CONFIG>/sharpyuv.lib>
						 )
endif()

if(NOT TARGET webpmux)
	add_library(webpmux INTERFACE IMPORTED)
    set_target_properties(webpmux PROPERTIES
                          INTERFACE_LINK_LIBRARIES
						    webpmux
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						 )
    target_include_directories(webpmux
								INTERFACE
									$<BUILD_INTERFACE:${WEBP_INCLUDE_DIR}>
									$<BUILD_INTERFACE:${WEBP_BINARY_DIR}>
							  )
    target_link_libraries(webpmux  INTERFACE 
							$<BUILD_INTERFACE:${WebP_LIBRARY}>
							$<BUILD_INTERFACE:${WEBP_BINARY_DIR}/$<CONFIG>/webpmux.lib>
							$<BUILD_INTERFACE:${WEBP_BINARY_DIR}/$<CONFIG>/sharpyuv.lib>
						 )
endif()

if(NOT TARGET webpdemux)
	add_library(webpdemux INTERFACE IMPORTED)
    set_target_properties(webpdemux PROPERTIES
                          INTERFACE_LINK_LIBRARIES
						    webpdemux
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						 )
    target_include_directories(webpdemux
								INTERFACE
									$<BUILD_INTERFACE:${WebP_INCLUDE_DIR}>
									$<BUILD_INTERFACE:${WEBP_BINARY_DIR}>
							  )
    target_link_libraries(webpdemux  INTERFACE 
							$<BUILD_INTERFACE:${WebP_LIBRARY}>
							$<BUILD_INTERFACE:${WEBP_BINARY_DIR}/$<CONFIG>/webpdemux.lib>
							$<BUILD_INTERFACE:${WEBP_BINARY_DIR}/$<CONFIG>/sharpyuv.lib>
						 )
endif()



####################### leptonica
set(SW_BUILD OFF CACHE BOOL "Build with sw" FORCE)

set(ENABLE_ZLIB  ON CACHE BOOL "Enable ZLIB support" FORCE)
set(ENABLE_PNG ON CACHE BOOL "Enable PNG support" FORCE)
set(ENABLE_GIF ON CACHE BOOL "Enable GIF support" FORCE)
set(ENABLE_JPEG ON CACHE BOOL "Enable JPEG support" FORCE)
set(ENABLE_TIFF ON CACHE BOOL "Enable TIFF support" FORCE)
set(ENABLE_WEBP ON CACHE BOOL "Enable WebP support" FORCE)
set(ENABLE_OPENJPEG ON CACHE BOOL "Enable OpenJPEG support" FORCE)

FetchContent_Declare(
  leptonica
  GIT_REPOSITORY https://github.com/DanBloomberg/leptonica.git
  GIT_TAG        1.85.0
  GIT_SHALLOW    TRUE
  
  CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE=ON
			 -DSW_BUILD=${SW_BUILD}
			 -DBUILD_PROG=OFF
			 -DSTRICT_CONF=OFF
			 -DENABLE_ZLIB=${ENABLE_ZLIB}
			 -DENABLE_PNG=${ENABLE_PNG}
			 -DENABLE_GIF=${ENABLE_GIF}
			 -DENABLE_JPEG=${ENABLE_JPEG}
			 -DENABLE_TIFF=${ENABLE_TIFF}
			 -DENABLE_WEBP=${ENABLE_WEBP}
			 -DENABLE_OPENJPEG=${ENABLE_OPENJPEG}
			 -DZLIB_INCLUDE_DIR=${ZLIB_INCLUDE_DIR}
			 -DZLIB_LIBRARY=${ZLIB_LIBRARY}
             -DPNG_INCLUDE_DIR=${PNG_INCLUDE_DIR}
			 -DPNG_LIBRARY=${PNG_LIBRARY}
             -DPNG_INCLUDE_DIRS=${PNG_INCLUDE_DIRS}
			 -DPNG_LIBRARIES=${PNG_LIBRARIES}
			 -DOPENJPEG_INCLUDE_DIRS=${OPENJPEG_INCLUDE_DIRS}
			 -DOPENJPEG_LIBRARIES=${OPENJPEG_LIBRARIES}
			 -DBUILD_SHARED_LIBS=OFF

  OVERRIDE_FIND_PACKAGE
)

FetchContent_MakeAvailable(leptonica png zlib giflib openjp2 webp libjpeg)

add_dependencies(leptonica jpeg_static png_static zlibstatic gif openjp2 openjpip webp)

file(REAL_PATH ${leptonica_SOURCE_DIR} LEPTONICA_INCLUDE_DIR)
file(REAL_PATH ${leptonica_SOURCE_DIR} LEPTONICA_SOURCE_DIR)
file(REAL_PATH ${leptonica_BINARY_DIR} LEPTONICA_BINARY_DIR)

set(LEPTONICA_LIBRARY ${LEPTONICA_BINARY_DIR}/$<CONFIG>/leptonica.lib CACHE FILEPATH "leptonica library" FORCE)

if(NOT TARGET leptonica)
	add_library(leptonica INTERFACE IMPORTED)
    set_target_properties(leptonica PROPERTIES
                          INTERFACE_LINK_LIBRARIES 
							  leptonica
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						  )
	target_include_directories(leptonica  INTERFACE 
						$<BUILD_INTERFACE:${LEPTONICA_INCLUDE_DIR}>
						)
	target_link_libraries(leptonica INTERFACE $<BUILD_INTERFACE:${LEPTONICA_BINARY_DIR}>)
endif()

####################### lexbor
set(LEXBOR_WITHOUT_THREADS ON CACHE BOOL "Build without Threads" FORCE)
set(LEXBOR_BUILD_SHARED OFF CACHE BOOL "Build shared library" FORCE)
set(LEXBOR_BUILD_STATIC ON CACHE BOOL "Build static library" FORCE)
set(LEXBOR_BUILD_SEPARATELY OFF CACHE BOOL "Build modules separately" FORCE)
set(LEXBOR_BUILD_EXAMPLES OFF CACHE BOOL "Build examples" FORCE)
set(LEXBOR_BUILD_TESTS OFF CACHE BOOL "Build tests" FORCE)
set(LEXBOR_BUILD_TESTS_CPP OFF CACHE BOOL "Build C++ tests" FORCE)
set(LEXBOR_BUILD_UTILS OFF CACHE BOOL "Build utils" FORCE)
set(LEXBOR_BUILD_WITH_ASAN OFF CACHE BOOL "Build with address sanitizer" FORCE)
set(LEXBOR_BUILD_WITH_FUZZER OFF CACHE BOOL "Build with fuzzer" FORCE)
set(LEXBOR_INSTALL_HEADERS OFF CACHE BOOL "Install header files" FORCE)
set(LEXBOR_WITH_PERF OFF CACHE BOOL "Enables support for rdtsc." FORCE)
set(LEXBOR_MAKE_PACKAGES_FILES OFF CACHE BOOL "Create files for build packages" FORCE)
set(LEXBOR_PRINT_MODULE_DEPENDENCIES OFF CACHE BOOL "Prints dependencies" FORCE)

FetchContent_Declare(
  lexbor
  GIT_REPOSITORY https://github.com/lexbor/lexbor.git
  GIT_TAG        v2.4.0
  GIT_SHALLOW    TRUE
  
  CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE=ON
			 -DLEXBOR_WITHOUT_THREADS=${LEXBOR_WITHOUT_THREADS}
			 -DLEXBOR_BUILD_SHARED=${LEXBOR_BUILD_SHARED}
			 -DLEXBOR_BUILD_STATIC=${LEXBOR_BUILD_STATIC}
			 -DLEXBOR_BUILD_SEPARATELY=${LEXBOR_BUILD_SEPARATELY}
			 -DLEXBOR_BUILD_EXAMPLES=${LEXBOR_BUILD_EXAMPLES}
			 -DLEXBOR_BUILD_TESTS=${LEXBOR_BUILD_TESTS}
			 -DLEXBOR_BUILD_TESTS_CPP=${LEXBOR_BUILD_TESTS_CPP}
			 -DLEXBOR_BUILD_UTILS=${LEXBOR_BUILD_UTILS}
			 -DLEXBOR_BUILD_WITH_ASAN=${LEXBOR_BUILD_WITH_ASAN}
			 -DLEXBOR_BUILD_WITH_FUZZER=${LEXBOR_BUILD_WITH_FUZZER}
			 -DLEXBOR_INSTALL_HEADERS=${LEXBOR_INSTALL_HEADERS}
			 -DLEXBOR_WITH_PERF=${LEXBOR_WITH_PERF}
			 -DLEXBOR_MAKE_PACKAGES_FILES=${LEXBOR_MAKE_PACKAGES_FILES}
			 -DLEXBOR_PRINT_MODULE_DEPENDENCIES=${LEXBOR_PRINT_MODULE_DEPENDENCIES}
			 -DBUILD_SHARED_LIBS=OFF
)

FetchContent_MakeAvailable(lexbor)

file(REAL_PATH ${lexbor_SOURCE_DIR} LEXBOR_INCLUDE_DIR)
file(REAL_PATH ${lexbor_SOURCE_DIR} LEXBOR_SOURCE_DIR)
file(REAL_PATH ${lexbor_BINARY_DIR} LEXBOR_BINARY_DIR)

set(LEXBOR_LIBRARY ${LEXBOR_BINARY_DIR}/$<CONFIG>/lexbor_static.lib CACHE FILEPATH "lexbor library" FORCE)


if(NOT TARGET lexbor)
	add_library(lexbor INTERFACE IMPORTED)
    set_target_properties(lexbor PROPERTIES
                          INTERFACE_LINK_LIBRARIES 
							  lexbor_static
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						  )
	target_include_directories(lexbor  INTERFACE 
						$<BUILD_INTERFACE:${LEXBOR_INCLUDE_DIR}>
						)
	target_link_libraries(lexbor INTERFACE $<BUILD_INTERFACE:${LEXBOR_LIBRARY}>)
endif()

if(NOT TARGET lexbor::lexbor)
	add_library(lexbor::lexbor INTERFACE IMPORTED)
    set_target_properties(lexbor::lexbor PROPERTIES
                          INTERFACE_LINK_LIBRARIES 
							  lexbor_static
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						  )
	target_include_directories(lexbor::lexbor  INTERFACE 
						$<BUILD_INTERFACE:${LEXBOR_INCLUDE_DIR}>
						)
	target_link_libraries(lexbor::lexbor INTERFACE $<BUILD_INTERFACE:${LEXBOR_LIBRARY}>)
endif()

set(lexbor ${LEXBOR_LIBRARY} CACHE FILEPATH "lexbor library" FORCE)

####################### docwire
set(DOCWIRE_DOC OFF CACHE BOOL "Compile Documentation" FORCE)
set(DOCWIRE_TRACE OFF CACHE BOOL "Enable Tracing" FORCE)
set(DOCWIRE_TESTS OFF CACHE BOOL "Build tests" FORCE)
set(DOCWIRE_CLI OFF CACHE BOOL "Build CLI" FORCE)
set(DOCWIRE_OPENAI OFF CACHE BOOL "Enable OpenAI Module" FORCE)
set(DOCWIRE_LOCALAI OFF CACHE BOOL "Enable Local AI Module" FORCE)
set(DOCWIRE_OCR OFF CACHE BOOL "Enable OCR Module" FORCE)
set(DOCWIRE_MAIL OFF CACHE BOOL "Enable Mail Module" FORCE)
set(DOCWIRE_PDF ON CACHE BOOL "Enable PDF Module" FORCE)
set(DOCWIRE_HTTP OFF CACHE BOOL "Enable HTTP Module" FORCE)

FetchContent_Declare(
  docwire
  GIT_REPOSITORY https://github.com/sheldonrobinson/docwire.git
  GIT_TAG        35d13571facbe6bd1af8edeb0dee5ae3799875cd
  GIT_SHALLOW    TRUE
  
  CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE=ON
			 -DBUILD_SHARED_LIBS=OFF
			 -DADDRESS_SANITIZER=OFF
			 -DDOCWIRE_DOC=${DOCWIRE_DOC}
			 -DDOCWIRE_TRACE=${DOCWIRE_TRACE}
			 -DDOCWIRE_TESTS=${DOCWIRE_TESTS}
			 -DDOCWIRE_CLI=${DOCWIRE_CLI}
			 -DDOCWIRE_OPENAI=${DOCWIRE_OPENAI}
			 -DDOCWIRE_LOCALAI=${DOCWIRE_LOCALAI}
			 -DDOCWIRE_OCR=${DOCWIRE_OCR}
			 -DDOCWIRE_MAIL=${DOCWIRE_MAIL}
			 -DDOCWIRE_PDF=${DOCWIRE_PDF}
			 -DDOCWIRE_HTTP=${DOCWIRE_HTTP}
			 
  
)

FetchContent_MakeAvailable(docwire lexbor rapidfuzz charsetdetect base64 file-windows)

# add_dependencies(docwire aklomp::base64 lexbor rapidfuzz::rapidfuzz libcharsetdetect unofficial-libmagic)

# Invoke the build for native code shared with the other target platforms.
# This can be changed to accommodate different builds.
add_subdirectory("${UNNU_DOCPARSER_PROSRC_DIR}" "${CMAKE_CURRENT_BINARY_DIR}/shared")

set_target_properties(unnu_dxp PROPERTIES
  BUILD_WITH_INSTALL_RPATH TRUE
)


# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(unnu_dxp_bundled_libraries
  # Defined in ../src/CMakeLists.txt.
  # This can be changed to accommodate different builds.
  $<TARGET_FILE:unnu_dxp>
  PARENT_SCOPE
)
