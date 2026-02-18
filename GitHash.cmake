find_package(Git REQUIRED QUIET)

message(VERBOSE "Resolving GIT Version")
set(GIT_SHA1 unknown)
set(GIT_SHORT_SHA1 unknown)
set(GIT_DATE unknown)
set(GIT_MESSAGE unknown)
set(BUILD_TIME unknown)

# SHA1
execute_process(
  COMMAND ${GIT_EXECUTABLE} describe --match=NeVeRmAtCh --always --abbrev=40 --dirty
  WORKING_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}"
  OUTPUT_VARIABLE GIT_SHA1
  ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)

# Short SHA1
execute_process(
  COMMAND ${GIT_EXECUTABLE} describe --match=NeVeRmAtCh --always --dirty
  WORKING_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}"
  OUTPUT_VARIABLE GIT_SHORT_SHA1
  ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)

# Date
execute_process(
  COMMAND "${GIT_EXECUTABLE}" log -1 --format=%ad --date=local
  WORKING_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}"
  OUTPUT_VARIABLE GIT_DATE
  ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)

# Message
execute_process(
  COMMAND "${GIT_EXECUTABLE}" log -1 --format=%s
  WORKING_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}"
  OUTPUT_VARIABLE GIT_MESSAGE
  ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)

# Build Time
string(TIMESTAMP BUILD_TIME "%Y-%m-%d %H:%M:%S")

# Write the header file
configure_file("${input_dir}/git_version.h.in"  "${output_dir}/git_version.h")
