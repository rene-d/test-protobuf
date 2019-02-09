#! /bin/bash

set -e

# protobuf/protobuf-c
if [ "$1" == "protobuf" ]; then
    mkdir -p build
    cmake -S . -B build
    cmake --build build
fi

# protobuf-c generated files
mkdir -p build/proto_gen
build/externals/bin/protoc-c --c_out=build/proto_gen foo.proto

# test program (well, too lazy to put that into cmake...)
g++-8 -o main -I build/externals/include -I build/proto_gen \
    build/proto_gen/foo.pb-c.c main.c \
    -lprotobuf-c -Lbuild/externals/lib

# run the test
./main

# show the packed data
protoc --decode=Foo foo.proto < data.bin
