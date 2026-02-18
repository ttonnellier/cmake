include_guard()

include("cmake/CompilerWarnings.cmake")
include("cmake/DefaultBuildType.cmake")
include("cmake/StaticAnalyzers.cmake")
include("cmake/Doxygen.cmake")
include("cmake/Sanitizers.cmake")
include("cmake/GitHashMacro.cmake")
include("cmake/Optimizations.cmake")
include("cmake/CompilerColors.cmake")

macro(project_options)
  set(options
      WARNINGS_AS_ERRORS
      ENABLE_EXPORT_COMPILE_COMMANDS
      ENABLE_CPPCHECK
      ENABLE_CLANG_TIDY
      ENABLE_IWYU
      ENABLE_DOXYGEN
      ENABLE_INTERPROCEDURAL_OPTIMIZATION
      ENABLE_NATIVE_OPTIMIZATION
      ENABLE_GIT_HASH
      ENABLE_SANITIZER_ADDRESS
      ENABLE_SANITIZER_LEAK
      ENABLE_SANITIZER_UNDEFINED_BEHAVIOR
      ENABLE_SANITIZER_THREAD
      ENABLE_SANITIZER_MEMORY)
  set(oneValueArgs
      PREFIX)
  set(multiValueArgs
      GIT_HASH_OUTPUT_PATH
      CPPCHECK_OPTIONS
      CLANG_TIDY_OPTIONS
      DOXYGEN_THEME
      MSVC_WARNINGS
      CLANG_WARNINGS
      GCC_WARNINGS
      COMPILER_OPTIONS)
  cmake_parse_arguments(
    ProjectOptions         # arguments are prefixed with "ProjectOptions_"
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN})

  ############################################################
  # Common stuff
  ############################################################
  # warning message level
  if(${ProjectOptions_WARNINGS_AS_ERRORS})
    message(STATUS WARNINGS_AS_ERRORS)
    set(WARNING_MESSAGE SEND_ERROR)
  else()
    set(WARNING_MESSAGE WARNING)
  endif()

  # in DefaultBuildType
  set_default_build_type()

  # in CompilerColors
  set_compiler_colors()

  # to obtain a .json file used by clang based tools
  if(${ProjectOptions_ENABLE_EXPORT_COMPILE_COMMANDS})
    set(CMAKE_EXPORT_COMPILE_COMMANDS ${ProjectOptions_ENABLE_EXPORT_COMPILE_COMMANDS})
  endif()


  ############################################################
  # Interface lib for the options
  ############################################################
  set(_options_target project_options)
  set(_warnings_target project_warnings)
  if(NOT "${ProjectOptions_PREFIX}" STREQUAL "")
    set(_options_target "${ProjectOptions_PREFIX}_project_options")
    set(_warnings_target "${ProjectOptions_PREFIX}_project_warnings")
  else()
    if(TARGET project_options)
      message(
        FATAL_ERROR
        "Multiple calls to `project_options` in the same `project` detected, but the argument `PREFIX` that is prepended to `project_options` and `project_warnings` is not set."
      )
    endif()
  endif()
  message(VERBOSE ${_options_target})

  add_library(${_options_target} INTERFACE)
  add_library(${_warnings_target} INTERFACE)


  ############################################################
  # Compiler warnings
  ############################################################
  set_project_warnings(
    ${_warnings_target}
    "${ProjectOptions_WARNINGS_AS_ERRORS}"
    "${ProjectOptions_MSVC_WARNINGS}"
    "${ProjectOptions_CLANG_WARNINGS}"
    "${ProjectOptions_GCC_WARNINGS}")

  ############################################################
  # Compiler options
  ############################################################
  ## if compiler is g++, add the record-gcc-switches flag to be able to see which flags have been used when compiling the target
  if(${CMAKE_CXX_COMPILER_ID} STREQUAL "GNU")
    target_compile_options(${_options_target} INTERFACE -frecord-gcc-switches)
  endif()

  if(NOT "$ProjectOptions_COMPILER_OPTIONS" STREQUAL "")
    target_compile_options(${_options_target} INTERFACE ${ProjectOptions_COMPILER_OPTIONS})
  endif()


  ############################################################
  # Static Analyzers
  ############################################################
  if(${ProjectOptions_ENABLE_CPPCHECK})
    enable_cppcheck(
      ${_options_target}
      "${ProjectOptions_CPPCHECK_OPTIONS}"
      "${ProjectOptions_WARNINGS_AS_ERRORS}")
  endif()

  if(${ProjectOptions_ENABLE_CLANG_TIDY})
    enable_clang_tidy(
      ${_options_target}
      "${ProjectOptions_CLANG_TIDY_OPTIONS}"
      "${ProjectOptions_ENABLE_PCH}"
      "${ProjectOptions_WARNINGS_AS_ERRORS}")
  endif()

  if(${ProjectOptions_ENABLE_IWYU})
    enable_include_what_you_use(
      ${_options_target}
    )
  endif()

  ############################################################
  # Doxygen
  ############################################################
  if(${ProjectOptions_ENABLE_DOXYGEN})
    enable_doxygen("${ProjectOptions_DOXYGEN_THEME}" "${ProjectOptions_PREFIX}")
  endif()

  ############################################################
  # Sanitizers
  ############################################################
  enable_sanitizers(
    ${_options_target}
    ${ProjectOptions_ENABLE_SANITIZER_ADDRESS}
    ${ProjectOptions_ENABLE_SANITIZER_LEAK}
    ${ProjectOptions_ENABLE_SANITIZER_UNDEFINED_BEHAVIOR}
    ${ProjectOptions_ENABLE_SANITIZER_THREAD}
    ${ProjectOptions_ENABLE_SANITIZER_MEMORY}
  )

  ############################################################
  # Git Hash
  ############################################################
  if(${ProjectOptions_ENABLE_GIT_HASH})
    enable_git_hash(${_options_target} "${ProjectOptions_GIT_HASH_OUTPUT_PATH}")
  endif()

  ############################################################
  # Optimizations
  ############################################################
  if(${ProjectOptions_ENABLE_INTERPROCEDURAL_OPTIMIZATION})
    enable_interprocedural_optimization(${_options_target})
  endif()

  if(${ProjectOptions_ENABLE_NATIVE_OPTIMIZATION})
    enable_native_optimization(${_options_target})
  endif()
