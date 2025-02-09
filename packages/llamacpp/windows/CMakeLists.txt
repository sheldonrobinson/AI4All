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

######################## llama.cpp
FetchContent_Declare(
  llama_cpp
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/llama.cpp.git #https://github.com/ggml-org/llama.cpp.git
  GIT_TAG        		 origin/master #b7248
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE

)


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


#################### OpenCL
FetchContent_Declare(
  opencl-headers
  GIT_REPOSITORY 		 https://github.com/KhronosGroup/OpenCL-Headers.git
  GIT_TAG        		 v2025.07.22
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL
  
  OVERRIDE_FIND_PACKAGE
)

FetchContent_Declare(
  opencl-icd-loader
  GIT_REPOSITORY 		 https://github.com/KhronosGroup/OpenCL-ICD-Loader.git
  GIT_TAG        		 v2025.07.22
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL
  
  OVERRIDE_FIND_PACKAGE
)

set(OPENCL_HEADERS_BUILD_CXX_TESTS OFF CACHE BOOL "Enable support for OpenCL C headers testing in C++ mode." FORCE)
set(OPENCL_ICD_LOADER_BUILD_SHARED_LIBS ON CACHE BOOL "Build OpenCL ICD Loader as shared library" FORCE)
set(ENABLE_OPENCL_LAYERS ON CACHE BOOL "Enable OpenCL Layers" FORCE)
set(ENABLE_OPENCL_LOADER_MANAGED_DISPATCH ON CACHE BOOL "Enable OpenCL Loader managed dispatch" FORCE)

FetchContent_MakeAvailable(opencl-headers)
file(REAL_PATH ${opencl-headers_SOURCE_DIR} OPENCL_HEADERS_DIR)
set(OPENCL_INCLUDE_DIR ${OPENCL_HEADERS_DIR} CACHE PATH "OpenCL header dir" FORCE)

if(NOT TARGET OpenCL::Headers)
	add_library(OpenCL::Headers INTERFACE IMPORTED)
    set_target_properties(OpenCL::Headers PROPERTIES
                          INTERFACE_LINK_LIBRARIES Headers							  
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						  )
endif()

if(NOT TARGET OpenCLHeaders)
	add_library(OpenCLHeaders INTERFACE IMPORTED)
    set_target_properties(OpenCLHeaders PROPERTIES
                          INTERFACE_LINK_LIBRARIES Headers							  
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						  )
endif()

FetchContent_MakeAvailable(opencl-icd-loader opencl-headers)
file(REAL_PATH ${opencl-icd-loader_BINARY_DIR} OPENCL_ICD_LOADER_BUILD_DIR)
set(OPENCL_LIBRARY ${OPENCL_ICD_LOADER_BUILD_DIR}/$<CONFIG>/OpenCL.lib CACHE FILEPATH "opencl-icd-loader import library" FORCE)
set(OPENCL_BINPATH ${OPENCL_ICD_LOADER_BUILD_DIR}/$<CONFIG>/OpenCL.dll CACHE FILEPATH "opencl-icd-loader library" FORCE)

if(NOT TARGET OpenCL::OpenCL)
	add_library(OpenCL::OpenCL INTERFACE IMPORTED)
    set_target_properties(OpenCL::OpenCL PROPERTIES
                          INTERFACE_LINK_LIBRARIES OpenCL							  
						  INTERFACE_POSITION_INDEPENDENT_CODE ON
						  )
endif()



#################### infoware
FetchContent_Declare(
  infoware
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/infoware.git
  GIT_TAG        		 origin/main
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL
  			 
  OVERRIDE_FIND_PACKAGE
)

####################
FetchContent_Declare(
  pciids
  GIT_REPOSITORY 		 https://github.com/sheldonrobinson/pciids.git
  GIT_TAG        		 origin/master
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL
  
  OVERRIDE_FIND_PACKAGE
)

FetchContent_MakeAvailable(pciids)

file(REAL_PATH ${pciids_SOURCE_DIR} PCI_IDS_SOURCE_DIR)



