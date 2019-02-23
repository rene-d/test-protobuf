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

# find_package(Protobuf REQUIRED)

#
#
set(external ${CMAKE_CURRENT_BINARY_DIR}/externals)

set(Protobuf_INCLUDE_DIR ${external}/include)
set(Protobuf_INCLUDE_DIRS ${external}/include)
set(Protobuf_PROTOC_EXECUTABLE ${external}/bin/protoc)
set(Protobuf_LIBRARY ${external}/lib/libprotobuf.a)
set(Protobuf_LITE_LIBRARY ${external}/lib/libprotobuf-lite.a)
set(Protobuf_PROTOC_LIBRARY ${external}/lib/libprotoc.a)

message(STATUS "Protobuf_INCLUDE_DIRS = ${Protobuf_INCLUDE_DIRS}")
message(STATUS "Protobuf_LIBRARY = ${Protobuf_LIBRARY}")
message(STATUS "Protobuf_PROTOC_EXECUTABLE = ${Protobuf_PROTOC_EXECUTABLE}")

#
#
function(protobuf_generate)
  include(CMakeParseArguments)

  set(_options APPEND_PATH DESCRIPTORS)
  set(_singleargs LANGUAGE OUT_VAR EXPORT_MACRO PROTOC_OUT_DIR)
  if(COMMAND target_sources)
    list(APPEND _singleargs TARGET)
  endif()
  set(_multiargs PROTOS IMPORT_DIRS GENERATE_EXTENSIONS)

  cmake_parse_arguments(protobuf_generate "${_options}" "${_singleargs}" "${_multiargs}" "${ARGN}")

  if(NOT protobuf_generate_PROTOS AND NOT protobuf_generate_TARGET)
    message(SEND_ERROR "Error: protobuf_generate called without any targets or source files")
    return()
  endif()

  if(NOT protobuf_generate_OUT_VAR AND NOT protobuf_generate_TARGET)
    message(SEND_ERROR "Error: protobuf_generate called without a target or output variable")
    return()
  endif()

  if(NOT protobuf_generate_LANGUAGE)
    set(protobuf_generate_LANGUAGE cpp)
  endif()
  string(TOLOWER ${protobuf_generate_LANGUAGE} protobuf_generate_LANGUAGE)

  if(NOT protobuf_generate_PROTOC_OUT_DIR)
    set(protobuf_generate_PROTOC_OUT_DIR ${CMAKE_CURRENT_BINARY_DIR})
  endif()

  if(protobuf_generate_EXPORT_MACRO AND protobuf_generate_LANGUAGE STREQUAL cpp)
    set(_dll_export_decl "dllexport_decl=${protobuf_generate_EXPORT_MACRO}:")
  endif()

  if(NOT protobuf_generate_GENERATE_EXTENSIONS)
    if(protobuf_generate_LANGUAGE STREQUAL cpp)
      set(protobuf_generate_GENERATE_EXTENSIONS .pb.h .pb.cc)
    elseif(protobuf_generate_LANGUAGE STREQUAL python)
      set(protobuf_generate_GENERATE_EXTENSIONS _pb2.py)
    else()
      message(SEND_ERROR "Error: protobuf_generate given unknown Language ${LANGUAGE}, please provide a value for GENERATE_EXTENSIONS")
      return()
    endif()
  endif()

  if(protobuf_generate_TARGET)
    get_target_property(_source_list ${protobuf_generate_TARGET} SOURCES)
    foreach(_file ${_source_list})
      if(_file MATCHES "proto$")
        list(APPEND protobuf_generate_PROTOS ${_file})
      endif()
    endforeach()
  endif()

  if(NOT protobuf_generate_PROTOS)
    message(SEND_ERROR "Error: protobuf_generate could not find any .proto files")
    return()
  endif()

  if(protobuf_generate_APPEND_PATH)
    # Create an include path for each file specified
    foreach(_file ${protobuf_generate_PROTOS})
      get_filename_component(_abs_file ${_file} ABSOLUTE)
      get_filename_component(_abs_path ${_abs_file} PATH)
      list(FIND _protobuf_include_path ${_abs_path} _contains_already)
      if(${_contains_already} EQUAL -1)
          list(APPEND _protobuf_include_path -I ${_abs_path})
      endif()
    endforeach()
  else()
    set(_protobuf_include_path -I ${CMAKE_CURRENT_SOURCE_DIR})
  endif()

  foreach(DIR ${protobuf_generate_IMPORT_DIRS})
    get_filename_component(ABS_PATH ${DIR} ABSOLUTE)
    list(FIND _protobuf_include_path ${ABS_PATH} _contains_already)
    if(${_contains_already} EQUAL -1)
        list(APPEND _protobuf_include_path -I ${ABS_PATH})
    endif()
  endforeach()

  set(_generated_srcs_all)
  foreach(_proto ${protobuf_generate_PROTOS})
    get_filename_component(_abs_file ${_proto} ABSOLUTE)
    get_filename_component(_abs_dir ${_abs_file} DIRECTORY)
    get_filename_component(_basename ${_proto} NAME_WE)
    file(RELATIVE_PATH _rel_dir ${CMAKE_CURRENT_SOURCE_DIR} ${_abs_dir})

    set(_generated_srcs)
    foreach(_ext ${protobuf_generate_GENERATE_EXTENSIONS})
      list(APPEND _generated_srcs "${protobuf_generate_PROTOC_OUT_DIR}/${_basename}${_ext}")
    endforeach()

    if(protobuf_generate_DESCRIPTORS AND protobuf_generate_LANGUAGE STREQUAL cpp)
      set(_descriptor_file "${CMAKE_CURRENT_BINARY_DIR}/${_basename}.desc")
      set(_dll_desc_out "--descriptor_set_out=${_descriptor_file}")
      list(APPEND _generated_srcs ${_descriptor_file})
    endif()
    list(APPEND _generated_srcs_all ${_generated_srcs})

    add_custom_command(
      OUTPUT ${_generated_srcs}
      COMMAND  protobuf::protoc
      ARGS --${protobuf_generate_LANGUAGE}_out ${_dll_export_decl}${protobuf_generate_PROTOC_OUT_DIR} ${_dll_desc_out} ${_protobuf_include_path} ${_abs_file}
      DEPENDS ${_abs_file} protobuf::protoc
      COMMENT "Running ${protobuf_generate_LANGUAGE} protocol buffer compiler on ${_proto}"
      VERBATIM )
  endforeach()

  set_source_files_properties(${_generated_srcs_all} PROPERTIES GENERATED TRUE)
  if(protobuf_generate_OUT_VAR)
    set(${protobuf_generate_OUT_VAR} ${_generated_srcs_all} PARENT_SCOPE)
  endif()
  if(protobuf_generate_TARGET)
    target_sources(${protobuf_generate_TARGET} PRIVATE ${_generated_srcs_all})
  endif()
