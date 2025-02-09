# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "llamacpp")
project(${PROJECT_NAME} LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT DEFINED CMAKE_INSTALL_PREFIX)
 	set(CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_BINARY_DIR}" CACHE PATH "Needed to avoid cmake_install.cmake build issues." FORCE) 
# 	if(NOT DEFINED CMAKE_INSTALL_BINDIR)
# 		set(CMAKE_INSTALL_BINDIR ${CMAKE_BINARY_DIR}/runner/$<CONFIG>)
# 	endif()
endif()

find_package(OpenMP REQUIRED)

set(CMAKE_BUILD_RPATH_USE_ORIGIN TRUE)
set(LLAMACPP_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../src)

if(MSVC)
	set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)
endif()

set(BUILD_SHARED_LIBS ON)
# set(CMAKE_INSTALL_LIBDIR lib CACHE PATH "library install dir" FORCE)

################## cpuinfo settings ###############################
set(CPUINFO_LOG_LEVEL "none" CACHE STRING "Minimum logging level (info with lower severity will be ignored)" FORCE)
set(CPUINFO_LOG_TO_STDIO OFF CACHE BOOL "Log errors, warnings, and information to stdout/stderr" FORCE)
set(CPUINFO_LIBRARY_TYPE "shared" CACHE STRING "Type of cpuinfo library (shared, static, or default) to build" FORCE)
set(CPUINFO_BUILD_TOOLS OFF CACHE BOOL "Build command-line tools" FORCE)
set(CPUINFO_BUILD_UNIT_TESTS OFF CACHE BOOL "Build cpuinfo unit tests" FORCE)
set(CPUINFO_BUILD_MOCK_TESTS OFF CACHE BOOL "Build cpuinfo mock tests" FORCE)
set(CPUINFO_BUILD_BENCHMARKS OFF CACHE BOOL "Build cpuinfo micro-benchmarks" FORCE)
set(CPUINFO_BUILD_PKG_CONFIG OFF CACHE BOOL "Build pkg-config manifest" FORCE)

add_subdirectory("${LLAMACPP_SRC_DIR}/cpuinfo" "${CMAKE_CURRENT_BINARY_DIR}/cpuinfo" EXCLUDE_FROM_ALL)
include_directories("${LLAMACPP_SRC_DIR}/cpuinfo/include")


# Set the linker flags for shared libraries
set(LLAMA_BUILD_COMMON ON CACHE BOOL "llama: build common utils library" FORCE)
set(LLAMA_CURL OFF CACHE BOOL "llama: use libcurl to download model from an URL" FORCE)
set(LLAMA_LLGUIDANCE ON CACHE BOOL "llama-common: include LLGuidance library for structured output in common utils" FORCE)

################## ggml settings ###############################
set(GGML_CPU     ON CACHE BOOL "ggml: enable CPU backend"                        FORCE)
set(GGML_CPU_REPACK ON CACHE BOOL "ggml: use runtime weight conversion of Q4_0 to Q4_X_X" FORCE)
set(GGML_NATIVE OFF CACHE BOOL "llama: disable -march=native flag" FORCE)
set(GGML_VULKAN ON CACHE BOOL "llama: enable vulkan" FORCE)
set(GGML_AVX    ON CACHE BOOL "ggml: enable AVX" FORCE)
set(GGML_AVX2   ON CACHE BOOL "ggml: enable AVX2" FORCE)
set(GGML_FMA   ON CACHE BOOL "ggml: enable FMA" FORCE)
set(GGML_F16C  ON CACHE BOOL "ggml: enable F16C" FORCE)
set(GGML_LLAMAFILE OFF CACHE BOOL "ggml: use LLAMAFILE" FORCE)
set(GGML_KOMPUTE  OFF CACHE BOOL "ggml: use Kompute" FORCE)
set(GGML_CUDA  OFF CACHE BOOL "ggml: use CUDA" FORCE)
set(GGML_OPENMP ON CACHE BOOL "ggml: use OpenMP" FORCE)

# set(Vulkan_GLSLC_EXECUTABLE "glslc" CACHE STRING "File path or command to run glslc" FORCE)
# set(VULKAN_SHADERS_GEN_EXECUTABLE "vulkan-shaders-gen" CACHE STRING "File path or command to run vulkan-shaders-gen" FORCE)

#################### Vulkan
set(VULKAN_HEADERS_ENABLE_TESTS OFF CACHE BOOL "Test Vulkan-Headers" FORCE)
set(VULKAN_HEADERS_ENABLE_INSTALL OFF CACHE BOOL "Install Vulkan-Headers" FORCE)
add_subdirectory("${LLAMACPP_SRC_DIR}/Vulkan-Headers" "${CMAKE_CURRENT_BINARY_DIR}/vkheaders" EXCLUDE_FROM_ALL)

