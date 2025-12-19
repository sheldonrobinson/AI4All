# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "unnu_ce")
project(${PROJECT_NAME} LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT DEFINED CMAKE_INSTALL_PREFIX)
	set(CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_BINARY_DIR}" CACHE PATH "Needed to avoid cmake_install.cmake build issues." FORCE) 
	if(NOT DEFINED CMAKE_INSTALL_BINDIR)
		set(CMAKE_INSTALL_BINDIR ${CMAKE_BINARY_DIR}/runner/$<CONFIG>)
	endif()
endif()

set(CMAKE_BUILD_RPATH_USE_ORIGIN TRUE)
set(UNNU_COG_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../src)

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

if(MSVC)
	add_compile_definitions(_CRT_SECURE_NO_WARNINGS NOMINMAX)
	add_compile_options(/EHsc)
	set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
	set(CMAKE_INSTALL_UCRT_LIBRARIES ON)
	set(CMAKE_INSTALL_OPENMP_LIBRARIES ON)
	set(CMAKE_INSTALL_SYSTEM_RUNTIME_DESTINATION ${CMAKE_BINARY_DIR}/runner/$<CONFIG>)
endif()

include(FetchContent)
include(ExternalProject)

find_package(Python COMPONENTS Interpreter REQUIRED)
find_package(Perl REQUIRED)

#################### MSVC vcvars
FetchContent_Declare(
  find-vcvars
  GIT_REPOSITORY 		 https://github.com/scikit-build/cmake-FindVcvars.git
  GIT_TAG        		 origin/master
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL
)

FetchContent_Populate(find-vcvars)

file(REAL_PATH ${find-vcvars_SOURCE_DIR} FINDVCVARS_SOURCE_DIR)

list(INSERT CMAKE_MODULE_PATH 0 ${FINDVCVARS_SOURCE_DIR})

set(cmd_wrapper)
if(MSVC)
  set(Vcvars_MSVC_ARCH 64)
  set(Vcvars_FIND_VCVARSALL TRUE)
  find_package(Vcvars REQUIRED)
  set(cmd_wrapper ${Vcvars_LAUNCHER})
endif()

######################## tcl
ExternalProject_Add(tcl86_project
      GIT_REPOSITORY			https://github.com/tcltk/tcl.git
      GIT_TAG 					core-8-6-17
	  GIT_SHALLOW 				TRUE
	  GIT_SUBMODULES_RECURSE	TRUE
      BUILD_IN_SOURCE 			ON
	  SOURCE_SUBDIR 			win
	  CONFIGURE_COMMAND	""
      BUILD_COMMAND				${cmd_wrapper} nmake -nologo -f makefile.vc MACHINE=x64 OPTS=msvcrt,nostubs,unchecked INSTALLDIR=<INSTALL_DIR>
      INSTALL_COMMAND			${cmd_wrapper} nmake -nologo -f makefile.vc install MACHINE=x64 OPTS=msvcrt,nostubs,unchecked INSTALLDIR=<INSTALL_DIR>
	  STEP_TARGETS download build install
	  USES_TERMINAL_BUILD 		TRUE
	  USES_TERMINAL_INSTALL 	TRUE
      )

ExternalProject_Get_Property(tcl86_project INSTALL_DIR)
set(TCL_HOME ${INSTALL_DIR})

set(TCL86_LIB_DIR "${TCL_HOME}/lib")
set(TCL86_BIN_DIR "${TCL_HOME}/bin")
set(TCL86_INC_DIR "${TCL_HOME}/include")


set(TCL86_BUILD_BINPATH "${TCL_HOME}/bin/tcl86t.dll")
set(TCL86_BUILD_IMPORTLIBPATH "${TCL_HOME}/lib/tcl86t.lib")
set(GZIP_BUILD_BINPATH "${TCL_HOME}/bin/zlib1.dll")

if(NOT EXISTS ${TCL86_INC_DIR})
 file(MAKE_DIRECTORY ${TCL86_INC_DIR})
endif()

if(NOT TARGET tcl86t)
	add_library(tcl86t SHARED IMPORTED GLOBAL)
	add_dependencies(tcl86t tcl86_project-install)
	set_target_properties( tcl86t
						   PROPERTIES 
						   IMPORTED_LOCATION ${TCL86_BUILD_BINPATH}
						   IMPORTED_IMPLIB ${TCL86_BUILD_IMPORTLIBPATH}
						   INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${TCL86_INC_DIR}>
						 )
	if (MSVC)
		set_target_properties(tcl86t PROPERTIES 
					PDB_OUTPUT_DIRECTORY $<INSTALL_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/tcl86/$<CONFIG>/lib>
					)
	endif()
endif()

if(NOT TARGET gzip)
    add_library(gzip SHARED IMPORTED GLOBAL)
    add_dependencies(gzip tcl86_project-install)
	set_target_properties( gzip
						   PROPERTIES
						   IMPORTED_LOCATION ${GZIP_BUILD_BINPATH}
						   )
endif()

######################## soar
FetchContent_Declare(
  soar
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/Soar.git
  GIT_TAG        		 origin/development
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE

  EXCLUDE_FROM_ALL		 
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
  GIT_REPOSITORY 		 https://github.com/madler/zlib.git
  GIT_TAG        		 v1.3.1.2
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL
			 
  OVERRIDE_FIND_PACKAGE

)

######################## bzip2
FetchContent_Declare(
  bzip2
  GIT_REPOSITORY 		 https://github.com/libarchive/bzip2.git
  GIT_TAG        		 origin/master
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL
			 
  OVERRIDE_FIND_PACKAGE
)

set(BZIP2_ENABLE_LIB_ONLY ON CACHE BOOL "Build libbz2 only.  This is a short hand for -DENABLE_APP=0 -DENABLE_EXAMPLES=0" FORCE)
set(BZIP2_ENABLE_STATIC_LIB ON CACHE BOOL "Build libbz2 in static mode also" FORCE)
set(BZIP2_ENABLE_SHARED_LIB OFF CACHE BOOL "Build libbz2 as a shared library" FORCE)
set(ENABLE_LIB_ONLY ON CACHE BOOL "Build libbz2 only.  This is a short hand for -DENABLE_APP=0 -DENABLE_EXAMPLES=0" FORCE)
set(ENABLE_STATIC_LIB ON CACHE BOOL "Build libbz2 in static mode also" FORCE)
set(ENABLE_SHARED_LIB OFF CACHE BOOL "Build libbz2 as a shared library" FORCE)
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
set(ZLIB_BUILD_SHARED ON CACHE BOOL "Enable building zlib shared library" FORCE)
set(ZLIB_BUILD_STATIC OFF CACHE BOOL "Enable building zlib static library" FORCE)
set(ZLIB_BUILD_MINIZIP ON CACHE BOOL "Enable building libminizip contrib library" FORCE)
set(ZLIB_INSTALL OFF CACHE BOOL "Enable installation of zlib" FORCE)
set(ZLIB_BUILD_EXAMPLES OFF CACHE BOOL "Enable Zlib Examples" FORCE)

