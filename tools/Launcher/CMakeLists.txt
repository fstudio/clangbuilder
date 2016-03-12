# launcher CMakeLists.txt
# manifest require CMake 3.4 or Later support
cmake_minimum_required(VERSION 3.4)
project(launcher)
if( CMAKE_SOURCE_DIR STREQUAL CMAKE_BINARY_DIR AND NOT MSVC_IDE )
  message(FATAL_ERROR "In-source builds are not allowed.
CMake would overwrite the makefiles distributed with launcher.
Please create a directory and run cmake from there, passing the path
to this source directory as the last argument.
This process created the file `CMakeCache.txt' and the directory `CMakeFiles'.
Please delete them.")
endif()

if(NOT WIN32)
  message(FATAL_ERROR "Launcher utility tools only run under Windows")
endif()
#

add_compile_options("-DCMAKE_BUILD")

add_executable(launcher WIN32
  GetOptInc.cpp
  Precompiled.cpp
  launcher.cpp
  launcher.rc
  Launcher.exe.manifest
)

#set_source_files_properties(launcher.rc PROPERTIES LANGUAGE RC)
target_link_libraries(launcher
  kernel32
  advapi32
  shell32
  user32
  gdi32
  comctl32
  shlwapi
)
