#!/bin/sh
set -euf

FLAVOR=$1
shift
CHANNEL=$1
shift

# shellcheck disable=SC2154
echo "
=============
build-test.sh
=============
.
---------
Arguments
---------
FLAVOR=$FLAVOR
CHANNEL=$CHANNEL
.
------
Matrix
------
dkml_host_abi=$dkml_host_abi
abi_pattern=$abi_pattern
opam_root=$opam_root
exe_ext=${exe_ext:-}
.
"

preinstall() {
    true
}
case "$CHANNEL" in
next)
    preinstall() {
        opamrun pin dkml-runtime-common         git+https://github.com/diskuv/dkml-runtime-common.git#main --switch dkml --no-action --yes
        opamrun pin dkml-runtime-distribution   git+https://github.com/diskuv/dkml-runtime-distribution.git#main --switch dkml --no-action --yes
    }
    ;;
release)
    ;;
*)
    echo "FATAL: The CHANNEL must be 'release' or 'next'"; exit 3
esac

# Set project directory
if [ -n "${CI_PROJECT_DIR:-}" ]; then
    PROJECT_DIR="$CI_PROJECT_DIR"
elif [ -n "${PC_PROJECT_DIR:-}" ]; then
    PROJECT_DIR="$PC_PROJECT_DIR"
elif [ -n "${GITHUB_WORKSPACE:-}" ]; then
    PROJECT_DIR="$GITHUB_WORKSPACE"
else
    PROJECT_DIR="$PWD"
fi
if [ -x /usr/bin/cygpath ]; then
    PROJECT_DIR=$(/usr/bin/cygpath -au "$PROJECT_DIR")
fi

# PATH. Add opamrun
export PATH="$PROJECT_DIR/.ci/sd4/opamrun:$PATH"

# Where to stage files before we make a tarball archive
STAGE_RELDIR=.ci/stage-build
rm -rf "$STAGE_RELDIR"
install -d "$STAGE_RELDIR"

# Initial Diagnostics (optional but useful)
opamrun switch
opamrun list --switch dkml
opamrun var --switch dkml
opamrun config report --switch dkml
opamrun option --switch dkml
opamrun exec --switch dkml -- ocamlc -config

# ----------- Primary Switch ------------

install -d .ci

# Update
case "$CHANNEL" in
next)
    opamrun repository set-url diskuv git+https://github.com/diskuv/diskuv-opam-repository.git
esac
opamrun update

#   Use latest dkml-runtime-distribution when channel=next in the secondary switch
if [ "$CHANNEL" = next ]; then
    opamrun pin dkml-runtime-common         git+https://github.com/diskuv/dkml-runtime-common.git#main --switch dkml --no-action --yes
    opamrun pin dkml-runtime-distribution   git+https://github.com/diskuv/dkml-runtime-distribution.git#main --switch dkml --no-action --yes
    opamrun pin dkml-runtimelib             git+https://github.com/diskuv/dkml-runtime-apps.git#main --switch dkml --no-action --yes
    opamrun pin with-dkml                   git+https://github.com/diskuv/dkml-runtime-apps.git#main --switch dkml --no-action --yes
fi

# Inform packages (especially dkml-component-staging-desktop-*) where opam executable is
DKML_SYS_OPAM_EXE=$(opamrun exec --switch dkml -- sh -c "command -v opam")
opamrun var --global "dkml-sys-opam-exe=$DKML_SYS_OPAM_EXE"

# Test by compiling
FLAVOR_LOWER=$(printf "%s" "$FLAVOR" | tr '[:upper:]' '[:lower:]')
opamrun install "./dkml-component-staging-desktop-$FLAVOR_LOWER" --switch dkml --yes