####################### minizip
set(MINIZIP_BUILD_SHARED ON CACHE BOOL "Enable building minizip shared library" FORCE)
set(MINIZIP_BUILD_STATIC OFF CACHE BOOL "Enable building minizip static library" FORCE)
set(MINIZIP_BUILD_TESTING OFF CACHE BOOL "Enable testing of minizip" FORCE)
set(MINIZIP_ENABLE_BZIP2 ON CACHE BOOL "Build minizip withj bzip2 support" FORCE)
set(MINIZIP_INSTALL OFF CACHE BOOL "Enable installation of minizip" FORCE)

FetchContent_MakeAvailable(zlib bzip2)

file(REAL_PATH ${zlib_SOURCE_DIR} ZLIB_SOURCE_DIR)
file(REAL_PATH ${zlib_BINARY_DIR} ZLIB_BINARY_DIR)

set(ZLIB_LIBRARY "${ZLIB_BINARY_DIR}/$<CONFIG>/z$<$<CONFIG:Debug>:d>.lib" CACHE FILEPATH "zlib library" FORCE)
set(ZLIB_INCLUDE_DIR "${ZLIB_SOURCE_DIR}" CACHE PATH "zlib include dir" FORCE)

if(NOT TARGET ZLIB::ZLIB)
	add_library(ZLIB::ZLIB SHARED IMPORTED GLOBAL)
    set_target_properties(ZLIB::ZLIB PROPERTIES
                          INTERFACE_LINK_LIBRARIES
							zlib
						  INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${ZLIB_INCLUDE_DIR}>
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						)
endif()

if(NOT TARGET unofficial::minizip::minizip)
	add_library(unofficial::minizip::minizip INTERFACE IMPORTED)
    set_target_properties(unofficial::minizip::minizip PROPERTIES
                          INTERFACE_LINK_LIBRARIES
						  libminizip zlib bz2_static
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						 )
endif()

add_dependencies(zlib bz2_static)

add_dependencies(libminizip zlib bz2_static)


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

add_dependencies(sqlite3-shared zlib)

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
						)
	target_link_libraries(SQLite::SQLite3 INTERFACE $<BUILD_INTERFACE:${SQLITE3_LIBRARY}>)
endif()

if(NOT TARGET SQLite3)
	add_library(SQLite3 INTERFACE IMPORTED)
    set_target_properties(SQLite3 PROPERTIES
                          INTERFACE_LINK_LIBRARIES 
							  sqlite3-shared
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						  )
	target_include_directories(SQLite3 INTERFACE 
						$<BUILD_INTERFACE:${SQLITE3_INCLUDE_DIR}>
						)
	target_link_libraries(SQLite3 INTERFACE $<BUILD_INTERFACE:${SQLITE3_LIBRARY}>)
endif()



######################## build soar
set(BUILD_TESTS OFF CACHE BOOL "Build tests" FORCE)
set(CLI OFF CACHE BOOL "Build Soar command line interface" FORCE)
set(SVS OFF CACHE BOOL "SVS Enabled" FORCE)
set(ENABLE_TCL ON CACHE BOOL "Build Soar with tcl bindings" FORCE)
set(TCL_LIBRARY ${TCL86_BUILD_IMPORTLIBPATH} CACHE FILEPATH "The path to the Tcl library" FORCE)
set(TCL_INCLUDE_PATH ${TCL86_INC_DIR} CACHE PATH "The directory containing tcl.h and other Tcl-related headers" FORCE)
set(TCL_TCLSH "${TCL86_BINARY_DIR}/$<CONFIG>/bin/tclsh86t${CMAKE_EXECUTABLE_SUFFIX}" CACHE FILEPATH "The path to the tclsh command-line executable" FORCE)

FetchContent_MakeAvailable(soar sqlite3 zlib bzip2)

file(REAL_PATH ${soar_SOURCE_DIR} SOAR_SOURCE_DIR)
file(REAL_PATH ${soar_BINARY_DIR} SOAR_BINARY_DIR)

add_dependencies(soar_lib sqlite3-shared zlib)
add_dependencies(TclSoarLib soar_lib tcl86t)

###################### onnxruntime
# FetchContent_Declare(
  # ort_project
  # GIT_REPOSITORY 		 https://github.com/sheldonrobinson/onnxruntime.git
  # GIT_TAG        		 origin/main
  # GIT_SHALLOW 			 TRUE
  # GIT_SUBMODULES_RECURSE TRUE

  # EXCLUDE_FROM_ALL
# )

# FetchContent_Populate(ort_project)

# file(REAL_PATH ${ort_project_SOURCE_DIR} ORT_SOURCE_DIR)
# file(REAL_PATH ${ort_project_BINARY_DIR} ORT_BINARY_DIR)

# file(TO_NATIVE_PATH ${ORT_SOURCE_DIR} ORT_BUILD_SRC_DIR)
# file(TO_NATIVE_PATH "tools/ci_build/build.py" ORT_BUILD_PY)
# file(TO_NATIVE_PATH ${ORT_BINARY_DIR} ORT_BUILD_BINARY_DIR)

# set(ORT_BUILD_PROJECT_DIR "${ORT_SOURCE_DIR}/Release")

# set(ORT_HOME ${ORT_BINARY_DIR})
# set(ORT_BUILD_DIR ${ORT_SOURCE_DIR}/$<CONFIG>)

# set(ORT_LIB_DIR "${ORT_HOME}/lib")
# set(ORT_BIN_DIR "${ORT_HOME}/bin")
# set(ORT_INC_DIR "${ORT_HOME}/include")
# set(ORT_HDRS_DIR "${ORT_HOME}/include/onnxruntime")

# if(NOT EXISTS ${ORT_INC_DIR})
 # file(MAKE_DIRECTORY ${ORT_INC_DIR})
# endif()

# set(ORT_OUTPUT_BINPATH "${ORT_BUILD_SRC_DIR}/Release/Release/onnxruntime.dll")
# set(ORT_OUTPUT_PROVIDERS_BINPATH "${ORT_BUILD_SRC_DIR}/Release/Release/onnxruntime_providers_shared.dll")
# set(ORT_OUTPUT_IMPORTLIBPATH "${ORT_BUILD_SRC_DIR}/Release/Release/onnxruntime.lib")
# set(ORT_OUTPUT_PROVIDERS_IMPORTLIBPATH "${ORT_BUILD_SRC_DIR}/Release/Release/onnxruntime_providers_shared.lib")


# set(ORT_BUILD_BINPATH "${ORT_HOME}/bin/onnxruntime.dll")
# set(ORT_BUILD_PROVIDERS_BINPATH "${ORT_HOME}/bin/onnxruntime_providers_shared.dll")
# set(ORT_BUILD_IMPORTLIBPATH "${ORT_HOME}/lib/onnxruntime.lib")
# set(ORT_BUILD_PROVIDERS_IMPORTLIBPATH "${ORT_HOME}/lib/onnxruntime_providers_shared.lib")

