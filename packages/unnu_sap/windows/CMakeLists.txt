# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)
# cmake_policy(SET CMP0177 OLD)
# cmake_policy(SET CMP0169 OLD)
# Project-level configuration.
set(PROJECT_NAME "unnu_sap")
project(${PROJECT_NAME} LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT DEFINED CMAKE_INSTALL_PREFIX)
	set(CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_BINARY_DIR}" CACHE PATH "Needed to avoid cmake_install.cmake build issues." FORCE) 
	if(NOT DEFINED CMAKE_INSTALL_BINDIR)
		set(CMAKE_INSTALL_BINDIR ${CMAKE_BINARY_DIR}/runner/$<CONFIG>)
	endif()
endif()

set(CMAKE_BUILD_RPATH_USE_ORIGIN TRUE)
set(UNNU_SAP_SRC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../src")

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


####################### zlib
set(ZLIB_BUILD_TESTING OFF CACHE BOOL "Enable Zlib Examples as tests" FORCE)
set(ZLIB_BUILD_SHARED OFF CACHE BOOL "Enable building zlib shared library" FORCE)
set(ZLIB_BUILD_STATIC ON CACHE BOOL "Enable building zlib static library" FORCE)
set(ZLIB_BUILD_MINIZIP OFF CACHE BOOL "Enable building libminizip contrib library" FORCE)
set(ZLIB_INSTALL ON CACHE BOOL "Enable installation of zlib" FORCE)
set(ZLIB_BUILD_EXAMPLES OFF CACHE BOOL "Enable Zlib Examples" FORCE)
add_subdirectory("${UNNU_SAP_SRC_DIR}/zlib" "${CMAKE_CURRENT_BINARY_DIR}/zlib" EXCLUDE_FROM_ALL)

set(ZLIB_INCLUDE_DIR "${UNNU_SAP_SRC_DIR}/zlib" PARENT_SCOPE)
set(ZLIB_LIBRARY "${CMAKE_CURRENT_BINARY_DIR}/zlib/$<CONFIG>/zs$<$<CONFIG:Debug>:d>.lib" PARENT_SCOPE)
set(ZLIB_FOUND TRUE PARENT_SCOPE)
include_directories("${CMAKE_CURRENT_BINARY_DIR}/zlib" "${UNNU_SAP_SRC_DIR}/zlib")
link_directories(${CMAKE_CURRENT_BINARY_DIR}/zlib/$<CONFIG>)
# include_directories("${CMAKE_CURRENT_BINARY_DIR}/zlib" "${UNNU_SAP_SRC_DIR}/zlib")
# get_target_property(ZLIB_INCLUDE_DIR zlibstatic HEADER_DIRS)
# get_target_property(ZLIB_LIBRARY zlibstatic IMPORTED_LOCATION)

set(BUILD_TESTING OFF CACHE BOOL "Enable creation of tests." FORCE)
set(EIGEN_BUILD_BLAS OFF CACHE BOOL "Toggles the building of the Eigen Blas library" FORCE)
set(EIGEN_BUILD_LAPACK OFF CACHE BOOL "Toggles the building of the included Eigen LAPACK library" FORCE)

if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
  set(COPYCMD copy)
  set(XCOPYCMD xcopy)
  set(XCOPYCMDFLAGS /S /Y)
  set(COPYCMDFLAGS /Y)
elseif(CMAKE_HOST_UNIX)
  set(COPYCMD cp)
  set(COPYCMDFLAGS -r)
  set(MKDIRFLAGS -p)
endif()

if(CMAKE_GENERATOR_PLATFORM MATCHES "^arm64")
set(ORT_PLATFORM "arm64")
else()
set(ORT_PLATFORM "x64")
endif()

if(NOT CMAKE_BUILD_TYPE)
  message(STATUS "No CMAKE_BUILD_TYPE given, default to Release")
  set(CMAKE_BUILD_TYPE Release)
endif()

set(BUILD_SHARED_LIBS ON)

file(TO_NATIVE_PATH "${UNNU_SAP_SRC_DIR}/ort" ORTBUILD_WORKING_DIR)
file(TO_NATIVE_PATH "${UNNU_SAP_SRC_DIR}/ort/tools/ci_build/build.py" ORTBUILD_BUILD_PY)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/ort/build/win-${ORT_PLATFORM}" ORTBUILD_DIR)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/ort/build/win-${ORT_PLATFORM}/$<CONFIG>" ORTBUILD_ROOT_DIR)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/ort/build/win-${ORT_PLATFORM}/$<CONFIG>/$<CONFIG>" ORTBUILD_BINARY_DIR)


