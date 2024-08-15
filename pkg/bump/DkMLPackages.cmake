include_guard()

set(ARCHIVEDIR ${CMAKE_CURRENT_BINARY_DIR}/archives)

# These packages do not have a META file, or not consistently for all package versions
set(PACKAGES_WITHOUT_META
    conf-dkml-sys-opam
    conf-withdkml
    ocaml
    ocamlfind
)

# These projects are managed through [git subtree] into vendor/ directory
# Transition steps: 
# 1. Move *_BRANCH from pkg/bump/CMakeLists.txt
# 2. Move *_URL from dependencies/fetch-git-projects.cmake
# 3. Remove from dependencies/CMakeLists.txt
# 4. Add to DKML_SUBTREE_PROJECTS in this file
set(dkml-compiler_BRANCH main)
set(dkml-compiler_URL https://github.com/diskuv/dkml-compiler.git)
set(dkml-component-ocamlcompiler_BRANCH main)
set(dkml-component-ocamlcompiler_URL https://github.com/diskuv/dkml-component-ocamlcompiler.git)
set(dkml-runtime-common_BRANCH main)
set(dkml-runtime-common_URL https://github.com/diskuv/dkml-runtime-common.git)
set(dkml-runtime-distribution_BRANCH main)
set(dkml-runtime-distribution_URL https://github.com/diskuv/dkml-runtime-distribution.git)

set(dkml-workflows_BRANCH v1)
set(dkml-workflows_URL https://github.com/diskuv/dkml-workflows-prerelease.git)

set(DKML_SUBTREE_PROJECTS
    dkml-compiler
    dkml-component-ocamlcompiler
    dkml-runtime-common
    dkml-runtime-distribution
    dkml-workflows)

set(DKML_PROJECTS_PREDUNE

    # These are the projects that are required to a) create a switch
    # with b) just an OCaml compiler. See note in [syncedProjects] about
    # [diskuv-opam-repository].
    dkml-compiler
    dkml-runtime-common
    dkml-runtime-distribution # contains create-opam-switch.sh
)
set(DKML_PROJECTS_POSTDUNE

    # These are projects that need [dune build *.opam] to bump their
    # versions.

    # Part of a CI or Full distribution -pkgs.txt
    dkml-runtime-apps

    # Install utility projects.
    # They are bumped therefore they should be built (they are built as part
    # of the Api target). Regardless, they are transitive dependencies
    # of many DkML projects.
    dkml-workflows

    # Install API Components
    dkml-component-desktop
    dkml-component-ocamlcompiler
    dkml-component-ocamlrun
    dkml-installer-ocaml
    dkml-installer-ocaml-byte
)
set(DKML_PROJECTS_FINAL

    # Technically [diskuv-opam-repository] belongs in [DKML_PROJECTS_PREDUNE],
    # however the repository must be updated after all the other
    # projects are updated (or else it can't get their checksums).
    # AFAIK this should not affect anything ... this pkg/bump/CMakeLists.txt
    # script uses pinning for all projects, so it is irrelevant if
    # [diskuv-opam-repository] is stale all the way until the end
    # of VersionBump.
    diskuv-opam-repository
)

set(DKML_PROJECTS_SYNCED
    ${DKML_PROJECTS_PREDUNE}
    ${DKML_PROJECTS_POSTDUNE}
    ${DKML_PROJECTS_FINAL}
)
set(DKML_PROJECTS_UNSYNCED
    # Not even bump-version.cmake is present for version synchronization, but
    # the latest code for these DkML projects is still built into the opam
    # switches and used by the installers.
    dkml-install-api
    dkml-component-curl
    dkml-component-opam
    dkml-component-unixutils
)

# Synchronized projects with their one or more opam packages
set(dkml-compiler_PACKAGES
    dkml-base-compiler
    dkml-compiler-env

    # dkml-compiler-maintain
    dkml-compiler-src)
set(dkml-runtime-apps_PACKAGES
    dkml-apps
    dkml-exe
    dkml-exe-lib
    dkml-runtimelib
    dkml-runtimescripts
    opam-dkml
    with-dkml)
set(dkml-runtime-common_PACKAGES
    dkml-runtime-common
    dkml-runtime-common-native)
set(dkml-runtime-distribution_PACKAGES dkml-runtime-distribution)
set(dkml-runtime_PACKAGES
    ${dkml-runtime-common_PACKAGES}
    ${dkml-runtime-distribution_PACKAGES})

set(dkml-workflows_PACKAGES dkml-workflows)

set(dkml-component-desktop_PACKAGES
    dkml-build-desktop
    dkml-component-common-desktop

    # dkml-component-desktop-maintain
    dkml-component-offline-desktop-ci
    dkml-component-offline-desktop-full
    dkml-component-staging-desktop-ci
    dkml-component-staging-desktop-full
    dkml-component-staging-dkmlconfdir
    dkml-component-staging-withdkml)
set(dkml-component-ocamlcompiler_PACKAGES
    dkml-component-ocamlcompiler-common
    dkml-component-ocamlcompiler-offline
    dkml-component-ocamlcompiler-network)
set(dkml-component-ocamlrun_PACKAGES
    dkml-component-offline-ocamlrun
    dkml-component-staging-ocamlrun)
set(dkml-installer-ocaml_PACKAGES
    dkml-installer-ocaml-common
    dkml-installer-ocaml-network)
set(dkml-installer-ocaml-byte_PACKAGES
    dkml-installer-ocaml-offline)

set(dkml-component_PACKAGES
    ${dkml-component-desktop_PACKAGES}
    ${dkml-component-ocamlcompiler_PACKAGES}
    ${dkml-component-ocamlrun_PACKAGES}
    ${dkml-component-ocaml_PACKAGES})
set(dkml-installer_PACKAGES
    ${dkml-installer-ocaml_PACKAGES}
    ${dkml-installer-ocaml-byte_PACKAGES})

# These are packages that have opam version numbers like 4.14.0~v1.2.1~prerel10
set(DKML_COMPILER_DKML_VERSIONED_PACKAGES
    dkml-base-compiler
    ${dkml-component-ocamlcompiler_PACKAGES}
    ${dkml-component-ocamlrun_PACKAGES})
# These are packages that have opam version numbers like 4.14.0
set(DKML_COMPILER_VERSIONED_PACKAGES
    conf-dkml-cross-toolchain)

# Sanity check
foreach(PROJECT IN LISTS DKML_PROJECTS_PREDUNE DKML_PROJECTS_POSTDUNE)
    if(NOT ${PROJECT}_PACKAGES)
        message(FATAL_ERROR "Missing set(${PROJECT}_PACKAGES ...) statement in ${CMAKE_CURRENT_LIST_FILE}")
    endif()
endforeach()

# Dune has multiple packages that varies depending on the Dune version
function(get_dune_PACKAGES)
    set(noValues)
    set(singleValues DUNE_VERSION OUTPUT_VARIABLE)
    set(multiValues)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "${noValues}" "${singleValues}" "${multiValues}")

    set(${ARG_OUTPUT_VARIABLE}
        chrome-trace
        dune
        dune-action-plugin
        dune-build-info
        dune-configurator
        dune-glob
        dune-private-libs
        dune-rpc
        dune-rpc-lwt
        dune-site
        dyn
        ocamlc-loc
        ordering
        stdune
        xdg
        PARENT_SCOPE)
endfunction()