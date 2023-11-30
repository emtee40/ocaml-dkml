#!/bin/sh
set -euf

sandbox=$(dirname "$0")
sandbox=$(cd "$sandbox" && pwd)

# Place usr/bin/ and bin/ into PATH
if [ -x /usr/bin/uname ] && [ "$(/usr/bin/uname -s)" = Darwin ]; then
    DKMLNATIVEDIR_BUILDHOST="$HOME/Applications/DkMLNative"
else
    # shellcheck disable=SC2034
    DKMLNATIVEDIR_BUILDHOST="${XDG_DATA_HOME:-$HOME/.local/share}/dkml-native"
fi
PATH="$DKMLNATIVEDIR_BUILDHOST/usr/bin:$DKMLNATIVEDIR_BUILDHOST/bin:$PATH"
export PATH

# [ocamlfind] is no longer installed in the global environment. https://github.com/diskuv/dkml-installer-ocaml/issues/83
# ocamlfind printconf

utop-full "$sandbox/script1/script.ocamlinit"

# Once ocaml has a shim, turn off || true
ocaml "$sandbox/script1/script.ocamlinit" || true

DKMLPARENTHOME_BUILDHOST="${XDG_DATA_HOME:-$HOME/.local/share}/dkml"
if [ -e "$DKMLPARENTHOME_BUILDHOST/dkmlvars.sh" ]; then
    # shellcheck disable=SC1091
    . "$DKMLPARENTHOME_BUILDHOST/dkmlvars.sh"
fi

if [ "${DiskuvOCamlMode:-}" = "byte" ]; then
    # Dune as of 3.8.3 requires explicit xxx.bc on the command line or else
    # it will do -output-complete-exe which requires a C linker
    dune build --root "$sandbox/scratch1/proj1" ./a.bc
    ocamlrun "$sandbox/scratch1/proj1/_build/default/a.bc"
else
    install -d scratch2
    cd scratch2

    dkml init --yes

    # install something with a low number of dependencies, that sufficiently exercises Opam
    opam install graphics --yes

    # regression test: https://discuss.ocaml.org/t/ann-diskuv-ocaml-1-x-x-windows-ocaml-installer-no-longer-in-preview/10309/8?u=jbeckford
    opam install ppx_jane --yes

    # regression test: https://github.com/diskuv/dkml-installer-ocaml/issues/12
    opam install pyml --yes

    # regression test: https://github.com/diskuv/dkml-installer-ocaml/issues/21
    opam install ocaml-lsp-server merlin --yes

    opam install ocamlformat --yes

    dune build --root "$sandbox/scratch1/proj2"
    dune exec --root "$sandbox/scratch1/proj2" ./best.exe    
fi