set(BUILD_TESTS OFF CACHE BOOL "Build Tests" FORCE)
add_subdirectory("${LLAMACPP_SRC_DIR}/Vulkan-Loader" "${CMAKE_CURRENT_BINARY_DIR}/vkloader" EXCLUDE_FROM_ALL)
add_dependencies(vulkan Vulkan-Headers)

add_subdirectory("${LLAMACPP_SRC_DIR}/lcpp" "${CMAKE_CURRENT_BINARY_DIR}/llama" EXCLUDE_FROM_ALL)
add_dependencies(ggml-vulkan vulkan)

add_subdirectory("${LLAMACPP_SRC_DIR}" "${CMAKE_CURRENT_BINARY_DIR}/shared")

				   
set(MSVCP_BINPATH "${CMAKE_CURRENT_SOURCE_DIR}/MSVCRT/Binaries/msvcp140$<$<CONFIG:Debug>:d>.dll")
set(MSVCP_1_BINPATH "${CMAKE_CURRENT_SOURCE_DIR}/MSVCRT/Binaries/msvcp140_1$<$<CONFIG:Debug>:d>.dll")
set(MSVCRT_BINPATH "${CMAKE_CURRENT_SOURCE_DIR}/MSVCRT/Binaries/vcruntime140$<$<CONFIG:Debug>:d>.dll")
set(MSVCRT_1_BINPATH "${CMAKE_CURRENT_SOURCE_DIR}/MSVCRT/Binaries/vcruntime140_1$<$<CONFIG:Debug>:d>.dll")
set(CONCRT_BINPATH "${CMAKE_CURRENT_SOURCE_DIR}/MSVCRT/Binaries/concrt140$<$<CONFIG:Debug>:d>.dll")
set(MSVCP_2_BINPATH "${CMAKE_CURRENT_SOURCE_DIR}/MSVCRT/Binaries/msvcp140_2$<$<CONFIG:Debug>:d>.dll")
set(MSVCP_ATOMIC_WAIT_BINPATH "${CMAKE_CURRENT_SOURCE_DIR}/MSVCRT/Binaries/msvcp140$<$<CONFIG:Debug>:d>_atomic_wait.dll")
set(MSVCP_CODECVT_IDS_BINPATH "${CMAKE_CURRENT_SOURCE_DIR}/MSVCRT/Binaries/msvcp140$<$<CONFIG:Debug>:d>_codecvt_ids.dll")
set(VCCORLIB_BINPATH "${CMAKE_CURRENT_SOURCE_DIR}/MSVCRT/Binaries/vccorlib140$<$<CONFIG:Debug>:d>.dll")
set(MSVCRT_THREADS_BINPATH "${CMAKE_CURRENT_SOURCE_DIR}/MSVCRT/Binaries/vcruntime140_threads$<$<CONFIG:Debug>:d>.dll")
set(VCAMP_BINPATH "${CMAKE_CURRENT_SOURCE_DIR}/MSVCRT/Binaries/vcamp140$<$<CONFIG:Debug>:d>.dll")
set(VCOMP_BINPATH "${CMAKE_CURRENT_SOURCE_DIR}/MSVCRT/Binaries/vcomp140$<$<CONFIG:Debug>:d>.dll")



