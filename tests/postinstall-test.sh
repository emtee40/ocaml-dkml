#!/bin/sh
set -euf
export OCAMLRUNPARAM=b

sandbox=$(dirname "$0")
sandbox=$(cd "$sandbox" && pwd)

# Place usr/bin/ and bin/ into PATH
if [ -x /usr/bin/uname ] && [ "$(/usr/bin/uname -s)" = Darwin ]; then
    # bug: dkml-install-api/package/console/common/dkml_package_console_common.ml[i] says
    # to place in Applications/DkMLNative.app/ in the .mli but does not do that in the .ml.
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

    # Initialize the DkML system.
    # Optional since done automatically with the first ocamlopt/dune/opam/... but test it explicitly.
    # --disable-sandboxing is needed on macOS/Linux because the installation path of DkMLNative
    # is not known apriori (it can be customized by the user).
    dkml init --yes --disable-sandboxing

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
