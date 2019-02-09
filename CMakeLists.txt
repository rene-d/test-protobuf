cmake_minimum_required(VERSION 3.9)

set(CMAKE_C_COMPILER gcc-8)
set(CMAKE_CXX_COMPILER g++-8)

include(ExternalProject)

include(protobuf.cmake)
include(protobuf-c.cmake)



protobufc_generate_c(PROTO_SRC PROTO_HEAD foo.proto)


add_library(foo-lib STATIC ${PROTO_SRC} ${PROTO_HEAD})
target_include_directories(foo-lib INTERFACE ${CMAKE_CURRENT_BINARY_DIR}/src_gen)
target_link_libraries(foo-lib PUBLIC protobufc::libprotobuf-c)

add_executable(main main.c)
target_link_libraries(main foo-lib)

add_executable(alea alea.c)
target_link_libraries(alea foo-lib)

enable_testing()

add_test(NAME main
    COMMAND ${CMAKE_SOURCE_DIR}/run.sh
    WORKING_DIRECTORY ${CURRENT_BINARY_DIR})
