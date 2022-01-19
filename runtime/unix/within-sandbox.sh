#!/bin/bash
# --------------------------
# within-sandbox.sh [-b BUILDTYPE] -p PLATFORM command ...
#
# Analog of within-dev.sh. Most of the same environment variables should be set albeit with different values.
#
# Note about mounting volumes:
#   We never mount a directory inside another critical directory where we place other files
#   because it is not well-defined how Docker behaves (_all_ of its versions and platforms).
#   Example: mounting /home/user/.opam within critical directory /home/user/ is bad.
#   Instead we mount in the `/` directory or some other mount exclusive directory like `/mnt`.
#   You can always symlink inside /home/user/ or other essential directory to the mounted directory.
# --------------------------
set -euf

# ------------------
# BEGIN Command line processing

usage() {
    echo "Usage:" >&2
    echo "    within-sandbox.sh -h                            Display this help message." >&2
    echo "    within-sandbox.sh [-b] -p PLATFORM              Enter the Build Sandbox with an interactive bash shell." >&2
    echo "    within-sandbox.sh [-b] -p PLATFORM command ...  Run the command and any arguments in the Build Sandbox." >&2
    echo "Options:" >&2
    echo "       -p PLATFORM: The target platform (not 'dev') used. DKML_TOOLS_DIR will be based on this" >&2
    echo "       -b BUILDTYPE: If specified, will set DKML_DUNE_BUILD_DIR in the Build Sandbox" >&2
    echo "Advanced Options:" >&2
    echo "       -c: If specified, compilation flags like CC are added to the environment." >&2
    echo "             This can take several seconds on Windows since vcdevcmd.bat needs to run" >&2
    echo "       -0 PREHOOK_SCRIPT: If specified, the script will be 'eval'-d upon" >&2
    echo "             entering the Build Sandbox _before_ any the opam command is run." >&2
    echo "       -1 PREHOOK_DOUBLE: If specified, the Bash statements will be 'eval'-d, 'dos2unix'-d and 'eval'-d" >&2
    echo "             upon entering the Build Sandbox _before_ any other commands are run but" >&2
    echo "             _after_ the PATH has been established." >&2
    echo "             It behaves similar to:" >&2
    echo '               eval "the PREHOOK_DOUBLE you gave" > /tmp/eval.sh' >&2
    echo '               eval /tmp/eval.sh' >&2
    echo '             Useful for setting environment variables (possibly from a script).' >&2
}

# no arguments should display usage
if [ $# -eq 0 ]; then
    usage
    exit 1
fi

PLATFORM=
BUILDTYPE=
PREHOOK_SINGLE=
PREHOOK_DOUBLE=
COMPILATION=OFF
while getopts ":hp:b:0:1:c" opt; do
    case ${opt} in
        h )
            usage
            exit 0
        ;;
        p )
            PLATFORM=$OPTARG
        ;;
        b )
            BUILDTYPE=$OPTARG
        ;;
        0 )
            PREHOOK_SINGLE=$OPTARG
        ;;
        1 )
            PREHOOK_DOUBLE=$OPTARG
        ;;
        c )
            COMPILATION=ON
        ;;
        \? )
            echo "This is not an option: -$OPTARG" >&2
            usage
            exit 1
        ;;
    esac
done
shift $((OPTIND -1))

if [ "${DKML_FEATUREFLAG_CMAKE_PLATFORM:-OFF}" = OFF ] && [ -z "$PLATFORM" ]; then
    usage
    exit 1
fi

# END Command line processing
# ------------------

DKMLDIR=$(dirname "$0")
DKMLDIR=$(cd "$DKMLDIR"/../.. && pwd)

if [ -n "${BUILDTYPE:-}" ] || [ -n "${DKML_DUNE_BUILD_DIR:-}" ]; then
    # shellcheck disable=SC1091
    . "$DKMLDIR"/runtime/unix/_common_build.sh
else
    # shellcheck disable=SC1091
    . "$DKMLDIR"/vendor/dkml-runtime-common/unix/_common_tool.sh
fi

if [ "${DKML_FEATUREFLAG_CMAKE_PLATFORM:-OFF}" = OFF ]; then
    # Set DKML_VCPKG_HOST_TRIPLET
    platform_vcpkg_triplet
else
    # Set OPAMROOTDIR_BUILDHOST
    set_opamrootdir
