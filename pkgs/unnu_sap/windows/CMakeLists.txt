# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)
# cmake_policy(SET CMP0177 OLD)
# cmake_policy(SET CMP0169 OLD)
# Project-level configuration.
set(PROJECT_NAME "unnu_sap")
project(${PROJECT_NAME} LANGUAGES CXX C)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# For
# set VERBOSE=1
# faster compile
# set CMAKE_BUILD_PARALLEL_LEVEL=8

if(NOT DEFINED CMAKE_INSTALL_PREFIX)
 	set(CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_BINARY_DIR}" CACHE PATH "Needed to avoid cmake_install.cmake build issues." FORCE) 
endif()

set(CMAKE_BUILD_RPATH_USE_ORIGIN TRUE)
set(UNNU_SAP_SRC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../src")

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
endif()

include(FetchContent)
include(ExternalProject)

find_package(Python COMPONENTS Interpreter REQUIRED)

#################### MSVC vcvars
FetchContent_Declare(
  findvcvars
  GIT_REPOSITORY 		 https://github.com/scikit-build/cmake-FindVcvars.git
  GIT_TAG        		 origin/master
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL
)

FetchContent_Populate(findvcvars)

file(REAL_PATH ${findvcvars_SOURCE_DIR} FINDVCVARS_SOURCE_DIR)

list(INSERT CMAKE_MODULE_PATH 0 ${FINDVCVARS_SOURCE_DIR})

set(cmd_wrapper)
if(MSVC)
  set(Vcvars_MSVC_ARCH 64)
  set(Vcvars_FIND_VCVARSALL TRUE)
  find_package(Vcvars REQUIRED)
  set(cmd_wrapper ${Vcvars_LAUNCHER})
endif()

####################### mglibs
FetchContent_Declare(
  mglibs
  GIT_REPOSITORY			https://github.com/mattiasgustavsson/libs.git
  GIT_TAG					origin/main
  GIT_SHALLOW				TRUE
  GIT_SUBMODULES_RECURSE	TRUE
  
  EXCLUDE_FROM_ALL
  
  OVERRIDE_FIND_PACKAGE
)

FetchContent_Populate(mglibs)

file(REAL_PATH ${mglibs_SOURCE_DIR} MGLIBS_SOURCE_DIR)
file(REAL_PATH ${mglibs_BINARY_DIR} MGLIBS_BINARY_DIR)

set(MGLIGS_INCLUDE_DIR "${MGLIBS_BINARY_DIR}/include" CACHE PATH "MB INCLUDE Directory" FORCE)
if(NOT EXISTS "${MGLIGS_INCLUDE_DIR}/mglibs")
 file(MAKE_DIRECTORY "${MGLIGS_INCLUDE_DIR}/mglibs")
endif()

file(GLOB mglibs_headers LIST_DIRECTORIES false RELATIVE "${MGLIBS_SOURCE_DIR}" "${MGLIBS_SOURCE_DIR}/*.h" )
add_custom_target(mglibs_xcopy ALL ${CMAKE_COMMAND} -E copy -t "${MGLIGS_INCLUDE_DIR}/mglibs"  ${mglibs_headers}
				WORKING_DIRECTORY ${MGLIBS_SOURCE_DIR}
				COMMENT "Copying mgligs to include ..."
				COMMAND_EXPAND_LISTS
				VERBATIM
				USES_TERMINAL)
if(NOT TARGET mattiasgustavsson::libs)
	add_library(mattiasgustavsson::libs INTERFACE IMPORTED)
	add_dependencies(mattiasgustavsson::libs mglibs_xcopy)
    set_target_properties(mattiasgustavsson::libs PROPERTIES
						  INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${MGLIGS_INCLUDE_DIR}>
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						 )
endif()

  # CONFIGURE_COMMAND			${Python_EXECUTABLE} <SOURCE_DIR>/tools/ci_build/build.py
											 # --update
											 # --cmake_generator "Visual Studio 17 2022"
											 # --build_dir <SOURCE_DIR>
											 # --config $<CONFIG>
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
											 # --cmake_extra_defines CMAKE_INSTALL_PREFIX=<INSTALL_DIR>

###################### onnxruntime
# ExternalProject_Add(
  # ort_project
  # GIT_REPOSITORY			https://github.com/sheldonrobinson/onnxruntime.git
  # GIT_TAG					origin/main
  # GIT_SHALLOW				TRUE
  # GIT_SUBMODULES_RECURSE	TRUE
  # BUILD_IN_SOURCE			ON
  # CONFIGURE_COMMAND			""
  # BUILD_COMMAND				${Python_EXECUTABLE} <SOURCE_DIR>/tools/ci_build/build.py
									 # --cmake_generator "Visual Studio 17 2022"
									 # --build_dir <SOURCE_DIR>
									 # --config $<CONFIG>
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
									 # --cmake_extra_defines CMAKE_INSTALL_PREFIX=<INSTALL_DIR>
  # INSTALL_COMMAND			${cmd_wrapper} msbuild <SOURCE_DIR>/$<CONFIG>/INSTALL.vcxproj /p:Configuration=$<CONFIG>
  # STEP_TARGETS build install
  # USES_TERMINAL_CONFIGURE	TRUE
  # USES_TERMINAL_BUILD 		TRUE
  # USES_TERMINAL_INSTALL 	TRUE
# )


# ExternalProject_Get_property(ort_project INSTALL_DIR)
# set(ONNXRUNTIME_ROOT_DIR ${INSTALL_DIR} CACHE PATH "onnxruntime root dir" FORCE)
# set(ORT_HOME ${ONNXRUNTIME_ROOT_DIR})
# set(ORT_LIB_DIR "${ORT_HOME}/lib")
# set(ORT_BIN_DIR "${ORT_HOME}/bin")
# set(ORT_INC_DIR "${ORT_HOME}/include")
# set(ORT_HDRS_DIR "${ORT_HOME}/include/onnxruntime")

# if(NOT EXISTS ${ORT_HDRS_DIR})
 # file(MAKE_DIRECTORY ${ORT_HDRS_DIR})
# endif()

# set(ORT_BUILD_BINPATH "${ORT_HOME}/bin/onnxruntime.dll")
# set(ORT_BUILD_PROVIDERS_BINPATH "${ORT_HOME}/bin/onnxruntime_providers_shared.dll")
# set(ORT_BUILD_IMPORTLIBPATH "${ORT_HOME}/lib/onnxruntime.lib")
# set(ORT_BUILD_PROVIDERS_IMPORTLIBPATH "${ORT_HOME}/lib/onnxruntime_providers_shared.lib")

#### Using FetchContent

FetchContent_Declare(
  ort_project
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/onnxruntime.git
  GIT_TAG        		 origin/main
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE

  EXCLUDE_FROM_ALL
)

FetchContent_Populate(ort_project)

file(REAL_PATH ${ort_project_SOURCE_DIR} ORT_SOURCE_DIR)
file(REAL_PATH ${ort_project_BINARY_DIR} ORT_BINARY_DIR)

file(TO_NATIVE_PATH ${ORT_SOURCE_DIR} ORT_BUILD_SRC_DIR)
file(TO_NATIVE_PATH "tools/ci_build/build.py" ORT_BUILD_PY)
file(TO_NATIVE_PATH ${ORT_BINARY_DIR} ORT_BUILD_BINARY_DIR)

set(ORT_BUILD_PROJECT_DIR "${ORT_SOURCE_DIR}/Release")
set(ORT_SLN_FILE "${ORT_SOURCE_DIR}/Release/onnxruntime.sln")

set(ORT_HOME ${ORT_BINARY_DIR})
set(ORT_BUILD_DIR ${ORT_SOURCE_DIR}/$<CONFIG>)

set(ORT_LIB_DIR "${ORT_HOME}/lib")
set(ORT_BIN_DIR "${ORT_HOME}/bin")
set(ORT_INC_DIR "${ORT_HOME}/include")
set(ORT_HDRS_DIR "${ORT_HOME}/include/onnxruntime")

if(NOT EXISTS ${ORT_HDRS_DIR})
 file(MAKE_DIRECTORY ${ORT_HDRS_DIR})
endif()

set(ORT_OUTPUT_BINPATH "${ORT_BUILD_SRC_DIR}/Release/Release/onnxruntime.dll")
set(ORT_OUTPUT_PROVIDERS_BINPATH "${ORT_BUILD_SRC_DIR}/Release/Release/onnxruntime_providers_shared.dll")
set(ORT_OUTPUT_IMPORTLIBPATH "${ORT_BUILD_SRC_DIR}/Release/Release/onnxruntime.lib")
set(ORT_OUTPUT_PROVIDERS_IMPORTLIBPATH "${ORT_BUILD_SRC_DIR}/Release/Release/onnxruntime_providers_shared.lib")

set(ORT_BUILD_BINPATH "${ORT_HOME}/bin/onnxruntime.dll")
set(ORT_BUILD_PROVIDERS_BINPATH "${ORT_HOME}/bin/onnxruntime_providers_shared.dll")
set(ORT_BUILD_IMPORTLIBPATH "${ORT_HOME}/lib/onnxruntime.lib")
set(ORT_BUILD_PROVIDERS_IMPORTLIBPATH "${ORT_HOME}/lib/onnxruntime_providers_shared.lib")

add_custom_command(OUTPUT ${ORT_OUTPUT_BINPATH}
						  ${ORT_OUTPUT_PROVIDERS_BINPATH}
						  ${ORT_OUTPUT_IMPORTLIBPATH}
						  ${ORT_OUTPUT_PROVIDERS_IMPORTLIBPATH}
				   COMMAND ${Python_EXECUTABLE} ${ORT_BUILD_PY} 
											 --cmake_generator "Visual Studio 17 2022" 
											 --build_dir ${ORT_BUILD_SRC_DIR}
											 --config Release
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
											 --cmake_extra_defines CMAKE_INSTALL_PREFIX=${ORT_BUILD_BINARY_DIR}
				   WORKING_DIRECTORY ${ORT_BUILD_SRC_DIR}
				   COMMAND_EXPAND_LISTS
				   USES_TERMINAL
				   VERBATIM)
	
add_custom_target(ort_install ALL ${cmd_wrapper} msbuild Install.vcxproj -property:Configuration=Release
				DEPENDS ${ORT_OUTPUT_BINPATH}
						${ORT_OUTPUT_PROVIDERS_BINPATH}
						${ORT_OUTPUT_IMPORTLIBPATH}
						${ORT_OUTPUT_PROVIDERS_IMPORTLIBPATH}
				BYPRODUCTS  ${ORT_BUILD_BINPATH}
							${ORT_BUILD_PROVIDERS_BINPATH}
							${ORT_BUILD_IMPORTLIBPATH}
							${ORT_BUILD_PROVIDERS_IMPORTLIBPATH}
				WORKING_DIRECTORY ${ORT_BUILD_PROJECT_DIR}
				COMMENT "Running generated ort install batch script..."
				COMMAND_EXPAND_LISTS
				VERBATIM
				USES_TERMINAL)

if(NOT TARGET ort)
	add_library(ort SHARED IMPORTED GLOBAL)
	add_dependencies(ort ort_install)
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
set(location_onnxruntime_header_dir ${ORT_HDRS_DIR} CACHE PATH "onnxruntime include directory" FORCE)
set(location_onnxruntime_lib ${ORT_BUILD_BINPATH} CACHE FILEPATH "onnxruntime.dll file path" FORCE)
set(location_onnxruntime_lib2 ${ORT_BUILD_IMPORTLIBPATH} CACHE FILEPATH "onnxruntime.lib file path" FORCE)
include_directories(${ORT_HOME}/include ${ORT_HOME}/include/onnxruntime)

####################### libpiper
FetchContent_Declare(
  piper
  GIT_REPOSITORY			https://github.com/sheldonrobinson/piper1-gpl.git
  GIT_TAG					origin/main
  GIT_SHALLOW				TRUE
  GIT_SUBMODULES_RECURSE	TRUE
  
  SOURCE_SUBDIR				libpiper
  
  EXCLUDE_FROM_ALL
  
  OVERRIDE_FIND_PACKAGE
)



################## nlohmann
FetchContent_Declare(
  nlohmann_json
  GIT_REPOSITORY 		 https://github.com/nlohmann/json.git
  GIT_TAG        		 v3.12.0
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
		 
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

####################### soundtouch
FetchContent_Declare(
  soundtouch
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/soundtouch.git
  GIT_TAG        		 origin/master
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
 
  EXCLUDE_FROM_ALL
			 
  OVERRIDE_FIND_PACKAGE

)

set(OPENMP ON CACHE BOOL "Use parallel multicore calculation through OpenMP" FORCE)
set(SOUNDSTRETCH OFF CACHE BOOL "Build soundstretch command line utility." FORCE)
set(SOUNDTOUCH_DLL ON CACHE BOOL "Build SoundTouchDLL C wrapper library" FORCE)
set(BUILD_SHARED_LIBS ON CACHE BOOL "Build SoundTouch as shared library" FORCE)

FetchContent_MakeAvailable(soundtouch)

file(REAL_PATH ${soundtouch_SOURCE_DIR} SOUNDTOUCH_SOURCE_DIR)
file(REAL_PATH ${soundtouch_BINARY_DIR} SOUNDTOUCH_BINARY_DIR)

set(SOUNDTOUCH_INCLUDE_DIR "${SOUNDTOUCH_SOURCE_DIR}/include" CACHE PATH "soundtouch include dir" FORCE)
set(SOUNDTOUCHDLL_INCLUDE_DIR "${SOUNDTOUCH_SOURCE_DIR}/source/SoundTouchDLL" CACHE PATH "soundtouch include dir" FORCE)

if(NOT TARGET SoundTouch::SoundTouch)
	add_library(SoundTouch::SoundTouch SHARED IMPORTED GLOBAL)
    set_target_properties(SoundTouch::SoundTouch PROPERTIES
                          INTERFACE_LINK_LIBRARIES
						  SoundTouch
						  INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${SOUNDTOUCH_INCLUDE_DIR}>
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						 )
endif()

if(NOT TARGET SoundTouch::SoundTouchDLL)
	add_library(SoundTouch::SoundTouchDLL SHARED IMPORTED GLOBAL)
    set_target_properties(SoundTouch::SoundTouchDLL PROPERTIES
                          INTERFACE_LINK_LIBRARIES
						  SoundTouchDLL
						  INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${SOUNDTOUCHDLL_INCLUDE_DIR}>
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						 )
endif()

include_directories(${SOUNDTOUCH_INCLUDE_DIR} ${SOUNDTOUCHDLL_INCLUDE_DIR} ${ORT_HDRS_DIR})

################# kroko-onnx
FetchContent_Declare(
  sherpa
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/kroko-onnx.git
  GIT_TAG        		 origin/sherpa-onnx
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL
  
  OVERRIDE_FIND_PACKAGE
)

################## kissfft
ExternalProject_Add(
  kissfft_project
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/kissfft.git
  GIT_TAG        		 origin/master
  GIT_SHALLOW 		 	 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  CMAKE_ARGS		-DKISSFFT_OPENMP=ON
					-DKISSFFT_PKGCONFIG=ON
					-DKISSFFT_STATICL=OFF
					-DKISSFFT_TEST=OFF
					-DKISSFFT_TOOLS=OFF
					-DKISSFFT_USE_ALLOCA=OFF
					-DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
  
  BUILD_COMMAND				${cmd_wrapper} msbuild kissfft.sln /p:Configuration=$<CONFIG>
  INSTALL_COMMAND			${cmd_wrapper} msbuild INSTALL.vcxproj /p:Configuration=$<CONFIG>
  STEP_TARGETS download configure build install
  USES_TERMINAL_BUILD 		TRUE
  USES_TERMINAL_INSTALL 	TRUE
)

ExternalProject_Get_property(kissfft_project INSTALL_DIR)
set(KISSFFT_ROOT_DIR ${INSTALL_DIR} CACHE PATH "kissfft dir" FORCE)

set(KISSFFT_BINPATH "${KISSFFT_ROOT_DIR}/bin/kissfft-float-openmp.dll")
set(KISSFFT_IMPORTLIBPATH "${KISSFFT_ROOT_DIR}/lib/kissfft-float-openmp.lib")

set(KISSFFT_INCLUDE_DIR "${KISSFFT_ROOT_DIR}/include" CACHE PATH "kissfft include dir" FORCE)

if(NOT EXISTS ${KISSFFT_INCLUDE_DIR})
 file(MAKE_DIRECTORY ${KISSFFT_INCLUDE_DIR})
endif()

if(NOT TARGET kissfft_shared)
	add_library(kissfft_shared SHARED IMPORTED GLOBAL)
	add_dependencies(kissfft_shared kissfft_project-install)
	set_target_properties(# Specifies the target library.
						   kissfft_shared
						   PROPERTIES 
						   IMPORTED_LOCATION	${KISSFFT_BINPATH}
						   IMPORTED_IMPLIB		${KISSFFT_IMPORTLIBPATH}
						 )
	if (MSVC)
		set_target_properties(kissfft_shared PROPERTIES 
					PDB_OUTPUT_DIRECTORY $<INSTALL_INTERFACE:${KISSFFT_ROOT_DIR}/lib>
					)
	endif()
endif()

if(NOT TARGET kissfft::kissfft)
	add_library(kissfft::kissfft INTERFACE IMPORTED)
	add_dependencies(kissfft::kissfft kissfft_project-install)
    set_target_properties(kissfft::kissfft PROPERTIES
						  INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${KISSFFT_INCLUDE_DIR}>
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						 )
endif()

####################### ten_vad 
FetchContent_Declare(
  tenvad 
  GIT_REPOSITORY			https://github.com/sheldonrobinson/ten-vad.git
  GIT_TAG					origin/main
  GIT_SHALLOW				TRUE
  GIT_SUBMODULES_RECURSE	TRUE
  
  SOURCE_SUBDIR		examples_onnx
  
  EXCLUDE_FROM_ALL
  
  OVERRIDE_FIND_PACKAGE
)

FetchContent_MakeAvailable(tenvad)
add_dependencies(ten_vad ort)

file(REAL_PATH ${tenvad_SOURCE_DIR} TENVAD_SOURCE_DIR)
file(REAL_PATH ${tenvad_BINARY_DIR} TENVAD_BINARY_DIR)

set(TENVAD_INCLUDE_DIR "${TENVAD_SOURCE_DIR}/include" CACHE PATH "tenvad INCLUDE Directory" FORCE)

if(NOT TARGET ten::libtenvad)
	add_library(ten::libtenvad INTERFACE IMPORTED)
    set_target_properties(ten::libtenvad PROPERTIES
						  INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${TENVAD_INCLUDE_DIR}>
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						 )
endif()

if(NOT TARGET ten::tenvad)
	add_library(ten::tenvad SHARED IMPORTED GLOBAL)
    set_target_properties(ten::tenvad PROPERTIES
						  INTERFACE_LINK_LIBRARIES ten_vad
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						 )
endif()



################# portaudio
set(PA_BUILD_SHARED_LIBS ON CACHE BOOL "Build dynamic library" FORCE)
set(PA_BUILD_TESTS OFF CACHE BOOL "Include test projects" FORCE)
set(PA_BUILD_EXAMPLES OFF CACHE BOOL "Include example projects" FORCE)
set(PA_WARNINGS_ARE_ERRORS OFF CACHE BOOL "Turn compiler warnings into errors" FORCE)
set(PA_ENABLE_DEBUG_OUTPUT OFF CACHE BOOL "Enable debug output for Portaudio" FORCE)
set(PA_USE_SKELETON OFF CACHE BOOL "Use skeleton host API" FORCE)
set(PA_USE_ASIO OFF CACHE BOOL "Enable support for ASIO" FORCE)
set(PA_USE_WMME ON CACHE BOOL "Enable support for WMME" FORCE)
set(PA_USE_WASAPI ON CACHE BOOL "Enable support for WASAPI" FORCE)
set(PA_USE_WDMKS ON CACHE BOOL "Enable support for WDMKS" FORCE)
set(PA_USE_WDMKS_DEVICE_INFO ON CACHE BOOL "Use WDM/KS API for device info" FORCE)

ExternalProject_Add(
  portaudio_project
  GIT_REPOSITORY			https://github.com/PortAudio/portaudio.git
  GIT_TAG					origin/master
  GIT_SHALLOW				TRUE
  GIT_SUBMODULES_RECURSE	TRUE
  CMAKE_ARGS			-DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
  CMAKE_CACHE_ARGS		-DPA_BUILD_SHARED_LIBS:BOOL=${PA_BUILD_SHARED_LIBS}
						-DPA_BUILD_TESTS:BOOL=${PA_BUILD_TESTS}
						-DPA_BUILD_EXAMPLES:BOOL=${PA_BUILD_EXAMPLES}
						-DPA_WARNINGS_ARE_ERRORS:BOOL=${PA_WARNINGS_ARE_ERRORS}
						-DPA_ENABLE_DEBUG_OUTPUT:BOOL=${PA_ENABLE_DEBUG_OUTPUT}
						-DPA_USE_SKELETON:BOOL=${PA_USE_SKELETON}
						-DPA_USE_ASIO:BOOL=${PA_USE_ASIO}
						-DPA_USE_WMME:BOOL=${PA_USE_WMME}
						-DPA_USE_WASAPI:BOOL=${PA_USE_WASAPI}
						-DPA_USE_WDMKS:BOOL=${PA_USE_WDMKS}
						-DPA_USE_WDMKS_DEVICE_INFO:BOOL=${PA_USE_WDMKS_DEVICE_INFO}  
  
  BUILD_COMMAND				${cmd_wrapper} msbuild portaudio.sln /p:Configuration=$<CONFIG>
  INSTALL_COMMAND			${cmd_wrapper} msbuild INSTALL.vcxproj /p:Configuration=$<CONFIG>
  STEP_TARGETS download configure build install
  USES_TERMINAL_BUILD 		TRUE
  USES_TERMINAL_INSTALL 	TRUE
)

ExternalProject_Get_property(portaudio_project INSTALL_DIR)
set(PORTAUDIO_ROOT_DIR ${INSTALL_DIR} CACHE PATH "portaudio dir" FORCE)

set(PORTAUDIO_BINPATH "${PORTAUDIO_ROOT_DIR}/bin/portaudio.dll")
set(PORTAUDIO_IMPORTLIBPATH "${PORTAUDIO_ROOT_DIR}/lib/portaudio.lib")
set(PORTAUDIO_INCLUDE_DIR "${PORTAUDIO_ROOT_DIR}/include" CACHE PATH "portaudio include dir" FORCE)

if(NOT EXISTS ${PORTAUDIO_INCLUDE_DIR})
 file(MAKE_DIRECTORY ${PORTAUDIO_INCLUDE_DIR})
endif()

if(NOT TARGET portaudio_shared)
	add_library(portaudio_shared SHARED IMPORTED GLOBAL)
	add_dependencies(portaudio_shared portaudio_project-install)
	set_target_properties(# Specifies the target library.
						   portaudio_shared
						   PROPERTIES 
						   IMPORTED_LOCATION	${PORTAUDIO_BINPATH}
						   IMPORTED_IMPLIB		${PORTAUDIO_IMPORTLIBPATH}
						 )
	if (MSVC)
		set_target_properties(portaudio_shared PROPERTIES 
					PDB_OUTPUT_DIRECTORY $<INSTALL_INTERFACE:${PORTAUDIO_ROOT_DIR}/lib>
					)
	endif()
endif()

if(NOT TARGET portaudio::portaudio)
	add_library(portaudio::portaudio INTERFACE IMPORTED)
	add_dependencies(portaudio::portaudio portaudio_project-install)
    set_target_properties(portaudio::portaudio PROPERTIES
						  INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${PORTAUDIO_INCLUDE_DIR}>
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						 )
endif()

################# kaldifst
set(KALDIFST_BUILD_TESTS OFF CACHE BOOL "Whether to build tests or not" FORCE)
set(KALDIFST_BUILD_PYTHON OFF CACHE BOOL "Whether to build Python" FORCE)

################# simple-sentencepiece
set(SBPE_ENABLE_TESTS OFF CACHE BOOL "Whether to build tests" FORCE)
set(SBPE_BUILD_PYTHON OFF CACHE BOOL "Whether to build Python" FORCE)

################# kaldi_decoder
set(KALDI_DECODER_ENABLE_TESTS OFF CACHE BOOL "Whether to build tests" FORCE)
set(KALDI_DECODER_BUILD_PYTHON OFF CACHE BOOL "Whether to build Python" FORCE)

set(SHERPA_ONNX_ENABLE_PYTHON OFF CACHE BOOL "Whether to build Python" FORCE)
set(SHERPA_ONNX_ENABLE_JNI OFF CACHE BOOL "Whether to build JNI internface" FORCE)
set(SHERPA_ONNX_ENABLE_GPU OFF CACHE BOOL "Enable ONNX Runtime GPU support" FORCE)
set(SHERPA_ONNX_ENABLE_DIRECTML ON CACHE BOOL "Enable ONNX Runtime DirectML support" FORCE)
set(SHERPA_ONNX_LINK_D3D OFF CACHE BOOL "Whether static ONNX runtime lib with DML" FORCE)
set(SHERPA_ONNX_ENABLE_RKNN OFF CACHE BOOL "Whether to build for RKNN NPU " FORCE)
set(SHERPA_ONNX_ENABLE_TESTS OFF CACHE BOOL "Whether to build tests" FORCE)
set(SHERPA_ONNX_ENABLE_CHECK OFF CACHE BOOL "Whether to build with assert" FORCE)
set(SHERPA_ONNX_ENABLE_PORTAUDIO OFF CACHE BOOL "Whether to build with portaudio" FORCE)
set(SHERPA_ONNX_ENABLE_C_API ON CACHE BOOL "Whether to build C API" FORCE)
set(SHERPA_ONNX_BUILD_C_API_EXAMPLES OFF CACHE BOOL "Whether to build C API EXAMPLES" FORCE)
set(SHERPA_ONNX_ENABLE_WEBSOCKET OFF CACHE BOOL "Whether to build webscoket server/client" FORCE)
set(SHERPA_ONNX_ENABLE_BINARY ON CACHE BOOL "Whether to build binaries" FORCE)
set(SHERPA_ONNX_ENABLE_TTS OFF CACHE BOOL "Whether to build TTS related code" FORCE)
set(SHERPA_ONNX_ENABLE_SPEAKER_DIARIZATION ON CACHE BOOL "Whether to build speaker diarization related code" FORCE)
set(SHERPA_ONNX_LINK_LIBSTDCPP_STATICALLY OFF CACHE BOOL "True to link libstdc++ statically. Used only when BUILD_SHARED_LIBS is OFF on Linux" FORCE)
set(SHERPA_ONNX_USE_PRE_INSTALLED_ONNXRUNTIME_IF_AVAILABLE ON CACHE BOOL "True to use pre-installed onnxruntime if available" FORCE)
set(SHERPA_ONNX_ENABLE_SANITIZER OFF CACHE BOOL "Whether to enable ubsan and asan" FORCE)

set(SHERPA_ONNXRUNTIME_LIB_DIR ${ORT_LIB_DIR} CACHE PATH "onnxruntime.lib directory" FORCE)
set(SHERPA_ONNXRUNTIME_BIN_DIR ${ORT_BIN_DIR} CACHE PATH "onnxruntime.dll directory" FORCE)
set(SHERPA_ONNXRUNTIME_INCLUDE_DIR ${ORT_HDRS_DIR} CACHE PATH "onnxruntime include directory" FORCE)

FetchContent_MakeAvailable(sherpa)
add_dependencies(sherpa-onnx-core ort)
add_dependencies(sherpa-onnx-c-api ort)

set(SHERPA_ONNX_CORE_IMPORTLIBPATH ${CMAKE_BINARY_DIR}/lib/$<CONFIG>/sherpa-onnx-core.lib)
set(SHERPA_ONNX_CAPI_BINPATH ${CMAKE_BINARY_DIR}/bin/$<CONFIG>/sherpa-onnx-c-api.dll)
set(SHERPA_ONNX_CAPI_IMPORTLIBPATH ${CMAKE_BINARY_DIR}/lib/$<CONFIG>/sherpa-onnx-c-api.lib)
set(SHERPA_ONNX_CXXAPI_BINPATH ${CMAKE_BINARY_DIR}/bin/$<CONFIG>/sherpa-onnx-cxx-api.dll)
set(SHERPA_ONNX_CXXAPI_IMPORTLIBPATH ${CMAKE_BINARY_DIR}/lib/$<CONFIG>/sherpa-onnx-cxx-api.lib)
################ piper
set(ONNXRUNTIME_DIR ${ORT_HOME} CACHE PATH "ONNXRuntime Home" FORCE)
FetchContent_MakeAvailable(piper)
add_dependencies(piper ort)

add_custom_target(espeak-ng-data-copy ALL)
add_dependencies(espeak-ng-data-copy piper)
add_custom_command(TARGET espeak-ng-data-copy POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E remove_directory
      "${CMAKE_BINARY_DIR}/runner/$<$<CONFIG:Release>:Release>$<$<CONFIG:Debug>:Debug>/espeak-ng-data"
    COMMAND ${CMAKE_COMMAND} -E make_directory
      "${CMAKE_BINARY_DIR}/runner/$<$<CONFIG:Release>:Release>$<$<CONFIG:Debug>:Debug>/espeak-ng-data"
    COMMAND ${CMAKE_COMMAND} -E copy_directory
      "${CMAKE_BINARY_DIR}/espeak_ng-install/share/espeak-ng-data"
      "${CMAKE_BINARY_DIR}/runner/$<$<CONFIG:Release>:Release>$<$<CONFIG:Debug>:Debug>/espeak-ng-data"
	COMMAND ${CMAKE_COMMAND} -E remove_directory
      "${CMAKE_BINARY_DIR}/runner/$<$<CONFIG:Release>:Release>$<$<CONFIG:Debug>:Debug>/espeak-ng-data/voices"
	COMMAND ${CMAKE_COMMAND} -E make_directory
      "${CMAKE_BINARY_DIR}/runner/$<$<CONFIG:Release>:Release>$<$<CONFIG:Debug>:Debug>/espeak-ng-data/voices"
)

# Invoke the build for native code shared with the other target platforms.
# This can be changed to accommodate different builds.
add_subdirectory("${UNNU_SAP_SRC_DIR}" "${CMAKE_CURRENT_BINARY_DIR}/shared")

# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.


set(unnu_sap_bundled_libraries
  # Defined in ../src/CMakeLists.txt.
  # This can be changed to accommodate different builds.
  $<TARGET_FILE:sherpa-onnx-c-api>
  $<TARGET_FILE:piper>
  $<TARGET_FILE:ort>
  $<TARGET_FILE:onnxruntime_providers_shared>
  $<TARGET_FILE:kissfft_shared>
  $<TARGET_FILE:SoundTouch>
  $<TARGET_FILE:SoundTouchDLL>
  $<TARGET_FILE:portaudio_shared>
  $<TARGET_FILE:unnu_sap>
  PARENT_SCOPE
)
