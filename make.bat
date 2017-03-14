@echo off
SetLocal EnableExtensions EnableDelayedExpansion

rem Use DCC32 compiler

:Main
call :DeleteFiles fpquisendw.res fpquisendw.dsk fpquisendw.cfg fpquisendw.dof fpquisendw.dpr
copy /y fpquisend.res fpquisendw.res >nul & type fpquisend.dpr | findstr /V "{$APPTYPE CONSOLE}" > fpquisendw.dpr
for %%x in ( fpquisend fpquisendw ) do call :CompileProg %%x
call :DeleteFiles fpquisendw.res fpquisendw.dsk fpquisendw.cfg fpquisendw.dof fpquisendw.dpr
fpquisend -h > fpquisend.txt & unix txt2htm fpquisend.txt >nul
goto :EOF

:CompileProg
if "%~1" == "" goto :EOF
if exist %1.map del /F %1.map
if exist %1.exe del /F %1.exe
if exist %1.exe ( call :NotifyFailure "Could not delete file %1.exe." & goto :EOF )
if not exist %1.dpr ( call :NotifyFailure "Could not find source file %1.dpr." & goto :EOF )
dcc32 %1.dpr
for %%i in (%1.exe) do call :NotifySuccess "%%~nxi compiled, %%~zi bytes."
if not exist %1.exe call :NotifyFailure "Could not compile %1.dpr"
goto :EOF

:NotifySuccess
if "%~1" == "" goto :EOF
unix tooltip-notifier text "%~1" preset stdSuccess delay 15000
echo Success: %~1
goto :EOF

:NotifyFailure
if "%~1" == "" goto :EOF
unix tooltip-notifier text "%~1" preset stdError delay 15000
echo Failure: %~1
goto :EOF

:DeleteFiles
if "%~1" == "" goto :EOF
if exist "%~1" del /F "%~1"
shift & goto DeleteFiles
goto :EOF
