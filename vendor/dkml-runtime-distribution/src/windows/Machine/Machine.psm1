[CmdletBinding()]
param ()

Import-Module DeploymentHash # for Get-Sha256Hex16OfText

# -----------------------------------
# Magic constants

# Magic constants that will identify new and existing deployments:
# * Microsoft build numbers
# * Semver numbers

$Windows10SdkCompatibleTriples = @(
    # Highest priority to lowest priority.
    # KEEP IN SYNC with WindowsAdministrator.rst and dkml-installer-ocaml/installer/winget/manifest/Diskuv.OCaml.installer.yaml

    #   Since we have the longest experience with 18362, we make that highest priority.
    #   Original:
    #   * OCaml 4.12.0 on Windows 32-bit requires Windows SDK 10.0.18362.0 (MSVC bug). Let's be consistent and use it for 64-bit as well.
    "10.0.18362",

    #   GitLab CI switched to 19041 with https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/gcp/windows-containers/-/commit/5f94426f12d082c2226da29ab7b79f0b90ec7725
    "10.0.19041"
)
$Windows10SdkCompatibleVers = $Windows10SdkCompatibleTriples | ForEach-Object {
    # 10.0.18362 -> 18362
    $_.Split(".")[2]
}
$Windows10SdkCompatibleComponents = $Windows10SdkCompatibleVers | ForEach-Object {
    # Ex. Microsoft.VisualStudio.Component.Windows10SDK.19041
    "Microsoft.VisualStudio.Component.Windows10SDK.${_}"
}
if ($null -eq $Windows10SdkCompatibleComponents) { $Windows10SdkCompatibleComponents = @() }

$Windows11SdkCompatibleTriples = @(
    # Highest priority to lowest priority.
    # KEEP IN SYNC with WindowsAdministrator.rst and dkml-installer-ocaml/installer/winget/manifest/Diskuv.OCaml.installer.yaml

    #   GitLab CI saas-windows-medium-amd64.
    #   Win11SDK_10.0.22621
    "10.0.22621.0"
)
$Windows11SdkCompatibleVers = $Windows11SdkCompatibleTriples | ForEach-Object {
    "$($_.Split(".")[0]).$($_.Split(".")[1]).$($_.Split(".")[2])"
}
$Windows11SdkCompatibleComponents = $Windows11SdkCompatibleVers | ForEach-Object {
    # Ex. Win11SDK_10.0.22621
    "Win11SDK_${_}"
}
if ($null -eq $Windows11SdkCompatibleComponents) { $Windows11SdkCompatibleComponents = @() }

# Visual Studio minimum version
# Why MSBuild / Visual Studio 2015+? Because [vcpkg](https://vcpkg.io/en/getting-started.html) needs
#   Visual Studio 2015 Update 3 or newer as of July 2021.
# 14.0.25431.01 == Visual Studio 2015 Update 3 (newest patch; older is 14.0.25420.10)
$VsVerMin = "14.0.25420.10"       # KEEP IN SYNC with WindowsAdministrator.rst and r-c-opam-(1-setup|2-build).sh's OPT_MSVS_PREFERENCE
$VsDescribeVerMin = "Visual Studio 2015 Update 3 or later"

$VsSetupVer = "2.2.14-87a8a69eef"

# Version Years
# -------------
#
# We install VS 2019 although it may be better for a compatibility matrix to do VS 2015 as well.
#
# If you need an older vs_buildtools.exe installer, see either:
# * https://docs.microsoft.com/en-us/visualstudio/releases/2019/history#release-dates-and-build-numbers
# * https://github.com/jberezanski/ChocolateyPackages/commits/master/visualstudio2017buildtools/tools/ChocolateyInstall.ps1
#
# However VS 2017 + VS 2019 Build Tools can install even the 2015 compiler component;
# confer https://devblogs.microsoft.com/cppblog/announcing-visual-c-build-tools-2015-standalone-c-tools-for-build-environments/.
#
# Below the installer is
#   >> VS 2019 Build Tools 16.11.2 <<
$VsBuildToolsMajorVer = "16" # Either 16 for Visual Studio 2019 or 15 for Visual Studio 2017 Build Tools
$VsBuildToolsInstaller = "https://download.visualstudio.microsoft.com/download/pr/bacf7555-1a20-4bf4-ae4d-1003bbc25da8/e6cfafe7eb84fe7f6cfbb10ff239902951f131363231ba0cfcd1b7f0677e6398/vs_BuildTools.exe"
$VsBuildToolsInstallChannel = "https://aka.ms/vs/16/release/channel" # use 'installChannelUri' from: & "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe" -all -products *

