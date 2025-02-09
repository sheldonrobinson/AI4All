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

##################### Soar
set(SVS ON CACHE BOOL "SVS Enabled" FORCE)
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/Soar" "${CMAKE_CURRENT_BINARY_DIR}/Soar" EXCLUDE_FROM_ALL)

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
			${CMAKE_CURRENT_BINARY_DIR}/Soar/$<CONFIG>
			)

# target_include_directories(unnu_ce PRIVATE ${SOAR_INCLUDE_DIR})

target_compile_definitions(unnu_ce PUBLIC DART_SHARED_LIB)

# target_link_libraries(unnu_ce soar::soar)

set(UNNU_LIB_DEPS sentencepiece-static soar_lib cpuinfo ort ortgenai $<TARGET_OBJECTS:slmengine_objs> tokenizers_cpp)

if(ANDROID)
target_link_libraries(unnu_ce PRIVATE ${UNNU_LIB_DEPS} log Threads::Threads)
else()
target_link_libraries(unnu_ce PRIVATE ${UNNU_LIB_DEPS} Threads::Threads)
endif()

if (ANDROID)
  # Support Android 15 16k page size
  target_link_options(unnu_ce PRIVATE "-Wl,-z,max-page-size=16384")
endif()
