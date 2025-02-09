# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "unnu_ort")
project(${PROJECT_NAME} LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT DEFINED CMAKE_INSTALL_PREFIX)	
	set(CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_BINARY_DIR}" CACHE PATH "Needed to avoid cmake_install.cmake build issues." FORCE) 
endif()

set(CMAKE_BUILD_RPATH_USE_ORIGIN TRUE)
set(UNNU_ORT_SRC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../src")

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

set(ZLIB_BUILD_TESTING OFF CACHE BOOL "Enable Zlib Examples as tests" FORCE)
set(ZLIB_BUILD_SHARED OFF CACHE BOOL "Enable building zlib shared library" FORCE)
set(ZLIB_BUILD_STATIC ON CACHE BOOL "Enable building zlib static library" FORCE)
set(ZLIB_BUILD_MINIZIP OFF CACHE BOOL "Enable building libminizip contrib library" FORCE)
set(ZLIB_INSTALL OFF CACHE BOOL "Enable installation of zlib" FORCE)
set(ZLIB_BUILD_EXAMPLES OFF CACHE BOOL "Enable Zlib Examples" FORCE)
add_subdirectory("${UNNU_ORT_SRC_DIR}/zlib" "${CMAKE_CURRENT_BINARY_DIR}/zlib" EXCLUDE_FROM_ALL)

set(ZLIB_INCLUDE_DIR "${CMAKE_CURRENT_BINARY_DIR}/include")
set(ZLIB_LIBRARY "${CMAKE_CURRENT_BINARY_DIR}/lib/zlibstatic.lib")
get_target_property(ZLIB_INCLUDE_DIR zlibstatic HEADER_DIRS)
get_target_property(ZLIB_LIBRARY zlibstatic IMPORTED_LOCATION)

set(BUILD_TESTING OFF CACHE BOOL "Enable creation of tests." FORCE)
set(EIGEN_BUILD_BLAS OFF CACHE BOOL "Toggles the building of the Eigen Blas library" FORCE)
set(EIGEN_BUILD_LAPACK OFF CACHE BOOL "Toggles the building of the included Eigen LAPACK library" FORCE)

if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
  set(COPYCMD copy)
  set(XCOPYCMD xcopy)
  set(XCOPYCMDFLAGS /S /Y)
  set(COPYCMDFLAGS /Y)
elseif(CMAKE_HOST_UNIX)
  set(XCOPYCMD cp)
  set(XCOPYCMDFLAGS -r)
  set(MKDIRFLAGS -p)
endif()

if(CMAKE_GENERATOR_PLATFORM MATCHES "^arm64")
  set(ORT_WIN_PLATFORM "arm64")
else()
  set(ORT_WIN_PLATFORM "x64")
endif()

file(TO_NATIVE_PATH "${UNNU_ORT_SRC_DIR}/ort" ORTBUILD_WORKING_DIR)
file(TO_NATIVE_PATH "${UNNU_ORT_SRC_DIR}/ort/tools/ci_build/build.py" ORTBUILD_BUILD_PY)
file(TO_NATIVE_PATH "${UNNU_ORT_SRC_DIR}/ort/build/win-${ORT_WIN_PLATFORM}" ORTBUILD_DIR)
file(TO_NATIVE_PATH "${UNNU_ORT_SRC_DIR}/ort/build/win-${ORT_WIN_PLATFORM}/$<CONFIG>" ORTBUILD_ROOT_DIR)
file(TO_NATIVE_PATH "${UNNU_ORT_SRC_DIR}/ort/build/win-${ORT_WIN_PLATFORM}/$<CONFIG>/$<CONFIG>" ORTBUILD_BINARY_DIR)

file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/onnxruntime/windows/${ORT_WIN_PLATFORM}/include" ORTBUILD_INC_DIR)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/onnxruntime/windows/${ORT_WIN_PLATFORM}/lib" ORTBUILD_LIB_DIR)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/onnxruntime/windows/${ORT_WIN_PLATFORM}/bin" ORTBUILD_BIN_DIR)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/onnxruntime/windows/${ORT_WIN_PLATFORM}/bin/onnxruntime.dll" ORTBUILD_BINARY)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/onnxruntime/windows/${ORT_WIN_PLATFORM}/bin/onnxruntime_providers_shared.dll" ORTBUILD_PROVIDERS_BINARY)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/onnxruntime/windows/${ORT_WIN_PLATFORM}/lib/onnxruntime.lib" ORTBUILD_IMPORTLIB)
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}/onnxruntime/windows/${ORT_WIN_PLATFORM}/lib/onnxruntime_providers_shared.lib" ORTBUILD_PROVIDERS_IMPORTLIB)

