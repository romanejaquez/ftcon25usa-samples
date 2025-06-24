# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(rive_native_library VERSION 0.0.1 LANGUAGES C)

# Download the Rive native libraries for windows
find_program(DART_EXECUTABLE dart REQUIRED) 
if(NOT DART_EXECUTABLE)
  message(FATAL_ERROR "rive_native: Dart SDK not found. Please install Dart and ensure it is in your PATH.")
endif()

if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
  message(STATUS "rive_native: CMake is running on Windows.")
  set(KEY "\\build\\rive_native")
  set(SETUP_COMMAND cmd.exe /C "${DART_EXECUTABLE} run rive_native:setup --verbose -p android")
else()
  message(STATUS "rive_native: CMake is running on a non-Windows host.")
  set(KEY "/build/rive_native")
  set(SETUP_COMMAND ${CMAKE_COMMAND} -E env "dart" "run" "rive_native:setup" "--verbose" "-p" "android")
endif()

set(PATH "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}")
string(FIND "${PATH}" "${KEY}" INDEX)

if(INDEX EQUAL -1)
    message(FATAL_ERROR "rive_native: Could not infer app root — '${KEY}' not found in: ${PATH}")
else()
    string(SUBSTRING "${PATH}" 0 ${INDEX} INFERRED_APP_DIR)
    message(STATUS "rive_native: Inferred app root: ${INFERRED_APP_DIR}")
endif()

execute_process(
  COMMAND ${SETUP_COMMAND}
  WORKING_DIRECTORY "${INFERRED_APP_DIR}"
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

# add_library(rive_native SHARED
#   "rive_native.c"
# )

# set_target_properties(rive_native PROPERTIES
#   PUBLIC_HEADER rive_native.h
#   OUTPUT_NAME "rive_native"
# )

# target_compile_definitions(rive_native PUBLIC DART_SHARED_LIB)
