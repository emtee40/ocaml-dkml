# The OPAMROOT and OPAMSWITCH variables must be set to the switch to copy from, and
# the 'opam' executable must be in the PATH.
#
# Test on Win32 with:
# cmake --log-context -D DRYRUN=1 -D CMAKE_MESSAGE_CONTEXT=dkml-workflows -D GIT_EXECUTABLE=git -D OPAM_EXECUTABLE=../../../build/pkg/bump/.ci/sd4/bs/bin/opam.exe -D WITH_COMPILER_SH=../../../build/pkg/bump/with-compiler.sh -D "BASH_EXECUTABLE=cmake;-E;env;CHERE_INVOKING=yes;MSYSTEM=CLANG64;MSYS2_ARG_CONV_EXCL=*;../../../build/pkg/bump/msys64/usr/bin/bash.exe;-l" -D DKML_RELEASE_DUNE_VERSION=3.15.0 -D DKML_BUMP_PACKAGES_PARTICIPANT_MODULE=../../../pkg/bump/DkMLBumpPackagesParticipant.cmake -P bump-packages.cmake
# and Unix with:
# cmake --log-context -D DRYRUN=1 -D CMAKE_MESSAGE_CONTEXT=dkml-workflows -D GIT_EXECUTABLE=git -D OPAM_EXECUTABLE=../../../build/pkg/bump/.ci/sd4/bs/bin/opam -D WITH_COMPILER_SH=../../../build/pkg/bump/with-compiler.sh -D BASH_EXECUTABLE=bash -D DKML_RELEASE_DUNE_VERSION=3.15.0 -D DKML_BUMP_PACKAGES_PARTICIPANT_MODULE=../../../pkg/bump/DkMLBumpPackagesParticipant.cmake -D DKML_VERSION_OPAMVER_NEW=2.1.1 -D TEMP_DIR=/tmp/dkml-workflows-tmp -P bump-packages.cmake

cmake_policy(SET CMP0011 NEW) # Included scripts do automatic cmake_policy PUSH and POP

if(NOT DKML_BUMP_PACKAGES_PARTICIPANT_MODULE)
    message(FATAL_ERROR "Missing -D DKML_BUMP_PACKAGES_PARTICIPANT_MODULE=.../DkMLBumpPackagesParticipant.cmake")
endif()

include(${DKML_BUMP_PACKAGES_PARTICIPANT_MODULE})

DkMLBumpPackagesParticipant_SetupDkmlUpgrade(src/scripts/setup-dkml.sh)
DkMLBumpPackagesParticipant_ModelUpgrade(src/logic/model.ml)
DkMLBumpPackagesParticipant_TestPromote(REL_FILENAMES
    test/gh-darwin/post/action.yml
    test/gh-darwin/pre/action.yml
    test/gh-linux/post/action.yml
    test/gh-linux/pre/action.yml
    test/gh-windows/post/action.yml
    test/gh-windows/pre/action.yml
    test/gl/setup-dkml.gitlab-ci.yml
    test/pc/setup-dkml-darwin_x86_64.sh
    test/pc/setup-dkml-darwin_arm64.sh
    test/pc/setup-dkml-linux_x86.sh
    test/pc/setup-dkml-linux_x86_64.sh
    test/pc/setup-dkml-windows_x86.ps1
    test/pc/setup-dkml-windows_x86_64.ps1)
DkMLBumpPackagesParticipant_GitAddAndCommit()
