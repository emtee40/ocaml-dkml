include(${CMAKE_CURRENT_LIST_DIR}/DkMLReleaseParticipant.cmake)

if(NOT DKML_RELEASE_OCAML_VERSION)
    message(FATAL_ERROR "Missing -D DKML_RELEASE_OCAML_VERSION=xx")
endif()

if(NOT regex_DKML_VERSION_OPAMVER)
    message(FATAL_ERROR "Missing -D regex_DKML_VERSION_OPAMVER=xx")
endif()

if(NOT regex_DKML_VERSION_SEMVER)
    message(FATAL_ERROR "Missing -D regex_DKML_VERSION_SEMVER=xx")
endif()

if(NOT DKML_VERSION_OPAMVER_NEW)
    message(FATAL_ERROR "Missing -D DKML_VERSION_OPAMVER_NEW=xx")
endif()

if(NOT DKML_VERSION_SEMVER_NEW)
    message(FATAL_ERROR "Missing -D DKML_VERSION_SEMVER_NEW=xx")
endif()

if(NOT OCAML_OPAM_REPOSITORY_GITREF)
    message(FATAL_ERROR "Missing -D OCAML_OPAM_REPOSITORY_GITREF=...")
endif()

if(NOT BOOTSTRAP_OPAM_VERSION)
    message(FATAL_ERROR "Missing -D BOOTSTRAP_OPAM_VERSION=...")
endif()

macro(_DkMLBumpVersionParticipant_Finish_Replace VERSION_TYPE)
    if(contents STREQUAL "${contents_NEW}")
        string(FIND "${contents_NEW}" "${DKML_VERSION_${VERSION_TYPE}_NEW}" idempotent)

        if(idempotent LESS 0)
            cmake_path(ABSOLUTE_PATH REL_FILENAME OUTPUT_VARIABLE FILENAME_ABS)
            message(FATAL_ERROR "The old version(s) ${regex_DKML_VERSION_${VERSION_TYPE}} were not found in ${FILENAME_ABS} or the file already had the new version ${DKML_VERSION_${VERSION_TYPE}_NEW} derived from the DKML_VERSION_CMAKEVER value in version.cmake")
        endif()

        # idempotent
        return()
    endif()

    file(WRITE ${REL_FILENAME} "${contents_NEW}")

    message(NOTICE "Bumped ${REL_FILENAME} to ${DKML_VERSION_${VERSION_TYPE}_NEW}")
    set_property(GLOBAL APPEND PROPERTY DkMLReleaseParticipant_REL_FILES ${REL_FILENAME})
endmacro()

macro(_DkMLBumpVersionParticipant_Finish_ReplaceDirect WHAT)
    if(contents STREQUAL "${contents_NEW}")
        # idempotent
        return()
    endif()

    file(WRITE ${REL_FILENAME} "${contents_NEW}")

    message(NOTICE "Bumped ${REL_FILENAME} to ${WHAT}")
    set_property(GLOBAL APPEND PROPERTY DkMLReleaseParticipant_REL_FILES ${REL_FILENAME})
endmacro()

# 1.2.1-2 -> 1.2.1-3
function(DkMLBumpVersionParticipant_PlainReplace REL_FILENAME)
    file(READ ${REL_FILENAME} contents)
    string(REGEX REPLACE
        "${regex_DKML_VERSION_SEMVER}"
        "${DKML_VERSION_SEMVER_NEW}"
        contents_NEW "${contents}")

    _DkMLBumpVersionParticipant_Finish_Replace(SEMVER)
endfunction()

function(DkMLBumpVersionParticipant_OCamlOpamRepositoryReplace REL_FILENAME)
    file(READ ${REL_FILENAME} contents)
    set(contents_NEW "${OCAML_OPAM_REPOSITORY_GITREF}")

    _DkMLBumpVersionParticipant_Finish_ReplaceDirect(${OCAML_OPAM_REPOSITORY_GITREF})
endfunction()

