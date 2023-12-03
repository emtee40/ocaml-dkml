#!/bin/sh
set -euf
awk '/set.DKML_VERSION_CMAKE/ && !/DKML_VERSION_CMAKEVER_OVERRIDE/{ gsub(/[^0-9.]/, "", $NF); print $NF}' version.cmake
