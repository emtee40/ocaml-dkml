#!/bin/sh
set -euf

# Reset environment so no conflicts with a parent Opam or OCaml system
unset OPAMROOT
unset OPAM_SWITCH_PREFIX
unset OPAMSWITCH
unset CAML_LD_LIBRARY_PATH
unset OCAMLLIB
unset OCAML_TOPLEVEL_PATH

# For MSYS2 on Windows, stop path conversion from \ to / which messes up
# docker (which is a native Windows command).
export MSYS2_ARG_CONV_EXCL='*'

export PC_PROJECT_DIR="$PWD"
export FDOPEN_OPAMEXE_BOOTSTRAP=false
export CACHE_PREFIX=v1
export OCAML_COMPILER=
export DKML_COMPILER=
export SKIP_OPAM_MODIFICATIONS=false
export PRIMARY_SWITCH_SKIP_INSTALL=false
export SECONDARY_SWITCH=false
export CONF_DKML_CROSS_TOOLCHAIN=@repository@
export DISKUV_OPAM_REPOSITORY=
export DKML_HOME=
# autogen from global_env_vars.{% for var in global_env_vars %}{{ nl }}export {{ var.name }}='{{ var.value }}'{% endfor %}

# Set matrix variables
# autogen from pc_vars. only linux_x86{{ nl }}{% for (name,value) in pc_vars.linux_x86 %}export {{ name }}="{{ value }}"{{ nl }}{% endfor %}

usage() {
  echo 'Setup DkML compiler on a desktop PC.' >&2
  echo 'usage: setup-dkml-linux_x86.sh [options]' >&2
  echo 'Options:' >&2

  # Context variables
  echo "  --PC_PROJECT_DIR=<value>. Defaults to the current directory (${PC_PROJECT_DIR})" >&2

  # Input variables
  echo "  --FDOPEN_OPAMEXE_BOOTSTRAP=true|false. Defaults to: ${FDOPEN_OPAMEXE_BOOTSTRAP}" >&2
  echo "  --CACHE_PREFIX=<value>. Defaults to: ${CACHE_PREFIX}" >&2
  echo "  --OCAML_COMPILER=<value>. --DKML_COMPILER takes priority. If --DKML_COMPILER is not set and --OCAML_COMPILER is set, then the specified OCaml version tag of dkml-compiler (ex. 4.12.1) is used. Defaults to: ${OCAML_COMPILER}" >&2
  echo "  --DKML_COMPILER=<value>. Unspecified or blank is the latest from the default branch (main) of dkml-compiler. Defaults to: ${DKML_COMPILER}" >&2
  echo "  --SKIP_OPAM_MODIFICATIONS=true|false. If true then the opam root and switches will not be created or modified. Defaults to: ${SKIP_OPAM_MODIFICATIONS}" >&2
  echo "  --SECONDARY_SWITCH=true|false. If true then the secondary switch named 'two' is created. Defaults to: ${SECONDARY_SWITCH}" >&2
  echo "  --PRIMARY_SWITCH_SKIP_INSTALL=true|false. If true no dkml-base-compiler will be installed in the 'dkml' switch. Defaults to: ${PRIMARY_SWITCH_SKIP_INSTALL}" >&2
  echo "  --CONF_DKML_CROSS_TOOLCHAIN=<value>. Unspecified or blank is the latest from the default branch (main) of conf-dkml-cross-toolchain. @repository@ is the latest from Opam. Defaults to: ${CONF_DKML_CROSS_TOOLCHAIN}" >&2
  echo "  --OCAML_OPAM_REPOSITORY=<value>. Defaults to the value of --DEFAULT_OCAML_OPAM_REPOSITORY_TAG (see below)" >&2
  echo "  --DISKUV_OPAM_REPOSITORY=<value>. Defaults to the value of --DEFAULT_DISKUV_OPAM_REPOSITORY_TAG (see below)" >&2
  echo "  --DKML_HOME=<value>. then DiskuvOCamlHome, DiskuvOCamlBinaryPaths and DiskuvOCamlDeploymentId will be set, in addition to the always-present DiskuvOCamlVarsVersion and DiskuvOCamlVersion." >&2
  echo "  --in_docker=true|false. When true, opamrun and cmdrun will launch commands inside a Docker container. Defaults to '${in_docker:-}'" >&2
  echo "  --dockcross_image=<value>. When --in_docker=true, will be Docker container image. Defaults to '${dockcross_image:-}'" >&2
  echo "  --dockcross_run_extra_args=<value>. When --in_docker=true, will be extra arguments passed to 'docker run'. Defaults to '${dockcross_run_extra_args:-}'" >&2

  # autogen from global_env_vars.{% for var in global_env_vars %}{{ nl }}  echo "  --{{ var.name }}=<value>. Defaults to: $\{{{ var.name }}}" >&2{% endfor %}
  exit 2
}
fail() {
  echo "Error: $*" >&2
  exit 3
}
unset file

