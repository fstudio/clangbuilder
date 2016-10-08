# Author: Force Charlie
# Copyright (C) 2016. Force Charlie. All Rights Reserved.
cmake_minimum_required(VERSION 3.2)
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




include(CheckCXXCompilerFlag)
CHECK_CXX_COMPILER_FLAG("-std=c++14" COMPILER_SUPPORTS_CXX14)
CHECK_CXX_COMPILER_FLAG("-std=c++11" COMPILER_SUPPORTS_CXX11)
if(COMPILER_SUPPORTS_CXX14)
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++14")
elseif(COMPILER_SUPPORTS_CXX11)
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
else()
        message(STATUS "The compiler ${CMAKE_CXX_COMPILER} has no C++11 support. Please use a different C++ compiler.")
endif()
# Find Boost Package

if (NOT MSVC)
    add_compile_options("-g")
    add_compile_options("-Wall")
    add_compile_options("-Wextra")
endif()





add_executable(ClangbuilderUI WIN32
  ClangbuilderUI.cpp
  ClangbuilderUI.manifest
  ClangbuilderUI.rc
  MainWindow.cpp
  MessageWindow.cpp
  stdafx.cpp
  VisualStudioSearch.cpp
  WindowsUtil.cpp
)

add_definitions(
  -D_UNICODE
  -DUNICODE
)

target_link_libraries(ClangbuilderUI
  d2d1
  dwrite
  shcore
  Winmm
  comctl32
)

