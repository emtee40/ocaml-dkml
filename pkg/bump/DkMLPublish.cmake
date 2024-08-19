include(${CMAKE_CURRENT_LIST_DIR}/DkMLPackages.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/DkMLAnyRun.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/DkMLBumpLevels.cmake)

# Aka. https://gitlab.com/dkml/distributions/dkml
set(GITLAB_UPLOAD_BASE_URL https://gitlab.com/api/v4/projects/dkml%2Fdistributions%2Fdkml)
set(PACKAGE_REGISTRY_URL_BASE "${GITLAB_UPLOAD_BASE_URL}/packages/generic/release")
set(PUBLISHDIR ${CMAKE_CURRENT_BINARY_DIR}/${DKML_VERSION_CMAKEVER}/publish)

set(glab_HINTS)

if(IS_DIRECTORY Z:/ProgramFiles/glab)
    list(APPEND glab_HINTS Z:/ProgramFiles/glab)
endif()

if(DKML_GOLDEN_SOURCE_CODE)
    set(find_program_OPTS)
else()
    set(find_program_OPTS REQUIRED)
endif()
find_program(GLAB_EXECUTABLE glab ${find_program_OPTS} HINTS ${glab_HINTS})

function(DkMLPublish_ChangeLog)
    set(noValues)
    set(singleValues OUTPUT_VARIABLE)
    set(multiValues)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    # There is no prerelease change.md, so use patch change.md
    set(changes_MD ${PROJECT_SOURCE_DIR}/contributors/changes/v${DKML_VERSION_MAJOR}.${DKML_VERSION_MINOR}.${DKML_VERSION_PATCH}.md)

    if(NOT EXISTS ${changes_MD})
        message(FATAL_ERROR "Missing changelog at ${changes_MD}")
    endif()

    set(${ARG_OUTPUT_VARIABLE} ${changes_MD} PARENT_SCOPE)
endfunction()

function(DkMLPublish_AddArchiveTarget)
    set(noValues)
    set(singleValues TARGET)
    set(multiValues PROJECTS)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    file(MAKE_DIRECTORY ${ARCHIVEDIR})

    # We use a stable timestamp so the tarball is somewhat reproducible
    # (at least on the same machine). We want to minimize SHA checksums
    # changing.
    #
    # configure_file() does not change the mtime if the expanded
    # contents (ARG_PROJECTS) don't change
    set(SORTED_PROJECTS ${ARG_PROJECTS})
    list(SORT SORTED_PROJECTS)
    configure_file(archive.in.mtime ${ARCHIVEDIR}/archive-${ARG_TARGET}.mtime @ONLY)
    file(TIMESTAMP ${ARCHIVEDIR}/archive-${ARG_TARGET}.mtime mtime_YYYYMMDD "%Y-%m-%d" UTC)

    set(outputs)
    set(checked_dirty_PROJECT_SOURCE_DIR OFF)
    foreach(pkg IN ITEMS ${ARG_PROJECTS})
        FetchContent_GetProperties(${pkg})
        set(git_ls_tree ${CMAKE_CURRENT_BINARY_DIR}/git-ls-tree/${pkg}.txt)
        set(git_ls_tree_ARGS)
        set(check_dirty OFF)
        if(pkg IN_LIST DKML_SUBTREE_PROJECTS)
            # vendor/<pkg>
            set(git_WORKDIR "${PROJECT_SOURCE_DIR}")
            list(APPEND git_ls_tree_ARGS vendor/${pkg})
            # only check PROJECT_SOURCE_DIR working tree for dirty files once
            # (for optimization, and to avoid git bailing with concurrent `git update-index`)
            if(NOT checked_dirty_PROJECT_SOURCE_DIR)
                set(check_dirty ON)
                set(checked_dirty_PROJECT_SOURCE_DIR ON)
            endif()
        else()
            # Isolated checkout.
            set(git_WORKDIR "${${pkg}_SOURCE_DIR}")
        endif()
        execute_process(
            WORKING_DIRECTORY "${git_WORKDIR}"
            COMMAND ${GIT_EXECUTABLE} ls-tree -r HEAD --name-only ${git_ls_tree_ARGS}
            OUTPUT_VARIABLE files
            OUTPUT_STRIP_TRAILING_WHITESPACE
            COMMAND_ERROR_IS_FATAL ANY
        )
        file(WRITE ${git_ls_tree} "${files}")
        string(REPLACE "\n" ";" absfiles "${files}")
        list(TRANSFORM absfiles PREPEND "${git_WORKDIR}/")

        if(pkg IN_LIST DKML_SUBTREE_PROJECTS)
            # vendor/<pkg>/x/y/z -> x/y/z
            file(STRINGS "${git_ls_tree}" git_ls_tree_CONTENTS)
            list(TRANSFORM git_ls_tree_CONTENTS REPLACE "^vendor/${pkg}/" "" OUTPUT_VARIABLE git_ls_tree_REROOT)
            set(git_ls_tree_ACTUAL "${CMAKE_CURRENT_BINARY_DIR}/git-ls-tree/${pkg}.reroot.txt")
            list(JOIN git_ls_tree_REROOT "\n" git_ls_tree_REROOT)
            file(WRITE "${git_ls_tree_ACTUAL}" "${git_ls_tree_REROOT}")
        else()
            # Isolated checkout. No transformation.
            set(git_ls_tree_ACTUAL "${git_ls_tree}")
        endif()

        set(tar_PRECMD)
        if(check_dirty)
            list(APPEND tar_PRECMD
                # Verify no dirty tracked files in working tree. The
                # source archive must correspond exactly to a clean git checkout.
                # https://unix.stackexchange.com/a/394674
                COMMAND
                ${GIT_EXECUTABLE} update-index --really-refresh
                COMMAND
                ${GIT_EXECUTABLE} diff-index --quiet HEAD)
        endif()

        set(output ${ARCHIVEDIR}/src.${pkg}.tar.gz)
        add_custom_command(
            # Always make the source archive relative to the root of the project,
            # regardless if it is a subtree project
            WORKING_DIRECTORY "${${pkg}_SOURCE_DIR}"
            OUTPUT ${output}
            DEPENDS ${absfiles}

            ${tar_PRECMD}

            # Create tarball
            COMMAND
            ${CMAKE_COMMAND} -E tar cfz
            ${output}
            --format=gnutar

            # --mtime format is not documented. Use https://gitlab.kitware.com/cmake/cmake/-/blob/master/Tests/RunCMake/CommandLineTar/mtime-tests.cmake
            --mtime=${mtime_YYYYMMDD}UTC
            --files-from=${git_ls_tree_ACTUAL}
        )
        list(APPEND outputs ${output})
    endforeach()

    add_custom_target(${ARG_TARGET}
        DEPENDS ${outputs}
    )
endfunction()

function(DkMLPublish_CreateReleaseTarget)
    set(noValues)
    set(singleValues TARGET)
    set(multiValues)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    # Get ChangeLog entry
    set(changes_MD_NEW_FILENAME ${PUBLISHDIR}/change.md)
    DkMLPublish_ChangeLog(OUTPUT_VARIABLE changes_MD)
    file(READ ${changes_MD} changes_CONTENT)
    string(TIMESTAMP now_YYYYMMDD "%Y-%m-%d")
    string(REPLACE "@@YYYYMMDD@@" "${now_YYYYMMDD}" changes_CONTENT "${changes_CONTENT}")
    file(WRITE ${changes_MD_NEW_FILENAME} ${changes_CONTENT})

    string(SUBSTRING "${now_YYYYMMDD}" 0 4 now_YYYYMMDD_LEFT4)
    string(SUBSTRING "${now_YYYYMMDD}" 4 6 now_YYYYMMDD_REMAINDER)
    math(EXPR next_YYYY "${now_YYYYMMDD_LEFT4} + 1")
    set(nextyear_YYYYMMDD "${next_YYYY}${now_YYYYMMDD_REMAINDER}")

    add_custom_target(${ARG_TARGET}
        DEPENDS ${changes_MD_NEW_FILENAME}
        COMMAND
        ${GLAB_EXECUTABLE} auth status

        # https://gitlab.com/gitlab-org/cli/-/blob/main/docs/source/release/create.md
        COMMAND
        ${GLAB_EXECUTABLE} release create ${DKML_VERSION_SEMVER}
        --name "DkML ${DKML_VERSION_SEMVER}"
        --ref "${DKML_VERSION_SEMVER}"
        --notes-file ${changes_MD_NEW_FILENAME}
        #   A date in the future so GitLab Releases page says "Upcoming Release" (it is untested right now!)
        --released-at "${nextyear_YYYYMMDD}T00:00:00Z"

        # There seems to be an eventual consistency issue with GitLab as of 2023-09. If
        # we create the release above, and then the next second upload the Generic Package
        # for that version, no Generic Package will be uploaded.
        COMMAND
        ${CMAKE_COMMAND} -E sleep 30

        VERBATIM USES_TERMINAL
    )
endfunction()

function(DkMLPublish_PublishAssetsTarget)
    set(noValues)
    set(singleValues TARGET ARCHIVE_TARGET)
    set(multiValues)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    # NOTICE
    # ------
    #
    # By using a stable "file path" in the [uploads] list, we can make
    # a stable permalink. So do NOT change the file paths unless it is
    # absolutely necessary (perhaps only for security invalidation).
    # Confer:
    # https://docs.gitlab.com/ee/user/project/releases/release_fields.html#permanent-links-to-latest-release-assets
    set(precommands)
    set(postcommands)
    set(uploads) # Files at most 100MB
    set(assetlinks) # References to 5GB Generic Packages
    set(depends)

    if(DKML_INSTALL_OCAML_NETWORK)
        set(tnetwork ${anyrun_OPAMROOT}/dkml/share/dkml-installer-ocaml-network/t)
    endif()
    if(DKML_INSTALL_OCAML_OFFLINE)
        set(toffline ${anyrun_OPAMROOT}/dkml/share/dkml-installer-ocaml-offline/t)
    endif()

    # Procedure
    # ---------
    # 1. Upload to Generic Package Registry because it can support 5GB uploads.
    # https://docs.gitlab.com/ee/user/gitlab_com/index.html#account-and-limit-settings
    # 2. Create a release pointing to Generic Package (rather than a normal release
    # attachment which only supports 100MB)
    # Only do that somewhat convoluted step for big installers ... the source
    # archives can be "normal" release attachments.

    macro(_handle_upload LINKTYPE SRCFILE DESTFILE NAME)
        # LINKTYPE: https://docs.gitlab.com/ee/user/project/releases/release_fields.html#link-types
        set(UPLOAD_SRCFILE "${SRCFILE}")
        set(UPLOAD_VERSION "${DKML_VERSION_SEMVER}")
        set(UPLOAD_DESTFILE "${DESTFILE}")
        configure_file(upload.in.cmake ${PUBLISHDIR}/upload-${DESTFILE}.cmake
            FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
            @ONLY)
        list(APPEND depends ${UPLOAD_SRCFILE})
        list(APPEND assetlinks "{\"name\": \"${NAME}\", \"url\":\"${PACKAGE_REGISTRY_URL_BASE}/${UPLOAD_VERSION}/${UPLOAD_DESTFILE}\", \"filepath\": \"/${DESTFILE}\", \"link_type\": \"${LINKTYPE}\"}")
        list(APPEND precommands
            COMMAND ${CMAKE_COMMAND} -P ${PUBLISHDIR}/upload-${DESTFILE}.cmake)
    endmacro()

    # TODO: When Windows test.gitlab-ci.yml job works, move this into the [release_job].
    if(DKML_TARGET_ABI STREQUAL windows_x86 OR DKML_TARGET_ABI STREQUAL windows_x86_64)
        # The reverse order of insertion shows up on GitLab UI. Want installer to display
        # first, so _handle_upload(<installer>) last.
        if(DKML_INSTALL_OCAML_NETWORK)
            _handle_upload(package
                ${tnetwork}/unsigned-dkml-native-${DKML_TARGET_ABI}-u-${DKML_VERSION_SEMVER}.exe
                uninstall64nu.exe
                "Windows/Intel 64-bit Native Uninstaller")
            _handle_upload(package
                ${tnetwork}/unsigned-dkml-native-${DKML_TARGET_ABI}-i-${DKML_VERSION_SEMVER}.exe
                setup64nu.exe
                "Windows/Intel 64-bit Native Installer")
        endif()
        if(DKML_INSTALL_OCAML_OFFLINE)
            _handle_upload(package
                ${toffline}/unsigned-dkml-byte-${DKML_TARGET_ABI}-u-${DKML_VERSION_SEMVER}.exe
                uninstall64bu.exe
                "Windows/Intel 64-bit Bytecode Uninstaller")
            _handle_upload(package
                ${toffline}/unsigned-dkml-byte-${DKML_TARGET_ABI}-i-${DKML_VERSION_SEMVER}.exe
                setup64bu.exe
                "Windows/Intel 64-bit Bytecode Installer")
        endif()
    endif()

    # TODO: Hack. This mimics test.gitlab-ci.yml [release_job] which we expect to fail because the GitLab Release
    # is created below. Alternatively, this might fail but [release_job] succeeds.
    # But test.gitlab-ci.yml [upload] should work, so these following links should be populated.
    if(DKML_INSTALL_OCAML_NETWORK)
        list(APPEND assetlinks "{\"name\": \"macOS/Silicon 64-bit Installer\", \"url\":\"${PACKAGE_REGISTRY_URL_BASE}/${DKML_VERSION_SEMVER}/dkml-native-darwin_arm64-i-${DKML_VERSION_SEMVER}.tar.gz\", \"filepath\": \"/dkml-native-darwin_arm64-i-${DKML_VERSION_SEMVER}.tar.gz\", \"link_type\": \"package\"}")
        list(APPEND assetlinks "{\"name\": \"DebianOldOld/Intel 64-bit Installer\", \"url\":\"${PACKAGE_REGISTRY_URL_BASE}/${DKML_VERSION_SEMVER}/dkml-native-linux_x86_64-i-${DKML_VERSION_SEMVER}.tar.gz\", \"filepath\": \"/dkml-native-linux_x86_64-i-${DKML_VERSION_SEMVER}.tar.gz\", \"link_type\": \"package\"}")
    endif()

    if(assetlinks)
        list(JOIN assetlinks "," assetlinks_csv)

        list(APPEND postcommands
            COMMAND
            ${GLAB_EXECUTABLE} release upload ${DKML_VERSION_SEMVER}
            --assets-links=[${assetlinks_csv}]
        )
    endif()

    # https://gitlab.com/gitlab-org/cli/-/blob/main/docs/source/release/upload.md
    foreach(PROJECT IN LISTS DKML_PROJECTS_PREDUNE DKML_PROJECTS_POSTDUNE)
        list(APPEND uploads "src.${PROJECT}.tar.gz#${PROJECT} Source Code")
        list(APPEND depends ${ARCHIVEDIR}/src.${PROJECT}.tar.gz)
    endforeach()

    add_custom_target(${ARG_TARGET}
        WORKING_DIRECTORY ${ARCHIVEDIR}
        DEPENDS ${depends}

        ${precommands}

        COMMAND
        ${GLAB_EXECUTABLE} release upload ${DKML_VERSION_SEMVER}
        ${uploads}

        ${postcommands}

        VERBATIM USES_TERMINAL
    )
    add_dependencies(${ARG_TARGET} ${ARG_ARCHIVE_TARGET})
endfunction()
