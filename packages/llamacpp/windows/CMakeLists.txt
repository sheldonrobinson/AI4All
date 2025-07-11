# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "llamacpp")
project(${PROJECT_NAME} LANGUAGES CXX C)

if(NOT DEFINED CMAKE_INSTALL_PREFIX)
	set(CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_BINARY_DIR}" CACHE PATH "Needed to avoid cmake_install.cmake build issues." FORCE) 
endif()

set(CMAKE_BUILD_RPATH_USE_ORIGIN TRUE)
set(LLAMACPP_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../src)

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

find_package(OpenMP REQUIRED)


################## cpuinfo settings ###############################
FetchContent_Declare(
  cpuinfo
  GIT_REPOSITORY https://github.com/sheldonrobinson/cpuinfo.git
  GIT_TAG        origin/main
  GIT_SHALLOW    TRUE
  
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

####################
FetchContent_Declare(
  pciids
  GIT_REPOSITORY https://github.com/sheldonrobinson/pciids.git
  GIT_TAG        origin/master
  GIT_SHALLOW    TRUE
  
  EXCLUDE_FROM_ALL
  
  OVERRIDE_FIND_PACKAGE
)

FetchContent_MakeAvailable(pciids)

file(REAL_PATH ${pciids_SOURCE_DIR} PCI_IDS_SOURCE_DIR)

#################### Vulkan
FetchContent_Declare(
  vulkan
  GIT_REPOSITORY https://github.com/KhronosGroup/Vulkan-Loader.git
  GIT_TAG        vulkan-sdk-1.4.328.1
  GIT_SHALLOW    TRUE
  
  EXCLUDE_FROM_ALL
  
  OVERRIDE_FIND_PACKAGE
)

FetchContent_Declare(
  vulkan-headers
  GIT_REPOSITORY https://github.com/KhronosGroup/Vulkan-Headers.git
  GIT_TAG        vulkan-sdk-1.4.328.1
  GIT_SHALLOW    TRUE
  
  EXCLUDE_FROM_ALL
  
  OVERRIDE_FIND_PACKAGE
)

set(VULKAN_HEADERS_ENABLE_TESTS OFF CACHE BOOL "Test Vulkan-Headers" FORCE)
set(VULKAN_HEADERS_ENABLE_INSTALL OFF CACHE BOOL "Install Vulkan-Headers" FORCE)
set(BUILD_TESTS OFF CACHE BOOL "Build Tests" FORCE)
set(LOADER_CODEGEN ON CACHE BOOL "Enable vulkan loader code generation" FORCE)


FetchContent_MakeAvailable(vulkan vulkan-headers)
add_dependencies(vulkan Vulkan-Headers)

#  FetchContent_MakeAvailable(vulkan-headers)

file(REAL_PATH ${vulkan-headers_SOURCE_DIR} VULKAN_HEADERS_DIR)
file(REAL_PATH ${vulkan_BINARY_DIR} VULKAN_LOADER_BUILD_DIR)

set(Vulkan_INCLUDE_DIR ${VULKAN_HEADERS_DIR}/include CACHE PATH "Vulkan include dir" FORCE)
set(Vulkan_LIBRARY ${VULKAN_LOADER_BUILD_DIR}/loader/$<CONFIG>/vulkan-1.lib CACHE FILEPATH "vulkan import library" FORCE)
set(Vulkan_BINPATH ${VULKAN_LOADER_BUILD_DIR}/loader/$<CONFIG>/vulkan-1.dll CACHE FILEPATH "vulkan library" FORCE)

if(NOT TARGET Vulkan::Vulkan)
	add_library(Vulkan::Vulkan INTERFACE IMPORTED)
	list(APPEND VULKAN_PROJECTS vulkan Vulkan-Headers)
    set_target_properties(Vulkan::Vulkan PROPERTIES
                          INTERFACE_LINK_LIBRARIES vulkan							  
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						  )
endif()

#################### infoware
FetchContent_Declare(
  infoware
  GIT_REPOSITORY https://github.com/sheldonrobinson/infoware.git
  GIT_TAG        origin/main
  GIT_SHALLOW    TRUE
  
  EXCLUDE_FROM_ALL
  			 
  OVERRIDE_FIND_PACKAGE
)

set(INFOWARE_USE_VULKAN ON CACHE BOOL "Add public, transitive define to infoware to use Vulkan for GPU detection."                           FORCE)
set(INFOWARE_USE_D3D    OFF CACHE BOOL "Add public, transitive define to infoware to use Direct 3D for GPU detection."                       FORCE)
set(INFOWARE_USE_OPENGL OFF CACHE BOOL "Add public, transitive define to infoware to use Open Graphics Language (OpenGL) for GPU detection." FORCE)
set(INFOWARE_USE_OPENCL OFF CACHE BOOL "Add public, transitive define to infoware to use Open Compute Language (OpenCL) for GPU detection."  FORCE)
set(INFOWARE_USE_X11 OFF CACHE BOOL "Add public, transitive define to infoware to use X11 for display detection." FORCE)
set(INFOWARE_USE_PCIIDS ON CACHE BOOL "Want PCI IDs. If disabled, the PCI ID database will not be compiled, and the pci.hpp API will be unimplemented." FORCE)
set(INFOWARE_EXAMPLES OFF CACHE BOOL "Add infoware examples to the build." FORCE)
set(INFOWARE_TESTS    OFF CACHE BOOL "Input tests for infoware."           FORCE)
set(INFOWARE_INSTALL  OFF CACHE BOOL "Install libraries and binaries."     FORCE)
set(INFOWARE_PCI_IDS_PATH       ${PCI_IDS_SOURCE_DIR}/pci.ids CACHE FILEPATH "pci.ids file to use. Overrides cloning from INFOWARE_PCI_IDS_REPOSITORY." FORCE)
set(INFOWARE_PCI_IDS_REPOSITORY "https://github.com/sheldonrobinson/pciids" CACHE STRING   "Path/URL to clone a pciids git repository from if override path not supplied. Defaults to https://github.com/pciutils/pciids." FORCE)

FetchContent_MakeAvailable(infoware pciids vulkan vulkan-headers)

file(REAL_PATH ${infoware_BINARY_DIR} INFOWARE_BUILD_DIR)
set(INFOWARE_BINARY_DLL ${INFOWARE_BUILD_DIR}/lib/$<CONFIG>/infoware$<$<CONFIG:Debug>:d>.dll CACHE FILEPATH "infoware build as dll" FORCE)

add_dependencies(infoware vulkan Vulkan-Headers)
target_include_directories(infoware PRIVATE ${Vulkan_INCLUDE_DIR})

################## OpenBLAS
FetchContent_Declare(
  openblas
  GIT_REPOSITORY https://github.com/sheldonrobinson/OpenBLAS.git
  GIT_TAG        origin/develop
  GIT_SHALLOW    TRUE
  
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

set(OPENBLAS_LIBRARY ${OPENBLAS_BINARY_DIR}/lib/$<CONFIG>/openblas.lib CACHE FILEPATH "openblas library" FORCE)

set(BLAS_LIBRARIES ${OPENBLAS_LIBRARY} CACHE STRING "BLAS libraries" FORCE)
set(BLAS_INCLUDE_DIRS ${OPENBLAS_INCLUDE_DIR} CACHE STRING "BLAS include dirs" FORCE)

if(NOT TARGET BLAS::BLAS)
	add_library(BLAS::BLAS INTERFACE IMPORTED)
    set_target_properties(BLAS::BLAS PROPERTIES
                          INTERFACE_LINK_LIBRARIES openblas_shared							  
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						  )
endif()

######################## llama.cpp



FetchContent_Declare(
  llama_cpp
  GIT_REPOSITORY https://github.com/ggml-org/llama.cpp.git
  GIT_TAG        b6869 # b6586
  GIT_SHALLOW    TRUE
  
  EXCLUDE_FROM_ALL 
)

# FetchContent_MakeAvailable(llama_cpp vulkan-headers vulkan openblas)

# add_dependencies(ggml-vulkan vulkan Vulkan-Headers)
# target_include_directories(ggml-vulkan PRIVATE ${Vulkan_INCLUDE_DIR})
# add_dependencies(ggml-blas openblas_shared)
# target_include_directories(ggml-blas PRIVATE ${OPENBLAS_BINARY_DIR})

# Set the linker flags for shared libraries
set(LLAMA_BUILD_COMMON ON CACHE BOOL "llama: build common utils library" FORCE)
set(LLAMA_CURL OFF CACHE BOOL "llama: use libcurl to download model from an URL" FORCE)
set(LLAMA_LLGUIDANCE ON CACHE BOOL "llama-common: include LLGuidance library for structured output in common utils" FORCE)
set(LLAMA_OPENSSL OFF CACHE BOOL "llama: use openssl to support HTTPS" FORCE)
set(LLAMA_TOOLS_INSTALL OFF CACHE BOOL "llama: install tools" FORCE)
set(LLAMA_BUILD_TESTS    OFF CACHE BOOL "llama: build tests"          FORCE)
set(LLAMA_BUILD_TOOLS    OFF CACHE BOOL "llama: build tools"          FORCE)
set(LLAMA_BUILD_SERVER   OFF CACHE BOOL "llama: build server example" FORCE)
set(LLAMA_BUILD_EXAMPLES OFF CACHE BOOL "llama: build examples"       FORCE)

################## ggml settings ###############################
set(BLA_VENDOR "OpenBLAS" CACHE STRING "BLAS Vendor" FORCE)
set(GGML_BLAS_VENDOR "OpenBLAS" CACHE STRING "BLAS Vendor" FORCE)
set(GGML_CPU     ON CACHE BOOL "ggml: enable CPU backend" FORCE)
set(GGML_CPU_REPACK ON CACHE BOOL "ggml: use runtime weight conversion of Q4_0 to Q4_X_X" FORCE)
set(GGML_NATIVE OFF CACHE BOOL "llama: disable -march=native flag" FORCE)
set(GGML_CPU_ALL_VARIANTS OFF CACHE BOOL "ggml: build all variants of the CPU backend (requires GGML_BACKEND_DL)" FORCE)
set(GGML_VULKAN ON CACHE BOOL "llama: enable vulkan" FORCE)
set(GGML_AVX    ON CACHE BOOL "ggml: enable AVX" FORCE)
set(GGML_AVX2   ON CACHE BOOL "ggml: enable AVX2" FORCE)
set(GGML_FMA   ON CACHE BOOL "ggml: enable FMA" FORCE)
set(GGML_F16C  ON CACHE BOOL "ggml: enable F16C" FORCE)
set(GGML_BLAS ON CACHE BOOL "ggml: use BLAS" FORCE)
set(GGML_OPENCL OFF CACHE BOOL "ggml: use OpenCL" FORCE)
set(GGML_LLAMAFILE OFF CACHE BOOL "ggml: use LLAMAFILE" FORCE)
set(GGML_KOMPUTE  OFF CACHE BOOL "ggml: use Kompute" FORCE)
set(GGML_CUDA  OFF CACHE BOOL "ggml: use CUDA" FORCE)
set(GGML_OPENMP ON CACHE BOOL "ggml: use OpenMP" FORCE)

set(GGML_BUILD_TESTS    OFF CACHE BOOL "ggml: build tests"    FORCE)
set(GGML_BUILD_EXAMPLES OFF CACHE BOOL "ggml: build examples" FORCE)

FetchContent_Populate(llama_cpp )

file(REAL_PATH ${llama_cpp_SOURCE_DIR} LLAMA_CPP_SOURCE_DIR)

file(REAL_PATH ${llama_cpp_BINARY_DIR} LLAMA_CPP_BINARY_DIR)

set(LLAMA_INCLUDE_DIR ${LLAMA_CPP_SOURCE_DIR}/include CACHE PATH "llama include dir" FORCE)
set(LLAMA_COMMON_INCLUDE_DIR ${LLAMA_CPP_SOURCE_DIR}/common CACHE PATH "llama common include dir" FORCE)
set(GGML_INCLUDE_DIR ${LLAMA_CPP_SOURCE_DIR}/ggml/include CACHE PATH "ggml include dir" FORCE)

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

file(TO_NATIVE_PATH ${Vulkan_LIBRARY} LLAMA_VULKAN_LIBRARY)
file(TO_NATIVE_PATH ${BLAS_LIBRARIES} LLAMA_BLAS_LIBRARY)
set(LLAMA_INSTALL_DIR ${CMAKE_CURRENT_BINARY_DIR}/lc/ins CACHE PATH "llama install dir" FORCE)
set(LLAMA_BUILD_DIR ${CMAKE_CURRENT_BINARY_DIR}/lc/bld CACHE PATH "llama build dir" FORCE)
set(LLGUIDANCE_DIR ${LLAMA_BUILD_DIR}/llguidance CACHE PATH "llguidance dir" FORCE)

file(TO_NATIVE_PATH ${OPENBLAS_BINARY_DIR} LLAMA_OPENBLAS_BINARY_DIR)

file(TO_NATIVE_PATH ${LLAMA_INSTALL_DIR} LLAMA_CPP_INSTALL_DIR)
file(TO_NATIVE_PATH ${LLAMA_BUILD_DIR} LLAMA_CPP_BUILD_DIR)
file(TO_NATIVE_PATH ${LLAMA_INSTALL_DIR}/bin LLAMA_CPP_BIN_DIR)
file(TO_NATIVE_PATH ${LLAMA_INSTALL_DIR}/lib LLAMA_CPP_LIB_DIR)
file(TO_NATIVE_PATH ${LLAMA_INSTALL_DIR}/bin/llama.dll LLAMA_BINARY)
file(TO_NATIVE_PATH ${LLAMA_INSTALL_DIR}/bin/ggml.dll GGML_BINARY)
file(TO_NATIVE_PATH ${LLAMA_INSTALL_DIR}/bin/ggml-base.dll GGML_BASE_BINARY)
file(TO_NATIVE_PATH ${LLAMA_INSTALL_DIR}/bin/ggml-cpu.dll GGML_CPU_BINARY)
file(TO_NATIVE_PATH ${LLAMA_INSTALL_DIR}/bin/ggml-blas.dll GGML_BLAS_BINARY)
file(TO_NATIVE_PATH ${LLAMA_INSTALL_DIR}/bin/ggml-vulkan.dll GGML_VULKAN_BINARY)
file(TO_NATIVE_PATH ${LLAMA_BUILD_DIR}/llguidance/source/target/release/llguidance.dll LLGUIDANCE_BINARY)

set(LLAMA_BINPATH ${LLAMA_INSTALL_DIR}/bin/llama.dll)
set(GGML_BINPATH ${LLAMA_INSTALL_DIR}/bin/ggml.dll)
set(GGML_BASE_BINPATH ${LLAMA_INSTALL_DIR}/bin/ggml-base.dll)
set(GGML_CPU_BINPATH ${LLAMA_INSTALL_DIR}/bin/ggml-cpu.dll)
set(GGML_BLAS_BINPATH ${LLAMA_INSTALL_DIR}/bin/ggml-blas.dll)
set(GGML_VULKAN_BINPATH ${LLAMA_INSTALL_DIR}/bin/ggml-vulkan.dll)
set(LLGUIDANCE_BINPATH ${LLAMA_BUILD_DIR}/llguidance/source/target/release/llguidance.dll)

file(TO_NATIVE_PATH ${LLAMA_BUILD_DIR}/common/$<CONFIG>/common.lib LLAMA_BUILD_COMMON_IMPORTLIB)
file(TO_NATIVE_PATH ${LLAMA_INSTALL_DIR}/lib/common.lib LLAMA_COMMON_IMPORTLIB)
file(TO_NATIVE_PATH ${LLAMA_BUILD_DIR}/llguidance/source/target/release/llguidance.dll.lib LLGUIDANCE_IMPORTLIB)
file(TO_NATIVE_PATH ${LLAMA_INSTALL_DIR}/lib/llama.lib LLAMA_IMPORTLIB)
file(TO_NATIVE_PATH ${LLAMA_INSTALL_DIR}/lib/ggml.lib GGML_IMPORTLIB)
file(TO_NATIVE_PATH ${LLAMA_INSTALL_DIR}/lib/ggml-base.lib GGML_BASE_IMPORTLIB)
file(TO_NATIVE_PATH ${LLAMA_INSTALL_DIR}/lib/ggml-cpu.lib GGML_CPU_IMPORTLIB)
file(TO_NATIVE_PATH ${LLAMA_INSTALL_DIR}/lib/ggml-blas.lib GGML_BLAS_IMPORTLIB)
file(TO_NATIVE_PATH ${LLAMA_INSTALL_DIR}/lib/ggml-vulkan.lib GGML_VULKAN_IMPORTLIB)

set(LLAMA_COMMON_IMPORTLIBPATH ${LLAMA_INSTALL_DIR}/lib/common.lib)
set(LLGUIDANCE_IMPORTLIBPATH ${LLAMA_BUILD_DIR}/llguidance/source/target/release/llguidance.dll.lib)
set(LLAMA_IMPORTLIBPATH ${LLAMA_INSTALL_DIR}/lib/llama.lib)
set(GGML_IMPORTLIBPATH ${LLAMA_INSTALL_DIR}/lib/ggml.lib)
set(GGML_BASE_IMPORTLIBPATH ${LLAMA_INSTALL_DIR}/lib/ggml-base.lib)
set(GGML_CPU_IMPORTLIBPATH ${LLAMA_INSTALL_DIR}/lib/ggml-cpu.lib)
set(GGML_BLAS_IMPORTLIBPATH ${LLAMA_INSTALL_DIR}/lib/ggml-blas.lib)
set(GGML_VULKAN_IMPORTLIBPATH ${LLAMA_INSTALL_DIR}/lib/ggml-vulkan.lib)


add_custom_target(llama_build ALL COMMAND cmake${CMAKE_EXECUTABLE_SUFFIX} 
										-A x64,version=10.0.26100.0 -T v143,host=x64 
										-B ${LLAMA_BUILD_DIR} -G "Visual Studio 17 2022" 
										--install-prefix=${LLAMA_INSTALL_DIR} 
										-DCMAKE_BUILD_TYPE=$<CONFIG>
										-DBUILD_SHARED_LIBS=ON 
										-DCMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES=${LLAMA_OPENBLAS_BINARY_DIR}
										-DCMAKE_CXX_FLAGS="/DNOMINMAX" 
										-DCMAKE_C_FLAGS="/DNOMINMAX" 
										-DLLAMA_BUILD_TESTS=${LLAMA_BUILD_TESTS}
										-DLLAMA_BUILD_TOOLS=${LLAMA_BUILD_TOOLS}
										-DLLAMA_BUILD_EXAMPLES=${LLAMA_BUILD_EXAMPLES}
										-DLLAMA_BUILD_COMMON=${LLAMA_BUILD_COMMON}
										-DLLAMA_LLGUIDANCE=${LLAMA_LLGUIDANCE} 
										-DLLAMA_OPENSSL=${LLAMA_OPENSSL}
										-DLLAMA_TOOLS_INSTALL=${LLAMA_TOOLS_INSTALL} 
										-DLLAMA_BUILD_SERVER=${LLAMA_BUILD_SERVER} 
										-DLLAMA_CURL=${LLAMA_CURL} 
										-DGGML_NATIVE=${GGML_NATIVE} 
										-DGGML_AVX=${GGML_AVX} 
										-DGGML_AVX2=${GGML_AVX2} 
										-DGGML_FMA=${GGML_FMA} 
										-DGGML_F16C=${GGML_F16C} 
										-DGGML_CPU=${GGML_CPU} 
										-DGGML_CUDA=${GGML_CUDA}
										-DGGML_BLAS=${GGML_BLAS}
										-DGGML_OPENMP=${GGML_OPENMP} 
										-DGGML_VULKAN=${GGML_VULKAN} 
										-DGGML_CPU_ALL_VARIANTS=${GGML_CPU_ALL_VARIANTS} 
										-DGGML_LLAMAFILE=${GGML_LLAMAFILE} 
										-DGGML_KOMPUTE=${GGML_KOMPUTE} 
										-DGGML_BUILD_TESTS=${GGML_BUILD_TESTS}
										-DGGML_BUILD_EXAMPLES=${GGML_BUILD_EXAMPLES}
										-DVulkan_INCLUDE_DIR=${Vulkan_INCLUDE_DIR} 
										-DVulkan_LIBRARY=${Vulkan_LIBRARY} 
										-DBLA_VENDOR="OpenBLAS" -DGGML_BLAS_VENDOR="OpenBLAS" 
										-DBLAS_LIBRARIES=${BLAS_LIBRARIES} 
										-DBLAS_INCLUDE_DIRS=${OPENBLAS_INCLUDE_DIR}

				  COMMAND cd ${LLAMA_CPP_BUILD_DIR} && msbuild llama.cpp.sln /p:Configuration=$<CONFIG> && msbuild INSTALL.vcxproj /p:Configuration=$<CONFIG> && ${COPYCMD} ${LLAMA_BUILD_COMMON_IMPORTLIB} ${LLAMA_CPP_LIB_DIR}

				  BYPRODUCTS ${LLAMA_BINARY}
							 ${GGML_BINARY}
							 ${GGML_BASE_BINARY}
							 ${GGML_CPU_BINARY}
							 ${GGML_BLAS_BINARY}
							 ${GGML_VULKAN_BINARY}
							 ${LLAMA_COMMON_IMPORTLIB}
							 ${LLAMA_IMPORTLIB}
							 ${GGML_IMPORTLIB}
							 ${GGML_BASE_IMPORTLIB}
							 ${GGML_CPU_IMPORTLIB}
							 ${GGML_BLAS_IMPORTLIB}
							 ${GGML_VULKAN_IMPORTLIB}
				  WORKING_DIRECTORY ${LLAMA_CPP_SOURCE_DIR}
				  COMMAND_EXPAND_LISTS
				  VERBATIM
				  USES_TERMINAL)

add_dependencies(llama_build Vulkan-Headers vulkan openblas_shared)

add_library(ggml-base SHARED IMPORTED GLOBAL)
add_dependencies(ggml-base llama_build)
set_target_properties(ggml-base

                       PROPERTIES
					   IMPORTED_LOCATION ${GGML_BASE_BINPATH}
					   IMPORTED_IMPLIB ${GGML_BASE_IMPORTLIBPATH}
					   INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${GGML_INCLUDE_DIR}>
					   )
if (CMAKE_BUILD_TYPE STREQUAL "Debug")
	set_target_properties(ggml-base PROPERTIES 
				PDB_OUTPUT_DIRECTORY $<INSTALL_INTERFACE:${LLAMA_BUILD_DIR}/bin/$<CONFIG>>
				)
endif()

add_library(ggml SHARED IMPORTED GLOBAL)
add_dependencies(ggml llama_build ggml-base)
set_target_properties(ggml

                       PROPERTIES
					   IMPORTED_LOCATION ${GGML_BINPATH}
					   IMPORTED_IMPLIB ${GGML_IMPORTLIBPATH}
					   INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${GGML_INCLUDE_DIR}>
					   )
if (MSVC)
	set_target_properties(ggml PROPERTIES 
				PDB_OUTPUT_DIRECTORY $<INSTALL_INTERFACE:${LLAMA_BUILD_DIR}/bin/$<CONFIG>>
				)
endif()

add_library(ggml-cpu SHARED IMPORTED GLOBAL)
add_dependencies(ggml-cpu llama_build ggml ggml-base)
set_target_properties(ggml-cpu

                       PROPERTIES
					   IMPORTED_LOCATION ${GGML_CPU_BINPATH}
					   IMPORTED_IMPLIB ${GGML_CPU_IMPORTLIBPATH}
					   INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${GGML_INCLUDE_DIR}>
					   )
if (MSVC)
	set_target_properties(ggml-cpu PROPERTIES 
				PDB_OUTPUT_DIRECTORY $<INSTALL_INTERFACE:${LLAMA_BUILD_DIR}/bin/$<CONFIG>>
				)
endif()

add_library(ggml-blas SHARED IMPORTED GLOBAL)
add_dependencies(ggml-blas llama_build ggml ggml-base openblas_shared)
set_target_properties(ggml-blas

                       PROPERTIES
					   IMPORTED_LOCATION ${GGML_BLAS_BINPATH}
					   IMPORTED_IMPLIB ${GGML_BLAS_IMPORTLIBPATH}
					   INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${GGML_INCLUDE_DIR}>
					   )
if (MSVC)
	set_target_properties(ggml-blas PROPERTIES 
				PDB_OUTPUT_DIRECTORY $<INSTALL_INTERFACE:${LLAMA_BUILD_DIR}/bin/$<CONFIG>>
				)
endif()

add_library(ggml-vulkan SHARED IMPORTED GLOBAL)
add_dependencies(ggml-vulkan llama_build ggml ggml-base vulkan)
set_target_properties(ggml-vulkan

                       PROPERTIES
					   IMPORTED_LOCATION ${GGML_VULKAN_BINPATH}
					   IMPORTED_IMPLIB ${GGML_VULKAN_IMPORTLIBPATH}
					   INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${LLAMA_INSTALL_DIR}>
					   )
if (MSVC)
	set_target_properties(ggml-vulkan PROPERTIES 
				PDB_OUTPUT_DIRECTORY $<INSTALL_INTERFACE:${LLAMA_BUILD_DIR}/bin/$<CONFIG>>
				)
endif()

add_library(llama SHARED IMPORTED GLOBAL)
add_dependencies(llama llama_build ggml ggml-base ggml-cpu)
set_target_properties(llama

                       PROPERTIES
					   IMPORTED_LOCATION ${LLAMA_BINPATH}
					   IMPORTED_IMPLIB ${LLAMA_IMPORTLIBPATH}
					   INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${LLAMA_INCLUDE_DIR}>
					   )
if (MSVC)
	set_target_properties(llama PROPERTIES 
				PDB_OUTPUT_DIRECTORY $<INSTALL_INTERFACE:${LLAMA_BUILD_DIR}/bin/$<CONFIG>>
				)
endif()

add_library(llguidance SHARED IMPORTED GLOBAL)
add_dependencies(llguidance llama_build)
set_target_properties(llguidance

                       PROPERTIES
					   IMPORTED_LOCATION ${LLGUIDANCE_BINPATH}
					   IMPORTED_IMPLIB ${LLGUIDANCE_IMPORTLIBPATH}
					   # INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${LLGUIDANCE_DIR}>
					   )


add_library(common STATIC IMPORTED GLOBAL)
add_dependencies(common llama_build ggml ggml-base llguidance)
set_target_properties(common
                       PROPERTIES
					   IMPORTED_LOCATION ${LLAMA_COMMON_IMPORTLIBPATH}
					   IMPORTED_IMPLIB ${LLAMA_COMMON_IMPORTLIBPATH}
					   INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${LLAMA_COMMON_INCLUDE_DIR}>
					   )
if (MSVC)
	set_target_properties(llama PROPERTIES 
				PDB_OUTPUT_DIRECTORY $<INSTALL_INTERFACE:${LLAMA_BUILD_DIR}/common/$<CONFIG>>
				)
endif()

add_subdirectory("${LLAMACPP_SRC_DIR}" "${CMAKE_CURRENT_BINARY_DIR}/shared")

				   
set(llamacpp_bundled_libraries
	$<TARGET_FILE:llamacpp>
	$<TARGET_FILE:llama>
	$<TARGET_FILE:llguidance>
	$<TARGET_FILE:ggml-vulkan>
	$<TARGET_FILE:ggml-blas>
	$<TARGET_FILE:ggml-cpu>
	$<TARGET_FILE:ggml-base>
	$<TARGET_FILE:ggml>
	$<TARGET_FILE:vulkan>
	$<TARGET_FILE:openblas_shared>  
    PARENT_SCOPE
)