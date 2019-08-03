# Author: Force Charlie
# Copyright (C) 2019. Force Charlie. All Rights Reserved.

add_executable(blast
  driver.cc
  pe.cc
  resolve.cc
  ../res/blast.rc
  ../res/cli.manifest
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