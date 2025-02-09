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
	file(REAL_PATH ${CMAKE_BINARY_DIR}/runner/$<CONFIG> FLUTTER_APP_DIR)
	set(CMAKE_INSTALL_SYSTEM_RUNTIME_DESTINATION ${FLUTTER_APP_DIR})
endif()

include(FetchContent)
include(ExternalProject)
include(InstallRequiredSystemLibraries)

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

###################### onnxruntime

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

if ( (CMAKE_CXX_COMPILER_ARCHITECTURE_ID STREQUAL "ARM64") OR  (CMAKE_CXX_COMPILER_ARCHITECTURE_ID STREQUAL "arm64") )
set(ORT_PLATFORM "arm64")
else()
set(ORT_PLATFORM "x64")
endif()

FetchContent_Declare(
  msonnxruntime
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/onnxruntime.git
  GIT_TAG        		 origin/main
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE

  EXCLUDE_FROM_ALL
)

####################### eigen
set(BUILD_TESTING OFF CACHE BOOL "Enable creation of tests." FORCE)
set(EIGEN_BUILD_TESTING OFF CACHE BOOL "Enable creation of Eigen tests." FORCE)
set(EIGEN_LEAVE_TEST_IN_ALL_TARGET OFF CACHE BOOL "Leaves tests in the all target, needed by ctest for automatic building." FORCE)
set(EIGEN_BUILD_BLAS OFF CACHE BOOL "Toggles the building of the Eigen Blas library" FORCE)
set(EIGEN_BUILD_LAPACK OFF CACHE BOOL "Toggles the building of the included Eigen LAPACK library" FORCE)
set(EIGEN_BUILD_DOC OFF CACHE BOOL "Enable creation of Eigen documentation" FORCE)
set(EIGEN_BUILD_DEMOS OFF CACHE BOOL "Toggles the building of the Eigen demos" FORCE)
set(EIGEN_BUILD_CMAKE_PACKAGE OFF CACHE BOOL "Enables the creation of EigenConfig.cmake and related files" FORCE)

set(onnxruntime_BUILD_UNIT_TESTS OFF CACHE BOOL "Build ONNXRuntime unit tests" FORCE)
set(onnxruntime_BUILD_BENCHMARKS OFF CACHE BOOL "Build ONNXRuntime micro-benchmarks" FORCE)
set(onnxruntime_USE_AVX ON CACHE BOOL "Use AVX instructions" FORCE)
set(onnxruntime_USE_AVX2 ON CACHE BOOL "Use AVX2 instructions" OFF)
set(onnxruntime_BUILD_SHARED_LIB ON CACHE BOOL "Build a shared library" FORCE)
set(onnxruntime_USE_FULL_PROTOBUF ON CACHE BOOL "Link to libprotobuf instead of libprotobuf-lite when this option is ON" FORCE)
set(onnxruntime_ENABLE_DELAY_LOADING_WIN_DLLS ON CACHE BOOL "Delay load some of the dependent DLls that are part of the OS" FORCE)
set(onnxruntime_USE_DML ON CACHE BOOL "Build with DirectML support" FORCE)
set(onnxruntime_USE_MIMALLOC ON CACHE BOOL "Override new/delete and arena allocator with mimalloc" FORCE)

FetchContent_Populate(msonnxruntime)

file(REAL_PATH ${msonnxruntime_SOURCE_DIR} MSONNXRUNTIME_SOURCE_DIR)
file(REAL_PATH ${msonnxruntime_BINARY_DIR} MSONNXRUNTIME_BINARY_DIR)

file(TO_NATIVE_PATH ${MSONNXRUNTIME_SOURCE_DIR} ORT_BUILD_SRC_DIR)
file(TO_NATIVE_PATH "${MSONNXRUNTIME_SOURCE_DIR}/tools/ci_build/build.py" ORT_BUILD_PY)

file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/ort/build/win-${ORT_PLATFORM}" ORT_BUILD_DIR)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/ort/build/win-${ORT_PLATFORM}/$<CONFIG>" ORT_BUILD_ROOT_DIR)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/ort/build/win-${ORT_PLATFORM}/$<CONFIG>/$<CONFIG>" ORT_BUILD_BINARY_DIR)


