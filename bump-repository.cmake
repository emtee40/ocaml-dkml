# Test with:
# cmake --log-context -D DRYRUN=1 -D CMAKE_MESSAGE_CONTEXT=diskuv-opam-repository -D BUMP_BINARY_DIR=../../../build/pkg/bump -D DKML_SOURCE_ARCHIVE_DIR=../../../build/pkg/bump/archives -D DKML_RELEASE_OCAML_VERSION=4.14.0 -D DKML_VERSION_SEMVER_NEW=1.2.1-3 -D DKML_VERSION_OPAMVER_NEW=1.2.1~prerel3 -D GIT_EXECUTABLE=git -D DKML_BUMP_REPOSITORY_PARTICIPANT_MODULE=../../../pkg/bump/DkMLBumpRepositoryParticipant.cmake -P bump-repository.cmake

cmake_policy(SET CMP0011 NEW) # Included scripts do automatic cmake_policy PUSH and POP

if(NOT DKML_BUMP_REPOSITORY_PARTICIPANT_MODULE)
    message(FATAL_ERROR "Missing -D DKML_BUMP_REPOSITORY_PARTICIPANT_MODULE=.../DkMLBumpRepositoryParticipant.cmake")
endif()

include(${DKML_BUMP_REPOSITORY_PARTICIPANT_MODULE})

DkMLBumpRepositoryParticipant_AddPackageVersions()
DkMLBumpRepositoryParticipant_GitAddAndCommit()
