#!/bin/sh
set -eufx

## ---- These instructions should be the same as in the README.md ----
# This test gets as far as installing `dune` from `opam` so we know that GLIBC versions are OK
# and basic end-user steps work.

#curl --proto '=https' --tlsv1.2 -sSf -o i0.tar.gz https://gitlab.com/dkml/distributions/dkml/-/jobs/5666906090/artifacts/raw/dkml-native-linux_x86_64-i-2.1.0.tar.gz
set +f && ln -sf dkml-native-linux_x86_64-i-*.tar.gz i0.tar.gz && set -f

install -d i0 && tar xCfz i0 i0.tar.gz --strip-components 1
CAML_LD_LIBRARY_PATH=i0/sg/staging-ocamlrun/linux_x86_64/lib/ocaml/stublibs i0/sg/staging-ocamlrun/linux_x86_64/bin/ocamlrun i0/bin/dkml-package.bc -v
rm -rf i0 i0.tar.gz

export OPAMROOTISOK=1 "PATH=$HOME/.local/share/dkml-native/usr/bin:$HOME/.local/share/dkml-native/bin:$PATH"
echo '#quit;;' | utop
opam --version
install -d ~/localswitch && cd ~/localswitch && dkml init --disable-sandboxing && opam install dune