# Components
# ----------
#
# The official list is at:
# https://docs.microsoft.com/en-us/visualstudio/install/workload-component-id-vs-build-tools?view=vs-2019
#
# BUT THAT LIST ISN'T COMPLETE. You can use the vs_buildtools.exe installer and "Export configuration"
# and it will produce a file like in `vsconfig.json` in this folder. That will have exact component ids to
# use, and most importantly you can pick older versions like `Microsoft.VisualStudio.Component.VC.14.26.x86.x64`
# if the version of Build Tools supports it.
# HAVING SAID THAT, it is safest to use generic component names `Microsoft.VisualStudio.Component.VC.Tools.x86.x64`
# and install the fixed-release Build Tools that corresponds to the compiler version you want.
#
# We chose the following to work around the bugs listed below:
#
# * Microsoft.VisualStudio.Component.VC.Tools.x86.x64
#   - VS 2019 C++ x64/x86 build tools (Latest)
# * Microsoft.VisualStudio.Component.Windows10SDK.18362
#   - Windows 10 SDK (10.0.18362.0)
#   - Same version in ocaml-opam Docker image as of 2021-10-10
#
# VISUAL STUDIO BUG 1 for OCAML 4.12.0
# ------------------------------------
#     ../../ocamlopt.opt.exe -nostdlib -I ../../stdlib -I ../../otherlibs/win32unix -c -w +33..39 -warn-error A -g -bin-annot -safe-string  semaphore.ml
#     ../../ocamlopt.opt.exe -nostdlib -I ../../stdlib -I ../../otherlibs/win32unix -linkall -a -cclib -lthreadsnat  -o threads.cmxa thread.cmx mutex.cmx condition.cmx event.cmx threadUnix.cmx semaphore.cmx
#     OCAML_FLEXLINK="../../boot/ocamlrun ../../flexdll/flexlink.exe" ../../boot/ocamlrun.exe ../../tools/ocamlmklib.exe -o threadsnat st_stubs.n.obj
#     dyndll09d83a.obj : fatal error LNK1400: section 0x13 contains invalid volatile metadata
#     ** Fatal error: Error during linking
#
#     make[3]: *** [Makefile:74: libthreadsnat.lib] Error 2
#     make[3]: Leaving directory '/c/DiskuvOCaml/OpamSys/32/src/opam/bootstrap/ocaml-4.12.0/otherlibs/systhreads'
#     make[2]: *** [Makefile:35: allopt] Error 2
#     make[2]: Leaving directory '/c/DiskuvOCaml/OpamSys/32/src/opam/bootstrap/ocaml-4.12.0/otherlibs'
#     make[1]: *** [Makefile:896: otherlibrariesopt] Error 2
#     make[1]: Leaving directory '/c/DiskuvOCaml/OpamSys/32/src/opam/bootstrap/ocaml-4.12.0'
#     make: *** [Makefile:219: opt.opt] Error 2
#
# Happens with Microsoft.VisualStudio.Component.VC.Tools.x86.x64,version=16.11.31317.239 (aka
# "MSVC v142 - VS 2019 C++ x64/x86 build tools (Latest)" as of September 2021) when compiling
# both native 32-bit (x86) and cross-compiled 64-bit host for 32-bit target (x64_x86).
#
# Does _not_ happen with Microsoft.VisualStudio.Component.VC.Tools.x86.x64,version=16.6.30013.169
# which had been installed in Microsoft.VisualStudio.Product.BuildTools,version=16.6.30309.148
# (aka version 14.26.28806 with VC\Tools\MSVC\14.26.28801 directory) of
# VisualStudio/16.6.4+30309.148 in the GitLab CI Windows container
# (https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/gcp/windows-containers/-/tree/main/cookbooks/preinstalled-software)
# by:
#  visualstudio2019buildtools 16.6.5.0 (no version 16.6.4!) (https://chocolatey.org/packages/visualstudio2019buildtools)
#  visualstudio2019-workload-vctools 1.0.0 (https://chocolatey.org/packages/visualstudio2019-workload-vctools)
#
# So we either want the "Latest" VC Tools for the old VS 2019 Studio 16.6:
#   >> VS 2019 Studio (Build Tools, etc.) 16.6.* <<
#   >> Microsoft.VisualStudio.Component.VC.Tools.x86.x64 (MSVC v142 - VS 2019 C++ x64/x86 build tools (Latest)) <<
# or the specific compiler selected:
#   >> Microsoft.VisualStudio.Component.VC.14.26.x86.x64 <<
# Either of those will give use 14.26 compiler tools.
$VcVars2019CompatibleVers = @(
    # Highest priority to lowest priority.

    #   Original GitLab CI
    #   Original C:\DiskuvOCaml\BuildTools
    "14.26",

    #   Original GitHub Actions
    "14.25",

    #   GitLab CI as of https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/gcp/windows-containers/-/commit/5f94426f12d082c2226da29ab7b79f0b90ec7725
    "14.29"
    )
