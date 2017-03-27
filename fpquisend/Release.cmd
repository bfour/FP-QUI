@echo off

echo FP-QUI Release %date: =0%-%time: =0% > "%~dpn0.txt"

if not exist "%~dp0gui\" mkdir "%~dp0gui"
if exist "%~dp0gui\" for %%t in ( avi ico wav ) do (
 rem if exist "%~dp0gui\*.%%t" del /f /q "%~dp0gui\*.%%t"
 xcopy /V /Y /F /I /C /R /D "%~dp0..\bin\*.%%t" "%~dp0gui\"
)
