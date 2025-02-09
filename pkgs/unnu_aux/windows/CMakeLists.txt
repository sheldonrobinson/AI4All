# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "unnu_aux")
project(${PROJECT_NAME} LANGUAGES CXX C)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT DEFINED CMAKE_INSTALL_PREFIX)
	set(CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_BINARY_DIR}" CACHE PATH "Needed to avoid cmake_install.cmake build issues." FORCE) 
endif()

set(CMAKE_BUILD_RPATH_USE_ORIGIN TRUE)
set(UNNU_AUX_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../src)

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
find_package(Threads REQUIRED)

######################## hashpp
FetchContent_Declare(
  hashpp
  GIT_REPOSITORY 		 https://github.com/D7EAD/HashPlusPlus.git
  GIT_TAG        		 origin/main
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL
			 
  OVERRIDE_FIND_PACKAGE
			 
)

FetchContent_GetProperties(hashpp)
if(NOT hashpp_POPULATED)
  FetchContent_Populate(
	hashpp
  )

endif()

file(REAL_PATH ${hashpp_SOURCE_DIR}/include HASHPP_INCLUDE_DIR)
file(REAL_PATH ${hashpp_SOURCE_DIR} HASHPP_SOURCE_DIR)
file(REAL_PATH ${hashpp_BINARY_DIR} HASHPP_BINARY_DIR)

if(NOT TARGET hashpp)
	add_library(hashpp INTERFACE IMPORTED)
    set_target_properties(hashpp PROPERTIES
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
							)
	target_include_directories(hashpp INTERFACE 
						$<BUILD_INTERFACE:${HASHPP_INCLUDE_DIR}>
						)
endif()

######################## libconfig
FetchContent_Declare(
  libconfig
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/libconfig.git
  GIT_TAG        		 origin/unnu_aux
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL
			 
  OVERRIDE_FIND_PACKAGE
			 
)

set(LIBCONFIG_BUILD_SHARED_LIBS OFF CACHE BOOL "Build shared libraries" FORCE)
set(BUILD_EXAMPLES OFF CACHE BOOL "Enable examples" FORCE)
set(BUILD_TESTS OFF CACHE BOOL "Enable tests" FORCE)
set(BUILD_FUZZERS OFF CACHE BOOL "Enable fuzzers" FORCE)
set(LIBCONFIG_INSTALL  OFF CACHE BOOL "Install applications and libraries" FORCE)

FetchContent_MakeAvailable(libconfig)

######################## yaml-cpp
FetchContent_Declare(
  yaml-cpp
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/yaml-cpp.git
  GIT_TAG 		 		 origin/master
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL

)

set(YAML_CPP_BUILD_CONTRIB  ON CACHE BOOL "Enable yaml-cpp contrib in library" FORCE)
set(YAML_CPP_BUILD_TOOLS  OFF CACHE BOOL "Enable parse tools" FORCE)
set(YAML_BUILD_SHARED_LIBS  ON CACHE BOOL "Build yaml-cpp shared library" FORCE)
set(YAML_CPP_INSTALL  OFF CACHE BOOL "Enable generation of yaml-cpp install targets" FORCE)
set(YAML_CPP_FORMAT_SOURCE  OFF CACHE BOOL "Format source" FORCE)
set(YAML_CPP_DISABLE_UNINSTALL  ON CACHE BOOL "Disable uninstallation of yaml-cpp" FORCE)
set(YAML_USE_SYSTEM_GTEST  OFF CACHE BOOL "Use system googletest if found" FORCE)
set(YAML_ENABLE_PIC  ON CACHE BOOL "Use Position-Independent Code" FORCE)


FetchContent_MakeAvailable(yaml-cpp)


################## cpuinfo settings ###############################
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


