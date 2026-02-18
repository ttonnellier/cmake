include_guard()

# https://github.com/aminya/project_options/blob/main/src/Optimization.cmake -- MIT license

# detect the architecture of the target build system or the host system as a fallback
function(detect_architecture arch)
  # if the target processor is not known, fallback to the host processor
  if("${CMAKE_SYSTEM_PROCESSOR}" STREQUAL ""
     AND NOT
         "${CMAKE_HOST_SYSTEM_PROCESSOR}"
         STREQUAL
         "")
    set(_arch "${CMAKE_HOST_SYSTEM_PROCESSOR}")
  elseif(
    NOT
    "${CMAKE_SYSTEM_PROCESSOR}"
    STREQUAL
    "")
    set(_arch "${CMAKE_SYSTEM_PROCESSOR}")
  elseif(
    NOT
    "${DETECTED_CMAKE_SYSTEM_PROCESSOR}" # set by detect_compiler()
    STREQUAL
    "")
    set(_arch "${DETECTED_CMAKE_SYSTEM_PROCESSOR}")
  endif()

  # make it lowercase for comparison
  string(TOLOWER "${_arch}" _arch)

  if(_arch STREQUAL x86 OR _arch MATCHES "^i[3456]86$")
    set(${arch}
        x86
        PARENT_SCOPE)
  elseif(
    _arch STREQUAL x64
    OR _arch STREQUAL x86_64
    OR _arch STREQUAL amd64)
    set(${arch}
        x64
        PARENT_SCOPE)
  elseif(_arch STREQUAL arm)
    set(${arch}
        arm
        PARENT_SCOPE)
  elseif(_arch STREQUAL arm64 OR _arch STREQUAL aarch64)
    set(${arch}
        arm64
        PARENT_SCOPE)
  else()
    # fallback to the most common architecture
    message(STATUS "Unknown architecture ${_arch} - using x64")
    set(${arch}
        x64
        PARENT_SCOPE)
  endif()
endfunction()


macro(enable_interprocedural_optimization _options_target)
  if(CMAKE_BUILD_TYPE STREQUAL "Release" OR CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
    include(CheckIPOSupported)
    check_ipo_supported(RESULT result OUTPUT output)
    # is_mingw(_is_mingw)
    # if(result AND NOT ${_is_mingw})
    if(result)
      message(
        STATUS
          "Interprocedural optimization is enabled. In other projects, linking with the compiled libraries of this project might require `set(CMAKE_INTERPROCEDURAL_OPTIMIZATION ON)`"
      )
      set(CMAKE_INTERPROCEDURAL_OPTIMIZATION ON)
      set_target_properties(${_options_target} PROPERTIES INTERPROCEDURAL_OPTIMIZATION ON)
    else()
      message(WARNING "Interprocedural Optimization is not supported. Not using it. Here is the error log: ${output}")
    endif()
  endif()
endmacro()

macro(enable_native_optimization _options_target)
  detect_architecture(_arch)
  if("${_arch}" STREQUAL "x64")
    message(STATUS "Enabling the optimizations specific to the current build machine (less portable)")
    if(MSVC)
      # unsupported yet
    else()
      target_compile_options(${_options_target} INTERFACE -march=native)
    endif()
  endif()
endmacro()