#################### infoware cont
set(INFOWARE_USE_VULKAN OFF CACHE BOOL "Add public, transitive define to infoware to use Vulkan for GPU detection."                         FORCE)
set(INFOWARE_USE_D3D    ON CACHE BOOL "Add public, transitive define to infoware to use Direct 3D for GPU detection."                       FORCE)
set(INFOWARE_USE_OPENGL OFF CACHE BOOL "Add public, transitive define to infoware to use Open Graphics Language (OpenGL) for GPU detection." FORCE)
set(INFOWARE_USE_OPENCL OFF CACHE BOOL "Add public, transitive define to infoware to use Open Compute Language (OpenCL) for GPU detection."  FORCE)
set(INFOWARE_USE_X11 OFF CACHE BOOL "Add public, transitive define to infoware to use X11 for display detection." FORCE)
set(INFOWARE_USE_PCIIDS ON CACHE BOOL "Want PCI IDs. If disabled, the PCI ID database will not be compiled, and the pci.hpp API will be unimplemented." FORCE)
set(INFOWARE_EXAMPLES OFF CACHE BOOL "Add infoware examples to the build." FORCE)
set(INFOWARE_TESTS    OFF CACHE BOOL "Input tests for infoware."           FORCE)
set(INFOWARE_INSTALL  OFF CACHE BOOL "Install libraries and binaries."     FORCE)
set(INFOWARE_PCI_IDS_PATH       ${PCI_IDS_SOURCE_DIR}/pci.ids CACHE FILEPATH "pci.ids file to use. Overrides cloning from INFOWARE_PCI_IDS_REPOSITORY." FORCE)
set(INFOWARE_PCI_IDS_REPOSITORY "https://github.com/sheldonrobinson/pciids" CACHE STRING   "Path/URL to clone a pciids git repository from if override path not supplied. Defaults to https://github.com/pciutils/pciids." FORCE)

FetchContent_MakeAvailable(infoware pciids)

file(REAL_PATH ${infoware_BINARY_DIR} INFOWARE_BUILD_DIR)
set(INFOWARE_BINARY_DLL ${INFOWARE_BUILD_DIR}/lib/$<CONFIG>/infoware$<$<CONFIG:Debug>:d>.dll CACHE FILEPATH "infoware build as dll" FORCE)

#################### Vulkan
FetchContent_Declare(
  vulkan
  GIT_REPOSITORY 		 https://github.com/KhronosGroup/Vulkan-Loader.git
  GIT_TAG        		 vulkan-sdk-1.4.328.1
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
  EXCLUDE_FROM_ALL
  
  OVERRIDE_FIND_PACKAGE
)

