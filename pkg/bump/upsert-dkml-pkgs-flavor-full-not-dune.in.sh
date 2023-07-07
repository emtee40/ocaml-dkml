#!/bin/sh
set -euf

#       shellcheck disable=SC1091
. '@UPSERT_UTILS@'

# Add or upgrade prereqs
idempotent_opam_local_install dkml-runtime-common '' '@dkml-runtime-common_SOURCE_DIR@' ./dkml-runtime-common.opam
idempotent_opam_local_install dkml-compiler-env '' '@dkml-compiler_SOURCE_DIR@' ./dkml-compiler-env.opam
idempotent_opam_local_install dkml-runtime-distribution '' '@dkml-runtime-distribution_SOURCE_DIR@' ./dkml-runtime-distribution.opam

# [ctypes.0.19.2-windowssupport-r6] requirements:
# - The following required C libraries are missing: libffi.
#       shellcheck disable=SC2050
if [ "@CMAKE_HOST_WIN32@" = 1 ] && [ ! -e /clang64/lib/libffi.a ]; then
    # 32-bit? mingw-w64-i686-libffi
    pacman -Sy --noconfirm --needed mingw-w64-clang-x86_64-libffi
fi

# Add or upgrade the diskuv-opam-repository packages (except dkml-runtime-apps
# which we will do in the next step).
#
# Why add them if we don't deploy them immediately in the DkML installation?
# Because this [dkml] switch is used to collect the [pins.txt] used in
# [create-opam-switch.sh]. Besides, we have to make sure the packages
# actually build!
idempotent_opam_install dkml-unmanaged-patched-pkgs '@DKML_UNMANAGED_PATCHED_PACKAGES_PKGVERS_CKSUM@' @DKML_UNMANAGED_PATCHED_PACKAGES_SPACED_PKGVERS@

# Add or upgrade dkml-runtime-apps
idempotent_opam_local_install dkml-runtime-apps-installable '' '@dkml-runtime-apps_SOURCE_DIR@' @dkml-runtime-apps_SPACED_INSTALLABLE_OPAMFILES@

# Add or upgrade the Full distribution (minus Dune, minus conf-withdkml)
# * See upsert-dkml-pkgs-compiler.in for why we add packages like this)
# * There may be some overlap between these distribution packages and the patched
#   diskuv-opam-repository packages. That's fine!
# * We don't want [conf-withdkml] since that pulls in an external [with-dkml.exe]
#   which is not repeatable (ie. not hermetic).
idempotent_opam_install full-not-dune-flavor-no-withdkml '' @FULL_NOT_DUNE_FLAVOR_NO_WITHDKML_SPACED_PKGVERS@
