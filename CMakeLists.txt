cmake_minimum_required(VERSION 3.9)

# set(CMAKE_C_COMPILER gcc-8)
# set(CMAKE_CXX_COMPILER g++-8)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_EXPORT_COMPILE_COMMANDS on)

include(ExternalProject)

include(protobuf.cmake)
include(protobuf-c.cmake)
include(zeromq.cmake)

enable_testing()


# C bindings
#
protobufc_generate_c(PROTO_SRC PROTO_HEAD foo.proto)

add_library(foo-lib STATIC ${PROTO_SRC} ${PROTO_HEAD})
target_include_directories(foo-lib INTERFACE ${CMAKE_CURRENT_BINARY_DIR}/src_gen)
target_link_libraries(foo-lib PUBLIC protobuf-c::libprotobuf-c)

add_executable(main main.c)
target_link_libraries(main foo-lib)

add_executable(alea alea.c)
target_link_libraries(alea foo-lib)

add_test(NAME main
    COMMAND ${CMAKE_SOURCE_DIR}/run.sh
    WORKING_DIRECTORY ${CURRENT_BINARY_DIR})


# C++ bindings
#
protobuf_generate_cpp(PROTO_CXX_SRC PROTO_CXX_HEAD foo.proto)
add_library(foo-cpp-lib STATIC ${PROTO_CXX_SRC} ${PROTO_CXX_HEAD})
target_include_directories(foo-cpp-lib INTERFACE ${CMAKE_CURRENT_BINARY_DIR}/ PUBLIC ${Protobuf_INCLUDE_DIR})
target_link_libraries(foo-cpp-lib PUBLIC ${Protobuf_LIBRARY})

add_executable(mainxx mainxx.cpp)
target_link_libraries(mainxx foo-cpp-lib)


# zeromq
#
add_executable(zmq_sub zmq_sub.cpp)
target_link_libraries(zmq_sub zeromq::libzmq)

add_executable(zmq_pub zmq_pub.cpp)
target_link_libraries(zmq_pub zeromq::libzmq)
