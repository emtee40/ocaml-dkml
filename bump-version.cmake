# Test with:
# cmake --log-context -D DRYRUN=1 -D CMAKE_MESSAGE_CONTEXT=dkml-workflows -D "regex_DKML_VERSION_SEMVER=2[.]1[.]1" -D "regex_DKML_VERSION_OPAMVER=2[.]1[.]1" -D DKML_VERSION_SEMVER_NEW=2.1.2 -D DKML_VERSION_OPAMVER_NEW=2.1.2 -D GIT_EXECUTABLE=git -D DKML_RELEASE_OCAML_VERSION=4.14.0 -D BOOTSTRAP_OPAM_VERSION=v2.2.0-alpha-20221228 -D OCAML_OPAM_REPOSITORY_GITREF=6c3f73f42890cc19f81eb1dec8023c2cd7b8b5cd -D DKML_BUMP_VERSION_PARTICIPANT_MODULE=../../pkg/bump/DkMLBumpVersionParticipant.cmake -P bump-version.cmake

if(NOT DKML_BUMP_VERSION_PARTICIPANT_MODULE)
    message(FATAL_ERROR "Missing -D DKML_BUMP_VERSION_PARTICIPANT_MODULE=.../DkMLBumpVersionParticipant.cmake")
endif()
include(${DKML_BUMP_VERSION_PARTICIPANT_MODULE})

DkMLBumpVersionParticipant_ModelReplace(src/logic/model.ml)
DkMLBumpVersionParticipant_DuneProjectReplace(dune-project)
DkMLReleaseParticipant_DuneBuildOpamFiles()
DkMLBumpVersionParticipant_GitAddAndCommit()
