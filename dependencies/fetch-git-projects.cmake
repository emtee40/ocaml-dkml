# This script exists, isolated from the other declarations, to allow the
# DkML project to get the correct versions in its `git-clone.sh`.
#
# This script is patterned after dksdk-cmake's script of the same name.
#
# It can be run in two ways:
# 1. In script mode with -D FETCH_GIT_EXPORT_TYPE=shell -P. That will output (on the
# standard output) shell variables of the form GIT_TAG_<name>=<value>.
# The name will be sanitized as a C identifier with
# string(MAKE_C_IDENTIFIER) and then upper-cased. So dkml-compiler would be
# GIT_TAG_DKML_COMPILER.
# 2. Included in a CMakeLists.txt

include(FetchContent)

function(FetchGit)
    # Parsing
    set(prefix ARG)
    set(noValues)
    set(singleValues GIT_REPOSITORY GIT_TAG)
    set(multiValues)
    cmake_parse_arguments(
        PARSE_ARGV 1 # start after the <name>
        ${prefix}
        "${noValues}" "${singleValues}" "${multiValues}"
    )

    set(name ${ARGV0}) # the <name>

    if(CMAKE_SCRIPT_MODE_FILE)
        if(FETCH_GIT_EXPORT_TYPE STREQUAL shell)
            string(MAKE_C_IDENTIFIER "${name}" nameSanitized)
            string(TOUPPER "${nameSanitized}" nameSanitizedUpper)

            if(DEFINED ENV{GIT_TAG_${nameSanitizedUpper}})
                set(value "GIT_TAG_${nameSanitizedUpper}='$ENV{GIT_TAG_${nameSanitizedUpper}}'")
            else()
                set(value "GIT_TAG_${nameSanitizedUpper}='${ARG_GIT_TAG}'")
            endif()
            if(FETCH_GIT_EXPORT_FILE)
                file(APPEND "${FETCH_GIT_EXPORT_FILE}" "${value}\n")
            else()
                message(NOTICE "${value}")
            endif()
        else()
            message(FATAL_ERROR "-D FETCH_GIT_EXPORT_TYPE= is not defined or is not 'shell'")
        endif()
    else()
        if(${name}_GIT_TAG)
            set(gitTag ${${name}_GIT_TAG})
        else()
            set(gitTag ${ARG_GIT_TAG})
        endif()

        FetchContent_Declare(${name}
            GIT_REPOSITORY ${ARG_GIT_REPOSITORY}
            GIT_TAG ${gitTag}
        )
    endif()
endfunction()

if(CMAKE_SCRIPT_MODE_FILE)
    if(FETCH_GIT_EXPORT_FILE)
        file(WRITE "${FETCH_GIT_EXPORT_FILE}" "")
    endif()
endif()

# DkML subprojects that are not versioned with DkML releases
# --------

FetchGit(dkml-install-api
    GIT_REPOSITORY https://github.com/diskuv/dkml-install-api.git
    GIT_TAG 0.5
)
FetchGit(dkml-component-unixutils
    GIT_REPOSITORY https://github.com/diskuv/dkml-component-unixutils.git
    GIT_TAG 0.3.0
)
FetchGit(dkml-component-opam
    GIT_REPOSITORY https://github.com/diskuv/dkml-component-opam.git
    GIT_TAG 2.2.0 # opam 2.2.0
)
