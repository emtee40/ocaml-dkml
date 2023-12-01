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
    # it will do -output-complete-exe which requires a C linker.
    # NOTE: As of DkML 2.1.0 there is no global [dune].
    #    dune build --root "$sandbox/proj1" ./a.bc
    #    ocamlrun "$sandbox/proj1/_build/default/a.bc"
    true
else
    install -d scratch2
    cd scratch2

    # Initialize the DkML system.
    # Optional since done automatically with the first ocamlopt/dune/opam/... but test it explicitly.
    # --disable-sandboxing is needed on macOS/Linux because the installation path of DkMLNative
    # is not known apriori (it can be customized by the user).
    dkml init --yes --disable-sandboxing

    # install something with a low number of dependencies, that sufficiently exercises Opam.
    # Enable tracing in case something goes wrong.
    echo "Installing [graphics]"
    DKML_BUILD_TRACE=ON DKML_BUILD_TRACE_LEVEL=2 opam config report --debug-level 1 # level=1 shows 'LOAD-GLOBAL-STATE @ ...' which is the opam root
    DKML_BUILD_TRACE=ON DKML_BUILD_TRACE_LEVEL=2 opam install graphics --yes

    # regression test: https://discuss.ocaml.org/t/ann-diskuv-ocaml-1-x-x-windows-ocaml-installer-no-longer-in-preview/10309/8?u=jbeckford
    opam install ppx_jane --yes

    # regression test: https://github.com/diskuv/dkml-installer-ocaml/issues/12
    opam install pyml --yes

    # regression test: https://github.com/diskuv/dkml-installer-ocaml/issues/21
    opam install ocaml-lsp-server merlin --yes

    opam install ocamlformat --yes

    opam exec -- dune build --root "$sandbox/proj2"
    opam exec -- dune exec --root "$sandbox/proj2" ./best.exe    
fi