FetchContent_Declare(
  vulkan-headers
  GIT_REPOSITORY 		 https://github.com/KhronosGroup/Vulkan-Headers.git
  GIT_TAG        		 vulkan-sdk-1.4.328.1
  GIT_SHALLOW 			 TRUE
  GIT_SUBMODULES_RECURSE TRUE
  
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

if (MSVC)
	set_target_properties(Vulkan::Vulkan PROPERTIES 
				PDB_OUTPUT_DIRECTORY $<INSTALL_INTERFACE:${VULKAN_LOADER_BUILD_DIR}/loader/$<CONFIG>>
				)
endif()

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


######################## llama.cpp cont

# Set the linker flags for shared libraries
set(LLAMA_BUILD_COMMON ON CACHE BOOL "llama: build common utils library" FORCE)
set(LLAMA_CURL OFF CACHE BOOL "llama: use libcurl to download model from an URL" FORCE)
set(LLAMA_LLGUIDANCE ON CACHE BOOL "llama-common: include LLGuidance library for structured output in common utils" FORCE)
set(LLAMA_OPENSSL OFF CACHE BOOL "llama: use openssl to support HTTPS" FORCE)
set(LLAMA_HTTPLIB OFF CACHE BOOL "llama: if libcurl is disabled, use httplib to download model from an URL" FORCE)
set(LLAMA_TOOLS_INSTALL OFF CACHE BOOL "llama: install tools" FORCE)
set(LLAMA_BUILD_TESTS    OFF CACHE BOOL "llama: build tests"          FORCE)
set(LLAMA_BUILD_TOOLS    OFF CACHE BOOL "llama: build tools"          FORCE)
set(LLAMA_BUILD_SERVER   OFF CACHE BOOL "llama: build server example" FORCE)
set(LLAMA_BUILD_EXAMPLES OFF CACHE BOOL "llama: build examples"       FORCE)

################## ggml settings ###############################
set(BLA_VENDOR "OpenBLAS" CACHE STRING "BLAS Vendor" FORCE)
set(GGML_BACKEND_DL ON CACHE BOOL "ggml: build backends as dynamic libraries (requires BUILD_SHARED_LIBS)" FORCE)
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
set(GGML_OPENCL ON CACHE BOOL "ggml: use OpenCL" FORCE)
set(GGML_OPENCL_EMBED_KERNELS ON CACHE BOOL "ggml: embed kernels" FORCE)
set(GGML_LLAMAFILE OFF CACHE BOOL "ggml: use LLAMAFILE" FORCE)
set(GGML_KOMPUTE OFF CACHE BOOL "ggml: use Kompute" FORCE)
set(GGML_CUDA ON CACHE BOOL "ggml: use CUDA" FORCE)
set(GGML_CUDA_FA ON CACHE BOOL "ggml: compile ggml FlashAttention CUDA kernels" FORCE)
set(GGML_HIP OFF CACHE BOOL "ggml: use HIP" FORCE)
set(GGML_HIP_MMQ_MFMA ON CACHE BOOL "ggml: enable MFMA MMA for CDNA in MMQ" FORCE)
set(GGML_OPENMP ON CACHE BOOL "ggml: use OpenMP" FORCE)
if ( (CMAKE_CXX_COMPILER_ARCHITECTURE_ID STREQUAL "ARM64") OR  (CMAKE_CXX_COMPILER_ARCHITECTURE_ID STREQUAL "arm64") )
	set(GGML_OPENCL_USE_ADRENO_KERNELS ON CACHE BOOL "ggml: use optimized kernels for Adreno" FORCE)
else()
	set(GGML_OPENCL_USE_ADRENO_KERNELS OFF CACHE BOOL "ggml: use optimized kernels for Adreno" FORCE)
endif()

file(REAL_PATH $ENV{HIP_PATH} HIP_PATH_STRING)

list(APPEND HIP_PREFIX_PATH "${HIP_PATH_STRING}" ${CMAKE_PREFIX_PATH})
list(APPEND HIP_MODULE_PATH "${HIP_PATH_STRING}/lib/cmake" ${CMAKE_MODULE_PATH})
list(APPEND NV_CUDA_ARCHS 50 52 61 70 75 80 86 89 120)
list(APPEND AMD_HIP_ARCHS gfx801 gfx802 gfx803 gfx805 gfx810 gfx9-generic gfx9-4-generic gfx950 gfx10-1-generic gfx10-3-generic gfx11-generic gfx12-generic)
set(HIP_CXX_COMPILER "hipcc"  CACHE STRING "HIPCC Compiler" FORCE)
set(HIP_C_COMPILER "clang"  CACHE STRING "HIP Compiler" FORCE)
set(HIP_CLANG_PATH "${HIP_PATH_STRING}/bin"  CACHE PATH "HIP Clang Path" FORCE)
set(HIP_PLATFORM "amd" CACHE STRING "HIP platform as computed by hipconfig" FORCE)
set(CMAKE_HIP_PLATFORM ${HIP_PLATFORM} CACHE STRING "Target HIP Platform" FORCE)
set(GPU_TARGETS ${AMD_HIP_ARCHS} CACHE INTERNAL "Semicolon delimited flags for AMD HIP Architectures" FORCE)
set(CMAKE_HIP_ARCHITECTURES ${AMD_HIP_ARCHS} CACHE INTERNAL "Semicolon delimited flags for AMD HIP Architectures" FORCE)
set(HIP_ARCHITECTURES ${AMD_HIP_ARCHS} CACHE INTERNAL "Semicolon delimited flags for AMD HIP Architectures" FORCE)
set(CMAKE_CUDA_ARCHITECTURES ${NV_CUDA_ARCHS} CACHE INTERNAL "Semicolon delimited flags for NVIDIA CUDA Architectures" FORCE)
set(CUDA_ARCHITECTURES ${NV_CUDA_ARCHS} CACHE INTERNAL "Semicolon delimited flags for NVIDIA CUDA Architectures" FORCE)

set(CLANGRT_BUILTINS_INCLUDE_DIR "${HIP_PATH_STRING}/clang/20/include" CACHE PATH "ClangRT library" FORCE)
set(CLANGRT_BUILTINS_LIBRARY "${HIP_PATH_STRING}/clang/20/lib/windows/clang_rt.builtins-x86_64.lib" CACHE PATH "ClangRT library" FORCE)
list(APPEND HIP_INCLUDE_DIRECTORIES "${HIP_PATH_STRING}/include" ${CLANGRT_BUILTINS_INCLUDE_DIR})

set(hip_DIR "${HIP_PATH_STRING}/lib/cmake/hip" CACHE PATH "hip package configuration files" FORCE)

set(hip_INCLUDE_DIR "${HIP_PATH_STRING}/include" CACHE PATH "hip package include" FORCE)
set(hip_INCLUDE_DIRS ${HIP_INCLUDE_DIRECTORIES} CACHE STRING "hip package include" FORCE)
list(APPEND hip_LIBRARIES "${HIP_PATH_STRING}/lib/amdhip64.lib" ${CLANGRT_BUILTINS_LIBRARY})
set(hip_LIBRARY  ${hip_LIBRARIES} CACHE PATH "hip libraries" FORCE)

set(hipblas_DIR "${HIP_PATH_STRING}/lib/cmake/hipblas" CACHE PATH "hipblas package configuration files" FORCE)
set(hipblas_INCLUDE_DIR "${HIP_PATH_STRING}/include" CACHE PATH "hipblas package include" FORCE)
set(hipblas_LIBRARY "${HIP_PATH_STRING}/lib/hipblas.lib" CACHE PATH "hipblas library" FORCE)

set(rocblas_DIR "${HIP_PATH_STRING}/lib/cmake/rocblas" CACHE PATH "rocblas package configuration files" FORCE)
set(rocblas_INCLUDE_DIR "${HIP_PATH_STRING}/include" CACHE PATH "rocblas package include" FORCE)
set(rocblas_LIBRARY "${HIP_PATH_STRING}/lib/rocblas.lib" CACHE PATH "rocblas library" FORCE)

set(hipblas-common_DIR "${HIP_PATH_STRING}/lib/cmake/hipblas-common" CACHE PATH "hipblas-common package configuration files" FORCE)
set(hipblas-common_INCLUDE_DIR "${HIP_PATH_STRING}/include" CACHE PATH "hipblas-common package include" FORCE)

set(GGML_BUILD_TESTS    OFF CACHE BOOL "ggml: build tests"    FORCE)
set(GGML_BUILD_EXAMPLES OFF CACHE BOOL "ggml: build examples" FORCE)

FetchContent_Populate(llama_cpp)

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

file(TO_NATIVE_PATH ${LLAMA_INSTALL_DIR} LLAMA_CPP_INSTALL_DIR)
file(TO_NATIVE_PATH ${LLAMA_BUILD_DIR} LLAMA_CPP_BUILD_DIR)
file(TO_NATIVE_PATH ${LLAMA_INSTALL_DIR}/bin LLAMA_CPP_BIN_DIR)
file(TO_NATIVE_PATH ${LLAMA_INSTALL_DIR}/lib LLAMA_CPP_LIB_DIR)
file(TO_NATIVE_PATH ${LLAMA_INSTALL_DIR}/bin/llama.dll LLAMA_BINARY)
file(TO_NATIVE_PATH ${LLAMA_INSTALL_DIR}/bin/ggml.dll GGML_BINARY)
file(TO_NATIVE_PATH ${LLAMA_INSTALL_DIR}/bin/ggml-base.dll GGML_BASE_BINARY)
file(TO_NATIVE_PATH ${LLAMA_INSTALL_DIR}/bin/ggml-cpu.dll GGML_CPU_BINARY)
file(TO_NATIVE_PATH ${LLAMA_INSTALL_DIR}/bin/ggml-blas.dll GGML_BLAS_BINARY)
file(TO_NATIVE_PATH ${LLAMA_INSTALL_DIR}/bin/ggml-opencl.dll GGML_OPENCL_BINARY)
file(TO_NATIVE_PATH ${LLAMA_INSTALL_DIR}/bin/ggml-vulkan.dll GGML_VULKAN_BINARY)
file(TO_NATIVE_PATH ${LLAMA_INSTALL_DIR}/bin/ggml-hip.dll GGML_HIP_BINARY)
file(TO_NATIVE_PATH ${LLAMA_INSTALL_DIR}/bin/ggml-cuda.dll GGML_CUDA_BINARY)
file(TO_NATIVE_PATH ${LLAMA_BUILD_DIR}/llguidance/source/target/release/llguidance.dll LLGUIDANCE_BINARY)

set(LLAMA_BINPATH ${LLAMA_INSTALL_DIR}/bin/llama.dll)
set(GGML_BINPATH ${LLAMA_INSTALL_DIR}/bin/ggml.dll)
set(GGML_BASE_BINPATH ${LLAMA_INSTALL_DIR}/bin/ggml-base.dll)
set(GGML_CPU_BINPATH ${LLAMA_INSTALL_DIR}/bin/ggml-cpu.dll)
set(GGML_BLAS_BINPATH ${LLAMA_INSTALL_DIR}/bin/ggml-blas.dll)
set(GGML_OPENCL_BINPATH ${LLAMA_INSTALL_DIR}/bin/ggml-opencl.dll)
set(GGML_VULKAN_BINPATH ${LLAMA_INSTALL_DIR}/bin/ggml-vulkan.dll)
set(GGML_HIP_BINPATH ${LLAMA_INSTALL_DIR}/bin/ggml-hip.dll)
set(GGML_CUDA_BINPATH ${LLAMA_INSTALL_DIR}/bin/ggml-cuda.dll)
set(LLGUIDANCE_BINPATH ${LLAMA_BUILD_DIR}/llguidance/source/target/release/llguidance.dll)

file(TO_NATIVE_PATH ${LLAMA_BUILD_DIR}/common/$<CONFIG>/common.lib LLAMA_BUILD_COMMON_IMPORTLIB)
file(TO_NATIVE_PATH ${LLAMA_INSTALL_DIR}/lib/common.lib LLAMA_COMMON_IMPORTLIB)
file(TO_NATIVE_PATH ${LLAMA_BUILD_DIR}/llguidance/source/target/release/llguidance.dll.lib LLGUIDANCE_IMPORTLIB)
file(TO_NATIVE_PATH ${LLAMA_INSTALL_DIR}/lib/llama.lib LLAMA_IMPORTLIB)
file(TO_NATIVE_PATH ${LLAMA_INSTALL_DIR}/lib/ggml.lib GGML_IMPORTLIB)
file(TO_NATIVE_PATH ${LLAMA_INSTALL_DIR}/lib/ggml-base.lib GGML_BASE_IMPORTLIB)

#### BACKEND_DL= FALSE
# file(TO_NATIVE_PATH ${LLAMA_INSTALL_DIR}/lib/ggml-cpu.lib GGML_CPU_IMPORTLIB)
# file(TO_NATIVE_PATH ${LLAMA_INSTALL_DIR}/lib/ggml-blas.lib GGML_BLAS_IMPORTLIB)
# file(TO_NATIVE_PATH ${LLAMA_INSTALL_DIR}/lib/ggml-opencl.lib GGML_OPENCL_IMPORTLIB)
# file(TO_NATIVE_PATH ${LLAMA_INSTALL_DIR}/lib/ggml-vulkan.lib GGML_VULKAN_IMPORTLIB)
# file(TO_NATIVE_PATH ${LLAMA_INSTALL_DIR}/lib/ggml-hip.lib GGML_HIP_IMPORTLIB)
# file(TO_NATIVE_PATH ${LLAMA_INSTALL_DIR}/lib/ggml-cuda.lib GGML_CUDA_IMPORTLIB)

#### BACKEND_DL=TRUE
file(TO_NATIVE_PATH ${LLAMA_BUILD_DIR}/ggml/src/$<CONFIG>/ggml-cpu.lib GGML_CPU_IMPORTLIB)
file(TO_NATIVE_PATH ${LLAMA_BUILD_DIR}/ggml/src/ggml-blas/$<CONFIG>/ggml-blas.lib GGML_BLAS_IMPORTLIB)
file(TO_NATIVE_PATH ${LLAMA_BUILD_DIR}/ggml/src/ggml-opencl/$<CONFIG>/ggml-opencl.lib GGML_OPENCL_IMPORTLIB)
file(TO_NATIVE_PATH ${LLAMA_BUILD_DIR}/ggml/src/ggml-vulkan/$<CONFIG>/ggml-vulkan.lib GGML_VULKAN_IMPORTLIB)
file(TO_NATIVE_PATH ${LLAMA_BUILD_DIR}/ggml/src/ggml-hip/$<CONFIG>/ggml-hip.lib GGML_HIP_IMPORTLIB)
file(TO_NATIVE_PATH ${LLAMA_BUILD_DIR}/ggml/src/ggml-cuda/$<CONFIG>/ggml-cuda.lib GGML_CUDA_IMPORTLIB)

set(LLAMA_COMMON_IMPORTLIBPATH ${LLAMA_INSTALL_DIR}/lib/common.lib)
set(LLGUIDANCE_IMPORTLIBPATH ${LLAMA_BUILD_DIR}/llguidance/source/target/release/llguidance.dll.lib)
set(LLAMA_IMPORTLIBPATH ${LLAMA_INSTALL_DIR}/lib/llama.lib)
set(GGML_IMPORTLIBPATH ${LLAMA_INSTALL_DIR}/lib/ggml.lib)
set(GGML_BASE_IMPORTLIBPATH ${LLAMA_INSTALL_DIR}/lib/ggml-base.lib)


#### BACKEND_DL=FALSE
# set(GGML_CPU_IMPORTLIBPATH ${LLAMA_INSTALL_DIR}/lib/ggml-cpu.lib)
# set(GGML_BLAS_IMPORTLIBPATH ${LLAMA_INSTALL_DIR}/lib/ggml-blas.lib)
# set(GGML_OPENCL_IMPORTLIBPATH ${LLAMA_INSTALL_DIR}/lib/ggml-opencl.lib)
# set(GGML_VULKAN_IMPORTLIBPATH ${LLAMA_INSTALL_DIR}/lib/ggml-vulkan.lib)
# set(GGML_HIP_IMPORTLIBPATH ${LLAMA_INSTALL_DIR}/lib/ggml-hip.lib)
# set(GGML_CUDA_IMPORTLIBPATH ${LLAMA_INSTALL_DIR}/lib/ggml-cuda.lib)

#### BACKEND_DL=FALSE
set(GGML_CPU_IMPORTLIBPATH ${LLAMA_BUILD_DIR}/ggml/src/$<CONFIG>/ggml-cpu.lib)
set(GGML_BLAS_IMPORTLIBPATH ${LLAMA_BUILD_DIR}/ggml/src/ggml-blas/$<CONFIG>/ggml-blas.lib)
set(GGML_OPENCL_IMPORTLIBPATH ${LLAMA_BUILD_DIR}/ggml/src/ggml-opencl/$<CONFIG>/ggml-opencl.lib)
set(GGML_VULKAN_IMPORTLIBPATH ${LLAMA_BUILD_DIR}/ggml/src/ggml-vulkan/$<CONFIG>/ggml-vulkan.lib)
set(GGML_HIP_IMPORTLIBPATH ${LLAMA_BUILD_DIR}/ggml/src/ggml-hip/$<CONFIG>/ggml-hip.lib)
set(GGML_CUDA_IMPORTLIBPATH ${LLAMA_BUILD_DIR}/ggml/src/ggml-cuda/$<CONFIG>/ggml-cuda.lib)

add_custom_target(llama_build ALL COMMAND cmake${CMAKE_EXECUTABLE_SUFFIX} 
										-B ${LLAMA_BUILD_DIR} -G "Visual Studio 17 2022" 
										--install-prefix=${LLAMA_INSTALL_DIR}
										-DCMAKE_BUILD_TYPE=$<CONFIG>
										-DBUILD_SHARED_LIBS=ON
										-DCMAKE_MODULE_PATH=${HIP_MODULE_PATH}
										-DCMAKE_PREFIX_PATH=${HIP_PREFIX_PATH}
										-DCMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES=${OPENBLAS_CONFIG_DIRPATH}
										-DCMAKE_C_STANDARD_INCLUDE_DIRECTORIES=${OPENBLAS_CONFIG_DIRPATH}
										-DCMAKE_CXX_FLAGS="/DNOMINMAX" 
										-DCMAKE_C_FLAGS="/DNOMINMAX"
										-DLLAMA_BUILD_TESTS=${LLAMA_BUILD_TESTS}
										-DLLAMA_BUILD_TOOLS=${LLAMA_BUILD_TOOLS}
										-DLLAMA_BUILD_EXAMPLES=${LLAMA_BUILD_EXAMPLES}
										-DLLAMA_BUILD_COMMON=${LLAMA_BUILD_COMMON}
										-DLLAMA_LLGUIDANCE=${LLAMA_LLGUIDANCE} 
										-DLLAMA_OPENSSL=${LLAMA_OPENSSL}
										-DLLAMA_HTTPLIB=${LLAMA_HTTPLIB}
										-DLLAMA_TOOLS_INSTALL=${LLAMA_TOOLS_INSTALL} 
										-DLLAMA_BUILD_SERVER=${LLAMA_BUILD_SERVER} 
										-DLLAMA_CURL=${LLAMA_CURL}
										-DGGML_BACKEND_DL=${GGML_BACKEND_DL}
										-DGGML_NATIVE=${GGML_NATIVE} 
										-DGGML_AVX=${GGML_AVX} 
										-DGGML_AVX2=${GGML_AVX2} 
										-DGGML_FMA=${GGML_FMA} 
										-DGGML_F16C=${GGML_F16C} 
										-DGGML_CPU=${GGML_CPU}
										-DGGML_CPU_ALL_VARIANTS=${GGML_CPU_ALL_VARIANTS} 
										-DGGML_CUDA=${GGML_CUDA}
										-DGGML_CUDA_FA=${GGML_CUDA_FA}
										-DGGML_HIP=${GGML_HIP}
										-DGGML_HIP_MMQ_MFMA=${GGML_HIP_MMQ_MFMA}
										-DGGML_VULKAN=${GGML_VULKAN}
										-DGGML_OPENCL=${GGML_OPENCL}
										-DGGML_OPENCL_EMBED_KERNELS=${GGML_OPENCL_EMBED_KERNELS}
										-DGGML_OPENCL_USE_ADRENO_KERNELS=${GGML_OPENCL_USE_ADRENO_KERNELS}
										-DGGML_BLAS=${GGML_BLAS}
										-DGGML_BLAS_VENDOR=${GGML_BLAS_VENDOR}
										-DGGML_OPENMP=${GGML_OPENMP}
										-DGGML_LLAMAFILE=${GGML_LLAMAFILE} 
										-DGGML_KOMPUTE=${GGML_KOMPUTE} 
										-DGGML_BUILD_TESTS=${GGML_BUILD_TESTS}
										-DGGML_BUILD_EXAMPLES=${GGML_BUILD_EXAMPLES}
										-DCMAKE_HIP_PLATFORM=${HIP_PLATFORM}
										-DHIP_PLATFORM=${HIP_PLATFORM}
										-DGPU_TARGETS=${AMD_HIP_ARCHS}
										-DCMAKE_HIP_ARCHITECTURES=${AMD_HIP_ARCHS}
										-DHIP_ARCHITECTURES=${AMD_HIP_ARCHS}
										-DCMAKE_CUDA_ARCHITECTURES=${NV_CUDA_ARCHS}
										-DCUDA_ARCHITECTURES=${NV_CUDA_ARCHS}
										-DVulkan_INCLUDE_DIR=${Vulkan_INCLUDE_DIR} 
										-DVulkan_LIBRARY=${Vulkan_LIBRARY} 
										-DBLA_VENDOR=${BLA_VENDOR}
										-DBLAS_LIBRARIES=${BLAS_LIBRARIES} 
										-DBLAS_INCLUDE_DIRS=${BLAS_INCLUDE_DIRS}
										-DOpenCL_INCLUDE_DIRS=${OPENCL_INCLUDE_DIR}
										-DOpenCL_LIBRARIES=${OPENCL_LIBRARY}
										-DHIP_CXX_COMPILER=${HIP_CXX_COMPILER}
										-DHIP_C_COMPILER=${HIP_C_COMPILER}
										-DHIP_CLANG_PATH=${HIP_CLANG_PATH}
										-DHIP_PATH=${HIP_PATH_STRING}
										-Dhip_DIR=${hip_DIR}
										-Dhip_INCLUDE_DIR=${hip_INCLUDE_DIRS}
										-DHIP_INCLUDE_DIR=${hip_INCLUDE_DIRS}
										-Dhip_INCLUDE_DIRS=${hip_INCLUDE_DIRS}
										-DHIP_INCLUDE_DIRS=${hip_INCLUDE_DIRS}
										-Dhip_LIBRARY=${hip_LIBRARY}
										-Dhipblas_DIR=${hipblas_DIR}
										-Dhipblas_INCLUDE_DIR=${hipblas_INCLUDE_DIR}
										-Dhipblas_LIBRARY=${hipblas_LIBRARY}
										-Drocblas_DIR=${rocblas_DIR}
										-Drocblas_INCLUDE_DIR=${rocblas_INCLUDE_DIR}
										-Drocblas_LIBRARY=${rocblas_LIBRARY}
										-Dhipblas-common_DIR=${hipblas-common_DIR}
										-Dhipblas-common_INCLUDE_DIR=${hipblas-common_INCLUDE_DIR}
										-Dhipblas-common_LIBRARY=""

				  COMMAND cd ${LLAMA_CPP_BUILD_DIR} && msbuild llama.cpp.sln /p:Configuration=$<CONFIG> && msbuild INSTALL.vcxproj /p:Configuration=$<CONFIG> && ${COPYCMD} ${LLAMA_BUILD_COMMON_IMPORTLIB} ${LLAMA_CPP_LIB_DIR}

				  BYPRODUCTS ${LLAMA_BINARY}
							 ${GGML_BINARY}
							 ${GGML_BASE_BINARY}
							 ${GGML_CPU_BINARY}
							 ${GGML_BLAS_BINARY}
							 ${GGML_OPENCL_BINARY}
							 ${GGML_VULKAN_BINARY}
							 # ${GGML_HIP_BINARY}
							 ${GGML_CUDA_BINARY}
							 ${LLAMA_COMMON_IMPORTLIB}
							 ${LLAMA_IMPORTLIB}
							 ${GGML_IMPORTLIB}
							 ${GGML_BASE_IMPORTLIB}
							 ${GGML_CPU_IMPORTLIB}
							 ${GGML_BLAS_IMPORTLIB}
							 ${GGML_OPENCL_IMPORTLIB}
							 ${GGML_VULKAN_IMPORTLIB}
							 # ${GGML_HIP_IMPORTLIB}
							 ${GGML_CUDA_IMPORTLIB}
				  WORKING_DIRECTORY ${LLAMA_CPP_SOURCE_DIR}
				  COMMAND_EXPAND_LISTS
				  VERBATIM
				  USES_TERMINAL)

add_dependencies(llama_build Vulkan-Headers vulkan openblas_shared OpenCL)

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
					   IMPORTED_IMPLIB ${GGML_CPU_IMPORTLIB} #${GGML_CPU_IMPORTLIBPATH}
					   INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${GGML_INCLUDE_DIR}>
					   )
