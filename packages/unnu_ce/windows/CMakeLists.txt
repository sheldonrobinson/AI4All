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

###################### ortgenai
FetchContent_Declare(
  msonnxruntime-genai
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/onnxruntime-genai.git
  GIT_TAG        		 origin/main
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE

  EXCLUDE_FROM_ALL
)

###################### onnxruntime
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


################### build ort-genai
set(USE_CUDA "Build with CUDA support" OFF)
set(USE_TRT_RTX "Build with TensorRT-RTX support" OFF)
option(USE_ROCM "Build with ROCm support" OFF)
option(USE_DML "Build with DML support" ON)
option(USE_WINML "Build with WinML support" OFF)
option(USE_GUIDANCE "Build with guidance support" ON)

FetchContent_Populate(msonnxruntime-genai)

file(REAL_PATH ${msonnxruntime-genai_SOURCE_DIR} MSORTGENAI_SOURCE_DIR)
file(REAL_PATH ${msonnxruntime-genai_BINARY_DIR} MSORTGENAI_BINARY_DIR)

file(TO_NATIVE_PATH ${MSORTGENAI_SOURCE_DIR} ORTGENAI_BUILD_SRC_DIR)
file(TO_NATIVE_PATH "${MSORTGENAI_SOURCE_DIR}/build.py" ORTGENAI_BUILD_PY)

file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/ortgenai/build/win-${ORT_PLATFORM}" ORTGENAI_BUILD_DIR)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/ortgenai/build/win-${ORT_PLATFORM}/$<CONFIG>" ORTGENAI_BUILD_ROOT_DIR)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/ortgenai/build/win-${ORT_PLATFORM}/$<CONFIG>/$<CONFIG>" ORTGENAI_BUILD_BINARY_DIR)

file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/ortgenai/win-${ORT_PLATFORM}/include" ORTGENAI_BUILD_INC_DIR)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/ortgenai/win-${ORT_PLATFORM}/bin" ORTGENAI_BUILD_BIN_DIR)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/ortgenai/win-${ORT_PLATFORM}/lib" ORTGENAI_BUILD_LIB_DIR)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/ortgenai/win-${ORT_PLATFORM}/bin/onnxruntime-genai.dll" ORTGENAI_BUILD_BINARY)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/ortgenai/win-${ORT_PLATFORM}/lib/onnxruntime-genai.lib" ORTGENAI_BUILD_IMPORTLIB)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/ortgenai/win-${ORT_PLATFORM}/include" ORTGENAI_BUILD_HEADERS)

set(ORTGENAI_LIB_DIR "${CMAKE_CURRENT_BINARY_DIR}/ortgenai/win-${ORT_PLATFORM}/lib")
set(ORTGENAI_BIN_DIR "${CMAKE_CURRENT_BINARY_DIR}/ortgenai/win-${ORT_PLATFORM}/bin")
set(ORTGENAI_INC_DIR "${CMAKE_CURRENT_BINARY_DIR}/ortgenai/win-${ORT_PLATFORM}/include")
set(ORTGENAI_HDRS_DIR "${CMAKE_CURRENT_BINARY_DIR}/ortgenai/win-${ORT_PLATFORM}/include")

set(ORTGENAI_BUILD_BINPATH "${CMAKE_CURRENT_BINARY_DIR}/ortgenai/win-${ORT_PLATFORM}/bin/onnxruntime-genai.dll")
set(ORTGENAI_BUILD_IMPORTLIBPATH "${CMAKE_CURRENT_BINARY_DIR}/ortgenai/win-${ORT_PLATFORM}/lib/onnxruntime-genai.lib")

add_custom_target(ortgenai_build ALL COMMAND python ${ORTGENAI_BUILD_PY}
								  --cmake_generator "Visual Studio 17 2022"
								  --build_dir ${ORTGENAI_BUILD_DIR} 
								  --config $<CONFIG>
								  --skip_tests
								  --skip_wheel
								  --use_dml
								  --use_guidance
								  --skip_examples
								  --parallel
								  --ort_home ${ORT_HOME}
								  --cmake_extra_defines CMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/ortgenai/win-${ORT_PLATFORM} CMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded$<$<CONFIG:Debug>:Debug>DLL ENABLE_PYTHON=OFF
				  COMMAND cd ${ORTGENAI_BUILD_ROOT_DIR} && msbuild INSTALL.vcxproj /p:Configuration=$<CONFIG>
						  && cd ${ORTGENAI_BUILD_BINARY_DIR}
						  && ${XCOPYCMD} ${XCOPYCMDFLAGS} *.dll ${ORTGENAI_BUILD_BIN_DIR} 
						  && ${XCOPYCMD} ${XCOPYCMDFLAGS} *.lib ${ORTGENAI_BUILD_BIN_DIR}
						  && ${XCOPYCMD} ${XCOPYCMDFLAGS} *.lib ${ORTGENAI_BUILD_LIB_DIR}
				  BYPRODUCTS ${ORTGENAI_BUILD_BINPATH}
							 ${ORTGENAI_BUILD_IMPORTLIBPATH}
				  WORKING_DIRECTORY ${ORTGENAI_BUILD_SRC_DIR}
				  COMMAND_EXPAND_LISTS
				  VERBATIM
				  USES_TERMINAL)

add_dependencies(ortgenai_build ort_build)


add_library(ortgenai SHARED IMPORTED GLOBAL)
add_dependencies(ortgenai ortgenai_build)
set_target_properties(# Specifies the target library.
                       ortgenai
                       PROPERTIES 
					   IMPORTED_LOCATION ${ORTGENAI_BUILD_BINPATH}
					   IMPORTED_IMPLIB ${ORTGENAI_BUILD_IMPORTLIBPATH}
					   INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${ORTGENAI_HDRS_DIR}>
					 )
if (MSVC)
	set_target_properties(ortgenai PROPERTIES 
				PDB_OUTPUT_DIRECTORY $<INSTALL_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/ortgenai/build/win-${ORT_PLATFORM}/$<CONFIG>/$<CONFIG>>
				)
endif()

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
  $<TARGET_FILE:ortgenai>
#  $<TARGET_FILE:abseil_dll>
  $<TARGET_FILE:soar_lib>
  PARENT_SCOPE
)
