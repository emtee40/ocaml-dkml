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