if (MSVC)
	set_target_properties(ggml-cpu PROPERTIES 
				PDB_OUTPUT_DIRECTORY $<INSTALL_INTERFACE:${LLAMA_BUILD_DIR}/ggml/src/ggml-cpu/$<CONFIG>>
				)
endif()

add_library(ggml-blas SHARED IMPORTED GLOBAL)
add_dependencies(ggml-blas llama_build ggml ggml-base openblas_shared)
set_target_properties(ggml-blas

                       PROPERTIES
					   IMPORTED_LOCATION ${GGML_BLAS_BINPATH}
					   IMPORTED_IMPLIB ${GGML_BLAS_IMPORTLIB} #${GGML_BLAS_IMPORTLIBPATH}
					   INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${GGML_INCLUDE_DIR}>
					   )
if (MSVC)
	set_target_properties(ggml-blas PROPERTIES 
				PDB_OUTPUT_DIRECTORY $<INSTALL_INTERFACE:${LLAMA_BUILD_DIR}/ggml/src/ggml-blas/$<CONFIG>>
				)
endif()

add_library(ggml-opencl SHARED IMPORTED GLOBAL)
add_dependencies(ggml-opencl llama_build ggml ggml-base OpenCL)
set_target_properties(ggml-opencl

                       PROPERTIES
					   IMPORTED_LOCATION ${GGML_OPENCL_BINPATH}
					   IMPORTED_IMPLIB ${GGML_OPENCL_IMPORTLIB} #${GGML_OPENCL_IMPORTLIBPATH}
					   INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${LLAMA_INSTALL_DIR}>
					   )
