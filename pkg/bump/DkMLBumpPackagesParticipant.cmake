cmake_policy(SET CMP0053 NEW) # Simplify variable reference and escape sequence evaluation
include(${CMAKE_CURRENT_LIST_DIR}/DkMLReleaseParticipant.cmake)

if(NOT DKML_RELEASE_DUNE_VERSION)
    message(FATAL_ERROR "Missing -D DKML_RELEASE_DUNE_VERSION=xx")
endif()

if(NOT DKML_VERSION_OPAMVER_NEW)
    message(FATAL_ERROR "Missing -D DKML_VERSION_OPAMVER_NEW=xx")
endif()

if(NOT OPAM_EXECUTABLE)
    message(FATAL_ERROR "Missing -D OPAM_EXECUTABLE=xx")
endif()

if(NOT WITH_COMPILER_SH)
    message(FATAL_ERROR "Missing -D WITH_COMPILER_SH=xx")
endif()

if(NOT BASH_EXECUTABLE)
    message(FATAL_ERROR "Missing -D BASH_EXECUTABLE=xx")
endif()

if(NOT TEMP_DIR)
    message(FATAL_ERROR "Missing -D TEMP_DIR=xx")
endif()

# Sets a printer of a "pinned" opam section of [switch-state]. Similar to:
#
# echo '
# pinned: [
# "0install.2.17"
# "dkml-base-compiler.4.14.0~v1.2.1~prerel10"
# "dkml-compiler-env.1.2.1~prerel10"
# ]
# '
#
# The "dkml-installer-ocaml-network.2.0.0" (or whatever version) is always
# pinned to stop an expensive retrigger where [dkml-installer-ocaml-network] is
# being installed (hence [dkml-installer-ocaml-network] is not available to be
# listed in the pinned opam section) ... and then after
# [dkml-installer-ocaml-network] is installed it becomes available to be
# listed in the pinned open section.
# In other words, we want idempotency.
# Ditto for [dkml-installer-ocaml-offline].
function(DkMLBumpPackagesParticipant_CreateOpamSwitchUpgrade REL_FILENAME)
    file(READ ${REL_FILENAME} contents)
    set(contents_NEW "${contents}")

    # Get list of package versions.
    # Example:
    # variantslib.v0.15.0
    # with-dkml.1.2.1~prerel10
    execute_process(
        COMMAND ${OPAM_EXECUTABLE} list --columns=package --short
        OUTPUT_VARIABLE pkgvers
        OUTPUT_STRIP_TRAILING_WHITESPACE
        COMMAND_ERROR_IS_FATAL ANY
    )

    # Convert to list
    string(REGEX REPLACE "\n" ";" pkgvers "${pkgvers}")
    _DkMLReleaseParticipant_NormalizePinnedPackages(pkgvers)

    # Add [dkml-installer-ocaml-network]
    list(FILTER pkgvers EXCLUDE REGEX "^dkml-installer-ocaml-network[.]")
    list(APPEND pkgvers "dkml-installer-ocaml-network.${DKML_VERSION_OPAMVER_NEW}")

    # Add [dkml-installer-ocaml-offline]
    list(FILTER pkgvers EXCLUDE REGEX "^dkml-installer-ocaml-offline[.]")
    list(APPEND pkgvers "dkml-installer-ocaml-offline.${DKML_VERSION_OPAMVER_NEW}")

    # Remove [dune] and replace with [dune+shim]
    # @: DkML 2.1.0 no longer places Dune in the global environment, so no shim needed
    # list(FILTER pkgvers EXCLUDE REGEX "^dune[.]")
    # list(APPEND pkgvers "dune.${DKML_RELEASE_DUNE_VERSION}+shim")

    # Sort
    list(SORT pkgvers)

    # Convert to list of quoted strings.
    list(TRANSFORM pkgvers PREPEND "  \"")
    list(TRANSFORM pkgvers APPEND "\"")
    list(JOIN pkgvers "\n" pkgvers)

    # Make a shell script printer
    cmake_path(GET CMAKE_CURRENT_LIST_FILE FILENAME managerFile)
    string(REGEX REPLACE
        [[### BEGIN pinned-section.*### END pinned-section[. A-Za-z]*]]
        "### BEGIN pinned-section. DO NOT EDIT THE LINES IN THIS SECTION
# Managed by ${managerFile}
echo 'pinned: [
${pkgvers}
]
'
### END pinned-section. DO NOT EDIT THE LINES ABOVE"
        contents_NEW "${contents_NEW}")

    if(contents STREQUAL "${contents_NEW}")
        # idempotent
        return()
    endif()

    file(WRITE ${REL_FILENAME} "${contents_NEW}")

    message(NOTICE "Upgraded [pinned:] opam section in ${REL_FILENAME}")
    set_property(GLOBAL APPEND PROPERTY DkMLReleaseParticipant_REL_FILES ${REL_FILENAME})
endfunction()

# Sets a series of commands like:
# opamrun pin add --switch "$do_pins_NAME"  --yes --no-action -k version alcotest "${PIN_ALCOTEST}"
function(DkMLBumpPackagesParticipant_SetupDkmlUpgrade REL_FILENAME)
    file(READ ${REL_FILENAME} contents)
    set(contents_NEW "${contents}")

    # Get list of packages.
    # Example:
    # variantslib
    # with-dkml
    execute_process(
        COMMAND ${OPAM_EXECUTABLE} list --short
        OUTPUT_VARIABLE pkgs
        OUTPUT_STRIP_TRAILING_WHITESPACE
        COMMAND_ERROR_IS_FATAL ANY
    )

    # Convert to list
    string(REGEX REPLACE "\n" ";" pkgs "${pkgs}")
    _DkMLReleaseParticipant_NormalizePinnedPackages(pkgs)

    # Sort
    list(SORT pkgs)

    # ocp-indent -> ocp-indent "${PIN_OCP_INDENT}"
    set(pkgs2)

    foreach(pkg IN LISTS pkgs)
        string(TOUPPER "${pkg}" PKG_UPPER_SANITIZED)
        string(REPLACE "-" "_" PKG_UPPER_SANITIZED "${PKG_UPPER_SANITIZED}")
        list(APPEND pkgs2 "${pkg} \"\${PIN_${PKG_UPPER_SANITIZED}}\"")
    endforeach()

    set(pkgs ${pkgs2})

    # Convert to list of commands
    list(TRANSFORM pkgs PREPEND [[    opamrun pin add --switch "$do_pins_NAME"  --yes --no-action -k version ]])
    list(JOIN pkgs "\n" pkgs)

    # Set the command
    cmake_path(GET CMAKE_CURRENT_LIST_FILE FILENAME managerFile)
    string(REGEX REPLACE
        [[### BEGIN pin-adds.*### END pin-adds[. A-Za-z]*]]
        "### BEGIN pin-adds. DO NOT EDIT THE LINES IN THIS SECTION
    # Managed by ${managerFile}
${pkgs}
    ### END pin-adds. DO NOT EDIT THE LINES ABOVE"
        contents_NEW "${contents_NEW}")

    if(contents STREQUAL "${contents_NEW}")
        # idempotent
        return()
    endif()

    file(WRITE ${REL_FILENAME} "${contents_NEW}")

    message(NOTICE "Upgraded [pin add] commands in ${REL_FILENAME}")
    set_property(GLOBAL APPEND PROPERTY DkMLReleaseParticipant_REL_FILES ${REL_FILENAME})
endfunction()

# Sets a series of OCaml list elements like:
# ("PIN_ALCOTEST", "1.6.0");
# ("PIN_ALCOTEST_ASYNC", "1.6.0");
function(DkMLBumpPackagesParticipant_ModelUpgrade REL_FILENAME)
    file(READ ${REL_FILENAME} contents)
    set(contents_NEW "${contents}")

    # Get list of packages.
    # Example:
    # variantslib.1.2.3
    # with-dkml.4.5.6
    execute_process(
        COMMAND ${OPAM_EXECUTABLE} list --columns=package --short
        OUTPUT_VARIABLE pkgvers
        OUTPUT_STRIP_TRAILING_WHITESPACE
        COMMAND_ERROR_IS_FATAL ANY
    )

    # Convert to list
    string(REGEX REPLACE "\n" ";" pkgvers "${pkgvers}")
    _DkMLReleaseParticipant_NormalizePinnedPackages(pkgvers)

    # Sort
    list(SORT pkgvers)

    # ocp-indent.1.2.3 -> ("PIN_OCP_INDENT", "1.2.3");
    # conf-c++.1.0 -> ("PIN_CONF_CPLUSPLUS", "1.0");
    set(bindings)

    foreach(pkgver IN LISTS pkgvers)
        string(FIND "${pkgver}" "." dotLoc)
        string(SUBSTRING "${pkgver}" 0 ${dotLoc} pkg)
        math(EXPR dotLocPlus1 "${dotLoc} + 1")
        string(SUBSTRING "${pkgver}" ${dotLocPlus1} -1 ver)
        string(TOUPPER "${pkg}" PKG_UPPER_SANITIZED)
        string(REPLACE "-" "_" PKG_UPPER_SANITIZED "${PKG_UPPER_SANITIZED}")
        string(REPLACE "+" "PLUS" PKG_UPPER_SANITIZED "${PKG_UPPER_SANITIZED}")
        string(APPEND bindings "\n    (\"PIN_${PKG_UPPER_SANITIZED}\", \"${ver}\");")
    endforeach()

    # Set the command
    cmake_path(GET CMAKE_CURRENT_LIST_FILE FILENAME managerFile)
    string(REGEX REPLACE
        [[\(\* BEGIN pin-env-vars.*END pin-env-vars[^*]* \*\)]]
        "(* BEGIN pin-env-vars. DO NOT EDIT THE LINES IN THIS SECTION *)
    (* Managed by ${managerFile} *)${bindings}
    (* END pin-env-vars. DO NOT EDIT THE LINES ABOVE *)"
        contents_NEW "${contents_NEW}")

    if(contents STREQUAL "${contents_NEW}")
        # idempotent
        return()
    endif()

    file(WRITE ${REL_FILENAME} "${contents_NEW}")

    message(NOTICE "Upgraded pin environment bindings in ${REL_FILENAME}")
    set_property(GLOBAL APPEND PROPERTY DkMLReleaseParticipant_REL_FILES ${REL_FILENAME})
endfunction()

# Adds UNION(global-compile, global-install) to dune-project
function(DkMLBumpPackagesParticipant_DuneProjectFlavorUpgrade REL_FILENAME)
    file(READ ${REL_FILENAME} contents)
    set(contents_NEW "${contents}")

    # Replace: flavor-<FLAVOR> or dkml-apps-only
    foreach(FLAVOR IN ITEMS ci full dkml-apps-only)
        # Which flavor should we query?
        set(query_FLAVOR ${FLAVOR})
        if(FLAVOR STREQUAL dkml-apps-only)
            # dkml-apps is in the ci flavor
            set(query_FLAVOR ci)
        endif()

        # What section should we search and replace?
        set(replace_FLAVOR flavor-${FLAVOR})
        if(FLAVOR STREQUAL dkml-apps-only)
            set(replace_FLAVOR dkml-apps-only)
        endif()

        set(pkgvers)
        foreach(GLOBALTYPE IN ITEMS compile install)
            # Get list of [global-compile] package versions for the flavor
            # Example:
            # with-dkml.1.2.1~prerel10
            execute_process(
                COMMAND ${OPAM_EXECUTABLE} exec -- dkml-desktop-gen-globals ${GLOBALTYPE} ${query_FLAVOR} package-versions
                OUTPUT_VARIABLE i_pkgvers
                OUTPUT_STRIP_TRAILING_WHITESPACE
                COMMAND_ERROR_IS_FATAL ANY
            )
            string(REGEX REPLACE "\n" ";" i_pkgvers "${i_pkgvers}")
            list(APPEND pkgvers ${i_pkgvers})
        endforeach()

        # Convert to list
        _DkMLReleaseParticipant_NormalizePinnedPackages(pkgvers)

        # Remove [dune]; we have a special insertion for it later
        list(FILTER pkgvers EXCLUDE REGEX "^dune[.]")

        # Special case: dkml-apps-only
        if(FLAVOR STREQUAL dkml-apps-only)
            list(FILTER pkgvers INCLUDE REGEX "^dkml-apps[.]")
        endif()

        # Sort
        list(SORT pkgvers)

        # Convert to list of (PKGNAME (= PKGVER)) strings.
        # - [dune] needs to be [dune] or [dune+shim] depending on
        # [conf-withdkml:installed], but [conf-withdkml:installed] can't be
        # used in the [depends:] section
        list(TRANSFORM pkgvers REPLACE "([^.]*)[.](.*)" "  (\\1 (= \\2))")
        list(JOIN pkgvers "\n" pkgvers)
        # @: DkML 2.1.0 no longer places Dune in the global environment, so no shim needed.
        #string(PREPEND pkgvers "  (dune (or (= ${DKML_RELEASE_DUNE_VERSION}) (= ${DKML_RELEASE_DUNE_VERSION}+shim)))\n")
        string(PREPEND pkgvers "  (dune (= ${DKML_RELEASE_DUNE_VERSION}))\n")

        # Make a dune-project section
        cmake_path(GET CMAKE_CURRENT_LIST_FILE FILENAME managerFile)
        string(REGEX REPLACE
            "; BEGIN ${replace_FLAVOR}[.].*; END ${replace_FLAVOR}[. A-Za-z]*"
            "; BEGIN ${replace_FLAVOR}. DO NOT EDIT THE LINES IN THIS SECTION
  ; Managed by ${managerFile}
${pkgvers}
  ; END ${replace_FLAVOR}. DO NOT EDIT THE LINES ABOVE"
            contents_NEW "${contents_NEW}")
    endforeach()

    if(contents STREQUAL "${contents_NEW}")
        # idempotent
        return()
    endif()

    file(WRITE ${REL_FILENAME} "${contents_NEW}")

    message(NOTICE "Upgraded [flavor-*] packages in ${REL_FILENAME}")
    set_property(GLOBAL APPEND PROPERTY DkMLReleaseParticipant_REL_FILES ${REL_FILENAME})
endfunction()

function(DkMLBumpPackagesParticipant_DkmlFlavorOpamUpgrade)
    set(noValues)
    set(singleValues REL_FILENAME FLAVOR)
    set(multiValues EXCLUDE_PACKAGES)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    file(READ ${ARG_REL_FILENAME} contents)
    set(contents_NEW "${contents}")

    set(buildspec)
    set(installspec)

    foreach(GLOBALTYPE IN ITEMS compile install)
        # Get list of [global-install] packages for the flavor
        # Example:
        # with-dkml.1.2.1~prerel10
        execute_process(
            COMMAND ${OPAM_EXECUTABLE} exec -- dkml-desktop-gen-globals ${GLOBALTYPE} ${ARG_FLAVOR} packages
            OUTPUT_VARIABLE pkgs
            OUTPUT_STRIP_TRAILING_WHITESPACE
            COMMAND_ERROR_IS_FATAL ANY
        )

        # Convert to list
        string(REGEX REPLACE "\n" ";" pkgs "${pkgs}")
        _DkMLReleaseParticipant_NormalizePinnedPackages(pkgs)

        # Remove any exclusions
        if(ARG_EXCLUDE_PACKAGES)
            list(REMOVE_ITEM pkgs ${ARG_EXCLUDE_PACKAGES})
        endif()

        # Sort
        list(SORT pkgs)

        # Make a list of:
        #   [ "sh" "-c" "OPAMLOGS=$PWD opam show --readonly --list-files dkml-apps > opamshow-dkml-apps.txt" ]
        # 1. Set OPAMLOGS so doesn't try to write to opam's default log
        #    directory in the opamroot that is read-only in a sandbox
        # 2. Use --readonly to future-proof with unreleased versions of opam
        set(i_buildspec ${pkgs})

        # Want REPLACE ".*", but nasty cmake bug:
        # https://gitlab.kitware.com/cmake/cmake/-/issues/18884 https://gitlab.kitware.com/cmake/cmake/-/issues/16899
        list(TRANSFORM i_buildspec REPLACE "[A-Za-z0-9_-]+"
            [==[  [ "sh" "-c" "OPAMLOGS=$PWD '%{dkml-sys-opam-exe}%' show --readonly --list-files \0 > opamshow-\0.txt" ]]==])
        list(APPEND buildspec ${i_buildspec})

        # Make a list of:
        # [ "dkml-desktop-copy-installed" "--file-list" "opamshow-dkml-apps.txt" "--opam-switch-prefix" "%{prefix}%" "--output-dir" "%{_:share}%/staging-files/%{dkml-abi}%/compile" ]
        set(i_installspec ${pkgs})
        list(TRANSFORM i_installspec REPLACE "[A-Za-z0-9_-]+"
            [==[  [ "dkml-desktop-copy-installed" "--file-list" "opamshow-\0.txt" "--opam-switch-prefix" "%{prefix}%" "--output-dir" "%{_:share}%/staging-files/%{dkml-abi}%/I_DST" ]]==])
        list(TRANSFORM i_installspec REPLACE I_DST ${GLOBALTYPE})
        list(APPEND installspec ${i_installspec})
    endforeach()

    list(JOIN buildspec "\n" buildspec)
    list(JOIN installspec "\n" installspec)

    cmake_path(GET CMAKE_CURRENT_LIST_FILE FILENAME managerFile)

    # Replace build: section
    string(REGEX REPLACE
        "# BEGIN build-flavor-${ARG_FLAVOR}[.].*# END build-flavor-${ARG_FLAVOR}[. A-Za-z]*"
        "# BEGIN build-flavor-${ARG_FLAVOR}. DO NOT EDIT THE LINES IN THIS SECTION
  # Managed by ${managerFile}. TODO: Use [opam] from dkml-component-opam
${buildspec}
  # END build-flavor-${ARG_FLAVOR}. DO NOT EDIT THE LINES ABOVE"
        contents_NEW "${contents_NEW}")

    # Replace install: section
    string(REGEX REPLACE
        "# BEGIN install-flavor-${ARG_FLAVOR}[.].*# END install-flavor-${ARG_FLAVOR}[. A-Za-z]*"
        "# BEGIN install-flavor-${ARG_FLAVOR}. DO NOT EDIT THE LINES IN THIS SECTION
  # Managed by ${managerFile}
${installspec}
  # END install-flavor-${ARG_FLAVOR}. DO NOT EDIT THE LINES ABOVE"
        contents_NEW "${contents_NEW}")

    if(contents STREQUAL "${contents_NEW}")
        # idempotent
        return()
    endif()

    file(WRITE ${ARG_REL_FILENAME} "${contents_NEW}")

    message(NOTICE "Upgraded [build:] and [install:] sections in ${ARG_REL_FILENAME}")
    set_property(GLOBAL APPEND PROPERTY DkMLReleaseParticipant_REL_FILES ${ARG_REL_FILENAME})
endfunction()

# EMPTY_DUNE_INC <name1> <value1> <name2> <value2> ...
# where <name1> is one of REL_FILENAMES <name1> <name2> ...
function(DkMLBumpPackagesParticipant_DuneIncUpgrade)
    set(noValues)
    set(singleValues DUNE_TARGET)
    set(multiValues REL_FILENAMES EMPTY_DUNE_INC)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    # Read them for a "before" snapshot. We also need to capture the file
    # timestamps so we don't retrigger CMake if there is no content changed.
    foreach(REL_FILENAME IN LISTS ARG_REL_FILENAMES)
        file(READ ${REL_FILENAME} contents)
        string(REPLACE "\r" "" contents "${contents}") # Normalize CRLF
        string(MAKE_C_IDENTIFIER ${REL_FILENAME} fileId)
        set(contents_${fileId} "${contents}")

        # file(COPY) preserves timestamps
        cmake_path(GET REL_FILENAME PARENT_PATH REL_FILEDIR)
        file(COPY ${REL_FILENAME} DESTINATION ${TEMP_DIR}/${REL_FILEDIR})
    endforeach()

    # Truncate each dune.inc
    foreach(REL_FILENAME IN LISTS ARG_REL_FILENAMES)
        set(empty_dune_inc)
        if(ARG_EMPTY_DUNE_INC)
            list(LENGTH ARG_EMPTY_DUNE_INC num_empty_keyvals)
            math(EXPR num_empty_keyvals_minus1 "${num_empty_keyvals} - 1")
            foreach(key_idx RANGE 0 ${num_empty_keyvals_minus1} 2)
                list(GET ARG_EMPTY_DUNE_INC ${key_idx} key)
                if(key STREQUAL REL_FILENAME)
                    math(EXPR value_idx "1 + ${key_idx}")
                    list(GET ARG_EMPTY_DUNE_INC ${value_idx} empty_dune_inc)
                    break()
                endif()
            endforeach()
        endif()
        file(WRITE ${REL_FILENAME} "${empty_dune_inc}")
    endforeach()

    # Clean the dune build directory so the dune target can be
    # reproducible and especially so it is not affected by
    # a prior bump.
    file(REMOVE _build/.lock)
    execute_process(
        COMMAND ${BASH_EXECUTABLE} ${WITH_COMPILER_SH} ${OPAM_EXECUTABLE} exec -- dune clean
    )

    # Run the dune target ... the first time may fail because it has yet
    # to be promoted ... and so may the second (and third) ... but eventually
    # it should work. The number of times until success has been observed to
    # be the number of dune include files that has to be generated (+1).
    list(LENGTH ARG_REL_FILENAMES NUM_FILENAMES)
    foreach(fileno RANGE 1 ${NUM_FILENAMES})
        execute_process(
            COMMAND ${BASH_EXECUTABLE} ${WITH_COMPILER_SH} ${OPAM_EXECUTABLE} exec -- dune build ${ARG_DUNE_TARGET} --auto-promote
            ERROR_QUIET # Don't want long promote diffs printed
        )        
    endforeach()    
    execute_process(
        COMMAND ${BASH_EXECUTABLE} ${WITH_COMPILER_SH} ${OPAM_EXECUTABLE} exec -- dune build ${ARG_DUNE_TARGET} --auto-promote
        COMMAND_ERROR_IS_FATAL ANY
    )

    # Which content changed, if any?
    set(changedFiles)

    foreach(REL_FILENAME IN LISTS ARG_REL_FILENAMES)
        file(READ ${REL_FILENAME} contents)
        string(REPLACE "\r" "" contents "${contents}") # Normalize CRLF
        string(MAKE_C_IDENTIFIER ${REL_FILENAME} fileId)

        if(NOT(contents_${fileId} STREQUAL "${contents}"))
            list(APPEND changedFiles ${REL_FILENAME})
        endif()
    endforeach()

    # Check idempotent
    if(NOT changedFiles)
        # idempotent content! But file timestamps could have changed, so
        # restore the timestamps (by restoring the original files)
        foreach(REL_FILENAME IN LISTS ARG_REL_FILENAMES)
            cmake_path(GET REL_FILENAME PARENT_PATH REL_FILEDIR)
            file(COPY ${TEMP_DIR}/${REL_FILENAME} DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}/${REL_FILEDIR})
        endforeach()

        return()
    endif()

    list(JOIN changedFiles " " changedFiles_SPACES)
    message(NOTICE "Upgraded ${changedFiles_SPACES}")
    set_property(GLOBAL APPEND PROPERTY DkMLReleaseParticipant_REL_FILES ${changedFiles})
endfunction()

function(DkMLBumpPackagesParticipant_TestPromote)
    set(noValues)
    set(singleValues)
    set(multiValues REL_FILENAMES)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    # Read them for a "before" snapshot
    foreach(REL_FILENAME IN LISTS ARG_REL_FILENAMES)
        file(READ ${REL_FILENAME} contents)
        string(REPLACE "\r" "" contents "${contents}") # Normalize CRLF
        string(MAKE_C_IDENTIFIER ${REL_FILENAME} fileId)
        set(contents_${fileId} "${contents}")
    endforeach()

    # Run the dune runtest ... the first time may fail because it has yet
    # to be promoted ... but the second time should work
    execute_process(
        COMMAND ${BASH_EXECUTABLE} ${WITH_COMPILER_SH} ${OPAM_EXECUTABLE} exec -- dune runtest --auto-promote
        ERROR_QUIET # Don't want long promote diffs printed
    )
    execute_process(
        COMMAND ${BASH_EXECUTABLE} ${WITH_COMPILER_SH} ${OPAM_EXECUTABLE} exec -- dune runtest --auto-promote
        COMMAND_ERROR_IS_FATAL ANY
    )

    # Which content changed, if any?
    set(changedFiles)

    foreach(REL_FILENAME IN LISTS ARG_REL_FILENAMES)
        file(READ ${REL_FILENAME} contents)
        string(REPLACE "\r" "" contents "${contents}") # Normalize CRLF
        string(MAKE_C_IDENTIFIER ${REL_FILENAME} fileId)

        if(NOT(contents_${fileId} STREQUAL "${contents}"))
            list(APPEND changedFiles ${REL_FILENAME})
        endif()
    endforeach()

    # Check idempotent
    if(NOT changedFiles)
        # idempotent
        return()
    endif()

    list(JOIN changedFiles " " changedFiles_SPACES)
    message(NOTICE "Upgraded ${changedFiles_SPACES}")
    set_property(GLOBAL APPEND PROPERTY DkMLReleaseParticipant_REL_FILES ${changedFiles})
endfunction()

function(DkMLBumpPackagesParticipant_GitAddAndCommit)
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
        ${GIT_EXECUTABLE} commit -m "Bump package lists"
        ENCODING UTF-8q
        COMMAND_ERROR_IS_FATAL ANY
    )
endfunction()