$VcVars2022CompatibleVers = @(
    #   GitLab CI as of https://about.gitlab.com/blog/2024/01/22/windows-2022-support-for-gitlab-saas-runners/.
    #   Started at 14.38. As of Jun 6, 2024 is 14.40.
    "14.38",
    "14.39",
    #       https://devblogs.microsoft.com/cppblog/msvc-toolset-minor-version-number-14-40-in-vs-2022-v17-10/
    #       > In Visual Studio 2022 version 17.10, the MSVC Toolset minor version will continue with 14.40 and continue incrementing in the ‘14.4x’ series.
    "14.40",
    "14.41",
    "14.42",
    "14.43",
    "14.44",
    "14.45",
    "14.46",
    "14.47",
    "14.48",
    "14.49"    
)
$VcVars2019CompatibleComponents = $VcVars2019CompatibleVers | ForEach-Object { "Microsoft.VisualStudio.Component.VC.${_}.x86.x64" }
if ($null -eq $VcVars2019CompatibleComponents) { $VcVars2019CompatibleComponents = @() }
$VcVars2022CompatibleComponents = $VcVars2022CompatibleVers | ForEach-Object { "Microsoft.VisualStudio.Component.VC.${_}.x86.x64" }
if ($null -eq $VcVars2022CompatibleComponents) { $VcVars2022CompatibleComponents = @() }