# add_custom_command(OUTPUT ${ORT_OUTPUT_BINPATH}
						  # ${ORT_OUTPUT_PROVIDERS_BINPATH}
						  # ${ORT_OUTPUT_IMPORTLIBPATH}
						  # ${ORT_OUTPUT_PROVIDERS_IMPORTLIBPATH}
				   # COMMAND ${Python_EXECUTABLE} ${ORT_BUILD_PY} 
											 # --cmake_generator "Visual Studio 17 2022" 
											 # --build_dir ${ORT_BUILD_SRC_DIR}
											 # --config Release 
											 # --build_shared_lib 
											 # --use_mimalloc 
											 # --use_full_protobuf
											 # --use_dml
											 # --use_binskim_compliant_compile_flags
											 # --compile_no_warning_as_error 
											 # --parallel
											 # --skip_submodule_sync
											 # --skip_tests 
											 # --skip_winml_tests 
											 # --cmake_extra_defines CMAKE_INSTALL_PREFIX=${ORT_BUILD_BINARY_DIR}
				   # WORKING_DIRECTORY ${ORT_BUILD_SRC_DIR}
				   # COMMAND_EXPAND_LISTS
				   # USES_TERMINAL
				   # VERBATIM)
	
# add_custom_target(ort_install ALL ${cmd_wrapper} msbuild Install.vcxproj -property:Configuration=Release
				# DEPENDS ${ORT_OUTPUT_BINPATH}
						# ${ORT_OUTPUT_PROVIDERS_BINPATH}
						# ${ORT_OUTPUT_IMPORTLIBPATH}
						# ${ORT_OUTPUT_PROVIDERS_IMPORTLIBPATH}
				# BYPRODUCTS	${ORT_BUILD_BINPATH}
							# ${ORT_BUILD_PROVIDERS_BINPATH}
							# ${ORT_BUILD_IMPORTLIBPATH}
							# ${ORT_BUILD_PROVIDERS_IMPORTLIBPATH}
				# WORKING_DIRECTORY ${ORT_BUILD_PROJECT_DIR}
				# COMMENT "Running generated ort install batch script..."
				# COMMAND_EXPAND_LISTS
				# VERBATIM
				# USES_TERMINAL)

ExternalProject_Add(
  ort_project
  GIT_REPOSITORY			https://github.com/sheldonrobinson/onnxruntime.git
  GIT_TAG					origin/main
  GIT_SHALLOW				TRUE
  GIT_SUBMODULES_RECURSE	TRUE
  BUILD_IN_SOURCE			ON
  CONFIGURE_COMMAND			""
  BUILD_COMMAND				${Python_EXECUTABLE} <SOURCE_DIR>/tools/ci_build/build.py
									 --cmake_generator "Visual Studio 17 2022"
									 --build_dir <SOURCE_DIR>
									 --config $<CONFIG>
									 --build_shared_lib 
									 --use_mimalloc 
									 --use_full_protobuf
									 --use_dml
									 --use_binskim_compliant_compile_flags
									 --compile_no_warning_as_error 
									 --parallel
									 --skip_submodule_sync
									 --skip_tests 
									 --skip_winml_tests 
									 --cmake_extra_defines CMAKE_INSTALL_PREFIX=<INSTALL_DIR>
  INSTALL_COMMAND			${cmd_wrapper} msbuild <SOURCE_DIR>/$<CONFIG>/INSTALL.vcxproj /p:Configuration=$<CONFIG>
  STEP_TARGETS build install
  USES_TERMINAL_CONFIGURE	TRUE
  USES_TERMINAL_BUILD 		TRUE
  USES_TERMINAL_INSTALL 	TRUE
)


ExternalProject_Get_property(ort_project INSTALL_DIR)
set(ONNXRUNTIME_ROOT_DIR ${INSTALL_DIR} CACHE PATH "onnxruntime root dir" FORCE)

set(ORT_HOME ${ONNXRUNTIME_ROOT_DIR})
set(ORT_LIB_DIR "${ORT_HOME}/lib")
set(ORT_BIN_DIR "${ORT_HOME}/bin")
set(ORT_INC_DIR "${ORT_HOME}/include")
set(ORT_HDRS_DIR "${ORT_HOME}/include/onnxruntime")

if(NOT EXISTS ${ORT_HDRS_DIR})
 file(MAKE_DIRECTORY ${ORT_HDRS_DIR})
endif()

set(ORT_BUILD_BINPATH "${ORT_HOME}/bin/onnxruntime.dll")
set(ORT_BUILD_PROVIDERS_BINPATH "${ORT_HOME}/bin/onnxruntime_providers_shared.dll")
set(ORT_BUILD_IMPORTLIBPATH "${ORT_HOME}/lib/onnxruntime.lib")
set(ORT_BUILD_PROVIDERS_IMPORTLIBPATH "${ORT_HOME}/lib/onnxruntime_providers_shared.lib")

# add_library(ort SHARED IMPORTED GLOBAL)
# add_dependencies(ort ort_project-install)
# list(APPEND ORT_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${ORT_BINARY_DIR}/include> $<BUILD_INTERFACE:${ORT_BINARY_DIR}/include/onnxruntime>)
# set_target_properties(# Specifies the target library.
                       # ort
                       # PROPERTIES 
					   # IMPORTED_LOCATION			 ${ORT_BUILD_BINPATH}
					   # IMPORTED_IMPLIB				 ${ORT_BUILD_IMPORTLIBPATH}
					 # )
# if (MSVC)
	# set_target_properties(ort PROPERTIES 
				# PDB_OUTPUT_DIRECTORY $<INSTALL_INTERFACE:${ORT_BUILD_DIR}/$<CONFIG>>
				# )
# endif()

# add_library(onnxruntime_providers_shared SHARED IMPORTED GLOBAL)
# add_dependencies(onnxruntime_providers_shared ort_project-install)
# set_target_properties(# Specifies the target library.
                       # onnxruntime_providers_shared
                       # PROPERTIES 
					   # IMPORTED_LOCATION	${ORT_BUILD_PROVIDERS_BINPATH}
					   # IMPORTED_IMPLIB		${ORT_BUILD_PROVIDERS_IMPORTLIBPATH}
					 # )
# if (MSVC)
	# set_target_properties(onnxruntime_providers_shared PROPERTIES 
				# PDB_OUTPUT_DIRECTORY $<INSTALL_INTERFACE:${ORT_BUILD_DIR}/$<CONFIG>>
				# )
# endif()