file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/ort/win-${ORT_PLATFORM}/include" ORT_BUILD_INC_DIR)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/ort/win-${ORT_PLATFORM}/bin" ORT_BUILD_BIN_DIR)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/ort/win-${ORT_PLATFORM}/lib" ORT_BUILD_LIB_DIR)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/ort/win-${ORT_PLATFORM}/bin/onnxruntime.dll" ORT_BUILD_BINARY)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/ort/win-${ORT_PLATFORM}/bin/onnxruntime_providers_shared.dll" ORT_BUILD_PROVIDERS_BINARY)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/ort/win-${ORT_PLATFORM}/lib/onnxruntime.lib" ORT_BUILD_IMPORTLIB)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/ort/win-${ORT_PLATFORM}/lib/onnxruntime_providers_shared.lib" ORT_BUILD_PROVIDERS_IMPORTLIB)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/ort/win-${ORT_PLATFORM}/include/onnxruntime" ORT_BUILD_HEADERS)

set(ORT_HOME "${CMAKE_CURRENT_BINARY_DIR}/ort/win-${ORT_PLATFORM}")
set(ORT_LIB_DIR "${CMAKE_CURRENT_BINARY_DIR}/ort/win-${ORT_PLATFORM}/lib")
set(ORT_BIN_DIR "${CMAKE_CURRENT_BINARY_DIR}/ort/win-${ORT_PLATFORM}/bin")
set(ORT_INC_DIR "${CMAKE_CURRENT_BINARY_DIR}/ort/win-${ORT_PLATFORM}/include")
set(ORT_HDRS_DIR "${CMAKE_CURRENT_BINARY_DIR}/ort/win-${ORT_PLATFORM}/include/onnxruntime")

set(ORT_BUILD_BINPATH "${CMAKE_CURRENT_BINARY_DIR}/ort/win-${ORT_PLATFORM}/bin/onnxruntime.dll")
set(ORT_BUILD_PROVIDERS_BINPATH "${CMAKE_CURRENT_BINARY_DIR}/ort/win-${ORT_PLATFORM}/bin/onnxruntime_providers_shared.dll")
set(ORT_BUILD_IMPORTLIBPATH "${CMAKE_CURRENT_BINARY_DIR}/ort/win-${ORT_PLATFORM}/lib/onnxruntime.lib")
set(ORT_BUILD_PROVIDERS_IMPORTLIBPATH "${CMAKE_CURRENT_BINARY_DIR}/ort/win-${ORT_PLATFORM}/lib/onnxruntime_providers_shared.lib")
set(DIRECTML_BINPATH "${CMAKE_CURRENT_BINARY_DIR}/ort/win-${ORT_PLATFORM}/bin/DirectML.dll")

if(NOT DEFINED ENV{SHERPA_ONNXRUNTIME_INCLUDE_DIR})
	set(ENV{SHERPA_ONNXRUNTIME_INCLUDE_DIR} ${ORT_HDRS_DIR})
endif()
if(NOT DEFINED ENV{SHERPA_ONNXRUNTIME_LIB_DIR})
	set(ENV{SHERPA_ONNXRUNTIME_LIB_DIR} ${ORT_LIB_DIR})
endif()
if(NOT DEFINED ENV{SHERPA_ONNXRUNTIME_BIN_DIR})
	set(ENV{SHERPA_ONNXRUNTIME_BIN_DIR} ${ORT_BIN_DIR})
endif()
if(NOT EXISTS ${ORT_HDRS_DIR})
 file(MAKE_DIRECTORY ${ORT_HDRS_DIR})
endif()
if(NOT EXISTS ${ORT_BUILD_IMPORTLIBPATH})
 file(MAKE_DIRECTORY ${ORT_LIB_DIR})
 file(TOUCH ${ORT_BUILD_IMPORTLIBPATH})
