# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "unnu_ce")
project(${PROJECT_NAME} LANGUAGES CXX C)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT DEFINED ${CMAKE_INSTALL_PREFIX})
	if(NOT DEFINED ${FLUTTER_EPHEMERAL_DIR})
		set(CMAKE_INSTALL_PREFIX "${CMAKE_BINARY_DIR}" CACHE STRING "Needed to avoid cmake_install.cmake build issues." FORCE) 
		if(NOT DEFINED ${CMAKE_INSTALL_BINDIR}
			set(CMAKE_INSTALL_BINDIR ${CMAKE_BINARY_DIR}/runner/$<CONFIG>)
		endif()
	else()
		set(CMAKE_INSTALL_PREFIX "${FLUTTER_EPHEMERAL_DIR}" CACHE STRING "Needed to avoid cmake_install.cmake build issues." FORCE) 
	endif()
endif()

set(UNNU_COG_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../src)

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

# python onnxruntime/tools/ci_build/build.py --build_dir onnxruntime/jni --build_shared_lib --config Release --skip_tests --skip_onnx_tests --android --android_abi arm64-v8a --android_api 35 --cmake_generator Ninja --android_ndk_path %ANDROID_NDK_ROOT% --cmake_extra_defines ANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON CMAKE_INSTALL_PREFIX=onnxruntime/jni
# copy onnxruntime/jni/arm64-v8a/Release/*.so onnxruntime/jni/arm64-v8a
# copy onnxruntime/jni/arm64-v8a/Release/*.a onnxruntime/jni/arm64-v8a

file(TO_NATIVE_PATH "${UNNU_COG_SRC_DIR}/onnxruntime/jni" ORTBUILD_DIR)
file(TO_NATIVE_PATH "${UNNU_COG_SRC_DIR}/onnxruntime/tools/ci_build/build.py" ORTBUILD_BUILD_PY)
file(TO_NATIVE_PATH "${UNNU_COG_SRC_DIR}/onnxruntime/jni/$<CONFIG>" ORTBUILD_BINARY_DIR)
file(TO_NATIVE_PATH "${UNNU_COG_SRC_DIR}" ORTBUILD_WORKING_DIR)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/onnxruntime/jni/include" ORTBUILD_INC_DIR)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/onnxruntime/jni/lib" ORTBUILD_LIB_DIR)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/onnxruntime/jni/arm64-v8a" ORTHOME_LIB_DIR)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/onnxruntime/headers" ORTHOME_HEADERS_DIR)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/onnxruntime/jni/arm64-v8a/libonnxruntime.so" ORTBUILD_BINARY)

set(ORTBUILD_BINPATH "${CMAKE_CURRENT_BINARY_DIR}/onnxruntime/jni/lib/libonnxruntime.so")
add_custom_command(OUTPUT ${UNNU_COG_SRC_DIR}/onnxruntime/jni/lib/libonnxruntime.so
				   COMMAND python ${ORTBUILD_BUILD_PY}
								  --cmake_generator Ninja
								  --build_dir ${UNNU_COG_SRC_DIR}/onnxruntime/jni 
								  --config $<CONFIG> 
								  --skip_tests
								  --skip_onnx_tests
								  --build_shared_lib 
								  --android 
								  --android_abi arm64-v8a 
								  --android_api 35 
								  --android_ndk_path $ENV{ANDROID_NDK_ROOT}
								  --cmake_extra_defines ANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON CMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/onnxruntime/jni
				  COMMAND cd ${ORTBUILD_BINARY_DIR} && ninja install && cd ${ORTBUILD_WORKING_DIR}
				  WORKING_DIRECTORY ${UNNU_COG_SRC_DIR}
				  COMMAND_EXPAND_LISTS
				  VERBATIM
				  USES_TERMINAL)


add_custom_target(ortbuild ALL COMMAND ${XCOPYCMD} ${XCOPYCMDFLAGS} ${ORTBUILD_BINARY} ${ORTHOME_LIB_DIR} 
								&& cd ${ORTBUILD_INC_DIR} 
								&& ${XCOPYCMD} ${XCOPYCMDFLAGS} * ${ORTHOME_HEADERS_DIR} 
								&& cd ${ORTBUILD_WORKING_DIR}
				  BYPRODUCTS ${ORTBUILD_BINARY}
				  WORKING_DIRECTORY ${UNNU_COG_SRC_DIR}/onnxruntime/jni
				  COMMAND_EXPAND_LISTS
				  VERBATIM
				  USES_TERMINAL)

