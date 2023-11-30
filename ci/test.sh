#!/bin/sh
set -euf

arch=$1
shift

ver=$(.ci/cmake/bin/cmake -P cmake/get-version.cmake)

# Unpack installer
install -d installer
if [ -e "dkml-native-$arch-i-$ver.tar.gz" ]; then
    tar xCfz installer "dkml-native-$arch-i-$ver.tar.gz" --strip-components 1
else
    tar xCf installer "dkml-native-$arch-i-$ver.tar" --strip-components 1
fi

# Run installer which on Unix just copies and edits the findlib + topfind packages with final install paths.
# Unlike Windows does not add to PATH ... that is your job.
CAML_LD_LIBRARY_PATH=$PWD/installer/sg/staging-ocamlrun/$arch/lib/ocaml/stublibs "installer/sg/staging-ocamlrun/$arch/bin/ocamlrun" installer/bin/dkml-package.bc -vv && rm -rf installer

# Temporary: This should have been done by the Unix installer just like the Windows installer.
#install -d "${XDG_DATA_HOME:-$HOME/.local/share}/dkml" && printf '(("DiskuvOCamlHome" ("%s/Applications/DkMLNative")))' "$HOME" | tee "${XDG_DATA_HOME:-$HOME/.local/share}/dkml/dkmlvars-v2.sexp"

# Optional since done automatically with the first ocaml/ocamlc/dune/utop/... but test it explicitly.
# And --disable-sandboxing is needed on macOS/Linux because the installation path of DkMLNative
# is not known apriori (it can be customized by the user).
export OCAMLRUNPARAM=b
# if [ "${SKIP_SYSTEM_INIT:-0}" = 0 ]; then
#     if [ "$(uname -s)" = Darwin ]; then
#         # bug: dkml-install-api/package/console/common/dkml_package_console_common.ml[i] says
#         # to place in Applications/DkMLNative.app/ in the .mli but does not do that in the .ml.
#         ~/Applications/DkMLNative/bin/dkml init --system --disable-sandboxing
#     else
#         ~/.local/share/dkml-native/bin/dkml init --system --disable-sandboxing
#     fi
# fi

# Do the post-install tests
exec sh tests/postinstall-test.sh
