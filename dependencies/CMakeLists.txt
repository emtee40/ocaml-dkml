include(${CMAKE_CURRENT_LIST_DIR}/fetch-git-projects.cmake)

FetchContent_MakeAvailable(
    dkml-component-opam
    dkml-component-unixutils
    dkml-install-api
)