if(NOT TARGET ort)
	add_library(ort SHARED IMPORTED GLOBAL)
	add_dependencies(ort ort_project-install)
	set_target_properties(# Specifies the target library.
						   ort
						   PROPERTIES 
						   IMPORTED_LOCATION			 ${ORT_BUILD_BINPATH}
						   IMPORTED_IMPLIB				 ${ORT_BUILD_IMPORTLIBPATH}
						   INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${ORT_INC_DIR}>
						 )
	if (MSVC)
		set_target_properties(ort PROPERTIES 
					PDB_OUTPUT_DIRECTORY $<INSTALL_INTERFACE:${ORT_LIB_DIR}>
					)
	endif()
endif()

if(NOT TARGET onnxruntime_providers_shared)
	add_library(onnxruntime_providers_shared SHARED IMPORTED GLOBAL)
	add_dependencies(onnxruntime_providers_shared ort_install)
	set_target_properties(# Specifies the target library.
						   onnxruntime_providers_shared
						   PROPERTIES 
						   IMPORTED_LOCATION	${ORT_BUILD_PROVIDERS_BINPATH}
						   IMPORTED_IMPLIB		${ORT_BUILD_PROVIDERS_IMPORTLIBPATH}
						   INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${ORT_INC_DIR}>
						 )
	if (MSVC)
		set_target_properties(onnxruntime_providers_shared PROPERTIES 
					PDB_OUTPUT_DIRECTORY $<INSTALL_INTERFACE:${ORT_LIB_DIR}>
					)
	endif()
endif()
if(NOT TARGET onnxruntime::onnxruntime)
	add_library(onnxruntime::onnxruntime INTERFACE IMPORTED)
	add_dependencies(onnxruntime::onnxruntime ort_install)
    set_target_properties(onnxruntime::onnxruntime PROPERTIES
						  INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${ORT_HDRS_DIR}>
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						 )
endif()

set(ORT_ROOT ${ORT_HOME} CACHE PATH "onnxruntime root directory" FORCE)
include_directories(${ORT_HOME}/include ${ORT_HOME}/include/onnxruntime)



################## nlohmann
FetchContent_Declare(
  nlohmann_json
  GIT_REPOSITORY 		 https://github.com/nlohmann/json.git
  GIT_TAG        		 v3.12.0
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL
  
  OVERRIDE_FIND_PACKAGE
)

set(JSON_BuildTests OFF CACHE BOOL "Build the unit tests when BUILD_TESTING is enabled." FORCE)
set(JSON_CI OFF CACHE BOOL "Enable CI build targets." FORCE)
set(JSON_Diagnostics OFF CACHE BOOL  "Use extended diagnostic messages." FORCE)
set(JSON_Diagnostic_Positions OFF CACHE BOOL "Enable diagnostic positions." FORCE)
set(JSON_GlobalUDLs ON CACHE BOOL "Place user-defined string literals in the global namespace." FORCE)
set(JSON_ImplicitConversions ON CACHE BOOL "Enable implicit conversions." FORCE)
set(JSON_DisableEnumSerialization OFF CACHE BOOL "Disable default integer enum serialization." FORCE)
set(JSON_LegacyDiscardedValueComparison OFF CACHE BOOL "Enable legacy discarded value comparison." FORCE)
set(JSON_Install OFF CACHE BOOL "Install CMake targets during install step." FORCE)
set(JSON_MultipleHeaders ON CACHE BOOL "Use non-amalgamated version of the library." FORCE)
set(JSON_SystemInclude OFF CACHE BOOL "Include as system headers (skip for clang-tidy)." FORCE)

FetchContent_MakeAvailable(nlohmann_json)

file(REAL_PATH ${nlohmann_json_SOURCE_DIR} NLOHMANN_JSON_SOURCE_DIR)

if(NOT TARGET nlohmann::json)
	add_library(nlohmann::json INTERFACE IMPORTED)
    set_target_properties(nlohmann::json PROPERTIES
                          INTERFACE_LINK_LIBRARIES nlohmann_json 							  
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						  )
endif()

################### argparse
FetchContent_Declare(
  argparse
  GIT_REPOSITORY 		 https://github.com/p-ranav/argparse.git
  GIT_TAG        		 v3.2
  GIT_SHALLOW 			 TRUE

  EXCLUDE_FROM_ALL

  OVERRIDE_FIND_PACKAGE
)

FetchContent_MakeAvailable(argparse)

if(NOT TARGET argparse::argparse)
	add_library(argparse::argparse INTERFACE IMPORTED)
    set_target_properties(argparse::argparse PROPERTIES
                          INTERFACE_LINK_LIBRARIES argparse 							  
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						  )
endif()

################### cpp-httplib
FetchContent_Declare(
  cpp-httplib
  GIT_REPOSITORY 		 https://github.com/yhirose/cpp-httplib.git
  GIT_TAG        		 v0.29.0
  GIT_SHALLOW 			 TRUE
  
  EXCLUDE_FROM_ALL
  
  OVERRIDE_FIND_PACKAGE
)

FetchContent_MakeAvailable(cpp-httplib)

if(NOT TARGET httplib::httplib)
	add_library(httplib::httplib INTERFACE IMPORTED)
    set_target_properties(httplib::httplib PROPERTIES
                          INTERFACE_LINK_LIBRARIES httplib 							  
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						  )
endif()

################### moodycamel::concurrentqueue
FetchContent_Declare(
  concurrentqueue 
  GIT_REPOSITORY 		 https://github.com/cameron314/concurrentqueue.git
  GIT_TAG        		 origin/master
  GIT_SHALLOW 			 TRUE
  
  EXCLUDE_FROM_ALL
  
  OVERRIDE_FIND_PACKAGE
)

FetchContent_MakeAvailable(concurrentqueue)

if(NOT TARGET moodycamel::concurrentqueue)
	add_library(moodycamel::concurrentqueue INTERFACE IMPORTED)
    set_target_properties(moodycamel::concurrentqueue PROPERTIES
						  INTERFACE_LINK_LIBRARIES concurrentqueue 							  
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						  )
endif()

###################### ortgenai
# Debug build broken missing reference to _imp__calloc_dbg, __imp__free_dbg, __imp__malloc_dbg, and __imp__CrtDbgReport 
FetchContent_Declare(
  oga_project
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/onnxruntime-genai.git
  GIT_TAG        		 origin/main
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE

  EXCLUDE_FROM_ALL
)

FetchContent_Populate(oga_project)

file(REAL_PATH ${oga_project_SOURCE_DIR} OGA_SOURCE_DIR)
file(REAL_PATH ${oga_project_BINARY_DIR} OGA_BINARY_DIR)

file(TO_NATIVE_PATH ${ORT_HOME} OGA_ORT_HOME)
file(TO_NATIVE_PATH ${OGA_SOURCE_DIR} OGA_BUILD_SRC_DIR)
file(TO_NATIVE_PATH "build.py" OGA_BUILD_PY)

file(TO_NATIVE_PATH ${OGA_BINARY_DIR} OGA_BUILD_BINARY_DIR)

set(OGA_BUILD_PROJECT_DIR "${OGA_SOURCE_DIR}/Release")

