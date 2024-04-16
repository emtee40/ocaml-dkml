#!/bin/sh
set -euf

# [ctypes.0.19.2-windowssupport-r6] requirements:
# - The following required C libraries are missing: libffi.
#       shellcheck disable=SC2050
if [ "@CMAKE_HOST_WIN32@" = 1 ] && [ ! -e /clang64/lib/libffi.a ]; then
    # 32-bit? mingw-w64-i686-libffi
    pacman -Sy --noconfirm --needed mingw-w64-clang-x86_64-libffi
fi

