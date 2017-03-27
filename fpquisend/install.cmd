@echo off
SetLocal EnableExtensions EnableDelayedExpansion

:Main
pushd "%~dp0" && call :InstallFpQui
popd
goto :EOF

:InstallFpQui
if "%ProgramFiles%" == ""               ( echo Not found ProgramFiles.                  & goto :EOF )
if not exist "Release.txt"              ( echo Not found Release.txt.                   & goto :EOF )
if not exist "%ProgramFiles%\"          ( echo Not found ProgramFiles.                  & goto :EOF )
if /I "%cd%" == "%ProgramFiles%\FP-QUI" ( echo Could not install from this directory.   & goto :EOF )
net session 1>nul 2>nul ||              ( echo Access denied. Administrator required.   & goto :EOF )
fc /L "Release.txt" "%ProgramFiles%\FP-QUI\Release.txt" 1>nul 2>nul && ( echo This FP-QUI version already installed. && goto :EOF )
taskkill /F /FI "WINDOWTITLE eq FP-QUI/dispatcherWindow" /FI "IMAGENAME eq FP-QUICore.exe" 1>nul 2>nul && ping -n 3 127.0.0.1 1>nul 2>nul
if exist "%ProgramFiles%\FP-QUI\" rename "%ProgramFiles%\FP-QUI" FP-QUI.OLD 1>nul 2>nul && mkdir "%ProgramFiles%\FP-QUI" 1>nul 2>nul
if not exist "%ProgramFiles%\FP-QUI\Release.txt" xcopy /F /V /C /S /Y /I "*.*" "%ProgramFiles%\FP-QUI\" 1>nul 2>nul
if exist "%ProgramFiles%\FP-QUI\Release.txt" if exist "%ProgramFiles%\FP-QUI.OLD\" rmdir /s /q "%ProgramFiles%\FP-QUI.OLD\" 1>nul 2>nul
if not exist "%ProgramFiles%\FP-QUI\Release.txt" if exist "%ProgramFiles%\FP-QUI.OLD\" rename "%ProgramFiles%\FP-QUI.OLD" FP-QUI 1>nul 2>nul
fc /L "Release.txt" "%ProgramFiles%\FP-QUI\Release.txt" 1>nul 2>nul && echo The FP-QUI updated successfully.
fc /L "Release.txt" "%ProgramFiles%\FP-QUI\Release.txt" 1>nul 2>nul || echo The FP-QUI update failure.
"%ComSpec%" /c call "%ProgramFiles%\FP-QUI\Register.cmd"
goto :EOF
