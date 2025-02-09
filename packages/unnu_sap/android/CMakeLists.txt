# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "unnu_sap")
project(${PROJECT_NAME} LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT DEFINED CMAKE_INSTALL_PREFIX)
	set(CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_BINARY_DIR}" CACHE PATH "Needed to avoid cmake_install.cmake build issues." FORCE) 
endif()

set(CMAKE_BUILD_RPATH_USE_ORIGIN TRUE)
set(UNNU_SAP_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../src)

if (UNIX AND NOT WIN32 AND NOT APPLE)
	if (CMAKE_SIZEOF_VOID_P MATCHES "8")
		set (LIB_POSTFIX "64" CACHE STRING "suffix for 32/64 dir placement")
		mark_as_advanced (LIB_POSTFIX)
	endif ()
endif ()

if (NOT DEFINED LIB_POSTFIX)
  set (LIB_POSTFIX "")
endif ()

# Set CMake flags
add_compile_options(-DBUILD_COMMIT=unknown -DBUILD_COMPILER=unknown -DBUILD_TARGET=Android -fvisibility=default -mbranch-protection=standard)
add_link_options("LINKER:--hash-style=gnu,--build-id=none")

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
	message("Adding DEBUG compile option")
	add_compile_options(-DDEBUG -D_DEBUG)
endif()

set(BUILD_SHARED_LIBS ON)
find_package(ZLIB REQUIRED)
find_package(OpenMP)

################ log needed to build android shared objects
link_libraries(log)


################## cpuinfo settings ###############################
set(CPUINFO_LOG_LEVEL "none" CACHE STRING "Minimum logging level (info with lower severity will be ignored)" FORCE)
set(CPUINFO_LOG_TO_STDIO OFF CACHE BOOL "Log errors, warnings, and information to stdout/stderr" FORCE)
set(CPUINFO_LIBRARY_TYPE "static" CACHE STRING "Type of cpuinfo library (shared, static, or default) to build" FORCE)
set(CPUINFO_BUILD_TOOLS OFF CACHE BOOL "Build command-line tools" FORCE)
set(CPUINFO_BUILD_UNIT_TESTS OFF CACHE BOOL "Build cpuinfo unit tests" FORCE)
set(CPUINFO_BUILD_MOCK_TESTS OFF CACHE BOOL "Build cpuinfo mock tests" FORCE)
set(CPUINFO_BUILD_BENCHMARKS OFF CACHE BOOL "Build cpuinfo micro-benchmarks" FORCE)
set(CPUINFO_BUILD_PKG_CONFIG OFF CACHE BOOL "Build pkg-config manifest" FORCE)

add_subdirectory("${UNNU_SAP_SRC_DIR}/cpuinfo" "${CMAKE_CURRENT_BINARY_DIR}/cpuinfo" EXCLUDE_FROM_ALL)
include_directories("${UNNU_SAP_SRC_DIR}/cpuinfo/include")

set_target_properties(cpuinfo PROPERTIES
  BUILD_WITH_INSTALL_RPATH TRUE
  PUBLIC_HEADER cpuinfo.h
  OUTPUT_NAME "cpuinfo"
  POSITION_INDEPENDENT_CODE True
)

###################### fxdiv
set(FXDIV_USE_INLINE_ASSEMBLY OFF CACHE BOOL "Allow use of inline assembly in FXdiv" FORCE)
set(FXDIV_BUILD_TESTS OFF CACHE BOOL "Build FXdiv unit tests" FORCE)
set(FXDIV_BUILD_BENCHMARKS OFF CACHE BOOL "Build FXdiv micro-benchmarks" FORCE)

###################### pthreadpool
set(PTHREADPOOL_LIBRARY_TYPE "static" CACHE STRING "Type of library (shared, static, or default) to build" FORCE)
set(PTHREADPOOL_BUILD_TESTS OFF CACHE BOOL "Build pthreadpool unit tests" FORCE)
set(PTHREADPOOL_BUILD_BENCHMARKS OFF CACHE BOOL "Build pthreadpool micro-benchmarks" FORCE)
set(PTHREADPOOL_ALLOW_DEPRECATED_API OFF CACHE BOOL "Enable deprecated API functions" FORCE)
add_subdirectory("${UNNU_SAP_SRC_DIR}/pthreadpool" "${CMAKE_CURRENT_BINARY_DIR}/pthreadpool" EXCLUDE_FROM_ALL)

set_target_properties(pthreadpool PROPERTIES
  BUILD_WITH_INSTALL_RPATH TRUE
  PUBLIC_HEADER pthreadpool.h
  OUTPUT_NAME "pthreadpool"
  POSITION_INDEPENDENT_CODE True
)