set(OGA_SLN_FILE "${OGA_SOURCE_DIR}/Release/Generators.sln")
set(OGA_OUTPUT_BINPATH "${OGA_BUILD_PROJECT_DIR}/Release/onnxruntime-genai.dll")
set(OGA_OUTPUT_IMPORTLIBPATH "${OGA_BUILD_PROJECT_DIR}/Release/onnxruntime-genai.lib")

set(OGA_HOME ${OGA_BINARY_DIR})
set(OGA_SOURCE_DIR ${OGA_SOURCE_DIR})

set(OGA_LIB_DIR "${OGA_HOME}/lib")
set(OGA_BIN_DIR "${OGA_HOME}/bin")
set(OGA_INC_DIR "${OGA_HOME}/include")

if(NOT EXISTS ${OGA_INC_DIR})
 file(MAKE_DIRECTORY ${OGA_INC_DIR})
endif()

set(OGA_BUILD_BINPATH "${OGA_HOME}/lib/onnxruntime-genai.dll")
set(OGA_BUILD_IMPORTLIBPATH "${OGA_HOME}/lib/onnxruntime-genai.lib")
# $<$<CONFIG:Debug>:CMAKE_CXX_FLAGS="/MDd /D_MT /D_DLL /D_DEBUG" LINK_FLAGS_DEBUG="/DEFAULTLIB:msvcrtd.lib /DEFAULTLIB:ucrtd.lib /DEFAULTLIB:msvcprtd.lib /DEFAULTLIB:vcruntimed.lib"> CMAKE_MSVC_RUNTIME_LIBRARY="MultiThreaded$<$<CONFIG:Debug>:Debug>DLL" 
add_custom_command(OUTPUT ${OGA_SLN_FILE}
				   COMMAND ${Python_EXECUTABLE} ${OGA_BUILD_PY}
											 --update
											 --cmake_generator "Visual Studio 17 2022" 
											 --build_dir ${OGA_BUILD_SRC_DIR} 
											 --config Release
											 --use_dml
											 --use_guidance
											 --parallel
											 --skip_examples
											 --skip_tests
											 --skip_wheel
											 --ort_home ${OGA_ORT_HOME}
											 --cmake_extra_defines CMAKE_INSTALL_PREFIX=${OGA_BUILD_BINARY_DIR} USE_WINML=OFF ONNXRUNTIME_LIB=onnxruntime.lib ZLIB_LIBRARY=${ZLIB_LIBRARY} ZLIB_INCLUDE_DIR=${ZLIB_INCLUDE_DIR}
				   WORKING_DIRECTORY ${OGA_SOURCE_DIR}
				   COMMAND_EXPAND_LISTS
				   USES_TERMINAL
				   VERBATIM)

add_custom_command(OUTPUT ${OGA_OUTPUT_BINPATH}
						  ${OGA_OUTPUT_IMPORTLIBPATH}
				   COMMAND ${Python_EXECUTABLE} ${OGA_BUILD_PY}
											 --build
											 --cmake_generator "Visual Studio 17 2022" 
											 --build_dir ${OGA_BUILD_SRC_DIR} 
											 --config Release 
											 --use_dml
											 --use_guidance
											 --parallel
											 --skip_examples
											 --skip_tests
											 --skip_wheel
											 --ort_home ${OGA_ORT_HOME}
											 --cmake_extra_defines CMAKE_INSTALL_PREFIX=${OGA_BUILD_BINARY_DIR} USE_WINML=OFF ONNXRUNTIME_LIB=onnxruntime.lib ZLIB_LIBRARY=${ZLIB_LIBRARY} ZLIB_INCLUDE_DIR=${ZLIB_INCLUDE_DIR}
				   DEPENDS ${OGA_SLN_FILE}					 
				   WORKING_DIRECTORY ${OGA_SOURCE_DIR}
				   COMMAND_EXPAND_LISTS
				   USES_TERMINAL
				   VERBATIM)
 
add_custom_target(oga_install ALL ${cmd_wrapper} msbuild Install.vcxproj -property:Configuration=Release
				  DEPENDS ${OGA_OUTPUT_BINPATH}
						  ${OGA_OUTPUT_IMPORTLIBPATH}
				  BYPRODUCTS ${OGA_BUILD_BINPATH}
							 ${OGA_BUILD_IMPORTLIBPATH}
				  WORKING_DIRECTORY ${OGA_BUILD_PROJECT_DIR}
				  COMMENT "Running generated oga install batch script..."
				  COMMAND_EXPAND_LISTS
				  VERBATIM
				  USES_TERMINAL)

add_dependencies(oga_install ort)
################### build ort-genai
set(OGA_LIB_DIR "${OGA_HOME}/lib")
set(OGA_BIN_DIR "${OGA_HOME}/bin")
set(OGA_INC_DIR "${OGA_HOME}/include")
set(OGA_HDRS_DIR "${OGA_HOME}/include")
list(APPEND OGA_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${OGA_BINARY_DIR}/include> ${ORT_INCLUDE_DIRECTORIES})
if(NOT TARGET ort-genai)
	add_library(ort-genai SHARED IMPORTED GLOBAL)
	add_dependencies(ort-genai oga_install)
	set_target_properties(# Specifies the target library.
						   ort-genai
						   PROPERTIES 
						   IMPORTED_LOCATION ${OGA_BUILD_BINPATH}
						   IMPORTED_IMPLIB ${OGA_BUILD_IMPORTLIBPATH}
						   INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${OGA_INC_DIR}>
						 )
	if (MSVC)
		set_target_properties(ort-genai PROPERTIES 
					PDB_OUTPUT_DIRECTORY $<INSTALL_INTERFACE:${OGA_BUILD_PROJECT_DIR}>
					)
	endif()
endif()

###################### slmengine configuration

include_directories(${OGA_HOME}/include ${ORT_HOME}/include ${ORT_HOME}/include/onnxruntime)

####################### eigen
set(BUILD_TESTING OFF CACHE BOOL "Enable creation of tests." FORCE)
set(EIGEN_BUILD_TESTING OFF CACHE BOOL "Enable creation of Eigen tests." FORCE)
set(EIGEN_LEAVE_TEST_IN_ALL_TARGET OFF CACHE BOOL "Leaves tests in the all target, needed by ctest for automatic building." FORCE)
set(EIGEN_BUILD_BLAS OFF CACHE BOOL "Toggles the building of the Eigen Blas library" FORCE)
set(EIGEN_BUILD_LAPACK OFF CACHE BOOL "Toggles the building of the included Eigen LAPACK library" FORCE)
set(EIGEN_BUILD_DOC OFF CACHE BOOL "Enable creation of Eigen documentation" FORCE)
set(EIGEN_BUILD_DEMOS OFF CACHE BOOL "Toggles the building of the Eigen demos" FORCE)
set(EIGEN_BUILD_CMAKE_PACKAGE OFF CACHE BOOL "Enables the creation of EigenConfig.cmake and related files" FORCE)