function Get-CompatibleVisualStudioVcVarsVer {
    param (
        $VsToolsMajorMinVer,
        [switch]
        $ThrowIfIncompatible
    )
    switch ("$VsToolsMajorMinVer")
    {
        # https://en.wikipedia.org/wiki/Microsoft_Visual_C%2B%2B
        "16.4" { if ($ThrowIfIncompatible) { throw "VS 16.4 (aka 14.24) has not been verified to be compatible with OCaml by Diskuv" } }
        "16.5" {"14.25"}
        "16.6" {"14.26"}
        "16.7" { if ($ThrowIfIncompatible) { throw "VS 16.7 (aka 14.27) has not been verified to be compatible with OCaml by Diskuv" } }
        "16.8" { if ($ThrowIfIncompatible) { throw "VS 16.8 (aka 14.28) has not been verified to be compatible with OCaml by Diskuv" } }
        "16.9" { if ($ThrowIfIncompatible) { throw "VS 16.9 (aka 14.28) has not been verified to be compatible with OCaml by Diskuv" } }
        "16.11" {"14.29"}
        "17.0" { if ($ThrowIfIncompatible) { throw "VS 17.0 (aka 14.3) has not been verified to be compatible with OCaml by Diskuv" } }
        "17.2" { if ($ThrowIfIncompatible) { throw "VS 17.2 (aka 14.3) has not been verified to be compatible with OCaml by Diskuv" } }
        "17.3" { if ($ThrowIfIncompatible) { throw "VS 17.3 (aka 14.3) has not been verified to be compatible with OCaml by Diskuv" } }
        "17.8" { "14.38" }
        "17.9" { "14.39" }
        #       https://devblogs.microsoft.com/cppblog/msvc-toolset-minor-version-number-14-40-in-vs-2022-v17-10/
        #       > In Visual Studio 2022 version 17.10, the MSVC Toolset minor version will continue with 14.40 and continue incrementing in the ‘14.4x’ series.
        #       We can leave 17.10 to always install the earliest minor version (14.40) since that minor version will always be available for 17.10.
        #       If there is a serious 14.40 bug we can bump up the minimum minor version.
        "17.10" { "14.40" }
        "17.11" { "14.41" }
        "17.12" { "14.42" } # This is the latest to be announced as of 2024-08-13. https://learn.microsoft.com/en-us/visualstudio/releases/2022/release-notes-preview
        "17.13" { "14.43" }
        "17.14" { "14.44" }
        "17.15" { "14.45" }
        "17.16" { "14.46" }
        "17.17" { "14.47" }
        "17.18" { "14.48" }
        "17.19" { "14.49" }        
        default {
            if ($ThrowIfIncompatible) { throw "Visual Studio $VsToolsMajorMinVer is not yet supported by Diskuv" }
        }
    }
}

$VsComponents = @(
    # Verbatim (except variable replacement) from vsconfig.json that was "Export configuration" from the
    # correctly versioned vs_buildtools.exe installer, but removed all transitive dependencies.

    # 2021-09-23/jonahbeckford@: Since vcpkg does not allow pinning the exact $VcVarsVer, we must install
    # VC.Tools. Also vcpkg expects VC\Auxiliary\Build\vcvarsall.bat to exist (https://github.com/microsoft/vcpkg-tool/blob/baf0eecbb56ef87c4704e482a3a296ca8e40ddc4/src/vcpkg/visualstudio.cpp#L207-L213)
    # which is only available with VC.Tools.

    # 2021-09-22/jonahbeckford@:
    # We do not include "Microsoft.VisualStudio.Component.VC.(Tools|$VcVarsVer).x86.x64" because
    # we need special logic in Get-CompatibleVisualStudios to detect it.

    # 2023-03-14/jonahbeckford@:
    # We do not include "Microsoft.VisualStudio.Component.Windows10SDK.$Windows10SdkVer" because
    # we need special logic in Get-CompatibleVisualStudios to detect it.

    "Microsoft.VisualStudio.Component.VC.Tools.x86.x64"
)
$VsSpecialComponents = @(
    # 2021-09-22/jonahbeckford@:
    # We only install this component if a viable "Microsoft.VisualStudio.Component.VC.Tools.x86.x64" not detected
    # in Get-CompatibleVisualStudios.
    "Microsoft.VisualStudio.Component.Windows10SDK.$($Windows10SdkCompatibleVers[0])",
    "Microsoft.VisualStudio.Component.VC.$($VcVars2019CompatibleVers[0]).x86.x64"
)
$VsAvailableProductLangs = @(
    # https://docs.microsoft.com/en-us/visualstudio/install/use-command-line-parameters-to-install-visual-studio?view=vs-2019#list-of-language-locales
    "Cs-cz",
    "De-de",
    "En-us",
    "Es-es",
    "Fr-fr",
    "It-it",
    "Ja-jp",
    "Ko-kr",
    "Pl-pl",
    "Pt-br",
    "Ru-ru",
    "Tr-tr",
    "Zh-cn",
    "Zh-tw"
)