# version: "1.2.1~prerel2" -> version: "1.2.1~prerel3"
function(DkMLBumpVersionParticipant_OpamReplace REL_FILENAME)
    file(READ ${REL_FILENAME} contents)
    set(contents_NEW "${contents}")

    string(REGEX REPLACE # Match at beginning of line: ^|\n
        "(^|\n)version: \"${regex_DKML_VERSION_OPAMVER}\""
        "\\1version: \"${DKML_VERSION_OPAMVER_NEW}\""
        contents_NEW "${contents_NEW}")
    _DkMLBumpVersionParticipant_Finish_Replace(OPAMVER)
endfunction()

# ReleaseDate: 2022-12-28 -> ReleaseDate: 2023-07-01
function(DkMLBumpVersionParticipant_ReleaseDateReplace REL_FILENAME)
    file(READ ${REL_FILENAME} contents)
    set(contents_NEW "${contents}")

    string(TIMESTAMP now_YYYYMMDD "%Y-%m-%d" UTC)
    string(REGEX REPLACE # Match at beginning of line: ^|\n
        "(^|\n)ReleaseDate: [0-9-]+"
        "\\1ReleaseDate: ${now_YYYYMMDD}"
        contents_NEW "${contents_NEW}")
    _DkMLBumpVersionParticipant_Finish_ReplaceDirect(${now_YYYYMMDD})
endfunction()

# Copyright: Copyright 2022 Diskuv, Inc. -> Copyright: Copyright 2023 Diskuv, Inc.
function(DkMLBumpVersionParticipant_CopyrightReplace REL_FILENAME)
    file(READ ${REL_FILENAME} contents)
    set(contents_NEW "${contents}")

    string(TIMESTAMP now_YYYY "%Y" UTC)
    string(REGEX REPLACE 
        "Copyright 2[0-9][0-9][0-9] Diskuv"
        "Copyright ${now_YYYY} Diskuv"
        contents_NEW "${contents_NEW}")
    _DkMLBumpVersionParticipant_Finish_ReplaceDirect(${now_YYYY})
endfunction()

# (version 1.2.1~prerel2) -> (version 1.2.1~prerel3)
function(DkMLBumpVersionParticipant_DuneProjectReplace REL_FILENAME)
    file(READ ${REL_FILENAME} contents)
    set(contents_NEW "${contents}")

    string(REGEX REPLACE # Match at beginning of line: ^|\n
        "(^|\n)[(]version ${regex_DKML_VERSION_OPAMVER}[)]"
        "\\1(version ${DKML_VERSION_OPAMVER_NEW})"
        contents_NEW "${contents_NEW}")
    _DkMLBumpVersionParticipant_Finish_Replace(OPAMVER)
endfunction()

# (version 4.14.0~v1.2.1~prerel2) -> (version 4.14.0~v1.2.1~prerel3)
function(DkMLBumpVersionParticipant_DuneProjectWithCompilerVersionReplace REL_FILENAME)
    file(READ ${REL_FILENAME} contents)
    set(contents_NEW "${contents}")

    string(REGEX REPLACE # Match at beginning of line: ^|\n
        "(^|\n)[(]version ([0-9.]*)[~]v${regex_DKML_VERSION_OPAMVER}[)]"
        "\\1(version ${DKML_RELEASE_OCAML_VERSION}~v${DKML_VERSION_OPAMVER_NEW})"
        contents_NEW "${contents_NEW}")

    _DkMLBumpVersionParticipant_Finish_Replace(OPAMVER)
endfunction()

# dkml-apps,1.2.1~prerel2 -> dkml-apps,1.2.1~prerel3
# dkml-exe,1.2.1~prerel2 -> dkml-exe,1.2.1~prerel3
# with-dkml,1.2.1~prerel2 -> with-dkml,1.2.1~prerel3
function(_DkMLBumpVersionParticipant_HelperApps REL_FILENAME SEPARATOR)
    file(READ ${REL_FILENAME} contents)
    set(contents_NEW "${contents}")

    set(regex_SEPARATOR "${SEPARATOR}")
    string(REPLACE "." "[.]" regex_SEPARATOR "${regex_SEPARATOR}")
    string(REPLACE "~" "[~]" regex_SEPARATOR "${regex_SEPARATOR}")

    foreach(pkg IN ITEMS dkml-apps dkml-exe with-dkml)
        string(REGEX REPLACE # Match at beginning of line: ^|\n
            "(^|\n)([ ]*)${pkg}${regex_SEPARATOR}${regex_DKML_VERSION_OPAMVER}"
            "\\1\\2${pkg}${SEPARATOR}${DKML_VERSION_OPAMVER_NEW}"
            contents_NEW "${contents_NEW}")
    endforeach()

    _DkMLBumpVersionParticipant_Finish_Replace(OPAMVER)
