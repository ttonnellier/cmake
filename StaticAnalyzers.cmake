# https://github.com/aminya/project_options/blob/main/src/StaticAnalyzers.cmake

include_guard()

# cppcheck, clang-tidy and iwyu are natively supported by cmake via targets
# properties {C,CXX}_CPPCHECK {C,CXX}_CLANG_TIDY and CXX_INCLUDE_WHAT_YOU_USE
# However, we do not want to use them to support fine granularity with nested libs
# Thus, we use properties named _TRANSITIVE_* in the options_target that we transfer to the
# target of interest using apply_transitive_properties

# Enable static analysis with cppcheck
macro(enable_cppcheck options_target CPPCHECK_OPTIONS WARNINGS_AS_ERRORS)
  find_program(CPPCHECK cppcheck)
  if(CPPCHECK)

    if(CMAKE_GENERATOR MATCHES ".*Visual Studio.*")
      set(CPPCHECK_TEMPLATE "vs")
    else()
      set(CPPCHECK_TEMPLATE "gcc")
    endif()

    if("${CPPCHECK_OPTIONS}" STREQUAL "")
      # Enable all warnings that are actionable by the user of this toolset
      # style should enable the other 3, but we'll be explicit just in case
      set(CPPCHECK_CMD
          "${CPPCHECK}"
          "--template=${CPPCHECK_TEMPLATE}"
          "--enable=style,performance,warning,portability"
          "--inline-suppr"
          # We cannot act on a bug/missing feature of cppcheck
          "--suppress=internalAstError"
          # if a file does not have an internalAstError, we get an unmatchedSuppression error
          "--suppress=unmatchedSuppression"
          "--inconclusive")
    else()
      # if the user provides a CPPCHECK_OPTIONS with a template specified, it will override this template
      set(CPPCHECK_CMD
        "${CPPCHECK}"
        "--template=${CPPCHECK_TEMPLATE}"
        "${CPPCHECK_OPTIONS}")
    endif()

    if(${WARNINGS_AS_ERRORS})
      list(APPEND CPPCHECK_CMD --error-exitcode=2)
    endif()

    # C cppcheck
    set(CMAKE_C_CPPCHECK ${CMAKE_CXX_CPPCHECK})

    if(NOT
       "${CMAKE_CXX_STANDARD}"
       STREQUAL
       "")
      list(APPEND CPPCHECK_CMD --std=c++${CMAKE_CXX_STANDARD})
    endif()

    if(NOT
       "${CMAKE_C_STANDARD}"
       STREQUAL
       "")
      list(APPEND CPPCHECK_CMD --std=c${CMAKE_C_STANDARD})
    endif()
    set_target_properties(${options_target} PROPERTIES _TRANSITIVE_CPPCHECK "${CPPCHECK_CMD}")
  else()
    message(${WARNING_MESSAGE} "cppcheck requested but executable not found")
  endif()

endmacro()

# Enable static analysis with clang-tidy
macro(enable_clang_tidy options_target CLANG_TIDY_OPTIONS ENABLE_PCH WARNINGS_AS_ERRORS)
  find_program(CLANG_TIDY clang-tidy)
  if(CLANG_TIDY)

    # clang-tidy only works with clang when PCH is enabled
    if((NOT CMAKE_CXX_COMPILER_ID MATCHES ".*Clang" OR (NOT CMAKE_C_COMPILER_ID MATCHES ".*Clang")) AND "${ENABLE_PCH}")
      message(
        FATAL_ERROR
        "clang-tidy cannot be enabled with non-clang compiler and PCH, clang-tidy fails to handle gcc's PCH file. Disabling PCH..."
      )
    endif()

    # construct the clang-tidy command line
    if("${CLANG_TIDY_OPTIONS}" STREQUAL "")
      set(CLANG_TIDY_CMD
        ${CLANG_TIDY}
        "-use-color"
        "-extra-arg=-Wno-unknown-warning-option")
    else()
      # if the user provides a CPPCHECK_OPTIONS with a template specified, it will override this template
      set(CLANG_TIDY_CMD
         ${CLANG_TIDY}
         "${CLANG_TIDY_OPTIONS}")
    endif()

    # set warnings as errors
    if(${WARNINGS_AS_ERRORS})
      list(APPEND CLANG_TIDY_CMD -warnings-as-errors=*)
    endif()

    # set C++ standard
    if(NOT "${CMAKE_CXX_STANDARD}" STREQUAL "")
      if("${CMAKE_CXX_CLANG_TIDY_DRIVER_MODE}" STREQUAL "cl")
        list(APPEND CLANG_TIDY_CMD -extra-arg=/std:c++${CMAKE_CXX_STANDARD})
      else()
        list(APPEND CLANG_TIDY_CMD -extra-arg=-std=c++${CMAKE_CXX_STANDARD})
      endif()
    endif()

    # set C standard
    if(NOT "${CMAKE_C_STANDARD}" STREQUAL "")
      if("${CMAKE_C_CLANG_TIDY_DRIVER_MODE}" STREQUAL "cl")
        list(APPEND CLANG_TIDY_CMD -extra-arg=/std:c${CMAKE_C_STANDARD})
      else()
        list(APPEND CLANG_TIDY_CMD -extra-arg=-std=c${CMAKE_C_STANDARD})
      endif()
    endif()

    set_target_properties(${options_target} PROPERTIES _TRANSITIVE_CLANG_TIDY "${CLANG_TIDY_CMD}")

  else()
    message(${WARNING_MESSAGE} "clang-tidy requested but executable not found")
  endif()
endmacro()


# Enable static analysis with include-what-you-use
macro(enable_include_what_you_use options_target)
  find_program(INCLUDE_WHAT_YOU_USE include-what-you-use)
  if(INCLUDE_WHAT_YOU_USE)
    set_target_properties(${options_target} PROPERTIES _TRANSITIVE_INCLUDE_WHAT_YOU_USE "${INCLUDE_WHAT_YOU_USE}")
  else()
    message(${WARNING_MESSAGE} "include-what-you-use requested but executable not found")
  endif()
endmacro()

# # Disable clang-tidy for target
# macro(target_disable_clang_tidy TARGET)
#   find_program(CLANG_TIDY clang-tidy)
#   if(CLANG_TIDY)
#     set_target_properties(${TARGET} PROPERTIES C_CLANG_TIDY "")
#     set_target_properties(${TARGET} PROPERTIES CXX_CLANG_TIDY "")
#   endif()
# endmacro()
#
# # Disable cppcheck for target
# macro(target_disable_cpp_check TARGET)
#   find_program(CPPCHECK cppcheck)
#   if(CPPCHECK)
#     set_target_properties(${TARGET} PROPERTIES C_CPPCHECK "")
#     set_target_properties(${TARGET} PROPERTIES CXX_CPPCHECK "")
#   endif()
# endmacro()
#
# # Disable static analysis for target
# macro(target_disable_static_analysis TARGET)
#     target_disable_clang_tidy(${TARGET})
#     target_disable_cpp_check(${TARGET})
# endmacro()
