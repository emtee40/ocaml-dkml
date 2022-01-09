#!/bin/sh
#
# This file has parts that are governed by one license and other parts that are governed by a second license (both apply).
# The first license is:
#   Licensed under https://github.com/ocaml/opam/blob/012103bc52bfd4543f3d6f59edde91ac70acebc8/LICENSE - LGPL 2.1 with special linking exceptions
# The second license (Apache License, Version 2.0) is below.
#
# ----------------------------
# Copyright 2021 Diskuv, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ----------------------------
#
# @jonahbeckford: 2021-10-26
# - This file is licensed differently than the rest of the Diskuv OCaml distribution.
#   Keep the Apache License in this file since this file is part of the reproducible
#   build files.
#
######################################
# reproducible-compile-ocaml-2-build_host.sh -d DKMLDIR -t TARGETDIR
#
# Purpose:
# 1. Build an OCaml environment including an OCaml native compiler that generates machine code for the
#    host ABI. Much of that follows
#    https://github.com/ocaml/opam/blob/012103bc52bfd4543f3d6f59edde91ac70acebc8/shell/bootstrap-ocaml.sh,
#    especially the Windows knobs.
#
# -------------------------------------------------------
set -euf

# ------------------
# BEGIN Command line processing

usage() {
    {
        printf "%s\n" "Usage:"
        printf "%s\n" "    reproducible-compile-ocaml-2-build_host.sh"
        printf "%s\n" "        -h             Display this help message."
        printf "%s\n" "        -d DIR -t DIR  Compile OCaml."
        printf "\n"
        printf "%s\n" "See 'reproducible-compile-ocaml-1-setup.sh -h' for more comprehensive docs."
        printf "\n"
        printf "%s\n" "Options"
        printf "%s\n" "   -d DIR: DKML directory containing a .dkmlroot file"
        printf "%s\n" "   -t DIR: Target directory for the reproducible directory tree"
        printf "%s\n" "   -b PREF: Required and used only for the MSVC compiler. See reproducible-compile-ocaml-1-setup.sh"
        printf "%s\n" "   -e DKMLHOSTABI: Uses the Diskuv OCaml compiler detector find a host ABI compiler"
        printf "%s\n" "   -i OCAMLCARGS: Optional. Extra arguments passed to ocamlc like -g to save debugging"
        printf "%s\n" "   -j OCAMLOPTARGS: Optional. Extra arguments passed to ocamlopt like -g to save debugging"
        printf "%s\n" "   -k HOSTABISCRIPT: Optional. See reproducible-compile-ocaml-1-setup.sh"
        printf "%s\n" "   -m CONFIGUREARGS: Optional. Extra arguments passed to OCaml's ./configure. --with-flexdll"
        printf "%s\n" "      and --host will have already been set appropriately, but you can override the --host heuristic by adding it"
        printf "%s\n" "      to -m CONFIGUREARGS"
    } >&2
}

DKMLDIR=
TARGETDIR=
DKMLHOSTABI=
CONFIGUREARGS=
OCAMLCARGS=
OCAMLOPTARGS=
HOSTABISCRIPT=
export MSVS_PREFERENCE=
while getopts ":d:t:b:e:m:i:j:k:h" opt; do
    case ${opt} in
        h )
            usage
            exit 0
        ;;
        d )
            DKMLDIR="$OPTARG"
            if [ ! -e "$DKMLDIR/.dkmlroot" ]; then
                printf "%s\n" "Expected a DKMLDIR at $DKMLDIR but no .dkmlroot found" >&2;
                usage
                exit 1
            fi
            DKMLDIR=$(cd "$DKMLDIR" && pwd) # absolute path
        ;;
        t )
            TARGETDIR="$OPTARG"
        ;;
        b )
            MSVS_PREFERENCE="$OPTARG"
        ;;
        e )
            DKMLHOSTABI="$OPTARG"
        ;;
        m )
            CONFIGUREARGS="$OPTARG"
        ;;
        i)
            OCAMLCARGS="$OPTARG"
            ;;
        j)
            OCAMLOPTARGS="$OPTARG"
            ;;
        k)
            HOSTABISCRIPT="$OPTARG"
            ;;
        \? )
            printf "%s\n" "This is not an option: -$OPTARG" >&2
            usage
            exit 1
        ;;
    esac
done
shift $((OPTIND -1))

if [ -z "$DKMLDIR" ] || [ -z "$TARGETDIR" ] || [ -z "$DKMLHOSTABI" ]; then
    printf "%s\n" "Missing required options" >&2
    usage
    exit 1
fi

# END Command line processing
# ------------------

# Need feature flag and usermode and statedir until all legacy code is removed in _common_tool.sh
# shellcheck disable=SC2034
DKML_FEATUREFLAG_CMAKE_PLATFORM=ON
# shellcheck disable=SC2034
USERMODE=ON
# shellcheck disable=SC2034
STATEDIR=

# shellcheck disable=SC1091
. "$DKMLDIR/runtime/unix/_common_tool.sh"

disambiguate_filesystem_paths

# Bootstrapping vars
TARGETDIR_UNIX=$(cd "$TARGETDIR" && pwd) # better than cygpath: handles TARGETDIR=. without trailing slash, and works on Unix/Windows
if [ -x /usr/bin/cygpath ]; then
    OCAMLSRC_UNIX=$(/usr/bin/cygpath -au "$TARGETDIR_UNIX/src/ocaml")
else
    OCAMLSRC_UNIX="$TARGETDIR_UNIX/src/ocaml"
fi

# ------------------

# Prereqs for reproducible-compile-ocaml-functions.sh
autodetect_system_binaries
autodetect_system_path

# shellcheck disable=SC1091
. "$DKMLDIR/installtime/unix/private/reproducible-compile-ocaml-functions.sh"

if [ -n "$HOSTABISCRIPT" ]; then
    case "$HOSTABISCRIPT" in
    /* | ?:*) # /a/b/c or C:\Windows
    ;;
    *) # relative path; need absolute path since we will soon change dir to $OCAMLSRC_UNIX
    HOSTABISCRIPT="$DKMLDIR/$HOSTABISCRIPT"
    ;;
    esac
fi

cd "$OCAMLSRC_UNIX"

# ./configure
ocaml_configure "$TARGETDIR_UNIX" "$DKMLHOSTABI" "$HOSTABISCRIPT" "$CONFIGUREARGS"

# TODO: Propagate OCAMLCARGS and OCAMLOPTARGS, perhaps through CAMLC and CAMLOPT Makefile
# TODO: variables.

# make
if [ "$OCAML_CONFIGURE_NEEDS_MAKE_FLEXDLL" = ON ]; then
    ocaml_make "$DKMLHOSTABI" flexdll
fi
ocaml_make "$DKMLHOSTABI" -j world
ocaml_make "$DKMLHOSTABI" -j "${BOOTSTRAP_OPT_TARGET:-opt.opt}"
if [ "$OCAML_CONFIGURE_NEEDS_MAKE_FLEXDLL" = ON ]; then
    ocaml_make "$DKMLHOSTABI" flexlink.opt
fi
ocaml_make "$DKMLHOSTABI" install