# Consolidate the magic constants into a single deployment id
$VsComponentsHash = Get-Sha256Hex16OfText -Text ($CygwinPackagesArch -join ',')
$Windows10SdkTriplesHash = Get-Sha256Hex16OfText -Text ($Windows10SdkCompatibleTriples -join ',')
$Windows11SdkTriplesHash = Get-Sha256Hex16OfText -Text ($Windows11SdkCompatibleTriples -join ',')
$MachineDeploymentId = "winsdk11-$Windows11SdkTriplesHash;winsdk10-$Windows10SdkTriplesHash;vsvermin-$VsVerMin;vssetup-$VsSetupVer;vscomp-$VsComponentsHash"

Export-ModuleMember -Variable MachineDeploymentId
Export-ModuleMember -Variable VsBuildToolsMajorVer
Export-ModuleMember -Variable VsBuildToolsInstaller
Export-ModuleMember -Variable VsBuildToolsInstallChannel

# -----------------------------------

$MachineDeploymentHash = Get-Sha256Hex16OfText -Text $MachineDeploymentId

if ($env:LOCALAPPDATA) {
    $DkmlParentHomeDir = "$env:LOCALAPPDATA\Programs\DkML"
} elseif ($env:XDG_DATA_HOME) {
    $DkmlParentHomeDir = "$env:XDG_DATA_HOME/dkml"
} elseif ($env:HOME) {
    $DkmlParentHomeDir = "$env:HOME/.local/share/dkml"
}

$dsc = [System.IO.Path]::DirectorySeparatorChar
$DkmlPowerShellModules = "$DkmlParentHomeDir${dsc}PowerShell${dsc}$MachineDeploymentHash${dsc}Modules"
$env:PSModulePath += "$([System.IO.Path]::PathSeparator)$DkmlPowerShellModules"

function Import-VSSetup {
    param (
        [Parameter(Mandatory = $true)]
        $TempPath
    )

    $VsSetupModules = "$DkmlPowerShellModules\VSSetup"

    if (!(Test-Path -Path $VsSetupModules\VSSetup.psm1)) {
        if (!(Test-Path -Path $TempPath)) { New-Item -Path $TempPath -ItemType Directory | Out-Null }
        Invoke-WebRequest -Uri https://github.com/microsoft/vssetup.powershell/releases/download/$VsSetupVer/VSSetup.zip -OutFile $TempPath\VSSetup.zip
        if (!(Test-Path -Path $VsSetupModules)) { New-Item -Path $VsSetupModules -ItemType Directory | Out-Null }
        Expand-Archive $TempPath\VSSetup.zip $VsSetupModules
    }

    Import-Module VSSetup
}
Export-ModuleMember -Function Import-VSSetup

function Get-VisualStudioComponentDescription {
    [CmdletBinding()]
    param (
        [switch]
        $VcpkgCompatibility
    )

    # Troubleshooting description of what needs to be installed
    $Windows10SdkFullVersDescription = $Windows10SdkCompatibleTriples -join " or "
    $Windows11SdkFullVersDescription = $Windows11SdkCompatibleTriples -join " or "
    $VcVars2019Description = ($VcVars2019CompatibleVers | ForEach-Object { "v$_" }) -join " or "
    $VcVars2022Description = ($VcVars2022CompatibleVers | ForEach-Object { "v$_" }) -join " or "
    if ($VcpkgCompatibility) {
        (
            "`ta) English language pack (en-US)`n" +
            "`tb) MSVC v142 - VS 2019 C++ x64/x86 build tools ($VcVars2019Description) or VS 2022 C++ x64/x86 build tools ($VcVars2022Description)`n" +
            "`tc) MSVC v142 - VS 2019 C++ x64/x86 build tools (Latest) or VS 2022 C++ x64/x86 build tools (Latest)`n" +
            "`td) Windows 10 SDK ($Windows10SdkFullVersDescription) or Windows 11 SDK ($Windows11SdkFullVersDescription)`n")
    } else {
        (
            "`ta) MSVC v142 - VS 2019 C++ x64/x86 build tools ($VcVars2019Description) or VS 2022 C++ x64/x86 build tools ($VcVars2022Description)`n" +
            "`tb) MSVC v142 - VS 2019 C++ x64/x86 build tools (Latest) or VS 2022 C++ x64/x86 build tools (Latest)`n" +
            "`tc) Windows 10 SDK ($Windows10SdkFullVersDescription) or Windows 11 SDK ($Windows11SdkFullVersDescription)`n")
    }
}

