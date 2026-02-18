cmake_minimum_required(VERSION 3.16)

project(
  project_name
  VERSION 1.2
  DESCRIPTION "Project Description"
  LANGUAGES CXX)

# C++ standard
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED YES)

# CMake options
include("cmake/Index.cmake")

string(REPLACE " " "_"  PROJECT_PREFIX ${PROJECT_NAME})

# Default warnings
set(CLANG_WARNINGS
      -Wall
      -Wextra                # reasonable and standard
      -Wextra-semi           # Warn about semicolon after in-class function definition.
      -Wshadow               # warn the user if a variable declaration shadows one from a parent context
      -Wnon-virtual-dtor     # warn the user if a class with virtual functions has a non-virtual destructor. This helps catch hard to track down memory errors
      -Wcast-align           # warn for potential performance problem casts
      -Wunused               # warn on anything being unused
      -Woverloaded-virtual   # warn if you overload (not override) a virtual function
      -Wpedantic             # warn if non-standard C++ is used
      -Wnull-dereference     # warn if a null dereference is detected
      -Wdouble-promotion     # warn if float is implicit promoted to double
      -Wformat=2             # warn on security issues around functions that format output (ie printf)
      -Wimplicit-fallthrough # warn on statements that fallthrough without an explicit annotation
      )

# Project options
## booleans
option(${PROJECT_PREFIX}_WARNINGS_AS_ERRORS                  "both for C++ code and cmake."                                                 OFF)
option(${PROJECT_PREFIX}_ENABLE_EXPORT_COMPILE_COMMANDS      "exports a json file - useful for clang based tools"                           ON)
option(${PROJECT_PREFIX}_ENABLE_CPPCHECK                     "static analysis tool."                                                        OFF)
option(${PROJECT_PREFIX}_ENABLE_CLANG_TIDY                   "clang based C++ linter tool."                                                 OFF)
option(${PROJECT_PREFIX}_ENABLE_GIT_HASH                     "fill git-version.h file with state of the git repository - requires .in file" ON)
option(${PROJECT_PREFIX}_ENABLE_IWYU                         "include-what-you-use: remove superflous includes"                             OFF)
option(${PROJECT_PREFIX}_ENABLE_DOXYGEN                      "write html documentation in docs/"                                            OFF)
option(${PROJECT_PREFIX}_ENABLE_SANITIZER_ADDRESS            "runtime check for pointer issues"                                             OFF)
option(${PROJECT_PREFIX}_ENABLE_SANITIZER_LEAK               "runtime check for memory leak"                                                OFF)
option(${PROJECT_PREFIX}_ENABLE_SANITIZER_UNDEFINED_BEHAVIOR "runtime check for ????"                                                       OFF)
option(${PROJECT_PREFIX}_ENABLE_SANITIZER_THREAD             "runtime check for data race"                                                  OFF)
option(${PROJECT_PREFIX}_ENABLE_SANITIZER_MEMORY             "runtime check for uninitialized stack"                                        OFF)
option(${PROJECT_PREFIX}_ENABLE_INTERPROCEDURAL_OPTIMIZATION "link time optimization"                                                       OFF)
option(${PROJECT_PREFIX}_ENABLE_NATIVE_OPTIMIZATION          "-march=native"                                                                OFF)
## strings
set(${PROJECT_PREFIX}_DOXYGEN_THEME        "original"          CACHE STRING "enhance the look of the generated documentation")
set_property(CACHE ${PROJECT_PREFIX}_DOXYGEN_THEME PROPERTY STRINGS "original" "awesome" "awesome-sidebar")
set(${PROJECT_PREFIX}_GCC_WARNINGS         ""                  CACHE STRING "overrides the default ones found in cmake/CompilerWarnings.cmake")
set(${PROJECT_PREFIX}_MSCV_WARNINGS        ""                  CACHE STRING "overrides the default ones found in cmake/CompilerWarnings.cmake")
set(${PROJECT_PREFIX}_CLANG_WARNINGS       ""                  CACHE STRING "overrides the default ones found in cmake/CompilerWarnings.cmake")
set(${PROJECT_PREFIX}_CPPCHECK_OPTIONS     ""                  CACHE STRING "overrides the default ones found in cmake/StaticAnalyzers.cmake")
set(${PROJECT_PREFIX}_CLANG_TIDY_OPTIONS   ""                  CACHE STRING "overrides the default ones found in cmake/StaticAnalyzers.cmake")
set(${PROJECT_PREFIX}_GIT_HASH_OUTPUT_PATH ""                  CACHE STRING "overrides the default one found in cmake/GitHashMacro.cmake - relative to src directory")
set(${PROJECT_PREFIX}_COMPILER_OPTIONS     ""                  CACHE STRING "appended to the current list of options")

# Load above values to the project_options macro
set_project_options()

# Disable some warnings  // TODO add an option...
get_target_property(tmp ${_warnings_target} INTERFACE_COMPILE_OPTIONS)
list(REMOVE_ITEM tmp "-Wold-style-cast" "-Wsign-conversion")
set_target_properties(${_warnings_target} PROPERTIES INTERFACE_COMPILE_OPTIONS "${tmp}")

# add source directory
add_subdirectory(src)

# if we are the top level project
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR) # if(PROJECT_IS_TOP_LEVEL) # cmake3.21
  add_subdirectory(apps)
endif()