add_library(onnxruntime SHARED IMPORTED GLOBAL)
set_target_properties(# Specifies the target library.
                       onnxruntime

                       # Specifies the parameter you want to define.
                       PROPERTIES IMPORTED_LOCATION

                       # Provides the path to the library you want to import.
                       ${ORTBUILD_BINPATH})
					   
######################### cpuinfo
set(CPUINFO_LOG_LEVEL "fatal" CACHE STRING "Minimum logging level (info with lower severity will be ignored)" FORCE)
# set(CPUINFO_LOG_TO_STDIO OFF CACHE BOOL "Log errors, warnings, and information to stdout/stderr" FORCE)
set(CPUINFO_LIBRARY_TYPE "static" CACHE STRING "Type of cpuinfo library (shared, static, or default) to build" FORCE)
set(CPUINFO_BUILD_TOOLS OFF CACHE BOOL "Build command-line tools" FORCE)
set(CPUINFO_BUILD_UNIT_TESTS OFF CACHE BOOL "Build cpuinfo unit tests" FORCE)
set(CPUINFO_BUILD_MOCK_TESTS OFF CACHE BOOL "Build cpuinfo mock tests" FORCE)
set(CPUINFO_BUILD_BENCHMARKS OFF CACHE BOOL "Build cpuinfo micro-benchmarks" FORCE)
set(CPUINFO_BUILD_PKG_CONFIG OFF CACHE BOOL "Build pkg-config manifest" FORCE)

include_directories("${UNNU_COG_SRC_DIR}/cpuinfo/include")
add_subdirectory("${UNNU_COG_SRC_DIR}/cpuinfo" "${CMAKE_CURRENT_BINARY_DIR}/cpuinfo")
link_directories(${CMAKE_CURRENT_BINARY_DIR}/cpuinfo/$<CONFIG>)

set(BUILD_SHARED_LIBS ON)
####################### tokenizers
set(MSGPACK_CXX17 ON CACHE BOOL "Using c++17 compiler" FORCE)
set(MSGPACK_USE_BOOST OFF CACHE BOOL "Use Boost libraried" FORCE)
set(SPM_ENABLE_SHARED ON CACHE BOOL "Builds shared libaries in addition to static libraries." FORCE)
set(SPM_ENABLE_TCMALLOC OFF CACHE BOOL "Link static library of TCMALLOC." FORCE)
add_subdirectory("${UNNU_COG_SRC_DIR}/tokenizers" "${CMAKE_CURRENT_BINARY_DIR}/tokenizers")

include_directories("${UNNU_COG_SRC_DIR}/onnxruntime/headers")
link_directories("${UNNU_COG_SRC_DIR}/onnxruntime/jni/arm64-v8a")
set(BUILD_SHARED_LIBS ON)
####################### ort-genai
set(USE_CUDA OFF CACHE BOOL "Build with CUDA support" FORCE)
set(USE_ROCM OFF CACHE BOOL "Build with ROCm support" FORCE)
set(USE_DML OFF CACHE BOOL "Build with DML support" FORCE)
set(ENABLE_JAVA OFF CACHE BOOL "Build the Java API." FORCE)
set(ENABLE_PYTHON OFF CACHE BOOL "Build the Python API." FORCE)
set(ENABLE_TESTS OFF CACHE BOOL "Enable tests" FORCE)
set(ORT_HOME "${UNNU_COG_SRC_DIR}/onnxruntime" CACHE PATH "ORT Home" FORCE)
set(TEST_PHI2 OFF CACHE BOOL "Enable tests for Phi2" FORCE)
set(ENABLE_MODEL_BENCHMARK OFF CACHE BOOL "Build model benchmark program" FORCE)
add_subdirectory("${UNNU_COG_SRC_DIR}/ortgenai" "${CMAKE_CURRENT_BINARY_DIR}/ortgenai" EXCLUDE_FROM_ALL)



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
  $<TARGET_FILE:onnxruntime>
  PARENT_SCOPE
)
