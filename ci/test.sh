#!/bin/sh
set -euf

arch=$1
shift

ver=$(.ci/cmake/bin/cmake -P cmake/get-version.cmake)

# Install
install -d box && tar xCf box "dkml-native-$arch-i-$ver.tar" --strip-components 1
"box/sg/staging-ocamlrun/$arch/bin/ocamlrun" box/bin/dkml-package.bc -vv
OCAMLRUNPARAM=b ~/Applications/DkMLNative/bin/dkml init