######################## dlib
FetchContent_Declare(
  dlib
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/dlib.git
  GIT_TAG        		 origin/master
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE

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

list(APPEND OPENBLAS_INCLUDE_DIRS ${OPENBLAS_INCLUDE_DIR} ${CMAKE_BINARY_DIR})
set(BLAS_LIBRARIES ${OPENBLAS_LIBRARY} CACHE STRING "BLAS libraries" FORCE)
set(BLAS_INCLUDE_DIRS ${OPENBLAS_BINARY_DIR} CACHE STRING "BLAS include dirs" FORCE)
# target_include_directories(openblas_shared PRIVATE ${OPENBLAS_BINARY_DIR})

if(NOT TARGET BLAS::BLAS)
	add_library(BLAS::BLAS INTERFACE IMPORTED)
    set_target_properties(BLAS::BLAS PROPERTIES
                          INTERFACE_LINK_LIBRARIES openblas_shared							  
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						  )
endif()

######################## dlib cont
set(BLA_VENDOR "OpenBLAS" CACHE STRING "BLAS Vendor" FORCE)
set(DLIB_IN_PROJECT_BUILD  ON CACHE INTERNAL "DLIB_IN_PROJECT_BUILD==true means you are using dlib by invoking add_subdirectory(dlib) in the parent project" FORCE)
set(DLIB_ENABLE_ASSERTS  OFF CACHE INTERNAL "Enable this if you want to turn on the DLIB_ASSERT macro" FORCE)
set(DLIB_ISO_CPP_ONLY  OFF CACHE INTERNAL "Enable this if you don't want to compile any non-ISO C++ code (i.e. you don't use any of the API Wrappers)" FORCE)
set(DLIB_NO_GUI_SUPPORT  ON CACHE INTERNAL "Enable this if you don't want to compile any of the dlib GUI code" FORCE)
set(DLIB_ENABLE_STACK_TRACE  OFF CACHE INTERNAL "Enable this if you want to turn on the DLIB_STACK_TRACE macros" FORCE)
set(DLIB_JPEG_SUPPORT  OFF CACHE INTERNAL "Disable this if you don't want to link against libjpeg" FORCE)
set(DLIB_LINK_WITH_SQLITE3  OFF CACHE INTERNAL "Disable this if you don't want to link against sqlite3" FORCE)
set(DLIB_USE_BLAS  OFF CACHE INTERNAL "Disable this if you don't want to use a BLAS library" FORCE)
set(DLIB_USE_LAPACK  OFF CACHE INTERNAL "Disable this if you don't want to use a LAPACK library" FORCE)
set(DLIB_USE_CUDA  OFF CACHE INTERNAL "Disable this if you don't want to use NVIDIA CUDA" FORCE)
set(DLIB_PNG_SUPPORT  OFF CACHE INTERNAL "Disable this if you don't want to link against libpng" FORCE)
set(DLIB_GIF_SUPPORT  OFF CACHE INTERNAL "Disable this if you don't want to link against libgif" FORCE)
set(DLIB_WEBP_SUPPORT  OFF CACHE INTERNAL "Disable this if you don't want to link against libwebp" FORCE)
set(DLIB_JXL_SUPPORT  OFF CACHE INTERNAL "Disable this if you don't want to link against libjxl" FORCE)
set(DLIB_USE_FFTW  OFF CACHE INTERNAL "Disable this if you don't want to link against fftw" FORCE)
set(DLIB_USE_MKL_FFT  OFF CACHE INTERNAL "Disable this is you don't want to use the MKL DFTI FFT implementation" FORCE)
set(DLIB_USE_MKL_SEQUENTIAL  OFF CACHE INTERNAL "Enable this if you have MKL installed and want to use the sequential version instead of the multi-core version." FORCE)
set(DLIB_USE_MKL_WITH_TBB  OFF CACHE INTERNAL "Enable this if you have MKL installed and want to use the tbb version instead of the openmp version." FORCE)
set(DLIB_USE_FFMPEG  OFF CACHE INTERNAL "Disable this if you don't want to use the FFMPEG library" FORCE)
set(CUDA_PROPAGATE_HOST_FLAGS  OFF CACHE INTERNAL "Propage C/CXX_FLAGS and friends to the host compiler via -Xcompile" FORCE)
set(DLIB_FORCE_MSVC_STATIC_RUNTIME  OFF CACHE INTERNAL "use static runtime" FORCE)

set(USE_SSE2_INSTRUCTIONS  ON CACHE INTERNAL "Compile your program with SSE2 instructions" FORCE)
set(USE_SSE4_INSTRUCTIONS  ON CACHE INTERNAL "Compile your program with SSE4 instructions" FORCE)
set(USE_AVX_INSTRUCTIONS   ON CACHE INTERNAL "Compile your program with AVX instructions"  FORCE)

FetchContent_MakeAvailable(dlib openblas)

# Invoke the build for native code shared with the other target platforms.
# This can be changed to accommodate different builds.
add_subdirectory("${UNNU_AUX_SRC_DIR}" "${CMAKE_CURRENT_BINARY_DIR}/shared")

set_target_properties(unnu_aux PROPERTIES
  BUILD_WITH_INSTALL_RPATH TRUE
)

# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(unnu_aux_bundled_libraries
  # Defined in ../src/CMakeLists.txt.
  # This can be changed to accommodate different builds.
  $<TARGET_FILE:unnu_aux>
  $<TARGET_FILE:yaml-cpp>
  $<TARGET_FILE:openblas_shared> 
  PARENT_SCOPE
)
