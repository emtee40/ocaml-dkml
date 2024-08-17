#!/bin/sh

# ================
# checkout-code.sh
# ================
#
# Checkouts all of the git source code.
#
# This should be done outside of
# dockcross (used by Linux) since a Docker-in-Docker container can have
# difficulties doing a git checkout (the Git credentials for any private
# repositories are likely not present). We don't care about any private
# repositories for DkML but any code that extends this (ex. DKSDK) may
# need to use private repositories.

set -euf

setup_WORKSPACE_VARNAME=$1
shift
setup_WORKSPACE=$1
shift

if [ -x /usr/bin/cygpath ]; then
    setup_WORKSPACE=$(/usr/bin/cygpath -au "$setup_WORKSPACE")
fi

# ------------------------ Functions ------------------------

# shellcheck source=./common-values.sh
. .ci/sd4/common-values.sh

do_git() {
    if [ -z "${GIT_LOCATION:-}" ]; then
        git "$@"
    else
        PATH="$GIT_LOCATION:$PATH" git "$@"
    fi
}

# Disable automatic garbage collection
git_disable_gc() {
    git_disable_gc_NAME=$1
    shift
    do_git -C ".ci/sd4/g/$git_disable_gc_NAME" config --local gc.auto 0
}

# Mimic the behavior of GitHub's actions/checkout@v3
# - the plus symbol in 'git fetch ... origin +REF:refs/tags/v0.0' overrides any existing REF
git_checkout() {
    git_checkout_NAME=$1
    shift
    git_checkout_URL=$1
    shift
    git_checkout_REF=$1
    shift

    case "$git_checkout_REF" in
      file://*)
        git_checkout_FILEURI=$(printf "%s" "$git_checkout_REF" | sed 's#^file://##')
        rm -rf ".ci/sd4/g/$git_checkout_NAME"
        cp -rp "$git_checkout_FILEURI" ".ci/sd4/g/$git_checkout_NAME" ;;
      *)
        if [ -e ".ci/sd4/g/$git_checkout_NAME" ]; then
            git_disable_gc "$git_checkout_NAME"
            do_git -C ".ci/sd4/g/$git_checkout_NAME" remote set-url origin "$git_checkout_URL"
            do_git -C ".ci/sd4/g/$git_checkout_NAME" fetch --no-tags --progress --no-recurse-submodules --depth=1 origin "+${git_checkout_REF}:refs/tags/v0.0"
        else
            install -d ".ci/sd4/g/$git_checkout_NAME"
            do_git -C ".ci/sd4/g/$git_checkout_NAME" -c init.defaultBranch=main init
            git_disable_gc "$git_checkout_NAME"
            do_git -C ".ci/sd4/g/$git_checkout_NAME" remote add origin "$git_checkout_URL"
            do_git -C ".ci/sd4/g/$git_checkout_NAME" fetch --no-tags --prune --progress --no-recurse-submodules --depth=1 origin "+${git_checkout_REF}:refs/tags/v0.0"
        fi
        do_git -C ".ci/sd4/g/$git_checkout_NAME" -c advice.detachedHead=false checkout --progress --force refs/tags/v0.0
        do_git -C ".ci/sd4/g/$git_checkout_NAME" log -1 --format='%H' ;;
    esac
}

# ---------------------------------------------------------------------

section_begin checkout-info "Summary: code checkout"

PIN_DKML_RUNTIME_DISTRIBUTION=${PIN_DKML_RUNTIME_DISTRIBUTION:-}
TAG_DKML_RUNTIME_DISTRIBUTION=${TAG_DKML_RUNTIME_DISTRIBUTION:-$PIN_DKML_RUNTIME_DISTRIBUTION}
DKML_RUNTIME_DISTRIBUTION=${DKML_RUNTIME_DISTRIBUTION:-$TAG_DKML_RUNTIME_DISTRIBUTION}

# shellcheck disable=SC2154
echo "
================
checkout-code.sh
================
.
---------
Arguments
---------
WORKSPACE_VARNAME=$setup_WORKSPACE_VARNAME
WORKSPACE=$setup_WORKSPACE
.
------
Inputs
------
VERBOSE=${VERBOSE:-}
.
-------
Context
-------
GIT_LOCATION=${GIT_LOCATION:-}
.
------
Matrix
------
dkml_host_abi=$dkml_host_abi
.
---------
Constants
---------
PIN_DKML_RUNTIME_DISTRIBUTION=${PIN_DKML_RUNTIME_DISTRIBUTION}
TAG_DKML_RUNTIME_DISTRIBUTION=${TAG_DKML_RUNTIME_DISTRIBUTION}
DKML_RUNTIME_DISTRIBUTION=${DKML_RUNTIME_DISTRIBUTION}
.
"

section_end checkout-info

install -d .ci/sd4/g

# dkml-runtime-distribution

#   For 'Diagnose Visual Studio environment variables (Windows)' we need dkml-runtime-distribution
#   so that 'Import-Module Machine' and 'Get-VSSetupInstance' can be run.
#   More importantly, for 'Locate Visual Studio (Windows)' we need dkml-runtime-distribution's
#   'Get-CompatibleVisualStudios' and 'Get-VisualStudioProperties'.
case "$dkml_host_abi" in
windows_*)
    section_begin checkout-dkml-runtime-distribution 'Checkout dkml-runtime-distribution'
    git_checkout dkml-runtime-distribution https://github.com/diskuv/dkml-runtime-distribution.git "$DKML_RUNTIME_DISTRIBUTION"
    section_end checkout-dkml-runtime-distribution
    ;;
esac
