$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -outfile vc_redist.x64.exe https://aka.ms/vs/17/release/vc_redist.x64.exe
.\vc_redist.x64.exe
