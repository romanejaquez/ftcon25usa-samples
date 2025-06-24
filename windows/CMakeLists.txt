# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "rive_native")
project(${PROJECT_NAME} LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Download the Rive native libraries for windows
find_program(DART_EXECUTABLE dart REQUIRED)
if(NOT DART_EXECUTABLE)
  message(FATAL_ERROR "rive_native: Dart SDK not found. Please install Dart and ensure it is in your PATH.")
endif()

execute_process(
  COMMAND cmd.exe /C "${DART_EXECUTABLE} run rive_native:setup --verbose -p windows"
  WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}/../"
  RESULT_VARIABLE result
  OUTPUT_VARIABLE output
  ERROR_VARIABLE error
  OUTPUT_STRIP_TRAILING_WHITESPACE
  ERROR_STRIP_TRAILING_WHITESPACE
)

message(STATUS "rive_native setup output: ${output}")
if(NOT error STREQUAL "")
  message(WARNING "rive_native setup error: ${error}")
endif()

if(NOT result EQUAL 0)
  message(FATAL_ERROR "rive_native: Failed to run setup command. Exit code: ${result}")
endif()

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "rive_native_plugin")

# Any new source files that you add to the plugin should be added here.
list(APPEND PLUGIN_SOURCES
  "rive_native_plugin.cpp"
  "rive_native_plugin_c_api.cpp"
)

# Define the plugin library target. Its name must not be changed (see comment
# on PLUGIN_NAME above).
add_library(${PLUGIN_NAME} SHARED
  ${PLUGIN_SOURCES}
)

# Apply a standard set of build settings that are configured in the
# application-level CMakeLists.txt. This can be removed for plugins that want
# full control over build settings.
apply_standard_settings(${PLUGIN_NAME})

# Symbols are hidden by default to reduce the chance of accidental conflicts
# between plugins. This should not be removed; any symbols that should be
# exported should be explicitly exported with the FLUTTER_PLUGIN_EXPORT macro.
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
include_directories(
    "${CMAKE_CURRENT_SOURCE_DIR}/include/external"
    "${CMAKE_CURRENT_SOURCE_DIR}/include"
)

# Source include directories and library dependencies. Add any plugin-specific
# dependencies here.
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE
  flutter
  flutter_wrapper_plugin
  d3d11
  dxgi
  optimized "${CMAKE_CURRENT_SOURCE_DIR}/bin/lib/release/rive_native.lib"
  debug "${CMAKE_CURRENT_SOURCE_DIR}/bin/lib/debug/rive_native.lib"
)
set(rive_native_bundled_libraries
  $<$<CONFIG:Debug>:${CMAKE_CURRENT_SOURCE_DIR}/bin/lib/debug/rive_native.dll>
  $<$<CONFIG:Profile>:${CMAKE_CURRENT_SOURCE_DIR}/bin/lib/release/rive_native.dll>
  $<$<CONFIG:Release>:${CMAKE_CURRENT_SOURCE_DIR}/bin/lib/release/rive_native.dll>
  PARENT_SCOPE
)