function Get-VisualStudioComponents {
    [CmdletBinding()]
    param (
        [switch]
        $VcpkgCompatibility
    )

    # Figure out which languages are needed
    if ($VcpkgCompatibility) {
        if (Get-Command Get-WinSystemLocale -ErrorAction SilentlyContinue) {
            $VsProductLangs = @(
                # English is required because of https://github.com/microsoft/vcpkg-tool/blob/baf0eecbb56ef87c4704e482a3a296ca8e40ddc4/src/vcpkg/visualstudio.cpp#L286-L291
                # Confer https://github.com/microsoft/vcpkg#quick-start-windows and https://github.com/microsoft/vcpkg/issues/3842
                "en-US",

                # Use the system default (will be deduplicated in the next step, and removed if unknown in the following step).
                # This is to be user-friendly for non-English users; not strictly required since the rest of the docs are in English.
                (Get-WinSystemLocale).Name
            )
        } else {
            # May be running in `setup-userprofile.ps1 -OnlyOutputCacheKey` in a non-Windows pwsh shell
            $VsProductLangs = @( "en-US" )
        }
        $VsProductLangs = $VsProductLangs | Sort-Object -Property { $_.ToLowerInvariant() } -Unique
    } else {
        $VsProductLangs = @()
    }
    if (-not ($VsProductLangs -is [array])) { $VsProductLangs = @( $VsProductLangs ) }

    #   Only include languages which are available
    $VsProductLangs = $VsProductLangs | Where-Object { $VsAvailableProductLangs -contains $_ }
    if (-not ($VsProductLangs -is [array])) { $VsProductLangs = @( $VsProductLangs ) }

    $VsDescribeComponents = Get-VisualStudioComponentDescription -VcpkgCompatibility:$VcpkgCompatibility
    $VsAddComponents =
        ($VsProductLangs | ForEach-Object { $i = 0 }{ @( "--addProductLang", $VsProductLangs[$i] ); $i++ }) +
        ($VsComponents | ForEach-Object { $i = 0 }{ @( "--add", $VsComponents[$i] ); $i++ }) +
        ($VsSpecialComponents | ForEach-Object { $i = 0 }{ @( "--add", $VsSpecialComponents[$i] ); $i++ })
    @{
        Add = $VsAddComponents;
        Describe = $VsDescribeComponents
    }
}
Export-ModuleMember -Function Get-VisualStudioComponents

