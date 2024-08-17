#!/bin/sh
set -euf

export DKMLDIR='@DKML_ROOT_DIR@'

#       shellcheck disable=SC1091
. '@UPSERT_UTILS@'
unset OPAMSWITCH # Interferes with init-opam-root.sh and create-opam-switch.sh

# shellcheck disable=SC2050
if [ "@CMAKE_HOST_WIN32@" = 1 ]; then
    # Get rid of annoying warning in prereleases of Opam 2.2
    "$OPAM_EXE" option --root "$OPAMROOT" --global depext=false
fi

# Make %{dkml-sys-opam-exe}% available
#       shellcheck disable=SC2050
if [ "@CMAKE_HOST_WIN32@" = 1 ] && [ -x /usr/bin/cygpath ]; then
    DKML_SYS_OPAM_EXE=$(/usr/bin/cygpath -aw "$OPAM_EXE")
else
    DKML_SYS_OPAM_EXE=$OPAM_EXE
fi
"$OPAM_EXE" var --global "dkml-sys-opam-exe=$DKML_SYS_OPAM_EXE"

# Make %{dkml-debug-env-failures}% available on machines with
# [flag-dkml-debug-env-failures]
#       shellcheck disable=SC2194
case "@FLAG_DKML_DEBUG_ENV_FAILURES@" in
    1|true|TRUE|True|on|ON|On)
        "$OPAM_EXE" var --global "dkml-debug-env-failures=true" ;;
    *)
        "$OPAM_EXE" var --global "dkml-debug-env-failures=false"
esac