####################### onnxruntime
set(USE_CUDA OFF CACHE BOOL "Build with CUDA support" FORCE)
set(USE_TRT_RTX OFF CACHE BOOL "Build with TensorRT-RTX support" FORCE)
set(USE_ROCM OFF CACHE BOOL "Build with ROCm support" FORCE)
set(USE_DML ON CACHE BOOL "Build with DML support" FORCE)
set(USE_WINML OFF CACHE BOOL "Build with WinML support" FORCE)
set(USE_GUIDANCE ON CACHE BOOL "Build with guidance support" FORCE)

set(ARTIFACTS_DIR ${OGA_HOME} CACHE PATH "ort-genai home" FORCE)
add_subdirectory("${OGA_SOURCE_DIR}/examples/slm_engine/src" "${CMAKE_CURRENT_BINARY_DIR}/slm_engine")

add_dependencies(slmengine ort-genai argparse::argparse nlohmann::json)
add_dependencies(input_decoder-test ort-genai argparse::argparse nlohmann::json)

add_dependencies(slm-server ort-genai zlib argparse::argparse nlohmann::json)
add_dependencies(slm-runner ort-genai zlib argparse::argparse nlohmann::json)
add_dependencies(unit-test ort-genai zlib argparse::argparse nlohmann::json)

set(SLMENGINE_BUILD_BINPATH "${CMAKE_CURRENT_BINARY_DIR}/slm_engine/cpp/$<CONFIG>/slmengine.dll")
set(SLMENGINE_BUILD_IMPORTLIBPATH "${CMAKE_CURRENT_BINARY_DIR}/slm_engine/cpp/$<CONFIG>/slmengine.lib")

set_target_properties(slmengine PROPERTIES
					  INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${OGA_SOURCE_DIR}/examples/slm_engine/src/cpp>)


if(NOT TARGET SLMEngine)
	add_library(SLMEngine SHARED IMPORTED GLOBAL)
	add_dependencies(SLMEngine slmengine)
    set_target_properties(SLMEngine PROPERTIES
                          INTERFACE_LINK_LIBRARIES 
							  slmengine
						  IMPORTED_LOCATION ${SLMENGINE_BUILD_BINPATH}
					      IMPORTED_IMPLIB ${SLMENGINE_BUILD_IMPORTLIBPATH}
						  INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${OGA_SOURCE_DIR}/examples/slm_engine/src/cpp>
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						  )
	if (MSVC)
		set_target_properties(SLMEngine PROPERTIES 
					PDB_OUTPUT_DIRECTORY $<INSTALL_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/slm_engine/cpp/$<CONFIG>>
					)
	endif()
endif()



######################## uuid4
FetchContent_Declare(
  minimal-uuid4
  GIT_REPOSITORY 		 https://github.com/umasagashi/minimal_uuid4.git
  GIT_TAG        		 origin/main
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE

  EXCLUDE_FROM_ALL

  OVERRIDE_FIND_PACKAGE	 
)

FetchContent_Populate(minimal-uuid4)

file(REAL_PATH ${minimal-uuid4_SOURCE_DIR} MINIMAL_UUID4_SOURCE_DIR)

add_library(minimal_uuid4 INTERFACE IMPORTED GLOBAL)
set_target_properties( minimal_uuid4
                       PROPERTIES 
					   INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${MINIMAL_UUID4_SOURCE_DIR}/include>
					 )

#################### OpenSSL
# file(TO_NATIVE_PATH ${PERL_EXECUTABLE} PERL_COMMAND)

# ExternalProject_Add(ssl_project
      # GIT_REPOSITORY			https://github.com/openssl/openssl.git
      # GIT_TAG 					openssl-3.6.0
	  # GIT_SHALLOW 				TRUE
	  # GIT_SUBMODULES_RECURSE	TRUE
      # BUILD_IN_SOURCE 			ON
	  # CONFIGURE_COMMAND			${PERL_COMMAND} Configure zlib-dynamic shared no-deprecated no-apps no-tests $<$<CONFIG:Debug>:--debug> $<$<CONFIG:Release>:--release> --prefix=<INSTALL_DIR> --openssldir=<INSTALL_DIR>/ssl --with-zlib-include=${ZLIB_INCLUDE_DIR} --with-zlib-lib=${ZLIB_LIBRARY} VC-WIN64A
      # BUILD_COMMAND				${cmd_wrapper} nmake -f makefile
      # INSTALL_COMMAND			${cmd_wrapper} nmake -f makefile install
	  # STEP_TARGETS configure build install
	  # USES_TERMINAL_CONFIGURE	TRUE
	  # USES_TERMINAL_BUILD 		TRUE
	  # USES_TERMINAL_INSTALL 	TRUE
      # )


# ExternalProject_Get_Property(ssl_project INSTALL_DIR)
# set(SSL_HOME ${INSTALL_DIR})
# add_dependencies(ssl_project-build zlib)

# set(SSL_LIB_DIR "${SSL_HOME}/lib")
# set(SSL_BIN_DIR "${SSL_HOME}/bin")
# set(SSL_INC_DIR "${SSL_HOME}/include")

# if(NOT EXISTS ${SSL_INC_DIR})
 # file(MAKE_DIRECTORY ${SSL_INC_DIR})
# endif()


# if(NOT TARGET libssl)
	# add_library(libssl SHARED IMPORTED GLOBAL)
	# add_dependencies(libssl ssl_project-install)
    # set_target_properties(libssl PROPERTIES
                          # IMPORTED_LOCATION ${SSL_HOME}/bin/libssl-3-x64.dll
						  # IMPORTED_IMPLIB ${SSL_HOME}/lib/libssl.lib
						  # INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${SSL_INC_DIR}>
						  # INTERFACE_POSITION_INDEPENDENT_CODE ON
						  # )
	# if (MSVC)
		# set_target_properties(libssl PROPERTIES 
					# PDB_OUTPUT_DIRECTORY $<INSTALL_INTERFACE:${SSL_HOME}/bin>
					# )
	# endif()
# endif()

# if(NOT TARGET OpenSSL::SSL)
	# add_library(OpenSSL::SSL SHARED IMPORTED GLOBAL)
	# add_dependencies(OpenSSL::SSL ssl_project-install)
    # set_target_properties(OpenSSL::SSL PROPERTIES
                          # IMPORTED_LOCATION ${SSL_HOME}/bin/libssl-3-x64.dll
						  # IMPORTED_IMPLIB ${SSL_HOME}/lib/libssl.lib
						  # INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${SSL_INC_DIR}>
						  # INTERFACE_POSITION_INDEPENDENT_CODE ON
						  # )
	# if (MSVC)
		# set_target_properties(OpenSSL::SSL PROPERTIES 
					# PDB_OUTPUT_DIRECTORY $<INSTALL_INTERFACE:${SSL_HOME}/bin>
					# )
	# endif()
# endif()

