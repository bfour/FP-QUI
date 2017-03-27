@echo off
SetLocal EnableExtensions EnableDelayedExpansion

rem Use DCC32 compiler

:Main
call :DeleteFiles *.~* *.dof *.dsk *.dcu *.cfg
call :DeleteFiles fpquitipw.res fpquitipw.dsk fpquitipw.cfg fpquitipw.dof fpquitipw.dpr
copy /y fpquitip.res fpquitipw.res >nul & type fpquitip.dpr | findstr /V "{$APPTYPE CONSOLE}" > fpquitipw.dpr
for %%x in ( fpquitip fpquitipw ) do call :CompileProg %%x
call :DeleteFiles fpquitipw.res fpquitipw.dsk fpquitipw.cfg fpquitipw.dof fpquitipw.dpr
fpquitip -h > fpquitip.txt & unix txt2htm fpquitip.txt >nul
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
