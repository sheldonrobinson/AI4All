# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.24)

# Project-level configuration.
set(PROJECT_NAME "unnu_ragl")
project(${PROJECT_NAME} LANGUAGES CXX C)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT DEFINED CMAKE_INSTALL_PREFIX)
 	set(CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_BINARY_DIR}" CACHE PATH "Needed to avoid cmake_install.cmake build issues." FORCE) 
endif()

set(CMAKE_BUILD_RPATH_USE_ORIGIN TRUE)
set(UNNU_RAG_LITE_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../src)

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

set(CMAKE_POSITION_INDEPENDENT_CODE ON)

include(FetchContent)
include(InstallRequiredSystemLibraries)

find_package(OpenMP REQUIRED)

######################### duckdb
FetchContent_Declare(
  duckdb
  GIT_REPOSITORY		 https://github.com/sheldonrobinson/duckdb.git
  GIT_TAG				 origin/v1.4.x
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

######################## sqlite3
FetchContent_Declare(
  sqlite3
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/sqlite-amalgamation.git
  GIT_TAG        		 origin/master
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL
			 
  OVERRIDE_FIND_PACKAGE
			 
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

######################## sqlite3 cont
set(SQLITE3_ENABLE_SHARED             ON CACHE BOOL  "Build shared library"                           FORCE)
set(SQLITE3_ENABLE_STATIC             OFF CACHE BOOL "Build static library"                           FORCE)
set(SQLITE3_BUILD_SHELL               OFF CACHE BOOL "Build SQLite3 shell application"                FORCE)
set(SQLITE3_ENABLE_STATIC_SHELL       OFF CACHE BOOL "Statically link shell tool"                     FORCE)
set(SQLITE3_ENABLE_DEBUG              OFF CACHE BOOL "Build with debugging features enabled"          FORCE)
set(SQLITE3_ENABLE_EDITLINE           OFF CACHE BOOL "Use BSD libedit"                                FORCE)
set(SQLITE3_ENABLE_READLINE           OFF CACHE BOOL "Use GNU readline"                               FORCE)
set(SQLITE3_ENABLE_ICU                OFF CACHE BOOL "Enable international components for unicode"    FORCE)
set(SQLITE3_ENABLE_THREADSAFE         ON CACHE BOOL "Build a thread-safe library"                     FORCE)
set(SQLITE3_ENABLE_DYNAMIC_EXTENSIONS ON CACHE BOOL "Support loadable extensions"                     FORCE)
set(SQLITE3_ENABLE_MATH               ON CACHE BOOL "SQL math functions"                              FORCE)
set(SQLITE3_ENABLE_FTS4               ON CACHE BOOL "Include fts4 support"                            FORCE)
set(SQLITE3_ENABLE_FTS3               OFF CACHE BOOL "Include fts3 support"                           FORCE)
set(SQLITE3_ENABLE_FTS5               ON CACHE BOOL "Include fts5 support"                            FORCE)
set(SQLITE3_ENABLE_RTREE              ON CACHE BOOL "Include rtree support"                           FORCE)
set(SQLITE3_ENABLE_SESSION            OFF CACHE BOOL "Enable the session extension"                   FORCE)
set(SQLITE3_ENABLE_COLUMN_METADATA    OFF CACHE BOOL "Enable column metadata"                         FORCE)
set(SQLITE3_ENABLE_DBSTAT_VTAB        OFF CACHE BOOL "Enable dbstat virtual table"                    FORCE)
set(SQLITE3_ENABLE_RBU                OFF CACHE BOOL "Enable resumable bulk update extension"         FORCE)
set(SQLITE3_ENABLE_STAT4              OFF CACHE BOOL "Enhance query planner under certain situations" FORCE)
set(SQLITE3_OMIT_DECLTYPE             OFF CACHE BOOL "Omit declared type of columns"                  FORCE)
set(SQLITE3_OMIT_JSON                 OFF CACHE BOOL "Omit JSON SQL functions"                        FORCE)
set(SQLITE3_OMIT_AUTOINIT             OFF CACHE BOOL "Omit automatic initialization"                  FORCE)
set(SQLITE3_RECOMMENDED_OPTIONS       ON CACHE BOOL "Compile by SQLite3 recommended options"          FORCE)
set(SQLITE3_USE_URI                   ON CACHE BOOL "Enable the default URI filename processing"      FORCE)
set(SQLITE3_WIN32_USE_UUID            OFF CACHE BOOL "Enable uuid type and method"     				  FORCE)
set(SQLITE3_INSTALL                   OFF CACHE BOOL "Install applications and library"          	  FORCE)

FetchContent_MakeAvailable(sqlite3 zlib bzip2)

add_dependencies(sqlite3-shared zlibstatic)

file(REAL_PATH ${sqlite3_SOURCE_DIR} SQLITE3_INCLUDE_DIR)
file(REAL_PATH ${sqlite3_SOURCE_DIR} SQLITE3_SOURCE_DIR)
file(REAL_PATH ${sqlite3_BINARY_DIR} SQLITE3_BINARY_DIR)

set(SQLITE3_LIBRARY ${SQLITE3_BINARY_DIR}/$<CONFIG>/sqlite3.lib CACHE FILEPATH "sqlite3 library" FORCE)
set(SQLITE3_LIB_DIR ${SQLITE3_BINARY_DIR}/$<CONFIG> CACHE PATH "sqlite3 library directory" FORCE)

if(NOT TARGET SQLite::SQLite3)
	add_library(SQLite::SQLite3 INTERFACE IMPORTED)
    set_target_properties(SQLite::SQLite3 PROPERTIES
                          INTERFACE_LINK_LIBRARIES 
							  sqlite3-shared
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						  )
	target_include_directories(SQLite::SQLite3 INTERFACE 
						$<BUILD_INTERFACE:${SQLITE3_INCLUDE_DIR}>
						$<BUILD_INTERFACE:${CMAKE_BINARY_DIR}>
						)
	target_link_libraries(SQLite::SQLite3 INTERFACE $<BUILD_INTERFACE:${SQLITE3_LIBRARY}>)
endif()

######################## boost cont
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

set(BOOST_ENABLE_MPI OFF CACHE BOOL "Build and enable installation of Boost.MPI and its dependents (requires MPI, CMake 3.10)" FORCE)
set(BOOST_ENABLE_PYTHON OFF CACHE BOOL "Build and enable installation of Boost.Python and its dependents (requires Python, CMake 3.14)" FORCE)
set(BUILD_TESTING OFF CACHE BOOL "Build the tests." FORCE)

set(BOOST_DLL_USE_STD_FS ON CACHE BOOL "Use std::filesystem instead of Boost.Filesystem" FORCE)
set(BOOST_ALL_NO_LIB ON CACHE BOOL "Build no system binaries." FORCE)

FetchContent_MakeAvailable(boost zlib bzip2 liblzma zstd iconv)

target_include_directories(boost_iostreams PRIVATE ${LibLZMA_INCLUDE_DIR} ${ZSTD_INCLUDE_DIR} ${BZIP2_SOURCE_DIR} ${BZIP2_BINARY_DIR} ${ZLIB_SOURCE_DIR} ${ZLIB_BINARY_DIR})
add_dependencies(boost_iostreams iconv_static zlibstatic bz2_static libzstd_static liblzma)

target_include_directories(boost_locale PRIVATE ${Iconv_INCLUDE_DIR})
add_dependencies(boost_locale iconv_static)

############################ Corrosion
FetchContent_Declare(
    Corrosion
    GIT_REPOSITORY		   https://github.com/corrosion-rs/corrosion.git
    GIT_TAG 	   		   v0.5 # Optionally specify a commit hash, version tag or branch here
	GIT_SHALLOW 		   TRUE
    GIT_SUBMODULES_RECURSE TRUE
)

set(CORROSION_DEV_MODE OFF CACHE BOOL "Enables some additional features if you're developing Corrosion" FORCE)
set(CORROSION_BUILD_TESTS OFF CACHE BOOL "Build Corrosion test project" FORCE)

FetchContent_MakeAvailable(Corrosion)

############################### GQLite
FetchContent_Declare(
    gqlite
    GIT_REPOSITORY		   https://github.com/sheldonrobinson/GQLite.git
    GIT_TAG				   origin/unnu_rag # Optionally specify a commit hash, version tag or branch here
	GIT_SHALLOW 		   TRUE
    GIT_SUBMODULES_RECURSE TRUE
			 
    OVERRIDE_FIND_PACKAGE
)

set(GQLITE_TESTS_OUTPUT_JUNIT OFF CACHE BOOL "Make GQLite test output junit" FORCE)
set(GQLITE_TESTS_DISABLE_RUST_TESTS OFF CACHE BOOL "Disable rust unittest (intended for CI)" FORCE)
set(GQLITE_INSTALL OFF CACHE BOOL "Install applicatuins and libraries" FORCE)

# FetchContent_MakeAvailable(zlib sqlite3 Corrosion gqlite)

FetchContent_GetProperties(gqlite)
if(NOT gqlite_POPULATED)

  # message("Fetch gqlite using previously declared details")
  FetchContent_Populate(gqlite)

  # Set custom variables, policies, etc.
  # ...

  # Bring the populated content into the build
  
  # corrosion_import_crate(MANIFEST_PATH ${gqlite_SOURCE_DIR}/Cargo.toml)
  add_subdirectory(${gqlite_SOURCE_DIR} ${gqlite_BINARY_DIR})
endif()

if(MSVC)
	set_target_properties(gqlitecpp PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS ON)
endif()

file(REAL_PATH ${gqlite_SOURCE_DIR}/include GQLITE_INCLUDE_DIR)
file(REAL_PATH ${gqlite_SOURCE_DIR} GQLITE_SOURCE_DIR)
file(REAL_PATH ${gqlite_BINARY_DIR} GQLITE_BINARY_DIR)

set(GQLITE_LIBRARY ${GQLITE_BINARY_DIR}/$<CONFIG>/gqlite.lib CACHE FILEPATH "gqlite library" FORCE)

set(GQLITEDB_IMPORTLIB ${GQLITE_BINARY_DIR}/gqlitedb.dll.lib CACHE FILEPATH "gqlite.dll link library" FORCE)
set(GQLITEDB_LIBRARY ${GQLITE_BINARY_DIR}/gqlitedb.dll CACHE FILEPATH "gqlite.dll library" FORCE)

if(NOT TARGET gqlitedbdll)
	add_library(gqlitedbdll SHARED IMPORTED GLOBAL)
	set_target_properties(# Specifies the target library.
						   gqlitedbdll

						   # Specifies the parameter you want to define.
						   PROPERTIES IMPORTED_LOCATION

						   # Provides the path to the library you want to import.
						   ${GQLITEDB_LIBRARY})
	target_include_directories(gqlitedbdll INTERFACE $<BUILD_INTERFACE:${GQLITE_INCLUDE_DIR}>)
	if(MSVC)
		set_target_properties(gqlitedbdll PROPERTIES IMPORTED_IMPLIB ${GQLITEDB_IMPORTLIB})
	endif()
endif()
# add_dependencies(gqlitedb sqlite3-shared)

######################### pthreadpool
FetchContent_Declare(
  pthreadpool
  GIT_REPOSITORY		 https://github.com/sheldonrobinson/pthreadpool.git
  GIT_TAG				 origin/main
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL
  			 
  OVERRIDE_FIND_PACKAGE
)

######################### fxdiv
FetchContent_Declare(
  fxdiv
  GIT_REPOSITORY		 https://github.com/sheldonrobinson/FXdiv.git
  GIT_TAG				 origin/master
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL
			 
  OVERRIDE_FIND_PACKAGE
)

set(FXDIV_USE_INLINE_ASSEMBLY  OFF CACHE BOOL "Allow use of inline assembly in FXdiv" FORCE)
set(FXDIV_BUILD_TESTS OFF CACHE BOOL "Build FXDiv unit tests" FORCE)
set(FXDIV_BUILD_BENCHMARKS  OFF CACHE BOOL "Build FXDiv micro-benchmarks" FORCE)
set(FXDIV_INSTALL OFF CACHE BOOL "Install applicatuins and libraries" FORCE)

FetchContent_MakeAvailable(fxdiv)

file(REAL_PATH ${fxdiv_SOURCE_DIR}/include FXDIV_INCLUDE_DIR)
file(REAL_PATH ${fxdiv_SOURCE_DIR} FXDIV_SOURCE_DIR)
file(REAL_PATH ${fxdiv_BINARY_DIR} FXDIV_BINARY_DIR)

set(FXDIV_LIBRARY ${FXDIV_BINARY_DIR}/$<CONFIG>/fxdiv.lib CACHE FILEPATH "fxdiv library" FORCE)

target_compile_definitions(fxdiv INTERFACE FXDIV_USE_INLINE_ASSEMBLY=0)

################## cpuinfo
FetchContent_Declare(
  cpuinfo
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/cpuinfo.git
  GIT_TAG        		 origin/main
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL
			 
  OVERRIDE_FIND_PACKAGE
)

set(CPUINFO_LOG_LEVEL "none" CACHE STRING "Minimum logging level (info with lower severity will be ignored)" FORCE)
set(CPUINFO_LOG_TO_STDIO OFF CACHE BOOL "Log errors, warnings, and information to stdout/stderr" FORCE)
set(CPUINFO_LIBRARY_TYPE "static" CACHE STRING "Type of cpuinfo library (shared, static, or default) to build" FORCE)
set(CPUINFO_BUILD_TOOLS OFF CACHE BOOL "Build command-line tools" FORCE)
set(CPUINFO_BUILD_UNIT_TESTS OFF CACHE BOOL "Build cpuinfo unit tests" FORCE)
set(CPUINFO_BUILD_MOCK_TESTS OFF CACHE BOOL "Build cpuinfo mock tests" FORCE)
set(CPUINFO_BUILD_BENCHMARKS OFF CACHE BOOL "Build cpuinfo micro-benchmarks" FORCE)
set(CPUINFO_BUILD_PKG_CONFIG OFF CACHE BOOL "Build pkg-config manifest" FORCE)
set(CPUINFO_INSTALL OFF CACHE BOOL "Install applicatuins and libraries" FORCE)

FetchContent_MakeAvailable(cpuinfo)

file(REAL_PATH ${cpuinfo_SOURCE_DIR}/include CPUINFO_INCLUDE_DIR)
file(REAL_PATH ${cpuinfo_SOURCE_DIR} CPUINFO_SOURCE_DIR)
file(REAL_PATH ${cpuinfo_BINARY_DIR} CPUINFO_BINARY_DIR)

set(CPUINFO_LIBRARY ${CPUINFO_BINARY_DIR}/$<CONFIG>/cpuinfo.lib CACHE FILEPATH "cpuinfo library" FORCE)

######################### pthreadpool cont
set(PTHREADPOOL_LIBRARY_TYPE "static" CACHE STRING "Type of library (shared, static, or default) to build" FORCE)
set(PTHREADPOOL_ALLOW_DEPRECATED_API OFF CACHE BOOL "Enable deprecated API functions" FORCE)
set(PTHREADPOOL_BUILD_TESTS OFF CACHE BOOL "Build pthreadpool unit tests" FORCE)
set(PTHREADPOOL_BUILD_BENCHMARKS OFF CACHE BOOL "Build pthreadpool micro-benchmarks" FORCE)
set(PTHREADPOOL_INSTALL OFF CACHE BOOL "Install applicatuins and libraries" FORCE)

FetchContent_MakeAvailable(pthreadpool cpuinfo fxdiv)

file(REAL_PATH ${pthreadpool_SOURCE_DIR}/include PTHREADPOOL_INCLUDE_DIR)
file(REAL_PATH ${pthreadpool_SOURCE_DIR} PTHREADPOOL_SOURCE_DIR)
file(REAL_PATH ${pthreadpool_BINARY_DIR} PTHREADPOOL_BINARY_DIR)

set(PTHREADPOOL_LIBRARY ${PTHREADPOOL_BINARY_DIR}/$<CONFIG>/pthreadpool.lib CACHE FILEPATH "pthreadpool library" FORCE)

add_dependencies(pthreadpool cpuinfo fxdiv)
target_compile_definitions(pthreadpool PUBLIC PTHREADPOOL_USE_CPUINFO=1)
target_include_directories(pthreadpool PRIVATE $<BUILD_INTERFACE:${CPUINFO_INCLUDE_DIR}>)


######################### blingfire
set(BLING_FIRE_INSTALL OFF CACHE INTERNAL "Install applications and libraries" FORCE)
FetchContent_Declare(
  blingfire
  GIT_REPOSITORY		 https://github.com/sheldonrobinson/BlingFire.git
  GIT_TAG				 origin/master
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL
			 
  OVERRIDE_FIND_PACKAGE
)

FetchContent_MakeAvailable(blingfire)

file(REAL_PATH ${blingfire_SOURCE_DIR}/blingfireclient.library/inc BLINGFIRE_INCLUDE_DIR)
file(REAL_PATH ${blingfire_SOURCE_DIR} BLINGFIRE_SOURCE_DIR)
file(REAL_PATH ${blingfire_BINARY_DIR} BLINGFIRE_BINARY_DIR)

set(BLINGFIRE_LIBRARY ${BLINGFIRE_BINARY_DIR}/$<CONFIG>/fsaClient.lib CACHE FILEPATH "blingfire library" FORCE)

######################### tokenizer-cpp
set(MSGPACK_USE_BOOST OFF CACHE BOOL "Use Boost libraried" FORCE)
set(MSGPACK_BUILD_DOCS OFF CACHE BOOL "Build Doxygen documentation" FORCE)
set(MSGPACK_INSTALL OFF CACHE BOOL "Install applications and libraries" FORCE)
set(MLC_ENABLE_SENTENCEPIECE_TOKENIZER ON CACHE BOOL "Enable SentencePiece tokenizer" FORCE)

set(SPM_ENABLE_NFKC_COMPILE OFF CACHE BOOL "Enables NFKC compile" FORCE)
set(SPM_ENABLE_SHARED OFF CACHE BOOL "Builds shared libaries in addition to static libraries." FORCE)
set(SPM_BUILD_TEST OFF CACHE BOOL "Builds test binaries." FORCE)
set(SPM_COVERAGE OFF CACHE BOOL "Runs gcov to test coverage." FORCE)
set(SPM_ENABLE_TENSORFLOW_SHARED OFF CACHE BOOL "Makes a tensorflow compatible shared file." FORCE)
set(SPM_ENABLE_TCMALLOC OFF CACHE BOOL "Enable TCMalloc if available." FORCE)
set(SPM_TCMALLOC_STATIC ON CACHE BOOL "Link static library of TCMALLOC." FORCE)
set(SPM_NO_THREADLOCAL OFF CACHE BOOL "Disable thread_local operator" FORCE)
set(SPM_ENABLE_MSVC_MT_BUILD OFF CACHE BOOL "Use /MT flag in MSVC build" FORCE)

FetchContent_Declare(
  tokenizers_cpp
  GIT_REPOSITORY		 https://github.com/sheldonrobinson/tokenizers-cpp.git
  GIT_TAG				 origin/main
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL
			 
  OVERRIDE_FIND_PACKAGE
)

FetchContent_MakeAvailable(tokenizers_cpp)

file(REAL_PATH ${tokenizers_cpp_SOURCE_DIR}/include TOKENIZERS_CPP_INCLUDE_DIR)
file(REAL_PATH ${tokenizers_cpp_SOURCE_DIR} TOKENIZERS_CPP_SOURCE_DIR)
file(REAL_PATH ${tokenizers_cpp_BINARY_DIR} TOKENIZERS_CPP_BINARY_DIR)

set(TOKENIZERS_CPP_LIBRARY ${TOKENIZERS_CPP_BINARY_DIR}/$<CONFIG>/tokenizer_cpp.lib CACHE FILEPATH "tokenizer-cpp library" FORCE)

# target_compile_options(sentencepiece-static PUBLIC /MD$<$<CONFIG:Debug>:d>)
# target_compile_options(sentencepiece_train-static PUBLIC /MD$<$<CONFIG:Debug>:d>)

################## ct2
FetchContent_Declare(
  ct2
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/CTranslate2.git
  GIT_TAG        		 origin/master
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL
  			 
  OVERRIDE_FIND_PACKAGE
)

################## onednn
FetchContent_Declare(
  dnnl
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/oneDNN.git
  GIT_TAG        		 origin/main
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL
			 
  OVERRIDE_FIND_PACKAGE
)

################## onetbb
FetchContent_Declare(
  tbb
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/oneTBB.git
  GIT_TAG        		 origin/master
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL
  			 
  OVERRIDE_FIND_PACKAGE
)

set(TBB_TEST OFF CACHE BOOL "Enable testing" FORCE)
set(TBB_EXAMPLES OFF CACHE BOOL "Enable examples" FORCE)
set(TBB_STRICT ON CACHE BOOL "Treat compiler warnings as errors" FORCE)
set(TBB_WINDOWS_DRIVER OFF CACHE BOOL "Build as Universal Windows Driver (UWD)" FORCE)
set(TBB_NO_APPCONTAINER OFF CACHE BOOL "Apply /APPCONTAINER:NO (for testing binaries for Windows Store)" FORCE)
set(TBB4PY_BUILD OFF CACHE BOOL "Enable tbb4py build" FORCE)
set(TBB_BUILD ON CACHE BOOL "Enable tbb build" FORCE)
set(TBBMALLOC_BUILD OFF CACHE BOOL "Enable tbbmalloc build" FORCE)
set(TBB_CPF OFF CACHE INTERNAL "Enable preview features of the library" FORCE)
set(TBB_FIND_PACKAGE OFF CACHE BOOL "Enable search for external oneTBB using find_package instead of build from sources" FORCE)
set(TBB_DISABLE_HWLOC_AUTOMATIC_SEARCH OFF CACHE BOOL "Disable HWLOC automatic search by pkg-config tool" FORCE)
set(TBB_ENABLE_IPO ON CACHE BOOL "Enable Interprocedural Optimization (IPO) during the compilation" FORCE)
set(TBB_CONTROL_FLOW_GUARD OFF CACHE BOOL "Enable Control Flow Guard (CFG) during the compilation" FORCE)
set(TBB_FUZZ_TESTING OFF CACHE BOOL "Enable fuzz testing" FORCE)
set(TBB_INSTALL OFF CACHE BOOL "Enable installation" FORCE)
set(TBB_FILE_TRIM ON CACHE BOOL "Enable __FILE__ trim" FORCE)
set(TBB_ENABLE_SHARED_LIBS ON CACHE BOOL "Build shared libs" FORCE)

FetchContent_MakeAvailable(tbb)

file(REAL_PATH ${tbb_SOURCE_DIR}/include TBB_INCLUDE_DIR)
file(REAL_PATH ${tbb_SOURCE_DIR} TBB_SOURCE_DIR)
file(REAL_PATH ${tbb_BINARY_DIR} TBB_BINARY_DIR)

################## armadillo
FetchContent_Declare(
  armadillo
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/armadillo.git
  GIT_TAG        		 15.2.x
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL
  			 
  OVERRIDE_FIND_PACKAGE
)

################## OpenBLAS
FetchContent_Declare(
  openblas
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/OpenBLAS.git
  GIT_TAG        		 origin/develop
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL
			 
  OVERRIDE_FIND_PACKAGE
)

set(OPENBLAS_BUILD_WITHOUT_LAPACK ON CACHE BOOL "Do not build LAPACK and LAPACKE (Only BLAS or CBLAS)" FORCE)
set(OPENBLAS_BUILD_WITHOUT_LAPACKE ON CACHE BOOL "Do not build the C interface to LAPACK)" FORCE)
set(OPENBLAS_BUILD_LAPACK_DEPRECATED OFF CACHE BOOL "When building LAPACK, include also some older, deprecated routines" FORCE)
set(BUILD_TESTING OFF CACHE BOOL "Build LAPACK testsuite when building LAPACK" FORCE)
set(BUILD_BENCHMARKS OFF CACHE BOOL "Build the collection of BLAS/LAPACK benchmarks" FORCE)
set(C_LAPACK ON CACHE BOOL "Build LAPACK from C sources instead of the original Fortran" FORCE)
set(OPENBLAS_BUILD_WITHOUT_CBLAS OFF CACHE BOOL "Do not build the C interface (CBLAS) to the BLAS functions" FORCE)
set(OPENBLAS_DYNAMIC_ARCH OFF CACHE BOOL "Include support for multiple CPU targets, with automatic selection at runtime (x86/x86_64, aarch64, ppc or RISCV64-RVV1.0 only)" FORCE)
set(BUILD_RELAPACK OFF CACHE BOOL "Build with ReLAPACK (recursive implementation of several LAPACK functions on top of standard LAPACK)" FORCE)
set(OPENBLAS_BUILD_STATIC_LIBS OFF CACHE BOOL "Build static library" FORCE)
set(OPENBLAS_BUILD_SHARED_LIBS ON CACHE BOOL "Build shared library" FORCE)
set(OPENBLAS_INSTALL OFF CACHE BOOL "Install applications and library" FORCE)
set(NOFORTRAN ON CACHE BOOL "No fortran compiler available" FORCE)
set(NO_AVX512 OFF CACHE BOOL "Do not use AVX512 extensions" FORCE)
set(USE_OPENMP ON CACHE BOOL "Enable OpenMP" FORCE)

FetchContent_MakeAvailable(openblas)

if (MSVC)
    target_compile_options(openblas_shared PUBLIC /fp:fast /arch:avx /arch:AVX2)
else ()
    target_compile_options(openblas_shared PUBLIC -mavx -mavx2 -mfma)
endif ()

file(REAL_PATH ${openblas_SOURCE_DIR} OPENBLAS_INCLUDE_DIR)
file(REAL_PATH ${openblas_SOURCE_DIR} OPENBLAS_SOURCE_DIR)
file(REAL_PATH ${openblas_BINARY_DIR} OPENBLAS_BINARY_DIR)

file(GLOB OPENBLAS_HEADERS_H ${openblas_SOURCE_DIR}/*.h)
file(COPY ${OPENBLAS_HEADERS_H} DESTINATION ${OPENBLAS_BINARY_DIR})
file(TO_NATIVE_PATH ${CMAKE_BINARY_DIR} OPENBLAS_CONFIG_DIRPATH)
file(TO_NATIVE_PATH ${OPENBLAS_BINARY_DIR} OPENBLAS_BINARY_DIRPATH)
list(APPEND OPENBLAS_INCLUDE_PATH ${OPENBLAS_CONFIG_DIRPATH} ${OPENBLAS_BINARY_DIRPATH})
set(OPENBLAS_LIBRARY ${OPENBLAS_BINARY_DIR}/lib/$<CONFIG>/openblas.lib CACHE FILEPATH "openblas library" FORCE)

list(APPEND OPENBLAS_INCLUDE_DIRS ${OPENBLAS_BINARY_DIR} ${CMAKE_BINARY_DIR})
set(BLAS_LIBRARIES ${OPENBLAS_LIBRARY} CACHE STRING "BLAS libraries" FORCE)
set(BLAS_INCLUDE_DIRS ${OPENBLAS_BINARY_DIR} CACHE STRING "BLAS include dirs" FORCE)
# target_include_directories(openblas_shared PRIVATE ${OPENBLAS_BINARY_DIR})

if(NOT TARGET BLAS::BLAS)
	add_library(BLAS::BLAS INTERFACE IMPORTED)
    set_target_properties(BLAS::BLAS PROPERTIES
                          INTERFACE_LINK_LIBRARIES
							openblas_shared
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
							)
endif()

################## armadillo cont
set(BLA_VENDOR "OpenBLAS" CACHE STRING "BLAS Vendor" FORCE)
set(ARMADILLO_STATIC_LIB ON CACHE BOOL "Generate static library instead of shared library" FORCE)
set(ARMADILLO_INSTALL OFF CACHE BOOL "Install applicatuins and libraries" FORCE)
set(OPENBLAS_PROVIDES_LAPACK OFF CACHE BOOL "Assume that OpenBLAS provides LAPACK functions" FORCE)

FetchContent_MakeAvailable(armadillo openblas)

file(REAL_PATH ${armadillo_SOURCE_DIR}/include ARMADILLO_INCLUDE_DIR)
file(REAL_PATH ${armadillo_SOURCE_DIR} ARMADILLO_SOURCE_DIR)
file(REAL_PATH ${armadillo_BINARY_DIR} ARMADILLO_BINARY_DIR)

set(ARMADILLO_LIBRARY ${ARMADILLO_BINARY_DIR}/$<CONFIG>/armadillo.lib CACHE FILEPATH "armadillo library" FORCE)

add_dependencies(armadillo openblas_shared)

################## onednn cont

set(DNNL_VERBOSE OFF CACHE BOOL "allows oneDNN be verbose whenever ONEDNN_VERBOSE environment variable set to 1" FORCE)
set(DNNL_ENABLE_CONCURRENT_EXEC ON CACHE BOOL "disables sharing a common scratchpad between primitives. This option must be turned ON if there is a possibility of executing distinct primitives concurrently. CAUTION: enabling this option increases memory consumption." FORCE) 
set(DNNL_ENABLE_PRIMITIVE_CACHE ON CACHE BOOL "enables primitive cache." FORCE)
set(DNNL_ENABLE_MAX_CPU_ISA ON CACHE BOOL "enables control of CPU ISA detected by oneDNN via DNNL_MAX_CPU_ISA environment variable and dnnl_set_max_cpu_isa() function" FORCE)
set(DNNL_ENABLE_CPU_ISA_HINTS ON CACHE BOOL "enables control of CPU ISA specific hints by oneDNN via DNNL_CPU_ISA_HINTS environment variable and dnnl_set_cpu_isa_hints() function" FORCE)
set(ONEDNN_BUILD_GRAPH ON CACHE BOOL "builds graph component" FORCE)
set(DNNL_LIBRARY_TYPE "SHARED" CACHE STRING "specifies whether oneDNN library should be SHARED or STATIC" FORCE)
set(DNNL_BUILD_DOC OFF CACHE BOOL "builds documentation" FORCE)
set(DNNL_BUILD_EXAMPLES OFF CACHE BOOL "builds examples" FORCE)
set(DNNL_BUILD_TESTS OFF CACHE BOOL "builds tests" FORCE)
set(DNNL_BUILD_FOR_CI OFF CACHE BOOL "specifies whether oneDNN library will use special testing environment for internal testing processes" FORCE)
set(DNNL_DEV_MODE OFF CACHE BOOL "Enables internal tracing capabilities" FORCE)
set(DNNL_WERROR OFF CACHE BOOL "treat warnings as errors" FORCE)
set(DNNL_EXPERIMENTAL OFF CACHE BOOL "Enables experimental features in oneDNN. When enabled, each experimental feature has to be individually selected using environment variables."  FORCE)
set(DNNL_EXPERIMENTAL_UKERNEL OFF CACHE BOOL "Enable experimental functionality for ukernels. This option works independently from DNNL_EXPERIMENTAL." FORCE)
set(DNNL_EXPERIMENTAL_PROFILING OFF CACHE BOOL "Enable experimental profiling capabilities. This option works independently from DNNL_EXPERIMENTAL." FORCE)
set(DNNL_EXPERIMENTAL_LOGGING OFF CACHE BOOL "Enable experimental functionality for logging. This option works independently from DNNL_EXPERIMENTAL." FORCE)
set(DNNL_EXPERIMENTAL_SYCL_KERNEL_COMPILER OFF CACHE BOOL "Enable experimental SYCL OpenCL kernel compiler extension. This option works independently from DNNL_EXPERIMENTAL." FORCE)
set(DNNL_ENABLE_JIT_PROFILING OFF CACHE BOOL "Enable registration of oneDNN kernels that are generated at runtime with VTune Profiler (on by default). Without the registrations, VTune Profiler would report data collected inside the kernels as `outside any known module`." FORCE)
set(DNNL_ENABLE_ITT_TASKS OFF CACHE BOOL "Enable ITT Tasks tagging feature and tag all primitive execution (on by default). VTune Profiler can group profiling results based on those ITT tasks and show corresponding timeline information." FORCE)
set(DNNL_ENABLE_MEM_DEBUG OFF CACHE BOOL "enables memory-related debug functionality, such as buffer overflow (default) and underflow, using gtests and benchdnn. Additionaly, this option enables testing of out-of-memory handling by the library, such as failed memory allocations, using primitive-related gtests. This feature is experimental and is only available on Linux." FORCE)
set(DNNL_ENABLE_STACK_CHECKER OFF CACHE BOOL "enables stack checker that can be used to get information about stack consumption for a particular library entry point. This feature is only available on Linux (see src/common/stack_checker.hpp for more details). Note: This option requires enabling concurrent scratchpad (DNNL_ENABLE_CONCURRENT_EXEC)." FORCE)
set(DNNL_DISABLE_GPU_REF_KERNELS OFF CACHE BOOL "builds oneDNN with only optimized kernels for GPU compute primitives" FORCE)
set(DNNL_INSTALL OFF CACHE BOOL "Install applications and libraries" FORCE)

FetchContent_MakeAvailable(dnnl tbb openblas)

if (MSVC)
    target_compile_options(dnnl PUBLIC /arch:SSE2 /arch:AVX /arch:AVX2 /fp:fast)
else ()
    target_compile_options(dnnl PUBLIC -msse2 -mavx -mavx2 -mfma)
endif ()

file(REAL_PATH ${dnnl_SOURCE_DIR}/include DNNL_INCLUDE_DIR)
file(REAL_PATH ${dnnl_SOURCE_DIR} DNNL_SOURCE_DIR)
file(REAL_PATH ${dnnl_BINARY_DIR} DNNL_BINARY_DIR)

set(DNNL_LIBRARY ${DNNL_BINARY_DIR}/src/$<CONFIG>/dnnl.lib CACHE FILEPATH "dnnl library" FORCE)

add_dependencies(dnnl tbb openblas_shared)

################## ct2

set(WITH_MKL OFF CACHE BOOL "Compile with Intel MKL backend" FORCE)
set(WITH_DNNL ON CACHE BOOL "Compile with DNNL backend" FORCE)
set(WITH_OPENBLAS ON CACHE BOOL "Compile with OpenBLAS backend" FORCE)
set(WITH_RUY OFF CACHE BOOL "Compile with Ruy backend" FORCE)
set(WITH_CUDA OFF CACHE BOOL "Compile with CUDA backend" FORCE)
set(WITH_CUDNN OFF CACHE BOOL "Compile with cuDNN backend" FORCE)
set(CUDA_DYNAMIC_LOADING OFF CACHE BOOL "Dynamically load CUDA libraries at runtime" FORCE)
set(OPENMP_RUNTIME "COMP" CACHE STRING "OpenMP runtime (INTEL, COMP, NONE)" FORCE)
set(ENABLE_CPU_DISPATCH ON CACHE BOOL "Compile CPU kernels for multiple ISA and dispatch at runtime" FORCE)
set(ENABLE_PROFILING OFF CACHE BOOL "Compile with profiling support" FORCE)
set(BUILD_CLI OFF CACHE BOOL "Compile the clients" FORCE)
set(BUILD_TESTS OFF CACHE BOOL "Compile the tests" FORCE)
set(CT2_BUILD_SHARED_LIBS ON CACHE BOOL "Build shared libraries" FORCE)
set(WITH_TENSOR_PARALLEL OFF CACHE BOOL "Compile with NCCL and MPI backend" FORCE)
set(WITH_FLASH_ATTN OFF CACHE BOOL "Compile with Flash Attention 2" FORCE)
set(CT2_INSTALL OFF CACHE BOOL "Install applications and libraries" FORCE)

FetchContent_MakeAvailable(ct2 dnnl tbb openblas)

file(REAL_PATH ${ct2_SOURCE_DIR}/include CTRANSLATE2_INCLUDE_DIR)
file(REAL_PATH ${ct2_SOURCE_DIR} CTRANSLATE2_SOURCE_DIR)
file(REAL_PATH ${ct2_BINARY_DIR} CTRANSLATE2_BINARY_DIR)

set(CTRANSLATE2_LIBRARY ${CTRANSLATE2_BINARY_DIR}/$<CONFIG>/ctranslate2.lib CACHE FILEPATH "ctranslate2 library" FORCE)
add_dependencies(ctranslate2 dnnl tbb openblas_shared)
target_include_directories(ctranslate2 PRIVATE ${DNNL_INCLUDE_DIR} ${DNNL_BINARY_DIR}/include ${OPENBLAS_INCLUDE_DIR} ${CMAKE_BINARY_DIR} ${OPENBLAS_BINARY_DIR})


######################### duckdb
if ( (CMAKE_CXX_COMPILER_ARCHITECTURE_ID STREQUAL "ARM64") OR  (CMAKE_CXX_COMPILER_ARCHITECTURE_ID STREQUAL "arm64") )
    set(DUCKDB_EXPLICIT_PLATFORM "windows_arm64" CACHE STRING "Set the platform for duckdb" FORCE) 
else()
    set(DUCKDB_EXPLICIT_PLATFORM "windows_amd64" CACHE STRING "Set the platform for duckdb" FORCE)
endif()
set(BUILD_MAIN_DUCKDB_LIBRARY ON CACHE BOOL "Build the main duckdb library and executable." FORCE)
set(EXTENSION_STATIC_BUILD ON CACHE BOOL "Extension build linking statically with DuckDB. Required for building linux loadable extensions."  FORCE)
		
set(FORCE_WARN_UNUSED OFF CACHE BOOL "Unused code objects lead to compiler warnings." FORCE)
set(SHADOW_FORBIDDEN_FUNCTIONS OFF CACHE BOOL "Compile time test on usage of deprecated functions" FORCE)
set(DISABLE_UNITY OFF CACHE BOOL "Disable unity builds." FORCE)
set(FORCE_COLORED_OUTPUT OFF CACHE BOOL "Always produce ANSI-colored output (GNU/Clang only)." FORCE)
set(BUILD_COMPLETE_EXTENSION_SET ON CACHE BOOL "Whether we need to actually build the complete set" FORCE)
set(WASM_ENABLED OFF CACHE BOOL "Are DuckDB-Wasm extensions build enabled" FORCE)
set(MUSL_ENABLED OFF CACHE BOOL "Are Musl extensions build enabled" FORCE)
set(EXPORT_DYNAMIC_SYMBOLS OFF CACHE BOOL "Export dynamic symbols." FORCE)
set(EXPORT_DLL_SYMBOLS ON CACHE BOOL "Export dll symbols on Windows, else import" FORCE)

set(BUILD_COMPLETE_EXTENSION_SET ON CACHE BOOL "Whether we need to actually build the complete set" FORCE)
set(DISABLE_BUILTIN_EXTENSIONS OFF CACHE BOOL "Disable linking extensions." FORCE)
set(GENERATE_EXTENSION_ENTRIES OFF CACHE BOOL "Build for generating extension_entries.hpp" FORCE)

set(DUCKDB_INSTALL OFF CACHE BOOL "Install applications and library" FORCE)

set(ENABLE_EXTENSION_AUTOLOADING ON CACHE BOOL "Enable extension auto-loading by default." FORCE)
set(ENABLE_EXTENSION_AUTOINSTALL  ON CACHE BOOL "Enable extension auto-installing by default." FORCE)
set(EXTENSION_TESTS_ONLY OFF CACHE BOOL "Only load the tests for extensions, don't actually build them; useful for testing loadable extensions" FORCE)
set(WASM_LOADABLE_EXTENSIONS OFF CACHE BOOL "WebAssembly build with loadable extensions." FORCE)
set(BUILD_EXTENSIONS_ONLY OFF CACHE BOOL "Build all extension as linkable, overriding DONT_LINK, and don't build core." FORCE)
set(EXPLICIT_EXCEPTIONS OFF CACHE BOOL "Explicitly enable C++ exceptions." FORCE)
set(BUILD_SHELL OFF CACHE BOOL "Build the DuckDB Shell and SQLite API Wrappers" FORCE)
set(BUILD_UNITTESTS  OFF CACHE BOOL "Build the unittest runner." FORCE)
set(ENABLE_UNITTEST_CPP_TESTS  OFF CACHE BOOL "Build the C++ Unit Tests." FORCE)
set(SET_DUCKDB_LIBRARY_VERSION OFF CACHE BOOL "Whether or not to set the DuckDB Library version and emit versioned shared libraries" FORCE)

FetchContent_MakeAvailable(duckdb zlib bzip2)

file(REAL_PATH ${duckdb_SOURCE_DIR}/src/include DUCKDB_INCLUDE_DIR)
file(REAL_PATH ${duckdb_SOURCE_DIR} DUCKDB_SOURCE_DIR)
file(REAL_PATH ${duckdb_BINARY_DIR} DUCKDB_BINARY_DIR)

set(DUCKDB_LIBRARY ${DUCKDB_BINARY_DIR}/src/$<CONFIG>/duckdb_static.lib CACHE FILEPATH "duckdb library" FORCE)

include_directories(${DUCKDB_SOURCE_DIR}/extension/fts/extension/fts/include ${DUCKDB_SOURCE_DIR}/extension/sqlite/src/include ${DUCKDB_SOURCE_DIR}/extension/vss/src/include)

add_dependencies(core_functions_extension zlibstatic)
add_dependencies(fts_extension zlibstatic)
add_dependencies(icu_extension zlibstatic)
add_dependencies(json_extension zlibstatic)
add_dependencies(parquet_extension zlibstatic)
add_dependencies(sqlite_scanner_extension zlibstatic)


# Invoke the build for native code shared with the other target platforms.
# This can be changed to accommodate different builds.
add_subdirectory("${UNNU_RAG_LITE_SRC_DIR}" "${CMAKE_CURRENT_BINARY_DIR}/shared")

# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(unnu_ragl_bundled_libraries
  # Defined in ../src/CMakeLists.txt.
  # This can be changed to accommodate different builds.
  $<TARGET_FILE:unnu_ragl>
  $<TARGET_FILE:dnnl>
  $<TARGET_FILE:openblas_shared>
  $<TARGET_FILE:sqlite3-shared>
  PARENT_SCOPE
)