endif()
if(NOT EXISTS ${ORT_BUILD_BINPATH})
 file(MAKE_DIRECTORY ${ORT_BIN_DIR})
 file(TOUCH ${ORT_BUILD_BINPATH})
endif()

add_custom_target(ort_build ALL COMMAND python ${ORT_BUILD_PY}
								  --cmake_generator "Visual Studio 17 2022"
								  --build_dir ${ORT_BUILD_DIR} 
								  --config $<CONFIG>
								  --build_shared_lib
								  --use_mimalloc
								  --use_full_protobuf
								  --skip_tests
								  --skip_onnx_tests
								  --skip_winml_tests
								  --use_dml
								  --parallel
								  --use_binskim_compliant_compile_flags
								  --compile_no_warning_as_error 
								  --skip_submodule_sync
								  --cmake_extra_defines CMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/ort/win-${ORT_PLATFORM} CMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded$<$<CONFIG:Debug>:Debug>DLL
				  COMMAND cd ${ORT_BUILD_ROOT_DIR} && msbuild INSTALL.vcxproj /p:Configuration=$<CONFIG> && ${COPYCMD} ${COPYCMDFLAGS} onnxruntime_config.h  ${ORT_BUILD_HEADERS} 
						  && cd ${ORT_BUILD_BINARY_DIR}
						  && ${XCOPYCMD} ${XCOPYCMDFLAGS} *.dll ${ORT_BUILD_BIN_DIR} 
						  && ${XCOPYCMD} ${XCOPYCMDFLAGS} *.lib ${ORT_BUILD_BIN_DIR}
						  && ${XCOPYCMD} ${XCOPYCMDFLAGS} *.lib ${ORT_BUILD_LIB_DIR}
				  BYPRODUCTS ${ORT_BUILD_BINPATH}
							 ${ORT_BUILD_PROVIDERS_BINPATH}
							 ${ORT_BUILD_IMPORTLIBPATH}
							 ${ORT_BUILD_PROVIDERS_IMPORTLIBPATH}
				  WORKING_DIRECTORY ${ORT_BUILD_SRC_DIR}
				  COMMAND_EXPAND_LISTS
				  VERBATIM
				  USES_TERMINAL)


add_library(ort SHARED IMPORTED GLOBAL)
add_dependencies(ort ort_build)
set_target_properties(# Specifies the target library.
                       ort
                       PROPERTIES 
					   IMPORTED_LOCATION ${ORT_BUILD_BINPATH}
					   IMPORTED_IMPLIB ${ORT_BUILD_IMPORTLIBPATH}
					   INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${ORT_HDRS_DIR}>
					 )
if (MSVC)
	set_target_properties(ort PROPERTIES 
				PDB_OUTPUT_DIRECTORY $<INSTALL_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/ort/build/win-${ORT_PLATFORM}/$<CONFIG>/$<CONFIG>>
				)
endif()

add_library(onnxruntime_providers_shared SHARED IMPORTED GLOBAL)
add_dependencies(onnxruntime_providers_shared ort)
set_target_properties(# Specifies the target library.
                       onnxruntime_providers_shared
                       PROPERTIES 
					   IMPORTED_LOCATION  ${ORT_BUILD_PROVIDERS_BINPATH}
					   IMPORTED_IMPLIB ${ORT_BUILD_PROVIDERS_IMPORTLIBPATH}
					 )


####################### sherpa-onnx-c-api
FetchContent_Declare(
  sherpa-onnx
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/sherpa-onnx.git
  GIT_TAG        		 origin/master
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL
)

################# kaldifst
set(KALDIFST_BUILD_TESTS OFF CACHE BOOL "Whether to build tests or not" FORCE)
set(KALDIFST_BUILD_PYTHON OFF CACHE BOOL "Whether to build Python" FORCE)

################# simple-sentencepiece
set(SBPE_ENABLE_TESTS OFF CACHE BOOL "Whether to build tests" FORCE)
set(SBPE_BUILD_PYTHON OFF CACHE BOOL "Whether to build Python" FORCE)