##########################  kleidiai
set(KLEIDIAI_BUILD_TESTS       OFF CACHE BOOL "Build unit tests."             FORCE)
set(KLEIDIAI_BUILD_BENCHMARK   OFF CACHE BOOL "Build the benchmark tool."     FORCE)
set(KLEIDIAI_ENABLE_CLANG_TIDY OFF CACHE BOOL "Build with Clang-Tidy checks." FORCE)
add_subdirectory("${UNNU_SAP_SRC_DIR}/kleidiai" "${CMAKE_CURRENT_BINARY_DIR}/kleidiai" EXCLUDE_FROM_ALL)

##########################  xnnpack
set(XNNPACK_ENABLE_ASSEMBLY ON CACHE BOOL "Build XNNPACK with assembly micro-kernels" FORCE)
set(XNNPACK_ENABLE_MEMOPT ON CACHE BOOL "Build XNNPACK with optimized memory allocation scheme" FORCE)
set(XNNPACK_ENABLE_SPARSE ON CACHE BOOL "Build XNNPACK with graph rewriting for sparse inference" FORCE)
set(XNNPACK_BUILD_LIBRARY ON CACHE BOOL "Build XNNPACK library" FORCE)
set(XNNPACK_BUILD_TESTS OFF CACHE BOOL "Build XNNPACK unit tests" FORCE)
set(XNNPACK_BUILD_ALL_MICROKERNELS ON CACHE BOOL "Builds all XNNPACK Microkernels" FORCE)
set(XNNPACK_BUILD_BENCHMARKS OFF CACHE BOOL "Build XNNPACK benchmarks" FORCE)
set(XNNPACK_BUILD_WITH_LIBM ON CACHE BOOL "Build XNNPACK with libm, can turn off on Windows to avoid mutiple math functions issue." FORCE)
set(XNNPACK_USE_SYSTEM_LIBS ON CACHE BOOL "Use system-provided dependency libraries" FORCE)
set(XNNPACK_ENABLE_KLEIDIAI ON CACHE BOOL "Use KleidiAI GEMM microkernels for Arm" FORCE)

add_subdirectory("${UNNU_SAP_SRC_DIR}/XNNPACK" "${CMAKE_CURRENT_BINARY_DIR}/XNNPACK" EXCLUDE_FROM_ALL)
add_dependencies(XNNPACK kleidiai cpuinfo pthreadpool)

############################### onnxruntime 
if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
  set(COPYCMD copy)
  set(XCOPYCMD xcopy)
  set(XCOPYCMDFLAGS /S /Y)
  set(COPYCMDFLAGS /Y)
elseif(CMAKE_HOST_UNIX)
  set(COPYCMD cp)
  set(XCOPYCMD cp)
  set(COPYCMDFLAGS -f)
  set(XCOPYCMDFLAGS -rf)
  set(MKDIRFLAGS -p)
endif()

if(CMAKE_GENERATOR_PLATFORM MATCHES "^arm64")
set(ORT_PLATFORM "arm64")
else()
set(ORT_PLATFORM "x64")
endif()

file(TO_NATIVE_PATH "${UNNU_SAP_SRC_DIR}/ort" ORTBUILD_WORKING_DIR)
file(TO_NATIVE_PATH "${UNNU_SAP_SRC_DIR}/ort/tools/ci_build/build.py" ORTBUILD_BUILD_PY)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/ort/build" ORTBUILD_DIR)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/ort/build/$<CONFIG>" ORTBUILD_BINARY_DIR)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/ort/jni/include" ORTBUILD_INC_DIR)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/ort/jni/lib" ORTBUILD_LIB_DIR)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/ort/jni" ORTBUILD_HOME)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/ort/jni/bin" ORTHOME_BIN_DIR)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/ort/jni/lib" ORTHOME_LIB_DIR)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/ort/jni/include/onnxruntime" ORTHOME_HEADERS_DIR)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/ort/jni/lib/libonnxruntime.so" ORTBUILD_BINARY)

set(ORT_HOME "${CMAKE_CURRENT_BINARY_DIR}/ort/jni")
set(ORT_LIB_DIR "${CMAKE_CURRENT_BINARY_DIR}/ort/jni/lib")
set(ORT_INC_DIR "${CMAKE_CURRENT_BINARY_DIR}/ort/jni/include")
set(ORT_HDRS_DIR "${CMAKE_CURRENT_BINARY_DIR}/ort/jni/include/onnxruntime")
set(ORTBUILD_BINPATH "${CMAKE_CURRENT_BINARY_DIR}/ort/jni/lib/libonnxruntime.so")

if(NOT EXISTS ${ORT_LIB_DIR})
 file(MAKE_DIRECTORY ${ORT_LIB_DIR})
endif()

if(NOT EXISTS ${ORT_HDRS_DIR})
 file(MAKE_DIRECTORY ${ORT_HDRS_DIR})
endif()

