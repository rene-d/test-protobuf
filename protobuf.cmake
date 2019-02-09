# protobuf.cmake
# rene-d 02/2019


#   GIT_REPOSITORY https://github.com/protocolbuffers/protobuf
#   GIT_TAG v3.0.0

set(URL https://github.com/protocolbuffers/protobuf/releases/download/v3.0.0/protobuf-cpp-3.0.0.tar.gz)


ExternalProject_Add(
  protobuf-external
  PREFIX ${CMAKE_CURRENT_BINARY_DIR}/protobuf

  URL ${URL}

  CMAKE_CACHE_ARGS
    "-DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}"
    "-DCMAKE_CXX_COMPILER:STRING=${CMAKE_CXX_COMPILER}"
    "-DCMAKE_INSTALL_PREFIX:FILEPATH=${CMAKE_CURRENT_BINARY_DIR}/externals"
    "-Dprotobuf_BUILD_TESTS:BOOL=OFF"
    "-Dprotobuf_BUILD_EXAMPLES:BOOL=OFF"
    "-Dprotobuf_WITH_ZLIB:BOOL=ON"

  SOURCE_SUBDIR cmake

#  LOG_CONFIGURE 1
#  BUILD_ALWAYS 1
#  STEP_TARGETS build
#  INSTALL_COMMAND ""  #Skip
)


cmake_policy(SET CMP0074 NEW)
set(Protobuf_ROOT ${CMAKE_CURRENT_BINARY_DIR}/externals)
find_package(Protobuf REQUIRED)

message(STATUS "Protobuf_INCLUDE_DIRS = ${Protobuf_INCLUDE_DIRS}")
message(STATUS "Protobuf_LIBRARY = ${Protobuf_LIBRARY}")
message(STATUS "Protobuf_PROTOC_EXECUTABLE = ${Protobuf_PROTOC_EXECUTABLE}")
