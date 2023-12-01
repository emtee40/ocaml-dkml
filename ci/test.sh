#!/bin/sh
set -euf

arch=$1
shift

ver=$(.ci/cmake/bin/cmake -P cmake/get-version.cmake)

# Unpack installer
install -d installer
if [ -e "dkml-native-$arch-i-$ver.tar.gz" ]; then
    tar xCfz installer "dkml-native-$arch-i-$ver.tar.gz" --strip-components 1
else
    tar xCf installer "dkml-native-$arch-i-$ver.tar" --strip-components 1
fi

# Run installer which on Unix just copies and edits the findlib + topfind packages with final install paths.
# Unlike Windows does not add to PATH ... that is your job.
CAML_LD_LIBRARY_PATH=$PWD/installer/sg/staging-ocamlrun/$arch/lib/ocaml/stublibs "installer/sg/staging-ocamlrun/$arch/bin/ocamlrun" installer/bin/dkml-package.bc -vv && rm -rf installer

# Do the post-install tests
exec sh tests/postinstall-test.sh