if (MSVC)
	set_target_properties(ggml-opencl PROPERTIES 
				PDB_OUTPUT_DIRECTORY $<INSTALL_INTERFACE:${LLAMA_BUILD_DIR}/ggml/src/ggml-opencl/$<CONFIG>>
				)
endif()

add_library(ggml-vulkan SHARED IMPORTED GLOBAL)
add_dependencies(ggml-vulkan llama_build ggml ggml-base vulkan)
set_target_properties(ggml-vulkan

                       PROPERTIES
					   IMPORTED_LOCATION ${GGML_VULKAN_BINPATH}
					   IMPORTED_IMPLIB ${GGML_VULKAN_IMPORTLIB} #${GGML_VULKAN_IMPORTLIBPATH}
					   INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${LLAMA_INSTALL_DIR}>
					   )
if (MSVC)
	set_target_properties(ggml-vulkan PROPERTIES 
				PDB_OUTPUT_DIRECTORY $<INSTALL_INTERFACE:${LLAMA_BUILD_DIR}/ggml/src/ggml-vulkan/$<CONFIG>>
				)
endif()

# add_library(ggml-hip SHARED IMPORTED GLOBAL)
# add_dependencies(ggml-hip llama_build ggml ggml-base)
# set_target_properties(ggml-hip

                       # PROPERTIES
					   # IMPORTED_LOCATION ${GGML_HIP_BINPATH}
					   # IMPORTED_IMPLIB ${GGML_HIP_IMPORTLIB} #${GGML_HIP_IMPORTLIBPATH}
					   # INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${LLAMA_INSTALL_DIR}>
					   # )
