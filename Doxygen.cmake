cmake_minimum_required(VERSION 3.16)


if (CMAKE_VERSION VERSION_GREATER_EQUAL "3.24.0")
  cmake_policy(SET CMP0135 NEW)
endif()

include_guard()

function(enable_doxygen DOXYGEN_THEME PROJECT_PREFIX)

  # set better defaults for doxygen
  set(DOXYGEN_OUTPUT_DIRECTORY ../docs) # relative to current binary directory
  set(DOXYGEN_CALLER_GRAPH YES)
  set(DOXYGEN_CALL_GRAPH YES)
  set(DOXYGEN_EXTRACT_ALL YES)
  set(DOXYGEN_GENERATE_TREEVIEW YES)
  set(DOXYGEN_DOT_IMAGE_FORMAT svg) # svg files are much smaller than jpeg and png, and yet they have higher quality
  set(DOXYGEN_DOT_TRANSPARENT YES)

  # If not specified, exclude files CMake downloads under _deps (like project_options)
  if(NOT DOXYGEN_EXCLUDE_PATTERNS)
    set(DOXYGEN_EXCLUDE_PATTERNS "${CMAKE_CURRENT_BINARY_DIR}/_deps/*")
  endif()

  # Theme
  if("${DOXYGEN_THEME}" STREQUAL "")
    set(DOXYGEN_THEME "awesome-sidebar")
  endif()

  if("${DOXYGEN_THEME}" STREQUAL "awesome" OR "${DOXYGEN_THEME}" STREQUAL "awesome-sidebar")
    # use a modern doxygen theme
    # https://github.com/jothepro/doxygen-awesome-css v2.0.2
    include(FetchContent)
    FetchContent_Declare(_doxygen_theme
                         URL https://github.com/jothepro/doxygen-awesome-css/archive/refs/tags/v2.0.2.zip)
    FetchContent_MakeAvailable(_doxygen_theme)
    if("${DOXYGEN_THEME}" STREQUAL "awesome" OR "${DOXYGEN_THEME}" STREQUAL "awesome-sidebar")
      set(DOXYGEN_HTML_EXTRA_STYLESHEET "${_doxygen_theme_SOURCE_DIR}/doxygen-awesome.css")
    endif()
    if("${DOXYGEN_THEME}" STREQUAL "awesome-sidebar")
      set(DOXYGEN_HTML_EXTRA_STYLESHEET ${DOXYGEN_HTML_EXTRA_STYLESHEET}
                                        "${_doxygen_theme_SOURCE_DIR}/doxygen-awesome-sidebar-only.css")
    endif()
  elseif("${DOXYGEN_THEME}" STREQUAL "original")
    # use the original doxygen theme
  else()
    # use custom doxygen theme

    # if any of the custom theme files are not found, the theme is reverted to original
    set(OLD_DOXYGEN_HTML_EXTRA_STYLESHEET ${DOXYGEN_HTML_EXTRA_STYLESHEET})
    foreach(file ${DOXYGEN_THEME})
      if(NOT EXISTS ${file})
        message(WARNING "Could not find doxygen theme file '${file}'. Using original theme.")
        set(DOXYGEN_HTML_EXTRA_STYLESHEET ${OLD_DOXYGEN_HTML_EXTRA_STYLESHEET})
        break()
      else()
        set(DOXYGEN_HTML_EXTRA_STYLESHEET ${DOXYGEN_HTML_EXTRA_STYLESHEET} "${file}")
      endif()
    endforeach()
  endif()

  # find doxygen and dot if available
  find_package(Doxygen REQUIRED OPTIONAL_COMPONENTS dot)
  message(STATUS "Adding `${PROJECT_PREFIX}-doxygen-docs` target that builds the documentation.")
  doxygen_add_docs("${PROJECT_PREFIX}-doxygen-docs"
                   # ALL # uncomment to add to default build target
                   ${PROJECT_SOURCE_DIR}
                   COMMENT "Generating documentation - entry file: ${CMAKE_CURRENT_BINARY_DIR}/html/index.html")
endfunction()