file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/ort/win-${ORT_PLATFORM}/include" ORTBUILD_INC_DIR)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/ort/win-${ORT_PLATFORM}/bin" ORTBUILD_BIN_DIR)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/ort/win-${ORT_PLATFORM}/lib" ORTBUILD_LIB_DIR)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/ort/win-${ORT_PLATFORM}/bin/onnxruntime.dll" ORTBUILD_BINARY)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/ort/win-${ORT_PLATFORM}/bin/onnxruntime_providers_shared.dll" ORTBUILD_PROVIDERS_BINARY)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/ort/win-${ORT_PLATFORM}/lib/onnxruntime.lib" ORTBUILD_IMPORTLIB)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/ort/win-${ORT_PLATFORM}/lib/onnxruntime_providers_shared.lib" ORTBUILD_PROVIDERS_IMPORTLIB)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/ort/win-${ORT_PLATFORM}/include/onnxruntime" ORTBUILD_HEADERS)

set(ORT_HOME "${CMAKE_CURRENT_BINARY_DIR}/ort/win-${ORT_PLATFORM}")
set(ORT_LIB_DIR "${CMAKE_CURRENT_BINARY_DIR}/ort/win-${ORT_PLATFORM}/lib")
set(ORT_BIN_DIR "${CMAKE_CURRENT_BINARY_DIR}/ort/win-${ORT_PLATFORM}/bin")
set(ORT_INC_DIR "${CMAKE_CURRENT_BINARY_DIR}/ort/win-${ORT_PLATFORM}/include")
set(ORT_HDRS_DIR "${CMAKE_CURRENT_BINARY_DIR}/ort/win-${ORT_PLATFORM}/include/onnxruntime")

set(ORTBUILD_BINPATH "${CMAKE_CURRENT_BINARY_DIR}/ort/win-${ORT_PLATFORM}/bin/onnxruntime.dll")
set(ORTBUILD_PROVIDERS_BINPATH "${CMAKE_CURRENT_BINARY_DIR}/ort/win-${ORT_PLATFORM}/bin/onnxruntime_providers_shared.dll")
set(ORTBUILD_IMPORTLIBPATH "${CMAKE_CURRENT_BINARY_DIR}/ort/win-${ORT_PLATFORM}/lib/onnxruntime.lib")
set(ORTBUILD_PROVIDERS_IMPORTLIBPATH "${CMAKE_CURRENT_BINARY_DIR}/ort/win-${ORT_PLATFORM}/lib/onnxruntime_providers_shared.lib")

if(NOT DEFINED ENV{SHERPA_ONNXRUNTIME_INCLUDE_DIR})
	set(ENV{SHERPA_ONNXRUNTIME_INCLUDE_DIR} ${ORT_HDRS_DIR})
endif()
if(NOT DEFINED ENV{SHERPA_ONNXRUNTIME_LIB_DIR})
	set(ENV{SHERPA_ONNXRUNTIME_LIB_DIR} ${ORT_LIB_DIR})
endif()
if(NOT EXISTS ${ORT_HDRS_DIR})
 file(MAKE_DIRECTORY ${ORT_HDRS_DIR})