endfunction()

# dkml-apps.1.2.1~prerel2 -> dkml-apps.1.2.1~prerel3
# dkml-exe.1.2.1~prerel2 -> dkml-exe.1.2.1~prerel3
# with-dkml.1.2.1~prerel2 -> with-dkml.1.2.1~prerel3
function(DkMLBumpVersionParticipant_PkgsReplace REL_FILENAME)
    _DkMLBumpVersionParticipant_HelperApps(${REL_FILENAME} ".")
endfunction()

# OCAML_DEFAULT_VERSION=4.14.0 -> OCAML_DEFAULT_VERSION=4.14.2
function(DkMLBumpVersionParticipant_CreateOpamSwitchReplace REL_FILENAME)
    file(READ ${REL_FILENAME} contents)
    set(contents_NEW "${contents}")

    string(REGEX REPLACE # Match at beginning of line: ^|\n
        "(^|\n)OCAML_DEFAULT_VERSION=[0-9.]+"
        "\\1OCAML_DEFAULT_VERSION=${DKML_RELEASE_OCAML_VERSION}"
        contents_NEW "${contents_NEW}")

    if(contents STREQUAL "${contents_NEW}")
        # idempotent
        return()
    endif()

    file(WRITE ${REL_FILENAME} "${contents_NEW}")

    message(NOTICE "Bumped ${REL_FILENAME} to ${DKML_RELEASE_OCAML_VERSION}")
    set_property(GLOBAL APPEND PROPERTY DkMLReleaseParticipant_REL_FILES ${REL_FILENAME})
endfunction()

# version = "1.2.1~prerel2" -> version = "1.2.1~prerel3"
function(DkMLBumpVersionParticipant_MetaReplace REL_FILENAME)
    file(READ ${REL_FILENAME} contents)
    set(contents_NEW "${contents}")

    string(REGEX REPLACE # Match at beginning of line: ^|\n
        "(^|\n)version *= *\"${regex_DKML_VERSION_OPAMVER}\""
        "\\1version = \"${DKML_VERSION_OPAMVER_NEW}\""
        contents_NEW "${contents_NEW}")

    _DkMLBumpVersionParticipant_Finish_Replace(OPAMVER)
endfunction()

# version: "4.14.0~v1.2.1~prerel2" -> version: "4.14.0~v1.2.1~prerel3"
# "dkml-runtime-common" {= "1.0.1"} -> "dkml-runtime-common" {= "1.0.2"}
# "dkml-runtime-common" {>= "1.0.1"} -> "dkml-runtime-common" {= "1.0.2"}
function(DkMLBumpVersionParticipant_DkmlBaseCompilerReplace REL_FILENAME)
    file(READ ${REL_FILENAME} contents)
    set(contents_NEW "${contents}")

    string(REGEX REPLACE # Match at beginning of line: ^|\n
        "(^|\n)version: \"([0-9.]*)[~]v${regex_DKML_VERSION_OPAMVER}\""
        "\\1version: \"${DKML_RELEASE_OCAML_VERSION}~v${DKML_VERSION_OPAMVER_NEW}\""
        contents_NEW "${contents_NEW}")

    string(REGEX REPLACE
        "(^|\n[ ]*)\"dkml-runtime-common\" {>?= \"${regex_DKML_VERSION_OPAMVER}\"}"
        "\\1\"dkml-runtime-common\" {= \"${DKML_VERSION_OPAMVER_NEW}\"}"
        contents_NEW "${contents_NEW}")

    _DkMLBumpVersionParticipant_Finish_Replace(OPAMVER)
endfunction()

# 4.14.0 -> 4.14.2
function(DkMLBumpVersionParticipant_OCamlVersionReplace REL_FILENAME)
    file(READ ${REL_FILENAME} contents)
    set(contents_NEW "${contents}")

    string(REGEX REPLACE # Match at beginning of line: ^|\n
        "(^|\n)[0-9]+[.][0-9]+[.][0-9]+$"
        "\\1${DKML_RELEASE_OCAML_VERSION}"
        contents_NEW "${contents_NEW}")

    _DkMLBumpVersionParticipant_Finish_ReplaceDirect(${DKML_RELEASE_OCAML_VERSION})
