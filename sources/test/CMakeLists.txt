

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

add_executable(xmlsdk_test
  xmlsdk.cc
)

target_link_libraries(xmlsdk_test
  belawin
)