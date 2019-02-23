# zeromq.cmake
# rene-d 02/2019

set(URL https://github.com/zeromq/libzmq/releases/download/v4.3.1/zeromq-4.3.1.tar.gz)


ExternalProject_Add(
    zeromq-external
  PREFIX ${CMAKE_CURRENT_BINARY_DIR}/zeromq
  URL ${URL}
  CMAKE_CACHE_ARGS
    "-DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}"
    "-DCMAKE_CXX_COMPILER:STRING=${CMAKE_CXX_COMPILER}"
    "-DCMAKE_CXX_STANDARD:STRING=14"
    "-DCMAKE_INSTALL_PREFIX:FILEPATH=${CMAKE_CURRENT_BINARY_DIR}/externals"
    "-DBUILD_TESTS:BOOL=OFF"
    "-DBUILD_SHARED:BOOL=OFF"
    "-DBUILD_STATIC:BOOL=ON"
    "-DWITH_DOCS:BOOL=OFF"
    "-DWITH_LIBSODIUM:BOOL=OFF"
    "-DENABLE_DRAFTS:BOOL=OFF"
#  SOURCE_SUBDIR .
#  LOG_CONFIGURE 1
#  BUILD_ALWAYS 1
#  STEP_TARGETS build
#  INSTALL_COMMAND ""  #Skip
)


set(Zeromq_ROOT ${CMAKE_CURRENT_BINARY_DIR}/externals)

set(Zeromq_INCLUDE_DIR ${Zeromq_ROOT}/include)
set(Zeromq_LIBRARY ${Zeromq_ROOT}/lib/libzmq.a)
set(Zeromq_LIBRARY_DEBUG ${Zeromq_ROOT}/lib/libzmq.a)
set(Zeromq_LIBRARY_RELEASE ${Zeromq_ROOT}/lib/libzmq.a)


if(Zeromq_LIBRARY)
    if(NOT TARGET zeromq::libzmq)
        add_library(zeromq::libzmq UNKNOWN IMPORTED)
        set_target_properties(zeromq::libzmq PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${Zeromq_INCLUDE_DIR}")
        set_target_properties(zeromq::libzmq PROPERTIES
            IMPORTED_LOCATION "${Zeromq_LIBRARY}")
        set_property(TARGET zeromq::libzmq APPEND PROPERTY
            IMPORTED_CONFIGURATIONS RELEASE)
        set_target_properties(zeromq::libzmq PROPERTIES
            IMPORTED_LOCATION_RELEASE "${Zeromq_LIBRARY_RELEASE}")

        set_property(TARGET zeromq::libzmq APPEND PROPERTY
            IMPORTED_CONFIGURATIONS DEBUG)
        set_target_properties(zeromq::libzmq PROPERTIES
            IMPORTED_LOCATION_DEBUG "${Zeromq_LIBRARY_DEBUG}")
    endif()
endif()

add_dependencies(zeromq::libzmq zeromq-external)
