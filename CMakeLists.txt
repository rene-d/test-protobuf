cmake_minimum_required(VERSION 3.8)

include(ExternalProject)

set(CMAKE_C_COMPILER gcc-8)
set(CMAKE_CXX_COMPILER g++-8)


ExternalProject_Add(
  protobuf-external
  PREFIX ${CMAKE_CURRENT_BINARY_DIR}/protobuf

  GIT_REPOSITORY https://github.com/protocolbuffers/protobuf
  GIT_TAG v3.0.0

#  LOG_CONFIGURE 1
  CMAKE_CACHE_ARGS
    "-DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}"
    "-DCMAKE_CXX_COMPILER:STRING=${CMAKE_CXX_COMPILER}"
#    "-DCMAKE_INSTALL_PREFIX:FILEPATH=<INSTALL_DIR>"
    "-DCMAKE_INSTALL_PREFIX:FILEPATH=${CMAKE_CURRENT_BINARY_DIR}/externals"
    "-Dprotobuf_BUILD_TESTS:BOOL=OFF"
    "-Dprotobuf_BUILD_EXAMPLES:BOOL=OFF"
    "-Dprotobuf_WITH_ZLIB:BOOL=ON"
    # other project specific parameters
  SOURCE_SUBDIR cmake
#  BUILD_ALWAYS 1
#  STEP_TARGETS build
 # INSTALL_COMMAND ""  #Skip
)

#ExternalProject_Get_Property(protobuf-external source_dir)
#include_directories(${source_dir}/src)
#link_directories(${CMAKE_CURRENT_BINARY_DIR}/protobuf)


ExternalProject_Add(
  protobuf-c-external
  PREFIX ${CMAKE_CURRENT_BINARY_DIR}/protobuf-c

  GIT_REPOSITORY https://github.com/protobuf-c/protobuf-c
  GIT_TAG v1.2.1

  CMAKE_CACHE_ARGS
    "-DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}"
    "-DCMAKE_C_COMPILER:STRING=${CMAKE_C_COMPILER}"
    "-DCMAKE_CXX_COMPILER:STRING=${CMAKE_CXX_COMPILER}"
 #   "-DCMAKE_INSTALL_PREFIX:FILEPATH=<INSTALL_DIR>"
 "-DCMAKE_INSTALL_PREFIX:FILEPATH=${CMAKE_CURRENT_BINARY_DIR}/externals"
    "-DCMAKE_POLICY_DEFAULT_CMP0074:STRING=NEW"
#    "-DProtobuf_ROOT:FILEPATH=${CMAKE_CURRENT_BINARY_DIR}/protobuf"
    "-DProtobuf_ROOT:FILEPATH=${CMAKE_CURRENT_BINARY_DIR}/externals"
  SOURCE_SUBDIR build-cmake
#    BUILD_ALWAYS 1
#    STEP_TARGETS build
#    INSTALL_COMMAND ""
)

add_dependencies(protobuf-c-external protobuf-external)
