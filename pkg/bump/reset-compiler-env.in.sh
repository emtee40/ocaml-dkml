#!/bin/sh

# Never use dkmlvars.sh from an old installation
export DiskuvOCamlForceDefaults=1

# Never let DkML environment variables creep in
unset DiskuvOCamlVarsVersion
unset DiskuvOCamlHome
unset DiskuvOCamlBinaryPaths
unset DiskuvOCamlDeploymentId
unset DiskuvOCamlVersion
unset DiskuvOCamlMSYS2Dir

# Use Visual Studio discovered by setup-dkml.
#   shellcheck disable=SC2194
case "@IS_VISUAL_STUDIO@" in
    ON)
        # shellcheck disable=SC1091
        . "@BINARY_DIR@/.ci/sd4/vsenv.sh"
        export DKML_COMPILE_SPEC="1"
        export DKML_COMPILE_TYPE="VS"
        export DKML_COMPILE_VS_DIR="$VS_DIR"
        export DKML_COMPILE_VS_VCVARSVER="$VS_VCVARSVER"
        export DKML_COMPILE_VS_WINSDKVER="$VS_WINSDKVER"
        export DKML_COMPILE_VS_MSVSPREFERENCE="$VS_MSVSPREFERENCE"
        export DKML_COMPILE_VS_CMAKEGENERATOR="$VS_CMAKEGENERATOR"
esac