################# kaldi_decoder
set(KALDI_DECODER_ENABLE_TESTS OFF CACHE BOOL "Whether to build tests" FORCE)
set(KALDI_DECODER_BUILD_PYTHON OFF CACHE BOOL "Whether to build Python" FORCE)

################# portaudio
set(PA_BUILD_SHARED_LIBS OFF CACHE BOOL "Build dynamic library" FORCE)
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

set(SHERPA_ONNX_ENABLE_PYTHON OFF CACHE BOOL "Whether to build Python" FORCE)
set(SHERPA_ONNX_ENABLE_JNI OFF CACHE BOOL "Whether to build JNI internface" FORCE)
set(SHERPA_ONNX_ENABLE_GPU OFF CACHE BOOL "Enable ONNX Runtime GPU support" FORCE)
set(SHERPA_ONNX_ENABLE_DIRECTML OFF CACHE BOOL "Enable ONNX Runtime DirectML support" FORCE)
set(SHERPA_ONNX_LINK_D3D OFF CACHE BOOL "Whether static ONNX runtime lib with DML" FORCE)
set(SHERPA_ONNX_ENABLE_RKNN OFF CACHE BOOL "Whether to build for RKNN NPU " FORCE)
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
set(SHERPA_ONNX_ENABLE_SANITIZER OFF CACHE BOOL "Whether to enable ubsan and asan" FORCE)

set(SHERPA_ONNXRUNTIME_LIB_DIR ${ORT_BIN_DIR} CACHE BOOL "onnxruntime.lib directory" FORCE)
set(SHERPA_ONNXRUNTIME_BIN_DIR ${ORT_BIN_DIR} CACHE BOOL "onnxruntime.dll directory" FORCE)
set(location_onnxruntime_lib ${ORT_BUILD_BINPATH} CACHE BOOL "onnxruntime.dll file path" FORCE)
set(location_onnxruntime_lib2 ${ORT_BUILD_IMPORTLIBPATH} CACHE BOOL "onnxruntime.lib file path" FORCE)
set(SHERPA_ONNXRUNTIME_INCLUDE_DIR ${ORT_HDRS_DIR} CACHE BOOL "onnxruntime include directory" FORCE)

# FetchContent_MakeAvailable(sherpa-onnx msonnxruntime)
# add_dependencies(sherpa-onnx-core ort_build ort)

FetchContent_Populate(sherpa-onnx)

file(REAL_PATH ${sherpa-onnx_SOURCE_DIR} SHERPA_ONNX_SOURCE_DIR)
file(REAL_PATH ${sherpa-onnx_BINARY_DIR} SHERPA_ONNX_BINARY_DIR)

set(SHERPA_ONNX_INCLUDE_DIR ${SHERPA_ONNX_SOURCE_DIR}/sherpa-onnx/csrc CACHE PATH "sherpa-onnx include dir" FORCE)
set(SHERPA_ONNX_CAPI_INCLUDE_DIR ${SHERPA_ONNX_SOURCE_DIR}/sherpa-onnx/c-api CACHE PATH "sherpa-onnx c-api include dir" FORCE)

set(SHERPA_ONNX_INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/so/ins CACHE PATH "sherpa-onnx install dir" FORCE)
set(SHERPA_ONNX_BUILD_DIR ${CMAKE_CURRENT_BINARY_DIR}/so/bld CACHE PATH "sherpa-onnx build dir" FORCE)

