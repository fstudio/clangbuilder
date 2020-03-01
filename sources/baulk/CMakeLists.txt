##

add_executable(baulk
  baulk.cc
  fs.cc
  download.cc
  windl.cc
  7z.cc
  msi.cc
  zip.cc
  decompress.cc
  ../res/cli.rc
  ../res/cli.manifest
)

target_link_libraries(baulk
  belawin
  winhttp
  Msi
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