#! /bin/bash

set -e

# test program
if [ "$1" == "alea" ]; then
    ./$*
else
    ./main
fi
echo ""

# unpack data
protoc --decode=Foo -I$(dirname $0) foo.proto < data.bin
