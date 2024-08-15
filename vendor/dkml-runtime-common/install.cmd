SETLOCAL ENABLEEXTENSIONS

@ECHO ---------------------
@ECHO Arguments:
@ECHO   Target directory = %1
@ECHO ---------------------
SET TARGETDIR=%1

@REM Create macos/ subdirectory including any parent directories (extensions are enabled)
IF NOT EXIST "%TARGETDIR%\macos" MKDIR "%TARGETDIR%\macos"

@REM Create unix/ subdirectory including any parent directories (extensions are enabled)
IF NOT EXIST "%TARGETDIR%\unix" MKDIR "%TARGETDIR%\unix"

@REM Copy in binary mode (/B) so that CRLF is not added
COPY /Y /B META                             "%TARGETDIR%"
IF %ERRORLEVEL% NEQ 0 (Echo Error during COPY &Exit /b 1)
COPY /Y /B template.dkmlroot                "%TARGETDIR%"
IF %ERRORLEVEL% NEQ 0 (Echo Error during COPY &Exit /b 1)
COPY /Y /B macos\brewbundle.sh              "%TARGETDIR%\macos"
IF %ERRORLEVEL% NEQ 0 (Echo Error during COPY &Exit /b 1)
COPY /Y /B unix\_common_tool.sh             "%TARGETDIR%\unix"
IF %ERRORLEVEL% NEQ 0 (Echo Error during COPY &Exit /b 1)
COPY /Y /B unix\_within_dev.sh              "%TARGETDIR%\unix"
IF %ERRORLEVEL% NEQ 0 (Echo Error during COPY &Exit /b 1)
COPY /Y /B unix\crossplatform-functions.sh  "%TARGETDIR%\unix"
IF %ERRORLEVEL% NEQ 0 (Echo Error during COPY &Exit /b 1)
