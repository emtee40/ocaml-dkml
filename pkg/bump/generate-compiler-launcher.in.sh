#!/bin/sh
set -euf

OUTPUT_FILE='@WITH_COMPILER_SH@'
#   Allow environment to override CMake vars
DKML_BUILD_TRACE=${DKML_BUILD_TRACE:-@DKML_BUILD_TRACE@}
DKML_BUILD_TRACE_LEVEL=${DKML_BUILD_TRACE_LEVEL:-@DKML_BUILD_TRACE_LEVEL@}

#       shellcheck disable=SC1091
. '@dkml-runtime-common_SOURCE_DIR@/unix/crossplatform-functions.sh'

autodetect_compiler --post-transform '@dkml-compiler_SOURCE_DIR@/env/standard-compiler-env-to-ocaml-configure-env.sh' "${OUTPUT_FILE}"
if [ "${DKML_BUILD_TRACE:-}" = ON ] && [ "${DKML_BUILD_TRACE_LEVEL:-0}" -ge 2 ]; then
  echo "=== ${OUTPUT_FILE} ===" >&2
  cat "${OUTPUT_FILE}" >&2
  echo '=== (done) ===' >&2
fi
