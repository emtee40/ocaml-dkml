#!/bin/sh

# shellcheck disable=SC1091
. unix/crossplatform-functions.sh

# Test Vectors
#   NIST.1
sha256check tests/nist.1.txt ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad
