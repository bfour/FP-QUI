@echo off
SetLocal EnableExtensions EnableDelayedExpansion

set /a Count=10
if not "%~1" == "" set /a Count=%1
for /l %%i in (1,1,%Count%) do (
echo Loop %%i:
call test.bat
unix sleep 5
)