OPTIND=1
while getopts :h-: option; do
  case $option in
  h) usage ;;
  -) case $OPTARG in
    PC_PROJECT_DIR) fail "Option \"$OPTARG\" missing argument" ;;
    PC_PROJECT_DIR=*) PC_PROJECT_DIR=${OPTARG#*=} ;;
    CACHE_PREFIX) fail "Option \"$OPTARG\" missing argument" ;;
    CACHE_PREFIX=*) CACHE_PREFIX=${OPTARG#*=} ;;
    FDOPEN_OPAMEXE_BOOTSTRAP) fail "Option \"$OPTARG\" missing argument" ;;
    FDOPEN_OPAMEXE_BOOTSTRAP=*) FDOPEN_OPAMEXE_BOOTSTRAP=${OPTARG#*=} ;;
    OCAML_COMPILER) fail "Option \"$OPTARG\" missing argument" ;;
    OCAML_COMPILER=*) OCAML_COMPILER=${OPTARG#*=} ;;
    DKML_COMPILER) fail "Option \"$OPTARG\" missing argument" ;;
    DKML_COMPILER=*) DKML_COMPILER=${OPTARG#*=} ;;
    SKIP_OPAM_MODIFICATIONS) fail "Option \"$OPTARG\" missing argument" ;;
    SKIP_OPAM_MODIFICATIONS=*) SKIP_OPAM_MODIFICATIONS=${OPTARG#*=} ;;
    SECONDARY_SWITCH) fail "Option \"$OPTARG\" missing argument" ;;
    SECONDARY_SWITCH=*) SECONDARY_SWITCH=${OPTARG#*=} ;;
    PRIMARY_SWITCH_SKIP_INSTALL) fail "Option \"$OPTARG\" missing argument" ;;
    PRIMARY_SWITCH_SKIP_INSTALL=*) PRIMARY_SWITCH_SKIP_INSTALL=${OPTARG#*=} ;;
    CONF_DKML_CROSS_TOOLCHAIN) fail "Option \"$OPTARG\" missing argument" ;;
    CONF_DKML_CROSS_TOOLCHAIN=*) CONF_DKML_CROSS_TOOLCHAIN=${OPTARG#*=} ;;
    DISKUV_OPAM_REPOSITORY) fail "Option \"$OPTARG\" missing argument" ;;
    DISKUV_OPAM_REPOSITORY=*) DISKUV_OPAM_REPOSITORY=${OPTARG#*=} ;;
    DKML_HOME) fail "Option \"$OPTARG\" missing argument" ;;
    DKML_HOME=*) DKML_HOME=${OPTARG#*=} ;;
    dockcross_image) fail "Option \"$OPTARG\" missing argument" ;;
    dockcross_image=*) dockcross_image=${OPTARG#*=} ;;
    dockcross_run_extra_args) fail "Option \"$OPTARG\" missing argument" ;;
    dockcross_run_extra_args=*) dockcross_run_extra_args=${OPTARG#*=} ;;
    in_docker) fail "Option \"$OPTARG\" missing argument" ;;
    in_docker=*) in_docker=${OPTARG#*=} ;;
    # autogen from global_env_vars.{% for var in global_env_vars %}{{ nl }}    {{ var.name }}) fail "Option \"$OPTARG\" missing argument" ;;{{ nl }}    {{ var.name }}=*) {{ var.name }}=${OPTARG#*=} ;;{% endfor %}
    help) usage ;;
    help=*) fail "Option \"${OPTARG%%=*}\" has unexpected argument" ;;
    *) fail "Unknown long option \"${OPTARG%%=*}\"" ;;
    esac ;;
  '?') fail "Unknown short option \"$OPTARG\"" ;;
  :) fail "Short option \"$OPTARG\" missing argument" ;;
  *) fail "Bad state in getopts (OPTARG=\"$OPTARG\")" ;;
  esac
done
shift $((OPTIND - 1))

########################### before_script ###############################

echo "Writing scripts ..."
install -d .ci/sd4

cat > .ci/sd4/common-values.sh <<'end_of_script'
{{ pc_common_values_script }}
end_of_script

cat > .ci/sd4/run-checkout-code.sh <<'end_of_script'
{{ pc_checkout_code_script }}
end_of_script

cat > .ci/sd4/run-setup-dkml.sh <<'end_of_script'
{{ pc_setup_dkml_script }}
end_of_script

sh .ci/sd4/run-checkout-code.sh PC_PROJECT_DIR "${PC_PROJECT_DIR}"
sh .ci/sd4/run-setup-dkml.sh PC_PROJECT_DIR "${PC_PROJECT_DIR}"

# shellcheck disable=SC2154
echo "
Finished setup.

To continue your testing, run:
  export dkml_host_abi='${dkml_host_abi}'
  export abi_pattern='${abi_pattern}'
  export opam_root='${opam_root}'
  export exe_ext='${exe_ext:-}'

Now you can use 'opamrun' to do opam commands like:

  PATH=\"$PWD/.ci/sd4/opamrun:\$PATH\" opamrun install XYZ.opam
  PATH=\"$PWD/.ci/sd4/opamrun:\$PATH\" opamrun -it exec -- bash
  sh ci/build-test.sh
"