endmacro()


################################################################################
# APPLY_TRANSITIVE_PROPERTIES
################################################################################
macro(target_apply_transitive_properties destination_target options_target)

  set(transitive_properties
    "CPPCHECK"
    "CLANG_TIDY"
    "INCLUDE_WHAT_YOU_USE"
    )
  foreach(transitive_property  ${transitive_properties})
    get_target_property(value ${options_target} _TRANSITIVE_${transitive_property})

    if(NOT "${value}" STREQUAL "value-NOTFOUND")
      if(NOT "${CMAKE_CXX_STANDARD}" STREQUAL "")
        set_target_properties(${destination_target} PROPERTIES CXX_${transitive_property} "${value}")
        message(STATUS "CXX_${transitive_property} is enabled for target ${destination_target}")
      elseif(NOT "${CMAKE_C_STANDARD}" STREQUAL "")
        set_target_properties(${destination_target} PROPERTIES C_${transitive_property} "${value}")
        message(STATUS "C_${transitive_property} is enabled for target ${destination_target}")
      endif()
    endif()
  endforeach()

endmacro()

################################################################################
# SET_PROJECT_OPTIONS (wrapper around project_options)
################################################################################
macro(set_project_options)

  set(option_names
   "${PROJECT_PREFIX}_WARNINGS_AS_ERRORS"
   "${PROJECT_PREFIX}_ENABLE_EXPORT_COMPILE_COMMANDS"
   "${PROJECT_PREFIX}_ENABLE_CPPCHECK"
   "${PROJECT_PREFIX}_ENABLE_CLANG_TIDY"
   "${PROJECT_PREFIX}_ENABLE_GIT_HASH"
   "${PROJECT_PREFIX}_ENABLE_IWYU"
   "${PROJECT_PREFIX}_ENABLE_DOXYGEN"
   "${PROJECT_PREFIX}_ENABLE_SANITIZER_ADDRESS"
   "${PROJECT_PREFIX}_ENABLE_SANITIZER_LEAK"
   "${PROJECT_PREFIX}_ENABLE_SANITIZER_UNDEFINED_BEHAVIOR"
   "${PROJECT_PREFIX}_ENABLE_SANITIZER_THREAD"
   "${PROJECT_PREFIX}_ENABLE_SANITIZER_MEMORY"
   "${PROJECT_PREFIX}_ENABLE_INTERPROCEDURAL_OPTIMIZATION"
   "${PROJECT_PREFIX}_ENABLE_NATIVE_OPTIMIZATION")


  # if exists, set the value to itself
  foreach(option_name ${option_names})
    string(REPLACE "${PROJECT_PREFIX}_" "" option_name_wo_prefix ${option_name})
    if(${${option_name}}) # convert boolean to set/unset
      set(${option_name_wo_prefix}_VALUE ${option_name_wo_prefix})
    else()
      unset(${option_name_wo_prefix}_VALUE)
    endif()
  endforeach()

  project_options(
    ${WARNINGS_AS_ERRORS_VALUE}                  # both for C++ code and cmake
    ${ENABLE_EXPORT_COMPILE_COMMANDS_VALUE}      # exports a json file. Useful for clang based tools.
    ${ENABLE_CPPCHECK_VALUE}                     # static analysis tool
    CPPCHECK_OPTIONS ${${PROJECT_NAME}_CPPCHECK_OPTIONS}   # overides the defaults one found in cmake/StaticAnalyzers.cmake
    ${ENABLE_CLANG_TIDY_VALUE}                   # clang based C++ linter tool
    CLANG_TIDY_OPTIONS ${${PROJECT_NAME}_CLANG_TIDY_OPTIONS}   # overides the defaults one found in cmake/StaticAnalyzers.cmake
    ${ENABLE_GIT_HASH_VALUE}
    GIT_HASH_OUTPUT_PATH ${${PROJECT_NAME}_GIT_HASH_OUTPUT_PATH}
    ${ENABLE_IWYU_VALUE}                         # include-what-you-use: remove superflous includes
    ${ENABLE_DOXYGEN_VALUE}                      # write html documentation in docs/
    DOXYGEN_THEME    ${${PROJECT_PREFIX}_DOXYGEN_THEME}        # or awesome or awsome-sidebar
    MSVC_WARNINGS    ${${PROJECT_PREFIX}_MSVC_WARNINGS}        # overides the defaults one
    CLANG_WARNINGS   ${${PROJECT_PREFIX}_CLANG_WARNINGS}       # overides the defaults one
    GCC_WARNINGS     ${${PROJECT_PREFIX}_GCC_WARNINGS}         # overides the defaults one found in cmake/CompilerWarnings.cmake
    COMPILER_OPTIONS ${${PROJECT_PREFIX}_COMPILER_OPTIONS}
    ${ENABLE_INTERPROCEDURAL_OPTIMIZATION_VALUE} # link time optimization
    ${ENABLE_NATIVE_OPTIMIZATION_VALUE}          # march=native
                                                 # do not use sanitizers in delivery code (they perform runtime checks)
    ${ENABLE_SANITIZER_ADDRESS_VALUE}            # pointer issues
    ${ENABLE_SANITIZER_LEAK_VALUE}               # memory leak
    ${ENABLE_SANITIZER_UNDEFINED_BEHAVIOR_VALUE} # useless?
    ${ENABLE_SANITIZER_THREAD_VALUE}             # data race
    ${ENABLE_SANITIZER_MEMORY_VALUE}             # uninitialized stack
    PREFIX ${PROJECT_PREFIX}                       # the prefix to not mess up when this is used as a library
  )
endmacro()
