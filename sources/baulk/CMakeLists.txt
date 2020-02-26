##

add_executable(baulk
  baulk.cc
  cleanup.cc
  download.cc
  utils.cc
  windl.cc
  ../res/cli.rc
  ../res/cli.manifest
)

target_link_libraries(baulk
  belawin
  winhttp
)