function Get-VisualStudioProperties {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $VisualStudioInstallation
    )
    $MsvsPreference = ("" + $VisualStudioInstallation.InstallationVersion.Major + "." + $VisualStudioInstallation.InstallationVersion.Minor)

    # From https://cmake.org/cmake/help/v3.22/manual/cmake-generators.7.html#visual-studio-generators
    $CMakeVsYear = switch ($VisualStudioInstallation.InstallationVersion.Major)
    {
        8 {"2005"}
        9 {"2008"}
        10 {"2010"}
        11 {"2012"}
        12 {"2013"}
        14 {"2015"}
        15 {"2017"}
        16 {"2019"}
        17 {"2022"}
    }
    $CMakeGenerator = ("Visual Studio " + $VisualStudioInstallation.InstallationVersion.Major + " " + $CMakeVsYear)

    # Find a compatible Component.VC.<version>.x86.x64
    $VcVarsVerCandidates = $VisualStudioInstallation.Packages | Where-Object {
        $VcVars2019CompatibleComponents.Contains($_.Id) -or $VcVars2022CompatibleComponents.Contains($_.Id)
    }
    if ($VcVarsVerCandidates.Count -eq 0) {
        # Only Microsoft.VisualStudio.Component.VC.Tools.x86.x64 (part of $VsComponents)
        # is available.
        # So use the default version for the installed Visual Studio.
        # (It is also found as the UniqueId on Microsoft.VisualStudio.Component.VC.Tools.x86.x64.)
        $VcVarsVerChoice = Get-CompatibleVisualStudioVcVarsVer -ThrowIfIncompatible -VsToolsMajorMinVer "$MsvsPreference"
    } else {
        # Pick the latest (not the highest priority) compatible version
        ($VcVarsVerCandidates | Sort-Object -Property Version -Descending | Select-Object -Property Id -First 1).Id -match "Microsoft[.]VisualStudio[.]Component[.]VC[.](?<VCVersion>.*)[.]x86[.]x64"
        $VcVarsVerChoice = $Matches.VCVersion
    }

    # Find a compatible Component.Windows10SDK.<version> or Win11SDK_<version>
    $WindowsSdkCandidates = $VisualStudioInstallation.Packages | Where-Object {
        $Windows10SdkCompatibleComponents.Contains($_.Id) -or $Windows11SdkCompatibleComponents.Contains($_.Id)
    }
    # Pick the latest (not the highest priority) compatible version
    # Caution: The different component "UniqueId":  "Win10SDK_10.0.19041,version=10.0.19041.1"
    # implies that -winsdk=10.0.19041.1. However, it is -winsdk=10.0.19041.0.
    # Always use the .0 suffix.
    $Id = ($WindowsSdkCandidates | Sort-Object -Property Version -Descending | Select-Object -Property Id -First 1).Id
    if ($Id -match "Microsoft[.]VisualStudio[.]Component[.]Windows10SDK[.](?<WinSDKVersion>.*)") {
        $WindowsSdkChoice = "10.0.$($Matches.WinSDKVersion).0"
    } elseif ($Id -match "Win11SDK_10[.](?<WinSDKMinorVersion>.*)[.](?<WinSDKPatchVersion>.*)") {
        $WindowsSdkChoice = "10.$($Matches.WinSDKMinorVersion).$($Matches.WinSDKPatchVersion).0"
    } else {
        Write-Warning "The Windows SDK identifier '$Id' from candidates $WindowsSdkCandidates is not in a recognized format."
        # flush for GitLab CI
        [Console]::Out.Flush()
        [Console]::Error.Flush()
        exit 2
    }

    @{
        InstallPath = $VisualStudioInstallation.InstallationPath;
        MsvsPreference = "VS$MsvsPreference";
        CMakeGenerator = "$CMakeGenerator";
        VcVarsVer = $VcVarsVerChoice;
        WinSdkVer = $WindowsSdkChoice;
    }
}
Export-ModuleMember -Function Get-VisualStudioProperties

