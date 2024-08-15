#!/bin/sh
set -euf

usage() {
    echo "promote.sh CENTRAL_OPAM_REPO DKML_OPAM_VERSION" >&2
    echo "Ex. promote.sh /z/source/opam-repository 2.0.0" >&2
    exit 1
}

if [ $# -lt 2 ]; then usage; fi

CENTRAL_OPAM_REPO=$1
shift
DKML_OPAM_VERSION=$1
shift

HERE=$(dirname "$0")
HERE=$(cd "$HERE" && pwd)

copypkgver() {
    # .../packages/dkml-exe/dkml-exe.2.0.0
    copypkgver_PKGVERDIR=$1
    shift

    # .../packages/dkml-exe/dkml-exe.2.0.0 -> dkml-exe
    copypkgver_PKG=$(dirname "$copypkgver_PKGVERDIR")
    copypkgver_PKG=$(basename "$copypkgver_PKG")
    copypkgver_PKGVER=$(basename "$copypkgver_PKGVERDIR")

    echo "$copypkgver_PKGVER"
    install -d "$CENTRAL_OPAM_REPO/packages/$copypkgver_PKG/"
    rsync -a --delete "$copypkgver_PKGVERDIR" "$CENTRAL_OPAM_REPO/packages/$copypkgver_PKG/"
}

# ex. /z/source/dkml/build/_deps/diskuv-opam-repository-src/packages/dkml-exe/dkml-exe.2.0.0
PKGVERDIRS=$(find "$HERE/packages" -mindepth 2 -maxdepth 2 -name "*.$DKML_OPAM_VERSION")
for PKGVERDIR in $PKGVERDIRS; do
    copypkgver "$PKGVERDIR"
done

# ex. /z/source/dkml/build/_deps/diskuv-opam-repository-src/packages/dkml-base-compiler/dkml-base-compiler.4.14.0~v2.0.0
PKGVERDIRS=$(find "$HERE/packages" -mindepth 2 -maxdepth 2 -name "*.*~v$DKML_OPAM_VERSION")
for PKGVERDIR in $PKGVERDIRS; do
    copypkgver "$PKGVERDIR"
done

# The latest version of conf-withdkml
# ex. /z/source/dkml/build/_deps/diskuv-opam-repository-src/packages/conf-withdkml/conf-withdkml.2
PKGVERDIRS=$(find "$HERE/packages" -mindepth 2 -maxdepth 2 -name "conf-withdkml.*" | sort -nr | head -n1)
for PKGVERDIR in $PKGVERDIRS; do
    copypkgver "$PKGVERDIR"
done

# The latest version of conf-dkml-sys-opam
# ex. /z/source/dkml/build/_deps/diskuv-opam-repository-src/packages/conf-dkml-sys-opam/conf-dkml-sys-opam.1
PKGVERDIRS=$(find "$HERE/packages" -mindepth 2 -maxdepth 2 -name "conf-dkml-sys-opam.*" | sort -nr | head -n1)
for PKGVERDIR in $PKGVERDIRS; do
    copypkgver "$PKGVERDIR"
done