set(ORTBUILD_BINPATH "${CMAKE_CURRENT_BINARY_DIR}/onnxruntime/windows/${ORT_WIN_PLATFORM}/bin/onnxruntime.dll")
set(ORTBUILD_PROVIDERS_BINPATH "${CMAKE_CURRENT_BINARY_DIR}/onnxruntime/windows/${ORT_WIN_PLATFORM}/bin/onnxruntime_providers_shared.dll")
set(ORTBUILD_IMPORTLIBPATH "${CMAKE_CURRENT_BINARY_DIR}/onnxruntime/windows/${ORT_WIN_PLATFORM}/lib/onnxruntime.lib")
set(ORTBUILD_PROVIDERS_IMPORTLIBPATH "${CMAKE_CURRENT_BINARY_DIR}/onnxruntime/windows/${ORT_WIN_PLATFORM}/lib/onnxruntime_providers_shared.lib")

set(ORT_LIB_DIR "${CMAKE_CURRENT_BINARY_DIR}/onnxruntime/windows/${ORT_WIN_PLATFORM}/lib")
set(ORT_BIN_DIR "${CMAKE_CURRENT_BINARY_DIR}/onnxruntime/windows/${ORT_WIN_PLATFORM}/bin")
set(ORT_INC_DIR "${CMAKE_CURRENT_BINARY_DIR}/onnxruntime/windows/${ORT_WIN_PLATFORM}/include")


add_custom_target(ortbuild ALL COMMAND  python ${ORTBUILD_BUILD_PY}
								  --cmake_generator "Visual Studio 17 2022"
								  --build_dir ${ORTBUILD_DIR} 
								  --config $<CONFIG> 
								  --build_shared_lib
								  --skip_tests
								  --skip_onnx_tests
								  --parallel 
								  --compile_no_warning_as_error 
								  --skip_submodule_sync
								  --cmake_extra_defines CMAKE_INSTALL_PREFIX=${CMAKE_CURRENT_BINARY_DIR}/onnxruntime/windows/${ORT_WIN_PLATFORM}
					 COMMAND  cd ${ORTBUILD_ROOT_DIR} && msbuild INSTALL.vcxproj /p:Configuration=$<CONFIG>
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

add_library(onnxruntime SHARED IMPORTED GLOBAL)
set_target_properties(# Specifies the target library.
                       onnxruntime

                       # Specifies the parameter you want to define.
                       PROPERTIES IMPORTED_LOCATION

                       # Provides the path to the library you want to import.
                       ${ORTBUILD_BINPATH})

if(MSVC)
set_target_properties(onnxruntime PROPERTIES IMPORTED_IMPLIB ${ORTBUILD_IMPORTLIBPATH})
endif()


set(BUILD_SHARED_LIBS ON)
####################### tokenizers
set(MSGPACK_CXX17 ON CACHE BOOL "Using c++17 compiler" FORCE)
set(MSGPACK_USE_BOOST OFF CACHE BOOL "Use Boost libraried" FORCE)
set (MSGPACK_BUILD_DOCS OFF CACHE BOOL "Build Doxygen documentation" FORCE)
set(SPM_ENABLE_SHARED OFF CACHE BOOL "Builds shared libaries in addition to static libraries." FORCE)
set(SPM_ENABLE_MSVC_MT_BUILD ON CACHE BOOL "Use /MT flag in MSVC build" FORCE)
add_subdirectory("${UNNU_ORT_SRC_DIR}/tokenizers" "${CMAKE_CURRENT_BINARY_DIR}/tokenizers" EXCLUDE_FROM_ALL)

# Invoke the build for native code shared with the other target platforms.
# This can be changed to accommodate different builds.
add_subdirectory("${UNNU_ORT_SRC_DIR}" "${CMAKE_CURRENT_BINARY_DIR}/shared")
add_dependencies(unnu_ort onnxruntime onnxruntime_providers_shared ortbuild)

# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(unnu_ort_bundled_libraries
  # Defined in ../src/CMakeLists.txt.
  # This can be changed to accommodate different builds.
  $<TARGET_FILE:unnu_ort>
  $<TARGET_FILE:onnxruntime>
  $<TARGET_FILE:onnxruntime_providers_shared>
  PARENT_SCOPE
)
