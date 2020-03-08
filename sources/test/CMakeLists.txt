

add_executable(genlink_test
  genlinksrc.cc
)

target_link_libraries(genlink_test
  belawin
)

add_executable(parsejson_test
  parsejson.cc
)

target_link_libraries(parsejson_test
  belawin
)

add_executable(regsdk_test
  regsdk.cc
  ../baulk/io.cc
)

target_link_libraries(regsdk_test
  belawin
)

add_executable(vsenv_test
  vsenv.cc
  ../baulk/process.cc
  ../baulk/compiler.cc
  ../baulk/fs.cc
  ../baulk/io.cc
)

target_link_libraries(vsenv_test
  belawin
)