if(NOT DEFINED ENV{SHERPA_ONNXRUNTIME_INCLUDE_DIR})
	set(ENV{SHERPA_ONNXRUNTIME_INCLUDE_DIR} ${ORT_HDRS_DIR})
endif()
if(NOT DEFINED ENV{SHERPA_ONNXRUNTIME_LIB_DIR})
	set(ENV{SHERPA_ONNXRUNTIME_LIB_DIR} ${ORT_LIB_DIR})
endif()

if(NOT EXISTS ${ORTBUILD_BINPATH})
 file(TOUCH ${ORTBUILD_BINPATH})
endif()

set(BUILD_TESTING OFF CACHE BOOL "Enable creation of tests." FORCE)
set(EIGEN_BUILD_BLAS OFF CACHE BOOL "Toggles the building of the Eigen Blas library" FORCE)
set(EIGEN_BUILD_LAPACK OFF CACHE BOOL "Toggles the building of the included Eigen LAPACK library" FORCE)

if( EXISTS cmake-env.properties)
  file(READ cmake-env.properties data)
  foreach(line IN LISTS data)
    string(REPLACE ":=" ";" line "${line}")
    list(POP_FRONT line var)
    set(${var} ${line})
  endforeach()
endif()

if(NOT DEFINED ENV{ANDROID_SDK_ROOT})
	message("CMAKE_HOST_SYSTEM_NAME :=${CMAKE_HOST_SYSTEM_NAME}")
	if( CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows" )
		set(ENV{ANDROID_SDK_ROOT} C:/Users/sheldon/AppData/Local/Android/Sdk)
	else()
		set(ENV{ANDROID_SDK_ROOT} /home/sheldon/Android/Sdk)
	endif()
endif()

set(ANDROID_SDK_ROOT $ENV{ANDROID_SDK_ROOT})

message("ANDROID_SDK_ROOT := $ENV{ANDROID_SDK_ROOT}")

if(NOT DEFINED ENV{ANDROID_NDK_HOME})
	set(ENV{ANDROID_NDK_HOME} ${ANDROID_SDK_ROOT}/ndk/27.0.12077973)
endif()

if(NOT DEFINED ENV{NDK_ROOT})
	set(ENV{NDK_ROOT} $ENV{ANDROID_NDK_HOME})
endif()

set(NDK_ROOT $ENV{NDK_ROOT})

message("NDK_ROOT := $ENV{NDK_ROOT}")

add_custom_target(ortbuild ALL COMMAND python ${ORTBUILD_BUILD_PY}
					  --cmake_generator Ninja
					  --build_dir ${ORTBUILD_DIR} 
					  --config $<CONFIG> 
					  --skip_tests
					  --skip_onnx_tests
					  --build_shared_lib
					  --use_nnapi 
					  --use_xnnpack
					  --android 
					  --android_abi arm64-v8a 
					  --android_api 35 
					  --android_ndk_path ${NDK_ROOT}
					  --android_sdk_path ${ANDROID_SDK_ROOT}
					  --cmake_extra_defines ANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON CMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/ort/jni CMAKE_BUILD_TYPE=$<CONFIG>
				  COMMAND cd ${ORTBUILD_BINARY_DIR} && ninja install 
					  && ${COPYCMD} ${COPYCMDFLAGS} onnxruntime_config.h  ${ORTHOME_HEADERS_DIR}
				  BYPRODUCTS ${ORTBUILD_BINARY}
				  WORKING_DIRECTORY ${ORTBUILD_WORKING_DIR}
				  COMMAND_EXPAND_LISTS
				  VERBATIM
				  USES_TERMINAL)

add_library(ort SHARED IMPORTED GLOBAL)
set_target_properties(# Specifies the target library.
			ort
			# Specifies the parameter you want to define.
			PROPERTIES IMPORTED_LOCATION
			# Provides the path to the library you want to import.
			${ORTBUILD_BINPATH}
			INTERFACE_INCLUDE_DIRECTORIES ${ORT_HDRS_DIR}
			)

####################### sherpa-onnx-c-api
message("ORT_HDRS_DIR := ${ORT_HDRS_DIR}")
include_directories(${ORT_HDRS_DIR})
link_directories(${ORT_LIB_DIR} "${CMAKE_CURRENT_BINARY_DIR}/lib" ${CMAKE_CURRENT_BINARY_DIR})

set(SHERPA_ONNXRUNTIME_LIB_DIR ${ORT_LIB_DIR})
set(SHERPA_ONNXRUNTIME_INCLUDE_DIR ${ORT_HDRS_DIR})
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
  $<TARGET_FILE:ssentencepiece_core>
  $<TARGET_FILE:onnxruntime>
  $<TARGET_FILE:XNNPACK>
  $<TARGET_FILE:kleidiai>
  $<TARGET_FILE:unnu_asr>
  $<TARGET_FILE:unnu_tts>
  PARENT_SCOPE
)
