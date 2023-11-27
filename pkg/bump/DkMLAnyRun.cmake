# [build] Finished setup.
# [build]
# [build] To continue your testing, run in PowerShell:
# [build]   $env:CHERE_INVOKING = "yes"
# [build]   $env:MSYSTEM = "CLANG64"
# [build]   $env:dkml_host_abi = "windows_x86_64"
# [build]   $env:abi_pattern = "win32-windows_x86_64"
# [build]   $env:opam_root = "Z:/source/dkml/build/packaging/bump/opamsw/.ci/o"
# [build]   $env:exe_ext = ".exe"

if(NOT DKML_HOST_ABI)
    if(CMAKE_HOST_WIN32)
        string(TOLOWER "${CMAKE_HOST_SYSTEM_PROCESSOR}" sysproc)
        if(sysproc STREQUAL x86)
            set(DKML_HOST_ABI windows_x86)
        elseif(sysproc STREQUAL arm64)
            set(DKML_HOST_ABI windows_arm64)
        else()
            set(DKML_HOST_ABI windows_x86_64)
        endif()
    elseif(CMAKE_HOST_APPLE)
        if(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL arm64)
            set(DKML_HOST_ABI darwin_arm64)
        else()
            set(DKML_HOST_ABI darwin_x86_64)
        endif()
    else()
        if(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL arm64)
            set(DKML_HOST_ABI linux_arm64)
        elseif(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL i686)
            set(DKML_HOST_ABI linux_x86)
        else()
            set(DKML_HOST_ABI linux_x86_64)
        endif()
    endif()
endif()

if(NOT DKML_TARGET_ABI)
    set(DKML_TARGET_ABI ${DKML_HOST_ABI})
endif()

set(anyrun_OPAMEXE ${CMAKE_CURRENT_BINARY_DIR}/.ci/sd4/bs/bin/opam${CMAKE_EXECUTABLE_SUFFIX})
set(anyrun_OPAMROOT ${CMAKE_CURRENT_BINARY_DIR}/.ci/o) # $OPAMROOT is also set indirectly in anyrun.sh by [cmdrun] or [opamrun]
if(SKIP_CMDRUN)
    set(anyrun_OUTPUTS)
else()
    set(anyrun_OUTPUTS
        ${anyrun_OPAMEXE}
        ${CMAKE_CURRENT_BINARY_DIR}/.ci/sd4/opamrun/cmdrun
        ${CMAKE_CURRENT_BINARY_DIR}/.ci/sd4/opamrun/opamrun)
endif()

set(MSYS2_BASH ${CMAKE_CURRENT_BINARY_DIR}/msys64/usr/bin/bash.exe)
set(MSYS2_BASH_RUN
    ${CMAKE_COMMAND} -E env CHERE_INVOKING=yes MSYSTEM=CLANG64 MSYS2_ARG_CONV_EXCL=*
    "${MSYS2_BASH}" -l)

if(CMAKE_HOST_WIN32)
    list(APPEND anyrun_OUTPUTS ${MSYS2_BASH})
endif()
