# protobufc.cmake
# rene-d 02/2019


# GIT_REPOSITORY https://github.com/protobuf-c/protobuf-c
# GIT_TAG v1.2.1

# set(URL https://github.com/protobuf-c/protobuf-c/releases/download/v1.2.1/protobuf-c-1.2.1.tar.gz)
set(URL https://github.com/protobuf-c/protobuf-c/releases/download/v1.3.1/protobuf-c-1.3.1.tar.gz)


ExternalProject_Add(
  protobuf-c-external
  PREFIX ${CMAKE_CURRENT_BINARY_DIR}/protobuf-c
  URL ${URL}
  CMAKE_CACHE_ARGS
    "-DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}"
    "-DCMAKE_C_COMPILER:STRING=${CMAKE_C_COMPILER}"
    "-DCMAKE_CXX_COMPILER:STRING=${CMAKE_CXX_COMPILER}"
    "-DCMAKE_CXX_STANDARD:STRING=14"
    "-DCMAKE_INSTALL_PREFIX:FILEPATH=${CMAKE_CURRENT_BINARY_DIR}/externals"
    "-DCMAKE_POLICY_DEFAULT_CMP0074:STRING=NEW"
    "-DProtobuf_ROOT:FILEPATH=${CMAKE_CURRENT_BINARY_DIR}/externals"
  SOURCE_SUBDIR build-cmake
#    BUILD_ALWAYS 1
#    STEP_TARGETS build
#    INSTALL_COMMAND ""
)

add_dependencies(protobuf-c-external protobuf-external)


set(ProtobufC_INCLUDE_DIR ${CMAKE_CURRENT_BINARY_DIR}/externals/include)
set(ProtobufC_LIBRARY ${CMAKE_CURRENT_BINARY_DIR}/externals/lib/libprotobuf-c.a)
set(ProtobufC_PROTOC-C_EXECUTABLE ${CMAKE_CURRENT_BINARY_DIR}/externals/bin/protoc-c)
mark_as_advanced(ProtobufC_PROTOC-C_EXECUTABLE)


#
#
if(NOT TARGET protobufc::libprotobuf-c)
    file(MAKE_DIRECTORY ${ProtobufC_INCLUDE_DIR})

    add_library(protobufc::libprotobuf-c UNKNOWN IMPORTED)
    set_target_properties(protobufc::libprotobuf-c PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${ProtobufC_INCLUDE_DIR}")
    set_target_properties(protobufc::libprotobuf-c PROPERTIES
        IMPORTED_LOCATION "${ProtobufC_LIBRARY}")
    set_property(TARGET protobufc::libprotobuf-c APPEND PROPERTY
        IMPORTED_CONFIGURATIONS RELEASE)
    set_target_properties(protobufc::libprotobuf-c PROPERTIES
        IMPORTED_LOCATION_RELEASE "${ProtobufC_LIBRARY_RELEASE}")
    set_property(TARGET protobufc::libprotobuf-c APPEND PROPERTY
        IMPORTED_CONFIGURATIONS DEBUG)
    set_target_properties(protobufc::libprotobuf-c PROPERTIES
        IMPORTED_LOCATION_DEBUG "${ProtobufC_LIBRARY_DEBUG}")

endif()


add_dependencies(protobufc::libprotobuf-c protobuf-c-external)


#
#
function(protobufc_generate_c SRCS HDRS)
  if(NOT ARGN)
    message(SEND_ERROR "Error: protobufc_generate_c() called without any proto files")
    return()
  endif()

  if(PROTOBUFC_GENERATE_C_APPEND_PATH)
    # Create an include path for each file specified
    foreach(FIL ${ARGN})
      get_filename_component(ABS_FIL ${FIL} ABSOLUTE)
      get_filename_component(ABS_PATH ${ABS_FIL} PATH)
      list(FIND _protobufc_include_path ${ABS_PATH} _contains_already)
      if(${_contains_already} EQUAL -1)
          list(APPEND _protobufc_include_path -I ${ABS_PATH})
      endif()
    endforeach()
  else()
    set(_protobufc_include_path -I ${CMAKE_CURRENT_SOURCE_DIR})
  endif()

  if(DEFINED ProtobufC_IMPORT_DIRS AND NOT DEFINED ProtobufC_IMPORT_DIRS)
    set(ProtobufC_IMPORT_DIRS "${ProtobufC_IMPORT_DIRS}")
  endif()
 if(DEFINED ProtobufC_IMPORT_DIRS AND NOT DEFINED ProtobufC_IMPORT_DIRS)
    set(ProtobufC_IMPORT_DIRS "${ProtobufC_IMPORT_DIRS}")
  endif()

  if(DEFINED ProtobufC_IMPORT_DIRS)
    foreach(DIR ${ProtobufC_IMPORT_DIRS})
      get_filename_component(ABS_PATH ${DIR} ABSOLUTE)
      list(FIND _protobufc_include_path ${ABS_PATH} _contains_already)
      if(${_contains_already} EQUAL -1)
          list(APPEND _protobufc_include_path -I ${ABS_PATH})
      endif()
    endforeach()
  endif()

  set(${SRCS})
  set(${HDRS})
  foreach(FIL ${ARGN})
    get_filename_component(ABS_FIL ${FIL} ABSOLUTE)
    get_filename_component(FIL_WE ${FIL} NAME_WE)

    if(NOT PROTOBUFC_GENERATE_CPP_APPEND_PATH)
      get_filename_component(FIL_DIR ${FIL} DIRECTORY)
      if(FIL_DIR)
        set(FIL_WE "${FIL_DIR}/${FIL_WE}")
      endif()
    endif()

    set(_out_DIR "${CMAKE_CURRENT_BINARY_DIR}/src_gen")

    list(APPEND ${SRCS} "${_out_DIR}/${FIL_WE}.pb-c.c")
    list(APPEND ${HDRS} "${_out_DIR}/${FIL_WE}.pb-c.h")

    file(MAKE_DIRECTORY "${_out_DIR}")

    add_custom_command(
      OUTPUT "${_out_DIR}/${FIL_WE}.pb-c.c"
             "${_out_DIR}/${FIL_WE}.pb-c.h"
      COMMAND  ${ProtobufC_PROTOC-C_EXECUTABLE}
      ARGS --c_out  ${CMAKE_CURRENT_BINARY_DIR}/src_gen ${_protobufc_include_path} ${ABS_FIL}
      DEPENDS ${ABS_FIL} ${ProtobufC_PROTOC-C_EXECUTABLE}
      COMMENT "Running C protocol buffer compiler on ${FIL}"
      VERBATIM )
  endforeach()

  set_source_files_properties(${${SRCS}} ${${HDRS}} PROPERTIES GENERATED TRUE)
  set(${SRCS} ${${SRCS}} PARENT_SCOPE)
  set(${HDRS} ${${HDRS}} PARENT_SCOPE)
endfunction()