endfunction()

# ("DKML_VERSION", "1.1.0-prerel15"); -> ("DKML_VERSION", "1.2.1-3")
# ("DEFAULT_DKML_COMPILER", "1.1.0-prerel15"); -> ("DEFAULT_DKML_COMPILER", "1.2.1-3");
# ("DEFAULT_DISKUV_OPAM_REPOSITORY_TAG", "6c3f73f42890cc19f81eb1dec8023c2cd7b8b5cd"); -> ("DEFAULT_DISKUV_OPAM_REPOSITORY_TAG", "6c3f73f42890cc19f81eb1dec8023c2cd7b8b5cd")
# ("DEFAULT_DISKUV_OPAM_REPOSITORY_TAG", "1.1.0-prerel15"); -> ("DEFAULT_DISKUV_OPAM_REPOSITORY_TAG", "1.2.1-3")
# ("BOOTSTRAP_OPAM_VERSION", "..."); -> ("BOOTSTRAP_OPAM_VERSION", "2.2.0-alpha-20221228")
#
# dkml-compiler project has two types of opam files:
# 1. dkml-base-compiler X.Y.Z~vM.N.O
# 2. dkml-compiler-env (etc) M.N.O
#
# So the project is tagged M.N.O.
function(DkMLBumpVersionParticipant_ModelReplace REL_FILENAME)
    file(READ ${REL_FILENAME} contents)
    set(contents_NEW "${contents}")

    string(REGEX REPLACE
        "\"DKML_VERSION\", \"${regex_DKML_VERSION_SEMVER}\""
        "\"DKML_VERSION\", \"${DKML_VERSION_SEMVER_NEW}\""
        contents_NEW "${contents_NEW}")
    string(REGEX REPLACE
        "\"DEFAULT_DKML_COMPILER\", \"${regex_DKML_VERSION_SEMVER}\""
        "\"DEFAULT_DKML_COMPILER\", \"${DKML_VERSION_SEMVER_NEW}\""
        contents_NEW "${contents_NEW}")
    string(REGEX REPLACE
        "\"DEFAULT_OCAML_OPAM_REPOSITORY_TAG\", \"[0-9a-f]*\""
        "\"DEFAULT_OCAML_OPAM_REPOSITORY_TAG\", \"${OCAML_OPAM_REPOSITORY_GITREF}\""
        contents_NEW "${contents_NEW}")
    string(REGEX REPLACE
        "\"DEFAULT_DISKUV_OPAM_REPOSITORY_TAG\", \"${regex_DKML_VERSION_SEMVER}\""
        "\"DEFAULT_DISKUV_OPAM_REPOSITORY_TAG\", \"${DKML_VERSION_SEMVER_NEW}\""
        contents_NEW "${contents_NEW}")
    string(REGEX REPLACE
        "\"BOOTSTRAP_OPAM_VERSION\", \"[^\\\"]*\""
        "\"BOOTSTRAP_OPAM_VERSION\", \"${BOOTSTRAP_OPAM_VERSION}\""
        contents_NEW "${contents_NEW}")

    _DkMLBumpVersionParticipant_Finish_Replace(SEMVER)
endfunction()

function(DkMLBumpVersionParticipant_GitAddAndCommit)
    if(DRYRUN)
        return()
    endif()

    get_property(relFiles GLOBAL PROPERTY DkMLReleaseParticipant_REL_FILES)

    if(NOT relFiles)
        return()
    endif()
    list(REMOVE_DUPLICATES relFiles)

    execute_process(
        COMMAND
        ${GIT_EXECUTABLE} -c core.safecrlf=false add ${relFiles}
        COMMAND_ERROR_IS_FATAL ANY
    )
    execute_process(
        COMMAND
        ${GIT_EXECUTABLE} commit -m "Version: ${DKML_VERSION_SEMVER_NEW}"
        ENCODING UTF-8
        COMMAND_ERROR_IS_FATAL ANY
    )
endfunction()