# if(NOT TARGET libcrypto)
	# add_library(libcrypto SHARED IMPORTED GLOBAL)
	# add_dependencies(libcrypto ssl_project-install)
    # set_target_properties(libcrypto PROPERTIES
                          # IMPORTED_LOCATION ${SSL_HOME}/bin/libcrypto-3-x64.dll
						  # IMPORTED_IMPLIB ${SSL_HOME}/lib/libcrypto.lib
						  # INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${SSL_INC_DIR}>
						  # INTERFACE_POSITION_INDEPENDENT_CODE ON
						  # )
	# if (MSVC)
		# set_target_properties(libcrypto PROPERTIES 
					# PDB_OUTPUT_DIRECTORY $<INSTALL_INTERFACE:${SSL_HOME}/bin>
					# )
	# endif()
# endif()

# if(NOT TARGET OpenSSL::Crypto)
	# add_library(OpenSSL::Crypto SHARED IMPORTED GLOBAL)
	# add_dependencies(OpenSSL::Crypto ssl_project-install)
    # set_target_properties(OpenSSL::Crypto PROPERTIES
                          # IMPORTED_LOCATION ${SSL_HOME}/bin/libcrypto-3-x64.dll
						  # IMPORTED_IMPLIB ${SSL_HOME}/lib/libcrypto.lib
						  # INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${SSL_INC_DIR}>
						  # INTERFACE_POSITION_INDEPENDENT_CODE ON
						  # )
	# if (MSVC)
		# set_target_properties(OpenSSL::Crypto PROPERTIES 
					# PDB_OUTPUT_DIRECTORY $<INSTALL_INTERFACE:${SSL_HOME}/bin>
					# )
	# endif()
# endif()

# set(OPENSSL_CRYPTO_LIBRARY "${SSL_HOME}/lib/libcrypto.lib" CACHE FILEPATH "OpenSSL libcrypto library" FORCE)
# set(OPENSSL_INCLUDE_DIR "${SSL_HOME}/include" CACHE PATH "OpenSSL include directory" FORCE)
# set(OPENSSL_ROOT_DIR "${SSL_HOME}" CACHE PATH "OpenSSL root directory" FORCE)

# include_directories(${SSL_HOME}/include)

  # DEPENDS 		ssl_project-install
######################## langchain++
# ExternalProject_Add(
  # langchain_project
  # GIT_REPOSITORY 		 https://github.com/sheldonrobinson/langchain_cpp.git
  # GIT_TAG        		 origin/main
  # GIT_SHALLOW 		 	 TRUE
  # GIT_SUBMODULES_RECURSE TRUE
  # CMAKE_ARGS -DBUILD_SHARED_LIBS:BOOL=ON
			 # -DENABLE_TESTING:BOOL=OFF
			 # -DBUILD_STATIC_LIBS:BOOL=OFF
			 # -DOPENSSL_CRYPTO_LIBRARY:FILEPATH=${OPENSSL_CRYPTO_LIBRARY}
			 # -DOPENSSL_INCLUDE_DIR:PATH=${OPENSSL_INCLUDE_DIR}
			 # -DOPENSSL_ROOT_DIR:PATH=${OPENSSL_ROOT_DIR}
			 # -DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR>
  # STEP_TARGETS configure build install
  # USES_TERMINAL_CONFIGURE	TRUE
  # USES_TERMINAL_BUILD 		TRUE
  # USES_TERMINAL_INSTALL 	TRUE
# )

# add_dependencies(langchain_project-configure ssl_project-install)

# ExternalProject_Get_Property(langchain_project INSTALL_DIR)
# set(LANGCHAIN_HOME ${INSTALL_DIR})

FetchContent_Declare(
  langchain_cpp
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/langchain_cpp.git
  GIT_TAG        		 origin/main
  GIT_SHALLOW 		 	 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL
  
  OVERRIDE_FIND_PACKAGE
)

set(BUILD_STATIC_LIBS OFF CACHE BOOL "Build static libraries" FORCE)
set(BUILD_SHARED_LIBS ON CACHE BOOL "Build shared libraries" FORCE)
set(ENABLE_TESTING OFF CACHE BOOL "Enable tests" FORCE)

FetchContent_MakeAvailable(langchain_cpp)

file(REAL_PATH ${langchain_cpp_SOURCE_DIR} LANGCHAIN_SOURCE_DIR)
file(REAL_PATH ${langchain_cpp_BINARY_DIR} LANGCHAIN_BINARY_DIR)

if(NOT TARGET langchain)
	add_library(langchain SHARED IMPORTED GLOBAL)
    set_target_properties(langchain PROPERTIES
						  INTERFACE_LINK_LIBRARIES langchain_cpp
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						  )
endif()



######################## libuv
FetchContent_Declare(
  libuv
  GIT_REPOSITORY 		 https://github.com/libuv/libuv.git
  GIT_TAG        		 origin/v1.x
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL
			 
  OVERRIDE_FIND_PACKAGE
)

set(LIBUV_BUILD_SHARED ON CACHE BOOL "Build shared lib" FORCE)

FetchContent_MakeAvailable(libuv)

file(REAL_PATH ${libuv_SOURCE_DIR} LIBUV_SOURCE_DIR)
file(REAL_PATH ${libuv_BINARY_DIR} LIBUV_BINARY_DIR)

set(LIBUV_LIBRARY ${LIBUV_SOURCE_DIR}/$<CONFIG>/uv.lib CACHE FILEPATH "libuv library" FORCE)

if(NOT TARGET libuv::libuv)
	add_library(libuv::libuv INTERFACE IMPORTED)
    set_target_properties(libuv::libuv PROPERTIES
                          INTERFACE_LINK_LIBRARIES 
							  uv
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						  )
endif()

################ lean4
find_package(Msys REQUIRED)
FetchContent_Declare(lean4_project
	URL			https://github.com/leanprover/lean4/releases/download/v4.27.0-rc1/lean-4.27.0-rc1-windows.zip
	URL_HASH 	SHA256=f36278b51559e9fba7c9dbef30755da6a482b093cf1498b0d1c2638618351593
	EXCLUDE_FROM_ALL
			 
	OVERRIDE_FIND_PACKAGE
  )
  
FetchContent_Populate(lean4_project)

file(REAL_PATH ${lean4_project_SOURCE_DIR} LEAN4_SOURCE_DIR)
				   
add_custom_target(lean4_Init_shared ALL ${MSYS_INSTALL_PATH}/ucrt64${CMAKE_EXECUTABLE_SUFFIX} sh -c "gendef libInit_shared.dll;dlltool -d libInit_shared.def -l libInit_shared.lib -D libInit_shared.dll --as-flags=--64"
		BYPRODUCTS ${LEAN4_SOURCE_DIR}/bin/libInit_shared.lib 
		WORKING_DIRECTORY ${LEAN4_SOURCE_DIR}/bin
		VERBATIM
		USES_TERMINAL)

