# https://github.com/PowerShell/PowerShell/issues/2138
$ProgressPreference = 'SilentlyContinue'

Invoke-WebRequest -outfile msys2.exe https://github.com/msys2/msys2-installer/releases/download/2024-01-13/msys2-x86_64-20240113.exe

# https://www.msys2.org/docs/installer/
.\msys2.exe in --confirm-command --accept-messages --root C:/msys64
