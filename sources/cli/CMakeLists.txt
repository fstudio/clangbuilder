add_executable(cli
  cli.cc
  ../res/cli.rc
  ../res/cli.manifest
)

if(lto_supported)
  set_property(TARGET cli PROPERTY INTERPROCEDURAL_OPTIMIZATION TRUE)
endif()

target_link_libraries(cli
  KERNEL32
)

install(TARGETS cli
	DESTINATION bin
)

add_executable(cmdex
  cmdex.cc
  ../res/cmdex.rc
  ../res/cli.manifest
)

if(lto_supported)
  set_property(TARGET cmdex PROPERTY INTERPROCEDURAL_OPTIMIZATION TRUE)
endif()

target_link_libraries(cmdex
  KERNEL32
)

install(TARGETS cmdex
	DESTINATION bin
)

add_executable(blastex
  blast.cc
  ../res/cmdex.rc
  ../res/cli.manifest
)

if(lto_supported)
  set_property(TARGET blastex PROPERTY INTERPROCEDURAL_OPTIMIZATION TRUE)
endif()

target_link_libraries(blastex
  belawin
)

install(TARGETS blastex
	DESTINATION bin
)