add_custom_target(lean4_Lake_shared ALL ${MSYS_INSTALL_PATH}/ucrt64${CMAKE_EXECUTABLE_SUFFIX} sh -c "gendef libLake_shared.dll;dlltool -d libLake_shared.def -l libLake_shared.lib -D libLake_shared.dll --as-flags=--64"
		BYPRODUCTS ${LEAN4_SOURCE_DIR}/bin/libLake_shared.lib
		WORKING_DIRECTORY ${LEAN4_SOURCE_DIR}/bin
		VERBATIM
		USES_TERMINAL)
				   
add_custom_target(lean4_leanshared ALL ${MSYS_INSTALL_PATH}/ucrt64${CMAKE_EXECUTABLE_SUFFIX} sh -c "gendef libleanshared.dll;dlltool -d libleanshared.def -l libleanshared.lib -D libleanshared.dll --as-flags=--64"
		BYPRODUCTS ${LEAN4_SOURCE_DIR}/bin/libleanshared.lib
		WORKING_DIRECTORY ${LEAN4_SOURCE_DIR}/bin
		VERBATIM
		USES_TERMINAL)				

add_custom_target(lean4_leanshared_1 ALL ${MSYS_INSTALL_PATH}/ucrt64${CMAKE_EXECUTABLE_SUFFIX} sh -c "gendef libleanshared_1.dll;dlltool -d libleanshared_1.def -l libleanshared_1.lib -D libleanshared_1.dll --as-flags=--64"
		BYPRODUCTS ${LEAN4_SOURCE_DIR}/bin/libleanshared_1.lib
		WORKING_DIRECTORY ${LEAN4_SOURCE_DIR}/bin
		VERBATIM
		USES_TERMINAL)	

add_custom_target(lean4_leanshared_2 ALL ${MSYS_INSTALL_PATH}/ucrt64${CMAKE_EXECUTABLE_SUFFIX} sh -c "gendef libleanshared_2.dll;dlltool -d libleanshared_2.def -l libleanshared_2.lib -D libleanshared_2.dll --as-flags=--64"
		BYPRODUCTS ${LEAN4_SOURCE_DIR}/bin/libleanshared_2.lib
		WORKING_DIRECTORY ${LEAN4_SOURCE_DIR}/bin
		VERBATIM
		USES_TERMINAL)	

add_library(Init_shared SHARED IMPORTED GLOBAL)
add_dependencies(Init_shared lean4_Init_shared)
set_target_properties( Init_shared
                       PROPERTIES
					   IMPORTED_LOCATION ${LEAN4_SOURCE_DIR}/bin/libInit_shared.dll
					   IMPORTED_IMPLIB ${LEAN4_SOURCE_DIR}/bin/libInit_shared.lib
					   INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${LEAN4_SOURCE_DIR}/include>
					 )

add_library(Lake_shared SHARED IMPORTED GLOBAL)
add_dependencies(Lake_shared lean4_Lake_shared)
set_target_properties( Lake_shared
                       PROPERTIES
					   IMPORTED_LOCATION ${LEAN4_SOURCE_DIR}/bin/libLake_shared.dll
					   IMPORTED_IMPLIB ${LEAN4_SOURCE_DIR}/bin/libLake_shared.lib
					   INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${LEAN4_SOURCE_DIR}/include>
					 )

add_library(leanshared SHARED IMPORTED GLOBAL)
add_dependencies(leanshared lean4_leanshared)
set_target_properties( leanshared
                       PROPERTIES
					   IMPORTED_LOCATION ${LEAN4_SOURCE_DIR}/bin/libleanshared.dll
					   IMPORTED_IMPLIB ${LEAN4_SOURCE_DIR}/bin/libleanshared.lib
					   INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${LEAN4_SOURCE_DIR}/include>
					 )
					 
add_library(leanshared_1 SHARED IMPORTED GLOBAL)
add_dependencies(leanshared_1 lean4_leanshared_1)
set_target_properties( leanshared_1
                       PROPERTIES
					   IMPORTED_LOCATION ${LEAN4_SOURCE_DIR}/bin/libleanshared_1.dll
					   IMPORTED_IMPLIB ${LEAN4_SOURCE_DIR}/bin/libleanshared_1.lib
					   INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${LEAN4_SOURCE_DIR}/include>
					 )
					 				 
add_library(leanshared_2 SHARED IMPORTED GLOBAL)
add_dependencies(leanshared_2 lean4_leanshared_2)
set_target_properties( leanshared_2
                       PROPERTIES
					   IMPORTED_LOCATION ${LEAN4_SOURCE_DIR}/bin/libleanshared_2.dll
					   IMPORTED_IMPLIB ${LEAN4_SOURCE_DIR}/bin/libleanshared_2.lib
					   INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${LEAN4_SOURCE_DIR}/include>
					 )

add_library(libcpp SHARED IMPORTED GLOBAL)
set_target_properties( libcpp
                       PROPERTIES
					   IMPORTED_LOCATION ${LEAN4_SOURCE_DIR}/bin/libc++.dll
					 )
					 
add_library(clang_cpp SHARED IMPORTED GLOBAL)
set_target_properties( clang_cpp
                       PROPERTIES
					   IMPORTED_LOCATION ${LEAN4_SOURCE_DIR}/bin/libclang-cpp.dll
					 )

add_library(LLVM_dll SHARED IMPORTED GLOBAL)
set_target_properties( LLVM_dll
                       PROPERTIES
					   IMPORTED_LOCATION ${LEAN4_SOURCE_DIR}/bin/libLLVM-19.dll
					 )
				 
# Invoke the build for native code shared with the other target platforms.
# This can be changed to accommodate different builds.
add_subdirectory("${UNNU_COG_SRC_DIR}" "${CMAKE_CURRENT_BINARY_DIR}/shared")


# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(unnu_ce_bundled_libraries
  # Defined in ../src/CMakeLists.txt.
  # This can be changed to accommodate different builds.
  $<TARGET_FILE:unnu_ce>
  $<TARGET_FILE:ort>
  $<TARGET_FILE:onnxruntime_providers_shared>
  $<TARGET_FILE:ort-genai>
  $<TARGET_FILE:slmengine>
  $<TARGET_FILE:tcl86t>
  $<TARGET_FILE:gzip>
  $<TARGET_FILE:Init_shared>
  $<TARGET_FILE:Lake_shared>
  $<TARGET_FILE:leanshared>
  $<TARGET_FILE:leanshared_1>
  $<TARGET_FILE:leanshared_2>
  $<TARGET_FILE:libcpp>
  $<TARGET_FILE:clang_cpp>
  $<TARGET_FILE:LLVM_dll>
  $<TARGET_FILE:uv>
  $<TARGET_FILE:zlib>
  $<TARGET_FILE:TclSoarLib>
  $<TARGET_FILE:sqlite3-shared>
  $<TARGET_FILE:soar_lib>
  PARENT_SCOPE
)
