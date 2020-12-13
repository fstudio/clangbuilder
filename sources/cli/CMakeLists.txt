add_executable(cli
  cli.cc
  ../res/cli.rc
  ../res/cli.manifest
)

if(lto_supported)
  set_property(TARGET cli PROPERTY INTERPROCEDURAL_OPTIMIZATION TRUE)
endif()

target_link_libraries(cli
  belawin
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
  belawin
)

install(TARGETS cmdex
	DESTINATION bin
)

add_executable(blast
  blast.cc
  ../res/blast.rc
  ../res/cli.manifest
)

if(lto_supported)
  set_property(TARGET blast PROPERTY INTERPROCEDURAL_OPTIMIZATION TRUE)
endif()

target_link_libraries(blast
  hazel
  belawin
)

install(TARGETS blast
	DESTINATION bin
)