# if (MSVC)
	# set_target_properties(ggml-hip PROPERTIES 
				# PDB_OUTPUT_DIRECTORY $<INSTALL_INTERFACE:${LLAMA_BUILD_DIR}/ggml/src/ggml-hip/$<CONFIG>>
				# )
# endif()

add_library(ggml-cuda SHARED IMPORTED GLOBAL)
add_dependencies(ggml-cuda llama_build ggml ggml-base)
set_target_properties(ggml-cuda
                       PROPERTIES
					   IMPORTED_LOCATION ${GGML_CUDA_BINPATH}
					   IMPORTED_IMPLIB ${GGML_CUDA_IMPORTLIB} #${GGML_CUDA_IMPORTLIBPATH}
					   INTERFACE_INCLUDE_DIRECTORIES $<BUILD_INTERFACE:${LLAMA_INSTALL_DIR}>
					   )
if (MSVC)
	set_target_properties(ggml-cuda PROPERTIES 
				PDB_OUTPUT_DIRECTORY $<INSTALL_INTERFACE:${LLAMA_BUILD_DIR}/ggml/src/ggml-cuda/$<CONFIG>>
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

include("${HIP_PATH_STRING}/cmake/FindHIP.cmake" RESULT_VARIABLE find_hip_cmake)

find_package(hip REQUIRED)
find_package(hipblas REQUIRED)
find_package(rocblas REQUIRED)

add_dependencies(ggml-opencl OpenCL)
add_dependencies(ggml-blas openblas_shared)
add_dependencies(ggml-vulkan vulkan)
# add_dependencies(ggml-hip hip::amdhip64 roc::hipblas-common roc::hipblas roc::rocblas)
add_dependencies(common llguidance)

add_subdirectory("${LLAMACPP_SRC_DIR}" "${CMAKE_CURRENT_BINARY_DIR}/shared")

				   
set(llamacpp_bundled_libraries
	$<TARGET_FILE:llamacpp>
	$<TARGET_FILE:llama>
	$<TARGET_FILE:llguidance>
	$<TARGET_FILE:ggml-cuda>
	# $<TARGET_FILE:ggml-hip>
	$<TARGET_FILE:ggml-vulkan>
	$<TARGET_FILE:ggml-opencl>
	$<TARGET_FILE:ggml-blas>
	$<TARGET_FILE:ggml-cpu>
	$<TARGET_FILE:ggml-base>
	$<TARGET_FILE:ggml>
	$<TARGET_FILE:vulkan>
	$<TARGET_FILE:OpenCL>
	$<TARGET_FILE:openblas_shared>  
    PARENT_SCOPE
)