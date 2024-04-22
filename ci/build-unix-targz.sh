#!/bin/sh
set -euf

arch=$1
shift
variant=$1
shift

ver=$(.ci/cmake/bin/cmake -P cmake/get-version.cmake)

case "$arch,$variant" in
    linux_*,dockcross)      .ci/cmake/bin/cmake --preset ci-reproduce -G Ninja -D SKIP_CMDRUN=1 -D DKML_HOST_LINUX_DOCKER=0 ;;
    linux_*,*)              .ci/cmake/bin/cmake --preset ci-reproduce -G Ninja -D DKML_HOST_LINUX_DOCKER=0 ;;
    darwin_x86_64,standard) .ci/cmake/bin/cmake --preset ci-reproduce -G Ninja -D DKML_HOST_ABI=darwin_x86_64 -D DKML_TARGET_ABI=darwin_x86_64 ;;
    darwin_arm64,standard)  .ci/cmake/bin/cmake --preset ci-reproduce -G Ninja -D DKML_HOST_ABI=darwin_arm64 -D DKML_TARGET_ABI=darwin_arm64 ;;
    *)                      echo "Unknown arch,variant option: $arch,$variant." >&2; exit 1
esac

.ci/cmake/bin/cmake --build --preset ci-reproduce

"build/pkg/bump/.ci/o/$ver/share/dkml-installer-ocaml-network/t/bundle-dkml-native-$arch-i.sh" tar
"build/pkg/bump/.ci/o/$ver/share/dkml-installer-ocaml-network/t/bundle-dkml-native-$arch-u.sh" tar
gzip "dkml-native-$arch-i-$ver.tar" "dkml-native-$arch-u-$ver.tar"