set(WINRT_CONS10 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-core-console-l1-1-0.dll)
set(WINRT_CONS20 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-core-console-l1-2-0.dll)
set(WINRT_DT10 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-core-datetime-l1-1-0.dll)
set(WINRT_DBG10 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-core-debug-l1-1-0.dll)
set(WINRT_ERRHND10 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-core-errorhandling-l1-1-0.dll)
set(WINRT_FIB10 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-core-fibers-l1-1-0.dll)
set(WINRT_FIB11 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-core-fibers-l1-1-1.dll)
set(WINRT_FILE110 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-core-file-l1-1-0.dll)
set(WINRT_FILE120 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-core-file-l1-2-0.dll)
set(WINRT_FILE210 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-core-file-l2-1-0.dll)
set(WINRT_HND10 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-core-handle-l1-1-0.dll)
set(WINRT_HEAP10 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-core-heap-l1-1-0.dll)
set(WINRT_ILOCK10 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-core-interlocked-l1-1-0.dll)
set(WINRT_KERNL10 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-core-kernel32-legacy-l1-1-1.dll)
set(WINRT_LIBLD10 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-core-libraryloader-l1-1-0.dll)
set(WINRT_L18N20 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-core-localization-l1-2-0.dll)
set(WINRT_MEM10 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-core-memory-l1-1-0.dll)
set(WINRT_NAMP10 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-core-namedpipe-l1-1-0.dll)
set(WINRT_PROENV10 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-core-processenvironment-l1-1-0.dll)
set(WINRT_PROCTHR10 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-core-processthreads-l1-1-0.dll)
set(WINRT_PROC11 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-core-processthreads-l1-1-1.dll)
set(WINRT_PROF10 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-core-profile-l1-1-0.dll)
set(WINRT_RTL10 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-core-rtlsupport-l1-1-0.dll)
set(WINRT_STR10 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-core-string-l1-1-0.dll)
set(WINRT_SYN10 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-core-synch-l1-1-0.dll)
set(WINRT_SYN20 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-core-synch-l1-2-0.dll)
set(WINRT_SYSINF10 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-core-sysinfo-l1-1-0.dll)
set(WINRT_SYSINF20 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-core-sysinfo-l1-2-0.dll)
set(WINRT_TZ10 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-core-timezone-l1-1-0.dll)
set(WINRT_UTIL10 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-core-util-l1-1-0.dll)
set(WINRT_CONIO10 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-crt-conio-l1-1-0.dll)
set(WINRT_CONV10 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-crt-convert-l1-1-0.dll)
set(WINRT_ENV10 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-crt-environment-l1-1-0.dll)
set(WINRT_FS10 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-crt-filesystem-l1-1-0.dll)
set(WINRT_HEAP11 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-crt-heap-l1-1-0.dll)
set(WINRT_LCL10 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-crt-locale-l1-1-0.dll)
set(WINRT_MATH10 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-crt-math-l1-1-0.dll)
set(WINRT_MBS10 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-crt-multibyte-l1-1-0.dll)
set(WINRT_PRIV10 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-crt-private-l1-1-0.dll)
set(WINRT_PROC10 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-crt-process-l1-1-0.dll)
set(WINRT_RT10 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-crt-runtime-l1-1-0.dll)
set(WINRT_STDIO10 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-crt-stdio-l1-1-0.dll)
set(WINRT_STRN10 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-crt-string-l1-1-0.dll)
set(WINRT_TM10 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-crt-time-l1-1-0.dll)
set(WINRT_UT10 ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/api-ms-win-crt-utility-l1-1-0.dll)
set(WINRT_BASE ${CMAKE_CURRENT_SOURCE_DIR}/WINRT/ucrtbase.dll)


# target_compile_definitions(llamacpp PUBLIC DART_SHARED_LIB)

set(llamacpp_bundled_libraries
	$<TARGET_FILE:llamacpp>
	$<TARGET_FILE:llama>
	$<TARGET_FILE:ggml-vulkan>
	$<TARGET_FILE:ggml-cpu>
	$<TARGET_FILE:ggml-base>
	$<TARGET_FILE:ggml>
	$<TARGET_FILE:cpuinfo>
	$<TARGET_FILE:vulkan>
	${MSVCP_BINPATH}
	${MSVCP_1_BINPATH}
	${MSVCRT_BINPATH}
	${MSVCRT_1_BINPATH}
	${CONCRT_BINPATH}
	${MSVCP_2_BINPATH}
	${MSVCP_ATOMIC_WAIT_BINPATH}
	${MSVCP_CODECVT_IDS_BINPATH}
	${VCCORLIB_BINPATH}
	${MSVCRT_THREADS_BINPATH}
	${VCAMP_BINPATH}
	${VCOMP_BINPATH}
	${WINRT_CONS10}
	${WINRT_CONS20}
	${WINRT_DT10}
	${WINRT_DBG10}
	${WINRT_ERRHND10}
	${WINRT_FIB10}
	${WINRT_FIB11}
	${WINRT_FILE110}
	${WINRT_FILE120}
	${WINRT_FILE210}
	${WINRT_HND10}
	${WINRT_HEAP10}
	${WINRT_ILOCK10}
	${WINRT_KERNL10}
	${WINRT_LIBLD10}
	${WINRT_L18N20}
	${WINRT_MEM10}
	${WINRT_NAMP10}
	${WINRT_PROENV10}
	${WINRT_PROCTHR10}
	${WINRT_PROC11}
	${WINRT_PROF10}
	${WINRT_RTL10}
	${WINRT_STR10}
	${WINRT_SYN10}
	${WINRT_SYN20}
	${WINRT_SYSINF10}
	${WINRT_SYSINF20}
	${WINRT_TZ10}
	${WINRT_UTIL10}
	${WINRT_CONIO10}
	${WINRT_CONV10}
	${WINRT_ENV10}
	${WINRT_FS10}
	${WINRT_HEAP11}
	${WINRT_LCL10}
	${WINRT_MATH10}
	${WINRT_MBS10}
	${WINRT_PRIV10}
	${WINRT_PROC10}
	${WINRT_RT10}
	${WINRT_STDIO10}
	${WINRT_STRN10}
	${WINRT_TM10}
	${WINRT_UT10}
  
  PARENT_SCOPE
)
