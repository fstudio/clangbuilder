# Author: Force Charlie
# Copyright (C) 2019. Force Charlie. All Rights Reserved.
cmake_minimum_required(VERSION 3.12)
project(blast)

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

set(BLAST_VERSION_MAJOR 7)
set(BLAST_VERSION_MINOR 0)
set(BLAST_VERSION_PATCH 0)
set(PACKAGE_VERSION "${BLAST_VERSION_MAJOR}.${BLAST_VERSION_MINOR}.${BLAST_VERSION_PATCH}")

set(CPACK_PACKAGE_NAME "Blast")
set(CPACK_PACKAGE_INSTALL_DIRECTORY "Blast")
set(CPACK_PACKAGE_VERSION_MAJOR ${CLANGBUILDERUI_VERSION_MAJOR})
set(CPACK_PACKAGE_VERSION_MINOR ${CLANGBUILDERUI_VERSION_MINOR})
set(CPACK_PACKAGE_VERSION_PATCH ${CLANGBUILDERUI_VERSION_PATCH})
set(CPACK_PACKAGE_VERSION ${PACKAGE_VERSION})
set(CPACK_PACKAGE_VENDOR "Blast")
set(CPACK_PACKAGE_CONTACT "Force Charlie")

include(CPack)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED YES)

include(CheckIPOSupported)
check_ipo_supported(RESULT lto_supported OUTPUT error)
if(lto_supported)
  message(STATUS "IPO/LTO enabled")
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


include_directories(
  ../include
)

add_executable(blast WIN32
  blast.cc
  readlink.cc
  symlink.cc
  dumpbin.cc
  blast.rc
  blast.manifest
)

add_definitions(
  -D_UNICODE
  -DUNICODE
)

if(lto_supported)
  set_property(TARGET blast PROPERTY INTERPROCEDURAL_OPTIMIZATION TRUE)
endif()

target_link_libraries(blast
  ole32
  KERNEL32
  ADVAPI32
  Shell32
  USER32
)

install(TARGETS "blast"
	DESTINATION bin
)