endfunction()

function(PROTOBUF_GENERATE_CPP SRCS HDRS)
  cmake_parse_arguments(protobuf_generate_cpp "" "EXPORT_MACRO;DESCRIPTORS" "" ${ARGN})

  set(_proto_files "${protobuf_generate_cpp_UNPARSED_ARGUMENTS}")
  if(NOT _proto_files)
    message(SEND_ERROR "Error: PROTOBUF_GENERATE_CPP() called without any proto files")
    return()
  endif()

  if(PROTOBUF_GENERATE_CPP_APPEND_PATH)
    set(_append_arg APPEND_PATH)
  endif()

  if(protobuf_generate_cpp_DESCRIPTORS)
    set(_descriptors DESCRIPTORS)
  endif()

  if(DEFINED PROTOBUF_IMPORT_DIRS AND NOT DEFINED Protobuf_IMPORT_DIRS)
    set(Protobuf_IMPORT_DIRS "${PROTOBUF_IMPORT_DIRS}")
  endif()

  if(DEFINED Protobuf_IMPORT_DIRS)
    set(_import_arg IMPORT_DIRS ${Protobuf_IMPORT_DIRS})
  endif()

  set(_outvar)
  protobuf_generate(${_append_arg} ${_descriptors} LANGUAGE cpp EXPORT_MACRO ${protobuf_generate_cpp_EXPORT_MACRO} OUT_VAR _outvar ${_import_arg} PROTOS ${_proto_files})

  set(${SRCS})
  set(${HDRS})
  if(protobuf_generate_cpp_DESCRIPTORS)
    set(${protobuf_generate_cpp_DESCRIPTORS})
  endif()

  foreach(_file ${_outvar})
    if(_file MATCHES "cc$")
      list(APPEND ${SRCS} ${_file})
    elseif(_file MATCHES "desc$")
      list(APPEND ${protobuf_generate_cpp_DESCRIPTORS} ${_file})
    else()
      list(APPEND ${HDRS} ${_file})
    endif()
  endforeach()
  set(${SRCS} ${${SRCS}} PARENT_SCOPE)
  set(${HDRS} ${${HDRS}} PARENT_SCOPE)
  if(protobuf_generate_cpp_DESCRIPTORS)
    set(${protobuf_generate_cpp_DESCRIPTORS} "${${protobuf_generate_cpp_DESCRIPTORS}}" PARENT_SCOPE)
  endif()