endif()
if(NOT EXISTS ${ORTBUILD_IMPORTLIBPATH})
 file(MAKE_DIRECTORY ${ORT_LIB_DIR})
 file(TOUCH ${ORTBUILD_IMPORTLIBPATH})
endif()

add_custom_target(ortbuild ALL COMMAND python ${ORTBUILD_BUILD_PY}
								  --cmake_generator "Visual Studio 17 2022"
								  --build_dir ${ORTBUILD_DIR} 
								  --config $<CONFIG>
								  --build_shared_lib
								  --use_mimalloc
								  --use_full_protobuf
								  --skip_tests
								  --skip_onnx_tests
								  --parallel 
								  --compile_no_warning_as_error 
								  --skip_submodule_sync
								  --cmake_extra_defines CMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/ort/win-${ORT_PLATFORM}
				  COMMAND cd ${ORTBUILD_ROOT_DIR} && msbuild INSTALL.vcxproj /p:Configuration=$<CONFIG> && ${COPYCMD} ${COPYCMDFLAGS} onnxruntime_config.h  ${ORTBUILD_HEADERS} 
						  && cd ${ORTBUILD_BINARY_DIR}
						  && ${XCOPYCMD} ${XCOPYCMDFLAGS} *.dll ${ORTBUILD_BIN_DIR} 
						  && ${XCOPYCMD} ${XCOPYCMDFLAGS} *.lib ${ORTBUILD_LIB_DIR}
				  BYPRODUCTS ${ORTBUILD_BINPATH}
							 ${ORTBUILD_PROVIDERS_BINPATH}
							 ${ORTBUILD_IMPORTLIBPATH}
							 ${ORTBUILD_PROVIDERS_IMPORTLIBPATH}
				  WORKING_DIRECTORY ${ORTBUILD_WORKING_DIR}
				  COMMAND_EXPAND_LISTS
				  VERBATIM
				  USES_TERMINAL)

add_dependencies(ortbuild zlibstatic)
add_library(onnxruntime_providers_shared SHARED IMPORTED GLOBAL)
set_target_properties(# Specifies the target library.
                       onnxruntime_providers_shared

                       # Specifies the parameter you want to define.
                       PROPERTIES IMPORTED_LOCATION

                       # Provides the path to the library you want to import.
                       ${ORTBUILD_PROVIDERS_BINPATH})
					   
if(MSVC)
set_target_properties(onnxruntime_providers_shared PROPERTIES IMPORTED_IMPLIB ${ORTBUILD_PROVIDERS_IMPORTLIBPATH})
endif()

add_library(ort SHARED IMPORTED GLOBAL)
set_target_properties(# Specifies the target library.
                       ort

                       # Specifies the parameter you want to define.
                       PROPERTIES IMPORTED_LOCATION
                       # Provides the path to the library you want to import.
                       ${ORTBUILD_BINPATH}
					   INTERFACE_INCLUDE_DIRECTORIES ${ORT_HDRS_DIR}
					   )

if(MSVC)
set_target_properties(ort PROPERTIES IMPORTED_IMPLIB ${ORTBUILD_IMPORTLIBPATH})
endif()
add_dependencies(ort ortbuild)
add_dependencies(onnxruntime_providers_shared ortbuild)