fi

# Set DKML_VCPKG_MANIFEST_DIR if necessary
if [ -e "$TOPDIR/vcpkg.json" ]; then
    DKML_VCPKG_MANIFEST_DIR="$TOPDIR"
    if [ -x /usr/bin/cygpath ]; then DKML_VCPKG_MANIFEST_DIR=$(/usr/bin/cygpath -aw "$DKML_VCPKG_MANIFEST_DIR"); fi
    export DKML_VCPKG_MANIFEST_DIR
else
    unset DKML_VCPKG_MANIFEST_DIR
fi

# Use same technique of dockcross so we can let the developer see their own files with their own user/group
# shellcheck disable=SC2034
BUILDER_USER="$( id -un )"
BUILDER_UID="$( id -u )"
USER_IDS=(-e BUILDER_UID="$BUILDER_UID" -e BUILDER_GID="$( id -g )" -e BUILDER_USER="$BUILDER_USER" -e BUILDER_GROUP="$( id -gn )")

# Essential Docker arguments.
DOCKER_ARGS=(
    # Mount TOPDIR as /work
    -v "$TOPDIR":/opt/diskuv-ocaml-build-chroot/work
    # use DKML_xxx so no chance of conflict with any external programs. For example DKML_DUNE_BUILD_DIR is used within Esy.
    --env DKML_ROOT_VERSION="$dkml_root_version"    
    # whether to get compilation tools into environment
    --env SANDBOX_COMPILATION="$COMPILATION"
)

if [ "${DKML_FEATUREFLAG_CMAKE_PLATFORM:-OFF}" = OFF ]; then
    DOCKER_ARGS+=( --env DKML_VCPKG_TRIPLET="$DKML_VCPKG_HOST_TRIPLET" )
fi

# Save bash history if user is not root
if [ "$BUILDER_UID" -ne 0 ]; then
    BH="$HOME"/.diskuv-ocaml.bash_history
    if [ ! -e "$BH" ]; then
        touch "$BH"
    fi
    DOCKER_ARGS+=(-v "$BH":/opt/diskuv-ocaml-build-chroot/mnt/bash_history)
fi

# Autodetect OPAMROOT and mount it if present
if [ "${DKML_FEATUREFLAG_CMAKE_PLATFORM:-OFF}" = OFF ]; then
    if [ -e "${BUILD_BASEPATH}$OPAMROOT_IN_CONTAINER" ]; then
        DOCKER_ARGS+=(
            -v "${BUILD_BASEPATH}$OPAMROOT_IN_CONTAINER":/opt/diskuv-ocaml-build-chroot/mnt/opamroot
        )
    fi
else
    if [ -e "$OPAMROOTDIR_BUILDHOST" ]; then
        DOCKER_ARGS+=(
            -v "$OPAMROOTDIR_BUILDHOST":/opt/diskuv-ocaml-build-chroot/mnt/opamroot
        )
    fi
fi

# If and only if [-b DKML_DUNE_BUILD_DIR] specified
if [ -n "${BUILDTYPE:-}" ]; then
    DOCKER_ARGS+=(
        --env DKML_DUNE_BUILD_DIR="/work/$DKML_DUNE_BUILD_DIR"
    )
fi

# Detect or enable DKML_BUILD_TRACE
DKML_BUILD_TRACE=${DKML_BUILD_TRACE:-ON}
DOCKER_ARGS+=(
    --env DKML_BUILD_TRACE="$DKML_BUILD_TRACE"
)

# Pass through any prehooks
if [ -n "$PREHOOK_DOUBLE" ]; then
    # sandbox-entrypoint.sh will pick up the SANDBOX_PRE_HOOK_DOUBLE and do `eval <(eval "$SANDBOX_PRE_HOOK_DOUBLE")`.
    DOCKER_ARGS+=(
        --env SANDBOX_PRE_HOOK_SINGLE="$PREHOOK_SINGLE"
        --env SANDBOX_PRE_HOOK_DOUBLE="$PREHOOK_DOUBLE"
    )
fi

if [ "$DKML_BUILD_TRACE" = ON ]; then set -x; fi
exec docker run -it \
    "${USER_IDS[@]}" \
    "${DOCKER_ARGS[@]}" \
    --privileged \
    diskuv-ocaml/linux-build-"$PLATFORM" \
    "$@"
