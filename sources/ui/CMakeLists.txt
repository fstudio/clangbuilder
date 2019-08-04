# Author: Force Charlie
# Copyright (C) 2019. Force Charlie. All Rights Reserved.

add_executable(ClangbuilderUI WIN32
  main.cc
  appexec.cc
  appui.cc
  apputils.cc
  settings.cc
  vssearch.cc
  ../res/app.rc
  ../res/app.manifest
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