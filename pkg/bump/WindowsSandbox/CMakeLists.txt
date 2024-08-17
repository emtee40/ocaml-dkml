include(${CMAKE_CURRENT_LIST_DIR}/../DkMLBumpLevels.cmake)

# install-vcruntime: For testing binaries like standalone msvc-compiled opam.exe without an installer.
#   The installers will auto-install the redistributable vcruntime so usually no need to do this.
# install-msys2: For testing binaries like opam.exe that need an MSYS2 environment.

# opam testing:
#   To mimic DkML, use:
#       .\install-vcruntime.cmd
#       .\install-msys2.cmd
#       .\install-winget.cmd
#       .\install-git.cmd
#       cd opam # Unpack the .zip from GitHub Actions
#       C:\msys64\msys2_shell.cmd -here -clang64
#   Then:
#       ./opam init --yes --no-setup --bare --disable-sandboxing '--git-location=/c/Program Files/Git/cmd' --cygwin-location=/c/msys64 default https://opam.ocaml.org
#       ./opam repository add default https://opam.ocaml.org --yes --dont-select --rank=3
#       ./opam option --yes --global download-command=wget


set(OPAMSWITCH ${PACKAGING_OPAMROOT}/dkml)
set(TOOLSDIR ${CMAKE_CURRENT_BINARY_DIR}/tools)
cmake_path(NATIVE_PATH OPAMSWITCH OPAMSWITCH_NATIVE)
cmake_path(NATIVE_PATH TOOLSDIR TOOLSDIR_NATIVE)
configure_file(config.in.wsb config.wsb @ONLY)
foreach(cmd IN ITEMS installer-byte installer-native uninstaller-byte uninstaller-native)
    configure_file(${cmd}.in.cmd ${TOOLSDIR}/${cmd}.cmd @ONLY NEWLINE_STYLE DOS)
endforeach()
file(COPY_FILE install-winget.ps1 ${TOOLSDIR}/install-winget.ps1 ONLY_IF_DIFFERENT)
file(COPY_FILE install-vcruntime.ps1 ${TOOLSDIR}/install-vcruntime.ps1 ONLY_IF_DIFFERENT)
foreach(cmd IN ITEMS install-winget install-git install-vsstudio install-native-prereqs install-vcruntime)
    configure_file(${cmd}.cmd ${TOOLSDIR}/${cmd}.cmd @ONLY NEWLINE_STYLE DOS)
endforeach()
configure_file("${PROJECT_SOURCE_DIR}/tests/postinstall-test.cmd" ${TOOLSDIR}/test.cmd @ONLY NEWLINE_STYLE DOS)
file(COPY
    "${PROJECT_SOURCE_DIR}/tests/proj1"
    "${PROJECT_SOURCE_DIR}/tests/proj2"
    "${PROJECT_SOURCE_DIR}/tests/script1"
    DESTINATION ${TOOLSDIR})

if(CMAKE_HOST_WIN32)
    add_custom_target(Package-WindowsSandbox
        COMMAND start config.wsb
        SOURCES ${CMAKE_CURRENT_BINARY_DIR}/config.wsb
    )

    add_custom_target(Package-WindowsDocker
        COMMAND
        start docker run -it
        -v "${OPAMSWITCH_NATIVE}:C:\\Switch"
        -v "${TOOLSDIR_NATIVE}:C:\\Tools"
        mcr.microsoft.com/windows/servercore:ltsc2022
        VERBATIM USES_TERMINAL)
endif()