file(TO_NATIVE_PATH ${SHERPA_ONNX_INSTALL_DIR} SHERPA_INSTALL_DIR)
file(TO_NATIVE_PATH ${SHERPA_ONNX_BUILD_DIR} SHERPA_BUILD_DIR)
file(TO_NATIVE_PATH ${SHERPA_ONNX_BUILD_DIR}/bin/$<CONFIG> SHERPA_BUILD_BINARY_DIR)
file(TO_NATIVE_PATH ${SHERPA_ONNX_BUILD_DIR}/lib/$<CONFIG> SHERPA_BUILD_LIBRARY_DIR)
file(TO_NATIVE_PATH ${SHERPA_ONNX_INSTALL_DIR}/bin SHERPA_ONNX_BIN_DIR)
file(TO_NATIVE_PATH ${SHERPA_ONNX_INSTALL_DIR}/lib SHERPA_ONNX_LIB_DIR)
file(TO_NATIVE_PATH ${SHERPA_ONNX_INSTALL_DIR}/bin/sherpa-onnx-core.dll SHERPA_ONNX_CORE_BINARY)
file(TO_NATIVE_PATH ${SHERPA_ONNX_INSTALL_DIR}/bin/sherpa-onnx-c-api.dll SHERPA_ONNX_CAPI_BINARY)
file(TO_NATIVE_PATH ${SHERPA_ONNX_INSTALL_DIR}/bin/sherpa-onnx-cxx-api.dll SHERPA_ONNX_CXXAPI_BINARY)

file(TO_NATIVE_PATH ${SHERPA_ONNX_INSTALL_DIR}/lib/sherpa-onnx-core.lib SHERPA_ONNX_CORE_IMPORTLIB)
file(TO_NATIVE_PATH ${SHERPA_ONNX_INSTALL_DIR}/lib/sherpa-onnx-c-api.lib SHERPA_ONNX_CAPI_IMPORTLIB)
file(TO_NATIVE_PATH ${SHERPA_ONNX_INSTALL_DIR}/lib/sherpa-onnx-cxx-api.lib SHERPA_ONNX_CXXAPI_IMPORTLIB)

set(SHERPA_ONNX_CORE_BINPATH ${SHERPA_ONNX_INSTALL_DIR}/bin/sherpa-onnx-core.dll)
set(SHERPA_ONNX_CORE_IMPORTLIBPATH ${SHERPA_ONNX_INSTALL_DIR}/lib/sherpa-onnx-core.lib)
set(SHERPA_ONNX_CAPI_BINPATH ${SHERPA_ONNX_INSTALL_DIR}/bin/sherpa-onnx-c-api.dll)
set(SHERPA_ONNX_CAPI_IMPORTLIBPATH ${SHERPA_ONNX_INSTALL_DIR}/lib/sherpa-onnx-c-api.lib)
set(SHERPA_ONNX_CXXAPI_BINPATH ${SHERPA_ONNX_INSTALL_DIR}/bin/sherpa-onnx-cxx-api.dll)
set(SHERPA_ONNX_CXXAPI_IMPORTLIBPATH ${SHERPA_ONNX_INSTALL_DIR}/lib/sherpa-onnx-cxx-api.lib)

