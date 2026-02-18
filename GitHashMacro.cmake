include_guard()
find_package(Git REQUIRED QUIET)

macro(
  enable_git_hash
  options_target
  GIT_HASH_OUTPUT_PATH
)

  set_target_properties(${_options_target} PROPERTIES _TRANSITIVE_ENABLE_GIT_HASH TRUE)
  set_target_properties(${_options_target} PROPERTIES _TRANSITIVE_GIT_HASH_OUTPUT_PATH "${GIT_HASH_OUTPUT_PATH}")

endmacro()

macro(
  target_add_git_hash
  destination_target
  options_target
)

  get_target_property(GIT_HASH ${options_target} _TRANSITIVE_ENABLE_GIT_HASH)
  get_target_property(GIT_HASH_OUTPUT_PATH ${options_target} _TRANSITIVE_GIT_HASH_OUTPUT_PATH)

  if(NOT "${GIT_HASH}" STREQUAL "GIT_HASH-NOTFOUND")

    if("${GIT_HASH_OUTPUT_PATH}" STREQUAL "")
      set(GIT_HASH_OUTPUT_PATH ${CMAKE_CURRENT_BINARY_DIR}/../generated)
    else()
      set(GIT_HASH_OUTPUT_PATH ${CMAKE_CURRENT_SOURCE_DIR}/${GIT_HASH_OUTPUT_PATH})
    endif()

    execute_process(
      COMMAND ${CMAKE_COMMAND}
      -Dinput_dir=${CMAKE_CURRENT_SOURCE_DIR}/../cmake
      -Doutput_dir=${GIT_HASH_OUTPUT_PATH}
      -P "${CMAKE_CURRENT_SOURCE_DIR}/../cmake/GitHash.cmake"
      )

    add_custom_command(TARGET ${destination_target}
      PRE_BUILD
      COMMAND ${CMAKE_COMMAND}
      -Dinput_dir="${CMAKE_CURRENT_SOURCE_DIR}/../cmake"
      -Doutput_dir="${GIT_HASH_OUTPUT_PATH}"
      -P "${CMAKE_CURRENT_SOURCE_DIR}/../cmake/GitHash.cmake"
      )

    set_property(TARGET ${destination_target} APPEND PROPERTY SOURCES "${GIT_HASH_OUTPUT_PATH}/git_version.h")

    message(STATUS "GIT_HASH is enabled for target ${destination_target} (${GIT_HASH_OUTPUT_PATH}/git_version.h) ${options_target}")
  endif()

endmacro()

macro(
  show_submodules_hash
  MODULE
)

  set(GIT_LOG unknown)
  execute_process(
    COMMAND sh -c "git submodule status --recursive | grep \"${MODULE} \""
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
    OUTPUT_VARIABLE GIT_LOG
    ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE)

  message("##########################################")
  message("${GIT_LOG}")
  message("##########################################")

endmacro()
