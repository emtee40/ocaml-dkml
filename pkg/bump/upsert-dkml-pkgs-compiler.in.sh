#!/bin/sh
set -euf

export DKMLDIR='@DKML_ROOT_DIR@'

#       shellcheck disable=SC1091
. '@UPSERT_UTILS@'

#   Default for compiler is ON and 2
DKML_BUILD_TRACE=${DKML_BUILD_TRACE:-ON}
DKML_BUILD_TRACE_LEVEL=${DKML_BUILD_TRACE_LEVEL:-2}
export DKML_BUILD_TRACE
export DKML_BUILD_TRACE_LEVEL

# Add or upgrade compiler packages.
# - In topological order so don't have unnecessary reinstalls
# - dkml-base-compiler can find its own C compiler, so it does not need
#   WITH_COMPILER_SH. However, during an opam recompile (perhaps
#   dkml-base-compiler was updated) many already-installed packages will
#   need a C compiler. This lack of C compiler won't appear during the initial
#   install (because dkml-base-compiler does not need it), but will during a
#   recompile. So we force the use of WITH_COMPILER_SH.
idempotent_opam_local_install dkml-compiler-TRANSITIVE \
    '@dkml-compiler_SHORTREF@,@dkml-runtime-common_SHORTREF@' \
    '@PROJECT_SOURCE_DIR@' \
    '@dkml-compiler_REL_SOURCE_DIR@/dkml-base-compiler.opam' \
    '@dkml-runtime-common_REL_SOURCE_DIR@/dkml-runtime-common.opam' @compiler_ADJUNCT_PACKAGES_SPACES@

# ensure from here on that [ocaml-system] is not installed through
# an inadvertent re-compile of [ocaml].
"$OPAM_EXE" switch set-invariant dkml-base-compiler @compiler_ADJUNCT_PACKAGES_SPACES@ --yes