#-A x64,version=10.0.26100.0 -T v143,host=x64 
add_custom_target(sherpa_build ALL COMMAND cmake${CMAKE_EXECUTABLE_SUFFIX} 
										-B ${SHERPA_ONNX_BUILD_DIR} -G "Visual Studio 17 2022" 
										--install-prefix=${SHERPA_ONNX_INSTALL_DIR} 
										-DCMAKE_BUILD_TYPE=$<CONFIG>
										-DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded$<$<CONFIG:Debug>:Debug>DLL
										-DCMAKE_CXX_FLAGS="/DNOMINMAX" 
										-DCMAKE_C_FLAGS="/DNOMINMAX" 
										-DBUILD_SHARED_LIBS=ON 
										-DSHERPA_ONNXRUNTIME_LIB_DIR=${ORT_BIN_DIR}
										-DSHERPA_ONNXRUNTIME_BIN_DIR=${ORT_BIN_DIR}
										-DSHERPA_ONNXRUNTIME_INCLUDE_DIR=${ORT_HDRS_DIR}
										-Dlocation_onnxruntime_lib=${ORT_BUILD_BINPATH}
										-Dlocation_onnxruntime_lib2=${ORT_BUILD_IMPORTLIBPATH}
										-DSHERPA_ONNX_ENABLE_PYTHON=${SHERPA_ONNX_ENABLE_PYTHON}
										-DSHERPA_ONNX_ENABLE_JNI=${SHERPA_ONNX_ENABLE_JNI}
										-DSHERPA_ONNX_ENABLE_GPU=${SHERPA_ONNX_ENABLE_GPU}
										-DSHERPA_ONNX_ENABLE_DIRECTML=${SHERPA_ONNX_ENABLE_DIRECTML}
										-DSHERPA_ONNX_LINK_D3D=${SHERPA_ONNX_LINK_D3D}
										-DSHERPA_ONNX_ENABLE_RKNN=${SHERPA_ONNX_ENABLE_RKNN}
										-DSHERPA_ONNX_ENABLE_TESTS=${SHERPA_ONNX_ENABLE_TESTS}
										-DSHERPA_ONNX_ENABLE_CHECK=${SHERPA_ONNX_ENABLE_CHECK}
										-DSHERPA_ONNX_ENABLE_PORTAUDIO=${SHERPA_ONNX_ENABLE_PORTAUDIO}
										-DSHERPA_ONNX_ENABLE_C_API=${SHERPA_ONNX_ENABLE_C_API}
										-DSHERPA_ONNX_BUILD_C_API_EXAMPLES=${SHERPA_ONNX_BUILD_C_API_EXAMPLES}
										-DSHERPA_ONNX_ENABLE_WEBSOCKET=${SHERPA_ONNX_ENABLE_WEBSOCKET}
										-DSHERPA_ONNX_ENABLE_BINARY=${SHERPA_ONNX_ENABLE_BINARY}
										-DSHERPA_ONNX_ENABLE_TTS=${SHERPA_ONNX_ENABLE_TTS}
										-DSHERPA_ONNX_ENABLE_SPEAKER_DIARIZATION=${SHERPA_ONNX_ENABLE_SPEAKER_DIARIZATION}
										-DSHERPA_ONNX_LINK_LIBSTDCPP_STATICALLY=${SHERPA_ONNX_LINK_LIBSTDCPP_STATICALLY}
										-DSHERPA_ONNX_USE_PRE_INSTALLED_ONNXRUNTIME_IF_AVAILABLE=${SHERPA_ONNX_USE_PRE_INSTALLED_ONNXRUNTIME_IF_AVAILABLE}
										-DSHERPA_ONNX_ENABLE_SANITIZER=${SHERPA_ONNX_ENABLE_SANITIZER}
										-DKALDIFST_BUILD_TESTS=${KALDIFST_BUILD_TESTS}
										-DKALDIFST_BUILD_PYTHON=${KALDIFST_BUILD_PYTHON}
										-DKALDI_DECODER_ENABLE_TESTS=${KALDI_DECODER_ENABLE_TESTS}
										-DKALDI_DECODER_BUILD_PYTHON=${KALDI_DECODER_BUILD_PYTHON}
										-DSBPE_ENABLE_TESTS=${SBPE_ENABLE_TESTS}
										-DSBPE_BUILD_PYTHON=${SBPE_BUILD_PYTHON}
										-DPA_BUILD_SHARED_LIBS=${PA_BUILD_SHARED_LIBS}
										-DPA_BUILD_TESTS=${PA_BUILD_TESTS}
										-DPA_BUILD_EXAMPLES=${PA_BUILD_EXAMPLES}
										-DPA_WARNINGS_ARE_ERRORS=${PA_WARNINGS_ARE_ERRORS}
										-DPA_ENABLE_DEBUG_OUTPUT=${PA_ENABLE_DEBUG_OUTPUT}
										-DPA_USE_SKELETON=${PA_USE_SKELETON}
										-DPA_USE_ASIO=${PA_USE_ASIO}
										-DPA_USE_WMME=${PA_USE_WMME}
										-DPA_USE_WASAPI=${PA_USE_WASAPI}
										-DPA_USE_WDMKS=${PA_USE_WDMKS}
										-DPA_USE_WDMKS_DEVICE_INFO=${PA_USE_WDMKS_DEVICE_INFO}									

				  COMMAND cd ${SHERPA_BUILD_DIR} && msbuild sherpa-onnx.sln /p:Configuration=$<CONFIG> && msbuild INSTALL.vcxproj /p:Configuration=$<CONFIG>
				          && cd ${SHERPA_BUILD_BINARY_DIR}
						  && ${XCOPYCMD} ${XCOPYCMDFLAGS} *.dll ${SHERPA_ONNX_BIN_DIR} 
						  && cd ${SHERPA_BUILD_LIBRARY_DIR}
						  && ${XCOPYCMD} ${XCOPYCMDFLAGS} *.lib ${SHERPA_ONNX_BIN_DIR}
						  && ${XCOPYCMD} ${XCOPYCMDFLAGS} *.lib ${SHERPA_ONNX_LIB_DIR}

				  BYPRODUCTS ${SHERPA_ONNX_CORE_IMPORTLIB}
							 ${SHERPA_ONNX_CAPI_BINARY}
							 ${SHERPA_ONNX_CXXAPI_BINARY}
				  WORKING_DIRECTORY ${SHERPA_ONNX_SOURCE_DIR}
				  COMMAND_EXPAND_LISTS
				  VERBATIM
				  USES_TERMINAL)


