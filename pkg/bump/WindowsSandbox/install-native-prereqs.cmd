CALL %~dp0install-winget.cmd
if %errorlevel% neq 0 exit /b %errorlevel%

CALL %~dp0install-git.cmd
if %errorlevel% neq 0 exit /b %errorlevel%

CALL %~dp0install-vsstudio.cmd
if %errorlevel% neq 0 exit /b %errorlevel%
