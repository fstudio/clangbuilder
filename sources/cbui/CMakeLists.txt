# Author: Force Charlie
# Copyright (C) 2019. Force Charlie. All Rights Reserved.
cmake_minimum_required(VERSION 3.12)
project(ClangbuilderUI)


if( CMAKE_SOURCE_DIR STREQUAL CMAKE_BINARY_DIR AND NOT MSVC_IDE )
  message(FATAL_ERROR "In-source builds are not allowed.
CMake would overwrite the makefiles distributed with Rhizo.
Please create a directory and run cmake from there, passing the path
to this source directory as the last argument.
This process created the file `CMakeCache.txt' and the directory `CMakeFiles'.
Please delete them.")
endif()

set(EXECUTABLE_OUTPUT_PATH ${PROJECT_BINARY_DIR}/bin)
set(LIBRARY_OUTPUT_PATH ${PROJECT_BINARY_DIR}/lib)
if(NOT DEFINED CLANGBUILDERUI_VERSION_MAJOR)
  set(CLANGBUILDERUI_VERSION_MAJOR 7)
endif()
if(NOT DEFINED CLANGBUILDERUI_VERSION_MINOR)
  set(CLANGBUILDERUI_VERSION_MINOR 0)
endif()
if(NOT DEFINED CLANGBUILDERUI_VERSION_PATCH)
  set(CLANGBUILDERUI_VERSION_PATCH 0)
endif()

if (NOT PACKAGE_VERSION)
  set(PACKAGE_VERSION
    "${CLANGBUILDERUI_VERSION_MAJOR}.${CLANGBUILDERUI_VERSION_MINOR}.${CLANGBUILDERUI_VERSION_PATCH}")
endif()

set(CPACK_PACKAGE_NAME "ClangbuilderUI")
set(CPACK_PACKAGE_INSTALL_DIRECTORY "ClangbuilderUI")
set(CPACK_PACKAGE_VERSION_MAJOR ${CLANGBUILDERUI_VERSION_MAJOR})
set(CPACK_PACKAGE_VERSION_MINOR ${CLANGBUILDERUI_VERSION_MINOR})
set(CPACK_PACKAGE_VERSION_PATCH ${CLANGBUILDERUI_VERSION_PATCH})
set(CPACK_PACKAGE_VERSION ${PACKAGE_VERSION})
set(CPACK_PACKAGE_VENDOR "ClangbuilderUI")
set(CPACK_PACKAGE_CONTACT "Force Charlie")

include(CPack)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED YES)

include(CheckIPOSupported)
check_ipo_supported(RESULT lto_supported OUTPUT error)
if(lto_supported)
  message(STATUS "IPO/LTO enabled")
else()
  message(STATUS "IPO/LTO not supported: <${error}>")
endif()

if (MSVC)
  add_compile_options("-D_CRT_SECURE_NO_WARNINGS=1")
  add_compile_options("-Zc:__cplusplus") # C++ __cplusplus
  set(WIN_COMPILER_FLAGS
    CMAKE_CXX_FLAGS
    CMAKE_CXX_FLAGS_DEBUG
    CMAKE_CXX_FLAGS_RELEASE
    CMAKE_C_FLAGS
    CMAKE_C_FLAGS_DEBUG
    CMAKE_C_FLAGS_RELEASE
  )
  foreach(WIN_COMPILER_FLAG ${WIN_COMPILER_FLAGS})
    string(REPLACE "/MD" "/MT" ${WIN_COMPILER_FLAG} "${${WIN_COMPILER_FLAG}}")
  endforeach()
else()
  add_compile_options("-g")
  add_compile_options("-Wall")
  add_compile_options("-Wextra")
  if(USE_SANITIZE)
    add_compile_options("-fsanitize=address")
    add_compile_options("-fno-omit-frame-pointer")
    set(CMAKE_EXE_LINKER_FLAGS "-fsanitize=address ")
  endif()
endif()

add_executable(ClangbuilderUI WIN32
  main.cc
  appdo.cc
  appui.cc
  apputils.cc
  settings.cc
  vssearch.cc
  res/app.rc
  res/app.manifest
)

add_definitions(
  -D_UNICODE
  -DUNICODE
)

if(lto_supported)
  set_property(TARGET ClangbuilderUI PROPERTY INTERPROCEDURAL_OPTIMIZATION TRUE)
endif()

target_link_libraries(ClangbuilderUI
  d2d1
  dwrite
  Pathcch
  shcore
  Winmm
  comctl32
  ole32.lib
  comsupp.lib
)

install(TARGETS "ClangbuilderUI"
	DESTINATION bin
)