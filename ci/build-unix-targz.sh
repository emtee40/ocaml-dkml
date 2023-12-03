#!/bin/sh
set -euf

arch=$1
shift

ver=$(.ci/cmake/bin/cmake -P cmake/get-version.cmake)

.ci/cmake/bin/cmake --build --preset ci-reproduce

"build/pkg/bump/.ci/o/$ver/share/dkml-installer-ocaml-network/t/bundle-dkml-native-$arch-i.sh" tar
"build/pkg/bump/.ci/o/$ver/share/dkml-installer-ocaml-network/t/bundle-dkml-native-$arch-u.sh" tar
gzip "dkml-native-$arch-i-$ver.tar" "dkml-native-$arch-u-$ver.tar"
