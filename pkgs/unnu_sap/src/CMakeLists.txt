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

########################
add_library(unnu_sap SHARED
   unnu_tts.cc unnu_asr.cc unnu_vad.cc unnu_voicefx.cc microphone.cc common.cc
)

set_target_properties(unnu_sap PROPERTIES
  BUILD_WITH_INSTALL_RPATH TRUE
  LINKER_LANGUAGE CXX
  PUBLIC_HEADER "unnu_asr.h;unnu_tts.h;unnu_vad.h;unnu_voicefx.h;common.h"
  OUTPUT_NAME "unnu_sap"
  POSITION_INDEPENDENT_CODE True
)

target_compile_definitions(unnu_sap PUBLIC DART_SHARED_LIB)

if(MSVC)
	set_property(TARGET unnu_sap PROPERTY
		MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
endif()

if(ANDROID)
	target_link_libraries(unnu_sap PRIVATE log piper sherpa-onnx-c-api onnxruntime::onnxruntime ort portaudio::portaudio portaudio_shared kissfft::kissfft kissfft_shared SoundTouchDLL ten_vad ten::libtenvad eigen nlohmann::json mattiasgustavsson::libs Threads::Threads)
else()
	target_link_libraries(unnu_sap PRIVATE piper sherpa-onnx-c-api onnxruntime::onnxruntime ort portaudio::portaudio portaudio_shared kissfft::kissfft kissfft_shared SoundTouchDLL ten_vad ten::libtenvad eigen nlohmann::json mattiasgustavsson::libs Threads::Threads)
endif()

if (ANDROID)
  # Support Android 15 16k page size.
  target_link_options(unnu_sap PRIVATE "-Wl,-z,max-page-size=16384")
endif()
