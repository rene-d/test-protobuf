#! /bin/bash

set -e

# test program
./main

# unpack data
protoc --decode=Foo -I$(dirname $0) foo.proto < data.bin
