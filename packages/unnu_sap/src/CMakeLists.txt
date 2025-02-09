# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(unnu_sap VERSION 0.0.1 LANGUAGES CXX C)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

cmake_policy(SET CMP0079 NEW)

if(NOT DEFINED CMAKE_INSTALL_PREFIX)
	set(CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_BINARY_DIR}" CACHE PATH "Needed to avoid cmake_install.cmake build issues." FORCE) 
	if(NOT DEFINED CMAKE_INSTALL_BINDIR)
		set(CMAKE_INSTALL_BINDIR ${CMAKE_BINARY_DIR}/runner/$<CONFIG>)
	endif()
endif()

find_package(OpenMP REQUIRED)
find_package(Threads REQUIRED)

include(gitversion/cmake.cmake)

################# libfvad
FetchContent_Declare(
  libfvad
  GIT_REPOSITORY https://github.com/dpirch/libfvad.git
  GIT_TAG        532ab666c20d3cfda38bca63abbb0f152706c369
  GIT_SHALLOW    TRUE
  
  EXCLUDE_FROM_ALL
)
set(ENABLE_EXAMPLES OFF CACHE BOOL "build the fvadwav example program; requires libsndfile" FORCE)
FetchContent_MakeAvailable(libfvad)

######################### miniaudio
# Options
add_library(osaudio STATIC 
 "${CMAKE_CURRENT_SOURCE_DIR}/ma/extras/osaudio/osaudio_miniaudio.c"
)

set_target_properties(osaudio PROPERTIES 
                              LINKER_LANGUAGE C
                              C_STANDARD 11
                              C_STANDARD_REQUIRED ON)

target_include_directories(osaudio PUBLIC
	"${CMAKE_CURRENT_SOURCE_DIR}/ma/extras/osaudio")
	
set_target_properties(osaudio PROPERTIES
  BUILD_WITH_INSTALL_RPATH TRUE
  PUBLIC_HEADER osaudio.h
  OUTPUT_NAME "osaudio"
  POSITION_INDEPENDENT_CODE True
 )

########################

add_library(unnu_asr SHARED
  "unnu_asr.cpp"
)

target_include_directories(unnu_asr INTERFACE 
		${CMAKE_CURRENT_SOURCE_DIR}
		PRIVATE
		$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/ma/extras/osaudio>)

# TARGET_GIT_VERSION_INIT(unnu_asr)

set_target_properties(unnu_asr PROPERTIES
  BUILD_WITH_INSTALL_RPATH TRUE
  LINKER_LANGUAGE CXX
  PUBLIC_HEADER unnu_asr.h
  OUTPUT_NAME "unnu_asr"
  POSITION_INDEPENDENT_CODE True
)

add_library(unnu_tts SHARED
   "unnu_tts.cc"
)

target_include_directories(unnu_tts INTERFACE 
		${CMAKE_CURRENT_SOURCE_DIR}
		PRIVATE
		$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/ma/extras/osaudio>)
		
# TARGET_GIT_VERSION_INIT(unnu_tts)

set_target_properties(unnu_tts PROPERTIES
  BUILD_WITH_INSTALL_RPATH TRUE
  LINKER_LANGUAGE CXX
  PUBLIC_HEADER unnu_tts.h
  OUTPUT_NAME "unnu_tts"
  POSITION_INDEPENDENT_CODE True
)

target_compile_definitions(unnu_asr PUBLIC DART_SHARED_LIB)
target_compile_definitions(unnu_tts PUBLIC DART_SHARED_LIB)

if(MSVC)
	set_property(TARGET unnu_asr PROPERTY
		MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
	set_property(TARGET unnu_tts PROPERTY
		MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
endif()

set(LIBRARY_DEPS osaudio sherpa-onnx-c-api)

if(ANDROID)
	target_link_libraries(unnu_asr PRIVATE log fvad ${LIBRARY_DEPS} Threads::Threads)
	target_link_libraries(unnu_tts PRIVATE log ${LIBRARY_DEPS} Threads::Threads)
else()
	target_link_libraries(unnu_asr PRIVATE fvad ${LIBRARY_DEPS} Threads::Threads)
	target_link_libraries(unnu_tts PRIVATE ${LIBRARY_DEPS} Threads::Threads)
endif()

if (ANDROID)
  # Support Android 15 16k page size.
  target_link_options(unnu_asr PRIVATE "-Wl,-z,max-page-size=16384")
  target_link_options(unnu_tts PRIVATE "-Wl,-z,max-page-size=16384")
endif()
