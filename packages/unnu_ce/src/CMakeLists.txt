# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.26)

project(unnu_ce VERSION 0.0.1 LANGUAGES CXX C)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_C_STANDARD_REQUIRED ON)

if(NOT DEFINED CMAKE_INSTALL_PREFIX)
	set(CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_BINARY_DIR}" CACHE PATH "Needed to avoid cmake_install.cmake build issues." FORCE) 
	# set(CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_BINARY_DIR}" PARENT_SCOPE)
	if(NOT DEFINED CMAKE_INSTALL_BINDIR)
		set(CMAKE_INSTALL_BINDIR ${CMAKE_BINARY_DIR}/runner/$<CONFIG>)
		# set(CMAKE_INSTALL_BINDIR ${CMAKE_BINARY_DIR}/bin/$<CONFIG> PARENT_SCOPE)
	endif()
endif()

################## abseil
set(BUILD_SHARED_LIBS ON)
set(ABSL_BUILD_TESTING OFF CACHE BOOL "If ON, Abseil will build all of Abseil's own tests." FORCE)
set(ABSL_BUILD_TEST_HELPERS OFF CACHE BOOL "If ON, Abseil will build libraries that you can use to write tests against Abseil code. This option requires that Abseil is configured to use GoogleTest." FORCE)
set(ABSL_USE_EXTERNAL_GOOGLETEST OFF CACHE BOOL "If ON, Abseil will assume that the targets for GoogleTest are already provided by the including project. This makes sense when Abseil is used with add_subdirectory." FORCE)
set(ABSL_FIND_GOOGLETEST OFF CACHE BOOL "If ON, Abseil will use find_package(GTest) rather than assuming that GoogleTest is already provided by the including project." FORCE)
set(ABSL_USE_GOOGLETEST_HEAD OFF CACHE BOOL "If ON, abseil will download HEAD from GoogleTest at config time." FORCE)
set(ABSL_BUILD_MONOLITHIC_SHARED_LIBS ON CACHE BOOL "Build Abseil as a single shared library (always enabled for Windows)" FORCE)
set(ABSL_ENABLE_INSTALL OFF)
set(ABSL_BUILD_DLL ON)
# add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/abseil" "${CMAKE_CURRENT_BINARY_DIR}/abseil" EXCLUDE_FROM_ALL)

################## re2
set(RE2_USE_ICU OFF CACHE BOOL "build against ICU for full Unicode properties support" FORCE)
set(USEPCRE OFF CACHE BOOL "build against PCRE for testing and benchmarking" FORCE)
set(RE2_BUILD_TESTING OFF CACHE BOOL "enable testing for RE2" FORCE)
# add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/re2" "${CMAKE_CURRENT_BINARY_DIR}/re2" EXCLUDE_FROM_ALL)

################## jsoncpp
set(JSONCPP_WITH_TESTS OFF CACHE BOOL "Compile and (for jsoncpp_check) run JsonCpp test executables" FORCE)
set(JSONCPP_WITH_POST_BUILD_UNITTEST OFF CACHE BOOL "Automatically run unit-tests as a post build step" FORCE)
set(JSONCPP_WITH_WARNING_AS_ERROR OFF CACHE BOOL "Force compilation to fail if a warning occurs" FORCE)
set(JSONCPP_WITH_STRICT_ISO ON CACHE BOOL "Issue all the warnings demanded by strict ISO C and ISO C++" FORCE)
set(JSONCPP_WITH_PKGCONFIG_SUPPORT OFF CACHE BOOL "Generate and install .pc files" FORCE)
set(JSONCPP_WITH_CMAKE_PACKAGE OFF CACHE BOOL "Generate and install cmake package files" FORCE)
set(JSONCPP_WITH_EXAMPLE OFF CACHE BOOL "Compile JsonCpp example" FORCE)
set(JSONCPP_STATIC_WINDOWS_RUNTIME OFF CACHE BOOL "Use static (MT/MTd) Windows runtime" FORCE)
set(BUILD_OBJECT_LIBS ON CACHE BOOL "Build jsoncpp_lib as a object library." FORCE)
# add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/jsoncpp" "${CMAKE_CURRENT_BINARY_DIR}/jsoncpp" EXCLUDE_FROM_ALL)

################## armadillo
set(HEADER_ONLY ON CACHE BOOL "Do not generate the wrapper library" FORCE)
set(STATIC_LIB ON CACHE BOOL "Generate static library instead of shared library" FORCE)
set(OPENBLAS_PROVIDES_LAPACK ON CACHE BOOL "Assume that OpenBLAS provides LAPACK functions" FORCE)
set(BUILD_SMOKE_TEST OFF CACHE BOOL "Build the smoke test" FORCE)
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/armadillo" "${CMAKE_CURRENT_BINARY_DIR}/arma" EXCLUDE_FROM_ALL)

######################### cpuinfo
set(CPUINFO_LOG_LEVEL "fatal" CACHE STRING "Minimum logging level (info with lower severity will be ignored)" FORCE)
# set(CPUINFO_LOG_TO_STDIO OFF CACHE BOOL "Log errors, warnings, and information to stdout/stderr" FORCE)
set(CPUINFO_LIBRARY_TYPE "static" CACHE STRING "Type of cpuinfo library (shared, static, or default) to build" FORCE)
set(CPUINFO_BUILD_TOOLS OFF CACHE BOOL "Build command-line tools" FORCE)
set(CPUINFO_BUILD_UNIT_TESTS OFF CACHE BOOL "Build cpuinfo unit tests" FORCE)
set(CPUINFO_BUILD_MOCK_TESTS OFF CACHE BOOL "Build cpuinfo mock tests" FORCE)
set(CPUINFO_BUILD_BENCHMARKS OFF CACHE BOOL "Build cpuinfo micro-benchmarks" FORCE)
set(CPUINFO_BUILD_PKG_CONFIG OFF CACHE BOOL "Build pkg-config manifest" FORCE)
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/cpuinfo" "${CMAKE_CURRENT_BINARY_DIR}/cpuinfo" EXCLUDE_FROM_ALL)