####################### sherpa-onnx-c-api
set(BUILD_SHARED_LIBS ON)
set(SHERPA_ONNXRUNTIME_LIB_DIR ${ORT_LIB_DIR} PARENT_SCOPE)
set(SHERPA_ONNXRUNTIME_INCLUDE_DIR ${ORT_HDRS_DIR} PARENT_SCOPE)
set(SHERPA_ONNX_ENABLE_TESTS OFF CACHE BOOL "Whether to build tests" FORCE)
set(SHERPA_ONNX_ENABLE_CHECK OFF CACHE BOOL "Whether to build with assert" FORCE)
set(SHERPA_ONNX_ENABLE_PORTAUDIO OFF CACHE BOOL "Whether to build with portaudio" FORCE)
set(SHERPA_ONNX_ENABLE_C_API ON CACHE BOOL "Whether to build C API" FORCE)
set(SHERPA_ONNX_BUILD_C_API_EXAMPLES OFF CACHE BOOL "Whether to build C API EXAMPLES" FORCE)
set(SHERPA_ONNX_ENABLE_WEBSOCKET OFF CACHE BOOL "Whether to build webscoket server/client" FORCE)
set(SHERPA_ONNX_ENABLE_BINARY ON CACHE BOOL "Whether to build binaries" FORCE)
set(SHERPA_ONNX_ENABLE_TTS ON CACHE BOOL "Whether to build TTS related code" FORCE)
set(SHERPA_ONNX_ENABLE_SPEAKER_DIARIZATION ON CACHE BOOL "Whether to build speaker diarization related code" FORCE)
set(SHERPA_ONNX_LINK_LIBSTDCPP_STATICALLY OFF CACHE BOOL "True to link libstdc++ statically. Used only when BUILD_SHARED_LIBS is OFF on Linux" FORCE)
set(SHERPA_ONNX_USE_PRE_INSTALLED_ONNXRUNTIME_IF_AVAILABLE ON CACHE BOOL "True to use pre-installed onnxruntime if available" FORCE)
set(KALDIFST_BUILD_PYTHON OFF CACHE BOOL "Whether to build Python" FORCE)
set(KALDI_DECODER_ENABLE_TESTS OFF CACHE BOOL "Whether to build tests" FORCE)
set(KALDI_DECODER_BUILD_PYTHON OFF CACHE BOOL "Whether to build Python" FORCE)

set(EIGEN_BUILD_TESTING OFF CACHE BOOL "Enable creation of Eigen tests." FORCE)
set(EIGEN_LEAVE_TEST_IN_ALL_TARGET OFF CACHE BOOL "Leaves tests in the all target, needed by ctest for automatic building." FORCE)
set(EIGEN_BUILD_BLAS ON CACHE BOOL "Toggles the building of the Eigen Blas library" FORCE)
set(EIGEN_BUILD_LAPACK ON CACHE BOOL "Toggles the building of the included Eigen LAPACK library" FORCE)
set(EIGEN_BUILD_DOC OFF CACHE BOOL "Enable creation of Eigen documentation" FORCE)
set(EIGEN_BUILD_DEMOS OFF CACHE BOOL "Toggles the building of the Eigen demos" FORCE)
set(EIGEN_BUILD_CMAKE_PACKAGE OFF CACHE BOOL "Enables the creation of EigenConfig.cmake and related files" FORCE)

set(simple-sentencepiece_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/ssentencepiece" PARENT_SCOPE)

include_directories("${UNNU_SAP_SRC_DIR}/sherpa-onnx")
add_subdirectory("${UNNU_SAP_SRC_DIR}/sherpa-onnx" "${CMAKE_CURRENT_BINARY_DIR}/sherpa" EXCLUDE_FROM_ALL)

add_dependencies(sherpa-onnx-core ssentencepiece_core ortbuild)
add_dependencies(sherpa-onnx-c-api sherpa-onnx-core ssentencepiece_core ortbuild)

# Invoke the build for native code shared with the other target platforms.
# This can be changed to accommodate different builds.
add_subdirectory("${UNNU_SAP_SRC_DIR}" "${CMAKE_CURRENT_BINARY_DIR}/shared")
add_dependencies(unnu_asr sherpa-onnx-c-api)
add_dependencies(unnu_tts sherpa-onnx-c-api)

# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.


set(unnu_sap_bundled_libraries
  # Defined in ../src/CMakeLists.txt.
  # This can be changed to accommodate different builds.
  $<TARGET_FILE:sherpa-onnx-c-api>
  $<TARGET_FILE:ort>
  $<TARGET_FILE:onnxruntime_providers_shared>
  $<TARGET_FILE:unnu_asr>
  $<TARGET_FILE:unnu_tts>
  PARENT_SCOPE
)