# Get zero or more Visual Studio installations that are compatible with Diskuv OCaml.
# The latest install date is chosen so theoretically should be zero or one installations returned,
# but for safety you should pick only the first given back (ex. Select-Object -First 1)
# and for troubleshooting you should dump what is given back (ex. Get-CompatibleVisualStudios | ConvertTo-Json -Depth 5)
function Get-CompatibleVisualStudios {
    [CmdletBinding()]
    param (
        [switch]
        $ErrorIfNotFound,
        [switch]
        $VcpkgCompatibility,
        [int]
        $ExitCodeIfNotFound = 1
    )
    $VsDescribeComponents = Get-VisualStudioComponentDescription -VcpkgCompatibility:$VcpkgCompatibility
    # Some examples of the related `vswhere` product: https://github.com/Microsoft/vswhere/wiki/Examples
    $allinstances = Get-VSSetupInstance
    # Filter on minimum Visual Studio version and required components
    $instances = $allinstances | Select-VSSetupInstance `
        -Product * `
        -Require $VsComponents `
        -Version "[$VsVerMin,)"
    # select installations that have `VC.Tools (Latest)` -and- the exact `VC.MM.NN (vMM.NN)`,
    # -or- `VC.Tools (Latest)` if the Visual Studio Tools version matches MM.NN.
    $instances = $instances | Where-Object {
        $VCToolsMatch = $_.Packages | Where-Object {
            $VcVarsVer = Get-CompatibleVisualStudioVcVarsVer -VsToolsMajorMinVer "$($_.Version.Major).$($_.Version.Minor)"
            $VcVarsVer -and ($_.Id -eq "Microsoft.VisualStudio.Component.VC.Tools.x86.x64")
        }
        $VCTools = $_.Packages | Where-Object {
            $_.Id -eq "Microsoft.VisualStudio.Component.VC.Tools.x86.x64"
        };
        $VCCompatible = $_.Packages | Where-Object {
            $VcVars2019CompatibleComponents.Contains($_.Id) -or $VcVars2022CompatibleComponents.Contains($_.Id)
        }
        ($VCToolsMatch.Count -gt 0) -or ( ($VCTools.Count -gt 0) -and ($VCCompatible.Count -gt 0) )
    }
    # select only installations that have the English language pack
    if ($VcpkgCompatibility) {
        $instances = $instances | Where-Object {
            # Use equivalent English language pack detection
            # logic as https://github.com/microsoft/vcpkg-tool/blob/baf0eecbb56ef87c4704e482a3a296ca8e40ddc4/src/vcpkg/visualstudio.cpp#L286-L291
            $VisualStudioProps = Get-VisualStudioProperties -VisualStudioInstallation $_
            $English = Get-ChildItem -Path "$($_.InstallationPath)\VC\Tools\MSVC\$($VisualStudioProps.VcVarsVer).*" -Recurse -Include 1033 | Measure-Object
            $English.Count -gt 0
        }
    }
    # give troubleshooting and exit if no more compatible installations remain
    if ($ErrorIfNotFound -and ($instances | Measure-Object).Count -eq 0) {
        Write-Warning "`n`nBEGIN Dump all incompatible Visual Studio(s)`n`n"
        if ($null -ne $allinstances) { Write-Warning ($allinstances | ConvertTo-Json -Depth 5) }
        Write-Warning "`n`nEND Dump all incompatible Visual Studio(s)`n`n"
        $err = (
            "There is no $VsDescribeVerMin with the following:`n$VsDescribeComponents`n`n" +
            "CHOOSE ONE OF THE SOLUTIONS BELOW`n" +
            "---------------------------------`n`n" +
            "SOLUTION 1 (Recommended)`n"+
            "1. Install winget (skip this step on Windows 11 or later since already installed):`n"+
            "     https://learn.microsoft.com/en-us/windows/package-manager/winget/#install-winget)`n"+
            "2. Run:`n"+
            "     winget install Microsoft.VisualStudio.2019.BuildTools --override `"--wait --passive --installPath $($pwd.drive.name):\VS --addProductLang En-us --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended`"`n" +
            "`nSOLUTION 2`n"+
            "1. Go to https://visualstudio.microsoft.com/vs/older-downloads/. Click the 'Download' button for 2019.`n" +
            "2. You may need to create a free account. Then download 'Build Tools for Visual Studio 2019'.`n" +
            "3. Run the Build Tools installer, and install all the components you see in the WARNING above.`n" +
            "`nSOLUTION 3 (inside Windows Sandbox only)`n" +
            "1. Follow https://learn.microsoft.com/en-us/windows/package-manager/winget/#install-winget-on-windows-sandbox`n" +
            "2. Use the second step of SOLUTION 1."
            )
        Write-Warning $err
        # flush for GitLab CI
        [Console]::Out.Flush()
        [Console]::Error.Flush()
        exit $ExitCodeIfNotFound
    }
    # sort by install date (newest first) and give back to caller
    $instances | Sort-Object -Property InstallDate -Descending
}
Export-ModuleMember -Function Get-CompatibleVisualStudios
