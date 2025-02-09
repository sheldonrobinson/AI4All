cmake_minimum_required(VERSION 3.22)

# Project-level configuration.
set(PROJECT_NAME "llamacpp")
project(${PROJECT_NAME} LANGUAGES CXX C)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_POLICY_VERSION_MINIMUM 3.5 PARENT_SCOPE)

if(NOT DEFINED CMAKE_INSTALL_PREFIX)
	set(CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_BINARY_DIR}" CACHE PATH "Needed to avoid cmake_install.cmake build issues." FORCE)
endif()

if (UNIX AND NOT WIN32 AND NOT APPLE)
	if (CMAKE_SIZEOF_VOID_P MATCHES "8")
		set (LIB_POSTFIX "64" CACHE STRING "suffix for 32/64 dir placement")
		mark_as_advanced (LIB_POSTFIX)
	endif ()
endif ()

if (NOT DEFINED LIB_POSTFIX)
  set (LIB_POSTFIX "")
endif ()

include(FetchContent)

find_package(Vulkan REQUIRED COMPONENTS glslc)
find_package(OpenMP REQUIRED)


set(CMAKE_BUILD_RPATH_USE_ORIGIN TRUE)
set(LLAMACPP_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../src)


# Set CMake flags
add_compile_options(-DBUILD_COMMIT=unknown -DBUILD_COMPILER=unknown -DBUILD_TARGET=Android -fvisibility=default -mbranch-protection=standard)
add_link_options("-Wl,-z,max-page-size=16384")
add_link_options("LINKER:--hash-style=gnu,--build-id=none")


if(CMAKE_BUILD_TYPE STREQUAL "Debug")
	message("Adding DEBUG compile option")
	add_compile_options(-DDEBUG -D_DEBUG)
endif()

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
  GIT_TAG        vulkan-sdk-1.4.328.1 # vulkan-sdk-1.3.296.0 # 

  GIT_SHALLOW    TRUE
  
  EXCLUDE_FROM_ALL
  
  OVERRIDE_FIND_PACKAGE
)

FetchContent_Declare(
  vulkan-headers
  GIT_REPOSITORY https://github.com/KhronosGroup/Vulkan-Headers.git
  GIT_TAG        vulkan-sdk-1.4.328.1 # vulkan-sdk-1.3.296.0 # 
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

##########################  kleidiai
set(KLEIDIAI_BUILD_TESTS       OFF CACHE BOOL "Build unit tests."             FORCE)
set(KLEIDIAI_BUILD_BENCHMARK   OFF CACHE BOOL "Build the benchmark tool."     FORCE)
set(KLEIDIAI_ENABLE_CLANG_TIDY OFF CACHE BOOL "Build with Clang-Tidy checks." FORCE)


FetchContent_Declare(
  kleidiai
  GIT_REPOSITORY https://git.gitlab.arm.com/kleidi/kleidiai.git
  GIT_TAG        v1.11.0 # release-1.10.0
  GIT_SHALLOW    TRUE
  
  EXCLUDE_FROM_ALL
  
  CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE=ON
             -DKLEIDIAI_BUILD_TESTS=OFF
             -DKLEIDIAI_BUILD_BENCHMARK=OFF
			 -DKLEIDIAI_ENABLE_CLANG_TIDY=OFF
			 -DBUILD_SHARED_LIBS=ON
)


FetchContent_MakeAvailable(kleidiai)

# Set the linker flags for shared libraries
set(LLAMA_BUILD_COMMON ON CACHE BOOL "llama: build common utils library" FORCE)
set(LLAMA_CURL         OFF CACHE BOOL "llama: use libcurl to download model from an URL" FORCE)
set(LLAMA_LLGUIDANCE   OFF CACHE BOOL "llama-common: include LLGuidance library for structured output in common utils" FORCE)
# set(GGML_CPU_ARM_ARCH  "armv8-a" CACHE STRING "ggml: CPU architecture for ARM" FORCE)
set(GGML_AVX    OFF CACHE BOOL "ggml: enable AVX" FORCE)
set(GGML_AVX2   OFF CACHE BOOL "ggml: enable AVX2" FORCE)
set(GGML_FMA    OFF CACHE BOOL "ggml: enable FMA" FORCE)
set(GGML_F16C   OFF CACHE BOOL "ggml: enable F16C" FORCE)
set(GGML_NATIVE        OFF CACHE BOOL "ggml: optimize the build for the current system" FORCE)
set(GGML_CPU ON CACHE BOOL "ggml: enable CPU backend" FORCE)
set(GGML_CPU_REPACK    ON CACHE BOOL "ggml: use runtime weight conversion of Q4_0 to Q4_X_X" FORCE)
set(GGML_CPU_KLEIDIAI  ON CACHE BOOL "ggml: use KleidiAI optimized kernels if applicable" FORCE)
set(GGML_OPENMP        ON CACHE BOOL "ggml: use OpenMP" FORCE)
set(GGML_OPENCL        OFF CACHE BOOL "ggml: use OpenCL" FORCE)
set(GGML_VULKAN        ON CACHE BOOL "llama: enable vulkan" FORCE)
set(GGML_BLAS          OFF CACHE BOOL "ggml: use BLAS" FORCE)
set(GGML_LLAMAFILE     OFF CACHE BOOL "ggml: use LLAMAFILE" FORCE)
set(GGML_KOMPUTE       OFF CACHE BOOL "ggml: use Kompute" FORCE)
set(GGML_CUDA          OFF CACHE BOOL "ggml: use CUDA" FORCE)

FetchContent_Declare(
  llama_cpp
  GIT_REPOSITORY https://github.com/ggml-org/llama.cpp.git
  GIT_TAG        4a4f426944e79b79e389f9ed7b34831cb9b637ad # release-1.10.0
  GIT_SHALLOW    TRUE
  
  EXCLUDE_FROM_ALL
  
  CMAKE_ARGS -DCMAKE_POSITION_INDEPENDENT_CODE=ON
             -DBUILD_SHARED_LIBS=ON
             -DLLAMA_BUILD_COMMON=ON
			 -DLLAMA_CURL=OFF
			 -DLLAMA_LLGUIDANCE=OFF
			 -DGGML_CPU=ON
			 -DGGML_CPU_REPACK=ON
			 -DGGML_NATIVE=OFF
			 -DGGML_VULKAN=ON
			 -DGGML_AVX=OFF
			 -DGGML_AVX2=OFF
			 -DGGML_FMA=OFF
			 -DGGML_F16C=OFF
			 -DGGML_CPU_KLEIDIAI=ON
			 -DGGML_LLAMAFILE=OFF
			 -DGGML_KOMPUTE=OFF
			 -DGGML_CUDA=OFF
			 -DGGML_BLAS=OFF
			 -DGGML_OPENMP=ON
)

FetchContent_MakeAvailable(llama_cpp)

add_dependencies(ggml-vulkan Vulkan::Headers)

add_subdirectory("${LLAMACPP_SRC_DIR}" "${CMAKE_BINARY_DIR}/shared")

set(llamacpp_bundled_libraries
  $<TARGET_FILE:llamacpp>
  $<TARGET_FILE:llama>
  $<TARGET_FILE:ggml-vulkan>
  $<TARGET_FILE:ggml-cpu>
  $<TARGET_FILE:ggml-base>
  $<TARGET_FILE:ggml>
#  PARENT_SCOPE
)