####################### tokenizers
set(MSGPACK_CXX17 ON CACHE BOOL "Using c++17 compiler" FORCE)
set(MSGPACK_CXX17 ON  PARENT_SCOPE)
set(MSGPACK_USE_BOOST OFF CACHE BOOL "Use Boost libraried" FORCE)
set(MSGPACK_USE_BOOST OFF PARENT_SCOPE)
set(MSGPACK_BUILD_DOCS OFF CACHE BOOL "Build Doxygen documentation" FORCE)
set(SPM_ENABLE_SHARED ON CACHE BOOL "Builds shared libaries in addition to static libraries." FORCE)
set(SPM_ENABLE_SHARED ON PARENT_SCOPE)
set(SPM_ENABLE_MSVC_MT_BUILD OFF CACHE BOOL "Use /MT flag in MSVC build" FORCE)
set(SPM_ENABLE_MSVC_MT_BUILD OFF PARENT_SCOPE)
set(MLC_ENABLE_SENTENCEPIECE_TOKENIZER ON CACHE BOOL "Enable SentencePiece tokenizer" FORCE)
set(MLC_ENABLE_SENTENCEPIECE_TOKENIZER ON PARENT_SCOPE)
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/tokenizers" "${CMAKE_CURRENT_BINARY_DIR}/tokenizers" EXCLUDE_FROM_ALL)

set(BUILD_SHARED_LIBS ON)
##################### Soar
set(SVS ON CACHE BOOL "SVS Enabled" FORCE)
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/Soar" "${CMAKE_CURRENT_BINARY_DIR}/Soar" EXCLUDE_FROM_ALL)

####################### slm-engine
set(slmengine_srcs 
		ortgenai/examples/slm_engine/src/cpp/slm_engine.cpp
		ortgenai/examples/slm_engine/src/cpp/input_decoder.cpp)

add_library(
    slmengine_objs
    OBJECT
    ${slmengine_srcs}
)

set_target_properties(slmengine_objs PROPERTIES POSITION_INDEPENDENT_CODE True)

target_compile_definitions(slmengine_objs PRIVATE 
		SW_VERSION_NUMBER="1.0.0" 
		ORT_GENAI_VERSION="0.9.0-dev"
		BUILDING_SLM_ENGINE)

target_include_directories(slmengine_objs PRIVATE 
		$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/json/single_include>
		$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/ortgenai/src>
		$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/ort/headers>
		$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/ortgenai/examples/slm_engine/src/cpp>)



add_library(unnu_ce SHARED
  "unnu_ce.cxx"
)

set_target_properties(unnu_ce PROPERTIES
  PUBLIC_HEADER unnu_ce.h
  OUTPUT_NAME "unnu_ce"
  CXX_STANDARD 17
)

find_package(Threads REQUIRED)

# find_package(Eigen3 REQUIRED)

target_include_directories(unnu_ce PRIVATE
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/cpuinfo/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/uuid4/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/armadillo/include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/tokenizers/include>
#  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/jsoncpp/include>
#  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/re2/re2>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/ortgenai/src>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/json/single_include>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/ortgenai/examples/slm_engine/src/cpp>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/ort/headers>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/Soar/Core/CLI/src>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/Soar/Core/ClientSML/src>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/Soar/Core/ConnectionSML/src>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/Soar/Core/ElementXML/src>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/Soar/Core/KernelSML/src>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/Soar/Core/SVS/src>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/Soar/Core/SoarKernel/src/debug_code>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/Soar/Core/SoarKernel/src/decision_process>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/Soar/Core/SoarKernel/src/episodic_memory>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/Soar/Core/SoarKernel/src/explanation_based_chunking>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/Soar/Core/SoarKernel/src/explanation_memory>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/Soar/Core/SoarKernel/src/interface>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/Soar/Core/SoarKernel/src/output_manager>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/Soar/Core/SoarKernel/src/parsing>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/Soar/Core/SoarKernel/src/reinforcement_learning>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/Soar/Core/SoarKernel/src/semantic_memory>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/Soar/Core/SoarKernel/src/shared>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/Soar/Core/SoarKernel/src/soar_representation>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/Soar/Core/SoarKernel/src/visualizer>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/Soar/Core/shared>
)

target_link_directories(unnu_ce PRIVATE 
			${CMAKE_CURRENT_BINARY_DIR}/cpuinfo/$<CONFIG>
			${CMAKE_CURRENT_BINARY_DIR}/Soar/$<CONFIG>
			)

# target_include_directories(unnu_ce PRIVATE ${SOAR_INCLUDE_DIR})

target_compile_definitions(unnu_ce PUBLIC DART_SHARED_LIB)

# target_link_libraries(unnu_ce soar::soar)

set(UNNU_LIB_DEPS sentencepiece-static soar_lib cpuinfo onnxruntime onnxruntime-genai $<TARGET_OBJECTS:slmengine_objs> tokenizers_cpp)

if(ANDROID)
target_link_libraries(unnu_ce PRIVATE ${UNNU_LIB_DEPS} log Threads::Threads)
else()
target_link_libraries(unnu_ce PRIVATE ${UNNU_LIB_DEPS} Threads::Threads)
endif()

if (ANDROID)
  # Support Android 15 16k page size
  target_link_options(unnu_ce PRIVATE "-Wl,-z,max-page-size=16384")
endif()