add_dependencies(sherpa_build ort_build ort)

add_library(sherpa-onnx-core STATIC IMPORTED GLOBAL)
add_dependencies(sherpa-onnx-core sherpa_build)
set_target_properties(sherpa-onnx-core

                       PROPERTIES
					   IMPORTED_LOCATION ${SHERPA_ONNX_CORE_IMPORTLIBPATH}
					   IMPORTED_IMPLIB ${SHERPA_ONNX_CORE_IMPORTLIBPATH}
					   INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${SHERPA_ONNX_INCLUDE_DIR}>
					   )
if (MSVC)
	set_target_properties(sherpa-onnx-core PROPERTIES 
				PDB_OUTPUT_DIRECTORY $<INSTALL_INTERFACE:${SHERPA_ONNX_BUILD_DIR}/lib/$<CONFIG>>
				)
endif()

add_library(sherpa-onnx-c-api SHARED IMPORTED GLOBAL)
add_dependencies(sherpa-onnx-c-api sherpa_build)
set_target_properties(sherpa-onnx-c-api

                       PROPERTIES
					   IMPORTED_LOCATION ${SHERPA_ONNX_CAPI_BINPATH}
					   IMPORTED_IMPLIB ${SHERPA_ONNX_CAPI_IMPORTLIBPATH}
					   INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${SHERPA_ONNX_CAPI_INCLUDE_DIR}>
					   )
if (MSVC)
	set_target_properties(sherpa-onnx-c-api PROPERTIES 
				PDB_OUTPUT_DIRECTORY $<INSTALL_INTERFACE:${SHERPA_ONNX_BUILD_DIR}/bin/$<CONFIG>>
				)
endif()

add_library(sherpa-onnx-cxx-api SHARED IMPORTED GLOBAL)
add_dependencies(sherpa-onnx-cxx-api sherpa_build sherpa-onnx-c-api)
set_target_properties(sherpa-onnx-cxx-api

                       PROPERTIES
					   IMPORTED_LOCATION ${SHERPA_ONNX_CXXAPI_BINPATH}
					   IMPORTED_IMPLIB ${SHERPA_ONNX_CXXAPI_IMPORTLIBPATH}
					   INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${SHERPA_ONNX_CAPI_INCLUDE_DIR}>
					   )
if (MSVC)
	set_target_properties(sherpa-onnx-cxx-api PROPERTIES 
				PDB_OUTPUT_DIRECTORY $<INSTALL_INTERFACE:${SHERPA_ONNX_BUILD_DIR}/bin/$<CONFIG>>
				)
endif()

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
  $<TARGET_FILE:sherpa-onnx-cxx-api>
  $<TARGET_FILE:sherpa-onnx-c-api>
  $<TARGET_FILE:ort>
  $<TARGET_FILE:onnxruntime_providers_shared>
  $<TARGET_FILE:unnu_asr>
  $<TARGET_FILE:unnu_tts>
  PARENT_SCOPE
)