endfunction()




if(Protobuf_LIBRARY)
    if(NOT TARGET protobuf::libprotobuf)
        add_library(protobuf::libprotobuf UNKNOWN IMPORTED)
        set_target_properties(protobuf::libprotobuf PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${Protobuf_INCLUDE_DIR}")
        set_target_properties(protobuf::libprotobuf PROPERTIES
            IMPORTED_LOCATION "${Protobuf_LIBRARY}")
        set_property(TARGET protobuf::libprotobuf APPEND PROPERTY
            IMPORTED_CONFIGURATIONS RELEASE)
        set_target_properties(protobuf::libprotobuf PROPERTIES
            IMPORTED_LOCATION_RELEASE "${Protobuf_LIBRARY_RELEASE}")

        set_property(TARGET protobuf::libprotobuf APPEND PROPERTY
            IMPORTED_CONFIGURATIONS DEBUG)
        set_target_properties(protobuf::libprotobuf PROPERTIES
            IMPORTED_LOCATION_DEBUG "${Protobuf_LIBRARY_DEBUG}")

        if(UNIX AND TARGET Threads::Threads)
            set_property(TARGET protobuf::libprotobuf APPEND PROPERTY
                INTERFACE_LINK_LIBRARIES Threads::Threads)
        endif()
    endif()
endif()

if(Protobuf_LITE_LIBRARY)
    if(NOT TARGET protobuf::libprotobuf-lite)
        add_library(protobuf::libprotobuf-lite UNKNOWN IMPORTED)
        set_target_properties(protobuf::libprotobuf-lite PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${Protobuf_INCLUDE_DIR}")

        set_target_properties(protobuf::libprotobuf-lite PROPERTIES
            IMPORTED_LOCATION "${Protobuf_LITE_LIBRARY}")

        set_property(TARGET protobuf::libprotobuf-lite APPEND PROPERTY
            IMPORTED_CONFIGURATIONS RELEASE)
        set_target_properties(protobuf::libprotobuf-lite PROPERTIES
            IMPORTED_LOCATION_RELEASE "${Protobuf_LITE_LIBRARY_RELEASE}")

        set_property(TARGET protobuf::libprotobuf-lite APPEND PROPERTY
            IMPORTED_CONFIGURATIONS DEBUG)
        set_target_properties(protobuf::libprotobuf-lite PROPERTIES
            IMPORTED_LOCATION_DEBUG "${Protobuf_LITE_LIBRARY_DEBUG}")
        if(UNIX AND TARGET Threads::Threads)
            set_property(TARGET protobuf::libprotobuf-lite APPEND PROPERTY
                INTERFACE_LINK_LIBRARIES Threads::Threads)
        endif()
    endif()
endif()

if(Protobuf_PROTOC_LIBRARY)
    if(NOT TARGET protobuf::libprotoc)
        add_library(protobuf::libprotoc UNKNOWN IMPORTED)
        set_target_properties(protobuf::libprotoc PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${Protobuf_INCLUDE_DIR}")
        set_target_properties(protobuf::libprotoc PROPERTIES
            IMPORTED_LOCATION "${Protobuf_PROTOC_LIBRARY}")
        set_property(TARGET protobuf::libprotoc APPEND PROPERTY
            IMPORTED_CONFIGURATIONS RELEASE)
        set_target_properties(protobuf::libprotoc PROPERTIES
            IMPORTED_LOCATION_RELEASE "${Protobuf_PROTOC_LIBRARY_RELEASE}")
        set_property(TARGET protobuf::libprotoc APPEND PROPERTY
            IMPORTED_CONFIGURATIONS DEBUG)
        set_target_properties(protobuf::libprotoc PROPERTIES
            IMPORTED_LOCATION_DEBUG "${Protobuf_PROTOC_LIBRARY_DEBUG}")
        if(UNIX AND TARGET Threads::Threads)
            set_property(TARGET protobuf::libprotoc APPEND PROPERTY
                INTERFACE_LINK_LIBRARIES Threads::Threads)
        endif()
    endif()
endif()

if(Protobuf_PROTOC_EXECUTABLE)
    if(NOT TARGET protobuf::protoc)
        add_executable(protobuf::protoc IMPORTED)
        set_target_properties(protobuf::protoc PROPERTIES
            IMPORTED_LOCATION "${Protobuf_PROTOC_EXECUTABLE}")
    endif()
endif()


add_dependencies(protobuf::protoc  protobuf-external)
add_dependencies(protobuf::libprotoc  protobuf-external)
add_dependencies(protobuf::libprotobuf  protobuf-external)
add_dependencies(protobuf::libprotobuf-lite  protobuf-external)
