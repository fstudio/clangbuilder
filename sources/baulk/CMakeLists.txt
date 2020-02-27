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

add_executable(indicators_test
  indicators_test.cc
)

target_link_libraries(indicators_test
  belawin
  winhttp
)

add_executable(windl_test
windl_test.cc
windl.cc
)

target_link_libraries(windl_test
  belawin
  winhttp
)